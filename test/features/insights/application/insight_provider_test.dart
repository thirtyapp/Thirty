import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/analytics/analytics_event_type.dart';
import 'package:thirty/core/analytics/analytics_service.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/insights/application/insight_provider.dart';
import 'package:thirty/features/insights/domain/insight_family.dart';
import 'package:thirty/features/insights/domain/insight_snapshot.dart';
import 'package:thirty/features/plans/application/plan_provider.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';

class _RecordingAnalyticsService implements AnalyticsService {
  final List<(AnalyticsEventType, Map<String, Object?>?)> events = [];

  @override
  void track(AnalyticsEventType type, {Map<String, Object?>? metadata}) {
    events.add((type, metadata));
  }
}

final _today = DateTime(2026, 9, 6);

Future<ProviderContainer> _containerWith({
  Map<String, Object> storedPrefs = const {},
  bool entitled = true,
  AnalyticsService? analytics,
  DateTime? now,
}) async {
  SharedPreferences.setMockInitialValues(storedPrefs);
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(now ?? _today),
      eventClockProvider.overrideWithValue(() => now ?? _today),
      premiumEntitlementProvider.overrideWithValue(entitled),
      if (analytics != null)
        analyticsServiceProvider.overrideWithValue(analytics),
    ],
  );
  return container;
}

Future<void> _seedDirectLighterChoices(
  ProviderContainer container,
  PlanId planId,
  List<String> dates,
) async {
  final journal = container.read(circleJournalRepositoryProvider);
  for (final date in dates) {
    await journal.recordShown(
      circleId: date,
      localDate: date,
      direction: planDirection(planId),
      activityId: activityPools[planDirection(planId)]!.first,
      shownAt: DateTime.parse(date),
      planId: planId.name,
      planVersion: 1,
      stageId: 'stage',
      planCycleId: '${planId.name}_cycle_1',
      treatmentUsed: 'lighter',
      treatmentSource: 'directChoice',
    );
  }
}

