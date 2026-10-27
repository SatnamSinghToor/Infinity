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

const _ratedThreeAndHalf = Product(
  id: 'r1',
  name: 'Real Rating',
  description: 'd',
  price: 50,
  originalPrice: 60,
  category: 'c',
  rating: 3.5,
  unit: '1 pc',
  stock: 5,
);

const _unrated = Product(
  id: 'r2',
  name: 'No Rating',
  description: 'd',
  price: 50,
  originalPrice: 60,
  category: 'c',
  rating: 0,
  unit: '1 pc',
  stock: 5,
);

Widget _host(Product product) => MultiProvider(
      providers: [
        ChangeNotifierProvider<ProductProvider>(create: (_) => ProductProvider(autoload: false)),
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
              child: ProductCard(product: product),
            ),
          ),
        ),
      ),
    );

void main() {
  tearDown(() => SupabaseService.client.auth.stopAutoRefresh());

  testWidgets('stars fill only as far as the real rating', (tester) async {
    await tester.pumpWidget(_host(_ratedThreeAndHalf));
    expect(tester.takeException(), isNull);
    expect(find.text('3.5'), findsOneWidget);
    // No made-up review count anywhere on the card.
    expect(find.text('12,345'), findsNothing);
  });

  testWidgets('a product with no rating shows no stars at all', (tester) async {
    await tester.pumpWidget(_host(_unrated));
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
  });
}
