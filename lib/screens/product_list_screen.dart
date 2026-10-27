import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../utils/constants.dart';
import '../widgets/listing_common.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

/// A plain product grid with the same header, Sort/Offers/In-stock chips and
/// cards as the category listing — used for a brand's products and for a
/// store's products. [source] is re-run whenever products change.
class ProductListScreen extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<Product> Function(ProductProvider provider) source;

  /// Shown above the chips and scrolls with the grid (e.g. a store's banner).
  final Widget? header;
  final String emptyMessage;

  const ProductListScreen({
    super.key,
    required this.title,
    required this.source,
    this.subtitle,
    this.header,
    this.emptyMessage = 'No products here yet',
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  ListingSort _sort = ListingSort.relevance;
  bool _offersOnly = false;
  bool _inStockOnly = false;

  Future<void> _pickSort() async {
    final chosen = await showSortSheet(context, _sort);
    if (chosen != null) setState(() => _sort = chosen);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final products = applyListingFilters(
      widget.source(provider),
      offersOnly: _offersOnly,
      inStockOnly: _inStockOnly,
      sort: _sort,
    );
    // The 96px+ bottom slot only needs to exist while the View Cart pill is
    // up; with an empty cart it just burned a blank band under the grid.
    final hasCartPill = context.watch<CartProvider>().itemCount > 0;

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
                  ListingHeader(title: widget.title, subtitle: widget.subtitle),
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        if (widget.header != null)
                          SliverToBoxAdapter(child: widget.header),
                        SliverToBoxAdapter(
                          child: ListingFilterRow(
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
                        if (products.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: ListingEmpty(
                              filtered: _offersOnly || _inStockOnly,
                              message: widget.emptyMessage,
                            ),
                          )
                        else
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              12,
                              4,
                              12,
                              // Enough to clear the card's ADD-button
                              // overhang when no pill, the pill's own
                              // height + its 16px float when there is one.
                              hasCartPill ? 120 : 24,
                            ),
                            sliver: SliverLayoutBuilder(
                              builder: (context, constraints) {
                                return SliverGrid(
                                  gridDelegate:
                                      ProductCardMetrics.delegate(
                                    width: constraints.crossAxisExtent,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    childCount: products.length,
                                    (context, i) => ProductCard(
                                      product: products[i],
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductDetailScreen(
                                            productId: products[i].id,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
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
}
