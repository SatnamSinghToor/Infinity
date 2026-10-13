import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/analytics.dart';
import '../services/supabase_service.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  bool _isLoading = false;

  /// Set when the last load from the backend failed (offline, server error).
  /// An empty list after a failure is not the same as an empty list.
  bool _loadFailed = false;

  /// Set when a background write to the server failed. The cart on this
  /// phone is still right, but the server's copy is behind — and the server
  /// prices an order from its own copy — so the cart screen says so and
  /// offers to resend everything ([retrySync]) instead of letting checkout
  /// quietly charge for an older cart.
  bool _syncFailed = false;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  bool get loadFailed => _loadFailed;
  bool get syncFailed => _syncFailed;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  String? get _userId => SupabaseService.client.auth.currentUser?.id;

  // The user whose server cart has been loaded into [_items]. While null,
  // anything in the cart was added as a guest (before logging in).
  String? _loadedFor;

  /// Forgets the in-memory cart on sign-out, without touching the server, so
  /// the next person (or a guest) doesn't inherit it.
  void resetLocal() {
    _items.clear();
    _loadedFor = null;
    _syncFailed = false;
    notifyListeners();
  }

  bool isInCart(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  int getQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    return index >= 0 ? _items[index].quantity : 0;
  }

  /// Loads the signed-in user's cart from Supabase, replacing local state.
  /// Call this once the user is known (e.g. after login).
  Future<void> loadCart() async {
    final uid = _userId;
    if (uid == null) return;

    // Items added while browsing as a guest are kept and merged into the
    // account's cart below, instead of being wiped by the server copy.
    final guestItems =
        _loadedFor == null ? List<CartItem>.of(_items) : <CartItem>[];

    _isLoading = true;
    _loadFailed = false;
    // A fresh read replaces whatever the server held, so any earlier sync
    // failure no longer applies — the guest merges below will re-raise the
    // flag if their writes fail.
    _syncFailed = false;
    notifyListeners();

    try {
      final rows = await SupabaseService.client
          .from('cart_items')
          .select(
            'id, qty, quantity, variant_id, '
            'products(id, name, description, price, discount_price, image_url, unit, rating, is_veg, stock, seller_id, categories(name)), '
            'product_variants(name, price)',
          )
          .eq('customer_id', uid);

      _items.clear();
      for (final row in rows) {
        final productRow = row['products'] as Map<String, dynamic>?;
        if (productRow == null) continue;
        final qty = (row['qty'] as num?)?.toInt() ??
            (row['quantity'] as num?)?.toInt() ??
            1;
        final variantRow = row['product_variants'] as Map<String, dynamic>?;
        _items.add(
          CartItem(
            id: row['id'] as String,
            product: Product.fromSupabaseRow(productRow),
            quantity: qty,
            variantId: row['variant_id'] as String?,
            variantName: variantRow?['name'] as String?,
            variantPrice: (variantRow?['price'] as num?)?.toDouble(),
          ),
        );
      }
      _loadedFor = uid;

      for (final guest in guestItems) {
        final index =
            _items.indexWhere((i) => i.product.id == guest.product.id);
        final CartItem merged;
        if (index >= 0) {
          _items[index].quantity += guest.quantity;
          merged = _items[index];
        } else {
          _items.add(guest);
          merged = guest;
        }
        await _upsertQuantity(merged, merged.quantity);
      }
    } catch (e) {
      debugPrint('Cart load failed: $e');
      _loadFailed = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  Map<String, dynamic> _serverRow(String uid, CartItem item, int quantity) => {
        'customer_id': uid,
        'user_id': uid,
        'product_id': item.product.id,
        'quantity': quantity,
        'qty': quantity,
        'variant': item.variantName ?? '',
        'variant_id': item.variantId,
      };

  Future<void> _upsertQuantity(CartItem item, int quantity) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await SupabaseService.client.from('cart_items').upsert(
          _serverRow(uid, item, quantity),
          onConflict: 'customer_id,product_id');
    } catch (e) {
      // The local cart already shows the change; what failed is its copy
      // on the server. Raise the flag the cart screen shows, so the user
      // can resend instead of paying for an older cart later.
      debugPrint('Cart sync failed: $e');
      if (!_syncFailed) {
        _syncFailed = true;
        notifyListeners();
      }
    }
  }

  /// Makes the server's copy of the cart match this one, and waits for it.
  ///
  /// The server prices an order from its own copy of the cart (not from
  /// anything the app sends), and the changes made while shopping are sent
  /// without waiting, so this is called just before paying or ordering.
  /// Returns false if the server could not be brought up to date.
  Future<bool> syncToServer() async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      final client = SupabaseService.client;
      for (final item in _items) {
        await client.from('cart_items').upsert(
            _serverRow(uid, item, item.quantity),
            onConflict: 'customer_id,product_id');
      }
      // Anything the server still holds that is no longer in this cart goes.
      final keep = [for (final item in _items) item.product.id];
      if (keep.isEmpty) {
        await client.from('cart_items').delete().eq('customer_id', uid);
      } else {
        await client
            .from('cart_items')
            .delete()
            .eq('customer_id', uid)
            .not('product_id', 'in', keep);
      }
      if (_syncFailed) {
        _syncFailed = false;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Cart sync to server failed: $e');
      if (!_syncFailed) {
        _syncFailed = true;
        notifyListeners();
      }
      return false;
    }
  }

  /// Resends the whole cart after a background sync failed — the "Try
  /// again" behind the cart screen's sync notice.
  Future<bool> retrySync() async => syncToServer();

  Future<void> _deleteRow(String productId) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await SupabaseService.client
          .from('cart_items')
          .delete()
          .eq('customer_id', uid)
          .eq('product_id', productId);
    } catch (e) {
      // The row is gone locally; only the server's copy remains. Same
      // flag as [_upsertQuantity] — [syncToServer] clears it by deleting
      // anything the server holds that this cart no longer has.
      debugPrint('Cart delete failed: $e');
      if (!_syncFailed) {
        _syncFailed = true;
        notifyListeners();
      }
    }
  }

  /// Adds [product] to the cart. When [variantId] is given, the cart line
  /// for this product carries that variant's name/price — since cart_items
  /// only has a unique constraint on (customer_id, product_id), choosing a
  /// different variant for a product already in the cart replaces the
  /// variant on that single line rather than adding a second one.
  /// Whether one more of [product] fits in its stock. The server would
  /// refuse the order at checkout anyway; saying so at the + button is
  /// kinder than a failed payment.
  bool canAddMore(Product product) => getQuantity(product.id) < product.stock;

  /// Returns false (and changes nothing) when the cart already holds all
  /// the stock there is.
  bool addToCart(
    Product product, {
    String? variantId,
    String? variantName,
    double? variantPrice,
  }) {
    if (!canAddMore(product)) return false;
    final index = _items.indexWhere((item) => item.product.id == product.id);
    int newQuantity;
    CartItem item;
    if (index >= 0) {
      _items[index].quantity++;
      item = CartItem(
        id: _items[index].id,
        product: product,
        quantity: _items[index].quantity,
        variantId: variantId ?? _items[index].variantId,
        variantName: variantName ?? _items[index].variantName,
        variantPrice: variantPrice ?? _items[index].variantPrice,
      );
      _items[index] = item;
      newQuantity = item.quantity;
    } else {
      item = CartItem(
        product: product,
        variantId: variantId,
        variantName: variantName,
        variantPrice: variantPrice,
      );
      _items.add(item);
      newQuantity = 1;
    }
    notifyListeners();
    _upsertQuantity(item, newQuantity);
    // Which products actually go into carts — the shop's stocking signal.
    Analytics.log('add_to_cart', {
      'product_id': product.id,
      'quantity': newQuantity,
    });
    return true;
  }

  /// The variant of [productId] in the cart, if the line carries one.
  String? variantIdOf(String productId) {
    for (final item in _items) {
      if (item.product.id == productId) return item.variantId;
    }
    return null;
  }

  /// Puts this size of [product] in the cart. A product has one line in the
  /// cart (the server keys it on the product), so choosing a different size
  /// switches that line to it, starting again at one, rather than adding a
  /// second line. Returns false when the product is out of stock.
  bool chooseVariant(
    Product product, {
    required String variantId,
    required String variantName,
    required double variantPrice,
  }) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index < 0) {
      return addToCart(
        product,
        variantId: variantId,
        variantName: variantName,
        variantPrice: variantPrice,
      );
    }
    if (_items[index].variantId == variantId) {
      return increaseQuantity(product.id);
    }
    if (product.stock <= 0) return false;
    final item = CartItem(
      id: _items[index].id,
      product: product,
      variantId: variantId,
      variantName: variantName,
      variantPrice: variantPrice,
    );
    _items[index] = item;
    notifyListeners();
    // Changed in place, not deleted and added again: a delete that landed
    // after the new row would empty the line on the server.
    _upsertQuantity(item, item.quantity);
    return true;
  }

  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
    _deleteRow(productId);
  }

  /// Returns false (and changes nothing) at the product's stock limit.
  bool increaseQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index < 0) return false;
    if (_items[index].quantity >= _items[index].product.stock) return false;
    _items[index].quantity++;
    notifyListeners();
    _upsertQuantity(_items[index], _items[index].quantity);
    return true;
  }

  void decreaseQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index < 0) return;
    if (_items[index].quantity > 1) {
      _items[index].quantity--;
      notifyListeners();
      _upsertQuantity(_items[index], _items[index].quantity);
    } else {
      final product = _items[index].product;
      _items.removeAt(index);
      notifyListeners();
      _deleteRow(product.id);
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
    final uid = _userId;
    if (uid == null) return;
    SupabaseService.client
        .from('cart_items')
        .delete()
        .eq('customer_id', uid)
        .then((_) {}, onError: (e) => debugPrint('Cart clear failed: $e'));
  }
}
