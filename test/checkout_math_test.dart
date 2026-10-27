import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:duggu/utils/checkout_math.dart';

/// The checkout screen shows a total before the order exists, and the server
/// prices the order itself. That gap is where a customer can be promised one
/// amount and charged another: `place_order` leaves the coupon out when it
/// cannot back it (this account has already used it, say), and the bill goes
/// up. The arithmetic behind the promise lives in one tested place, and the
/// checkout now compares its promise with the server's answer and says so on
/// the confirmation screen instead of staying quiet.
void main() {
  String read(String path) => File(path).readAsStringSync();

  group('coupon discount', () {
    test('is the coupon percent of the subtotal', () {
      const coupon = {'discount_percent': 10, 'max_discount': 100};
      expect(couponDiscountFor(coupon, 500), 50);
    });

    test('stops at the coupon maximum', () {
      const coupon = {'discount_percent': 50, 'max_discount': 100};
      expect(couponDiscountFor(coupon, 1000), 100);
    });

    test('a missing coupon, or missing fields, is worth nothing', () {
      expect(couponDiscountFor(null, 500), 0);
      expect(couponDiscountFor(const {}, 500), 0);
      expect(
        couponDiscountFor(const {'discount_percent': 10}, 500),
        50,
        reason: 'no maximum means no cap',
      );
    });

    test('never takes off more than the bill', () {
      const coupon = {'discount_percent': 10, 'max_discount': 100};
      expect(couponDiscountFor(coupon, 0), 0);
      expect(couponDiscountFor(coupon, 50), 5);
    });
  });

  group('wallet money', () {
    test('is capped by the bill and by the balance', () {
      expect(walletUseFor(payable: 500, balance: 2000), 500);
      expect(walletUseFor(payable: 500, balance: 120.5), 120);
    });

    test('is whole rupees, and never negative', () {
      expect(walletUseFor(payable: 499.9, balance: 5000), 499);
      expect(walletUseFor(payable: 500, balance: 0), 0);
      expect(walletUseFor(payable: 0, balance: 500), 0);
      expect(walletUseFor(payable: 500, balance: -10), 0);
    });
  });

  test('the promised total is items + delivery - coupon - wallet', () {
    expect(
      payableTotalFor(
        subtotal: 500,
        deliveryFee: 29,
        discount: 50,
        walletUsed: 100,
      ),
      379,
    );
  });

  group('the rider tip', () {
    test('sits on top of the bill', () {
      expect(
        payableTotalFor(
          subtotal: 18,
          deliveryFee: 29,
          discount: 0,
          walletUsed: 0,
          tip: 20,
        ),
        67,
      );
    });

    test('is never paid for out of the wallet', () {
      // The wallet is worked out from the bill without the tip, so a big
      // balance still leaves the whole tip to pay.
      final wallet = walletUseFor(payable: 47, balance: 1000);
      expect(wallet, 47);
      expect(
        payableTotalFor(
          subtotal: 18,
          deliveryFee: 29,
          discount: 0,
          walletUsed: wallet.toDouble(),
          tip: 20,
        ),
        20,
      );
    });

    test('offers only amounts the server accepts', () {
      for (final t in tipOptions) {
        expect(t, inInclusiveRange(1, 500));
      }
    });

    test('reaches the server and the payment the same way', () {
      expect(
          read('lib/providers/order_provider.dart'), contains("'p_tip': tip"));
      expect(read('lib/services/payment_service.dart'), contains("'tip': tip"));
      final checkout = read('lib/screens/checkout_screen.dart');
      expect(checkout, contains('tip: _tip,'));
      expect(checkout, contains('tip: _tip.toDouble(),'));
      final fn = read('supabase/functions/create-razorpay-order/index.ts');
      expect(fn, contains('const MAX_TIP = 500'));
      expect(fn, contains('Math.max(0, total - walletUsed) + tip'));
    });
  });

  group('promise against the server', () {
    test('rounding is not a mismatch', () {
      expect(chargedDiffersFromPromise(379, 379), isFalse);
      expect(chargedDiffersFromPromise(379, 379.4), isFalse);
      expect(chargedDiffersFromPromise(379, 529), isTrue);
    });

    test('a coupon the server left out is caught', () {
      const subtotal = 500.0;
      const deliveryFee = 29.0;
      final discount = couponDiscountFor(
        const {'discount_percent': 10, 'max_discount': 100},
        subtotal,
      );
      final promised = payableTotalFor(
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        discount: discount,
        walletUsed: 0,
      );
      // What place_order charges when it cannot use the coupon.
      const charged = subtotal + deliveryFee;

      expect(promised, 479);
      expect(chargedDiffersFromPromise(promised, charged), isTrue);
    });
  });

  test('the checkout promises with the shared arithmetic', () {
    final checkout = read('lib/screens/checkout_screen.dart');

    expect(checkout, contains('couponDiscountFor(_appliedCoupon, subtotal)'));
    expect(checkout, contains('return walletUseFor('));
    expect(checkout, contains('final promisedTotal = payableTotalFor('));
    // No second copy of the coupon sum: that is how the two drift apart.
    expect(checkout, isNot(contains('final maxDiscount =')));
  });

  test('the customer hears when the server disagreed', () {
    final checkout = read('lib/screens/checkout_screen.dart');

    expect(checkout, contains('chargedDiffersFromPromise('));
    // Only compared when no wallet money is involved.
    expect(checkout, contains('if (walletUsed == 0 &&'));
    expect(checkout, contains('totalNotice: totalNotice,'));
    // Both notices moved into the string files with the screen's l10n
    // migration: the screen asks for them, the arb holds them.
    expect(checkout, contains('l10n.checkoutFinalTotalCoupon'));
    expect(checkout, contains('l10n.checkoutFinalTotalChanged'));
    final arb = read('lib/l10n/app_en.arb');
    expect(arb, contains('could not be applied to the order'));
    expect(arb, contains('as shown before payment'));

    // And the confirmation screen has somewhere to show it.
    expect(checkout, contains('final String? totalNotice;'));
    expect(checkout, contains('final totalNotice = this.totalNotice;'));
  });
}
