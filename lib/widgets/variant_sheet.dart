import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../models/product_variant.dart';
import '../providers/cart_provider.dart';
import '../utils/constants.dart';
import 'app_network_image.dart';
import 'cart_action.dart';
import 'pressable.dart';

/// Orange grocery "Select an option" bottom sheet.
/// Matches spec: drag handle, close button, product image/name, radio selection,
/// price/MRP/discount per option, full-width orange "Add to cart" button.
Future<void> showVariantSheet(
  BuildContext context,
  Product product, {
  ProductVariant? initialVariant,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _VariantSheet(
      product: product,
      initialVariant: initialVariant,
    ),
  );
}

class _VariantSheet extends StatefulWidget {
  final Product product;
  final ProductVariant? initialVariant;

  const _VariantSheet({
    required this.product,
    this.initialVariant,
  });

  @override
  State<_VariantSheet> createState() => _VariantSheetState();
}

class _VariantSheetState extends State<_VariantSheet> {
  ProductVariant? _selectedVariant;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedVariant = widget.initialVariant ?? widget.product.firstAvailableVariant;
    // Variants are already loaded in the product model
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final variants = widget.product.variants;
    final availableVariants = variants.where((v) => v.isAvailable).toList();

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  // Product image + name
                  Container(
                    width: 48,
                    height: 48,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppConstants.imageBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppConstants.cardBorder),
                    ),
                    child: widget.product.gallery.isNotEmpty
                        ? AppNetworkImage(
                            widget.product.gallery.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.variantSheetTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textSecondaryColor,
                          ),
                        ),
                        Text(
                          widget.product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button
                  Pressable(
                    child: Material(
                      color: Colors.grey[100],
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(context),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Iconsax.close_circle_copy,
                            size: 22,
                            color: AppConstants.textPrimaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppConstants.cardBorder),
            // Variant list
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(AppConstants.primaryColor),
                  ),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Pressable(
                      child: TextButton(
                        onPressed: () => setState(() => _isLoading = true),
                        child: Text(
                          l10n.variantSheetRetry,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (variants.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.variantSheetNoOptions,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  children: [
                    for (final variant in availableVariants)
                      _VariantRow(
                        product: widget.product,
                        variant: variant,
                        isSelected: _selectedVariant?.id == variant.id,
                        onTap: () => setState(() => _selectedVariant = variant),
                      ),
                    // Disabled variants (out of stock)
                    for (final variant in variants.where((v) => !v.isAvailable))
                      _VariantRow(
                        product: widget.product,
                        variant: variant,
                        isSelected: false,
                        onTap: null,
                        disabledReason: 'Out of stock',
                      ),
                  ],
                ),
              ),
            // Add to cart button (sticky at bottom)
            if (availableVariants.isNotEmpty)
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AppConstants.cardBorder),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: _buildAddToCartButton(availableVariants),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Text(
        widget.product.name.isNotEmpty ? widget.product.name[0] : '?',
        style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white.withOpacity(0.6),
        ),
      ),
    );
  }

Widget _buildAddToCartButton(List<ProductVariant> availableVariants) {
    final selected = _selectedVariant;
    final canAdd = selected != null &&
        widget.product.canAddMore(variantId: selected.id);
    
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: canAdd
            ? () {
                HapticFeedback.lightImpact();
                final cart = context.read<CartProvider>();
                cart.addToCart(
                  widget.product,
                  variantId: selected!.id,
                  variantName: selected.label,
                  variantPrice: selected.price,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${selected.label} ${AppLocalizations.of(context).productAddedToCart}',
                    ),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppConstants.primaryColor,
                  ),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppConstants.primaryColor.withOpacity(0.4),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          ),
        ),
        child: selected != null
            ? Text(
                '${AppLocalizations.of(context).variantSheetAddToCart} ${selected.formattedPrice}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              )
            : Text(
                AppLocalizations.of(context).variantSheetSelectOption,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}

class _VariantRow extends StatelessWidget {
  final Product product;
  final ProductVariant variant;
  final bool isSelected;
  final VoidCallback? onTap;
  final String? disabledReason;

  const _VariantRow({
    required this.product,
    required this.variant,
    required this.isSelected,
    this.onTap,
    this.disabledReason,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    final hasDiscount = variant.mrp > variant.price;
    final discountPercent = variant.discountPercent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppConstants.primaryColor.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppConstants.primaryColor : AppConstants.cardBorder,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Radio indicator
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppConstants.primaryColor : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                // Product image
                Container(
                  width: 56,
                  height: 56,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppConstants.imageBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppConstants.cardBorder),
                  ),
                  child: product.gallery.isNotEmpty
                      ? AppNetworkImage(
                          product.gallery.first,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
                const SizedBox(width: 14),
                // Variant details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        variant.label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDisabled ? Colors.grey[500] : AppConstants.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (disabledReason != null)
                        Text(
                          disabledReason!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppConstants.dangerColor,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            // Price
                            Text(
                              variant.formattedPrice,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppConstants.textPrimaryColor,
                              ),
                            ),
                            if (hasDiscount) ...[
                              const SizedBox(width: 6),
                              // MRP
                              Text(
                                variant.formattedMrp,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppConstants.textSecondaryColor,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Discount
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppConstants.discountBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  variant.discountDisplay.isNotEmpty
                                      ? variant.discountDisplay
                                      : '$discountPercent% OFF',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppConstants.discountBlue,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Availability indicator
                if (!isDisabled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'In Stock',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.successColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Text(
        product.name.isNotEmpty ? product.name[0] : '?',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white.withOpacity(0.6),
        ),
      ),
    );
  }
}