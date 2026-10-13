# Working on DUGGUSTORE

## Dead code goes as you go

The owner asked for this explicitly: whatever a change leaves unused is
deleted in the same change, not left behind. After every change, look for
and remove:

- Dart files nothing imports any more.
- Classes, functions, fields and constants nothing refers to (extensions
  such as `context.tokens`, `safeSetState` and `ListingSort.label` are used
  by their members, not their names — they stay).
- Strings in `lib/l10n/app_en.arb` (and their `@` entries) no code asks for.
- Asset files nothing loads, and their `pubspec.yaml` lines. Fonts in
  `assets/fonts/` are found by name by `google_fonts`; they stay.

When a test only lists a thing that is gone (like the colour names in
`test/theme_mode_test.dart`), take it out of the test too.

## Before pushing

`dart format lib test`, `flutter analyze` (keep it at 0 issues), and
`flutter test` must all pass.
