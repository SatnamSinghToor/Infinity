import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:duggu/utils/constants.dart';
import 'package:duggu/utils/tokens.dart';

/// The app ships one look: light.
///
/// `AppTokens.dark` is a real palette, and the widgets that already read
/// `context.tokens` — the two nav bars, the notification bell — would take
/// their colour from it. But most screens still name their colours through
/// `AppConstants`, so following the system into dark today would leave half a
/// screen dark and half of it pale.
///
/// That is a decision, not an accident, so these tests hold it in place: the
/// two palettes may not drift apart while both are in use, the pile of screens
/// naming their own colours may only shrink, and `ThemeMode.light` may not go
/// away while any of them are left.
void main() {
  String read(String path) => File(path).readAsStringSync();

  /// The `AppConstants` members that are colours (or gradients). The rest of
  /// that class — the app's name, its tagline — is not a reason to hold the
  /// theme back.
  const colourNames = [
    'primaryColor',
    'accentColor',
    'blackColor',
    'backgroundColor',
    'cardColor',
    'textPrimaryColor',
    'textSecondaryColor',
    'dangerColor',
    'successColor',
    'headerGradient',
  ];

  final colourPattern = RegExp('AppConstants\\.(${colourNames.join('|')})\\b');

  /// Every file in `lib/` that still draws itself with those colours.
  Set<String> filesNamingColours() => {
        for (final file in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .where((f) => colourPattern.hasMatch(f.readAsStringSync())))
          file.path.replaceAll(r'\', '/'),
      };

  test('the light palette and the constants agree while both are drawn', () {
    // A screen that reads tokens sits next to screens that read
    // AppConstants, so in the look the app ships the two must be the same
    // colour — otherwise migrating one screen changes it on screen.
    expect(AppTokens.light.surface, AppConstants.backgroundColor);
    expect(AppTokens.light.card, AppConstants.cardColor);
    expect(AppTokens.light.field, AppConstants.cardColor);
    expect(AppTokens.light.textPrimary, AppConstants.textPrimaryColor);
    expect(AppTokens.light.textSecondary, AppConstants.textSecondaryColor);
    expect(AppTokens.light.primary, AppConstants.primaryColor);
    expect(AppTokens.light.accent, AppConstants.accentColor);
    expect(AppTokens.light.danger, AppConstants.dangerColor);
    expect(AppTokens.light.success, AppConstants.successColor);
  });

  test('the dark palette is a different look, not a copy', () {
    expect(AppTokens.dark.surface, isNot(AppTokens.light.surface));
    expect(AppTokens.dark.card, isNot(AppTokens.light.card));
    expect(AppTokens.dark.textPrimary, isNot(AppTokens.light.textPrimary));
  });

  /// How many files still name their own colours. Lower this whenever one
  /// moves to `context.tokens`; it may never go up — that is what stops new
  /// screens from adding to the pile.
  const backlog = 79;

  test('the pile of screens naming their own colours only shrinks', () {
    final files = filesNamingColours();
    final over = files.toList()..sort();

    expect(
      files.length,
      lessThanOrEqualTo(backlog),
      reason: 'backlog is $backlog, ${files.length} files name colours: $over',
    );
  });

  test('dark cannot ship while any of them are left', () {
    final pinnedToLight =
        read('lib/main.dart').contains('themeMode: ThemeMode.light');
    final files = filesNamingColours();
    final left = files.toList()..sort();

    if (pinnedToLight) {
      expect(
        files,
        isNotEmpty,
        reason: 'nothing left to migrate — flip the theme mode and delete '
            'this guard',
      );
    } else {
      expect(
        files,
        isEmpty,
        reason: 'the app would follow the system into dark, but these files '
            'still draw their own colours: $left',
      );
    }
  });
}
