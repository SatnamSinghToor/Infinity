import 'cart_item.dart';
import 'product.dart';

class Order {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final String address;
  final String phone;
  final String name;
  final DateTime dateTime;
  final String status;
  final String? deliveryId;

  /// The delivery fee the server charged on this order. Delivery is charged
  /// per seller, so an order's fee is not always the cart's fee.
  final double deliveryFee;

  /// Wallet money the server put towards this order, already taken off
  /// [totalAmount].
  final double walletUsed;

  /// What the customer tipped the delivery partner — included in
  /// [totalAmount], never the seller's.
  final double tip;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.address,
    required this.phone,
    required this.name,
    required this.dateTime,
    this.status = 'pending',
    this.deliveryId,
    this.deliveryFee = 0,
    this.walletUsed = 0,
    this.tip = 0,
  });

  /// Every column [fromSupabaseRow] reads, in one place: the orders list and
  /// the order detail screen ask the same question, so they can never show
  /// different versions of the same order.
  static const selectColumns =
      'id, status, total_amount, delivery_address, created_at, delivery_id, '
      'delivery_fee, wallet_used, tip, order_items(quantity, price_at_purchase, '
      'products(id, name, description, price, discount_price, image_url, '
      'unit, rating, is_veg, stock, seller_id, categories(name)))';

  /// Builds an [Order] from an `orders` row selected with [selectColumns].
  ///
  /// Numbers that are missing read as zero instead of throwing: an order that
  /// has already been paid for is worth showing as much of as the server will
  /// tell us.
  factory Order.fromSupabaseRow(Map<String, dynamic> row) {
    final itemRows = (row['order_items'] as List?) ?? const [];
    final items = <CartItem>[];
    for (final raw in itemRows) {
      if (raw is! Map) continue;
      final productRow = raw['products'] as Map<String, dynamic>?;
      if (productRow == null) continue;
      items.add(
        CartItem(
          product: Product.fromSupabaseRow(productRow),
          quantity: (raw['quantity'] as num?)?.toInt() ?? 1,
        ),
      );
    }

    return Order(
      id: row['id'] as String,
      items: items,
      totalAmount: (row['total_amount'] as num?)?.toDouble() ?? 0,
      address: row['delivery_address'] as String? ?? '',
      // The name and phone belong to the delivery address, not to the order.
      phone: '',
      name: '',
      dateTime: DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
      status: row['status'] as String? ?? 'pending',
      deliveryId: row['delivery_id'] as String?,
      deliveryFee: (row['delivery_fee'] as num?)?.toDouble() ?? 0,
      walletUsed: (row['wallet_used'] as num?)?.toDouble() ?? 0,
      tip: (row['tip'] as num?)?.toDouble() ?? 0,
    );
  }

  String get formattedDate {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// A human-friendly version of [status], e.g. `ready_for_pickup` ->
  /// `Ready For Pickup`, for display in the UI. Comparisons against
  /// [status] itself should keep using the raw lowercase value, since
  /// that's what the `orders.status` check constraint in Supabase allows.
  String get statusLabel {
    return status
        .split('_')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  /// What the items cost, before delivery and before any wallet money: the
  /// lines the server itself priced.
  double get itemsSubtotal =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Where this order has got to on the four-step journey the detail screen
  /// draws: 0 placed, 1 preparing, 2 on the way, 3 delivered. `-1` for a
  /// cancelled order, which never reaches the end of it. The tracking screen
  /// maps statuses the same way, so the two screens cannot disagree.
  static int stepIndexFor(String status) {
    switch (status.toLowerCase()) {
      case 'cancelled':
        return -1;
      case 'confirmed':
        return 0;
      case 'preparing':
      case 'ready_for_pickup':
        return 1;
      case 'out_for_delivery':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  /// See [stepIndexFor].
  int get stepIndex => stepIndexFor(status);
}
