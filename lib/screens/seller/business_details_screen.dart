import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:duggu/l10n/app_localizations.dart';

import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/tokens.dart';
import '../../widgets/gradient_app_bar.dart';
import 'package:provider/provider.dart';
import '../../widgets/role_common.dart';
import '../../utils/safe_state.dart';
import '../../utils/indian_ids.dart';
import '../../widgets/form_section.dart';
import '../../widgets/pressable.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// Collects the payout/compliance details `sellers` has columns for
/// (PAN, GST, FSSAI, bank account, UPI) but the onboarding flow
/// (`AuthProvider.becomeSeller`) never asked for — it only captured
/// business/owner name. Never writes `status`/`rejection_reason`: those
/// are review-controlled columns guarded by a DB trigger.
class BusinessDetailsScreen extends StatefulWidget {
  const BusinessDetailsScreen({super.key});

  @override
  State<BusinessDetailsScreen> createState() => _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends State<BusinessDetailsScreen> {
  bool _isLoading = true;

  /// Whether the last load failed: said out loud, with a way to try
  /// again, instead of passing off a failed request as empty.
  bool _loadFailed = false;
  bool _isSaving = false;

  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _panController = TextEditingController();
  final _gstController = TextEditingController();
  final _fssaiController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _upiController = TextEditingController();

  String? _status;
  String? _rejectionReason;

  /// What is wrong with each field after the last save, by field.
  final Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _addressController.dispose();
    _panController.dispose();
    _gstController.dispose();
    _fssaiController.dispose();
    _bankAccountController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = context.read<AuthProvider>().userId;
    safeSetState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final rows = await SupabaseService.client
          .from('sellers')
          .select()
          .eq('id', uid)
          .limit(1);
      if (rows.isNotEmpty) {
        final s = rows.first;
        _businessNameController.text = s['business_name'] as String? ?? '';
        _ownerNameController.text = s['owner_name'] as String? ?? '';
        _addressController.text = s['business_address'] as String? ?? '';
        _panController.text = s['pan_number'] as String? ?? '';
        _gstController.text = s['gst_number'] as String? ?? '';
        _fssaiController.text = s['fssai_number'] as String? ?? '';
        _bankAccountController.text = s['bank_account_number'] as String? ?? '';
        _ifscController.text = s['bank_ifsc'] as String? ?? '';
        _upiController.text = s['upi_id'] as String? ?? '';
        _status = s['status']?.toString();
        _rejectionReason = s['rejection_reason'] as String?;
      }
    } catch (_) {
      safeSetState(() => _loadFailed = true);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  /// Which step (0 business, 1 compliance, 2 payout) the seller is on. One
  /// short page at a time instead of nine fields in one scroll.
  int _step = 0;
  static const _stepCount = 3;
  static const _stepKeys = [
    {'name', 'owner', 'address'},
    {'pan', 'gst', 'fssai'},
    {'bank', 'ifsc', 'upi'},
  ];

  int _stepOf(String key) => _stepKeys.indexWhere((keys) => keys.contains(key));

  void _next() {
    FocusScope.of(context).unfocus();
    if (!_validate(AppLocalizations.of(context), only: _stepKeys[_step])) {
      return;
    }
    safeSetState(() => _step++);
  }

  void _back() {
    FocusScope.of(context).unfocus();
    safeSetState(() {
      _errors.clear();
      _step--;
    });
  }

  /// Checks every field against its format and says, under the field, what
  /// is wrong. Optional fields are only checked when they are filled in.
  /// With [only], just those fields are checked and shown.
  bool _validate(AppLocalizations l10n, {Set<String>? only}) {
    String? check(
      TextEditingController c,
      bool Function(String) ok,
      String message, {
      bool required = false,
    }) {
      final v = c.text.trim();
      if (v.isEmpty) return required ? l10n.sellerBusinessErrRequired : null;
      return ok(v) ? null : message;
    }

    final errors = <String, String?>{
      'name': _businessNameController.text.trim().isEmpty
          ? l10n.sellerBusinessErrName
          : null,
      'pan': check(_panController, IndianIds.isPan, l10n.sellerBusinessErrPan),
      'gst': check(_gstController, IndianIds.isGst, l10n.sellerBusinessErrGst),
      'fssai': check(
          _fssaiController, IndianIds.isFssai, l10n.sellerBusinessErrFssai),
      'bank': check(_bankAccountController, IndianIds.isBankAccount,
          l10n.sellerBusinessErrBank),
      'ifsc':
          check(_ifscController, IndianIds.isIfsc, l10n.sellerBusinessErrIfsc),
      'upi': check(_upiController, IndianIds.isUpi, l10n.sellerBusinessErrUpi),
    };
    // A bank account needs its IFSC, and the other way round.
    if (errors['bank'] == null &&
        errors['ifsc'] == null &&
        (_bankAccountController.text.trim().isEmpty !=
            _ifscController.text.trim().isEmpty)) {
      if (_ifscController.text.trim().isEmpty) {
        errors['ifsc'] = l10n.sellerBusinessErrIfscNeeded;
      } else {
        errors['bank'] = l10n.sellerBusinessErrBankNeeded;
      }
    }
    safeSetState(() {
      _errors
        ..clear()
        ..addAll({
          for (final e in errors.entries)
            if (e.value != null && (only == null || only.contains(e.key)))
              e.key: e.value!,
        });
      // Saving from the last step with a mistake on an earlier one: take the
      // seller back to where it is, or they'd never see the message.
      if (only == null && _errors.isNotEmpty) {
        _step = _errors.keys.map(_stepOf).reduce((a, b) => a < b ? a : b);
      }
    });
    return _errors.isEmpty;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final uid = context.read<AuthProvider>().userId;
    FocusScope.of(context).unfocus();
    if (!_validate(l10n)) {
      roleSay(context, l10n.sellerBusinessFixErrors);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await SupabaseService.client.from('sellers').update({
        'business_name': _businessNameController.text.trim(),
        'owner_name': _ownerNameController.text.trim(),
        'business_address': _addressController.text.trim(),
        'pan_number': _panController.text.trim(),
        'gst_number': _gstController.text.trim(),
        'fssai_number': _fssaiController.text.trim(),
        'bank_account_number': _bankAccountController.text.trim(),
        'bank_ifsc': _ifscController.text.trim(),
        'upi_id': _upiController.text.trim(),
      }).eq('id', uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.sellerBusinessSaved,
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.sellerBusinessSaveFailed,
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _field(
    String key,
    String label,
    TextEditingController controller, {
    String? hint,
    String? helper,
    IconData? icon,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    TextCapitalization caps = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: formatters,
        textCapitalization: caps,
        onChanged: (_) {
          if (_errors.containsKey(key)) {
            safeSetState(() => _errors.remove(key));
          }
        },
        decoration: formFieldDecoration(
          label: label,
          hint: hint,
          helper: helper,
          error: _errors[key],
          icon: icon,
        ),
      ),
    );
  }

  /// What the review status means for the seller, in one line.
  Widget _statusBanner(AppLocalizations l10n) {
    final status = (_status ?? '').toUpperCase();
    final (Color color, IconData icon, String title, String body) =
        switch (status) {
      'APPROVED' => (
          AppConstants.successColor,
          Iconsax.verify,
          l10n.sellerBusinessApprovedTitle,
          l10n.sellerBusinessApprovedBody,
        ),
      'REJECTED' => (
          AppConstants.dangerColor,
          Iconsax.close_circle,
          l10n.sellerBusinessRejectedTitle,
          (_rejectionReason ?? '').trim().isEmpty
              ? l10n.sellerBusinessRejectedBody
              : _rejectionReason!.trim(),
        ),
      _ => (
          Colors.orange,
          Iconsax.clock,
          l10n.sellerBusinessPendingTitle,
          l10n.sellerBusinessPendingBody,
        ),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.card,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The fields of step [i], as one card.
  Widget _stepSection(int i, AppLocalizations l10n) {
    switch (i) {
      case 0:
        return FormSection(
          icon: Iconsax.shop,
          title: l10n.sellerBusinessSectionBusiness,
          subtitle: l10n.sellerBusinessSectionBusinessBody,
          children: [
            _field(
                'name', l10n.sellerBusinessNameLabel, _businessNameController,
                icon: Iconsax.building, caps: TextCapitalization.words),
            _field('owner', l10n.sellerBusinessOwnerLabel, _ownerNameController,
                icon: Iconsax.user, caps: TextCapitalization.words),
            _field(
                'address', l10n.sellerBusinessAddressLabel, _addressController,
                icon: Iconsax.location, caps: TextCapitalization.sentences),
          ],
        );
      case 1:
        return FormSection(
          icon: Iconsax.shield_tick,
          title: l10n.sellerBusinessCompliance,
          subtitle: l10n.sellerBusinessComplianceBody,
          children: [
            _field('pan', l10n.sellerBusinessPanLabel, _panController,
                hint: 'ABCDE1234F',
                icon: Iconsax.personalcard,
                formatters: IndianIds.upperCode(10),
                caps: TextCapitalization.characters),
            _field('gst', l10n.sellerBusinessGstLabel, _gstController,
                hint: '22ABCDE1234F1Z5',
                icon: Iconsax.receipt_2,
                formatters: IndianIds.upperCode(15),
                caps: TextCapitalization.characters),
            _field('fssai', l10n.sellerBusinessFssaiLabel, _fssaiController,
                hint: l10n.sellerBusinessFssaiHint,
                helper: l10n.sellerBusinessFssaiHelper,
                icon: Iconsax.document_text,
                keyboard: TextInputType.number,
                formatters: IndianIds.digits(14)),
          ],
        );
      default:
        return FormSection(
          icon: Iconsax.bank,
          title: l10n.sellerBusinessPayoutDetails,
          subtitle: l10n.sellerBusinessPayoutBody,
          children: [
            _field('bank', l10n.sellerBusinessBankLabel, _bankAccountController,
                hint: l10n.sellerBusinessBankHint,
                icon: Iconsax.card,
                keyboard: TextInputType.number,
                formatters: IndianIds.digits(18)),
            _field('ifsc', l10n.sellerBusinessIfscLabel, _ifscController,
                hint: 'SBIN0001234',
                helper: l10n.sellerBusinessIfscHelper,
                icon: Iconsax.bank,
                formatters: IndianIds.upperCode(11),
                caps: TextCapitalization.characters),
            _field('upi', l10n.sellerBusinessUpiLabel, _upiController,
                hint: 'name@okaxis',
                icon: Iconsax.mobile,
                keyboard: TextInputType.emailAddress,
                formatters: IndianIds.upiFormatters),
          ],
        );
    }
  }

  /// "Step 2 of 3", the step's name, and a three-part bar filled up to here.
  Widget _progress(AppLocalizations l10n) {
    final names = [
      l10n.sellerBusinessSectionBusiness,
      l10n.sellerBusinessCompliance,
      l10n.sellerBusinessPayoutDetails,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.sellerBusinessStepOf(_step + 1, _stepCount),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '· ${names[_step]}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < _stepCount; i++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 5,
                    decoration: BoxDecoration(
                      color: i <= _step
                          ? AppConstants.primaryColor
                          : const Color(0xFFEFEFEF),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                if (i < _stepCount - 1) const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buttons(AppLocalizations l10n) {
    final last = _step == _stepCount - 1;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            if (_step > 0) ...[
              Expanded(
                child: SizedBox(
                  height: AppControl.lg,
                  child: Pressable(
                      child: OutlinedButton(
                    onPressed: _isSaving ? null : _back,
                    child: Text(l10n.sellerBusinessBack,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  )),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: SizedBox(
                height: AppControl.lg,
                child: Pressable(
                    child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                  ),
                  onPressed: _isSaving ? null : (last ? _save : _next),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          last
                              ? l10n.sellerBusinessSave
                              : l10n.sellerBusinessNext,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The phone's back gesture steps back through the wizard before it
    // leaves the screen.
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: GradientAppBar(
          title: Text(l10n.sellerBusinessTitle,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          centerTitle: true,
        ),
        body: RoleBody(
          loading: _isLoading,
          loadingMessage: l10n.sellerBusinessLoading,
          failed: _loadFailed,
          errorTitle: l10n.sellerBusinessLoadFailed,
          onRetry: _load,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_status != null && _step == 0) _statusBanner(l10n),
                    _progress(l10n),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.06, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(_step),
                        child: _stepSection(_step, l10n),
                      ),
                    ),
                  ],
                ),
              ),
              _buttons(l10n),
            ],
          ),
        ),
      ),
    );
  }
}
