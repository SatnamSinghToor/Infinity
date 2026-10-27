import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:duggu/providers/auth_provider.dart';
import 'package:duggu/providers/product_provider.dart';
import 'package:duggu/screens/auth/login_screen.dart';
import 'package:duggu/services/supabase_service.dart';

/// The login page is one plain column in one scroll view. These tests hold
/// that order down: a form that can be drawn on top of itself — the button
/// over the small print, or the small print over the button — is worse than
/// a slow one, and it is exactly what a page of clever nested boxes ends up
/// doing when a phone hands it an odd size for a frame.
Widget _host() => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Nothing to load and nothing to fetch: the page is under test, not
        // the shop behind it.
        ChangeNotifierProvider(create: (_) => ProductProvider(autoload: false)),
      ],
      child: const MaterialApp(
        // The page's words come from the string files now, so the app's own
        // delegates have to be installed here as well.
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // The photo rows flow on a ticker of their own; switching it off
        // keeps the test to the frames the layout needs and nothing more.
        home: TickerMode(enabled: false, child: LoginScreen()),
      ),
    );

void main() {
  // The sign-in client keeps a ten-second refresh timer for as long as it
  // exists. It is built here, outside any test, so that timer belongs to the
  // clock the test runner itself is on — a test body, which runs on a clock
  // of its own, has to end with nothing of its own still ticking.
  setUpAll(() => SupabaseService.client);

  // And it is stopped as well, so nothing is left running after the file.
  tearDown(() => SupabaseService.client.auth.stopAutoRefresh());

  /// A phone-sized screen, so the page is laid out the way it really is.
  Future<void> pumpLogin(WidgetTester tester) async {
    tester.view.physicalSize = const Size(720, 1560);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host());
    await tester.pump();
    // Building the page reaches the sign-in client, and that client keeps a
    // ten-second refresh timer of its own for as long as it exists. A test
    // body has to end with nothing ticking, and a tearDown runs too late for
    // that check, so it is stopped here.
    SupabaseService.client.auth.stopAutoRefresh();
  }

  testWidgets('the page stacks in one order, with nothing overlapping',
      (tester) async {
    await pumpLogin(tester);

    expect(tester.takeException(), isNull);

    final skip = find.text('Skip');
    final heading = find.text('Log In or Sign Up');
    final button = find.text('Continue');
    final smallPrint = find.textContaining('By continuing', findRichText: true);

    expect(skip, findsOneWidget);
    expect(heading, findsOneWidget);
    expect(button, findsOneWidget);
    expect(smallPrint, findsOneWidget);

    // Skip is part of the header row, so it stays above everything else.
    expect(tester.getBottomLeft(skip).dy,
        lessThanOrEqualTo(tester.getTopLeft(heading).dy));
    // The heading, the button, then the small print, each below the last.
    expect(tester.getBottomLeft(heading).dy,
        lessThan(tester.getTopLeft(button).dy));
    expect(tester.getBottomLeft(button).dy,
        lessThanOrEqualTo(tester.getTopLeft(smallPrint).dy));
  });

  testWidgets('the fields fit the page and sit above the button',
      (tester) async {
    await pumpLogin(tester);

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    expect(tester.takeException(), isNull);

    final page = tester.getRect(find.byType(LoginScreen));
    final button = tester.getTopLeft(find.text('Continue')).dy;
    for (var i = 0; i < 2; i++) {
      final field = tester.getRect(fields.at(i));
      expect(field.left, greaterThanOrEqualTo(page.left));
      expect(field.right, lessThanOrEqualTo(page.right),
          reason: 'a field never runs off the page');
      expect(field.bottom, lessThan(button),
          reason: 'the fields come before the button');
    }
  });
}
