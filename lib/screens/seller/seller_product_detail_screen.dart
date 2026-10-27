import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../models/review.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/tokens.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../utils/format.dart';
import '../../widgets/adaptive_image.dart';
import '../../widgets/product_gallery.dart';
import '../../widgets/role_common.dart';
import 'add_product_screen.dart';
import '../../widgets/pressable.dart';

/// Full view of one of the seller's own products: photo, where it stands in
/// the shop, its details, how it has sold, its description and its reviews,
/// with Edit and Hide/Show at the bottom. Takes the raw product row directly
/// (rather than routing through ProductProvider, which only loads
/// `is_active = true` products) so a hidden/inactive product still opens
/// correctly here — and then re-reads the row, because some callers hand
/// over only the few columns their own list needed.
///
/// It used to be read-only: a photo, a price and "No description added."
/// with nothing to do about it, so the page looked empty. Every section now
/// either says something about the product or offers the step that fills it.
class SellerProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const SellerProductDetailScreen({super.key, required this.product});

  @override
  State<SellerProductDetailScreen> createState() =>
      _SellerProductDetailScreenState();
}

class _SellerProductDetailScreenState extends State<SellerProductDetailScreen> {
  /// The product as last read; starts as what the caller handed over.
  late Map<String, dynamic> _product = Map.of(widget.product);

  /// The category's name, once looked up from `category_id`.
  String? _categoryName;

  /// Units sold and money taken, over orders that were not cancelled.
  int _sold = 0;
  double _revenue = 0;
  bool _isLoadingSales = true;
  bool _salesFailed = false;

  /// While Hide/Show is on its way to the server.
  bool _isToggling = false;

  List<Review> _reviews = [];
  bool _isLoadingReviews = true;

  /// Whether the reviews could not be fetched: a product with no reviews yet
  /// and a product whose reviews failed to load must not look the same.
  bool _reviewsFailed = false;

  String get _productId => widget.product['id'] as String;

  @override
  void initState() {
    super.initState();
    _refreshProduct();
    _loadSales();
    _loadReviews();
  }

  /// Re-reads the whole row (and the category's name). A failure keeps what
  /// the caller handed over, which is still a correct, if thinner, page.
  Future<void> _refreshProduct() async {
    try {
      final row = await SupabaseService.client
          .from('products')
          .select(
            'id, name, description, price, mrp, unit, stock, is_active, '
            'category_id, brand, image_url, image_urls, about_highlights',
          )
          .eq('id', _productId)
          .maybeSingle();
      if (row == null || !mounted) return;
      setState(() => _product = Map<String, dynamic>.from(row));
      final categoryId = row['category_id'];
      if (categoryId == null) return;
      final category = await SupabaseService.client
          .from('categories')
          .select('name')
          .eq('id', categoryId)
          .maybeSingle();
      if (mounted) {
        setState(() => _categoryName = category?['name'] as String?);
      }
    } catch (e) {
      // Best-effort: the row the caller passed in is already on screen.
      debugPrint('seller product detail: refresh failed: $e');
    }
  }

  /// Try again after the sales failed to load.
  void _retrySales() {
    setState(() {
      _isLoadingSales = true;
      _salesFailed = false;
    });
    _loadSales();
  }

  /// How the product has sold: every order line for it, minus cancelled
  /// orders.
  Future<void> _loadSales() async {
    try {
      final rows = await SupabaseService.client
          .from('order_items')
          .select('quantity, price_at_purchase, orders(status)')
          .eq('product_id', _productId);
      var sold = 0;
      var revenue = 0.0;
      for (final row in rows) {
        final order = row['orders'];
        if (order is Map && order['status'] == 'cancelled') continue;
        final quantity = (row['quantity'] as num?)?.toInt() ?? 0;
        final price = (row['price_at_purchase'] as num?)?.toDouble() ?? 0;
        sold += quantity;
        revenue += quantity * price;
      }
      if (mounted) {
        setState(() {
          _sold = sold;
          _revenue = revenue;
        });
      }
    } catch (e) {
      debugPrint('seller product detail: sales failed: $e');
      if (mounted) setState(() => _salesFailed = true);
    }
    if (mounted) setState(() => _isLoadingSales = false);
  }

