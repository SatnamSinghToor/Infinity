import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The Festival chip used to sit in the Home strip all year, leading to an
/// empty-feeling page most of the time. These pins keep it tied to the
/// festival calendar's own near-window instead of always showing.
void main() {
  test('the strip is built from the near-window list, not the fixed one', () {
    final src = File('lib/screens/home_screen.dart').readAsStringSync();
    expect(src, contains('List<HomeChip> get _visibleChips'));
    expect(src, contains('if (_festivalNear) return homeChips;'));
    expect(src, contains('itemCount: chips.length + 1,'));
    // The minute clock (already ticking for the night theme) also notices
    // the exact day the window opens or closes, not just when something
    // else happens to trigger a rebuild.
    expect(src, contains('near != _festivalNear'));
  });
}
