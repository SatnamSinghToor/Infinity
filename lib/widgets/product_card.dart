import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../models/product_variant.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import 'app_network_image.dart';
import 'edit_tools.dart';
import 'product_hero.dart';
import 'variant_sheet.dart';

/// Measurements for the two-column mobile product grid.
///
/// At a card width of about 164-166 dp these values reproduce the reference:
/// a ~190 dp image canvas, a 44 dp unit footer and a 89 x 52 dp action button.
class ProductCardMetrics {
  ProductCardMetrics._();

  static const double cardRadius = 20;
  static const double controlRadius = 16;
  static const double overlapRight = 8;
  static const double overlapIntoImage = 8;
  static const double gridSpacing = 16;
  static const double gridRunSpacing = 18;

  static double imageHeight(double cardWidth, {required bool dense}) {
    final double height = cardWidth * (dense ? 1.16 : 1.28);
    return (dense
            ? height.clamp(132.0, 200.0)
            : height.clamp(188.0, 280.0))
        .toDouble();
  }

  static double footerHeight({required bool dense}) => dense ? 44.0 : 72.0;

  /// Space for price, offer, two-line title, rating and delivery time.
  static double metadataHeight({required bool dense}) => dense ? 132.0 : 154.0;

  static double cellHeight(double cardWidth, {required bool dense}) {
    return imageHeight(cardWidth, dense: dense) +
        footerHeight(dense: dense) +
        metadataHeight(dense: dense) +
        8;
  }

  static SliverGridDelegate delegate({
    required double width,
    int columns = 2,
    bool dense = true,
  }) {
    final double spacing = columns > 2 ? 12.0 : gridSpacing;
    final double runSpacing = columns > 2 ? 14.0 : gridRunSpacing;
    final double cardWidth = (width - spacing * (columns - 1)) / columns;

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      crossAxisSpacing: spacing,
      mainAxisSpacing: runSpacing,
      mainAxisExtent: cellHeight(cardWidth, dense: dense),
    );
  }
}

/// Grocery product card with the two states from the supplied designs:
///
/// * Not in cart: outlined ADD button, with a small options footer for
///   multi-variant products.
/// * In cart: filled orange minus / quantity / plus stepper.
class ProductCard extends StatefulWidget {
  static const addKey = Key('product-card-add');
  static const stepperKey = Key('product-card-stepper');

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
    this.dense = true,
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

  Product get product => widget.product;
  bool get dense => widget.dense;
  VoidCallback? get onTap => widget.onTap;
  VoidCallback? get onFavoriteTap => widget.onFavoriteTap;
  bool get showFavorite => widget.showFavorite;

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
  static const Color _clockSlate = Color(0xFF8B94A2);
  static const Color _canvasTop = Color(0xFFFAFBFC);
  static const Color _canvasBottom = Color(0xFFEFF1F4);

  @override
  void initState() {
    super.initState();
    _activeVariant = widget.selectedVariant ?? product.firstAvailableVariant;
  }

  @override
  void didUpdateWidget(covariant ProductCard oldWidget) {
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
    return cart.getQuantity(product.id, variantId: currentVariant?.id);
  }

  @override
  Widget build(BuildContext context) {
    Widget card = LayoutBuilder(
      builder: (context, constraints) {
        final double width =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : 163.0;
        return _buildCardContent(context, width);
      },
    );

    card = ProductEditPencil(product: product, child: card);

    return Listener(
      onPointerDown: (_) => ProductHero.handOver(product.id, _heroTag),
      child: card,
    );
  }

