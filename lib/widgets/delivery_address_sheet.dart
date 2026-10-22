import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/address_form_screen.dart';
import '../screens/seller/store_location_picker_screen.dart';
import '../services/device_location_service.dart';
import '../services/geocoding_service.dart';
import '../utils/constants.dart';
import 'pressable.dart';

/// "Where should we deliver?" — opened from the address line on Home. Live
/// location, a pin on the map, a typed address, or (when signed in) one of
/// the saved addresses. Works for guests too; theirs is kept on the phone.
Future<void> showDeliveryAddressSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _DeliveryAddressSheet(pageContext: context),
  );
}

class _DeliveryAddressSheet extends StatefulWidget {
  /// The screen that opened the sheet — used to push screens and show
  /// messages after the sheet has closed.
  final BuildContext pageContext;

  const _DeliveryAddressSheet({required this.pageContext});

  @override
  State<_DeliveryAddressSheet> createState() => _DeliveryAddressSheetState();
}

class _DeliveryAddressSheetState extends State<_DeliveryAddressSheet> {
  bool _isLocating = false;

  void _message(String text, {SnackBarAction? action}) {
    final page = widget.pageContext;
    if (!page.mounted) return;
    ScaffoldMessenger.of(page)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
          action: action));
  }

  Future<void> _useCurrentLocation() async {
    if (_isLocating) return;
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthProvider>();
    setState(() => _isLocating = true);
    try {
      final position = await DeviceLocationService.current();
      final place = await GeocodingService.reverse(
        position.latitude,
        position.longitude,
      );
      final address = (place?.address.isNotEmpty ?? false)
          ? place!.address
          : l10n.addressCurrentFallback(
              '${position.latitude.toStringAsFixed(4)}, '
              '${position.longitude.toStringAsFixed(4)}');
      final ok = await auth.setDeliveryLocation(
        address,
        lat: position.latitude,
        lng: position.longitude,
      );
      if (!mounted) return;
      Navigator.pop(context);
      _message(
        ok ? l10n.addressDeliveringTo(address) : l10n.addressSaveFailed,
      );
    } on LocationException catch (e) {
      _message(
        e.message,
        action: e.canOpenSettings
            ? SnackBarAction(
                label: l10n.addressSettings,
                onPressed: Geolocator.openAppSettings,
              )
            : null,
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _chooseOnMap() async {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthProvider>();
    final page = widget.pageContext;
    final navigator = Navigator.of(page);
    final lat = auth.deliveryLat;
    final lng = auth.deliveryLng;
    Navigator.pop(context);

    final result = await navigator.push<StoreLocationResult>(
      MaterialPageRoute(
        builder: (_) => StoreLocationPickerScreen(
          initial: (lat != null && lng != null) ? ll.LatLng(lat, lng) : null,
          title: l10n.addressPickTitle,
          searchHint: l10n.addressPickHint,
          confirmLabel: l10n.addressDeliverHere,
        ),
      ),
    );
    if (result == null) return;
    final address = result.address.isNotEmpty
        ? result.address
        : l10n.addressPinnedFallback('${result.lat.toStringAsFixed(4)}, '
            '${result.lng.toStringAsFixed(4)}');
    final ok = await auth.setDeliveryLocation(
      address,
      lat: result.lat,
      lng: result.lng,
      label: 'Other',
    );
    _message(
      ok ? l10n.addressDeliveringTo(address) : l10n.addressSaveFailed,
    );
  }

  void _addManually() {
    final page = widget.pageContext;
    final navigator = Navigator.of(page);
    Navigator.pop(context);
    navigator.push(
      MaterialPageRoute(builder: (_) => const AddressFormScreen()),
    );
  }

  /// Labels are stored as codes; only what is shown is translated.
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

  Future<void> _pickSaved(String id, String address) async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.setDefaultAddress(id);
    if (!mounted) return;
    Navigator.pop(context);
    _message(
      ok
          ? AppLocalizations.of(context).addressDeliveringTo(address)
          : AppLocalizations.of(context).addressChangeFailed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final saved = auth.addresses;
    final current = auth.address;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.addressChooseTitle,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            _optionTile(
              icon: Iconsax.gps,
              title: l10n.addressUseCurrent,
              subtitle: l10n.addressFindWhere,
              busy: _isLocating,
              onTap: _useCurrentLocation,
            ),
            _optionTile(
              icon: Iconsax.location,
              title: l10n.addressChooseMap,
              subtitle: l10n.addressDragPin,
              onTap: _chooseOnMap,
            ),
            _optionTile(
              icon: Iconsax.edit,
              title: l10n.addressAddManually,
              subtitle: l10n.addressTypeFull,
              onTap: _addManually,
            ),
            if (saved.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                l10n.addressSavedHeading,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textSecondaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              for (final a in saved)
                InkWell(
                  onTap: () => _pickSaved(a.id, a.fullAddress),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          a.isDefault
                              ? Iconsax.record_circle
                              : Iconsax.record_circle_copy,
                          size: 20,
                          color: a.isDefault
                              ? AppConstants.primaryColor
                              : Colors.grey,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _labelText(l10n, a.label),
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                a.fullAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppConstants.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ] else if (current.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                l10n.addressCurrentHeading,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textSecondaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Iconsax.record_circle,
                    size: 20,
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      current,
                      style: GoogleFonts.poppins(fontSize: 12.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool busy = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Pressable(
          child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(icon, size: 18, color: AppConstants.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: AppConstants.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Iconsax.arrow_right_3_copy, color: Colors.grey),
            ],
          ),
        ),
      )),
    );
  }
}
