import 'package:flutter/material.dart';

import 'diwali_data.dart';
import 'diwali_icons.dart';
import 'diwali_painters.dart';
import 'diwali_product_card.dart';
import 'diwali_reveal.dart';
import 'diwali_store.dart';
import 'diwali_theme.dart';

/// The six arch-shaped entry points that sit inside the dark hero.
class DiwaliHeroTile extends StatelessWidget {
  const DiwaliHeroTile({
    super.key,
    required this.tile,
    required this.width,
    this.onTap,
  });

  final DiwaliTile tile;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final imageHeight = width * 1.08;
    return DiwaliHoverLift(
      borderRadius: 14,
      lift: 5,
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: imageHeight,
              child: Stack(
                children: [
                  // The wine-coloured dome behind the photograph.
                  Positioned.fill(
                    child: CustomPaint(
                      painter: const DiwaliArchShadowPainter(
                        color: Color(0x66000000),
                        elevation: 8,
                      ),
                        child: ClipPath(
                          clipper: const DiwaliArchClipper(bottomRadius: 9),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  DiwaliColors.tileTop,
                                  DiwaliColors.tileMid,
                                  DiwaliColors.tileBottom,
                                ],
                                stops: [0.0, 0.55, 1.0],
                              ),
                            ),
                          ),
                        ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
                      child: ClipPath(
                        clipper: const DiwaliArchClipper(bottomRadius: 7),
                        child: DiwaliAssetImage(
                          asset: tile.asset,
                          width: width - 8,
                          height: imageHeight - 6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Text(
              tile.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: DiwaliText.body(
                DiwaliLayout(MediaQuery.sizeOf(context).width).tileLabel * 0.82,
                color: Colors.white,
                weight: FontWeight.w600,
                height: 1.22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiwaliHeroTileGrid extends StatelessWidget {
  const DiwaliHeroTileGrid({
    super.key,
    required this.tiles,
    required this.availableWidth,
    required this.columns,
    this.onTap,
  });

  final List<DiwaliTile> tiles;
  final double availableWidth;
  final int columns;
  final ValueChanged<DiwaliTile>? onTap;

  @override
  Widget build(BuildContext context) {
    final gap = columns >= 6 ? 14.0 : 10.0;
    final width = (availableWidth - gap * (columns - 1)) / columns;
    return Wrap(
      spacing: gap,
      runSpacing: 18,
      children: [
        for (var i = 0; i < tiles.length; i++)
          DiwaliReveal(
            delay: Duration(milliseconds: 55 * i),
            child: DiwaliHeroTile(
              tile: tiles[i],
              width: width,
              onTap: onTap == null ? null : () => onTap!(tiles[i]),
            ),
          ),
      ],
    );
  }
}

/// Editorial arch card: photograph in a dome, title and subtitle below.
class DiwaliArchCard extends StatelessWidget {
  const DiwaliArchCard({
    super.key,
    required this.item,
    required this.width,
    this.onTap,
    this.titleSize = 15,
  });

  final DiwaliArchItem item;
  final double width;
  final VoidCallback? onTap;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    final imageHeight = width * 0.96;
    return DiwaliHoverLift(
      borderRadius: 14,
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: imageHeight,
              width: width,
              child: CustomPaint(
                painter: const DiwaliArchShadowPainter(elevation: 6),
                child: ClipPath(
                  clipper: const DiwaliArchClipper(bottomRadius: 8),
                  child: DiwaliAssetImage(
                    asset: item.asset,
                    width: width,
                    height: imageHeight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DiwaliText.serifStyle(titleSize).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: DiwaliText.body(11, color: DiwaliColors.ink2),
            ),
          ],
        ),
      ),
    );
  }
}

class DiwaliArchRail extends StatefulWidget {
  const DiwaliArchRail({
    super.key,
    required this.items,
    required this.availableWidth,
    this.pad,
    this.onTap,
  });

  final List<DiwaliArchItem> items;
  final double availableWidth;
  final double? pad;
  final ValueChanged<DiwaliArchItem>? onTap;

  @override
  State<DiwaliArchRail> createState() => _DiwaliArchRailState();
}

class _DiwaliArchRailState extends State<DiwaliArchRail> {
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
    final start = pos.pixels <= 1;
    final end = pos.pixels >= pos.maxScrollExtent - 1;
    if (start != _atStart || end != _atEnd) {
      setState(() {
        _atStart = start;
        _atEnd = end;
      });
    }
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
    final w = layout.archItemWidth(widget.availableWidth);
    final pad = widget.pad ?? layout.pad;
    final gap = layout.isExpanded ? 18.0 : 12.0;
    return SizedBox(
      height: w * 0.96 + 62,
      child: Stack(
        children: [
          Positioned.fill(
            child: ListView.separated(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: pad),
              itemCount: widget.items.length,
              separatorBuilder: (_, __) => SizedBox(width: gap),
              itemBuilder: (context, index) => DiwaliReveal(
                delay: Duration(milliseconds: 60 * index),
                child: DiwaliArchCard(
                  item: widget.items[index],
                  width: w,
                  onTap: widget.onTap == null
                      ? null
                      : () => widget.onTap!(widget.items[index]),
                ),
              ),
            ),
          ),
          if (layout.showRailArrows && !_atEnd)
            Positioned(
              right: 3,
              top: w * 0.42,
              child: DiwaliCircleButton(
                onTap: () => _controller.animateTo(
                  (_controller.offset + (w + gap) * 2)
                      .clamp(0.0, _controller.position.maxScrollExtent),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                ),
              ),
            ),
          if (layout.showRailArrows && !_atStart)
            Positioned(
              left: 3,
              top: w * 0.42,
              child: DiwaliCircleButton(
                icon: Icons.arrow_back_ios_rounded,
                onTap: () => _controller.animateTo(
                  (_controller.offset - (w + gap) * 2)
                      .clamp(0.0, _controller.position.maxScrollExtent),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Rounded square category tile (used by Festive Home / Outfit / Pooja).
class DiwaliCategoryTile extends StatelessWidget {
  const DiwaliCategoryTile({
    super.key,
    required this.tile,
    required this.width,
    this.onTap,
  });

  final DiwaliTile tile;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => DiwaliHoverLift(
        borderRadius: 12,
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DiwaliAssetImage(
                  asset: tile.asset,
                  width: width,
                  height: width * 0.92,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                tile.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: DiwaliText.body(
                  11.5,
                  weight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      );
}

class DiwaliCategoryTileGrid extends StatelessWidget {
  const DiwaliCategoryTileGrid({
    super.key,
    required this.tiles,
    required this.availableWidth,
    this.columns = 4,
    this.onTap,
  });

  final List<DiwaliTile> tiles;
  final double availableWidth;
  final int columns;
  final ValueChanged<DiwaliTile>? onTap;

  @override
  Widget build(BuildContext context) {
    final gap = 10.0;
    final w = (availableWidth - gap * (columns - 1)) / columns;
    return Wrap(
      spacing: gap,
      runSpacing: 16,
      children: [
        for (var i = 0; i < tiles.length; i++)
          DiwaliReveal(
            delay: Duration(milliseconds: 55 * i),
            child: DiwaliCategoryTile(
              tile: tiles[i],
              width: w,
              onTap: onTap == null ? null : () => onTap!(tiles[i]),
            ),
          ),
      ],
    );
  }
}

/// A kite-shaped "Diyas & Candles" category entry.
class DiwaliDiamondCategory extends StatelessWidget {
  const DiwaliDiamondCategory({
    super.key,
    required this.item,
    required this.width,
    this.onTap,
  });

  final DiwaliDiamond item;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final imageSize = width * 0.86;
    return DiwaliHoverLift(
      borderRadius: 10,
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: imageSize,
              width: imageSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipPath(
                    clipper: const DiwaliDiamondClipper(),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFFFF3CF),
                            DiwaliColors.cream3,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(3),
                    child: ClipPath(
                      clipper: const DiwaliDiamondClipper(),
                      child: DiwaliAssetImage(
                        asset: item.asset,
                        width: imageSize - 6,
                        height: imageSize - 6,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0xAA3B0014)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: DiwaliText.body(
                11,
                color: DiwaliColors.wine600,
                weight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiwaliDiamondGrid extends StatelessWidget {
  const DiwaliDiamondGrid({
    super.key,
    required this.items,
    required this.availableWidth,
    required this.columns,
    this.onTap,
  });

  final List<DiwaliDiamond> items;
  final double availableWidth;
  final int columns;
  final ValueChanged<DiwaliDiamond>? onTap;

  @override
  Widget build(BuildContext context) {
    final gap = columns >= 8 ? 12.0 : 9.0;
    final w = (availableWidth - gap * (columns - 1)) / columns;
    return Wrap(
      spacing: gap,
      runSpacing: 16,
      children: [
        for (var i = 0; i < items.length; i++)
          DiwaliReveal(
            delay: Duration(milliseconds: 45 * i),
            child: DiwaliDiamondCategory(
              item: items[i],
              width: w,
              onTap: onTap == null ? null : () => onTap!(items[i]),
            ),
          ),
      ],
    );
  }
}

/// Rounded filter chip with a thumbnail — the "Thoughtful Gifts for All" row.
class DiwaliGiftChipButton extends StatelessWidget {
  const DiwaliGiftChipButton({
    super.key,
    required this.item,
    required this.index,
    this.onTap,
  });

  final DiwaliGiftChip item;
  final int index;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final store = DiwaliScope.of(context);
    final selected = store.giftChipIndex == index;
    return GestureDetector(
      onTap: onTap ?? () => store.selectGiftChip(index),
      child: AnimatedContainer(
        duration: DiwaliMotion.hover,
        curve: DiwaliMotion.curve,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? DiwaliColors.wine600 : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? DiwaliColors.wine600 : DiwaliColors.line,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x33790031),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : const [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: DiwaliColors.cream3,
              backgroundImage: AssetImage(item.asset),
              onBackgroundImageError: (_, __) {},
            ),
            const SizedBox(width: 7),
            Text(
              item.label.replaceAll('\n', ' '),
              style: DiwaliText.body(
                11,
                color: selected ? Colors.white : DiwaliColors.ink2,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiwaliGiftChipRow extends StatelessWidget {
  const DiwaliGiftChipRow({super.key, required this.items});

  final List<DiwaliGiftChip> items;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              DiwaliGiftChipButton(item: items[i], index: i),
              const SizedBox(width: 9),
            ],
          ],
        ),
      );
}

/// A brand tile with the logo stamped over the photograph.
class DiwaliBrandCard extends StatelessWidget {
  const DiwaliBrandCard({
    super.key,
    required this.brand,
    required this.width,
    this.onTap,
  });

  final DiwaliBrand brand;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => DiwaliHoverLift(
        borderRadius: 14,
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: width * 0.72,
                  width: width,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DiwaliAssetImage(
                          asset: brand.asset,
                          width: width,
                          height: width * 0.72,
                        ),
                      ),
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x11000000), Color(0x66000000)],
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          brand.logo,
                          textAlign: TextAlign.center,
                          style: DiwaliText.displayStyle(20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                brand.name,
                style: DiwaliText.body(13, weight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      size: 13, color: DiwaliColors.green),
                  const SizedBox(width: 2),
                  Text(
                    '4.6',
                    style: DiwaliText.body(10.5, color: DiwaliColors.ink2),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '· 20 mins',
                    style: DiwaliText.body(10.5, color: DiwaliColors.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class DiwaliBrandRail extends StatelessWidget {
  const DiwaliBrandRail({
    super.key,
    required this.brands,
    required this.availableWidth,
    this.pad,
  });

  final List<DiwaliBrand> brands;
  final double availableWidth;
  final double? pad;

  @override
  Widget build(BuildContext context) {
    final layout = DiwaliLayout(availableWidth);
    final w = layout.brandItemWidth(availableWidth);
    return SizedBox(
      height: w * 0.72 + 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: pad ?? layout.pad),
        itemCount: brands.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) => DiwaliReveal(
          delay: Duration(milliseconds: 80 * index),
          child: DiwaliBrandCard(brand: brands[index], width: w),
        ),
      ),
    );
  }
}

/// One date in the "Festive Calendar" strip.
class DiwaliCalendarCard extends StatelessWidget {
  const DiwaliCalendarCard({
    super.key,
    required this.item,
    required this.width,
  });

  final DiwaliCalendarItem item;
  final double width;

  @override
  Widget build(BuildContext context) => DiwaliHoverLift(
        borderRadius: 12,
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: DiwaliAssetImage(
                  asset: item.asset,
                  width: width,
                  height: width * 0.86,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: DiwaliColors.cream3,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '${item.day} ${item.month}',
                  style: DiwaliText.body(
                    11,
                    color: DiwaliColors.wine600,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: DiwaliText.body(11, weight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
}

/// Generic promotional banner with a headline, copy and CTA.
class DiwaliPromoBanner extends StatelessWidget {
  const DiwaliPromoBanner({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.background,
    this.image,
    this.height = 190,
    this.onTap,
    this.textColor = Colors.white,
    this.ornament = const DiwaliBow(),
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String cta;
  final BoxDecoration background;
  final String? image;
  final double height;
  final VoidCallback? onTap;
  final Color textColor;
  final Widget ornament;

  @override
  Widget build(BuildContext context) => DiwaliHoverLift(
        borderRadius: 16,
        lift: 4,
        onTap: onTap,
        child: Container(
          height: height,
          decoration: background.copyWith(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              if (image != null)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: height * 1.05,
                  child: ClipPath(
                    clipper: const DiwaliArchClipper(bottomRadius: 0),
                    child: DiwaliAssetImage(
                      asset: image!,
                      width: height * 1.05,
                      height: height,
                    ),
                  ),
                ),
              Positioned(
                right: 14,
                top: 8,
                child: Opacity(opacity: 0.9, child: ornament),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 120, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: DiwaliText.body(
                        10,
                        color: textColor.withAlpha(217),
                        weight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DiwaliText.serifStyle(23, color: textColor)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DiwaliText.body(
                        11.5,
                        color: textColor.withAlpha(224),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        color: textColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        cta.toUpperCase(),
                        style: DiwaliText.body(
                          10,
                          color: DiwaliColors.wine600,
                          weight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
