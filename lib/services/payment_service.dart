import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase/supabase.dart' show FunctionException;

import 'supabase_service.dart';

class RazorpayPaymentResult {
  final bool success;
  final String? paymentId;
  final String? errorMessage;

  const RazorpayPaymentResult.success(this.paymentId)
      : success = true,
        errorMessage = null;

  const RazorpayPaymentResult.failure(this.errorMessage)
      : success = false,
        paymentId = null;
}

/// Wraps the Razorpay Checkout SDK's event-based API in a `Future`, backed
/// by the `create-razorpay-order` / `verify-razorpay-payment` edge functions.
/// The server (not this client) decides how much is actually payable, so
/// nothing here passes an amount to Razorpay directly.
class PaymentService {
  /// Opens Razorpay Checkout for the signed-in user's current cart and
  /// resolves once the payment is either verified or abandoned/failed.
  static Future<RazorpayPaymentResult> payForCart({
    String? contactPhone,
    String? contactEmail,
    String couponCode = '',
    int walletAmount = 0,
    int tip = 0,
  }) {
    final completer = Completer<RazorpayPaymentResult>();
    final razorpay = Razorpay();
    bool _cleanedUp = false;

    void cleanup() {
      if (!_cleanedUp) {
        _cleanedUp = true;
        razorpay.clear();
      }
    }

    // Safety timeout: if no event fires within 5 minutes, clean up.
    // (User may have closed the checkout sheet without completing/abandoning.)
    final timeout = Timer(const Duration(minutes: 5), () {
      if (!completer.isCompleted) {
        completer.complete(
          const RazorpayPaymentResult.failure('Payment timed out.'),
        );
        cleanup();
      }
    });

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (
      PaymentSuccessResponse response,
    ) async {
      timeout.cancel();
      try {
        final verifyResponse = await SupabaseService.client.functions.invoke(
          'verify-razorpay-payment',
          body: {
            'order_id': response.orderId,
            'payment_id': response.paymentId,
            'signature': response.signature,
          },
        );
        final valid = verifyResponse.data is Map
            ? verifyResponse.data['valid'] == true
            : false;
        if (valid) {
          completer.complete(
            RazorpayPaymentResult.success(response.paymentId),
          );
        } else {
          completer.complete(
            const RazorpayPaymentResult.failure(
              'Payment could not be verified. Please try again.',
            ),
          );
        }
      } catch (_) {
        completer.complete(
          const RazorpayPaymentResult.failure(
            'Payment could not be verified. Please try again.',
          ),
        );
      } finally {
        cleanup();
      }
    });

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (
      PaymentFailureResponse response,
    ) {
      timeout.cancel();
      completer.complete(
        RazorpayPaymentResult.failure(
          response.message ?? 'Payment was not completed.',
        ),
      );
      cleanup();
    });

    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (
      ExternalWalletResponse response,
    ) {
      timeout.cancel();
      completer.complete(
        const RazorpayPaymentResult.failure(
          'External wallet payments are not supported yet.',
        ),
      );
      cleanup();
    });

    () async {
      try {
        final orderResponse = await SupabaseService.client.functions.invoke(
          'create-razorpay-order',
          body: {
            'receipt': 'duggu_${DateTime.now().millisecondsSinceEpoch}',
            'coupon_code': couponCode,
            'wallet_amount': walletAmount,
            'tip': tip,
          },
        );
        final data = orderResponse.data as Map;
        final options = {
          'key': data['key_id'],
          'amount': data['amount'],
          'order_id': data['order_id'],
          'currency': 'INR',
          'name': 'Infinity',
          'description': 'Order payment',
          if (contactPhone != null || contactEmail != null)
            'prefill': {
              if (contactPhone != null) 'contact': contactPhone,
              if (contactEmail != null) 'email': contactEmail,
            },
        };
        razorpay.open(options);
      } on FunctionException catch (e) {
        timeout.cancel();
        final message = e.details is Map ? e.details['error'] as String? : null;
        completer.complete(
          RazorpayPaymentResult.failure(
            message ?? 'Could not start the payment.',
          ),
        );
        cleanup();
      } catch (_) {
        timeout.cancel();
        completer.complete(
          const RazorpayPaymentResult.failure('Could not start the payment.'),
        );
        cleanup();
      }
    }();

    return completer.future;
  }
}
