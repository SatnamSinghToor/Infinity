import 'package:flutter/material.dart';

import '../utils/tokens.dart';

/// One part of a long form: a white card with an icon, a title, a line on
/// what the part is for, and its fields. The seller's profile screens are
/// built from these so each group reads as one thing instead of one long
/// run of boxes.
class FormSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  /// Something small at the top right, such as a "2 of 5" count.
  final Widget? trailing;

  const FormSection({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: AppRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: t.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md - 2),
                ),
                child: Icon(icon, size: 18, color: t.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: t.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }
}

/// A form field's spacing and the one border look these screens use.
InputDecoration formFieldDecoration({
  required String label,
  String? hint,
  String? helper,
  String? error,
  IconData? icon,
  String? suffix,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    errorText: error,
    helperMaxLines: 2,
    errorMaxLines: 2,
    prefixIcon: icon == null ? null : Icon(icon, size: 20),
    suffixText: suffix,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    border: const OutlineInputBorder(),
  );
}
