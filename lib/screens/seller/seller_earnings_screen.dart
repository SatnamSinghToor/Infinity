import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../utils/safe_state.dart';
import '../../utils/format.dart';
import '../../widgets/role_common.dart';
import '../payouts_screen.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../widgets/pressable.dart';
import '../../utils/tokens.dart';

/// Reads `orders.commission_amount` / `seller_payout` — both already
/// computed by the `set_order_commission` trigger whenever an order is
/// marked delivered — and totals them for this seller. No new backend
/// logic needed, just a screen to see what was previously invisible.
class SellerEarningsScreen extends StatefulWidget {
  const SellerEarningsScreen({super.key});

  @override
  State<SellerEarningsScreen> createState() => _SellerEarningsScreenState();
}

class _SellerEarningsScreenState extends State<SellerEarningsScreen> {
  bool _isLoading = true;

  /// Whether the last load failed: said out loud, with a way to try
  /// again, instead of passing off a failed request as empty.
  bool _loadFailed = false;
  List<Map<String, dynamic>> _orders = [];

  /// Which stretch of time the totals cover.
  _Period _period = _Period.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().userId;
    safeSetState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final rows = await SupabaseService.client
          .from('orders')
          .select(
            'id, total_amount, commission_amount, seller_payout, created_at',
          )
          .eq('seller_id', userId)
          .eq('status', 'delivered')
          .order('created_at', ascending: false);
      safeSetState(() => _orders = List<Map<String, dynamic>>.from(rows));
    } catch (_) {
      safeSetState(() => _loadFailed = true);
    }
    safeSetState(() => _isLoading = false);
  }

  /// The delivered orders inside [_period].
  List<Map<String, dynamic>> get _inPeriod {
    final now = DateTime.now();
    final from = switch (_period) {
      _Period.all => null,
      _Period.month => DateTime(now.year, now.month),
      _Period.week => now.subtract(const Duration(days: 7)),
    };
    if (from == null) return _orders;
    return _orders.where((o) {
      final at = DateTime.tryParse(o['created_at'] as String? ?? '');
      return at != null && !at.toLocal().isBefore(from);
    }).toList();
  }

  double _sum(List<Map<String, dynamic>> orders, String key) =>
      orders.fold<double>(
        0,
        (sum, o) => sum + ((o[key] as num?)?.toDouble() ?? 0),
      );

  static String _date(String? iso) {
    final at = DateTime.tryParse(iso ?? '')?.toLocal();
    if (at == null) return '';
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
    return '${at.day} ${months[at.month - 1]} ${at.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final orders = _inPeriod;
    final totalPayout = _sum(orders, 'seller_payout');
    final totalCommission = _sum(orders, 'commission_amount');
    final totalSales = _sum(orders, 'total_amount');

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
          title: Text(l10n.sellerEarningsTitle,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          centerTitle: true),
      body: RoleBody(
        loading: _isLoading,
        loadingMessage: l10n.sellerEarningsLoading,
        failed: _loadFailed,
        errorTitle: l10n.sellerEarningsLoadFailed,
        onRetry: _load,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Which stretch of time every number below covers.
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final p in _Period.values)
                    ChoiceChip(
                      label: Text(
                        switch (p) {
                          _Period.all => l10n.sellerEarningsAllTime,
                          _Period.month => l10n.sellerEarningsThisMonth,
                          _Period.week => l10n.sellerEarningsLast7Days,
                        },
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      selected: _period == p,
                      onSelected: (_) => safeSetState(() => _period = p),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF435965),
                      Color(0xFF607783),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.sellerEarningsNetPayout,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatRupees(totalPayout),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.sellerEarningsFromOrders(orders.length),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RoleStatCard(
                      label: l10n.sellerEarningsTotalSales,
                      value: formatRupees(totalSales),
                      icon: Iconsax.receipt,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RoleStatCard(
                      label: l10n.sellerEarningsCommissionPaid,
                      value: formatRupees(totalCommission),
                      icon: Iconsax.discount_shape,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Earnings used to be a number with no way out of the app.
              SizedBox(
                width: double.infinity,
                child: Pressable(
                    child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PayoutsScreen()),
                  ).then((_) => _load()),
                  icon: const Icon(Iconsax.wallet_3, size: 18),
                  label: Text(l10n.sellerEarningsPayouts,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                )),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.sellerEarningsDeliveredOrders(orders.length),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (orders.isEmpty)
                // Nothing delivered yet is the normal start, so the screen
                // says how money arrives here instead of one bare line.
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.card,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Iconsax.wallet_money,
                        size: 36,
                        color: AppConstants.primaryColor,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _orders.isEmpty
                            ? l10n.sellerEarningsEmpty
                            : l10n.sellerEarningsEmptyPeriod,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.sellerEarningsHowItWorks,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: AppConstants.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final o in orders)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.listGap),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.card,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.sellerEarningsOrderNumber(
                                  (o['id'] as String).substring(0, 8),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _date(o['created_at'] as String?),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppConstants.textSecondaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.sellerEarningsBreakdown(
                                  formatRupees(
                                      (o['total_amount'] as num?) ?? 0),
                                  formatRupees(
                                      (o['commission_amount'] as num?) ?? 0),
                                ),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppConstants.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          formatRupees((o['seller_payout'] as num?) ?? 0),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.successColor,
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

enum _Period { all, month, week }
