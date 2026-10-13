import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart' show FunctionException;

import 'error_reporter.dart';
import 'supabase_service.dart';

/// The AI writer behind "Generate with AI" on Add Product.
///
/// The screen used to call `functions.invoke` itself and take whatever came
/// back. That is how this feature broke quietly: the answer is a map only when
/// the function is deployed and answers with json, and every other case — the
/// function missing from the project, the provider key missing, a body that is
/// a string instead of a map, a reply without a description — landed in one
/// `catch` and said "Could not generate description". None of it was the
/// seller's fault and none of it was worth reading. Here the reply is decoded
/// once, every failure is given a reason, and the length rule the feature is
/// designed around lives in the open:
/// [ProductDescriptionAi.minWords] to [ProductDescriptionAi.maxWords] words.
///
/// The other half of the rule is in
/// `supabase/functions/generate-product-description/index.ts`, which counts
/// words the same way (see [ProductDescriptionAi.countWords]) and is
/// checked against the same numbers, so the count under the seller's box is the
/// count the server wrote to.
class ProductDescriptionAi {
  ProductDescriptionAi._();

  /// The Edge Function this app talks to. Renaming it means renaming the
  /// folder in `supabase/functions/` too.
  static const String functionName = 'generate-product-description';

  /// A description shorter than this is not a listing; longer than the max and
  /// the buyer stops reading. Both bounds are the point of the feature.
  static const int minWords = 700;
  static const int maxWords = 1500;

  /// How long one tap waits. A page of [maxWords] words is two or three calls
  /// to the provider, and the function is given `AI_BUDGET_MS` (two minutes by
  /// default) to answer inside; the app waits a little longer than that rather
  /// than cutting a page off that is already on its way.
  static const Duration timeout = Duration(seconds: 130);

  /// The shortest stub of a line still worth keeping when a text is cut down.
  static const int _minStubWords = 12;

  /// Words, counted as the Edge Function counts them: runs of whitespace apart,
  /// section titles and bullets included. Both sides use this rule so the
  /// number the seller sees is the number that was checked.
  static int countWords(String text) => wordsOf(text).length;

  /// The words of [text], same rule as [countWords].
  static List<String> wordsOf(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const <String>[];
    return trimmed
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
  }

