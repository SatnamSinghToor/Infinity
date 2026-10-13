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
import '../screens/checkout_screen.dart';
import '../utils/constants.dart';
import '../utils/tokens.dart';
import '../services/analytics.dart';
import '../services/supabase_service.dart';
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
  /// either is missing, then opens the payment page.
  Future<void> _proceed(AuthProvider auth) async {
    if (!auth.isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }
    var address = _deliveryAddress(auth);
    if (address == null) {
      await _changeAddress(auth);
      if (!mounted) return;
      address = _deliveryAddress(auth);
      if (address == null) return;
    }
    if (address.fullName.isEmpty || address.phone.isEmpty) {
      final who = await showReceiverSheet(
        context,
        name: address.fullName,
        phone: address.phone,
      );
      if (who == null || !mounted) return;
      setState(() {
        _receiverName = who.$1;
        _receiverPhone = who.$2;
      });
      address = _deliveryAddress(auth);
      if (address == null) return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          address: address!,
          tip: _tip,
          deliveryNote: _deliveryNote,
          coupon: _appliedCoupon,
        ),
      ),
    );
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

  Future<void> _confirmClear(BuildContext context, CartProvider cart) async {
    final l10n = AppLocalizations.of(context);
    final clear = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cartClearTitle),
        content: Text(l10n.cartClearBody),
        actions: [
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.cartKeep,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )),
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.cartClearAction,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )),
        ],
      ),
    );
    if (clear == true) cart.clearCart();
  }

  Widget _header(AppLocalizations l10n, bool empty) {
    Widget circle(IconData icon, VoidCallback onTap) => Pressable(
            child: Material(
          color: const Color(0xFFEFEFEF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
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
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
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
                              // Room for the checkout bar pinned under the list.
                              170 + MediaQuery.of(context).padding.bottom,
                            ),
                            children: [
                              if (cartProvider.syncFailed)
                                _SyncNotice(cart: cartProvider),
                              if (!_searching)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Pressable(
                                      child: TextButton.icon(
                                    onPressed: () =>
                                        _confirmClear(context, cartProvider),
                                    icon: const Icon(Iconsax.trash, size: 18),
                                    label: Text(
                                      l10n.cartClear,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          AppConstants.primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  )),
                                ),
                              if (!_searching)
                                _DeliveryCard(count: cartProvider.itemCount),
                              for (final item in shown)
                                _CartItemCard(item: item, cart: cartProvider),
                              if (!_searching) _AlsoLike(cart: cartProvider),
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
                              // Just above the app's bottom bar (the shell
                              // reports its height as padding), or the phone's
                              // own edge when the cart was opened on its own.
                              bottom: MediaQuery.of(context).padding.bottom,
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
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
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
                        borderRadius: BorderRadius.circular(14),
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
                  borderRadius: BorderRadius.circular(14),
                ),
                selectedColor: context.tokens.primary.withValues(alpha: 0.15),
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                  selectedColor: context.tokens.primary.withValues(alpha: 0.15),
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

  /// Blinkit's pinned bottom: where it is going, with Change, and the one
  /// button — total on its left, Proceed To Pay on its right.
  Widget _checkoutBar(
    AppLocalizations l10n,
    CartProvider cart,
    AuthProvider auth,
  ) {
    final address = auth.isLoggedIn ? _deliveryAddress(auth) : null;
    final total = payableTotalFor(
      subtotal: cart.totalAmount,
      deliveryFee: OrderProvider.deliveryFeeFor(cart.items),
      discount: couponDiscountFor(_appliedCoupon, cart.totalAmount),
      walletUsed: 0,
      tip: _tip.toDouble(),
    );
    final label = !auth.isLoggedIn
        ? l10n.cartLoginToCheckout
        : address == null
            ? l10n.cartSelectAddress
            : l10n.cartProceedToPay;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: context.tokens.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.tokens.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    address.label == 'Work'
                        ? Iconsax.briefcase
                        : Iconsax.home_2,
                    size: 20,
                    color: context.tokens.primary,
                  ),
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
                          fontWeight: FontWeight.w800,
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 16, color: context.tokens.border),
          ],
          SizedBox(
            height: 56,
            width: double.infinity,
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
                onPressed: () => _proceed(auth),
                child: Row(
                  children: [
                    if (auth.isLoggedIn && address != null)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatRupees(total),
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
                      flex: 6,
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Iconsax.arrow_right_3_copy, size: 18),
                  ],
                ),
              ),
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
                borderRadius: BorderRadius.circular(12),
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
        color: AppConstants.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.3)),
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

  const _CartItemCard({required this.item, required this.cart});

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    // Struck-through price only when the plain product is on offer; a chosen
    // variant has its own price with no "was" price to show.
    final showWas =
        item.variantPrice == null && product.originalPrice > product.price;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
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
                    fontWeight: FontWeight.w700,
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
                      borderRadius: BorderRadius.circular(20),
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
                                fontWeight: FontWeight.w800,
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
                    CartAction(product: product, alwaysShowStepper: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Delivery in 12 minutes · Shipment of 3 items", above the items.
class _DeliveryCard extends StatelessWidget {
  final int count;

  const _DeliveryCard({required this.count});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final eta = context.watch<DeliveryEtaProvider>().label;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppConstants.successColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Iconsax.timer_1,
                color: AppConstants.successColor, size: 24),
          ),
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
                    fontWeight: FontWeight.w800,
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
      ),
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
        borderRadius: BorderRadius.circular(22),
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
                  fontSize: 17,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 17,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
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
                color: AppConstants.successColor.withValues(alpha: 0.1),
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
                        fontWeight: FontWeight.w700,
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
                style: TextStyle(fontWeight: FontWeight.w700, color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
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
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.bold,
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
