import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duggu/diwali/diwali_data.dart';
import 'package:duggu/diwali/diwali_home.dart';
import 'package:duggu/diwali/diwali_product_card.dart';
import 'package:duggu/diwali/diwali_store.dart';
import 'package:duggu/diwali/diwali_utils.dart';

void main() {
  group('DiwaliStore', () {
    test('ADD, increment and decrement keep count and total in sync', () {
      final store = DiwaliStore();
      final product = DiwaliCatalog.festiveVibes.first;

      expect(store.hasCart, isFalse);
      expect(store.cartCount, 0);
      expect(store.cartTotal, 0);

      store.add(product);
      expect(store.hasCart, isTrue);
      expect(store.quantityOf(product), 1);
      expect(store.cartTotal, product.priceValue);
      expect(store.cartLines, hasLength(1));

      store.add(product);
      expect(store.cartCount, 2);
      expect(store.cartTotal, product.priceValue * 2);

      store.remove(product);
      expect(store.cartCount, 1);
      store.remove(product);
      expect(store.hasCart, isFalse);
      expect(store.cartTotal, 0);
    });

    test('the same item in two rails is one cart line', () {
      final store = DiwaliStore();
      final shared = DiwaliCatalog.warmth[1];
      expect(
        DiwaliCatalog.entrance.map((p) => p.id),
        contains(shared.id),
      );

      store.add(shared);
      expect(store.cartLines, hasLength(1));
      expect(store.cartCount, 1);
    });

    test('savings are the difference between MRP and selling price', () {
      final store = DiwaliStore();
      for (final product in DiwaliCatalog.gifts.take(2)) {
        store.add(product);
      }
      expect(store.cartSavings, greaterThan(0));
      final total = store.cartTotal;
      store.clearCart();
      expect(store.cartSavings, 0);
      expect(store.cartTotal, 0);
      expect(total, greaterThan(0));
    });

    test('wishlist toggles and search is case-insensitive', () {
      final store = DiwaliStore();
      final product = DiwaliCatalog.lights.first;

      expect(store.isWishlisted(product), isFalse);
      store.toggleWishlist(product);
      expect(store.isWishlisted(product), isTrue);
      store.toggleWishlist(product);
      expect(store.isWishlisted(product), isFalse);

      store.setQuery('URLI');
      expect(store.searchResults(), isNotEmpty);
      expect(
        store.searchResults().every((p) => p.name.toLowerCase().contains('urli')),
        isTrue,
      );

      store.setQuery('zzzznothing');
      expect(store.searchResults(), isEmpty);
      expect(store.resultCount, 0);

      store.clearQuery();
      expect(store.query, isEmpty);
      expect(store.resultCount, -1);
    });

    test('header selections are stable', () {
      final store = DiwaliStore();
      store.selectTab(3);
      store.selectGiftChip(2);
      store.setAddress('Model Town, Ludhiana');
      store.setVoiceListening(true);

      expect(store.tabIndex, 3);
      expect(store.giftChipIndex, 2);
      expect(store.address, 'Model Town, Ludhiana');
      expect(store.voiceListening, isTrue);

      store.setVoiceListening(false);
      expect(store.voiceListening, isFalse);
    });
  });

  group('catalogue', () {
    test('every rail has products with parseable prices', () {
      for (final rail in DiwaliCatalog.allRails) {
        expect(rail, isNotEmpty);
        for (final product in rail) {
          expect(product.priceValue, greaterThan(0), reason: product.name);
          expect(product.name, isNotEmpty);
          expect(product.qty, isNotEmpty);
        }
      }
    });

    test('all referenced images are bundled in assets/diwali', () {
      final assets = <String>{
        for (final tile in DiwaliCatalog.heroTiles) tile.asset,
        for (final rail in DiwaliCatalog.allRails)
          for (final product in rail) product.asset,
        for (final item in DiwaliCatalog.festiveShopping) item.asset,
        for (final item in DiwaliCatalog.vibrantDecor) item.asset,
        for (final item in DiwaliCatalog.diwaliGifting) item.asset,
        for (final item in DiwaliCatalog.giftChips) item.asset,
        for (final item in DiwaliCatalog.diyasAndCandles) item.asset,
        for (final item in DiwaliCatalog.calendar) item.asset,
        for (final item in DiwaliCatalog.brands) item.asset,
        for (final item in DiwaliCatalog.festiveHome) item.asset,
        for (final item in DiwaliCatalog.diwaliOutfit) item.asset,
        for (final item in DiwaliCatalog.poojaEssentials) item.asset,
      };
      expect(assets.length, greaterThan(30));
      for (final asset in assets) {
        expect(File(asset).existsSync(), isTrue, reason: 'missing $asset');
      }
    });

    test('the three bundled Diwali fonts are registered in pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final family in const ['DiwaliSerif', 'DiwaliDisplay', 'Poppins']) {
        expect(pubspec, contains('family: $family'));
      }
      for (final face in const [
        'DiwaliSerif-Regular.ttf',
        'DiwaliSerif-Italic.ttf',
        'DiwaliDisplay-Regular.ttf',
      ]) {
        expect(pubspec, contains(face));
        expect(File('assets/fonts/$face').existsSync(), isTrue);
      }
      expect(pubspec, contains('- assets/diwali/'));
    });
  });

  group('diwaliRupees', () {
    test('uses Indian digit grouping', () {
      expect(diwaliRupees(0), '₹0');
      expect(diwaliRupees(499), '₹499');
      expect(diwaliRupees(1499), '₹1,499');
      expect(diwaliRupees(123456), '₹1,23,456');
      expect(diwaliRupees(12345678), '₹1,23,45,678');
    });
  });

  group('responsive layout', () {
    const viewports = <(String, Size)>[
      ('phone 360x640', Size(360, 640)),
      ('tablet 820x1180', Size(820, 1180)),
      ('desktop 1440x900', Size(1440, 900)),
    ];

    for (final viewport in viewports) {
      testWidgets('the whole storefront lays out at ${viewport.$1}',
          (tester) async {
        tester.view.physicalSize = viewport.$2;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(const MaterialApp(home: DiwaliPage()));
        await tester.pump(const Duration(milliseconds: 120));
        // Long enough for every staggered reveal timer to fire.
        await tester.pump(const Duration(seconds: 1));

        final renderErrors = <Object>[];
        Object? error;
        while ((error = tester.takeException()) != null) {
          renderErrors.add(error!);
        }
        expect(renderErrors, isEmpty, reason: renderErrors.join('\n'));
        expect(find.text('DIWALI'), findsOneWidget);
        expect(find.text('FESTIVE SHOPPING STARTS HERE'), findsOneWidget);
        expect(find.text('Light Up Your Celebrations'), findsOneWidget);
      });
    }
  });

  testWidgets('a product card ADD button writes through to the store',
      (tester) async {
    final store = DiwaliStore();
    final product = DiwaliCatalog.festiveVibes.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiwaliScope(
            store: store,
            child: SingleChildScrollView(
              child: DiwaliProductCard(product: product, width: 180),
            ),
          ),
        ),
      ),
    );

    expect(find.text('ADD'), findsOneWidget);
    await tester.tap(find.text('ADD'));
    await tester.pump();

    expect(store.cartCount, 1);
    expect(store.cartTotal, product.priceValue);
    expect(find.text('ADD'), findsNothing);
  });
}
