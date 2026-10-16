import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:duggu/models/product.dart';
import 'package:duggu/models/product_variant.dart';
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

const _oatsTwoSizes = Product(
  id: 'oats',
  name: 'Quaker Oats',
  description: 'd',
  price: 176.4,
  originalPrice: 199.5,
  category: 'Breakfast',
  rating: 4,
  unit: '900 gm',
  stock: 20,
  variants: [
    ProductVariant(
      id: 'v900',
      label: '900 GM',
      price: 176.4,
      mrp: 199.5,
      stock: 20,
    ),
    ProductVariant(
      id: 'v400',
      label: '400 GM',
      price: 88.2,
      mrp: 99.0,
      stock: 20,
    ),
  ],
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

  testWidgets('a product in two sizes says so under ADD', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProductProvider>(create: (_) => _TwoSizes()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => WishlistProvider()),
          ChangeNotifierProvider(create: (_) => EditModeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 163,
                height: ProductCardMetrics.cellHeight(163, dense: false),
                child: const ProductCard(product: _oatsTwoSizes),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('ADD'), findsOneWidget);
    expect(find.text('2 options'), findsOneWidget);
    SupabaseService.client.auth.stopAutoRefresh();
  });
}