  /// The length rule, applied to a description that arrived too long.
  ///
  /// The function caps what it writes, but the app is the last thing between a
  /// runaway answer and the product page: an older deployment, or a reply that
  /// came from a model that would not stop, would otherwise be saved into
  /// `products.description` and shown to every buyer. Whole lines are kept
  /// while they fit, and the last line is kept word by word when the text runs
  /// over in mid-line; the cut then steps back to the end of the last sentence
  /// — but not at the cost of going under [minWords], because half a thought at
  /// the end of a page looks like the app is broken.
  static String capToMax(String text, {int? max}) {
    final limit = max ?? maxWords;
    // Inside the rule already: hand the text over as it was written. Only a
    // page that is too long for the box is re-shaped, and even then the
    // paragraph breaks that are there are kept.
    if (countWords(text) <= limit) return text.trim();
    final kept = <String>[];
    var used = 0;
    for (final raw in text.trim().split(RegExp(r'\n+'))) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final size = countWords(line);
      if (used + size <= limit) {
        kept.add(line);
        used += size;
        continue;
      }
      final room = limit - used;
      if (room >= _minStubWords) {
        kept.add(wordsOf(line).take(room).join(' '));
      }
      break;
    }
    var out = kept.join('\n\n');
    final end = lastSentenceEnd(out);
    if (end > 0) {
      final shorter = out.substring(0, end).trim();
      if (countWords(shorter) >= minWords) out = shorter;
    }
    return out;
  }

  /// Where the last sentence of [text] ends, in the last 600 characters, or -1
  /// when it runs over without one. A punctuation mark only counts as the end
  /// of a sentence when nothing but a closing quote or bracket follows it.
  static int lastSentenceEnd(String text) {
    final from = text.length > 600 ? text.length - 600 : 0;
    for (var i = text.length - 1; i >= from; i--) {
      final c = text[i];
      if (c != '.' && c != '!' && c != '?' && c != '\u0964') continue;
      var j = i + 1;
      if (j < text.length) {
        final next = text[j];
        if (next == '"' || next == '\'' || next == ')' || next == ']') j++;
      }
      if (j >= text.length) return i + 1;
      final after = text[j];
      if (after == ' ' || after == '\n' || after == '\t') return i + 1;
    }
    return -1;
  }

  /// Asks the writer for a description of [name], in [category], sold as [unit]
  /// — using the seller's own [notes] as the brief and their [store] name for
  /// the last section.
  ///
  /// Throws [ProductDescriptionFailure] with the reason. The seller's text is
  /// never part of a failure: the caller keeps whatever is in the box until an
  /// answer is in hand.
  static Future<ProductDescriptionDraft> write({
    required String name,
    String category = '',
    String unit = '',
    String notes = '',
    String store = '',
  }) async {
    if (name.trim().isEmpty) {
      throw const ProductDescriptionFailure(
        ProductDescriptionProblem.needName,
        message: 'A product name is needed to write from.',
      );
    }
    if (SupabaseService.client.auth.currentUser == null) {
      throw const ProductDescriptionFailure(
        ProductDescriptionProblem.notSignedIn,
      );
    }

    final stopwatch = Stopwatch()..start();
    try {
      final response = await SupabaseService.client.functions.invoke(
        functionName,
        body: <String, dynamic>{
          'name': name.trim(),
          'category': category.trim(),
          'unit': unit.trim(),
          'description': notes.trim(),
          'store': store.trim(),
          // The rule travels with the request, so a function deployed
          // from an older commit still writes to what this app can show.
          'minWords': minWords,
          'maxWords': maxWords,
        },
      ).timeout(timeout);
      final draft = draftFrom(response.data);
      final ms = stopwatch.elapsedMilliseconds;
      final by = draft.fromModel ? 'model' : 'via ${draft.fallbackReason}';
      final passes = '${draft.passes} ${draft.passes == 1 ? 'pass' : 'passes'}';
      debugPrint(
        'ai description: ${draft.words} words in ${ms}ms ($by, $passes)',
      );
      return draft;
    } on ProductDescriptionFailure {
      rethrow;
    } on TimeoutException {
      throw const ProductDescriptionFailure(ProductDescriptionProblem.timedOut);
    } on FunctionException catch (e) {
      throw failureFrom(e);
    } on Exception catch (e) {
      unawaited(ErrorReporter.report(e, null, source: 'ai_description'));
      throw ProductDescriptionFailure(problemFor(e), detail: '$e');
    }
  }

  /// Public because the form reads a reply through it and the tests do too.
  ///
  /// The reply, decoded. `functions.invoke` hands back the decoded json when
  /// the function answered with a json content type — and the raw `String`
  /// when it did not, which is what a proxy page, a plain-text error, or an
  /// older deployment answers with. A string that parses as json is taken
  /// apart here rather than thrown at the seller.
  static ProductDescriptionDraft draftFrom(Object? data) {
    final map = asMap(data);
    if (map == null) {
      throw ProductDescriptionFailure(
        ProductDescriptionProblem.unreachable,
        detail: preview(data),
      );
    }
    final error = map['error'];
    if (error != null) {
      // A body that says `error` came from this function's own refusals.
      throw ProductDescriptionFailure(
        ProductDescriptionProblem.refused,
        message: '$error',
      );
    }
    final description = (map['description']?.toString() ?? '').trim();
    if (description.isEmpty) {
      throw const ProductDescriptionFailure(ProductDescriptionProblem.empty);
    }
    final capped = capToMax(description);
    final words = countWords(capped);
    final reason = (map['fallback_reason']?.toString() ?? '').trim();
    return ProductDescriptionDraft(
      description: capped,
      highlights: highlightsFrom(map['highlights']),
      words: words,
      inRange: words >= minWords,
      shortBy: words < minWords ? minWords - words : 0,
      fromModel: map['model'] != 'duggu-composed' && map['fallback'] != true,
      // A deployment older than this field still marks the page as composed;
      // "no key" is the only reason that was ever silent about, so it is the
      // default rather than a blank the screen would have to explain.
      fallbackReason: reason == '' ? 'no_key' : reason,
      passes: map['passes'] is int ? map['passes'] as int : 1,
    );
  }

  /// [data] as a map, or null when the reply is not json at all.
  static Map<String, dynamic>? asMap(Object? data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty || !trimmed.startsWith('{')) return null;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  /// The Highlights strip: plain words, no bullets left over from the model, no
  /// duplicates, at most eight. Anything that is not a string is turned into
  /// one rather than thrown — a `(dynamic) List` of `Object?` used to crash the
  /// chips while painting them.
  static List<String> highlightsFrom(Object? raw) {
    if (raw is! List) return const <String>[];
    final out = <String>[];
    final seen = <String>{};
    for (final item in raw) {
      final text = highlightText('${item ?? ''}');
      // Two characters is not a highlight; the function drops them too, so
      // the strip looks the same whichever half of the wire produced it.
      if (text.length < 3) continue;
      final key = text.toLowerCase();
      if (seen.add(key)) out.add(text);
      if (out.length == 8) break;
    }
    return out;
  }

  static String highlightText(String raw) {
    var text = raw.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    text = text.replaceFirst(RegExp(r'^[-*\u2022]\s*'), '');
    text = text.replaceFirst(RegExp(r'^\d+[.)]\s*'), '');
    text = text.replaceAll(RegExp(r'[*_`]'), '').trim();
    if (text.length > 70) text = '${text.substring(0, 69).trimRight()}\u2026';
    return text;
  }

  /// The function's refusal, read for what it means. Its `code` is written for
  /// this app; the `error` string beside it is written for a person, so it is
  /// carried along as [ProductDescriptionFailure.message].
  static ProductDescriptionFailure failureFrom(FunctionException e) =>
      failureFor(e.status, e.details);

  /// The mapping on its own, so a test can hand it the same shapes the
  /// Supabase SDK hands the app without going over a network.
  @visibleForTesting
  static ProductDescriptionFailure failureFor(int status, Object? raw) {
    final details = asMap(raw) ?? raw;
    String? code;
    String? message;
    if (details is Map) {
      code = details['code']?.toString();
      message = details['error']?.toString();
    }
    // Anything else that came back — a proxy's html, a gateway's plain text —
    // is not something to show a seller, and it is the only evidence of what
    // actually answered, so it goes to the log rather than being thrown away.
    final text = details is String ? preview(details) : null;
    var problem = ProductDescriptionProblem.refused;
    if (code == 'AI_AUTH' || status == 401) {
      problem = ProductDescriptionProblem.notSignedIn;
    } else if (code == 'AI_RATE_LIMIT' ||
        code == 'AI_PROVIDER_LIMIT' ||
        status == 429) {
      problem = ProductDescriptionProblem.rateLimited;
    } else if (status == 404 || code == 'NOT_FOUND') {
      problem = ProductDescriptionProblem.notDeployed;
    } else if (code == 'AI_EMPTY') {
      problem = ProductDescriptionProblem.empty;
    } else if (code == 'AI_INTERNAL') {
      problem = ProductDescriptionProblem.crashed;
    } else if (code == 'AI_BAD_KEY' ||
        code == 'AI_BAD_ADDRESS' ||
        code == 'AI_BAD_REQUEST') {
      problem = ProductDescriptionProblem.misconfigured;
    } else if (code == 'AI_TIMEOUT') {
      problem = ProductDescriptionProblem.timedOut;
    } else if (status >= 500) {
      problem = ProductDescriptionProblem.unavailable;
    }
    return ProductDescriptionFailure(
      problem,
      message: message,
      detail: text,
      status: status,
    );
  }

  /// What a non-http error means: no route is a connection problem, and
  /// everything else is left [ProductDescriptionProblem.unavailable] with the
  /// exception itself in [ProductDescriptionFailure.detail].
  static ProductDescriptionProblem problemFor(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('failed host lookup') ||
        text.contains('socketexception') ||
        text.contains('clientexception') ||
        text.contains('connection')) {
      return ProductDescriptionProblem.offline;
    }
    return ProductDescriptionProblem.unavailable;
  }

  /// First 200 characters of a reply, for the log — a body that is not json is
  /// worth seeing, and is far too long to print whole.
  static String preview(Object? data) {
    final text = '${data ?? ''}'.replaceAll('\n', ' ').trim();
    return text.length > 200 ? '${text.substring(0, 200)}\u2026' : text;
  }
}

