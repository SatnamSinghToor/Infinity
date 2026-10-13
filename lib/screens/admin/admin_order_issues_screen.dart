import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../utils/safe_state.dart';
import '../../widgets/role_common.dart';
import '../../widgets/pressable.dart';

/// Admin queue for `order_issues` (customer "report a problem" tickets).
/// Unlike `return_requests`, admin updates here aren't gated by an order
/// time window, so resolve/reject always succeeds regardless of order age.
class AdminOrderIssuesScreen extends StatefulWidget {
  const AdminOrderIssuesScreen({super.key});

  @override
  State<AdminOrderIssuesScreen> createState() => _AdminOrderIssuesScreenState();
}

class _AdminOrderIssuesScreenState extends State<AdminOrderIssuesScreen> {
  bool _isLoading = true;

  /// Whether the last load failed: said out loud, with a way to try
  /// again, instead of passing off a failed request as empty.
  bool _loadFailed = false;
  List<Map<String, dynamic>> _issues = [];
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
          .from('order_issues')
          .select()
          .order('created_at', ascending: false);
      safeSetState(() => _issues = List<Map<String, dynamic>>.from(rows));
    } catch (_) {
      safeSetState(() => _loadFailed = true);
    }
    safeSetState(() => _isLoading = false);
  }

  Future<void> _reject(String id) async {
    safeSetState(() => _updatingIds.add(id));
    try {
      await SupabaseService.client.from('order_issues').update({
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

  Future<void> _resolve(Map<String, dynamic> issue) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: '${issue['refund_amount'] ?? 0}',
    );
    final refund = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminIssuesResolveTitle),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.adminIssuesRefundLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.adminIssuesCancel,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
          Pressable(
              child: ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(controller.text.trim()) ?? 0),
            child: Text(l10n.adminIssuesResolve,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
        ],
      ),
    );
    if (refund == null) return;

    final id = issue['id'] as String;
    safeSetState(() => _updatingIds.add(id));
    try {
      await SupabaseService.client.from('order_issues').update({
        'status': 'resolved',
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
          content: Text(AppLocalizations.of(context).adminIssuesUpdateFailed,
              maxLines: 1, overflow: TextOverflow.ellipsis)),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'resolved':
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
          title: Text(l10n.adminIssuesTitle,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          centerTitle: true),
      body: RoleBody(
        loading: _isLoading,
        loadingMessage: l10n.adminIssuesLoading,
        failed: _loadFailed,
        errorTitle: l10n.adminIssuesLoadFailed,
        onRetry: _load,
        child: _issues.isEmpty
            ? RoleEmpty(
                icon: Iconsax.info_circle,
                title: l10n.adminIssuesEmptyTitle,
                message: l10n.adminIssuesEmptyBody,
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _issues.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final i = _issues[index];
                    final id = i['id'] as String;
                    final status = i['status'] as String? ?? 'open';
                    final isUpdating = _updatingIds.contains(id);

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
                                  i['reason'] as String? ?? '',
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
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _statusColor(status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if ((i['description'] as String?)?.isNotEmpty ==
                              true) ...[
                            const SizedBox(height: 6),
                            Text(
                              i['description'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            l10n.adminIssuesOrder(
                              (i['order_id'] as String).substring(0, 8),
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          if (status == 'open') ...[
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
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Pressable(
                                      child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppConstants.dangerColor,
                                    ),
                                    onPressed: () => _reject(id),
                                    child: Text(l10n.adminIssuesReject,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  )),
                                  const SizedBox(width: 8),
                                  Pressable(
                                      child: ElevatedButton(
                                    onPressed: () => _resolve(i),
                                    child: Text(l10n.adminIssuesResolve,
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
