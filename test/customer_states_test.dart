import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The customer side of the app must treat a failed load the way the seller's,
/// delivery partner's and admin's screens now do: say that it failed, and
/// offer to try again. A cart that comes back empty because the request died
/// is not the same as an empty cart, and telling someone "your cart is empty"
/// when the truth is "we could not ask" is how an order gets abandoned.
void main() {
  String read(String path) => File(path).readAsStringSync();

  const providers = [
    'lib/providers/cart_provider.dart',
    'lib/providers/wishlist_provider.dart',
    'lib/providers/order_provider.dart',
    'lib/providers/notification_provider.dart',
    'lib/providers/wallet_provider.dart',
  ];

  test('providers keep the failure instead of swallowing it', () {
    for (final path in providers) {
      final src = read(path);
      expect(src, contains('bool get loadFailed'), reason: path);
      expect(src, contains('_loadFailed = true;'), reason: path);
      expect(src, contains('_loadFailed = false;'), reason: path);
    }
  });

  /// Screens whose words have moved into `lib/l10n/app_en.arb`: file -> the
  /// key it asks for and the English sentence that key has to hold.
  const migrated = {
    'cart_screen.dart': ('cartLoadFailed', "Couldn't load your cart"),
    'wishlist_screen.dart': (
      'wishlistLoadFailed',
      "Couldn't load your wishlist",
    ),
    'orders_screen.dart': ('ordersLoadFailed', "Couldn't load your orders"),
    'wallet_screen.dart': ('walletLoadFailed', "Couldn't load your wallet"),
    'payment_methods_screen.dart': (
      'paymentMethodsLoadFailed',
      "Couldn't load your payment methods",
    ),
    'notifications_screen.dart': (
      'notificationsLoadFailed',
      "Couldn't load your notifications",
    ),
    'brands_screen.dart': ('brandsLoadFailed', "Couldn't load the brands"),
    'order_support_screen.dart': (
      'orderSupportLoadFailed',
      "Couldn't load this order's tickets",
    ),
  };

  test('every customer list screen says a load failed, with a retry', () {
    final arb = read('lib/l10n/app_en.arb');
    for (final entry in migrated.entries) {
      final src = read('lib/screens/${entry.key}');
      final (key, sentence) = entry.value;
      expect(src, contains('RoleError('), reason: entry.key);
      expect(src, contains('l10n.$key'), reason: entry.key);
      expect(src, contains('onRetry:'), reason: entry.key);
      expect(arb, contains(sentence), reason: '${entry.key} asks for $key');
    }
  });

  test('the three screens that hid a failure now keep it too', () {
    for (final name in [
      'payment_methods_screen.dart',
      'brands_screen.dart',
      'order_support_screen.dart',
    ]) {
      final src = read('lib/screens/$name');
      expect(src, contains('bool _loadFailed = false;'), reason: name);
    }
  });

  test('what is genuinely empty still reads as empty, not as broken', () {
    // The empty states of the migrated screens have moved into the string
    // files: the words still have to be there, and the screen still has to
    // ask for them.
    final arb = read('lib/l10n/app_en.arb');
    expect(arb, contains('Your cart is empty'));
    expect(
      read('lib/screens/cart_screen.dart'),
      contains('l10n.cartEmptyTitle'),
    );
    expect(arb, contains('Your wishlist is empty'));
    expect(
      read('lib/screens/wishlist_screen.dart'),
      contains('l10n.wishlistEmptyTitle'),
    );
    expect(arb, contains('No orders yet!'));
    expect(
      read('lib/screens/orders_screen.dart'),
      contains('l10n.ordersEmptyTitle'),
    );
    expect(arb, contains('No transactions yet'));
    expect(
      read('lib/screens/wallet_screen.dart'),
      contains('l10n.walletEmpty'),
    );
  });

  test('an order still on its way can be tracked', () {
    final detail = read('lib/screens/order_detail_screen.dart');
    expect(detail, contains("import 'order_tracking_screen.dart';"));
    expect(detail, contains('OrderTrackingScreen(orderId: order.id)'));
    expect(detail, contains('_isTrackable'));
  });

  test('a document list and a product section keep their failures', () {
    final kyc = read('lib/screens/kyc_documents_screen.dart');
    expect(kyc, contains('bool _loadFailed = false;'));
    // The words moved into the string files with the screen's l10n
    // migration, so the pin is the key here and the sentence in the arb.
    expect(kyc, contains('l10n.kycLoadFailed'));
    expect(kyc, contains('onRetry: _load,'));

    final detail = read('lib/screens/product_detail_screen.dart');
    // Options and reviews are sections of a page that otherwise loaded, so
    // they say so inline instead of replacing the page. Their words moved
    // into the string files with the screen's l10n migration.
    expect(detail, contains('RoleInlineError('));
    expect(detail, contains('l10n.productDetailOptionsFailed'));
    expect(detail, contains('l10n.productDetailReviewsFailed'));
    final arb = read('lib/l10n/app_en.arb');
    expect(arb, contains("Couldn't load the options for this product."));
    expect(arb, contains("Couldn't load the reviews."));
    expect(arb, contains("Couldn't load your documents"));
  });

  test('the screens that had no way in can be opened now', () {
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    // A screen named by only its own file is a feature with no door.
    for (final name in ['OrderTrackingScreen', 'AdminCategoriesScreen']) {
      final files = sources
          .where((f) => f.readAsStringSync().contains('$name('))
          .map((f) => f.path)
          .toList();
      expect(files.length, greaterThan(1), reason: '$name has a way in');
    }
  });
}
