import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../screens/search_screen.dart';
import '../utils/constants.dart';
import '../screens/main_shell.dart';
import 'pressable.dart';

/// Shared pieces of the product-listing screens (category, brand, store), so
/// they all look and behave the same.

enum ListingSort { relevance, priceLow, priceHigh, rating, discount }

extension ListingSortLabel on ListingSort {
  String label(AppLocalizations l10n) {
    switch (this) {
      case ListingSort.relevance:
        return l10n.listingRelevance;
      case ListingSort.priceLow:
        return l10n.listingPriceLow;
      case ListingSort.priceHigh:
        return l10n.listingPriceHigh;
      case ListingSort.rating:
        return l10n.listingRating;
      case ListingSort.discount:
        return l10n.listingDiscount;
    }
  }
}

/// Applies the listing's chips (offers, in stock) and sort to [products].
List<Product> applyListingFilters(
  List<Product> products, {
  required bool offersOnly,
  required bool inStockOnly,
  required ListingSort sort,
}) {
  var list = List<Product>.of(products);
  if (offersOnly) list = list.where((p) => p.discountPercent > 0).toList();
  if (inStockOnly) list = list.where((p) => p.stock > 0).toList();
  switch (sort) {
    case ListingSort.relevance:
      break;
    case ListingSort.priceLow:
      list.sort((a, b) => a.price.compareTo(b.price));
    case ListingSort.priceHigh:
      list.sort((a, b) => b.price.compareTo(a.price));
    case ListingSort.rating:
      list.sort((a, b) => b.rating.compareTo(a.rating));
    case ListingSort.discount:
      list.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
  }
  return list;
}

Future<ListingSort?> showSortSheet(BuildContext context, ListingSort current) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<ListingSort>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.listingSortBy,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          for (final option in ListingSort.values)
            ListTile(
              title: Text(option.label(l10n)),
              trailing: option == current
                  ? const Icon(
                      Iconsax.tick_circle,
                      color: AppConstants.primaryColor,
                    )
                  : null,
              onTap: () => Navigator.pop(ctx, option),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Sets no status bar style: the status bar is left to the system, as on Home.
class DarkStatusBar extends StatelessWidget {
  final Widget child;

  const DarkStatusBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Top bar in the app's plain style: a back arrow, the title with the
/// "Delivering to…" line under it, search, and a hairline under it all.
class ListingHeader extends StatelessWidget {
  final String title;

  /// Replaces the delivery-address line when given.
  final String? subtitle;

  /// Rides inside the bar, above its hairline, such as the filter chips.
  final Widget? bottom;

  const ListingHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final address = context.watch<AuthProvider>().address.trim();
    final line = subtitle ??
        (address.isEmpty
            ? l10n.listingSetAddress
            : l10n.listingDeliveringTo(address));

    return Container(
      decoration: const BoxDecoration(
        color: AppConstants.backgroundColor,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEBEBEB)),
        ),
      ),
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 4),
                Pressable(
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, size: 24),
                    color: AppConstants.textPrimaryColor,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.textPrimaryColor,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Iconsax.location_copy,
                            size: 12,
                            color: AppConstants.primaryColor,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              line,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                                color: AppConstants.textSecondaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Pressable(
                  child: IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ),
                    icon: const Icon(Iconsax.search_normal_1_copy, size: 22),
                    color: AppConstants.textPrimaryColor,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          if (bottom != null) bottom!,
        ],
      ),
    );
  }
}

/// The Sort / Offers / In stock chips row.
class ListingFilterRow extends StatelessWidget {
  final ListingSort sort;
  final bool offersOnly;
  final bool inStockOnly;
  final VoidCallback onSortTap;
  final VoidCallback onOffersTap;
  final VoidCallback onInStockTap;

  const ListingFilterRow({
    super.key,
    required this.sort,
    required this.offersOnly,
    required this.inStockOnly,
    required this.onSortTap,
    required this.onOffersTap,
    required this.onInStockTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        children: [
          _chip(
            label: sort == ListingSort.relevance
                ? l10n.listingSort
                : sort.label(l10n),
            icon: Iconsax.sort_copy,
            active: sort != ListingSort.relevance,
            trailing: Iconsax.arrow_down_1_copy,
            onTap: onSortTap,
          ),
          _chip(
            label: l10n.listingOffers,
            icon: Iconsax.discount_shape,
            active: offersOnly,
            onTap: onOffersTap,
          ),
          _chip(
            label: l10n.listingInStock,
            icon: Iconsax.box_tick,
            active: inStockOnly,
            onTap: onInStockTap,
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    IconData? trailing,
  }) {
    final color =
        active ? AppConstants.primaryColor : AppConstants.textPrimaryColor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Pressable(
          child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active
                ? AppConstants.primaryColor.withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? AppConstants.primaryColor
                  : Colors.black.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 2),
                Icon(trailing, size: 15, color: color),
              ],
            ],
          ),
        ),
      )),
    );
  }
}

/// Floating "View cart · N items" pill; empty when the cart is empty.
class ViewCartPill extends StatelessWidget {
  const ViewCartPill({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final count = context.watch<CartProvider>().itemCount;
    if (count == 0) return const SizedBox.shrink();
    return Center(
      child: Pressable(
          child: GestureDetector(
        onTap: () => MainShell.goTo(context, MainShell.cart),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppConstants.primaryColor, Color(0xFFFF8A2B)],
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryColor.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.listingViewCart,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    l10n.homeItemCount(count),
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.22),
                ),
                child: const Icon(
                  Iconsax.arrow_right_3_copy,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }
}

/// Shown when a listing has nothing to show.
class ListingEmpty extends StatelessWidget {
  final bool filtered;

  /// Overrides the usual "nothing here yet" line when a caller has its own.
  final String? message;

  const ListingEmpty({super.key, required this.filtered, this.message});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.box, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              filtered
                  ? l10n.listingNoMatches
                  : message ?? l10n.listingNoProducts,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              filtered
                  ? l10n.listingTryClearingFilters
                  : l10n.listingCheckBackSoon,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
