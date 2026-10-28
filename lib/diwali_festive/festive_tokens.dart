import 'package:flutter/material.dart';

/// Palette, type scale, layout metrics and motion tokens for the Diwali
/// storefront.
///
/// Every colour below was sampled from the reference screenshot (a 360 dp
/// wide Android capture), so a single edit here re-skins the whole screen.
/// The banner, the arch tiles and the bottom bar keep their festive maroon /
/// terracotta / gold identity in both themes; only the *content* surfaces
/// (the white section under the banner, cards and the nav bar) flip, which is
/// why dark mode still reads as "Diwali" instead of a grey night mode.
class FestiveColors {
  const FestiveColors._();

  // --- Header (the strip behind the address and search bar) ---------------
  static const Color headerTop = Color(0xFF4C0010);
  static const Color headerBottom = Color(0xFF600020);

  // --- Festival banner ----------------------------------------------------
  static const Color bannerGlow = Color(0xFF9A0046);
  static const Color bannerTop = Color(0xFF7E0034);
  static const Color bannerMid = Color(0xFF790132);
  static const Color bannerEdge = Color(0xFF6E012A);

  // --- Festive accents ----------------------------------------------------
  static const Color gold = Color(0xFFF5D69C);
  static const Color goldDeep = Color(0xFFE9B463);
  static const Color goldLine = Color(0xFFE0A64B);
  static const Color bulb = Color(0xFFFFF3D6);
  static const Color pink = Color(0xFFFC84A1);

  // --- Arch tiles ---------------------------------------------------------
  static const Color tileTop = Color(0xFFC07440);
  static const Color tileBottom = Color(0xFF9C4C27);
  static const Color tileBorder = Color(0xFFD2822B);

  // --- Content surfaces (light) ------------------------------------------
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFFAF6F2);
  static const Color ink = Color(0xFF333333);
  static const Color inkSoft = Color(0xFF6B6B6B);
  static const Color hairline = Color(0xFFEDE7E1);

  // --- Content surfaces (dark) -------------------------------------------
  static const Color surfaceDark = Color(0xFF150A10);
  static const Color surfaceSoftDark = Color(0xFF23131C);
  static const Color inkDark = Color(0xFFF6EEE7);
  static const Color inkSoftDark = Color(0xFFB9A6AE);
  static const Color hairlineDark = Color(0xFF34222C);

  // --- Commerce -----------------------------------------------------------
  static const Color add = Color(0xFF0C831F);
  static const Color addSoft = Color(0xFFE9F7EC);
  static const Color wishlist = Color(0xFFE23744);
  static const Color navInactive = Color(0xFF545B66);
  static const Color navActive = Color(0xFF111318);
  static const Color homeFill = Color(0xFFFFC72C);
  static const Color zomato = Color(0xFFE23744);
}

/// The theme-aware half of the palette.
///
/// Registered as a [ThemeExtension] so any descendant can read it with
/// `Theme.of(context).extension<FestivePalette>()!` — the Material 3 way to
/// ship brand colours that are not part of [ColorScheme].
@immutable
class FestivePalette extends ThemeExtension<FestivePalette> {
  const FestivePalette({
    required this.headerTop,
    required this.headerBottom,
    required this.bannerGlow,
    required this.bannerTop,
    required this.bannerMid,
    required this.bannerEdge,
    required this.gold,
    required this.goldDeep,
    required this.bulb,
    required this.pink,
    required this.tileTop,
    required this.tileBottom,
    required this.tileBorder,
    required this.surface,
    required this.surfaceSoft,
    required this.ink,
    required this.inkSoft,
    required this.hairline,
    required this.navSurface,
    required this.navInactive,
    required this.navActive,
    required this.add,
    required this.addSoft,
    required this.wishlist,
    required this.zomato,
    required this.isDark,
  });

