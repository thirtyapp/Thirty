import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/home_page.dart';
import 'package:thirty/features/home/presentation/widgets/circle_hero.dart';
import 'package:thirty/features/home/presentation/widgets/daily_intention_prompt.dart';

final _today = DateTime(2026, 8, 2);

Future<Widget> _wrap({
  Map<String, Object> storedPrefs = const {},
  bool entitled = false,
}) async {
  SharedPreferences.setMockInitialValues(storedPrefs);
  final prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_today),
      premiumEntitlementProvider.overrideWithValue(entitled),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const HomePage()),
  );
}

void main() {
  testWidgets(
    'shows the Daily Context Question when today has no recommendation yet',
    (WidgetTester tester) async {
      await tester.pumpWidget(await _wrap());

      expect(find.byType(DailyIntentionPrompt), findsOneWidget);
      expect(find.byType(CircleHero), findsNothing);
    },
  );

  testWidgets(
    'renders the Circle Hero experience once today\'s recommendation exists',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        await _wrap(
          storedPrefs: {
            recommendationDayKey: '2026-08-02',
            recommendationIntentionKey: 'moreEnergy',
            recommendationActivityIdKey: 'thirtyMinuteWalk',
          },
        ),
      );

      expect(find.byType(CircleHero), findsOneWidget);
      expect(find.byType(DailyIntentionPrompt), findsNothing);
    },
  );

  testWidgets(
    'the history icon is reachable from every state this page can be in '
    '(ADR-013 §6) — see app_router_test.dart for where tapping it actually '
    'navigates',
    (WidgetTester tester) async {
      await tester.pumpWidget(await _wrap());
      expect(find.byIcon(Icons.history), findsOneWidget);

      await tester.pumpWidget(
        await _wrap(
          storedPrefs: {
            recommendationDayKey: '2026-08-02',
            recommendationIntentionKey: 'moreEnergy',
            recommendationActivityIdKey: 'thirtyMinuteWalk',
          },
        ),
      );
      expect(find.byIcon(Icons.history), findsOneWidget);
    },
  );

  testWidgets(
    'ActionReportPrompt is not shown before today\'s Circle is closed',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        await _wrap(
          storedPrefs: {
            recommendationDayKey: '2026-08-02',
            recommendationIntentionKey: 'moreEnergy',
            recommendationActivityIdKey: 'thirtyMinuteWalk',
          },
        ),
      );

      expect(find.text('Did you try this activity?'), findsNothing);
    },
  );

  testWidgets(
    'ActionReportPrompt appears once today\'s Circle is closed',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        await _wrap(
          storedPrefs: {
            recommendationDayKey: '2026-08-02',
            recommendationIntentionKey: 'moreEnergy',
            recommendationActivityIdKey: 'thirtyMinuteWalk',
            recommendationStatusKey: 'closed',
            recommendationStartedAtKey: _today.toIso8601String(),
            recommendationClosedAtKey: _today.toIso8601String(),
          },
        ),
      );

      expect(find.text('Did you try this activity?'), findsOneWidget);
    },
  );

  testWidgets(
    'the Plans ("Your path") icon is absent by default (no production '
    'entitlement — Batch 2A access seam)',
    (WidgetTester tester) async {
      await tester.pumpWidget(await _wrap());
      expect(find.byIcon(Icons.route_outlined), findsNothing);
    },
  );

  testWidgets(
    'the Plans icon appears only when entitled',
    (WidgetTester tester) async {
      await tester.pumpWidget(await _wrap(entitled: true));
      expect(find.byIcon(Icons.route_outlined), findsOneWidget);
    },
  );
}
