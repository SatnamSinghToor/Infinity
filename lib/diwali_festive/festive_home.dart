import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'festive_art.dart';
import 'festive_cards.dart';
import 'festive_data.dart';
import 'festive_sheets.dart';
import 'festive_store.dart';
import 'festive_tokens.dart';
import 'festive_widgets.dart';

/// The Diwali festival home screen.
///
/// A full-bleed festive hero (brand strip, delivery promise, category tabs,
/// fairy-lit banner and the six arch tiles) over a light content surface with
/// product rails. Everything is data-driven: pass [copy], [categories],
/// [tiles] and [rails] to render a different catalogue, or wire the callbacks
/// to the host app's navigation.
///
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute<void>(builder: (_) => const DiwaliFestiveScreen()),
/// );
/// ```
class DiwaliFestiveScreen extends StatefulWidget {
  const DiwaliFestiveScreen({
    super.key,
    this.copy = FestiveCopy.reference,
    this.categories = FestiveContent.categories,
    this.tiles = FestiveContent.tiles,
    this.rails = FestiveContent.rails,
    this.navigation = FestiveContent.navigation,
    this.initialTab = 1,
    this.showBottomNav = true,
    this.showZomatoButton = true,
    this.onNavigate,
    this.onCategoryTap,
    this.onTileTap,
    this.onZomatoTap,
    this.maxContentWidth = FestiveBreakpoints.maxContentWidth,
  });

  final FestiveCopy copy;
  final List<FestiveCategory> categories;
  final List<FestiveTile> tiles;
  final List<FestiveRail> rails;
  final List<FestiveNavDestination> navigation;
  final int initialTab;
  final bool showBottomNav;
  final bool showZomatoButton;

  /// Host navigation for the bottom bar. When null the bar still moves its
  /// highlight and reports what would happen.
  final ValueChanged<int>? onNavigate;
  final ValueChanged<FestiveCategory>? onCategoryTap;
  final ValueChanged<FestiveTile>? onTileTap;
  final VoidCallback? onZomatoTap;
  final double maxContentWidth;

  @override
  State<DiwaliFestiveScreen> createState() => _DiwaliFestiveScreenState();
}

