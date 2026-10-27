import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:duggu/utils/constants.dart';
import 'package:duggu/widgets/role_common.dart';

/// The seller's, the delivery partner's and the admin's screens are three
/// areas of one app, and these tests hold them to that: one look for the
/// numbers, one way of saying "loading", "nothing here" and "that failed" —
/// and no screen that quietly swallows a failed load, which is how a seller
/// ends up staring at an empty shop that is not actually empty.
void main() {
  // ---------------------------------------------------------------------------
  // The shared pieces themselves.

  Widget host(Widget child) => MaterialApp(
        theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
        )),
        home: Scaffold(body: child),
      );

  testWidgets('the body shows loading, then the failure, then the screen',
      (tester) async {
    var retried = 0;
    // Loading.
    await tester.pumpWidget(host(RoleBody(
      loading: true,
      failed: false,
      onRetry: () => retried++,
      child: const Text('the list'),
    )));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('the list'), findsNothing);

    // Failed: the screen says so, and offers to try again.
    await tester.pumpWidget(host(RoleBody(
      loading: false,
      failed: true,
      onRetry: () => retried++,
      child: const Text('the list'),
    )));
    expect(find.text('the list'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(retried, 1);

    // Ready: the screen itself.
    await tester.pumpWidget(host(RoleBody(
      loading: false,
      failed: false,
      onRetry: () => retried++,
      child: const Text('the list'),
    )));
    expect(find.text('the list'), findsOneWidget);
  });

  testWidgets('the stat card holds a long label at the largest text size',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.3)),
        child: child!,
      ),
      home: const Scaffold(
        body: Center(
          child: SizedBox(
            width: 160,
            height: 110,
            child: RoleStatCard(
              label: 'Pending boost requests',
              value: '12',
              icon: Iconsax.shopping_bag,
              dense: true,
            ),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('the empty and the failure states each say what they mean',
      (tester) async {
    await tester.pumpWidget(host(const RoleEmpty(
      icon: Iconsax.receipt,
      title: 'No orders yet',
      message: 'Orders land here the moment a customer checks out.',
    )));
    expect(find.text('No orders yet'), findsOneWidget);
    expect(find.textContaining('the moment a customer checks out'),
        findsOneWidget);

    await tester.pumpWidget(host(RoleError(
      title: "Couldn't load your orders",
      onRetry: () {},
    )));
    expect(find.text("Couldn't load your orders"), findsOneWidget);
    expect(find.textContaining('nothing was lost'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // The screens themselves, read as text. This is the part that would
  // otherwise rot: a new role screen (or a new load added to an old one)
  // that swallows its failure silently.

  final roleFiles = [
    for (final dir in ['seller', 'delivery', 'admin'])
      ...Directory('lib/screens/$dir')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .map((f) => f.path.replaceAll(r'\', '/')),
  ];

  /// The body of the function that starts at [start] in [lines], by braces.
  String functionBody(List<String> lines, int start) {
    var depth = 0;
    var seen = false;
    final out = <String>[];
    for (var i = start; i < lines.length; i++) {
      for (final ch in lines[i].split('')) {
        if ('([{'.contains(ch)) {
          depth++;
          seen = true;
        } else if (')]}'.contains(ch)) {
          depth--;
        }
      }
      out.add(lines[i]);
      if (seen && depth == 0) break;
    }
    return out.join('\n');
  }

  test('no role screen swallows a load failure', () {
    final problems = <String>[];
    // A load may report a failure with a flag of its own (one per screen),
    // or by telling the user in as many words. What it may not do is nothing.
    final reports = RegExp(
        'Failed\\s*=\\s*true|_toast\\(|_tell\\(|ScaffoldMessenger|debugPrint');
    final swallows = RegExp(r'catch \(_\) \{\s*\}');

    for (final path in roleFiles) {
      final lines = File(path).readAsStringSync().split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (!RegExp(r'Future<void> _load\w*\(').hasMatch(lines[i])) continue;
        final name =
            RegExp(r'Future<void> (\w+)\(').firstMatch(lines[i])!.group(1);
        final body = functionBody(lines, i);
        if (swallows.hasMatch(body)) {
          problems.add('$path:$name swallows its failure');
        } else if (!reports.hasMatch(body)) {
          problems.add('$path:$name fails without saying anything');
        }
      }
    }
    expect(problems, isEmpty,
        reason: 'A request that failed is not an empty list. Say so — a flag '
            'the screen can show, or a line the user can read.');
  });

  test('the screens that fetch a list have a way to show it failed', () {
    final problems = <String>[];
    for (final path in roleFiles) {
      final source = File(path).readAsStringSync();
      if (!RegExp(r'Future<void> _load\w*\(').hasMatch(source)) continue;
      if (!source.contains('RoleBody(') &&
          !source.contains('RoleError(') &&
          !source.contains('_optionsFailed') &&
          !source.contains('_reviewsFailed')) {
        problems.add('$path loads data but has no failure state');
      }
    }
    expect(problems, isEmpty);
  });

  test('the role screens draw their numbers with the shared stat card', () {
    final problems = <String>[];
    for (final path in roleFiles) {
      final source = File(path).readAsStringSync();
      if (RegExp(r'class _StatCard').hasMatch(source)) {
        problems.add('$path: a private stat card; use RoleStatCard');
      }
    }
    expect(problems, isEmpty);
  });

  test('the shared role widgets are used, not re-invented', () {
    final source = File('lib/widgets/role_common.dart').readAsStringSync();
    for (final name in [
      'RoleStatCard',
      'RoleLoading',
      'RoleBody',
      'RoleError',
      'RoleEmpty',
      'RoleEmptyNote',
    ]) {
      expect(source.contains('class $name'), isTrue,
          reason: '$name is part of the role kit');
    }
    // And the colour rule: the roles use the app's palette, not their own.
    expect(source.contains('AppConstants.primaryColor'), isTrue);
  });

  // The delivery partner's four screens moved their words into the string
  // files: file -> the key it asks for and the English sentence that key
  // has to hold. Dual-pinned, like the customer screens, so a sentence
  // cannot quietly disappear from either side.
  const deliveryScreens = {
    'delivery_dashboard_screen.dart': (
      'deliveryDashTodayPerformance',
      "Today's Performance",
    ),
    'delivery_orders_screen.dart': ('deliveryOrdersTitle', 'My Delivery'),
    'delivery_earnings_screen.dart': ('deliveryEarningsTitle', 'My Earnings'),
    'delivery_more_screen.dart': ('deliveryMoreTitle', 'Profile'),
  };

  // The admin's ten screens did the same.
  const adminScreens = {
    'admin_users_screen.dart': ('adminUsersTitle', 'Manage Users'),
    'admin_moderation_screen.dart': ('adminModerationTitle', 'Moderation'),
    'admin_order_issues_screen.dart': ('adminIssuesTitle', 'Order Issues'),
    'admin_return_requests_screen.dart': (
      'adminReturnsTitle',
      'Return Requests',
    ),
    'admin_sponsored_slots_screen.dart': ('adminSlotsTitle', 'Sponsored Slots'),
    'admin_dashboard_screen.dart': ('adminDashTitle', 'Admin Dashboard'),
    'admin_payouts_screen.dart': ('adminPayoutsTitle', 'Payout Requests'),
    'admin_banners_screen.dart': ('adminBannersTitle', 'Banners'),
    'admin_categories_screen.dart': ('adminCategoriesTitle', 'Categories'),
    'admin_festivals_screen.dart': ('adminFestivalsTitle', 'Festival calendar'),
  };

  // The seller's twelve screens did the same, dashboard and products first,
  // the other ten after them.
  const sellerScreens = {
    'seller_dashboard_screen.dart': ('sellerDashTitle', 'Seller Dashboard'),
    'seller_products_screen.dart': ('sellerProductsTitle', 'My Products'),
    'seller_orders_screen.dart': ('sellerOrdersTitle', 'Manage Orders'),
    'seller_product_detail_screen.dart': (
      'sellerProductDetailReviews',
      'Reviews ({count})',
    ),
    'seller_earnings_screen.dart': ('sellerEarningsTitle', 'Earnings'),
    'seller_reviews_screen.dart': ('sellerReviewsTitle', 'Reviews'),
    'my_boost_requests_screen.dart': ('sellerBoostsTitle', 'My Boost Requests'),
    'seller_more_screen.dart': ('sellerMoreTitle', 'Profile'),
    'business_details_screen.dart': ('sellerBusinessTitle', 'Business Details'),
    'store_profile_screen.dart': ('sellerStoreTitle', 'Store Profile'),
    'store_location_picker_screen.dart': (
      'sellerLocationHint',
      'Use GPS, search an address, or move the map to place the pin.',
    ),
    'add_product_screen.dart': ('addProductTitle', 'Add Product'),
  };

  /// The migrated role screens, by the folder they live in.
  const screensByRole = {
    'seller': sellerScreens,
    'delivery': deliveryScreens,
    'admin': adminScreens,
  };

  test('the role screens read their words from the string files', () {
    final arb = File('lib/l10n/app_en.arb').readAsStringSync();
    for (final role in screensByRole.entries) {
      for (final entry in role.value.entries) {
        final src =
            File('lib/screens/${role.key}/${entry.key}').readAsStringSync();
        final (key, sentence) = entry.value;
        expect(src, contains('AppLocalizations.of(context)'),
            reason: '${role.key}/${entry.key}');
        expect(src, contains('l10n.$key'), reason: '${role.key}/${entry.key}');
        expect(arb, contains('"$key": "$sentence"'),
            reason: '${role.key}/${entry.key} asks for $key');
      }
    }
  });

  test('no migrated role screen still hardcodes its old headings', () {
    // The words now live in the .arb; finding the sentence back in the
    // screen means the migration was undone somewhere.
    for (final role in screensByRole.entries) {
      for (final entry in role.value.entries) {
        final src =
            File('lib/screens/${role.key}/${entry.key}').readAsStringSync();
        final (_, sentence) = entry.value;
        expect(
          src,
          isNot(contains("'$sentence'")),
          reason: '${role.key}/${entry.key} still says "$sentence" itself',
        );
      }
    }
  });
}
