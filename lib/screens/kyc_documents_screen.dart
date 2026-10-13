import 'dart:typed_data';
import 'package:duggu/l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase/supabase.dart' show FileOptions;

import '../services/supabase_service.dart';
import '../utils/constants.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/role_common.dart';
import '../utils/safe_state.dart';
import '../widgets/pressable.dart';
import '../utils/tokens.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// Shared KYC document upload screen for both sellers and delivery
/// partners — the two tables (seller_documents / delivery_partner_documents)
/// share the same doc_type/status shape, just a different owner column,
/// table name, and private storage bucket.
class KycDocumentsScreen extends StatefulWidget {
  final String table;
  final String ownerColumn;
  final String bucket;

  const KycDocumentsScreen({
    super.key,
    required this.table,
    required this.ownerColumn,
    required this.bucket,
  });

  @override
  State<KycDocumentsScreen> createState() => _KycDocumentsScreenState();
}

class _KycDocumentsScreenState extends State<KycDocumentsScreen> {
  /// Document codes go to the database, the names are what is shown. Each
  /// carries what a good upload looks like, an icon, and whether it is
  /// needed (GST and FSSAI only apply to some sellers).
  static List<_Doc> _docTypes(AppLocalizations l10n) => [
        _Doc('PAN', l10n.kycDocPan, l10n.kycHintPan, Iconsax.personalcard,
            required: true),
        _Doc('GST_CERTIFICATE', l10n.kycDocGst, l10n.kycHintGst,
            Iconsax.receipt_2),
        _Doc('FSSAI_LICENSE', l10n.kycDocFssai, l10n.kycHintFssai,
            Iconsax.document_text),
        _Doc('BANK_PROOF', l10n.kycDocBankProof, l10n.kycHintBank, Iconsax.bank,
            required: true),
        _Doc('ADDRESS_PROOF', l10n.kycDocAddressProof, l10n.kycHintAddress,
            Iconsax.location,
            required: true),
      ];

  /// Statuses are stored as codes too.
  static String _statusText(AppLocalizations l10n, String status) {
    switch (status) {
      case 'VERIFIED':
        return l10n.kycStatusVerified;
      case 'REJECTED':
        return l10n.kycStatusRejected;
      case 'PENDING':
        return l10n.kycStatusUnderReview;
      default:
        return l10n.kycStatusPending;
    }
  }

  bool _isLoading = true;

  /// Whether the last load failed. Every document reads as "not uploaded
  /// yet" when the list is empty, and asking someone to upload their PAN
  /// again because a request died is worse than saying it failed.
  bool _loadFailed = false;
  final Map<String, Map<String, dynamic>> _documents = {};
  final Set<String> _uploading = {};

