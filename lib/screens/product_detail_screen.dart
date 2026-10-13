import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../models/review.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/analytics.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import '../utils/description_sections.dart';
import '../utils/tokens.dart';
import '../utils/safe_state.dart';
import '../utils/format.dart';
import '../widgets/cart_action.dart';
import '../widgets/role_common.dart';
import '../widgets/product_hero.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/edit_badge.dart';
import '../widgets/product_gallery.dart';
import '../widgets/product_card.dart';
import 'main_shell.dart';
import 'product_list_screen.dart';
import '../widgets/pressable.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  /// The card this page was opened from, if it was opened from one: the big
  /// photo then flies out of that card instead of simply appearing.
  late final Object _heroTag = ProductHero.tagFor(widget.productId);

  List<Review> _reviews = [];
  bool _isLoadingReviews = true;
  List<Map<String, dynamic>> _variants = [];
  bool _variantsFailed = false;
  bool _reviewsFailed = false;
  String? _selectedVariantId;
  bool _isSubscribedToStock = false;
  bool _isTogglingStockAlert = false;

  @override
  void initState() {
    super.initState();
    // Which products get opened — the other half of the add-to-cart signal.
    Analytics.log('product_view', {'product_id': widget.productId});
    _loadReviews();
    _loadVariants();
    _loadStockAlertState();
  }

  Future<void> _loadStockAlertState() async {
    final uid = SupabaseService.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final rows = await SupabaseService.client
          .from('stock_alerts')
          .select('id')
          .eq('user_id', uid)
          .eq('product_id', widget.productId)
          .limit(1);
      if (mounted) {
        safeSetState(() => _isSubscribedToStock = rows.isNotEmpty);
      }
    } catch (_) {
      // Best-effort: until this lands the bell simply reads as "not
      // subscribed", and tapping it still works either way — a stale bell
      // state is cosmetic, the alert write below is what matters.
    }
  }

  Future<void> _toggleStockAlert() async {
    final uid = SupabaseService.client.auth.currentUser?.id;
    if (uid == null) return;
    safeSetState(() => _isTogglingStockAlert = true);
    try {
      if (_isSubscribedToStock) {
        await SupabaseService.client
            .from('stock_alerts')
            .delete()
            .eq('user_id', uid)
            .eq('product_id', widget.productId);
      } else {
        await SupabaseService.client.from('stock_alerts').insert({
          'user_id': uid,
          'product_id': widget.productId,
        });
      }
      if (mounted) {
        safeSetState(() => _isSubscribedToStock = !_isSubscribedToStock);
      }
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.productDetailNotifyFailed,
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
        );
      }
    } finally {
      if (mounted) safeSetState(() => _isTogglingStockAlert = false);
    }
  }

  Future<void> _loadVariants() async {
    if (mounted) safeSetState(() => _variantsFailed = false);
    try {
      final rows = await SupabaseService.client
          .from('product_variants')
          .select()
          .eq('product_id', widget.productId)
          .eq('is_active', true)
          .order('price');
      if (mounted) {
        safeSetState(() {
          _variants = List<Map<String, dynamic>>.from(rows);
          if (_variants.isNotEmpty) {
            _selectedVariantId = _variants.first['id'] as String;
          }
        });
      }
    } catch (_) {
      // Without the options list the buyer cannot pick the right size, so
      // this must not pass silently as "no options".
      if (mounted) safeSetState(() => _variantsFailed = true);
    }
  }

  Map<String, dynamic>? get _selectedVariant {
    if (_selectedVariantId == null) return null;
    for (final v in _variants) {
      if (v['id'] == _selectedVariantId) return v;
    }
    return null;
  }

  Future<void> _loadReviews() async {
    if (mounted) safeSetState(() => _reviewsFailed = false);
    try {
      final rows = await SupabaseService.client
          .from('reviews')
          .select()
          .eq('product_id', widget.productId)
          .order('created_at', ascending: false);
      safeSetState(() => _reviews = rows.map(Review.fromSupabaseRow).toList());
    } catch (_) {
      safeSetState(() => _reviewsFailed = true);
    }
    safeSetState(() => _isLoadingReviews = false);
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final product = productProvider.getProductById(widget.productId);
    final l10n = AppLocalizations.of(context);
    if (product == null) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: GradientAppBar(
            title: Text(l10n.productDetailTitle,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            centerTitle: true),
        body: Center(
          child: productProvider.isLoading
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.productDetailUnavailable,
                    textAlign: TextAlign.center,
                  ),
                ),
        ),
      );
    }
    final isInCart = cartProvider.isInCart(product.id);
    final isWishlisted = wishlistProvider.isWishlisted(product.id);

    // Price follows the chosen option; the "was" price and the saving only
    // exist for the plain product.
    final price =
        (_selectedVariant?['price'] as num?)?.toDouble() ?? product.price;
    final was =
        _selectedVariant == null && product.originalPrice > product.price
            ? product.originalPrice
            : null;
    final store = product.storeName?.trim();
    final storeProducts = store == null || store.isEmpty
        ? 0
        : productProvider.allProducts
            .where((p) => p.sellerId == product.sellerId)
            .length;
    // The seller's one block of text, read into the boxes the page shows.
    final parts = DescriptionParts.parse(product.description);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppConstants.backgroundColor,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: Column(
          children: [
            // The top bar reaches up behind the status bar, so the two
            // are one colour.
            Container(
              color: AppConstants.backgroundColor,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(
                    children: [
                      _RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.maybePop(context),
                      ),
                      const Spacer(),
                      _RoundIconButton(
                        icon: isWishlisted ? Iconsax.heart : Iconsax.heart_copy,
                        color: isWishlisted
                            ? AppConstants.dangerColor
                            : AppConstants.textPrimaryColor,
                        onTap: () => wishlistProvider.toggle(product),
                      ),
                      const SizedBox(width: 12),
                      _RoundIconButton(
                        icon: Iconsax.share,
                        onTap: () => Share.share(
                          l10n.productDetailShare(
                            product.name,
                            formatRupees(price),
                            AppConstants.appName,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEBEBEB)),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isEditing(context)) _adminBar(product),
                        _buildHeroImage(product),
                        Container(
                          width: double.infinity,
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  height: 1.2,
                                  fontWeight: FontWeight.w800,
                                  color: AppConstants.textPrimaryColor,
                                ),
                              ),
                              // Under the name, like Amazon's item
                              // highlights line: the opening sentence, not
                              // the raw text with its bullets and links.
                              if (parts.summary.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  parts.summary,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    height: 1.45,
                                    color: AppConstants.textSecondaryColor,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  Text(
                                    formatRupees(price),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (was != null)
                                    Text(
                                      formatRupees(was),
                                      style: const TextStyle(
                                        fontSize: 17,
                                        color: AppConstants.textSecondaryColor,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  if (was != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        l10n.productDetailSaved(
                                            formatRupees(was - price)),
                                        maxLines: 1,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppConstants.successColor,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (product.unit.trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  product.unit,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppConstants.textSecondaryColor,
                                  ),
                                ),
                              ],
                              if (_variantsFailed) ...[
                                const SizedBox(height: 18),
                                RoleInlineError(
                                  message: l10n.productDetailOptionsFailed,
                                  onRetry: _loadVariants,
                                ),
                              ],
                              if (_variants.isNotEmpty) ...[
                                const SizedBox(height: 22),
                                Text(
                                  l10n.productDetailSelectOption,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    for (final v in _variants)
                                      _OptionCard(
                                        label: v['name'] as String? ?? '',
                                        selected: v['id'] == _selectedVariantId,
                                        onTap: () => safeSetState(
                                          () => _selectedVariantId =
                                              v['id'] as String,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (store != null && store.isNotEmpty)
                          _SectionCard(
                            title: l10n.productDetailStoreDetails,
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E2),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFE4E4E4),
                                    ),
                                  ),
                                  child: const Icon(
                                    Iconsax.shop,
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        store,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        l10n.productDetailStoreProducts(
                                            storeProducts),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          color:
                                              AppConstants.textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Material(
                                  color: const Color(0xFFF7F4EF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    side: const BorderSide(
                                      color: Color(0xFFE4E4E4),
                                    ),
                                  ),
                                  child: Pressable(
                                      child: InkWell(
                                    customBorder: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductListScreen(
                                          title: store,
                                          source: (provider) => provider
                                              .allProducts
                                              .where((p) =>
                                                  p.sellerId ==
                                                  product.sellerId)
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            l10n.productDetailVisitStore,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            size: 22,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )),
                                ),
                              ],
                            ),
                          ),
                        // What can be done with an order, as the app's rules say.
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Row(
                            children: [
                              Expanded(
                                child: _PolicyTile(
                                  icon: Iconsax.refresh,
                                  label: l10n.productDetailReturnable,
                                ),
                              ),
                              const SizedBox(
                                height: 34,
                                child: VerticalDivider(
                                  width: 1,
                                  color: Color(0xFFE4E4E4),
                                ),
                              ),
                              Expanded(
                                child: _PolicyTile(
                                  icon: Iconsax.close_circle,
                                  label: l10n.productDetailCancellable,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _ProductDetailsCard(
                          product: product,
                          parts: parts,
                          store: store,
                        ),
                        const SizedBox(height: 20),
                        _buildReviewsSection(),
                        const SizedBox(height: 20),
                        _buildSimilarProducts(productProvider, product),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // The buy bar stays put while the page scrolls.
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                12 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEBEBEB))),
              ),
              child: product.stock <= 0
                  ? SizedBox(
                      width: double.infinity,
                      height: AppControl.lg,
                      child: Pressable(
                          child: ElevatedButton(
                        onPressed:
                            _isTogglingStockAlert ? null : _toggleStockAlert,
                        style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          _isSubscribedToStock
                              ? l10n.productDetailNotifyOn
                              : l10n.productDetailNotifyMe,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )),
                    )
                  : Row(
                      children: [
                        if (isInCart) ...[
                          CartAction(
                            product: product,
                            alwaysShowStepper: true,
                            outline: true,
                            height: AppControl.lg,
                            width: 128,
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: _BuyButton(
                            label: isInCart
                                ? l10n.productDetailGoToCart
                                : l10n.productDetailAddToCart,
                            icon: isInCart
                                ? Iconsax.arrow_right_3_copy
                                : Iconsax.shopping_bag,
                            onTap: () {
                              if (isInCart) {
                                MainShell.goTo(context, MainShell.cart);
                              } else {
                                _addSelectedToCart(cartProvider, product);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _addSelectedToCart(CartProvider cartProvider, Product product) {
    final variant = _selectedVariant;
    cartProvider.addToCart(
      product,
      variantId: variant?['id'] as String?,
      variantName: variant?['name'] as String?,
      variantPrice: (variant?['price'] as num?)?.toDouble(),
    );
  }

  Widget _buildReviewsSection() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.productDetailReviews,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppConstants.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoadingReviews)
            const Center(child: CircularProgressIndicator())
          else if (_reviewsFailed)
            RoleInlineError(
              message: l10n.productDetailReviewsFailed,
              onRetry: _loadReviews,
            )
          else if (_reviews.isEmpty)
            Text(
              l10n.productDetailNoReviews,
              style: TextStyle(color: Colors.grey[600]),
            )
          else
            ..._reviews.map(
              (review) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating
                                ? Iconsax.star
                                : Iconsax.star_copy,
                            size: 14,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    if (review.comment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(review.comment,
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSimilarProducts(
    ProductProvider productProvider,
    Product currentProduct,
  ) {
    final l10n = AppLocalizations.of(context);
    final similar = productProvider.allProducts
        .where(
          (p) =>
              p.category == currentProduct.category &&
              p.id != currentProduct.id,
        )
        .take(6)
        .toList();
    if (similar.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.productDetailSimilar,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppConstants.textPrimaryColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: similar.length,
            itemBuilder: (context, i) {
              final product = similar[i];
              return SizedBox(
                width: 148,
                child: GestureDetector(
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _placeholderHeroImage(Product product) {
    return Container(
      decoration: BoxDecoration(gradient: _getGradient(product.imageGradient)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            product.name.isNotEmpty ? product.name[0] : '?',
            style: TextStyle(
              fontSize: 80,
              color: Colors.white.withValues(alpha: 0.5),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.category,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// What an admin with edit mode on can do to a product: take it off sale.
  /// (The seller owns its details; the admin decides whether it is shown.)
  Widget _adminBar(Product product) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF4DB),
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          const Icon(Iconsax.edit, size: 16, color: AppConstants.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.productDetailAdminOnSale,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
          Pressable(
              child: TextButton(
            onPressed: () => _hideProduct(product),
            child: Text(
              l10n.productDetailHideFromStore,
              style: const TextStyle(color: AppConstants.dangerColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _hideProduct(Product product) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.productDetailHideTitle(product.name),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        content: Text(l10n.productDetailHideBody),
        actions: [
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.productDetailCancel,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.productDetailHide,
              style: const TextStyle(color: AppConstants.dangerColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final products = context.read<ProductProvider>();
    try {
      await SupabaseService.client
          .from('products')
          .update({'is_active': false}).eq('id', product.id);
      await products.reload();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.productDetailHideFailed,
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
        );
      }
    }
  }

  Widget _buildHeroImage(Product product) {
    return ProductGallery(
      key: ValueKey(product.id),
      urls: product.gallery,
      placeholder: _placeholderHeroImage(product),
      heroTag: _heroTag,
    );
  }

  Gradient _getGradient(String gradient) {
    switch (gradient) {
      case 'red':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEF5350), Color(0xFFC62828)],
        );
      case 'orange':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFA726), Color(0xFFEF6C00)],
        );
      case 'yellow':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFEE58), Color(0xFFF9A825)],
        );
      case 'brown':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA1887F), Color(0xFF6D4C41)],
        );
      case 'white':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
        );
    }
  }
}

/// A round, soft grey button for the top bar.
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.color = AppConstants.textPrimaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
        child: Material(
      color: const Color(0xFFEFEFEF),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Icon(icon, size: 24, color: color),
        ),
      ),
    ));
  }
}

/// One choice among a product's options (size, colour, pack).
class _OptionCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
        child: GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 96, maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF3E2) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                selected ? AppConstants.primaryColor : const Color(0xFFE4E4E4),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    ));
  }
}

/// A white block with a heading, set apart from the next by a grey gap.
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PolicyTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PolicyTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 26, color: AppConstants.primaryColor),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

/// The buy bar's big action: a soft-shadowed orange gradient pill. The plain
/// theme ElevatedButton read flat and cheap next to the rest of the page.
class _BuyButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _BuyButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
        child: GestureDetector(
      onTap: onTap,
      child: Container(
        // The app's primary action height, like every other main button.
        height: AppControl.lg,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppConstants.primaryColor, Color(0xFFFF8A2B)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryColor.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 19, color: Colors.white),
          ],
        ),
      ),
    ));
  }
}

