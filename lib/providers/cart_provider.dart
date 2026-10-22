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
  @protected
  bool syncFailedInternal = false;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  bool get loadFailed => _loadFailed;
  bool get syncFailed => syncFailedInternal;

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
    syncFailedInternal = false;
    notifyListeners();
  }

  bool isInCart(String productId, {String? variantId}) {
    final key = variantId != null ? '$productId:$variantId' : productId;
    return _items.any((item) => item.cartKey == key);
  }

  int getQuantity(String productId, {String? variantId}) {
    final key = variantId != null ? '$productId:$variantId' : productId;
    final index = _items.indexWhere((item) => item.cartKey == key);
    return index >= 0 ? _items[index].quantity : 0;
  }

  /// Whether one more of [product] (with [variantId]) fits in its stock.
  /// For multi-variant products, checks the variant's stock.
  bool canAddMore(Product product, {String? variantId}) {
    final currentQty = getQuantity(product.id, variantId: variantId);
    if (variantId != null) {
      final variant = product.getVariant(variantId);
      if (variant != null) return currentQty < variant.stock;
    }
    return currentQty < product.stock;
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
    syncFailedInternal = false;
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
        // Parse defensively: one malformed row must not abort the whole
        // load and wipe the cart view.
        try {
          final productRow = row['products'] as Map<String, dynamic>?;
          if (productRow == null) continue;
          final id = row['id'] as String?;
          if (id == null) continue;
          final qty = (row['qty'] as num?)?.toInt() ??
              (row['quantity'] as num?)?.toInt() ??
              1;
          final variantRow = row['product_variants'] as Map<String, dynamic>?;
          _items.add(
            CartItem(
              id: id,
              product: Product.fromSupabaseRow(productRow),
              quantity: qty,
              variantId: row['variant_id'] as String?,
              variantName: variantRow?['name'] as String?,
              variantPrice: (variantRow?['price'] as num?)?.toDouble(),
            ),
          );
        } catch (e) {
          debugPrint('Skipping malformed cart row: $e');
        }
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
        await upsertQuantity(merged, merged.quantity);
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

  @protected
  Future<void> upsertQuantity(CartItem item, int quantity) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      // Use composite key for upsert conflict resolution
      await SupabaseService.client.from('cart_items').upsert(
          _serverRow(uid, item, quantity),
          onConflict: 'customer_id,product_id,variant_id');
    } catch (e) {
      // The local cart already shows the change; what failed is its copy
      // on the server. Raise the flag the cart screen shows, so the user
      // can resend instead of paying for an older cart later.
      debugPrint('Cart sync failed: $e');
      if (!syncFailedInternal) {
        syncFailedInternal = true;
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
            onConflict: 'customer_id,product_id,variant_id');
      }
      // Anything the server still holds that is no longer in this cart goes.
      // Reconcile per composite key: a product may legitimately keep one
      // variant while another variant of the same product was removed, so a
      // product_id-only delete would wrongly keep stale variant rows (which
      // the server would then price at checkout).
      final keep = [for (final item in _items) item.cartKey];
      final serverRows = await client
          .from('cart_items')
          .select('id, product_id, variant_id')
          .eq('customer_id', uid);
      final serverId = <String>[];
      for (final row in serverRows) {
        final rowKey = row['variant_id'] == null
            ? (row['product_id'] as String?)
            : '${row['product_id']}:${row['variant_id']}';
        if (!keep.contains(rowKey) && row['id'] is String) {
          serverId.add(row['id'] as String);
        }
      }
      if (serverId.isNotEmpty) {
        await client
            .from('cart_items')
            .delete()
            .filter('id', 'in', serverId);
      }
      if (syncFailedInternal) {
        syncFailedInternal = false;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Cart sync to server failed: $e');
      if (!syncFailedInternal) {
        syncFailedInternal = true;
        notifyListeners();
      }
      return false;
    }
  }

  /// Resends the whole cart after a background sync failed — the "Try
  /// again" behind the cart screen's sync notice.
  Future<bool> retrySync() async => syncToServer();

  Future<void> _deleteRow(String productId, {String? variantId}) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      var query = SupabaseService.client
          .from('cart_items')
          .delete()
          .eq('customer_id', uid)
          .eq('product_id', productId);
      if (variantId != null) {
        query = query.eq('variant_id', variantId);
      }
      await query;
    } catch (e) {
      debugPrint('Cart delete failed: $e');
      if (!syncFailedInternal) {
        syncFailedInternal = true;
        notifyListeners();
      }
    }
  }

  /// Adds [product] to the cart with optional [variantId], [variantName], [variantPrice].
  /// Each variant is stored as a separate cart line with key "productId:variantId".
  /// Returns false (and changes nothing) when the cart already holds all the stock.
  bool addToCart(
    Product product, {
    String? variantId,
    String? variantName,
    double? variantPrice,
  }) {
    if (!canAddMore(product, variantId: variantId)) return false;

    final cartKey = variantId != null ? '${product.id}:$variantId' : product.id;
    final index = _items.indexWhere((item) => item.cartKey == cartKey);

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
    debugPrint(
        '[cart] add ${item.cartKey} -> $newQuantity (notify done, card should rebuild)');
    upsertQuantity(item, newQuantity);
    Analytics.log('add_to_cart', {
      'product_id': product.id,
      'variant_id': variantId,
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

  /// Changes the variant of [product] in the cart to [variantId].
  /// If the variant is already selected, just increases quantity.
  /// Returns false when out of stock.
  bool chooseVariant(
    Product product, {
    required String variantId,
    required String variantName,
    required double variantPrice,
  }) {
    final cartKey = '${product.id}:$variantId';
    final index = _items.indexWhere((item) => item.cartKey == cartKey);
    if (index >= 0) {
      return increaseQuantity(product.id, variantId: variantId);
    }
    final productIndex = _items.indexWhere((item) => item.product.id == product.id);
    if (productIndex < 0) {
      return addToCart(
        product,
        variantId: variantId,
        variantName: variantName,
        variantPrice: variantPrice,
      );
    }
    if (product.stock <= 0) return false;
    final item = CartItem(
      id: _items[productIndex].id,
      product: product,
      variantId: variantId,
      variantName: variantName,
      variantPrice: variantPrice,
    );
    _items[productIndex] = item;
    notifyListeners();
    upsertQuantity(item, item.quantity);
    return true;
  }

  void removeFromCart(String productId, {String? variantId}) {
    final key = variantId != null ? '$productId:$variantId' : productId;
    _items.removeWhere((item) => item.cartKey == key);
    notifyListeners();
    _deleteRow(productId, variantId: variantId);
  }

  /// Returns false (and changes nothing) at the stock limit.
  /// For variant lines the variant's own stock is the limit.
  bool increaseQuantity(String productId, {String? variantId}) {
    final key = variantId != null ? '$productId:$variantId' : productId;
    final index = _items.indexWhere((item) => item.cartKey == key);
    if (index < 0) return false;
    if (!canAddMore(_items[index].product, variantId: variantId)) return false;
    _items[index].quantity++;
    debugPrint('[cart] inc ${_items[index].cartKey} -> ${_items[index].quantity} (notify next)');
    notifyListeners();
    upsertQuantity(_items[index], _items[index].quantity);
    return true;
  }

  void decreaseQuantity(String productId, {String? variantId}) {
    final key = variantId != null ? '$productId:$variantId' : productId;
    final index = _items.indexWhere((item) => item.cartKey == key);
    if (index < 0) return;
    if (_items[index].quantity > 1) {
      _items[index].quantity--;
      notifyListeners();
      upsertQuantity(_items[index], _items[index].quantity);
    } else {
      final product = _items[index].product;
      _items.removeAt(index);
      notifyListeners();
      _deleteRow(product.id, variantId: variantId);
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
