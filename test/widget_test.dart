import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/providers/theme_mode_provider.dart';
import 'package:thirty/core/routing/app_router.dart';

void main() {
  testWidgets('ThirtyApp starts within a ProviderScope and shows the '
      'product entry screen on the root route', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ThirtyApp()));
    await tester.pumpAndSettle();

    expect(find.text('THIRTY'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('switching ThemeMode via the showcase updates the provider', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ThirtyApp()),
    );
    await tester.pumpAndSettle();

    appRouter.go('/showcase');
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.system);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.text('THIRTY — Design System'))).brightness,
      Brightness.dark,
    );
  });
}
