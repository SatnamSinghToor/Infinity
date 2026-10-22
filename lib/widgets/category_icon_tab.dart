import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/constants.dart';
import 'pressable.dart';

/// A circular icon + label category tab, used in the light header strip.
/// The selected tab gets a filled gradient circle and an underline bar.
class CategoryIconTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  /// The idle ink of the icon. Each chip hands its own accent so the strip
  /// reads as a family of coloured storefronts; the selected chip paints
  /// the label white over the app's gradient instead.
  final Color accent;

  const CategoryIconTab({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.accent = const Color(0xFF6B7280),
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
        child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: 68,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? null : Colors.white,
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [
                            AppConstants.primaryColor,
                            AppConstants.accentColor,
                          ],
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected
                      ? Colors.white
                      : accent,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppConstants.textPrimaryColor
                      : AppConstants.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 3,
                width: isSelected ? 20 : 0,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
