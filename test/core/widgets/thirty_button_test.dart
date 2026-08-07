import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_button.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

void main() {
  group('ThirtyButton', () {
    testWidgets('shows its label', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(ThirtyButton(label: 'Start', onPressed: () {})),
      );

      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('fires onPressed when enabled and tapped', (
      WidgetTester tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(ThirtyButton(label: 'Start', onPressed: () => tapped = true)),
      );

      await tester.tap(find.byType(ThirtyButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('does not fire onPressed when disabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const ThirtyButton(label: 'Start', onPressed: null)),
      );

      await tester.tap(find.byType(ThirtyButton));
      await tester.pump();

      // No exception and no callback to assert on: absence of a crash and
      // the widget being present is the observable behavior here.
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('shows a spinner and ignores taps while loading', (
      WidgetTester tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          ThirtyButton(
            label: 'Start',
            onPressed: () => tapped = true,
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(ThirtyButton));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('keeps the same size between the normal and loading state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(ThirtyButton(label: 'Start', onPressed: () {})),
      );
      final normalSize = tester.getSize(find.byType(ThirtyButton));

      await tester.pumpWidget(
        _wrap(
          const ThirtyButton(label: 'Start', onPressed: null, isLoading: true),
        ),
      );
      final loadingSize = tester.getSize(find.byType(ThirtyButton));

      expect(loadingSize, normalSize);
    });

    testWidgets('exposes accessible button semantics', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(ThirtyButton(label: 'Start', onPressed: () {})),
      );

      final semantics = tester.getSemantics(find.byType(ThirtyButton));
      expect(semantics.label, 'Start');
      expect(semantics.flagsCollection.isButton, isTrue);
      expect(semantics.flagsCollection.isEnabled, Tristate.isTrue);
    });

    testWidgets('communicates disabled state via semantics', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const ThirtyButton(label: 'Start', onPressed: null)),
      );

      final semantics = tester.getSemantics(find.byType(ThirtyButton));
      expect(semantics.flagsCollection.isEnabled, Tristate.isFalse);
    });

    testWidgets('communicates the loading status via semantics', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(ThirtyButton(label: 'Start', onPressed: () {}, isLoading: true)),
      );

      final semantics = tester.getSemantics(find.byType(ThirtyButton));
      expect(semantics.label, contains('Start'));
      expect(semantics.label, contains('bezig'));
      expect(semantics.flagsCollection.isEnabled, Tristate.isFalse);
    });

    testWidgets('shows an icon when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          ThirtyButton(
            label: 'Start',
            onPressed: () {},
            icon: Icons.play_arrow_rounded,
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets(
      'replaces the default splash with a quiet local pressed overlay',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _wrap(ThirtyButton(label: 'Start', onPressed: () {})),
        );

        final inkWell = tester.widget<InkWell>(find.byType(InkWell));

        expect(inkWell.splashFactory, NoSplash.splashFactory);
        expect(
          inkWell.overlayColor?.resolve({WidgetState.pressed}),
          isNotNull,
        );
        // Hover/focus stay on InkWell's own defaults — only the pressed
        // state is resolved to a custom color.
        expect(inkWell.overlayColor?.resolve({WidgetState.hovered}), isNull);
      },
    );

    testWidgets(
      'gives primary and secondary distinct, non-null pressed overlays '
      '(variant-aware, accessibility-verified — Premium Pass 01D '
      'Experiment 3B)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _wrap(ThirtyButton(label: 'Start', onPressed: () {})),
        );
        final primaryOverlay = tester
            .widget<InkWell>(find.byType(InkWell))
            .overlayColor
            ?.resolve({WidgetState.pressed});

        await tester.pumpWidget(
          _wrap(
            ThirtyButton(
              label: 'Start',
              onPressed: () {},
              variant: ThirtyButtonVariant.secondary,
            ),
          ),
        );
        final secondaryOverlay = tester
            .widget<InkWell>(find.byType(InkWell))
            .overlayColor
            ?.resolve({WidgetState.pressed});

        expect(primaryOverlay, isNotNull);
        expect(secondaryOverlay, isNotNull);
        expect(primaryOverlay, isNot(secondaryOverlay));
      },
    );
  });
}
