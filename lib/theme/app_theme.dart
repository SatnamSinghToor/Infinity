import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/constants.dart';
import '../utils/tokens.dart';

/// The one text look for buttons that are not the solid primary button:
/// Poppins, semibold, 14pt.
final TextStyle _buttonTextStyle = GoogleFonts.poppins(
  fontWeight: FontWeight.w600,
  fontSize: 14,
);

/// The shared frame of every input border: same radius, so the field looks
/// identical in every state.
const OutlineInputBorder _fieldBorder = OutlineInputBorder(
  borderRadius: AppRadius.field,
);

/// Builds the app's [ThemeData]: Poppins type, one orange button look, and
/// the field/hover styling shared by every screen.
ThemeData buildAppTheme() {
  final baseTextTheme = GoogleFonts.poppinsTextTheme();
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppConstants.primaryColor,
    primary: AppConstants.primaryColor,
    secondary: AppConstants.accentColor,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    extensions: const [AppTokens.light],
    scaffoldBackgroundColor: AppConstants.backgroundColor,
    textTheme: baseTextTheme.apply(
      bodyColor: AppConstants.textPrimaryColor,
      displayColor: AppConstants.textPrimaryColor,
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
        fontWeight: FontWeight.w700,
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
    cardTheme: CardTheme(
      elevation: 0,
      color: AppConstants.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    // Every button in the app is the same orange, with the same shape.
    // (Only buttons that delete or reject something are red, set where
    // they are used.)
    elevatedButtonTheme: ElevatedButtonThemeData(style: _primaryButton()),
    filledButtonTheme: FilledButtonThemeData(style: _primaryButton()),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppConstants.primaryColor,
        side: const BorderSide(
          color: AppConstants.primaryColor,
          width: 1.4,
        ),
        minimumSize: const Size(64, AppControl.md),
        padding: AppControl.padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: _buttonTextStyle,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppConstants.primaryColor,
        textStyle: _buttonTextStyle,
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

/// The one button look: solid orange, white text, rounded.
ButtonStyle _primaryButton() => ElevatedButton.styleFrom(
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: Colors.white,
      disabledBackgroundColor:
          AppConstants.primaryColor.withOpacity(0.35),
      disabledForegroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size(64, AppControl.md),
      padding: AppControl.padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 14.5,
      ),
    );
