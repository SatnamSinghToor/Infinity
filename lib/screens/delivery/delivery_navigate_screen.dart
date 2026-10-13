import 'dart:async';

import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../services/device_location_service.dart';
import '../../services/route_service.dart';
import '../../utils/launch_actions.dart';
import '../../utils/tokens.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/pressable.dart';
import '../../widgets/osm_attribution.dart';

/// Directions inside the app, on the same OpenStreetMap tiles the customer's
/// own order-tracking screen already uses — a rider used to be sent out to
/// whatever maps app happened to be on their phone (or none) for this.
///
/// The road route comes from OSRM ([RouteService]) and follows the rider as
/// they move; when it can't be had, a straight line and its distance stand
/// in. For spoken turn-by-turn, the screen hands the trip to Google Maps.
class DeliveryNavigateScreen extends StatefulWidget {
  final double destLat;
  final double destLng;
  final String title;
  final String? address;

  const DeliveryNavigateScreen({
    super.key,
    required this.destLat,
    required this.destLng,
    required this.title,
    this.address,
  });

  @override
  State<DeliveryNavigateScreen> createState() => _DeliveryNavigateScreenState();
}

class _DeliveryNavigateScreenState extends State<DeliveryNavigateScreen> {
  Position? _me;
  bool _locating = true;
  String? _locateError;
  final _mapController = MapController();

  RoadRoute? _route;

  /// The last route lookup failed: the map is showing a straight line, and
  /// the card says so rather than passing it off as the road.
  bool _routeFailed = false;

  /// Where the current [_route] starts; a new one is fetched once the rider
  /// has moved well away from it.
  ll.LatLng? _routeFrom;
  StreamSubscription<Position>? _follow;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  @override
  void dispose() {
    _follow?.cancel();
    super.dispose();
  }

  ll.LatLng get _dest => ll.LatLng(widget.destLat, widget.destLng);

  Future<void> _fetchRoute(Position from) async {
    final start = ll.LatLng(from.latitude, from.longitude);
    _routeFrom = start;
    final route = await RouteService.fetch(start, _dest);
    if (!mounted) return;
    if (route == null) {
      if (_route == null) setState(() => _routeFailed = true);
      return;
    }
    final firstRoute = _route == null;
    setState(() {
      _route = route;
      _routeFailed = false;
    });
    if (firstRoute) _fit();
  }

  /// Keeps the rider's dot moving, and re-routes once they have left the
  /// start of the current route behind (a turn missed, a shortcut taken).
  void _startFollowing() {
    _follow ??= Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((p) {
      if (!mounted) return;
      setState(() => _me = p);
      final from = _routeFrom;
      if (from == null ||
          Geolocator.distanceBetween(
                  from.latitude, from.longitude, p.latitude, p.longitude) >
              60) {
        _fetchRoute(p);
      }
    }, onError: (Object e) => debugPrint('Follow failed: $e'));
  }

