import 'dart:async';

import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../services/geocoding_service.dart';
import '../../utils/constants.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/pressable.dart';
import '../../widgets/osm_attribution.dart';

/// What the seller confirmed on the map: the pin, plus the address the pin
/// resolves to (may be empty if the lookup failed or was offline).
class StoreLocationResult {
  final double lat;
  final double lng;
  final String address;
  final String city;
  final String pincode;

  const StoreLocationResult({
    required this.lat,
    required this.lng,
    this.address = '',
    this.city = '',
    this.pincode = '',
  });
}

/// Full-screen map for placing the store pin. Three ways to set it:
///  * live location — the GPS button jumps the map to where the seller is,
///  * manual address — type an address/area/pincode and search,
///  * map pin — pan the map under the fixed centre pin to fine-tune.
/// Pops with a [StoreLocationResult] when confirmed.
class StoreLocationPickerScreen extends StatefulWidget {
  /// Existing pin, if the store already has one.
  final ll.LatLng? initial;

  /// Address text to search for when there is no [initial] pin yet.
  final String initialQuery;

  /// Wording, so the same map can serve the store pin and delivery addresses.
  final String title;
  final String searchHint;
  final String confirmLabel;

  const StoreLocationPickerScreen({
    super.key,
    this.initial,
    this.initialQuery = '',
    this.title = 'Store Location',
    this.searchHint = 'Search store address, area or pincode',
    this.confirmLabel = 'Confirm store location',
  });

  @override
  State<StoreLocationPickerScreen> createState() =>
      _StoreLocationPickerScreenState();
}

class _StoreLocationPickerScreenState extends State<StoreLocationPickerScreen> {
  // Centre of India — only the starting view when nothing is known yet.
  static const _defaultCenter = ll.LatLng(20.5937, 78.9629);

  final _map = MapController();
  late final TextEditingController _searchController;
  Timer? _debounce;

  late ll.LatLng _point;
  late bool _hasPoint;
  GeocodedPlace? _place;
  bool _locating = false;
  bool _searching = false;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _point = widget.initial ?? _defaultCenter;
    _hasPoint = widget.initial != null;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _map.dispose();
    super.dispose();
  }

  void _toast(String message, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
          action: action));
  }

  void _onMapReady() {
    if (widget.initial != null) {
      _resolveAddress();
    } else if (widget.initialQuery.trim().isNotEmpty) {
      _searchAddress(auto: true);
    } else {
      _useCurrentLocation(silent: true);
    }
  }

  // The user panned the map: the pin stays at the centre, so the map's
  // centre is the new store location. Wait for them to settle before
  // hitting the geocoder.
  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    _point = camera.center;
    if (!_hasPoint || !_resolving) {
      setState(() {
        _hasPoint = true;
        _resolving = true;
      });
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), _resolveAddress);
  }

  Future<void> _resolveAddress() async {
    final target = _point;
    if (mounted) setState(() => _resolving = true);
    final place =
        await GeocodingService.reverse(target.latitude, target.longitude);
    if (!mounted) return;
    // Ignore a stale answer if the pin has moved on since.
    if (target != _point) return;
    setState(() {
      _place = place;
      _resolving = false;
    });
  }

  void _moveTo(ll.LatLng target, {GeocodedPlace? place, double zoom = 16}) {
    _debounce?.cancel();
    _map.move(target, zoom);
    setState(() {
      _point = target;
      _hasPoint = true;
      _place = place;
      _resolving = place == null;
    });
    if (place == null) _resolveAddress();
  }

  Future<void> _useCurrentLocation({bool silent = false}) async {
    if (_locating) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!silent) _toast(l10n.sellerLocationGpsOff);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (!silent) {
          _toast(
            l10n.sellerLocationPermissionBlocked,
            action: SnackBarAction(
              label: l10n.sellerLocationSettings,
              onPressed: Geolocator.openAppSettings,
            ),
          );
        }
        return;
      }
      if (permission == LocationPermission.denied) {
        if (!silent) _toast(l10n.sellerLocationPermissionNeeded);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      _moveTo(ll.LatLng(position.latitude, position.longitude));
    } catch (e) {
      debugPrint('Current location failed: $e');
      if (!silent) _toast(l10n.sellerLocationFailed);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _searchAddress({bool auto = false}) async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _searching) return;
    FocusScope.of(context).unfocus();
    setState(() => _searching = true);
    final place = await GeocodingService.search(query);
    if (!mounted) return;
    setState(() => _searching = false);
    if (place == null) {
      if (auto) {
        _useCurrentLocation(silent: true);
      } else {
        _toast(AppLocalizations.of(context).sellerLocationNotFound);
      }
      return;
    }
    _moveTo(ll.LatLng(place.lat, place.lng), place: place);
  }

  void _confirm() {
    Navigator.pop(
      context,
      StoreLocationResult(
        lat: _point.latitude,
        lng: _point.longitude,
        address: _place?.address ?? '',
        city: _place?.city ?? '',
        pincode: _place?.pincode ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
          title:
              Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          centerTitle: true),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _point,
              initialZoom: _hasPoint ? 16 : 5,
              maxZoom: 19,
              onMapReady: _onMapReady,
              onPositionChanged: _onPositionChanged,
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
            ],
          ),
          // Fixed centre pin — the map moves under it.
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _hasPoint ? 1 : 0.35,
                  child: const Icon(
                    Iconsax.location_copy,
                    size: 48,
                    color: AppConstants.primaryColor,
                    shadows: [Shadow(color: Colors.black38, blurRadius: 8)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(top: 12, left: 12, right: 12, child: _buildSearchBar()),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 10),
                  child: FloatingActionButton.small(
                    heroTag: 'store-location-gps',
                    backgroundColor: Colors.white,
                    foregroundColor: AppConstants.primaryColor,
                    onPressed: _locating ? null : _useCurrentLocation,
                    child: _locating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Iconsax.gps),
                  ),
                ),
                _buildBottomCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _searchAddress(),
        decoration: InputDecoration(
          hintText: widget.searchHint,
          hintStyle: const TextStyle(fontSize: 13),
          prefixIcon: const Icon(Iconsax.search_normal_1, size: 20),
          suffixIcon: _searching
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Pressable(
                  child: IconButton(
                  icon: const Icon(
                    Iconsax.arrow_right_3,
                    color: AppConstants.primaryColor,
                  ),
                  onPressed: _searchAddress,
                )),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCard() {
    final l10n = AppLocalizations.of(context);
    final address = _place?.address ?? '';
    final String headline;
    if (!_hasPoint) {
      headline = l10n.sellerLocationHint;
    } else if (_resolving) {
      headline = l10n.sellerLocationResolving;
    } else if (address.isNotEmpty) {
      headline = address;
    } else {
      headline = l10n.sellerLocationLookupUnavailable;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Iconsax.location,
                  size: 20,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    headline,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppConstants.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            if (_hasPoint) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Text(
                  '${_point.latitude.toStringAsFixed(5)}, '
                  '${_point.longitude.toStringAsFixed(5)}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: Pressable(
                  child: ElevatedButton(
                onPressed: _hasPoint ? _confirm : null,
                child: Text(widget.confirmLabel,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              )),
            ),
          ],
        ),
      ),
    );
  }
}
