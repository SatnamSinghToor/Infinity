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

/// The return requests customers raised on this seller's orders: which
/// order, why, how much is to be refunded, and where the request stands.
///
/// Read-only on purpose: a refund moves money, so approving or rejecting
/// one stays with the admin (who already has the screen for it). The
/// seller sees each request the moment it exists, and its outcome.
class SellerReturnsScreen extends StatefulWidget {
  const SellerReturnsScreen({super.key});

  @override
  State<SellerReturnsScreen> createState() => _SellerReturnsScreenState();
}

class _SellerReturnsScreenState extends State<SellerReturnsScreen> {
  bool _isLoading = true;

  /// A failed load is said out loud, with a retry — never shown as "no
  /// returns".
  bool _loadFailed = false;
  List<Map<String, dynamic>> _returns = [];

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
          .from('return_requests')
          .select(
            'id, order_id, reason, description, status, refund_amount, '
            'created_at, resolved_at, orders!inner(seller_id)',
          )
          .eq('orders.seller_id', userId)
          .order('created_at', ascending: false);
      safeSetState(() => _returns = List<Map<String, dynamic>>.from(rows));
    } catch (e) {
      debugPrint('Seller returns load failed: $e');
      safeSetState(() => _loadFailed = true);
    }
    safeSetState(() => _isLoading = false);
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'approved':
      case 'refunded':
      case 'completed':
        return context.tokens.success;
      case 'rejected':
        return context.tokens.danger;
      default:
        return context.tokens.primary;
    }
  }

  String _date(String? iso) {
    final at = DateTime.tryParse(iso ?? '')?.toLocal();
    if (at == null) return '';
    return '${at.day}/${at.month}/${at.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.surface,
      appBar: GradientAppBar(
        title: Text(
          l10n.sellerReturnsTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: RoleBody(
        loading: _isLoading,
        loadingMessage: l10n.sellerReturnsLoading,
        failed: _loadFailed,
        errorTitle: l10n.sellerReturnsLoadFailed,
        onRetry: _load,
        child: _returns.isEmpty
            ? RoleEmpty(
                icon: Iconsax.rotate_left,
                title: l10n.sellerReturnsEmptyTitle,
                message: l10n.sellerReturnsEmptyBody,
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _returns.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final r = _returns[i];
                    final status = (r['status'] as String?) ?? 'pending';
                    final color = _statusColor(context, status);
                    final orderId = (r['order_id'] as String?) ?? '';
                    final refund = (r['refund_amount'] as num?) ?? 0;
                    final note = (r['description'] as String?)?.trim() ?? '';
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: tokens.card,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.sellerReturnsOrder(
                                    orderId.length > 8
                                        ? orderId.substring(0, 8)
                                        : orderId,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status[0].toUpperCase() +
                                      status.substring(1).replaceAll('_', ' '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (r['reason'] as String?) ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (note.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              note,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: tokens.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Iconsax.calendar_1,
                                size: 15,
                                color: tokens.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _date(r['created_at'] as String?),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: tokens.textSecondary,
                                ),
                              ),
                              const Spacer(),
                              if (refund > 0)
                                Text(
                                  l10n.sellerReturnsRefund(
                                    formatRupees(refund),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
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
