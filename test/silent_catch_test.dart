import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Failures used to die in empty `catch` blocks: a payment method looked
/// removed when it was not, a delivery run looked claimed when it was not,
/// the online switch lied about the server, and a seller quietly lived
/// inside the customer app because the profile read never landed. These
/// pins keep every one of those failures loud.
void main() {
  String read(String path) => File(path).readAsStringSync();

  test('there is one shared one-line notice for action failures', () {
    final common = read('lib/widgets/role_common.dart');
    expect(common, contains('void roleSay(BuildContext context'));
    expect(common, contains('hideCurrentSnackBar()'));
  });

  test('payment methods say when a write fails', () {
    // The words moved into the string files with the screen's l10n
    // migration; the screen must still ask for them and say them aloud.
    final src = read('lib/screens/payment_methods_screen.dart');
    expect(src, contains('paymentMethodsSetDefaultFailed'));
    expect(src, contains('paymentMethodsDeleteFailed'));
    expect(src, contains('roleSay('));
    final arb = read('lib/l10n/app_en.arb');
    expect(arb, contains("Couldn't set this as your default"));
    expect(arb, contains("Couldn't remove this payment method"));
  });

  test('claiming a run can lose the race, loudly', () {
    final src = read('lib/screens/delivery/delivery_orders_screen.dart');
    // `.select('id')` returns only the rows the update touched, so an
    // already-claimed order is detectable instead of invisible.
    expect(src, contains(".select('id')"));
    // The words moved into the string files with the screen's l10n
    // migration; the screen must still ask for them and say them aloud.
    expect(src, contains('deliveryOrdersClaimLost'));
    expect(src, contains('deliveryOrdersAcceptFailed'));
    final arb = read('lib/l10n/app_en.arb');
    expect(arb, contains('taken by another partner'));
    expect(arb, contains("Couldn't accept this order"));
  });

  test('marking delivered splits the order write from the earnings write', () {
    final src = read('lib/screens/delivery/delivery_orders_screen.dart');
    expect(src, contains('deliveryOrdersMarkDeliveredFailed'));
    expect(src, contains('deliveryOrdersFeeNotRecorded'));
    final arb = read('lib/l10n/app_en.arb');
    expect(arb, contains("Couldn't mark this order delivered"));
    expect(arb, contains('delivery fee could not be recorded'));
    expect(arb, contains('tell the admin'));
  });

  test('the online switch reverts and explains when the server refuses', () {
    final auth = read('lib/providers/auth_provider.dart');
    expect(auth, contains('Future<bool> setOnlineStatus'));
    expect(auth, contains('_isOnline = !online;'));
    final dash = read('lib/screens/delivery/delivery_dashboard_screen.dart');
    expect(dash, contains('roleSay('));
    expect(dash, contains('deliveryDashOnlineToggleFailed'));
    expect(
      read('lib/l10n/app_en.arb'),
      contains("Couldn't update your online status"),
    );
  });

  test('a failed profile load is stale, retried, and shown', () {
    final auth = read('lib/providers/auth_provider.dart');
    expect(auth, contains('bool _profileStale = false;'));
    expect(auth, contains('bool get profileStale => _profileStale;'));
    expect(auth, contains('refreshProfile'));
    expect(auth, contains('Duration(seconds: 2)'));
    expect(auth, contains('Duration(seconds: 6)'));
    expect(auth, contains('Duration(seconds: 15)'));

    // The Profile screen carries the note, so the user can re-read by hand.
    final profile = read('lib/screens/profile_screen.dart');
    expect(profile, contains('authProvider.profileStale'));
    expect(profile, contains('RoleInlineError('));
    // The note's words live in the string files now; the screen must ask
    // for them and the arb must hold them.
    expect(profile, contains('l10n.profileStale'));
    expect(
      read('lib/l10n/app_en.arb'),
      contains("Couldn't load your account details."),
    );

    // Signing out clears the flag so the next login starts clean.
    expect(auth, contains('_profileStale = false;'));
  });

  test('a cart that could not sync says so and can resend', () {
    final provider = read('lib/providers/cart_provider.dart');
    expect(provider, contains('bool _syncFailed = false;'));
    expect(provider, contains('bool get syncFailed => _syncFailed;'));
    expect(provider, contains('retrySync'));

    final screen = read('lib/screens/cart_screen.dart');
    expect(screen, contains('cartProvider.syncFailed'));
    expect(screen, contains('l10n.cartSyncFailed'));
    expect(screen, contains('l10n.cartSyncRetry'));

    final arb = read('lib/l10n/app_en.arb');
    expect(arb, contains('cartSyncFailed'));
    expect(arb, contains('cartSyncRetry'));
  });

  test('product requests say when the list could not load', () {
    final src = read('lib/screens/help_screens.dart');
    expect(src, contains('bool _loadFailed = false;'));
    expect(src, contains('RoleInlineError('));
    // The words moved into the string files with the screen's l10n
    // migration; the screen must still ask for them.
    expect(src, contains('l10n.helpRequestsLoadFailed'));
    expect(
      read('lib/l10n/app_en.arb'),
      contains("Couldn't load your requests."),
    );
  });

  test('no empty catch blocks remain anywhere in the app', () {
    final emptyCatch = RegExp(r'catch\s*\([^)]*\)\s*\{\s*\}');
    final offenders = <String>[];
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final source = file.readAsStringSync();
      for (final match in emptyCatch.allMatches(source)) {
        final line = '\n'.allMatches(source.substring(0, match.start)).length;
        offenders.add('${file.path}:${line + 1}');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'every catch must handle, explain, or say why it may stay '
          'quiet — found: ${offenders.join(', ')}',
    );
  });

  test('the catches that stay quiet say why they may', () {
    expect(read('lib/providers/auth_provider.dart'), contains('Best-effort'));
    expect(
      read('lib/screens/onboarding_screen.dart'),
      contains('Best-effort'),
    );
    expect(read('lib/widgets/night_sky.dart'), contains('Best-effort'));
    expect(read('lib/screens/home_screen.dart'), contains('Best-effort'));
    expect(
      read('lib/screens/product_detail_screen.dart'),
      contains('Best-effort'),
    );
  });
}
