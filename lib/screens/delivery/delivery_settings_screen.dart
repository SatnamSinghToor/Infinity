import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/tokens.dart';
import '../../widgets/pressable.dart';
import '../../widgets/role_common.dart';
import '../help_screens.dart';
import '../notifications_screen.dart';

/// The rider's Settings: their notifications, a new password, and closing
/// the account.
class DeliverySettingsScreen extends StatelessWidget {
  const DeliverySettingsScreen({super.key});

  /// A new password, twice, at least six characters.
  Future<void> _changePassword(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthProvider>();
    final first = TextEditingController();
    final again = TextEditingController();
    String? problem;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(
            l10n.deliverySettingsPassword,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: first,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.deliverySettingsNewPassword,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: again,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.deliverySettingsConfirmPassword,
                  errorText: problem,
                ),
              ),
            ],
          ),
          actions: [
            Pressable(
              child: TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  l10n.deliverySettingsCancel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Pressable(
              child: ElevatedButton(
                onPressed: () async {
                  if (first.text.length < 6) {
                    setState(() => problem = l10n.deliverySettingsTooShort);
                    return;
                  }
                  if (first.text != again.text) {
                    setState(() => problem = l10n.deliverySettingsMismatch);
                    return;
                  }
                  final error = await auth.updatePassword(first.text);
                  if (!ctx.mounted) return;
                  if (error != null) {
                    setState(() => problem = error);
                  } else {
                    Navigator.pop(ctx, true);
                  }
                },
                child: Text(
                  l10n.deliverySettingsSave,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    first.dispose();
    again.dispose();
    if (saved == true && context.mounted) {
      roleSay(context, l10n.deliverySettingsPasswordSaved);
    }
  }

  /// A delivery partner's account has runs and payouts tied to it, so it
  /// is closed by support rather than a button (delete_my_account refuses
  /// it); this says so and takes them there.
  Future<void> _deleteAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.deliverySettingsDelete,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        content: Text(l10n.deliverySettingsDeleteBody),
        actions: [
          Pressable(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                l10n.deliverySettingsCancel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Pressable(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                l10n.deliverySettingsContact,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
    if (go == true && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ContactUsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    Widget row(IconData icon, String label, VoidCallback onTap) => InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
            child: Row(
              children: [
                Icon(icon, size: 22, color: tokens.textPrimary),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, color: tokens.textPrimary),
                  ),
                ),
                Icon(
                  Iconsax.arrow_right_3,
                  size: 18,
                  color: tokens.textSecondary,
                ),
              ],
            ),
          ),
        );
    return Scaffold(
      backgroundColor: tokens.surface,
      appBar: AppBar(
        backgroundColor: tokens.card,
        surfaceTintColor: tokens.card,
        title: Text(
          l10n.deliveryProfileSettings,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: tokens.card,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                  child: Text(
                    l10n.deliverySettingsGeneral,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
                Divider(height: 1, color: tokens.border),
                row(
                  Iconsax.notification,
                  l10n.deliverySettingsNotifications,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                ),
                Divider(height: 1, color: tokens.border),
                row(
                  Iconsax.lock_1,
                  l10n.deliverySettingsPassword,
                  () => _changePassword(context),
                ),
                Divider(height: 1, color: tokens.border),
                row(
                  Iconsax.trash,
                  l10n.deliverySettingsDelete,
                  () => _deleteAccount(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
