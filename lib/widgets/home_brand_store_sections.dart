import 'dart:ui' show ImageFilter;
import 'package:duggu/l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'app_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../screens/product_list_screen.dart';
import '../screens/store_screen.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import 'category_tile.dart';

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppConstants.textPrimaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: AppConstants.textSecondaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BrandInfo {
  final String name;
  int count = 0;
  String? imageUrl;

  _BrandInfo(this.name);
}

/// The brands that products in the store actually carry (taken from each
/// product's `brand`), most products first. Empty until sellers fill in a
/// brand on their products.
List<_BrandInfo> _brandsOf(ProductProvider provider) {
  final byKey = <String, _BrandInfo>{};
  for (final product in provider.allProducts) {
    final brand = product.brand?.trim();
    if (brand == null || brand.isEmpty) continue;
    final info =
        byKey.putIfAbsent(brand.toLowerCase(), () => _BrandInfo(brand));
    info.count++;
    final url = product.imageUrl;
    if (info.imageUrl == null && url != null && url.isNotEmpty) {
      info.imageUrl = url;
    }
  }
  return byKey.values.toList()
    ..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0
          ? byCount
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
}

/// "Shop by Brand": one tile per brand found on products (Apple, Samsung, …).
/// Hidden while no product has a brand.
class HomeBrandsSection extends StatelessWidget {
  const HomeBrandsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brands = _brandsOf(context.watch<ProductProvider>());
    if (brands.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: l10n.homeBrandsTitle,
            subtitle: l10n.homeBrandsSubtitle,
          ),
          SizedBox(
            height: 128,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: brands.length,
              itemBuilder: (context, i) {
                final brand = brands[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: SizedBox(
                    width: 88,
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductListScreen(
                            title: brand.name,
                            subtitle: l10n.homeProductCount(brand.count),
                            source: (p) => p.allProducts
                                .where(
                                  (x) =>
                                      x.brand?.trim().toLowerCase() ==
                                      brand.name.toLowerCase(),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 88,
                            height: 88,
                            child: CategoryArt(
                              imageUrl: brand.imageUrl,
                              icon: Iconsax.award,
                              tint: categoryTints[i % categoryTints.length],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            brand.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// "Local Stores": the approved stores that sellers have set up. Tapping one
/// opens its page with its own products. Hidden while there are none.
class HomeStoresSection extends StatefulWidget {
  const HomeStoresSection({super.key});

  @override
  State<HomeStoresSection> createState() => _HomeStoresSectionState();
}

class _HomeStoresSectionState extends State<HomeStoresSection> {
  List<Map<String, dynamic>> _stores = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await SupabaseService.client
          .from('stores')
          .select(
            'id, owner_id, name, description, logo_url, banner_url, address, '
            'city, pincode, rating, is_open, is_approved',
          )
          .order('created_at');
      if (mounted) {
        setState(() => _stores = List<Map<String, dynamic>>.from(rows));
      }
    } catch (_) {
      // Offline: just leave the section out.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_stores.isEmpty) return const SizedBox.shrink();
    final provider = context.watch<ProductProvider>();

    int productCount(Map<String, dynamic> store) => provider.allProducts
        .where((p) => p.sellerId == store['owner_id'])
        .length;

    // A store's name is its business brand. Show stores that are approved or
    // already have products on sale (their products are visible to
    // customers anyway), with the ones that have the most products first.
    final stores = _stores
        .where(
          (s) => (s['is_approved'] as bool? ?? false) || productCount(s) > 0,
        )
        .toList()
      ..sort((a, b) => productCount(b).compareTo(productCount(a)));
    if (stores.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: l10n.homeLocalBrandsTitle,
            subtitle: l10n.homeLocalBrandsSubtitle,
          ),
          SizedBox(
            height: 176,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: stores.length,
              itemBuilder: (context, i) {
                final store = stores[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: _StoreCard(
                    store: store,
                    productCount: productCount(store),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoreScreen(store: store),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// One colour scheme per store: banner gradient plus the panel below it.
class _StorePalette {
  final Color a;
  final Color b;
  final Color panel;

  const _StorePalette(this.a, this.b, this.panel);
}

const _storePalettes = [
  _StorePalette(Color(0xFF7B61FF), Color(0xFF3D2EBF), Color(0xFF241A66)),
  _StorePalette(Color(0xFF12B5A6), Color(0xFF0A6E8F), Color(0xFF0B3B4F)),
  _StorePalette(Color(0xFFFF5FA2), Color(0xFFB3126B), Color(0xFF5C0B39)),
  _StorePalette(Color(0xFF3CC6E8), Color(0xFF1E6FE0), Color(0xFF12327A)),
  _StorePalette(Color(0xFF6CCB5F), Color(0xFF0F7B3F), Color(0xFF0B3F24)),
  _StorePalette(Color(0xFFFF6B6B), Color(0xFFC2185B), Color(0xFF5E0E2D)),
  _StorePalette(Color(0xFF7C8CFF), Color(0xFF2F3FB5), Color(0xFF161E5C)),
];

/// The same store always gets the same colours.
_StorePalette _paletteFor(String name) {
  final sum = name.codeUnits.fold<int>(0, (a, b) => a + b);
  return _storePalettes[sum % _storePalettes.length];
}

/// A store as a business brand: its own banner across the top, its logo on
/// the banner's edge, and its details on a dark panel below. Nothing white;
/// the banner is never cropped (it sits over a blurred copy of itself).
class _StoreCard extends StatelessWidget {
  final Map<String, dynamic> store;
  final int productCount;
  final VoidCallback onTap;

  const _StoreCard({
    required this.store,
    required this.productCount,
    required this.onTap,
  });

  static const _bannerHeight = 98.0;
  static const _logoSize = 58.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = store['name'] as String? ?? l10n.homeStoreFallback;
    final banner = store['banner_url'] as String?;
    final logo = store['logo_url'] as String?;
    final city = (store['city'] as String?)?.trim() ?? '';
    final rating = (store['rating'] as num?)?.toDouble() ?? 0;
    final isOpen = store['is_open'] as bool? ?? true;
    final palette = _paletteFor(name);
    final fallback = [palette.a, palette.b];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 264,
        decoration: BoxDecoration(
          color: palette.panel,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Banner.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: _bannerHeight,
              child: (banner != null && banner.isNotEmpty)
                  ? _banner(banner, fallback)
                  : _gradient(fallback),
            ),
            // Logo, sitting across the banner's bottom edge.
            Positioned(
              left: 14,
              top: _bannerHeight - _logoSize / 2,
              child: Container(
                width: _logoSize,
                height: _logoSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: palette.panel,
                    width: 3,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: (logo != null && logo.isNotEmpty)
                    ? Padding(
                        padding: const EdgeInsets.all(5),
                        child: AppNetworkImage(
                          logo,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              _initial(name, palette.b),
                        ),
                      )
                    : _initial(name, palette.b),
              ),
            ),
            // Name and city, beside the logo.
            Positioned(
              left: 14 + _logoSize + 10,
              right: 12,
              top: _bannerHeight + 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (city.isNotEmpty)
                    Text(
                      city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: Colors.white.withOpacity(0.65),
                      ),
                    ),
                ],
              ),
            ),
            // Rating, open/closed, item count.
            Positioned(
              left: 14,
              right: 14,
              bottom: 10,
              child: Row(
                children: [
                  if (rating > 0) ...[
                    const Icon(
                      Iconsax.star_1,
                      size: 15,
                      color: AppConstants.accentColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      rating.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (isOpen
                              ? AppConstants.successColor
                              : AppConstants.dangerColor)
                          .withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isOpen ? l10n.homeOpen : l10n.homeClosed,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isOpen
                            ? const Color(0xFF7BE07F)
                            : const Color(0xFFFF8A80),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l10n.homeItemCount(productCount),
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.accentColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradient(List<Color> colors) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
    );
  }

  /// The whole banner, uncropped: sharp in the middle, with a blurred,
  /// enlarged copy filling any space left at the sides.
  Widget _banner(String url, List<Color> fallback) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _gradient(fallback),
        ClipRect(
          child: Transform.scale(
            scale: 1.25,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: AppNetworkImage(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        ColoredBox(color: Colors.black.withOpacity(0.12)),
        AppNetworkImage(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _initial(String name, Color color) {
    return Center(
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
