import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'festive_art.dart';
import 'festive_data.dart';
import 'festive_tokens.dart';
import 'festive_widgets.dart';

/// The gold "Diwali" wordmark.
///
/// Drawn with a [TextPainter] instead of a `Text` widget so the diamond
/// ornaments can be placed exactly over the two "i" dots, using the metrics of
/// the bundled Playfair Display face (advance centres 0.309 and 0.948 of the
/// word, dot centre 0.74 em above the baseline).
class FestiveWordmark extends StatelessWidget {
  const FestiveWordmark({
    super.key,
    required this.text,
    required this.fontSize,
    required this.palette,
  });

  final String text;
  final double fontSize;
  final FestivePalette palette;

  @override
  Widget build(BuildContext context) {
    final TextScaler scaler = clampTextScaler(MediaQuery.textScalerOf(context));
    final TextStyle style =
        FestiveType.serif(fontSize, color: Colors.white, height: 1);
    final TextPainter measure = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();

    return Semantics(
      header: true,
      label: text,
      child: ExcludeSemantics(
        child: SizedBox(
          width: double.infinity,
          height: measure.height,
          child: CustomPaint(
            painter: _WordmarkPainter(
              text: text,
              style: style,
              textScaler: scaler,
              gradient: palette.wordmarkGradient,
              ornament: palette.gold,
              ornamentEdge: palette.goldDeep,
              shadow: palette.bannerEdge,
            ),
          ),
        ),
      ),
    );
  }
}

class _WordmarkPainter extends CustomPainter {
  const _WordmarkPainter({
    required this.text,
    required this.style,
    required this.textScaler,
    required this.gradient,
    required this.ornament,
    required this.ornamentEdge,
    required this.shadow,
  });

  final String text;
  final TextStyle style;
  final TextScaler textScaler;
  final LinearGradient gradient;
  final Color ornament;
  final Color ornamentEdge;
  final Color shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final TextPainter tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();

    final Offset origin = Offset(
      (size.width - tp.width) / 2,
      (size.height - tp.height) / 2,
    );
    final Rect textRect = Rect.fromLTWH(origin.dx, origin.dy, tp.width, tp.height);

    // A soft drop shadow gives the lettering the printed, embossed feel of the
    // reference without a second layer of text.
    canvas.save();
    canvas.translate(0, 2);
    final TextPainter shadowPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(color: shadow.withAlpha(90)),
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    shadowPainter.paint(canvas, origin);
    canvas.restore();

    final TextPainter filled = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(
          foreground: Paint()
            ..shader = gradient.createShader(textRect)
            ..isAntiAlias = true,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    filled.paint(canvas, origin);
    shadowPainter.dispose();
    filled.dispose();

    final double baselineDistance =
        tp.computeDistanceToActualBaseline(TextBaseline.alphabetic) ??
            tp.height * 0.78;
    final double baseline = origin.dy + baselineDistance;
    final double paintedSize = textScaler.scale(style.fontSize ?? 0);
    final double dotSize = paintedSize * 0.27;
    final double dotCenterY = baseline - paintedSize * 0.74;

    // The two "i" letters, from the font's own advance widths.
    for (final double fraction in const <double>[0.309, 0.948]) {
      final double cx = origin.dx + tp.width * fraction;
      final Offset centre = Offset(cx, dotCenterY);

      canvas.drawCircle(
        centre,
        dotSize * 0.95,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[ornament.withAlpha(110), ornament.withAlpha(0)],
          ).createShader(Rect.fromCircle(center: centre, radius: dotSize * 0.95)),
      );

      canvas.save();
      canvas.translate(centre.dx, centre.dy);
      canvas.rotate(math.pi / 4);
      final RRect diamond = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: dotSize, height: dotSize),
        Radius.circular(dotSize * 0.2),
      );
      canvas.drawRRect(
        diamond,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[ornament, ornamentEdge],
          ).createShader(Rect.fromCenter(
            center: Offset.zero,
            width: dotSize,
            height: dotSize,
          )),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: dotSize * 0.3,
            height: dotSize * 0.3,
          ),
          Radius.circular(dotSize * 0.08),
        ),
        Paint()..color = const Color(0xFF8C0B3B),
      );
      canvas.restore();
    }
    tp.dispose();
  }

  @override
  bool shouldRepaint(_WordmarkPainter oldDelegate) =>
      oldDelegate.text != text ||
      oldDelegate.style != style ||
      oldDelegate.ornament != ornament ||
      oldDelegate.gradient != gradient;
}

