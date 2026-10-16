import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../models/product_variant.dart';
import '../providers/cart_provider.dart';
import '../utils/constants.dart';
import 'app_network_image.dart';
import 'edit_tools.dart';
import 'product_hero.dart';
import 'variant_sheet.dart';

/// Orange Grocery UI Product Card — Pixel-perfect match for the approved design.
///
/// Visual Specifications:
/// - Card: 20px outer radius, 1.0px hairline border (#E3E6EB)
/// - Pale image canvas (#FAFBFC -> #EFF1F4) with contain photo fit
/// - Wishlist heart button at top-right
/// - Carousel dots at bottom-left (• • • •)
/// - Indian vegetarian food mark at bottom-right (green square with green dot)
/// - Variant footer: #F8F9FB background with variant label on left
/// - ADD Button / Stepper:
///   - 1.0px HAIRLINE border (#FF5A00)
///   - 16px corner radius
///   - Generous dimensions overlapping both the footer divider and outer right card border
///   - Multi-option: Upper white section with bold "ADD", lower peach (#FFF0E8) pill with "N options"
///   - Single-option: Solid white with bold orange "ADD"
///   - Stepper: Solid orange (#FF5A00) with 1.0px hairline border (#E64E00) and white − qty +
/// - Metadata below card: Large bold price, struck-through MRP, blue discount (% OFF on MRP),
///   bold title, 5 yellow stars + reviews count, and slate clock icon with 9 mins ETA.
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
    this.showFavorite = true,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  final Object _heroTag = Object();
  ProductVariant? _activeVariant;
  bool _isFavorite = false;

  Product get product => widget.product;
  bool get dense => widget.dense;
  VoidCallback? get onTap => widget.onTap;
  VoidCallback? get onFavoriteTap => widget.onFavoriteTap;
  bool get showFavorite => widget.showFavorite;

  // Exact color palette from the design specification
  static const Color _orange = Color(0xFFFF5A00);
  static const Color _orangeDark = Color(0xFFE64E00);
  static const Color _peachOptionBg = Color(0xFFFFF0E8);
  static const Color _vegGreen = Color(0xFF237A35);
  static const Color _nonVegRed = Color(0xFFD32F2F);
  static const Color _discountBlue = Color(0xFF2F6FC9);
  static const Color _inkPrimary = Color(0xFF20252E);
  static const Color _inkSecondary = Color(0xFF68717E);
  static const Color _mrpMuted = Color(0xFF747C88);
  static const Color _line = Color(0xFFE3E6EB);
  static const Color _footerBg = Color(0xFFF8F9FB);
  static const Color _starYellow = Color(0xFFFFC93D);
  static const Color _clockSlate = Color(0xFF6B94A2);

  @override
  void initState() {
    super.initState();
    _activeVariant = widget.selectedVariant ?? product.firstAvailableVariant;
  }

  @override
  void didUpdateWidget(ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedVariant != oldWidget.selectedVariant) {
      _activeVariant = widget.selectedVariant ?? product.firstAvailableVariant;
    }
  }

  bool get hasMultipleOptions => product.variants.length > 1;

  ProductVariant? get currentVariant =>
      _activeVariant ?? product.firstAvailableVariant;

  int get currentQuantity {
    final cart = context.watch<CartProvider>();
    final vid = currentVariant?.id;
    return cart.getQuantity(product.id, variantId: vid);
  }

  @override
  Widget build(BuildContext context) {
    Widget card = _buildCardContent(context);

    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }

    card = ProductEditPencil(product: product, child: card);

    return Listener(
      onPointerDown: (_) => ProductHero.handOver(product.id, _heroTag),
      child: card,
    );
  }

  Widget _buildCardContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildVisualCard(context),
        _buildMetadata(context),
      ],
    );
  }

  Widget _buildVisualCard(BuildContext context) {
    final variant = currentVariant;
    final variantLabel = variant?.label ?? product.unit;
    final qty = currentQuantity;
    final isAdded = qty > 0;
    final soldOut = !product.isAvailable || product.stock <= 0;

    // Exact proportional dimensions matching the design
    final imageHeight = dense ? 140.0 : 166.0;
    final footerHeight = dense ? 48.0 : 54.0;
    final btnWidth = dense ? 88.0 : 104.0;
    final btnHeight = dense ? 44.0 : 50.0;
    // Overlaps 16-18px above the divider into the image canvas
    final overlapTop = imageHeight - (btnHeight * 0.36);
    // Overlaps 6-8px past the right border of the card
    final overlapRight = dense ? -6.0 : -8.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line, width: 1.0), // Hairline border
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C1C2532),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top: Image Canvas with rounded top corners
              Container(
                height: imageHeight,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFAFBFC), Color(0xFFEFF1F4)],
                  ),
                ),
                child: Stack(
                  children: [
                    // Product Photo
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Opacity(
                          opacity: soldOut ? 0.45 : 1.0,
                          child: Hero(
                            tag: _heroTag,
                            child: _buildPhoto(),
                          ),
                        ),
                      ),
                    ),
                    // Sold Out Badge
                    if (soldOut)
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Sold out',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    // Wishlist Heart Button (top-right)
                    if (showFavorite)
                      Positioned(
                        top: 9,
                        right: 9,
                        child: _buildWishlistButton(),
                      ),
                    // Carousel Pagination Dots (bottom-left)
                    Positioned(
                      bottom: 11,
                      left: 12,
                      child: _buildCarouselDots(),
                    ),
                    // Standard Indian Vegetarian Symbol (bottom-right of image)
                    if (product.isFood)
                      Positioned(
                        bottom: 11,
                        right: 12,
                        child: _buildVegBadge(),
                      ),
                  ],
                ),
              ),
              // Thin Hairline Divider Line
              Container(
                height: 1.0,
                color: _line,
              ),
              // Bottom: Variant Footer with rounded bottom corners
              Container(
                height: footerHeight,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: _footerBg,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(19)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    // Variant Pack Label (e.g., "1 kg", "750 g")
                    Flexible(
                      child: Text(
                        variantLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: dense ? 14 : 16,
                          fontWeight: FontWeight.w800,
                          color: _inkPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // OVERLAPPING ADD / STEPPER CONTROL
          Positioned(
            top: overlapTop,
            right: overlapRight,
            child: _buildActionControl(
              btnWidth: btnWidth,
              btnHeight: btnHeight,
              qty: qty,
              isAdded: isAdded,
              soldOut: soldOut,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto() {
    final gallery = product.gallery;
    final url = gallery.isNotEmpty ? gallery.first : (product.imageUrl ?? '');
    if (url.isEmpty) {
      return _buildPlaceholder();
    }
    return AppNetworkImage(
      url,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Text(
        product.name.isNotEmpty ? product.name[0] : '?',
        style: GoogleFonts.poppins(
          fontSize: dense ? 32 : 44,
          fontWeight: FontWeight.w800,
          color: Colors.grey.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildWishlistButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (onFavoriteTap != null) {
          onFavoriteTap!();
        } else {
          setState(() => _isFavorite = !_isFavorite);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            size: dense ? 17 : 19,
            color: _isFavorite ? const Color(0xFFEC4C54) : const Color(0xFF89919C),
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselDots() {
    final count = product.gallery.length > 1 ? product.gallery.length : 4;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count.clamp(2, 4),
        (index) => Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: index == 0 ? const Color(0xFF404650) : const Color(0xFFBDC3CB),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildVegBadge() {
    final isVeg = product.isVeg;
    final color = isVeg ? _vegGreen : _nonVegRed;
    return Container(
      width: dense ? 18 : 21,
      height: dense ? 18 : 21,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color, width: 1.2), // Hairline green border
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: isVeg
            ? Container(
                width: dense ? 8 : 9.5,
                height: dense ? 8 : 9.5,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              )
            : Icon(
                Icons.change_history,
                size: dense ? 8 : 9.5,
                color: color,
              ),
      ),
    );
  }

  Widget _buildActionControl({
    required double btnWidth,
    required double btnHeight,
    required int qty,
    required bool isAdded,
    required bool soldOut,
  }) {
    if (soldOut) {
      return Container(
        width: btnWidth,
        height: btnHeight,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!, width: 1.0),
        ),
        alignment: Alignment.center,
        child: Text(
          'ADD',
          style: GoogleFonts.poppins(
            fontSize: dense ? 13 : 15,
            fontWeight: FontWeight.w700,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    if (isAdded) {
      // Solid Orange Quantity Stepper
      return Container(
        width: btnWidth,
        height: btnHeight,
        decoration: BoxDecoration(
          color: _orange,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _orangeDark, width: 1.0), // Hairline border
          boxShadow: const [
            BoxShadow(
              color: Color(0x3BFF5A00),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Minus Button
            Expanded(
              child: InkWell(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                onTap: () {
                  HapticFeedback.selectionClick();
                  final cart = context.read<CartProvider>();
                  cart.decreaseQuantity(
                    product.id,
                    variantId: currentVariant?.id,
                  );
                },
                child: const Center(
                  child: Icon(Icons.remove, color: Colors.white, size: 18),
                ),
              ),
            ),
            // Quantity Number with subtle vertical divider lines
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              height: btnHeight * 0.68,
              decoration: BoxDecoration(
                border: Border.symmetric(
                  vertical: BorderSide(
                    color: Colors.white.withOpacity(0.35),
                    width: 1.0,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  '$qty',
                  style: GoogleFonts.poppins(
                    fontSize: dense ? 13 : 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Plus Button
            Expanded(
              child: InkWell(
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                onTap: () {
                  HapticFeedback.selectionClick();
                  final cart = context.read<CartProvider>();
                  final ok = cart.increaseQuantity(
                    product.id,
                    variantId: currentVariant?.id,
                  );
                  if (!ok) {
                    _showStockLimitToast();
                  }
                },
                child: const Center(
                  child: Icon(Icons.add, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Unadded State — Multi-option vs Single-option
    if (hasMultipleOptions) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _openVariantSheet();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: btnWidth,
          height: btnHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _orange, width: 1.0), // Hairline border
            boxShadow: const [
              BoxShadow(
                color: Color(0x18FF5A00),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Column(
              children: [
                // Upper Section: White background with bold orange "ADD"
                Expanded(
                  flex: 11,
                  child: Center(
                    child: Text(
                      'ADD',
                      style: GoogleFonts.poppins(
                        fontSize: dense ? 13 : 15,
                        fontWeight: FontWeight.w800,
                        color: _orangeDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
                // Lower Section: Soft peach tint with "N options"
                Expanded(
                  flex: 9,
                  child: Container(
                    width: double.infinity,
                    color: _peachOptionBg,
                    alignment: Alignment.center,
                    child: Text(
                      '${product.variants.length} options',
                      style: GoogleFonts.poppins(
                        fontSize: dense ? 9.5 : 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF87909C),
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Single-option ADD Button
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _quickAdd();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: btnWidth,
        height: btnHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _orange, width: 1.0), // Hairline border
          boxShadow: const [
            BoxShadow(
              color: Color(0x18FF5A00),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          'ADD',
          style: GoogleFonts.poppins(
            fontSize: dense ? 14 : 16,
            fontWeight: FontWeight.w800,
            color: _orangeDark,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  void _quickAdd() {
    final cart = context.read<CartProvider>();
    final variant = currentVariant;
    final ok = cart.addToCart(
      product,
      variantId: variant?.id,
      variantName: variant?.label,
      variantPrice: variant?.price,
    );
    if (ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _orange,
          ),
        );
    } else {
      _showStockLimitToast();
    }
  }

  Future<void> _openVariantSheet() async {
    final chosen = await showVariantSheet(
      context,
      product,
      initialVariant: currentVariant,
    );
    if (chosen != null && mounted) {
      setState(() => _activeVariant = chosen);
    }
  }

  void _showStockLimitToast() {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).cartStockLimit(product.stock),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Widget _buildMetadata(BuildContext context) {
    final variant = currentVariant;
    final price = variant?.price ?? product.price;
    final mrp = variant?.mrp ?? product.originalPrice;
    final discountPercent = variant != null && variant.mrp > variant.price
        ? variant.discountPercent
        : product.discountPercent;
    final hasDiscount = mrp > price;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 11, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Price line (Selling Price + Struck-through MRP)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}',
                style: GoogleFonts.poppins(
                  fontSize: dense ? 17 : 20,
                  fontWeight: FontWeight.w900,
                  color: _inkPrimary,
                  letterSpacing: -0.6,
                ),
              ),
              if (hasDiscount) ...[
                const SizedBox(width: 7),
                Text(
                  '₹${mrp.toStringAsFixed(mrp.truncateToDouble() == mrp ? 0 : 2)}',
                  style: GoogleFonts.poppins(
                    fontSize: dense ? 12 : 14,
                    color: _mrpMuted,
                    decoration: TextDecoration.lineThrough,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          // Discount line in Bright Blue (#2F6FC9)
          if (hasDiscount) ...[
            const SizedBox(height: 2),
            Text(
              '$discountPercent% OFF on MRP',
              style: GoogleFonts.poppins(
                fontSize: dense ? 11.5 : 13,
                fontWeight: FontWeight.w800,
                color: _discountBlue,
                letterSpacing: -0.3,
              ),
            ),
          ],
          // Product Name (2 lines max)
          const SizedBox(height: 3),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: dense ? 12.5 : 14,
              fontWeight: FontWeight.w700,
              color: _inkPrimary,
              height: 1.25,
            ),
          ),
          // 5 Yellow Stars + Review Count
          const SizedBox(height: 5),
          Row(
            children: [
              ...List.generate(
                5,
                (i) => const Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: _starYellow,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _getReviewCountString(product),
                style: GoogleFonts.poppins(
                  fontSize: dense ? 10.5 : 11.5,
                  fontWeight: FontWeight.w500,
                  color: _inkSecondary,
                ),
              ),
            ],
          ),
          // Delivery ETA with slate clock icon
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _clockSlate, width: 1.3),
                ),
                child: const Center(
                  child: Icon(
                    Icons.access_time_rounded,
                    size: 9,
                    color: _clockSlate,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '9 mins',
                style: GoogleFonts.poppins(
                  fontSize: dense ? 10.5 : 11.5,
                  fontWeight: FontWeight.w600,
                  color: _inkSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getReviewCountString(Product product) {
    // Generates a realistic organic review count formatted with comma e.g. 59,680
    final count = 1000 + (product.id.hashCode.abs() % 89000);
    final str = count.toString();
    if (str.length > 3) {
      return '${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
    }
    return str;
  }
}
