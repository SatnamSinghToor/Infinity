import 'package:flutter/material.dart';

import 'festive_tokens.dart';

/// Content models for the Diwali storefront.
///
/// Everything on screen — copy, categories, the six banner tiles, the rails and
/// their products — is data. Swapping in a CMS means replacing this file (or
/// passing your own [FestiveContent] into `DiwaliFestiveScreen`), never editing
/// widget code.
@immutable
class FestiveCategory {
  const FestiveCategory(this.label, this.glyph);

  final String label;
  final FestiveGlyph glyph;
}

/// The line glyphs of the category strip, drawn by `FestiveGlyphPainter`.
enum FestiveGlyph { basket, diya, party, headphones, beauty, gift, home, grid, printer }

@immutable
class FestiveTile {
  const FestiveTile({
    required this.title,
    required this.asset,
    this.focalAlignment = Alignment.bottomCenter,
    this.imageScale = 1,
  });

  /// Two lines break exactly where the design breaks them
  /// ("Lights, Diya\n& Decor").
  final String title;
  final String asset;

  /// Which part of the photograph survives the crop inside the arch.
  final Alignment focalAlignment;

  /// Enlarges the photo inside the arch so a product fills the frame the way
  /// the reference product shots do.
  final double imageScale;
}

@immutable
class FestiveProduct {
  const FestiveProduct({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    required this.mrp,
    required this.asset,
    this.rating = 4.2,
    this.ratingCount = 0,
    this.badge,
  });

  final String id;
  final String name;

  /// Pack size or weight, e.g. "6 pcs" or "200 g".
  final String unit;
  final int price;
  final int mrp;
  final String asset;
  final double rating;
  final int ratingCount;

  /// Optional ribbon ("Bestseller", "New").
  final String? badge;

  bool get hasDiscount => mrp > price;
  int get discountPercent => hasDiscount ? ((mrp - price) * 100 / mrp).round() : 0;
}

@immutable
class FestiveRail {
  const FestiveRail({
    required this.title,
    required this.subtitle,
    required this.products,
  });

  final String title;
  final String subtitle;
  final List<FestiveProduct> products;
}

@immutable
class FestiveNavDestination {
  const FestiveNavDestination(this.label, this.glyph);

  final String label;
  final FestiveGlyph glyph;
}

/// Header copy. The defaults reproduce the reference capture verbatim; a
/// production build passes live values (delivery promise, saved address,
/// wallet balance) through `DiwaliFestiveScreen.copy`.
@immutable
class FestiveCopy {
  const FestiveCopy({
    required this.brand,
    required this.eta,
    required this.surgeLabel,
    required this.addressTag,
    required this.addressLine,
    required this.searchHints,
    required this.walletBalance,
    required this.bannerEyebrow,
    required this.bannerTitle,
    required this.bannerDate,
  });

  final String brand;
  final String eta;
  final String surgeLabel;
  final String addressTag;
  final String addressLine;

  /// The hint cycles through these with a soft fade, like the real storefront.
  final List<String> searchHints;
  final int walletBalance;
  final String bannerEyebrow;
  final String bannerTitle;
  final String bannerDate;

  static const FestiveCopy reference = FestiveCopy(
    brand: 'Blinkit in',
    eta: '17 minutes',
    surgeLabel: 'Surge applicable',
    addressTag: 'HOME',
    addressLine: 'hdsyy uuure, Hisar Railway',
    searchHints: <String>[
      'pooja thali',
      'diya',
      'rangoli colours',
      'dry fruits',
      'fairy lights',
    ],
    walletBalance: 0,
    bannerEyebrow: 'GET READY FOR',
    bannerTitle: 'Diwali',
    bannerDate: '8TH NOVEMBER, SUNDAY',
  );

  /// Same layout, the app's own voice — use this when wiring live data.
  factory FestiveCopy.forApp({
    required String brand,
    required String eta,
    required String addressLine,
    String addressTag = 'HOME',
    String? surgeLabel,
  }) {
    return FestiveCopy(
      brand: '$brand in',
      eta: eta,
      surgeLabel: surgeLabel ?? reference.surgeLabel,
      addressTag: addressTag,
      addressLine: addressLine,
      searchHints: reference.searchHints,
      walletBalance: reference.walletBalance,
      bannerEyebrow: reference.bannerEyebrow,
      bannerTitle: reference.bannerTitle,
      bannerDate: reference.bannerDate,
    );
  }
}

