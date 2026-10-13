import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/tokens.dart';
import 'pressable.dart';

typedef RoleNavItem = ({IconData outline, IconData filled, String label});

/// Same visual style as the customer [BottomNavWidget], generalized so
/// seller/delivery/admin dashboards can each pass their own destinations.
/// [currentIndex] normally stays 0 (Home) — the rest are pushed as
/// separate screens rather than swapped in place, matching how the
/// customer bottom nav behaves.
class RoleBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<RoleNavItem> items;

  const RoleBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: tokens.card,
          borderRadius: AppRadius.card,
          border:
              Border.all(color: Colors.black.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = currentIndex == index;
            return Pressable(
                child: GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  isSelected
                      ? ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [tokens.primary, tokens.accent],
                          ).createShader(bounds),
                          child: Icon(
                            item.filled,
                            color: Colors.white,
                            size: 21,
                          ),
                        )
                      // 21px, like the icons inside the app and the
                      // customer bar.
                      : Icon(item.outline, color: tokens.textPrimary, size: 21),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: isSelected ? tokens.primary : tokens.textPrimary,
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ));
          }),
        ),
      ),
    );
  }
}
