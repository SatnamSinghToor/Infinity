import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../utils/constants.dart';
import 'app_network_image.dart';
import 'cart_action.dart';
import 'edit_tools.dart';
import 'product_hero.dart';
import 'variant_sheet.dart';

/// The one product card in the app.
///
/// Home, search, wishlist, deals, "similar products", the category, brand and
/// store listings and the compact three-across home shelves all draw this
/// widget, so a product looks the same wherever it turns up. The narrow shelf
/// cells pass [dense]; everything else takes the standard size.
///
/// The card is the clean shop-shelf layout: the photo across the whole top,
/// then the name in bold, the pack size under it in grey, the price in green
/// with the crossed-out MRP beside it, and the square orange button with a
/// shopping bag on it sitting at the right, level with the price — it turns
/// into the − quantity + stepper once the item is in the cart.
class ProductCard extends StatefulWidget {
  final Product product;

  /// Narrow three-across shelf cells: the same card with smaller type and a
  /// shorter bag button, so it stays readable at half the width.
  final bool dense;

  /// What tapping the card does. Screens that already wrap the card in their
  /// own GestureDetector leave this null.
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.dense = false,
    this.onTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  /// This card's own tag for the flight to the product's page. Two cards for
  /// the same product (the home screen shows one on several shelves) must
  /// never share a tag, so it is never the product id.
  final Object _heroTag = Object();

  // The card reads these as if they were its own, so the rest of it is
  // written exactly as it was when it was a plain widget.
  Product get product => widget.product;
  bool get dense => widget.dense;
  VoidCallback? get onTap => widget.onTap;

  /// The card's hairline.
  static const Color _hairline = Color(0xFFEBEBEB);

  /// What the photo is letterboxed against. White, like the studio backdrop
  /// the product shots are taken on.
  static const Color _backdrop = Color(0xFFFFFFFF);

