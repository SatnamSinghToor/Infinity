import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duggu/utils/tokens.dart';
import 'package:duggu/widgets/bottom_nav.dart';
import 'package:duggu/widgets/role_bottom_nav.dart';

/// The nav bar itself: the one [Container] in a nav whose decoration carries
/// the card radius.
BoxDecoration? _bar(WidgetTester tester) {
  BoxDecoration? found;
  for (final element in find.byType(Container).evaluate()) {
    final decoration = (element.widget as Container).decoration;
    if (decoration is! BoxDecoration) continue;
    if (decoration.borderRadius == AppRadius.card) found = decoration;
  }
  return found;
}

Future<void> _pump(WidgetTester tester, AppTokens tokens, Widget nav) {
  return tester.pumpWidget(
    MaterialApp(
      // The customer's bar takes its labels from the string files now, so the
      // app's delegates have to be installed here as well.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(extensions: [tokens]),
      home: Scaffold(bottomNavigationBar: nav),
    ),
  );
}

void main() {
  testWidgets('the customer nav takes its colour from the theme',
      (tester) async {
    await _pump(
      tester,
      AppTokens.dark,
      BottomNavWidget(currentIndex: 0, onTap: (_) {}),
    );
    expect(_bar(tester)?.color, AppTokens.dark.card);
  });

  testWidgets('the role nav takes its colour from the theme', (tester) async {
    await _pump(
      tester,
      AppTokens.dark,
      RoleBottomNav(
        currentIndex: 0,
        onTap: (_) {},
        items: const [
          (outline: Icons.home_outlined, filled: Icons.home, label: 'Home'),
        ],
      ),
    );
    expect(_bar(tester)?.color, AppTokens.dark.card);
  });

  testWidgets('swapping the theme swaps the nav, with no other change',
      (tester) async {
    await _pump(
      tester,
      AppTokens.light,
      BottomNavWidget(currentIndex: 0, onTap: (_) {}),
    );
    // Light is the look the app has always drawn, so migrating the nav onto
    // tokens must leave it exactly as it was.
    expect(_bar(tester)?.color, Colors.white);
  });
}
