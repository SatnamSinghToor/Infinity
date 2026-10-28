import 'package:flutter/material.dart';

import 'festive_data.dart';
import 'festive_store.dart';
import 'festive_tokens.dart';
import 'festive_widgets.dart';

/// Search sheet: a real text field, the catalogue filtered live, and the
/// suggestion chips the storefront shows before you type.
class FestiveSearchSheet extends StatefulWidget {
  const FestiveSearchSheet({
    super.key,
    required this.store,
    required this.palette,
    required this.typeScale,
    this.hints = FestiveCopy.reference.searchHints,
  });

  final FestiveStore store;
  final FestivePalette palette;
  final double typeScale;
  final List<String> hints;

  @override
  State<FestiveSearchSheet> createState() => _FestiveSearchSheetState();
}

class _FestiveSearchSheetState extends State<FestiveSearchSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.store.query);
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _apply(String value) {
    setState(() {});
    widget.store.query = value;
  }

  @override
  Widget build(BuildContext context) {
    final FestivePalette palette = widget.palette;
    final double t = widget.typeScale;
    final List<FestiveProduct> results = widget.store.resultsFor(_controller.text);

    return AnimatedBuilder(
      animation: widget.store,
      builder: (BuildContext context, Widget? _) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          minChildSize: 0.6,
          maxChildSize: 0.96,
          builder: (BuildContext context, ScrollController sheetScroll) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: palette.surfaceSoft,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: palette.hairline),
                            ),
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.search,
                                    size: 20, color: palette.inkSoft),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    focusNode: _focus,
                                    onChanged: _apply,
                                    textInputAction: TextInputAction.search,
                                    style: FestiveType.body(
                                      14 * t,
                                      color: palette.ink,
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      hintText: 'Search for diyas, candles, gifts',
                                      hintStyle: FestiveType.body(
                                        14 * t,
                                        color: palette.inkSoft,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_controller.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _controller.clear();
                                      _apply('');
                                    },
                                    child: Icon(Icons.close,
                                        size: 18, color: palette.inkSoft),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: Icon(Icons.close, color: palette.ink),
                          tooltip: 'Close search',
                        ),
                      ],
                    ),
                  ),
                  if (_controller.text.isEmpty)
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: <Widget>[
                          for (final String hint in widget.hints)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text(
                                  hint,
                                  style: FestiveType.body(
                                    12 * t,
                                    color: palette.ink,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: palette.surfaceSoft,
                                side: BorderSide(color: palette.hairline),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                onPressed: () {
                                  _controller.text = hint;
                                  _apply(hint);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: results.isEmpty
                        ? _EmptyResults(palette: palette, query: _controller.text)
                        : ListView.separated(
                            controller: sheetScroll,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: results.length,
                            separatorBuilder: (BuildContext context, int i) =>
                                Divider(height: 1, color: palette.hairline),
                            itemBuilder: (BuildContext context, int index) {
                              final FestiveProduct product = results[index];
                              return _ResultRow(
                                product: product,
                                palette: palette,
                                typeScale: t,
                                quantity: widget.store.quantityOf(product),
                                onAdd: () {
                                  widget.store.add(product);
                                  setState(() {});
                                },
                                onRemove: () {
                                  widget.store.remove(product);
                                  setState(() {});
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.palette, required this.query});

  final FestivePalette palette;
  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.search_off_rounded, size: 48, color: palette.inkSoft),
            const SizedBox(height: 12),
            Text(
              'No match for "$query"',
              textAlign: TextAlign.center,
              style: FestiveType.body(
                14,
                color: palette.ink,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try "diya", "candle" or "hamper".',
              textAlign: TextAlign.center,
              style: FestiveType.body(12.5, color: palette.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.product,
    required this.palette,
    required this.typeScale,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  final FestiveProduct product;
  final FestivePalette palette;
  final double typeScale;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 58,
              height: 58,
              child: Image.asset(
                product.asset,
                fit: BoxFit.cover,
                cacheWidth: 174,
                errorBuilder: (BuildContext context, Object error,
                        StackTrace? stack) =>
                    ColoredBox(color: palette.surfaceSoft),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: FestiveType.body(
                    13 * typeScale,
                    color: palette.ink,
                    weight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.unit,
                  style: FestiveType.body(
                    11 * typeScale,
                    color: palette.inkSoft,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Text(
                      rupee(product.price),
                      style: FestiveType.body(
                        12.5 * typeScale,
                        color: palette.ink,
                        weight: FontWeight.w700,
                      ),
                    ),
                    if (product.hasDiscount) ...<Widget>[
                      const SizedBox(width: 6),
                      Text(
                        rupee(product.mrp),
                        style: FestiveType.body(
                          10.5 * typeScale,
                          color: palette.inkSoft,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AddToCartButton(
            quantity: quantity,
            palette: palette,
            onAdd: onAdd,
            onRemove: onRemove,
            typeScale: typeScale,
          ),
        ],
      ),
    );
  }
}

/// Cart sheet with live totals and the savings line.
class FestiveCartSheet extends StatelessWidget {
  const FestiveCartSheet({
    super.key,
    required this.store,
    required this.palette,
    required this.typeScale,
    this.onCheckout,
  });

  final FestiveStore store;
  final FestivePalette palette;
  final double typeScale;
  final VoidCallback? onCheckout;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (BuildContext context, Widget? _) {
        final List<FestiveProduct> lines = store.cartLines;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: palette.hairline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          lines.isEmpty ? 'Your cart is empty' : 'Your cart',
                          style: FestiveType.body(
                            17 * typeScale,
                            color: palette.ink,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (lines.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            store.clearCart();
                          },
                          child: Text(
                            'Clear all',
                            style: FestiveType.body(
                              12 * typeScale,
                              color: palette.inkSoft,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (lines.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Column(
                          children: <Widget>[
                            Icon(Icons.shopping_bag_outlined,
                                size: 44, color: palette.inkSoft),
                            const SizedBox(height: 10),
                            Text(
                              'Add a diya, some candles, a hamper.',
                              style: FestiveType.body(
                                13 * typeScale,
                                color: palette.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...<Widget>[
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: lines.length,
                        separatorBuilder: (BuildContext context, int i) =>
                            Divider(height: 20, color: palette.hairline),
                        itemBuilder: (BuildContext context, int index) {
                          final FestiveProduct product = lines[index];
                          return Row(
                            children: <Widget>[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Image.asset(
                                    product.asset,
                                    fit: BoxFit.cover,
                                    cacheWidth: 132,
                                    errorBuilder:
                                        (BuildContext context, Object error,
                                                StackTrace? stack) =>
                                            ColoredBox(
                                                color: palette.surfaceSoft),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: FestiveType.body(
                                        12.5 * typeScale,
                                        color: palette.ink,
                                        weight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      product.unit,
                                      style: FestiveType.body(
                                        10.5 * typeScale,
                                        color: palette.inkSoft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              AddToCartButton(
                                quantity: store.quantityOf(product),
                                palette: palette,
                                typeScale: typeScale,
                                onAdd: () => store.add(product),
                                onRemove: () => store.remove(product),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    _BillRow(
                      label: 'Item total',
                      value: rupee(store.cartTotal),
                      palette: palette,
                      typeScale: typeScale,
                    ),
                    if (store.cartSavings > 0)
                      _BillRow(
                        label: 'Savings on MRP',
                        value: '- ${rupee(store.cartSavings)}',
                        palette: palette,
                        typeScale: typeScale,
                        highlight: true,
                      ),
                    _BillRow(
                      label: 'Delivery fee',
                      value: 'FREE',
                      palette: palette,
                      typeScale: typeScale,
                      highlight: true,
                    ),
                    Divider(height: 20, color: palette.hairline),
                    _BillRow(
                      label: 'To pay',
                      value: rupee(store.cartTotal),
                      palette: palette,
                      typeScale: typeScale,
                      bold: true,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: FilledButton(
                        onPressed: onCheckout,
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.add,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Proceed to checkout',
                          style: FestiveType.body(
                            14 * typeScale,
                            color: Colors.white,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({
    required this.label,
    required this.value,
    required this.palette,
    required this.typeScale,
    this.highlight = false,
    this.bold = false,
  });

  final String label;
  final String value;
  final FestivePalette palette;
  final double typeScale;
  final bool highlight;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: FestiveType.body(
                12.5 * typeScale,
                color: palette.ink,
                weight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: FestiveType.body(
              12.5 * typeScale,
              color: highlight ? palette.add : palette.ink,
              weight: bold || highlight ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Product details sheet (tap a card in a rail).
class FestiveProductSheet extends StatelessWidget {
  const FestiveProductSheet({
    super.key,
    required this.product,
    required this.store,
    required this.palette,
    required this.typeScale,
  });

  final FestiveProduct product;
  final FestiveStore store;
  final FestivePalette palette;
  final double typeScale;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (BuildContext context, Widget? _) {
        final int quantity = store.quantityOf(product);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: palette.hairline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 104,
                          height: 104,
                          child: Image.asset(
                            product.asset,
                            fit: BoxFit.cover,
                            cacheWidth: 312,
                            errorBuilder: (BuildContext context, Object error,
                                    StackTrace? stack) =>
                                ColoredBox(color: palette.surfaceSoft),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              product.name,
                              style: FestiveType.body(
                                15 * typeScale,
                                color: palette.ink,
                                weight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.unit,
                              style: FestiveType.body(
                                12 * typeScale,
                                color: palette.inkSoft,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: palette.addSoft,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Text(
                                        product.rating.toStringAsFixed(1),
                                        style: FestiveType.body(
                                          10.5 * typeScale,
                                          color: palette.add,
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(Icons.star_rounded,
                                          size: 11, color: palette.add),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (product.ratingCount > 0)
                                  Text(
                                    '${compactCount(product.ratingCount)} ratings',
                                    style: FestiveType.body(
                                      10.5 * typeScale,
                                      color: palette.inkSoft,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              rupee(product.price),
                              style: FestiveType.body(
                                19 * typeScale,
                                color: palette.ink,
                                weight: FontWeight.w800,
                              ),
                            ),
                            if (product.hasDiscount)
                              Text(
                                '${rupee(product.mrp)}  ·  ${product.discountPercent}% off',
                                style: FestiveType.body(
                                  11 * typeScale,
                                  color: palette.inkSoft,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                      ),
                      AddToCartButton(
                        quantity: quantity,
                        palette: palette,
                        typeScale: typeScale * 1.25,
                        onAdd: () => store.add(product),
                        onRemove: () => store.remove(product),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
