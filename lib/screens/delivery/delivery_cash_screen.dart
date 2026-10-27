import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/format.dart';
import '../../utils/safe_state.dart';
import '../../utils/tokens.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/role_common.dart';

/// Cash Collection: the cash-on-delivery orders this rider handed over,
/// with what was collected on each, today's total and the total overall —
/// the cash the rider is carrying for the shop.
class DeliveryCashScreen extends StatefulWidget {
  const DeliveryCashScreen({super.key});

  @override
  State<DeliveryCashScreen> createState() => _DeliveryCashScreenState();
}

class _DeliveryCashScreenState extends State<DeliveryCashScreen> {
  bool _isLoading = true;

  /// A failed load is said out loud, with a retry — never shown as "no
  /// cash collected".
  bool _loadFailed = false;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final riderId = context.read<AuthProvider>().userId;
    safeSetState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final rows = await SupabaseService.client
          .from('orders')
          .select('id, total_amount, delivery_address, created_at')
          .eq('delivery_id', riderId)
          .eq('payment_method', 'cod')
          .eq('status', 'delivered')
          .order('created_at', ascending: false);
      safeSetState(() => _orders = List<Map<String, dynamic>>.from(rows));
    } catch (e) {
      debugPrint('Cash collection load failed: $e');
      safeSetState(() => _loadFailed = true);
    }
    safeSetState(() => _isLoading = false);
  }

  double _amount(Map<String, dynamic> o) =>
      (o['total_amount'] as num?)?.toDouble() ?? 0;

  DateTime? _at(Map<String, dynamic> o) =>
      DateTime.tryParse(o['created_at'] as String? ?? '')?.toLocal();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final today = DateUtils.dateOnly(DateTime.now());
    final total = _orders.fold<double>(0, (s, o) => s + _amount(o));
    final todayTotal = _orders.where((o) {
      final at = _at(o);
      return at != null && DateUtils.isSameDay(at, today);
    }).fold<double>(0, (s, o) => s + _amount(o));

    Widget figure(String label, String value, IconData icon) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: tokens.card,
              borderRadius: AppRadius.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: tokens.primary),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );

    return Scaffold(
      backgroundColor: tokens.surface,
      appBar: GradientAppBar(
        title: Text(
          l10n.deliveryCashTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: RoleBody(
        loading: _isLoading,
        loadingMessage: l10n.deliveryCashLoading,
        failed: _loadFailed,
        errorTitle: l10n.deliveryCashLoadFailed,
        onRetry: _load,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  figure(
                    l10n.deliveryCashToday,
                    formatRupees(todayTotal),
                    Iconsax.money_recive,
                  ),
                  const SizedBox(width: 12),
                  figure(
                    l10n.deliveryCashTotal,
                    formatRupees(total),
                    Iconsax.money_3,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_orders.isEmpty)
                RoleEmpty(
                  icon: Iconsax.money_3,
                  title: l10n.deliveryCashEmptyTitle,
                  message: l10n.deliveryCashEmptyBody,
                )
              else
                for (final o in _orders)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.listGap),
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    decoration: BoxDecoration(
                      color: tokens.card,
                      borderRadius: AppRadius.card,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: tokens.success.withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(
                            Iconsax.tick_circle,
                            color: tokens.success,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.deliveryCashOrder(
                                  (o['id'] as String).substring(0, 8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                (o['delivery_address'] as String?) ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatRupees(_amount(o)),
                          maxLines: 1,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
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
