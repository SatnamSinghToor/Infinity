import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'app_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../screens/category_listing_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/product_detail_screen.dart';
import '../utils/constants.dart';
import 'category_tile.dart';
import 'product_card.dart';
import 'pressable.dart';

/// What Home shows on its "All" tab, top to bottom: Bestsellers as collage
/// cards, then one block of category tiles per main category, then shelves of
/// products (Deals first) — all built from the store's own categories and
/// products.
///
/// It arrives as slivers rather than one box: as a box, every shelf and every
/// card in it was built and laid out on the first frame of the page. Sizes and
/// spacing are untouched — only when the work happens has changed.
class HomeAllSections {
  const HomeAllSections._();

  static List<Widget> slivers(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<ProductProvider>();
    final groups = _groups(provider);
    if (groups.isEmpty) return const <Widget>[];

    final deals = provider.allProducts
        .where((p) => p.discountPercent > 0 && (p.imageUrl ?? '').isNotEmpty)
        .toList()
      ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));

    // The customer's own past orders, as they are in stock today: the
    // quickest way back to the things they buy every week.
    final buyAgain = [
      for (final id in context.watch<OrderProvider>().recentProductIds)
        if (provider.getProductById(id) case final p?)
          if (p.isAvailable && (p.imageUrl ?? '').isNotEmpty) p,
    ];

    return [
      // The top padding of the box this used to be.
      const SliverToBoxAdapter(child: SizedBox(height: 6)),
      ...ProductShelf.slivers(
        context,
        title: l10n.homeBuyAgain,
        subtitle: l10n.homeBuyAgainSub,
        products: buyAgain.take(6).toList(),
        minCount: 2,
        onSeeAll: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OrdersScreen()),
        ),
      ),
      ..._Bestsellers.slivers(context, groups),
      for (final group in groups)
        if (group.subs.isNotEmpty)
          ..._TileBlock.slivers(context, provider, group),
      if (deals.length >= 3)
        ...ProductShelf.slivers(
          context,
          title: l10n.homeDealsHeading,
          products: deals.take(6).toList(),
          onSeeAll: () => _seeAll(context, groups.first.name),
        ),
      for (final group in groups.take(4))
        ...ProductShelf.slivers(
          context,
          title: group.name,
          products: group.products
              .where((p) => (p.imageUrl ?? '').isNotEmpty)
              .take(6)
              .toList(),
          onSeeAll: () => _seeAll(context, group.name),
        ),
    ];
  }

  /// Where every "see all" on this page goes.
  static void _seeAll(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryListingScreen(title: title),
      ),
    );
  }

  /// The main categories that have products, biggest first.
  static List<_Group> _groups(ProductProvider provider) {
    final out = <_Group>[];
    for (final name in provider.categories.skip(1)) {
      final products = provider.allProducts
          .where((p) => provider.inCategoryGroup(p, name))
          .toList();
      if (products.isEmpty) continue;
      final subs = <_Sub>[];
      for (final sub in provider.subCategoriesOf(name)) {
        final inSub = products.where((p) => p.category == sub).toList();
        if (inSub.isNotEmpty) subs.add(_Sub(sub, inSub));
      }
      out.add(_Group(name, products, subs));
    }
    out.sort((a, b) => b.products.length.compareTo(a.products.length));
    return out;
  }
}

class _Sub {
  final String name;
  final List<Product> products;

  const _Sub(this.name, this.products);
}

class _Group {
  final String name;
  final List<Product> products;
  final List<_Sub> subs;

  const _Group(this.name, this.products, this.subs);
}

Widget sectionHeading(String text, {String? subtitle}) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.replaceAll('/', ' & '),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: AppConstants.textSecondaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );

// ---------------------------------------------------------------------------
// Bestsellers

class _Bestsellers {
  const _Bestsellers._();

