import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../services/supabase_service.dart';

/// Where a customer's delivery stands: is there a store that can bring it,
/// and how long that takes.
enum DeliveryStatus {
  /// No delivery address with a map position yet.
  noLocation,

  /// No open store has put itself on the map yet.
  noStore,

  /// The nearest open store doesn't deliver this far.
  outOfRange,

  /// A store can deliver; [DeliveryEtaProvider.minutes] is filled in.
  ok,
}

class _StorePoint {
  final String ownerId;
  final String name;
  final double lat;
  final double lng;
  final double radiusKm;
  final bool approved;

  const _StorePoint({
    required this.ownerId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusKm,
    required this.approved,
  });
}

/// Works out the delivery time from real data: the distance between the
/// customer's address and the nearest open store, plus packing time. Nothing
/// is quoted until there is an address and a store to measure from.
class DeliveryEtaProvider extends ChangeNotifier {
  /// Time to pick and pack an order.
  static const packingMinutes = 8;

  /// Average rider speed in town.
  static const _kmPerHour = 22.0;

  /// Roads are longer than the straight line between two points.
  static const _roadFactor = 1.3;

  List<_StorePoint> _stores = [];
  double? _lat;
  double? _lng;
  Set<String> _sellersWithProducts = {};

  DeliveryStatus _status = DeliveryStatus.noLocation;
  int? _minutes;
  double? _distanceKm;
  String? _storeName;

  DeliveryEtaProvider() {
    load();
  }

  DeliveryStatus get status => _status;

  /// Whole minutes until delivery; only when [status] is [DeliveryStatus.ok].
  int? get minutes => _minutes;

  /// Straight-line distance to the store that would deliver.
  double? get distanceKm => _distanceKm;

  String? get storeName => _storeName;

  /// "12 minutes", or null while it can't be worked out.
  String? get label => _status == DeliveryStatus.ok && _minutes != null
      ? '$_minutes ${_minutes == 1 ? 'minute' : 'minutes'}'
      : null;

  /// "590 m away" / "1.4 km away".
  String? get distanceLabel {
    final d = _distanceKm;
    if (d == null) return null;
    return d < 1
        ? '${(d * 1000).round()} m away'
        : '${d.toStringAsFixed(1)} km away';
  }

  Future<void> load() async {
    try {
      final rows = await SupabaseService.client
          .from('stores')
          .select('owner_id, name, lat, lng, delivery_radius_km, is_open, '
              'is_approved');
      _stores = [
        for (final row in rows)
          if ((row['is_open'] as bool? ?? true) &&
              row['lat'] is num &&
              row['lng'] is num)
            _StorePoint(
              ownerId: row['owner_id'] as String? ?? '',
              name: row['name'] as String? ?? 'Store',
              lat: (row['lat'] as num).toDouble(),
              lng: (row['lng'] as num).toDouble(),
              radiusKm: (row['delivery_radius_km'] as num?)?.toDouble() ?? 0,
              approved: row['is_approved'] as bool? ?? false,
            ),
      ];
      if (_recompute()) notifyListeners();
    } catch (e) {
      debugPrint('Delivery stores load failed: $e');
    }
  }

  /// Called whenever the customer's address or the products on sale change.
  void setInputs({
    required double? lat,
    required double? lng,
    required Set<String> sellersWithProducts,
  }) {
    _lat = lat;
    _lng = lng;
    _sellersWithProducts = sellersWithProducts;
    // This runs while widgets build, so announce the change afterwards.
    if (_recompute()) Future.microtask(notifyListeners);
  }

  /// Returns whether anything changed.
  bool _recompute() {
    final oldStatus = _status;
    final oldMinutes = _minutes;
    final oldDistance = _distanceKm;
    final oldName = _storeName;

    _minutes = null;
    _distanceKm = null;
    _storeName = null;

    final lat = _lat;
    final lng = _lng;
    if (lat == null || lng == null) {
      _status = DeliveryStatus.noLocation;
    } else {
      // Stores that are approved or already selling.
      final candidates = _stores
          .where((s) => s.approved || _sellersWithProducts.contains(s.ownerId))
          .toList();
      if (candidates.isEmpty) {
        _status = DeliveryStatus.noStore;
      } else {
        _StorePoint? nearest;
        var nearestKm = double.infinity;
        for (final store in candidates) {
          final km = _haversineKm(lat, lng, store.lat, store.lng);
          if (km < nearestKm) {
            nearest = store;
            nearestKm = km;
          }
        }
        _storeName = nearest!.name;
        _distanceKm = nearestKm;
        if (nearest.radiusKm > 0 && nearestKm > nearest.radiusKm) {
          _status = DeliveryStatus.outOfRange;
        } else {
          final ride = nearestKm * _roadFactor / _kmPerHour * 60;
          _minutes = math.max(10, (packingMinutes + ride).ceil());
          _status = DeliveryStatus.ok;
        }
      }
    }

    return oldStatus != _status ||
        oldMinutes != _minutes ||
        oldName != _storeName ||
        (oldDistance ?? -1) != (_distanceKm ?? -1);
  }

  static double _haversineKm(
      double lat1, double lng1, double lat2, double lng2) {
    const earthKm = 6371.0;
    double rad(double deg) => deg * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return earthKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
