import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../utils/constants.dart';
import '../widgets/category_tile.dart';
import '../widgets/listing_common.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';
import '../widgets/pressable.dart';

/// A top-level category (e.g. "Fruits/Veggies") as a split screen: its
/// sub-categories in a rail on the left ("All" first), and the selected one's
/// products on the right with sort and filter chips. A category without
/// sub-categories shows just the product grid.
class CategoryListingScreen extends StatefulWidget {
  /// The top-level category's name, shown in the top bar.
  final String title;

  /// The sub-category to open on; null means "All".
  final String? initialCategory;

  const CategoryListingScreen({
    super.key,
    required this.title,
    this.initialCategory,
  });

  @override
  State<CategoryListingScreen> createState() => _CategoryListingScreenState();
}

class _CategoryListingScreenState extends State<CategoryListingScreen> {
  static const _railWidth = 86.0;

  String? _selected; // null = All
  ListingSort _sort = ListingSort.relevance;
  bool _offersOnly = false;
  bool _inStockOnly = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialCategory;
  }

  bool _inSelection(ProductProvider provider, Product p, String? category) =>
      category == null
          ? provider.inCategoryGroup(p, widget.title)
          : p.category == category;

  int _countIn(ProductProvider provider, String? category) =>
      provider.allProducts
          .where((p) => _inSelection(provider, p, category))
          .length;

  Future<void> _pickSort() async {
    final chosen = await showSortSheet(context, _sort);
    if (chosen != null) setState(() => _sort = chosen);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final products = applyListingFilters(
      provider.allProducts
          .where((p) => _inSelection(provider, p, _selected))
          .toList(),
      offersOnly: _offersOnly,
      inStockOnly: _inStockOnly,
      sort: _sort,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppConstants.backgroundColor,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: DarkStatusBar(
        child: Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          body: Stack(
            children: [
              Column(
                children: [
                  // The chips span the width under the title, so the rail
                  // and the grid below both start on the same line.
                  ListingHeader(
                    title: widget.title,
                    bottom: ListingFilterRow(
                      sort: _sort,
                      offersOnly: _offersOnly,
                      inStockOnly: _inStockOnly,
                      onSortTap: _pickSort,
                      onOffersTap: () =>
                          setState(() => _offersOnly = !_offersOnly),
                      onInStockTap: () =>
                          setState(() => _inStockOnly = !_inStockOnly),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (provider.subCategoriesOf(widget.title).isNotEmpty)
                          _buildRail(provider),
                        Expanded(child: _buildContent(products)),
                      ],
                    ),
                  ),
                ],
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: SafeArea(top: false, child: ViewCartPill()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRail(ProductProvider provider) {
    // null stands for "All".
    final entries = <String?>[null, ...provider.subCategoriesOf(widget.title)];
    return Container(
      width: _railWidth,
      color: Colors.white,
      child: ListView.builder(
        // Flush with the header, so the lit "All" tile has no white strip
        // above it.
        padding: const EdgeInsets.only(bottom: 110),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final name = entries[i];
          final selected = name == _selected;
          final empty = _countIn(provider, name) == 0;
          return Pressable(
              child: GestureDetector(
            onTap: () => setState(() => _selected = name),
            behavior: HitTestBehavior.opaque,
            child: Opacity(
              opacity: empty && !selected ? 0.55 : 1,
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
                decoration: BoxDecoration(
                  color: selected
                      ? AppConstants.primaryColor.withOpacity(0.07)
                      : Colors.transparent,
                  border: Border(
                    left: BorderSide(
                      width: 4,
                      color: selected
                          ? AppConstants.primaryColor
                          : Colors.transparent,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: name == null
                          ? const CategoryArt(
                              imageUrl: null,
                              icon: Iconsax.category,
                              tint: Color(0xFFF2F2F2),
                              circle: true,
                              iconSize: 26,
                            )
                          : CategoryArt(
                              imageUrl: categoryImageUrl(provider, name),
                              icon: categoryIcon(provider, name),
                              tint:
                                  categoryTints[(i - 1) % categoryTints.length],
                              circle: true,
                              iconSize: 26,
                            ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name == null ? 'All' : breakableName(name),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        height: 1.2,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? AppConstants.primaryColor
                            : AppConstants.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ));
        },
      ),
    );
  }

  Widget _buildContent(List<Product> products) {
    return Column(
      children: [
        Expanded(
          child: products.isEmpty
              ? ListingEmpty(filtered: _offersOnly || _inStockOnly)
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 120),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.55,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, i) => ProductCard(
                    product: products[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailScreen(productId: products[i].id),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