/// "Product details", laid out the way Amazon.in's mobile product page lays
/// it out (checked against a live listing): a stack of sections, each with
/// its own heading, that open and close — Nutritional Info and Top
/// highlights open, Product specifications and Additional details closed —
/// and Important information, always shown, at the bottom.
class _ProductDetailsCard extends StatelessWidget {
  final Product product;
  final DescriptionParts parts;
  final String? store;

  const _ProductDetailsCard({
    required this.product,
    required this.parts,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = product.displayBrand;
    final unit = product.unit.trim();
    final seller = store != null && store!.isNotEmpty ? store : null;
    final diet = product.isFood
        ? (product.isVeg ? l10n.productDetailVeg : l10n.productDetailNonVeg)
        : null;

    // The seller's own highlights first, then the bullets written into the
    // description, each point once.
    final points = <String>[];
    for (final p in [...product.highlights, ...parts.bullets]) {
      if (!points.any((q) => q.toLowerCase() == p.toLowerCase())) {
        points.add(p);
      }
    }

    final topRows = <(String, String)>[
      if (brand != null) (l10n.productDetailBrand, brand),
      if (unit.isNotEmpty) (l10n.productDetailNetQuantity, unit),
      (l10n.productDetailCategory, product.category),
      if (diet != null) (l10n.productDetailDietType, diet),
    ];

    // Everything known about the item, then what the description spelled
    // out as "Label: value", without repeating a label.
    final specRows = <(String, String)>[...topRows];
    if (seller != null) specRows.add((l10n.productDetailSoldByLabel, seller));
    for (final row in parts.specs) {
      final taken =
          specRows.any((r) => r.$1.toLowerCase() == row.$1.toLowerCase());
      if (!taken) specRows.add(row);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.productDetailDetailsHeading,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (parts.nutrition.isNotEmpty)
            _DetailsSection(
              title: l10n.productDetailNutrition,
              initiallyOpen: true,
              child: _Lines(parts.nutrition),
            ),
          _DetailsSection(
            title: l10n.productDetailTopHighlights,
            initiallyOpen: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KeyValueTable(topRows),
                if (points.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    l10n.productDetailAboutItem,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SeeMoreBullets(points),
                ],
              ],
            ),
          ),
          _DetailsSection(
            title: l10n.productDetailProductSpecs,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (diet != null) ...[
                  _DietLine(veg: product.isVeg),
                  const SizedBox(height: 12),
                ],
                _KeyValueTable(specRows),
              ],
            ),
          ),
          if (parts.hasDetails)
            _DetailsSection(
              title: l10n.productDetailAdditionalDetails,
              child: _AdditionalDetails(parts),
            ),
          const _SectionDivider(),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              l10n.productDetailImportantInfo,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          if (parts.ingredients != null)
            _LabelledText(
              label: l10n.productDetailIngredients,
              text: parts.ingredients!,
            ),
          _LabelledText(
            label: l10n.productDetailLegalDisclaimer,
            text: l10n.productDetailLegalDisclaimerBody,
          ),
          if (parts.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final note in parts.notes)
              Text(
                note,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppConstants.textSecondaryColor,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: Color(0xFFEBEBEB));
}

