import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Order status used to move only on a pull-to-refresh: a seller marking an
/// order "preparing" or a rider marking it "out for delivery" reached the
/// shopper's screen only the next time it re-asked the server. These pins
/// keep the live status subscription wired to both screens that show it.
void main() {
  String read(String path) => File(path).readAsStringSync();

  test('the provider streams one order\'s status and cleans up after itself',
      () {
    final src = read('lib/providers/order_provider.dart');
    expect(src, contains('void watchOrderStatus(String? orderId)'));
    // Only the base `orders` row, not a join — Supabase's realtime stream
    // cannot read `order_items`, so only the status is meant to move live.
    expect(
        src, contains(".from('orders')\n        .stream(primaryKey: ['id'])"));
    expect(src, contains("Best-effort"));
    expect(src, contains('void dispose() {'));
    expect(src, contains('_statusWatch?.cancel();'));
  });

  test('the order detail screen starts and stops the live watch', () {
    final src = read('lib/screens/order_detail_screen.dart');
    expect(src, contains('watchOrderStatus(widget.orderId)'));
    expect(src, contains('watchOrderStatus(null)'));
    // The screen reads the live order back from the provider, not only its
    // own one-time fetch, so a status pushed in after the initial load is
    // still shown.
    expect(src, contains('context.watch<OrderProvider>().orders'));
  });

  test('the tracking screen starts and stops the live watch', () {
    final src = read('lib/screens/order_tracking_screen.dart');
    expect(src, contains('watchOrderStatus(widget.orderId)'));
    expect(src, contains('watchOrderStatus(null)'));
  });
}
