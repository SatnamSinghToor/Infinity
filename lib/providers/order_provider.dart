import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart' show PostgrestException;

import '../models/cart_item.dart';
import '../models/order.dart';
import '../services/supabase_service.dart';

class OrderProvider extends ChangeNotifier {
  final List<Order> _orders = [];
  bool _isLoading = false;

  /// Set when the last load from the backend failed (offline, server error).
  /// An empty order list after a failure is not the same as no orders.
  bool _loadFailed = false;

  static const freeDeliveryThreshold = 299;
  static const baseDeliveryFee = 29;

  List<Order> get orders => List.unmodifiable(_orders.reversed);

  /// Every product the customer has ordered, newest order first, each once
  /// — what the home page's "Buy again" shelf is built from. Cancelled
  /// orders don't count: nobody actually received those.
  List<String> get recentProductIds {
    final sorted = [..._orders]
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final seen = <String>{};
    return [
      for (final order in sorted)
        if (order.status != 'cancelled')
          for (final item in order.items)
            if (seen.add(item.product.id)) item.product.id,
    ];
  }

  bool get isLoading => _isLoading;
  bool get loadFailed => _loadFailed;

  String? get _userId => SupabaseService.client.auth.currentUser?.id;

  /// Forgets the in-memory orders on sign-out.
  void resetLocal() {
    _listWatch?.cancel();
    _listWatch = null;
    _orders.clear();
    notifyListeners();
  }

  /// Total delivery fee across a cart, charged per seller (a cart can span
  /// multiple sellers, and each seller's slice ships — and is charged
  /// delivery for — on its own).
  static double deliveryFeeFor(List<CartItem> cartItems) {
    final bySeller = <String, double>{};
    for (final item in cartItems) {
      bySeller[item.product.sellerId] =
          (bySeller[item.product.sellerId] ?? 0) + item.totalPrice;
    }
    double fee = 0;
    for (final subtotal in bySeller.values) {
      if (subtotal > 0 && subtotal < freeDeliveryThreshold) {
        fee += baseDeliveryFee;
      }
    }
    return fee;
  }

