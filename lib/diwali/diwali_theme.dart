import 'package:flutter/material.dart';

/// The palette sampled from the reference screens. Keeping it in one place
/// means a colour change is a single edit and every widget stays in sync.
class DiwaliColors {
  const DiwaliColors._();

  static const Color wine950 = Color(0xFF3B0014);
  static const Color wine900 = Color(0xFF4B001A);
  static const Color wine800 = Color(0xFF5C0022);
  static const Color wine700 = Color(0xFF6B002A);
  static const Color wine600 = Color(0xFF790131);
  static const Color wine500 = Color(0xFF8B0A3C);
  static const Color berry = Color(0xFF9E004D);
  static const Color magenta = Color(0xFFA80B4B);
  static const Color plum = Color(0xFF741030);

  static const Color cream = Color(0xFFFBF9ED);
  static const Color cream2 = Color(0xFFFFF8E9);
  static const Color cream3 = Color(0xFFFFF1CC);
  static const Color cream4 = Color(0xFFFEF4DB);
  static const Color white = Colors.white;

  static const Color ink = Color(0xFF1B1B1B);
  static const Color ink2 = Color(0xFF3B3B3B);
  static const Color muted = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEE9DC);

  static const Color yellow = Color(0xFFFFF200);
  static const Color green = Color(0xFF0C831F);
  static const Color greenSoft = Color(0xFFE8F6E9);
  static const Color greenBorder = Color(0xFF8FD3A0);
  static const Color blue = Color(0xFF0A72C6);
  static const Color gold = Color(0xFFE2A83E);
  static const Color zomato = Color(0xFFE23744);
  static const Color tileTop = Color(0xFFA8531F);
  static const Color tileMid = Color(0xFF8E3A16);
  static const Color tileBottom = Color(0xFF6E2A11);

  /// The dark hero's layered background. Written as a factory so the widget
  /// tree stays declarative (no mutable global gradient instance).
  static LinearGradient get heroGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [wine800, wine600, wine900],
        stops: [0.0, 0.45, 1.0],
      );

  static LinearGradient get tileGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [tileTop, tileMid, tileBottom],
        stops: [0.0, 0.55, 1.0],
      );

  static LinearGradient get deepBanner => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF8E0A3F), Color(0xFF7A0636)],
      );

  static LinearGradient get creamBanner => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF7E1), Color(0xFFFEF1D5)],
      );

  static RadialGradient get heroGlow => const RadialGradient(
        center: Alignment(0, -0.7),
        radius: 1.1,
        colors: [Color(0x8CAE0049), Color(0x00AE0049)],
      );
}

/// Text styles. The app already bundles Poppins with real faces for every
/// weight; `DiwaliSerif` and `DiwaliDisplay` are registered in pubspec.yaml.
class DiwaliText {
  const DiwaliText._();

  static const String ui = 'Poppins';
  static const String serif = 'DiwaliSerif';
  static const String display = 'DiwaliDisplay';

  static TextStyle body(
    double size, {
    Color color = DiwaliColors.ink,
    FontWeight weight = FontWeight.w400,
    double? height,
    double letterSpacing = 0,
    TextDecoration? decoration,
  }) =>
      TextStyle(
        fontFamily: ui,
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        decoration: decoration,
      );

  static TextStyle serifStyle(
    double size, {
    Color color = DiwaliColors.wine600,
    bool italic = false,
    double letterSpacing = 0,
  }) =>
      TextStyle(
        fontFamily: serif,
        // The display faces are Latin subsets; anything outside them (notably
        // ₹) falls through to the bundled Poppins family, which has it.
        fontFamilyFallback: const <String>[ui],
        fontSize: size,
        color: color,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        letterSpacing: letterSpacing,
      );

  static TextStyle displayStyle(
    double size, {
    Color color = const Color(0xFFFFF0C9),
  }) =>
      TextStyle(
        fontFamily: display,
        fontFamilyFallback: const <String>[ui],
        fontSize: size,
        color: color,
        letterSpacing: 1,
        shadows: const [
          Shadow(color: Color(0x44000000), blurRadius: 18, offset: Offset(0, 4)),
        ],
      );

