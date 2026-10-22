import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/delivery_eta_provider.dart';
import '../providers/product_provider.dart';
import '../providers/wishlist_provider.dart';
import '../widgets/home_all_sections.dart';
import 'category_listing_screen.dart';
import '../models/address.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/wallet_provider.dart';
import '../screens/checkout_screen.dart';
import '../utils/constants.dart';
import '../utils/tokens.dart';
import '../services/analytics.dart';
import '../services/supabase_service.dart';
import '../services/system_bars_service.dart';
import '../services/upi_apps_service.dart';
import '../utils/checkout_math.dart';
import '../utils/format.dart';
import '../widgets/checkout_address_sheets.dart';
import '../widgets/app_network_image.dart';
import '../widgets/role_common.dart';
import '../widgets/cart_action.dart';
import 'auth/login_screen.dart';
import 'main_shell.dart';
import '../widgets/pressable.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _searchController = TextEditingController();

  /// The search button looks through the items in this cart, not the store.
  bool _searching = false;
  String _query = '';

  // Blinkit settles the whole order on the cart; only the way to pay is
  // left for the next page. These are what the cart settles.

  /// The rider's tip in rupees; 0 is none. Always one of [tipOptions].
  int _tip = 0;

  /// Quick instructions ticked for the delivery partner, and a typed one.
  final Set<String> _noteChips = {};
  final _noteController = TextEditingController();

  final _couponController = TextEditingController();
  Map<String, dynamic>? _appliedCoupon;
  String? _couponError;
  bool _applyingCoupon = false;

  /// Whether a Place Order is running right now: the bar's button spins.
  bool _placingOrder = false;

  /// An address picked from the sheet; null means the one the app knows.
  Address? _pickedAddress;

  /// Who takes the order, when typed in because the account had none.
  String? _receiverName;
  String? _receiverPhone;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn && auth.addresses.isEmpty) auth.loadAddresses();
    // The payment apps behind the bar's method names, fetched once.
    PaymentChoice.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _noteController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  /// The ticked chips and the typed note, as one line for the rider.
  String get _deliveryNote => [
        ..._noteChips,
        if (_noteController.text.trim().isNotEmpty) _noteController.text.trim(),
      ].join('. ');

  /// Where the order goes: the address picked here, else the one under
  /// Home's search bar, else the default saved one. Null when none is
  /// known. Name and phone come from the account unless typed in here.
  Address? _deliveryAddress(AuthProvider auth) {
    final saved = auth.addresses;
    final fallback = saved.isEmpty
        ? null
        : saved.firstWhere((a) => a.isDefault, orElse: () => saved.first);
    final where = _pickedAddress?.fullAddress ??
        (auth.address.trim().isNotEmpty
            ? auth.address
            : fallback?.fullAddress ?? '');
    if (where.trim().isEmpty) return null;
    Address? match;
    for (final a in saved) {
      if (a.fullAddress.trim() == where.trim()) match = a;
    }
    final account = auth.userName.trim();
    return Address(
      id: _pickedAddress?.id ?? match?.id ?? '',
      label: _pickedAddress?.label ?? match?.label ?? 'Home',
      fullAddress: where,
      lat: _pickedAddress?.lat ?? match?.lat,
      lng: _pickedAddress?.lng ?? match?.lng,
      fullName: _receiverName ??
          (account.isEmpty || account == 'Guest' ? '' : account),
      phone: _receiverPhone ?? auth.phone.trim(),
    );
  }

  Future<void> _changeAddress(AuthProvider auth) async {
    final picked = await showAddressPicker(
      context,
      current: _deliveryAddress(auth)?.fullAddress,
    );
    if (picked != null && mounted) setState(() => _pickedAddress = picked);
  }

  /// Proceed To Pay: signs in, settles an address and who takes it if
  /// either is missing, then returns the ready address. Null means the
  /// flow stopped (login, address or receiver not settled).
  Future<Address?> _settledAddress(AuthProvider auth) async {
    if (!auth.isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return null;
    }
    var address = _deliveryAddress(auth);
    if (address == null) {
      await _changeAddress(auth);
      if (!mounted) return null;
      address = _deliveryAddress(auth);
      if (address == null) return null;
    }
    if (address.fullName.isEmpty || address.phone.isEmpty) {
      final who = await showReceiverSheet(
        context,
        name: address.fullName,
        phone: address.phone,
      );
      if (who == null || !mounted) return null;
      setState(() {
        _receiverName = who.$1;
        _receiverPhone = who.$2;
      });
      address = _deliveryAddress(auth);
      if (address == null) return null;
    }
    return address;
  }

  /// Opens the payment picker; tapping a row there selects it and lands
  /// right back here, with the bar showing the method.
  Future<void> _proceed(AuthProvider auth) async {
    final address = await _settledAddress(auth);
    if (address == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          address: address,
          tip: _tip,
          deliveryNote: _deliveryNote,
          coupon: _appliedCoupon,
        ),
      ),
    );
    // The picker may have changed the chosen method: redraw the bar.
    if (mounted) setState(() {});
  }

  /// Place Order: the picker's chosen way to pay spends nothing on its own
  /// tap; this runs the payment, or places the order straight away for
  /// cash, with everything the cart settled.
  Future<void> _placeOrder(AuthProvider auth) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.items.isEmpty) return;
    final address = await _settledAddress(auth);
    if (address == null || !mounted) return;
    setState(() => _placingOrder = true);
    try {
      await placeOrderNow(
        context,
        cartProvider: cart,
        address: address,
        tip: _tip,
        deliveryNote: _deliveryNote,
        coupon: _appliedCoupon,
        useWallet: PaymentChoice.useWallet,
      );
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  Future<void> _applyCoupon(double subtotal) async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _applyingCoupon = true;
      _couponError = null;
    });
    try {
      final rows = await SupabaseService.client
          .from('coupons')
          .select('code, discount_percent, max_discount, min_order_value')
          .eq('is_active', true)
          .ilike('code', code)
          .limit(1);
      if (!mounted) return;
      if (rows.isEmpty) {
        Analytics.log('coupon_failed', {'code': code, 'reason': 'invalid'});
        setState(() {
          _appliedCoupon = null;
          _couponError = l10n.checkoutCouponInvalid;
        });
      } else {
        final coupon = rows.first;
        final minOrder = (coupon['min_order_value'] as num?)?.toDouble() ?? 0;
        if (subtotal < minOrder) {
          Analytics.log('coupon_failed', {'code': code, 'reason': 'min_order'});
          setState(() {
            _appliedCoupon = null;
            _couponError = l10n.checkoutCouponMinOrder(formatRupees(minOrder));
          });
        } else {
          setState(() {
            _appliedCoupon = coupon;
            _couponError = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Coupon check failed: $e');
      if (mounted) setState(() => _couponError = l10n.checkoutCouponFailed);
    }
    if (mounted) setState(() => _applyingCoupon = false);
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      _query = '';
      _searchController.clear();
    });
  }

  bool _matches(CartItem item) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return item.product.name.toLowerCase().contains(q) ||
        (item.variantName?.toLowerCase().contains(q) ?? false) ||
        (item.product.brand?.toLowerCase().contains(q) ?? false);
  }

  Widget _header(AppLocalizations l10n, bool empty) {
    Widget circle(IconData icon, VoidCallback onTap) => Pressable(
            child: Material(
          color: const Color(0xFFEFEFEF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(icon, size: 22),
            ),
          ),
        ));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            // Back toggle beside the "My Cart" title — lands on the Home tab.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => MainShell.tab.value = MainShell.home,
              child: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Iconsax.arrow_left_copy, size: 24),
              ),
            ),
            Expanded(
              child: _searching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: l10n.cartSearchHint,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                      style: const TextStyle(fontSize: 18),
                    )
                  : Text(
                      l10n.cartTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimaryColor,
                      ),
                    ),
            ),
            if (_searching)
              circle(Icons.close_rounded, _toggleSearch)
            else if (!empty)
              circle(Iconsax.search_normal_1_copy, _toggleSearch),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final empty = cartProvider.items.isEmpty;
    final shown = cartProvider.items.where(_matches).toList();
    // The one gap the floating checkout card lifts itself by: the phone's
    // own nav strip. MediaQuery's viewPadding reads zero once the window
    // has gone edge-to-edge (see SystemBars), so the strip's height wins
    // when it is known.
    final bottomInset = SystemBars.stripHeight > 0
        ? SystemBars.stripHeight
        : MediaQuery.of(context).viewPadding.bottom > 0
            ? MediaQuery.of(context).viewPadding.bottom
            : 6.0;
    // The checkout card's full stack: 12+12 card padding, the ~48
    // "Delivering to" row (signed in with an address) and the 56 button.
    // Reserving for the tallest state, so the last card never slides under
    // the pinned card no matter which state the bar is in.
    // +12: the hair of lift the card carries above the nav line.
    const checkoutCardHeight = 140.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: AppConstants.backgroundColor,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          body: Column(
            children: [
              // The header reaches up behind the status bar, so the two
              // are one colour.
              Container(
                color: AppConstants.backgroundColor,
                child: SafeArea(
                  bottom: false,
                  child: _header(l10n, empty),
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEBEBEB)),
              Expanded(
                child: empty
                    ? _EmptyCart(
                        onBrowse: () => MainShell.tab.value = MainShell.home,
                        failed: cartProvider.loadFailed,
                        onRetry: cartProvider.loadCart,
                      )
                    : Stack(
                        children: [
                          ListView(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              16,
                              16,
                              // Room for the floating checkout card pinned
                              // at the very bottom: its full grown height,
                              // the gap it lifts by, and one breath of air.
                              // The old flat 140 fell short of the card's
                              // address row, so the last card hid under it.
                              checkoutCardHeight + bottomInset + 12,
                            ),
                            children: [
                              if (cartProvider.syncFailed)
                                _SyncNotice(cart: cartProvider),
                              if (!_searching)
                                // One merged section: the delivery header
                                // and every item row live inside a single
                                // white card, separated by hairlines — the
                                // gap between the old cards is gone.
                                Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    14,
                                    14,
                                    4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.xl),
                                  ),
                                  child: Column(
                                    children: [
                                      _DeliveryCard(
                                        count: cartProvider.itemCount,
                                        embedded: true,
                                      ),
                                      for (final item in shown)
                                        _CartItemCard(
                                          item: item,
                                          cart: cartProvider,
                                          embedded: true,
                                        ),
                                    ],
                                  ),
                                ),
                              // A clear rest between the merged section and
                              // the suggestions below it.
                              if (!_searching) ...[
                                const SizedBox(height: 18),
                                _AlsoLike(cart: cartProvider),
                              ],
                              if (shown.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 32,
                                  ),
                                  child: Center(
                                    child: Text(
                                      l10n.cartNoMatch,
                                      style: const TextStyle(
                                        color: AppConstants.textSecondaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              if (!_searching) ...[
                                _couponCard(l10n, cartProvider),
                                _BillCard(
                                  cart: cartProvider,
                                  discount: couponDiscountFor(
                                    _appliedCoupon,
                                    cartProvider.totalAmount,
                                  ),
                                  tip: _tip,
                                ),
                                _tipCard(l10n),
                                _instructionsCard(l10n),
                                _cancellationNote(l10n),
                              ],
                            ],
                          ),
                          if (!_searching)
                            Positioned(
                              left: 0,
                              right: 0,
                              // Sits right on the phone's own nav strip: the
                              // window knows the strip's exact height, and
                              // the card rests on top of it. The same inset
                              // the list reserves its bottom room by.
                              // Rides a touch higher than the nav bar's
                              // own line — a hair of lift.
                              bottom: bottomInset + 12,
                              child: _checkoutBar(
                                  l10n, cartProvider, authProvider),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ));
  }

  /// One white card of the cart, its heading inside it.
  Widget _card({String? title, String? subtitle, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.5,
                color: context.tokens.textSecondary,
              ),
            ),
          ],
          if (title != null) const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _couponCard(AppLocalizations l10n, CartProvider cart) {
    return _card(
      title: l10n.cartCoupons,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: l10n.checkoutCouponHint,
                    prefixIcon: const Icon(Iconsax.ticket_discount, size: 20),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: Pressable(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.tokens.primary,
                      side: BorderSide(color: context.tokens.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _applyingCoupon
                        ? null
                        : () => _applyCoupon(cart.totalAmount),
                    child: _applyingCoupon
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.checkoutApply,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
            ],
          ),
          if (_appliedCoupon != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.checkoutCouponApplied(_appliedCoupon!['code']),
              style: TextStyle(
                color: context.tokens.success,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (_couponError != null) ...[
            const SizedBox(height: 8),
            Text(
              _couponError!,
              style: TextStyle(color: context.tokens.danger, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  /// Optional tip chips; tapping the chosen one again takes the tip back
  /// off. The server checks the amount and credits it to the rider.
  Widget _tipCard(AppLocalizations l10n) {
    return _card(
      title: l10n.checkoutTipTitle,
      subtitle: l10n.checkoutTipBody,
      child: Row(
        children: [
          for (final amount in tipOptions) ...[
            Expanded(
              child: ChoiceChip(
                label: SizedBox(
                  width: double.infinity,
                  child: Text(
                    formatRupees(amount),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                selected: _tip == amount,
                showCheckmark: false,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                selectedColor: context.tokens.primary.withOpacity(0.15),
                onSelected: (_) =>
                    setState(() => _tip = _tip == amount ? 0 : amount),
              ),
            ),
            if (amount != tipOptions.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  /// Tap-to-add notes for the delivery partner, plus a line of free text.
  /// Sent with the order as its delivery note; the rider's run card shows it.
  Widget _instructionsCard(AppLocalizations l10n) {
    final options = [
      (Iconsax.notification_bing, l10n.checkoutNoteNoBell),
      (Iconsax.home_2, l10n.checkoutNoteLeaveDoor),
      (Iconsax.call, l10n.checkoutNoteCallArrive),
      (Iconsax.pet, l10n.checkoutNotePet),
    ];
    return _card(
      title: l10n.checkoutInstructions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (icon, text) in options)
                FilterChip(
                  avatar: Icon(icon, size: 16),
                  label:
                      Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
                  selected: _noteChips.contains(text),
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  selectedColor: context.tokens.primary.withOpacity(0.15),
                  onSelected: (on) => setState(() =>
                      on ? _noteChips.add(text) : _noteChips.remove(text)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            maxLength: 120,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l10n.checkoutInstructionsHint,
              isDense: true,
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _cancellationNote(AppLocalizations l10n) {
    return _card(
      title: l10n.cartCancellationTitle,
      child: Text(
        l10n.cartCancellationBody,
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: context.tokens.textSecondary,
        ),
      ),
    );
  }

  /// The chosen method's face on the bar: the real launcher icon of the
  /// UPI app, or a glyph for card and cash.
  Widget _methodIcon() {
    final icon = PaymentChoice.icon;
    if (icon != null) return Image.memory(icon, fit: BoxFit.contain);
    return Icon(
      PaymentChoice.code == 'card' ? Iconsax.card : Iconsax.money_3,
      size: 14,
      color: context.tokens.primary,
    );
  }

  /// Blinkit's pinned bottom: where it is going, with Change, and the one
  /// button — total on its left, Proceed To Pay on its right.
  Widget _checkoutBar(
    AppLocalizations l10n,
    CartProvider cart,
    AuthProvider auth,
  ) {
    final address = auth.isLoggedIn ? _deliveryAddress(auth) : null;
    final discount = couponDiscountFor(_appliedCoupon, cart.totalAmount);
    final deliveryFee = OrderProvider.deliveryFeeFor(cart.items);
    final payableAfterDiscount = cart.totalAmount + deliveryFee - discount;
    final walletUsed = PaymentChoice.useWallet
        ? walletUseFor(
            payable: payableAfterDiscount,
            balance: context.read<WalletProvider>().balance.toDouble(),
          )
        : 0;
    final total = payableTotalFor(
      subtotal: cart.totalAmount,
      deliveryFee: deliveryFee,
      discount: discount,
      walletUsed: walletUsed.toDouble(),
      tip: _tip.toDouble(),
    );
    final label = !auth.isLoggedIn
        ? l10n.cartLoginToCheckout
        : address == null
            ? l10n.cartSelectAddress
            : l10n.cartProceedToPay;
    // Floating card like the nav pill under it: side gutter, fully rounded
    // and an even gap between the two, instead of a full-bleed sheet that
    // sits flush on the bar.
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        0,
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: context.tokens.card,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xl)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (address != null) ...[
            Row(
              children: [
                Icon(
                  address.label == 'Work'
                      ? Iconsax.briefcase
                      : Iconsax.home_2,
                  size: 22,
                  color: context.tokens.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.cartDeliveringTo(address.label),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        address.fullAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: context.tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Pressable(
                  child: TextButton(
                    onPressed: () => _changeAddress(auth),
                    child: Text(
                      l10n.checkoutChange,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.tokens.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          // Two states. Until a way to pay has actually been picked on the
          // picker screen, the hairline "Select Payment Method" button
          // stands here. The moment a row there is tapped (the screen
          // closes and lands right back), the bar flips to Blinkit's:
          // the chosen app on the left, total + Place Order on the right.
          if (!PaymentChoice.chosen)
            SizedBox(
              height: 48,
              width: double.infinity,
              child: Pressable(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // Hairline checkout: white fill, thin orange border and
                    // orange glyphs, matching the product card ADD buttons.
                    backgroundColor: Colors.white,
                    foregroundColor: context.tokens.primary,
                    side: BorderSide(color: context.tokens.primary, width: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _proceed(auth),
                  // One centred label, no arrow.
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 48,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // The chosen method; tapping it reopens the picker.
                  Expanded(
                    flex: 5,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _proceed(auth),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // The app's own icon, with no box around it.
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: _methodIcon(),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'PAY USING',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                  color: context.tokens.textPrimary,
                                ),
                              ),
                              const Icon(Iconsax.arrow_up_2_copy, size: 10),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            PaymentChoice.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF20252E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Total on its left inside, Place Order on its right —
                  // one solid button, exactly like the reference shot.
                  Expanded(
                    flex: 7,
                    child: SizedBox(
                      height: 52,
                      child: Pressable(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.tokens.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _placingOrder
                              ? null
                              : () => _placeOrder(auth),
                          child: _placingOrder
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          formatRupees(total),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          l10n.cartTotalLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Flexible(
                                      child: Text(
                                        l10n.checkoutPlaceOrder,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Iconsax.arrow_right_3_copy,
                                      size: 13,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback onBrowse;

  /// Whether the cart could not be read at all: an empty cart and a cart we
  /// could not fetch should never read the same way.
  final bool failed;
  final VoidCallback onRetry;

  const _EmptyCart({
    required this.onBrowse,
    this.failed = false,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (failed) {
      return RoleError(
        title: l10n.cartLoadFailed,
        onRetry: onRetry,
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.shopping_cart, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            l10n.cartEmptyTitle,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.cartEmptyBody,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Pressable(
              child: ElevatedButton(
            onPressed: onBrowse,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: Text(
              l10n.cartBrowse,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )),
        ],
      ),
    );
  }
}

/// A quiet strip above the list: a background write of the cart to the
/// server failed, so the copy the shop prices from is behind this phone's.
/// It says so plainly and offers to resend, instead of letting checkout
/// silently charge for an older cart.
class _SyncNotice extends StatelessWidget {
  final CartProvider cart;

  const _SyncNotice({required this.cart});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppConstants.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Iconsax.wifi_square,
            size: 20,
            color: AppConstants.primaryColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.cartSyncFailed,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppConstants.textPrimaryColor,
              ),
            ),
          ),
          Pressable(
              child: TextButton(
            onPressed: cart.retrySync,
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: Text(
              l10n.cartSyncRetry,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final CartProvider cart;

  /// When true the card drops its own white shell and hairline: the row
  /// joins the delivery card above it in one section.
  final bool embedded;

  const _CartItemCard({
    required this.item,
    required this.cart,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    // Struck-through price only when the plain product is on offer; a chosen
    // variant has its own price with no "was" price to show.
    final showWas =
        item.variantPrice == null && product.originalPrice > product.price;

    final Widget content = Row(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE4E4E4)),
            ),
            clipBehavior: Clip.antiAlias,
            child: _Thumbnail(product: product),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (product.unit.isNotEmpty && item.variantName == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      product.unit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: () {
                    context.read<WishlistProvider>().add(product);
                    cart.removeFromCart(product.id);
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                        content: Text(
                          AppLocalizations.of(context).cartMovedToWishlist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ));
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      AppLocalizations.of(context).cartMoveToWishlist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppConstants.textSecondaryColor,
                        decoration: TextDecoration.underline,
                        decorationStyle: TextDecorationStyle.dashed,
                      ),
                    ),
                  ),
                ),
                if (item.variantName != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEFEF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.variantName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppConstants.textSecondaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              formatRupees(item.unitPrice),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (showWas) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                formatRupees(product.originalPrice),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppConstants.textSecondaryColor,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    CartAction(
                      product: product,
                      alwaysShowStepper: true,
                      outline: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
    );

    if (!embedded) return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: content,
    );
    // Inside the merged section card: a hairline on top separates this row
    // from the delivery header (or a previous item) with no shell.
    return Column(
      children: [
        const Divider(height: 1, thickness: 1, color: Color(0xFFEBEBEB)),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: content,
        ),
      ],
    );
  }
}

/// "Delivery in 12 minutes · Shipment of 3 items", above the items.
class _DeliveryCard extends StatelessWidget {
  final int count;

  /// True drops the shell so the header can sit at the top of the merged
  /// section card that also carries the item rows.
  final bool embedded;

  const _DeliveryCard({required this.count, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final eta = context.watch<DeliveryEtaProvider>().label;
    final Widget content = Row(
        children: [
          // Bare icon — no tinted tile behind it.
          const Icon(Iconsax.timer_1,
              color: AppConstants.successColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eta == null
                      ? l10n.cartDeliverySoon
                      : l10n.cartDeliveryIn(eta),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l10n.cartShipment(count),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

    if (!embedded) return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: content,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: content,
    );
  }
}

/// Products from the same categories as the cart, not in it yet, in stock:
/// the one-tap "forgot the salt" row Blinkit puts under the cart.
class _AlsoLike extends StatelessWidget {
  final CartProvider cart;

  const _AlsoLike({required this.cart});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final products = context.watch<ProductProvider>().allProducts;
    final inCart = {for (final i in cart.items) i.product.id};
    final categories = {for (final i in cart.items) i.product.category};
    if (categories.isEmpty) return const SizedBox.shrink();
    final picks = products
        .where((p) =>
            categories.contains(p.category) &&
            !inCart.contains(p.id) &&
            p.isAvailable &&
            (p.imageUrl ?? '').isNotEmpty)
        .take(6)
        .toList();
    // Nothing to suggest: no card at all, not an empty white strip.
    if (picks.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: ProductShelf(
        title: l10n.cartYouMightLike,
        products: picks,
        onSeeAll: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryListingScreen(
              title: cart.items.first.product.category,
              initialCategory: cart.items.first.product.category,
            ),
          ),
        ),
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final CartProvider cart;

  /// What the applied coupon takes off; 0 without one.
  final double discount;

  /// The rider's tip in rupees.
  final int tip;

  const _BillCard({
    required this.cart,
    required this.discount,
    required this.tip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subtotal = cart.totalAmount;
    final delivery = OrderProvider.deliveryFeeFor(cart.items);
    // What the discounts add up to, against the printed price. Variants
    // carry their own price and no MRP of their own, so they sit this out.
    final saved = cart.items.fold<double>(0, (sum, i) {
      if (i.variantPrice != null) return sum;
      final off = i.product.originalPrice - i.product.price;
      return off > 0 ? sum + off * i.quantity : sum;
    });
    // Free delivery is per seller; the bar only makes sense for one.
    final oneSeller =
        cart.items.map((i) => i.product.sellerId).toSet().length == 1;
    const threshold = OrderProvider.freeDeliveryThreshold;

    Widget line(String label, String value, {bool bold = false}) => Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (oneSeller) ...[
            _FreeDeliveryBar(
              subtotal: subtotal,
              threshold: threshold.toDouble(),
              free: delivery == 0,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            l10n.cartBillDetails,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const _Dashed(),
          line(l10n.cartItemsCount(cart.itemCount), formatRupees(subtotal)),
          const SizedBox(height: 14),
          line(
            l10n.cartDeliveryFee,
            delivery == 0 ? l10n.cartFree : formatRupees(delivery),
          ),
          if (discount > 0) ...[
            const SizedBox(height: 14),
            line(l10n.checkoutCouponDiscount, '-${formatRupees(discount)}'),
          ],
          if (tip > 0) ...[
            const SizedBox(height: 14),
            line(l10n.checkoutTipLine, formatRupees(tip)),
          ],
          const _Dashed(),
          line(
            l10n.cartToPay,
            formatRupees(payableTotalFor(
              subtotal: subtotal,
              deliveryFee: delivery,
              discount: discount,
              walletUsed: 0,
              tip: tip.toDouble(),
            )),
            bold: true,
          ),
          if (saved >= 1) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppConstants.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.discount_shape,
                      size: 18, color: AppConstants.successColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.cartYouSave(formatRupees(saved)),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppConstants.successColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// How far the cart is from free delivery, as a bar that fills up.
class _FreeDeliveryBar extends StatelessWidget {
  final double subtotal;
  final double threshold;
  final bool free;

  const _FreeDeliveryBar({
    required this.subtotal,
    required this.threshold,
    required this.free,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progress = free ? 1.0 : (subtotal / threshold).clamp(0.0, 1.0);
    final color = free ? AppConstants.successColor : AppConstants.primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Iconsax.truck_fast, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                free
                    ? l10n.cartFreeDeliveryUnlocked
                    : l10n.cartFreeDeliveryShort(
                        formatRupees((threshold - subtotal).ceil())),
                style: TextStyle(fontWeight: FontWeight.w600, color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              minHeight: 6,
              backgroundColor: const Color(0xFFEFEFEF),
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// A row of short dashes across the card.
class _Dashed extends StatelessWidget {
  const _Dashed();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: LayoutBuilder(
        builder: (context, box) {
          final count = (box.maxWidth / 18).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              count,
              (_) => Container(
                width: 9,
                height: 1.4,
                color: const Color(0xFFD9D2C7),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final Product product;

  const _Thumbnail({required this.product});

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(gradient: _gradientFor(product.imageGradient)),
      child: Center(
        child: Text(
          product.name.isNotEmpty ? product.name[0] : '?',
          style: TextStyle(
            fontSize: 30,
            color: Colors.white.withOpacity(0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = product.imageUrl;
    if (url == null || url.isEmpty) return _placeholder();
    return ColoredBox(
      color: Colors.white,
      child: AppNetworkImage(
        url,
        width: 84,
        height: 84,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _placeholder();
        },
        errorBuilder: (context, error, stack) => _placeholder(),
      ),
    );
  }

  static Gradient _gradientFor(String gradient) {
    switch (gradient) {
      case 'red':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEF5350), Color(0xFFC62828)],
        );
      case 'orange':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFA726), Color(0xFFEF6C00)],
        );
      case 'yellow':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFEE58), Color(0xFFF9A825)],
        );
      case 'brown':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA1887F), Color(0xFF6D4C41)],
        );
      case 'white':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
        );
    }
  }
}
