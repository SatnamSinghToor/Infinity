import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:duggu/models/product.dart';
import 'package:duggu/providers/auth_provider.dart';
import 'package:duggu/providers/cart_provider.dart';
import 'package:duggu/providers/edit_mode_provider.dart';
import 'package:duggu/providers/product_provider.dart';
import 'package:duggu/providers/wishlist_provider.dart';
import 'package:duggu/services/supabase_service.dart';
import 'package:duggu/widgets/product_card.dart';

const _oats = Product(
  id: 'oats',
  name: 'Quaker Oats',
  description: 'd',
  price: 176.4,
  originalPrice: 199.5,
  category: 'Breakfast',
  rating: 4,
  unit: '900 gm',
  stock: 20,
);

/// A catalogue that says the oats come in two sizes.
class _TwoSizes extends ProductProvider {
  _TwoSizes() : super(autoload: false);

  @override
  int variantCount(String productId) => productId == 'oats' ? 2 : 0;
}

void main() {
  tearDown(() => SupabaseService.client.auth.stopAutoRefresh());

  group('choosing a size', () {
    test('the first choice adds a line for that size', () {
      final cart = CartProvider();
      cart.chooseVariant(_oats,
          variantId: 'v900', variantName: '900 GM', variantPrice: 176.4);
      expect(cart.getQuantity('oats'), 1);
      expect(cart.variantIdOf('oats'), 'v900');
      expect(cart.totalAmount, 176.4);
    });

    test('the same size again is one more of it', () {
      final cart = CartProvider();
      cart.chooseVariant(_oats,
          variantId: 'v900', variantName: '900 GM', variantPrice: 176.4);
      cart.chooseVariant(_oats,
          variantId: 'v900', variantName: '900 GM', variantPrice: 176.4);
      expect(cart.getQuantity('oats'), 2);
    });

    test('another size switches the one line to it, from one', () {
      final cart = CartProvider();
      cart.chooseVariant(_oats,
          variantId: 'v900', variantName: '900 GM', variantPrice: 176.4);
      cart.increaseQuantity('oats');
      cart.chooseVariant(_oats,
          variantId: 'v400', variantName: '400 GM', variantPrice: 88.2);
      expect(cart.items, hasLength(1));
      expect(cart.variantIdOf('oats'), 'v400');
      expect(cart.getQuantity('oats'), 1);
      expect(cart.totalAmount, 88.2);
    });
  });

  testWidgets('a product in two sizes says so under its +', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProductProvider>(create: (_) => _TwoSizes()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => WishlistProvider()),
          ChangeNotifierProvider(create: (_) => EditModeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 163,
                height: 296,
                child: ProductCard(product: _oats),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('2 Opt'), findsOneWidget);
    SupabaseService.client.auth.stopAutoRefresh();
  });
}
