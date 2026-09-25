import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/routing/app_router.dart';
import 'package:thirty/features/premium/presentation/premium_offer_page.dart';
import 'package:thirty/features/settings/presentation/settings_page.dart';

/// Step 5 (`docs/product/adr/ADR-017-v1-step5-revenuecat-billing.md`) —
/// integration-level navigation coverage for the new billing routes,
/// following the existing pattern in `app_router_test.dart` (real
/// `appRouter`/`ThirtyApp`, no fakes, `appRouter.go`/real taps).
/// A settled entitlement status (as `main.dart`'s startup `initialize()`
/// would leave it). Since Phase C1, You shows no acquisition CTA while the
/// status is still being checked, so tests that follow the "Become
/// Premium" path need a known free state.
class _SettledEntitlement extends EntitlementNotifier {
  _SettledEntitlement(this._status);

  final EntitlementStatus _status;

  @override
  EntitlementStatus build() => _status;
}

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          entitlementStatusProvider.overrideWith(
            () => _SettledEntitlement(EntitlementStatus.inactive),
          ),
        ],
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

  testWidgets(
    'the "You" bottom-nav destination opens SettingsPage — reachable '
    'regardless of entitlement (founder IA correction: "You" replaced '
    'the old AppBar Settings icon as the access path)',
    (tester) async {
      await pumpApp(tester);
      // `appRouter` is a shared singleton across this test file (matching
      // `app_router_test.dart`'s own established pattern) — explicitly
      // return to the root route rather than assuming a previous test left
      // it there.
      appRouter.go('/');
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('You'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
    },
  );

  testWidgets('tapping "Become Premium" in Settings opens the offer '
      'page', (tester) async {
    await pumpApp(tester);
    appRouter.go('/settings');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Become Premium'));
    await tester.pumpAndSettle();

    expect(find.byType(PremiumOfferPage), findsOneWidget);
  });
}
