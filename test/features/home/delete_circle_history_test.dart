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
import 'package:thirty/features/home/presentation/widgets/journal_data_controls.dart';
import 'package:thirty/features/insights/application/insight_provider.dart';
import 'package:thirty/features/insights/domain/insight_snapshot.dart';
import 'package:thirty/features/plans/application/plan_provider.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';
import 'package:thirty/features/reminder/application/reminder_provider.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';

/// RELEASE-DEVICE-FIX-1 (P1) — "Delete Circle history" removes every
/// recorded Circle: the journal, today's Circle session, the selection
/// history drawn from past Circles, and derived Insights. Today is
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

  testWidgets('no recorded-Circle key survives: session, reflection, Plan '
      'fields and the selection history drawn from past Circles', (
    tester,
  ) async {
    final (prefs, container) =
        await tester.runAsync(setUpApp)
            as (SharedPreferences, ProviderContainer);
    addTearDown(container.dispose);
    await tester.runAsync(() => walkTodaysCircle(container));
    expect(
      prefs.getStringList(recommendationHistoryKeyFor(Intention.gentlerPace)),
      isNotEmpty,
    );

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

  testWidgets('Premium: derived Insight snapshots go, entitlement and Plan '
      'progress stay', (tester) async {
    final (prefs, container) =
        await tester.runAsync(() => setUpApp(entitled: true))
            as (SharedPreferences, ProviderContainer);
    addTearDown(container.dispose);
    container.read(planProvider.notifier).activatePlan(PlanId.gentlerPacePath);
    await tester.runAsync(() => walkTodaysCircle(container));
    await tester.runAsync(
      () => prefs.setString(
        insightSnapshotsKey,
        '{"schemaVersion":1,"lastAssessedAt":null,"snapshots":[]}',
      ),
    );
    final cursorBefore = container
        .read(planProvider)
        .progress[PlanId.gentlerPacePath]!
        .forwardCursor;
    expect(cursorBefore, 1);

    await deleteThroughDialog(tester, container);

    expect(prefs.containsKey(insightSnapshotsKey), isFalse);
    expect(container.read(insightProvider).snapshots, isEmpty);
    expect(container.read(entitlementStatusProvider), EntitlementStatus.active);
    expect(
      container
          .read(planProvider)
          .progress[PlanId.gentlerPacePath]!
          .forwardCursor,
      cursorBefore,
    );
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
