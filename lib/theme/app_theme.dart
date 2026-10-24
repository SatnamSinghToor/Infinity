import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/constants.dart';
import '../utils/tokens.dart';

/// The one text look for buttons that are not the solid primary button:
/// Poppins, medium (not semibold — Poppins runs heavy, so the button
/// labels read fat with anything above w500), ~14pt.
final TextStyle _buttonTextStyle = GoogleFonts.poppins(
  fontWeight: FontWeight.w500,
  fontSize: 14.5,
);

/// The shared frame of every input border: same radius, so the field looks
/// identical in every state.
const OutlineInputBorder _fieldBorder = OutlineInputBorder(
  borderRadius: AppRadius.field,
);

/// Builds the app's [ThemeData]: orange primary actions, quiet secondary
/// controls, and the field/hover styling shared by every screen.
ThemeData buildAppTheme() {
  final baseTextTheme = GoogleFonts.poppinsTextTheme();
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppConstants.primaryColor,
    primary: AppConstants.primaryColor,
    secondary: AppConstants.accentColor,
  );

  return ThemeData(
    useMaterial3: true,
    // The registered family (pubspec fonts:) — one family, every real face.
    // A plain bold TextStyle inheriting a single-face google_fonts variant
    // family would otherwise be faked bold by the engine and draw fat
    // synthetic strokes.
    fontFamily: 'Poppins',
    colorScheme: colorScheme,
    extensions: const [AppTokens.light],
    scaffoldBackgroundColor: AppConstants.backgroundColor,
    textTheme: baseTextTheme.apply(
      bodyColor: AppConstants.textPrimaryColor,
      displayColor: AppConstants.textPrimaryColor,
      // Same reason: keep the whole default typography on the one family.
      fontFamily: 'Poppins',
      fontFamilyFallback: const ['Poppins'],
    ),
    // Every screen's header matches the content below it.
    appBarTheme: AppBarTheme(
      backgroundColor: AppConstants.backgroundColor,
      foregroundColor: AppConstants.textPrimaryColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(
        color: AppConstants.textPrimaryColor,
      ),
      actionsIconTheme: const IconThemeData(
        color: AppConstants.textPrimaryColor,
      ),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: AppConstants.textPrimaryColor,
      ),
    ),
    // One slide-in transition everywhere, so screens opened from Home
    // feel like part of the same app.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppConstants.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    // Filled actions carry the brand color. Secondary actions stay neutral
    // so an outlined or text button does not compete with the main CTA.
    elevatedButtonTheme: ElevatedButtonThemeData(style: _primaryButton()),
    filledButtonTheme: FilledButtonThemeData(style: _primaryButton()),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppConstants.textPrimaryColor,
        side: const BorderSide(
          color: AppConstants.cardBorder,
          width: 1,
        ),
        minimumSize: const Size(64, AppControl.md),
        padding: AppControl.padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: _buttonTextStyle,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppConstants.textPrimaryColor,
        textStyle: _buttonTextStyle,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppConstants.textSecondaryColor,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppConstants.cardColor,
      hintStyle: GoogleFonts.poppins(
        color: AppConstants.textSecondaryColor.withOpacity(0.78),
        fontSize: 13.5,
      ),
      labelStyle: GoogleFonts.poppins(
        color: AppConstants.textSecondaryColor,
        fontSize: 13.5,
      ),
      floatingLabelStyle: GoogleFonts.poppins(
        color: AppConstants.primaryColor,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
      border: _fieldBorder.copyWith(
        borderSide: const BorderSide(color: Color(0xFFEBEBEB)),
      ),
      enabledBorder: _fieldBorder.copyWith(
        borderSide: const BorderSide(color: Color(0xFFEBEBEB)),
      ),
      focusedBorder: _fieldBorder.copyWith(
        borderSide: const BorderSide(
          color: AppConstants.primaryColor,
          width: 1.5,
        ),
      ),
      errorBorder: _fieldBorder.copyWith(
        borderSide: const BorderSide(color: AppConstants.dangerColor),
      ),
      focusedErrorBorder: _fieldBorder.copyWith(
        borderSide: const BorderSide(
          color: AppConstants.dangerColor,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    ),
  );
}

/// The primary button look: solid brand orange, white text, rounded.
ButtonStyle _primaryButton() => ElevatedButton.styleFrom(
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: Colors.white,
      disabledBackgroundColor: const Color(0xFFE4E6E8),
      disabledForegroundColor: AppConstants.textSecondaryColor,
      elevation: 0,
      minimumSize: const Size(64, AppControl.md),
      padding: AppControl.padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w500,
        fontSize: 14.5,
      ),
    );
