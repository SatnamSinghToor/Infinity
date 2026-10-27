import 'product.dart';

class CartItem {
  final String? id;
  final Product product;
  int quantity;
  final String? variantId;
  final String? variantName;
  final double? variantPrice;

  CartItem({
    this.id,
    required this.product,
    this.quantity = 1,
    this.variantId,
    this.variantName,
    this.variantPrice,
  });

  /// Composite key for cart storage: "productId:variantId" (or just "productId" for no variant)
  String get cartKey => variantId != null ? '${product.id}:$variantId' : product.id;

  double get unitPrice => variantPrice ?? product.price;

  double get totalPrice => unitPrice * quantity;
}
