import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:duggu/models/order.dart';

/// The order detail screen is the screen a customer opens when something has
/// gone wrong — "where is my order". It used to answer with an order it made
/// up: when the id was not in the list in memory it built an empty one with a
/// total of zero, and the real "Order Not Found" branch underneath was dead
/// (`order.id != orderId` can never be true when the stand-in's id *is* the
/// orderId). That is exactly the case that happens when a notification opens
/// the order before any list has loaded — the customer sees a blank order and
/// reads it as "my order is gone". The same screen also printed "Delivery Fee
/// FREE" whatever the server had charged.
///
/// These tests hold the honest version in place: one place decides what an
/// order row means, the two kinds of "nothing to show" stay apart, and the
/// money rows say what the server actually took.
void main() {
  String read(String path) => File(path).readAsStringSync();

  test('an order row becomes the order the customer paid for', () {
    final order = Order.fromSupabaseRow(_row(walletUsed: 100));

    expect(order.id, 'ord-1');
    expect(order.status, 'confirmed');
    expect(order.statusLabel, 'Confirmed');
    expect(order.address, '12 Main Street, Ludhiana');
    expect(order.deliveryId, 'del-9');
    expect(order.items, hasLength(1));
    expect(order.items.first.product.name, 'Basmati Rice');
    expect(order.items.first.quantity, 2);
    expect(order.itemsSubtotal, 500);
    expect(order.deliveryFee, 29);
    expect(order.walletUsed, 100);
    expect(order.totalAmount, 529);
    expect(order.dateTime.toUtc().year, 2026);
  });

  test('columns the server left out read as zero, not as a crash', () {
    final order = Order.fromSupabaseRow(_row(deliveryFee: null));

    expect(order.deliveryFee, 0);
    expect(order.walletUsed, 0);
    expect(order.itemsSubtotal, 500);
  });

  test('an item without its product is skipped, never faked', () {
    final order = Order.fromSupabaseRow(
      _row(
        items: [
          {'quantity': 1, 'price_at_purchase': 50},
        ],
      ),
    );

    expect(order.items, isEmpty);
    expect(order.itemsSubtotal, 0);
  });

  test('the journey drawn follows the real status', () {
    expect(Order.stepIndexFor('pending'), 0);
    expect(Order.stepIndexFor('confirmed'), 0);
    expect(Order.stepIndexFor('preparing'), 1);
    expect(Order.stepIndexFor('ready_for_pickup'), 1);
    expect(Order.stepIndexFor('out_for_delivery'), 2);
    expect(Order.stepIndexFor('DELIVERED'), 3);
    // A cancelled order never reaches the end of the journey.
    expect(Order.stepIndexFor('cancelled'), -1);
  });

  test('the detail screen never invents an order', () {
    final screen = read('lib/screens/order_detail_screen.dart');

    expect(screen, contains('class OrderDetailScreen extends StatefulWidget'));
    expect(screen, contains('await provider.findOrder(widget.orderId)'));
    expect(screen, contains('provider.lookupFailed'));
    expect(screen, isNot(contains('firstWhere')));
    expect(screen, isNot(contains('orElse:')));
  });

  test('both kinds of nothing are drawn, and one of them retries', () {
    final screen = read('lib/screens/order_detail_screen.dart');

    expect(screen, contains('RoleLoading('));
    expect(screen, contains('RoleError('));
    expect(screen, contains('onRetry: _retry'));
    // The words moved into the string files with the screen's l10n
    // migration: the screen asks for them, the arb holds them.
    expect(screen, contains('l10n.orderDetailNotFound'));
    expect(screen, contains('title: l10n.orderDetailLoadFailed'));
    final arb = read('lib/l10n/app_en.arb');
    expect(arb, contains('Order not found'));
    expect(arb, contains("Couldn't load this order"));
  });

  test('the provider keeps the two kinds of nothing apart', () {
    final provider = read('lib/providers/order_provider.dart');

    expect(provider, contains('Future<Order?> findOrder(String orderId)'));
    expect(provider, contains('bool get lookupFailed'));
    expect(provider, contains('_lookupFailed = true;'));
    expect(provider, contains('.maybeSingle()'));
  });

  test('one place decides what an order row means', () {
    final model = read('lib/models/order.dart');
    expect(model, contains('static const selectColumns'));
    expect(model, contains('factory Order.fromSupabaseRow'));
    expect(model, contains('delivery_fee'));
    expect(model, contains('wallet_used'));

    // The list and the detail screen ask the same question.
    expect(
      read('lib/providers/order_provider.dart'),
      contains('.select(Order.selectColumns)'),
    );
  });

  test('the money rows say what the server charged', () {
    final screen = read('lib/screens/order_detail_screen.dart');

    expect(screen, contains('formatRupees(order.itemsSubtotal)'));
    expect(screen, contains('order.deliveryFee > 0'));
    expect(screen, contains('l10n.orderDetailWalletApplied'));
    // The delivery row says FREE only when there is nothing to charge.
    expect(screen, contains('l10n.orderDetailFree'));
    expect(screen, contains('isGreen: order.deliveryFee <= 0'));
    // The heading is the order's own status, not a fixed "Order Placed".
    expect(screen, contains('l10n.orderDetailStatusWith(order.statusLabel)'));
    expect(screen, isNot(contains("'Order Placed'")));
    final arb = read('lib/l10n/app_en.arb');
    expect(arb, contains('Wallet Applied'));
    expect(arb, contains('Order {status}'));
  });

  test('a cancel is only announced once the backend agreed', () {
    final provider = read('lib/providers/order_provider.dart');
    expect(provider, contains('Future<bool> updateOrderStatus('));
    expect(provider, contains('_orders[at] = before;'));

    final screen = read('lib/screens/order_detail_screen.dart');
    expect(screen, contains('await provider.updateOrderStatus('));
    expect(screen, contains('l10n.orderDetailCancelFailed'));
    expect(
      read('lib/l10n/app_en.arb'),
      contains("Couldn't cancel this order. Please try again."),
    );
  });

  test('a review or rating that failed to save says so', () {
    final screen = read('lib/screens/order_detail_screen.dart');

    expect(screen, contains('l10n.orderDetailReviewFailed'));
    expect(screen, contains('l10n.orderDetailRateFailed'));
    final arb = read('lib/l10n/app_en.arb');
    expect(arb, contains("Couldn't save your review. Please try again."));
    expect(arb, contains("Couldn't save your rating. Please try again."));
  });

  test('the referral row does not hide itself when it fails', () {
    final profile = read('lib/screens/profile_screen.dart');

    expect(profile, contains('bool _failed = false;'));
    // The row's words moved into the string files with the screen's l10n
    // migration; it must still ask for them, and the arb must hold them.
    expect(profile, contains('l10n.profileReferralFailed'));
    expect(
      read('lib/l10n/app_en.arb'),
      contains("Couldn't load your friends code — tap to retry"),
    );
  });

  test('both doors into an order still open it by id', () {
    for (final name in ['orders_screen.dart', 'notifications_screen.dart']) {
      expect(
        read('lib/screens/$name'),
        contains('OrderDetailScreen(orderId:'),
        reason: name,
      );
    }
  });
}

/// An `orders` row shaped like the one [Order.selectColumns] asks for.
Map<String, dynamic> _row({
  String status = 'confirmed',
  num total = 529,
  num? deliveryFee = 29,
  num? walletUsed,
  List<dynamic>? items,
}) {
  final row = <String, dynamic>{
    'id': 'ord-1',
    'status': status,
    'total_amount': total,
    'delivery_address': '12 Main Street, Ludhiana',
    'created_at': '2026-09-20T10:30:00Z',
    'delivery_id': 'del-9',
    'order_items': items ??
        [
          {
            'quantity': 2,
            'price_at_purchase': 250,
            'products': {
              'id': 'prod-1',
              'name': 'Basmati Rice',
              'description': 'Long grain',
              'price': 250,
              'discount_price': 250,
              'stock': 8,
              'seller_id': 'sell-1',
              'unit': '5 kg',
              'categories': {'name': 'Grocery'},
            },
          },
        ],
  };
  if (deliveryFee != null) row['delivery_fee'] = deliveryFee;
  if (walletUsed != null) row['wallet_used'] = walletUsed;
  return row;
}
