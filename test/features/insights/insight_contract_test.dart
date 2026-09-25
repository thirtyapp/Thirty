import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/analytics/analytics_event_type.dart';
import 'package:thirty/core/analytics/analytics_service.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_button.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/insights/application/insight_provider.dart';
import 'package:thirty/features/insights/domain/insight_engine.dart';
import 'package:thirty/features/insights/domain/insight_snapshot.dart';
import 'package:thirty/features/insights/presentation/widgets/insight_card.dart';
import 'package:thirty/features/plans/application/plan_provider.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';

/// Insights contract correction (frozen architecture §9 / §21):
/// aged-out evidence is never current, earlier Insights stay readable but
/// not actionable, the observation is dated, and Dismiss hides exactly that
/// observation until a genuinely new one exists.

class _RecordingAnalytics implements AnalyticsService {
  final events = <AnalyticsEventType>[];
  @override
  void track(AnalyticsEventType type, {Map<String, Object?>? metadata}) {
    events.add(type);
  }
}

/// A Clearer Head direction pattern (5 visits, 20 Aug – 5 Sep), assessed
/// 6 Sep. Clearer Head is not active, so it is applicable while current.
Map<String, Object?> _patternSnapshot({
  bool? dismissed,
  List<String> dates = const ['2026-08-20', '2026-08-27', '2026-09-05'],
}) => {
  'id': 'pattern',
  'family': 'directionPathContinuity',
  'applicationType': 'activateOrResumePlan',
  'targetPlanId': 'clearerHeadPath',
  'targetStageId': null,
  'isPatternClaim': true,
  'evidenceCount': 5,
  'evidenceDateKeys': dates,
  'usefulnessNumerator': null,
  'usefulnessDenominator': null,
  'generatedAt': '2026-09-06T09:00:00.000',
  'ruleVersion': insightRuleVersion,
  'templateVersion': insightTemplateVersion,
  // Old stored snapshots have no 'dismissed' key at all.
  'dismissed': ?dismissed,
};

String _blob(List<Map<String, Object?>> snapshots) => jsonEncode({
  'schemaVersion': insightSnapshotsSchemaVersion,
  'lastAssessedAt': '2026-09-06T09:00:00.000',
  'snapshots': snapshots,
});

Future<ProviderContainer> _container({
  required DateTime now,
  Map<String, Object> prefs = const {},
  bool entitled = true,
  AnalyticsService? analytics,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final shared = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(shared),
      nowProvider.overrideWithValue(now),
      eventClockProvider.overrideWithValue(() => now),
      premiumEntitlementProvider.overrideWithValue(entitled),
      if (analytics != null) analyticsServiceProvider.overrideWithValue(analytics),
    ],
  );
}

/// The newest evidence is 5 Sep; the 28-day window at [now] starts 28 days
/// before [now]'s date.
final _fresh = DateTime(2026, 9, 20); // window from 23 Aug — 5 Sep inside
final _agedOut = DateTime(2026, 10, 10); // window from 12 Sep — 5 Sep outside

Map<String, Object> _persisted(ProviderContainer container) {
  final prefs = container.read(sharedPreferencesProvider);
  return {
    for (final key in prefs.getKeys())
      if (prefs.get(key) != null) key: prefs.get(key)!,
  };
}

Future<void> _seedLighterChoices(
  ProviderContainer container,
  List<String> dates,
) async {
  final journal = container.read(circleJournalRepositoryProvider);
  for (final date in dates) {
    await journal.recordShown(
      circleId: 'c_$date',
      localDate: date,
      direction: planDirection(PlanId.clearerHeadPath),
      activityId: activityPools[planDirection(PlanId.clearerHeadPath)]!.first,
      shownAt: DateTime.parse(date),
      planId: PlanId.clearerHeadPath.name,
      planVersion: 1,
      stageId: 'stage',
      planCycleId: 'cycle',
      treatmentUsed: 'lighter',
      treatmentSource: 'directChoice',
    );
  }
}