/// One answer from the writer, ready for the seller's form.
class ProductDescriptionDraft {
  const ProductDescriptionDraft({
    required this.description,
    required this.highlights,
    required this.words,
    required this.inRange,
    this.shortBy = 0,
    this.fromModel = true,
    this.fallbackReason = '',
    this.passes = 1,
  });

  /// The page, already inside the length rule.
  final String description;

  /// Lines for the product page's Highlights strip.
  final List<String> highlights;

  /// [description]'s word count, as the app counts words.
  final int words;

  /// False when the writer ran out of its time budget before the floor. The
  /// text is still worth keeping — the screen says so and offers one more tap,
  /// which continues from what is in the box.
  final bool inRange;

  /// How many words the floor still wants.
  final int shortBy;

  /// False when the page was composed on the server from the seller's own
  /// notes, because no AI key is set or the provider was down. It is not a
  /// failure — the listing can be published — but the seller is told which of
  /// the two they are looking at.
  final bool fromModel;

  /// Why the model did not write it, in the server's own one-word answer:
  /// `no_key`, `bad_key`, `bad_address`, `bad_request`, `timeout`,
  /// `provider_limit`, `upstream`, `not_json` or `crashed`, and only worth
  /// reading when [fromModel] is false. It exists because those reasons are
  /// answered by different people: a seller can wait out a slow provider,
  /// answered by different people — a seller can wait out a slow provider, only
  /// the store owner can set a key — and one sentence for all of them sends the
  /// seller off to wait for something that is not going to change.
  final String fallbackReason;

