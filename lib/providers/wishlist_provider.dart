import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/supabase_service.dart';

class WishlistProvider extends ChangeNotifier {
  final List<Product> _wishlisted = [];
  bool _isLoading = false;

  /// Set when the last load from the backend failed (offline, server error).
  /// An empty list after a failure is not the same as an empty list.
  bool _loadFailed = false;

  List<Product> get wishlistedProducts => List.unmodifiable(_wishlisted);
  bool get isLoading => _isLoading;
  bool get loadFailed => _loadFailed;

  String? get _userId => SupabaseService.client.auth.currentUser?.id;

  bool isWishlisted(String productId) {
    return _wishlisted.any((p) => p.id == productId);
  }

  int get count => _wishlisted.length;

  /// Loads the signed-in user's wishlist from Supabase, replacing local state.
  Future<void> loadWishlist() async {
    final uid = _userId;
    if (uid == null) return;

    _isLoading = true;
    _loadFailed = false;
    notifyListeners();

    try {
      // `wishlist_items` has no foreign key to `products`, so the products
      // can't be embedded in one query: read the saved ids, then the products.
      final saved = await SupabaseService.client
          .from('wishlist_items')
          .select('product_id, created_at')
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      final ids = [
        for (final row in saved)
          if (row['product_id'] is String) row['product_id'] as String,
      ];

      final products = <String, Product>{};
      if (ids.isNotEmpty) {
        final rows = await SupabaseService.client
            .from('products')
            .select(
              'id, name, description, price, discount_price, image_url, '
              'image_urls, unit, rating, is_veg, stock, seller_id, brand, '
              'categories(name)',
            )
            .inFilter('id', ids)
            .eq('is_active', true);
        for (final row in rows) {
          final product = Product.fromSupabaseRow(row);
          products[product.id] = product;
        }
      }

      // Newest saved first; items that are no longer on sale are skipped.
      _wishlisted
        ..clear()
        ..addAll([
          for (final id in ids)
            if (products[id] != null) products[id]!,
        ]);
    } catch (e) {
      debugPrint('Wishlist load failed: $e');
      _loadFailed = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  void toggle(Product product) {
    if (isWishlisted(product.id)) {
      remove(product.id);
    } else {
      add(product);
    }
  }

  void add(Product product) {
    if (_wishlisted.any((p) => p.id == product.id)) return;
    _wishlisted.add(product);
    notifyListeners();

    final uid = _userId;
    if (uid == null) return;
    SupabaseService.client.from('wishlist_items').upsert({
      'user_id': uid,
      'product_id': product.id,
    }, onConflict: 'user_id,product_id').then(
      (_) {},
      onError: (e) => debugPrint('Wishlist add failed: $e'),
    );
  }

  void remove(String productId) {
    _wishlisted.removeWhere((p) => p.id == productId);
    notifyListeners();

    final uid = _userId;
    if (uid == null) return;
    SupabaseService.client
        .from('wishlist_items')
        .delete()
        .eq('user_id', uid)
        .eq('product_id', productId)
        .then((_) {}, onError: (e) => debugPrint('Wishlist remove failed: $e'));
  }

  /// Forgets the in-memory wishlist on sign-out, without touching the server.
  void resetLocal() {
    _wishlisted.clear();
    notifyListeners();
  }

  void clear() {
    _wishlisted.clear();
    notifyListeners();

    final uid = _userId;
    if (uid == null) return;
    SupabaseService.client
        .from('wishlist_items')
        .delete()
        .eq('user_id', uid)
        .then((_) {}, onError: (e) => debugPrint('Wishlist clear failed: $e'));
  }
}
