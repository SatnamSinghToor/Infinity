import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/tokens.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../utils/safe_state.dart';
import '../../widgets/role_common.dart';

/// Lists individual reviews across all of a seller's products — the
/// dashboard's stat card only ever showed the average, never the actual
/// comments customers left.
class SellerReviewsScreen extends StatefulWidget {
  const SellerReviewsScreen({super.key});

  @override
  State<SellerReviewsScreen> createState() => _SellerReviewsScreenState();
}

class _SellerReviewsScreenState extends State<SellerReviewsScreen> {
  bool _isLoading = true;

  /// Whether the last load failed: said out loud, with a way to try
  /// again, instead of passing off a failed request as empty.
  bool _loadFailed = false;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().userId;
    safeSetState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final products = await SupabaseService.client
          .from('products')
          .select('id')
          .eq('seller_id', userId);
      final productIds =
          products.map((p) => p['id'] as String).toList(growable: false);

      List<Map<String, dynamic>> reviews = [];
      if (productIds.isNotEmpty) {
        reviews = List<Map<String, dynamic>>.from(
          await SupabaseService.client
              .from('reviews')
              .select('rating, comment, created_at, products(name)')
              .inFilter('product_id', productIds)
              .order('created_at', ascending: false),
        );
      }
      safeSetState(() => _reviews = reviews);
    } catch (_) {
      safeSetState(() => _loadFailed = true);
    }
    safeSetState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
          title: Text(l10n.sellerReviewsTitle,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          centerTitle: true),
      body: RoleBody(
        loading: _isLoading,
        loadingMessage: l10n.sellerReviewsLoading,
        failed: _loadFailed,
        errorTitle: l10n.sellerReviewsLoadFailed,
        onRetry: _load,
        child: _reviews.isEmpty
            ? RoleEmpty(
                icon: Iconsax.star,
                title: l10n.sellerReviewsEmptyTitle,
                message: l10n.sellerReviewsEmptyBody,
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reviews.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.listGap),
                  itemBuilder: (context, index) {
                    final r = _reviews[index];
                    final rating = (r['rating'] as num?)?.toInt() ?? 0;
                    final productName =
                        (r['products'] as Map?)?['name'] as String? ??
                            l10n.sellerReviewsProductFallback;
                    final comment = r['comment'] as String? ?? '';

                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadius.card,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < rating
                                        ? Iconsax.star
                                        : Iconsax.star_copy,
                                    size: 14,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (comment.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              comment,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: AppConstants.textSecondaryColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
