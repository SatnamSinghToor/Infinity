import 'package:flutter/material.dart';

import 'diwali_data.dart';
import 'diwali_icons.dart';
import 'diwali_painters.dart';
import 'diwali_store.dart';
import 'diwali_theme.dart';

/// Wraps every bundled photograph with a consistent decode size and a
/// graceful fallback if an asset is ever renamed.
class DiwaliAssetImage extends StatelessWidget {
  const DiwaliAssetImage({
    super.key,
    required this.asset,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.cacheWidth = 480,
  });

  final String asset;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) => Image.asset(
        asset,
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
        cacheWidth: cacheWidth,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: DiwaliColors.cream3,
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_outlined,
            color: DiwaliColors.wine600,
            size: 26,
          ),
        ),
      );
}

enum DiwaliCardImageStyle { arch, rounded, square }

/// A single storefront product tile.
///
/// The card intentionally carries all of the states seen in the reference:
/// measurement selector, wishlist, sponsored marker, price-drop ribbon,
/// rating, variant count, low-stock warning, ADD → stepper, and "Similar".
class DiwaliProductCard extends StatelessWidget {
  const DiwaliProductCard({
    super.key,
    required this.product,
    required this.width,
    this.style = DiwaliCardImageStyle.rounded,
    this.showDeliveryTime = true,
    this.onTap,
  });

  final DiwaliProduct product;
  final double width;
  final DiwaliCardImageStyle style;
  final bool showDeliveryTime;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isArch = style == DiwaliCardImageStyle.arch;
    final imageHeight = width * (isArch ? 1.02 : 0.90);
    final compact = width < 160;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---- Image stack ---------------------------------------------
          SizedBox(
            height: imageHeight + (product.highlight ? 16 : 0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: imageHeight,
                  child: _ProductImage(
                    product: product,
                    width: width,
                    height: imageHeight,
                    style: style,
                    showDeliveryTime: showDeliveryTime,
                    onTap: onTap,
                  ),
                ),
                if (product.badge.isNotEmpty)
                  Positioned(
                    left: 6,
                    top: 8,
                    child: _Badge(label: product.badge),
                  ),
                if (product.highlight)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Center(child: _PriceDropChip(offer: product.offer)),
                  ),
              ],
            ),
          ),
          SizedBox(height: compact ? 7 : 9),

          // ---- Measurement selector ------------------------------------
          _MeasureChip(
            label: product.chip.isNotEmpty ? product.chip : product.qty,
            width: width,
          ),
          const SizedBox(height: 6),

          // ---- Name -----------------------------------------------------
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DiwaliText.body(
              compact ? 11.5 : 12.5,
              color: DiwaliColors.ink2,
              height: 1.32,
            ),
          ),
          const SizedBox(height: 5),

          // ---- Price ----------------------------------------------------
          _PriceRow(product: product, compact: compact),
          if (product.offer.isNotEmpty && !product.highlight) ...[
            const SizedBox(height: 2),
            Text(
              product.offer,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DiwaliText.body(
                10.5,
                color: DiwaliColors.green,
                weight: FontWeight.w700,
              ),
            ),
          ],
          if (product.variants.isNotEmpty) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${product.variants} (${product.qty})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DiwaliText.body(10.5, color: DiwaliColors.muted),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 14, color: DiwaliColors.muted),
              ],
            ),
          ],
          if (product.rating > 0) ...[
            const SizedBox(height: 6),
            _RatingBadge(rating: product.rating, reviews: product.reviews),
          ],
          if (product.stock.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              product.stock,
              style: DiwaliText.body(
                10.5,
                color: DiwaliColors.zomato,
                weight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 9),

          // ---- ADD / stepper --------------------------------------------
          DiwaliAddControl(product: product),
          const SizedBox(height: 7),
          _SimilarRow(product: product),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({
    required this.product,
    required this.width,
    required this.height,
    required this.style,
    required this.showDeliveryTime,
    required this.onTap,
  });

  final DiwaliProduct product;
  final double width;
  final double height;
  final DiwaliCardImageStyle style;
  final bool showDeliveryTime;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isArch = style == DiwaliCardImageStyle.arch;
    final image = Stack(
      children: [
        Positioned.fill(
          child: DiwaliAssetImage(
            asset: product.asset,
            width: width,
            height: height,
          ),
        ),
        // Soft bottom scrim keeps the time / eco chips legible.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0x33000000)],
                stops: [0.65, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          left: 6,
          bottom: 5,
          child: Row(
            children: [
              if (showDeliveryTime) _DeliveryChip(time: product.time),
              if (isArch) ...[
                const SizedBox(width: 4),
                const _EcoChip(),
              ],
            ],
          ),
        ),
        if (product.isAd)
          Positioned(
            left: 7,
            top: 7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xB3000000),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                'Ad',
                style: DiwaliText.body(9, color: Colors.white),
              ),
            ),
          ),
        Positioned(
          right: 6,
          top: 6,
          child: _WishlistButton(product: product),
        ),
      ],
    );

    final shaped = isArch
        ? ClipPath(
            clipper: const DiwaliArchClipper(bottomRadius: 10),
            child: image,
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(
              style == DiwaliCardImageStyle.square ? 3 : 10,
            ),
            child: image,
          );

    if (onTap == null) return shaped;
    return GestureDetector(onTap: onTap, child: shaped);
  }
}

