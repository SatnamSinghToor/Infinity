import 'package:flutter/material.dart';

import 'diwali_config.dart';
import 'diwali_data.dart';
import 'diwali_icons.dart';
import 'diwali_product_card.dart';
import 'diwali_reveal.dart';
import 'diwali_sections.dart';
import 'diwali_store.dart';
import 'diwali_theme.dart';
import 'diwali_utils.dart';

/// Standalone route wrapper. Register it as `kDiwaliRoute` in the app, or
/// push it with [Navigator]; the same storefront is also embedded directly in
/// the Home tab through [DiwaliHomePage].
class DiwaliPage extends StatelessWidget {
  const DiwaliPage({super.key, this.onNavigate});

  /// Optional host navigation for the bottom bar. `MainShell` supplies this
  /// when the storefront *is* the Home tab, so its four items still reach the
  /// real Categories / Cart / Profile tabs.
  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: DiwaliColors.cream,
        body: DiwaliHomePage(
          showBottomNav: true,
          onNavigate: onNavigate,
        ),
      );
}

/// The festive storefront, complete with sticky header, live search, cart,
/// bottom navigation and back-to-top. Embeddable: when [showBottomNav] is
/// false the host app's own navigation bar remains the only one on screen.
class DiwaliHomePage extends StatefulWidget {
  const DiwaliHomePage({
    super.key,
    this.showBottomNav = false,
    this.onExit,
    this.onCategoryTap,
    this.onTabTap,
    this.onNavigate,
  });

  final bool showBottomNav;
  final VoidCallback? onExit;
  final ValueChanged<String>? onCategoryTap;
  final ValueChanged<int>? onTabTap;
  final ValueChanged<int>? onNavigate;

  @override
  State<DiwaliHomePage> createState() => _DiwaliHomePageState();
}

class _DiwaliHomePageState extends State<DiwaliHomePage> {
  final DiwaliStore _store = DiwaliStore();
  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();
  bool _searchOpen = false;
  bool _cartOpen = false;
  int _navIndex = 0;

  @override
  void dispose() {
    _store.dispose();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _openSearch() {
    _search.text = _store.query;
    _search.selection = TextSelection.collapsed(offset: _search.text.length);
    setState(() => _searchOpen = true);
  }

  void _closeSearch() {
    FocusScope.of(context).unfocus();
    _store.setVoiceListening(false);
    setState(() => _searchOpen = false);
  }

  void _openCart() => setState(() => _cartOpen = true);
  void _closeCart() => setState(() => _cartOpen = false);

  void _scrollToTop() {
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeOutCubic,
    );
  }

