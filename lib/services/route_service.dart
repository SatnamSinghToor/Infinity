import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;

/// A road route between two points: the line to draw, its length and how
/// long it takes.
class RoadRoute {
  final List<ll.LatLng> points;
  final double meters;
  final double seconds;

  const RoadRoute(this.points, this.meters, this.seconds);
}

/// Road routes from OSRM (OpenStreetMap's routing engine), on the same map
/// data the app's tiles are drawn from — no key needed.
///
/// This uses the public demo server, which is meant for light use: fine for
/// a handful of riders, but a busy shop should point [_base] at its own
/// OSRM (or a keyed service) before it leans on it.
class RouteService {
  const RouteService._();

  static const _base = 'https://router.project-osrm.org/route/v1/driving';

  /// The route from [from] to [to], or null when it couldn't be worked out
  /// (offline, server busy) — the caller falls back to a straight line.
  static Future<RoadRoute?> fetch(ll.LatLng from, ll.LatLng to) async {
    final url = Uri.parse(
      '$_base/${from.longitude},${from.latitude};'
      '${to.longitude},${to.latitude}'
      '?overview=full&geometries=geojson',
    );
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['code'] != 'Ok') return null;
      final route = (body['routes'] as List).first as Map<String, dynamic>;
      final coords = (route['geometry']['coordinates'] as List)
          .map((c) => ll.LatLng(
                (c[1] as num).toDouble(),
                (c[0] as num).toDouble(),
              ))
          .toList();
      if (coords.length < 2) return null;
      return RoadRoute(
        coords,
        (route['distance'] as num).toDouble(),
        (route['duration'] as num).toDouble(),
      );
    } catch (e) {
      debugPrint('Route lookup failed: $e');
      return null;
    }
  }
}
