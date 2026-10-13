import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../models/address.dart';
import '../providers/auth_provider.dart';
import '../screens/address_management_screen.dart';
import '../utils/tokens.dart';
import 'pressable.dart';

/// Blinkit's "Select delivery address" sheet: the saved addresses, the one
/// in use ticked, and a way to add a new one. Returns the address picked,
/// or null when the sheet was closed (or sent off to add one).
Future<Address?> showAddressPicker(
  BuildContext context, {
  String? current,
}) {
  final auth = context.read<AuthProvider>();
  // A sheet opened before the list arrived still fills in once it does.
  if (auth.addresses.isEmpty) auth.loadAddresses();
  return showModalBottomSheet<Address>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.tokens.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheet) => _AddressPicker(current: current),
  );
}

class _AddressPicker extends StatelessWidget {
  final String? current;

  const _AddressPicker({this.current});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final saved = context.watch<AuthProvider>().addresses;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          children: [
            Text(
              l10n.checkoutPickAddress,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Pressable(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: tokens.primary,
                  side: BorderSide(color: tokens.border),
                  alignment: Alignment.centerLeft,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Iconsax.add_copy, size: 20),
                label: Text(
                  l10n.checkoutAddAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddressManagementScreen(),
                    ),
                  );
                },
              ),
            ),
            if (saved.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.checkoutSavedAddresses,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              for (final address in saved)
                _AddressRow(
                  address: address,
                  selected: address.fullAddress.trim() == current?.trim(),
                  onTap: () => Navigator.pop(context, address),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final Address address;
  final bool selected;
  final VoidCallback onTap;

  const _AddressRow({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final label = address.label.trim().isEmpty ? 'Home' : address.label;
    return Pressable(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                selected ? tokens.primary.withOpacity(0.06) : tokens.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? tokens.primary : tokens.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tokens.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  label == 'Work'
                      ? Iconsax.briefcase
                      : label == 'Home'
                          ? Iconsax.home_2
                          : Iconsax.location,
                  size: 20,
                  color: selected ? tokens.primary : tokens.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: tokens.textPrimary,
                            ),
                          ),
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: tokens.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              l10n.checkoutDefaultBadge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: tokens.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      address.fullAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    Iconsax.tick_circle,
                    size: 20,
                    color: tokens.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Who takes the order at the door. Asked only when the account has no
/// name or phone yet — Blinkit's "receiver details" step. Returns the pair,
/// or null when the sheet was closed.
Future<(String, String)?> showReceiverSheet(
  BuildContext context, {
  required String name,
  required String phone,
}) {
  return showModalBottomSheet<(String, String)>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.tokens.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ReceiverSheet(name: name, phone: phone),
  );
}

class _ReceiverSheet extends StatefulWidget {
  final String name;
  final String phone;

  const _ReceiverSheet({required this.name, required this.phone});

  @override
  State<_ReceiverSheet> createState() => _ReceiverSheetState();
}

class _ReceiverSheetState extends State<_ReceiverSheet> {
  late final _name = TextEditingController(text: widget.name);
  late final _phone = TextEditingController(text: widget.phone);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _ready =>
      _name.text.trim().isNotEmpty && _phone.text.trim().length >= 10;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.checkoutReceiverTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.checkoutFullName,
                  prefixIcon: const Icon(Iconsax.user),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.checkoutPhoneNumber,
                  prefixIcon: const Icon(Iconsax.call),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Pressable(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _ready
                        ? () => Navigator.pop(
                              context,
                              (_name.text.trim(), _phone.text.trim()),
                            )
                        : null,
                    child: Text(
                      l10n.checkoutSaveAndProceed,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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
