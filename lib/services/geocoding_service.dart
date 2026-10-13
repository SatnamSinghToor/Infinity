import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A place resolved from a typed address ([GeocodingService.search]) or from
/// map coordinates ([GeocodingService.reverse]).
class GeocodedPlace {
  final double lat;
  final double lng;
  final String address;
  final String city;
  final String pincode;

  const GeocodedPlace({
    required this.lat,
    required this.lng,
    required this.address,
    this.city = '',
    this.pincode = '',
  });
}

/// Address <-> coordinates lookups against OpenStreetMap's Nominatim, so the
/// map screens need no API key (same reasoning as the OSM tracking map).
/// Nominatim's usage policy asks for an identifying User-Agent and light
/// traffic — callers should debounce and only look up on user actions.
class GeocodingService {
  static const _host = 'nominatim.openstreetmap.org';
  static const _headers = {
    'User-Agent': 'DugguApp/1.0 (com.duggu.app)',
    'Accept-Language': 'en',
  };
  static const _timeout = Duration(seconds: 10);

  /// Finds the best match for a typed [query], or null if nothing matched
  /// (or the request failed).
  static Future<GeocodedPlace?> search(
    String query, {
    String countryCodes = 'in',
  }) async {
    final q = query.trim();
    if (q.isEmpty) return null;
    final uri = Uri.https(_host, '/search', {
      'q': q,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '1',
      if (countryCodes.isNotEmpty) 'countrycodes': countryCodes,
    });
    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final list = jsonDecode(res.body) as List;
      if (list.isEmpty) return null;
      return _parse(list.first as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Geocode search failed: $e');
      return null;
    }
  }

  /// Finds the address at [lat]/[lng], or null if none was found.
  static Future<GeocodedPlace?> reverse(double lat, double lng) async {
    final uri = Uri.https(_host, '/reverse', {
      'lat': '$lat',
      'lon': '$lng',
      'format': 'jsonv2',
      'addressdetails': '1',
      'zoom': '18',
    });
    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (json['error'] != null) return null;
      return _parse(json, fallbackLat: lat, fallbackLng: lng);
    } catch (e) {
      debugPrint('Reverse geocode failed: $e');
      return null;
    }
  }

  static GeocodedPlace? _parse(
    Map<String, dynamic> json, {
    double? fallbackLat,
    double? fallbackLng,
  }) {
    final lat = double.tryParse('${json['lat']}') ?? fallbackLat;
    final lng = double.tryParse('${json['lon']}') ?? fallbackLng;
    if (lat == null || lng == null) return null;

    final addr = (json['address'] as Map?)?.cast<String, dynamic>() ?? {};
    String pick(List<String> keys) {
      for (final k in keys) {
        final v = addr[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return '';
    }

    return GeocodedPlace(
      lat: lat,
      lng: lng,
      address: (json['display_name'] as String?)?.trim() ?? '',
      city: pick(['city', 'town', 'village', 'municipality', 'state_district']),
      pincode: pick(['postcode']),
    );
  }
}
