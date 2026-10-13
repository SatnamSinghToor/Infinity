import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../utils/format.dart';
import '../../utils/safe_state.dart';
import '../../widgets/role_common.dart';

/// A seller's own sponsored_slots requests and their approval status —
/// previously only visible to admins, leaving the seller with no way to
/// tell whether a boost request was approved, rejected, or still pending.
class MyBoostRequestsScreen extends StatefulWidget {
  const MyBoostRequestsScreen({super.key});

  @override
  State<MyBoostRequestsScreen> createState() => _MyBoostRequestsScreenState();
}

class _MyBoostRequestsScreenState extends State<MyBoostRequestsScreen> {
  bool _isLoading = true;

  /// Whether the last load failed: said out loud, with a way to try
  /// again, instead of passing off a failed request as empty.
  bool _loadFailed = false;
  List<Map<String, dynamic>> _slots = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = context.read<AuthProvider>().userId;
    safeSetState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final rows = await SupabaseService.client
          .from('sponsored_slots')
          .select('*, products(name)')
          .eq('seller_id', uid)
          .order('created_at', ascending: false);
      safeSetState(() => _slots = List<Map<String, dynamic>>.from(rows));
    } catch (_) {
      safeSetState(() => _loadFailed = true);
    }
    safeSetState(() => _isLoading = false);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return AppConstants.successColor;
      case 'REJECTED':
        return AppConstants.dangerColor;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
        title: Text(l10n.sellerBoostsTitle,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: RoleBody(
        loading: _isLoading,
        loadingMessage: l10n.sellerBoostsLoading,
        failed: _loadFailed,
        errorTitle: l10n.sellerBoostsLoadFailed,
        onRetry: _load,
        child: _slots.isEmpty
            ? RoleEmpty(
                icon: Iconsax.tag,
                title: l10n.sellerBoostsEmptyTitle,
                message: l10n.sellerBoostsEmptyBody,
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _slots.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final s = _slots[index];
                    final status = s['status'] as String? ?? 'PENDING';
                    final productName =
                        (s['products'] as Map?)?['name'] as String? ??
                            l10n.sellerBoostsProductFallback;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  s['headline'] as String? ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(
                                    status,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _statusColor(status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.sellerBoostsProduct(productName),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            l10n.sellerBoostsDaysFee(
                              (s['duration_days'] as num?)?.toInt() ?? 0,
                              formatRupees((s['fee_amount'] as num?) ?? 0),
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          if (status == 'REJECTED' &&
                              s['rejection_reason'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                l10n.sellerBoostsReason(
                                  s['rejection_reason'] as String,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
