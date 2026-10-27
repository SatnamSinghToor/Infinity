import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'supabase_service.dart';

/// Streams the signed-in delivery partner's device location into
/// `delivery_tracking` (one row per order, upserted on `order_id`) for as
/// long as they have orders `out_for_delivery`. Customers watch the same
/// table via Realtime on the order tracking screen.
class LocationTrackingService {
  LocationTrackingService._();
  static final LocationTrackingService instance = LocationTrackingService._();

  StreamSubscription<Position>? _positionSub;
  Set<String> _trackedOrderIds = {};
  String? _partnerId;

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Call whenever the partner's active order list changes. Starts
  /// streaming location once there's at least one order out for delivery,
  /// and stops once there are none.
  Future<void> syncActiveOrders(
    String partnerId,
    Iterable<String> outForDeliveryOrderIds,
  ) async {
    _partnerId = partnerId;
    _trackedOrderIds = outForDeliveryOrderIds.toSet();

    if (_trackedOrderIds.isEmpty) {
      await _positionSub?.cancel();
      _positionSub = null;
      return;
    }

    if (_positionSub != null) return;
    if (!await _ensurePermission()) return;

    _positionSub = Geolocator.getPositionStream(
      locationSettings: _settings(),
    ).listen(_broadcast, onError: (_) {});
    // The stream only reports after moving [distanceFilter]; send where the
    // rider is right now so the customer's map isn't empty until then.
    try {
      _broadcast(await Geolocator.getCurrentPosition());
    } catch (e) {
      debugPrint('First location fix failed: $e');
    }
  }

  /// On Android, runs as a foreground service with an ongoing notification,
  /// so the customer's map keeps moving while the rider has another app
  /// (or the screen off) — a plain stream stops the moment the app is
  /// backgrounded.
  LocationSettings _settings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Delivering an order',
          notificationText: 'Sharing your location with the customer.',
          notificationChannelName: 'Live delivery location',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15,
    );
  }

  Future<void> _broadcast(Position position) async {
    final partnerId = _partnerId;
    if (partnerId == null) return;
    for (final orderId in _trackedOrderIds) {
      try {
        await SupabaseService.client.from('delivery_tracking').upsert({
          'order_id': orderId,
          'delivery_id': partnerId,
          'status': 'out_for_delivery',
          'latitude': position.latitude,
          'longitude': position.longitude,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'order_id');
      } catch (e) {
        debugPrint('Location broadcast failed: $e');
      }
    }
  }

  /// Stops location tracking and cleans up resources. Call when the partner
  /// logs out or the app no longer needs to track location.
  Future<void> dispose() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _trackedOrderIds.clear();
    _partnerId = null;
  }
}