class _DeliveryChip extends StatelessWidget {
  const _DeliveryChip({required this.time});

  final String time;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(240),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time_rounded,
                size: 10, color: DiwaliColors.ink2),
            const SizedBox(width: 2),
            Text(
              time,
              style: DiwaliText.body(9, weight: FontWeight.w700),
            ),
          ],
        ),
      );
}

class _EcoChip extends StatelessWidget {
  const _EcoChip();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(230),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'eco',
          style: DiwaliText.body(
            9,
            color: DiwaliColors.green,
            weight: FontWeight.w800,
          ),
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE9A8),
          border: Border.all(color: const Color(0xFFD9A93F)),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DiwaliText.body(
            8.5,
            color: const Color(0xFF6B3A00),
            weight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      );
}

/// The purple-and-yellow "PRICE DROP / UPTO 60% OFF" ribbon that overlaps the
/// bottom of a hero product tile.
class _PriceDropChip extends StatelessWidget {
  const _PriceDropChip({required this.offer});

  final String offer;

  @override
  Widget build(BuildContext context) => Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: DiwaliColors.plum,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFFFFD15C), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DiwaliDiyaMark(size: 22, color: Color(0xFFFFD15C)),
            const SizedBox(width: 4),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRICE DROP',
                  style: DiwaliText.body(
                    8,
                    color: DiwaliColors.yellow,
                    weight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  offer.isNotEmpty ? offer : 'UPTO 60% OFF',
                  style: DiwaliText.body(
                    10,
                    color: Colors.white,
                    weight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _MeasureChip extends StatelessWidget {
  const _MeasureChip({required this.label, required this.width});

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) => Container(
        constraints: BoxConstraints(maxWidth: width),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F3),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFFE7E7E2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DiwaliText.body(10.5, color: DiwaliColors.ink2),
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 13, color: DiwaliColors.ink2),
          ],
        ),
      );
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.product, required this.compact});

  final DiwaliProduct product;
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            product.price,
            style: DiwaliText.body(
              compact ? 14 : 15.5,
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              product.mrp,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DiwaliText.body(
                compact ? 10.5 : 11,
                color: DiwaliColors.muted,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      );
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating, required this.reviews});

  final int rating;
  final String reviews;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFFE4E4DE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$rating',
              style: DiwaliText.body(10, weight: FontWeight.w700),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.star_rounded, size: 11, color: DiwaliColors.green),
            const SizedBox(width: 4),
            Text(
              '($reviews)',
              style: DiwaliText.body(9.5, color: DiwaliColors.muted),
            ),
          ],
        ),
      );
}

class _WishlistButton extends StatelessWidget {
  const _WishlistButton({required this.product});

  final DiwaliProduct product;

  @override
  Widget build(BuildContext context) {
    final store = DiwaliScope.of(context);
    final active = store.isWishlisted(product);
    return GestureDetector(
      onTap: () => store.toggleWishlist(product),
      child: AnimatedContainer(
        duration: DiwaliMotion.quick,
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(242),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 4),
          ],
        ),
        child: Icon(
          active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 17,
          color: active ? DiwaliColors.zomato : DiwaliColors.ink2,
        ),
      ),
    );
  }
}

/// ADD button morphs into a ± stepper once an item is in the cart.
class DiwaliAddControl extends StatelessWidget {
  const DiwaliAddControl({super.key, required this.product, this.height = 34});

  final DiwaliProduct product;
  final double height;

