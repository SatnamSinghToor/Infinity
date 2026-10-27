import 'package:flutter/material.dart';

import 'diwali_config.dart';
import 'diwali_data.dart';
import 'diwali_decor_cards.dart';
import 'diwali_icons.dart';
import 'diwali_painters.dart';
import 'diwali_product_card.dart';
import 'diwali_reveal.dart';
import 'diwali_store.dart';
import 'diwali_theme.dart';

/// The full scrollable storefront. Everything below the sticky header lives
/// here; [DiwaliHomePage] owns the scaffold, header overlay, nav and cart.
class DiwaliStorefrontBody extends StatelessWidget {
  const DiwaliStorefrontBody({
    super.key,
    required this.scrollController,
    required this.onSearchTap,
    required this.onCartTap,
    required this.onCategoryTap,
    required this.onTabTap,
    this.onProductTap,
  });

  final ScrollController scrollController;
  final VoidCallback onSearchTap;
  final VoidCallback onCartTap;
  final ValueChanged<String> onCategoryTap;
  final ValueChanged<int> onTabTap;
  final ValueChanged<DiwaliProduct>? onProductTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final layout = DiwaliLayout(screenWidth);

    return SingleChildScrollView(
      controller: scrollController,
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DiwaliHero(
            layout: layout,
            onSearchTap: onSearchTap,
            onCartTap: onCartTap,
            onCategoryTap: onCategoryTap,
          ),
          _DiwaliTabStrip(layout: layout, onTabTap: onTabTap),
          _DiwaliDeliveryStrip(layout: layout),
          _railSection(
            layout,
            title: 'Light Up Your Celebrations',
            subtitle: 'Diya, candles & lights starting at just ₹49',
            products: DiwaliCatalog.festiveVibes,
            style: DiwaliCardImageStyle.arch,
            background: DiwaliColors.cream,
            onProductTap: onProductTap,
          ),
          _DiwaliCouponStrip(layout: layout),
          _railSection(
            layout,
            title: 'Make Your Entrance Shine',
            subtitle: 'Urlis, torans & pooja accents that wow your guests',
            products: DiwaliCatalog.entrance,
            background: Colors.white,
            onProductTap: onProductTap,
          ),
          _DiwaliGiftingSection(layout: layout, onProductTap: onProductTap),
          _railSection(
            layout,
            title: 'Let There Be Light',
            subtitle: 'String lights, fairy lights & lanterns for every corner',
            products: DiwaliCatalog.lights,
            background: DiwaliColors.cream,
            onProductTap: onProductTap,
          ),
          _archSection(
            layout,
            title: 'Festive Shopping Made Easy',
            subtitle: 'Thoughtful finds for your home and your people',
            items: DiwaliCatalog.festiveShopping,
          ),
          _DiwaliPriceDropBanner(layout: layout),
          _archSection(
            layout,
            title: 'Vibrant Decor Finds',
            subtitle: 'Bright accents for a home that feels like Diwali',
            items: DiwaliCatalog.vibrantDecor,
            background: Colors.white,
          ),
          _DiwaliDiyasSection(layout: layout),
          _railSection(
            layout,
            title: 'Add Warmth to Every Corner',
            subtitle: 'Torans, candles & little details that glow',
            products: DiwaliCatalog.warmth,
            background: DiwaliColors.cream,
            onProductTap: onProductTap,
          ),
          _railSection(
            layout,
            title: 'Little Joys, Big Celebrations',
            subtitle: 'Rangoli, stickers & floor decor from ₹49',
            products: DiwaliCatalog.celebrations,
            background: Colors.white,
            onProductTap: onProductTap,
          ),
          _railSection(
            layout,
            title: 'Curate Your Cosy Corner',
            subtitle: 'Soft furnishings and blooms for the season',
            products: DiwaliCatalog.corner,
            background: DiwaliColors.cream,
            onProductTap: onProductTap,
          ),
          _railSection(
            layout,
            title: 'Rituals & Festive Feasting',
            subtitle: 'Everything you need for the puja thali',
            products: DiwaliCatalog.rituals,
            background: Colors.white,
            onProductTap: onProductTap,
          ),
          _DiwaliCalendarSection(layout: layout),
          _DiwaliBrandsSection(layout: layout),
          _tileSection(
            layout,
            title: 'Festive Home Makeover',
            subtitle: 'Little changes, a whole lot of sparkle',
            tiles: DiwaliCatalog.festiveHome,
            onCategoryTap: onCategoryTap,
          ),
          _tileSection(
            layout,
            title: 'Diwali Outfit Edit',
            subtitle: 'Get ready for the brightest nights',
            tiles: DiwaliCatalog.diwaliOutfit,
            background: Colors.white,
            onCategoryTap: onCategoryTap,
          ),
          _tileSection(
            layout,
            title: 'Pooja Essentials',
            subtitle: 'Everything for a blessed celebration',
            tiles: DiwaliCatalog.poojaEssentials,
            onCategoryTap: onCategoryTap,
          ),
          _DiwaliFooter(layout: layout),
          SizedBox(height: 90 + MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }

  Widget _railSection(
    DiwaliLayout layout, {
    required String title,
    required String subtitle,
    required List<DiwaliProduct> products,
    required Color background,
    DiwaliCardImageStyle style = DiwaliCardImageStyle.rounded,
    ValueChanged<DiwaliProduct>? onProductTap,
  }) {
    return _DiwaliSectionShell(
      layout: layout,
      background: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: layout.pad),
            child: DiwaliSectionHeading(
              title: title,
              subtitle: subtitle,
              onSeeAll: () {},
            ),
          ),
          const SizedBox(height: 12),
          DiwaliProductRail(
            products: products,
            availableWidth: layout.contentWidth,
            style: style,
            pad: layout.pad,
            onProductTap: onProductTap,
          ),
        ],
      ),
    );
  }

  Widget _archSection(
    DiwaliLayout layout, {
    required String title,
    required String subtitle,
    required List<DiwaliArchItem> items,
    Color background = DiwaliColors.cream2,
  }) {
    return _DiwaliSectionShell(
      layout: layout,
      background: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: layout.pad),
            child: DiwaliSectionHeading(
              title: title,
              subtitle: subtitle,
              onSeeAll: () {},
            ),
          ),
          const SizedBox(height: 16),
          DiwaliArchRail(
            items: items,
            availableWidth: layout.contentWidth,
            pad: layout.pad,
          ),
        ],
      ),
    );
  }

  Widget _tileSection(
    DiwaliLayout layout, {
    required String title,
    required String subtitle,
    required List<DiwaliTile> tiles,
    required ValueChanged<String> onCategoryTap,
    Color background = DiwaliColors.cream2,
  }) {
    final inner = layout.contentWidth - layout.pad * 2;
    return _DiwaliSectionShell(
      layout: layout,
      background: background,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: layout.pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DiwaliSectionHeading(title: title, subtitle: subtitle),
            const SizedBox(height: 18),
            DiwaliCategoryTileGrid(
              tiles: tiles,
              availableWidth: inner,
              columns: layout.isExpanded ? 4 : 4,
              onTap: (tile) => onCategoryTap(tile.label),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centers content on wide screens and gives every section the same rhythm.
class _DiwaliSectionShell extends StatelessWidget {
  const _DiwaliSectionShell({
    required this.layout,
    required this.child,
    this.background = DiwaliColors.cream,
    this.verticalPadding,
  });

  final DiwaliLayout layout;
  final Widget child;
  final Color background;
  final double? verticalPadding;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: background,
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: layout.contentWidth,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: verticalPadding ?? layout.sectionPadTop,
              ),
              child: child,
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// HERO
// ---------------------------------------------------------------------------

class _DiwaliHero extends StatelessWidget {
  const _DiwaliHero({
    required this.layout,
    required this.onSearchTap,
    required this.onCartTap,
    required this.onCategoryTap,
  });

  final DiwaliLayout layout;
  final VoidCallback onSearchTap;
  final VoidCallback onCartTap;
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final inner = layout.contentWidth - layout.pad * 2;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: DiwaliColors.heroGradient),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
              child: CustomPaint(
                painter: DiwaliLatticePainter(spacing: layout.isCompact ? 22 : 28),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: DiwaliColors.heroGlow),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: layout.contentWidth,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  layout.pad,
                  MediaQuery.paddingOf(context).top + 12,
                  layout.pad,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _HeroTopBar(
                      layout: layout,
                      onCartTap: onCartTap,
                      onSearchTap: onSearchTap,
                    ),
                    SizedBox(height: layout.isCompact ? 16 : 22),
                    _HeroWordmark(layout: layout),
                    const SizedBox(height: 10),
                    _DiwaliFairyLights(height: layout.isCompact ? 38 : 48),
                    SizedBox(height: layout.isCompact ? 20 : 26),
                    DiwaliReveal(
                      child: DiwaliHeroTileGrid(
                        tiles: DiwaliCatalog.heroTiles,
                        availableWidth: inner,
                        columns: layout.tileColumns,
                        onTap: (tile) => onCategoryTap(tile.label),
                      ),
                    ),
                    SizedBox(height: layout.isCompact ? 14 : 20),
                    _DiwaliFairyLights(
                      height: layout.isCompact ? 34 : 42,
                      flip: true,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTopBar extends StatelessWidget {
  const _HeroTopBar({
    required this.layout,
    required this.onCartTap,
    required this.onSearchTap,
  });

  final DiwaliLayout layout;
  final VoidCallback onCartTap;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    final store = DiwaliScope.of(context);
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _showAddressSheet(context, store),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 19, color: Colors.white),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DELIVERING TO',
                            style: DiwaliText.body(
                              9,
                              color: const Color(0xFFFFDDA6),
                              weight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  store.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: DiwaliText.body(
                                    layout.isCompact ? 12.5 : 14,
                                    color: Colors.white,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 17, color: Colors.white),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _HeroIconButton(
              icon: Icons.headset_mic_outlined,
              onTap: () => _showHelpSheet(context),
            ),
            const SizedBox(width: 8),
            _HeroIconButton(icon: Icons.local_mall_outlined, onTap: onCartTap),
          ],
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: onSearchTap,
          child: Container(
            height: layout.isCompact ? 44 : 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 13),
                const Icon(Icons.search_rounded,
                    size: 20, color: DiwaliColors.wine600),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    store.query.isEmpty
                        ? 'Search "diya", "lights", "gifts"...'
                        : store.query,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DiwaliText.body(
                      layout.isCompact ? 12.5 : 14,
                      color: store.query.isEmpty
                          ? DiwaliColors.muted
                          : DiwaliColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 22,
                  color: const Color(0xFFE6E1D6),
                ),
                GestureDetector(
                  onTap: () => onSearchTap(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.mic_none_rounded,
                      size: 20,
                      color: store.voiceListening
                          ? DiwaliColors.zomato
                          : DiwaliColors.wine600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddressSheet(BuildContext context, DiwaliStore store) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose delivery location',
                style: DiwaliText.serifStyle(20)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              for (final address in const [
                'Sector 32, Ludhiana',
                'Model Town, Ludhiana',
                'Sarabha Nagar, Ludhiana',
                'Ferozepur Road, Ludhiana',
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined,
                      color: DiwaliColors.wine600),
                  title: Text(
                    address,
                    style: DiwaliText.body(13),
                  ),
                  trailing: store.address == address
                      ? const Icon(Icons.check_circle_rounded,
                          color: DiwaliColors.green, size: 20)
                      : null,
                  onTap: () {
                    store.setAddress(address);
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We are here to help',
                style: DiwaliText.serifStyle(20)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Our festive care team is available 8 AM – 11 PM all week.',
                style: DiwaliText.body(13, color: DiwaliColors.ink2),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          size: 17),
                      label: const Text('Chat with us'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DiwaliColors.wine600,
                        side: const BorderSide(color: DiwaliColors.wine600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.call_outlined, size: 17),
                      label: const Text('Call us'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DiwaliColors.wine600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(36),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(82)),
          ),
          child: Icon(icon, size: 19, color: Colors.white),
        ),
      );
}

class _HeroWordmark extends StatelessWidget {
  const _HeroWordmark({required this.layout});

  final DiwaliLayout layout;

  @override
  Widget build(BuildContext context) => DiwaliReveal(
        duration: const Duration(milliseconds: 800),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DiwaliSparkle(
                      color: const Color(0xFFFFE6A2),
                      size: layout.isCompact ? 16 : 24),
                  const SizedBox(width: 10),
                  Text(
                    'DIWALI',
                    style: DiwaliText.displayStyle(layout.heroWord),
                  ),
                  const SizedBox(width: 10),
                  DiwaliSparkle(
                      color: const Color(0xFFFFE6A2),
                      size: layout.isCompact ? 16 : 24),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'The Festival of Lights',
              style: DiwaliText.serifStyle(
                layout.isCompact ? 19 : 26,
                color: DiwaliColors.cream3,
                italic: true,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(31),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withAlpha(66)),
              ),
              child: Text(
                'FESTIVE SHOPPING STARTS HERE',
                style: DiwaliText.body(
                  layout.isCompact ? 9.5 : 11,
                  color: Colors.white,
                  weight: FontWeight.w700,
                  letterSpacing: 1.7,
                ),
              ),
            ),
          ],
        ),
      );
}

