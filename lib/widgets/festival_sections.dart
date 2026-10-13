import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'app_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../models/festival.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../screens/category_listing_screen.dart';
import '../screens/product_detail_screen.dart';
import '../utils/constants.dart';
import '../utils/format.dart';
import 'category_tile.dart';
import 'festival_artwork.dart';
import 'edit_tools.dart';
import 'ganesh_art.dart';
import 'home_all_sections.dart';

/// The Festival page on Home: a hero for the festival that is on, a row of
/// tall picture cards, then shelves of the festival's products. All of it
/// comes from the Festival category, so filling that category fills the page.
class FestivalSections extends StatelessWidget {
  /// The festival on today, or null between festivals.
  final Festival? festival;

  static const category = 'Festival';

  /// Runs after an admin changes the festival, so Home reloads it.
  final Future<void> Function()? onEdited;

  const FestivalSections({super.key, required this.festival, this.onEdited});

  /// Puts the festival's pencil (edit mode) on its hero.
  Widget _withFestivalPencil({required Widget child}) {
    final f = festival;
    if (f == null || onEdited == null) return child;
    return FestivalEditPencil(festival: f, onChanged: onEdited!, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<ProductProvider>();
    final products = provider.allProducts
        .where((p) => provider.inCategoryGroup(p, category))
        .toList();
    final subs = <String, List<Product>>{
      for (final sub in provider.subCategoriesOf(category))
        sub: products.where((p) => p.category == sub).toList(),
    }..removeWhere((_, list) => list.isEmpty);

    final accent = festival?.accent ?? const Color(0xFFC4531A);
    final from = festival?.colorTo ?? const Color(0xFFFFF1DE);
    // A banner picture set by an admin replaces the title and the artwork.
    final banner = provider.categoryImage(category);
    final bannerHeight = MediaQuery.sizeOf(context).width * 300 / 1080;

    void seeAll([String? sub]) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CategoryListingScreen(title: category, initialCategory: sub),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The hero melts out of the header's colour into the page.
        _withFestivalPencil(
            child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              // Carries on the header's colour, then the cards' band.
              colors: [from, from],
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Ganesh festivals wear Ganesha's face around the heading; it
              // runs to the screen edges, out past the hero's padding.
              if (banner != null)
                Positioned(
                  top: -22,
                  left: -16,
                  right: -16,
                  child: BannerPicture(url: banner),
                )
              else if (isGaneshFestival(festival?.title))
                const Positioned(
                  top: -22,
                  left: -16,
                  right: -16,
                  child: GaneshFaceArt(),
                ),
              Column(
                children: [
                  if (banner != null)
                    SizedBox(height: bannerHeight - 22 + 6)
                  else ...[
                    Text(
                      festival?.kicker ?? l10n.festivalKickerFallback,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        letterSpacing: 5,
                        fontWeight: FontWeight.w600,
                        color: accent.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // With Ganesha's face around it the title must fit between
                    // the ears, so it shrinks to that width.
                    Builder(builder: (context) {
                      final title = Text(
                        festival?.title ?? l10n.festivalTitleFallback,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 34,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      );
                      if (!isGaneshFestival(festival?.title)) return title;
                      return SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.56,
                        child: FittedBox(fit: BoxFit.scaleDown, child: title),
                      );
                    }),
                  ],
                  const SizedBox(height: 18),
                  if (products.isNotEmpty)
                    PictureCards(
                      accent: accent,
                      backdrop: from,
                      cards: [
                        // Ganesh festivals lead the offer-card carousel with
                        // the two darshan photos, full-bleed like the rest.
                        if (isGaneshFestival(festival?.title)) ...[
                          PictureCardData(
                            title: l10n.festivalCardMittiKeGanpati,
                            subtitle: l10n.festivalCardGanpatiDarshan,
                            imageUrl: null,
                            fullAssetImage: 'assets/festival/mitti_ganpati.jpg',
                            showPicture: false,
                            onTap: seeAll,
                          ),
                          PictureCardData(
                            title: l10n.festivalCardSthapana,
                            subtitle: l10n.festivalCardGanpatiDarshan,
                            imageUrl: null,
                            fullAssetImage: 'assets/festival/sthapana.jpg',
                            showPicture: false,
                            onTap: seeAll,
                          ),
                        ],
                        if (subs.isNotEmpty)
                          for (final e in subs.entries)
                            PictureCardData(
                              title: e.key,
                              subtitle: l10n.homeProductCount(e.value.length),
                              imageUrl: provider.categoryImage(e.key) ??
                                  e.value.map((p) => p.imageUrl).firstWhere(
                                        (u) => (u ?? '').isNotEmpty,
                                        orElse: () => null,
                                      ),
                              onTap: () => seeAll(e.key),
                              editName: e.key,
                              showPicture: !provider.pictureRemoved(e.key),
                              fullImageUrl: provider.categoryCardImage(e.key),
                            )
                        else
                          for (final p in products.take(8))
                            PictureCardData(
                              title: p.name,
                              subtitle: '${formatRupees(p.price)} · ${p.unit}',
                              imageUrl: p.imageUrl,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailScreen(productId: p.id),
                                ),
                              ),
                            ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        )),
        if (products.isEmpty)
          _EmptyFestival(accent: accent, name: festival?.chipLabel)
        else if (subs.isNotEmpty)
          for (final e in subs.entries)
            ProductShelf(
              title: e.key,
              products: e.value
                  .where((p) => (p.imageUrl ?? '').isNotEmpty)
                  .take(6)
                  .toList(),
              minCount: 1,
              onSeeAll: () => seeAll(e.key),
            )
        else
          ProductShelf(
            title: festival == null
                ? l10n.festivalPicks
                : l10n.festivalChipPicks(festival!.chipLabel),
            subtitle: l10n.festivalEverything,
            products: products
                .where((p) => (p.imageUrl ?? '').isNotEmpty)
                .take(8)
                .toList(),
            minCount: 1,
            onSeeAll: seeAll,
          ),
        // Pooja festivals also get the thali and the bhog section.
        if (festival?.showPooja ?? false) ...[
          const PoojaThaliCard(),
          const BhogFeastsSection(),
        ],
      ],
    );
  }
}

class PictureCardData {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback onTap;

