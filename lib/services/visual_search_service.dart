import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'error_reporter.dart';

/// What the phone made of a photo: the search terms, best first, and whether
/// the models themselves could not run.
///
/// Those are two different answers. "We read the photo and nothing on it is
/// worth searching for" is about the customer's picture; "we could not read the
/// photo at all" is usually a device that has never run this before and has no
/// internet for ML Kit to fetch its model — and telling *that* customer to try
/// a clearer picture sends them off to take another photo that fails the same
/// way.
class PhotoSearch {
  const PhotoSearch(this.terms, {this.unavailable = false});

  /// Search terms, best first. Empty when nothing was made out.
  final List<String> terms;

  /// True when every engine that ran threw.
  final bool unavailable;

  /// Nothing could be read: no terms, and the phone could not be asked.
  static const PhotoSearch none = PhotoSearch(<String>[], unavailable: true);
}

/// Turns a photo into search terms, on the phone: the words printed on it
/// (a brand or product name on a pack) first, then what it looks like
/// ("Fruit", "Apple", "Bottle"…). The first term that finds products wins.
class VisualSearchService {
  VisualSearchService._();

  // Labels too vague to find anything useful.
  static const _tooGeneric = {
    'food',
    'ingredient',
    'product',
    'recipe',
    'cuisine',
    'dish',
    'tableware',
    'plant',
    'produce',
    'natural foods',
    'staple food',
    'whole food',
    'superfood',
    'packaging and labeling',
    'plastic',
    'material property',
    'font',
    'rectangle',
    'pattern',
    'material',
    'label',
    'text',
    'brand',
  };

  // Words printed on packs that never name a product.
  static const _packWords = {
    'net',
    'weight',
    'ingredients',
    'contains',
    'store',
    'mfg',
    'exp',
    'best',
    'before',
    'price',
    'batch',
    'manufactured',
    'packed',
    'marketed',
    'india',
    'made',
    'with',
    'from',
    'and',
    'the',
    'for',
  };

  /// Whether the phone could not run the models at all.
  ///
  /// One engine failing is normal — the labeller can fail on a photo that text
  /// recognition read perfectly well — so only "every engine that ran threw"
  /// counts as unusable. Nothing having run is not that, either.
  static bool modelUnavailable({required int ran, required int failed}) =>
      ran > 0 && failed == ran;

  /// Search terms for the picture at [path], best first. Empty — with
  /// [PhotoSearch.unavailable] set — when the phone could not read it at all.
  static Future<PhotoSearch> termsFor(String path) async {
    final terms = <String>[];
    var engines = 0;
    var failed = 0;

    try {
      final input = InputImage.fromFilePath(path);

      engines++;
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      try {
        final text = await recognizer.processImage(input);
        final words = RegExp(r'[A-Za-z][A-Za-z\-]{3,}')
            .allMatches(text.text)
            .map((m) => m.group(0)!.toLowerCase())
            .where((w) => !_packWords.contains(w))
            .toSet()
            .toList()
          ..sort((a, b) => b.length.compareTo(a.length));
        terms.addAll(words.take(6));
      } catch (e, stack) {
        failed++;
        debugPrint('Text recognition failed: $e');
        unawaited(ErrorReporter.report(e, stack, source: 'visual_search.text'));
      } finally {
        await recognizer.close();
      }

      engines++;
      final labeler = ImageLabeler(
        options: ImageLabelerOptions(confidenceThreshold: 0.55),
      );
      try {
        final labels = await labeler.processImage(input)
          ..sort((a, b) => b.confidence.compareTo(a.confidence));
        for (final label in labels) {
          final name = label.label.toLowerCase();
          if (!_tooGeneric.contains(name)) terms.add(name);
        }
      } catch (e, stack) {
        failed++;
        debugPrint('Image labelling failed: $e');
        unawaited(
          ErrorReporter.report(e, stack, source: 'visual_search.labels'),
        );
      } finally {
        await labeler.close();
      }
    } catch (e, stack) {
      debugPrint('Photo search failed: $e');
      unawaited(ErrorReporter.report(e, stack, source: 'visual_search'));
      return PhotoSearch.none;
    }

    return PhotoSearch(
      terms,
      unavailable: modelUnavailable(ran: engines, failed: failed),
    );
  }
}
