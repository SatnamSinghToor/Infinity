/// The one place the app's measurements live.
///
/// Nothing here is a colour: colour is [AppTokens], because colour is the
/// only part of the look that changes between light and dark. Everything
/// below is the same in both.
///
/// `AppConstants` still holds the colours the screens were written against.
/// New code should take colour from `context.tokens` and measurements from
/// here, so a screen migrates one file at a time instead of all at once.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The spacing scale, on a 4 pt grid.
///
/// Use the named gaps at the bottom for the app's recurring rhythms so two
/// screens that both separate cards end up with the same gap.
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// The gap down the side of a screen.
  static const double gutter = lg;

  /// Between two cards in a vertical list.
  static const double listGap = md;

  /// Inside a card, between its content and its edge.
  static const double cardPadding = lg;

  /// Between a section's title and what it introduces.
  static const double sectionGap = md;
}

/// Corner radii. The sizes match what the app already draws: buttons 14,
/// cards 16, fields 12.
class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double button = 14;

  /// Fully round, for chips and pills.
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius field = BorderRadius.all(Radius.circular(md));
  static const BorderRadius action = BorderRadius.all(Radius.circular(button));
  static const BorderRadius sheet =
      BorderRadius.vertical(top: Radius.circular(xl));
}

/// Heights and padding for things you tap.
///
/// Material asks for 48 as the smallest comfortable target. The app had
/// every button at 46 with 12 of padding top and bottom, and its primary
/// actions at 50-56, which read as oversized next to the text around them.
class AppControl {
  const AppControl._();

  /// Inline and secondary buttons.
  static const double sm = 40;

  /// The standard button, and the floor for anything tappable.
  static const double md = 44;

  /// A screen's primary action.
  static const double lg = 48;

  /// Padding inside a button.
  static const EdgeInsets padding =
      EdgeInsets.symmetric(horizontal: 18, vertical: 10);
}

/// How long things move for.
class AppDurations {
  const AppDurations._();

  /// A press, a tick, a highlight.
  static const Duration fast = Duration(milliseconds: 150);

  /// A sheet, a fade, an expanding card.
  static const Duration base = Duration(milliseconds: 250);

  /// A screen change.
  static const Duration slow = Duration(milliseconds: 450);
}

/// The type scale, in the one font the app uses.
///
/// Sizes are the ones already on screen, so adopting these does not move any
/// layout: 21 is a screen title, 19 an app bar, 14.5 body copy, 12.5 the
/// smallest caption.
class AppType {
  const AppType._();

  static TextStyle get display => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  static TextStyle get title => GoogleFonts.poppins(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        height: 1.25,
      );

  static TextStyle get appBarTitle => GoogleFonts.poppins(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        height: 1.25,
      );

  static TextStyle get heading => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get body => GoogleFonts.poppins(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  static TextStyle get label => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get caption => GoogleFonts.poppins(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        height: 1.35,
      );
}

/// The colours a screen means rather than the colours it happens to use.
///
/// Registered on [ThemeData.extensions], so a screen asks for
/// `context.tokens.textPrimary` and gets the right one for whichever
/// brightness is showing, without knowing which that is.
class AppTokens extends ThemeExtension<AppTokens> {
  /// Behind everything.
  final Color surface;

  /// A band that sits on [surface] to group things: a header, a strip.
  final Color surfaceAlt;

  /// A card.
  final Color card;

  /// What a card is filled with when it holds an input.
  final Color field;

  final Color textPrimary;
  final Color textSecondary;

  /// Hairlines: card edges, dividers, field outlines.
  final Color border;

  final Color primary;
  final Color accent;
  final Color danger;
  final Color success;

  const AppTokens({
    required this.surface,
    required this.surfaceAlt,
    required this.card,
    required this.field,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.primary,
    required this.accent,
    required this.danger,
    required this.success,
  });

  /// The look the app ships with. Values are the ones the screens already
  /// draw, so adopting these changes nothing on screen.
  static const AppTokens light = AppTokens(
    surface: Color(0xFFF7F7F7),
    surfaceAlt: Color(0xFFF2F2F2),
    card: Color(0xFFFFFFFF),
    field: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF6E6E6E),
    border: Color(0xFFEBEBEB),
    primary: Color(0xFFFF6A00),
    accent: Color(0xFFF2711C),
    danger: Color(0xFFE53935),
    success: Color(0xFF43A047),
  );

  /// The same roles, for after dark. Warm near-blacks rather than pure
  /// black, so the orange still has something to sit on.
  ///
  /// Not shipped yet, on purpose: `main.dart` holds the app to light, because
  /// most screens still take their colour from `AppConstants` and would keep
  /// drawing themselves pale. The widgets that read `context.tokens` — the two
  /// nav bars, the notification bell — plus the tests are what use this
  /// palette today, and `test/theme_mode_test.dart` will not let `themeMode`
  /// go until every screen has moved over.
  static const AppTokens dark = AppTokens(
    surface: Color(0xFF141110),
    surfaceAlt: Color(0xFF1D1917),
    card: Color(0xFF1F1B19),
    field: Color(0xFF262120),
    textPrimary: Color(0xFFF4EFE8),
    textSecondary: Color(0xFFA79C90),
    border: Color(0xFF332C28),
    primary: Color(0xFFFF7A1A),
    accent: Color(0xFFFF8A3D),
    danger: Color(0xFFEF5350),
    success: Color(0xFF66BB6A),
  );

  @override
  AppTokens copyWith({
    Color? surface,
    Color? surfaceAlt,
    Color? card,
    Color? field,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? primary,
    Color? accent,
    Color? danger,
    Color? success,
  }) {
    return AppTokens(
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      card: card ?? this.card,
      field: field ?? this.field,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
      danger: danger ?? this.danger,
      success: success ?? this.success,
    );
  }

  @override
  AppTokens lerp(covariant AppTokens? other, double t) {
    if (other == null) return this;
    return AppTokens(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      card: Color.lerp(card, other.card, t)!,
      field: Color.lerp(field, other.field, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

/// So a screen can write `context.tokens.card` instead of reaching into
/// [Theme.of] and casting.
extension AppTokensX on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ?? AppTokens.light;
}
