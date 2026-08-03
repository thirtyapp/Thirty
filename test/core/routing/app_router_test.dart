import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/routing/app_router.dart';
import 'package:thirty/features/home/presentation/widgets/circle_hero.dart';

void main() {
  testWidgets('the root route shows HomePage', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const ThirtyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CircleHero), findsOneWidget);
    expect(find.text('THIRTY — Design System'), findsNothing);
  });

  testWidgets('the /showcase route shows the design system showcase', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const ThirtyApp(),
      ),
    );
    await tester.pumpAndSettle();

    appRouter.go('/showcase');
    await tester.pumpAndSettle();

    expect(find.text('THIRTY — Design System'), findsOneWidget);
  });
}