/// Fairy lights powered by a repeating controller; disposes cleanly.
class _DiwaliFairyLights extends StatefulWidget {
  const _DiwaliFairyLights({required this.height, this.flip = false});

  final double height;
  final bool flip;

  @override
  State<_DiwaliFairyLights> createState() => _DiwaliFairyLightsState();
}

class _DiwaliFairyLightsState extends State<_DiwaliFairyLights>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => DiwaliFairyLights(
          progress: _controller.value,
          height: widget.height,
          flip: widget.flip,
          bulbs: DiwaliLayout(MediaQuery.sizeOf(context).width).isCompact ? 16 : 26,
        ),
      );
}

// ---------------------------------------------------------------------------
// TAB STRIP + DELIVERY STRIP
// ---------------------------------------------------------------------------

class _DiwaliTabStrip extends StatelessWidget {
  const _DiwaliTabStrip({required this.layout, required this.onTabTap});

  final DiwaliLayout layout;
  final ValueChanged<int> onTabTap;

  @override
  Widget build(BuildContext context) {
    final store = DiwaliScope.of(context);
    return ColoredBox(
      color: Colors.white,
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: layout.contentWidth,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              layout.pad,
              16,
              layout.pad,
              12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < DiwaliCatalog.tabs.length; i++)
                  Expanded(
                    child: _DiwaliTabItem(
                      tab: DiwaliCatalog.tabs[i],
                      selected: store.tabIndex == i,
                      layout: layout,
                      onTap: () {
                        store.selectTab(i);
                        onTabTap(i);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiwaliTabItem extends StatelessWidget {
  const _DiwaliTabItem({
    required this.tab,
    required this.selected,
    required this.onTap,
    required this.layout,
  });

  final DiwaliTab tab;
  final bool selected;
  final VoidCallback onTap;
  final DiwaliLayout layout;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: DiwaliMotion.hover,
              width: layout.isCompact ? 50 : 62,
              height: layout.isCompact ? 50 : 62,
              decoration: BoxDecoration(
                color: selected ? DiwaliColors.cream3 : const Color(0xFFF6F4EE),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? DiwaliColors.wine600
                      : const Color(0xFFECE8DC),
                  width: selected ? 1.6 : 1,
                ),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x22790031),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ]
                    : const [],
              ),
              child: Center(
                child: DiwaliTabGlyph(
                  icon: tab.icon,
                  size: layout.isCompact ? 26 : 32,
                  color: selected
                      ? DiwaliColors.wine600
                      : const Color(0xFF7A2C45),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tab.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DiwaliText.body(
                layout.tabLabel,
                color: selected ? DiwaliColors.wine600 : DiwaliColors.ink2,
                weight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      );
}

class _DiwaliDeliveryStrip extends StatelessWidget {
  const _DiwaliDeliveryStrip({required this.layout});

  final DiwaliLayout layout;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Colors.white,
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: layout.contentWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: layout.pad),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded,
                          size: 20, color: DiwaliColors.green),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'DELIVERY IN 16 MINS',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DiwaliText.body(
                            layout.isCompact ? 13 : 17,
                            weight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      // On a narrow phone the offer line moves to its own
                      // row below the time so neither label is clipped.
                      if (!layout.isCompact) ...[
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Free delivery above ₹199',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DiwaliText.body(
                              11,
                              color: DiwaliColors.green,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (layout.isCompact)
                  Padding(
                    padding: const EdgeInsets.only(top: 3, left: 25),
                    child: Text(
                      'Free delivery above ₹199',
                      style: DiwaliText.body(
                        10.5,
                        color: DiwaliColors.green,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: layout.pad),
                    children: const [
                      _FilterChip(label: 'Festive Offers', selected: true),
                      _FilterChip(label: 'Under ₹299'),
                      _FilterChip(label: 'Free Delivery'),
                      _FilterChip(label: 'Bestsellers'),
                      _FilterChip(label: 'New Arrivals'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: DiwaliColors.line),
              ],
            ),
          ),
        ),
      );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Chip(
          label: Text(
            label,
            style: DiwaliText.body(
              11,
              color: selected ? Colors.white : DiwaliColors.ink2,
              weight: FontWeight.w600,
            ),
          ),
          backgroundColor: selected ? DiwaliColors.wine600 : Colors.white,
          side: BorderSide(
            color: selected ? DiwaliColors.wine600 : DiwaliColors.line,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        ),
      );
}

// ---------------------------------------------------------------------------
// BANNERS
// ---------------------------------------------------------------------------

class _DiwaliCouponStrip extends StatelessWidget {
  const _DiwaliCouponStrip({required this.layout});

  final DiwaliLayout layout;

  @override
  Widget build(BuildContext context) => _DiwaliSectionShell(
        layout: layout,
        background: DiwaliColors.cream,
        verticalPadding: 8,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: layout.pad),
          child: DiwaliReveal(
            child: Container(
              height: layout.isCompact ? 76 : 88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF1A8), Color(0xFFFFD36B)],
                ),
                border: Border.all(color: const Color(0xFFE6B23F)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const DiwaliDiyaMark(size: 40, color: DiwaliColors.wine600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FLAT ₹150 OFF ON YOUR FIRST ORDER',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DiwaliText.body(
                            layout.isCompact ? 12 : 15,
                            color: DiwaliColors.wine900,
                            weight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Use code DIWALI150 · T&Cs apply',
                          style: DiwaliText.body(
                            11,
                            color: DiwaliColors.wine700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: DiwaliColors.wine600,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'COPY',
                      style: DiwaliText.body(
                        10,
                        color: Colors.white,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _DiwaliPriceDropBanner extends StatelessWidget {
  const _DiwaliPriceDropBanner({required this.layout});

  final DiwaliLayout layout;

  @override
  Widget build(BuildContext context) => _DiwaliSectionShell(
        layout: layout,
        background: DiwaliColors.cream2,
        verticalPadding: 10,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: layout.pad),
          child: DiwaliReveal(
            child: DiwaliPromoBanner(
              eyebrow: 'The Big Festive Sale',
              title: 'Price Drop, Jaw Drop',
              subtitle: 'Up to 60% off on lights, diyas & festive decor.',
              cta: 'Shop the drop',
              height: layout.isCompact ? 168 : 200,
              image: '$kDiwaliAssetRoot/decor-3.jpg',
              background: BoxDecoration(
                gradient: DiwaliColors.deepBanner,
              ),
            ),
          ),
        ),
      );
}

class _DiwaliGiftingSection extends StatelessWidget {
  const _DiwaliGiftingSection({
    required this.layout,
    required this.onProductTap,
  });

  final DiwaliLayout layout;
  final ValueChanged<DiwaliProduct>? onProductTap;

  @override
  Widget build(BuildContext context) => _DiwaliSectionShell(
        layout: layout,
        background: DiwaliColors.cream2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: layout.pad),
              child: DiwaliReveal(
                child: DiwaliPromoBanner(
                  eyebrow: 'The Diwali Gift Store',
                  title: 'Thoughtful Gifts for All',
                  subtitle: 'Handpicked hampers for everyone on your list.',
                  cta: 'Explore gifts',
                  height: layout.isCompact ? 172 : 200,
                  image: '$kDiwaliAssetRoot/hamper-3.jpg',
                  background: BoxDecoration(
                    gradient: DiwaliColors.creamBanner,
                  ),
                  textColor: DiwaliColors.wine700,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const DiwaliGiftChipRow(items: DiwaliCatalog.giftChips),
            const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: layout.pad),
              child: DiwaliSectionHeading(
                title: 'Sweet Surprises, Wrapped with Love',
                subtitle: 'Chocolates, hampers & treats they will remember',
                onSeeAll: () {},
              ),
            ),
            const SizedBox(height: 12),
            DiwaliProductRail(
              products: DiwaliCatalog.gifts,
              availableWidth: layout.contentWidth,
              pad: layout.pad,
              onProductTap: onProductTap,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: layout.pad),
              child: DiwaliSectionHeading(
                title: 'Shop by Gift Mood',
                subtitle: 'Curated picks for every kind of celebration',
                onSeeAll: () {},
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: layout.pad),
              child: DiwaliArchRail(
                items: DiwaliCatalog.diwaliGifting,
                availableWidth: layout.contentWidth - layout.pad * 2,
                pad: 0,
              ),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// EDITORIAL SECTIONS
// ---------------------------------------------------------------------------

class _DiwaliDiyasSection extends StatelessWidget {
  const _DiwaliDiyasSection({required this.layout});

  final DiwaliLayout layout;

  @override
  Widget build(BuildContext context) {
    final inner = layout.contentWidth - layout.pad * 2;
    return _DiwaliSectionShell(
      layout: layout,
      background: DiwaliColors.cream3,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: layout.pad),
        child: Column(
          children: [
            DiwaliSectionHeading(
              title: 'Diyas & Candles',
              subtitle: 'A little flame for every happy moment',
              center: true,
            ),
            const SizedBox(height: 20),
            DiwaliDiamondGrid(
              items: DiwaliCatalog.diyasAndCandles,
              availableWidth: inner,
              columns: layout.diamondColumns,
            ),
          ],
        ),
      ),
    );
  }
}

class _DiwaliCalendarSection extends StatelessWidget {
  const _DiwaliCalendarSection({required this.layout});

  final DiwaliLayout layout;

  @override
  Widget build(BuildContext context) {
    final inner = layout.contentWidth - layout.pad * 2;
    final gap = 12.0;
    final w = (inner - gap * 2) / 3;
    return _DiwaliSectionShell(
      layout: layout,
      background: DiwaliColors.cream2,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: layout.pad),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const DiwaliLotus(size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Festive Calendar',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: DiwaliText.serifStyle(
                      layout.isCompact ? 17 : layout.sectionTitle,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 6),
                const DiwaliLotus(size: 18),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Never miss a moment of the festivities',
              style: DiwaliText.body(12, color: DiwaliColors.ink2),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: gap,
              runSpacing: 16,
              children: [
                for (var i = 0; i < DiwaliCatalog.calendar.length; i++)
                  DiwaliReveal(
                    delay: Duration(milliseconds: 80 * i),
                    child: DiwaliCalendarCard(
                      item: DiwaliCatalog.calendar[i],
                      width: w,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DiwaliBrandsSection extends StatelessWidget {
  const _DiwaliBrandsSection({required this.layout});

  final DiwaliLayout layout;

  @override
  Widget build(BuildContext context) => _DiwaliSectionShell(
        layout: layout,
        background: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: layout.pad),
              child: DiwaliSectionHeading(
                title: 'Small Businesses, Big Hearts',
                subtitle: 'Discover homegrown brands we love',
                onSeeAll: () {},
              ),
            ),
            const SizedBox(height: 14),
            DiwaliBrandRail(
              brands: DiwaliCatalog.brands,
              availableWidth: layout.contentWidth,
              pad: layout.pad,
            ),
            if (layout.showBrandLine) ...[
              const SizedBox(height: 14),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: layout.pad),
                child: DiwaliDiamondRule(
                  color: DiwaliColors.wine600.withAlpha(89),
                  filled: true,
                  step: 22,
                  height: 8,
                ),
              ),
            ],
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// FOOTER
// ---------------------------------------------------------------------------

class _DiwaliFooter extends StatefulWidget {
  const _DiwaliFooter({required this.layout});

  final DiwaliLayout layout;

  @override
  State<_DiwaliFooter> createState() => _DiwaliFooterState();
}

class _DiwaliFooterState extends State<_DiwaliFooter> {
  final TextEditingController _email = TextEditingController();
  bool _subscribed = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = widget.layout;
    return _DiwaliSectionShell(
      layout: layout,
      background: DiwaliColors.wine900,
      verticalPadding: 34,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: layout.pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const DiwaliSparkle(color: Color(0xFFFFE6A2), size: 13),
                const SizedBox(width: 8),
                Text(
                  'INFINITY',
                  style: DiwaliText.displayStyle(layout.isCompact ? 24 : 30),
                ),
                const SizedBox(width: 8),
                const DiwaliSparkle(color: Color(0xFFFFE6A2), size: 13),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Celebrating every moment, every festival, together.',
              textAlign: TextAlign.center,
              style: DiwaliText.body(
                12,
                color: DiwaliColors.cream3,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'GET FESTIVE UPDATES',
              style: DiwaliText.body(
                10,
                color: const Color(0xFFFFDDA6),
                weight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      style: DiwaliText.body(13, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        hintStyle:
                            DiwaliText.body(13, color: const Color(0xAAFFFFFF)),
                        filled: true,
                        fillColor: Colors.white.withAlpha(26),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.white.withAlpha(76),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.white.withAlpha(76),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: DiwaliColors.cream3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_email.text.contains('@')) {
                      setState(() => _subscribed = true);
                    }
                  },
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: DiwaliColors.cream3,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _subscribed ? 'DONE' : 'JOIN',
                        style: DiwaliText.body(
                          11,
                          color: DiwaliColors.wine900,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_subscribed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'You are on the list. Happy Diwali!',
                  style:
                      DiwaliText.body(11, color: const Color(0xFFB7F0A8)),
                ),
              ),
            const SizedBox(height: 26),
            Wrap(
              spacing: 22,
              runSpacing: 10,
              children: [
                for (final label in const [
                  'About us',
                  'Help & support',
                  'Terms',
                  'Privacy',
                  'Returns',
                ])
                  Text(
                    label,
                    style: DiwaliText.body(
                      11.5,
                      color: DiwaliColors.cream3,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(color: Color(0x33FFFFFF), height: 1),
            const SizedBox(height: 14),
            Text(
              '© 2026 Infinity. Made with light in Ludhiana.',
              style: DiwaliText.body(10.5, color: const Color(0xAAFFFFFF)),
            ),
          ],
        ),
      ),
    );
  }
}
