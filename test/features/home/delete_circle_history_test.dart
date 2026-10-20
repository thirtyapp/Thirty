import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/analytics/analytics_consent.dart';
import 'package:thirty/core/analytics/analytics_event_type.dart';
import 'package:thirty/core/analytics/analytics_service.dart';
import 'package:thirty/core/premium/entitlement_gateway.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/providers/theme_mode_provider.dart';
import 'package:thirty/core/qa/qa_entitlement_gateway.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/first_breath_provider.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/home/presentation/widgets/journal_data_controls.dart';
import 'package:thirty/features/insights/application/insights_provider.dart'
    show insightsKey, insightsUnreadableKey;
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/kept_circle.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart'
    show circlePlansKey, circlePlansUnreadableKey;
import 'package:thirty/features/reminder/application/reminder_provider.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';

/// RELEASE-DEVICE-FIX-1 (P1) — "Delete Circle history" removes every
/// recorded Circle: the journal, today's Circle session, the selection
/// history drawn from past Circles, and everything learned from them. Today is
/// re-derived from the empty store. Preferences survive.
class _SilentAnalytics implements AnalyticsService {
  @override
  void track(AnalyticsEventType type, {Map<String, Object?>? metadata}) {}
}

void main() {
  final today = DateTime(2026, 10, 8, 14);

  /// The kept preferences, as a user would have set them.
  const preferences = <String, Object>{
    firstNameKey: 'Thomas',
    firstNamePromptSeenKey: true,
    reminderEnabledKey: true,
    reminderHourKey: 19,
    reminderMinuteKey: 5,
    themeModeKey: 'dark',
    analyticsConsentKey: true,
    firstBreathLastPlayedDateKey: '2026-10-08',
  };

  Future<(SharedPreferences, ProviderContainer)> setUpApp({
    bool entitled = false,
  }) async {
    SharedPreferences.setMockInitialValues(Map.of(preferences));
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWithValue(today),
        eventClockProvider.overrideWithValue(() => today),
        analyticsServiceProvider.overrideWithValue(_SilentAnalytics()),
        entitlementGatewayProvider.overrideWithValue(
          QaEntitlementGateway(
            entitled ? EntitlementStatus.active : EntitlementStatus.inactive,
          ),
        ),
      ],
    );
    await container.read(entitlementStatusProvider.notifier).initialize();
    return (prefs, container);
  }

  /// Today's Circle walked through the real lifecycle: chosen, started,
  /// closed and reflected on.
  Future<void> walkTodaysCircle(ProviderContainer container) async {
    final circle = container.read(recommendationProvider.notifier);
    circle.chooseIntention(Intention.gentlerPace);
    await pumpEventQueue();
    circle.start();
    await pumpEventQueue();
    circle.close();
    await pumpEventQueue();
    circle.reportAttempt(CircleAttemptResponse.aLittle);
    await pumpEventQueue();
    circle.reportUsefulness(CircleUsefulnessResponse.veryUseful);
    await pumpEventQueue();
  }

  /// "Delete Circle history" → "Delete permanently", through the real
  /// confirmation dialog.
  Future<void> deleteThroughDialog(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => JournalDataControls.confirmAndClear(
                context,
                ref.read(circleJournalRepositoryProvider),
                ref,
              ),
              child: const Text('Delete Circle history'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Delete Circle history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete permanently'));
    await tester.pumpAndSettle();
  }

  Set<String> circleKeysIn(SharedPreferences prefs) =>
      prefs.getKeys().where((key) => key.startsWith('recommendation_')).toSet()
        ..addAll(prefs.getKeys().where((key) => key == circleJournalKey));

  testWidgets('today\'s closed, reflected Circle is gone everywhere: '
      'journal, Today and its answers', (tester) async {
    final (prefs, container) =
        await tester.runAsync(setUpApp)
            as (SharedPreferences, ProviderContainer);
    addTearDown(container.dispose);
    await tester.runAsync(() => walkTodaysCircle(container));
    expect(
      container.read(recommendationProvider).status,
      RecommendationStatus.closed,
    );
    expect(circleKeysIn(prefs), isNotEmpty);

    await deleteThroughDialog(tester, container);

    expect(container.read(circleJournalRepositoryProvider).readAll(), isEmpty);
    final todayState = container.read(recommendationProvider);
    expect(todayState.recommendation, isNull);
    expect(todayState.status, RecommendationStatus.notStarted);
    expect(todayState.attemptResponse, isNull);
    expect(todayState.usefulnessResponse, isNull);
  });

  testWidgets('no recorded-Circle key survives: session, reflection, '
      'composed Circle, the retired Phase D keys and the selection history '
      'drawn from past Circles', (tester) async {
    final (prefs, container) =
        await tester.runAsync(setUpApp)
            as (SharedPreferences, ProviderContainer);
    addTearDown(container.dispose);
    // Retired V1 selector keys an older build may have left behind.
    await tester.runAsync(() async {
      await prefs.setStringList(
        recommendationHistoryKeyFor(Intention.gentlerPace),
        ['easyWalk'],
      );
      await prefs.setString(recommendationLastFamilyKey, 'walking');
      // Retired Phase D keys (ADR-024) a development build may have left.
      await prefs.setString(recommendationSessionKey, '{}');
      await prefs.setString(recommendationReplacedRoutineKey, 'routine-1');
    });
    await tester.runAsync(() => walkTodaysCircle(container));
    // V2 Phase B: today's offer is recorded too.
    for (final key in [
      recommendationTimeWindowKey,
      recommendationOfferedMinutesKey,
      recommendationReasonKey,
    ]) {
      expect(prefs.containsKey(key), isTrue, reason: key);
    }

    await deleteThroughDialog(tester, container);

    expect(circleKeysIn(prefs), isEmpty);
    for (final intention in Intention.values) {
      expect(
        prefs.containsKey(recommendationHistoryKeyFor(intention)),
        isFalse,
      );
    }
    expect(prefs.containsKey(recommendationLastFamilyKey), isFalse);
  });

  testWidgets('V2: everything learned goes with it — the next Circle is a '
      'first-ever use again, and the time choice starts from first use', (
    tester,
  ) async {
    final (prefs, container) =
        await tester.runAsync(setUpApp)
            as (SharedPreferences, ProviderContainer);
    addTearDown(container.dispose);
    container.read(timeWindowChoiceProvider.notifier).choose(TimeWindow.upTo30);
    await tester.runAsync(() => walkTodaysCircle(container));
    expect(container.read(timeWindowChoiceProvider), TimeWindow.upTo30);

    await deleteThroughDialog(tester, container);

    expect(container.read(timeWindowChoiceProvider), TimeWindow.about20);
    container
        .read(recommendationProvider.notifier)
        .chooseIntention(Intention.gentlerPace);
    final again = container.read(recommendationProvider).recommendation!;
    expect(again.activityId, ActivityId.easyWalk);
    expect(again.reason, RecommendationReason.starter);
  });

  testWidgets('preferences survive: name, reminder, appearance, analytics '
      'consent and the first-breath flag', (tester) async {
    final (prefs, container) =
        await tester.runAsync(setUpApp)
            as (SharedPreferences, ProviderContainer);
    addTearDown(container.dispose);
    await tester.runAsync(() => walkTodaysCircle(container));

    await deleteThroughDialog(tester, container);

    for (final entry in preferences.entries) {
      expect(prefs.get(entry.key), entry.value, reason: entry.key);
    }
  });

  testWidgets('kept Circles stay, the entitlement stays — and nothing '
      'learned survives the deleted evidence', (tester) async {
    final (prefs, container) =
        await tester.runAsync(() => setUpApp(entitled: true))
            as (SharedPreferences, ProviderContainer);
    addTearDown(container.dispose);
    final kept = KeptCircle(
      id: 'kept-1',
      name: 'My gentle Circle',
      need: Intention.gentlerPace,
      plan: CirclePlan.fromWire(const ['warmDrink:10', 'lookFar:2'])!,
      createdAt: today.subtract(const Duration(days: 40)),
      fromCircleId: '2026-08-29',
    );
    await tester.runAsync(
      () => prefs.setString(
        keptCirclesKey,
        jsonEncode(keptCirclesRecord([kept])),
      ),
    );
    container.invalidate(keptCirclesProvider);
    await tester.runAsync(() => walkTodaysCircle(container));

    await deleteThroughDialog(tester, container);

    final owned = container.read(keptCirclesProvider).kept.single;
    expect(owned.name, 'My gentle Circle');
    expect(owned.plan.toWire(), ['warmDrink:10', 'lookFar:2']);
    expect(container.read(entitlementStatusProvider), EntitlementStatus.active);
    // No evidence left.
    expect(container.read(pastCirclesProvider), isEmpty);
  });

  testWidgets('a Plans or Insights record set aside as unreadable goes '
      'too; an unreadable kept-Circles record stays', (tester) async {
    final (prefs, container) =
        await tester.runAsync(() => setUpApp(entitled: true))
            as (SharedPreferences, ProviderContainer);
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      await prefs.setString(circlePlansUnreadableKey, '{"stages": "old"}');
      await prefs.setString(insightsUnreadableKey, '{"snapshots": "old"}');
      await prefs.setString(keptCirclesUnreadableKey, '{"kept": "old"}');
    });
    await tester.runAsync(() => walkTodaysCircle(container));

    await deleteThroughDialog(tester, container);

    expect(prefs.containsKey(circlePlansUnreadableKey), isFalse);
    expect(prefs.containsKey(insightsUnreadableKey), isFalse);
    expect(prefs.getString(keptCirclesUnreadableKey), '{"kept": "old"}');
    // Nothing else was made of them: no Plan or Insight record appeared.
    expect(prefs.containsKey(insightsKey), isFalse);
    expect(prefs.getString(circlePlansKey), isNot(contains('old')));
  });

  testWidgets('after a restart the deleted Circle does not come back', (
    tester,
  ) async {
    final (prefs, container) =
        await tester.runAsync(setUpApp)
            as (SharedPreferences, ProviderContainer);
    addTearDown(container.dispose);
    await tester.runAsync(() => walkTodaysCircle(container));
    await deleteThroughDialog(tester, container);

    final restarted = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWithValue(today),
      ],
    );
    addTearDown(restarted.dispose);

    expect(restarted.read(circleJournalRepositoryProvider).readAll(), isEmpty);
    expect(restarted.read(recommendationProvider).recommendation, isNull);
    expect(restarted.read(firstNameProvider), 'Thomas');
  });

  testWidgets('cancelling keeps everything', (tester) async {
    final (prefs, container) =
        await tester.runAsync(setUpApp)
            as (SharedPreferences, ProviderContainer);
    addTearDown(container.dispose);
    await tester.runAsync(() => walkTodaysCircle(container));
    final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => JournalDataControls.confirmAndClear(
                context,
                ref.read(circleJournalRepositoryProvider),
                ref,
              ),
              child: const Text('Delete Circle history'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Delete Circle history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep my history'));
    await tester.pumpAndSettle();

    expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
    expect(
      container.read(recommendationProvider).status,
      RecommendationStatus.closed,
    );
  });
}
