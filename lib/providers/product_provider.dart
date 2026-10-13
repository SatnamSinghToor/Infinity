import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../models/product.dart';
import '../services/supabase_service.dart';

/// One chip in the strip at the top of Home.
class HomeChip {
  /// Also the name of the category whose products it shows ("All" shows
  /// everything).
  final String name;
  final IconData icon;

  const HomeChip(this.name, this.icon);
}

/// The Home strip is its own fixed list of storefronts, separate from the
/// Categories tab (which follows the category tree in the database).
const homeChips = [
  HomeChip('All', Iconsax.category),
  HomeChip('Festival', Iconsax.magic_star),
  HomeChip('Electronics', Iconsax.mobile),
  HomeChip('Beauty', Iconsax.brush_2),
  HomeChip('Pharmacy', Iconsax.health),
  HomeChip('Gifting', Iconsax.gift),
  HomeChip('Decor', Iconsax.home_2),
  HomeChip('Kids', Iconsax.happyemoji),
  HomeChip('Imported', Iconsax.airplane),
];

class ProductProvider extends ChangeNotifier {
  String _selectedCategory = 'All';
  String? _selectedBrand;
  String _searchQuery = '';
  bool _isLoading = false;
  bool _usingLiveData = false;

  // Set when the last load from the backend failed (offline, server error).
  bool _loadFailed = false;

  // Nothing is shown until it has really been loaded — no placeholder
  // products or categories.
  List<Product> _products = [];
  List<String> _categories = ['All'];
  List<IconData> _categoryIcons = [Iconsax.category];

  /// The picture an admin set for a category card, by category name.
  Map<String, String> _categoryImages = {};

  /// A picture that IS the whole card, set by an admin, by category name.
  Map<String, String> _cardImages = {};

  /// How many sizes or packs each product is sold in (its active rows in
  /// `product_variants`). A card shows "2 Opt" under its + for these, and
  /// its + opens the Choose Variant sheet instead of adding straight away.
  Map<String, int> _variantCounts = {};

  /// The number of active variants [productId] has; 0 when it has none.
  int variantCount(String productId) => _variantCounts[productId] ?? 0;

  // Sub-categories by their top-level category's name, in display order.
  Map<String, List<String>> _subCategories = {};

  /// [autoload] is on in the app, so the shop is there the moment the first
  /// screen asks for it. A test (or anything building a screen without a
  /// backend behind it) can switch it off, and then nothing goes out over
  /// the network — and nothing is left ticking — until someone asks for a
  /// [reload].
  ProductProvider({bool autoload = true}) {
    if (autoload) _loadFromSupabase();
  }

  bool get isLoading => _isLoading;
  bool get usingLiveData => _usingLiveData;
  bool get loadFailed => _loadFailed;
  String get selectedCategory => _selectedCategory;
  String? get selectedBrand => _selectedBrand;
  String get searchQuery => _searchQuery;
  List<Product> get allProducts => _products;
  List<String> get categories => _categories;
  List<IconData> get categoryIcons => _categoryIcons;

  /// The picture set for the category card called [name], if any.
  /// Marks a card whose picture an admin removed on purpose (so it does not
  /// fall back to a product photo); kept in the category's `image_url`.
  static const noPicture = 'none';

  String? categoryImage(String name) {
    final url = _categoryImages[name];
    return url == noPicture ? null : url;
  }

  /// Whether the card called [name] is set to show no picture at all.
  bool pictureRemoved(String name) => _categoryImages[name] == noPicture;

  /// The picture that stands in for the whole card called [name], if any.
  String? categoryCardImage(String name) => _cardImages[name];

  /// The sub-categories under the top-level category [parent] (empty if it
  /// has none).
  List<String> subCategoriesOf(String parent) =>
      _subCategories[parent] ?? const [];

  /// Whether [product] belongs to the top-level category [parent], either
  /// directly or through one of its sub-categories.
  bool inCategoryGroup(Product product, String parent) =>
      product.category == parent ||
      subCategoriesOf(parent).contains(product.category);

