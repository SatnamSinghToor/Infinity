import 'dart:async';

import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;

import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/delivery_eta_provider.dart';
import '../providers/order_provider.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import '../widgets/gradient_app_bar.dart';
import '../utils/format.dart';
import '../utils/launch_actions.dart';
import '../widgets/osm_attribution.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  @override
  void initState() {
    super.initState();
    // The status stepper below reads straight from the provider's order
    // list; this just keeps that entry's status current while the screen
    // is open, the same way the delivery-location map already streams.
    context.read<OrderProvider>().watchOrderStatus(widget.orderId);
  }

  @override
  void dispose() {
    context.read<OrderProvider>().watchOrderStatus(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.orderId;
    final l10n = AppLocalizations.of(context);
    final orderProvider = context.watch<OrderProvider>();

    final order = orderProvider.orders.firstWhere(
      (o) => o.id == orderId,
      orElse: () => Order(
        id: orderId,
        items: [],
        totalAmount: 0,
        address: '',
        phone: '',
        name: '',
        dateTime: DateTime.now(),
      ),
    );

    if (order.items.isEmpty && order.id != orderId) {
      return Scaffold(
        appBar: GradientAppBar(
            title: Text(l10n.trackingNotFound,
                maxLines: 1, overflow: TextOverflow.ellipsis)),
        body: Center(
          child: Text(l10n.trackingOrderMissing,
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      );
    }

    final statusIndex = _getStatusIndex(order.status);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
          title: Text(l10n.trackingTitle,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Iconsax.truck,
                      size: 48,
                      color: AppConstants.primaryColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.trackingOrderNumber(orderId),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.trackingExpected(
                        context.watch<DeliveryEtaProvider>().label ??
                            l10n.trackingEtaUnset,
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (order.status == 'out_for_delivery' &&
                order.deliveryId != null) ...[
              const SizedBox(height: 20),
              _RiderCard(riderId: order.deliveryId!),
              const SizedBox(height: 12),
              _LiveTrackingMap(orderId: order.id),
            ],
            const SizedBox(height: 28),
            _buildTimeline(l10n, statusIndex),
            const SizedBox(height: 28),
            _buildSection(l10n.trackingSummary),
            const SizedBox(height: 8),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.product.name} × ${item.quantity}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      formatRupees(item.totalPrice),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.trackingTotal,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  formatRupees(order.totalAmount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _getStatusIndex(String status) {
    switch (status.toLowerCase()) {
      case 'cancelled':
        return -1;
      case 'confirmed':
        return 0;
      case 'preparing':
      case 'ready_for_pickup':
        return 1;
      case 'out_for_delivery':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  Widget _buildTimeline(AppLocalizations l10n, int activeIndex) {
    final steps = [
      {'icon': Iconsax.box, 'label': l10n.trackingPlaced},
      {'icon': Iconsax.clock, 'label': l10n.trackingPreparing},
      {'icon': Iconsax.truck, 'label': l10n.trackingOnWay},
      {'icon': Iconsax.tick_circle, 'label': l10n.trackingDelivered},
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final isActive = index <= activeIndex && activeIndex >= 0;
        final isLast = index == steps.length - 1;

        return Row(
          children: [
            SizedBox(
              width: 40,
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppConstants.primaryColor
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        steps[index]['icon'] as IconData,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        height: 40,
                        width: 2,
                        color: isActive && activeIndex > index
                            ? AppConstants.primaryColor
                            : Colors.grey[300],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      steps[index]['label'] as String,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.w500,
                        color:
                            isActive ? AppConstants.primaryColor : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isActive ? l10n.trackingInProgress : l10n.trackingPending,
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive
                            ? AppConstants.textSecondaryColor
                            : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSection(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

/// Live delivery-partner location for [orderId], via a Realtime subscription
/// on `delivery_tracking` and OpenStreetMap tiles (no API key needed). The
/// marker glides to each new position and the map follows it, so the rider
/// never drives off the edge of the view; a badge says how fresh it is.
class _LiveTrackingMap extends StatefulWidget {
  final String orderId;

  const _LiveTrackingMap({required this.orderId});

  @override
  State<_LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<_LiveTrackingMap> {
  final _map = MapController();
  late final Stream<List<Map<String, dynamic>>> _stream = SupabaseService.client
      .from('delivery_tracking')
      .stream(primaryKey: ['id']).eq('order_id', widget.orderId);

  ll.LatLng? _from;
  ll.LatLng? _to;
  DateTime? _updatedAt;
  bool _mapReady = false;

  /// Re-draws the "Xs ago" badge; the position itself arrives by stream.
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _map.dispose();
    super.dispose();
  }

  void _onRow(Map<String, dynamic> row) {
    final lat = (row['latitude'] as num?)?.toDouble();
    final lng = (row['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return;
    final next = ll.LatLng(lat, lng);
    _updatedAt =
        DateTime.tryParse(row['updated_at'] as String? ?? '')?.toLocal() ??
            DateTime.now();
    if (_to == next) return;
    _from = _to ?? next;
    _to = next;
    // After this frame: moving the map is a state change of its own and
    // must not happen in the middle of building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _mapReady) _map.move(next, _map.camera.zoom);
    });
  }

  String _freshness(AppLocalizations l10n) {
    final at = _updatedAt;
    if (at == null) return l10n.trackingLiveNow;
    final age = DateTime.now().difference(at);
    if (age.inSeconds < 10) return l10n.trackingLiveNow;
    if (age.inMinutes < 1) return l10n.trackingLiveSeconds(age.inSeconds);
    return l10n.trackingLiveMinutes(age.inMinutes);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _stream,
          builder: (context, snapshot) {
            final rows = snapshot.data;
            if (rows != null && rows.isNotEmpty) _onRow(rows.first);
            final to = _to;
            if (to == null) {
              return Container(
                color: Colors.white,
                alignment: Alignment.center,
                child: Text(
                  l10n.trackingWaitingLocation,
                  style: TextStyle(color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }
            final stale = _updatedAt != null &&
                DateTime.now().difference(_updatedAt!).inMinutes >= 1;
            return Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: to,
                    initialZoom: 15,
                    maxZoom: 19,
                    onMapReady: () => _mapReady = true,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.duggustore.app',
                      // OpenStreetMap has no tiles past zoom 19: stretch those
                      // instead of showing grey.
                      maxNativeZoom: 19,
                    ),
                    const OsmAttribution(),
                    // Glide from the last position to the new one instead
                    // of jumping.
                    TweenAnimationBuilder<double>(
                      key: ValueKey(to),
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeInOut,
                      builder: (context, t, _) {
                        final from = _from ?? to;
                        final point = ll.LatLng(
                          from.latitude + (to.latitude - from.latitude) * t,
                          from.longitude + (to.longitude - from.longitude) * t,
                        );
                        return MarkerLayer(
                          markers: [
                            Marker(
                              point: point,
                              width: 44,
                              height: 44,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppConstants.primaryColor
                                          .withValues(alpha: 0.35),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Iconsax.truck_fast,
                                  color: AppConstants.primaryColor,
                                  size: 26,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 9,
                          color:
                              stale ? Colors.grey : AppConstants.successColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _freshness(l10n),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Who is bringing the order, with a button to call them — the first thing
/// anyone wants when the rider seems lost or late.
class _RiderCard extends StatefulWidget {
  final String riderId;

  const _RiderCard({required this.riderId});

  @override
  State<_RiderCard> createState() => _RiderCardState();
}

class _RiderCardState extends State<_RiderCard> {
  late final Future<Map<String, dynamic>?> _rider = SupabaseService.client
      .from('profiles')
      .select('full_name, phone')
      .eq('id', widget.riderId)
      .maybeSingle()
      .catchError((Object e) {
    debugPrint('Rider lookup failed: $e');
    return null;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<Map<String, dynamic>?>(
      future: _rider,
      builder: (context, snap) {
        final name = (snap.data?['full_name'] as String?)?.trim();
        final phone = (snap.data?['phone'] as String?)?.trim();
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    AppConstants.primaryColor.withValues(alpha: 0.12),
                child: const Icon(Iconsax.truck_fast,
                    color: AppConstants.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (name == null || name.isEmpty)
                          ? l10n.trackingRiderFallback
                          : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      l10n.trackingRiderOnWay,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (phone != null && phone.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () async {
                    final ok = await LaunchActions.call(phone);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(l10n.trackingCallFailed,
                                maxLines: 1, overflow: TextOverflow.ellipsis)),
                      );
                    }
                  },
                  icon: const Icon(Iconsax.call, size: 16),
                  label: Text(l10n.trackingCallRider,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
            ],
          ),
        );
      },
    );
  }
}
