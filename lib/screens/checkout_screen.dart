import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/delivery_eta_provider.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import '../models/address.dart';
import '../providers/wallet_provider.dart';
import '../services/analytics.dart';
import '../services/payment_service.dart';
import '../services/upi_apps_service.dart';
import '../utils/checkout_math.dart';
import '../utils/constants.dart';
import '../utils/tokens.dart';
import '../utils/format.dart';
import '../widgets/gradient_app_bar.dart';
import 'main_shell.dart';
import '../widgets/pressable.dart';

class CheckoutScreen extends StatefulWidget {
  /// Where the order goes, with who takes it: settled on the cart.
  final Address address;

  /// The rider's tip in rupees, chosen on the cart; 0 is none.
  final int tip;

  /// The instructions for the rider, ticked and typed on the cart.
  final String deliveryNote;

  /// The coupon the cart applied, as the coupons table returned it.
  final Map<String, dynamic>? coupon;

  const CheckoutScreen({
    super.key,
    required this.address,
    this.tip = 0,
    this.deliveryNote = '',
    this.coupon,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

/// Places the order with the way to pay the picker remembered, straight
/// from the cart: the cart settles everything, the picker's chosen method,
/// wallet switch, coupon and tip ride along, and the confirmation opens
/// over the shell.
Future<void> placeOrderNow(
  BuildContext context, {
  required CartProvider cartProvider,
  required Address address,
  required int tip,
  required String deliveryNote,
  required Map<String, dynamic>? coupon,
  required bool useWallet,
}) async {
  final l10n = AppLocalizations.of(context);
  final selectedAddress = address;
  if (selectedAddress.fullName.trim().isEmpty ||
      selectedAddress.phone.trim().isEmpty ||
      selectedAddress.fullAddress.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.checkoutFillDetails,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (cartProvider.items.isEmpty) return;

  // The server prices the order from its own copy of the cart, so bring
  // that up to date before paying or ordering.
  if (!await cartProvider.syncToServer()) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.checkoutCartSyncFailed,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  if (!context.mounted) return;

  final paymentMethod = PaymentChoice.code;
  final subtotal = cartProvider.totalAmount;
  final deliveryFee = OrderProvider.deliveryFeeFor(cartProvider.items);
  final discount = couponDiscountFor(coupon, subtotal);
  // The wallet money this order would use: never more than the bill, never
  // more than the balance, and only when the picker's switch is on.
  final walletUsed = useWallet
      ? walletUseFor(
          payable: subtotal + deliveryFee - discount,
          balance: context.read<WalletProvider>().balance.toDouble(),
        )
      : 0;
  // What the customer was promised while picking a way to pay.
  final promisedTotal = payableTotalFor(
    subtotal: subtotal,
    deliveryFee: deliveryFee,
    discount: discount,
    walletUsed: walletUsed.toDouble(),
    tip: tip.toDouble(),
  );
  String? paymentId;

  if (paymentMethod != 'cod') {
    final result = await PaymentService.payForCart(
      contactPhone: selectedAddress.phone,
      couponCode: coupon?['code'] as String? ?? '',
      walletAmount: walletUsed,
      tip: tip,
    );
    if (!context.mounted) return;
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? l10n.checkoutPaymentFailed,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    paymentId = result.paymentId;
  }

  if (!context.mounted) return;
  final orderProvider = Provider.of<OrderProvider>(context, listen: false);
  final order = await orderProvider.placeOrder(
    cartItems: cartProvider.items,
    address: selectedAddress.fullAddress,
    phone: selectedAddress.phone,
    name: selectedAddress.fullName,
    paymentMethod: paymentMethod,
    addressId: selectedAddress.id.isEmpty ? null : selectedAddress.id,
    paymentId: paymentId,
    couponCode: coupon?['code'] as String? ?? '',
    walletUsed: walletUsed,
    deliveryNote: deliveryNote,
    tip: tip,
  );

  if (!context.mounted) return;

  if (order == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          paymentId != null
              ? l10n.checkoutPaidOrderFailed(paymentId)
              : (orderProvider.lastError ?? l10n.checkoutPlaceFailed),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  Analytics.log('order_placed', {
    'total': order.totalAmount,
    'items': cartProvider.itemCount,
    'payment': paymentMethod,
    'coupon': discount > 0,
  });

  cartProvider.clearCart();

  // The server has the last word on the amount, and it does not always agree
  // with the promise: a coupon that this account has already used is left
  // out, and the order costs more than the screen said. Say so, on the
  // confirmation itself, instead of letting the customer find out later.
  // (Only when no wallet money is involved: how the server records wallet
  // spending in the order total is not something this screen can see.)
  String? totalNotice;
  if (walletUsed == 0 &&
      chargedDiffersFromPromise(promisedTotal, order.totalAmount)) {
    totalNotice = discount > 0
        ? l10n.checkoutFinalTotalCoupon(formatRupees(order.totalAmount))
        : l10n.checkoutFinalTotalChanged(
            formatRupees(order.totalAmount),
            formatRupees(promisedTotal),
          );
  }

  // On top of the shell, not replacing it: the bar's Continue returns home
  // and the back arrow lands on an emptied cart instead of losing the app.
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => OrderConfirmationScreen(
        order: order,
        totalNotice: totalNotice,
      ),
    ),
  );
}

/// Blinkit's second and last step: everything else was settled on the cart
/// (items, coupon, tip, instructions, address), so this page only asks how
/// to pay — the bill total on top, the ways to pay, no button of its own.
class _CheckoutScreenState extends State<CheckoutScreen> {
  /// The UPI apps on this phone, card and cash: the choice itself lives in
  /// [PaymentChoice], so it survives the hop between the cart and this page
  /// and the cart can read the same selection for its own bar.
  List<InstalledUpiApp> get _upiApps => PaymentChoice.list;

  /// The rider's tip in rupees, settled on the cart before this page opened.
  int get _tip => widget.tip;

  /// The icon drawn before each method: the real launcher icon of the UPI
  /// app, or a plain glyph for card and cash. No box behind either.
  Widget _paymentIcon(int index) {
    if (index < _upiApps.length) {
      final icon = _upiApps[index].icon;
      return SizedBox(
        width: 38,
        height: 38,
        child: (icon != null)
            ? Image.memory(icon, fit: BoxFit.contain)
            : const Icon(Iconsax.mobile, size: 26, color: Color(0xFF20252E)),
      );
    }
    final glyphIndex = index - _upiApps.length;
    // Same 38x38 box the UPI icons ride in, glyph centred inside it, so
    // every row's icon sits on one straight line. Ink, not the accent.
    return SizedBox(
      width: 38,
      height: 38,
      child: Center(
        child: Icon(
          const [
            Iconsax.card,
            Iconsax.money_3,
          ][glyphIndex.clamp(0, 1)],
          size: 24,
          color: const Color(0xFF20252E),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cart = Provider.of<CartProvider>(context, listen: false);
      Analytics.log('checkout_started', {
        'items': cart.itemCount,
        'subtotal': cart.totalAmount,
      });
      // The UPI apps on this phone, each one with its own brand icon.
      PaymentChoice.ensureLoaded().then((_) {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final walletBalance = context.watch<WalletProvider>().balance;

    final subtotal = cartProvider.totalAmount;
    final deliveryFee = OrderProvider.deliveryFeeFor(cartProvider.items);
    final discount = couponDiscountFor(widget.coupon, subtotal);
    final walletUsed = PaymentChoice.useWallet
        ? walletUseFor(
            payable: subtotal + deliveryFee - discount,
            balance: context.read<WalletProvider>().balance.toDouble(),
          )
        : 0;
    final finalTotal = payableTotalFor(
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      walletUsed: walletUsed.toDouble(),
      tip: _tip.toDouble(),
    );

    return Scaffold(
      backgroundColor: context.tokens.surface,
      body: Column(
        children: [
          Container(
            color: context.tokens.surface,
            child: SafeArea(
              bottom: false,
              child: _header(l10n, formatRupees(finalTotal)),
            ),
          ),
          Divider(height: 1, thickness: 1, color: context.tokens.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // The payment picker, grouped like the pay apps on this
                // phone: every installed UPI app under "Recommended" with
                // its real logo, then Cards, then Cash.
                _card(
                  child: Column(
                    children: [
                      _paymentSection(
                        'Recommended',
                        [
                          for (var i = 0; i < _upiApps.length; i++)
                            _paymentRow(
                              i,
                              _upiApps[i].package == 'upi'
                                  ? _upiApps[i].label
                                  : '${_upiApps[i].label} UPI',
                            ),
                        ],
                      ),
                      _paymentSection('Cards', [
                        _paymentRow(
                          _upiApps.length,
                          l10n.checkoutPayCard,
                        ),
                      ]),
                      _paymentSection('Cash', [
                        _paymentRow(
                          _upiApps.length + 1,
                          l10n.checkoutPayCod,
                        ),
                      ]),
                    ],
                  ),
                ),
                if (walletBalance > 0)
                  _card(
                    child: Row(
                      children: [
                        _iconTile(Iconsax.wallet_3),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.checkoutUseWallet('$walletBalance'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (walletUsed > 0)
                                Text(
                                  '${l10n.checkoutWalletUsed}: -₹$walletUsed',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: context.tokens.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Switch(
                          value: PaymentChoice.useWallet,
                          activeColor: context.tokens.primary,
                          onChanged: (value) =>
                              setState(() => PaymentChoice.useWallet = value),
                        ),
                      ],
                    ),
                  ),
                _card(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _iconTile(Iconsax.location),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.address.fullName} · '
                              '${widget.address.phone}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.address.fullAddress,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.3,
                                color: context.tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(AppLocalizations l10n, String total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          Pressable(
            child: IconButton(
              icon: const Icon(Iconsax.arrow_left_copy, size: 24),
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.checkoutPayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: context.tokens.textPrimary,
                  ),
                ),
                Text(
                  l10n.checkoutBillTotal(total),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: context.tokens.card,
        borderRadius: AppRadius.card,
        border: Border.all(color: context.tokens.border),
      ),
      child: child,
    );
  }

  Widget _iconTile(IconData icon) {
    return Icon(icon, size: 24, color: context.tokens.primary);
  }

  Widget _paymentRow(int index, String label) {
    final selected = PaymentChoice.index == index;
    return Pressable(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Choosing a row is the whole transaction on this page: remember
          // it and hand the customer straight back to the cart, whose bar
          // now shows the method and its Place Order button.
          setState(() {
            PaymentChoice.index = index;
            PaymentChoice.chosen = true;
          });
          Navigator.pop(context);
        },
        child: Container(
          // Selection is signalled by the tick alone: no wash, no band,
          // nothing behind the row.
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              _paymentIcon(index),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF20252E),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Iconsax.tick_circle : Iconsax.arrow_right_3_copy,
                size: 21,
                color: selected
                    ? AppConstants.successColor
                    : const Color(0xFF87909C),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A grouped payment block in the payment picker: a bold heading over a
  /// white card whose rows sit separated by hairlines.
  Widget _paymentSection(String title, List<Widget> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF20252E),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: context.tokens.border),
                  rows[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class OrderConfirmationScreen extends StatelessWidget {
  final Order order;

  /// Set when the server's total came out different from the amount the
  /// checkout screen had shown. Null on the ordinary, matching path.
  final String? totalNotice;

  const OrderConfirmationScreen({
    super.key,
    required this.order,
    this.totalNotice,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalNotice = this.totalNotice;
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
        title: Text(l10n.checkoutOrderPlacedTitle,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Icon(
                    Iconsax.tick_circle_copy,
                    size: 80,
                    color: AppConstants.successColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.checkoutSuccess,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.checkoutOrderId(order.id),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  if (totalNotice != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConstants.dangerColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              AppConstants.dangerColor.withOpacity(0.35),
                        ),
                      ),
                      child: Text(
                        totalNotice,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: AppConstants.dangerColor,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Order items
                  ...order.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              l10n.checkoutItemLine(
                                  item.product.name, item.quantity),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            formatRupees(item.totalPrice),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  // Delivery info
                  Row(
                    children: [
                      const Icon(
                        Iconsax.location,
                        size: 20,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.checkoutDeliveringTo(order.address),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Iconsax.clock, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        l10n.checkoutExpectedDelivery(
                          context.watch<DeliveryEtaProvider>().label ??
                              l10n.checkoutEtaUnknown,
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Iconsax.wallet_money,
                        size: 20,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.checkoutTotal(formatRupees(order.totalAmount)),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: AppControl.lg,
              child: Pressable(
                  child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                onPressed: () => MainShell.goTo(context, MainShell.home),
                child: Text(
                  l10n.checkoutContinue,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
}
