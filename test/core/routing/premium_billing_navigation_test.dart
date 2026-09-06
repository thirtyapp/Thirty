import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/routing/app_router.dart';
import 'package:thirty/features/premium/presentation/premium_offer_page.dart';
import 'package:thirty/features/settings/presentation/settings_page.dart';

/// Step 5 (`docs/product/adr/ADR-017-v1-step5-revenuecat-billing.md`) —
/// integration-level navigation coverage for the new billing routes,
/// following the existing pattern in `app_router_test.dart` (real
/// `appRouter`/`ThirtyApp`, no fakes, `appRouter.go`/real taps).
void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const ThirtyApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the /settings route shows SettingsPage', (tester) async {
    await pumpApp(tester);

    appRouter.go('/settings');
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets('the /premium route shows PremiumOfferPage', (tester) async {
    await pumpApp(tester);

    appRouter.go('/premium');
    await tester.pumpAndSettle();

    expect(find.byType(PremiumOfferPage), findsOneWidget);
  });

  testWidgets('the home screen\'s Settings icon opens SettingsPage — '
      'reachable regardless of entitlement, unlike the Plans icon',
      (tester) async {
    await pumpApp(tester);
    // `appRouter` is a shared singleton across this test file (matching
    // `app_router_test.dart`'s own established pattern) — explicitly
    // return to the root route rather than assuming a previous test left
    // it there.
    appRouter.go('/');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets('tapping "Upgrade to Premium" in Settings opens the offer '
      'page', (tester) async {
    await pumpApp(tester);
    appRouter.go('/settings');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Upgrade to Premium'));
    await tester.pumpAndSettle();

    expect(find.byType(PremiumOfferPage), findsOneWidget);
  });
}
