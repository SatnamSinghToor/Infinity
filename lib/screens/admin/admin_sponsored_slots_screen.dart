import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/tokens.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../utils/format.dart';
import '../../utils/safe_state.dart';
import '../../widgets/role_common.dart';
import '../../widgets/pressable.dart';

/// Admin queue for `sponsored_slots` requests. `fee_amount` is a generated
/// column (`duration_days * 5`) so it's never written from the client.
/// Approving sets `starts_at`/`ends_at` from `duration_days` so the slot
/// goes live immediately; the public "APPROVED and currently live" RLS
/// policy depends on those two columns being set.
class AdminSponsoredSlotsScreen extends StatefulWidget {
  const AdminSponsoredSlotsScreen({super.key});

  @override
  State<AdminSponsoredSlotsScreen> createState() =>
      _AdminSponsoredSlotsScreenState();
}

class _AdminSponsoredSlotsScreenState extends State<AdminSponsoredSlotsScreen> {
  bool _isLoading = true;

  /// Whether the last load failed: said out loud, with a way to try
  /// again, instead of passing off a failed request as empty.
  bool _loadFailed = false;
  List<Map<String, dynamic>> _slots = [];
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
          .from('sponsored_slots')
          .select('*, products(name)')
          .order('created_at', ascending: false);
      safeSetState(() => _slots = List<Map<String, dynamic>>.from(rows));
    } catch (_) {
      safeSetState(() => _loadFailed = true);
    }
    safeSetState(() => _isLoading = false);
  }

  Future<void> _approve(Map<String, dynamic> slot) async {
    final id = slot['id'] as String;
    final durationDays = (slot['duration_days'] as num?)?.toInt() ?? 7;
    final now = DateTime.now();
    safeSetState(() => _updatingIds.add(id));
    try {
      await SupabaseService.client.from('sponsored_slots').update({
        'status': 'APPROVED',
        'starts_at': now.toIso8601String(),
        'ends_at': now.add(Duration(days: durationDays)).toIso8601String(),
        'rejection_reason': null,
      }).eq('id', id);
      await _load();
    } catch (_) {
      _showError();
    } finally {
      if (mounted) safeSetState(() => _updatingIds.remove(id));
    }
  }

  Future<void> _reject(String id) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminSlotsRejectTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.adminSlotsReasonLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.adminSlotsCancel,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
          Pressable(
              child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.dangerColor,
            ),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.adminSlotsReject,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
        ],
      ),
    );
    if (reason == null) return;

    safeSetState(() => _updatingIds.add(id));
    try {
      await SupabaseService.client.from('sponsored_slots').update({
        'status': 'REJECTED',
        'rejection_reason': reason.isEmpty ? 'Not approved' : reason,
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
          content: Text(AppLocalizations.of(context).adminSlotsUpdateFailed,
              maxLines: 1, overflow: TextOverflow.ellipsis)),
    );
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
        title: Text(l10n.adminSlotsTitle,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: RoleBody(
        loading: _isLoading,
        loadingMessage: l10n.adminSlotsLoading,
        failed: _loadFailed,
        errorTitle: l10n.adminSlotsLoadFailed,
        onRetry: _load,
        child: _slots.isEmpty
            ? RoleEmpty(
                icon: Iconsax.tag,
                title: l10n.adminSlotsEmptyTitle,
                message: l10n.adminSlotsEmptyBody,
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _slots.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.listGap),
                  itemBuilder: (context, index) {
                    final s = _slots[index];
                    final id = s['id'] as String;
                    final status = s['status'] as String? ?? 'PENDING';
                    final isUpdating = _updatingIds.contains(id);
                    final productName =
                        (s['products'] as Map?)?['name'] as String? ??
                            l10n.adminSlotsUnknownProduct;

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
                                  s['headline'] as String? ?? '',
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
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.adminSlotsProduct(productName),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            l10n.adminSlotsDaysFee(
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
                            Text(
                              s['rejection_reason'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          if (status == 'PENDING') ...[
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
                                    child: Text(l10n.adminSlotsReject,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  )),
                                  const SizedBox(width: 8),
                                  Pressable(
                                      child: ElevatedButton(
                                    onPressed: () => _approve(s),
                                    child: Text(l10n.adminSlotsApprove,
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