class _DiwaliFestiveScreenState extends State<DiwaliFestiveScreen> {
  late final FestiveStore _store = FestiveStore(initialTab: widget.initialTab);
  final ScrollController _scroll = ScrollController();
  final ValueNotifier<double> _offset = ValueNotifier<double>(0);
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_trackScroll);
  }

  void _trackScroll() {
    if (_scroll.hasClients) _offset.value = _scroll.offset;
  }

  @override
  void dispose() {
    _scroll.removeListener(_trackScroll);
    _scroll.dispose();
    _offset.dispose();
    _store.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------- feedback --

  void _notify(String message, FestivePalette palette) {
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: FestiveType.body(12.5, color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: palette.headerBottom,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
          duration: const Duration(milliseconds: 1700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
  }

  Future<void> _openSearch(FestivePalette palette, double typeScale) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(120),
      builder: (BuildContext context) => FestiveSearchSheet(
        store: _store,
        palette: palette,
        typeScale: typeScale,
      ),
    );
  }

  Future<void> _openCart(FestivePalette palette, double typeScale) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(120),
      builder: (BuildContext context) => FestiveCartSheet(
        store: _store,
        palette: palette,
        typeScale: typeScale,
        onCheckout: () {
          Navigator.of(context).maybePop();
          _notify('Checkout opens the payment screen', palette);
        },
      ),
    );
  }

  Future<void> _openProduct(
    FestiveProduct product,
    FestivePalette palette,
    double typeScale,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(120),
      builder: (BuildContext context) => FestiveProductSheet(
        product: product,
        store: _store,
        palette: palette,
        typeScale: typeScale,
      ),
    );
  }

  // ------------------------------------------------------------------ build --

  @override
  Widget build(BuildContext context) {
    final FestivePalette palette = paletteOf(context);
    final MediaQueryData media = MediaQuery.of(context);
    final double windowWidth = media.size.width;
    final FestiveSize size = FestiveBreakpoints.sizeOf(windowWidth);
    final double contentWidth = math.min(windowWidth, widget.maxContentWidth);
    final double typeScale = size.typeScale;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: palette.navSurface,
        systemNavigationBarIconBrightness:
            palette.isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: palette.surface,
        body: FestiveStoreScope(
          store: _store,
          child: FestiveScope(
            size: size,
            palette: palette,
            contentWidth: contentWidth,
            gutter: size.gutter,
            child: FestiveRevealScope(
              controller: _scroll,
              child: Stack(
                children: <Widget>[
                  MediaQuery.withClampedTextScaling(
                    minScaleFactor: 0.9,
                    maxScaleFactor: 1.35,
                    child: AnimatedBuilder(
                      animation: _store,
                      builder: (BuildContext context, Widget? _) {
                        return CustomScrollView(
                          controller: _scroll,
                          physics: const BouncingScrollPhysics(),
                          slivers: <Widget>[
                            SliverToBoxAdapter(
                              child: _FestiveHero(
                                copy: widget.copy,
                                categories: widget.categories,
                                tiles: widget.tiles,
                                store: _store,
                                onSearchTap: () => _openSearch(palette, typeScale),
                                onVoiceTap: () {
                                  _store.voiceListening = !_store.voiceListening;
                                  if (_store.voiceListening) {
                                    _notify('Listening… say "diya"', palette);
                                  }
                                },
                                onAddressTap: () => _notify(
                                    'Address selector opens here', palette),
                                onWalletTap: () => _notify(
                                    'Wallet: ${rupee(widget.copy.walletBalance)}',
                                    palette),
                                onProfileTap: () =>
                                    _notify('Account opens here', palette),
                                onCategoryTap: (int index) {
                                  _store.tabIndex = index;
                                  final FestiveCategory category =
                                      widget.categories[index];
                                  if (widget.onCategoryTap != null) {
                                    widget.onCategoryTap!(category);
                                  } else {
                                    _notify(
                                      index == 0
                                          ? 'Showing everything festive'
                                          : 'Browsing ${category.label}',
                                      palette,
                                    );
                                  }
                                },
                                onTileTap: (FestiveTile tile) {
                                  if (widget.onTileTap != null) {
                                    widget.onTileTap!(tile);
                                  } else {
                                    _notify(
                                      tile.title.replaceAll('\n', ' '),
                                      palette,
                                    );
                                  }
                                },
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: _FestiveContentSection(
                                rails: widget.rails,
                                store: _store,
                                onProductTap: (FestiveProduct product) =>
                                    _openProduct(product, palette, typeScale),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  _buildMiniHeader(palette, contentWidth, typeScale),
                  _buildCartBar(palette),
                  _buildBackToTop(palette),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: widget.showBottomNav
            ? FestiveBottomBar(
                destinations: widget.navigation,
                index: _navIndex,
                palette: palette,
                showZomato: widget.showZomatoButton,
                onZomatoTap: widget.onZomatoTap ??
                    () => _notify('Food delivery opens Zomato', palette),
                onSelected: (int index) {
                  setState(() => _navIndex = index);
                  if (widget.onNavigate != null) {
                    widget.onNavigate!(index);
                  } else if (index != 0) {
                    _notify(
                      '${widget.navigation[index].label} opens here',
                      palette,
                    );
                  }
                },
              )
            : null,
      ),
    );
  }

  /// Compact header that fades in once the hero has scrolled away.
  Widget _buildMiniHeader(
    FestivePalette palette,
    double contentWidth,
    double typeScale,
  ) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ValueListenableBuilder<double>(
        valueListenable: _offset,
        builder: (BuildContext context, double offset, Widget? child) {
          final double t = ((offset - 120) / 90).clamp(0.0, 1.0).toDouble();
          if (t == 0) return const SizedBox.shrink();
          return IgnorePointer(
            ignoring: t < 0.6,
            child: Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * -16),
                child: child,
              ),
            ),
          );
        },
        child: Material(
          color: palette.headerBottom,
          elevation: 6,
          shadowColor: Colors.black.withAlpha(90),
          child: SizedBox(
            height: 52,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: SizedBox(
                  width: contentWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.location_on_rounded,
                            size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${widget.copy.addressTag} - ${widget.copy.addressLine}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FestiveType.body(
                              13,
                              color: Colors.white,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Semantics(
                          button: true,
                          label: 'Search',
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _openSearch(palette, typeScale),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: <Widget>[
                                  const Icon(Icons.search,
                                      size: 15, color: Colors.white),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Search',
                                    style: FestiveType.body(
                                      11.5,
                                      color: Colors.white,
                                      weight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartBar(FestivePalette palette) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedBuilder(
        animation: _store,
        builder: (BuildContext context, Widget? child) {
          final bool show = _store.hasCart;
          return IgnorePointer(
            ignoring: !show,
            child: AnimatedSlide(
              duration: FestiveMotion.base,
              curve: FestiveMotion.enter,
              offset: show ? Offset.zero : const Offset(0, 1.25),
              child: AnimatedOpacity(
                duration: FestiveMotion.fast,
                opacity: show ? 1 : 0,
                child: FestiveCartBar(
                  count: _store.cartCount,
                  total: _store.cartTotal,
                  palette: palette,
                  onTap: () => _openCart(palette, 1),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackToTop(FestivePalette palette) {
    return Positioned(
      right: 14,
      bottom: 78,
      child: ValueListenableBuilder<double>(
        valueListenable: _offset,
        builder: (BuildContext context, double offset, Widget? child) {
          final bool show = offset > 900;
          return IgnorePointer(
            ignoring: !show,
            child: AnimatedScale(
              duration: FestiveMotion.base,
              curve: FestiveMotion.spring,
              scale: show ? 1 : 0.4,
              child: AnimatedOpacity(
                duration: FestiveMotion.fast,
                opacity: show ? 1 : 0,
                child: child,
              ),
            ),
          );
        },
        child: Semantics(
          button: true,
          label: 'Back to top',
          child: GestureDetector(
            onTap: () {
              _scroll.animateTo(
                0,
                duration: FestiveMotion.slow,
                curve: FestiveMotion.enter,
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: palette.headerBottom,
                shape: BoxShape.circle,
                border: Border.all(color: palette.gold.withAlpha(120)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.keyboard_arrow_up_rounded,
                  size: 22, color: palette.gold),
            ),
          ),
        ),
      ),
    );
  }
}

/// The dark hero: brand strip, tabs, banner title, arch tiles and the
/// diamond divider that hands over to the light section.
class _FestiveHero extends StatelessWidget {
  const _FestiveHero({
    required this.copy,
    required this.categories,
    required this.tiles,
    required this.store,
    required this.onSearchTap,
    required this.onVoiceTap,
    required this.onAddressTap,
    required this.onWalletTap,
    required this.onProfileTap,
    required this.onCategoryTap,
    required this.onTileTap,
  });

  final FestiveCopy copy;
  final List<FestiveCategory> categories;
  final List<FestiveTile> tiles;
  final FestiveStore store;
  final VoidCallback onSearchTap;
  final VoidCallback onVoiceTap;
  final VoidCallback onAddressTap;
  final VoidCallback onWalletTap;
  final VoidCallback onProfileTap;
  final ValueChanged<int> onCategoryTap;
  final ValueChanged<FestiveTile> onTileTap;

  @override
  Widget build(BuildContext context) {
    final FestiveScope scope = FestiveScope.of(context);
    final FestivePalette palette = scope.palette;
    final FestiveSize size = scope.size;
    final double typeScale = size.typeScale;
    final double contentWidth = scope.contentWidth;
    final double gutter = scope.gutter;
    final double wordmarkSize = switch (size) {
      FestiveSize.compact => 37,
      FestiveSize.medium => 46,
      FestiveSize.expanded => 54,
    };
    final double gridGap = switch (size) {
      FestiveSize.compact => 10,
      FestiveSize.medium => 14,
      FestiveSize.expanded => 16,
    };
    final int columns = switch (size) {
      FestiveSize.compact => 3,
      FestiveSize.medium => 4,
      FestiveSize.expanded => 6,
    };
    final double tileWidth =
        (contentWidth - gutter * 2 - gridGap * (columns - 1)) / columns;
    final double gridHeight =
        tileWidth * FestiveMetrics.tileAspect * (tiles.length / columns).ceil() +
            gridGap * ((tiles.length / columns).ceil() - 1);

    return Stack(
      children: <Widget>[
        // One continuous maroon gradient: the header is darkest, the banner
        // glows behind the fairy lights, and the edges fall back to wine.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  palette.headerTop,
                  palette.headerBottom,
                  palette.bannerTop,
                  palette.bannerMid,
                  palette.bannerEdge,
                ],
                stops: const <double>[0, 0.2, 0.36, 0.62, 1],
              ),
            ),
          ),
        ),
        // Warm glow under the lights.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.34),
                  radius: 0.95,
                  colors: <Color>[
                    palette.bannerGlow.withAlpha(210),
                    palette.bannerGlow.withAlpha(0),
                  ],
                ),
              ),
            ),
          ),
        ),
        // The garland that hangs over the status bar in the reference.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: FairyLights.hanging(height: 104, strings: 2),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SafeArea(
              bottom: false,
              child: Center(
                child: SizedBox(
                  width: contentWidth,
                  child: FestiveHeader(
                    copy: copy,
                    palette: palette,
                    typeScale: typeScale,
                    horizontalPadding: gutter,
                    voiceListening: store.voiceListening,
                    onSearchTap: onSearchTap,
                    onVoiceTap: onVoiceTap,
                    onAddressTap: onAddressTap,
                    onWalletTap: onWalletTap,
                    onProfileTap: onProfileTap,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: SizedBox(
                width: contentWidth,
                child: FestiveTabStrip(
                  categories: categories,
                  index: store.tabIndex,
                  onSelected: onCategoryTap,
                  typeScale: typeScale,
                  contentWidth: contentWidth,
                ),
              ),
            ),
            // Banner.
            Stack(
              children: <Widget>[
                Positioned.fill(
                  child: IgnorePointer(
                    child: FestiveBackdrop(palette: palette),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: FairyLights.toran(
                      height: 30,
                      bulbCount: size.isCompact ? 22 : 34,
                      intensity: 0.9,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 22),
                  child: Column(
                    children: <Widget>[
                      FestiveBannerTitle(
                        copy: copy,
                        palette: palette,
                        typeScale: typeScale,
                        wordmarkSize: wordmarkSize,
                      ),
                      SizedBox(height: size.isCompact ? 12 : 18),
                      SizedBox(
                        width: contentWidth,
                        height: gridHeight,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: gutter),
                          child: FestiveTileGrid(
                            tiles: tiles,
                            contentWidth:
                                contentWidth - gutter * 2,
                            size: size,
                            palette: palette,
                            typeScale: typeScale,
                            onTileTap: onTileTap,
                          ),
                        ),
                      ),
                      SizedBox(height: size.isCompact ? 20 : 26),
                      DiamondDivider(color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// The light section under the banner: rails of festive products.
class _FestiveContentSection extends StatelessWidget {
  const _FestiveContentSection({
    required this.rails,
    required this.store,
    required this.onProductTap,
  });

  final List<FestiveRail> rails;
  final FestiveStore store;
  final ValueChanged<FestiveProduct> onProductTap;

  @override
  Widget build(BuildContext context) {
    final FestiveScope scope = FestiveScope.of(context);
    final FestivePalette palette = scope.palette;
    final FestiveSize size = scope.size;
    final double typeScale = size.typeScale;
    final double contentWidth = scope.contentWidth;
    final double gutter = scope.gutter;
    return ColoredBox(
      color: palette.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(height: size.sectionGap),
          for (int i = 0; i < rails.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: size.sectionGap + 6),
              child: Center(
                child: SizedBox(
                  width: contentWidth,
                  child: FestiveReveal(
                    delay: Duration(milliseconds: 90 * i),
                    child: _RailHost(
                      rail: rails[i],
                      palette: palette,
                      size: size,
                      typeScale: typeScale,
                      contentWidth: contentWidth,
                      gutter: gutter,
                      store: store,
                      onProductTap: onProductTap,
                    ),
                  ),
                ),
              ),
            ),
          Center(
            child: SizedBox(
              width: contentWidth,
              child: Padding(
                padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 28),
                child: Column(
                  children: <Widget>[
                    Divider(color: palette.hairline, height: 1),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Sparkle(size: 12, color: palette.goldDeep, pulse: false),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Handpicked for Diwali · prices include GST',
                            textAlign: TextAlign.center,
                            style: FestiveType.body(
                              scope.type(11.5),
                              color: palette.inkSoft,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Sparkle(size: 12, color: palette.goldDeep, pulse: false),
                      ],
                    ),
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

/// Binds one rail to the live store so a card rebuilds when its own quantity
/// or wishlist state changes.
class _RailHost extends StatelessWidget {
  const _RailHost({
    required this.rail,
    required this.palette,
    required this.size,
    required this.typeScale,
    required this.contentWidth,
    required this.gutter,
    required this.store,
    required this.onProductTap,
  });

  final FestiveRail rail;
  final FestivePalette palette;
  final FestiveSize size;
  final double typeScale;
  final double contentWidth;
  final double gutter;
  final FestiveStore store;
  final ValueChanged<FestiveProduct> onProductTap;

  @override
  Widget build(BuildContext context) {
    return FestiveRailView(
      rail: rail,
      palette: palette,
      size: size,
      typeScale: typeScale,
      contentWidth: contentWidth - gutter * 2,
      gutter: gutter,
      quantityOf: store.quantityOf,
      isWishlisted: store.isWishlisted,
      onAdd: store.add,
      onRemove: store.remove,
      onWishlist: (FestiveProduct product) {
        store.toggleWishlist(product);
      },
      onProductTap: onProductTap,
    );
  }
}
