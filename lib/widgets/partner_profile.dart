import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../providers/auth_provider.dart';
import '../utils/tokens.dart';
import 'app_network_image.dart';

/// The pieces the seller's and the rider's Profile tabs are built from, so
/// the two partner apps look and behave the same: who is signed in at the
/// top, then grouped white cards of rows.

/// Who is signed in: the photo (or the name's first letter), the name, and
/// the email and phone they are reached on.
class PartnerProfileHeader extends StatelessWidget {
  final AuthProvider auth;

  /// A line under the name — the rider's online status, say.
  final Widget? badge;

  const PartnerProfileHeader({super.key, required this.auth, this.badge});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final name = auth.userName.trim();
    final url = auth.avatarUrl;
    Widget line(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(icon, size: 15, color: tokens.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                ),
              ),
            ],
          ),
        );
    Widget initial() => Center(
          child: Text(
            name.isEmpty ? '?' : name[0].toUpperCase(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: tokens.primary,
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: tokens.primary.withOpacity(0.12),
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
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                if (auth.email.trim().isNotEmpty)
                  line(Iconsax.sms, auth.email.trim()),
                if (auth.phone.trim().isNotEmpty)
                  line(Iconsax.call, auth.phone.trim()),
                if (badge != null) ...[
                  const SizedBox(height: 6),
                  badge!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A small grey heading and a white card holding its rows, a hairline
/// between each.
class PartnerGroup extends StatelessWidget {
  final String? title;
  final List<PartnerRow> rows;

  const PartnerGroup({super.key, this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                title!.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: tokens.textSecondary,
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: tokens.card,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, indent: 62, color: tokens.border),
                  rows[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One row: a tinted icon, the title with an optional line under it, and
/// an arrow — or, for [danger], red and without the arrow.
class PartnerRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;

  const PartnerRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = danger ? tokens.danger : tokens.primary;
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: danger ? tokens.danger : tokens.textPrimary,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: danger
          ? null
          : Icon(
              Iconsax.arrow_right_3,
              size: 16,
              color: tokens.textSecondary,
            ),
    );
  }
}