  void _notify(String message) {
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: DiwaliText.body(12.5, color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: DiwaliColors.wine600,
        duration: const Duration(milliseconds: 1700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _handleCategory(String category) {
    if (widget.onCategoryTap != null) {
      widget.onCategoryTap!(category);
    } else {
      _notify('Browsing $category');
    }
  }

  void _handleTab(int index) {
    if (widget.onTabTap != null) {
      widget.onTabTap!(index);
    } else {
      _notify('${DiwaliCatalog.tabs[index].label} edit is coming up');
    }
  }

  void _handleNav(int index) {
    // With a host navigation callback the storefront keeps its own bar but
    // the taps still land on the app's real tabs.
    if (widget.onNavigate != null && index != 0) {
      widget.onNavigate!(index);
      return;
    }
    setState(() => _navIndex = index);
    switch (index) {
      case 0:
        _scrollToTop();
        break;
      case 1:
        _notify('Categories are on the Diwali home page');
        break;
      case 2:
        _openCart();
        break;
      case 3:
        _notify('Your profile is a tap away');
        break;
    }
  }

  void _showProduct(DiwaliProduct product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DiwaliScope(
        store: _store,
        child: _DiwaliProductSheet(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The host app applies a global 0.85 text scaler in MaterialApp.builder.
    // The storefront's fixed-height chips, steppers and rails are drawn to a
    // single type scale, so it owns its own scaling here. (The app already
    // ignores the OS text-size setting at its root, so this does not remove
    // an accessibility control that was available.)
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: DiwaliScope(
        store: _store,
        child: DiwaliRevealScope(
          controller: _scroll,
          child: AnimatedBuilder(
            animation: _store,
            builder: (context, _) => AnimatedBuilder(
              animation: _scroll,
              builder: (context, _) => _buildStack(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStack(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final layout = DiwaliLayout(screen.width);
    final offset = _scroll.hasClients ? _scroll.offset : 0.0;
    final sticky = (offset / (layout.heroHeight * 0.72)).clamp(0.0, 1.0);
    final showBackToTop = offset > 900;

    final navHeight = widget.showBottomNav ? 62.0 + bottomInset : 0.0;
    final cartBarHeight = _store.hasCart ? 62.0 : 0.0;

    return Stack(
      children: [
        // ---- Storefront ------------------------------------------
        Positioned.fill(
          child: DiwaliStorefrontBody(
            scrollController: _scroll,
            onSearchTap: _openSearch,
            onCartTap: _openCart,
            onCategoryTap: _handleCategory,
            onTabTap: _handleTab,
            onProductTap: _showProduct,
          ),
        ),

        // ---- Sticky light header ----------------------------------
        if (sticky > 0.01)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: sticky < 0.85,
              child: Opacity(
                opacity: sticky,
                child: Transform.translate(
                  offset: Offset(0, -(1 - sticky) * 18),
                  child: _DiwaliStickyHeader(
                    onSearchTap: _openSearch,
                    onCartTap: _openCart,
                    onBack: widget.onExit ??
                        (Navigator.canPop(context)
                            ? () => Navigator.of(context).maybePop()
                            : null),
                    cartCount: _store.cartCount,
                  ),
                ),
              ),
            ),
          ),

        // ---- Back to top ------------------------------------------
        if (showBackToTop)
          Positioned(
            right: 16,
            bottom: navHeight + cartBarHeight + 14,
            child: DiwaliCircleButton(
              onTap: _scrollToTop,
              size: 40,
              icon: Icons.keyboard_arrow_up_rounded,
              background: DiwaliColors.wine600,
              color: Colors.white,
            ),
          ),

        // ---- Sticky cart bar --------------------------------------
        if (_store.hasCart)
          Positioned(
            left: 0,
            right: 0,
            bottom: navHeight,
            child: GestureDetector(
              onTap: _openCart,
              child: _DiwaliCartBar(store: _store),
            ),
          ),

        // ---- Bottom nav -------------------------------------------
        if (widget.showBottomNav)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _DiwaliBottomNav(
              index: _navIndex,
              cartCount: _store.cartCount,
              bottomInset: bottomInset,
              onTap: _handleNav,
            ),
          ),

        // ---- Cart panel -------------------------------------------
        _buildCartPanel(screen.height, bottomInset),

        // ---- Search overlay ---------------------------------------
        if (_searchOpen)
          Positioned.fill(
            child: _DiwaliSearchOverlay(
              controller: _search,
              onClose: _closeSearch,
              onProductTap: _showProduct,
            ),
          ),
      ],
    );
  }

  Widget _buildCartPanel(double screenHeight, double bottomInset) {
    final height = (screenHeight * 0.76).clamp(360.0, 640.0);
    return Stack(
      children: [
        if (_cartOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeCart,
              child: ColoredBox(
                color: Colors.black.withAlpha(107),
              ),
            ),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutCubic,
          left: 0,
          right: 0,
          bottom: _cartOpen ? 0 : -height - 40,
          height: height,
          child: IgnorePointer(
            ignoring: !_cartOpen,
            child: _DiwaliCartPanel(
              store: _store,
              bottomInset: bottomInset,
              onClose: _closeCart,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// STICKY HEADER
// ---------------------------------------------------------------------------

class _DiwaliStickyHeader extends StatelessWidget {
  const _DiwaliStickyHeader({
    required this.onSearchTap,
    required this.onCartTap,
    required this.cartCount,
    this.onBack,
  });

  final VoidCallback onSearchTap;
  final VoidCallback onCartTap;
  final int cartCount;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final store = DiwaliScope.of(context);
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: const Color(0x22000000),
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, top + 8, 14, 9),
        child: Row(
          children: [
            if (onBack != null)
              GestureDetector(
                onTap: onBack,
                child: const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 19, color: DiwaliColors.wine600),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.location_on_outlined,
                    size: 19, color: DiwaliColors.wine600),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DELIVERING TO',
                    style: DiwaliText.body(
                      8.5,
                      color: DiwaliColors.muted,
                      weight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    store.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DiwaliText.body(12, weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onSearchTap,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: DiwaliColors.cream,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.search_rounded,
                    size: 20, color: DiwaliColors.wine600),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onCartTap,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: DiwaliColors.cream,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_mall_outlined,
                        size: 20, color: DiwaliColors.wine600),
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: DiwaliColors.zomato,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$cartCount',
                          style: DiwaliText.body(
                            9,
                            color: Colors.white,
                            weight: FontWeight.w800,
                          ),
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
}

// ---------------------------------------------------------------------------
// BOTTOM NAV
// ---------------------------------------------------------------------------

class _DiwaliBottomNav extends StatelessWidget {
  const _DiwaliBottomNav({
    required this.index,
    required this.cartCount,
    required this.bottomInset,
    required this.onTap,
  });

  final int index;
  final int cartCount;
  final double bottomInset;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        elevation: 12,
        shadowColor: const Color(0x22000000),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                for (var i = 0; i < 4; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          DiwaliNavGlyph(
                            icon: DiwaliNavIcon.values[i],
                            color: index == i
                                ? DiwaliColors.wine600
                                : DiwaliColors.muted,
                            size: 23,
                            badge: i == 2 ? cartCount : 0,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            const ['Home', 'Categories', 'Cart', 'Profile'][i],
                            style: DiwaliText.body(
                              10,
                              color: index == i
                                  ? DiwaliColors.wine600
                                  : DiwaliColors.muted,
                              weight: index == i
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// CART
// ---------------------------------------------------------------------------

class _DiwaliCartBar extends StatelessWidget {
  const _DiwaliCartBar({required this.store});

  final DiwaliStore store;

  @override
  Widget build(BuildContext context) => Container(
        height: 62,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: DiwaliColors.green,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${store.cartCount} item${store.cartCount == 1 ? '' : 's'}  ·  ${diwaliRupees(store.cartTotal)}',
                  style: DiwaliText.body(
                    13,
                    color: Colors.white,
                    weight: FontWeight.w800,
                  ),
                ),
                Text(
                  'You save ${diwaliRupees(store.cartSavings)}',
                  style: DiwaliText.body(
                    10.5,
                    color: const Color(0xFFC9F5CE),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              'VIEW CART',
              style: DiwaliText.body(
                12,
                color: Colors.white,
                weight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.white),
          ],
        ),
      );
}

class _DiwaliCartPanel extends StatelessWidget {
  const _DiwaliCartPanel({
    required this.store,
    required this.bottomInset,
    required this.onClose,
  });

  final DiwaliStore store;
  final double bottomInset;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final lines = store.cartLines;
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: DiwaliColors.line),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_mall_outlined,
                    size: 20, color: DiwaliColors.wine600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your festive cart',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DiwaliText.serifStyle(19)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  constraints:
                      const BoxConstraints(minWidth: 34, minHeight: 34),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
          ),
          Expanded(
            child: lines.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_bag_outlined,
                            size: 46, color: DiwaliColors.line),
                        const SizedBox(height: 10),
                        Text(
                          'Your cart is waiting for sparkle',
                          style: DiwaliText.body(
                            13,
                            color: DiwaliColors.muted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: lines.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 18, color: DiwaliColors.line),
                    itemBuilder: (context, index) {
                      final line = lines[index];
                      return Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: DiwaliAssetImage(
                              asset: line.product.asset,
                              width: 58,
                              height: 58,
                              cacheWidth: 160,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: DiwaliText.body(12),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  line.product.price,
                                  style: DiwaliText.body(
                                    13,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 106,
                            child: DiwaliAddControl(
                              product: line.product,
                              height: 32,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(18, 14, 18, 18 + bottomInset),
            decoration: const BoxDecoration(
              color: DiwaliColors.cream,
              border: Border(top: BorderSide(color: DiwaliColors.line)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Item total',
                      style: DiwaliText.body(12, color: DiwaliColors.ink2),
                    ),
                    const Spacer(),
                    Text(
                      diwaliRupees(store.cartTotal),
                      style: DiwaliText.body(13, weight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      'Delivery',
                      style: DiwaliText.body(12, color: DiwaliColors.ink2),
                    ),
                    const Spacer(),
                    Text(
                      'FREE',
                      style: DiwaliText.body(
                        12,
                        color: DiwaliColors.green,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18, color: DiwaliColors.line),
                Row(
                  children: [
                    Text(
                      'To pay',
                      style: DiwaliText.body(15, weight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Text(
                      diwaliRupees(store.cartTotal),
                      style: DiwaliText.body(18, weight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: lines.isEmpty
                        ? null
                        : () {
                            onClose();
                            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Order placed — happy Diwali!',
                                  style: DiwaliText.body(
                                    12.5,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: DiwaliColors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DiwaliColors.wine600,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: DiwaliColors.line,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      lines.isEmpty ? 'ADD SOMETHING FESTIVE' : 'PROCEED TO PAY',
                      style: DiwaliText.body(
                        12.5,
                        color: Colors.white,
                        weight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SEARCH
// ---------------------------------------------------------------------------

class _DiwaliSearchOverlay extends StatelessWidget {
  const _DiwaliSearchOverlay({
    required this.controller,
    required this.onClose,
    required this.onProductTap,
  });

  final TextEditingController controller;
  final VoidCallback onClose;
  final ValueChanged<DiwaliProduct> onProductTap;

  @override
  Widget build(BuildContext context) {
    final store = DiwaliScope.of(context);
    final results = store.searchResults();
    final top = MediaQuery.paddingOf(context).top;

    return Material(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(12, top + 8, 12, 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: DiwaliColors.line)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onClose,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: DiwaliColors.wine600),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    onChanged: store.setQuery,
                    style: DiwaliText.body(14),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search diyas, lights, gifts...',
                      hintStyle: DiwaliText.body(
                        13,
                        color: DiwaliColors.muted,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (store.query.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      controller.clear();
                      store.clearQuery();
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.close_rounded,
                          size: 18, color: DiwaliColors.muted),
                    ),
                  ),
                GestureDetector(
                  onTap: () =>
                      store.setVoiceListening(!store.voiceListening),
                  child: AnimatedContainer(
                    duration: DiwaliMotion.quick,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: store.voiceListening
                          ? DiwaliColors.zomato.withAlpha(31)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
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
          if (store.voiceListening)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: DiwaliColors.cream3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.graphic_eq_rounded,
                      size: 17, color: DiwaliColors.wine600),
                  const SizedBox(width: 8),
                  Text(
                    'Listening… try saying “diya” or “fairy lights”',
                    style: DiwaliText.body(12, color: DiwaliColors.wine700),
                  ),
                ],
              ),
            ),
          Expanded(
            child: store.query.isEmpty
                ? _DiwaliSearchSuggestions(
                    onPick: (term) {
                      controller.text = term;
                      store.setQuery(term);
                    },
                  )
                : results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off_rounded,
                                size: 46, color: DiwaliColors.line),
                            const SizedBox(height: 12),
                            Text(
                              'No matches for “${store.query}”',
                              style: DiwaliText.body(
                                13,
                                weight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Try “diya”, “urli”, “lights” or “hamper”',
                              style: DiwaliText.body(
                                11.5,
                                color: DiwaliColors.muted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                            child: Text(
                              '${results.length} RESULT${results.length == 1 ? '' : 'S'}',
                              style: DiwaliText.body(
                                10,
                                color: DiwaliColors.muted,
                                weight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Expanded(
                            child: GridView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 190,
                                mainAxisExtent: 430,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 14,
                              ),
                              itemCount: results.length,
                              itemBuilder: (context, index) =>
                                  LayoutBuilder(
                                builder: (context, constraints) =>
                                    DiwaliProductCard(
                                  product: results[index],
                                  width: constraints.maxWidth,
                                  showDeliveryTime: false,
                                  onTap: () => onProductTap(results[index]),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _DiwaliSearchSuggestions extends StatelessWidget {
  const _DiwaliSearchSuggestions({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          Text(
            'POPULAR THIS DIWALI',
            style: DiwaliText.body(
              10,
              color: DiwaliColors.muted,
              weight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              for (final term in const [
                'diya',
                'urli',
                'lights',
                'hamper',
                'candle',
                'chocolate',
                'rangoli',
                'sweets',
                'towel',
                'rose',
              ])
                GestureDetector(
                  onTap: () => onPick(term),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: DiwaliColors.cream,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: DiwaliColors.line),
                    ),
                    child: Text(
                      term,
                      style: DiwaliText.body(
                        12,
                        color: DiwaliColors.wine600,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
}

// ---------------------------------------------------------------------------
// PRODUCT SHEET
// ---------------------------------------------------------------------------

class _DiwaliProductSheet extends StatelessWidget {
  const _DiwaliProductSheet({required this.product});

  final DiwaliProduct product;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 9),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: DiwaliColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: DiwaliAssetImage(
                      asset: product.asset,
                      width: 96,
                      height: 96,
                      cacheWidth: 260,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: DiwaliText.body(
                            14,
                            weight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              product.price,
                              style: DiwaliText.body(
                                18,
                                weight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              product.mrp,
                              style: DiwaliText.body(
                                12,
                                color: DiwaliColors.muted,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        if (product.offer.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              product.offer,
                              style: DiwaliText.body(
                                11.5,
                                color: DiwaliColors.green,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded,
                      size: 18, color: DiwaliColors.green),
                  const SizedBox(width: 6),
                  Text(
                    'Delivery in ${product.time}',
                    style: DiwaliText.body(12, color: DiwaliColors.ink2),
                  ),
                  const Spacer(),
                  Text(
                    product.qty,
                    style: DiwaliText.body(12, color: DiwaliColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: DiwaliAddControl(product: product, height: 46),
            ),
          ],
        ),
      );
}

/// Convenience export for hosts that want to link straight to the route.
const String diwaliRoute = kDiwaliRoute;
