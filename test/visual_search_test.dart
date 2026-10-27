import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:duggu/services/visual_search_service.dart';

/// The photo search reads what is printed on a pack and what the picture looks
/// like, on the phone. Both engines can refuse to run the first time on a
/// device with no internet — ML Kit still has to fetch its model — and when
/// that happened the app answered "try a clearer picture", which sends the
/// customer off to take another photo that fails in exactly the same way.
///
/// These tests hold the two answers apart: nothing was found in the photo, and
/// nothing could be asked of the phone.
void main() {
  String read(String path) => File(path).readAsStringSync();

  test('the phone is only unusable when every engine that ran threw', () {
    expect(VisualSearchService.modelUnavailable(ran: 2, failed: 2), isTrue);
    expect(VisualSearchService.modelUnavailable(ran: 1, failed: 1), isTrue);
    // One engine failing is normal: the other one still read the photo.
    expect(VisualSearchService.modelUnavailable(ran: 2, failed: 1), isFalse);
    expect(VisualSearchService.modelUnavailable(ran: 2, failed: 0), isFalse);
    // Nothing ran at all is not a failed model.
    expect(VisualSearchService.modelUnavailable(ran: 0, failed: 0), isFalse);
  });

  test('an empty result can say why it is empty', () {
    expect(PhotoSearch.none.terms, isEmpty);
    expect(PhotoSearch.none.unavailable, isTrue);
    expect(const PhotoSearch(['milk']).unavailable, isFalse);
    expect(const PhotoSearch(['milk']).terms, ['milk']);
  });

  test('the service hands back the terms and the doubt together', () {
    final service = read('lib/services/visual_search_service.dart');

    expect(service, contains('Future<PhotoSearch> termsFor('));
    expect(service, contains('modelUnavailable(ran: engines, failed: failed)'));
    expect(service, contains('var engines = 0;'));
    // A failure a developer can find later, not only a debug line.
    expect(service, contains('ErrorReporter.report('));
    expect(service, contains("source: 'visual_search.text'"));
    expect(service, contains("source: 'visual_search.labels'"));
  });

  test('the screen says so when the photo could not be read at all', () {
    final screen = read('lib/screens/search_screen.dart');

    expect(screen, contains('if (result.unavailable)'));
    expect(screen, contains('for (final term in result.terms)'));
    // Both lines moved into the string files with the screen's l10n
    // migration: the keys are pinned here, the sentences in the arb.
    expect(screen, contains('l10n.searchScannerFailed'));
    expect(screen, contains('l10n.searchNoMatch'));
    final arb = read('lib/l10n/app_en.arb');
    expect(arb, contains('one-time download'));
    // The old advice is still there, but only for the photo's own fault.
    expect(arb, contains('Try a clearer picture'));
  });

  test('the seller side still waits for its model', () {
    // Background removal learned this first: it retries while ML Kit reports
    // the model as still downloading.
    final removal = read('lib/services/background_removal_service.dart');

    expect(removal, contains('modelPending'));
    expect(removal, contains("text.contains('download')"));
    expect(removal, contains('attempt < 4'));
  });
}
