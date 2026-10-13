import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/app_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../utils/constants.dart';
import '../widgets/adaptive_image.dart';
import 'product_list_screen.dart';

/// A local store's page: its banner, logo and details, then its products.
/// [store] is a row from the `stores` table.
class StoreScreen extends StatelessWidget {
  final Map<String, dynamic> store;

  const StoreScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ownerId = store['owner_id'] as String?;
    final name = store['name'] as String? ?? l10n.homeStoreFallback;

    return ProductListScreen(
      title: name,
      subtitle: [store['city'], store['pincode']]
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .join(' • '),
      source: (provider) =>
          provider.allProducts.where((p) => p.sellerId == ownerId).toList(),
      header: _StoreHeader(store: store),
      emptyMessage: l10n.storeNoProducts,
    );
  }
}

class _StoreHeader extends StatelessWidget {
  final Map<String, dynamic> store;

  const _StoreHeader({required this.store});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = store['name'] as String? ?? l10n.homeStoreFallback;
    final banner = store['banner_url'] as String?;
    final logo = store['logo_url'] as String?;
    final description = (store['description'] as String?)?.trim() ?? '';
    final address = (store['address'] as String?)?.trim() ?? '';
    final rating = (store['rating'] as num?)?.toDouble() ?? 0;
    final isOpen = store['is_open'] as bool? ?? true;

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The whole banner, never cropped.
          if (banner != null && banner.isNotEmpty)
            AdaptiveImage(
              image: CachedNetworkImageProvider(banner),
              maxHeight: 190,
              backgroundColor: const Color(0xFFF2F2F2),
            )
          else
            Container(
              height: 84,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppConstants.primaryColor, AppConstants.accentColor],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF2F2F2),
                    border:
                        Border.all(color: Colors.black.withOpacity(0.06)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (logo != null && logo.isNotEmpty)
                      ? Padding(
                          padding: const EdgeInsets.all(6),
                          child: AppNetworkImage(
                            logo,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _initial(name),
                          ),
                        )
                      : _initial(name),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (rating > 0) ...[
                            const Icon(
                              Iconsax.star_1,
                              size: 16,
                              color: Color(0xFFFFA000),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          _statusChip(context, isOpen),
                        ],
                      ),
                      if (address.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Iconsax.location,
                                size: 14,
                                color: AppConstants.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppConstants.textSecondaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppConstants.textPrimaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _initial(String name) {
    return Center(
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppConstants.primaryColor,
        ),
      ),
    );
  }

  Widget _statusChip(BuildContext context, bool open) {
    final l10n = AppLocalizations.of(context);
    final color = open ? AppConstants.successColor : AppConstants.dangerColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        open ? l10n.storeStatusOpen : l10n.storeStatusClosed,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
