import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase/supabase.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/supabase_service.dart';

/// Restores the app's backend session and visible data after a long pause.
///
/// Mobile operating systems suspend timers and network sockets while an app is
/// backgrounded. Supabase can reconnect on its own, but a resumed screen also
/// needs a fresh session and fresh data instead of leaving taps aimed at a
/// stale connection.
class AppLifecycleRecovery extends StatefulWidget {
  final Widget child;

  const AppLifecycleRecovery({super.key, required this.child});

  @override
  State<AppLifecycleRecovery> createState() => _AppLifecycleRecoveryState();
}

class _AppLifecycleRecoveryState extends State<AppLifecycleRecovery>
    with WidgetsBindingObserver {
  static const _refreshAfter = Duration(seconds: 15);
  static const _networkTimeout = Duration(seconds: 12);

  DateTime? _backgroundedAt;
  bool _recovering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _backgroundedAt ??= DateTime.now();
      // Timers do not run reliably in the background; the refresher starts
      // over from a clean slate on resume.
      SupabaseService.client.auth.stopAutoRefresh();
      return;
    }

    if (state != AppLifecycleState.resumed) return;
    final pausedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (pausedAt == null) return;
    if (DateTime.now().difference(pausedAt) < _refreshAfter) {
      // A quick glance away: nothing to reload, but the refresher that was
      // stopped on the way out has to run again.
      SupabaseService.client.auth.startAutoRefresh();
      return;
    }
    unawaited(_recoverAfterPause());
  }

  Future<void> _recoverAfterPause() async {
    if (_recovering) return;
    _recovering = true;
    final client = SupabaseService.client;

    try {
      // A mobile OS may suspend the SDK's refresh timer along with the app.
      // Refresh only when expired or close to expiry; never rotate a fresh token.
      final session = client.auth.currentSession;
      final expiresAt = session?.expiresAt;
      final expiresSoon = expiresAt != null &&
          DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000)
                  .difference(DateTime.now()) <=
              const Duration(minutes: 2);
      if (session != null && (session.isExpired || expiresSoon)) {
        try {
          await client.auth.refreshSession().timeout(_networkTimeout);
        } on AuthRetryableFetchException catch (error) {
          // Offline: keep the session; the refresher retries it below.
          debugPrint('Resume session refresh deferred: $error');
        } on AuthException catch (error) {
          // The saved sign-in can no longer be renewed (revoked, or signed
          // out elsewhere). Back to Login, rather than carrying on as a
          // signed-in user whose every request fails.
          debugPrint('Resume session lost: $error');
          if (mounted) await context.read<AuthProvider>().signOut();
          return;
        } catch (error) {
          debugPrint('Resume session refresh deferred: $error');
        }
      }
      // Only after the refresh above, so the two never race with the same
      // refresh token.
      client.auth.startAutoRefresh();

      if (!mounted) return;
      // Fire refreshes in parallel and keep the interface responsive even if
      // one backend request is slow. Providers expose their normal load errors
      // so the screens can offer their usual retry affordance.
      unawaited(context.read<ProductProvider>().reload());

      if (context.read<AuthProvider>().isLoggedIn) {
        unawaited(context.read<CartProvider>().loadCart());
        unawaited(context.read<WishlistProvider>().loadWishlist());
        final orders = context.read<OrderProvider>();
        unawaited(orders.loadOrders());
        // Re-opened, not just "kept": a watch whose socket died while the
        // phone slept never says so, and would otherwise stay dead. A new
        // watch also reopens the realtime socket if Android closed it.
        orders.rewatchAllStatuses();
        final notifications = context.read<NotificationProvider>();
        unawaited(notifications.loadNotifications());
        notifications.rewatchLive();
        unawaited(context.read<WalletProvider>().loadTransactions());
      }
    } catch (error, stackTrace) {
      // Recovery is best-effort: an offline phone should still leave the app
      // usable, with normal retry controls, rather than throwing on resume.
      debugPrint('App resume recovery failed: $error\n$stackTrace');
    } finally {
      _recovering = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
