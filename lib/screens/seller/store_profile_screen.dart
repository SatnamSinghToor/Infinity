import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as ll;

import 'package:supabase/supabase.dart' show FileOptions;

import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/tokens.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/adaptive_image.dart';
import 'store_location_picker_screen.dart';
import '../../widgets/role_common.dart';
import '../../utils/safe_state.dart';
import '../../widgets/pressable.dart';
import '../../utils/indian_ids.dart';
import '../../widgets/form_section.dart';
import '../../widgets/osm_attribution.dart';

/// Lets a seller create/edit their public `stores` profile — name, logo,
/// banner, address, delivery radius and open/closed status. `is_approved`
/// and `rating` are shown but never written here: approval is an admin
/// decision and rating is computed elsewhere, so this screen only ever
/// touches the fields a store owner is meant to control.
class StoreProfileScreen extends StatefulWidget {
  const StoreProfileScreen({super.key});

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  bool _isLoading = true;

  /// Whether the last load failed: said out loud, with a way to try
  /// again, instead of passing off a failed request as empty.
  bool _loadFailed = false;
  bool _isSaving = false;
  String? _storeId;
  Map<String, dynamic>? _store;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _radiusController = TextEditingController(text: '10');
  bool _isOpen = true;

  // Store pin (stores.lat / stores.lng); null until the seller sets one.
  double? _lat;
  double? _lng;

  Uint8List? _logoBytes;
  Uint8List? _bannerBytes;

  /// What is wrong with the pincode after the last save, if anything.
  String? _pincodeError;

