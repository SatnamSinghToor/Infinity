import 'package:flutter/material.dart';

import '../diwali/diwali_config.dart';
import '../diwali/diwali_home.dart';
import '../utils/constants.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/listing_common.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// The customer app's frame: the four main screens (Home, Categories, Cart,
/// Profile) share one bottom bar, so it is always there — with the current
/// screen lit up — on exactly those screens. Orders sit one tap deeper,
/// under "My Orders" in Profile, which keeps the bar to four roomy tabs.
///
/// Everything else (a product, search, a store, checkout, sign-in…) opens
/// over this frame and covers the bar, as those are steps inside a task
/// rather than places to jump between.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// Which of the four screens is showing.
  static final ValueNotifier<int> tab = ValueNotifier<int>(0);

  static const home = 0;
  static const categories = 1;
  static const cart = 2;
  static const profile = 3;

  /// Jumps to one of the main screens from anywhere, closing whatever is open
  /// over the frame on the way.
  static void goTo(BuildContext context, int index) {
    tab.value = index;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  // A screen is built the first time it is opened, then kept alive so it
  // comes back exactly as it was left (scroll position, search, …).
  late final Set<int> _opened;

  /// The tab that is arriving fades in, so a jump between the four reads as
  /// a change of page instead of a flash. Nothing is thrown away: the other
  /// three stay alive underneath, exactly as they were.
  late final AnimationController _arriving = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 190),
    value: 1,
  );

  @override
  void initState() {
    super.initState();
    // A fresh frame (after sign-in, sign-out or switching role) starts on Home.
    MainShell.tab.value = MainShell.home;
    _opened = {MainShell.home};
    MainShell.tab.addListener(_fadeInTab);
  }

  void _fadeInTab() {
    if (mounted) _arriving.forward(from: 0.55);
  }

  @override
  void dispose() {
    MainShell.tab.removeListener(_fadeInTab);
    _arriving.dispose();
    super.dispose();
  }

  static const _builders = <WidgetBuilder>[
    _home,
    _categories,
    _cart,
    _profile,
  ];

  /// Flip `kDiwaliAsHome` in lib/diwali/diwali_config.dart to make the
  /// festive storefront *be* the Home tab instead of a chip inside it.
  static Widget _home(BuildContext _) => kDiwaliAsHome
      ? DiwaliPage(onNavigate: (i) => MainShell.tab.value = i)
      : const HomeScreen();
  static Widget _categories(BuildContext _) => const CategoriesScreen();
  static Widget _cart(BuildContext _) => const CartScreen();
  static Widget _profile(BuildContext _) => const ProfileScreen();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: MainShell.tab,
      builder: (context, index, _) {
        _opened.add(index);
        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          // The bar floats over the screens; each one pads its bottom by the
          // bar's height so nothing is hidden behind it.
          extendBody: true,
          body: FadeTransition(
            opacity: _arriving,
            child: IndexedStack(
              index: index,
              children: [
                for (var i = 0; i < _builders.length; i++)
                  _opened.contains(i)
                      ? _builders[i](context)
                      : const SizedBox.shrink(),
              ],
            ),
          ),
          // On Home and Categories a cart pill floats just above the bar.
          // No side or bottom padding: the pill sits flat on the content
          // above the bar, lifted only by its own shadow. On the Cart tab
          // the bar itself is dropped: the checkout column owns the bottom.
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The standalone Diwali page draws its own cart pill and bar.
              if (!kDiwaliAsHome &&
                  (index == MainShell.home || index == MainShell.categories))
                const ViewCartPill(),
              if (index != MainShell.cart &&
                  !(kDiwaliAsHome && index == MainShell.home))
                BottomNavWidget(
                  currentIndex: index,
                  onTap: (i) => MainShell.tab.value = i,
                ),
            ],
          ),
        );
      },
    );
  }
}