  /// The saving line's colour: the brand orange, not green.
  static const Color _offInk = AppConstants.primaryColor;
  static const Color _muted = AppConstants.textSecondaryColor;
  static const Color _lowStockInk = Color(0xFF9A6300);
  static const Color _vegGreen = Color(0xFF2E9E3E);
  static const Color _nonVegRed = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    Widget card = _shell(context);
    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }
    card = ProductEditPencil(product: product, child: card);
    // Any press reports this card's tag before the tap is handled, so the
    // product's page can fly its photo out of this very card — whether the
    // tap is taken by the card's own gesture or by a screen that wrapped it.
    return Listener(
      onPointerDown: (_) => ProductHero.handOver(product.id, _heroTag),
      child: card,
    );
  }

  /// The shelf look: the photo in its own square, rounded box with a thin
  /// line round it, and the pack size, name and price written under it on
  /// the page itself rather than inside a white card.
  Widget _shell(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Every photo is the same square, whatever size the seller
        // uploaded. In a cell too short for a full square it shrinks,
        // rather than pushing the price off the bottom.
        Flexible(
          child: AspectRatio(aspectRatio: 1, child: _photo(context)),
        ),
        _details(),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Photo

  Widget _photo(BuildContext context) {
    final soldOut = product.stock <= 0;
    final lowStock = !soldOut && product.stock <= 5;
    final radius = BorderRadius.circular(dense ? 14 : 18);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: _backdrop,
              borderRadius: radius,
              border: Border.all(color: _hairline),
            ),
            // A sold-out photo stays visible, just pushed back.
            child: Opacity(
              opacity: soldOut ? 0.45 : 1,
              // The photo, and only the photo, is what flies to the page.
              child: Hero(tag: _heroTag, child: _picture()),
            ),
          ),
        ),
        if (soldOut)
          Positioned(left: 8, bottom: 8, child: _tag('Sold out', _muted))
        else if (lowStock)
          Positioned(
            left: 8,
            bottom: dense ? 40 : 50,
            child: _tag(
              AppLocalizations.of(context).productOnlyLeft(product.stock),
              _lowStockInk,
            ),
          ),
        // The + sits on the photo's corner, as on the grocery shelves; the
        // stepper it turns into grows leftwards over the photo from there.
        if (!soldOut)
          Positioned(
            right: dense ? 5 : 7,
            bottom: dense ? 5 : 7,
            left: dense ? 5 : 7,
            child: Align(
              alignment: Alignment.bottomRight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: CartAction(
                  product: product,
                  bagButton: true,
                  plusButton: true,
                  options: _options(context),
                  onChoose: _options(context) > 0
                      ? () => showVariantSheet(context, product)
                      : null,
                  width: dense ? double.infinity : 96,
                  addWidth: null,
                  height: dense ? 30 : 36,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// How many sizes the product comes in, from the catalogue. Zero where
  /// no catalogue is on hand (a card drawn on its own, as in tests).
  int _options(BuildContext context) {
    try {
      return context.select<ProductProvider, int>(
        (p) => p.variantCount(product.id),
      );
    } on ProviderNotFoundException {
      return 0;
    }
  }

  Widget _picture() {
    final url = product.imageUrl ?? '';
    if (url.isEmpty) return _initialTile();
    // cover: the photo fills its square edge to edge, whatever shape the
    // seller uploaded, so every card on a shelf has the same size of picture.
    return AppNetworkImage(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _initialTile(),
    );
  }

  /// No photo (or one that will not load): the product's first letter on its
  /// own colour, so the cell still reads as a product.
  Widget _initialTile() {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: _gradientFor(product.imageGradient)),
      child: Center(
        child: Text(
          product.name.isNotEmpty ? product.name[0] : '?',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: dense ? 26 : 42,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Gradient _gradientFor(String key) {
    switch (key) {
      case 'red':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEF5350), Color(0xFFC62828)],
        );
      case 'orange':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFA726), Color(0xFFEF6C00)],
        );
      case 'yellow':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFEE58), Color(0xFFF9A825)],
        );
      case 'brown':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA1887F), Color(0xFF6D4C41)],
        );
      case 'white':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
        );
    }
  }

  /// A small white chip on the photo, for the one line the card has to say
  /// about stock.
  Widget _tag(String label, Color ink) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 7,
        vertical: dense ? 3 : 3.5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(7),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: dense ? 8.5 : 9.5,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Pack size, name, price

  /// Under the photo: the pack size in small grey capitals, the name in
  /// bold, the price with the crossed-out MRP, and the saving under it.
  Widget _details() {
    final off = product.discountPercent;
    return Padding(
      padding: EdgeInsets.fromLTRB(2, dense ? 6 : 8, 2, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _metaLine(),
          SizedBox(height: dense ? 2 : 3),
          // A two-line slot even for a one-line name, so every card in a row
          // keeps its price level with its neighbours'.
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: dense ? 29 : 36),
            child: Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: dense ? 12 : 14.5,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: AppConstants.textPrimaryColor,
              ),
            ),
          ),
          SizedBox(height: dense ? 3 : 4),
          _priceLine(),
          if (off > 0)
            Text(
              '$off% off',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: dense ? 11 : 12.5,
                fontWeight: FontWeight.w600,
                color: _offInk,
              ),
            ),
        ],
      ),
    );
  }

  /// The pack size in small grey capitals ("250 GM"), with the veg mark
  /// before it when the product is food.
  ///
  /// Scaled down rather than clipped if the line is ever narrower than it
  /// is, so a long pack size stays whole and readable.
  Widget _metaLine() {
    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (product.isFood)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: _vegMark(),
              ),
            Text(
              product.unit.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: dense ? 10.5 : 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
                color: _muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceLine() {
    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              product.formattedPrice,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: dense ? 13 : 15.5,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimaryColor,
              ),
            ),
            if (product.originalPrice > product.price)
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Text(
                  product.formattedOriginalPrice,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: dense ? 10.5 : 12,
                    color: _muted,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The little green (or red) mark Indian shoppers look for, shown only on
  /// food, where it means something.
  Widget _vegMark() {
    final color = product.isVeg ? _vegGreen : _nonVegRed;
    final side = dense ? 10.0 : 11.0;
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.2),
        borderRadius: BorderRadius.circular(2.5),
      ),
      child: Center(
        child: Container(
          width: side / 2.2,
          height: side / 2.2,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
