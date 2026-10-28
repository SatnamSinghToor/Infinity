import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duggu/diwali_festive/festive.dart';

/// Layout and interaction smoke tests for the Diwali festival home screen.
///
/// The screen is built only from Flutter's own widgets, so these run without
/// the app's provider tree. Deliberately no `pumpAndSettle()`: the fairy
/// lights twinkle forever, so the tree never reaches a "settled" state — the
/// tests pump a fixed number of frames instead.
void main() {
  Future<void> pumpScreen(
    WidgetTester tester,
    Size logicalSize, {
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = logicalSize * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, brightness: brightness),
        home: const DiwaliFestiveScreen(),
      ),
    );
    // First frame + the entrance animations.
    await tester.pump(const Duration(milliseconds: 700));
  }

  Future<void> tearDownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  group('DiwaliFestiveScreen layout', () {
    for (final Size size in const <Size>[
      Size(360, 800), // phone, the reference capture
      Size(834, 1112), // tablet
      Size(1440, 900), // desktop / web
      Size(320, 640), // small phone
    ]) {
      testWidgets('renders at ${size.width.toInt()}x${size.height.toInt()}',
          (WidgetTester tester) async {
        await pumpScreen(tester, size);

        expect(tester.takeException(), isNull);
        expect(find.text('17 minutes'), findsOneWidget);
        expect(find.text('Surge applicable'), findsOneWidget);
        expect(find.text('Diwali'), findsWidgets);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Order Again'), findsOneWidget);

        await tearDownTree(tester);
      });
    }

    testWidgets('renders in dark mode', (WidgetTester tester) async {
      await pumpScreen(tester, const Size(390, 844),
          brightness: Brightness.dark);
      expect(tester.takeException(), isNull);
      expect(find.text('17 minutes'), findsOneWidget);
      await tearDownTree(tester);
    });

    testWidgets('survives a 1.35x text scale', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(1.35),
            ),
            child: const DiwaliFestiveScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));
      expect(tester.takeException(), isNull);
      await tearDownTree(tester);
    });
  });

  group('DiwaliFestiveScreen interactions', () {
    testWidgets('category tab selects and reports the category',
        (WidgetTester tester) async {
      await pumpScreen(tester, const Size(390, 844));

      await tester.tap(find.text('Party'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('Browsing Party'), findsOneWidget);
      await tearDownTree(tester);
    });

    testWidgets('ADD fills the cart and raises the cart bar',
        (WidgetTester tester) async {
      await pumpScreen(tester, const Size(390, 844));

      // Bring the first rail into view.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
      await tester.pump(const Duration(milliseconds: 400));

      final Finder addButton = find.text('ADD').first;
      expect(addButton, findsOneWidget);
      await tester.tap(addButton, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      expect(find.text('1 item'), findsOneWidget);
      expect(find.text('View cart'), findsOneWidget);

      await tearDownTree(tester);
    });

    testWidgets('search field opens the search sheet',
        (WidgetTester tester) async {
      await pumpScreen(tester, const Size(390, 844));

      await tester.tap(find.text('Search "pooja thali"'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('Search for diyas, candles, gifts'), findsOneWidget);

      await tearDownTree(tester);
    });
  });

  group('festive formatting', () {
    test('rupee() uses Indian digit grouping', () {
      expect(rupee(0), '₹0');
      expect(rupee(349), '₹349');
      expect(rupee(4999), '₹4,999');
      expect(rupee(112499), '₹1,12,499');
    });

    test('compactCount() shortens thousands', () {
      expect(compactCount(860), '860');
      expect(compactCount(4200), '4.2k');
    });

    test('forApp() keeps the design copy but swaps the live values', () {
      final FestiveCopy copy = FestiveCopy.forApp(
        brand: 'Infinity',
        eta: '12 minutes',
        addressLine: 'Sector 17, Chandigarh',
      );
      expect(copy.brand, 'Infinity in');
      expect(copy.eta, '12 minutes');
      expect(copy.addressLine, 'Sector 17, Chandigarh');
      expect(copy.addressTag, 'HOME');
      expect(copy.bannerTitle, FestiveCopy.reference.bannerTitle);
    });

    test('catalogue data is internally consistent', () {
      for (final FestiveRail rail in FestiveContent.rails) {
        expect(rail.products, isNotEmpty);
        for (final FestiveProduct product in rail.products) {
          expect(product.price, greaterThan(0));
          expect(product.mrp, greaterThanOrEqualTo(product.price));
          expect(product.asset, startsWith('assets/'));
        }
      }
      expect(FestiveContent.tiles, hasLength(6));
      expect(FestiveContent.categories, hasLength(6));
    });
  });
}
