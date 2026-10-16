import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../utils/constants.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/product_card.dart';
import '../screens/product_detail_screen.dart';
import '../widgets/pressable.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  int _selectedFilter = 0;

  static const _filters = [
    'All Deals',
    'Biggest Discount',
    'Fresh Picks',
    'Bestsellers',
  ];

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    List<Product> dealsProducts;
    switch (_selectedFilter) {
      case 1:
        dealsProducts = List.from(productProvider.allProducts)
          ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
        dealsProducts = dealsProducts.take(12).toList();
        break;
      case 2:
        dealsProducts = productProvider.allProducts
            .where(
              (p) =>
                  p.category == 'Fruits & Vegetables' ||
                  p.category == 'Dairy & Eggs',
            )
            .toList();
        break;
      case 3:
        dealsProducts = List.from(productProvider.allProducts)
          ..sort((a, b) => b.rating.compareTo(a.rating));
        dealsProducts = dealsProducts.take(12).toList();
        break;
      default:
        dealsProducts = List.from(productProvider.allProducts)
          ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
        dealsProducts = dealsProducts.take(20).toList();
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
          title: const Text('Deals & Offers',
              maxLines: 1, overflow: TextOverflow.ellipsis),
          centerTitle: true),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: dealsProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.tag, size: 72, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No deals right now',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${dealsProducts.length} deals',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Upto ${dealsProducts.map((p) => p.discountPercent).reduce((a, b) => a > b ? a : b)}% OFF',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return GridView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              clipBehavior: Clip.none,
                              gridDelegate: ProductCardMetrics.delegate(
                                width: constraints.maxWidth - 24,
                              ),
                              itemCount: dealsProducts.length,
                              itemBuilder: (context, index) {
                                final product = dealsProducts[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailScreen(
                                          productId: product.id,
                                        ),
                                      ),
                                    );
                                  },
                                  child: ProductCard(product: product),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_filters.length, (index) {
          final isSelected = _selectedFilter == index;
          return Pressable(
              child: GestureDetector(
            onTap: () => setState(() => _selectedFilter = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppConstants.primaryColor
                    : AppConstants.backgroundColor,
                borderRadius: BorderRadius.circular(20),
                border:
                    isSelected ? null : Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                _filters[index],
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : AppConstants.textSecondaryColor,
                ),
              ),
            ),
          ));
        }),
      ),
    );
  }
}