  Widget _buildCardContent(BuildContext context, double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildVisualCard(context, width),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: _buildMetadata(context),
        ),
      ],
    );
  }

  Widget _buildVisualCard(BuildContext context, double width) {
    final variant = currentVariant;
    final String variantLabel = variant?.label ?? product.unit;
    final int qty = currentQuantity;
    final bool isAdded = qty > 0;
    final bool soldOut = !product.isAvailable || product.stock <= 0;

    final double imageHeight =
        ProductCardMetrics.imageHeight(width, dense: dense);
    final double footerHeight = ProductCardMetrics.footerHeight(dense: dense);
    final double btnWidth =
        (width * (dense ? 0.54 : 0.55)).clamp(88.0, 205.0).toDouble();
    final double btnHeight = dense ? 52.0 : 64.0;
    final double overlapTop =
        imageHeight - ProductCardMetrics.overlapIntoImage;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ProductCardMetrics.cardRadius),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1C2532),
            blurRadius: 7,
            offset: Offset(0, 2),
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
              GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: imageHeight,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(ProductCardMetrics.cardRadius),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [_canvasTop, _canvasBottom],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            dense ? 12 : 18,
                            dense ? 10 : 16,
                            dense ? 12 : 18,
                            dense ? 22 : 28,
                          ),
                          child: Opacity(
                            opacity: soldOut ? 0.45 : 1,
                            child: Hero(
                              tag: _heroTag,
                              child: _buildPhoto(),
                            ),
                          ),
                        ),
                      ),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      if (showFavorite)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _buildWishlistButton(),
                        ),
                      Positioned(
                        bottom: dense ? 10 : 14,
                        left: dense ? 10 : 14,
                        child: _buildCarouselDots(),
                      ),
                      if (product.isFood)
                        Positioned(
                          bottom: dense ? 10 : 13,
                          right: dense ? 10 : 14,
                          child: _buildVegBadge(),
                        ),
                    ],
                  ),
                ),
              ),
              Container(height: 1, color: _line),
              GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: footerHeight,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: _footerBg,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(ProductCardMetrics.cardRadius),
                    ),
                  ),
                  padding: EdgeInsets.only(
                    left: dense ? 12 : 16,
                    right: btnWidth * 0.55,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    variantLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: dense ? 14 : 18,
                      fontWeight: FontWeight.w800,
                      color: _inkPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: overlapTop,
            right: -ProductCardMetrics.overlapRight,
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: dense ? 32 : 44,
          fontWeight: FontWeight.w800,
          color: Colors.grey.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildWishlistButton() {
    final bool wished = context.watch<WishlistProvider>().isWishlisted(
          product.id,
        );

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (onFavoriteTap != null) {
          onFavoriteTap!();
        } else {
          context.read<WishlistProvider>().toggle(product);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: dense ? 30 : 34,
        height: dense ? 30 : 34,
        child: Icon(
          wished ? Icons.favorite : Icons.favorite_border,
          size: dense ? 22 : 26,
          color: wished ? const Color(0xFFEC4C54) : const Color(0xFF89919C),
        ),
      ),
    );
  }

  Widget _buildCarouselDots() {
    final int galleryCount = product.gallery.length;
    final int count = galleryCount > 1
        ? galleryCount.clamp(2, 4).toInt()
        : 4;
    final double size = dense ? 6.0 : 8.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (index) => Container(
          width: size,
          height: size,
          margin: EdgeInsets.only(right: dense ? 4 : 6),
          decoration: BoxDecoration(
            color: index == 0
                ? const Color(0xFF404650)
                : const Color(0xFFBDC3CB),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildVegBadge() {
    final bool isVeg = product.isVeg;
    final Color color = isVeg ? _vegGreen : _nonVegRed;
    final double side = dense ? 18.0 : 24.0;

    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1.6),
      ),
      child: Center(
        child: isVeg
            ? Container(
                width: side * 0.42,
                height: side * 0.42,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              )
            : Icon(
                Icons.change_history,
                size: side * 0.42,
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
          borderRadius: BorderRadius.circular(ProductCardMetrics.controlRadius),
          border: Border.all(color: Colors.grey[300]!, width: 1.2),
        ),
        alignment: Alignment.center,
        child: Text(
          'ADD',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: dense ? 13 : 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    if (isAdded) {
      return Container(
        key: ProductCard.stepperKey,
        width: btnWidth,
        height: btnHeight,
        decoration: BoxDecoration(
          color: _orange,
          borderRadius: BorderRadius.circular(ProductCardMetrics.controlRadius),
          border: Border.all(color: _orangeDark),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1AFF5A00),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(ProductCardMetrics.controlRadius),
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.read<CartProvider>().decreaseQuantity(
                        product.id,
                        variantId: currentVariant?.id,
                      );
                },
                child: const Center(
                  child: Text(
                    '−',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: 1,
              height: dense ? 22 : 26,
              color: Colors.white38,
            ),
            Expanded(
              child: Center(
                child: Text(
                  '$qty',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: dense ? 15 : 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
            Container(
              width: 1,
              height: dense ? 22 : 26,
              color: Colors.white38,
            ),
            Expanded(
              child: InkWell(
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(ProductCardMetrics.controlRadius),
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  final bool ok = context.read<CartProvider>().increaseQuantity(
                        product.id,
                        variantId: currentVariant?.id,
                      );
                  if (!ok) {
                    _showStockLimitToast();
                  }
                },
                child: const Center(
                  child: Text(
                    '+',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (hasMultipleOptions) {
      return GestureDetector(
        key: ProductCard.addKey,
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
            borderRadius: BorderRadius.circular(ProductCardMetrics.controlRadius),
            border: Border.all(color: _orange, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14FF5A00),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(ProductCardMetrics.controlRadius - 1),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      'ADD',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: dense ? 14 : 17,
                        fontWeight: FontWeight.w800,
                        color: _orangeDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    color: _peachOptionBg,
                    alignment: Alignment.center,
                    child: Text(
                      '${product.variants.length} options',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: dense ? 9.5 : 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF87909C),
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

    return GestureDetector(
      key: ProductCard.addKey,
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
          borderRadius: BorderRadius.circular(ProductCardMetrics.controlRadius),
          border: Border.all(color: _orange, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14FF5A00),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          'ADD',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: dense ? 15 : 20,
            fontWeight: FontWeight.w800,
            color: _orangeDark,
            letterSpacing: -0.35,
          ),
        ),
      ),
    );
  }

  void _quickAdd() {
    final cart = context.read<CartProvider>();
    final variant = currentVariant;
    final bool ok = cart.addToCart(
      product,
      variantId: variant?.id,
      variantName: variant?.label,
      variantPrice: variant?.price,
    );

    if (!ok) {
      _showStockLimitToast();
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${product.name} added to cart',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _orange,
        ),
      );
  }

  Future<void> _openVariantSheet() async {
    final ProductVariant? chosen = await showVariantSheet(
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
    final double price = variant?.price ?? product.price;
    final double mrp = variant?.mrp ?? product.originalPrice;
    final int discountPercent = variant != null && variant.mrp > variant.price
        ? variant.discountPercent
        : product.discountPercent;
    final bool hasDiscount = mrp > price;

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹${_rupees(price)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: dense ? 18 : 24,
                  fontWeight: FontWeight.w900,
                  color: _inkPrimary,
                  letterSpacing: -0.55,
                ),
              ),
              if (hasDiscount) ...[
                const SizedBox(width: 8),
                Text(
                  '₹${_rupees(mrp)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: dense ? 13 : 15,
                    color: _mrpMuted,
                    decoration: TextDecoration.lineThrough,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          if (hasDiscount) ...[
            const SizedBox(height: 2),
            Text(
              '$discountPercent% OFF on MRP',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: dense ? 12 : 15,
                fontWeight: FontWeight.w800,
                color: _discountBlue,
                letterSpacing: -0.3,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: dense ? 13 : 16,
              fontWeight: FontWeight.w700,
              color: _inkPrimary,
              height: 1.28,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              ...List.generate(
                5,
                (index) => Icon(
                  Icons.star_rounded,
                  size: dense ? 14 : 16,
                  color: _starYellow,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _reviewCountLabel(product),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: dense ? 11 : 13,
                  fontWeight: FontWeight.w500,
                  color: _inkSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: dense ? 15 : 18,
                height: dense ? 15 : 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _clockSlate, width: 1.5),
                ),
                child: Icon(
                  Icons.access_time_rounded,
                  size: dense ? 9 : 11,
                  color: _clockSlate,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '9 mins',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: dense ? 11 : 13,
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

  String _rupees(double value) =>
      value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);

  String _reviewCountLabel(Product product) {
    final int count = 1000 + (product.id.hashCode.abs() % 89000);
    final String str = count.toString();
    if (str.length > 3) {
      return '${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
    }
    return str;
  }
}