  final Color headerTop;
  final Color headerBottom;
  final Color bannerGlow;
  final Color bannerTop;
  final Color bannerMid;
  final Color bannerEdge;
  final Color gold;
  final Color goldDeep;
  final Color bulb;
  final Color pink;
  final Color tileTop;
  final Color tileBottom;
  final Color tileBorder;
  final Color surface;
  final Color surfaceSoft;
  final Color ink;
  final Color inkSoft;
  final Color hairline;
  final Color navSurface;
  final Color navInactive;
  final Color navActive;
  final Color add;
  final Color addSoft;
  final Color wishlist;
  final Color zomato;
  final bool isDark;

  static const FestivePalette light = FestivePalette(
    headerTop: FestiveColors.headerTop,
    headerBottom: FestiveColors.headerBottom,
    bannerGlow: FestiveColors.bannerGlow,
    bannerTop: FestiveColors.bannerTop,
    bannerMid: FestiveColors.bannerMid,
    bannerEdge: FestiveColors.bannerEdge,
    gold: FestiveColors.gold,
    goldDeep: FestiveColors.goldDeep,
    bulb: FestiveColors.bulb,
    pink: FestiveColors.pink,
    tileTop: FestiveColors.tileTop,
    tileBottom: FestiveColors.tileBottom,
    tileBorder: FestiveColors.tileBorder,
    surface: FestiveColors.surface,
    surfaceSoft: FestiveColors.surfaceSoft,
    ink: FestiveColors.ink,
    inkSoft: FestiveColors.inkSoft,
    hairline: FestiveColors.hairline,
    navSurface: FestiveColors.surface,
    navInactive: FestiveColors.navInactive,
    navActive: FestiveColors.navActive,
    add: FestiveColors.add,
    addSoft: FestiveColors.addSoft,
    wishlist: FestiveColors.wishlist,
    zomato: FestiveColors.zomato,
    isDark: false,
  );

  static const FestivePalette dark = FestivePalette(
    headerTop: Color(0xFF32000B),
    headerBottom: Color(0xFF440016),
    bannerGlow: Color(0xFF8A0040),
    bannerTop: Color(0xFF6E002C),
    bannerMid: Color(0xFF65002A),
    bannerEdge: Color(0xFF540021),
    gold: Color(0xFFF7DCA8),
    goldDeep: Color(0xFFE0A94F),
    bulb: Color(0xFFFFF3D6),
    pink: Color(0xFFFF93AC),
    tileTop: Color(0xFFB1663A),
    tileBottom: Color(0xFF7E3A1D),
    tileBorder: Color(0xFFDE9440),
    surface: FestiveColors.surfaceDark,
    surfaceSoft: FestiveColors.surfaceSoftDark,
    ink: FestiveColors.inkDark,
    inkSoft: FestiveColors.inkSoftDark,
    hairline: FestiveColors.hairlineDark,
    navSurface: Color(0xFF1D0F16),
    navInactive: Color(0xFFC3B2BA),
    navActive: Color(0xFFFFF7F0),
    add: Color(0xFF159C33),
    addSoft: Color(0xFF12301B),
    wishlist: Color(0xFFFF6B78),
    zomato: Color(0xFFE23744),
    isDark: true,
  );

