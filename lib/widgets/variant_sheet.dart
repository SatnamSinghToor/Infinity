import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../services/supabase_service.dart';
import '../utils/format.dart';
import '../utils/tokens.dart';
import 'app_network_image.dart';
import 'cart_action.dart';
import 'pressable.dart';

/// The shelves' "Choose Variant" sheet: every size [product] is sold in,
/// each with its picture, price, the struck MRP and the saving, and a + to
/// put that size in the cart. The size already in the cart shows its
/// stepper instead.
Future<void> showVariantSheet(BuildContext context, Product product) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.tokens.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _VariantSheet(product: product),
  );
}

class _VariantSheet extends StatefulWidget {
  final Product product;

  const _VariantSheet({required this.product});

  @override
  State<_VariantSheet> createState() => _VariantSheetState();
}

class _VariantSheetState extends State<_VariantSheet> {
  List<Map<String, dynamic>>? _variants;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _failed = false);
    try {
      final rows = await SupabaseService.client
          .from('product_variants')
          .select('id, name, price, mrp, stock_qty, image_url')
          .eq('product_id', widget.product.id)
          .eq('is_active', true)
          .order('price', ascending: false);
      if (mounted) {
        setState(() => _variants = List<Map<String, dynamic>>.from(rows));
      }
    } catch (e) {
      // Without the list there is nothing to choose from: say so, with a
      // retry, rather than showing an empty sheet.
      debugPrint('Variants load failed: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final variants = _variants;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.variantSheetTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                  Pressable(
                    child: Material(
                      color: tokens.surfaceAlt,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Iconsax.close_circle_copy, size: 22),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: tokens.border),
            if (_failed)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      l10n.variantSheetFailed,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: tokens.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Pressable(
                      child: TextButton(
                        onPressed: _fetch,
                        child: Text(
                          l10n.variantSheetRetry,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (variants == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  children: [
                    for (final v in variants)
                      _VariantRow(product: widget.product, variant: v),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VariantRow extends StatelessWidget {
  final Product product;
  final Map<String, dynamic> variant;

  const _VariantRow({required this.product, required this.variant});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cart = context.watch<CartProvider>();
    final id = variant['id'] as String;
    final name = (variant['name'] as String?) ?? '';
    final price = (variant['price'] as num?)?.toDouble() ?? product.price;
    final mrp = (variant['mrp'] as num?)?.toDouble() ?? 0;
    final stock = (variant['stock_qty'] as num?)?.toInt();
    final image = (variant['image_url'] as String?)?.trim();
    final off = mrp > price ? ((mrp - price) / mrp * 100).round() : 0;
    final soldOut = stock != null && stock <= 0;
    final inCart =
        cart.getQuantity(product.id) > 0 && cart.variantIdOf(product.id) == id;

    void choose() {
      HapticFeedback.lightImpact();
      cart.chooseVariant(
        product,
        variantId: id,
        variantName: name,
        variantPrice: price,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: inCart ? tokens.primary : tokens.border,
          width: inCart ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.border),
            ),
            child: AppNetworkImage(
              image != null && image.isNotEmpty
                  ? image
                  : (product.imageUrl ?? ''),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Iconsax.box,
                color: tokens.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        formatRupees(price),
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: tokens.textPrimary,
                        ),
                      ),
                      if (mrp > price) ...[
                        const SizedBox(width: 6),
                        Text(
                          formatRupees(mrp),
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 13,
                            color: tokens.textSecondary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                      if (off > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '$off% off',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: tokens.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (inCart)
            CartAction(
              product: product,
              bagButton: true,
              plusButton: true,
              width: 96,
              height: 38,
              onChoose: choose,
            )
          else
            Pressable(
              child: GestureDetector(
                onTap: soldOut ? null : choose,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: soldOut
                          ? tokens.primary.withOpacity(0.35)
                          : tokens.primary,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Iconsax.add_copy,
                    size: 22,
                    color: soldOut
                        ? tokens.primary.withOpacity(0.35)
                        : tokens.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