void main() {
  group('InsightNotifier — cadence', () {
    test('assesses and stores a snapshot the first time it is due', () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      container.read(planProvider.notifier).activatePlan(PlanId.clearerHeadPath);
      await _seedDirectLighterChoices(container, PlanId.clearerHeadPath, [
        '2026-08-20',
        '2026-08-23',
        '2026-08-27',
        '2026-09-01',
        '2026-09-05',
      ]);

      container.read(insightProvider.notifier).refreshIfDue();

      final state = container.read(insightProvider);
      expect(state.lastAssessedAt, _today);
      expect(state.snapshots, hasLength(1));
      expect(state.snapshots.single.family, InsightFamily.chosenPacing);
    });

    test('does not reassess within the 7-day interval', () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      container.read(planProvider.notifier).activatePlan(PlanId.clearerHeadPath);
      await _seedDirectLighterChoices(container, PlanId.clearerHeadPath, [
        '2026-08-20',
        '2026-08-23',
        '2026-08-27',
        '2026-09-01',
        '2026-09-05',
      ]);
      container.read(insightProvider.notifier).refreshIfDue();
      final firstAssessedAt = container.read(insightProvider).lastAssessedAt;

      // A second call, same "now" — must not re-run the assessment or
      // append a duplicate snapshot.
      container.read(insightProvider.notifier).refreshIfDue();

      final state = container.read(insightProvider);
      expect(state.lastAssessedAt, firstAssessedAt);
      expect(state.snapshots, hasLength(1));
    });

    test('reassesses once the 7-day interval has elapsed', () async {
      final container = await _containerWith();
      container.read(planProvider.notifier).activatePlan(PlanId.clearerHeadPath);
      await _seedDirectLighterChoices(container, PlanId.clearerHeadPath, [
        '2026-08-20',
        '2026-08-23',
        '2026-08-27',
        '2026-09-01',
        '2026-09-05',
      ]);
      container.read(insightProvider.notifier).refreshIfDue();
      expect(container.read(insightProvider).snapshots, hasLength(1));

      // Simulated restart under a later "now" — same idiom as
      // `plan_provider_test.dart`'s own "simulated restart" tests: read
      // every persisted key out, dispose the first container, then build a
      // fresh one from that snapshot.
      final prefs = container.read(sharedPreferencesProvider);
      final restored = <String, Object>{
        for (final key in prefs.getKeys())
          if (prefs.get(key) != null) key: prefs.get(key)!,
      };
      container.dispose();

      final later = await _containerWith(
        storedPrefs: restored,
        now: _today.add(const Duration(days: 8)),
      );
      addTearDown(later.dispose);

      later.read(insightProvider.notifier).refreshIfDue();
      final state = later.read(insightProvider);
      expect(state.lastAssessedAt, _today.add(const Duration(days: 8)));
      // Same observation as before (nothing meaningfully changed) — no
      // duplicate snapshot appended, "no invented novelty quota."
      expect(state.snapshots, hasLength(1));
    });

    test('no eligible observation advances lastAssessedAt without a snapshot', () async {
      final container = await _containerWith();
      addTearDown(container.dispose);

      container.read(insightProvider.notifier).refreshIfDue();

      final state = container.read(insightProvider);
      expect(state.lastAssessedAt, _today);
      expect(state.snapshots, isEmpty);
    });
  });

  group('InsightNotifier — snapshot cap', () {
    test('retains at most 52 snapshots, oldest dropped first', () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      container.read(planProvider.notifier).activatePlan(PlanId.clearerHeadPath);

      final notifier = container.read(insightProvider.notifier);
      final journal = container.read(circleJournalRepositoryProvider);
      // Fixed dates within the fixed 28-day evaluation window (`_today` is
      // 2026-09-06) — reused across many distinct `circleId`s so each
      // added record grows the direct-choice count by exactly one without
      // needing dates outside the window.
      const windowDates = [
        '2026-08-10',
        '2026-08-13',
        '2026-08-17',
        '2026-08-21',
        '2026-08-25',
        '2026-08-29',
        '2026-09-01',
        '2026-09-03',
        '2026-09-05',
        '2026-09-06',
      ];

      // Each iteration adds one more relevant record, growing
      // `evidenceCount` by one — a genuinely different observation every
      // time, so every call from the 5th onward actually appends.
      for (var i = 0; i < 60; i++) {
        final date = windowDates[i % windowDates.length];
        await journal.recordShown(
          circleId: 'cap_test_$i',
          localDate: date,
          direction: Intention.clearerHead,
          activityId: ActivityId.phoneFreeWalk,
          shownAt: DateTime.parse(date),
          planId: PlanId.clearerHeadPath.name,
          planVersion: 1,
          stageId: 'stage',
          planCycleId: 'cycle',
          treatmentUsed: 'lighter',
          treatmentSource: 'directChoice',
        );
        // Force this call to be due regardless of the 7-day cadence, so
        // this test exercises the cap itself rather than the cadence gate.
        notifier.state = notifier.state.copyWith(lastAssessedAt: DateTime(2000));
        notifier.refreshIfDue();
      }

      final finalState = container.read(insightProvider);
      expect(finalState.snapshots.length, insightSnapshotMaxCount);
      // The most recent (highest evidence count) observation survives;
      // the oldest were dropped first.
      expect(finalState.snapshots.last.evidenceCount, 60);
    });
  });

  group('InsightNotifier — restore fail-safe', () {
    test('a corrupt persisted blob restores to empty state, never throws', () async {
      final container = await _containerWith(
        storedPrefs: {insightSnapshotsKey: 'not json'},
      );
      addTearDown(container.dispose);

      final state = container.read(insightProvider);
      expect(state.lastAssessedAt, isNull);
      expect(state.snapshots, isEmpty);
    });

    test('a single corrupt snapshot is dropped, the rest survive', () async {
      final valid = {
        'id': 'a',
        'family': 'chosenPacing',
        'applicationType': 'setLighterDefault',
        'targetPlanId': 'clearerHeadPath',
        'targetStageId': null,
        'isPatternClaim': true,
        'evidenceCount': 5,
        'evidenceDateKeys': ['2026-08-20'],
        'usefulnessNumerator': null,
        'usefulnessDenominator': null,
        'generatedAt': '2026-09-01T00:00:00.000',
        'ruleVersion': insightRuleVersion,
        'templateVersion': insightTemplateVersion,
      };
      final corrupt = {'family': 'chosenPacing'};
      final blob = jsonEncode({
        'schemaVersion': insightSnapshotsSchemaVersion,
        'lastAssessedAt': '2026-09-01T00:00:00.000',
        'snapshots': [valid, corrupt],
      });

      final container = await _containerWith(
        storedPrefs: {insightSnapshotsKey: blob},
      );
      addTearDown(container.dispose);

      final state = container.read(insightProvider);
      expect(state.snapshots, hasLength(1));
      expect(state.snapshots.single.id, 'a');
    });
  });

  group('InsightNotifier — application recheck / execution', () {
    test('applying an eligible pacing Insight sets the Plan default and fires analytics', () async {
      final analytics = _RecordingAnalyticsService();
      final container = await _containerWith(analytics: analytics);
      addTearDown(container.dispose);
      container.read(planProvider.notifier).activatePlan(PlanId.clearerHeadPath);
      await _seedDirectLighterChoices(container, PlanId.clearerHeadPath, [
        '2026-08-20',
        '2026-08-23',
        '2026-08-27',
        '2026-09-01',
        '2026-09-05',
      ]);
      container.read(insightProvider.notifier).refreshIfDue();

      container.read(insightProvider.notifier).applyCurrent();

      expect(
        container
            .read(planProvider)
            .progress[PlanId.clearerHeadPath]!
            .lighterDefault,
        isTrue,
      );
      expect(
        analytics.events.any((e) => e.$1 == AnalyticsEventType.insightApplicationAccepted),
        isTrue,
      );
    });

    test(
      'a stale application (state changed since assessment) is withdrawn, '
      'never executed, and reported as invalidated',
      () async {
        final analytics = _RecordingAnalyticsService();
        final container = await _containerWith(analytics: analytics);
        addTearDown(container.dispose);
        container.read(planProvider.notifier).activatePlan(PlanId.clearerHeadPath);
        await _seedDirectLighterChoices(container, PlanId.clearerHeadPath, [
          '2026-08-20',
          '2026-08-23',
          '2026-08-27',
          '2026-09-01',
          '2026-09-05',
        ]);
        container.read(insightProvider.notifier).refreshIfDue();

        // The lighter default becomes true through some other path before
        // the user acts on the (now stale) displayed Insight.
        container
            .read(planProvider.notifier)
            .setLighterDefaultForPlan(PlanId.clearerHeadPath, true);
        analytics.events.clear();

        container.read(insightProvider.notifier).applyCurrent();

        expect(
          analytics.events.any(
            (e) => e.$1 == AnalyticsEventType.insightApplicationInvalidated,
          ),
          isTrue,
        );
        expect(
          analytics.events.any(
            (e) => e.$1 == AnalyticsEventType.insightApplicationAccepted,
          ),
          isFalse,
        );
      },
    );

    test('applying with no snapshots at all is a safe no-op', () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      container.read(insightProvider.notifier).applyCurrent();
      // No throw; nothing to assert beyond survival.
    });
  });

  group('InsightNotifier — clearAll', () {
    test('wipes lastAssessedAt and every retained snapshot', () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      container.read(planProvider.notifier).activatePlan(PlanId.clearerHeadPath);
      await _seedDirectLighterChoices(container, PlanId.clearerHeadPath, [
        '2026-08-20',
        '2026-08-23',
        '2026-08-27',
        '2026-09-01',
        '2026-09-05',
      ]);
      container.read(insightProvider.notifier).refreshIfDue();
      expect(container.read(insightProvider).snapshots, isNotEmpty);

      await container.read(insightProvider.notifier).clearAll();

      final state = container.read(insightProvider);
      expect(state.lastAssessedAt, isNull);
      expect(state.snapshots, isEmpty);
    });
  });

  group('currentInsightProvider — live recheck', () {
    test('withdraws immediately once the underlying state invalidates it, '
        'even mid cadence window', () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      container.read(planProvider.notifier).activatePlan(PlanId.clearerHeadPath);
      await _seedDirectLighterChoices(container, PlanId.clearerHeadPath, [
        '2026-08-20',
        '2026-08-23',
        '2026-08-27',
        '2026-09-01',
        '2026-09-05',
      ]);
      container.read(insightProvider.notifier).refreshIfDue();
      expect(container.read(currentInsightProvider), isNotNull);

      container
          .read(planProvider.notifier)
          .setLighterDefaultForPlan(PlanId.clearerHeadPath, true);

      expect(container.read(currentInsightProvider), isNull);
    });
  });
}
