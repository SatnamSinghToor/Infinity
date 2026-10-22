import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../utils/tokens.dart';

/// A delivery run's two stops, top to bottom: where to collect it and
/// where it goes — each with its own label, so a rider reads the route at a
/// glance instead of working out which address is which.
class RunStops extends StatelessWidget {
  final String pickLabel;
  final String pickTitle;
  final String? pickAddress;
  final String dropLabel;
  final String dropAddress;

  const RunStops({
    super.key,
    required this.pickLabel,
    required this.pickTitle,
    this.pickAddress,
    required this.dropLabel,
    required this.dropAddress,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Stop(
          icon: Iconsax.shop,
          color: t.primary,
          label: pickLabel,
          title: pickTitle,
          subtitle: pickAddress,
          showLine: true,
        ),
        _Stop(
          icon: Iconsax.location,
          color: t.success,
          label: dropLabel,
          title: dropAddress,
        ),
      ],
    );
  }
}

class _Stop extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String title;
  final String? subtitle;
  final bool showLine;

  const _Stop({
    required this.icon,
    required this.color,
    required this.label,
    required this.title,
    this.subtitle,
    this.showLine = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 17, color: color),
                ),
                // Joins the pickup to the drop-off, like a route.
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: t.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showLine ? 12 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (subtitle != null && subtitle!.trim().isNotEmpty)
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: t.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
