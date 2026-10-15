import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../models/product_variant.dart';
import '../providers/cart_provider.dart';
import '../utils/constants.dart';
import 'app_network_image.dart';
import 'cart_action.dart';
import 'product_hero.dart';
import 'variant_sheet.dart';

/// Orange grocery product card — responsive, with variant support.
/// 
/// Visual spec:
/// - Card: 20px radius, light grey hairline border (#E3E6EB)
/// - Image: white/very light grey background, contain fit
/// - Veg badge: green only (#237A35) at bottom-right of image
/// - Non-veg badge: red outline at bottom-right
/// - CTA: Orange #FF5A00, 16px radius
/// - ADD state: white fill, orange outline, orange label (+ "N Opt" for variants)
/// - Stepper state: solid orange with white − 1 + controls
/// - Overlapping CTA at bottom-right of card
/// - Price/MRP/discount/rating/delivery below card
class ProductCard extends StatefulWidget {
  final Product product;
  final ProductVariant? selectedVariant;
  final bool dense;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool showFavorite;

  const ProductCard({
    super.key,
    required this.product,
    this.selectedVariant,
    this.dense = false,
    this.onTap,
    this.onFavoriteTap,
    this.showFavorite = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  final Object _heroTag = Object();

  Product get product => widget.product;
  ProductVariant? get selectedVariant => widget.selectedVariant;
  bool get dense => widget.dense;
  VoidCallback? get onTap => widget.onTap;
  VoidCallback? get onFavoriteTap => widget.onFavoriteTap;
  bool get showFavorite => widget.showFavorite;

  bool get hasVariants => product.hasVariants;
  bool get isInCart {
    final cart = context.watch<CartProvider>();
    final vid = selectedVariant?.id;
    return cart.isInCart(product.id, variantId: vid);
  }

  int get quantity {
    final cart = context.watch<CartProvider>();
    final vid = selectedVariant?.id;
    return cart.getQuantity(product.id, variantId: vid);
  }

  @override
  Widget build(BuildContext context) {
    final card = _buildCard(context);
    
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }
    return card;
  }

  Widget _buildCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFood = product.isFood;
    final displayVariant = selectedVariant ?? product.firstAvailableVariant;
    final isAdded = isInCart;
    final qty = quantity;
    
    // Responsive sizing
    final imageHeight = dense ? 140.0 : 180.0;
    final cardBorderRadius = BorderRadius.circular(AppConstants.cardRadius);
    final imageBorderRadius = BorderRadius.vertical(
      top: Radius.circular(AppConstants.imageRadius),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Product Card Visual
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Main card container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: cardBorderRadius,
                border: Border.all(
                  color: AppConstants.cardBorder,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image container
                  Container(
                    height: imageHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppConstants.imageBackground,
                      borderRadius: imageBorderRadius,
                    ),
                    child: Stack(
                      children: [
                        // Product image
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: imageBorderRadius,
                            child: _buildImage(),
                          ),
                        ),
                        // Favorite button (top-right)
                        if (showFavorite)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: _buildFavoriteButton(),
                          ),
                        // Carousel dots (bottom-left) - for multiple images
                        if (product.gallery.length > 1)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            right: 8,
                            child: _buildCarouselDots(),
                          ),
                        // Veg/Non-veg badge (bottom-right)
                        if (isFood)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: _buildFoodBadge(),
                          ),
                      ],
                    ),
                  ),
                  // Variant/Quantity footer
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: dense ? 8 : 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppConstants.cardBorder,
                          width: 0.5,
                        ),
                      ),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(AppConstants.cardRadius),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Variant label
                        if (hasVariants && displayVariant != null)
                          Flexible(
                            child: Text(
                              displayVariant.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: dense ? 11 : 12,
                                fontWeight: FontWeight.w500,
                                color: AppConstants.textPrimaryColor,
                              ),
                            ),
                          ),
                        const Spacer(),
                        // Cart action (overlapping)
                        _buildCartAction(displayVariant, isAdded, qty),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Product metadata below card
        _buildMetadata(context, displayVariant),
      ],
    );
  }

  Widget _buildImage() {
    final gallery = product.gallery;
    if (gallery.isEmpty) {
      return _buildPlaceholder();
    }
    return PageView.builder(
      itemCount: gallery.length,
      itemBuilder: (context, index) {
        return AppNetworkImage(
          gallery[index],
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Text(
        product.name.isNotEmpty ? product.name[0] : '?',
        style: GoogleFonts.poppins(
          fontSize: dense ? 32 : 48,
          fontWeight: FontWeight.w700,
          color: Colors.white.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Material(
      color: Colors.white.withOpacity(0.9),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onFavoriteTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            Iconsax.heart,
            size: dense ? 18 : 20,
            color: AppConstants.textPrimaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        product.gallery.length,
        (index) => Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(index == 0 ? 1 : 0.5),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildFoodBadge() {
    final isVeg = product.isVeg;
    final color = isVeg ? AppConstants.vegGreen : AppConstants.nonVegRed;
    final icon = isVeg ? Iconsax.tick_circle : Iconsax.close_circle;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 8,
        vertical: dense ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: isVeg ? null : Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: dense ? 10 : 12,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            isVeg ? 'Veg' : 'Non-Veg',
            style: GoogleFonts.poppins(
              fontSize: dense ? 9 : 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartAction(ProductVariant? variant, bool isAdded, int qty) {
    final hasOptions = hasVariants && (product.variants.length >= 2);
    final variantId = variant?.id;
    final canAdd = variant != null && product.canAddMore(product, variantId: variantId);
    
    return CartAction(
      product: product,
      height: dense ? 32 : 36,
      bagButton: true,
      plusButton: hasOptions,
      options: hasOptions ? product.variants.length : 0,
      onChoose: hasOptions
          ? () => showVariantSheet(context, product, initialVariant: variant)
          : null,
      width: 96,
      addWidth: 96,
      enabled: canAdd,
    );
  }

  Widget _buildMetadata(BuildContext context, ProductVariant? variant) {
    final l10n = AppLocalizations.of(context);
    final price = variant?.price ?? product.price;
    final mrp = variant?.mrp ?? product.originalPrice;
    final discount = variant?.discountPercent ?? product.discountPercent;
    final hasDiscount = mrp > price;
    final rating = product.rating;
    final reviewCount = product.reviews?.isNotEmpty == true 
        ? int.tryParse(product.reviews!.replaceAll(',', '')) ?? 0 
        : 0;
    
    return Padding(
      padding: EdgeInsets.fromLTRB(4, dense ? 6 : 8, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Price line
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // Selling price
              Text(
                '₹${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}',
                style: GoogleFonts.poppins(
                  fontSize: dense ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimaryColor,
                ),
              ),
              if (hasDiscount) ...[
                const SizedBox(width: 6),
                // Struck-through MRP
                Text(
                  '₹${mrp.toStringAsFixed(mrp.truncateToDouble() == mrp ? 0 : 2)}',
                  style: GoogleFonts.poppins(
                    fontSize: dense ? 11 : 12,
                    color: AppConstants.textSecondaryColor,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 6),
                // Discount badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppConstants.discountBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    variant?.discountDisplay ?? '$discount% OFF',
                    style: GoogleFonts.poppins(
                      fontSize: dense ? 9 : 10,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.discountBlue,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          // Product name (2 lines max)
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: dense ? 12 : 13.5,
              height: 1.3,
              fontWeight: FontWeight.w500,
              color: AppConstants.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          // Rating, reviews, delivery
          Row(
            children: [
              // Star rating
              if (rating > 0) ...[
                Icon(
                  Iconsax.star1,
                  size: dense ? 12 : 13,
                  color: Colors.amber[700],
                ),
                const SizedBox(width: 3),
                Text(
                  rating.toStringAsFixed(1),
                  style: GoogleFonts.poppins(
                    fontSize: dense ? 10 : 11,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
                if (reviewCount > 0) ...[
                  const SizedBox(width: 3),
                  Text(
                    '($reviewCount)',
                    style: GoogleFonts.poppins(
                      fontSize: dense ? 10 : 11,
                      color: AppConstants.textSecondaryColor,
                    ),
                  ),
                ],
              ],
              const Spacer(),
              // Delivery estimate
              Icon(
                Iconsax.truck_fast,
                size: dense ? 12 : 13,
                color: AppConstants.textSecondaryColor,
              ),
              const SizedBox(width: 3),
              Text(
                l10n.productDeliveryETA,
                style: GoogleFonts.poppins(
                  fontSize: dense ? 10 : 11,
                  color: AppConstants.textSecondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}