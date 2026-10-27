import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../utils/constants.dart';
import '../widgets/plain_app_bar.dart';
import '../widgets/category_tile.dart';
import 'brands_screen.dart';
import 'category_listing_screen.dart';
import 'deals_screen.dart';
import 'main_shell.dart';

/// The Categories tab: every main category as a tile. Tapping one opens
/// [CategoryListingScreen] — its sub-categories on the left, their products
/// on the right.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  void _open(BuildContext context, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CategoryListingScreen(title: name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    // Skip the synthetic "All" entry that leads the strip on Home.
    final all = provider.categories.skip(1).toList();
    // Hide main categories that have neither products nor sub-categories yet.
    final stocked = all
        .where(
          (name) =>
              provider.subCategoriesOf(name).isNotEmpty ||
              provider.allProducts
                  .any((p) => provider.inCategoryGroup(p, name)),
        )
        .toList();
    final names = stocked.isEmpty ? all : stocked;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: PlainAppBar(
        titleText: 'Categories',
        onBack: () => MainShell.tab.value = MainShell.home,
      ),
      body: RefreshIndicator(
        onRefresh: provider.reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            32 + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Shop by category',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimaryColor,
                ),
              ),
            ),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 0.68,
              children: [
                for (var i = 0; i < names.length; i++)
                  CategoryTile(
                    name: names[i],
                    imageUrl: categoryImageUrl(provider, names[i]),
                    icon: categoryIcon(provider, names[i]),
                    tint: categoryTints[i % categoryTints.length],
                    onTap: () => _open(context, names[i]),
                  ),
                CategoryTile(
                  name: 'Deals',
                  imageUrl: null,
                  icon: Iconsax.tag,
                  tint: categoryTints[names.length % categoryTints.length],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DealsScreen()),
                  ),
                ),
                CategoryTile(
                  name: 'Brands',
                  imageUrl: null,
                  icon: Iconsax.shopping_bag,
                  tint:
                      categoryTints[(names.length + 1) % categoryTints.length],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BrandsScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