  Future<void> _openGoogleMaps() async {
    final ok = await LaunchActions.directions(widget.destLat, widget.destLng);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).deliveryNavigateMapsFailed,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _locateError = null;
    });
    try {
      final position = await DeviceLocationService.current();
      if (!mounted) return;
      setState(() {
        _me = position;
        _locating = false;
      });
      _fit();
      _fetchRoute(position);
      _startFollowing();
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _locateError = e.message;
        _locating = false;
      });
    }
  }

  void _fit() {
    final me = _me;
    final dest = ll.LatLng(widget.destLat, widget.destLng);
    if (me == null) {
      _mapController.move(dest, 15);
      return;
    }
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: [
          dest,
          ll.LatLng(me.latitude, me.longitude),
          ...?_route?.points,
        ],
        padding: const EdgeInsets.fromLTRB(48, 96, 48, 160),
        // Two points a few metres apart would otherwise fit at zoom 22+,
        // past the last zoom level map tiles exist for: a blank grey map.
        maxZoom: 17,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final dest = ll.LatLng(widget.destLat, widget.destLng);
    final me = _me;
    final distanceMeters = me == null
        ? null
        : Geolocator.distanceBetween(
            me.latitude, me.longitude, widget.destLat, widget.destLng);

    return Scaffold(
      backgroundColor: t.surface,
      appBar: GradientAppBar(
        title: Text(l10n.deliveryNavigateTitle,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: dest,
              initialZoom: 15,
              maxZoom: 19,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.duggustore.app',
                // OpenStreetMap has no tiles past zoom 19: stretch those
                // instead of showing grey.
                maxNativeZoom: 19,
              ),
              const OsmAttribution(),
              if (me != null)
                PolylineLayer(
                  polylines: [
                    // The road route when there is one; a straight line
                    // only while it loads or when it can't be had.
                    Polyline(
                      points: _route?.points ??
                          [ll.LatLng(me.latitude, me.longitude), dest],
                      strokeWidth: _route == null ? 3 : 5,
                      color: _route == null
                          ? t.primary.withOpacity(0.45)
                          : t.primary.withOpacity(0.9),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: dest,
                    width: 44,
                    height: 44,
                    child: Icon(
                      Iconsax.location,
                      color: t.primary,
                      size: 40,
                    ),
                  ),
                  if (me != null)
                    Marker(
                      point: ll.LatLng(me.latitude, me.longitude),
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 6),
                          ],
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Iconsax.truck_fast,
                          color: t.primary,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: _InfoCard(
              tokens: t,
              title: widget.title,
              address: widget.address,
              locating: _locating,
              error: _locateError,
              distanceMeters: distanceMeters,
              route: _route,
              routeFailed: _routeFailed,
              onRetry: _locate,
            ),
          ),
          Positioned(
            left: 16,
            bottom: 24,
            child: Pressable(
                child: FloatingActionButton.extended(
              heroTag: 'google-maps',
              backgroundColor: t.primary,
              foregroundColor: Colors.white,
              onPressed: _openGoogleMaps,
              icon: const Icon(Iconsax.routing_2),
              label: Text(l10n.deliveryNavigateOpenMaps,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            )),
          ),
          Positioned(
            right: 16,
            bottom: 24,
            child: Pressable(
                child: FloatingActionButton(
              heroTag: 'recenter',
              backgroundColor: Colors.white,
              foregroundColor: t.primary,
              onPressed: _me == null ? _locate : _fit,
              tooltip: l10n.deliveryNavigateRecenter,
              child: const Icon(Iconsax.gps),
            )),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final AppTokens tokens;
  final String title;
  final String? address;
  final bool locating;
  final String? error;
  final double? distanceMeters;
  final RoadRoute? route;
  final bool routeFailed;
  final VoidCallback onRetry;

  const _InfoCard({
    required this.tokens,
    required this.title,
    required this.address,
    required this.locating,
    required this.error,
    required this.distanceMeters,
    required this.route,
    required this.routeFailed,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Iconsax.location, color: tokens.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (address != null && address!.isNotEmpty)
                  Text(
                    address!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700], fontSize: 12.5),
                  ),
                const SizedBox(height: 2),
                if (locating)
                  Text(l10n.deliveryNavigateLocating,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12.5))
                else if (error != null)
                  Text(error!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: tokens.danger, fontSize: 12.5))
                else if (route != null)
                  Text(
                    l10n.deliveryNavigateByRoad(
                      _format(route!.meters),
                      (route!.seconds / 60).ceil(),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  )
                else if (distanceMeters != null) ...[
                  Text(
                    l10n.deliveryNavigateDistance(_format(distanceMeters!)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                  if (routeFailed)
                    Text(
                      l10n.deliveryNavigateNoRoute,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                ],
              ],
            ),
          ),
          if (error != null)
            Pressable(
                child: TextButton(
              onPressed: onRetry,
              child: Text(l10n.deliveryNavigateRetry,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            )),
        ],
      ),
    );
  }

  String _format(double meters) {
    if (meters < 950) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}
