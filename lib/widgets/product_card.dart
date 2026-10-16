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

/// Orange Grocery UI Product Card — Exact specification clone.
///
/// Visual Specifications:
/// - Card: 20px outer radius, 1px light-grey border (#E3E6EB)
/// - Pale image canvas with contain photo fit (#FAFBFC -> #EFF1F4)
/// - Wishlist heart icon at top-right
/// - Carousel dots at bottom-left (• • • •)
/// - Green vegetarian food indicator (#237A35) at bottom-right of image
/// - Footer: #F8F9FB background with variant label on left
/// - Overlapping ADD / Stepper control sitting directly across the footer divider
/// - ADD button: white fill, 2px orange border (#FF5A00), bold orange "ADD"
///   (+ "N options" subtext for multi-option products)
/// - Stepper: solid orange (#FF5A00) pill with white − qty + controls
///   (+ "Change option" underlined link for multi-option products)
/// - Metadata below card: Price, crossed-out MRP, blue discount (% OFF on MRP),
///   product title, 5 yellow stars + reviews, and delivery ETA with clock icon.
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

  // Colors as specified in Orange Grocery UI spec
  static const Color _orange = Color(0xFFFF5A00);
  static const Color _orangeDark = Color(0xFFE64E00);
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
        // 1. Main visual card container
        _buildVisualCard(context),
        // 2. Metadata below card (Price, MRP, Discount, Title, Rating, Delivery)
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

    // Responsive dimensions
    final imageHeight = dense ? 132.0 : 158.0;
    final footerHeight = dense ? 46.0 : 52.0;
    final btnWidth = dense ? 78.0 : 92.0;
    final btnHeight = dense ? 38.0 : 44.0;
    // Perfectly overlaps the footer divider line (half above in image canvas, half below in footer)
    final overlapTop = imageHeight - (btnHeight * 0.48);
    // Overlaps the lower-right card boundary by a small amount as per PDF overlap rule
    final overlapRight = dense ? -2.0 : -4.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line, width: 1),
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
              // Top: Image Canvas with top rounded corners
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
                      // Product photo
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
                      // Sold out tag
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
                      // Wishlist heart button (top-right)
                      if (showFavorite)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _buildWishlistButton(),
                        ),
                      // Carousel dots (bottom-left)
                      Positioned(
                        bottom: 9,
                        left: 10,
                        child: _buildCarouselDots(),
                      ),
                      // Indian Vegetarian symbol (bottom-right of image)
                      if (product.isFood)
                        Positioned(
                          bottom: 9,
                          right: 10,
                          child: _buildVegBadge(),
                        ),
                    ],
                  ),
                ),
                // Divider line
                Container(
                  height: 1,
                  color: _line,
                ),
                // Bottom: Variant footer with bottom rounded corners
                Container(
                  height: footerHeight,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: _footerBg,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(19)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      // Variant label (e.g., "1 kg", "750 g")
                      Flexible(
                        child: Text(
                          variantLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: dense ? 13 : 15,
                            fontWeight: FontWeight.w800,
                            color: _inkPrimary,
                            letterSpacing: -0.3,
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
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x15000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            size: dense ? 16 : 18,
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
          width: 5.5,
          height: 5.5,
          margin: const EdgeInsets.only(right: 3.5),
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
      width: dense ? 16 : 19,
      height: dense ? 16 : 19,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color, width: 1.5),
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
                width: dense ? 7 : 8.5,
                height: dense ? 7 : 8.5,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              )
            : Icon(
                Icons.change_history,
                size: dense ? 7 : 8.5,
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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[300]!, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          'ADD',
          style: GoogleFonts.poppins(
            fontSize: dense ? 12 : 14,
            fontWeight: FontWeight.w700,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    if (isAdded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Orange - qty + stepper
          Container(
            width: btnWidth,
            height: btnHeight,
            decoration: BoxDecoration(
              color: _orange,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _orangeDark, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3BFF5A00),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Minus button
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final cart = context.read<CartProvider>();
                      cart.decreaseQuantity(
                        product.id,
                        variantId: currentVariant?.id,
                      );
                    },
                    child: const Center(
                      child: Icon(Icons.remove, color: Colors.white, size: 16),
                    ),
                  ),
                ),
                // Quantity count with vertical dividing lines
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  height: btnHeight * 0.7,
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      vertical: BorderSide(
                        color: Colors.white.withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$qty',
                      style: GoogleFonts.poppins(
                        fontSize: dense ? 12 : 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Plus button
                Expanded(
                  child: InkWell(
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
                      child: Icon(Icons.add, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // "Change option" text link for multi-option products
          if (hasMultipleOptions)
            GestureDetector(
              onTap: () => _openVariantSheet(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  'Change option',
                  style: GoogleFonts.poppins(
                    fontSize: dense ? 9.5 : 10.5,
                    fontWeight: FontWeight.w800,
                    color: _orangeDark,
                    decoration: TextDecoration.underline,
                    decorationColor: _orangeDark,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Default ADD button state
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (hasMultipleOptions) {
          _openVariantSheet();
        } else {
          _quickAdd();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: btnWidth,
        height: btnHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _orange, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18FF5A00),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: hasMultipleOptions
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ADD',
                    style: GoogleFonts.poppins(
                      fontSize: dense ? 12 : 14,
                      fontWeight: FontWeight.w800,
                      color: _orangeDark,
                      height: 1.1,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    '${product.variants.length} options',
                    style: GoogleFonts.poppins(
                      fontSize: dense ? 8.5 : 9.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF87909C),
                      height: 1.1,
                    ),
                  ),
                ],
              )
            : Text(
                'ADD',
                style: GoogleFonts.poppins(
                  fontSize: dense ? 13 : 15,
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
      padding: const EdgeInsets.fromLTRB(2, 9, 2, 0),
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
                  fontSize: dense ? 15 : 18,
                  fontWeight: FontWeight.w900,
                  color: _inkPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              if (hasDiscount) ...[
                const SizedBox(width: 6),
                Text(
                  '₹${mrp.toStringAsFixed(mrp.truncateToDouble() == mrp ? 0 : 2)}',
                  style: GoogleFonts.poppins(
                    fontSize: dense ? 11 : 13,
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
                fontSize: dense ? 11 : 12.5,
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
              fontSize: dense ? 12 : 13.5,
              fontWeight: FontWeight.w700,
              color: _inkPrimary,
              height: 1.25,
            ),
          ),
          // 5 Yellow Stars + Review Count
          const SizedBox(height: 4),
          Row(
            children: [
              ...List.generate(
                5,
                (i) => const Icon(
                  Icons.star_rounded,
                  size: 13,
                  color: _starYellow,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _getReviewCountString(product),
                style: GoogleFonts.poppins(
                  fontSize: dense ? 10 : 11,
                  fontWeight: FontWeight.w500,
                  color: _inkSecondary,
                ),
              ),
            ],
          ),
          // Delivery ETA with slate clock icon
          const SizedBox(height: 3),
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
                  fontSize: dense ? 10 : 11,
                  fontWeight: FontWeight.w500,
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