  static List<Widget> slivers(BuildContext context, List<_Group> groups) {
    final l10n = AppLocalizations.of(context);
    // The six biggest sub-categories; main categories without sub-categories
    // (Electronics, …) stand in when there are fewer.
    final cards = <_CollageData>[];
    for (final group in groups) {
      if (group.subs.isEmpty) {
        cards.add(_CollageData(group.name, group.name, null, group.products));
      } else {
        for (final sub in group.subs) {
          cards.add(_CollageData(sub.name, group.name, sub.name, sub.products));
        }
      }
    }
    cards.sort((a, b) => b.products.length.compareTo(a.products.length));
    final shown = cards.take(6).toList();
    if (shown.length < 3) return const <Widget>[];

    return [
      SliverToBoxAdapter(child: sectionHeading(l10n.homeBestsellersHeading)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid.count(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
          children: [
            for (final card in shown)
              _CollageCard(
                data: card,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryListingScreen(
                      title: card.parent,
                      initialCategory: card.sub,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ];
  }
}

class _CollageData {
  final String title;
  final String parent;
  final String? sub;
  final List<Product> products;

  const _CollageData(this.title, this.parent, this.sub, this.products);
}

/// Four product photos in a 2×2 grid, "+N more" on the last, and the
/// category's name beneath.
class _CollageCard extends StatelessWidget {
  final _CollageData data;
  final VoidCallback onTap;

  const _CollageCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final withPhoto =
        data.products.where((p) => (p.imageUrl ?? '').isNotEmpty).toList();
    final photos = withPhoto.take(4).map((p) => p.imageUrl!).toList();
    final more = data.products.length - photos.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF1F8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    padding: EdgeInsets.zero,
                    children: [
                      for (var i = 0; i < 4; i++)
                        _thumb(i < photos.length ? photos[i] : null, i),
                    ],
                  ),
                  if (more > 0)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 3,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFEEF1F8).withOpacity(0.95),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            l10n.homeMoreCount(more),
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF5B6070),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Text(
                  data.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumb(String? url, int index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ColoredBox(
        color: url == null
            ? categoryTints[index % categoryTints.length]
            : Colors.white,
        child: url == null
            ? null
            : Padding(
                padding: const EdgeInsets.all(3),
                child: AppNetworkImage(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category tiles

/// One main category's sub-categories as picture tiles, four to a row.
class _TileBlock {
  const _TileBlock._();

  static List<Widget> slivers(
    BuildContext context,
    ProductProvider provider,
    _Group group,
  ) {
    final subs = group.subs.take(8).toList();
    return [
      SliverToBoxAdapter(child: sectionHeading(group.name)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid.count(
          crossAxisCount: 4,
          mainAxisSpacing: 14,
          crossAxisSpacing: 10,
          childAspectRatio: 0.68,
          children: [
            for (var i = 0; i < subs.length; i++)
              CategoryTile(
                name: subs[i].name,
                imageUrl: categoryImageUrl(provider, subs[i].name),
                icon: Iconsax.category,
                tint: categoryTints[i % categoryTints.length],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryListingScreen(
                      title: group.name,
                      initialCategory: subs[i].name,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ];
  }
}

// Product shelves

class ProductShelf extends StatelessWidget {
  final String title;
  final List<Product> products;
  final VoidCallback onSeeAll;
  final String? subtitle;

  /// Fewest products worth a shelf of its own.
  final int minCount;

  /// Cards across a row. Three, like Blinkit's shelves: the narrow cells
  /// work because the pack size shares its line with a compact ADD pill
  /// and the price sits on a line of its own.
  final int columns;

  const ProductShelf({
    super.key,
    required this.title,
    required this.products,
    required this.onSeeAll,
    this.subtitle,
    this.minCount = 3,
    this.columns = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (products.length < minCount) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeading(title, subtitle: subtitle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, cons) {
              final (w, h) = _cellSize(cons.maxWidth, columns);
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                clipBehavior: Clip.none,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
                childAspectRatio: w / h,
                children: [
                  for (final p in products) _card(context, p, columns),
                ],
              );
            },
          ),
        ),
        _SeeAllTile(products: products, onTap: onSeeAll),
      ],
    );
  }

  /// The same shelf as slivers, for a page that builds its sections only as
  /// they come into view. Cells come from [_cellSize], so both shapes of this
  /// shelf lay out identically.
  static List<Widget> slivers(
    BuildContext context, {
    required String title,
    required List<Product> products,
    required VoidCallback onSeeAll,
    String? subtitle,
    int minCount = 3,
    int columns = 3,
  }) {
    if (products.length < minCount) return const <Widget>[];
    return [
      SliverToBoxAdapter(child: sectionHeading(title, subtitle: subtitle)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverLayoutBuilder(
          builder: (_, constraints) {
            final (w, h) = _cellSize(constraints.crossAxisExtent, columns);
            return SliverGrid.count(
              crossAxisCount: columns,
              crossAxisSpacing: 10,
              mainAxisSpacing: 12,
              childAspectRatio: w / h,
              children: [
                for (final p in products) _card(context, p, columns),
              ],
            );
          },
        ),
      ),
      SliverToBoxAdapter(
        child: _SeeAllTile(products: products, onTap: onSeeAll),
      ),
    ];
  }

  static Widget _card(BuildContext context, Product p, int columns) {
    return ProductCard(
      product: p,
      dense: columns > 2,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: p.id),
        ),
      ),
    );
  }

  /// Cells are sized from their own width so a card's photo, pack-size line,
  /// price and name always fit — no clipping on small phones, no dead space
  /// on big ones. Whatever the card's text block needs, the photo takes the
  /// rest, so a cell is never a pixel short.
  static (double, double) _cellSize(double width, int columns) {
    final w = (width - 10 * (columns - 1)) / columns;
    return (w, ProductCardMetrics.cellHeight(w, dense: columns > 2));
  }
}

/// The "{three thumbs} See all products ›" pill under a shelf.
class _SeeAllTile extends StatelessWidget {
  final List<Product> products;
  final VoidCallback onTap;

  const _SeeAllTile({required this.products, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Pressable(
          child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF1F8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFDDE2F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 30,
                child: Stack(
                  children: [
                    for (var i = 0; i < 3 && i < products.length; i++)
                      Positioned(
                        left: i * 18.0,
                        child: Container(
                          width: 30,
                          height: 30,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFDDE2F0),
                            ),
                          ),
                          child: ClipOval(
                            child: AppNetworkImage(
                              products[i].imageUrl ?? '',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 30 + 36),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.homeSeeAllProducts,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 4),
              const Icon(
                Iconsax.arrow_right_3_copy,
                size: 16,
                color: AppConstants.textPrimaryColor,
              ),
            ],
          ),
        ),
      )),
    );
  }
}
