import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'app_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../screens/category_listing_screen.dart';
import '../utils/constants.dart';
import 'category_tile.dart';
import 'edit_tools.dart';
import 'festival_sections.dart';
import 'home_all_sections.dart';
import 'pressable.dart';

/// The colours a store page is dressed in: a soft tint for its tiles and
/// bands, and a stronger accent for its cards.
class StoreTheme {
  final Color tint;
  final Color accent;

  const StoreTheme(this.tint, this.accent);

  /// The colour the header takes on this page, so the page flows out of it.
  Color get header => Color.lerp(tint, accent, 0.12)!;

  /// The same colour a little deeper, where it ends below the offer cards.
  Color get deep => Color.lerp(tint, accent, 0.3)!;

  static const _themes = {
    'Electronics': StoreTheme(Color(0xFFEDE7FF), Color(0xFF5B3FD0)),
    'Beauty': StoreTheme(Color(0xFFFFE6F0), Color(0xFFC2185B)),
    'Pharmacy': StoreTheme(Color(0xFFE4F6EC), Color(0xFF1E7F4F)),
    'Gifting': StoreTheme(Color(0xFFFFEADF), Color(0xFFC4531A)),
    'Decor': StoreTheme(Color(0xFFFFF2D6), Color(0xFF9A6A12)),
    'Kids': StoreTheme(Color(0xFFE2F1FF), Color(0xFF1565C0)),
    'Imported': StoreTheme(Color(0xFFEAEAFB), Color(0xFF3F4AA8)),
  };

  static StoreTheme of(String category) =>
      _themes[category] ??
      const StoreTheme(Color(0xFFFFEFE0), Color(0xFFE65100));
}

/// How a chip's store page opens, after Blinkit's pages for the same chips:
/// each one starts with its own kind of cards.
enum _StoreLayout {
  /// Small bordered "Featured" cards, then Top Deals.
  featured,

  /// Big picture cards that settle in the middle, then a tinted shelf.
  focus,

  /// A heading, then a grid of round-cornered tiles.
  gifting,

  /// A title banner, then the tiles.
  hero,

  /// A title banner, then "Up to X% OFF" cards.
  deals,

  /// A title banner, then a shelf straight away.
  shelfFirst,

  /// Any other chip: the big cards, Top Deals and the tiles.
  standard,
}

/// A store page for one of Home's chips (Electronics, Beauty, …), built from
/// its sub-categories. Each chip opens the way its Blinkit page does, then
/// they share the tiles to shop by category and a shelf per sub-category.
class ChipStoreSections extends StatelessWidget {
  final String category;

  const ChipStoreSections({super.key, required this.category});

  static const _layouts = {
    'Electronics': _StoreLayout.featured,
    'Beauty': _StoreLayout.focus,
    'Gifting': _StoreLayout.gifting,
    'Pharmacy': _StoreLayout.hero,
    'Kids': _StoreLayout.deals,
    'Decor': _StoreLayout.shelfFirst,
    'Imported': _StoreLayout.shelfFirst,
  };

  /// Whether [category] has sub-categories with products in them; a chip
  /// without them keeps the plain product grid.
  static bool hasStore(ProductProvider provider, String category) {
    final subs = provider.subCategoriesOf(category);
    if (subs.isEmpty) return false;
    return provider.allProducts.any((p) => subs.contains(p.category));
  }

  /// The pictures that float either side of a chip's banner title.
  static (List<String>, List<String>) _heroArt(String category) {
    switch (category) {
      case 'Pharmacy':
        return (['💊', '🩺'], ['🌿', '🧴']);
      case 'Kids':
        return (['🍼', '🧸'], ['🎈', '⭐']);
      case 'Decor':
        return (['🪴', '🕯️'], ['🛋️', '🖼️']);
      case 'Imported':
        return (['✈️', '🍫'], ['🌍', '🧀']);
      default:
        return (const [], const []);
    }
  }

