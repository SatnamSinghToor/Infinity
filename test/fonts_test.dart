import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:duggu/utils/app_fonts.dart';

/// The fonts ship inside the app and the package is forbidden to download
/// one — which is only safe while every face the code asks for is really in
/// the bundle. A weight without its file would not fail a build; it would
/// quietly draw in the system font on every customer's phone. So the test
/// reads the code the way the package does and checks the folder.
void main() {
  // How google_fonts names the file for a weight (`Poppins-SemiBold.ttf`).
  const parts = {
    100: 'Thin',
    200: 'ExtraLight',
    300: 'Light',
    400: 'Regular',
    500: 'Medium',
    600: 'SemiBold',
    700: 'Bold',
    800: 'ExtraBold',
    900: 'Black',
  };
  // The getter the code calls, and the family the package files it under.
  const families = {
    'poppins': 'Poppins',
    'playfairDisplay': 'PlayfairDisplay',
  };

  String fileFor(String family, int weight, bool italic) {
    var part = parts[weight]!;
    if (italic) part = part == 'Regular' ? 'Italic' : '${part}Italic';
    return '${AppFonts.directory}/$family-$part.ttf';
  }

  /// Every (family, weight, italic) the code asks google_fonts for.
  Set<String> facesUsedInLib() {
    final faces = <String>{};
    final call = RegExp(r'GoogleFonts\.([a-zA-Z]+?)(TextTheme)?\(');
    final weightToken = RegExp(r'FontWeight\.(w[1-9]00|bold|normal)\b');
    const named = {'bold': 700, 'normal': 400};
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // The helper warms weights from a list; the next test reads that list.
      if (entity.path.endsWith('app_fonts.dart')) continue;
      final src = entity.readAsStringSync();
      for (final m in call.allMatches(src)) {
        final family = families[m.group(1)];
        if (family == null) {
          fail('${entity.path}: GoogleFonts.${m.group(1)} is not a family '
              'the app bundles');
        }
        if (m.group(2) != null) {
          // A text theme: regular and medium, as Material's defaults are.
          faces.add(fileFor(family, 400, false));
          faces.add(fileFor(family, 500, false));
          continue;
        }
        // The call's arguments, up to the parenthesis that closes it.
        var depth = 1;
        var i = m.end;
        while (i < src.length && depth > 0) {
          if (src[i] == '(') depth++;
          if (src[i] == ')') depth--;
          i++;
        }
        final body = src.substring(m.end, i - 1);
        expect(body.contains('textStyle:'), isFalse,
            reason: '${entity.path}: a textStyle passed to GoogleFonts may '
                'carry a weight this test cannot see — ask for the weight '
                'explicitly');
        final italic = body.contains('FontStyle.italic');
        final weights = <int>{};
        for (final w in weightToken.allMatches(body)) {
          final token = w.group(1)!;
          weights.add(named[token] ?? int.parse(token.substring(1)));
        }
        if (body.contains('fontWeight:')) {
          expect(weights, isNotEmpty,
              reason: '${entity.path}: a fontWeight this test cannot read; '
                  'write the FontWeight values in the call');
        }
        if (weights.isEmpty) weights.add(400);
        for (final weight in weights) {
          faces.add(fileFor(family, weight, italic));
        }
      }
    }
    return faces;
  }

  test('every face the code asks for is in the bundle', () {
    final faces = facesUsedInLib();
    expect(faces, isNotEmpty);
    for (final face in faces) {
      expect(File(face).existsSync(), isTrue, reason: '$face is missing');
    }
  });

  test('the first frame warms faces that exist', () {
    for (final weight in AppFonts.firstFrameWeights) {
      final face = fileFor('Poppins', weight.value, false);
      expect(File(face).existsSync(), isTrue, reason: face);
    }
  });

  test('the bundled files are real fonts, not pointers', () {
    final files = Directory(AppFonts.directory)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.ttf'))
        .toList();
    expect(files, isNotEmpty);
    for (final file in files) {
      final handle = file.openSync();
      final head = handle.readSync(4);
      handle.closeSync();
      expect(head, [0, 1, 0, 0], reason: '${file.path} is not TrueType');
      expect(file.lengthSync(), greaterThan(50 * 1024), reason: file.path);
    }
  });

  test('the folder is an asset and the package may not go online', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- ${AppFonts.directory}/'));

    final fonts = File('lib/utils/app_fonts.dart').readAsStringSync();
    expect(fonts, contains('allowRuntimeFetching = false'));
    expect(File('lib/main.dart').readAsStringSync(),
        contains('await AppFonts.prepare()'));
  });

  test('each family ships its licence and files it', () {
    for (final entry in AppFonts.licences.entries) {
      final text = File(entry.value).readAsStringSync();
      expect(text, contains('SIL Open Font License'), reason: entry.key);
    }
    expect(File('lib/utils/app_fonts.dart').readAsStringSync(),
        contains('LicenseRegistry.addLicense'));
  });
}
