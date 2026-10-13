import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/location_tracking_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/format.dart';
import '../../utils/launch_actions.dart';
import '../../utils/safe_state.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/live_entrance.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/pressable.dart';
import '../../widgets/role_bottom_nav.dart';
import '../../widgets/role_common.dart';
import '../../widgets/run_stops.dart';
import 'delivery_earnings_screen.dart';
import 'delivery_more_screen.dart';
import 'delivery_navigate_screen.dart';
import 'delivery_orders_screen.dart';

/// The delivery partner's Home tab: online toggle, today's numbers, the
/// runs in hand (with directions, a call button and "Delivered"), and the
/// orders waiting for pickup — with the store to collect from and what the
/// run pays. Kept live: a new order, or one claimed by someone else, shows
/// up here without a pull-to-refresh.
class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() =>
      _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _available = [];
  List<Map<String, dynamic>> _mine = [];
  double? _avgRating;
  int _ratingCount = 0;
  double _totalEarnings = 0;
  double _todayEarnings = 0;
  int _todayRuns = 0;

  /// Every order this rider has had, for the day's and all-time counts,
  /// the cash taken on cash-on-delivery ones and the status chart.
  List<Map<String, dynamic>> _all = [];

  /// Earned and not yet paid out or asked for (payout_balance()).
  double? _balance;

  /// Every earning, for the earnings chart.
  List<(DateTime, double)> _earningEntries = [];

  /// How far back the earnings chart looks: 7 or 30 days.
  int _chartDays = 7;

  /// Pickup store (name, address) by the seller's id, and the customer's
  /// phone by their id (runs in hand only).
  Map<String, Map<String, dynamic>> _stores = {};
  Map<String, String?> _phoneByCustomer = {};

  /// Told apart from "no runs yet": a partner whose load failed must not be
  /// told they have nothing to do.
  bool _loadFailed = false;

  /// Use the singleton instance so it can be disposed on logout from anywhere.
  final _locationTracking = LocationTrackingService.instance;
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

  @override
  void dispose() {
    _availableWatch?.cancel();
    _mineWatch?.cancel();
    _reloadDebounce?.cancel();
    _locationTracking.dispose();
    super.dispose();
  }

  /// A run becoming available, being taken by another partner, or one of
  /// this partner's own runs changing turns into a quiet reload.
  void _watchLive() {
    final userId = context.read<AuthProvider>().userId;
    if (userId.isEmpty) return;
    void reload(_) {
      _reloadDebounce?.cancel();
      _reloadDebounce =
          Timer(const Duration(milliseconds: 400), () => _load(silent: true));
    }

    _availableWatch = SupabaseService.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('status', 'ready_for_pickup')
        .listen(reload,
            onError: (Object e) => debugPrint('Dashboard watch failed: $e'));
    _mineWatch = SupabaseService.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('delivery_id', userId)
        .listen(reload,
            onError: (Object e) => debugPrint('Dashboard watch failed: $e'));
  }

  /// [silent]: a background refresh from the live watch updates in place
  /// instead of flashing the loading screen.
  Future<void> _load({bool silent = false}) async {
    final userId = context.read<AuthProvider>().userId;
    safeSetState(() {
      if (!silent) _isLoading = true;
      _loadFailed = false;
    });
    try {
      final available = await SupabaseService.client
          .from('orders')
          .select('id, delivery_address, total_amount, status, delivery_fee, '
              'tip, seller_id')
          .eq('status', 'ready_for_pickup')
          .isFilter('delivery_id', null);
      final mine = await SupabaseService.client
          .from('orders')
          .select('id, delivery_address, total_amount, status, delivery_fee, '
              'delivery_latitude, delivery_longitude, customer_id, seller_id')
          .eq('delivery_id', userId)
          .neq('status', 'delivered');
      final ratings = await SupabaseService.client
          .from('delivery_ratings')
          .select('rating')
          .eq('delivery_id', userId);
      final earnings = await SupabaseService.client
          .from('delivery_earnings')
          .select('amount, created_at')
          .eq('partner_id', userId);
      final all = await SupabaseService.client
          .from('orders')
          .select('id, status, total_amount, payment_method, created_at')
          .eq('delivery_id', userId);
      final availableList = List<Map<String, dynamic>>.from(available);
      final mineList = List<Map<String, dynamic>>.from(mine);
      final ratingList = List<Map<String, dynamic>>.from(ratings);
      final earningList = List<Map<String, dynamic>>.from(earnings);

      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      double total = 0, today = 0;
      var runsToday = 0;
      for (final e in earningList) {
        final amount = (e['amount'] as num?)?.toDouble() ?? 0;
        total += amount;
        final at = DateTime.tryParse(e['created_at'] as String? ?? '');
        if (at != null && !at.toLocal().isBefore(midnight)) {
          today += amount;
          runsToday++;
        }
      }

      // Best-effort: the store name and the customer's phone make a run
      // easier to act on, but a run is still a run without them.
      final stores = <String, Map<String, dynamic>>{};
      final phoneByCustomer = <String, String?>{};
      try {
        final sellerIds = {
          for (final o in [...availableList, ...mineList])
            if (o['seller_id'] != null) o['seller_id'] as String,
        };
        if (sellerIds.isNotEmpty) {
          final rows = await SupabaseService.client
              .from('stores')
              .select('owner_id, name, address')
              .inFilter('owner_id', sellerIds.toList());
          for (final s in List<Map<String, dynamic>>.from(rows)) {
            stores[s['owner_id'] as String] = s;
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
        debugPrint('Dashboard store/contact lookup failed: $e');
      }

      // Best-effort too: without it the tile says "—", not a wrong number.
      double? balance;
      try {
        final rows = await SupabaseService.client.rpc('payout_balance');
        if (rows is List && rows.isNotEmpty) {
          final row = Map<String, dynamic>.from(rows.first as Map);
          final earned = (row['earned'] as num?)?.toDouble() ?? 0;
          final outstanding = (row['outstanding'] as num?)?.toDouble() ?? 0;
          balance = (earned - outstanding).clamp(0, double.infinity).toDouble();
        }
      } catch (e) {
        debugPrint('Dashboard balance lookup failed: $e');
      }

      safeSetState(() {
        _available = availableList;
        _mine = mineList;
        _ratingCount = ratingList.length;
        _avgRating = ratingList.isEmpty
            ? null
            : ratingList.fold<num>(0, (sum, r) => sum + (r['rating'] as num)) /
                ratingList.length;
        _totalEarnings = total;
        _todayEarnings = today;
        _todayRuns = runsToday;
        _stores = stores;
        _phoneByCustomer = phoneByCustomer;
        _all = List<Map<String, dynamic>>.from(all);
        _earningEntries = [
          for (final e in earningList)
            if (DateTime.tryParse(e['created_at'] as String? ?? '')
                case final at?)
              (at.toLocal(), (e['amount'] as num?)?.toDouble() ?? 0),
        ];
        _balance = balance;
      });
      final outForDelivery = _mine
          .where((o) => o['status'] == 'out_for_delivery')
          .map((o) => o['id'] as String);
      _locationTracking.syncActiveOrders(userId, outForDelivery);
    } catch (_) {
      if (!silent) safeSetState(() => _loadFailed = true);
    }
    if (!silent) safeSetState(() => _isLoading = false);
  }

  Future<void> _claim(String orderId) async {
    final l10n = AppLocalizations.of(context);
    final userId = context.read<AuthProvider>().userId;
    try {
      // Only the rows the update touched come back: none means another
      // partner got there first, which is worth saying.
      final claimed = await SupabaseService.client
          .from('orders')
          .update({'delivery_id': userId, 'status': 'out_for_delivery'})
          .eq('id', orderId)
          .isFilter('delivery_id', null)
          .select('id');
      if (claimed.isEmpty) _tell(l10n.deliveryOrdersClaimLost);
      _load(silent: true);
    } catch (_) {
      // The button looked like it did nothing; say why instead.
      _tell(l10n.deliveryDashClaimFailed);
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
      _tell(l10n.deliveryDashMarkDeliveredFailed);
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
        // The delivery is done; only its earnings record is missing.
        _tell(l10n.deliveryOrdersFeeNotRecorded);
      }
    }
    _load(silent: true);
  }

  void _navigate(Map<String, dynamic> o) {
    final l10n = AppLocalizations.of(context);
    final lat = (o['delivery_latitude'] as num?)?.toDouble();
    final lng = (o['delivery_longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) {
      _tell(l10n.deliveryOrdersNavigateFailed);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryNavigateScreen(
          destLat: lat,
          destLng: lng,
          title: l10n.deliveryOrdersNavigateToCustomer,
          address: o['delivery_address'] as String?,
        ),
      ),
    );
  }

  Future<void> _call(String phone) async {
    final ok = await LaunchActions.call(phone);
    if (!ok && mounted) {
      _tell(AppLocalizations.of(context).deliveryOrdersCallFailed);
    }
  }

  /// One line at the bottom of the screen, used for the things a partner
  /// does with a button where the request can fail.
  void _tell(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
        .then((_) => _load(silent: true));
  }

  void _goToTab(int index) {
    if (index == 0) return;
    _open(switch (index) {
      1 => const DeliveryOrdersScreen(),
      2 => const DeliveryEarningsScreen(),
      _ => const DeliveryMoreScreen(),
    });
  }

  Widget _card({required Widget child}) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: child,
      );

  Widget _stops(Map<String, dynamic> o, AppLocalizations l10n) {
    final store = _stores[o['seller_id'] as String?];
    final name = (store?['name'] as String?)?.trim();
    return RunStops(
      pickLabel: l10n.deliveryOrdersPickFrom,
      pickTitle: (name != null && name.isNotEmpty)
          ? name
          : l10n.deliveryOrdersStoreFallback,
      pickAddress: store?['address'] as String?,
      dropLabel: l10n.deliveryOrdersDeliverTo,
      dropAddress: o['delivery_address'] as String? ?? l10n.deliveryNoAddress,
    );
  }

  Widget _mineCard(Map<String, dynamic> o, AppLocalizations l10n) {
    final phone = _phoneByCustomer[o['customer_id'] as String?];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stops(o, l10n),
          const Divider(height: 20),
          Text(
            formatRupees((o['total_amount'] as num?) ?? 0),
            style: const TextStyle(
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Pressable(
                    child: OutlinedButton.icon(
                  onPressed: () => _navigate(o),
                  icon: const Icon(Iconsax.routing, size: 16),
                  label: Text(l10n.deliveryOrdersNavigate,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                )),
              ),
              if (phone != null && phone.trim().isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Pressable(
                      child: OutlinedButton.icon(
                    onPressed: () => _call(phone),
                    icon: const Icon(Iconsax.call, size: 16),
                    label: Text(l10n.deliveryOrdersCall,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  )),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: Pressable(
                    child: ElevatedButton(
                  onPressed: () => _markDelivered(
                    o['id'] as String,
                    (o['delivery_fee'] as num?)?.toInt() ?? 0,
                  ),
                  child: Text(l10n.deliveryDelivered,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _availableCard(
    Map<String, dynamic> o,
    AppLocalizations l10n, {
    required bool online,
  }) {
    // The customer's tip is the rider's too, so it counts in what the run
    // pays.
    final fee = ((o['delivery_fee'] as num?) ?? 0) + ((o['tip'] as num?) ?? 0);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stops(o, l10n),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.successColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n.deliveryDashYouEarn(formatRupees(fee)),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.successColor,
                      ),
                    ),
                  ),
                ),
              ),
              Pressable(
                  child: ElevatedButton(
                onPressed: online ? () => _claim(o['id'] as String) : null,
                child: Text(l10n.deliveryAccept,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _live(String key, Widget child) => LiveEntrance(
        key: ValueKey(key),
        id: key,
        seen: _seenIds,
        child: child,
      );

  bool _isToday(Map<String, dynamic> o) {
    final at = DateTime.tryParse(o['created_at'] as String? ?? '')?.toLocal();
    return at != null && DateUtils.isSameDay(at, DateTime.now());
  }

  double _amount(Map<String, dynamic> o) =>
      (o['total_amount'] as num?)?.toDouble() ?? 0;

  bool _isCashDelivered(Map<String, dynamic> o) =>
      o['payment_method'] == 'cod' && o['status'] == 'delivered';

  int _countStatus(String status) =>
      _all.where((o) => o['status'] == status).length;

  List<Map<String, dynamic>> get _activeRuns =>
      _mine.where((o) => o['status'] != 'cancelled').toList();

  /// Hi, name, email — and the Online switch, as the partner apps put it.
  Widget _header(AppLocalizations l10n, AuthProvider auth) {
    final name = auth.userName.trim();
    final first = name.isEmpty ? '' : name.split(' ').first;
    final url = auth.avatarUrl;
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: url != null && url.isNotEmpty
                    ? AppNetworkImage(url, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          first.isEmpty ? '?' : first[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.deliveryDashHi(first),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (auth.email.trim().isNotEmpty)
                      Text(
                        auth.email.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppConstants.textSecondaryColor,
                        ),
                      ),
                  ],
                ),
              ),
              const NotificationBell(),
              const SizedBox(width: 4),
              _OnlinePill(
                online: auth.isOnline,
                onLabel: l10n.deliveryDashOnlinePill,
                offLabel: l10n.deliveryDashOfflinePill,
                onChanged: (v) async {
                  // The provider flips back if the write fails; the screen
                  // explains why the switch just returned.
                  final ok = await auth.setOnlineStatus(v);
                  if (!ok && mounted) {
                    roleSay(context, l10n.deliveryDashOnlineToggleFailed);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final date = '${two(now.day)}-${two(now.month)}-${now.year}';
    final cashToday = _all
        .where((o) => _isCashDelivered(o) && _isToday(o))
        .fold<double>(0, (s, o) => s + _amount(o));
    final cashInHand =
        _all.where(_isCashDelivered).fold<double>(0, (s, o) => s + _amount(o));
    final todayOrders = _all.where(_isToday).length;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      extendBody: true,
      bottomNavigationBar: RoleBottomNav(
        currentIndex: 0,
        onTap: _goToTab,
        items: [
          (
            outline: Iconsax.home,
            filled: Iconsax.home_copy,
            label: l10n.deliveryDashNavHome,
          ),
          (
            outline: Iconsax.box,
            filled: Iconsax.box,
            label: l10n.deliveryDashNavDeliveries,
          ),
          (
            outline: Iconsax.wallet_3,
            filled: Iconsax.wallet_3,
            label: l10n.deliveryDashNavEarnings,
          ),
          (
            outline: Iconsax.profile_circle,
            filled: Iconsax.profile_circle,
            label: l10n.deliveryDashNavMore,
          ),
        ],
      ),
      body: Column(
        children: [
          _header(l10n, auth),
          Expanded(
            child: RoleBody(
              loading: _isLoading,
              loadingMessage: l10n.deliveryDashLoading,
              failed: _loadFailed,
              errorTitle: l10n.deliveryDashLoadFailed,
              onRetry: _load,
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                  children: [
                    _sectionTitle(
                      l10n.deliveryDashTodayPerformance,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              AppConstants.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          date,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.55,
                      children: [
                        _TodayTile(
                          icon: Iconsax.wallet_3,
                          value: formatRupees(_todayEarnings),
                          label: l10n.deliveryDashTodayEarnings,
                          onTap: () => _goToTab(2),
                        ),
                        _TodayTile(
                          icon: Iconsax.box_tick,
                          value: '$_todayRuns',
                          label: l10n.deliveryDashOrdersDelivered,
                        ),
                        _TodayTile(
                          icon: Iconsax.money_recive,
                          value: formatRupees(cashToday),
                          label: l10n.deliveryDashCashCollected,
                        ),
                        _TodayTile(
                          icon: Iconsax.box,
                          value: '$todayOrders',
                          label: l10n.deliveryDashTodayOrders,
                          onTap: () => _goToTab(1),
                        ),
                      ],
                    ),
                    _sectionTitle(l10n.deliveryDashOverview),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.3,
                      children: [
                        _OverviewTile(
                          icon: Iconsax.box,
                          title: l10n.deliveryDashActiveOrders,
                          value: '${_activeRuns.length}',
                          onTap: () => _goToTab(1),
                        ),
                        _OverviewTile(
                          icon: Iconsax.wallet_3,
                          title: l10n.deliveryDashAvailableBalance,
                          value:
                              _balance == null ? '—' : formatRupees(_balance!),
                          onTap: () => _goToTab(2),
                        ),
                        _OverviewTile(
                          icon: Iconsax.money_recive,
                          title: l10n.deliveryDashCashInHand,
                          value: formatRupees(cashInHand),
                        ),
                        _OverviewTile(
                          icon: Iconsax.box_1,
                          title: l10n.deliveryDashTotalOrders,
                          value: '${_all.length}',
                          onTap: () => _goToTab(1),
                        ),
                      ],
                    ),
                    _sectionTitle(l10n.deliveryDashActiveOrders),
                    _StatusChart(
                      parts: [
                        (
                          l10n.deliveryDashOutForDelivery,
                          _countStatus('out_for_delivery'),
                        ),
                        (
                          l10n.deliveryDashDeliveredLegend,
                          _countStatus('delivered'),
                        ),
                        (
                          l10n.deliveryDashCancelledLegend,
                          _countStatus('cancelled'),
                        ),
                      ],
                      leftLabel: l10n.deliveryDashTotalEarnedShort,
                      leftValue: formatRupees(_totalEarnings),
                      rightLabel: _avgRating == null
                          ? l10n.deliveryDashNoReviews
                          : l10n.deliveryDashReviewCount(_ratingCount),
                      rightValue: _avgRating == null
                          ? '—'
                          : '★ ${_avgRating!.toStringAsFixed(1)}',
                    ),
                    _sectionTitle(l10n.deliveryDashEarningsChart),
                    _EarningsChart(
                      entries: _earningEntries,
                      days: _chartDays,
                      label7: l10n.deliveryDashLast7,
                      label30: l10n.deliveryDashLast30,
                      onDays: (d) => safeSetState(() => _chartDays = d),
                    ),
                    _sectionTitle(l10n.deliveryDashPerformance),
                    _PerformanceCard(
                      total: _all.length,
                      active: _activeRuns.length,
                      delivered: _countStatus('delivered'),
                      cancelled: _countStatus('cancelled'),
                      labels: (
                        total: l10n.deliveryDashPerfTotal,
                        active: l10n.deliveryDashPerfActive,
                        delivered: l10n.deliveryDashDeliveredLegend,
                        cancelled: l10n.deliveryDashCancelledLegend,
                        success: l10n.deliveryDashSuccessRate,
                        cancelRate: l10n.deliveryDashCancelRate,
                        progress: l10n.deliveryDashInProgress,
                      ),
                    ),
                    _sectionTitle(
                      l10n.deliveryDashMyDeliveries,
                      trailing: _activeRuns.isEmpty
                          ? null
                          : Text(
                              '${_activeRuns.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                    ),
                    if (_activeRuns.isEmpty)
                      RoleEmptyNote(
                        icon: Iconsax.truck_fast,
                        message: l10n.deliveryDashNoActiveBody,
                      )
                    else
                      for (final o in _activeRuns)
                        _live('mine_${o['id']}', _mineCard(o, l10n)),
                    _sectionTitle(
                      l10n.deliveryDashAvailableOrders,
                      trailing: Pressable(
                        child: TextButton(
                          onPressed: () => _goToTab(1),
                          child: Text(
                            l10n.deliveryViewAll,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    if (!auth.isOnline)
                      RoleEmptyNote(
                        icon: Iconsax.moon,
                        message: l10n.deliveryDashOfflineNote,
                      )
                    else if (_available.isEmpty)
                      RoleEmptyNote(
                        icon: Iconsax.box,
                        message: l10n.deliveryDashNoneWaitingBody,
                      )
                    else
                      for (final o in _available.take(5))
                        _live(
                          'available_${o['id']}',
                          _availableCard(o, l10n, online: auth.isOnline),
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

/// The Online / Offline switch as a pill: orange with the knob on the
/// right while on duty, grey with it on the left while off.
class _OnlinePill extends StatelessWidget {
  final bool online;
  final String onLabel;
  final String offLabel;
  final ValueChanged<bool> onChanged;

  const _OnlinePill({
    required this.online,
    required this.onLabel,
    required this.offLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const knob = 26.0;
    return Pressable(
      child: GestureDetector(
        onTap: () => onChanged(!online),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 38,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: online ? AppConstants.primaryColor : const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!online) ...[
                Container(
                  width: knob,
                  height: knob,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ] else
                const SizedBox(width: 6),
              Text(
                online ? onLabel : offLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: online ? Colors.white : AppConstants.textPrimaryColor,
                ),
              ),
              if (online) ...[
                const SizedBox(width: 8),
                Container(
                  width: knob,
                  height: knob,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ] else
                const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}

/// One of the day's four figures: an icon, the number, what it counts.
class _TodayTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _TodayTile({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: AppConstants.primaryColor, size: 26),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppConstants.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A Delivery Overview figure: a grey round icon, then what it is and the
/// number under it.
class _OverviewTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _OverviewTile({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFEFEF),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppConstants.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The rider's orders by status as a half ring with its legend, and two
/// figures along the bottom.
class _StatusChart extends StatelessWidget {
  final List<(String, int)> parts;
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  const _StatusChart({
    required this.parts,
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  static const _shades = [
    AppConstants.primaryColor,
    Color(0xFFFF9D52),
    Color(0xFFFFCFA6),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 70,
                child: CustomPaint(
                  painter: _HalfRingPainter(
                    values: [for (final p in parts) p.$2],
                    colors: _shades,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < parts.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _shades[i % _shades.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                parts[i].$1,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppConstants.textSecondaryColor,
                                ),
                              ),
                            ),
                            Text(
                              '${parts[i].$2}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28, color: Color(0xFFEBEBEB)),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leftLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                    Text(
                      leftValue,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      rightLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                    Text(
                      rightValue,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HalfRingPainter extends CustomPainter {
  final List<int> values;
  final List<Color> colors;

  const _HalfRingPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 26.0;
    final radius = math.min(size.width / 2, size.height) - stroke / 2;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height),
      radius: radius,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final total = values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      paint.color = const Color(0xFFEFEFEF);
      canvas.drawArc(rect, math.pi, math.pi, false, paint);
      return;
    }
    var start = math.pi;
    for (var i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      final sweep = math.pi * values[i] / total;
      paint.color = colors[i % colors.length];
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_HalfRingPainter old) =>
      old.values.join(',') != values.join(',');
}

/// Earnings over the last 7 or 30 days as a line with a soft fill under
/// it, the period's total over it, and whether it is up or down on the
/// period before.
class _EarningsChart extends StatelessWidget {
  final List<(DateTime, double)> entries;
  final int days;
  final String label7;
  final String label30;
  final ValueChanged<int> onDays;

  const _EarningsChart({
    required this.entries,
    required this.days,
    required this.label7,
    required this.label30,
    required this.onDays,
  });

  /// What was earned on each of the [n] days ending [offset] days ago,
  /// oldest first.
  List<double> _series(int n, {int offset = 0}) {
    final today = DateUtils.dateOnly(DateTime.now());
    final out = List<double>.filled(n, 0);
    for (final (at, amount) in entries) {
      final ago = today.difference(DateUtils.dateOnly(at)).inDays - offset;
      if (ago >= 0 && ago < n) out[n - 1 - ago] += amount;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final series = _series(days);
    final total = series.fold<double>(0, (a, b) => a + b);
    final before = _series(days, offset: days).fold<double>(0, (a, b) => a + b);
    final up = total >= before;
    final today = DateUtils.dateOnly(DateTime.now());
    final first = today.subtract(Duration(days: days - 1));
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    String day(DateTime d) => '${d.day} ${months[d.month - 1]}';
    const axis = TextStyle(
      fontSize: 12.5,
      color: AppConstants.textSecondaryColor,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatRupees(total),
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                up ? Iconsax.trend_up : Iconsax.trend_down,
                color:
                    up ? AppConstants.successColor : AppConstants.dangerColor,
                size: 22,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppConstants.primaryColor.withValues(alpha: 0.5),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: days,
                    isDense: true,
                    icon: const Icon(
                      Iconsax.arrow_down_1,
                      size: 16,
                      color: AppConstants.primaryColor,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.primaryColor,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 7,
                        child: Text(label7,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 30,
                        child: Text(label30,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) onDays(v);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            width: double.infinity,
            child: CustomPaint(painter: _LinePainter(values: series)),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(day(first), style: axis),
                Text(day(today), style: axis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<double> values;

  const _LinePainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0;
    const color = AppConstants.primaryColor;
    final top = values.fold<double>(0, math.max);
    // A round scale above the highest day, in four steps.
    final step = top <= 0 ? 30.0 : ((top / 4) / 10).ceil() * 10.0;
    final scale = step * 4;
    final width = size.width - left;
    final grid = Paint()
      ..color = const Color(0xFFEFEFEF)
      ..strokeWidth = 1;
    final text = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i <= 4; i++) {
      final y = size.height - size.height * i / 4;
      if (i > 0) canvas.drawLine(Offset(left, y), Offset(size.width, y), grid);
      text.text = TextSpan(
        text: (step * i).round().toString(),
        style: const TextStyle(
          fontSize: 11,
          color: AppConstants.textSecondaryColor,
        ),
      );
      text.layout();
      text.paint(canvas, Offset(0, y - text.height / 2));
    }
    if (values.isEmpty) return;
    Offset point(int i) {
      final x = values.length == 1
          ? left + width
          : left + width * i / (values.length - 1);
      return Offset(x, size.height - size.height * values[i] / scale);
    }

    final line = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      line.lineTo(point(i).dx, point(i).dy);
    }
    final fill = Path.from(line)
      ..lineTo(point(values.length - 1).dx, size.height)
      ..lineTo(point(0).dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.02)
          ],
        ).createShader(Rect.fromLTWH(left, 0, width, size.height)),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(point(values.length - 1), 5.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.values.join(',') != values.join(',');
}

/// Total, active, delivered and cancelled across the top, then the success
/// rate, the cancellation rate and the share still in progress as bars.
class _PerformanceCard extends StatelessWidget {
  final int total;
  final int active;
  final int delivered;
  final int cancelled;
  final ({
    String total,
    String active,
    String delivered,
    String cancelled,
    String success,
    String cancelRate,
    String progress,
  }) labels;

  const _PerformanceCard({
    required this.total,
    required this.active,
    required this.delivered,
    required this.cancelled,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    double share(int n) => total == 0 ? 0 : n / total;
    Widget figure(String label, int value, CrossAxisAlignment align) =>
        Expanded(
          child: Column(
            crossAxisAlignment: align,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppConstants.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
    Widget rate(String label, double value) => Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                  ),
                  Text(
                    '${(value * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 9,
                  backgroundColor:
                      AppConstants.primaryColor.withValues(alpha: 0.12),
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              figure(labels.total, total, CrossAxisAlignment.start),
              figure(labels.active, active, CrossAxisAlignment.center),
              figure(labels.delivered, delivered, CrossAxisAlignment.center),
              figure(labels.cancelled, cancelled, CrossAxisAlignment.end),
            ],
          ),
          const Divider(height: 28, color: Color(0xFFEBEBEB)),
          rate(labels.success, share(delivered)),
          rate(labels.cancelRate, share(cancelled)),
          rate(labels.progress, share(active)),
        ],
      ),
    );
  }
}
