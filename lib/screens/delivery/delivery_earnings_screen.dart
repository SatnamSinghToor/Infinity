import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/format.dart';
import '../../utils/safe_state.dart';
import 'package:provider/provider.dart';
import '../../widgets/role_common.dart';
import '../payouts_screen.dart';
import 'delivery_cash_screen.dart';
import '../../widgets/pressable.dart';

class DeliveryEarningsScreen extends StatefulWidget {
  const DeliveryEarningsScreen({super.key});

  @override
  State<DeliveryEarningsScreen> createState() => _DeliveryEarningsScreenState();
}

class _DeliveryEarningsScreenState extends State<DeliveryEarningsScreen> {
  bool _isLoading = true;

  /// Whether the last load failed: said out loud, with a way to try
  /// again, instead of passing off a failed request as empty.
  bool _loadFailed = false;
  List<Map<String, dynamic>> _earnings = [];

  /// Earned and not yet paid out or asked for (payout_balance()).
  double? _wallet;

  /// Cash taken on cash-on-delivery runs this rider delivered.
  double _cash = 0;

  /// What the shop has actually paid this rider (payouts marked paid).
  double _settled = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final partnerId = context.read<AuthProvider>().userId;
    safeSetState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final client = SupabaseService.client;
      final rows = await client
          .from('delivery_earnings')
          .select()
          .eq('partner_id', partnerId)
          .order('created_at', ascending: false);
      final cod = await client
          .from('orders')
          .select('total_amount')
          .eq('delivery_id', partnerId)
          .eq('payment_method', 'cod')
          .eq('status', 'delivered');
      final paid = await client
          .from('payout_requests')
          .select('amount')
          .eq('user_id', partnerId)
          .eq('status', 'paid');
      double? wallet;
      try {
        final balance = await client.rpc('payout_balance');
        if (balance is List && balance.isNotEmpty) {
          final row = Map<String, dynamic>.from(balance.first as Map);
          final earned = (row['earned'] as num?)?.toDouble() ?? 0;
          final outstanding = (row['outstanding'] as num?)?.toDouble() ?? 0;
          wallet = (earned - outstanding).clamp(0, double.infinity).toDouble();
        }
      } catch (e) {
        // The tile shows "—" rather than a made-up number.
        debugPrint('Earnings wallet lookup failed: $e');
      }
      double sum(List rows, String column) => rows.fold<double>(
          0, (s, r) => s + ((r[column] as num?)?.toDouble() ?? 0));
      safeSetState(() {
        _earnings = List<Map<String, dynamic>>.from(rows);
        _cash = sum(cod, 'total_amount');
        _settled = sum(paid, 'amount');
        _wallet = wallet;
      });
    } catch (e) {
      debugPrint('Rider earnings load failed: $e');
      safeSetState(() => _loadFailed = true);
    }
    safeSetState(() => _isLoading = false);
  }

  double _amount(Map<String, dynamic> e) =>
      (e['amount'] as num?)?.toDouble() ?? 0;

  double get _total => _earnings.fold(0, (s, e) => s + _amount(e));

  /// Earned since [from] (local midnight of a day).
  double _since(DateTime from) => _earnings.where((e) {
        final at = DateTime.tryParse(e['created_at'] as String? ?? '');
        return at != null && !at.toLocal().isBefore(from);
      }).fold(0, (s, e) => s + _amount(e));

  void _open(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
          .then((_) => _load());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = DateUtils.dateOnly(DateTime.now());
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
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
                      child: Text(
                        l10n.deliveryEarningsTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: RoleBody(
              loading: _isLoading,
              loadingMessage: l10n.deliveryEarningsLoading,
              failed: _loadFailed,
              errorTitle: l10n.deliveryEarningsLoadFailed,
              onRetry: _load,
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Iconsax.trend_up,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.deliveryEarningsTotal,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: AppConstants.textSecondaryColor,
                                      ),
                                    ),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        formatRupees(_total),
                                        maxLines: 1,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                        ),
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
                              const Icon(
                                Iconsax.calendar_1,
                                color: AppConstants.textSecondaryColor,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l10n.deliveryEarningsToday,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 15.5),
                                ),
                              ),
                              Text(
                                formatRupees(_since(today)),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.45,
                      children: [
                        _Tile(
                          icon: Iconsax.wallet_3,
                          value: _wallet == null ? '—' : formatRupees(_wallet!),
                          label: l10n.deliveryEarningsWallet,
                          onTap: () => _open(const PayoutsScreen()),
                        ),
                        _Tile(
                          icon: Iconsax.money_recive,
                          value: formatRupees(_cash),
                          label: l10n.deliveryCashTitle,
                          onTap: () => _open(const DeliveryCashScreen()),
                        ),
                        _Tile(
                          icon: Iconsax.chart_1,
                          value: formatRupees(_since(weekStart)),
                          label: l10n.deliveryEarningsWeek,
                        ),
                        _Tile(
                          icon: Iconsax.card_receive,
                          value: formatRupees(_settled),
                          label: l10n.deliveryEarningsSettled,
                          onTap: () => _open(const PayoutsScreen()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Asking for the money is its own button, not only a tile
                    // to discover: a request is how the wallet is paid out.
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Pressable(
                        child: OutlinedButton.icon(
                          onPressed: () => _open(const PayoutsScreen()),
                          icon: const Icon(Iconsax.wallet_3, size: 18),
                          label: Text(
                            l10n.deliveryEarningsPayouts,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppConstants.primaryColor,
                            side: const BorderSide(
                              color: AppConstants.primaryColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      l10n.deliveryEarningsHistory,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_earnings.isEmpty)
                      RoleEmptyNote(
                        icon: Iconsax.wallet_3,
                        message: l10n.deliveryEarningsEmpty,
                      )
                    else
                      for (final e in _earnings)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Iconsax.truck_fast,
                                color: AppConstants.primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  (e['note'] as String?)?.isNotEmpty == true
                                      ? e['note'] as String
                                      : l10n.deliveryEarningsFeeFallback,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '+${formatRupees(_amount(e))}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
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
          ),
        ],
      ),
    );
  }
}

/// One of the four money figures: an icon, the amount, what it is.
class _Tile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _Tile({
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: AppConstants.primaryColor, size: 28),
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
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
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