/// One heading that opens and closes its content, with a chevron that turns.
class _DetailsSection extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyOpen;

  const _DetailsSection({
    required this.title,
    required this.child,
    this.initiallyOpen = false,
  });

  @override
  State<_DetailsSection> createState() => _DetailsSectionState();
}

class _DetailsSectionState extends State<_DetailsSection> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionDivider(),
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _open
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: widget.child,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Label on the left, value on the right, a hairline between rows: the
/// table Amazon uses for Top highlights and Product specifications.
class _KeyValueTable extends StatelessWidget {
  final List<(String, String)> rows;

  const _KeyValueTable(this.rows);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: i == rows.length - 1
                  ? null
                  : const Border(
                      bottom: BorderSide(color: Color(0xFFEFEFEF)),
                    ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    rows[i].$1,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Text(
                    rows[i].$2,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: AppConstants.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The "About this item" points: four at first, the rest behind See more.
class _SeeMoreBullets extends StatefulWidget {
  final List<String> points;

  const _SeeMoreBullets(this.points);

  @override
  State<_SeeMoreBullets> createState() => _SeeMoreBulletsState();
}

class _SeeMoreBulletsState extends State<_SeeMoreBullets> {
  static const _shown = 4;
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final points = widget.points;
    final extra = points.length > _shown;
    final visible = _all || !extra ? points : points.take(_shown).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _Bullets(visible),
        ),
        if (extra)
          Pressable(
              child: TextButton(
            onPressed: () => setState(() => _all = !_all),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: AppConstants.primaryColor,
            ),
            child: Text(
              _all ? l10n.productDetailSeeLess : l10n.productDetailSeeMore,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          )),
      ],
    );
  }
}