/// Assets. They resolve to the photographs already bundled with the app
/// (`assets/diwali/`); drop replacements in under the same names to match the
/// reference product photography exactly.
abstract final class FestiveAssets {
  static const String root = 'assets/diwali';

  static const String tileDecor = '$root/urli-1.jpg';
  static const String tileHome = '$root/towel-2.jpg';
  static const String tileSweets = '$root/chocolate-1.jpg';
  static const String tileGifts = '$root/beauty-4.jpg';
  static const String tileAppliances = '$root/appliance-2.jpg';
  static const String tileFestive = '$root/ethnic-2.jpg';
}

/// The catalogue drawn on the reference screen.
abstract final class FestiveContent {
  static const List<FestiveCategory> categories = <FestiveCategory>[
    FestiveCategory('All', FestiveGlyph.basket),
    FestiveCategory('Diwali', FestiveGlyph.diya),
    FestiveCategory('Party', FestiveGlyph.party),
    FestiveCategory('Electronics', FestiveGlyph.headphones),
    FestiveCategory('Beauty', FestiveGlyph.beauty),
    FestiveCategory('Gifting', FestiveGlyph.gift),
  ];

  static const List<FestiveTile> tiles = <FestiveTile>[
    FestiveTile(
      title: 'Lights, Diya\n& Decor',
      asset: FestiveAssets.tileDecor,
      imageScale: 1.15,
    ),
    FestiveTile(
      title: 'Home\nMakeover',
      asset: FestiveAssets.tileHome,
      imageScale: 1.2,
    ),
    FestiveTile(
      title: 'Sweets &\nHampers',
      asset: FestiveAssets.tileSweets,
      imageScale: 1.1,
    ),
    FestiveTile(
      title: 'Diwali\nGift Shop',
      asset: FestiveAssets.tileGifts,
      imageScale: 1.12,
    ),
    FestiveTile(
      title: 'Appliances\n& Gadgets',
      asset: FestiveAssets.tileAppliances,
      imageScale: 1.18,
    ),
    FestiveTile(
      title: 'Festive\nReady',
      asset: FestiveAssets.tileFestive,
      imageScale: 1.2,
    ),
  ];

