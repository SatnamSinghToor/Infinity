import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/tokens.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/pressable.dart';
import '../auth/login_screen.dart';
import '../help_screens.dart';
import '../support_chat_screen.dart';
import 'delivery_edit_profile_screen.dart';
import 'delivery_settings_screen.dart';

/// The rider's My Profile tab, as the partner apps lay it out: who is
/// signed in with an Edit button, then Help & Support, the policies (folded
/// away until asked for), and Settings and Log out under Account.
class DeliveryMoreScreen extends StatelessWidget {
  const DeliveryMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final auth = context.watch<AuthProvider>();
    void open(Widget screen) => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
    return Scaffold(
      backgroundColor: tokens.surface,
      body: Column(
        children: [
          Container(
            color: tokens.card,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 60,
                child: Row(
                  children: [
                    if (Navigator.canPop(context))
                      IconButton(
                        icon: const Icon(Iconsax.arrow_left_copy),
                        onPressed: () => Navigator.maybePop(context),
                      )
                    else
                      const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n.deliveryMoreTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _ProfileCard(
                  auth: auth,
                  editLabel: l10n.deliveryProfileEdit,
                  onEdit: () => open(const DeliveryEditProfileScreen()),
                ),
                _Section(
                  title: l10n.deliveryProfileSupport,
                  children: [
                    _Row(
                      icon: Iconsax.message_text,
                      label: l10n.deliveryProfileChat,
                      onTap: () => open(const SupportChatScreen()),
                    ),
                    _Row(
                      icon: Iconsax.star,
                      label: l10n.profileRateUs,
                      onTap: () => showRateUsSheet(context),
                    ),
                  ],
                ),
                _Section(
                  title: l10n.deliveryProfilePolicies,
                  children: [
                    _Folded(
                      icon: Iconsax.shield_tick,
                      label: l10n.deliveryProfilePolicies,
                      children: [
                        _Row(
                          label: l10n.deliveryProfilePrivacy,
                          onTap: () => open(const PoliciesScreen()),
                        ),
                        _Row(
                          label: l10n.deliveryProfileTerms,
                          onTap: () => open(const TermsScreen()),
                        ),
                      ],
                    ),
                  ],
                ),
                _Section(
                  title: l10n.deliveryProfileAccount,
                  children: [
                    _Row(
                      icon: Iconsax.setting_2,
                      label: l10n.deliveryProfileSettings,
                      onTap: () => open(const DeliverySettingsScreen()),
                    ),
                    _Row(
                      icon: Iconsax.logout,
                      label: l10n.deliveryMoreLogout,
                      onTap: () async {
                        await context.read<AuthProvider>().signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The photo, name and email, and the Edit button.
class _ProfileCard extends StatelessWidget {
  final AuthProvider auth;
  final String editLabel;
  final VoidCallback onEdit;

  const _ProfileCard({
    required this.auth,
    required this.editLabel,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final name = auth.userName.trim();
    final url = auth.avatarUrl;
    Widget initial() => Center(
          child: Text(
            name.isEmpty ? '?' : name[0].toUpperCase(),
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: tokens.primary,
            ),
          ),
        );
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: tokens.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: url != null && url.isNotEmpty
                ? AppNetworkImage(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => initial(),
                  )
                : initial(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? '—' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
                if (auth.email.trim().isNotEmpty)
                  Text(
                    auth.email.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: tokens.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Pressable(
            child: TextButton.icon(
              onPressed: onEdit,
              icon: Icon(Iconsax.edit_2, size: 18, color: tokens.textPrimary),
              label: Text(
                editLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: tokens.textPrimary),
              ),
              style: TextButton.styleFrom(
                backgroundColor: tokens.surfaceAlt,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A white card with its heading inside it and a hairline under the
/// heading and between the rows.
class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
          ),
          for (final child in children) ...[
            Divider(height: 1, color: tokens.border),
            child,
          ],
        ],
      ),
    );
  }
}

/// One row: an outline icon (or an indent, inside a folded group), its
/// label, and a chevron.
class _Row extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback onTap;

  const _Row({this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(icon == null ? 58 : 18, 16, 16, 16),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22, color: tokens.textPrimary),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, color: tokens.textPrimary),
              ),
            ),
            Icon(Iconsax.arrow_right_3, size: 18, color: tokens.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// A row that opens to show more rows under it, with a chevron that turns.
class _Folded extends StatefulWidget {
  final IconData icon;
  final String label;
  final List<Widget> children;

  const _Folded({
    required this.icon,
    required this.label,
    required this.children,
  });

  @override
  State<_Folded> createState() => _FoldedState();
}

class _FoldedState extends State<_Folded> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
            child: Row(
              children: [
                Icon(widget.icon, size: 22, color: tokens.textPrimary),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, color: tokens.textPrimary),
                  ),
                ),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Iconsax.arrow_down_1,
                    size: 18,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: _open
              ? Column(
                  children: [
                    for (final child in widget.children) ...[
                      Divider(height: 1, color: tokens.border),
                      child,
                    ],
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
