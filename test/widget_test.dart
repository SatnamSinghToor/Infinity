import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duggu/main.dart';
import 'package:duggu/services/supabase_service.dart';
import 'package:duggu/utils/constants.dart';

void main() {
  testWidgets('App launches with the splash screen', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // The wordmark is a picture of the word "duggu", so the splash has to
    // label it or a screen reader has nothing to say. Asserted on the widget
    // rather than through bySemanticsLabel, which only sees the label once
    // the semantics tree has been flushed for an accessibility client.
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == 'duggu',
        description: 'the splash wordmark labelled for screen readers',
      ),
      findsOneWidget,
    );
    expect(find.text(AppConstants.tagline), findsOneWidget);
    expect(find.text('Getting your store ready…'), findsOneWidget);

    // Let the splash's timers run out so none is left pending.
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(MaterialApp), findsOneWidget);

    // The real sign-in client refreshes its session on a timer; stop it so
    // the test ends with nothing pending.
    SupabaseService.client.auth.stopAutoRefresh();
  });
}
