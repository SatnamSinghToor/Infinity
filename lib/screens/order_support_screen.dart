import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../services/supabase_service.dart';
import '../utils/constants.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/role_common.dart';
import '../widgets/pressable.dart';

/// Lets a customer report a problem with an order (`order_issues`) or
/// request a return (`return_requests`), and shows any tickets already
/// filed for it. Both tables are customer-writable per their RLS policies;
/// `return_requests` additionally requires the order to be delivered and
/// within its 10-day return window, so a rejected insert just surfaces
/// as a friendly error rather than being pre-validated here.
class OrderSupportScreen extends StatefulWidget {
  final String orderId;

  const OrderSupportScreen({super.key, required this.orderId});

  @override
  State<OrderSupportScreen> createState() => _OrderSupportScreenState();
}

class _OrderSupportScreenState extends State<OrderSupportScreen> {
  bool _isLoading = true;

  /// Whether the last load failed: tickets we could not read must not read
  /// as "nothing was ever reported".
  bool _loadFailed = false;
  List<Map<String, dynamic>> _issues = [];
  List<Map<String, dynamic>> _returns = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final issues = await SupabaseService.client
          .from('order_issues')
          .select()
          .eq('order_id', widget.orderId)
          .order('created_at', ascending: false);
      final returns = await SupabaseService.client
          .from('return_requests')
          .select()
          .eq('order_id', widget.orderId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _issues = List<Map<String, dynamic>>.from(issues);
          _returns = List<Map<String, dynamic>>.from(returns);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _submit({required bool isReturn}) async {
    final reasonController = TextEditingController();
    final descController = TextEditingController();
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isReturn
              ? l10n.orderSupportRequestReturn
              : l10n.orderSupportReportProblem,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: l10n.orderSupportReason,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.orderSupportDescription,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.orderSupportCancel,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
          Pressable(
              child: ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: Text(l10n.orderSupportSubmit,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
        ],
      ),
    );
    if (confirmed != true) return;

    final uid = SupabaseService.client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      if (isReturn) {
        await SupabaseService.client.from('return_requests').insert({
          'order_id': widget.orderId,
          'user_id': uid,
          'reason': reasonController.text.trim(),
          'description': descController.text.trim(),
        });
      } else {
        await SupabaseService.client.from('order_issues').insert({
          'order_id': widget.orderId,
          'user_id': uid,
          'reason': reasonController.text.trim(),
          'description': descController.text.trim(),
        });
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.orderSupportSubmitted,
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.orderSupportSubmitFailed,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'resolved':
      case 'approved':
        return AppConstants.successColor;
      case 'rejected':
        return AppConstants.dangerColor;
      default:
        return Colors.orange;
    }
  }

  Widget _ticketCard(Map<String, dynamic> ticket) {
    final status = ticket['status'] as String? ?? 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ticket['reason'] as String? ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(status),
                  ),
                ),
              ),
            ],
          ),
          if ((ticket['description'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              ticket['description'] as String,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loadFailed && _issues.isEmpty && _returns.isEmpty) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: GradientAppBar(
            title: Text(l10n.orderSupportTitle,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            centerTitle: true),
        body: RoleError(
          title: l10n.orderSupportLoadFailed,
          onRetry: _load,
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
          title: Text(l10n.orderSupportTitle,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Pressable(
                            child: OutlinedButton.icon(
                          onPressed: () => _submit(isReturn: false),
                          icon: const Icon(Iconsax.warning_2, size: 18),
                          label: Text(l10n.orderSupportReportProblem,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        )),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Pressable(
                            child: OutlinedButton.icon(
                          onPressed: () => _submit(isReturn: true),
                          icon: const Icon(Iconsax.undo, size: 18),
                          label: Text(l10n.orderSupportRequestReturnButton,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_issues.isNotEmpty) ...[
                    Text(
                      l10n.orderSupportIssuesHeading,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._issues.map(_ticketCard),
                    const SizedBox(height: 16),
                  ],
                  if (_returns.isNotEmpty) ...[
                    Text(
                      l10n.orderSupportReturnsHeading,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._returns.map(_ticketCard),
                  ],
                  if (_issues.isEmpty && _returns.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Column(
                        children: [
                          Icon(
                            Iconsax.message_question,
                            size: 44,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.orderSupportEmpty,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.4,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
