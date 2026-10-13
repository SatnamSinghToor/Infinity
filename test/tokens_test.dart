import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duggu/utils/tokens.dart';

void main() {
  const scale = <double>[
    AppSpacing.xxs,
    AppSpacing.xs,
    AppSpacing.sm,
    AppSpacing.md,
    AppSpacing.lg,
    AppSpacing.xl,
    AppSpacing.xxl,
    AppSpacing.xxxl,
  ];

  group('Spacing', () {
    test('the scale ascends', () {
      for (var i = 1; i < scale.length; i++) {
        expect(scale[i] > scale[i - 1], isTrue);
      }
    });

    test('every step lands on the grid', () {
      for (final step in scale) {
        expect(step % 2, 0);
      }
    });

    test('the named gaps come off the scale, not from thin air', () {
      expect(scale, contains(AppSpacing.gutter));
      expect(scale, contains(AppSpacing.listGap));
      expect(scale, contains(AppSpacing.cardPadding));
      expect(scale, contains(AppSpacing.sectionGap));
    });
  });

  group('Radii', () {
    test('the scale ascends and pill rounds anything off', () {
      expect(AppRadius.md > AppRadius.sm, isTrue);
      expect(AppRadius.lg > AppRadius.md, isTrue);
      expect(AppRadius.xl > AppRadius.lg, isTrue);
      expect(AppRadius.pill > AppRadius.xl, isTrue);
    });

    test('the button radius matches what the buttons already draw', () {
      expect(AppRadius.action, const BorderRadius.all(Radius.circular(14)));
    });
  });

  group('Controls', () {
    test('ascend, and stay in the range a thumb is happy with', () {
      expect(AppControl.md > AppControl.sm, isTrue);
      expect(AppControl.lg > AppControl.md, isTrue);
      // Material's smallest comfortable target, and no taller than that.
      expect(AppControl.sm >= 40, isTrue);
      expect(AppControl.lg <= 48, isTrue);
    });
  });

  group('Durations', () {
    test('ascend', () {
      expect(AppDurations.base > AppDurations.fast, isTrue);
      expect(AppDurations.slow > AppDurations.base, isTrue);
    });
  });

  group('Tokens', () {
    test('text reads against its surface in both palettes', () {
      final lightText = AppTokens.light.textPrimary.computeLuminance();
      final lightSurface = AppTokens.light.surface.computeLuminance();
      final darkText = AppTokens.dark.textPrimary.computeLuminance();
      final darkSurface = AppTokens.dark.surface.computeLuminance();
      // Light: dark ink on a pale ground. Dark: pale ink on a dark ground.
      expect(lightText < lightSurface, isTrue);
      expect(darkText > darkSurface, isTrue);
    });

    test('a card sits above its surface in both palettes', () {
      final lightCard = AppTokens.light.card.computeLuminance();
      final lightSurface = AppTokens.light.surface.computeLuminance();
      final darkCard = AppTokens.dark.card.computeLuminance();
      final darkSurface = AppTokens.dark.surface.computeLuminance();
      expect(lightCard > lightSurface, isTrue);
      expect(darkCard > darkSurface, isTrue);
    });

    test('secondary text sits between the text and the surface', () {
      for (final t in [AppTokens.light, AppTokens.dark]) {
        final surface = t.surface.computeLuminance();
        final text = t.textPrimary.computeLuminance();
        final secondary = t.textSecondary.computeLuminance();
        final low = surface < text ? surface : text;
        final high = surface < text ? text : surface;
        expect(secondary > low, isTrue);
        expect(secondary < high, isTrue);
      }
    });

    test('lerp walks from one palette to the other', () {
      final start = AppTokens.light.lerp(AppTokens.dark, 0).card;
      final end = AppTokens.light.lerp(AppTokens.dark, 1).card;
      final none = AppTokens.light.lerp(null, 0.5).card;
      expect(start, AppTokens.light.card);
      expect(end, AppTokens.dark.card);
      expect(none, AppTokens.light.card);
    });

    test('copyWith changes only what it is asked to', () {
      const green = Color(0xFF00FF00);
      final changed = AppTokens.light.copyWith(card: green);
      expect(changed.card, green);
      expect(changed.surface, AppTokens.light.surface);
      expect(changed.textPrimary, AppTokens.light.textPrimary);
    });
  });

  testWidgets('a screen reads the tokens off the theme', (tester) async {
    late AppTokens seen;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppTokens.light]),
        home: Builder(
          builder: (context) {
            seen = context.tokens;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(seen.card, AppTokens.light.card);
    expect(seen.textPrimary, AppTokens.light.textPrimary);
  });
}