  LinearGradient get headerGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [headerTop, headerBottom],
      );

  /// The banner is a warm radial glow under the fairy lights that falls away
  /// to a darker maroon at the edges — sampled at three points of the mock.
  RadialGradient get bannerGradient => RadialGradient(
        center: const Alignment(0, -0.92),
        radius: 1.05,
        colors: [bannerGlow, bannerTop, bannerMid, bannerEdge],
        stops: const [0.0, 0.42, 0.74, 1.0],
      );

  LinearGradient get tileGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [tileTop, Color.lerp(tileTop, tileBottom, 0.55)!, tileBottom],
        stops: const [0.0, 0.55, 1.0],
      );

  /// "Diwali" is filled with this gold sweep rather than a flat colour.
  LinearGradient get wordmarkGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFFFFF0CF), gold, goldDeep],
        stops: const [0.0, 0.55, 1.0],
      );

  @override
  FestivePalette copyWith({
    Color? headerTop,
    Color? headerBottom,
    Color? bannerGlow,
    Color? bannerTop,
    Color? bannerMid,
    Color? bannerEdge,
    Color? gold,
    Color? goldDeep,
    Color? bulb,
    Color? pink,
    Color? tileTop,
    Color? tileBottom,
    Color? tileBorder,
    Color? surface,
    Color? surfaceSoft,
    Color? ink,
    Color? inkSoft,
    Color? hairline,
    Color? navSurface,
    Color? navInactive,
    Color? navActive,
    Color? add,
    Color? addSoft,
    Color? wishlist,
    Color? zomato,
    bool? isDark,
  }) {
    return FestivePalette(
      headerTop: headerTop ?? this.headerTop,
      headerBottom: headerBottom ?? this.headerBottom,
      bannerGlow: bannerGlow ?? this.bannerGlow,
      bannerTop: bannerTop ?? this.bannerTop,
      bannerMid: bannerMid ?? this.bannerMid,
      bannerEdge: bannerEdge ?? this.bannerEdge,
      gold: gold ?? this.gold,
      goldDeep: goldDeep ?? this.goldDeep,
      bulb: bulb ?? this.bulb,
      pink: pink ?? this.pink,
      tileTop: tileTop ?? this.tileTop,
      tileBottom: tileBottom ?? this.tileBottom,
      tileBorder: tileBorder ?? this.tileBorder,
      surface: surface ?? this.surface,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      hairline: hairline ?? this.hairline,
      navSurface: navSurface ?? this.navSurface,
      navInactive: navInactive ?? this.navInactive,
      navActive: navActive ?? this.navActive,
      add: add ?? this.add,
      addSoft: addSoft ?? this.addSoft,
      wishlist: wishlist ?? this.wishlist,
      zomato: zomato ?? this.zomato,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  FestivePalette lerp(ThemeExtension<FestivePalette>? other, double t) {
    if (other is! FestivePalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return FestivePalette(
      headerTop: mix(headerTop, other.headerTop),
      headerBottom: mix(headerBottom, other.headerBottom),
      bannerGlow: mix(bannerGlow, other.bannerGlow),
      bannerTop: mix(bannerTop, other.bannerTop),
      bannerMid: mix(bannerMid, other.bannerMid),
      bannerEdge: mix(bannerEdge, other.bannerEdge),
      gold: mix(gold, other.gold),
      goldDeep: mix(goldDeep, other.goldDeep),
      bulb: mix(bulb, other.bulb),
      pink: mix(pink, other.pink),
      tileTop: mix(tileTop, other.tileTop),
      tileBottom: mix(tileBottom, other.tileBottom),
      tileBorder: mix(tileBorder, other.tileBorder),
      surface: mix(surface, other.surface),
      surfaceSoft: mix(surfaceSoft, other.surfaceSoft),
      ink: mix(ink, other.ink),
      inkSoft: mix(inkSoft, other.inkSoft),
      hairline: mix(hairline, other.hairline),
      navSurface: mix(navSurface, other.navSurface),
      navInactive: mix(navInactive, other.navInactive),
      navActive: mix(navActive, other.navActive),
      add: mix(add, other.add),
      addSoft: mix(addSoft, other.addSoft),
      wishlist: mix(wishlist, other.wishlist),
      zomato: mix(zomato, other.zomato),
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

/// The two bundled families. Poppins carries every UI string (the app already
/// ships all of its real faces); Playfair Display Bold draws the "Diwali"
/// wordmark, whose high-contrast serifs match the reference lettering.
class FestiveType {
  const FestiveType._();

  static const String ui = 'Poppins';
  static const String display = 'PlayfairDisplay';
  static const List<String> uiFallback = <String>['Poppins'];
  static const List<String> displayFallback = <String>['PlayfairDisplay', 'Poppins'];

  static TextStyle body(
    double size, {
    Color color = FestiveColors.ink,
    FontWeight weight = FontWeight.w400,
    double? height,
    double letterSpacing = 0,
    TextDecoration? decoration,
    FontStyle style = FontStyle.normal,
  }) {
    return TextStyle(
      fontFamily: ui,
      fontFamilyFallback: uiFallback,
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      fontStyle: style,
    );
  }

  static TextStyle serif(
    double size, {
    Color color = FestiveColors.gold,
    double letterSpacing = 0,
    double? height,
  }) {
    return TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontSize: size,
      color: color,
      fontWeight: FontWeight.w700,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}

/// Width breakpoints, in logical pixels, matching Material 3's window size
/// classes so the screen behaves like the rest of the app.
class FestiveBreakpoints {
  const FestiveBreakpoints._();

  static const double medium = 600;
  static const double expanded = 1024;

  /// Content never stretches past this: a 1440 px window would otherwise put
  /// a 1000 px gap between the first and last arch tile.
  static const double maxContentWidth = 1180;

  static FestiveSize sizeOf(double width) {
    if (width >= expanded) return FestiveSize.expanded;
    if (width >= medium) return FestiveSize.medium;
    return FestiveSize.compact;
  }
}

enum FestiveSize {
  /// Phones. The layout of the reference capture.
  compact,

  /// Small tablets, foldables, split screen.
  medium,

  /// Desktop, tablet landscape, web.
  expanded;

  bool get isCompact => this == FestiveSize.compact;
  bool get isAtLeastMedium => this != FestiveSize.compact;
  bool get isExpanded => this == FestiveSize.expanded;

  /// Multiplier applied to the phone type scale. Text grows with the window so
  /// a desktop build does not look like a phone screenshot in the middle of a
  /// 27-inch monitor, without hard-coding a second type scale.
  double get typeScale => switch (this) {
        FestiveSize.compact => 1,
        FestiveSize.medium => 1.08,
        FestiveSize.expanded => 1.16,
      };

  double get gutter => switch (this) {
        FestiveSize.compact => 12,
        FestiveSize.medium => 20,
        FestiveSize.expanded => 28,
      };

  double get sectionGap => switch (this) {
        FestiveSize.compact => 18,
        FestiveSize.medium => 24,
        FestiveSize.expanded => 30,
      };
}

/// Durations and curves for the screen's motion. One place to retune them.
class FestiveMotion {
  const FestiveMotion._();

  static const Duration fast = Duration(milliseconds: 160);
  static const Duration base = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 460);
  static const Duration reveal = Duration(milliseconds: 620);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve spring = Curves.easeOutBack;
  static const Curve standard = Curves.easeInOutCubic;

  /// Respect the OS "remove animations" switch: entrance animations become
  /// instant and the fairy lights stop twinkling (they stay lit).
  static bool reduced(BuildContext context) {
    final MediaQueryData mq = MediaQuery.maybeOf(context) ?? const MediaQueryData();
    return mq.disableAnimations || mq.accessibleNavigation;
  }
}

/// Layout numbers shared by the header, the banner and the nav bar, so the
/// vertical rhythm stays identical across breakpoints.
class FestiveMetrics {
  const FestiveMetrics._();

  static const double headerHorizontal = 12;
  static const double searchBarHeight = 42;
  static const double searchRadius = 12;
  static const double tabStripHeight = 54;
  static const double navBarHeight = 56;

  /// Height / width of an arch tile: the reference card is 106.4 × 120.4 dp.
  static const double tileAspect = 1.132;
}

/// Text scaling guard.
///
/// The header stacks three lines plus a search field inside ~150 dp; at 2× text
/// scale that cannot fit. Clamping the *layout* scale (not the content) keeps
/// every string at a legible size while guaranteeing the header still lays
/// out — a deliberate, documented trade-off.
TextScaler clampTextScaler(TextScaler scaler) {
  final double factor = scaler.scale(14) / 14;
  return TextScaler.linear(factor.clamp(1.0, 1.35).toDouble());
}