  /// The sub-category this card stands for, so an admin can edit it.
  final String? editName;

  /// A picture that is the whole card (set by an admin): it fills the card
  /// and the usual title and arrow are left off.
  final String? fullImageUrl;

  /// Like [fullImageUrl] but bundled in the app (asset path, no network).
  final String? fullAssetImage;

  /// False when an admin removed the card's picture: none is drawn.
  final bool showPicture;

  /// A label for the action shown at the card's corner instead of the plain
  /// round arrow (offer banners pass "Shop now").
  final String? ctaLabel;

  /// Gradient colours for a card that has no picture; defaults to the
  /// shared card tints fading into the page's accent.
  final List<Color>? tint;

  const PictureCardData({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
    this.editName,
    this.fullImageUrl,
    this.fullAssetImage,
    this.showPicture = true,
    this.ctaLabel,
    this.tint,
  });
}

/// One tall picture card, used by every carousel of them: the picture covers
/// the whole card, a dark gradient fades up from the bottom so the words
/// read on any photo, and both lines of text are white. A tap ripples.
class PictureCard extends StatelessWidget {
  final Color accent;
  final PictureCardData card;

  /// Which card this is in its row; without a picture it picks a tint.
  final int index;

  const PictureCard({
    super.key,
    required this.accent,
    required this.card,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final full = card.fullImageUrl;
    final asset = card.fullAssetImage;
    String? photo;
    if (card.showPicture && (card.imageUrl ?? '').isNotEmpty) {
      photo = card.imageUrl;
    }
    // A card with no photo wears the banner's own colours, else the shared
    // tints faded towards the page's accent.
    List<Color> tints() {
      final custom = card.tint;
      if (custom != null) return custom;
      final base = categoryTints[index % categoryTints.length];
      final end = Color.lerp(base, accent, 0.35)!;
      return [
        base,
        end,
      ];
    }

    final deep =
        Color.lerp(Colors.black, accent, 0.35)!.withValues(alpha: 0.92);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        image: full != null
            ? DecorationImage(
                image: CachedNetworkImageProvider(full), fit: BoxFit.cover)
            : asset != null
                ? DecorationImage(image: AssetImage(asset), fit: BoxFit.cover)
                : null,
        gradient: full != null || asset != null || photo != null
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: tints(),
              ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: card.onTap,
          splashColor: Colors.white.withValues(alpha: 0.24),
          highlightColor: Colors.white.withValues(alpha: 0.10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photo != null)
                Positioned.fill(
                  child: AppNetworkImage(
                    photo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              // A dark fade under the words, so they stay readable whether
              // the card wears a photo, a picture or just its tint.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 150,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0),
                        Colors.black.withValues(alpha: 0.55),
                        deep,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
              // Title and subtitle stacked on their own line, full card
              // width, with the button below rather than beside them — a
              // long name ("Pantry Essentials Sale") used to share that
              // width with the CTA pill and got squeezed down to two or
              // three letters a line.
              Positioned(
                left: 18,
                right: 14,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      card.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 19,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (card.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        card.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    if (card.ctaLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              card.ctaLabel!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Iconsax.arrow_right_3_copy,
                              size: 14,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        child: const Icon(
                          Iconsax.arrow_right_3_copy,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tall cards in a sideways row, Blinkit-style: the card in the middle of
/// the screen is drawn full size and the neighbours a little smaller, peeking
/// in from both sides; a swipe settles on the next card. Each is the picture
/// on a warm tint, with the title and a round arrow on a dark fade at the
/// bottom.
class PictureCards extends StatefulWidget {
  final Color accent;
  final List<PictureCardData> cards;

  /// Both default to the app's proportions: a card is 57% of the screen wide
  /// and 1.5 times as tall as it is wide, so the pictures read big.
  final double? height;
  final double? cardWidth;

  /// When set, the row sits on a band of this colour that darkens downwards
  /// and runs a little below the cards, so they rest on it.
  final Color? backdrop;

  const PictureCards({
    super.key,
    required this.accent,
    required this.cards,
    this.height,
    this.cardWidth,
    this.backdrop,
  });

  @override
  State<PictureCards> createState() => _PictureCardsState();
}

class _PictureCardsState extends State<PictureCards> {
  static const _gap = 10.0;

  /// How much smaller a card is when it's a page away from the middle.
  static const _sideScale = 0.9;

  PageController? _controller;
  double _fraction = 0;

  /// With more than one card the row goes round: the last card sits at the
  /// left of the first, so the middle card always has a neighbour each side.
  bool get _loops => widget.cards.length > 1;

  late int _page = _loops ? widget.cards.length * 1000 : 0;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  double _cardWidth(double screenWidth) =>
      widget.cardWidth ?? screenWidth * 0.57;

  PageController _controllerFor(double screenWidth) {
    final fraction =
        ((_cardWidth(screenWidth) + _gap) / screenWidth).clamp(0.3, 1.0);
    if (_controller == null || (fraction - _fraction).abs() > 0.001) {
      _controller?.dispose();
      _fraction = fraction;
      _controller = PageController(
        viewportFraction: fraction,
        initialPage: _page,
      );
    }
    return _controller!;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final controller = _controllerFor(width);
    // Full-bleed: the row runs to the screen edges, not the hero's padding.
    return SizedBox(
      height: (widget.height ?? _cardWidth(width) * 1.5) +
          (widget.backdrop == null ? 0 : _bandExtra),
      child: OverflowBox(
        maxWidth: width,
        child: _band(
            width,
            PageView.builder(
              controller: controller,
              clipBehavior: Clip.none,
              itemCount: _loops ? null : widget.cards.length,
              onPageChanged: (i) => _page = i,
              itemBuilder: (context, i) => AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  var page = _page.toDouble();
                  if (controller.position.haveDimensions) {
                    page = controller.page ?? page;
                  }
                  final t = (1 - (page - i).abs()).clamp(0.0, 1.0);
                  return Transform.scale(
                    scale: _sideScale + (1 - _sideScale) * t,
                    child: child,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _gap / 2),
                  child: _withPencil(
                    widget.cards[i % widget.cards.length],
                    PictureCard(
                      accent: widget.accent,
                      card: widget.cards[i % widget.cards.length],
                      index: i % widget.cards.length,
                    ),
                  ),
                ),
              ),
            )),
      ),
    );
  }

  /// How far the band runs below the cards.
  static const _bandExtra = 30.0;

  Widget _band(double width, Widget pages) {
    final tint = widget.backdrop;
    if (tint == null) return pages;
    return Container(
      width: width,
      padding: const EdgeInsets.only(bottom: _bandExtra),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tint, Color.lerp(tint, widget.accent, 0.3)!],
        ),
      ),
      child: pages,
    );
  }

  /// The card's own pencil (edit mode), for cards that are a sub-category.
  Widget _withPencil(PictureCardData card, Widget child) =>
      card.editName == null
          ? child
          : CategoryEditPencil(name: card.editName!, child: child);
}

/// Shown while the Festival category has nothing in it yet.
class _EmptyFestival extends StatelessWidget {
  final Color accent;
  final String? name;

  const _EmptyFestival({required this.accent, required this.name});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        children: [
          Icon(Iconsax.magic_star,
              size: 44, color: accent.withValues(alpha: 0.7)),
          const SizedBox(height: 14),
          Text(
            name == null
                ? l10n.festivalGettingReady
                : l10n.festivalSpecialsOnWay(name!),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppConstants.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.festivalEmptyBody,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppConstants.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// A banner picture an admin set, across the top of a page. It has the same
/// proportions as the artwork it stands in for.
class BannerPicture extends StatelessWidget {
  final String url;

  const BannerPicture({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1080 / 300,
      child: AppNetworkImage(
        url,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