  /// The title banner's words for the chips that open with one: a small
  /// line, the big title and an optional line under it.
  static (String, String, String?) _heroText(
    AppLocalizations l10n,
    String category,
  ) {
    switch (category) {
      case 'Pharmacy':
        return (l10n.chipHeroPharmacyKicker, l10n.chipHeroPharmacyTitle, null);
      case 'Kids':
        return (l10n.chipHeroKidsKicker, l10n.chipHeroKidsTitle, null);
      case 'Decor':
        return (l10n.chipHeroDecorKicker, l10n.chipHeroDecorTitle, null);
      case 'Imported':
        return (
          l10n.chipHeroImportedKicker,
          l10n.chipHeroImportedTitle,
          l10n.chipHeroImportedSubtitle,
        );
      default:
        return ('', category, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<ProductProvider>();
    final theme = StoreTheme.of(category);
    final layout = _layouts[category] ?? _StoreLayout.standard;
    final width = MediaQuery.sizeOf(context).width;
    final all = provider.allProducts
        .where((p) => provider.inCategoryGroup(p, category))
        .toList();
    final subs = <String, List<Product>>{
      for (final sub in provider.subCategoriesOf(category))
        sub: all.where((p) => p.category == sub).toList(),
    }..removeWhere((_, list) => list.isEmpty);

    void open([String? sub]) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CategoryListingScreen(title: category, initialCategory: sub),
          ),
        );

    String? photoOf(String name, List<Product> list) =>
        provider.categoryImage(name) ??
        list
            .map((p) => p.imageUrl)
            .firstWhere((u) => (u ?? '').isNotEmpty, orElse: () => null);

    final withPhoto = all.where((p) => (p.imageUrl ?? '').isNotEmpty).toList();
    final deals = withPhoto.where((p) => p.discountPercent > 0).toList()
      ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    // The best picks: the biggest discounts, else whatever has a photo.
    final picks = (deals.length >= 3 ? deals : withPhoto).take(6).toList();

    final cards = [
      for (final e in subs.entries)
        PictureCardData(
          title: e.key,
          subtitle: l10n.homeProductCount(e.value.length),
          imageUrl: photoOf(e.key, e.value),
          onTap: () => open(e.key),
          editName: e.key,
          fullImageUrl: provider.categoryCardImage(e.key),
          showPicture: !provider.pictureRemoved(e.key),
        ),
    ];

    Widget tiles([String? heading]) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // No argument means the usual heading; '' means none at all.
            if ((heading ?? l10n.chipShopByCategory).isNotEmpty)
              sectionHeading(heading ?? l10n.chipShopByCategory),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 10,
                childAspectRatio: 0.68,
                children: [
                  for (final e in subs.entries)
                    CategoryEditPencil(
                      name: e.key,
                      child: CategoryTile(
                        name: e.key,
                        imageUrl: photoOf(e.key, e.value),
                        backgroundUrl: provider.categoryCardImage(e.key),
                        hidePicture: provider.pictureRemoved(e.key),
                        icon: Iconsax.category,
                        tint: theme.tint,
                        onTap: () => open(e.key),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );

    Widget shelf(String title, {String? subtitle}) => ProductShelf(
          title: title,
          subtitle: subtitle,
          products: picks,
          onSeeAll: open,
        );

    final hero = _heroText(l10n, category);
    final art = _heroArt(category);
    // A banner picture set by an admin replaces the title and the artwork.
    final banner = provider.categoryImage(category);
    Widget heroBlock({String? subtitle}) => CategoryEditPencil(
          name: category,
          child: banner != null
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BannerPicture(url: banner),
                )
              : _StoreHero(
                  theme: theme,
                  kicker: hero.$1,
                  title: hero.$2,
                  subtitle: subtitle,
                  leftArt: art.$1,
                  rightArt: art.$2,
                ),
        );
    // Everything from the header down to just below the offer cards sits on
    // one colour that starts as the header's, so the page flows out of it.
    Widget backdrop(List<Widget> children) =>
        _TopBackdrop(theme: theme, children: children);
    final List<Widget> top;
    switch (layout) {
      case _StoreLayout.featured:
        top = [
          backdrop([
            if (banner != null) heroBlock(),
            _FeaturedCards(cards: cards, accent: theme.accent),
          ]),
          if (deals.length >= 3) shelf(l10n.chipTopDeals),
          tiles(),
        ];
      case _StoreLayout.focus:
        final size = width * 0.67;
        top = [
          backdrop([
            if (banner != null) heroBlock(),
            PictureCards(
              accent: theme.accent,
              cardWidth: size,
              height: size * 1.02,
              cards: cards,
            ),
          ]),
          if (picks.length >= 3)
            // Carries on from where the cards' colour ends.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [theme.deep, theme.tint],
                ),
              ),
              child: shelf(
                l10n.chipHeroBeautyShelfTitle,
                subtitle: l10n.chipHeroBeautyShelfSubtitle,
              ),
            ),
          tiles(),
        ];
      case _StoreLayout.gifting:
        top = [
          backdrop([
            if (banner != null) heroBlock(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                l10n.chipGiftingTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 23,
                  fontStyle: FontStyle.italic,
                  // Bold, not semi-bold: it is the italic face the app ships.
                  fontWeight: FontWeight.w700,
                  color: theme.accent,
                ),
              ),
            ),
          ]),
          tiles(''),
          if (picks.length >= 3) shelf(l10n.chipTopBuys),
        ];
      case _StoreLayout.hero:
        top = [
          backdrop([heroBlock()]),
          tiles(),
        ];
      case _StoreLayout.deals:
        top = [
          backdrop([
            heroBlock(),
            _DealCards(
              subs: subs,
              theme: theme,
              onOpen: open,
              photoOf: photoOf,
              fullImageOf: provider.categoryCardImage,
              pictureRemoved: provider.pictureRemoved,
            ),
          ]),
          if (picks.length >= 3) shelf(l10n.chipTopPicks),
          tiles(),
        ];
      case _StoreLayout.shelfFirst:
        top = [
          backdrop([heroBlock(subtitle: hero.$3)]),
          if (picks.length >= 3)
            shelf(category == 'Decor' ? l10n.chipTopPicks : hero.$2),
          tiles(),
        ];
      case _StoreLayout.standard:
        top = [
          backdrop([
            if (banner != null) heroBlock(),
            PictureCards(accent: theme.accent, cards: cards),
          ]),
          if (deals.length >= 3) shelf(l10n.chipTopDeals),
          tiles(),
        ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...top,
        // Each sub-category's own shelf; every other one sits on the
        // theme's tint, so the page has some rhythm.
        for (var i = 0; i < subs.length; i++)
          _Band(
            tinted: i.isOdd,
            tint: theme.tint,
            child: ProductShelf(
              title: subs.keys.elementAt(i),
              products: subs.values
                  .elementAt(i)
                  .where((p) => (p.imageUrl ?? '').isNotEmpty)
                  .take(6)
                  .toList(),
              minCount: 1,
              onSeeAll: () => open(subs.keys.elementAt(i)),
            ),
          ),
      ],
    );
  }
}

