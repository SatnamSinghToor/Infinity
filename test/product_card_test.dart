import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:duggu/models/product.dart';
import 'package:duggu/providers/auth_provider.dart';
import 'package:duggu/providers/cart_provider.dart';
import 'package:duggu/providers/edit_mode_provider.dart';
import 'package:duggu/providers/wishlist_provider.dart';
import 'package:duggu/services/supabase_service.dart';
import 'package:duggu/widgets/product_card.dart';

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

Widget _gridCell(Widget card) {
  const w = 163.0;
  return SizedBox(
    width: w,
    height: ProductCardMetrics.cellHeight(w, dense: false),
    child: card,
  );
}

Widget _shelfCell(Widget card) {
  const w = 103.0;
  return SizedBox(
    width: w,
    height: ProductCardMetrics.cellHeight(w, dense: true),
    child: card,
  );
}

void main() {
  tearDown(() => SupabaseService.client.auth.stopAutoRefresh());

  testWidgets('a two-across card lays out in its cell', (tester) async {
    await tester.pumpWidget(
      _host(_gridCell(const ProductCard(product: _chips, onTap: _noop))),
    );
    expect(tester.takeException(), isNull);
    expect(find.text(_chips.name), findsOneWidget);
    expect(find.text('ADD'), findsOneWidget);
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

  testWidgets('a two-across card still fits once the stepper shows',
      (tester) async {
    await tester.pumpWidget(
      _host(_gridCell(const ProductCard(product: _chips, onTap: _noop))),
    );
    await tester.tap(find.byKey(ProductCard.addKey));
    await tester.pump();

    expect(find.byKey(ProductCard.stepperKey), findsOneWidget);
    expect(find.text('−'), findsOneWidget);
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
    await tester.tap(find.byKey(ProductCard.addKey));
    await tester.pump();

    expect(find.byKey(ProductCard.stepperKey), findsOneWidget);
    expect(find.text('−'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a sold-out card lays out and offers no ADD', (tester) async {
    await tester.pumpWidget(
      _host(_gridCell(const ProductCard(product: _soldOut, onTap: _noop))),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Sold out'), findsOneWidget);
    expect(find.byKey(ProductCard.addKey), findsNothing);
  });

  testWidgets('tapping ADD turns it into the orange stepper at once',
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
    await tester.tap(find.byKey(ProductCard.addKey));
    await tester.pump();
    expect(cart.getQuantity(_chips.id), 1);
    expect(find.byKey(ProductCard.addKey), findsNothing);
    expect(find.byKey(ProductCard.stepperKey), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });
}

void _noop() {}