void main() {
  group('Evidence age', () {
    test('the frozen window: newest evidence on the window start is still '
        'current; one day earlier is not', () {
      final now = DateTime(2026, 9, 30); // window starts 2 Sep
      expect(insightEvidenceIsCurrent(['2026-08-01', '2026-09-02'], now), isTrue);
      expect(insightEvidenceIsCurrent(['2026-08-01', '2026-09-01'], now), isFalse);
      // A plain current-place fact has no evidence to age out.
      expect(insightEvidenceIsCurrent(const [], now), isTrue);
    });

    test('fresh evidence: the pattern is current and actionable', () async {
      final container = await _container(
        now: _fresh,
        prefs: {insightSnapshotsKey: _blob([_patternSnapshot()])},
      );
      addTearDown(container.dispose);

      expect(container.read(currentInsightProvider), isNotNull);
      expect(container.read(displayedInsightProvider)!.isCurrent, isTrue);
    });

    test('aged-out evidence: never current, but readable as a dated earlier '
        'Insight — Premium and Free alike', () async {
      for (final entitled in [true, false]) {
        final container = await _container(
          now: _agedOut,
          entitled: entitled,
          prefs: {insightSnapshotsKey: _blob([_patternSnapshot()])},
        );
        addTearDown(container.dispose);

        expect(container.read(currentInsightProvider), isNull);
        final displayed = container.read(displayedInsightProvider)!;
        expect(displayed.isCurrent, isFalse, reason: 'entitled: $entitled');
        expect(displayed.insight.observedAt, DateTime(2026, 9, 6, 9));
        // The snapshot itself is preserved.
        expect(container.read(insightProvider).snapshots, hasLength(1));
      }
    });

    test('an aged-out Insight is not actionable: applying is withdrawn, no '
        'Plan change', () async {
      final analytics = _RecordingAnalytics();
      final container = await _container(
        now: _agedOut,
        analytics: analytics,
        prefs: {insightSnapshotsKey: _blob([_patternSnapshot()])},
      );
      addTearDown(container.dispose);

      container.read(insightProvider.notifier).applyCurrent();

      expect(container.read(planProvider).activePlanId, isNull);
      expect(analytics.events, [
        AnalyticsEventType.insightApplicationInvalidated,
      ]);
    });

    test('a still-true pattern re-found on newer dates is re-dated, not '
        'withdrawn as aged-out', () async {
      final container = await _container(now: DateTime(2026, 9, 6));
      container.read(planProvider.notifier).activatePlan(PlanId.clearerHeadPath);
      await _seedLighterChoices(container, [
        '2026-08-12',
        '2026-08-20',
        '2026-08-25',
        '2026-08-30',
        '2026-09-05',
      ]);
      container.read(insightProvider.notifier).refreshIfDue();
      expect(container.read(insightProvider).snapshots, hasLength(1));
      await Future<void>.delayed(Duration.zero);
      final stored = _persisted(container);
      container.dispose();

      // A week later (window from 16 Aug): 12 Aug aged out, 12 Sep arrived —
      // still five choices, the same observation, on newer dates.
      final later = await _container(now: DateTime(2026, 9, 13), prefs: stored);
      addTearDown(later.dispose);
      await _seedLighterChoices(later, ['2026-09-12']);
      later.invalidate(circleJournalRepositoryProvider);
      later.read(insightProvider.notifier).refreshIfDue();

      final snapshots = later.read(insightProvider).snapshots;
      expect(snapshots, hasLength(2));
      expect(snapshots.last.evidenceCount, 5);
      expect(snapshots.last.evidenceDateKeys.last, '2026-09-12');
      expect(later.read(currentInsightProvider), isNotNull);
    });
  });

  group('Dismiss', () {
    test('hides exactly that observation, persists across restart, and '
        'changes no Plan state', () async {
      final container = await _container(
        now: _fresh,
        prefs: {insightSnapshotsKey: _blob([_patternSnapshot()])},
      );
      final planBefore = container.read(planProvider);
      container.read(insightProvider.notifier).dismissLatest();

      expect(container.read(currentInsightProvider), isNull);
      expect(container.read(displayedInsightProvider), isNull);
      expect(container.read(insightProvider).snapshots, hasLength(1));
      expect(container.read(planProvider).activePlanId, planBefore.activePlanId);
      await Future<void>.delayed(Duration.zero);
      final stored = _persisted(container);
      container.dispose();

      final restarted = await _container(now: _fresh, prefs: stored);
      addTearDown(restarted.dispose);
      expect(restarted.read(insightProvider).snapshots.single.dismissed, isTrue);
      expect(restarted.read(displayedInsightProvider), isNull);
    });

    test('old snapshots without the metadata read as not dismissed; '
        'an aged-out dismissed one is not shown as earlier either', () async {
      final legacy = await _container(
        now: _fresh,
        prefs: {insightSnapshotsKey: _blob([_patternSnapshot()])},
      );
      addTearDown(legacy.dispose);
      expect(legacy.read(insightProvider).snapshots.single.dismissed, isFalse);

      final dismissedEarlier = await _container(
        now: _agedOut,
        prefs: {
          insightSnapshotsKey: _blob([_patternSnapshot(dismissed: true)]),
        },
      );
      addTearDown(dismissedEarlier.dispose);
      expect(dismissedEarlier.read(displayedInsightProvider), isNull);
    });

    test('a genuinely new observation shows again; re-finding the dismissed '
        'one does not', () async {
      final container = await _container(now: DateTime(2026, 9, 6));
      container.read(planProvider.notifier).activatePlan(PlanId.clearerHeadPath);
      const dates = [
        '2026-08-10',
        '2026-08-15',
        '2026-08-20',
        '2026-08-25',
        '2026-09-05',
      ];
      await _seedLighterChoices(container, dates);
      final notifier = container.read(insightProvider.notifier);
      notifier.refreshIfDue();
      notifier.dismissLatest();
      expect(container.read(displayedInsightProvider), isNull);

      // Due again, same evidence: the same observation — stays hidden.
      notifier.state = notifier.state.copyWith(lastAssessedAt: DateTime(2000));
      notifier.refreshIfDue();
      expect(container.read(displayedInsightProvider), isNull);

      // A new relevant record: a genuinely new observation (6 choices).
      await _seedLighterChoices(container, ['2026-09-06']);
      container.invalidate(circleJournalRepositoryProvider);
      notifier.state = notifier.state.copyWith(lastAssessedAt: DateTime(2000));
      notifier.refreshIfDue();
      final shown = container.read(displayedInsightProvider);
      expect(shown, isNotNull);
      expect(shown!.insight.evidenceCount, 6);
      container.dispose();
    });
  });

  group('Preserved behaviour', () {
    test('Plan-state withdrawal: a fresh Insight made invalid by Plan state '
        'is withdrawn and not shown as earlier', () async {
      final container = await _container(
        now: _fresh,
        prefs: {insightSnapshotsKey: _blob([_patternSnapshot()])},
      );
      addTearDown(container.dispose);
      expect(container.read(currentInsightProvider), isNotNull);

      container.read(planProvider.notifier).activatePlan(PlanId.clearerHeadPath);

      expect(container.read(currentInsightProvider), isNull);
      expect(container.read(displayedInsightProvider), isNull);
    });

    test('journal deletion clears every snapshot, current or earlier', () async {
      final container = await _container(
        now: _agedOut,
        prefs: {insightSnapshotsKey: _blob([_patternSnapshot()])},
      );
      addTearDown(container.dispose);
      expect(container.read(displayedInsightProvider), isNotNull);

      await container.read(insightProvider.notifier).clearAll();

      expect(container.read(insightProvider).snapshots, isEmpty);
      expect(container.read(displayedInsightProvider), isNull);
    });

    test('the current-place fallback (no evidence dates) never ages out', () async {
      final fact = _patternSnapshot()
        ..['isPatternClaim'] = false
        ..['evidenceCount'] = 0
        ..['evidenceDateKeys'] = <String>[];
      final container = await _container(
        now: DateTime(2027, 6, 1),
        prefs: {insightSnapshotsKey: _blob([fact])},
      );
      addTearDown(container.dispose);
      expect(container.read(displayedInsightProvider)!.isCurrent, isTrue);
    });

    test('thresholds are unchanged', () {
      expect(insightMinRecordCount, 5);
      expect(insightMinDistinctDates, 3);
      expect(insightMinSpanDays, 14);
      expect(insightEvaluationWindowDays, 28);
      expect(insightCadenceDays, 7);
    });
  });

  group('InsightCard', () {
    Future<ProviderContainer> pumpCard(
      WidgetTester tester, {
      required DateTime now,
      bool entitled = true,
    }) async {
      final container = await _container(
        now: now,
        entitled: entitled,
        prefs: {insightSnapshotsKey: _blob([_patternSnapshot()])},
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: SingleChildScrollView(child: InsightCard()),
            ),
          ),
        ),
      );
      return container;
    }

    testWidgets('current: dated "Observed on", "recent" wording, the '
        'application, and Dismiss', (tester) async {
      await pumpCard(tester, now: _fresh);

      expect(find.text('Observed on Sep 6, 2026'), findsOneWidget);
      expect(find.textContaining('5 recent visits'), findsOneWidget);
      expect(find.widgetWithText(ThirtyButton, 'Activate this Plan'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
    });

    testWidgets('earlier (aged-out): "An earlier Insight from", no "recent", '
        'no application — Free and Premium', (tester) async {
      for (final entitled in [true, false]) {
        await pumpCard(tester, now: _agedOut, entitled: entitled);

        expect(find.text('An earlier Insight from Sep 6, 2026'), findsOneWidget);
        expect(find.textContaining('recent'), findsNothing);
        expect(find.textContaining('5 visits'), findsOneWidget);
        expect(find.byType(ThirtyButton), findsNothing);
        expect(find.text('Dismiss'), findsOneWidget);
      }
    });

    testWidgets('tapping Dismiss hides the card', (tester) async {
      final container = await pumpCard(tester, now: _fresh);

      await tester.tap(find.text('Dismiss'));
      await tester.pump();

      expect(find.textContaining('Clearer Head'), findsNothing);
      expect(container.read(insightProvider).snapshots.single.dismissed, isTrue);
    });
  });
}
