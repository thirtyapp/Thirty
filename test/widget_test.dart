import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/providers/theme_mode_provider.dart';
import 'package:thirty/core/routing/app_router.dart';
import 'package:thirty/features/home/presentation/widgets/circle_hero.dart';

Future<Widget> _wrap() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const ThirtyApp(),
  );
}

void main() {
  testWidgets('ThirtyApp starts within a ProviderScope and shows the '
      'product entry screen on the root route', (WidgetTester tester) async {
    await tester.pumpWidget(await _wrap());
    await tester.pumpAndSettle();

    expect(find.byType(CircleHero), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('switching ThemeMode via the showcase updates the provider', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
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
