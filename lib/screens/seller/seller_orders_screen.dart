import 'dart:async';

import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../utils/format.dart';
import '../../utils/safe_state.dart';
import '../../widgets/live_entrance.dart';
import '../../widgets/role_common.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../widgets/pressable.dart';
import '../../utils/tokens.dart';

/// Lets a seller move their own orders through the fulfillment pipeline
/// (pending -> confirmed -> preparing -> ready_for_pickup), at which point
/// a delivery partner claims it from the delivery dashboard. Every status
/// write here also fires the existing `notify_order_status` /
/// `set_order_commission` triggers, so the customer gets notified and
/// payout/commission is computed automatically on delivery.
class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  static const _activeStatuses = [
    'pending',
    'confirmed',
    'preparing',
    'ready_for_pickup',
    'out_for_delivery',
  ];

  bool _isLoading = true;

  /// Whether the last load failed. Orders that could not be fetched are not
  /// "no orders", and the screen says so rather than looking empty.
  bool _loadFailed = false;

  /// Which orders the list shows: 'active' (still to be handled), 'all',
  /// or one status — the row of chips across the top.
  String _filter = 'active';

  final _searchController = TextEditingController();
  String _query = '';

  /// Only orders placed in this range, when set.
  DateTimeRange? _range;
  List<Map<String, dynamic>> _orders = [];
  final Set<String> _updatingIds = {};

  /// Rows an entrance animation has already played for, so a background
  /// reload from the realtime watch doesn't replay it for an order already
  /// on screen — only a genuinely new or newly-changed one gets it.
  final Set<String> _seenIds = {};

  StreamSubscription<List<Map<String, dynamic>>>? _watch;
  Timer? _reloadDebounce;

  @override
  void initState() {
    super.initState();
    _load();
    _watchLive();
  }

  /// A new order landing, or its status changing from elsewhere (the
  /// customer cancelling, a rider marking it delivered), used to only reach
  /// this screen on the next pull-to-refresh — this turns either into an
  /// immediate, silent reload.
  void _watchLive() {
    final userId = context.read<AuthProvider>().userId;
    if (userId.isEmpty) return;
    _watch = SupabaseService.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('seller_id', userId)
        .listen(
          (_) {
            _reloadDebounce?.cancel();
            _reloadDebounce = Timer(
              const Duration(milliseconds: 400),
              () => _load(silent: true),
            );
          },
          onError: (Object e) => debugPrint('Seller orders watch failed: $e'),
        );
  }

  @override
  void dispose() {
    _watch?.cancel();
    _reloadDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// [silent] is set by the realtime watch: a background refresh should
  /// update the list in place, not flash the full-screen loading spinner
  /// over a page the seller is already looking at.
  Future<void> _load({bool silent = false}) async {
    final userId = context.read<AuthProvider>().userId;
    safeSetState(() {
      if (!silent) _isLoading = true;
      _loadFailed = false;
    });
    try {
      final rows = await SupabaseService.client
          .from('orders')
          .select(
            'id, status, total_amount, delivery_address, created_at, '
            'order_items(quantity, product_name)',
          )
          .eq('seller_id', userId)
          .order('created_at', ascending: false);
      safeSetState(() => _orders = List<Map<String, dynamic>>.from(rows));
    } catch (_) {
      // A silent background refresh failing must not blank out a list that
      // loaded fine a moment ago — it just tries again on the next event.
      if (!silent) safeSetState(() => _loadFailed = true);
    }
    if (!silent) safeSetState(() => _isLoading = false);
  }

  String? _nextStatus(String status) {
    switch (status) {
      case 'pending':
        return 'confirmed';
      case 'confirmed':
        return 'preparing';
      case 'preparing':
        return 'ready_for_pickup';
      default:
        return null;
    }
  }

  String _nextActionLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'pending':
        return l10n.sellerOrdersConfirm;
      case 'confirmed':
        return l10n.sellerOrdersPreparing;
      case 'preparing':
        return l10n.sellerOrdersReady;
      default:
        return '';
    }
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    safeSetState(() => _updatingIds.add(orderId));
    try {
      await SupabaseService.client
          .from('orders')
          .update({'status': newStatus}).eq('id', orderId);
      // Silent: the row already shows its own spinner via _updatingIds: a
      // full-page one on top of it would be a second, redundant loading
      // state for the same action.
      await _load(silent: true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context).sellerOrdersUpdateFailed,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
        );
      }
    } finally {
      if (mounted) safeSetState(() => _updatingIds.remove(orderId));
    }
  }

  Future<void> _confirmCancel(String orderId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.sellerOrdersCancelTitle),
        content: Text(l10n.sellerOrdersCancelBody),
        actions: [
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.sellerOrdersNo,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
          Pressable(
              child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.dangerColor,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.sellerOrdersCancelConfirm,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
        ],
      ),
    );
    if (confirmed == true) await _updateStatus(orderId, 'cancelled');
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return AppConstants.successColor;
      case 'cancelled':
        return AppConstants.dangerColor;
      case 'out_for_delivery':
      case 'ready_for_pickup':
        return AppConstants.primaryColor;
      default:
        return Colors.orange;
    }
  }

  /// The steps an order goes through, in order; cancelled is off the path.
  static const _steps = [
    'pending',
    'confirmed',
    'preparing',
    'ready_for_pickup',
    'out_for_delivery',
    'delivered',
  ];

  /// "5 min ago", "3 h ago", or the date once it is older than a day.
  /// The card's title: the first product's name, plus how many others are in
  /// the same order — the order id used to sit here, but a shopper's own
  /// item is what a seller is scanning the list for, not the id.
  String _leadName(List items, AppLocalizations l10n) {
    final first = items.isEmpty
        ? l10n.sellerOrdersItemFallback
        : (items.first['product_name'] as String? ??
            l10n.sellerOrdersItemFallback);
    final rest = items.length - 1;
    return rest > 0
        ? l10n.sellerOrdersMoreItems(rest).replaceFirst(
              RegExp(r'^\+'),
              '$first + ',
            )
        : first;
  }

  String _ago(AppLocalizations l10n, String? iso) {
    final at = DateTime.tryParse(iso ?? '')?.toLocal();
    if (at == null) return '';
    final d = DateTime.now().difference(at);
    if (d.inMinutes < 1) return l10n.sellerOrdersJustNow;
    if (d.inMinutes < 60) return l10n.sellerOrdersMinutesAgo(d.inMinutes);
    if (d.inHours < 24) return l10n.sellerOrdersHoursAgo(d.inHours);
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
    return '${at.day} ${months[at.month - 1]}';
  }

  /// What happens next when it is not the seller's move.
  String? _waitingNote(String status, AppLocalizations l10n) {
    switch (status) {
      case 'ready_for_pickup':
        return l10n.sellerOrdersWaitingPickup;
      case 'out_for_delivery':
        return l10n.sellerOrdersOnTheWay;
      default:
        return null;
    }
  }

  /// A thin bar of the order's steps, filled up to where it is.
  Widget _progress(String status) {
    final at = _steps.indexOf(status);
    if (at < 0) return const SizedBox.shrink();
    return Row(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i <= at ? _statusColor(status) : const Color(0xFFEFEFEF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i < _steps.length - 1) const SizedBox(width: 3),
        ],
      ],
    );
  }

  /// The orders the chips, the search box and the dates leave in view.
  List<Map<String, dynamic>> _visible() {
    final q = _query.trim().toLowerCase();
    return _orders.where((o) {
      final status = o['status'] as String? ?? 'pending';
      if (_filter == 'active' && !_activeStatuses.contains(status)) {
        return false;
      }
      if (_filter != 'active' && _filter != 'all' && status != _filter) {
        return false;
      }
      if (_range != null) {
        final at = DateTime.tryParse(o['created_at'] as String? ?? '');
        if (at == null) return false;
        final day = DateUtils.dateOnly(at.toLocal());
        if (day.isBefore(_range!.start) || day.isAfter(_range!.end)) {
          return false;
        }
      }
      if (q.isEmpty) return true;
      final items = (o['order_items'] as List?) ?? const [];
      return (o['id'] as String).toLowerCase().startsWith(q) ||
          ((o['delivery_address'] as String?) ?? '')
              .toLowerCase()
              .contains(q) ||
          items.any((i) =>
              ((i['product_name'] as String?) ?? '').toLowerCase().contains(q));
    }).toList();
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _range,
    );
    if (picked != null) safeSetState(() => _range = picked);
  }

  String _rangeLabel(DateTimeRange r) {
    String d(DateTime t) => '${t.day}/${t.month}';
    return '${d(r.start)} – ${d(r.end)}';
  }

  /// Search, the dates, and a chip per status with how many orders it has.
  Widget _filters(AppLocalizations l10n) {
    int count(String f) => _orders.where((o) {
          final status = o['status'] as String? ?? 'pending';
          if (f == 'all') return true;
          if (f == 'active') return _activeStatuses.contains(status);
          return status == f;
        }).length;
    final chips = <(String, String)>[
      ('active', l10n.sellerOrdersChipActive),
      ('all', l10n.sellerOrdersChipAll),
      for (final st in [..._steps, 'cancelled']) (st, _statusLabel(st)),
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => safeSetState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: l10n.sellerOrdersSearchHint,
                    prefixIcon: const Icon(Iconsax.search_normal_1, size: 20),
                    isDense: true,
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Iconsax.close_circle, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              safeSetState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Pressable(
                child: OutlinedButton.icon(
                  onPressed: _pickRange,
                  icon: const Icon(Iconsax.calendar_1, size: 18),
                  label: Text(
                    _range == null
                        ? l10n.sellerOrdersDates
                        : _rangeLabel(_range!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    foregroundColor: AppConstants.primaryColor,
                    side: BorderSide(
                      color: _range == null
                          ? const Color(0xFFE4E4E4)
                          : AppConstants.primaryColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (_range != null)
                IconButton(
                  tooltip: l10n.sellerOrdersClearDates,
                  onPressed: () => safeSetState(() => _range = null),
                  icon: const Icon(Iconsax.close_circle, size: 20),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final (key, label) = chips[i];
              return ChoiceChip(
                label: Text(
                  '$label (${count(key)})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                selected: _filter == key,
                showCheckmark: false,
                onSelected: (_) => safeSetState(() => _filter = key),
              );
            },
          ),
        ),
      ],
    );
  }

  String _statusLabel(String status) {
    return status
        .split('_')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visibleOrders = _visible();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
        title: Text(l10n.sellerOrdersTitle,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: RoleBody(
        loading: _isLoading,
        loadingMessage: l10n.sellerOrdersLoading,
        failed: _loadFailed,
        errorTitle: l10n.sellerOrdersLoadFailed,
        onRetry: _load,
        child: Column(
          children: [
            _filters(l10n),
            Expanded(
              child: visibleOrders.isEmpty
                  ? RoleEmpty(
                      icon: Iconsax.receipt,
                      title: l10n.sellerOrdersEmptyTitle,
                      message: l10n.sellerOrdersEmptyBody,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: visibleOrders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final o = visibleOrders[index];
                          final id = o['id'] as String;
                          final status = o['status'] as String? ?? 'pending';
                          final nextStatus = _nextStatus(status);
                          final isUpdating = _updatingIds.contains(id);
                          final items = (o['order_items'] as List?) ?? [];
                          final canCancel =
                              status == 'pending' || status == 'confirmed';
                          final units = items.fold<int>(
                            0,
                            (n, i) =>
                                n + ((i['quantity'] as num?)?.toInt() ?? 0),
                          );
                          const shown = 3;
                          final waiting = _waitingNote(status, l10n);

                          return LiveEntrance(
                            key: ValueKey(id),
                            id: id,
                            seen: _seenIds,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _leadName(items, l10n),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${_ago(l10n, o['created_at'] as String?)}'
                                              ' · ${l10n.sellerOrdersItemCount(units)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppConstants
                                                    .textSecondaryColor,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              l10n.sellerOrdersOrderNumber(
                                                id.substring(0, 8),
                                              ),
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                color: AppConstants
                                                    .textSecondaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _statusColor(
                                            status,
                                          ).withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _statusLabel(status),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _statusColor(status),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  _progress(status),
                                  const SizedBox(height: AppSpacing.sm),
                                  for (final item in items.take(shown))
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        '${item['product_name'] ?? l10n.sellerOrdersItemFallback}'
                                        ' × ${item['quantity']}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  if (items.length > shown)
                                    Text(
                                      l10n.sellerOrdersMoreItems(
                                          items.length - shown),
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppConstants.textSecondaryColor,
                                      ),
                                    ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Iconsax.location,
                                          size: 14, color: Colors.grey[500]),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          o['delivery_address'] as String? ??
                                              '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    formatRupees(
                                        (o['total_amount'] as num?) ?? 0),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppConstants.primaryColor,
                                    ),
                                  ),
                                  if (waiting != null) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    Row(
                                      children: [
                                        const Icon(Iconsax.info_circle,
                                            size: 14,
                                            color: AppConstants
                                                .textSecondaryColor),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            waiting,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppConstants
                                                  .textSecondaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (nextStatus != null || canCancel) ...[
                                    const SizedBox(height: 10),
                                    if (isUpdating)
                                      const Align(
                                        alignment: Alignment.centerRight,
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    else
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          if (canCancel)
                                            Pressable(
                                                child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    AppConstants.dangerColor,
                                              ),
                                              onPressed: () =>
                                                  _confirmCancel(id),
                                              child: Text(
                                                  l10n.sellerOrdersCancel,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            )),
                                          if (nextStatus != null) ...[
                                            const SizedBox(width: 8),
                                            Pressable(
                                                child: ElevatedButton(
                                              onPressed: () =>
                                                  _updateStatus(id, nextStatus),
                                              child: Text(
                                                  _nextActionLabel(
                                                      status, l10n),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            )),
                                          ],
                                        ],
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