  /// Loads the signed-in customer's orders (with their items) from Supabase.
  Future<void> loadOrders() async {
    final uid = _userId;
    if (uid == null) return;

    _isLoading = true;
    _loadFailed = false;
    notifyListeners();

    try {
      final rows = await SupabaseService.client
          .from('orders')
          .select(Order.selectColumns)
          .eq('customer_id', uid)
          .order('created_at', ascending: false);

      _orders.clear();
      for (final row in rows) {
        _orders.add(Order.fromSupabaseRow(row));
      }
    } catch (e) {
      debugPrint('Order load failed: $e');
      _loadFailed = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Set when the last [findOrder] could not ask the backend at all. An order
  /// that could not be fetched is not an order that does not exist, and a
  /// screen that blurs the two tells a paying customer their order is gone.
  bool _lookupFailed = false;
  bool get lookupFailed => _lookupFailed;

  /// One order, for the screens that can be opened without the list: a
  /// notification tap lands straight on an order, and the list may not have
  /// been loaded yet — or at all, if the app has just started.
  ///
  /// Answers from the loaded list first, so the usual path costs nothing, and
  /// only then asks the backend. Returns null when this account has no such
  /// order, and also when the question could not be asked — [lookupFailed]
  /// says which of the two happened.
  Future<Order?> findOrder(String orderId) async {
    final uid = _userId;
    if (uid == null) return null;

    for (final order in _orders) {
      if (order.id == orderId) return order;
    }

    _lookupFailed = false;
    try {
      final row = await SupabaseService.client
          .from('orders')
          .select(Order.selectColumns)
          .eq('id', orderId)
          .eq('customer_id', uid)
          .maybeSingle();
      if (row == null) return null;

      final order = Order.fromSupabaseRow(row);
      if (!_orders.any((existing) => existing.id == order.id)) {
        _orders.add(order);
        notifyListeners();
      }
      return order;
    } catch (e) {
      debugPrint('Order lookup failed: $e');
      _lookupFailed = true;
      return null;
    }
  }

  /// Why the last [placeOrder] failed, in words that can be shown to the
  /// shopper ("Not enough stock left of …"); null when it did not fail.
  String? lastError;

  /// Places the signed-in customer's cart as orders (one per seller) through
  /// the `place_order` database function, then reloads the order list.
  ///
  /// The server works out every amount itself, from its own copy of the
  /// cart: prices, delivery fee, coupon, wallet and stock. Nothing here is a
  /// price or a total; [couponCode] and [walletUsed] are only what the
  /// shopper asked for. Call `CartProvider.syncToServer` first so that copy
  /// is current.
  ///
  /// Returns a combined [Order] for the confirmation screen, or null (with
  /// [lastError] set) if nothing could be placed.
  Future<Order?> placeOrder({
    required List<CartItem> cartItems,
    required String address,
    required String phone,
    required String name,
    String paymentMethod = 'cod',
    String? addressId,
    String? paymentId,
    String couponCode = '',
    String deliveryNote = '',
    int walletUsed = 0,
    int tip = 0,
  }) async {
    lastError = null;
    final uid = _userId;
    if (uid == null || cartItems.isEmpty) return null;

    final List<Map<String, dynamic>> placed;
    try {
      final result = await SupabaseService.client.rpc(
        'place_order',
        params: {
          'p_address': address,
          'p_address_id': addressId,
          'p_coupon_code': couponCode,
          'p_wallet_amount': walletUsed,
          'p_payment_method': paymentMethod,
          'p_payment_id': paymentId,
          'p_delivery_note': deliveryNote,
          'p_tip': tip,
        },
      );
      placed = List<Map<String, dynamic>>.from(result as List);
    } on PostgrestException catch (e) {
      debugPrint('Place order failed: ${e.message}');
      lastError = e.message;
      return null;
    } catch (e) {
      debugPrint('Place order failed: $e');
      return null;
    }

    if (placed.isEmpty) return null;

    await loadOrders();

    final ids = [for (final row in placed) row['placed_order_id'] as String];
    final totalAmount = placed.fold<double>(
      0,
      (sum, row) => sum + ((row['placed_total'] as num?)?.toDouble() ?? 0),
    );

    return Order(
      id: ids.join(', '),
      items: cartItems,
      totalAmount: totalAmount,
      address: address,
      phone: phone,
      name: name,
      dateTime: DateTime.now(),
      status: 'pending',
    );
  }

  /// Moves an order's status, locally first so the screen reacts at once.
  ///
  /// Returns whether the backend accepted it. When it did not, the old status
  /// is put back and false is returned rather than leaving the app claiming
  /// something the shop never heard — an order that is cancelled on screen
  /// but not in the database is a support ticket.
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return false;

    final before = _orders[index];
    _orders[index] = _withStatus(before, newStatus);
    notifyListeners();

    try {
      await SupabaseService.client
          .from('orders')
          .update({'status': newStatus}).eq('id', orderId);
      return true;
    } catch (e) {
      debugPrint('Order status update failed: $e');
      final at = _orders.indexWhere((o) => o.id == orderId);
      if (at != -1) {
        _orders[at] = before;
        notifyListeners();
      }
      return false;
    }
  }

  static Order _withStatus(Order order, String status) {
    return Order(
      id: order.id,
      items: order.items,
      totalAmount: order.totalAmount,
      address: order.address,
      phone: order.phone,
      name: order.name,
      dateTime: order.dateTime,
      status: status,
      deliveryId: order.deliveryId,
      deliveryFee: order.deliveryFee,
      walletUsed: order.walletUsed,
      tip: order.tip,
    );
  }

  // --- live order status ---------------------------------------------------

  StreamSubscription<List<Map<String, dynamic>>>? _listWatch;
  StreamSubscription<List<Map<String, dynamic>>>? _statusWatch;
  String? _statusWatchOrderId;

  /// Keeps every one of the signed-in customer's orders' status current —
  /// not just the single order [watchOrderStatus] tracks — for as long as
  /// the app is signed in. A seller confirming, or a rider marking one
  /// delivered, used to only reach here on the next [loadOrders] call; this
  /// moves it into the "My Orders" list itself, live, the same way a chat
  /// app moves a delivered tick without anyone pulling to refresh.
  /// Starts the live status watch over again, for when the app comes back
  /// from the background with a socket that may have died silently.
  void rewatchAllStatuses() {
    _listWatch?.cancel();
    _listWatch = null;
    watchAllStatuses();
  }

  void watchAllStatuses() {
    final uid = _userId;
    if (uid == null || _listWatch != null) return;
    _listWatch = SupabaseService.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('customer_id', uid)
        .listen(
          (rows) {
            var changed = false;
            for (final row in rows) {
              final id = row['id'] as String?;
              final status = row['status'] as String?;
              if (id == null || status == null) continue;
              final index = _orders.indexWhere((o) => o.id == id);
              if (index == -1 || _orders[index].status == status) continue;
              _orders[index] = _withStatus(_orders[index], status);
              changed = true;
            }
            if (changed) notifyListeners();
          },
          // Best-effort: a dropped realtime connection just means the list
          // falls back to needing a manual refresh, not that it breaks.
          onError: (Object e) => debugPrint('Order list watch failed: $e'),
        );
  }

  /// Keeps [orderId]'s status current for as long as a tracking or detail
  /// screen has it open: a seller marking an order "preparing" or a rider
  /// marking it "out for delivery" used to only reach the shopper's screen
  /// on their next pull-to-refresh — this reflects it the moment it happens.
  ///
  /// Only the status moves live; the order's items and total stay as
  /// originally loaded, since Supabase's realtime stream reads only the
  /// `orders` table itself, not the joined order items. Call with the same
  /// [orderId] again is a no-op; call with a different id moves the
  /// subscription; call with null stops it (leaving a screen behind).
  void watchOrderStatus(String? orderId) {
    if (_statusWatchOrderId == orderId) return;
    _statusWatch?.cancel();
    _statusWatch = null;
    _statusWatchOrderId = orderId;
    if (orderId == null) return;
    _statusWatch = SupabaseService.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .listen(
          (rows) {
            if (rows.isEmpty) return;
            final status = rows.first['status'] as String?;
            if (status == null) return;
            final index = _orders.indexWhere((o) => o.id == orderId);
            if (index == -1 || _orders[index].status == status) return;
            _orders[index] = _withStatus(_orders[index], status);
            notifyListeners();
          },
          // Best-effort: a dropped realtime connection just means the screen
          // falls back to needing a manual refresh, not that it breaks.
          onError: (Object e) => debugPrint('Order status watch failed: $e'),
        );
  }

  @override
  void dispose() {
    _statusWatch?.cancel();
    _listWatch?.cancel();
    super.dispose();
  }
}
