import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// The app's type used to arrive over the network. `google_fonts` downloads
/// a face the first time it is asked for, so the first screen drew in the
/// system font and snapped to Poppins a moment later — and a phone with no
/// internet never got Poppins at all.
///
/// The faces the app uses now ship inside it, in `assets/fonts/`, named the
/// way the package looks them up (`Poppins-SemiBold.ttf`,
/// `PlayfairDisplay-BoldItalic.ttf`). Every `GoogleFonts.poppins(...)` call
/// stays as it is; the package simply finds the file on disk and never goes
/// online — [prepare] forbids it to, so a face that is missing from the bundle
/// shows up as the system font in development instead of a download in
/// production. `test/fonts_test.dart` checks that every weight the code asks
/// for has its file.
class AppFonts {
  AppFonts._();

  /// Where the font files and their licences live.
  static const String directory = 'assets/fonts';

  /// The licences of the bundled faces. Both are the SIL Open Font License,
  /// which asks for exactly this: ship the licence with the font.
  static const Map<String, String> licences = {
    'Poppins': '$directory/OFL-Poppins.txt',
    'Playfair Display': '$directory/OFL-PlayfairDisplay.txt',
  };

  /// The faces the first frame needs: the text theme (regular and medium) and
  /// the splash (semi-bold and bold). The rest load on first use, from disk,
  /// well inside a frame.
  static const List<FontWeight> firstFrameWeights = [
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w600,
  ];

  /// Longest a launch will wait for the fonts. They come from the asset
  /// bundle, so this is a safety net, not an expectation.
  static const Duration patience = Duration(seconds: 3);

  /// Keeps the fonts on the device, files their licences, and has the first
  /// frame's faces loaded before it is drawn. Never throws: a font is not
  /// worth failing a launch over.
  static Future<void> prepare() async {
    GoogleFonts.config.allowRuntimeFetching = false;

    LicenseRegistry.addLicense(() async* {
      for (final entry in licences.entries) {
        final text = await rootBundle.loadString(entry.value);
        yield LicenseEntryWithLineBreaks([entry.key], text);
      }
    });

    try {
      final faces = [
        for (final weight in firstFrameWeights)
          GoogleFonts.poppins(fontWeight: weight),
      ];
      await GoogleFonts.pendingFonts(faces).timeout(patience);
    } catch (e) {
      // The screen draws in the system font until the face arrives; the
      // package has already said which file it wanted.
      debugPrint('Fonts were not ready for the first frame: $e');
    }
  }
}
