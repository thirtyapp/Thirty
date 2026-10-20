import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/analytics/analytics_consent.dart';
import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/routing/app_router.dart';
import 'package:thirty/features/personal_circle/application/guidance_voice.dart';
import 'package:thirty/features/personal_circle/domain/spoken_cues.dart';
import 'package:thirty/features/personal_circle/presentation/yours_page.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';
import 'package:thirty/features/settings/presentation/widgets/you_data_card.dart';
import 'package:thirty/features/settings/presentation/widgets/you_personal_card.dart';
import 'package:thirty/features/settings/presentation/widgets/you_preferences_card.dart';
import 'package:thirty/features/settings/presentation/widgets/you_premium_card.dart';

class _SettledEntitlement extends EntitlementNotifier {
  _SettledEntitlement(this._status);

  final EntitlementStatus _status;

  @override
  EntitlementStatus build() => _status;
}

/// B7 — You as the user's ownership and control (contract, Navigation:
/// Personal · Preferences · Premium · Data & privacy), in the final shell:
/// Yours and What THIRTY remembers under Personal, the reminder and
/// appearance, THIRTY's voice only where Premium can play it, the data
/// controls, the subscription's status and restore — and nothing retired.
void main() {
  Future<void> pumpYou(
    WidgetTester tester,
    EntitlementStatus status, {
    Map<String, Object> stored = const {},
  }) async {
    SharedPreferences.setMockInitialValues({
      firstNamePromptSeenKey: true,
      ...stored,
    });
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(412, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          entitlementStatusProvider.overrideWith(
            () => _SettledEntitlement(status),
          ),
          bundledGuidanceVoicesProvider.overrideWithValue(
            ThirtyVoice.values.toSet(),
          ),
        ],
        child: const ThirtyApp(),
      ),
    );
    await tester.pumpAndSettle();
    appRouter.go('/settings');
    await tester.pumpAndSettle();
  }

  double top(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text).first).dy;

  for (final status in [EntitlementStatus.active, EntitlementStatus.inactive]) {
    final paid = status == EntitlementStatus.active;
    testWidgets('${status.name}: Personal (name, What THIRTY remembers, '
        'Yours, History) → Premium → Preferences → Data & privacy → About → '
        'Restore; the voice only with Premium; nothing retired', (
      tester,
    ) async {
      await pumpYou(tester, status);

      final order = [
        'Personal',
        YouPersonalCard.rowTitle,
        YouPersonalCard.memoryTitle,
        YouPersonalCard.yoursTitle,
        YouPersonalCard.historyTitle,
        'THIRTY Premium',
        YouPremiumCard.body,
        paid ? 'Premium is active' : 'Pricing isn’t available right now.',
        'Preferences',
        'Daily reminder',
        'Appearance',
        if (paid) SpokenGuidanceCopy.title,
        'Data & privacy',
        'Share anonymous usage data',
        'Copy as text',
        'Delete Circle history',
        'About',
        'Restore purchases',
      ];
      for (var i = 1; i < order.length; i++) {
        expect(
          top(tester, order[i]),
          greaterThan(top(tester, order[i - 1])),
          reason: '${order[i]} below ${order[i - 1]}',
        );
      }
      expect(
        find.text(SpokenGuidanceCopy.title),
        paid ? findsOneWidget : findsNothing,
      );
      // Founder decision (B7): usage-data consent sits in Data & privacy,
      // once; Reset suggestion preferences stays in What THIRTY remembers.
      const usage = 'Share anonymous usage data';
      expect(find.text(usage), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(YouDataCard),
          matching: find.text(usage),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(YouPreferencesCard),
          matching: find.text(usage),
        ),
        findsNothing,
      );
      expect(find.text('Reset suggestion preferences'), findsNothing);
      if (paid) {
        for (final voice in ThirtyVoice.values) {
          expect(find.text(voice.label), findsOneWidget, reason: voice.label);
        }
      }
      for (final retired in [
        'Toolkit',
        'routine',
        'Routine',
        'Path',
        'tune-up',
        'Coach',
        'Journal',
      ]) {
        expect(
          find.textContaining(retired, findRichText: true),
          findsNothing,
          reason: retired,
        );
      }

      // Yours is one row away, in the You tab, whatever Premium's state.
      await tester.tap(find.text(YouPersonalCard.yoursTitle));
      await tester.pumpAndSettle();
      expect(find.byType(YoursPage), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
      appRouter.go('/settings');
      await tester.pumpAndSettle();
    });
  }

  testWidgets('the move keeps consent exactly as it was: a stored "on" '
      'shows on, and the switch still sets it', (tester) async {
    await pumpYou(
      tester,
      EntitlementStatus.inactive,
      stored: const {analyticsConsentKey: true},
    );
    final toggle = find.descendant(
      of: find.byKey(const ValueKey('you.analytics')),
      matching: find.byType(Switch),
    );
    expect(
      find.descendant(of: find.byType(YouDataCard), matching: toggle),
      findsOneWidget,
    );
    expect(tester.widget<Switch>(toggle).value, isTrue);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(YouDataCard)),
    );
    expect(container.read(analyticsConsentProvider), isFalse);
  });
}
