import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../models/payout_request.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/format.dart';
import '../../utils/safe_state.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/role_common.dart';
import '../../widgets/pressable.dart';

/// The admin's side of a payout request: approve it, or reject it with a
/// reason the partner will read on their own Payouts screen.
///
/// Approving does not move money. It says "this is owed and agreed", and the
/// screen keeps showing it as approved until someone marks it paid with the
/// bank's reference — an app claiming "paid" on its own would be a lie the
/// partner cannot check.
class AdminPayoutsScreen extends StatefulWidget {
  const AdminPayoutsScreen({super.key});

  @override
  State<AdminPayoutsScreen> createState() => _AdminPayoutsScreenState();
}

class _AdminPayoutsScreenState extends State<AdminPayoutsScreen> {
  bool _isLoading = true;

  /// Whether the last load failed. A queue that could not be fetched is not
  /// an empty queue, and it must not read as "nobody is waiting for money".
  bool _loadFailed = false;
  List<PayoutRequest> _requests = [];
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
          .from('payout_requests')
          .select()
          // Pending first, then newest: the queue reads top-down.
          .order('status')
          .order('created_at', ascending: false);
      safeSetState(() => _requests = [
            for (final row in rows)
              PayoutRequest.fromSupabaseRow(Map<String, dynamic>.from(row)),
          ]);
    } catch (_) {
      safeSetState(() => _loadFailed = true);
    }
    safeSetState(() => _isLoading = false);
  }

  Future<void> _decide(PayoutRequest request, {required bool approve}) async {
    final l10n = AppLocalizations.of(context);
    String? note;
    if (!approve) {
      final controller = TextEditingController();
      note = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.adminPayoutsRejectTitle),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.adminPayoutsReasonLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            Pressable(
                child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.adminPayoutsCancel,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            )),
            Pressable(
                child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.dangerColor,
              ),
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(l10n.adminPayoutsReject,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            )),
          ],
        ),
      );
      if (note == null) return;
    }

    safeSetState(() => _updatingIds.add(request.id));
    try {
      await SupabaseService.client.from('payout_requests').update({
        'status': approve ? 'approved' : 'rejected',
        'decided_by': SupabaseService.client.auth.currentUser?.id,
        'decided_at': DateTime.now().toIso8601String(),
        'decision_note': approve
            ? 'Approved. The transfer will follow.'
            : (note!.isEmpty ? 'Not approved' : note),
      }).eq('id', request.id);
      await _load();
    } catch (_) {
      _toast(l10n.adminPayoutsUpdateFailed);
    } finally {
      if (mounted) safeSetState(() => _updatingIds.remove(request.id));
    }
  }

  Future<void> _markPaid(PayoutRequest request) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final reference = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminPayoutsMarkPaid),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.adminPayoutsReferenceLabel,
            helperText: l10n.adminPayoutsReferenceHelper,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.adminPayoutsCancel,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
          Pressable(
              child: ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.adminPayoutsMarkPaidButton,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
        ],
      ),
    );
    if (reference == null) return;

    safeSetState(() => _updatingIds.add(request.id));
    try {
      await SupabaseService.client.from('payout_requests').update({
        'status': 'paid',
        'paid_at': DateTime.now().toIso8601String(),
        'payment_reference': reference.isEmpty ? null : reference,
      }).eq('id', request.id);
      await _load();
    } catch (_) {
      _toast(l10n.adminPayoutsMarkPaidFailed);
    } finally {
      if (mounted) safeSetState(() => _updatingIds.remove(request.id));
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
      case 'paid':
        return AppConstants.successColor;
      case 'rejected':
        return AppConstants.dangerColor;
      default:
        return AppConstants.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pending = _requests.where((r) => r.isPending).toList();
    final decided = _requests.where((r) => !r.isPending).toList();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
        title: Text(l10n.adminPayoutsTitle,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: RoleBody(
        loading: _isLoading,
        loadingMessage: l10n.adminPayoutsLoading,
        failed: _loadFailed,
        errorTitle: l10n.adminPayoutsLoadFailed,
        onRetry: _load,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pending.isEmpty)
                RoleEmptyNote(
                  icon: Iconsax.wallet_3,
                  message: l10n.adminPayoutsEmpty,
                )
              else ...[
                Text(
                  l10n.adminPayoutsWaiting(pending.length),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...pending.map(_pendingCard),
              ],
              if (decided.isNotEmpty) ...[
                const SizedBox(height: 22),
                Text(
                  l10n.adminPayoutsDecided,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...decided.map(_decidedCard),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _pendingCard(PayoutRequest request) {
    final l10n = AppLocalizations.of(context);
    final isUpdating = _updatingIds.contains(request.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                formatRupees(request.amount),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                request.roleLabel,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppConstants.textSecondaryColor,
                ),
              ),
              const Spacer(),
              Text(
                request.formattedDate,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppConstants.textSecondaryColor,
                ),
              ),
            ],
          ),
          if (request.method != null && request.method!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              l10n.adminPayoutsSendTo(request.method!),
              style: const TextStyle(fontSize: 13),
            ),
          ],
          if (request.note != null && request.note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              l10n.adminPayoutsPartnerNote(request.note!),
              style: const TextStyle(
                fontSize: 12.5,
                color: AppConstants.textSecondaryColor,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (isUpdating)
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Pressable(
                      child: ElevatedButton(
                    onPressed: () => _decide(request, approve: true),
                    child: Text(l10n.adminPayoutsApprove,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  )),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Pressable(
                      child: OutlinedButton(
                    onPressed: () => _decide(request, approve: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.dangerColor,
                    ),
                    child: Text(l10n.adminPayoutsReject,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  )),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _decidedCard(PayoutRequest request) {
    final l10n = AppLocalizations.of(context);
    final color = _statusColor(request.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                formatRupees(request.amount),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request.status[0].toUpperCase() + request.status.substring(1),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                request.roleLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.textSecondaryColor,
                ),
              ),
            ],
          ),
          if (request.decisionNote != null &&
              request.decisionNote!.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              request.decisionNote!,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppConstants.textSecondaryColor,
              ),
            ),
          ],
          if (request.status == 'approved') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: Pressable(
                  child: OutlinedButton.icon(
                onPressed: _updatingIds.contains(request.id)
                    ? null
                    : () => _markPaid(request),
                icon: const Icon(Iconsax.tick_circle, size: 16),
                label: Text(l10n.adminPayoutsMarkPaid,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              )),
            ),
          ],
          if (request.paymentReference != null &&
              request.paymentReference!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              l10n.adminPayoutsReference(request.paymentReference!),
              style: const TextStyle(
                fontSize: 12,
                color: AppConstants.textSecondaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