  String? get _uid => SupabaseService.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _uid;
    if (uid == null) return;
    safeSetState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final rows = await SupabaseService.client
          .from(widget.table)
          .select()
          .eq(widget.ownerColumn, uid);
      _documents.clear();
      for (final row in rows) {
        _documents[row['doc_type'] as String] = row;
      }
    } catch (_) {
      safeSetState(() => _loadFailed = true);
    }
    safeSetState(() => _isLoading = false);
  }

  Future<void> _upload(String docType) async {
    final uid = _uid;
    if (uid == null) return;

    // A document is as often photographed on the spot as found in the
    // gallery, so the seller chooses.
    final source = await _chooseSource();
    if (source == null) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;

    safeSetState(() => _uploading.add(docType));
    try {
      final Uint8List bytes = await picked.readAsBytes();
      final path = '$uid/$docType.jpg';
      await SupabaseService.client.storage.from(widget.bucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );
      await SupabaseService.client.from(widget.table).upsert({
        widget.ownerColumn: uid,
        'doc_type': docType,
        'file_url': path,
        'status': 'PENDING',
        'rejection_reason': null,
      }, onConflict: '${widget.ownerColumn},doc_type');
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context).kycUploadFailed,
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
        );
      }
    } finally {
      if (mounted) safeSetState(() => _uploading.remove(docType));
    }
  }

  Future<ImageSource?> _chooseSource() {
    final l10n = AppLocalizations.of(context);
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Iconsax.camera),
                title: Text(l10n.kycTakePhoto),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Iconsax.gallery),
                title: Text(l10n.kycFromGallery),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// How far the seller has got: required documents verified, of all
  /// required ones.
  Widget _progress(AppLocalizations l10n, List<_Doc> docs) {
    final required = docs.where((d) => d.required).toList();
    final verified = required
        .where((d) => _documents[d.type]?['status'] == 'VERIFIED')
        .length;
    final uploaded =
        required.where((d) => _documents.containsKey(d.type)).length;
    final done = verified == required.length;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                done ? Iconsax.verify : Iconsax.shield_search,
                color: done ? AppConstants.successColor : Colors.orange,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  done
                      ? l10n.kycAllVerified
                      : l10n.kycProgress(verified, required.length),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: required.isEmpty ? 0 : verified / required.length,
              minHeight: 6,
              backgroundColor: const Color(0xFFEFEFEF),
              color: done ? AppConstants.successColor : Colors.orange,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            done
                ? l10n.kycAllVerifiedBody
                : uploaded < required.length
                    ? l10n.kycUploadRemaining(required.length - uploaded)
                    : l10n.kycUnderReviewBody,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: AppConstants.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'VERIFIED':
        return AppConstants.successColor;
      case 'REJECTED':
        return AppConstants.dangerColor;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Every document reads as "not uploaded yet" when the list is empty, so a
    // load that failed has to say so — otherwise someone whose PAN is already
    // on file is asked to upload it again. Same shape as the other screens
    // that guard their body: its own Scaffold, one item, a way back.
    final l10n = AppLocalizations.of(context);
    final docTypes = _docTypes(l10n);
    if (_loadFailed && _documents.isEmpty) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: GradientAppBar(
            title: Text(l10n.kycTitle,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            centerTitle: true),
        body: RoleError(
          title: l10n.kycLoadFailed,
          onRetry: _load,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
          title:
              Text(l10n.kycTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                children: [
                  _progress(l10n, docTypes),
                  for (final d in docTypes) ...[
                    _docCard(l10n, d),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _docCard(AppLocalizations l10n, _Doc d) {
    final doc = _documents[d.type];
    final status = doc?['status'] as String?;
    final isUploading = _uploading.contains(d.type);
    final color =
        status == null ? AppConstants.textSecondaryColor : _statusColor(status);
    final reason = (doc?['rejection_reason'] as String?)?.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.card,
        border: status == 'REJECTED'
            ? Border.all(color: AppConstants.dangerColor.withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              status == 'VERIFIED' ? Iconsax.tick_circle : d.icon,
              size: 20,
              color: status == null ? AppConstants.primaryColor : color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        d.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      d.required ? l10n.kycRequired : l10n.kycOptional,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: d.required
                            ? AppConstants.primaryColor
                            : AppConstants.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  d.hint,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status == null
                        ? l10n.kycNotUploaded
                        : _statusText(l10n, status),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                if (status == 'REJECTED') ...[
                  const SizedBox(height: 6),
                  Text(
                    reason.isEmpty ? l10n.kycRejectedHelp : reason,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppConstants.dangerColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (isUploading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          // A verified document is done; replacing it would send it back to
          // review, so it is not offered.
          else if (status != 'VERIFIED')
            Pressable(
                child: OutlinedButton(
              onPressed: () => _upload(d.type),
              child: Text(doc == null ? l10n.kycUpload : l10n.kycReplace,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            )),
        ],
      ),
    );
  }
}

class _Doc {
  final String type;
  final String label;
  final String hint;
  final IconData icon;
  final bool required;

  const _Doc(this.type, this.label, this.hint, this.icon,
      {this.required = false});
}
