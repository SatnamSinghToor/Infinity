import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../utils/constants.dart';
import '../widgets/gradient_app_bar.dart';
import '../utils/format.dart';
import '../widgets/product_card.dart';
import '../widgets/role_common.dart';
import 'product_detail_screen.dart';
import '../widgets/pressable.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wishlistProvider = context.watch<WishlistProvider>();
    final cartProvider = context.watch<CartProvider>();
    final products = wishlistProvider.wishlistedProducts;

    // A wishlist we could not read is not an empty wishlist.
    if (wishlistProvider.loadFailed && products.isEmpty) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: GradientAppBar(
            title: Text(l10n.wishlistTitle,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            centerTitle: true),
        body: RoleError(
          title: l10n.wishlistLoadFailed,
          onRetry: wishlistProvider.loadWishlist,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
        title: Text(l10n.wishlistTitle,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
        actions: [
          if (products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Pressable(
                  child: TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.wishlistClearTitle,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      content: Text(
                        l10n.wishlistClearBody,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(l10n.wishlistCancel,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            wishlistProvider.clear();
                            Navigator.pop(ctx);
                          },
                          child: Text(l10n.wishlistClear,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(
                  l10n.wishlistClear,
                  style: const TextStyle(color: AppConstants.dangerColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )),
            ),
        ],
      ),
      body: products.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.heart_slash,
                      size: 72,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.wishlistEmptyTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.wishlistEmptyBody,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: Pressable(
                          child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(l10n.wishlistBrowse,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      )),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        l10n.wishlistItemsCount(products.length),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        formatRupees(
                            products.fold(0.0, (sum, p) => sum + p.price)),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.55,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailScreen(productId: product.id),
                            ),
                          );
                        },
                        child: ProductCard(product: product),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: 48,
                    child: Pressable(
                        child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        var added = 0;
                        for (final product in products) {
                          if (cartProvider.addToCart(product)) added++;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.wishlistAddedToCart(added),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            backgroundColor: AppConstants.successColor,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      child: Text(
                        l10n.wishlistAddAll,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
    );
  }
}
