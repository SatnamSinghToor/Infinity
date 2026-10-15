import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../utils/constants.dart';
import 'product_card_v2.dart';

/// Responsive product grid that adjusts columns based on viewport width.
/// - 320-500px: 2 columns
/// - 501-899px: 3 columns
/// - 900px+: 4 columns
class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final bool dense;
  final bool showFavorite;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onProductTap;
  final Map<String, ProductVariant?> selectedVariants;
  final void Function(Product, ProductVariant?)? onVariantSelected;

  const ProductGrid({
    super.key,
    required this.products,
    this.dense = false,
    this.showFavorite = false,
    this.onFavoriteTap,
    this.onProductTap,
    this.selectedVariants = const {},
    this.onVariantSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = _calculateColumns(width);
        final spacing = _calculateSpacing(width, columns);
        final childAspectRatio = _calculateAspectRatio(width, columns, dense);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final selectedVariant = selectedVariants[product.id];
            
            return ProductCard(
              product: product,
              selectedVariant: selectedVariant,
              dense: dense,
              onTap: onProductTap != null ? () => onProductTap!() : null,
              onFavoriteTap: onFavoriteTap,
              showFavorite: showFavorite,
            );
          },
        );
      },
    );
  }

  int _calculateColumns(double width) {
    if (width <= AppConstants.mobileBreakpoint) return 2;
    if (width <= AppConstants.tabletBreakpoint) return 3;
    return 4;
  }

  double _calculateSpacing(double width, int columns) {
    if (width <= AppConstants.mobileBreakpoint) return 12;
    if (width <= AppConstants.tabletBreakpoint) return 22;
    return 24;
  }

  double _calculateAspectRatio(double width, int columns, bool dense) {
    // Card width = (width - (columns - 1) * spacing) / columns
    // Card height varies based on content
    final spacing = _calculateSpacing(width, columns);
    final cardWidth = (width - (columns - 1) * spacing) / columns;
    
    // Base height: image + footer + metadata
    // Image is square (aspectRatio 1:1)
    // Footer ~50px, Metadata ~80px
    final footerHeight = dense ? 48.0 : 56.0;
    final metadataHeight = dense ? 70.0 : 90.0;
    final cardHeight = cardWidth + footerHeight + metadataHeight;
    
    return cardWidth / cardHeight;
  }
}

/// Sliver version for use in CustomScrollView
class ProductGridSliver extends StatelessWidget {
  final List<Product> products;
  final bool dense;
  final bool showFavorite;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onProductTap;
  final Map<String, ProductVariant?> selectedVariants;
  final void Function(Product, ProductVariant?)? onVariantSelected;

  const ProductGridSliver({
    super.key,
    required this.products,
    this.dense = false,
    this.showFavorite = false,
    this.onFavoriteTap,
    this.onProductTap,
    this.selectedVariants = const {},
    this.onVariantSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = _calculateColumns(width);
        final spacing = _calculateSpacing(width, columns);
        final childAspectRatio = _calculateAspectRatio(width, columns, dense);

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final product = products[index];
              final selectedVariant = selectedVariants[product.id];
              
              return ProductCard(
                product: product,
                selectedVariant: selectedVariant,
                dense: dense,
                onTap: onProductTap != null ? () => onProductTap!() : null,
                onFavoriteTap: onFavoriteTap,
                showFavorite: showFavorite,
              );
            },
            childCount: products.length,
          ),
        );
      },
    );
  }

  int _calculateColumns(double width) {
    if (width <= AppConstants.mobileBreakpoint) return 2;
    if (width <= AppConstants.tabletBreakpoint) return 3;
    return 4;
  }

  double _calculateSpacing(double width, int columns) {
    if (width <= AppConstants.mobileBreakpoint) return 12;
    if (width <= AppConstants.tabletBreakpoint) return 22;
    return 24;
  }

  double _calculateAspectRatio(double width, int columns, bool dense) {
    final spacing = _calculateSpacing(width, columns);
    final cardWidth = (width - (columns - 1) * spacing) / columns;
    
    final footerHeight = dense ? 48.0 : 56.0;
    final metadataHeight = dense ? 70.0 : 90.0;
    final cardHeight = cardWidth + footerHeight + metadataHeight;
    
    return cardWidth / cardHeight;
  }
}

/// Consumer-based product grid that watches ProductProvider
class ProductGridConsumer extends StatelessWidget {
  final String? categoryId;
  final String? searchQuery;
  final bool dense;
  final bool showFavorite;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onProductTap;
  final Map<String, ProductVariant?> selectedVariants;
  final void Function(Product, ProductVariant?)? onVariantSelected;

  const ProductGridConsumer({
    super.key,
    this.categoryId,
    this.searchQuery,
    this.dense = false,
    this.showFavorite = false,
    this.onFavoriteTap,
    this.onProductTap,
    this.selectedVariants = const {},
    this.onVariantSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final products = _getProducts(provider);
        
        if (products.isEmpty) {
          return _buildEmptyState(context);
        }
        
        return ProductGrid(
          products: products,
          dense: dense,
          showFavorite: showFavorite,
          onFavoriteTap: onFavoriteTap,
          onProductTap: onProductTap,
          selectedVariants: selectedVariants,
          onVariantSelected: onVariantSelected,
        );
      },
    );
  }

  List<Product> _getProducts(ProductProvider provider) {
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      return provider.searchResults;
    }
    if (categoryId != null) {
      return provider.getProductsByCategory(categoryId!);
    }
    return provider.products;
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.box_remove,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.productNoProductsFound,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppConstants.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.productTryDifferentSearch,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}