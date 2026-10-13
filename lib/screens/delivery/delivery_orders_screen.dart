import 'dart:async';

import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/format.dart';
import '../../utils/launch_actions.dart';
import '../../utils/safe_state.dart';
import '../../widgets/live_entrance.dart';
import '../../widgets/role_common.dart';
import '../../widgets/run_stops.dart';
import '../../widgets/pressable.dart';
import 'delivery_navigate_screen.dart';

/// Full delivery job list — "My Deliveries" (claimed, in progress) and
/// "Available" (ready for pickup, unclaimed) as two tabs, instead of both
/// being squeezed into the dashboard's scroll.
class DeliveryOrdersScreen extends StatefulWidget {
  const DeliveryOrdersScreen({super.key});

  @override
  State<DeliveryOrdersScreen> createState() => _DeliveryOrdersScreenState();
}

class _DeliveryOrdersScreenState extends State<DeliveryOrdersScreen> {
  bool _isLoading = true;

  /// Which runs the list shows — the row of chips across the top: 'all',
  /// 'ready_for_pickup' (the open pool), 'out_for_delivery' (in hand) or
  /// 'delivered' (done).
  String _filter = 'all';

  bool _searching = false;
  final _searchController = TextEditingController();
  String _query = '';

  /// Whether the last load failed. Runs that could not be fetched are not
  /// "no runs", and the screen says so rather than looking empty.
  bool _loadFailed = false;

  List<Map<String, dynamic>> _available = [];
  List<Map<String, dynamic>> _mine = [];

  /// Runs this partner has already completed — there was nowhere in the app
  /// a rider could look this up before.
  List<Map<String, dynamic>> _history = [];

  /// The pickup store for each run, by the seller's id — a rider must know
  /// where to collect an order from before they can decide whether to take
  /// it, or find the place once they have.
  Map<String, Map<String, dynamic>> _storeByOwner = {};

  /// The customer's phone, by their id — only fetched and shown for runs
  /// already claimed, not for the "Available" list, which is not this
  /// rider's delivery yet.
  Map<String, String?> _phoneByCustomer = {};

  /// Rows an entrance animation has already played for, so a reload from
  /// the realtime watch below doesn't replay it for a run already on
  /// screen — only a genuinely new or newly-available one gets it.
  final Set<String> _seenIds = {};

  StreamSubscription<List<Map<String, dynamic>>>? _availableWatch;
  StreamSubscription<List<Map<String, dynamic>>>? _mineWatch;
  Timer? _reloadDebounce;

  @override
  void initState() {
    super.initState();
    _load();
    _watchLive();
  }

  /// A run becoming available, being claimed by another partner, or one of
  /// this partner's own runs changing status used to only reach this screen
  /// on the next pull-to-refresh; these two watches turn any of that into an
  /// immediate reload. Coalesced behind [_reloadDebounce] since claiming a
  /// run touches the row that both watches are looking at, and would
  /// otherwise fire it twice back to back.
  void _watchLive() {
    final userId = context.read<AuthProvider>().userId;
    if (userId.isEmpty) return;
    _availableWatch = SupabaseService.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('status', 'ready_for_pickup')
        .listen(
          (_) => _debouncedReload(),
          onError: (Object e) => debugPrint('Available runs watch failed: $e'),
        );
    _mineWatch = SupabaseService.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('delivery_id', userId)
        .listen(
          (_) => _debouncedReload(),
          onError: (Object e) => debugPrint('My runs watch failed: $e'),
        );
  }

