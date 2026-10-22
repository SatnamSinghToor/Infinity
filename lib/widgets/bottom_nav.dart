import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../utils/tokens.dart';
import 'pressable.dart';

class BottomNavWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavWidget({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// Every icon is drawn to fill the same [_iconBox]. The glyphs come with
  /// different amounts of empty margin, so each has its own size to make
  /// them look equally big. About 21px: the size of the icons inside the app,
  /// where 24-25 (and 29 once chosen) made the bar the heaviest thing on
  /// every screen.
  static const _iconBox = 24.0;

  static const _items = [
    (icon: Iconsax.home, size: 21.2),
    (icon: Iconsax.category, size: 21.2),
    (icon: Iconsax.shopping_cart, size: 20.0),
    (icon: Iconsax.user, size: 20.3),
  ];

  /// The labels, in the same order as [_items] — read from the string files
  /// (lib/l10n/app_en.arb) instead of being spelled out here, so the bar
  /// speaks whichever language the app is showing. This is the first widget
  /// to move over; the screens follow it one at a time.
  static List<String> _labels(AppLocalizations l10n) => [
        l10n.navHome,
        l10n.navCategories,
        l10n.navCart,
        l10n.navProfile,
      ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final labels = _labels(AppLocalizations.of(context));
    return SafeArea(
      top: false,
      minimum: EdgeInsets.zero,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: tokens.card,
          borderRadius: AppRadius.card,
          border:
              Border.all(color: Colors.black.withOpacity(0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final isSelected = currentIndex == index;
            // Each item gets an equal-width slot, so the icons are evenly
            // spaced no matter how long the labels are.
            return Expanded(
              child: Pressable(
                  child: GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The same icon in both states: the chosen one just
                    // fills with the orange gradient and grows a little.
                    SizedBox(
                      width: _iconBox,
                      height: _iconBox,
                      child: Center(
                        child: AnimatedScale(
                          scale: isSelected ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutBack,
                          child: isSelected
                              ? ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [tokens.primary, tokens.accent],
                                  ).createShader(bounds),
                                  child: Icon(
                                    item.icon,
                                    color: Colors.white,
                                    size: item.size,
                                  ),
                                )
                              : Icon(
                                  item.icon,
                                  color: tokens.textPrimary,
                                  size: item.size,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      labels[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: isSelected ? tokens.primary : tokens.textPrimary,
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    // A small orange pointer on the bar's bottom edge, under
                    // the chosen tab.
                    SizedBox(
                      height: 14,
                      width: 26,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          height: isSelected ? 7 : 0,
                          width: 26,
                          child: CustomPaint(
                            painter: _PointerPainter(tokens.primary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            );
          }),
        ),
      ),
    );
  }
}

/// A low triangle with a rounded tip, pointing up.
class _PointerPainter extends CustomPainter {
  const _PointerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, h)
      ..lineTo(w * 0.38, h * 0.16)
      ..quadraticBezierTo(w * 0.5, 0, w * 0.62, h * 0.16)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PointerPainter old) => old.color != color;
}
