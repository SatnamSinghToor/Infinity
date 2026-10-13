import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:duggu/models/address.dart';
import 'package:duggu/models/product.dart';
import 'package:duggu/providers/auth_provider.dart';
import 'package:duggu/providers/cart_provider.dart';
import 'package:duggu/providers/delivery_eta_provider.dart';
import 'package:duggu/providers/order_provider.dart';
import 'package:duggu/providers/wallet_provider.dart';
import 'package:duggu/providers/product_provider.dart';
import 'package:duggu/providers/wishlist_provider.dart';
import 'package:duggu/screens/cart_screen.dart';
import 'package:duggu/screens/checkout_screen.dart';
import 'package:duggu/services/supabase_service.dart';

/// A signed-in shopper, as far as the checkout can tell.
class _SignedIn extends AuthProvider {
  final String _where;
  final String _who;
  final String _tel;
  final List<Address> _saved;

  _SignedIn({
    String address = '',
    String name = '',
    String phone = '',
    List<Address> saved = const [],
  })  : _where = address,
        _who = name,
        _tel = phone,
        _saved = saved;

  @override
  bool get isLoggedIn => true;
  @override
  String get address => _where;
  @override
  String get userName => _who;
  @override
  String get phone => _tel;
  @override
  List<Address> get addresses => _saved;
}

const _lamp = Product(
  id: 'p1',
  name: 'Brass Lantern',
  description: 'd',
  price: 499,
  originalPrice: 599,
  category: 'Decor',
  rating: 4,
  unit: '1 pc',
  stock: 10,
);

Future<void> _open(WidgetTester tester, AuthProvider auth, Widget home) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.7;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider(create: (_) => CartProvider()..addToCart(_lamp)),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryEtaProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pump();
}

/// Lets whatever the screen started (animations, the cart's sync) finish.
Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 5));
  // The sign-in client keeps a refresh timer of its own; a test body has to
  // end with nothing ticking, and a tearDown runs too late for that check.
  SupabaseService.client.auth.stopAutoRefresh();
}

const _home = Address(
  id: 'a1',
  label: 'Home',
  fullName: 'Satnam',
  phone: '7419042583',
  fullAddress: 'Lalauda, Tohana, Fatehabad, Haryana',
  isDefault: true,
);

void main() {
  tearDown(() => SupabaseService.client.auth.stopAutoRefresh());

  testWidgets('the cart ends in Blinkit\'s bar: where it goes, and Proceed',
      (tester) async {
    await _open(
      tester,
      _SignedIn(
        address: 'Lalauda, Tohana, Fatehabad, Haryana',
        name: 'Satnam',
        phone: '7419042583',
      ),
      const CartScreen(),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Delivering to Home'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
    expect(find.text('Proceed To Pay'), findsOneWidget);
    // Tip and instructions are settled on the cart itself.
    await tester.scrollUntilVisible(
      find.text('Tip your delivery partner'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Tip your delivery partner'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('no address known: the button asks for one', (tester) async {
    await _open(
      tester,
      _SignedIn(name: 'Satnam', phone: '7419042583'),
      const CartScreen(),
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Delivering to'), findsNothing);
    expect(find.text('Select address to proceed'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('Proceed opens only the payment step', (tester) async {
    await _open(
      tester,
      _SignedIn(
        address: 'Lalauda, Tohana, Fatehabad, Haryana',
        name: 'Satnam',
        phone: '7419042583',
        saved: const [_home],
      ),
      const CartScreen(),
    );
    await tester.tap(find.text('Proceed To Pay'));
    await tester.pumpAndSettle();
    expect(find.text('Select payment method'), findsOneWidget);
    expect(find.text('Pay now'), findsOneWidget);
    // Nothing to fill in on the way to paying.
    expect(find.byType(TextField), findsNothing);
    await _close(tester);
  });

  testWidgets('cash on delivery places the order instead of paying',
      (tester) async {
    await _open(
      tester,
      _SignedIn(),
      const CheckoutScreen(address: _home, tip: 20),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Satnam · 7419042583'), findsOneWidget);
    await tester.tap(find.textContaining('Cash'));
    await tester.pump();
    expect(find.text('PLACE ORDER'), findsOneWidget);
    await _close(tester);
  });
}
