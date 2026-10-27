import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A rider's run used to say only the drop-off address and the amount — not
/// where to collect the order from, not the customer's number, and no way
/// to open directions without leaving the app to type an address by hand.
/// These pins keep that information, and the actions built on it, wired in.
void main() {
  String read(String path) => File(path).readAsStringSync();

  test('calling still goes through the phone\'s own dialler', () {
    final src = read('lib/utils/launch_actions.dart');
    expect(src, contains("Uri(scheme: 'tel', path: digits)"));
  });

  test('a run knows its pickup store and the customer to call', () {
    final src = read('lib/screens/delivery/delivery_orders_screen.dart');
    expect(src, contains("from('stores')"));
    expect(src, contains("select('owner_id, name, address, lat, lng')"));
    expect(src, contains("from('profiles')"));
    expect(src, contains("select('id, phone')"));
    // The customer's phone is only looked up for runs already claimed —
    // not the "Available" list, which is not this rider's delivery yet.
    expect(src, contains('isMine ? _phoneByCustomer'));
  });

  test('a lookup failure for the extra details does not blank the runs', () {
    final src = read('lib/screens/delivery/delivery_orders_screen.dart');
    expect(src, contains('Best-effort'));
  });

  test('the run card offers Navigate, and Call once claimed', () {
    final src = read('lib/screens/delivery/delivery_orders_screen.dart');
    expect(src, contains('l10n.deliveryOrdersNavigate'));
    expect(src, contains('l10n.deliveryOrdersCall'));
    expect(src, contains('l10n.deliveryOrdersMoreItems('));
    expect(src, contains('l10n.deliveryOrdersPickFrom'));
    expect(src, contains('l10n.deliveryOrdersDeliverTo'));
    final arb = read('lib/l10n/app_en.arb');
    expect(arb, contains('"deliveryOrdersNavigate"'));
    expect(arb, contains('"deliveryOrdersCall"'));
    expect(arb, contains('"deliveryOrdersPickFrom"'));
    expect(arb, contains('"deliveryOrdersDeliverTo"'));
  });
}