  /// The section under the banner. The reference shows its first row of cards
  /// only — the second is built from the same card so the page ends on a
  /// finished note instead of a crop.
  static const List<FestiveRail> rails = <FestiveRail>[
    FestiveRail(
      title: 'Bring home your festive vibes',
      subtitle: 'Set your space aglow with diyas',
      products: <FestiveProduct>[
        FestiveProduct(
          id: 'diya-brass-set',
          name: 'Brass Diya Set',
          unit: '6 pcs',
          price: 349,
          mrp: 699,
          asset: '${FestiveAssets.root}/diya-4.jpg',
          rating: 4.4,
          ratingCount: 2140,
          badge: 'Bestseller',
        ),
        FestiveProduct(
          id: 'diya-tealight',
          name: 'Clay Diya & Tealight Pack',
          unit: '24 pcs',
          price: 199,
          mrp: 399,
          asset: '${FestiveAssets.root}/candle-1.jpg',
          rating: 4.3,
          ratingCount: 860,
        ),
        FestiveProduct(
          id: 'candle-pillar',
          name: 'Scented Pillar Candles',
          unit: 'Set of 3',
          price: 499,
          mrp: 899,
          asset: '${FestiveAssets.root}/candle-2.jpg',
          rating: 4.5,
          ratingCount: 1290,
        ),
        FestiveProduct(
          id: 'diya-painted',
          name: 'Hand-painted Diya Box',
          unit: '12 pcs',
          price: 259,
          mrp: 449,
          asset: '${FestiveAssets.root}/diya-1.jpg',
          rating: 4.1,
          ratingCount: 640,
        ),
        FestiveProduct(
          id: 'urli-gold',
          name: 'Golden Urli Bowl',
          unit: '1 pc',
          price: 649,
          mrp: 1199,
          asset: '${FestiveAssets.root}/urli-2.jpg',
          rating: 4.6,
          ratingCount: 320,
          badge: 'New',
        ),
        FestiveProduct(
          id: 'toran-marigold',
          name: 'Marigold Door Toran',
          unit: '1 pc',
          price: 299,
          mrp: 549,
          asset: '${FestiveAssets.root}/toran-1.jpg',
          rating: 4.2,
          ratingCount: 1170,
        ),
        FestiveProduct(
          id: 'fairy-lights',
          name: 'Warm Fairy String Lights',
          unit: '10 m',
          price: 379,
          mrp: 799,
          asset: '${FestiveAssets.root}/lights-1.jpg',
          rating: 4.3,
          ratingCount: 2210,
        ),
      ],
    ),
    FestiveRail(
      title: 'Diwali gifting under ₹499',
      subtitle: 'Sweet, scented and ready to gift',
      products: <FestiveProduct>[
        FestiveProduct(
          id: 'hamper-dryfruit',
          name: 'Dry Fruit Celebration Box',
          unit: '400 g',
          price: 449,
          mrp: 799,
          asset: '${FestiveAssets.root}/hamper-3.jpg',
          rating: 4.5,
          ratingCount: 980,
        ),
        FestiveProduct(
          id: 'chocolate-gift',
          name: 'Chocolate Gift Pack',
          unit: '18 pcs',
          price: 399,
          mrp: 649,
          asset: '${FestiveAssets.root}/chocolate-4.jpg',
          rating: 4.4,
          ratingCount: 1420,
          badge: 'Bestseller',
        ),
        FestiveProduct(
          id: 'candle-trio',
          name: 'Scented Candle Trio',
          unit: '3 jars',
          price: 349,
          mrp: 599,
          asset: '${FestiveAssets.root}/candle-3.jpg',
          rating: 4.2,
          ratingCount: 510,
        ),
        FestiveProduct(
          id: 'rangoli-kit',
          name: 'Rangoli Colour Kit',
          unit: '1 kit',
          price: 189,
          mrp: 349,
          asset: '${FestiveAssets.root}/rangoli-1.jpg',
          rating: 4.0,
          ratingCount: 260,
        ),
        FestiveProduct(
          id: 'pooja-thali',
          name: 'Pooja Thali Set',
          unit: '1 pc',
          price: 479,
          mrp: 899,
          asset: '${FestiveAssets.root}/pooja-1.jpg',
          rating: 4.6,
          ratingCount: 730,
        ),
        FestiveProduct(
          id: 'roses-red',
          name: 'Red Rose Bunch',
          unit: '10 stems',
          price: 299,
          mrp: 499,
          asset: '${FestiveAssets.root}/rose-2.jpg',
          rating: 4.1,
          ratingCount: 420,
        ),
      ],
    ),
  ];

  static const List<FestiveNavDestination> navigation = <FestiveNavDestination>[
    FestiveNavDestination('Home', FestiveGlyph.home),
    FestiveNavDestination('Order Again', FestiveGlyph.basket),
    FestiveNavDestination('Categories', FestiveGlyph.grid),
    FestiveNavDestination('Print', FestiveGlyph.printer),
  ];

  /// Everything the screen renders, in one object, so a host can inject its
  /// own catalogue without touching this file.
  static const List<FestiveRail> allRails = rails;
}

/// Indian digit grouping for prices: 1,12,499 rather than 112,499.
String rupee(int value) {
  final String digits = value.abs().toString();
  if (digits.length <= 3) return '₹$digits';

  final String last3 = digits.substring(digits.length - 3);
  String head = digits.substring(0, digits.length - 3);
  final List<String> groups = <String>[];
  while (head.length > 2) {
    groups.insert(0, head.substring(head.length - 2));
    head = head.substring(0, head.length - 2);
  }
  if (head.isNotEmpty) groups.insert(0, head);
  return '₹${groups.join(',')},$last3';
}

/// 4200 → "4.2k", keeping the rating chip one line wide.
String compactCount(int value) {
  if (value < 1000) return '$value';
  final double k = value / 1000;
  return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
}

/// A palette for the widgets that live outside the themed subtree (sheets,
/// overlays) but still need the same festive surface colours.
FestivePalette paletteOf(BuildContext context) {
  return Theme.of(context).extension<FestivePalette>() ??
      (Theme.of(context).brightness == Brightness.dark
          ? FestivePalette.dark
          : FestivePalette.light);
}
