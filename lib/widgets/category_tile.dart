import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'app_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../providers/product_provider.dart';
import '../utils/constants.dart';
import 'pressable.dart';

/// Soft warm tints that category tiles cycle through by position.
const categoryTints = [
  Color(0xFFFFF1E0),
  Color(0xFFFFF6D6),
  Color(0xFFFFE9DC),
  Color(0xFFEFF6E8),
  Color(0xFFE8F1F8),
  Color(0xFFFCEBEF),
];

/// A photo to stand in for a category: the first product in it (or, for a
/// top-level category, in any of its sub-categories) that has one.
/// (Categories themselves have no image in the database yet.)
String? categoryImageUrl(ProductProvider provider, String category) {
  for (final product in provider.allProducts) {
    final url = product.imageUrl;
    if (provider.inCategoryGroup(product, category) &&
        url != null &&
        url.isNotEmpty) {
      return url;
    }
  }
  return null;
}

IconData categoryIcon(ProductProvider provider, String category) {
  final index = provider.categories.indexOf(category);
  return index >= 0 && index < provider.categoryIcons.length
      ? provider.categoryIcons[index]
      : Iconsax.category;
}

/// Lets "Fruits/Veggies" wrap after the slash instead of being cut off.
String breakableName(String name) => name.replaceAll('/', '/​');

/// The category picture: a photo on a soft tint, or an icon when there's no
/// photo. Fills the space it is given.
class CategoryArt extends StatelessWidget {
  final String? imageUrl;
  final IconData icon;
  final Color tint;
  final bool circle;
  final double iconSize;

  /// A picture set for the whole tile: it fills the tile behind the photo.
  final String? backgroundUrl;

  /// True when the picture was removed on purpose: nothing is drawn.
  final bool hidePicture;

  const CategoryArt({
    super.key,
    required this.imageUrl,
    required this.icon,
    required this.tint,
    this.circle = false,
    this.iconSize = 30,
    this.backgroundUrl,
    this.hidePicture = false,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Icon(icon, size: iconSize, color: AppConstants.primaryColor),
    );
    final url = imageUrl;

    final Widget content = hidePicture
        ? const SizedBox.shrink()
        : (url == null || url.isEmpty)
            ? fallback
            : Padding(
                padding: const EdgeInsets.all(8),
                child: AppNetworkImage(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => fallback,
                ),
              );

    return Container(
      decoration: BoxDecoration(
        color: tint,
        image: (backgroundUrl ?? '').isEmpty
            ? null
            : DecorationImage(
                image: CachedNetworkImageProvider(backgroundUrl!),
                fit: BoxFit.cover,
              ),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}

/// A category in a grid: picture on top, full (up to two-line) name below.
class CategoryTile extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final IconData icon;
  final Color tint;

  /// A picture set for the whole tile, behind its photo.
  final String? backgroundUrl;

  /// True when the picture was removed on purpose: nothing is drawn.
  final bool hidePicture;
  final VoidCallback onTap;

  const CategoryTile({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.icon,
    required this.tint,
    this.backgroundUrl,
    this.hidePicture = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
        child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: CategoryArt(
              imageUrl: imageUrl,
              icon: icon,
              tint: tint,
              backgroundUrl: backgroundUrl,
              hidePicture: hidePicture,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            breakableName(name),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimaryColor,
            ),
          ),
        ],
      ),
    ));
  }
}