/// The one colour the top of a store page sits on: it starts as the header's
/// colour and deepens a little down to just below the offer cards.
class _TopBackdrop extends StatelessWidget {
  final StoreTheme theme;
  final List<Widget> children;

  const _TopBackdrop({required this.theme, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 10, bottom: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.header, theme.deep],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// A banner that opens a chip's page: a small line, a big title and a tint
/// that melts into the page, with a few pictures floating either side.
class _StoreHero extends StatefulWidget {
  final StoreTheme theme;
  final String kicker;
  final String title;
  final String? subtitle;

  /// What floats at the left and at the right of the title.
  final List<String> leftArt;
  final List<String> rightArt;

  const _StoreHero({
    required this.theme,
    required this.kicker,
    required this.title,
    this.subtitle,
    this.leftArt = const [],
    this.rightArt = const [],
  });

  @override
  State<_StoreHero> createState() => _StoreHeroState();
}

class _StoreHeroState extends State<_StoreHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// One picture, bobbing up and down and tilting a little; [index] keeps
  /// the pictures out of step with each other.
  Widget _float(String art, int index, double size) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final phase = _controller.value * 2 * math.pi + index * 1.7;
        return Transform.translate(
          offset: Offset(0, 6 * math.sin(phase)),
          child:
              Transform.rotate(angle: 0.12 * math.sin(phase + 1), child: child),
        );
      },
      child: Text(art, style: TextStyle(fontSize: size)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final hasArt = widget.leftArt.isNotEmpty || widget.rightArt.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(hasArt ? 56 : 20, 22, hasArt ? 56 : 20, 26),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Pictures sit in the side padding, staggered up and down.
          for (var i = 0; i < widget.leftArt.length; i++)
            Positioned(
              left: i.isEven ? -46 : -34,
              top: i * 36.0,
              child: _float(widget.leftArt[i], i, i.isEven ? 34 : 26),
            ),
          for (var i = 0; i < widget.rightArt.length; i++)
            Positioned(
              right: i.isEven ? -46 : -34,
              top: 8 + i * 36.0,
              child: _float(widget.rightArt[i], i + 2, i.isEven ? 30 : 26),
            ),
          SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                if (widget.kicker.isNotEmpty)
                  Text(
                    widget.kicker,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                      color: theme.accent,
                    ),
                  ),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: theme.accent,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      color: theme.accent.withOpacity(0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small picture cards in a plain sideways row, each with a "Featured" tag
/// sitting on its coloured border.
class _FeaturedCards extends StatelessWidget {
  final List<PictureCardData> cards;
  final Color accent;

  const _FeaturedCards({required this.cards, required this.accent});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final card = cards[i];
          final full = card.fullImageUrl;
          final item = GestureDetector(
            onTap: card.onTap,
            child: SizedBox(
              width: 116,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: categoryTints[i % categoryTints.length],
                        // A photo set for the whole card is its
                        // background, lightened so the title stays
                        // readable.
                        image: full == null
                            ? null
                            : DecorationImage(
                                image: CachedNetworkImageProvider(full),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.white.withOpacity(0.35),
                                  BlendMode.lighten,
                                ),
                              ),
                        borderRadius: BorderRadius.circular(18),
                        // A hairline in the page's own colour: the cards
                        // should sit on the tint, not be framed by it.
                        border:
                            Border.all(color: accent.withOpacity(0.45)),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (card.showPicture && card.imageUrl != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 44, 8, 8),
                              child: AppNetworkImage(
                                card.imageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          Positioned(
                            left: 8,
                            right: 8,
                            top: 16,
                            child: Text(
                              card.title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                                color: AppConstants.textPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l10n.chipFeatured,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          return card.editName == null
              ? item
              : CategoryEditPencil(name: card.editName!, child: item);
        },
      ),
    );
  }
}

/// Two cards to a row, one per sub-category: an "Up to X% OFF" tag (when
/// something in it is discounted), its name and a picture.
class _DealCards extends StatelessWidget {
  final Map<String, List<Product>> subs;
  final StoreTheme theme;
  final void Function([String? sub]) onOpen;
  final String? Function(String, List<Product>) photoOf;
  final String? Function(String) fullImageOf;
  final bool Function(String) pictureRemoved;

  const _DealCards({
    required this.subs,
    required this.theme,
    required this.onOpen,
    required this.photoOf,
    required this.fullImageOf,
    required this.pictureRemoved,
  });

  Widget _card(
    AppLocalizations l10n,
    String name,
    List<Product> products,
  ) =>
      CategoryEditPencil(
        name: name,
        child: _cardBody(l10n, name, products),
      );

  Widget _cardBody(
    AppLocalizations l10n,
    String name,
    List<Product> products,
  ) {
    final full = fullImageOf(name);
    final off = products.fold<int>(
      0,
      (best, p) => p.discountPercent > best ? p.discountPercent : best,
    );
    final photo = photoOf(name, products);
    return Pressable(
        child: GestureDetector(
      onTap: () => onOpen(name),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          // A photo set for the whole card is its background, lightened so
          // the title and tag on top stay readable.
          image: full == null
              ? null
              : DecorationImage(
                  image: CachedNetworkImageProvider(full),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withOpacity(0.35),
                    BlendMode.lighten,
                  ),
                ),
          gradient: full != null
              ? null
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [theme.tint, Colors.white],
                ),
        ),
        child: Column(
          children: [
            if (off > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFC94D),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(10),
                  ),
                ),
                child: Text(
                  l10n.chipUpToOff(off),
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textPrimaryColor,
                  ),
                ),
              )
            else
              const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimaryColor,
                ),
              ),
            ),
            Expanded(
              child: pictureRemoved(name)
                  ? const SizedBox.shrink()
                  : photo == null
                      ? Icon(
                          Iconsax.category,
                          color: theme.accent.withOpacity(0.5),
                          size: 40,
                        )
                      : Padding(
                          padding: const EdgeInsets.all(8),
                          child: AppNetworkImage(
                            photo,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
            ),
          ],
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.02,
        children: [
          for (final e in subs.entries.take(4)) _card(l10n, e.key, e.value),
        ],
      ),
    );
  }
}

class _Band extends StatelessWidget {
  final bool tinted;
  final Color tint;
  final Widget child;

  const _Band({required this.tinted, required this.tint, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!tinted) return child;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 22),
      padding: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(0),
      ),
      // The shelf brings its own top padding; trim it inside the band.
      child: Transform.translate(offset: const Offset(0, -2), child: child),
    );
  }
}
