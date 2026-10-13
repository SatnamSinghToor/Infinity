import 'package:duggu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../models/address.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/gradient_app_bar.dart';
import 'address_form_screen.dart';
import '../widgets/pressable.dart';

/// The signed-in user's saved delivery addresses: pick the default, edit,
/// delete, or add one (typed, live location, or from the map).
class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({super.key});

  @override
  State<AddressManagementScreen> createState() =>
      _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().loadAddresses();
  }

  Future<void> _openForm([Address? existing]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddressFormScreen(existing: existing)),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              existing == null
                  ? AppLocalizations.of(context).addressAdded
                  : AppLocalizations.of(context).addressUpdated,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          backgroundColor: AppConstants.successColor,
        ),
      );
    }
  }

  Future<void> _setDefault(Address address) async {
    final ok = await context.read<AuthProvider>().setDefaultAddress(address.id);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context).addressDefaultFailed,
                maxLines: 1, overflow: TextOverflow.ellipsis)),
      );
    }
  }

  Future<void> _confirmDelete(Address address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx).addressDeleteTitle),
        content: Text(address.fullAddress),
        actions: [
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx).addressCancel,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.dangerColor,
            ),
            child: Text(AppLocalizations.of(ctx).addressDelete,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await context.read<AuthProvider>().deleteAddress(address.id);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context).addressDeleteFailed,
                maxLines: 1, overflow: TextOverflow.ellipsis)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final addresses = context.watch<AuthProvider>().addresses;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
        title: Text(l10n.addressTitle,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: addresses.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.location, size: 72, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      l10n.addressEmptyTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.addressEmptyBody,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: Pressable(
                          child: ElevatedButton(
                        onPressed: () => _openForm(),
                        child: Text(l10n.addressAdd,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      )),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...addresses.map(_buildAddressCard),
                const SizedBox(height: 4),
                SizedBox(
                  height: 48,
                  child: Pressable(
                      child: OutlinedButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Iconsax.add),
                    label: Text(l10n.addressAddNew,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  )),
                ),
              ],
            ),
    );
  }

  /// Labels live in the database as codes; only the display is translated.
  String _labelText(AppLocalizations l10n, String code) {
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

  IconData _iconFor(String label) {
    switch (label) {
      case 'Home':
        return Iconsax.home;
      case 'Work':
        return Iconsax.briefcase;
      case 'Current location':
        return Iconsax.gps;
      default:
        return Iconsax.location;
    }
  }

  Widget _buildAddressCard(Address address) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: address.isDefault
            ? Border.all(color: AppConstants.primaryColor, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _iconFor(address.label),
                size: 18,
                color: AppConstants.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _labelText(l10n, address.label),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (address.hasPin)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(
                    Iconsax.location_tick,
                    size: 16,
                    color: AppConstants.successColor,
                  ),
                ),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    l10n.addressDefaultBadge,
                    style: GoogleFonts.poppins(
                      color: AppConstants.primaryColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            address.fullAddress,
            style: GoogleFonts.poppins(fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Pressable(
                  child: TextButton.icon(
                onPressed: () => _openForm(address),
                icon: const Icon(Iconsax.edit, size: 16),
                label: Text(l10n.addressEdit,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              )),
              if (!address.isDefault)
                Pressable(
                    child: TextButton(
                  onPressed: () => _setDefault(address),
                  child: Text(l10n.addressSetDefault,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                )),
              Pressable(
                  child: IconButton(
                onPressed: () => _confirmDelete(address),
                icon: const Icon(
                  Iconsax.trash,
                  color: AppConstants.dangerColor,
                  size: 18,
                ),
                tooltip: l10n.addressDelete,
              )),
            ],
          ),
        ],
      ),
    );
  }
}
