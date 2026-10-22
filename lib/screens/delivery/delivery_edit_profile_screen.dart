import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/safe_state.dart';
import '../../utils/tokens.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/pressable.dart';
import '../../widgets/role_common.dart';
import '../kyc_documents_screen.dart';

/// Edit Profile for a delivery partner, in two steps as the partner apps
/// do it: who they are (photo, name, date of birth, city, mobile,
/// address), then how they ride (vehicle, its number, the licence, and the
/// ID and licence photos).
class DeliveryEditProfileScreen extends StatefulWidget {
  const DeliveryEditProfileScreen({super.key});

  @override
  State<DeliveryEditProfileScreen> createState() =>
      _DeliveryEditProfileScreenState();
}

class _DeliveryEditProfileScreenState extends State<DeliveryEditProfileScreen> {
  static const _vehicles = ['BIKE', 'SCOOTER', 'EV_SCOOTER', 'BICYCLE'];

  int _step = 0;
  bool _isLoading = true;

  /// A failed load is said out loud, with a retry — never shown as empty
  /// fields a save would then write over the real ones with.
  bool _loadFailed = false;
  bool _saving = false;
  bool _uploadingPhoto = false;

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _vehicleNumber = TextEditingController();
  final _licence = TextEditingController();
  DateTime? _birth;
  String _vehicle = 'BIKE';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _phone,
      _city,
      _address,
      _vehicleNumber,
      _licence
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    safeSetState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final rows = await SupabaseService.client
          .from('delivery_partners')
          .select(
            'full_name, phone, date_of_birth, city, address, vehicle_type, '
            'vehicle_number, licence_number',
          )
          .eq('id', auth.userId)
          .limit(1);
      final row = rows.isEmpty ? const <String, dynamic>{} : rows.first;
      String pick(String? a, String b) =>
          (a != null && a.trim().isNotEmpty) ? a : b;
      safeSetState(() {
        _name.text = pick(auth.userName == 'Guest' ? null : auth.userName,
            (row['full_name'] as String?) ?? '');
        _phone.text = pick(auth.phone, (row['phone'] as String?) ?? '');
        _city.text = (row['city'] as String?) ?? '';
        _address.text = (row['address'] as String?) ?? '';
        _vehicleNumber.text = (row['vehicle_number'] as String?) ?? '';
        _licence.text = (row['licence_number'] as String?) ?? '';
        _birth = DateTime.tryParse((row['date_of_birth'] as String?) ?? '');
        final v = row['vehicle_type'] as String?;
        if (v != null && _vehicles.contains(v)) _vehicle = v;
      });
    } catch (e) {
      debugPrint('Partner profile load failed: $e');
      safeSetState(() => _loadFailed = true);
    }
    safeSetState(() => _isLoading = false);
  }

  Future<void> _pickPhoto() async {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthProvider>();
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    safeSetState(() => _uploadingPhoto = true);
    final ok = await auth.updateAvatar(bytes);
    safeSetState(() => _uploadingPhoto = false);
    if (!ok && mounted) roleSay(context, l10n.profileAvatarFailed);
  }

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 16),
    );
    if (picked != null) safeSetState(() => _birth = picked);
  }

  bool get _stepOneReady =>
      _name.text.trim().isNotEmpty && _phone.text.trim().length >= 10;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthProvider>();
    safeSetState(() => _saving = true);
    try {
      final name = _name.text.trim();
      final phone = _phone.text.trim();
      await SupabaseService.client.from('delivery_partners').upsert({
        'id': auth.userId,
        'full_name': name,
        'email': auth.email,
        'phone': phone,
        'date_of_birth': _birth?.toIso8601String().substring(0, 10),
        'city': _city.text.trim(),
        'address': _address.text.trim(),
        'vehicle_type': _vehicle,
        'vehicle_number': _vehicleNumber.text.trim(),
        'licence_number': _licence.text.trim(),
      });
      final ok = await auth.updateProfile(fullName: name, phone: phone);
      if (!ok) throw Exception('profile row not saved');
      if (!mounted) return;
      roleSay(context, l10n.deliveryEditSaved);
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Partner profile save failed: $e');
      if (mounted) roleSay(context, l10n.deliveryEditSaveFailed);
    } finally {
      safeSetState(() => _saving = false);
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
        child: Text(
          text,
          style: TextStyle(fontSize: 15, color: context.tokens.textPrimary),
        ),
      );

  Widget _field(
    TextEditingController c, {
    TextInputType? keyboard,
    int lines = 1,
    Widget? prefix,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      maxLines: lines,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(prefixIcon: prefix),
    );
  }

  Widget _avatar(double size) {
    final tokens = context.tokens;
    final auth = context.watch<AuthProvider>();
    final url = auth.avatarUrl;
    final name = auth.userName.trim();
    return Pressable(
      child: GestureDetector(
        onTap: _uploadingPhoto ? null : _pickPhoto,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: tokens.primary.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: tokens.primary.withOpacity(0.35),
                  width: size > 80 ? 4 : 2,
                ),
              ),
              child: _uploadingPhoto
                  ? const Center(child: CircularProgressIndicator())
                  : url != null && url.isNotEmpty
                      ? AppNetworkImage(url, fit: BoxFit.cover)
                      : Center(
                          child: Text(
                            name.isEmpty ? '?' : name[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: size * 0.4,
                              fontWeight: FontWeight.w600,
                              color: tokens.primary,
                            ),
                          ),
                        ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.all(size > 80 ? 9 : 4),
                decoration: BoxDecoration(
                  color: tokens.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.card, width: 2),
                ),
                child: Icon(
                  Iconsax.camera,
                  size: size > 80 ? 22 : 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _personal(AppLocalizations l10n) {
    final tokens = context.tokens;
    final birth = _birth;
    String two(int n) => n.toString().padLeft(2, '0');
    return [
      Center(child: _avatar(128)),
      _label(l10n.deliveryEditName),
      _field(_name),
      _label(l10n.deliveryEditEmail),
      // The sign-in email: shown, not edited here.
      InputDecorator(
        decoration: const InputDecoration(enabled: false),
        child: Text(
          context.read<AuthProvider>().email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 16, color: tokens.textSecondary),
        ),
      ),
      _label(l10n.deliveryEditBirth),
      Pressable(
        child: GestureDetector(
          onTap: _pickBirth,
          child: InputDecorator(
            decoration: const InputDecoration(
              suffixIcon: Icon(Iconsax.calendar_1),
            ),
            child: Text(
              birth == null
                  ? l10n.deliveryEditBirthHint
                  : '${birth.year}-${two(birth.month)}-${two(birth.day)}',
              style: TextStyle(
                fontSize: 16,
                color:
                    birth == null ? tokens.textSecondary : tokens.textPrimary,
              ),
            ),
          ),
        ),
      ),
      _label(l10n.deliveryEditCity),
      _field(_city),
      _label(l10n.deliveryEditMobile),
      _field(
        _phone,
        keyboard: TextInputType.phone,
        prefix: const Padding(
          padding: EdgeInsets.fromLTRB(14, 14, 8, 14),
          child: Text('🇮🇳 +91', style: TextStyle(fontSize: 16)),
        ),
      ),
      _label(l10n.deliveryEditAddress),
      _field(_address, lines: 3),
    ];
  }

  List<Widget> _riding(AppLocalizations l10n) {
    final tokens = context.tokens;
    String vehicleName(String v) => switch (v) {
          'BIKE' => l10n.deliveryEditVehicleBike,
          'SCOOTER' => l10n.deliveryEditVehicleScooter,
          'EV_SCOOTER' => l10n.deliveryEditVehicleEv,
          _ => l10n.deliveryEditVehicleBicycle,
        };
    return [
      _label(l10n.deliveryEditVehicle),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final v in _vehicles)
            ChoiceChip(
              label: Text(
                vehicleName(v),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              selected: _vehicle == v,
              showCheckmark: false,
              selectedColor: tokens.primary.withOpacity(0.15),
              onSelected: (_) => setState(() => _vehicle = v),
            ),
        ],
      ),
      _label(l10n.deliveryEditVehicleNumber),
      _field(_vehicleNumber),
      _label(l10n.deliveryEditLicence),
      _field(_licence),
      _label(l10n.deliveryEditDocuments),
      Pressable(
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const KycDocumentsScreen(
                table: 'delivery_partner_documents',
                ownerColumn: 'partner_id',
                bucket: 'delivery-documents',
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.card,
              borderRadius: AppRadius.card,
              border: Border.all(color: tokens.border),
            ),
            child: Row(
              children: [
                Icon(Iconsax.personalcard, color: tokens.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.deliveryEditDocumentsBody,
                    style: TextStyle(color: tokens.textPrimary),
                  ),
                ),
                Icon(Iconsax.arrow_right_3,
                    size: 18, color: tokens.textSecondary),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final first = _step == 0;
    return Scaffold(
      backgroundColor: tokens.surface,
      appBar: AppBar(
        backgroundColor: tokens.card,
        surfaceTintColor: tokens.card,
        toolbarHeight: 72,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () =>
              first ? Navigator.maybePop(context) : setState(() => _step = 0),
        ),
        title: Row(
          children: [
            if (!first) ...[_avatar(46), const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.deliveryEditTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    first ? l10n.deliveryEditStepOne : l10n.deliveryEditStepTwo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 46,
              height: 46,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: first ? 0.5 : 1),
                    duration: const Duration(milliseconds: 300),
                    builder: (_, v, __) => CircularProgressIndicator(
                      value: v,
                      strokeWidth: 3.5,
                      backgroundColor: tokens.border,
                      color: tokens.primary,
                    ),
                  ),
                  Text(
                    first ? '1/2' : '2/2',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: RoleBody(
        loading: _isLoading,
        failed: _loadFailed,
        onRetry: _load,
        loadingMessage: l10n.deliveryEditLoading,
        errorTitle: l10n.deliveryEditLoadFailed,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: first ? _personal(l10n) : _riding(l10n),
        ),
      ),
      bottomNavigationBar: _isLoading || _loadFailed
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: AppControl.lg,
                        child: Pressable(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => first
                                    ? Navigator.maybePop(context)
                                    : setState(() => _step = 0),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: tokens.textPrimary,
                              side: BorderSide(
                                color: tokens.textSecondary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.button,
                                ),
                              ),
                            ),
                            child: Text(
                              first
                                  ? l10n.deliverySettingsCancel
                                  : l10n.deliveryEditBack,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: SizedBox(
                        height: AppControl.lg,
                        child: Pressable(
                          child: ElevatedButton(
                            onPressed: _saving || (first && !_stepOneReady)
                                ? null
                                : () =>
                                    first ? setState(() => _step = 1) : _save(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tokens.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.button,
                                ),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    first
                                        ? l10n.deliveryEditNext
                                        : l10n.deliverySettingsSave,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
