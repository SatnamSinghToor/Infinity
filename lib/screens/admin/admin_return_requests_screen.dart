import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/tokens.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../utils/safe_state.dart';
import '../../widgets/role_common.dart';
import '../../widgets/pressable.dart';

/// Admin queue for `return_requests`. Approving/rejecting only updates
/// `status`/`refund_amount`/`resolved_at` — the RLS policy on this table
/// requires the underlying order to still be `delivered` and within its
/// 10-day window even for admin updates, so an approve/reject on a stale
/// request can fail; that surfaces as a plain error rather than crashing.
class AdminReturnRequestsScreen extends StatefulWidget {
  const AdminReturnRequestsScreen({super.key});

  @override
  State<AdminReturnRequestsScreen> createState() =>
      _AdminReturnRequestsScreenState();
}

class _AdminReturnRequestsScreenState extends State<AdminReturnRequestsScreen> {
  bool _isLoading = true;

  /// Whether the last load failed: said out loud, with a way to try
  /// again, instead of passing off a failed request as empty.
  bool _loadFailed = false;
  List<Map<String, dynamic>> _requests = [];
  final Set<String> _updatingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    safeSetState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final rows = await SupabaseService.client
          .from('return_requests')
          .select()
          .order('created_at', ascending: false);
      safeSetState(() => _requests = List<Map<String, dynamic>>.from(rows));
    } catch (_) {
      safeSetState(() => _loadFailed = true);
    }
    safeSetState(() => _isLoading = false);
  }

  Future<void> _reject(String id) async {
    safeSetState(() => _updatingIds.add(id));
    try {
      await SupabaseService.client.from('return_requests').update({
        'status': 'rejected',
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      await _load();
    } catch (_) {
      _showError();
    } finally {
      if (mounted) safeSetState(() => _updatingIds.remove(id));
    }
  }

  Future<void> _approve(Map<String, dynamic> request) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: '${request['refund_amount'] ?? 0}',
    );
    final refund = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminReturnsApproveTitle),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.adminReturnsRefundLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.adminReturnsCancel,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
          Pressable(
              child: ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(controller.text.trim()) ?? 0),
            child: Text(l10n.adminReturnsApprove,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
        ],
      ),
    );
    if (refund == null) return;

    final id = request['id'] as String;
    safeSetState(() => _updatingIds.add(id));
    try {
      await SupabaseService.client.from('return_requests').update({
        'status': 'approved',
        'refund_amount': refund,
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      await _load();
    } catch (_) {
      _showError();
    } finally {
      if (mounted) safeSetState(() => _updatingIds.remove(id));
    }
  }

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).adminReturnsUpdateFailed,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppConstants.successColor;
      case 'rejected':
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
        title: Text(l10n.adminReturnsTitle,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: RoleBody(
        loading: _isLoading,
        loadingMessage: l10n.adminReturnsLoading,
        failed: _loadFailed,
        errorTitle: l10n.adminReturnsLoadFailed,
        onRetry: _load,
        child: _requests.isEmpty
            ? RoleEmpty(
                icon: Iconsax.undo,
                title: l10n.adminReturnsEmptyTitle,
                message: l10n.adminReturnsEmptyBody,
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.listGap),
                  itemBuilder: (context, index) {
                    final r = _requests[index];
                    final id = r['id'] as String;
                    final status = r['status'] as String? ?? 'pending';
                    final isUpdating = _updatingIds.contains(id);

                    return RoleCard(
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  r['reason'] as String? ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              RoleStatusChip(
                                label: RoleStatusChip.titled(status),
                                color: _statusColor(status),
                              ),
                            ],
                          ),
                          if ((r['description'] as String?)?.isNotEmpty ==
                              true) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              r['description'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.adminReturnsOrder(
                              (r['order_id'] as String).substring(0, 8),
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          if (status == 'pending') ...[
                            const SizedBox(height: AppSpacing.md),
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
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Pressable(
                                      child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppConstants.dangerColor,
                                    ),
                                    onPressed: () => _reject(id),
                                    child: Text(l10n.adminReturnsReject,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  )),
                                  const SizedBox(width: 8),
                                  Pressable(
                                      child: ElevatedButton(
                                    onPressed: () => _approve(r),
                                    child: Text(l10n.adminReturnsApprove,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  )),
                                ],
                              ),
                          ],
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
