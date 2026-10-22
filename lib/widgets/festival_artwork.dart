import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'app_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../screens/search_screen.dart';
import '../utils/tokens.dart';
import 'pressable.dart';

void _search(BuildContext context, List<String> terms) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => SearchScreen(initialTerms: terms)),
  );
}

/// "Put together the perfect pooja thali": the artwork, and a button that
/// searches the store for the things it lists.
class PoojaThaliCard extends StatelessWidget {
  static const _terms = [
    'diya',
    'agarbatti',
    'kumkum',
    'haldi',
    'coconut',
    'kapoor',
    'flowers',
  ];

  const PoojaThaliCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/festival/pooja_chokey.jpg',
              width: double.infinity,
              fit: BoxFit.fitWidth,
              cacheWidth: 1080,
            ),
          ),
          const SizedBox(height: 12),
          Pressable(
              child: GestureDetector(
            onTap: () => _search(context, _terms),
            child: Container(
              height: AppControl.lg,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Color(0xFFB8741F), Color(0xFF8A5A1C)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8A5A1C).withOpacity(0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.festivalSeeAllPooja,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Iconsax.arrow_right_3_copy,
                    size: 18,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}

/// "Bhog & Festive Feasts": the banner and four tiles under it. Each tile
/// shows a real product from the store that matches it and opens a search for
/// that group's items.
class BhogFeastsSection extends StatelessWidget {
  /// The headings are shown; the terms are what searches and product names
  /// are matched against, so those stay as they are.
  static List<({String title, List<String> terms})> _tiles(
    AppLocalizations l10n,
  ) {
    return [
      (
        title: l10n.festivalTileModak,
        terms: [
          'rice flour',
          'jaggery',
          'ghee',
          'coconut',
          'flour',
          'atta',
          'milk'
        ],
      ),
      (
        title: l10n.festivalTileBhog,
        terms: [
          'ghee',
          'sugar',
          'cashew',
          'almond',
          'raisin',
          'dry fruits',
          'sweets',
          'paneer',
          'milk'
        ],
      ),
      (
        title: l10n.festivalTileStaples,
        terms: ['atta', 'dal', 'oil', 'rice'],
      ),
      (
        title: l10n.festivalTileCookware,
        terms: ['cooker', 'kadhai', 'cookware', 'kitchenware', 'appliances'],
      ),
    ];
  }

  static const _backdrop = Color(0xFFF5E4C3);

  const BhogFeastsSection({super.key});

  /// The first product with a picture that matches one of [terms], trying
  /// the terms in order.
  static String? _imageFor(List<Product> products, List<String> terms) {
    for (final term in terms) {
      for (final p in products) {
        if ((p.imageUrl ?? '').isEmpty) continue;
        final text = '${p.name} ${p.category} ${p.brand ?? ''}'.toLowerCase();
        // Whole words only, so "pan" doesn't match "Sampann".
        if (RegExp('\\b${RegExp.escape(term)}\\b').hasMatch(text)) {
          return p.imageUrl;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tiles = _tiles(l10n);
    final products = context.watch<ProductProvider>().allProducts;
    return Container(
      margin: const EdgeInsets.only(top: 32),
      decoration: const BoxDecoration(
        color: _backdrop,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      // The heading's picture runs to the right edge, so it has to be held
      // inside the band's own rounded corners instead of cutting past them.
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Heading on the left, the modak photo running off the right edge.
          Padding(
            padding: const EdgeInsets.only(top: 24, left: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.festivalBhogKicker,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          letterSpacing: 2.6,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9A6A3A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.festivalBhogTitle,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 31,
                          height: 1.12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFC4531A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.festivalBhogSubtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          height: 1.35,
                          color: const Color(0xFF8A5A1C),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(24),
                  ),
                  child: Image.asset(
                    'assets/festival/modak_box.jpg',
                    width: 148,
                    height: 190,
                    fit: BoxFit.cover,
                    cacheWidth: 500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Row(
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _FeastTile(
                      title: tiles[i].title,
                      imageUrl: _imageFor(products, tiles[i].terms),
                      onTap: () => _search(context, tiles[i].terms),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeastTile extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final VoidCallback onTap;

  const _FeastTile({
    required this.title,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 0.85,
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFD9721A), Color(0xFFB85510)],
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  child: imageUrl == null
                      ? const Icon(
                          Iconsax.shopping_bag,
                          color: Colors.white54,
                          size: 34,
                        )
                      : Container(
                          color: Colors.white.withOpacity(0.92),
                          padding: const EdgeInsets.all(6),
                          child: AppNetworkImage(
                            imageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox(),
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
