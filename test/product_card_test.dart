import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import 'package:duggu/models/product.dart';
import 'package:duggu/providers/auth_provider.dart';
import 'package:duggu/providers/cart_provider.dart';
import 'package:duggu/providers/edit_mode_provider.dart';
import 'package:duggu/providers/wishlist_provider.dart';
import 'package:duggu/services/supabase_service.dart';
import 'package:duggu/widgets/cart_action.dart';
import 'package:duggu/widgets/product_card.dart';

/// The longest name, the biggest price and every badge the shops put on a
/// shelf, so the tightest line in the card is the one under test.
const _chips = Product(
  id: 'p1',
  name: "Lay's American Style Cream & Onion Flavour Potato Chips",
  description: 'Crispy potato chips with a cream and onion seasoning.',
  price: 1299,
  originalPrice: 1599,
  category: 'Snacks',
  rating: 4.3,
  unit: '52 g',
  stock: 40,
);

const _soldOut = Product(
  id: 'p2',
  name: 'Sprite Lime Flavoured Soft Drink',
  description: 'Chilled soft drink.',
  price: 40,
  originalPrice: 40,
  category: 'Cold Drinks',
  rating: 0,
  unit: '750 ml',
  stock: 0,
);

Widget _host(Widget card) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => EditModeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        home: Scaffold(body: Center(child: card)),
      ),
    );

/// Two across, in the cell the home, search, wishlist and listing screens
/// give a card: 163 wide at an aspect ratio of 0.55.
Widget _gridCell(Widget card) => SizedBox(width: 163, height: 296, child: card);

/// Three across on a home shelf: about 103 wide and cellW + 130 tall.
Widget _shelfCell(Widget card) =>
    SizedBox(width: 103, height: 233, child: card);

void main() {
  // Adding to the cart asks Supabase who is signed in, which creates the auth
  // client. It refreshes its session on a timer; stop it so the test ends
  // with nothing pending.
  tearDown(() => SupabaseService.client.auth.stopAutoRefresh());

  testWidgets('a two-across card lays out in its cell', (tester) async {
    await tester.pumpWidget(
      _host(_gridCell(const ProductCard(product: _chips, onTap: _noop))),
    );
    expect(tester.takeException(), isNull);
    expect(find.text(_chips.name), findsOneWidget);
  });

  testWidgets('a three-across shelf card lays out in its cell', (tester) async {
    await tester.pumpWidget(
      _host(
        _shelfCell(
          const ProductCard(product: _chips, dense: true, onTap: _noop),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text(_chips.name), findsOneWidget);
  });

  // Adding to the cart swaps the bag button for the − quantity + stepper,
  // which is the widest the card's action ever gets. The cell must still fit.
  testWidgets('a two-across card still fits once the stepper shows',
      (tester) async {
    await tester.pumpWidget(
      _host(_gridCell(const ProductCard(product: _chips, onTap: _noop))),
    );
    await tester.tap(find.byKey(CartAction.addKey));
    await tester.pump();

    expect(find.byIcon(Iconsax.minus_copy), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a three-across shelf card still fits once the stepper shows',
      (tester) async {
    await tester.pumpWidget(
      _host(
        _shelfCell(
          const ProductCard(product: _chips, dense: true, onTap: _noop),
        ),
      ),
    );
    await tester.tap(find.byKey(CartAction.addKey));
    await tester.pump();

    expect(find.byIcon(Iconsax.minus_copy), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a sold-out card lays out and offers no ADD', (tester) async {
    await tester.pumpWidget(
      _host(_gridCell(const ProductCard(product: _soldOut, onTap: _noop))),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Sold out'), findsOneWidget);
  });
  testWidgets('tapping the bag turns it into the stepper at once',
      (tester) async {
    final cart = CartProvider();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: cart),
          ChangeNotifierProvider(create: (_) => WishlistProvider()),
          ChangeNotifierProvider(create: (_) => EditModeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child:
                  _gridCell(const ProductCard(product: _chips, onTap: _noop)),
            ),
          ),
        ),
      ),
    );
    final before = tester.getRect(find.byType(CartAction));
    await tester.tap(find.byKey(CartAction.addKey));
    // One frame, no settling: the stepper must already be the thing shown,
    // with no bag left over under it for the next tap to miss.
    await tester.pump();
    expect(cart.getQuantity(_chips.id), 1);
    expect(find.byKey(CartAction.addKey), findsNothing);
    // Same room before and after, so the name and price beside the button
    // keep their size instead of shrinking to make space for the stepper.
    expect(tester.getRect(find.byType(CartAction)), before);
    expect(find.text('1'), findsOneWidget);
    await tester.pumpAndSettle();

    // Turned like a number wheel: pushed left the bigger numbers roll in,
    // a notch at a time; pushed right the smaller ones do.
    final wheel = find.text('1');
    final gesture = await tester.startGesture(tester.getCenter(wheel));
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(-5, 0));
      await tester.pump();
    }
    expect(cart.getQuantity(_chips.id), 5);
    // Mid-turn the numbers are on the wheel itself, the quantity in the
    // middle and its neighbours either side.
    expect(find.text('5'), findsWidgets);
    expect(find.text('6'), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(5, 0));
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(cart.getQuantity(_chips.id), 4);
  });
}

void _noop() {}
