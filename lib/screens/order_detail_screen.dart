import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../models/order.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../services/invoice_service.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/role_common.dart';
import '../utils/format.dart';
import 'cart_screen.dart';
import 'order_support_screen.dart';
import 'order_tracking_screen.dart';
import '../widgets/pressable.dart';

/// One order — opened from the orders list, or straight from a notification.
///
/// The order used to be looked for in the list that happened to be in memory,
/// and when it was not there the screen quietly made one up: no items, a total
/// of zero. Someone who tapped a notification before the list had loaded — or
/// after a restart — saw that blank order, which reads as "my order is gone".
/// The provider is asked instead (memory first, backend second), and the two
/// ways of having nothing to show are kept apart: the order could not be
/// loaded, or this account has no such order.
class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _resolve();
    context.read<OrderProvider>().watchOrderStatus(widget.orderId);
  }

  @override
  void dispose() {
    context.read<OrderProvider>().watchOrderStatus(null);
    super.dispose();
  }

  Future<void> _resolve() async {
    final provider = context.read<OrderProvider>();
    final order = await provider.findOrder(widget.orderId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _order = order;
      _failed = order == null && provider.lookupFailed;
    });
  }

  void _retry() {
    setState(() {
      _loading = true;
      _failed = false;
    });
    _resolve();
  }

  Widget _shell(String title, Widget body) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: body,
    );
  }

  /// Shown when there is no order to draw. Could not ask is not the same as
  /// "no such order", so the first one offers the retry and the second one
  /// says plainly what a missing order means.
  Widget _nothingToShow() {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return RoleLoading(message: l10n.orderDetailLoading);
    }
    if (_failed) {
      return RoleError(
        title: l10n.orderDetailLoadFailed,
        message: l10n.orderDetailLoadFailedBody,
        onRetry: _retry,
      );
    }
    return RoleEmpty(
      icon: Iconsax.box,
      title: l10n.orderDetailNotFound,
      message: l10n.orderDetailNotFoundBody,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Once resolved, the order also lives in the provider's list, where
    // watchOrderStatus keeps its status current — a seller marking it
    // "preparing" or a rider marking it "out for delivery" reaches this
    // screen the moment it happens, no refresh needed.
    final live = context.watch<OrderProvider>().orders;
    Order? fromProvider;
    for (final o in live) {
      if (o.id == widget.orderId) {
        fromProvider = o;
        break;
      }
    }
    final order = fromProvider ?? _order;
    if (order == null) {
      return _shell(
        _loading ? l10n.orderDetailTitle : l10n.orderDetailNotFoundTitle,
        _nothingToShow(),
      );
    }

    return _shell(
      l10n.orderDetailTitle,
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(order),
            // The delivery partner's phone has been feeding the tracking
            // table all along; until now nothing on this side could read it.
            if (_isTrackable(order)) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Pressable(
                    child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderTrackingScreen(orderId: order.id),
                      ),
                    );
                  },
                  icon: const Icon(Iconsax.location, size: 18),
                  label: Text(l10n.orderDetailTrack,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                )),
              ),
            ],
            const SizedBox(height: 16),
            _buildSection(l10n.orderDetailSectionInfo),
            const SizedBox(height: 8),
            _buildInfoCard([
              _buildInfoRow(l10n.orderDetailOrderId, order.id),
              _buildInfoRow(l10n.orderDetailDate, order.formattedDate),
              _buildInfoRow(l10n.orderDetailStatusLabel, order.statusLabel),
            ]),
            const SizedBox(height: 16),
            _buildSection(l10n.orderDetailSectionAddress),
            const SizedBox(height: 8),
            _buildInfoCard([
              _buildInfoRow(l10n.orderDetailName, order.name),
              _buildInfoRow(l10n.orderDetailPhone, order.phone),
              _buildInfoRow(l10n.orderDetailAddress, order.address),
            ]),
            const SizedBox(height: 16),
            _buildSection(l10n.orderDetailSectionItems),
            const SizedBox(height: 8),
            ...order.items.map(
              (item) => _buildOrderItem(context, item, order),
            ),
            if (order.status == 'delivered' || order.status == 'cancelled') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Pressable(
                    child: ElevatedButton.icon(
                  onPressed: () => _orderAgain(order),
                  icon: const Icon(Iconsax.repeat, size: 18),
                  label: Text(l10n.orderDetailOrderAgain,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                )),
              ),
              if (order.status == 'delivered') ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: Pressable(
                      child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await InvoiceService.share(order);
                      } catch (e) {
                        debugPrint('Invoice failed: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.orderDetailInvoiceFailed,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Iconsax.document_download, size: 18),
                    label: Text(l10n.orderDetailInvoice,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  )),
                ),
              ],
            ],
            if (order.status == 'delivered' && order.deliveryId != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Pressable(
                    child: OutlinedButton.icon(
                  onPressed: () => _showDeliveryRatingDialog(context, order),
                  icon: const Icon(Iconsax.star, size: 18),
                  label: Text(l10n.orderDetailRatePartner,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                )),
              ),
            ],
            const SizedBox(height: 16),
            _buildSection(l10n.orderDetailSectionPayment),
            const SizedBox(height: 8),
            _buildInfoCard([
              _buildInfoRow(
                l10n.orderDetailSubtotal,
                formatRupees(order.itemsSubtotal),
              ),
              _buildInfoRow(
                l10n.orderDetailDeliveryFee,
                order.deliveryFee > 0
                    ? formatRupees(order.deliveryFee)
                    : l10n.orderDetailFree,
                isGreen: order.deliveryFee <= 0,
              ),
              if (order.tip > 0)
                _buildInfoRow(
                  l10n.orderDetailTip,
                  formatRupees(order.tip),
                ),
              if (order.walletUsed > 0)
                _buildInfoRow(
                  l10n.orderDetailWalletApplied,
                  '- ${formatRupees(order.walletUsed)}',
                  isGreen: true,
                ),
              const Divider(height: 20),
              _buildInfoRow(
                l10n.orderDetailTotal,
                formatRupees(order.totalAmount),
                isBold: true,
                isPrimary: true,
              ),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Pressable(
                  child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderSupportScreen(orderId: order.id),
                    ),
                  );
                },
                icon: const Icon(Iconsax.message_question, size: 18),
                label: Text(l10n.orderDetailSupport,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              )),
            ),
            const SizedBox(height: 24),
            if (order.status == 'pending' || order.status == 'confirmed')
              SizedBox(
                height: 48,
                child: Pressable(
                    child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.dangerColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    _showCancelDialog(context, order);
                  },
                  child: Text(
                    l10n.orderDetailCancelOrder,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
              ),
          ],
        ),
      ),
    );
  }

  /// Whether this order is worth tracking: still on its way somewhere.
  /// Delivered and cancelled orders have nothing left to follow.
  static bool _isTrackable(Order order) {
    const live = [
      'pending',
      'confirmed',
      'preparing',
      'ready_for_pickup',
      'out_for_delivery',
    ];
    return live.contains(order.status);
  }

  /// Puts this order's items back in the cart, as they are in stock today
  /// — the same product at today's price, never more than there is.
  void _orderAgain(Order order) {
    final l10n = AppLocalizations.of(context);
    final products = context.read<ProductProvider>();
    final cart = context.read<CartProvider>();
    var added = 0;
    var skipped = 0;
    for (final item in order.items) {
      final current = products.getProductById(item.product.id);
      if (current == null || !current.isAvailable) {
        skipped++;
        continue;
      }
      var got = 0;
      for (var i = 0; i < item.quantity; i++) {
        final ok = cart.addToCart(
          current,
          variantId: item.variantId,
          variantName: item.variantName,
          variantPrice: item.variantPrice,
        );
        if (!ok) break;
        got++;
      }
      got > 0 ? added++ : skipped++;
    }
    final message = added == 0
        ? l10n.orderDetailOrderAgainNone
        : skipped == 0
            ? l10n.orderDetailOrderAgainAdded(added)
            : '${l10n.orderDetailOrderAgainAdded(added)}. '
                '${l10n.orderDetailOrderAgainSkipped(skipped)}';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
          action: added == 0
              ? null
              : SnackBarAction(
                  label: l10n.orderDetailViewCart,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  ),
                ),
        ),
      );
  }

  Widget _buildStatusCard(Order order) {
    final l10n = AppLocalizations.of(context);
    // The journey has to match the status underneath it: this card used to
    // say "Order Placed" with three grey steps even for a delivered order.
    final step = order.stepIndex;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppConstants.primaryColor, AppConstants.accentColor],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            l10n.orderDetailStatusWith(order.statusLabel),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            order.id,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatusStep(
                icon: Iconsax.box,
                label: l10n.orderDetailStepPlaced,
                active: step >= 0,
              ),
              _StatusStep(
                icon: Iconsax.truck,
                label: l10n.orderDetailStepPreparing,
                active: step >= 1,
              ),
              _StatusStep(
                icon: Iconsax.location,
                label: l10n.orderDetailStepOnWay,
                active: step >= 2,
              ),
              _StatusStep(
                icon: Iconsax.tick_circle,
                label: l10n.orderDetailStepDelivered,
                active: step >= 3,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    bool isPrimary = false,
    bool isGreen = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isPrimary
                  ? AppConstants.primaryColor
                  : isGreen
                      ? Colors.green
                      : AppConstants.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(BuildContext context, CartItem item, Order order) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    item.product.name.isNotEmpty ? item.product.name[0] : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      l10n.orderDetailQty(item.quantity),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                formatRupees(item.totalPrice),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
          if (order.status == 'delivered') ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Pressable(
                  child: TextButton.icon(
                onPressed: () => _showReviewDialog(context, item),
                icon: const Icon(Iconsax.star, size: 16),
                label: Text(l10n.orderDetailWriteReview,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              )),
            ),
          ],
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context, CartItem item) {
    final l10n = AppLocalizations.of(context);
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.orderDetailReviewTitle(item.product.name),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => Pressable(
                        child: IconButton(
                      onPressed: () => setDialogState(() => rating = i + 1),
                      icon: Icon(
                        i < rating ? Iconsax.star : Iconsax.star_copy,
                        color: Colors.orange,
                      ),
                    )),
                  ),
                ),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: l10n.orderDetailReviewHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Pressable(
                child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.orderDetailCancel,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            )),
            Pressable(
                child: ElevatedButton(
              onPressed: () async {
                final uid = SupabaseService.client.auth.currentUser?.id;
                if (uid == null) return;
                try {
                  await SupabaseService.client.from('reviews').upsert({
                    'user_id': uid,
                    'order_id': widget.orderId,
                    'product_id': item.product.id,
                    'rating': rating,
                    'comment': commentController.text.trim(),
                  }, onConflict: 'order_id,product_id');
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(l10n.orderDetailReviewThanks,
                              maxLines: 1, overflow: TextOverflow.ellipsis)),
                    );
                  }
                } catch (_) {
                  // Leave the dialog up with what was written in it: closing
                  // it silently looked like the review had been saved.
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.orderDetailReviewFailed,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(l10n.orderDetailSubmit,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            )),
          ],
        ),
      ),
    );
  }

  void _showDeliveryRatingDialog(BuildContext context, Order order) {
    final l10n = AppLocalizations.of(context);
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.orderDetailRateTitle,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => Pressable(
                        child: IconButton(
                      onPressed: () => setDialogState(() => rating = i + 1),
                      icon: Icon(
                        i < rating ? Iconsax.star : Iconsax.star_copy,
                        color: Colors.orange,
                      ),
                    )),
                  ),
                ),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: l10n.orderDetailRateHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Pressable(
                child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            )),
            Pressable(
                child: ElevatedButton(
              onPressed: () async {
                final uid = SupabaseService.client.auth.currentUser?.id;
                if (uid == null || order.deliveryId == null) return;
                try {
                  await SupabaseService.client.from('delivery_ratings').upsert(
                    {
                      'order_id': order.id,
                      'customer_id': uid,
                      'delivery_id': order.deliveryId,
                      'rating': rating,
                      'comment': commentController.text.trim(),
                    },
                    onConflict: 'order_id',
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.orderDetailRateThanks,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.orderDetailRateFailed,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Submit',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            )),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Order order) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.orderDetailCancelTitle,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        content: Text(l10n.orderDetailCancelQuestion),
        actions: [
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.orderDetailNo,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
          Pressable(
              child: ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final provider = context.read<OrderProvider>();
              final cancelled =
                  await provider.updateOrderStatus(order.id, 'cancelled');
              if (!mounted) return;
              // Only say it is cancelled once the backend has said so too.
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    cancelled
                        ? l10n.orderDetailCancelled(order.id)
                        : l10n.orderDetailCancelFailed,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  backgroundColor: AppConstants.dangerColor,
                ),
              );
              await _resolve();
            },
            child: Text(l10n.orderDetailCancelOrder,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
        ],
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _StatusStep({
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: active ? AppConstants.primaryColor : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: active ? AppConstants.primaryColor : Colors.grey,
          ),
        ),
      ],
    );
  }
}