  List<Product> get filteredProducts {
    List<Product> result = _products;

    if (_selectedCategory != 'All') {
      result =
          result.where((p) => inCategoryGroup(p, _selectedCategory)).toList();
    }

    if (_selectedBrand != null) {
      result = result.where((p) => p.brand == _selectedBrand).toList();
    }

    if (_searchQuery.isNotEmpty) {
      result = result
          .where(
            (p) =>
                p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.category.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    return result;
  }

  /// The product with [id], or null if it isn't (or is no longer) on sale.
  Product? getProductById(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Loads products and categories again (e.g. after a failed load).
  Future<void> reload() => _loadFromSupabase();

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setBrand(String? brand) {
    _selectedBrand = brand;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> _loadFromSupabase() async {
    _isLoading = true;
    _loadFailed = false;
    notifyListeners();

    try {
      final client = SupabaseService.client;

      final categoryRows = await client
          .from('categories')
          .select('id, name, parent_id, sort_order, image_url, icon_url')
          .eq('is_active', true)
          .order('name');

      final productRows = await client
          .from('products')
          .select(
            'id, name, description, price, discount_price, image_url, image_urls, unit, rating, is_veg, stock, seller_id, category_id, brand, about_highlights, categories(name)',
          )
          .eq('is_active', true)
          .order('created_at', ascending: false);

      // Each seller's store name is their business brand. (`stores` is
      // publicly readable; sellers without a store just have no business
      // brand.)
      final storeNames = <String, String>{};
      try {
        final storeRows = await client.from('stores').select('owner_id, name');
        for (final row in storeRows) {
          final owner = row['owner_id'] as String?;
          final name = (row['name'] as String?)?.trim();
          if (owner != null && name != null && name.isNotEmpty) {
            storeNames[owner] = name;
          }
        }
      } catch (e) {
        debugPrint('Store names load failed: $e');
      }

      // Top-level categories drive the chips and the Categories tab; the rest
      // are sub-categories, grouped under their parent.
      final topRows =
          categoryRows.where((row) => row['parent_id'] == null).toList();
      final categoryNames =
          topRows.map((row) => row['name'] as String).toList();

      final parentNames = {
        for (final row in topRows) row['id'] as String: row['name'] as String,
      };
      final subRows = categoryRows
          .where((row) => parentNames.containsKey(row['parent_id']))
          .toList()
        ..sort(
          (a, b) => ((a['sort_order'] as num?) ?? 0)
              .compareTo((b['sort_order'] as num?) ?? 0),
        );
      _subCategories = {};
      for (final row in subRows) {
        final parent = parentNames[row['parent_id']]!;
        (_subCategories[parent] ??= []).add(row['name'] as String);
      }

      // Which products come in several sizes. Best-effort: without it the
      // cards simply add the plain product, as they always did.
      try {
        final variantRows = await client
            .from('product_variants')
            .select('product_id')
            .eq('is_active', true);
        final counts = <String, int>{};
        for (final row in variantRows) {
          final id = row['product_id'] as String?;
          if (id != null) counts[id] = (counts[id] ?? 0) + 1;
        }
        _variantCounts = counts;
      } catch (e) {
        debugPrint('Variant counts load failed: $e');
      }

      _cardImages = {
        for (final row in categoryRows)
          if (((row['icon_url'] as String?) ?? '').isNotEmpty)
            row['name'] as String: row['icon_url'] as String,
      };
      _categoryImages = {
        for (final row in categoryRows)
          if (((row['image_url'] as String?) ?? '').isNotEmpty)
            row['name'] as String: row['image_url'] as String,
      };

      _categories = ['All', ...categoryNames];
      _categoryIcons = [
        Iconsax.category,
        ...categoryNames.map(_iconForCategory),
      ];

      _products = productRows
          .map(Product.fromSupabaseRow)
          .map((p) => p.withStoreName(storeNames[p.sellerId]))
          .toList();

      _usingLiveData = true;
    } catch (e) {
      // Offline or backend unreachable. Keep whatever was loaded before (if
      // anything) and let the screens offer a retry.
      _loadFailed = true;
      debugPrint('Supabase product load failed: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  IconData _iconForCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('fruit') || n.contains('veg')) return Iconsax.apple;
    if (n.contains('bakery')) return Iconsax.cake;
    if (n.contains('snack') || n.contains('drink')) return Iconsax.glass;
    if (n.contains('electronic')) return Iconsax.mobile;
    if (n.contains('pharma')) return Iconsax.hospital;
    if (n.contains('fashion') || n.contains('beauty')) return Iconsax.bag;
    if (n.contains('toy')) return Iconsax.game;
    if (n.contains('baby')) return Iconsax.heart;
    if (n.contains('festival')) return Iconsax.gift;
    if (n.contains('grocery')) return Iconsax.shopping_bag;
    return Iconsax.category;
  }
}
