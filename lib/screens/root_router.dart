import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/order_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/push_service.dart';
import '../utils/constants.dart';
import 'auth/login_screen.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';
import 'seller/seller_dashboard_screen.dart';
import 'delivery/delivery_dashboard_screen.dart';
import 'admin/admin_dashboard_screen.dart';

/// Decides which root screen to show: the login flow when signed out, or
/// the screen matching the signed-in user's role.
class RootRouter extends StatefulWidget {
  const RootRouter({super.key});

  @override
  State<RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<RootRouter> {
  String? _syncedUserId;

  // Whether the first-run walkthrough has been completed on this device;
  // null until read from storage. Only consulted while signed out, so
  // people who are already logged in never see it.
  bool? _onboardingSeen;

  @override
  void initState() {
    super.initState();
    OnboardingScreen.hasSeen().then((seen) {
      if (mounted) setState(() => _onboardingSeen = seen);
    });
    // A push that lands while the app is open refreshes the inbox.
    PushService.onPush = () {
      if (mounted) context.read<NotificationProvider>().loadNotifications();
    };
  }

  /// Auth-flow rules (kept here and on OnboardingScreen):
  /// 1. "Get Started" ends on Login, never on Register.
  /// 2. "Skip" enters as a guest.
  /// 3. Register opens only from Login, for an email/phone with no account
  ///    or via its "Sign Up" action.
  void _onOnboardingFinished(bool createAccount) {
    setState(() => _onboardingSeen = true);
    // The router shows LoginScreen by itself once onboarding is seen.
  }

  // "Skip" on the walkthrough: straight to the store as a guest.
  void _onOnboardingSkipped() {
    setState(() => _onboardingSeen = true);
    context.read<AuthProvider>().continueAsGuest();
  }

  /// Runs once when the signed-in user signs out: drops their cart,
  /// wishlist, orders and so on from memory so a guest (or the next person
  /// to log in) never sees them.
  void _forgetSignedOutUserData() {
    _syncedUserId = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CartProvider>().resetLocal();
      context.read<WishlistProvider>().resetLocal();
      context.read<OrderProvider>().resetLocal();
      context.read<NotificationProvider>().resetLocal();
      context.read<WalletProvider>().resetLocal();
    });
  }

  void _syncUserData(AuthProvider auth) {
    if (!auth.isLoggedIn) {
      _syncedUserId = null;
      return;
    }
    if (_syncedUserId == auth.userId) return;
    _syncedUserId = auth.userId;
    context.read<CartProvider>().loadCart();
    context.read<WishlistProvider>().loadWishlist();
    context.read<OrderProvider>()
      ..loadOrders()
      ..watchAllStatuses();
    context.read<NotificationProvider>()
      ..loadNotifications()
      ..watchLive();
    context.read<WalletProvider>().loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final screen = _screen(context);
    // Onboarding → store, login → store, sign-out → login: every swap of the
    // root screen cross-fades. Without it the new screen replaced the old
    // one in a single frame, and that frame is also the one where Home is
    // built for the first time, so Skip felt like a freeze and then a jolt.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(screen.runtimeType),
        child: screen,
      ),
    );
  }

  Widget _screen(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.initialized) {
      return const Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isLoggedIn) {
      if (_syncedUserId != null) _forgetSignedOutUserData();

      // Skipped the login: browse the store; checkout asks for a login.
      if (auth.isGuest) return const MainShell();

      if (_onboardingSeen == null) {
        return const Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          body: Center(child: CircularProgressIndicator()),
        );
      }
      if (_onboardingSeen == false) {
        return OnboardingScreen(
          onFinished: _onOnboardingFinished,
          onSkip: _onOnboardingSkipped,
        );
      }
      return const LoginScreen();
    }

    _syncUserData(auth);

    switch (auth.role) {
      case UserRole.seller:
        return const SellerDashboardScreen();
      case UserRole.delivery:
        return const DeliveryDashboardScreen();
      case UserRole.admin:
        return const AdminDashboardScreen();
      case UserRole.customer:
        return const MainShell();
    }
  }
}
