import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/order_provider.dart';
import '../utils/constants.dart';
import '../utils/tokens.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/live_entrance.dart';
import '../widgets/role_common.dart';
import '../utils/format.dart';
import 'main_shell.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  /// Rows an entrance animation has already played for, so a status update
  /// arriving live for an order already on screen doesn't replay it.
  final Set<String> _seenIds = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final orderProvider = context.watch<OrderProvider>();
    final orders = orderProvider.orders;

    // No orders and a load that failed are two different things.
    if (orderProvider.loadFailed && orders.isEmpty) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: GradientAppBar(
            title: Text(l10n.ordersTitle,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            centerTitle: true),
        body: RoleError(
          title: l10n.ordersLoadFailed,
          onRetry: orderProvider.loadOrders,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
          title: Text(l10n.ordersTitle,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          centerTitle: true),
      body: orders.isEmpty
          ? RoleEmpty(
              icon: Iconsax.receipt,
              title: l10n.ordersEmptyTitle,
              message: l10n.ordersEmptyBody,
              action: SizedBox(
                height: AppControl.lg,
                child: ElevatedButton.icon(
                  onPressed: () => MainShell.goTo(context, MainShell.home),
                  icon: const Icon(Iconsax.shopping_bag, size: 18),
                  label: const Text(
                    'Start shopping',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              itemCount: orders.length,
              itemBuilder: (context, index) => LiveEntrance(
                key: ValueKey(orders[index].id),
                id: orders[index].id,
                seen: _seenIds,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OrderDetailScreen(orderId: orders[index].id),
                      ),
                    );
                  },
                  child: _OrderCard(order: orders[index]),
                ),
              ),
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  /// What each status means in colour, matching the amber/green/red the
  /// support tickets use: a delivered order reads as done, a cancelled one
  /// as red, everything in flight as amber.
  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppConstants.successColor;
      case 'cancelled':
        return AppConstants.dangerColor;
      default:
        return const Color(0xFFF59E0B); // amber, for everything in flight
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.listGap),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The first item's photo makes the card readable at a glance;
              // an order without pictures reads like a database dump.
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 46,
                  height: 46,
                  color: AppConstants.backgroundColor,
                  child: (order.items.isNotEmpty &&
                          order.items.first.product.gallery.isNotEmpty)
                      ? Image.network(
                          order.items.first.product.gallery.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Iconsax.receipt,
                            size: 20,
                            color: Colors.grey,
                          ),
                        )
                      : const Icon(Iconsax.receipt, size: 20, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _itemsSummary(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${order.formattedDate} · ${order.shortRef}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // A live status change (a seller confirming, a rider marking
              // it delivered) pops the badge in fresh rather than swapping
              // its text in place — the same tell a chat app gives a
              // message that just went from sent to read.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: Container(
                  key: ValueKey(order.status),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    order.statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).ordersTotal,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12.5,
                  color: Color(0xFF757575),
                ),
              ),
              Text(
                formatRupees(order.totalAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15.5,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The card's headline: the first line item, then how many more hide
  /// behind it, so a five-item order still reads as one clean line.
  String _itemsSummary() {
    if (order.items.isEmpty) return '';
    final first = order.items.first;
    final summary =
        '${first.product.name} × ${first.quantity}';
    final more = order.items.length - 1;
    return more > 0 ? '$summary +$more more' : summary;
  }
}
