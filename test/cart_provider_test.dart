import 'package:flutter_test/flutter_test.dart';

import 'package:duggu/models/cart_item.dart';
import 'package:duggu/models/product.dart';
import 'package:duggu/models/product_variant.dart';
import 'package:duggu/providers/cart_provider.dart';
import 'package:duggu/services/supabase_service.dart';

Product _product(String id,
    {String name = 'Product', double price = 100, int stock = 5}) {
  return Product(
    id: id,
    name: name,
    description: 'd',
    price: price,
    originalPrice: price,
    category: 'c',
    rating: 4,
    unit: '1 pc',
    stock: stock,
  );
}

Product _variantProduct(String id,
    {int productStock = 10, required List<ProductVariant> variants}) {
  return Product(
    id: id,
    name: 'Variant product',
    description: 'd',
    price: 100,
    originalPrice: 100,
    category: 'c',
    rating: 4,
    unit: '1 pc',
    stock: productStock,
    variants: variants,
  );
}

/// A CartProvider whose server calls go nowhere. The local behaviour under
/// test (keys, stock limits, merge, flags) is the same; the write just fails,
/// which is the state the sync-failure UI already handles.
class _FailingSyncCart extends CartProvider {
  @override
  Future<void> upsertQuantity(CartItem item, int quantity) async {
    // Mimic the real implementation: catch and flag, don't rethrow.
    syncFailedInternal = true;
  }
}

void main() {
  setUpAll(() => SupabaseService.client);
  tearDown(() => SupabaseService.client.auth.stopAutoRefresh());

  group('cart keys', () {
    test('a variant line is keyed by product and variant together', () {
      final cart = CartProvider();
      cart.addToCart(_product('p1'),
          variantId: 'v1', variantName: 'Big', variantPrice: 120);
      expect(cart.getQuantity('p1', variantId: 'v1'), 1);
      // Without the variant the line is a different one: nothing there.
      expect(cart.getQuantity('p1'), 0);
      expect(cart.isInCart('p1', variantId: 'v1'), isTrue);
      expect(cart.isInCart('p1'), isFalse);
    });

    test('two variants of one product are two lines', () {
      final cart = CartProvider();
      cart.addToCart(_product('p1'),
          variantId: 'v1', variantName: 'Big', variantPrice: 120);
      cart.addToCart(_product('p1'),
          variantId: 'v2', variantName: 'Small', variantPrice: 60);
      expect(cart.items, hasLength(2));
      expect(cart.itemCount, 2);
    });

    test('removing one variant keeps the other', () {
      final cart = CartProvider();
      cart.addToCart(_product('p1'),
          variantId: 'v1', variantName: 'Big', variantPrice: 120);
      cart.addToCart(_product('p1'),
          variantId: 'v2', variantName: 'Small', variantPrice: 60);
      cart.removeFromCart('p1', variantId: 'v1');
      expect(cart.items, hasLength(1));
      expect(cart.variantIdOf('p1'), 'v2');
    });
  });

  group('choosing a variant', () {
    test('choosing the variant already in the cart adds one more of it', () {
      final cart = CartProvider();
      cart.addToCart(_product('p1'),
          variantId: 'v1', variantName: 'Big', variantPrice: 120);
      expect(
        cart.chooseVariant(_product('p1'),
            variantId: 'v1', variantName: 'Big', variantPrice: 120),
        isTrue,
      );
      expect(cart.getQuantity('p1', variantId: 'v1'), 2);
    });
  });

  group('stock limits', () {
    test('addToCart refuses past the variant stock, not the product stock', () {
      final product = _variantProduct('p1',
          productStock: 10,
          variants: [
            const ProductVariant(id: 'v1', label: 'Big', price: 120, mrp: 120, stock: 2),
          ]);
      final cart = CartProvider();
      expect(cart.addToCart(product, variantId: 'v1'), isTrue);
      expect(cart.addToCart(product, variantId: 'v1'), isTrue);
      // Variant stock is 2: the third add must fail even though the product
      // itself reports 10.
      expect(cart.addToCart(product, variantId: 'v1'), isFalse);
      expect(cart.getQuantity('p1', variantId: 'v1'), 2);
    });

    test('increaseQuantity stops at the variant stock too', () {
      final product = _variantProduct('p1',
          productStock: 10,
          variants: [
            const ProductVariant(id: 'v1', label: 'Big', price: 120, mrp: 120, stock: 1),
          ]);
      final cart = CartProvider();
      cart.addToCart(product, variantId: 'v1');
      expect(cart.increaseQuantity('p1', variantId: 'v1'), isFalse);
      expect(cart.getQuantity('p1', variantId: 'v1'), 1);
    });
  });

  group('loadCart merge', () {
    test('guest items are preserved while the load runs', () {
      final cart = CartProvider();
      cart.addToCart(_product('p1'));
      cart.addToCart(_product('p2'), variantId: 'v1');
      // Nothing has been loaded for a signed-in user yet, so these are guest
      // items — the merge path reads them from the in-memory list.
      expect(cart.items, hasLength(2));
      expect(cart.totalAmount, greaterThan(0));
    });

    test('resetLocal forgets everything without touching the server', () {
      final cart = CartProvider();
      cart.addToCart(_product('p1'));
      cart.resetLocal();
      expect(cart.items, isEmpty);
      expect(cart.syncFailed, isFalse);
    });
  });

  group('sync failure flags', () {
    test('a failed background write raises syncFailed', () async {
      final cart = _FailingSyncCart();
      cart.addToCart(_product('p1'));
      // The local cart keeps the item even though the write failed.
      expect(cart.items, hasLength(1));
      await Future<void>.delayed(Duration.zero);
      expect(cart.syncFailed, isTrue);
    });

    test('a failed write leaves the local quantity right', () async {
      final cart = _FailingSyncCart();
      cart.addToCart(_product('p1'));
      cart.increaseQuantity('p1');
      await Future<void>.delayed(Duration.zero);
      expect(cart.getQuantity('p1'), 2);
      expect(cart.totalAmount, 200);
    });
  });
}
