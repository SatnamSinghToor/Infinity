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

  double get unitPrice => variantPrice ?? product.price;

  double get totalPrice => unitPrice * quantity;
}