/// Eyebrow + wordmark + date, the type block at the top of the banner.
class FestiveBannerTitle extends StatelessWidget {
  const FestiveBannerTitle({
    super.key,
    required this.copy,
    required this.palette,
    required this.typeScale,
    required this.wordmarkSize,
  });

  final FestiveCopy copy;
  final FestivePalette palette;
  final double typeScale;
  final double wordmarkSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          copy.bannerEyebrow,
          textAlign: TextAlign.center,
          style: FestiveType.body(
            13.5 * typeScale,
            color: palette.gold,
            weight: FontWeight.w600,
            letterSpacing: 2.6 * typeScale,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        FestiveWordmark(
          text: copy.bannerTitle,
          fontSize: wordmarkSize,
          palette: palette,
        ),
        const SizedBox(height: 2),
        Text(
          copy.bannerDate,
          textAlign: TextAlign.center,
          style: FestiveType.body(
            11 * typeScale,
            color: palette.pink,
            weight: FontWeight.w500,
            letterSpacing: 2.0 * typeScale,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

/// One arch tile: pointed top and bottom, terracotta gradient, gold hairline
/// border and a product photograph bleeding out of the bottom point.
class FestiveArchTile extends StatelessWidget {
  const FestiveArchTile({
    super.key,
    required this.tile,
    required this.width,
    required this.height,
    required this.palette,
    required this.typeScale,
    this.onTap,
  });

  final FestiveTile tile;
  final double width;
  final double height;
  final FestivePalette palette;
  final double typeScale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FestiveTap(
      onTap: onTap,
      hoverLift: 5,
      hoverScale: 1.015,
      semanticLabel: tile.title.replaceAll('\n', ' '),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: ClipPath(
                clipper: const ArchTileClipper(),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(gradient: palette.tileGradient),
                    ),
                    // Warm radial highlight behind the photograph.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, 0.05),
                          radius: 0.85,
                          colors: <Color>[
                            palette.tileTop.withAlpha(120),
                            palette.tileTop.withAlpha(0),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: height * 0.34,
                      bottom: 0,
                      child: Transform.scale(
                        scale: tile.imageScale,
                        child: Image.asset(
                          tile.asset,
                          fit: BoxFit.cover,
                          alignment: tile.focalAlignment,
                          filterQuality: FilterQuality.medium,
                          // Decode at roughly the drawn size: six tiles of
                          // 760 px sources would otherwise cost ~14 MB.
                          cacheWidth: (width * MediaQuery.devicePixelRatioOf(context))
                              .round()
                              .clamp(120, 900)
                              .toInt(),
                          errorBuilder: (BuildContext context, Object error,
                              StackTrace? stack) {
                            return Center(
                              child: FestiveGlyphIcon(
                                glyph: FestiveGlyph.diya,
                                color: palette.gold.withAlpha(180),
                                size: width * 0.32,
                                strokeWidth: 1.4,
                                fill: palette.gold.withAlpha(40),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Dissolve the top of the photograph into the tile.
                    Positioned(
                      left: 0,
                      right: 0,
                      top: height * 0.34,
                      height: height * 0.30,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                palette.tileTop,
                                palette.tileTop.withAlpha(0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          width * 0.07,
                          height * 0.105,
                          width * 0.07,
                          0,
                        ),
                        child: Text(
                          tile.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: FestiveType.body(
                            12.5 * typeScale,
                            color: Colors.white,
                            weight: FontWeight.w600,
                            height: 1.22,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: ArchTileBorderPainter(
                    color: palette.tileBorder,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The 3 / 4 / 6 column arch grid. Column count and tile size come from the
/// available width, never from a device name.
class FestiveTileGrid extends StatelessWidget {
  const FestiveTileGrid({
    super.key,
    required this.tiles,
    required this.contentWidth,
    required this.size,
    required this.palette,
    required this.typeScale,
    this.onTileTap,
  });

  final List<FestiveTile> tiles;
  final double contentWidth;
  final FestiveSize size;
  final FestivePalette palette;
  final double typeScale;
  final ValueChanged<FestiveTile>? onTileTap;

  @override
  Widget build(BuildContext context) {
    final int columns = switch (size) {
      FestiveSize.compact => 3,
      FestiveSize.medium => 4,
      FestiveSize.expanded => 6,
    };
    final double gap = switch (size) {
      FestiveSize.compact => 10,
      FestiveSize.medium => 14,
      FestiveSize.expanded => 16,
    };
    final double tileWidth = (contentWidth - gap * (columns - 1)) / columns;
    final double tileHeight = tileWidth * FestiveMetrics.tileAspect;

    return SizedBox(
      width: contentWidth,
      child: Wrap(
        spacing: gap,
        runSpacing: gap,
        children: <Widget>[
          for (final FestiveTile tile in tiles)
            FestiveArchTile(
              tile: tile,
              width: tileWidth,
              height: tileHeight,
              palette: palette,
              typeScale: typeScale,
              onTap: onTileTap == null ? null : () => onTileTap!(tile),
            ),
        ],
      ),
    );
  }
}

/// Section heading: a heavy title and a quiet subtitle.
class FestiveSectionHeading extends StatelessWidget {
  const FestiveSectionHeading({
    super.key,
    required this.title,
    required this.subtitle,
    required this.palette,
    required this.typeScale,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final FestivePalette palette;
  final double typeScale;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                style: FestiveType.body(
                  15.5 * typeScale,
                  color: palette.ink,
                  weight: FontWeight.w800,
                  letterSpacing: -0.2,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: FestiveType.body(
                  12.5 * typeScale,
                  color: palette.inkSoft,
                  weight: FontWeight.w400,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// A product tile: photography, wishlist, rating, price and the ADD → stepper
/// control.
class FestiveProductCard extends StatelessWidget {
  const FestiveProductCard({
    super.key,
    required this.product,
    required this.width,
    required this.palette,
    required this.typeScale,
    required this.quantity,
    required this.wishlisted,
    required this.onAdd,
    required this.onRemove,
    required this.onWishlist,
    this.onTap,
  });

  final FestiveProduct product;
  final double width;
  final FestivePalette palette;
  final double typeScale;
  final int quantity;
  final bool wishlisted;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onWishlist;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final double imageSize = width;
    final double textFactor =
        MediaQuery.textScalerOf(context).scale(10) / 10;
    return FestiveTap(
      onTap: onTap,
      hoverLift: 4,
      hoverScale: 1.012,
      semanticLabel: '${product.name}, ${product.unit}, ${rupee(product.price)}',
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: imageSize,
              height: imageSize,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: palette.surfaceSoft),
                        child: Image.asset(
                          product.asset,
                          fit: BoxFit.cover,
                          cacheWidth:
                              (imageSize * MediaQuery.devicePixelRatioOf(context))
                                  .round()
                                  .clamp(120, 900)
                                  .toInt(),
                          errorBuilder: (BuildContext context, Object error,
                              StackTrace? stack) {
                            return const SizedBox.expand();
                          },
                        ),
                      ),
                    ),
                  ),
                  if (product.badge != null)
                    Positioned(
                      left: 0,
                      top: 8,
                      child: _Badge(label: product.badge!, palette: palette),
                    ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: _WishlistButton(
                      active: wishlisted,
                      palette: palette,
                      onTap: onWishlist,
                      size: 28,
                    ),
                  ),
                  if (product.rating >= 4)
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: _RatingChip(rating: product.rating, palette: palette),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 12 * typeScale * 1.3 * 2 * textFactor,
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: FestiveType.body(
                  12 * typeScale,
                  color: palette.ink,
                  weight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              product.unit,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FestiveType.body(
                10.5 * typeScale,
                color: palette.inkSoft,
                weight: FontWeight.w400,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        rupee(product.price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FestiveType.body(
                          12.5 * typeScale,
                          color: palette.ink,
                          weight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      if (product.hasDiscount)
                        Text(
                          rupee(product.mrp),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FestiveType.body(
                            10 * typeScale,
                            color: palette.inkSoft,
                            weight: FontWeight.w400,
                            height: 1.2,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ),
                AddToCartButton(
                  quantity: quantity,
                  palette: palette,
                  onAdd: onAdd,
                  onRemove: onRemove,
                  typeScale: typeScale,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.palette});

  final String label;
  final FestivePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: palette.surface.withAlpha(palette.isDark ? 230 : 242),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.star_rounded, size: 10, color: palette.add),
          const SizedBox(width: 2),
          Text(
            label,
            style: FestiveType.body(
              8.5,
              color: palette.ink,
              weight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.rating, required this.palette});

  final double rating;
  final FestivePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: palette.surface.withAlpha(238),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            rating.toStringAsFixed(1),
            style: FestiveType.body(
              9,
              color: palette.ink,
              weight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(width: 2),
          Icon(Icons.star_rounded, size: 9, color: palette.add),
        ],
      ),
    );
  }
}

/// Heart with a pop when it is toggled.
class _WishlistButton extends StatelessWidget {
  const _WishlistButton({
    required this.active,
    required this.palette,
    required this.onTap,
    required this.size,
  });

  final bool active;
  final FestivePalette palette;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: active,
      label: active ? 'Remove from wishlist' : 'Add to wishlist',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.surface.withAlpha(235),
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withAlpha(28),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: FestiveMotion.base,
            switchInCurve: FestiveMotion.spring,
            transitionBuilder: (Widget child, Animation<double> anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey<bool>(active),
              size: size * 0.58,
              color: active ? palette.wishlist : palette.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}

/// ADD pill that morphs into a quantity stepper.
class AddToCartButton extends StatelessWidget {
  const AddToCartButton({
    super.key,
    required this.quantity,
    required this.palette,
    required this.onAdd,
    required this.onRemove,
    required this.typeScale,
  });

  final int quantity;
  final FestivePalette palette;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final double typeScale;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(7);
    final Widget child = quantity == 0
        ? Semantics(
            button: true,
            label: 'Add to cart',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAdd,
              child: AnimatedContainer(
                duration: FestiveMotion.fast,
                width: 42 * typeScale,
                height: 27 * typeScale,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.addSoft,
                  borderRadius: radius,
                  border: Border.all(color: palette.add.withAlpha(120)),
                ),
                child: Text(
                  'ADD',
                  style: FestiveType.body(
                    11 * typeScale,
                    color: palette.add,
                    weight: FontWeight.w700,
                    letterSpacing: 0.2,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          )
        : Container(
            height: 27 * typeScale,
            decoration: BoxDecoration(
              color: palette.add,
              borderRadius: radius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _StepperButton(
                  icon: Icons.remove_rounded,
                  onTap: onRemove,
                  label: 'Decrease quantity',
                ),
                SizedBox(
                  width: 18 * typeScale,
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: FestiveType.body(
                      11 * typeScale,
                      color: Colors.white,
                      weight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ),
                _StepperButton(
                  icon: Icons.add_rounded,
                  onTap: onAdd,
                  label: 'Increase quantity',
                ),
              ],
            ),
          );

    return AnimatedSize(
      duration: FestiveMotion.base,
      curve: FestiveMotion.enter,
      alignment: Alignment.centerLeft,
      child: AnimatedSwitcher(
        duration: FestiveMotion.base,
        switchInCurve: FestiveMotion.enter,
        switchOutCurve: FestiveMotion.exit,
        transitionBuilder: (Widget widget, Animation<double> anim) =>
            FadeTransition(opacity: anim, child: widget),
        child: KeyedSubtree(
          key: ValueKey<bool>(quantity == 0),
          child: child,
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.label,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 24,
          height: 27,
          child: Icon(icon, size: 14, color: Colors.white),
        ),
      ),
    );
  }
}

/// A horizontally scrolling rail of [FestiveProductCard]s with the section
/// heading above it and (on pointer devices) page arrows.
class FestiveRailView extends StatefulWidget {
  const FestiveRailView({
    super.key,
    required this.rail,
    required this.palette,
    required this.size,
    required this.typeScale,
    required this.contentWidth,
    required this.gutter,
    required this.quantityOf,
    required this.isWishlisted,
    required this.onAdd,
    required this.onRemove,
    required this.onWishlist,
    this.onProductTap,
  });

  final FestiveRail rail;
  final FestivePalette palette;
  final FestiveSize size;
  final double typeScale;
  final double contentWidth;
  final double gutter;
  final int Function(FestiveProduct) quantityOf;
  final bool Function(FestiveProduct) isWishlisted;
  final void Function(FestiveProduct) onAdd;
  final void Function(FestiveProduct) onRemove;
  final void Function(FestiveProduct) onWishlist;
  final void Function(FestiveProduct)? onProductTap;

  @override
  State<FestiveRailView> createState() => _FestiveRailViewState();
}

class _FestiveRailViewState extends State<FestiveRailView> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _visibleCards => switch (widget.size) {
        FestiveSize.compact => 3.25,
        FestiveSize.medium => 4.3,
        FestiveSize.expanded => 6.3,
      };

  void _page(int direction) {
    if (!_controller.hasClients) return;
    final double cardWidth = _cardWidth + 12;
    final double target = (_controller.offset + cardWidth * 2 * direction)
        .clamp(0.0, _controller.position.maxScrollExtent)
        .toDouble();
    _controller.animateTo(
      target,
      duration: FestiveMotion.slow,
      curve: FestiveMotion.standard,
    );
  }

  late double _cardWidth = 0;

  @override
  Widget build(BuildContext context) {
    final int count = _visibleCards.floor();
    final double gap = widget.size.isCompact ? 10 : 14;
    // One extra slot of a card peeks past the edge, the way the reference rail
    // does, so the row reads as scrollable.
    _cardWidth = (widget.contentWidth - gap * (count - 1)) / _visibleCards;
    final double textFactor =
        MediaQuery.textScalerOf(context).scale(10) / 10;
    final double ts = widget.typeScale;
    // Same arithmetic as FestiveProductCard: image + name + unit + price row.
    final double nameHeight = 12 * ts * 1.3 * 2 * textFactor;
    final double unitHeight = 10.5 * ts * 1.2 * textFactor;
    final double priceHeight =
        (12.5 * ts * 1.2 + 10 * ts * 1.2) * textFactor;
    final double cardHeight = _cardWidth +
        8 +
        nameHeight +
        2 +
        unitHeight +
        6 +
        math.max(priceHeight, 27 * ts) +
        2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.gutter),
          child: FestiveSectionHeading(
            title: widget.rail.title,
            subtitle: widget.rail.subtitle,
            palette: widget.palette,
            typeScale: widget.typeScale,
            trailing: widget.size.isAtLeastMedium
                ? _RailArrows(
                    palette: widget.palette,
                    onPrevious: () => _page(-1),
                    onNext: () => _page(1),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: widget.gutter),
            clipBehavior: Clip.none,
            itemCount: widget.rail.products.length,
            separatorBuilder: (BuildContext context, int index) =>
                SizedBox(width: gap),
            itemBuilder: (BuildContext context, int index) {
              final FestiveProduct product = widget.rail.products[index];
              return RepaintBoundary(
                child: FestiveProductCard(
                  product: product,
                  width: _cardWidth,
                  palette: widget.palette,
                  typeScale: widget.typeScale,
                  quantity: widget.quantityOf(product),
                  wishlisted: widget.isWishlisted(product),
                  onAdd: () => widget.onAdd(product),
                  onRemove: () => widget.onRemove(product),
                  onWishlist: () => widget.onWishlist(product),
                  onTap: widget.onProductTap == null
                      ? null
                      : () => widget.onProductTap!(product),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RailArrows extends StatelessWidget {
  const _RailArrows({
    required this.palette,
    required this.onPrevious,
    required this.onNext,
  });

  final FestivePalette palette;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _ArrowButton(
          icon: Icons.chevron_left_rounded,
          palette: palette,
          onTap: onPrevious,
          label: 'Scroll back',
        ),
        const SizedBox(width: 6),
        _ArrowButton(
          icon: Icons.chevron_right_rounded,
          palette: palette,
          onTap: onNext,
          label: 'Scroll forward',
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.palette,
    required this.onTap,
    required this.label,
  });

  final IconData icon;
  final FestivePalette palette;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.surfaceSoft,
            shape: BoxShape.circle,
            border: Border.all(color: palette.hairline),
          ),
          child: Icon(icon, size: 18, color: palette.ink),
        ),
      ),
    );
  }
}