  @override
  Widget build(BuildContext context) {
    final store = DiwaliScope.of(context);
    final qty = store.quantityOf(product);

    if (qty == 0) {
      return GestureDetector(
        onTap: () => store.add(product),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: DiwaliColors.magenta, width: 1.2),
          ),
          child: Center(
            child: Text(
              'ADD',
              style: DiwaliText.body(
                13,
                color: DiwaliColors.magenta,
                weight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: DiwaliColors.magenta,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 36,
            height: height,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 17,
              onPressed: () => store.remove(product),
              icon: const Icon(Icons.remove_rounded, color: Colors.white),
            ),
          ),
          Text(
            '$qty',
            style: DiwaliText.body(
              14,
              color: Colors.white,
              weight: FontWeight.w800,
            ),
          ),
          SizedBox(
            width: 36,
            height: height,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 17,
              onPressed: () => store.add(product),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimilarRow extends StatelessWidget {
  const _SimilarRow({required this.product});

  final DiwaliProduct product;

  @override
  Widget build(BuildContext context) {
    if (!product.similar) return const SizedBox(height: 15);
    return GestureDetector(
      onTap: () {},
      child: Row(
        children: [
          Text(
            'Similar',
            style: DiwaliText.body(
              10.5,
              color: DiwaliColors.muted,
              weight: FontWeight.w500,
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 10, color: DiwaliColors.muted),
        ],
      ),
    );
  }
}

/// Section heading with twin sparkles and an optional "SEE ALL" action.
class DiwaliSectionHeading extends StatelessWidget {
  const DiwaliSectionHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.onSeeAll,
    this.seeAllLabel = 'SEE ALL',
    this.titleSize,
    this.color = DiwaliColors.wine600,
    this.center = false,
    this.showRule = true,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;
  final String seeAllLabel;
  final double? titleSize;
  final Color color;
  final bool center;
  final bool showRule;

  @override
  Widget build(BuildContext context) {
    final size = titleSize ?? DiwaliLayout(MediaQuery.sizeOf(context).width).sectionTitle;
    final title = Row(
      mainAxisSize: center ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment:
          center ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        DiwaliSparkle(color: color, size: size * 0.62),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            this.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: DiwaliText.serifStyle(size, color: color).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        DiwaliSparkle(color: color, size: size * 0.62),
      ],
    );

    return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (center) const Spacer(),
            if (!center) Expanded(child: title),
            if (center) title,
            if (center) const Spacer(),
            if (onSeeAll != null && !center)
              GestureDetector(
                onTap: onSeeAll,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: DiwaliColors.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        seeAllLabel,
                        style: DiwaliText.body(
                          9.5,
                          color: DiwaliColors.wine600,
                          weight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 10, color: DiwaliColors.wine600),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: DiwaliText.body(
              DiwaliLayout(MediaQuery.sizeOf(context).width).sectionSub,
              color: DiwaliColors.ink2,
            ),
          ),
        ],
        if (showRule) ...[
          const SizedBox(height: 9),
          DiwaliDiamondRule(color: color.withAlpha(191), height: 9),
        ],
      ],
    );
  }
}

/// A horizontally scrollable product carousel with desktop arrow controls.
class DiwaliProductRail extends StatefulWidget {
  const DiwaliProductRail({
    super.key,
    required this.products,
    required this.availableWidth,
    this.style = DiwaliCardImageStyle.rounded,
    this.pad,
    this.onProductTap,
  });

  final List<DiwaliProduct> products;
  final double availableWidth;
  final DiwaliCardImageStyle style;
  final double? pad;
  final ValueChanged<DiwaliProduct>? onProductTap;

  @override
  State<DiwaliProductRail> createState() => _DiwaliProductRailState();
}

class _DiwaliProductRailState extends State<DiwaliProductRail> {
  final ScrollController _controller = ScrollController();
  bool _atStart = true;
  bool _atEnd = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    final nextStart = pos.pixels <= 1;
    final nextEnd = pos.pixels >= pos.maxScrollExtent - 1;
    if (nextStart != _atStart || nextEnd != _atEnd) {
      setState(() {
        _atStart = nextStart;
        _atEnd = nextEnd;
      });
    }
  }

  void _scroll(double delta) {
    if (!_controller.hasClients) return;
    _controller.animateTo(
      (_controller.offset + delta)
          .clamp(0.0, _controller.position.maxScrollExtent),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = DiwaliLayout(widget.availableWidth);
    final itemWidth = layout.railItemWidth(widget.availableWidth);
    final pad = widget.pad ?? layout.pad;
    final gap = layout.isExpanded ? 16.0 : 12.0;

    return SizedBox(
      height: _railHeight(itemWidth, widget.style),
      child: Stack(
        children: [
          Positioned.fill(
            child: ListView.separated(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: pad),
              itemCount: widget.products.length,
              separatorBuilder: (_, __) => SizedBox(width: gap),
              itemBuilder: (context, index) => DiwaliProductCard(
                product: widget.products[index],
                width: itemWidth,
                style: widget.style,
                onTap: widget.onProductTap == null
                    ? null
                    : () => widget.onProductTap!(widget.products[index]),
              ),
            ),
          ),
          if (layout.showRailArrows && !_atEnd)
            Positioned(
              right: 3,
              top: itemWidth * 0.42,
              child: DiwaliCircleButton(
                onTap: () => _scroll((itemWidth + gap) * 2),
              ),
            ),
          if (layout.showRailArrows && !_atStart)
            Positioned(
              left: 3,
              top: itemWidth * 0.42,
              child: DiwaliCircleButton(
                onTap: () => _scroll(-(itemWidth + gap) * 2),
                icon: Icons.arrow_back_ios_rounded,
              ),
            ),
        ],
      ),
    );
  }

  static double _railHeight(double itemWidth, DiwaliCardImageStyle style) {
    // Image + measure + name + price + optional offer + rating + ADD + similar
    final image = itemWidth * (style == DiwaliCardImageStyle.arch ? 1.02 : 0.90);
    return image + 268;
  }
}