class _Bullets extends StatelessWidget {
  final List<String> points;

  const _Bullets(this.points);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final point in points)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8, right: 10, left: 2),
                  child: CircleAvatar(
                    radius: 2.5,
                    backgroundColor: AppConstants.textPrimaryColor,
                  ),
                ),
                Expanded(
                  child: Text(
                    point,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppConstants.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Lines extends StatelessWidget {
  final List<String> lines;

  const _Lines(this.lines);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              line,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ),
      ],
    );
  }
}

/// Amazon's "This is a Vegetarian product." line, with the Indian veg/non-veg
/// mark in front of it.
class _DietLine extends StatelessWidget {
  final bool veg;

  const _DietLine({required this.veg});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = veg ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C);
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(2),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            veg
                ? l10n.productDetailVegProduct
                : l10n.productDetailNonVegProduct,
            style: const TextStyle(fontSize: 14.5),
          ),
        ),
      ],
    );
  }
}

/// The description's prose: its paragraphs, then each titled part with its
/// own heading, points and text.
class _AdditionalDetails extends StatelessWidget {
  final DescriptionParts parts;

  const _AdditionalDetails(this.parts);

  static const _body = TextStyle(
    fontSize: 15,
    height: 1.6,
    color: AppConstants.textSecondaryColor,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in parts.paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(p, style: _body),
          ),
        for (final section in parts.sections) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text(
              section.title,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final p in section.paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(p, style: _body),
            ),
          if (section.bullets.isNotEmpty) ...[
            _Bullets(section.bullets),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

/// "Ingredients:" in bold, then the text — Important information's layout.
class _LabelledText extends StatelessWidget {
  final String label;
  final String text;

  const _LabelledText({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppConstants.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
