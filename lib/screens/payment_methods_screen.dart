import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../models/payment_method.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/role_common.dart';
import '../utils/safe_state.dart';
import '../widgets/pressable.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  bool _isLoading = true;

  /// Whether the last load failed: an empty list after a failure must say
  /// so rather than read as "no cards saved".
  bool _loadFailed = false;
  List<PaymentMethod> _methods = [];

  String? get _userId => SupabaseService.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _userId;
    if (uid == null) return;
    safeSetState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final rows = await SupabaseService.client
          .from('payment_methods')
          .select()
          .eq('user_id', uid)
          .order('is_default', ascending: false);
      safeSetState(
          () => _methods = rows.map(PaymentMethod.fromSupabaseRow).toList());
    } catch (_) {
      safeSetState(() => _loadFailed = true);
    }
    safeSetState(() => _isLoading = false);
  }

  Future<void> _addMethod() async {
    final l10n = AppLocalizations.of(context);
    String type = 'UPI';
    final labelController = TextEditingController();
    final detailController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.paymentMethodsAddTitle,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                        value: 'UPI',
                        label: Text(l10n.paymentMethodsUpi,
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ButtonSegment(
                        value: 'CARD',
                        label: Text(l10n.paymentMethodsCard,
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                  selected: {type},
                  onSelectionChanged: (selection) =>
                      setDialogState(() => type = selection.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: labelController,
                  decoration: InputDecoration(
                    labelText: type == 'UPI'
                        ? l10n.paymentMethodsUpiLabel
                        : l10n.paymentMethodsCardLabel,
                    hintText: type == 'UPI'
                        ? l10n.paymentMethodsUpiLabelHint
                        : l10n.paymentMethodsCardLabelHint,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailController,
                  decoration: InputDecoration(
                    labelText: type == 'UPI'
                        ? l10n.paymentMethodsUpiDetail
                        : l10n.paymentMethodsCardDetail,
                    hintText: type == 'UPI'
                        ? l10n.paymentMethodsUpiDetailHint
                        : l10n.paymentMethodsCardDetailHint,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Pressable(
                child: TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.paymentMethodsCancel,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            )),
            Pressable(
                child: ElevatedButton(
              onPressed: () async {
                if (labelController.text.trim().isEmpty ||
                    detailController.text.trim().isEmpty) {
                  return;
                }
                final uid = _userId;
                if (uid == null) return;
                try {
                  await SupabaseService.client.from('payment_methods').insert({
                    'user_id': uid,
                    'type': type,
                    'label': labelController.text.trim(),
                    'detail': detailController.text.trim(),
                    'is_default': _methods.isEmpty,
                  });
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (_) {
                  if (ctx.mounted) Navigator.pop(ctx, false);
                }
              },
              child: Text(l10n.paymentMethodsSave,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            )),
          ],
        ),
      ),
    );

    if (saved == true) _load();
  }

  Future<void> _setDefault(PaymentMethod method) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await SupabaseService.client
          .from('payment_methods')
          .update({'is_default': false}).eq('user_id', uid);
      await SupabaseService.client
          .from('payment_methods')
          .update({'is_default': true}).eq('id', method.id);
      _load();
    } catch (_) {
      if (mounted) {
        roleSay(
          context,
          AppLocalizations.of(context).paymentMethodsSetDefaultFailed,
        );
      }
    }
  }

  Future<void> _delete(PaymentMethod method) async {
    try {
      await SupabaseService.client
          .from('payment_methods')
          .delete()
          .eq('id', method.id);
      _load();
    } catch (_) {
      if (mounted) {
        roleSay(
          context,
          AppLocalizations.of(context).paymentMethodsDeleteFailed,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loadFailed && _methods.isEmpty) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: GradientAppBar(
          title: Text(l10n.paymentMethodsTitle,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          centerTitle: true,
        ),
        body: RoleError(
          title: l10n.paymentMethodsLoadFailed,
          onRetry: _load,
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
        title: Text(l10n.paymentMethodsTitle,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMethod,
        child: const Icon(Iconsax.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _methods.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.card,
                          size: 72,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.paymentMethodsEmpty,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _methods.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final method = _methods[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: method.isDefault
                            ? Border.all(
                                color: AppConstants.primaryColor, width: 1.5)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            method.type == 'CARD'
                                ? Iconsax.card
                                : Iconsax.wallet_3,
                            color: AppConstants.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      method.label,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                    if (method.isDefault) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppConstants.primaryColor
                                              .withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          l10n.paymentMethodsDefaultBadge,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: AppConstants.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  method.detail,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          if (!method.isDefault)
                            Pressable(
                                child: TextButton(
                              onPressed: () => _setDefault(method),
                              child: Text(l10n.paymentMethodsSetDefault,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            )),
                          Pressable(
                              child: IconButton(
                            icon: const Icon(Iconsax.trash,
                                color: AppConstants.dangerColor, size: 18),
                            onPressed: () => _delete(method),
                          )),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
