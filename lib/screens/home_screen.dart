import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/app_network_image.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../models/festival.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/delivery_eta_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import '../utils/format.dart';
import '../widgets/category_icon_tab.dart';
import '../widgets/chip_store_sections.dart';
import '../widgets/delivery_address_sheet.dart';
import '../widgets/edit_badge.dart';
import '../widgets/edit_tools.dart';
import '../widgets/home_brand_store_sections.dart';
import '../widgets/festival_sections.dart';
import '../widgets/home_all_sections.dart';
import '../widgets/night_sky.dart';
import '../widgets/product_card.dart';
import '../widgets/voice_search_button.dart';
import '../widgets/voice_search_sheet.dart';
import 'auth/login_screen.dart';
import 'notifications_screen.dart';
import 'product_detail_screen.dart';
import 'search_screen.dart';
import 'main_shell.dart';
import 'category_listing_screen.dart';
import '../widgets/pressable.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _promoPage = 0;

  /// The offer cards move on their own: one slides into the middle and rests
  /// there, then the next. Another tab, a page pushed on top of this one, or
  /// a finger on the row holds it still.
  bool _promoDriftOn = true;
  bool _homeOnTop = true;

  /// How long one slide takes, and how long each card then rests in the
  /// middle. A scroll that is moving shuts its cards off from taps, so the
  /// row must stand still most of the time or nothing on it can be opened.
  static const _promoSlide = Duration(milliseconds: 650);
  static const _promoRest = Duration(seconds: 3);

  /// A touch on the row holds the flow until this moment, so the card the
  /// shopper is reaching for does not slide away under their finger.
  DateTime _promoHoldUntil = DateTime(0);

  /// The offers start a long way into the endless row, so they can be sent
  /// back the way they came as well as on.
  static const _promoStart = 10000;

  /// Share of the width one banner takes, so the next ones peek in at the
  /// sides; the banner in the middle is drawn full size, the others smaller.
  /// These match the festival page's picture cards, so both rows of offers
  /// read as one family.
  static const _promoFraction = 0.6;
  static const _promoGap = 5.0;
  static const _promoSideScale = 0.9;
  late final PageController _promoController;

  // Shown when the admin has no working banners. Only claims that are true:
  // the free-delivery rule comes from the real delivery-fee settings.
  static List<({String title, String subtitle})> _promoSlides(
    AppLocalizations l10n,
  ) =>
      [
        (
          title: l10n.homeFreeDelivery,
          subtitle: l10n.homeFreeDeliveryAbove(
              formatRupees(OrderProvider.freeDeliveryThreshold)),
        ),
      ];

  List<Map<String, dynamic>> _banners = [];

  // After 10 pm the header turns to a night sky (until 6 am).
  bool _night = NightSky.active;
  Timer? _clock;

  // The festival calendar; the one that is on today dresses the Festival chip.
  List<Festival> _festivals = [];
  Festival? _festival;

  /// Whether any festival is within its window (see [_visibleChips]) —
  /// tracked so the minute clock notices the exact day it flips, not only
  /// the days something else already triggers a rebuild.
  bool _festivalNear = false;

  /// The dark sky is for the everyday header; the Festival page has its own
  /// warm colours even after dark.
  bool get _onFestivalTab =>
      context.read<ProductProvider>().selectedCategory ==
      FestivalSections.category;
  bool get _dark => _night && !_onFestivalTab;

  /// The Home strip, minus the Festival chip outside its own window: a week
  /// before the nearest festival starts, through a week after the last one
  /// on the calendar ends. Chasing an empty page the rest of the year is
  /// worse than a strip one chip shorter.
  List<HomeChip> get _visibleChips {
    final chips = homeChips;
    if (_festivalNear) return chips;
    return chips.where((c) => c.name != FestivalSections.category).toList();
  }

  /// The header, search bar and chip strip have a fixed height, so their text
  /// keeps its normal size whatever text size the phone is set to: a line that
  /// grows would push the layout around or get cut off.
  Widget _fixedText(BuildContext context, Widget child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: child,
      );

  /// The colours of the store page being shown (only used on store pages).
  StoreTheme get _storeTheme =>
      StoreTheme.of(context.read<ProductProvider>().selectedCategory);

  /// Whether the chip picked is one with a store page of its own (sub-category
  /// cards, Top Deals, shelves) rather than the plain product grid.
  bool get _storePage {
    final provider = context.read<ProductProvider>();
    final chip = provider.selectedCategory;
    if (chip == 'All' ||
        chip == FestivalSections.category ||
        provider.selectedBrand != null ||
        provider.searchQuery.isNotEmpty) {
      return false;
    }
    return ChipStoreSections.hasStore(provider, chip);
  }

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      final night = NightSky.active;
      final festival = Festival.current(_festivals);
      final near = _festivals.any((f) => f.isNear(DateTime.now()));
      if (mounted &&
          (night != _night || festival != _festival || near != _festivalNear)) {
        setState(() {
          _night = night;
          _festival = festival;
          _festivalNear = near;
        });
      }
    });
    NightSky.forced.addListener(_themeChanged);
    _promoController = PageController(
      viewportFraction: _promoFraction,
      initialPage: _promoStart,
    );
    _promoPage = _promoStart;
    unawaited(_driftOffers());
    _watchBanners();
    _loadFestivals();
  }

  void _themeChanged() {
    if (mounted) setState(() => _night = NightSky.active);
  }

  Future<void> _loadFestivals() async {
    try {
      final rows = await SupabaseService.client
          .from('festivals')
          .select()
          .eq('is_active', true);
      final all = [
        for (final row in rows)
          Festival.fromMap(Map<String, dynamic>.from(row)),
      ];
      if (mounted) {
        setState(() {
          _festivals = all;
          _festival = Festival.current(all);
          _festivalNear = all.any((f) => f.isNear(DateTime.now()));
        });
      }
    } catch (_) {
      // Best-effort decoration: the store below must keep working when the
      // festival read fails, so the header simply stays un-dressed instead
      // of failing the page.
    }
  }

  StreamSubscription<List<Map<String, dynamic>>>? _bannerWatch;

  /// Keeps the offer carousel current for as long as Home is open: an admin
  /// publishing, editing or reordering a banner used to only reach a
  /// shopper's screen on their next app launch — this reflects it the
  /// moment it happens, the same way OrderProvider keeps a tracked order's
  /// status live.
  void _watchBanners() {
    _bannerWatch = SupabaseService.client
        .from('banners')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('sort_order')
        .listen(
          _applyBannerRows,
          // Best-effort: a dropped realtime connection just means the
          // carousel stops updating live, not that the page breaks.
          onError: (Object e) => debugPrint('Banner watch failed: $e'),
        );
  }

  /// A one-off re-fetch for right after this device's own edit — the
  /// realtime watch above would pick it up too, but not to wait on: the
  /// change should be back on screen the moment the editor closes, not
  /// whenever the websocket round-trip happens to land.
  Future<void> _loadBanners() async {
    try {
      final rows = await SupabaseService.client
          .from('banners')
          .select(
            'id, sort_order, image_url, link_type, link_id, title, subtitle, cta_label, '
            'color_from, color_to, accent_color, product_image_urls',
          )
          .eq('is_active', true)
          .order('sort_order');
      await _applyBannerRows(List<Map<String, dynamic>>.from(rows));
    } catch (_) {
      // Best-effort: no banners is a valid home page; a failed read must
      // not take the shelves below down with it.
    }
  }

  Future<void> _applyBannerRows(List<Map<String, dynamic>> rows) async {
    // Keep only picture banners whose image actually loads — a dead link
    // would otherwise leave a blank box in the carousel. Offer banners
    // (with a title) are drawn by the app, so they need no check.
    final checks = await Future.wait(
      rows.map(
        (row) => row['title'] != null
            ? Future.value(true)
            : _bannerLoads(row['image_url'] as String?),
      ),
    );
    final working = <Map<String, dynamic>>[
      for (var i = 0; i < rows.length; i++)
        if (checks[i]) Map<String, dynamic>.from(rows[i]),
    ];
    if (mounted) setState(() => _banners = working);
  }

  Future<bool> _bannerLoads(String? url) async {
    if (url == null || url.isEmpty || !mounted) return false;
    // Pictures that ship inside the app are always there.
    if (url.startsWith('asset:')) return true;
    var failed = false;
    try {
      await precacheImage(
        CachedNetworkImageProvider(url),
        context,
        onError: (_, __) => failed = true,
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      return false;
    }
    return !failed;
  }

  /// A ready-made banner picture: `asset:path` for one bundled with the app,
  /// otherwise a web address.
  Widget _bannerPicture(String url) {
    if (url.startsWith('asset:')) {
      return Image.asset(
        url.substring(6),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: AppConstants.accentColor),
      );
    }
    return ColoredBox(
      color: Colors.white,
      child: AppNetworkImage(
        url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: AppConstants.accentColor),
      ),
    );
  }

  /// The banner's own colours, as the card's background gradient when it
  /// has no product photo to show. Null when the row carries none.
  List<Color>? _bannerTint(Map<String, dynamic> banner) {
    final colors = <Color>[];
    for (final value in [banner['color_from'], banner['color_to']]) {
      final hex = (value as String?)?.replaceFirst('#', '').trim() ?? '';
      if (hex.length != 6) return null;
      final parsed = int.tryParse('FF$hex', radix: 16);
      if (parsed == null) return null;
      colors.add(Color(parsed));
    }
    return [
      colors[0],
      Color.lerp(colors[1], AppConstants.primaryColor, 0.2)!,
    ];
  }

  void _onBannerTap(Map<String, dynamic> banner) {
    if (banner['link_type'] == 'category' && banner['link_id'] != null) {
      // "Category" or "Category|Sub-category".
      final parts = (banner['link_id'] as String).split('|');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryListingScreen(
            title: parts.first,
            initialCategory: parts.length > 1 ? parts[1] : null,
          ),
        ),
      );
      return;
    }
    if (banner['link_type'] == 'product' && banner['link_id'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ProductDetailScreen(productId: banner['link_id'] as String),
        ),
      );
    }
  }

  @override
  void dispose() {
    NightSky.forced.removeListener(_themeChanged);
    _promoDriftOn = false;
    _clock?.cancel();
    _bannerWatch?.cancel();
    _promoController.dispose();
    super.dispose();
  }

  /// Whether the offers are on screen: the home tab, with nothing pushed
  /// over it. There is no point sliding a row nobody can see.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _homeOnTop = ModalRoute.of(context)?.isCurrent ?? true;
  }

  /// The flow itself: one card slides into the middle, rests there for
  /// [_promoRest], then the next. Every slide ends on a card, which is where
  /// the scroll's own physics would have put it anyway, so a swipe still
  /// lands on a card as it should.
  Future<void> _driftOffers() async {
    while (mounted && _promoDriftOn) {
      await Future<void>.delayed(_promoRest);
      if (!mounted || !_promoDriftOn) return;
      if (!_homeOnTop || MainShell.tab.value != MainShell.home) continue;
      if (DateTime.now().isBefore(_promoHoldUntil)) continue;
      if (!_promoController.hasClients) continue;
      final position = _promoController.position;
      // A finger on the row, or the row still settling after one, owns it.
      if (!position.haveDimensions || position.isScrollingNotifier.value) {
        continue;
      }
      final page = _promoController.page;
      if (page == null) continue;
      await _promoController.animateToPage(
        page.round() + 1,
        duration: _promoSlide,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  /// A tap on a banner: the one in the middle opens; one peeking in at the
  /// side is only brought to the middle, so a near miss never opens the
  /// wrong offer.
  void _onPromoTap(int index, VoidCallback open) {
    final page = _promoController.hasClients ? _promoController.page : null;
    if (page != null && (page - index).abs() > 0.5) {
      _promoController.animateToPage(
        index,
        duration: _promoSlide,
        curve: Curves.easeInOutCubic,
      );
      return;
    }
    open();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final statusBarHeight = MediaQuery.of(context).padding.top;
    // Extra room under the last row when the floating cart pill rides on
    // top of the bottom bar.
    final pillRoom = cartProvider.itemCount > 0 ? 70.0 : 0.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        // Only an admin sees this: it switches the pencils on.
        // Lifted above the floating bottom bar, which the page runs behind.
        floatingActionButton: Padding(
          padding: EdgeInsets.only(
            bottom: 96 + MediaQuery.of(context).padding.bottom,
          ),
          child: const EditModeSwitch(),
        ),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: false,
              toolbarHeight: 0,
              automaticallyImplyLeading: false,
              backgroundColor: _dark
                  ? const Color(0xFF2B3347)
                  : _onFestivalTab
                      ? (_festival?.colorFrom ?? const Color(0xFFFFD9A8))
                      : _storePage
                          ? _storeTheme.header
                          : const Color(0xFFFFE7A1),
              elevation: 0,
              // Room for the delivery time and the address line above the
              // pinned search bar.
              expandedHeight: 65 + 126 + statusBarHeight,
              flexibleSpace: FlexibleSpaceBar(
                background: _fixedText(
                  context,
                  _buildCollapsibleTop(context, authProvider, cartProvider),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(50 + 92),
                child: _fixedText(
                  context,
                  Column(
                    children: [
                      _buildSearchBar(context),
                      _buildCategoryStrip(productProvider),
                    ],
                  ),
                ),
              ),
            ),
            // Under the chips of every other page the header's colour fades
            // into the page, instead of stopping in a hard edge.
            if (!_onFestivalTab && !_storePage)
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: _dark
                          ? const [Color(0xFFF6F7FB), Color(0xFFFAF5EE)]
                          : const [Color(0xFFFFE7A1), Color(0xFFFFF7D8)],
                    ),
                  ),
                  child: _buildPromoCarousel(),
                ),
              ),
            if (!_onFestivalTab && !_storePage) ...const [
              SliverToBoxAdapter(child: SizedBox(height: 6)),
              SliverToBoxAdapter(child: HomeBrandsSection()),
            ],
            if (productProvider.selectedCategory == 'All' &&
                productProvider.selectedBrand == null &&
                productProvider.searchQuery.isEmpty &&
                productProvider.allProducts.isNotEmpty)
              ...HomeAllSections.slivers(context)
            else if (_onFestivalTab &&
                productProvider.selectedBrand == null &&
                productProvider.searchQuery.isEmpty)
              SliverToBoxAdapter(
                child: FestivalSections(
                  festival: _festival,
                  onEdited: _loadFestivals,
                ),
              )
            else if (_storePage)
              SliverToBoxAdapter(
                child: ChipStoreSections(
                    category: productProvider.selectedCategory),
              )
            else ...[
              SliverToBoxAdapter(child: _buildProductCount(productProvider)),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              _buildProductGrid(productProvider),
            ],
            SliverToBoxAdapter(
              // The bar floats over the scroll; when the cart pill rides
              // above it too, the last row needs that much more room.
              child: SizedBox(
                height: 96 + pillRoom + MediaQuery.of(context).padding.bottom,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The delivery-time lines in the header, worked out from the customer's
  /// address and the nearest store. Nothing is quoted without them.
  List<Widget> _etaLines(DeliveryEtaProvider eta) {
    final l10n = AppLocalizations.of(context);
    final ink = _dark ? Colors.white : AppConstants.textPrimaryColor;
    final String small;
    final String big;
    switch (eta.status) {
      case DeliveryStatus.ok:
        small = l10n.homeEtaDeliveryIn;
        big = eta.label ?? '';
      case DeliveryStatus.noLocation:
        small = l10n.homeEtaDeliveryTime;
        big = l10n.homeEtaSetAddress;
      case DeliveryStatus.noStore:
        small = l10n.homeEtaDelivery;
        big = l10n.homeEtaFromLocal;
      case DeliveryStatus.outOfRange:
        small = eta.storeName == null
            ? l10n.homeEtaDelivery
            : l10n.homeEtaNearestStore(eta.storeName!);
        big = l10n.homeEtaOutOfRange;
    }
    final ok = eta.status == DeliveryStatus.ok;
    return [
      Text(
        small,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 12,
          height: 1.2,
          fontWeight: FontWeight.w500,
          color: ink.withOpacity(_dark ? 0.85 : 0.7),
        ),
      ),
      const SizedBox(height: 2),
      Row(
        children: [
          Flexible(
            child: Text(
              big,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: ok ? 22 : 19,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
          ),
          if (ok && eta.distanceLabel != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _dark
                    ? Colors.white.withOpacity(0.18)
                    : const Color(0xFF1E88E5).withOpacity(0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                eta.distanceLabel!,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _dark ? Colors.white : const Color(0xFF1565C0),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    ];
  }

  // Gradient header top: mode toggle, delivery ETA, address (collapses on scroll).
  Widget _buildCollapsibleTop(
    BuildContext context,
    AuthProvider authProvider,
    CartProvider cartProvider,
  ) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    // The search bar and chip strip sit below this area (50 + 92 tall).
    const belowHeight = 50.0 + 92;
    return LayoutBuilder(builder: (context, box) {
      final total = box.maxHeight.isFinite ? box.maxHeight : 220.0;
      return Container(
        decoration: BoxDecoration(
          gradient: _dark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF151B2B),
                    Color(0xFF2B3347),
                    Color(0xFF465067),
                  ],
                )
              : _onFestivalTab
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _festival?.colorFrom ?? const Color(0xFFFFD9A8),
                        _festival?.colorTo ?? const Color(0xFFFFF1DE),
                      ],
                    )
                  : _storePage
                      // A store page takes its own colour, which carries on
                      // down through its hero and offer cards.
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [_storeTheme.header, _storeTheme.header],
                        )
                      : AppConstants.homeHeaderGradient,
          // The Festival and store pages flow straight from the header into
          // their hero, so there the header's bottom is square, with no
          // curved corners.
          borderRadius: (_onFestivalTab || _storePage)
              ? BorderRadius.zero
              : const BorderRadius.only(
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
        ),
        child: Stack(
          children: [
            if (_dark)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: total - belowHeight + 30,
                child: const NightSkyAnimation(),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(30, 6 + statusBarHeight, 21, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              _etaLines(context.watch<DeliveryEtaProvider>()),
                        ),
                      ),
                      _headerIconButton(
                        icon: Iconsax.notification,
                        badgeCount:
                            context.watch<NotificationProvider>().unreadCount,
                        // Notifications belong to an account: guests log in first.
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => authProvider.isLoggedIn
                                ? const NotificationsScreen()
                                : const LoginScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Pressable(
                          child: GestureDetector(
                        onTap: () => MainShell.tab.value = MainShell.cart,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _headerIconButton(
                              icon: Iconsax.shopping_cart_copy,
                              onTap: null,
                            ),
                            if (cartProvider.itemCount > 0)
                              Positioned(
                                right: -3,
                                top: -3,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: AppConstants.dangerColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 1.5),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${cartProvider.itemCount}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ],
              ),
            ),
            // The address line hangs just above the search bar, whatever the
            // phone's status bar height, so it never slides under it.
            Positioned(
              left: 30,
              right: 21,
              bottom: belowHeight + 8,
              child:
                  // Opens the address chooser (live location / map / typed / saved),
                  // for guests and signed-in users alike.
                  Pressable(
                      child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => showDeliveryAddressSheet(context),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        authProvider.address.isNotEmpty
                            ? authProvider.address
                            : AppLocalizations.of(context).homeAddressHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _dark
                              ? Colors.white
                              : AppConstants.textPrimaryColor
                                  .withOpacity(0.85),
                        ),
                      ),
                    ),
                    // The location pin sits at the right end, in the same
                    // 36-wide slot as the cart above it, so the two line up
                    // with the voice button below.
                    SizedBox(
                      width: 36,
                      child: Icon(
                        Iconsax.location_copy,
                        size: 20,
                        color: _dark
                            ? Colors.white
                            : AppConstants.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              )),
            ),
          ],
        ),
      );
    });
  }

  // Pinned search bar — stays visible while the section above collapses away.
  /// "Search for guava, Maggi, laptop…" — examples taken from what's really
  /// in the store, not a fixed list.
  String _searchHint(ProductProvider provider) {
    final names = <String>[];
    for (final p in provider.allProducts) {
      final name = p.name.trim();
      if (name.isEmpty || name.length > 14) continue;
      if (names.any((n) => n.toLowerCase() == name.toLowerCase())) continue;
      names.add(name);
      if (names.length == 3) break;
    }
    final l10n = AppLocalizations.of(context);
    return names.isEmpty
        ? l10n.homeSearchProducts
        : l10n.homeSearchFor(names.join(', '));
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          // The search field. Tapping it opens search.
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                );
              },
              child: Container(
                height: VoiceSearchButton.size,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(VoiceSearchButton.radius),
                  border: Border.all(
                    color: VoiceSearchButton.borderColor,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.search_normal_1_copy,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _searchHint(context.watch<ProductProvider>()),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Voice and photo search: its own button beside the field.
          VoiceSearchButton(onTap: () => _openVoiceSearch(context)),
        ],
      ),
    );
  }

  /// Opens the voice / photo sheet over Home, then the search screen with
  /// what was said, or asking for a photo.
  Future<void> _openVoiceSearch(BuildContext context) async {
    final result = await showVoiceSearchSheet(context);
    if (result == null || !context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => result.photo
            ? SearchScreen(photoSource: result.photoSource)
            : SearchScreen(initialTerms: result.terms),
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    VoidCallback? onTap,
    int badgeCount = 0,
  }) {
    return Pressable(
        child: GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _dark
                  ? Colors.white.withOpacity(0.16)
                  : Colors.white.withOpacity(0.55),
            ),
            child: Icon(
              icon,
              color: _dark ? Colors.white : AppConstants.textPrimaryColor,
              size: 20,
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppConstants.dangerColor,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    ));
  }

  // Category icon strip, sitting on the page background below the header.
  Widget _buildCategoryStrip(ProductProvider productProvider) {
    final l10n = AppLocalizations.of(context);
    final chips = _visibleChips;
    return Container(
      // At night the chips sit on a light fade, so their labels stay
      // readable whether the header is open or pinned.
      decoration: _dark
          ? const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00E9EBF3),
                  Color(0xFFE9EBF3),
                  Color(0xFFF6F7FB)
                ],
                stops: [0, 0.35, 1],
              ),
            )
          : null,
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: SizedBox(
        height: 84,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          itemCount: chips.length + 1,
          itemBuilder: (context, index) {
            if (index == chips.length) {
              return CategoryIconTab(
                label: l10n.homeSeeAll,
                icon: Iconsax.category,
                isSelected: false,
                onTap: () => MainShell.tab.value = MainShell.categories,
              );
            }
            final chip = chips[index];
            final tab = CategoryIconTab(
              label: chip.name == FestivalSections.category
                  ? (_festival?.chipLabel ?? chip.name)
                  : chip.name,
              icon: chip.icon,
              isSelected: productProvider.selectedCategory == chip.name,
              onTap: () {
                productProvider.setBrand(null);
                productProvider.setCategory(chip.name);
              },
            );
            // Each chip has its own pencil (edit mode only): its own
            // tools, or the festival's while one is on.
            if (chip.name == 'All') return tab;
            final festival = _festival;
            if (chip.name == FestivalSections.category && festival != null) {
              return FestivalEditPencil(
                festival: festival,
                onChanged: _loadFestivals,
                child: tab,
              );
            }
            return CategoryEditPencil(name: chip.name, child: tab);
          },
        ),
      ),
    );
  }

  // Swipeable promo banner with dot indicators.
  Widget _buildPromoCarousel() {
    // The offer cards wear the festival page's tall card shape: the same
    // width, and one and a half times as tall.
    final cardHeight =
        (MediaQuery.of(context).size.width * _promoFraction - 2 * _promoGap) *
            1.5;
    final l10n = AppLocalizations.of(context);
    final slideCount = _promoSlideCount(l10n);
    return Column(
      children: [
        SizedBox(
          height: cardHeight,
          // Any touch on the row holds the flow for a while.
          child: Listener(
            onPointerDown: (_) => _promoHoldUntil =
                DateTime.now().add(const Duration(seconds: 6)),
            child: PageView.builder(
              controller: _promoController,
              // Endless, so the drift never reaches the end of the row.
              itemCount: null,
              // The dots listen to the controller themselves, so a swipe
              // repaints five little dots rather than the whole page.
              onPageChanged: (page) => _promoPage = page,
              itemBuilder: (context, index) => _focusScaled(
                index,
                Builder(builder: (context) {
                  // The row is endless, so the slides come round again.
                  final i = index % slideCount;
                  if (_banners.isNotEmpty) {
                    final banner = _banners[i];
                    if (banner['title'] != null) {
                      final raw = banner['product_image_urls'] as List? ?? [];
                      var photo = '';
                      for (final u in raw.whereType<String>()) {
                        if (u.isNotEmpty) {
                          photo = u;
                          break;
                        }
                      }
                      var cta = banner['cta_label'] as String?;
                      if (cta == null || cta.isEmpty) cta = l10n.homeShopNow;
                      const pad = EdgeInsets.symmetric(horizontal: _promoGap);
                      return Padding(
                        padding: pad,
                        // Same card, look and size as the festival carousel;
                        // the banner keeps its own words, photo and action.
                        child: PictureCard(
                          accent: AppConstants.primaryColor,
                          card: PictureCardData(
                            title: banner['title'] as String,
                            subtitle: banner['subtitle'] as String? ?? '',
                            imageUrl: photo,
                            ctaLabel: cta,
                            tint: _bannerTint(banner),
                            onTap: () =>
                                _onPromoTap(index, () => _onBannerTap(banner)),
                          ),
                        ),
                      );
                    }
                    return GestureDetector(
                      onTap: () =>
                          _onPromoTap(index, () => _onBannerTap(banner)),
                      child: Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: _promoGap),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.primaryColor
                                  .withOpacity(0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: _bannerPicture(banner['image_url'] as String),
                        ),
                      ),
                    );
                  }
                  final slide = _promoSlides(l10n)[i];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: _promoGap),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        begin: Alignment.bottomRight,
                        end: Alignment.topLeft,
                        colors: [
                          AppConstants.blackColor,
                          Color(0xFFB84A00),
                          AppConstants.accentColor,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppConstants.primaryColor.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -20,
                            top: -20,
                            child: ImageFiltered(
                              imageFilter:
                                  ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.35),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        slide.title,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        slide.subtitle,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white
                                              .withOpacity(0.9),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Iconsax.discount_shape_copy,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: _promoController,
          builder: (context, _) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(slideCount, (index) {
              final isActive = index == _promoDot(l10n);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppConstants.primaryColor
                      : AppConstants.primaryColor.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  /// How many offer cards there are: the admin's banners, or the one
  /// built-in slide. The row repeats them, so it never runs out.
  int _promoSlideCount(AppLocalizations l10n) =>
      _banners.isNotEmpty ? _banners.length : _promoSlides(l10n).length;

  /// The slide nearest the middle of the viewport: the dot that is lit.
  int _promoDot(AppLocalizations l10n) {
    final count = _promoSlideCount(l10n);
    if (_promoController.hasClients &&
        _promoController.position.haveDimensions) {
      final page = _promoController.page;
      if (page != null) return page.round() % count;
    }
    return _promoPage % count;
  }

  /// Scales a banner down as it slides away from the middle of the screen, so
  /// the one in focus stands a little larger than its neighbours.
  Widget _focusScaled(int index, Widget child) {
    return AnimatedBuilder(
      animation: _promoController,
      builder: (context, child) {
        var page = _promoPage.toDouble();
        if (_promoController.hasClients &&
            _promoController.position.haveDimensions) {
          page = _promoController.page ?? page;
        }
        final t = (1 - (page - index).abs()).clamp(0.0, 1.0);
        return Transform.scale(
          scale: _promoSideScale + (1 - _promoSideScale) * t,
          child: child,
        );
      },
      // Every banner has its own pencil; the stand-in slide offers to add one.
      child: BannerEditPencil(
        banner: _banners.isEmpty ? null : _banners[index % _banners.length],
        onChanged: _loadBanners,
        child: child,
      ),
    );
  }

  Widget _buildProductCount(ProductProvider productProvider) {
    final l10n = AppLocalizations.of(context);
    final brand = productProvider.selectedBrand;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.homeProductsFound(productProvider.filteredProducts.length),
              style: GoogleFonts.poppins(
                color: const Color(0xFF757575),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (brand != null)
            InputChip(
              label: Text(brand,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              onDeleted: () => productProvider.setBrand(null),
              backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
            ),
        ],
      ),
    );
  }

  /// What to show instead of the grid: a spinner while loading, a retry if
  /// the load failed, otherwise a plain "nothing here".
  Widget _buildGridEmpty(ProductProvider productProvider) {
    final l10n = AppLocalizations.of(context);
    if (productProvider.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final failed = productProvider.loadFailed;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        children: [
          Icon(
            failed ? Iconsax.wifi_square : Iconsax.box,
            size: 56,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            failed ? l10n.homeLoadFailed : l10n.homeNoProducts,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF757575),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            failed ? l10n.homeLoadFailedBody : l10n.homeNoProductsBody,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (failed) ...[
            const SizedBox(height: 14),
            Pressable(
                child: OutlinedButton(
              onPressed: productProvider.reload,
              child: Text(l10n.homeRetry,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            )),
          ],
        ],
      ),
    );
  }

  /// The shelf of products on the "All" tab.
  ///
  /// It is a sliver, not a grid inside a box: the products are then built as
  /// they scroll into view, so a long catalogue no longer has to be laid out
  /// in one go — the first frame comes up straight away and the memory only
  /// holds what is on screen.
  Widget _buildProductGrid(ProductProvider productProvider) {
    final products = productProvider.filteredProducts;
    if (products.isEmpty) {
      return SliverToBoxAdapter(child: _buildGridEmpty(productProvider));
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          return SliverGrid(
            gridDelegate: ProductCardMetrics.delegate(
              width: constraints.crossAxisExtent,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, index) => _productCell(products[index]),
              childCount: products.length,
            ),
          );
        },
      ),
    );
  }

  Widget _productCell(Product product) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: product.id),
        ),
      ),
      child: ProductCard(product: product),
    );
  }
}
