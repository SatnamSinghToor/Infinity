import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:duggu/services/product_description_service.dart';

/// The seller's AI writer is built on one number: a description is 700 words at
/// the shortest and 1500 at the longest. Two lines sell nothing, and a page the
/// buyer never reaches the end of is worse than no page.
///
/// The rule only holds while both halves agree about it — the app, which asks
/// for the page and shows the count under the box, and
/// `supabase/functions/generate-product-description/index.ts`, which writes it
/// and checks what came back. The button used to fail with "Could not generate
/// description" for four different reasons, none of them the seller's fault and
/// none of them named; these tests are the word-count arithmetic, the decoding
/// of a reply, and the pins that keep the two halves from drifting apart.
void main() {
  String read(String path) => File(path).readAsStringSync();

  const functionPath =
      'supabase/functions/generate-product-description/index.ts';
  final function = File(functionPath).existsSync() ? read(functionPath) : '';

  /// Runs [body] and hands back the failure it threw, because the reason is
  /// the whole content of this feature's error handling.
  ProductDescriptionFailure failureFrom(void Function() body) {
    try {
      body();
    } on ProductDescriptionFailure catch (failure) {
      return failure;
    }
    fail('expected a ProductDescriptionFailure');
  }

  /// [count] words in lines of ten, each ending in a full stop.
  String page(int count) {
    final lines = <String>[];
    var made = 0;
    while (made < count) {
      final line = <String>[];
      for (var i = 0; made + line.length < count && line.length < 10; i++) {
        line.add('w${made + line.length}_$i');
      }
      lines.add('${line.join(' ')}.');
      made += line.length;
    }
    return lines.join('\n');
  }

  group('the length rule', () {
    test('the app and the function want the same page', () {
      expect(ProductDescriptionAi.minWords, 700);
      expect(ProductDescriptionAi.maxWords, 1500);
      expect(function, isNotEmpty, reason: '$functionPath is missing');
      expect(function, contains('const MIN_WORDS = 700;'));
      expect(function, contains('const MAX_WORDS = 1500;'));
    });

    test('words are counted as both sides count them', () {
      expect(ProductDescriptionAi.countWords('one two   three\nfour'), 4);
      expect(ProductDescriptionAi.countWords(''), 0);
      expect(ProductDescriptionAi.countWords('   \n \t '), 0);
      // Titles and bullets are words too: the seller sees one number, and it
      // is the number that says whether the page is long enough.
      expect(ProductDescriptionAi.countWords('Care:\n\u2022 keep it dry'), 5);
    });

    test('a page over the ceiling is cut, and cut at a sentence', () {
      final capped = ProductDescriptionAi.capToMax(page(2600));
      final words = ProductDescriptionAi.countWords(capped);
      expect(words, lessThanOrEqualTo(1500));
      expect(words, greaterThanOrEqualTo(1400));
      expect(capped.trimRight().endsWith('.'), isTrue);
      expect(capped, startsWith('w0_0 w1_1 w2_2'));
    });

    test('a page inside the rule is handed over as it was written', () {
      final text = page(900);
      expect(ProductDescriptionAi.capToMax(text), text.trim());
      // The cut must not re-paragraph a seller's text on its way past.
      expect(ProductDescriptionAi.capToMax(text), isNot(contains('\n\n')));
    });

    test('the app waits longer than the function is allowed to write', () {
      final budget =
          RegExp(r"get\('AI_BUDGET_MS'\), (\d+)").firstMatch(function);
      expect(budget, isNotNull, reason: 'the function needs a time budget');
      expect(
        ProductDescriptionAi.timeout.inMilliseconds,
        greaterThan(int.parse(budget![1]!)),
        reason: 'a page still on its way must not be called a failure',
      );
      expect(
        ProductDescriptionAi.timeout.inSeconds,
        lessThan(200),
        reason: 'and a seller must not be left waiting forever',
      );
    });
  });

  group('the reply', () {
    test('a description and its highlights are read out of the json', () {
      final draft = ProductDescriptionAi.draftFrom(<String, dynamic>{
        'description': page(20),
        'highlights': <String>['One line', 'Another'],
        'model': 'gpt-4o-mini',
        'passes': 2,
      });
      expect(draft.words, 20);
      // Short of the floor, so the seller is offered the tap that continues.
      expect(draft.inRange, isFalse);
      expect(draft.shortBy, ProductDescriptionAi.minWords - 20);
      expect(draft.highlights, <String>['One line', 'Another']);
      expect(draft.fromModel, isTrue);
      expect(draft.passes, 2);
    });

    test('a reply that is a json string is still a reply', () {
      // `functions.invoke` hands back a String whenever the function did not
      // answer with a json content type. The screen used to cast it to a Map,
      // which threw, and the cast was the last thing the seller saw.
      final body = jsonEncode(<String, dynamic>{
        'description': page(30),
        'highlights': <String>['One line'],
      });
      final draft = ProductDescriptionAi.draftFrom(body);
      expect(draft.words, 30);
      expect(draft.highlights, <String>['One line']);
    });

    test('a reply that is not json names itself and shows what came back', () {
      final failure = failureFrom(
        () => ProductDescriptionAi.draftFrom('<html>502 Bad Gateway</html>'),
      );
      expect(failure.problem, ProductDescriptionProblem.unreachable);
      expect(failure.detail, contains('502 Bad Gateway'));
    });

    test('a reply without a description is a failure, not an empty box', () {
      final failure = failureFrom(
        () => ProductDescriptionAi.draftFrom(<String, dynamic>{
          'highlights': <String>['One line'],
        }),
      );
      expect(failure.problem, ProductDescriptionProblem.empty);
    });

    test('a too-long reply is capped before the seller is shown it', () {
      final draft = ProductDescriptionAi.draftFrom(<String, dynamic>{
        'description': page(4000),
      });
      expect(draft.words, lessThanOrEqualTo(ProductDescriptionAi.maxWords));
    });

    test('highlights are plain, deduped, and at most eight', () {
      final long = ('a ' * 60).trim();
      final out = ProductDescriptionAi.highlightsFrom(<Object?>[
        '- **Bold** claim',
        'Bold CLAIM',
        ' 1. Numbered one',
        12,
        'x',
        long,
        'six',
        'seven',
        'eight',
        'nine',
        'ten',
        'eleven',
      ]);
      expect(out, hasLength(8));
      expect(out.first, 'Bold claim');
      expect(out, isNot(contains('Bold CLAIM')));
      expect(out[1], 'Numbered one');
      expect(out[2].length, lessThanOrEqualTo(70));
      // The two-character entries were dropped, and eight is the cap.
      expect(out.last, 'ten');
      expect(out, isNot(contains('eleven')));
    });

    test('a composed page is not sold as the model writing', () {
      final draft = ProductDescriptionAi.draftFrom(<String, dynamic>{
        'description': page(25),
        'model': 'duggu-composed',
        'fallback': true,
      });
      expect(draft.fromModel, isFalse);
    });

    test('a composed page says why the model did not write it', () {
      final refused = ProductDescriptionAi.draftFrom(<String, dynamic>{
        'description': page(25),
        'fallback': true,
        'fallback_reason': 'bad_key',
      });
      expect(refused.fallbackReason, 'bad_key');
      // A deployment older than this field marks the page and says nothing
      // more. The one reason it ever left unexplained was the missing key, so
      // that is what the app says, rather than guessing at a newer one.
      final old = ProductDescriptionAi.draftFrom(<String, dynamic>{
        'description': page(25),
        'fallback': true,
      });
      expect(old.fallbackReason, 'no_key');
    });
  });

  group('why a tap failed', () {
    test('every reason has a sentence the seller can act on', () {
      // Each case used to land in one `catch` and say the same useless thing.
      expect(
        ProductDescriptionAi.failureFor(404, <String, dynamic>{
          'error': 'Function not found',
          'code': 'NOT_FOUND',
        }).problem,
        ProductDescriptionProblem.notDeployed,
      );
      expect(
        ProductDescriptionAi.failureFor(401, null).problem,
        ProductDescriptionProblem.notSignedIn,
      );
      expect(
        ProductDescriptionAi.failureFor(429, <String, dynamic>{
          'code': 'AI_RATE_LIMIT',
        }).problem,
        ProductDescriptionProblem.rateLimited,
      );
      expect(
        ProductDescriptionAi.failureFor(502, <String, dynamic>{
          'code': 'AI_UPSTREAM',
          'error': 'the AI service is asking for a pause',
        }).problem,
        ProductDescriptionProblem.unavailable,
      );
      expect(
        ProductDescriptionAi.failureFor(502, <String, dynamic>{
          'code': 'AI_EMPTY',
        }).problem,
        ProductDescriptionProblem.empty,
      );
      final refused = ProductDescriptionAi.failureFor(400, <String, dynamic>{
        'error': 'a product name is needed to write from',
        'code': 'AI_NO_NAME',
      });
      expect(refused.problem, ProductDescriptionProblem.refused);
      // The function's refusals are written for a person, so they are shown.
      expect(refused.message, 'a product name is needed to write from');
      expect(refused.status, 400);
    });

    test('a mistake in the settings is not read as a busy minute', () {
      // The three of these are the same answer to a seller and a different
      // job for whoever owns the server, and all three used to say "try again
      // in a minute" - which is how a wrong key gets retried for a week.
      for (final code in const <String>[
        'AI_BAD_KEY',
        'AI_BAD_ADDRESS',
        'AI_BAD_REQUEST',
      ]) {
        final failure = ProductDescriptionAi.failureFor(
          500,
          <String, dynamic>{'code': code},
        );
        expect(
          failure.problem,
          ProductDescriptionProblem.misconfigured,
          reason: '$code is not fixed by tapping again',
        );
      }
      final crashed = ProductDescriptionAi.failureFor(500, <String, dynamic>{
        'code': 'AI_INTERNAL',
        'error': 'the AI writer broke while answering',
      });
      expect(crashed.problem, ProductDescriptionProblem.crashed);
      // The reason is carried in the failure as well, because the seller is
      // told to go to the log and the log has to have something in it.
      expect(crashed.message, isNotNull);

      final slow = ProductDescriptionAi.failureFor(504, <String, dynamic>{
        'code': 'AI_TIMEOUT',
      });
      expect(slow.problem, ProductDescriptionProblem.timedOut);

      // Paced by the provider or paced by the server: the seller can do one
      // thing about either, and it is not "you asked too many times".
      final paced = ProductDescriptionAi.failureFor(429, <String, dynamic>{
        'code': 'AI_PROVIDER_LIMIT',
      });
      expect(paced.problem, ProductDescriptionProblem.rateLimited);

      // What the app cannot name is still not given a guess at a cause — but
      // what did answer is kept for the log, because "an error" on its own is
      // the sentence nobody can act on.
      final unknown = ProductDescriptionAi.failureFor(500, '<html>oops</html>');
      expect(unknown.problem, ProductDescriptionProblem.unavailable);
      expect(unknown.detail, contains('oops'));
    });

    test('only a tap that could help is offered', () {
      final screen = read('lib/screens/seller/add_product_screen.dart');
      final start = screen.indexOf('bool _canRetry(');
      expect(start, greaterThan(-1));
      final canRetry = screen.substring(start, screen.indexOf('\n  }', start));
      expect(canRetry, contains('ProductDescriptionProblem.misconfigured'));
      expect(canRetry, contains('ProductDescriptionProblem.crashed'));
      // A provider that is busy is exactly what a second tap is for.
      expect(canRetry, isNot(contains('unavailable')));
      expect(
        screen,
        contains('_descriptionRetry ? _generateDescription : null'),
      );
    });

    test('the screen has a sentence for every problem, without exception', () {
      final screen = read('lib/screens/seller/add_product_screen.dart');
      for (final problem in ProductDescriptionProblem.values) {
        expect(
          screen,
          contains('ProductDescriptionProblem.${problem.name}'),
          reason: 'no message for $problem: the seller gets the generic one',
        );
      }
    });
  });

  group('the two halves', () {
    test('the function is in git and writes to the rule it is given', () {
      expect(function, isNotEmpty);
      // Asked for in the prompt, and then checked: a floor nobody verifies is
      // a wish.
      expect(function, contains('between {{MIN}} and {{MAX}} words'));
      expect(function, contains('function capWords'));
      expect(function, contains('function continuationBrief'));
      expect(function, contains('inRange: wordCount >= minWords'));
      expect(function, contains('shortBy: Math.max(0, minWords - wordCount)'));
      // A page this long cannot be written inside one request's patience.
      expect(function, contains('out_of_time'));
    });

    test('the function needs a login, and answers without a key', () {
      expect(function, contains('authUser(req)'));
      expect(function, contains("'AI_AUTH'"));
      expect(function, contains('rateWindow('));
      expect(function, contains('composeFallback(input, range.minWords)'));
      expect(function, contains("model: 'duggu-composed'"));
    });

    test('every code the function answers with is one the app maps', () {
      // An unknown code is not an unknown error: it lands on "the server
      // answered with an error", which is a sentence about nothing. So the
      // list is checked from both ends, and a code added on one side without
      // the other is caught here rather than by a seller.
      const shared = <String>[
        'AI_AUTH',
        'AI_RATE_LIMIT',
        'AI_EMPTY',
        'AI_INTERNAL',
        'AI_BAD_KEY',
        'AI_BAD_ADDRESS',
        'AI_BAD_REQUEST',
        'AI_PROVIDER_LIMIT',
        'AI_TIMEOUT',
      ];
      final service = read('lib/services/product_description_service.dart');
      for (final code in shared) {
        expect(
          function,
          contains("'$code'"),
          reason: 'the function no longer answers with $code',
        );
        expect(
          service,
          contains("'$code'"),
          reason: '$code would land on the sentence about a busy minute',
        );
      }
      // And the reason a page was composed without a model is in the reply,
      // not only in the log.
      expect(function, contains('fallback_reason: fallback ? why :'));
      expect(service, contains("map['fallback_reason']"));
    });

    test('the ask travels with the request', () {
      final service = read('lib/services/product_description_service.dart');
      expect(service, contains("'minWords': minWords"));
      expect(service, contains("'maxWords': maxWords"));
      expect(service, contains("'generate-product-description'"));
      // The Supabase call is here and nowhere else, so the decoding is one
      // place to read.
      expect(service, contains('.functions'));
      expect(service, contains('.timeout(timeout)'));
    });

    test('the screen asks the service and never the endpoint', () {
      final screen = read('lib/screens/seller/add_product_screen.dart');
      expect(screen, contains('ProductDescriptionAi.write('));
      expect(screen, isNot(contains('functions.invoke')));
      // The first version wrote an empty string over the seller's own text
      // when a reply had no description in it. It must not come back.
      expect(
        screen,
        isNot(contains("_descriptionController.text = data['description']")),
      );
      // The rule is shown, not just asked for, and a short page offers the tap
      // that finishes it.
      expect(screen, contains('addProductWordCount('));
      expect(screen, contains('addProductDescriptionRule('));
      expect(screen, contains('addProductGenerateShort('));
      expect(screen, contains('addProductExtend'));
      expect(screen, contains('addProductGenerateFromNotes'));
      // Each reason the model did not write the page has its own line, and the
      // two that a second tap cannot fix do not come with a retry button.
      expect(screen, contains('addProductGenerateAiRefused'));
      expect(screen, contains('addProductGenerateAiAddress'));
      expect(screen, contains('addProductGenerateAiDown'));
      expect(screen, contains('addProductGenerateMisconfigured'));
      expect(screen, contains('addProductGenerateCrashed'));
      // A long page has to be readable where it was written.
      expect(screen, contains('maxLines: 10'));
      // A failure waits on the screen for the seller to come back to it, and
      // the reason reaches the log too.
      expect(screen, contains('RoleInlineError('));
      expect(screen, contains("debugPrint('generate description failed"));
    });

    test('the strings are in the English file, with their descriptions', () {
      final decoded = jsonDecode(read('lib/l10n/app_en.arb'));
      final arb = decoded as Map<String, dynamic>;
      const keys = <String>[
        'addProductGenerating',
        'addProductExtend',
        'addProductDescriptionRule',
        'addProductWordCount',
        'addProductWritingHelp',
        'addProductGenerateShort',
        'addProductGenerateFromNotes',
        'addProductGenerateOffline',
        'addProductGenerateSlow',
        'addProductGenerateSignIn',
        'addProductGenerateMissing',
        'addProductGenerateRateLimited',
        'addProductGenerateBusy',
        'addProductGenerateEmpty',
        'addProductGenerateGarbled',
        'addProductGenerateMisconfigured',
        'addProductGenerateCrashed',
        'addProductGenerateAiRefused',
        'addProductGenerateAiAddress',
        'addProductGenerateAiDown',
      ];
      for (final key in keys) {
        expect(arb[key], isA<String>(), reason: '$key is missing');
        expect(arb['@$key'], isA<Map>(), reason: '@$key has no description');
      }
      // The numbers come from the code, so the wording and the rule cannot
      // drift apart.
      expect(arb['addProductWordCount'], contains('{count}'));
      expect(arb['addProductWordCount'], contains('{min}'));
      expect(arb['addProductWordCount'], contains('{max}'));
    });
  });
}
