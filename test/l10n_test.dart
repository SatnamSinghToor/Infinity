import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The app's strings live in `lib/l10n/app_en.arb`, and `flutter pub get`
/// generates `AppLocalizations` from it. The wire is only useful while it
/// stays plugged in, so these tests fail when a widget asks for a string the
/// English file does not have, when the generated class stops being installed
/// for the whole app, or when user-facing words creep back into the widget
/// that draws the bottom bar.
void main() {
  String read(String path) => File(path).readAsStringSync();

  Map<String, dynamic> arb() =>
      jsonDecode(read('lib/l10n/app_en.arb')) as Map<String, dynamic>;

  /// The string keys, without the `@name` description entries beside them.
  Set<String> keys() => arb().keys.where((k) => !k.startsWith('@')).toSet();

  test('every string the app asks for is in the English file', () {
    final used = <String, List<String>>{};
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final source = file.readAsStringSync();
      for (final match in RegExp(r'\bl10n\.(\w+)').allMatches(source)) {
        used.putIfAbsent(match.group(1)!, () => []).add(file.path);
      }
    }

    expect(used, isNotEmpty, reason: 'no screen reads a string yet');
    for (final entry in used.entries) {
      expect(
        keys(),
        contains(entry.key),
        reason: 'l10n.${entry.key} is used in ${entry.value.join(', ')}',
      );
    }
  });

  test('the bottom bar takes its labels from the string files', () {
    final nav = read('lib/widgets/bottom_nav.dart');

    for (final key in ['navHome', 'navCategories', 'navCart', 'navProfile']) {
      expect(nav, contains('l10n.$key'), reason: key);
    }
    expect(nav, contains('AppLocalizations.of(context)'));
    // The words themselves belong in the .arb, not in the widget.
    expect(nav, isNot(contains("label: 'Home'")));
  });

  test('the generated strings are installed for the whole app', () {
    final main = read('lib/main.dart');

    expect(main, contains('localizationsDelegates:'));
    expect(main, contains('AppLocalizations.localizationsDelegates'));
    expect(
      main,
      contains('supportedLocales: AppLocalizations.supportedLocales'),
    );
    expect(main, contains('package:duggu/l10n/app_localizations.dart'));

    final config = read('l10n.yaml');
    expect(config, contains('arb-dir: lib/l10n'));
    expect(config, contains('template-arb-file: app_en.arb'));

    expect(read('pubspec.yaml'), contains('generate: true'));
    expect(read('pubspec.yaml'), contains('flutter_localizations:'));
  });

  test('every English string carries a description for translators', () {
    for (final key in keys()) {
      expect(
        arb()['@$key'],
        isA<Map>(),
        reason: 'no "@$key" description',
      );
    }
  });

  test('the English file is a json object that names its locale', () {
    expect(arb()['@@locale'], 'en');
  });
}
