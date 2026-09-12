import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/core/widgets/thirty_progress_circle.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/home_page.dart';
import 'package:thirty/features/home/presentation/widgets/circle_hero.dart';
import 'package:thirty/features/home/presentation/widgets/circle_ready_prompt.dart';
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
    'shows the Circle-first Ready state, not the direction chooser, when '
    'today has no recommendation yet',
    (WidgetTester tester) async {
      await tester.pumpWidget(await _wrap());

      expect(find.byType(CircleReadyPrompt), findsOneWidget);
      expect(find.text("Begin today's Circle"), findsOneWidget);
      expect(find.byType(DailyIntentionPrompt), findsNothing);
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
    'the Circle occupies the exact same position and size in the Ready '
    "state and in the Circle Hero's first settled frame once today's "
    'recommendation exists — the Golden Home continuity correction\'s '
    'core visual requirement: no jump in horizontal/vertical position, '
    'diameter, or top spacing across the daily flow',
    (WidgetTester tester) async {
      await tester.pumpWidget(await _wrap());
      final readyRect = tester.getRect(find.byType(ThirtyProgressCircle));

      SharedPreferences.setMockInitialValues({
        recommendationDayKey: '2026-08-02',
        recommendationIntentionKey: 'moreEnergy',
        recommendationActivityIdKey: 'thirtyMinuteWalk',
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            nowProvider.overrideWithValue(_today),
            premiumEntitlementProvider.overrideWithValue(false),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            // Reduced motion settles CircleHero's First Breath ritual
            // straight to its end state on the very first frame — no
            // `pumpAndSettle` needed (and none would even be safe here:
            // the ambient breathing animation that starts once
            // RecommendationStatus.notStarted's CTA is pressed repeats
            // forever, which `pumpAndSettle` would never resolve).
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: true),
                child: const HomePage(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircleHero), findsOneWidget);
      expect(
        tester.getRect(find.byType(ThirtyProgressCircle)),
        readyRect,
        reason:
            'the Circle must occupy the exact same position and size in '
            "the Ready state and in the Circle Hero's first frame",
      );
    },
  );

  testWidgets(
    'shows no AppBar action icons in any state — founder IA correction: '
    'Plans, Insights (history\'s new home) and You are all persistent '
    'bottom-nav destinations, so a duplicate AppBar shortcut here would '
    'be redundant',
    (WidgetTester tester) async {
      await tester.pumpWidget(await _wrap());
      expect(find.byType(IconButton), findsNothing);

      await tester.pumpWidget(
        await _wrap(
          storedPrefs: {
            recommendationDayKey: '2026-08-02',
            recommendationIntentionKey: 'moreEnergy',
            recommendationActivityIdKey: 'thirtyMinuteWalk',
          },
        ),
      );
      expect(find.byType(IconButton), findsNothing);
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
    'the Plans icon is absent regardless of entitlement — Plans is now a '
    'bottom-nav destination reachable from the shell, not an AppBar '
    'shortcut on Today (founder IA correction)',
    (WidgetTester tester) async {
      await tester.pumpWidget(await _wrap());
      expect(find.byIcon(Icons.route_outlined), findsNothing);

      await tester.pumpWidget(await _wrap(entitled: true));
      expect(find.byIcon(Icons.route_outlined), findsNothing);
    },
  );

  testWidgets(
    'a new local day returns to the Circle-first Ready state even though '
    'yesterday\'s Circle was closed — no "missed day" state, just a fresh '
    'day (Playbook Ch.1 §7-§8)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        await _wrap(
          storedPrefs: {
            recommendationDayKey: '2026-08-01',
            recommendationIntentionKey: 'moreEnergy',
            recommendationActivityIdKey: 'thirtyMinuteWalk',
            recommendationStatusKey: 'closed',
            recommendationStartedAtKey: DateTime(
              2026,
              8,
              1,
            ).toIso8601String(),
            recommendationClosedAtKey: DateTime(2026, 8, 1).toIso8601String(),
          },
        ),
      );

      expect(find.byType(CircleReadyPrompt), findsOneWidget);
      expect(find.byType(CircleHero), findsNothing);
    },
  );
}
