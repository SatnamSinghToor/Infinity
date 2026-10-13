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

/// Blinkit's second and last step: everything else was settled on the cart
/// (items, coupon, tip, instructions, address), so this page only asks how
/// to pay — the bill total on top, the ways to pay, and one button.
class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedPayment = 0;
  bool _isPlacingOrder = false;
  bool _useWallet = false;

  /// The rider's tip in rupees; 0 is no tip. Always one of [tipOptions].
  late final int _tip = widget.tip;

  late final Map<String, dynamic>? _appliedCoupon = widget.coupon;

  String get _deliveryNote => widget.deliveryNote;

  List<String> _paymentMethods(AppLocalizations l10n) => [
        l10n.checkoutPayUpi,
        l10n.checkoutPayCard,
        l10n.checkoutPayCod,
      ];

  static const _paymentMethodCodes = ['upi', 'card', 'cod'];

  static const _paymentIcons = [
    Iconsax.mobile,
    Iconsax.card,
    Iconsax.money_3,
  ];

  /// What the cart's coupon takes off, as the bill showed it.
  double _discountFor(double subtotal) =>
      couponDiscountFor(_appliedCoupon, subtotal);

  /// The wallet money this order would use: never more than the bill, never
  /// more than the balance, and only when the switch is on.
  int _walletUsedFor(double payableAfterDiscount) {
    if (!_useWallet) return 0;
    return walletUseFor(
      payable: payableAfterDiscount,
      balance: context.read<WalletProvider>().balance.toDouble(),
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
    });
  }

  Future<void> _placeOrder(CartProvider cartProvider) async {
    final l10n = AppLocalizations.of(context);
    final selectedAddress = widget.address;
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

    setState(() => _isPlacingOrder = true);

    // The server prices the order from its own copy of the cart, so bring
    // that up to date before paying or ordering.
    if (!await cartProvider.syncToServer()) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
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
    if (!mounted) return;

    final paymentMethod = _paymentMethodCodes[_selectedPayment];
    final subtotal = cartProvider.totalAmount;
    final deliveryFee = OrderProvider.deliveryFeeFor(cartProvider.items);
    final discount = _discountFor(subtotal);
    final walletUsed = _walletUsedFor(subtotal + deliveryFee - discount);
    // What the summary on this screen is telling the customer to expect.
    final promisedTotal = payableTotalFor(
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      walletUsed: walletUsed.toDouble(),
      tip: _tip.toDouble(),
    );
    String? paymentId;

    if (paymentMethod != 'cod') {
      final result = await PaymentService.payForCart(
        contactPhone: selectedAddress.phone,
        couponCode: _appliedCoupon?['code'] as String? ?? '',
        walletAmount: walletUsed,
        tip: _tip,
      );
      if (!mounted) return;
      if (!result.success) {
        setState(() => _isPlacingOrder = false);
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

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final order = await orderProvider.placeOrder(
      cartItems: cartProvider.items,
      address: selectedAddress.fullAddress,
      phone: selectedAddress.phone,
      name: selectedAddress.fullName,
      paymentMethod: paymentMethod,
      addressId: selectedAddress.id.isEmpty ? null : selectedAddress.id,
      paymentId: paymentId,
      couponCode: _appliedCoupon?['code'] as String? ?? '',
      walletUsed: walletUsed,
      deliveryNote: _deliveryNote,
      tip: _tip,
    );

    if (!mounted) return;
    setState(() => _isPlacingOrder = false);

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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OrderConfirmationScreen(
          order: order,
          totalNotice: totalNotice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final paymentMethods = _paymentMethods(l10n);
    final walletBalance = context.watch<WalletProvider>().balance;

    final subtotal = cartProvider.totalAmount;
    final deliveryFee = OrderProvider.deliveryFeeFor(cartProvider.items);
    final discount = _discountFor(subtotal);
    final walletUsed = _walletUsedFor(subtotal + deliveryFee - discount);
    final finalTotal = payableTotalFor(
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      walletUsed: walletUsed.toDouble(),
      tip: _tip.toDouble(),
    );
    final cod = _paymentMethodCodes[_selectedPayment] == 'cod';

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
                _card(
                  child: Column(
                    children: [
                      for (var i = 0; i < paymentMethods.length; i++) ...[
                        if (i > 0)
                          Divider(height: 1, color: context.tokens.border),
                        _paymentRow(i, paymentMethods[i]),
                      ],
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
                                  fontWeight: FontWeight.w700,
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
                          value: _useWallet,
                          activeThumbColor: context.tokens.primary,
                          onChanged: (value) =>
                              setState(() => _useWallet = value),
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
                                fontWeight: FontWeight.w700,
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
      bottomNavigationBar: _payBar(l10n, cartProvider, finalTotal, cod),
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
                    fontWeight: FontWeight.w800,
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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.tokens.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }

  Widget _iconTile(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: context.tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: context.tokens.primary),
    );
  }

  Widget _paymentRow(int index, String label) {
    final selected = _selectedPayment == index;
    return Pressable(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedPayment = index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              _iconTile(_paymentIcons[index]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                selected ? Iconsax.tick_circle : Iconsax.record,
                size: 22,
                color:
                    selected ? context.tokens.primary : context.tokens.border,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The amount and the one button, as Blinkit pins them to the bottom.
  Widget _payBar(
    AppLocalizations l10n,
    CartProvider cartProvider,
    double finalTotal,
    bool cod,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: context.tokens.card,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SizedBox(
            height: 56,
            child: Pressable(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.tokens.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed:
                    _isPlacingOrder ? null : () => _placeOrder(cartProvider),
                child: _isPlacingOrder
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatRupees(finalTotal),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                l10n.cartTotalLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              cod
                                  ? l10n.checkoutPlaceOrder
                                  : l10n.checkoutPayNow,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Icon(Iconsax.arrow_right_3_copy, size: 18),
                        ],
                      ),
              ),
            ),
          ),
        ),
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
                borderRadius: BorderRadius.circular(16),
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
                        fontSize: 22, fontWeight: FontWeight.bold),
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
                        color: AppConstants.dangerColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              AppConstants.dangerColor.withValues(alpha: 0.35),
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
                          fontWeight: FontWeight.bold,
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => MainShell.goTo(context, MainShell.home),
                child: Text(
                  l10n.checkoutContinue,
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
}
