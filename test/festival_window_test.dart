import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duggu/models/festival.dart';

Festival _festival({required DateTime start, required DateTime end}) {
  return Festival(
    chipLabel: 'Diwali',
    kicker: 'CELEBRATE',
    title: 'Diwali',
    start: start,
    end: end,
    colorFrom: const Color(0xFFFFD9A8),
    colorTo: const Color(0xFFFFF1DE),
    accent: const Color(0xFFC4531A),
  );
}

void main() {
  // A one-day festival on the 15th, for a stable, easy-to-reason-about
  // midpoint — every check below is stated as an offset from it.
  final f = _festival(
    start: DateTime(2026, 3, 15),
    end: DateTime(2026, 3, 15),
  );

  group('isNear', () {
    test('the festival\'s own day is near', () {
      expect(f.isNear(DateTime(2026, 3, 15)), isTrue);
    });

    test('exactly 7 days before is still near', () {
      expect(f.isNear(DateTime(2026, 3, 8)), isTrue);
    });

    test('exactly 7 days after is still near', () {
      expect(f.isNear(DateTime(2026, 3, 22)), isTrue);
    });

    test('8 days before is not near', () {
      expect(f.isNear(DateTime(2026, 3, 7)), isFalse);
    });

    test('8 days after is not near', () {
      expect(f.isNear(DateTime(2026, 3, 23)), isFalse);
    });

    test('a custom window is honoured', () {
      expect(f.isNear(DateTime(2026, 3, 12), days: 2), isFalse);
      expect(f.isNear(DateTime(2026, 3, 13), days: 2), isTrue);
    });

    test('a multi-day festival stays near across its own span', () {
      final multi = _festival(
        start: DateTime(2026, 3, 15),
        end: DateTime(2026, 3, 18),
      );
      expect(multi.isNear(DateTime(2026, 3, 16)), isTrue);
      expect(multi.isNear(DateTime(2026, 3, 8)), isTrue);
      expect(multi.isNear(DateTime(2026, 3, 25)), isTrue);
      expect(multi.isNear(DateTime(2026, 3, 26)), isFalse);
    });
  });
}
