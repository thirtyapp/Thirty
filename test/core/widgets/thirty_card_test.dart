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
}
