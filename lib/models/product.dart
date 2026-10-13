import '../utils/format.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double originalPrice;
  final String category;
  final double rating;
  final bool isVeg;
  final bool isAvailable;
  final String unit;
  final int discount;
  final String imageGradient;
  final String? imageUrl;

  /// Every photo of the product, the main one first (`image_urls`); empty
  /// for products saved with a single photo — use [gallery].
  final List<String> imageUrls;
  final String sellerId;
  final int stock;

  /// A company brand the seller chose (Apple, Samsung, Amul…). Null when the
  /// product is sold under the seller's own business name — see [storeName].
  final String? brand;

  /// The seller's store name — the product's business brand.
  final String? storeName;

  /// The seller's short selling points (`about_highlights`), shown under
  /// "About this item". Empty when the seller added none.
  final List<String> highlights;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.category,
    this.rating = 0,
    this.isVeg = true,
    this.isAvailable = true,
    this.unit = '1 pc',
    this.discount = 0,
    this.imageGradient = 'green',
    this.imageUrl,
    this.imageUrls = const [],
    this.sellerId = '',
    this.stock = 999,
    this.brand,
    this.storeName,
    this.highlights = const [],
  });

  static final _foodCategory = RegExp(
    r'fruit|veg|grocery|snack|drink|dairy|bakery|milk|festival|sweet|food|'
    r'beverage|atta|rice|dal|oil|masala|egg|meat|fish|grain|pulse|flour|'
    r'cooking|biscuit|chocolate|juice|tea|coffee|spread|dessert|ready|'
    r'frozen|cut|sprout|produce|organic',
  );

  /// Whether this is a food/grocery item — the only kind where a Veg /
  /// Non-veg mark makes sense.
  bool get isFood => _foodCategory.hasMatch(category.toLowerCase());

  /// Whether the seller picked a company brand for this product.
  bool get hasCompanyBrand => brand != null && brand!.trim().isNotEmpty;

  /// The brand to show: the company brand if there is one, otherwise the
  /// seller's business name (store name). Null if neither is known.
  String? get displayBrand {
    if (hasCompanyBrand) return brand!.trim();
    final store = storeName?.trim();
    return (store == null || store.isEmpty) ? null : store;
  }

  /// The photos to show, main one first: [imageUrls], or just [imageUrl].
  List<String> get gallery {
    if (imageUrls.isNotEmpty) return imageUrls;
    final url = imageUrl;
    return (url == null || url.isEmpty) ? const [] : [url];
  }

  /// A copy of this product with the seller's store name filled in.
  Product withStoreName(String? store) {
    return Product(
      id: id,
      name: name,
      description: description,
      price: price,
      originalPrice: originalPrice,
      category: category,
      rating: rating,
      isVeg: isVeg,
      isAvailable: isAvailable,
      unit: unit,
      discount: discount,
      imageGradient: imageGradient,
      imageUrl: imageUrl,
      imageUrls: imageUrls,
      sellerId: sellerId,
      stock: stock,
      brand: brand,
      storeName: store,
      highlights: highlights,
    );
  }

  static const _gradientKeys = [
    'red',
    'orange',
    'yellow',
    'brown',
    'white',
    'green',
  ];

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// Builds a [Product] from a Supabase `products` row, optionally with a
  /// joined `categories(name)` map under the `categories` key.
  factory Product.fromSupabaseRow(Map<String, dynamic> row) {
    final id = row['id'] as String;
    final sellPrice =
        _toDouble(row['discount_price']) ?? _toDouble(row['price']) ?? 0;
    final basePrice = _toDouble(row['price']) ?? sellPrice;
    final categoryMap = row['categories'] as Map<String, dynamic>?;
    final categoryName = categoryMap?['name'] as String? ?? 'Grocery';
    final stock = (row['stock'] as num?)?.toInt() ?? 999;

    return Product(
      id: id,
      name: row['name'] as String? ?? '',
      description: row['description'] as String? ?? '',
      price: sellPrice,
      originalPrice: basePrice > sellPrice ? basePrice : sellPrice,
      category: categoryName,
      rating: _toDouble(row['rating']) ?? 0,
      isVeg: row['is_veg'] as bool? ?? true,
      isAvailable: stock > 0,
      unit: row['unit'] as String? ?? '1 pc',
      imageUrl: row['image_url'] as String?,
      imageUrls: [
        for (final u in (row['image_urls'] as List?) ?? const [])
          if (u is String && u.isNotEmpty) u,
      ],
      imageGradient: _gradientKeys[id.hashCode.abs() % _gradientKeys.length],
      sellerId: row['seller_id'] as String? ?? '',
      stock: stock,
      brand: (row['brand'] as String?)?.trim().isNotEmpty == true
          ? row['brand'] as String
          : null,
      // The stored list is `dynamic`; anything that is not text is dropped
      // here rather than thrown when the page paints it.
      highlights: [
        for (final h in (row['about_highlights'] as List?) ?? const [])
          if (h is String && h.trim().isNotEmpty) h.trim(),
      ],
    );
  }

  double get discountPrice => price;

  String get formattedPrice => formatRupees(price);

  String get formattedOriginalPrice => formatRupees(originalPrice);

  int get discountPercent {
    if (originalPrice > 0) {
      return ((originalPrice - price) / originalPrice * 100).round();
    }
    return discount;
  }
}
