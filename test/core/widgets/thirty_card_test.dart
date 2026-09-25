import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_card.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

void main() {
  group('ThirtyCard', () {
    testWidgets('renders its child', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const ThirtyCard(child: Text('Content'))));

      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('fires onTap when tapped', (WidgetTester tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          ThirtyCard(onTap: () => tapped = true, child: const Text('Content')),
        ),
      );

      await tester.tap(find.text('Content'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders without a tap handler', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const ThirtyCard(child: Text('Content'))));

      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('has an InkWell only when onTap is provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(ThirtyCard(onTap: () {}, child: const Text('Content'))),
      );
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('has no InkWell when onTap is absent', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const ThirtyCard(child: Text('Content'))));
      expect(find.byType(InkWell), findsNothing);
    });
  });

  group('ThirtyCard — Phase A3 surface language', () {
    Future<void> pumpCard(WidgetTester tester, ThemeData theme) {
      return tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: ThirtyCard(child: Text('Content'))),
        ),
      );
    }

    // ThirtyCard builds an outer shadow Container and an inner content
    // Container, in that order.
    Container innerContainer(WidgetTester tester) => tester.widget<Container>(
      find
          .descendant(
            of: find.byType(ThirtyCard),
            matching: find.byType(Container),
          )
          .at(1),
    );

    BoxDecoration decorationAt(WidgetTester tester, int index) {
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(ThirtyCard),
              matching: find.byType(Container),
            )
            .at(index),
      );
      return container.decoration! as BoxDecoration;
    }

    testWidgets('light: radius 24, soft two-layer shadow, borderless', (
      tester,
    ) async {
      await pumpCard(tester, AppTheme.light);

      final outer = decorationAt(tester, 0);
      expect(outer.borderRadius, AppRadius.xl);
      expect(outer.boxShadow, AppShadows.light);
      expect(AppShadows.light, hasLength(2));
      expect(outer.border, isNull);
      expect(innerContainer(tester).decoration, isNull);
      expect(
        tester
            .widget<ClipRRect>(
              find.descendant(
                of: find.byType(ThirtyCard),
                matching: find.byType(ClipRRect),
              ),
            )
            .borderRadius,
        AppRadius.xl,
      );
    });

    testWidgets('dark: radius 24, dark shadow, borderless like light (A5)', (
      tester,
    ) async {
      await pumpCard(tester, AppTheme.dark);

      final outer = decorationAt(tester, 0);
      expect(outer.borderRadius, AppRadius.xl);
      expect(outer.boxShadow, AppShadows.dark);
      expect(outer.border, isNull);
      expect(innerContainer(tester).decoration, isNull);
      expect(
        tester
            .widget<Material>(
              find.descendant(
                of: find.byType(ThirtyCard),
                matching: find.byType(Material),
              ),
            )
            .color,
        AppColors.dark.surface,
      );
    });

    test('shadows stay short so history cards 8pt apart do not bleed', () {
      for (final shadow in [...AppShadows.light, ...AppShadows.dark]) {
        expect(shadow.blurRadius, lessThanOrEqualTo(16));
        expect(shadow.offset.dy, lessThanOrEqualTo(4));
      }
    });
  });
}
