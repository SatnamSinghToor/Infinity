import 'dart:typed_data';
import 'package:duggu/l10n/app_localizations.dart';
import '../../widgets/app_network_image.dart';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase/supabase.dart' show FileOptions;

import '../../providers/auth_provider.dart';
import '../../services/background_removal_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../utils/format.dart';
import '../../utils/safe_state.dart';
import 'add_product_screen.dart';
import 'seller_product_detail_screen.dart';
import '../../widgets/role_common.dart';
import '../../widgets/pressable.dart';

enum _ProductFilter { all, active, hidden, lowStock }

/// The seller's full product catalog — search, filter, and every
/// per-product action (edit, replace photo, boost, hide/unhide, delete)
/// in one place, instead of buried in a cramped dashboard list.
class SellerProductsScreen extends StatefulWidget {
  const SellerProductsScreen({super.key});

  @override
  State<SellerProductsScreen> createState() => _SellerProductsScreenState();
}

class _SellerProductsScreenState extends State<SellerProductsScreen> {
  bool _isLoading = true;

  /// Whether the last load failed. A shop that could not be fetched is not
  /// an empty shop, and the screen says so rather than looking empty.
  bool _loadFailed = false;

  List<Map<String, dynamic>> _products = [];
  final Set<String> _updatingPhotoIds = {};
  final _searchController = TextEditingController();
  String _query = '';
  _ProductFilter _filter = _ProductFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().userId;
    safeSetState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final rows = await SupabaseService.client
          .from('products')
          .select(
            'id, name, description, price, mrp, unit, stock, is_active, '
            'category_id, brand, image_url, image_urls, about_highlights',
          )
          .eq('seller_id', userId)
          .order('created_at', ascending: false);
      safeSetState(() => _products = List<Map<String, dynamic>>.from(rows));
    } catch (_) {
      safeSetState(() => _loadFailed = true);
    }
    safeSetState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _visibleProducts {
    return _products.where((p) {
      final name = (p['name'] as String? ?? '').toLowerCase();
      if (_query.isNotEmpty && !name.contains(_query)) return false;

      final isActive = p['is_active'] as bool? ?? true;
      final stock = (p['stock'] as num?)?.toInt() ?? 0;
      switch (_filter) {
        case _ProductFilter.active:
          return isActive;
        case _ProductFilter.hidden:
          return !isActive;
        case _ProductFilter.lowStock:
          return stock <= 5;
        case _ProductFilter.all:
          return true;
      }
    }).toList();
  }

  Future<void> _addProduct() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
    if (saved == true) _load();
  }

  Future<void> _editProduct(Map<String, dynamic> product) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddProductScreen(existingProduct: product),
      ),
    );
    if (saved == true) _load();
  }

  /// Stock management: a number field for how many are in hand now,
  /// saved straight to the product.
  Future<void> _updateStock(Map<String, dynamic> p) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller =
        TextEditingController(text: '${(p['stock'] as num?)?.toInt() ?? 0}');
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.sellerProductsStockTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: p['name'] as String? ?? '',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          Pressable(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                l10n.sellerProductsStockCancel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Pressable(
            child: ElevatedButton(
              onPressed: () {
                final n = int.tryParse(controller.text.trim());
                if (n != null && n >= 0) Navigator.pop(ctx, n);
              },
              child: Text(
                l10n.sellerProductsStockSave,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    try {
      await SupabaseService.client
          .from('products')
          .update({'stock': value}).eq('id', p['id'] as String);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.sellerProductsStockSaved(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
      _load();
    } catch (e) {
      debugPrint('Stock update failed: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.sellerProductsStockFailed,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> product) async {
    final l10n = AppLocalizations.of(context);
    final newValue = !(product['is_active'] as bool? ?? true);
    try {
      await SupabaseService.client
          .from('products')
          .update({'is_active': newValue}).eq('id', product['id'] as String);
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.sellerProductsUpdateFailed,
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
        );
      }
    }
  }

  Future<void> _confirmDeleteProduct(Map<String, dynamic> product) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.sellerProductsDeleteTitle),
        content: Text(
          l10n.sellerProductsDeleteBody(product['name'] as String? ?? ''),
        ),
        actions: [
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.sellerProductsCancel,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
          Pressable(
              child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.dangerColor,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.sellerProductsDelete,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await SupabaseService.client
          .from('products')
          .delete()
          .eq('id', product['id'] as String);
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.sellerProductsDeleteFailed,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }
  }

  Future<void> _editPhoto(Map<String, dynamic> product) async {
    final l10n = AppLocalizations.of(context);
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 100,
    );
    if (picked == null) return;

    if (!mounted) return;
    final id = product['id'] as String;
    final sellerId = context.read<AuthProvider>().userId;
    Uint8List bytes = await picked.readAsBytes();
    safeSetState(() => _updatingPhotoIds.add(id));
    try {
      // Cut the product out of its background; if that isn't possible the
      // original photo is saved instead.
      var isPng = false;
      final cutout = await BackgroundRemovalService.removeBackground(
        picked.path,
      );
      if (cutout != null) {
        bytes = cutout;
        isPng = true;
      } else if (BackgroundRemovalService.isSupported && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.sellerProductsBgFailed,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
      final path = '$sellerId/${DateTime.now().millisecondsSinceEpoch}'
          '.${isPng ? 'png' : 'jpg'}';
      await SupabaseService.client.storage.from('product-images').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: isPng ? 'image/png' : 'image/jpeg',
            ),
          );
      final url = SupabaseService.client.storage
          .from('product-images')
          .getPublicUrl(path);
      // This replaces the main photo; the product's other photos stay.
      final others = [
        for (final u in ((product['image_urls'] as List?) ?? const []).skip(1))
          if (u is String) u,
      ];
      await SupabaseService.client.from('products').update({
        'image_url': url,
        'image_urls': [url, ...others]
      }).eq(
        'id',
        id,
      );
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.sellerProductsPhotoFailed,
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingPhotoIds.remove(id));
    }
  }

  /// Requests a sponsored slot for [product] — pending admin approval.
  /// `fee_amount` is a generated column (`duration_days * 5`), so it's
  /// only shown here, never sent in the insert.
  Future<void> _requestBoost(Map<String, dynamic> product) async {
    final l10n = AppLocalizations.of(context);
    final headlineController = TextEditingController(
      text: l10n.sellerProductsBoostDraft(product['name'] as String? ?? ''),
    );
    int durationDays = 7;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.sellerProductsBoostTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: headlineController,
                  decoration: InputDecoration(
                    labelText: l10n.sellerProductsBoostHeadline,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(l10n.sellerProductsBoostDuration),
                    const SizedBox(width: 12),
                    DropdownButton<int>(
                      value: durationDays,
                      items: const [3, 7, 14, 30]
                          .map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text(
                                l10n.sellerProductsBoostDays(
                                  d,
                                  formatRupees(d * 5),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => durationDays = v);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            Pressable(
                child: TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.sellerProductsCancel,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            )),
            Pressable(
                child: ElevatedButton(
              onPressed: () {
                if (headlineController.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: Text(l10n.sellerProductsBoostRequest,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            )),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final sellerId = context.read<AuthProvider>().userId;

    try {
      await SupabaseService.client.from('sponsored_slots').insert({
        'seller_id': sellerId,
        'product_id': product['id'],
        'headline': headlineController.text.trim(),
        'duration_days': durationDays,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.sellerProductsBoostSent,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.sellerProductsBoostFailed,
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
        );
      }
    }
  }

  Widget _productThumbnail(Map<String, dynamic> product) {
    final url = product['image_url'] as String?;
    final name = product['name'] as String? ?? '';
    if (url == null || url.isEmpty) return _productPlaceholder(name);
    return ColoredBox(
      color: Colors.white,
      child: AppNetworkImage(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _productPlaceholder(name),
      ),
    );
  }

  Widget _productPlaceholder(String name) {
    return Container(
      color: AppConstants.accentColor.withValues(alpha: 0.3),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _filterChip(String label, _ProductFilter value) {
    final isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        selected: isSelected,
        selectedColor: AppConstants.primaryColor.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: isSelected
              ? AppConstants.primaryColor
              : AppConstants.textPrimaryColor,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final products = _visibleProducts;
    final allLabel = l10n.sellerProductsFilterAll;
    final activeLabel = l10n.sellerProductsFilterActive;
    final hiddenLabel = l10n.sellerProductsFilterHidden;
    final lowStockLabel = l10n.sellerProductsFilterLowStock;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
          title: Text(l10n.sellerProductsTitle,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          centerTitle: true),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        child: const Icon(Iconsax.add),
      ),
      body: RoleBody(
        loading: _isLoading,
        loadingMessage: l10n.sellerProductsLoading,
        failed: _loadFailed,
        errorTitle: l10n.sellerProductsLoadFailed,
        onRetry: _load,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.sellerProductsSearchHint,
                  prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _filterChip(allLabel, _ProductFilter.all),
                  _filterChip(activeLabel, _ProductFilter.active),
                  _filterChip(hiddenLabel, _ProductFilter.hidden),
                  _filterChip(lowStockLabel, _ProductFilter.lowStock),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: products.isEmpty
                  ? RoleEmpty(
                      icon: Iconsax.shopping_bag,
                      title: _products.isEmpty
                          ? l10n.sellerProductsEmptyTitle
                          : l10n.sellerProductsNoMatches,
                      message: _products.isEmpty
                          ? l10n.sellerProductsEmptyBody
                          : l10n.sellerProductsNoMatchesBody,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final p = products[index];
                          final stock = (p['stock'] as num?)?.toInt() ?? 0;
                          final isActive = p['is_active'] as bool? ?? true;
                          final isLowStock = stock > 0 && stock <= 5;
                          final id = p['id'] as String;
                          final hidden = l10n.sellerProductsFilterHidden;
                          String stockLabel;
                          if (stock == 0) {
                            stockLabel = l10n.sellerProductsOutOfStock;
                          } else if (isLowStock) {
                            stockLabel = l10n.sellerProductsLowStock(stock);
                          } else {
                            stockLabel = l10n.sellerProductsInStock(stock);
                          }
                          String toggleLabel;
                          if (isActive) {
                            toggleLabel = l10n.sellerProductsHide;
                          } else {
                            toggleLabel = l10n.sellerProductsUnhide;
                          }

                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _editPhoto(p),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: SizedBox(
                                          width: 64,
                                          height: 64,
                                          child: _updatingPhotoIds.contains(id)
                                              ? const Center(
                                                  child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  ),
                                                )
                                              : _productThumbnail(p),
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(
                                            color: AppConstants.primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Iconsax.camera,
                                            size: 11,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    // The detail page can edit, hide or
                                    // show the product: re-read on return.
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            SellerProductDetailScreen(
                                          product: p,
                                        ),
                                      ),
                                    ).then((_) => _load()),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['name'] as String? ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          formatRupees(
                                              (p['price'] as num?) ?? 0),
                                          style: const TextStyle(
                                            color: AppConstants.primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Text(
                                              stockLabel,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: stock == 0
                                                    ? AppConstants.dangerColor
                                                    : isLowStock
                                                        ? Colors.orange
                                                        : Colors.grey[600],
                                                fontWeight:
                                                    (stock == 0 || isLowStock)
                                                        ? FontWeight.w600
                                                        : null,
                                              ),
                                            ),
                                            if (!isActive) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 1,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade300,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  hidden,
                                                  style: const TextStyle(
                                                      fontSize: 10),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Pressable(
                                    child: IconButton(
                                  icon: const Icon(
                                    Iconsax.edit_2,
                                    size: 20,
                                    color: AppConstants.primaryColor,
                                  ),
                                  tooltip: l10n.sellerProductsEdit,
                                  onPressed: () => _editProduct(p),
                                )),
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Iconsax.more_square,
                                    size: 20,
                                  ),
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'stock':
                                        _updateStock(p);
                                        break;
                                      case 'boost':
                                        _requestBoost(p);
                                        break;
                                      case 'toggle':
                                        _toggleActive(p);
                                        break;
                                      case 'delete':
                                        _confirmDeleteProduct(p);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'stock',
                                      child:
                                          Text(l10n.sellerProductsStockTitle),
                                    ),
                                    PopupMenuItem(
                                      value: 'boost',
                                      child: Text(l10n.sellerProductsBoost),
                                    ),
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Text(toggleLabel),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text(l10n.sellerProductsDelete),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
