/// The arithmetic the checkout screen shows a customer before the order
/// exists.
///
/// Nothing here is the price. The server prices the order itself: `place_order`
/// reads the cart from `cart_items`, works out the delivery fee per seller,
/// and applies the coupon only if the `coupons` table still backs it. What
/// this file works out is the *promise* the screen makes while the customer
/// decides — and having it in one tested place is what lets the screen notice
/// when the server's answer came out different, instead of letting the
/// customer find out on delivery.
library;

/// What [coupon] takes off [subtotal]: `discount_percent` of it, never more
/// than `max_discount`. A null coupon, or one missing those fields, gives
/// zero rather than an error.
double couponDiscountFor(Map<String, dynamic>? coupon, double subtotal) {
  if (coupon == null) return 0;
  final percent = (coupon['discount_percent'] as num?)?.toDouble() ?? 0;
  final maxDiscount =
      (coupon['max_discount'] as num?)?.toDouble() ?? double.infinity;
  return (subtotal * percent / 100).clamp(0, maxDiscount).toDouble();
}

/// How much wallet money can go towards a bill of [payable]: never more than
/// the bill, never more than [balance], and whole rupees.
int walletUseFor({required double payable, required double balance}) {
  if (payable <= 0 || balance <= 0) return 0;
  final capped = payable < balance ? payable : balance;
  return capped.floor();
}

/// The amount the customer is told to expect, in the order the summary shows
/// it: items, plus delivery, less coupon, less wallet, plus the rider's tip.
/// The wallet never pays the tip — work its use out from the bill without
/// it, as place_order does.
double payableTotalFor({
  required double subtotal,
  required double deliveryFee,
  required double discount,
  required double walletUsed,
  double tip = 0,
}) {
  return subtotal + deliveryFee - discount - walletUsed + tip;
}

/// The tips the checkout offers for the delivery partner, in rupees.
const tipOptions = [10, 20, 30, 50];

/// Whether the server's total is different from the one the app promised.
///
/// Half a rupee is rounding, not a mismatch. A coupon that quietly did not
/// apply — already used by this account, switched off while the customer was
/// paying — is a mismatch, and the customer gets told.
bool chargedDiffersFromPromise(double promised, double charged) {
  return (charged - promised).abs() > 0.5;
}