  /// How many calls to the provider it took.
  final int passes;
}

/// Why a tap did not produce a description. Every case has a sentence the
/// screen can show, because "Could not generate description" sent sellers to
/// retry something that was never going to change.
enum ProductDescriptionProblem {
  /// The device has no route to Duggu.
  offline,

  /// The writer did not answer inside [ProductDescriptionAi.timeout].
  timedOut,

  /// The session is gone, and the writer only answers a signed-in seller.
  notSignedIn,

  /// `/functions/v1/generate-product-description` is not in the project —
  /// the function is not deployed (see supabase/README.md).
  notDeployed,

  /// Too many descriptions from this account, or the provider asked for a
  /// pause.
  rateLimited,

  /// The writer cannot be paid or cannot be reached: the key on the server was
  /// refused, or `AI_BASE_URL` is not the address of a model. Tapping again
  /// cannot fix this one, which is the whole point of naming it apart from
  /// [unavailable] — a seller told to wait a minute for a wrong key waits
  /// forever, and the store keeps paying for the retry.
  misconfigured,

  /// The writer itself broke, on the server, and said so. The log line beside
  /// the refusal has the exception; the app cannot fix it and does not pretend
  /// that waiting will.
  crashed,

  /// The writer answered, but not with a description.
  unavailable,

  /// The reply was not a reply: not json, or an html page from something in
  /// front of the function. What came back is in the failure's `detail`,
  /// because only the log can read it.
  unreachable,

  /// The writer refused this request. Its own words explain how.
  refused,

  /// Nothing came back at all, so the box keeps what it had.
  empty,

  /// There is no product name to write from.
  needName,
}

/// One failure, with the reason in two registers: [message] in the writer's own
/// words (it may be shown), [detail] for the log (it should not).
class ProductDescriptionFailure implements Exception {
  const ProductDescriptionFailure(
    this.problem, {
    this.message,
    this.detail,
    this.status,
  });

  final ProductDescriptionProblem problem;
  final String? message;
  final String? detail;

  /// The http status, when there was one.
  final int? status;

  @override
  String toString() {
    final parts = [
      problem.name,
      if (status != null) '$status',
      if (message != null) message!,
      if (detail != null) '($detail)',
    ];
    return 'ProductDescriptionFailure(${parts.join(' ')})';
  }
}
