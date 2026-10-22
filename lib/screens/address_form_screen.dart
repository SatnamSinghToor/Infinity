import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';

import '../models/address.dart';
import '../providers/auth_provider.dart';
import '../services/device_location_service.dart';
import '../services/geocoding_service.dart';
import '../utils/constants.dart';
import '../utils/tokens.dart';
import '../widgets/gradient_app_bar.dart';
import 'seller/store_location_picker_screen.dart';
import '../widgets/pressable.dart';

/// Add or edit a delivery address. Three ways to fill it in, mix as you like:
///  * type it,
///  * "Use current location" (GPS, then the address is looked up),
///  * "Choose on map" (search or drag the pin).
/// Signed-in users save it to their account; guests keep it on the phone.
/// Pops with `true` once saved.
class AddressFormScreen extends StatefulWidget {
  final Address? existing;

  const AddressFormScreen({super.key, this.existing});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  static const _labels = ['Home', 'Work', 'Other'];

  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  String _label = 'Home';
  double? _lat;
  double? _lng;
  bool _isLocating = false;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  /// The label is stored as a code ('Home', 'Work', …) so it never changes
  /// language in the database; only what the customer reads is translated.
  static String _labelText(AppLocalizations l10n, String code) {
    switch (code) {
      case 'Home':
        return l10n.addressLabelHome;
      case 'Work':
        return l10n.addressLabelWork;
      case 'Current location':
        return l10n.addressLabelCurrent;
      default:
        return l10n.addressLabelOther;
    }
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _addressController.text = existing.fullAddress;
      _label = _labels.contains(existing.label) ? existing.label : 'Other';
      _lat = existing.lat;
      _lng = existing.lng;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _toast(String message, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
          action: action));
  }

  Future<void> _useCurrentLocation() async {
    if (_isLocating) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _isLocating = true);
    try {
      final position = await DeviceLocationService.current();
      final place = await GeocodingService.reverse(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        if (place != null && place.address.isNotEmpty) {
          _addressController.text = place.address;
        }
      });
      if (place == null || place.address.isEmpty) {
        _toast(l10n.addressLocateFailed);
      }
    } on LocationException catch (e) {
      _toast(
        e.message,
        action: e.canOpenSettings
            ? SnackBarAction(
                label: l10n.addressSettings,
                onPressed: Geolocator.openAppSettings,
              )
            : null,
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _chooseOnMap() async {
    final result = await Navigator.push<StoreLocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => StoreLocationPickerScreen(
          initial:
              (_lat != null && _lng != null) ? ll.LatLng(_lat!, _lng!) : null,
          initialQuery: _addressController.text.trim(),
          title: AppLocalizations.of(context).addressPickTitle,
          searchHint: AppLocalizations.of(context).addressPickHint,
          confirmLabel: AppLocalizations.of(context).addressConfirmLocation,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _lat = result.lat;
      _lng = result.lng;
      if (result.address.isNotEmpty) _addressController.text = result.address;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final text = _addressController.text.trim();

    setState(() => _isSaving = true);
    bool ok;
    if (!auth.isLoggedIn) {
      await auth.setLocalAddress(text, lat: _lat, lng: _lng);
      ok = true;
    } else {
      final address = Address(
        id: widget.existing?.id ?? '',
        label: _label,
        fullAddress: text,
        lat: _lat,
        lng: _lng,
        // A new address becomes the one orders go to.
        isDefault: widget.existing?.isDefault ?? true,
      );
      ok = _isEditing
          ? await auth.updateAddress(address.id, address)
          : await auth.addAddress(address);
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      _toast(AppLocalizations.of(context).addressSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;
    final hasPin = _lat != null && _lng != null;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
        title: Text(
            _isEditing ? l10n.addressFormEditTitle : l10n.addressFormAddTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      icon: _isLocating ? null : Iconsax.gps,
                      label: l10n.addressUseCurrent,
                      busy: _isLocating,
                      onTap: _useCurrentLocation,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionButton(
                      icon: Iconsax.location,
                      label: l10n.addressChooseMap,
                      onTap: _chooseOnMap,
                    ),
                  ),
                ],
              ),
              if (hasPin) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.location_tick,
                        size: 18,
                        color: AppConstants.successColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.addressMapSet('${_lat!.toStringAsFixed(4)}, '
                              '${_lng!.toStringAsFixed(4)}'),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.successColor,
                          ),
                        ),
                      ),
                      Pressable(
                          child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() {
                          _lat = null;
                          _lng = null;
                        }),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Iconsax.close_circle_copy, size: 18),
                        ),
                      )),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (loggedIn) ...[
                Text(
                  l10n.addressSaveAs,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final label in _labels)
                      ChoiceChip(
                        label: Text(_labelText(l10n, label),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        selected: _label == label,
                        selectedColor:
                            AppConstants.primaryColor.withOpacity(0.15),
                        onSelected: (_) => setState(() => _label = label),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _addressController,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.addressFullLabel,
                  hintText: l10n.addressFullHint,
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => (value ?? '').trim().length < 8
                    ? l10n.addressFullError
                    : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: AppControl.lg,
                child: Pressable(
                    child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing
                              ? l10n.addressSaveChanges
                              : l10n.addressSaveAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required VoidCallback onTap,
    IconData? icon,
    bool busy = false,
  }) {
    return Pressable(
        child: OutlinedButton(
      onPressed: busy ? null : onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppConstants.primaryColor,
        side: const BorderSide(color: AppConstants.primaryColor),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (busy)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(icon, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ));
  }
}
