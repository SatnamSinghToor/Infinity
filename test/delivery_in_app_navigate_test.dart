import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The rider's Navigate button used to hand off to whatever maps app the
/// phone had (or none). These pins keep it opening the app's own map
/// instead, on the same tiles the customer's own tracking screen uses.
void main() {
  String read(String path) => File(path).readAsStringSync();

  test('the screen draws the same OpenStreetMap tiles as order tracking', () {
    final navigate = read('lib/screens/delivery/delivery_navigate_screen.dart');
    final tracking = read('lib/screens/order_tracking_screen.dart');
    const tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    expect(navigate, contains(tileUrl));
    expect(tracking, contains(tileUrl));
  });

  test('it draws the road route, with a straight line only as a fallback', () {
    final src = read('lib/screens/delivery/delivery_navigate_screen.dart');
    expect(src, contains('PolylineLayer'));
    expect(src, contains('RouteService.fetch('));
    expect(src, contains('_route?.points ??'));
    expect(src, contains('Geolocator.distanceBetween('));
    final service = read('lib/services/route_service.dart');
    expect(service, contains('router.project-osrm.org'));
  });

  test('turn-by-turn is one tap away in Google Maps', () {
    final src = read('lib/screens/delivery/delivery_navigate_screen.dart');
    expect(src, contains('LaunchActions.directions('));
    expect(read('lib/utils/launch_actions.dart'), contains("'/maps/dir/'"));
  });

  test('the run list opens the in-app screen, not an external maps app', () {
    final src = read('lib/screens/delivery/delivery_orders_screen.dart');
    expect(src, contains('DeliveryNavigateScreen('));
    expect(src, isNot(contains('LaunchActions.navigateTo')));
    // Calling isn't navigation: the dialler still has to be a real app.
    expect(src, contains('LaunchActions.call('));
  });

  test('missing coordinates say so instead of opening a blank map', () {
    final src = read('lib/screens/delivery/delivery_orders_screen.dart');
    expect(src, contains('if (lat == null || lng == null) {'));
    expect(src, contains('deliveryOrdersNavigateFailed'));
  });
}
