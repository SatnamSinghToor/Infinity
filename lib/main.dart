import 'package:flutter/material.dart';
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
import '../screens/splash_screen.dart';
import '../widgets/night_sky.dart';
import '../widgets/app_lifecycle_recovery.dart';
import '../utils/app_fonts.dart';
import '../theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Before anything else: catch what would otherwise die silently on a
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
        title: 'Duggu - Quick Store',
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
        // Very large system text would break layouts that have fixed heights,
        // so it is held to 130% (still bigger than the default).
        builder: (context, child) {
          // The builder can be invoked with a null child before the first
          // route exists; an empty box keeps AppLifecycleRecovery mounted.
          if (child == null) return const SizedBox.shrink();
          final media = MediaQuery.of(context);
          return AppLifecycleRecovery(
            child: MediaQuery(
              data: media.copyWith(
                textScaler: media.textScaler.clamp(
                  minScaleFactor: 0.9,
                  maxScaleFactor: 1.3,
                ),
              ),
              child: child,
            ),
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}