  static const TextStyle eyebrow = TextStyle(
    fontFamily: ui,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.4,
    color: Color(0xFF7A2C45),
  );

  static const TextStyle rupeeFallback = TextStyle(fontFamily: ui);
}

/// Breakpoint-aware measurements. One instance per build; cheap and immutable.
enum DiwaliBreakpoint { compact, medium, expanded }

class DiwaliLayout {
  const DiwaliLayout(this.width);

  final double width;

  DiwaliBreakpoint get breakpoint {
    if (width >= 1024) return DiwaliBreakpoint.expanded;
    if (width >= 600) return DiwaliBreakpoint.medium;
    return DiwaliBreakpoint.compact;
  }

  bool get isCompact => breakpoint == DiwaliBreakpoint.compact;
  bool get isExpanded => breakpoint == DiwaliBreakpoint.expanded;

  static const double maxContent = 1180;

  double get contentWidth => width < maxContent ? width : maxContent;

  double get pad {
    if (isExpanded) return 34;
    if (isCompact) return 16;
    return 24;
  }

  double get sectionPadTop {
    if (isExpanded) return 38;
    if (isCompact) return 22;
    return 30;
  }

  /// Number of hero tiles per row.
  int get tileColumns => isExpanded ? 6 : 3;

  int get diamondColumns => isExpanded ? 8 : 4;

  int get squareTileColumns => 4;

  /// Visible product cards in a carousel at rest (a sliver of the next one
  /// peeks in, so the row reads as scrollable).
  double get railFraction {
    if (isExpanded) return 0.184;
    if (breakpoint == DiwaliBreakpoint.medium) return 0.30;
    return 0.45;
  }

  double get archFraction {
    if (isExpanded) return 0.23;
    if (breakpoint == DiwaliBreakpoint.medium) return 0.30;
    return 0.44;
  }

  double get brandFraction {
    if (isExpanded) return 0.22;
    if (breakpoint == DiwaliBreakpoint.medium) return 0.28;
    return 0.43;
  }

  double railItemWidth(double available) =>
      (available * railFraction).clamp(140.0, 230.0);

  double archItemWidth(double available) =>
      (available * archFraction).clamp(150.0, 280.0);

  double brandItemWidth(double available) =>
      (available * brandFraction).clamp(160.0, 280.0);

  double get displayTitle {
    if (isExpanded) return 46;
    if (isCompact) return 30;
    return 38;
  }

  double get heroWord {
    if (isExpanded) return 86;
    // Rozha One is a wide display face: 56 px overruns a 360 px phone once
    // the two sparkles and their gaps are added.
    if (isCompact) return 44;
    return 68;
  }

  double get sectionTitle {
    if (isExpanded) return 25;
    if (isCompact) return 19;
    return 22;
  }

  double get sectionSub => isExpanded ? 14 : 13;

  double get deliveryTime {
    if (isExpanded) return 34;
    if (isCompact) return 28;
    return 32;
  }

  double get tabLabel => isCompact ? 11 : 12;

  double get tileLabel => isCompact ? 12.5 : 15;

  bool get showRailArrows => !isCompact;
  bool get showBrandLine => !isCompact;

  /// Height of the collapsed light header that pins while scrolling.
  double get stickyHeaderHeight => isCompact ? 118 : 142;

  /// Rough height of the whole dark hero, used to fade the pinned header in.
  double get heroHeight {
    if (isExpanded) return 760;
    if (isCompact) return 900;
    return 960;
  }
}

/// Small shared geometry.
class DiwaliRadius {
  const DiwaliRadius._();

  static const double small = 8;
  static const double medium = 14;
  static const double large = 22;

  static BorderRadius get card => BorderRadius.circular(small);
  static BorderRadius get panel => BorderRadius.circular(medium);
}

/// Durations used by hover, reveal and stepper animations.
class DiwaliMotion {
  const DiwaliMotion._();

  static const Duration hover = Duration(milliseconds: 220);
  static const Duration reveal = Duration(milliseconds: 560);
  static const Duration quick = Duration(milliseconds: 180);
  static const Curve curve = Curves.easeOutCubic;
}
