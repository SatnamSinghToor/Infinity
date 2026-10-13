import 'package:flutter_test/flutter_test.dart';

import 'package:duggu/utils/search_match.dart';

void main() {
  group('levenshtein', () {
    test('identical words are zero apart', () {
      expect(levenshtein('maggi', 'maggi'), 0);
    });

    test('one substitution is one apart', () {
      expect(levenshtein('meggi', 'maggi'), 1);
    });

    test('one missing letter is one apart', () {
      expect(levenshtein('mag', 'maggi'), 2);
    });
  });

  group('wordMatches', () {
    test('an exact word matches', () {
      expect(wordMatches('maggi', 'maggi 2-minute noodles'), isTrue);
    });

    test('a prefix matches', () {
      expect(wordMatches('mag', 'maggi'), isTrue);
    });

    test('a one-letter typo on a long-enough word still matches', () {
      expect(wordMatches('meggi', 'maggi'), isTrue);
    });

    test('a short word does not fuzzy-match — only an exact hit counts', () {
      // "tea" is 3 letters, under the fuzzy-match floor, so it must not
      // match "toa" (a different, unrelated word) just because it is close.
      expect(wordMatches('tea', 'toa'), isFalse);
    });

    test('an unrelated word does not match', () {
      expect(wordMatches('shampoo', 'maggi'), isFalse);
    });

    test('too many differences do not match', () {
      // "xyzzy" vs "maggi": both 5 letters but share almost nothing, well
      // past the two-edit budget for a 5-letter word.
      expect(wordMatches('xyzzy', 'maggi'), isFalse);
    });
  });

  group('fieldScore', () {
    test('an exact field match scores highest', () {
      expect(fieldScore('maggi', 'Maggi'), 4);
    });

    test('a prefix scores below an exact match', () {
      final prefix = fieldScore('mag', 'Maggi Noodles');
      final exact = fieldScore('maggi', 'Maggi');
      expect(prefix, greaterThan(0));
      expect(prefix, lessThan(exact));
    });

    test('a typo still scores, but below a clean match', () {
      final typo = fieldScore('meggi', 'Maggi Noodles');
      final clean = fieldScore('maggi', 'Maggi Noodles');
      expect(typo, greaterThan(0));
      expect(typo, lessThan(clean));
    });

    test('no match scores zero', () {
      expect(fieldScore('shampoo', 'Maggi Noodles'), 0);
    });

    test('an empty field scores zero', () {
      expect(fieldScore('maggi', null), 0);
      expect(fieldScore('maggi', ''), 0);
    });
  });

  group('nearestTerms', () {
    test('finds the closest word to a typo', () {
      final out = nearestTerms('meggi', ['Maggi', 'Milk', 'Bread']);
      expect(out, contains('Maggi'));
    });

    test('an unrelated query gets no suggestion', () {
      expect(nearestTerms('xyzzyplugh', ['Maggi', 'Milk', 'Bread']), isEmpty);
    });

    test('an empty query gets no suggestion', () {
      expect(nearestTerms('', ['Maggi']), isEmpty);
    });

    test('duplicates in the vocabulary are not repeated', () {
      final out = nearestTerms('milk', ['Milk', 'milk', 'MILK', 'Bread']);
      expect(out.where((t) => t.toLowerCase() == 'milk').length, 1);
    });

    test('closer words come first', () {
      // "mailk" is one edit from "milk" and further from "silk".
      final out = nearestTerms('mailk', ['silk', 'milk']);
      expect(out.first, 'milk');
    });
  });
}