  void _debouncedReload() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _availableWatch?.cancel();
    _mineWatch?.cancel();
    _reloadDebounce?.cancel();
    super.dispose();
  }

  static const _runColumns = 'id, delivery_address, delivery_latitude, '
      'delivery_longitude, delivery_note, total_amount, status, seller_id, '
      'payment_method, created_at, '
      'order_items(quantity, product_name, variant_name, price)';

  /// [silent] is set by the realtime watches: a background refresh should
  /// update the lists in place, not flash the full-screen loading spinner
  /// over a page the rider is already looking at.
  Future<void> _load({bool silent = false}) async {
    final userId = context.read<AuthProvider>().userId;
    safeSetState(() {
      if (!silent) _isLoading = true;
      _loadFailed = false;
    });
    try {
      final available = await SupabaseService.client
          .from('orders')
          .select(_runColumns)
          .eq('status', 'ready_for_pickup')
          .isFilter('delivery_id', null);
      final mine = await SupabaseService.client
          .from('orders')
          .select('$_runColumns, delivery_fee, customer_id')
          .eq('delivery_id', userId)
          .neq('status', 'delivered');
      final history = await SupabaseService.client
          .from('orders')
          .select(_runColumns)
          .eq('delivery_id', userId)
          .eq('status', 'delivered')
          .order('created_at', ascending: false)
          .limit(100);
      final availableList = List<Map<String, dynamic>>.from(available);
      final mineList = List<Map<String, dynamic>>.from(mine);
      final historyList = List<Map<String, dynamic>>.from(history);

      // Best-effort: the pickup address and the customer's phone make a
      // run easier to act on, but a run is still a run without them — a
      // failure here must not blank out orders that loaded just fine.
      final storeByOwner = <String, Map<String, dynamic>>{};
      final phoneByCustomer = <String, String?>{};
      try {
        final sellerIds = {
          for (final o in [...availableList, ...mineList, ...historyList])
            if (o['seller_id'] != null) o['seller_id'] as String,
        };
        if (sellerIds.isNotEmpty) {
          final stores = await SupabaseService.client
              .from('stores')
              .select('owner_id, name, address, lat, lng')
              .inFilter('owner_id', sellerIds.toList());
          for (final s in List<Map<String, dynamic>>.from(stores)) {
            storeByOwner[s['owner_id'] as String] = s;
          }
        }

        final customerIds = {
          for (final o in mineList)
            if (o['customer_id'] != null) o['customer_id'] as String,
        };
        if (customerIds.isNotEmpty) {
          final customers = await SupabaseService.client
              .from('profiles')
              .select('id, phone')
              .inFilter('id', customerIds.toList());
          for (final c in List<Map<String, dynamic>>.from(customers)) {
            phoneByCustomer[c['id'] as String] = c['phone'] as String?;
          }
        }
      } catch (e) {
        debugPrint('Run pickup/contact lookup failed: $e');
      }

      safeSetState(() {
        _available = availableList;
        _mine = mineList;
        _history = historyList;
        _storeByOwner = storeByOwner;
        _phoneByCustomer = phoneByCustomer;
      });
    } catch (_) {
      // A silent background refresh failing must not blank out a list that
      // loaded fine a moment ago — it just tries again on the next event.
      if (!silent) safeSetState(() => _loadFailed = true);
    }
    if (!silent) safeSetState(() => _isLoading = false);
  }

  Future<void> _claim(String orderId) async {
    final l10n = AppLocalizations.of(context);
    final userId = context.read<AuthProvider>().userId;
    try {
      // `.select('id')` returns only the rows the update actually touched —
      // an empty result means another partner claimed this run first, which
      // is a different story from a network failure.
      final claimed = await SupabaseService.client
          .from('orders')
          .update({'delivery_id': userId, 'status': 'out_for_delivery'})
          .eq('id', orderId)
          .isFilter('delivery_id', null)
          .select('id');
      if (claimed.isEmpty && mounted) {
        roleSay(context, l10n.deliveryOrdersClaimLost);
      }
      _load();
    } catch (_) {
      if (mounted) {
        roleSay(context, l10n.deliveryOrdersAcceptFailed);
      }
    }
  }

  Future<void> _markDelivered(String orderId, int deliveryFee) async {
    final l10n = AppLocalizations.of(context);
    final partnerId = context.read<AuthProvider>().userId;
    try {
      await SupabaseService.client
          .from('orders')
          .update({'status': 'delivered'}).eq('id', orderId);
    } catch (_) {
      if (mounted) {
        roleSay(context, l10n.deliveryOrdersMarkDeliveredFailed);
      }
      return;
    }
    if (deliveryFee > 0) {
      try {
        await SupabaseService.client.from('delivery_earnings').insert({
          'partner_id': partnerId,
          'order_id': orderId,
          'amount': deliveryFee,
          'note': 'Delivery fee',
        });
      } catch (_) {
        // The delivery itself is done — only its earnings record is
        // missing. That is an admin fix, and the partner must know to ask
        // for it rather than losing the fee in silence.
        if (mounted) {
          roleSay(context, l10n.deliveryOrdersFeeNotRecorded);
        }
      }
    }
    _load();
  }

  Future<void> _call(String? phone) async {
    final l10n = AppLocalizations.of(context);
    if (phone == null || phone.trim().isEmpty) return;
    final ok = await LaunchActions.call(phone);
    if (!ok && mounted) roleSay(context, l10n.deliveryOrdersCallFailed);
  }

  /// Directions to wherever this run needs the partner next: the store,
  /// before it's picked up; the customer, once it's on the way to them.
  /// Opens the app's own map (the same OpenStreetMap tiles the customer's
  /// tracking screen uses) rather than handing the rider off to whatever
  /// maps app their phone happens to have.
  void _navigate(Map<String, dynamic> o, {required bool isMine}) {
    final l10n = AppLocalizations.of(context);
    final double? lat;
    final double? lng;
    final String? address;
    final String title;
    if (isMine) {
      lat = (o['delivery_latitude'] as num?)?.toDouble();
      lng = (o['delivery_longitude'] as num?)?.toDouble();
      address = o['delivery_address'] as String?;
      title = l10n.deliveryOrdersNavigateToCustomer;
    } else {
      final store = _storeByOwner[o['seller_id'] as String?];
      lat = (store?['lat'] as num?)?.toDouble();
      lng = (store?['lng'] as num?)?.toDouble();
      address = store?['address'] as String?;
      title = (store?['name'] as String?) ?? l10n.deliveryOrdersNavigateToStore;
    }
    if (lat == null || lng == null) {
      roleSay(context, l10n.deliveryOrdersNavigateFailed);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryNavigateScreen(
          destLat: lat!,
          destLng: lng!,
          title: title,
          address: address,
        ),
      ),
    );
  }

  String _stamp(String? iso) {
    final at = DateTime.tryParse(iso ?? '')?.toLocal();
    if (at == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    return '${two(at.day)}-${two(at.month)}-${at.year} '
        '${two(hour)}:${two(at.minute)} ${at.hour < 12 ? 'AM' : 'PM'}';
  }

  /// Every run on one list, newest first, each marked with where it
  /// stands for this rider.
  List<(Map<String, dynamic>, String)> get _runs {
    final all = <(Map<String, dynamic>, String)>[
      for (final o in _available) (o, 'ready_for_pickup'),
      for (final o in _mine)
        if (o['status'] != 'cancelled') (o, 'out_for_delivery'),
      for (final o in _history) (o, 'delivered'),
    ];
    all.sort((a, b) => ((b.$1['created_at'] as String?) ?? '')
        .compareTo((a.$1['created_at'] as String?) ?? ''));
    return all;
  }

  List<(Map<String, dynamic>, String)> _visible() {
    final q = _query.trim().toLowerCase();
    return _runs.where((r) {
      if (_filter != 'all' && r.$2 != _filter) return false;
      if (q.isEmpty) return true;
      final o = r.$1;
      final items = (o['order_items'] as List?) ?? const [];
      return (o['id'] as String).toLowerCase().startsWith(q) ||
          ((o['delivery_address'] as String?) ?? '')
              .toLowerCase()
              .contains(q) ||
          items.any((i) =>
              ((i['product_name'] as String?) ?? '').toLowerCase().contains(q));
    }).toList();
  }

  String _stageLabel(String stage, AppLocalizations l10n) {
    switch (stage) {
      case 'ready_for_pickup':
        return l10n.deliveryOrdersReadyForPickup;
      case 'out_for_delivery':
        return l10n.deliveryDashOutForDelivery;
      default:
        return l10n.deliveryDashDeliveredLegend;
    }
  }

  Color _stageColor(String stage) {
    switch (stage) {
      case 'ready_for_pickup':
        return AppConstants.primaryColor;
      case 'out_for_delivery':
        return const Color(0xFF1E88E5);
      default:
        return AppConstants.successColor;
    }
  }

  /// One run, the way partner apps lay it out: its number and time with
  /// where it stands, what is in it, how it is paid — and, for cash on a
  /// run not yet handed over, the amount to collect at the door.
  Widget _orderCard(Map<String, dynamic> o, String stage) {
    final l10n = AppLocalizations.of(context);
    final isMine = stage == 'out_for_delivery';
    final historic = stage == 'delivered';
    final store = _storeByOwner[o['seller_id'] as String?];
    final storeName = store?['name'] as String?;
    final items = ((o['order_items'] as List?) ?? const [])
        .map((i) => Map<String, dynamic>.from(i as Map))
        .toList();
    final note = (o['delivery_note'] as String?)?.trim();
    final phone = isMine ? _phoneByCustomer[o['customer_id'] as String?] : null;
    final cod = o['payment_method'] == 'cod';
    final total = (o['total_amount'] as num?) ?? 0;
    const shown = 2;
    const divider = Divider(height: 24, color: Color(0xFFEBEBEB));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.deliveryOrdersNumber(
                    (o['id'] as String).substring(0, 8).toUpperCase(),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _stageLabel(stage, l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _stageColor(stage),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _stamp(o['created_at'] as String?),
            style: const TextStyle(
              fontSize: 13,
              color: AppConstants.textSecondaryColor,
            ),
          ),
          divider,
          for (final i in items.take(shown))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${i['quantity'] ?? 1} x ${i['product_name'] ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14.5),
                        ),
                        if (((i['variant_name'] as String?) ?? '')
                            .trim()
                            .isNotEmpty)
                          Text(
                            l10n.deliveryOrdersPackSize(
                              (i['variant_name'] as String).trim(),
                            ),
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
                  const SizedBox(width: 8),
                  Text(
                    formatRupees(
                      ((i['price'] as num?) ?? 0) *
                          ((i['quantity'] as num?) ?? 1),
                    ),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          if (items.length > shown)
            Text(
              l10n.deliveryOrdersMoreItems(items.length - shown),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppConstants.primaryColor,
              ),
            ),
          if (!historic) ...[
            divider,
            RunStops(
              pickLabel: l10n.deliveryOrdersPickFrom,
              pickTitle: (storeName != null && storeName.isNotEmpty)
                  ? storeName
                  : l10n.deliveryOrdersStoreFallback,
              pickAddress: store?['address'] as String?,
              dropLabel: l10n.deliveryOrdersDeliverTo,
              dropAddress:
                  o['delivery_address'] as String? ?? l10n.deliveryNoAddress,
            ),
          ],
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l10n.deliveryOrdersNote(note),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: AppConstants.textSecondaryColor,
              ),
            ),
          ],
          divider,
          Row(
            children: [
              Expanded(
                child: Text(
                  cod
                      ? (historic
                          ? l10n.deliveryOrdersPaidCod
                          : l10n.deliveryOrdersPayCod)
                      : l10n.deliveryOrdersPaidOnline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
              ),
              Text(
                formatRupees(total),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (cod && isMine) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppConstants.primaryColor.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.deliveryOrdersCollect,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ),
                  Text(
                    formatRupees(total),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!historic) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Pressable(
                    child: OutlinedButton.icon(
                      onPressed: () => _navigate(o, isMine: isMine),
                      icon: const Icon(Iconsax.routing, size: 16),
                      label: Text(
                        l10n.deliveryOrdersNavigate,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                if (isMine && phone != null && phone.trim().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Pressable(
                      child: OutlinedButton.icon(
                        onPressed: () => _call(phone),
                        icon: const Icon(Iconsax.call, size: 16),
                        label: Text(
                          l10n.deliveryOrdersCall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Expanded(
                  child: isMine
                      ? Pressable(
                          child: ElevatedButton(
                            onPressed: () => _markDelivered(
                              o['id'] as String,
                              (o['delivery_fee'] as num?)?.toInt() ?? 0,
                            ),
                            child: Text(
                              l10n.deliveryDelivered,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                      : Pressable(
                          child: ElevatedButton(
                            onPressed: () => _claim(o['id'] as String),
                            child: Text(
                              l10n.deliveryAccept,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final runs = _visible();
    final chips = <(String, String)>[
      ('all', l10n.deliveryOrdersChipAll),
      ('ready_for_pickup', l10n.deliveryOrdersReadyForPickup),
      ('out_for_delivery', l10n.deliveryDashOutForDelivery),
      ('delivered', l10n.deliveryDashDeliveredLegend),
    ];
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  SizedBox(
                    height: 60,
                    child: Row(
                      children: [
                        if (Navigator.canPop(context))
                          IconButton(
                            icon: const Icon(Iconsax.arrow_left_copy),
                            onPressed: () => Navigator.maybePop(context),
                          )
                        else
                          const SizedBox(width: 16),
                        Expanded(
                          child: _searching
                              ? TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  onChanged: (v) =>
                                      safeSetState(() => _query = v),
                                  decoration: InputDecoration(
                                    hintText: l10n.deliveryOrdersSearchHint,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                  ),
                                )
                              : Text(
                                  l10n.deliveryOrdersTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                        IconButton(
                          icon: Icon(
                            _searching
                                ? Iconsax.close_circle
                                : Iconsax.search_normal_1,
                          ),
                          onPressed: () => safeSetState(() {
                            _searching = !_searching;
                            _query = '';
                            _searchController.clear();
                          }),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 56,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                      itemCount: chips.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final (key, label) = chips[i];
                        final on = _filter == key;
                        return Pressable(
                          child: GestureDetector(
                            onTap: () => safeSetState(() => _filter = key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: on
                                    ? AppConstants.primaryColor
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: on
                                      ? AppConstants.primaryColor
                                      : const Color(0xFFE0E0E0),
                                ),
                              ),
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: on
                                      ? Colors.white
                                      : AppConstants.textPrimaryColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RoleBody(
              loading: _isLoading,
              loadingMessage: l10n.deliveryOrdersLoading,
              failed: _loadFailed,
              errorTitle: l10n.deliveryOrdersLoadFailed,
              onRetry: _load,
              child: RefreshIndicator(
                onRefresh: _load,
                child: runs.isEmpty
                    ? RoleEmpty(
                        icon: Iconsax.box,
                        title: l10n.deliveryOrdersEmptyTitle,
                        message: l10n.deliveryOrdersEmptyBody,
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          for (final (o, stage) in runs)
                            LiveEntrance(
                              key: ValueKey('${stage}_${o['id']}'),
                              id: '${stage}_${o['id']}',
                              seen: _seenIds,
                              child: _orderCard(o, stage),
                            ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