  String? get _userId => SupabaseService.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _radiusController.dispose();
    super.dispose();
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
          .from('stores')
          .select()
          .eq('owner_id', uid)
          .limit(1);
      if (rows.isNotEmpty) {
        final store = rows.first;
        _storeId = store['id'] as String;
        _store = store;
        _nameController.text = store['name'] as String? ?? '';
        _descriptionController.text = store['description'] as String? ?? '';
        _addressController.text = store['address'] as String? ?? '';
        _cityController.text = store['city'] as String? ?? '';
        _pincodeController.text = store['pincode'] as String? ?? '';
        _radiusController.text = '${store['delivery_radius_km'] ?? 10}';
        _isOpen = store['is_open'] as bool? ?? true;
        _lat = (store['lat'] as num?)?.toDouble();
        _lng = (store['lng'] as num?)?.toDouble();
      } else {
        // Prefill from the seller's business profile for a faster first save.
        final sellerRows = await SupabaseService.client
            .from('sellers')
            .select('business_name, business_address')
            .eq('id', uid)
            .limit(1);
        if (sellerRows.isNotEmpty) {
          _nameController.text =
              sellerRows.first['business_name'] as String? ?? '';
          _addressController.text =
              sellerRows.first['business_address'] as String? ?? '';
        }
      }
    } catch (_) {
      safeSetState(() => _loadFailed = true);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickImage({required bool isBanner}) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      if (isBanner) {
        _bannerBytes = bytes;
      } else {
        _logoBytes = bytes;
      }
    });
  }

  bool get _hasPin => _lat != null && _lng != null;

  Future<void> _openLocationPicker() async {
    final l10n = AppLocalizations.of(context);
    final typedAddress = [
      _addressController.text,
      _cityController.text,
      _pincodeController.text,
    ].map((s) => s.trim()).where((s) => s.isNotEmpty).join(', ');

    final result = await Navigator.push<StoreLocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => StoreLocationPickerScreen(
          initial: _hasPin ? ll.LatLng(_lat!, _lng!) : null,
          initialQuery: typedAddress,
          title: l10n.sellerStorePickTitle,
          searchHint: l10n.sellerStorePickHint,
          confirmLabel: l10n.sellerStorePickConfirm,
        ),
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      _lat = result.lat;
      _lng = result.lng;
    });

    // Offer the pin's address for the manual fields, but never silently
    // overwrite something the seller already typed.
    if (result.address.isEmpty) return;
    final fieldsEmpty = _addressController.text.trim().isEmpty;
    var useIt = fieldsEmpty;
    if (!fieldsEmpty && _addressController.text.trim() != result.address) {
      useIt = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.sellerStoreUpdateAddressTitle),
              content: Text(
                l10n.sellerStoreUpdateAddressBody(result.address),
              ),
              actions: [
                Pressable(
                    child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.sellerStoreKeepMine,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                )),
                Pressable(
                    child: TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.sellerStoreUseThis,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                )),
              ],
            ),
          ) ??
          false;
    }
    if (!useIt || !mounted) return;
    setState(() {
      _addressController.text = result.address;
      if (result.city.isNotEmpty) _cityController.text = result.city;
      if (result.pincode.isNotEmpty) _pincodeController.text = result.pincode;
    });
  }

  Future<String?> _uploadImage(
      String uid, Uint8List bytes, String label) async {
    try {
      final path =
          '$uid/store_${label}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await SupabaseService.client.storage.from('product-images').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      return SupabaseService.client.storage
          .from('product-images')
          .getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  String _slugify(String name) {
    final base = name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'(^-|-$)'), '');
    final suffix = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return '${base.isEmpty ? 'store' : base}-$suffix';
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final uid = _userId;
    if (uid == null) return;
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.sellerStoreErrName,
                maxLines: 1, overflow: TextOverflow.ellipsis)),
      );
      return;
    }
    final pin = _pincodeController.text.trim();
    if (pin.isNotEmpty && !IndianIds.isPincode(pin)) {
      setState(() => _pincodeError = l10n.sellerStoreErrPincode);
      return;
    }

    setState(() => _isSaving = true);
    try {
      String? logoUrl = _store?['logo_url'] as String?;
      String? bannerUrl = _store?['banner_url'] as String?;
      if (_logoBytes != null) {
        logoUrl = await _uploadImage(uid, _logoBytes!, 'logo') ?? logoUrl;
      }
      if (_bannerBytes != null) {
        bannerUrl =
            await _uploadImage(uid, _bannerBytes!, 'banner') ?? bannerUrl;
      }

      final data = {
        'owner_id': uid,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'delivery_radius_km':
            double.tryParse(_radiusController.text.trim()) ?? 10,
        'is_open': _isOpen,
        if (_lat != null && _lng != null) ...{'lat': _lat, 'lng': _lng},
        if (logoUrl != null) 'logo_url': logoUrl,
        if (bannerUrl != null) 'banner_url': bannerUrl,
      };

      if (_storeId != null) {
        await SupabaseService.client
            .from('stores')
            .update(data)
            .eq('id', _storeId!);
      } else {
        data['slug'] = _slugify(_nameController.text.trim());
        final inserted = await SupabaseService.client
            .from('stores')
            .insert(data)
            .select('id')
            .single();
        _storeId = inserted['id'] as String;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.sellerStoreSaved,
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.sellerStoreSaveFailed,
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Which step the seller is on: 0 about, 1 branding, 2 address,
  /// 3 delivery, 4 open & save. One short page at a time instead of the
  /// whole profile in one scroll.
  int _step = 0;
  static const _stepCount = 5;

  /// What must be right before leaving step [step]; says what is wrong
  /// and returns false when it isn't.
  bool _stepValid(int step, AppLocalizations l10n) {
    if (step == 0 && _nameController.text.trim().isEmpty) {
      roleSay(context, l10n.sellerStoreErrName);
      return false;
    }
    if (step == 2) {
      final pin = _pincodeController.text.trim();
      if (pin.isNotEmpty && !IndianIds.isPincode(pin)) {
        setState(() => _pincodeError = l10n.sellerStoreErrPincode);
        return false;
      }
    }
    return true;
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (!_stepValid(_step, AppLocalizations.of(context))) return;
    setState(() => _step++);
  }

  void _back() {
    FocusScope.of(context).unfocus();
    setState(() => _step--);
  }

  /// Save from the last step: an earlier step that isn't right yet takes
  /// the seller back to it, instead of failing somewhere they can't see.
  Future<void> _finish() async {
    final l10n = AppLocalizations.of(context);
    for (final step in [0, 2]) {
      if (!_stepValid(step, l10n)) {
        setState(() => _step = step);
        return;
      }
    }
    await _save();
  }

  Widget _stepSection(int i, AppLocalizations l10n) {
    switch (i) {
      case 0:
        return FormSection(
          icon: Iconsax.shop,
          title: l10n.sellerStoreSectionAbout,
          subtitle: l10n.sellerStoreSectionAboutBody,
          children: [
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: formFieldDecoration(
                label: l10n.sellerStoreNameLabel,
                icon: Iconsax.shop,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              decoration: formFieldDecoration(
                label: l10n.sellerStoreDescriptionLabel,
                hint: l10n.sellerStoreDescriptionHint,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        );
      case 1:
        return FormSection(
          icon: Iconsax.gallery,
          title: l10n.sellerStoreSectionBranding,
          subtitle: l10n.sellerStoreSectionBrandingBody,
          children: [
            _buildImagePicker(
              label: l10n.sellerStoreBannerLabel,
              bytes: _bannerBytes,
              existingUrl: _store?['banner_url'] as String?,
              height: 120,
              maxHeight: 220,
              onTap: () => _pickImage(isBanner: true),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildImagePicker(
              label: l10n.sellerStoreLogoLabel,
              bytes: _logoBytes,
              existingUrl: _store?['logo_url'] as String?,
              height: 90,
              maxHeight: 220,
              onTap: () => _pickImage(isBanner: false),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      case 2:
        return FormSection(
          icon: Iconsax.location,
          title: l10n.sellerStoreSectionAddress,
          subtitle: l10n.sellerStoreSectionAddressBody,
          children: [
            TextField(
              controller: _addressController,
              textCapitalization: TextCapitalization.sentences,
              decoration: formFieldDecoration(
                label: l10n.sellerStoreAddressLabel,
                icon: Iconsax.location,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityController,
                    textCapitalization: TextCapitalization.words,
                    decoration: formFieldDecoration(
                      label: l10n.sellerStoreCityLabel,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: IndianIds.digits(6),
                    onChanged: (_) {
                      if (_pincodeError != null) {
                        setState(() => _pincodeError = null);
                      }
                    },
                    decoration: formFieldDecoration(
                      label: l10n.sellerStorePincodeLabel,
                      hint: '125120',
                      error: _pincodeError,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      case 3:
        return FormSection(
          icon: Iconsax.truck_fast,
          title: l10n.sellerStoreSectionDelivery,
          subtitle: l10n.sellerStoreSectionDeliveryBody,
          children: [
            _buildLocationCard(),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _radiusController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: formFieldDecoration(
                label: l10n.sellerStoreRadiusLabel,
                helper: l10n.sellerStoreRadiusHelper,
                icon: Iconsax.routing,
                suffix: 'km',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      default:
        return Column(
          children: [
            _completeness(l10n),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.card,
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.sellerStoreOpen),
                subtitle: Text(
                  _isOpen
                      ? l10n.sellerStoreOpenBody
                      : l10n.sellerStoreClosedBody,
                  style: const TextStyle(fontSize: 12.5),
                ),
                value: _isOpen,
                activeThumbColor: AppConstants.primaryColor,
                onChanged: (v) => setState(() => _isOpen = v),
              ),
            ),
          ],
        );
    }
  }

  /// "Step 2 of 5", the step's name, and a bar filled up to here.
  Widget _progress(AppLocalizations l10n) {
    final names = [
      l10n.sellerStoreSectionAbout,
      l10n.sellerStoreSectionBranding,
      l10n.sellerStoreSectionAddress,
      l10n.sellerStoreSectionDelivery,
      l10n.sellerStoreStepFinish,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.sellerStoreStepOf(_step + 1, _stepCount),
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

  /// Approval and rating, shown once on the first step.
  Widget _statusRow(AppLocalizations l10n) {
    final approved = _store!['is_approved'] as bool? ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusChip(
                label: approved
                    ? l10n.sellerStoreApproved
                    : l10n.sellerStorePendingApproval,
                color: approved ? AppConstants.successColor : Colors.orange,
              ),
              const SizedBox(width: 8),
              _StatusChip(
                label:
                    '${(_store!['rating'] as num?)?.toStringAsFixed(1) ?? '0.0'} ★',
                color: AppConstants.primaryColor,
              ),
            ],
          ),
          if (!approved) ...[
            const SizedBox(height: 6),
            Text(
              l10n.sellerStorePendingBody,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: AppConstants.textSecondaryColor,
              ),
            ),
          ],
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
                    child: Text(l10n.sellerStoreBack,
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
                  onPressed: _isSaving ? null : (last ? _finish : _next),
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
                          last ? l10n.sellerStoreSave : l10n.sellerStoreNext,
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
            title: Text(l10n.sellerStoreTitle,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            centerTitle: true),
        body: RoleBody(
          loading: _isLoading,
          loadingMessage: l10n.sellerStoreLoading,
          failed: _loadFailed,
          errorTitle: l10n.sellerStoreLoadFailed,
          onRetry: _load,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_store != null && _step == 0) _statusRow(l10n),
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

  /// How much of the store page is filled in, and what is still missing:
  /// a store without a photo, a description or a pin sells less, and the
  /// seller should see that at a glance.
  Widget _completeness(AppLocalizations l10n) {
    bool has(TextEditingController c) => c.text.trim().isNotEmpty;
    final checks = <(bool, String)>[
      (
        _bannerBytes != null || _store?['banner_url'] != null,
        l10n.sellerStoreMissingBanner
      ),
      (
        _logoBytes != null || _store?['logo_url'] != null,
        l10n.sellerStoreMissingLogo
      ),
      (has(_descriptionController), l10n.sellerStoreMissingDescription),
      (
        has(_addressController) &&
            has(_cityController) &&
            has(_pincodeController),
        l10n.sellerStoreMissingAddress
      ),
      (_hasPin, l10n.sellerStoreMissingPin),
    ];
    final done = checks.where((c) => c.$1).length;
    if (done == checks.length) return const SizedBox.shrink();
    final missing = [
      for (final c in checks)
        if (!c.$1) c.$2
    ];
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
          Text(
            l10n.sellerStoreComplete((done * 100 / checks.length).round()),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: done / checks.length,
              minHeight: 6,
              backgroundColor: const Color(0xFFEFEFEF),
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.sellerStoreStillMissing(missing.join(', ')),
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

  /// Store pin: a small read-only map once set, or a prompt to set it.
  /// Tapping either opens the full-screen picker (live GPS, address search,
  /// or dragging the map).
  Widget _buildLocationCard() {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasPin)
            GestureDetector(
              onTap: _openLocationPicker,
              child: SizedBox(
                height: 150,
                child: IgnorePointer(
                  child: FlutterMap(
                    // A new key per pin so the preview recentres after edits.
                    key: ValueKey('$_lat,$_lng'),
                    options: MapOptions(
                      initialCenter: ll.LatLng(_lat!, _lng!),
                      initialZoom: 15,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.duggustore.app',
                      ),
                      const OsmAttribution(),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: ll.LatLng(_lat!, _lng!),
                            width: 44,
                            height: 44,
                            alignment: Alignment.topCenter,
                            child: const Icon(
                              Iconsax.location_copy,
                              size: 44,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _hasPin ? Iconsax.location_tick : Iconsax.location_add,
                      size: 20,
                      color: _hasPin
                          ? AppConstants.successColor
                          : AppConstants.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _hasPin
                            ? l10n.sellerStorePinSet(
                                _lat!.toStringAsFixed(4),
                                _lng!.toStringAsFixed(4),
                              )
                            : l10n.sellerStorePinNotSet,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.sellerStorePinHelp,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: Pressable(
                      child: OutlinedButton.icon(
                    onPressed: _openLocationPicker,
                    icon:
                        Icon(_hasPin ? Iconsax.edit_2 : Iconsax.gps, size: 18),
                    label: Text(
                      _hasPin
                          ? l10n.sellerStoreChangeLocation
                          : l10n.sellerStoreSetLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.primaryColor,
                      side: const BorderSide(color: AppConstants.primaryColor),
                    ),
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker({
    required String label,
    required Uint8List? bytes,
    required String? existingUrl,
    required double height,
    required double maxHeight,
    required VoidCallback onTap,
  }) {
    final ImageProvider? image = bytes != null
        ? MemoryImage(bytes)
        : (existingUrl != null
            ? CachedNetworkImageProvider(existingUrl)
            : null);

    // Once a photo is chosen the box takes the photo's own shape (no crop);
    // the fixed-height box is only the empty "add a photo" state.
    if (image != null) {
      return GestureDetector(
        onTap: onTap,
        child: AdaptiveImage(
          image: image,
          maxHeight: maxHeight,
          borderRadius: BorderRadius.circular(12),
          overlay: Align(
            alignment: Alignment.bottomRight,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.edit_2, color: Colors.white, size: 16),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.gallery_add, color: Colors.grey),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).sellerStoreAddPhoto(label),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
