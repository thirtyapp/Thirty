import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/routing/app_router.dart';

void main() {
  testWidgets('the root route shows HomePage', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ThirtyApp()));
    await tester.pumpAndSettle();

    expect(find.text('THIRTY'), findsOneWidget);
    expect(find.text('Your healthiest 30 minutes.'), findsOneWidget);
    expect(find.text('THIRTY — Design System'), findsNothing);
  });

  testWidgets('the /showcase route shows the design system showcase', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: ThirtyApp()));
    await tester.pumpAndSettle();

    appRouter.go('/showcase');
    await tester.pumpAndSettle();

    expect(find.text('THIRTY — Design System'), findsOneWidget);
  });
}
