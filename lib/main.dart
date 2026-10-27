import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/delivery_eta_provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/edit_mode_provider.dart';
import '../providers/order_provider.dart';
import '../providers/wishlist_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/analytics.dart';
import '../services/deep_link_service.dart';
import '../services/error_reporter.dart';
import '../services/push_service.dart';
import '../services/system_bars_service.dart';
import '../screens/splash_screen.dart';
import '../widgets/night_sky.dart';
import '../widgets/app_lifecycle_recovery.dart';
import '../utils/app_fonts.dart';
import '../theme/app_theme.dart';

/// The system's three-key strip: Flutter asks the window for edge-to-edge,
/// and a see-through bar makes the phone paint white glyphs over whatever
/// is behind it. [SystemBars] keeps the strip white with dark glyphs on it,
/// and is re-asked now and then because Flutter re-asserts its own setup as
/// screens change.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Before anything else: catch what would otherwise die silently on a
  // customer's phone, and show a readable card instead of the red screen.
  ErrorReporter.start();
  // What the shop learns from: a small set of named events. Guests are
  // not recorded at all — see supabase/app_events.sql.
  Analytics.start();
  // The fonts ship with the app; have the first frame's faces in hand.
  await AppFonts.prepare();
  NightSky.load();
  // A tapped push must be able to navigate before any screen exists.
  PushService.navigatorKey = GlobalKey<NavigatorState>();
  // Does nothing until android/app/google-services.json joins the app.
  PushService.start();
  // The system's three navigation keys get their own solid strip in the
  // app's background colour — screen content never shows through behind
  // them, and the keys never sit on a see-through patch.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: SystemUiOverlay.values);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
    // Android forces a grey scrim on near-white nav bars unless this is
    // explicitly off — the keys then sit on plain white, app-wide.
    systemNavigationBarContrastEnforced: false,
  ));
  runApp(const MyApp());
  // Waits for the first frame, so PushService.navigatorKey has a context to
  // read the AuthProvider from by the time a reset-password link arrives.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await DeepLinkService.start();
    } catch (error, stack) {
      // A link that blows up here would otherwise die silently on the phone.
      ErrorReporter.report(error, stack, source: 'deep_link_start');
    }
    // The provider tree is now ready; process any queued deep links.
    DeepLinkService.markAppReady();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => EditModeProvider()),
        // Delivery time follows the customer's address and the nearest store.
        ChangeNotifierProxyProvider2<AuthProvider, ProductProvider,
            DeliveryEtaProvider>(
          create: (_) => DeliveryEtaProvider(),
          update: (_, auth, products, eta) {
            if (eta == null) return DeliveryEtaProvider();
            return eta
              ..setInputs(
                lat: auth.deliveryLat,
                lng: auth.deliveryLng,
                sellersWithProducts: {
                  for (final p in products.allProducts) p.sellerId,
                },
              );
          },
        ),
      ],
      child: MaterialApp(
        navigatorKey: PushService.navigatorKey,
        title: 'Infinity - Quick Store',
        // The strings live in lib/l10n/*.arb, and a screen reads them with
        // `AppLocalizations.of(context)`. Installing the delegates once, here,
        // is what makes that call work everywhere below.
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
        // Held to light on purpose. AppTokens.dark exists, but the screens
        // still name their colours directly, so following the system into
        // dark would give half a screen the dark palette and half the old
        // one. This flips over once the screens read context.tokens.
        themeMode: ThemeMode.light,
        theme: buildAppTheme(),
        // Global type size: user asked every screen to read slightly
        // smaller, so the whole app renders at 85% of its previous size
        // regardless of where a font size was declared.
        builder: (context, child) {
          // The builder can be invoked with a null child before the first
          // route exists; an empty box keeps AppLifecycleRecovery mounted.
          if (child == null) return const SizedBox.shrink();
          SystemBars.apply();
          final scaled = const TextScaler.linear(0.85);
          assert(() {
            // One-shot confirmation in debug builds that the down-scale is
            // installed in the MediaQuery chain.
            debugPrint('[type-scale] 100px -> ${scaled.scale(100)}');
            return true;
          }());
          // The three navigation keys' strip: Flutter draws content under
          // it (edge-to-edge), so the system colours never reach the eye.
          // One opaque white band, exactly the strip's height, laid over
          // that inset — while the keyboard is down the bar is gone and
          // there is nothing to paint.
          final strip = MediaQuery.of(context).viewInsets.bottom > 0
              ? 0.0
              : MediaQuery.of(context).viewPadding.bottom;
          return AppLifecycleRecovery(
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              // The three navigation keys: the strip behind them is white
              // and their glyphs stay dark. This merges into every screen
              // below, so no page can leave them white on white.
              value: const SystemUiOverlayStyle(
                systemNavigationBarColor: Colors.white,
                systemNavigationBarIconBrightness: Brightness.dark,
                systemNavigationBarDividerColor: Colors.transparent,
                systemNavigationBarContrastEnforced: false,
              ),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: scaled),
                child: Stack(
                  children: [
                    Positioned.fill(child: child),
                    if (strip > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: strip,
                        child: ColoredBox(color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}
