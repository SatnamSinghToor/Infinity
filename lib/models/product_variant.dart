/// A sellable variant of a product (e.g., "1 kg", "2 kg", "500 g").
/// Each variant has its own price, MRP, stock, and availability.
class ProductVariant {
  final String id;
  final String label;
  final double price;
  final double mrp;
  final int stock;
  final bool isAvailable;
  final String? discountLabel;

  const ProductVariant({
    required this.id,
    required this.label,
    required this.price,
    required this.mrp,
    required this.stock,
    this.isAvailable = true,
    this.discountLabel,
  });

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'] as String,
      label: map['label'] as String,
      price: (map['price'] as num).toDouble(),
      mrp: (map['mrp'] as num).toDouble(),
      stock: (map['stock'] as num).toInt(),
      isAvailable: map['is_available'] as bool? ?? true,
      discountLabel: map['discount_label'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'price': price,
      'mrp': mrp,
      'stock': stock,
      'is_available': isAvailable,
      'discount_label': discountLabel,
    };
  }

  int get discountPercent {
    if (mrp > 0) {
      return ((mrp - price) / mrp * 100).round();
    }
    return 0;
  }

  String get discountDisplay {
    if (discountLabel != null && discountLabel!.isNotEmpty) {
      return discountLabel!;
    }
    if (discountPercent > 0) {
      return '$discountPercent% OFF';
    }
    return '';
  }

  ProductVariant copyWith({
    String? id,
    String? label,
    double? price,
    double? mrp,
    int? stock,
    bool? isAvailable,
    String? discountLabel,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      label: label ?? this.label,
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      stock: stock ?? this.stock,
      isAvailable: isAvailable ?? this.isAvailable,
      discountLabel: discountLabel ?? this.discountLabel,
    );
  }
}

/// Extension to format rupees for ProductVariant
extension ProductVariantFormat on ProductVariant {
  String get formattedPrice => '₹${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}';
  
  String get formattedMrp => '₹${mrp.toStringAsFixed(mrp.truncateToDouble() == mrp ? 0 : 2)}';
}