  Future<void> _edit() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddProductScreen(existingProduct: _product),
      ),
    );
    if (saved == true) _refreshProduct();
  }

  Future<void> _toggleActive() async {
    final l10n = AppLocalizations.of(context);
    final show = !(_product['is_active'] as bool? ?? true);
    setState(() => _isToggling = true);
    try {
      await SupabaseService.client
          .from('products')
          .update({'is_active': show}).eq('id', _productId);
      if (!mounted) return;
      setState(() => _product = {..._product, 'is_active': show});
      roleSay(
        context,
        show
            ? l10n.sellerProductDetailShownDone
            : l10n.sellerProductDetailHiddenDone,
      );
    } catch (e) {
      debugPrint('seller product detail: toggle failed: $e');
      if (mounted) roleSay(context, l10n.sellerProductDetailUpdateFailed);
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  Future<void> _loadReviews() async {
    try {
      final rows = await SupabaseService.client
          .from('reviews')
          .select()
          .eq('product_id', widget.product['id'] as String)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() => _reviews = rows.map(Review.fromSupabaseRow).toList());
      }
    } catch (_) {
      if (mounted) setState(() => _reviewsFailed = true);
    }
    if (mounted) setState(() => _isLoadingReviews = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = _product;
    final imageUrl = p['image_url'] as String?;
    // Every photo, the main one first; falls back to just the main photo.
    final photos = [
      for (final u in (p['image_urls'] as List?) ?? const [])
        if (u is String && u.isNotEmpty) u,
    ];
    final price = (p['price'] as num?)?.toDouble() ?? 0;
    final mrp = (p['mrp'] as num?)?.toDouble();
    final stock = (p['stock'] as num?)?.toInt() ?? 0;
    final isActive = p['is_active'] as bool? ?? true;
    final highlights = [
      for (final h in (p['about_highlights'] as List?) ?? const [])
        if (h is String && h.trim().isNotEmpty) h,
    ];
    final description = (p['description'] as String?)?.trim() ?? '';
    final unit = (p['unit'] as String?)?.trim() ?? '';
    final brand = (p['brand'] as String?)?.trim() ?? '';
    final discount = (mrp != null && mrp > price && mrp > 0)
        ? ((mrp - price) / mrp * 100).round()
        : 0;
    final rating = _reviews.isEmpty
        ? null
        : _reviews.fold<double>(0, (sum, r) => sum + r.rating) /
            _reviews.length;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
        title: Text(
          p['name'] as String? ?? l10n.sellerProductDetailProductFallback,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: _actions(l10n, isActive),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Takes the photo's own shape (no crop); only the no-photo
            // placeholder keeps a fixed height.
            (imageUrl == null || imageUrl.isEmpty) && photos.isEmpty
                ? SizedBox(
                    width: double.infinity,
                    height: 240,
                    child: _placeholder(p['name'] as String? ?? ''),
                  )
                : photos.length > 1
                    ? ProductGallery(key: ValueKey(p['id']), urls: photos)
                    : Container(
                        width: double.infinity,
                        color: Colors.white,
                        child: AdaptiveImage(
                          image: CachedNetworkImageProvider(
                            (imageUrl != null && imageUrl.isNotEmpty)
                                ? imageUrl
                                : photos.first,
                          ),
                          maxHeight: 380,
                          backgroundColor: Colors.white,
                          placeholderAspectRatio: 1.4,
                        ),
                      ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p['name'] as String? ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _statusChip(l10n, isActive),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        formatRupees(price),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      if (discount > 0) ...[
                        const SizedBox(width: 10),
                        Text(
                          formatRupees(mrp!),
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.sellerProductDetailDiscountValue(discount),
                          style: const TextStyle(
                            color: AppConstants.successColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stock == 0
                        ? l10n.sellerProductDetailOutOfStock
                        : stock <= 5
                            ? l10n.sellerProductDetailLowStock(stock)
                            : l10n.sellerProductDetailStock(stock),
                    style: TextStyle(
                      color: stock == 0
                          ? AppConstants.dangerColor
                          : stock <= 5
                              ? AppConstants.primaryColor
                              : Colors.grey[600],
                      fontWeight: stock <= 5 ? FontWeight.w600 : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _heading(l10n.sellerProductDetailPerformance),
                  const SizedBox(height: 8),
                  _performance(l10n, rating),
                  const SizedBox(height: 20),
                  _heading(l10n.sellerProductDetailDetails),
                  const SizedBox(height: 8),
                  _card(
                    Column(
                      children: [
                        _detailRow(
                          l10n.sellerProductDetailCategory,
                          _categoryName ?? l10n.sellerProductDetailNotSet,
                        ),
                        _detailRow(
                          l10n.sellerProductDetailUnit,
                          unit.isNotEmpty
                              ? unit
                              : l10n.sellerProductDetailNotSet,
                        ),
                        _detailRow(
                          l10n.sellerProductDetailBrand,
                          brand.isNotEmpty
                              ? brand
                              : l10n.sellerProductDetailNotSet,
                        ),
                        _detailRow(
                          l10n.sellerProductDetailMrp,
                          mrp != null && mrp > 0
                              ? formatRupees(mrp)
                              : l10n.sellerProductDetailNotSet,
                          last: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _heading(l10n.sellerProductDetailDescription),
                  const SizedBox(height: 8),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppConstants.textSecondaryColor,
                        height: 1.5,
                      ),
                    )
                  else
                    _missingDescription(l10n),
                  if (highlights.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.sellerProductDetailHighlights,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: highlights
                          .map((h) => Chip(
                              label: Text(h,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    l10n.sellerProductDetailReviews(_reviews.length),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_isLoadingReviews)
                    const Center(child: CircularProgressIndicator())
                  else if (_reviewsFailed)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.sellerProductDetailReviewsFailed,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                        Pressable(
                            child: TextButton(
                          onPressed: () {
                            setState(() => _reviewsFailed = false);
                            _loadReviews();
                          },
                          child: Text(
                            l10n.sellerProductDetailTryAgain,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                      ],
                    )
                  else if (_reviews.isEmpty)
                    Text(
                      l10n.sellerProductDetailNoReviews,
                      style: TextStyle(color: Colors.grey[600]),
                    )
                  else
                    ..._reviews.map(
                      (review) => Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppRadius.card,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < review.rating
                                      ? Iconsax.star
                                      : Iconsax.star_copy,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                            if (review.comment.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                review.comment,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ],
                        ),
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

  Widget _heading(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      );

  Widget _card(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.card,
        ),
        child: child,
      );

  /// Live or hidden, in the colour a seller reads at a glance.
  Widget _statusChip(AppLocalizations l10n, bool isActive) {
    final color =
        isActive ? AppConstants.successColor : AppConstants.textSecondaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Iconsax.eye : Iconsax.eye_slash,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            isActive
                ? l10n.sellerProductDetailLive
                : l10n.sellerProductDetailHidden,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Units sold, money taken and the average rating, three across.
  Widget _performance(AppLocalizations l10n, double? rating) {
    if (_salesFailed) {
      return _card(
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.sellerProductDetailSalesFailed,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            Pressable(
                child: TextButton(
              onPressed: _retrySales,
              child: Text(
                l10n.sellerProductDetailTryAgain,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )),
          ],
        ),
      );
    }
    final loading = _isLoadingSales;
    return Row(
      children: [
        Expanded(
          child: RoleStatCard(
            dense: true,
            icon: Iconsax.box,
            label: l10n.sellerProductDetailSold,
            value: loading ? '…' : '$_sold',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RoleStatCard(
            dense: true,
            icon: Iconsax.wallet_money,
            label: l10n.sellerProductDetailRevenue,
            value: loading ? '…' : formatRupees(_revenue),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RoleStatCard(
            dense: true,
            icon: Iconsax.star,
            label: l10n.sellerProductDetailRating,
            value: _isLoadingReviews
                ? '…'
                : rating == null
                    ? l10n.sellerProductDetailNoRating
                    : rating.toStringAsFixed(1),
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value, {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: AppConstants.textSecondaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// An empty description is a step to take, not a sentence to read: the
  /// edit screen is where it is written, with the AI writer beside the box.
  Widget _missingDescription(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.06),
        borderRadius: AppRadius.card,
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.sellerProductDetailNoDescription,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.sellerProductDetailAddDescriptionHint,
            style: const TextStyle(
              color: AppConstants.textSecondaryColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Pressable(
              child: TextButton.icon(
            onPressed: _edit,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            icon: const Icon(Iconsax.magicpen, size: 16),
            label: Text(
              l10n.sellerProductDetailAddDescription,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )),
        ],
      ),
    );
  }

  /// Edit and Hide/Show, always within reach of the thumb.
  Widget _actions(AppLocalizations l10n, bool isActive) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Pressable(
                  child: OutlinedButton.icon(
                onPressed: _isToggling ? null : _toggleActive,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConstants.textPrimaryColor,
                ),
                icon: Icon(
                  isActive ? Iconsax.eye_slash : Iconsax.eye,
                  size: 18,
                ),
                label: Text(
                  isActive
                      ? l10n.sellerProductDetailHide
                      : l10n.sellerProductDetailUnhide,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Pressable(
                  child: ElevatedButton.icon(
                onPressed: _edit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Iconsax.edit_2, size: 18),
                label: Text(
                  l10n.sellerProductDetailEdit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(String name) {
    return Container(
      color: AppConstants.accentColor.withOpacity(0.3),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 64,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
