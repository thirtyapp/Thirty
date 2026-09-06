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
import 'package:thirty/features/plans/application/plan_provider.dart';
import 'package:thirty/features/plans/domain/plan_catalog.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';
import 'package:thirty/features/plans/domain/plan_state.dart';

class _RecordingAnalyticsService implements AnalyticsService {
  final List<AnalyticsEventType> events = [];

  @override
  void track(AnalyticsEventType type, {Map<String, Object?>? metadata}) {
    events.add(type);
  }
}

final _today = DateTime(2026, 8, 2, 9);

Future<ProviderContainer> _containerWith({
  Map<String, Object> storedPrefs = const {},
  bool entitled = true,
  AnalyticsService? analytics,
}) async {
  SharedPreferences.setMockInitialValues(storedPrefs);
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_today),
      eventClockProvider.overrideWithValue(() => _today),
      premiumEntitlementProvider.overrideWithValue(entitled),
      if (analytics != null)
        analyticsServiceProvider.overrideWithValue(analytics),
    ],
  );
  return container;
}

void main() {
  group('PlanNotifier — initial state', () {
    test('all three Plans start with a fresh PlanProgress and no active '
        'Plan', () async {
      final container = await _containerWith();
      addTearDown(container.dispose);

      final state = container.read(planProvider);
      expect(state.activePlanId, isNull);
      expect(state.progress.keys.toSet(), PlanId.values.toSet());
      for (final progress in state.progress.values) {
        expect(progress.forwardCursor, 0);
        expect(progress.status, PlanCycleStatus.inProgress);
        expect(progress.lastEncounteredStageId, isNull);
        expect(progress.pendingRevisit, isFalse);
        expect(progress.cycleHistory, isEmpty);
      }
    });
  });

  group('activatePlan / deactivatePlan', () {
    test('activating a Plan sets it active without mutating its progress',
        () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);

      notifier.activatePlan(PlanId.moreEnergyPath);

      expect(container.read(planProvider).activePlanId, PlanId.moreEnergyPath);
      expect(
        notifier.progressFor(PlanId.moreEnergyPath).forwardCursor,
        0,
      );
    });

    test('switching to a different Plan preserves the previous Plan\'s own '
        'saved position', () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);

      notifier.activatePlan(PlanId.moreEnergyPath);
      notifier.advanceCursorForCircle(
        PlanId.moreEnergyPath,
        'circle-1',
        isRevisit: false,
      );
      expect(notifier.progressFor(PlanId.moreEnergyPath).forwardCursor, 1);

      notifier.activatePlan(PlanId.clearerHeadPath);

      expect(container.read(planProvider).activePlanId, PlanId.clearerHeadPath);
      // moreEnergyPath's own progress is untouched by switching away.
      expect(notifier.progressFor(PlanId.moreEnergyPath).forwardCursor, 1);
      expect(notifier.progressFor(PlanId.clearerHeadPath).forwardCursor, 0);
    });

    test('activating the already-active Plan is a no-op (no duplicate '
        'analytics)', () async {
      final analytics = _RecordingAnalyticsService();
      final container = await _containerWith(analytics: analytics);
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);

      notifier.activatePlan(PlanId.moreEnergyPath);
      notifier.activatePlan(PlanId.moreEnergyPath);

      expect(
        analytics.events.where((e) => e == AnalyticsEventType.planStarted),
        hasLength(1),
      );
    });

    test('deactivatePlan clears the active Plan but preserves its '
        'progress', () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);

      notifier.activatePlan(PlanId.moreEnergyPath);
      notifier.advanceCursorForCircle(
        PlanId.moreEnergyPath,
        'circle-1',
        isRevisit: false,
      );
      notifier.deactivatePlan();

      expect(container.read(planProvider).activePlanId, isNull);
      expect(notifier.progressFor(PlanId.moreEnergyPath).forwardCursor, 1);
    });
  });

  group('forward cursor vs. one-off revisit — independence', () {
    test('queueRevisit does nothing before any stage has ever been '
        'encountered', () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);

      notifier.queueRevisit();

      expect(
        notifier.progressFor(PlanId.moreEnergyPath).pendingRevisit,
        isFalse,
      );
    });

    test('queueRevisit sets pendingRevisit without touching forwardCursor',
        () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);
      notifier.advanceCursorForCircle(
        PlanId.moreEnergyPath,
        'circle-1',
        isRevisit: false,
      );

      notifier.queueRevisit();

      final progress = notifier.progressFor(PlanId.moreEnergyPath);
      expect(progress.pendingRevisit, isTrue);
      expect(progress.forwardCursor, 1);
    });

    test('clearQueuedRevisit clears it before it applies to any Circle',
        () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);
      notifier.advanceCursorForCircle(
        PlanId.moreEnergyPath,
        'circle-1',
        isRevisit: false,
      );
      notifier.queueRevisit();

      notifier.clearQueuedRevisit();

      expect(
        notifier.progressFor(PlanId.moreEnergyPath).pendingRevisit,
        isFalse,
      );
    });

    test('resolveSessionFor consumes the queued revisit and returns the '
        'last encountered stage, without moving forwardCursor', () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);
      // Advance through stage 0 and 1 so lastEncounteredStageId is stage 1.
      notifier.advanceCursorForCircle(
        PlanId.moreEnergyPath,
        'circle-1',
        isRevisit: false,
      );
      final stage1Id = notifier
          .progressFor(PlanId.moreEnergyPath)
          .lastEncounteredStageId;
      notifier.queueRevisit();

      final assignment = notifier.resolveSessionFor(Intention.moreEnergy);

      expect(assignment, isNotNull);
      expect(assignment!.isRevisit, isTrue);
      expect(assignment.stageId, stage1Id);
      // Forward cursor is untouched by the revisit resolution itself.
      expect(notifier.progressFor(PlanId.moreEnergyPath).forwardCursor, 1);
      expect(
        notifier.progressFor(PlanId.moreEnergyPath).pendingRevisit,
        isFalse,
      );
    });

    test('after a revisit is used, forward progression resumes from the '
        'previously saved cursor', () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);
      notifier.advanceCursorForCircle(
        PlanId.moreEnergyPath,
        'circle-1',
        isRevisit: false,
      );
      notifier.queueRevisit();
      final revisitAssignment = notifier.resolveSessionFor(
        Intention.moreEnergy,
      );
      notifier.advanceCursorForCircle(
        PlanId.moreEnergyPath,
        'revisit-circle',
        isRevisit: revisitAssignment!.isRevisit,
      );

      // Next resolution (a new, unrelated Circle) must return the ordinary
      // forward stage (index 1), not another revisit and not stage 0 again.
      final nextAssignment = notifier.resolveSessionFor(Intention.moreEnergy);

      expect(nextAssignment, isNotNull);
      expect(nextAssignment!.isRevisit, isFalse);
      expect(
        nextAssignment.stageId,
        stageAt(PlanId.moreEnergyPath, 1).id,
      );
    });

    test('a stale/invalid lastEncounteredStageId revisit target is '
        'skipped in favor of ordinary forward progression', () async {
      // Simulate a corrupted pendingRevisit pointing at a stage id that no
      // longer exists in the catalogue.
      final container = await _containerWith(
        storedPrefs: {
          plansStateKey: jsonEncode({
            'schemaVersion': plansStateSchemaVersion,
            'activePlanId': PlanId.moreEnergyPath.name,
            'progress': {
              for (final id in PlanId.values)
                id.name: {
                  'planId': id.name,
                  'contentVersion': planContentVersion,
                  'cycleId': '${id.name}_cycle_1',
                  'cycleStartedAt': _today.toIso8601String(),
                  'forwardCursor': 1,
                  'lastEncounteredStageId': id == PlanId.moreEnergyPath
                      ? 'not_a_real_stage'
                      : null,
                  'pendingRevisit': id == PlanId.moreEnergyPath,
                  'status': PlanCycleStatus.inProgress.name,
                  'cycleHistory': <Object?>[],
                  'lastAdvancedCircleId': null,
                },
            },
          }),
        },
      );
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);

      // The per-Plan fail-safe restore should have reset moreEnergyPath to
      // fresh entirely, since its lastEncounteredStageId is incompatible.
      final progress = notifier.progressFor(PlanId.moreEnergyPath);
      expect(progress.forwardCursor, 0);
      expect(progress.pendingRevisit, isFalse);
    });
  });

  group('resolveSessionFor — daily resolution rule', () {
    test('returns null without entitlement even with a matching active '
        'Plan', () async {
      final container = await _containerWith(entitled: false);
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);

      expect(notifier.resolveSessionFor(Intention.moreEnergy), isNull);
    });

    test('returns null when no Plan is active', () async {
      final container = await _containerWith();
      addTearDown(container.dispose);

      expect(
        container
            .read(planProvider.notifier)
            .resolveSessionFor(Intention.moreEnergy),
        isNull,
      );
    });

    test('returns null for a non-matching direction', () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);

      expect(notifier.resolveSessionFor(Intention.clearerHead), isNull);
    });

    test('returns the stage at forwardCursor for a fresh matching Plan',
        () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);

      final assignment = notifier.resolveSessionFor(Intention.moreEnergy);

      expect(assignment, isNotNull);
      expect(assignment!.stageId, stageAt(PlanId.moreEnergyPath, 0).id);
      expect(assignment.activityId, stageAt(PlanId.moreEnergyPath, 0).activityId);
      expect(assignment.isRevisit, isFalse);
    });

    test('fires exactly one planSessionShown event per resolution',
        () async {
      final analytics = _RecordingAnalyticsService();
      final container = await _containerWith(analytics: analytics);
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);

      notifier.resolveSessionFor(Intention.moreEnergy);

      expect(
        analytics.events
            .where((e) => e == AnalyticsEventType.planSessionShown),
        hasLength(1),
      );
    });
  });

  group('advanceCursorForCircle — progression', () {
    test('advances the cursor by exactly one on a real close', () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);

      notifier.advanceCursorForCircle(
        PlanId.moreEnergyPath,
        'circle-1',
        isRevisit: false,
      );

      final progress = notifier.progressFor(PlanId.moreEnergyPath);
      expect(progress.forwardCursor, 1);
      expect(progress.lastEncounteredStageId, stageAt(PlanId.moreEnergyPath, 0).id);
    });

    test('is idempotent: the same circleId can never advance the cursor '
        'twice', () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);

      notifier.advanceCursorForCircle(
        PlanId.moreEnergyPath,
        'circle-1',
        isRevisit: false,
      );
      notifier.advanceCursorForCircle(
        PlanId.moreEnergyPath,
        'circle-1',
        isRevisit: false,
      );

      expect(notifier.progressFor(PlanId.moreEnergyPath).forwardCursor, 1);
    });

    test('a revisit-sourced advance never moves the cursor, only records '
        'idempotency', () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);
      notifier.advanceCursorForCircle(
        PlanId.moreEnergyPath,
        'circle-1',
        isRevisit: false,
      );

      notifier.advanceCursorForCircle(
        PlanId.moreEnergyPath,
        'revisit-circle',
        isRevisit: true,
      );

      expect(notifier.progressFor(PlanId.moreEnergyPath).forwardCursor, 1);
    });

    test('advancing past stage 5 completes the cycle and fires exactly '
        'one planCycleCompleted event, with no auto-restart', () async {
      final analytics = _RecordingAnalyticsService();
      final container = await _containerWith(analytics: analytics);
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);

      for (var i = 0; i < 5; i++) {
        notifier.advanceCursorForCircle(
          PlanId.moreEnergyPath,
          'circle-$i',
          isRevisit: false,
        );
      }

      final progress = notifier.progressFor(PlanId.moreEnergyPath);
      expect(progress.status, PlanCycleStatus.completed);
      expect(progress.forwardCursor, 5);
      expect(
        analytics.events
            .where((e) => e == AnalyticsEventType.planCycleCompleted),
        hasLength(1),
      );
      // No auto-restart: resolveSessionFor now falls through to null.
      expect(notifier.resolveSessionFor(Intention.moreEnergy), isNull);
    });
  });

  group('repeatCycle', () {
    test('is a no-op while the current cycle is still in progress',
        () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);
      final before = notifier.progressFor(PlanId.moreEnergyPath).cycleId;

      notifier.repeatCycle(PlanId.moreEnergyPath);

      expect(notifier.progressFor(PlanId.moreEnergyPath).cycleId, before);
    });

    test('creates a new cycleId, resets the cursor, and preserves the '
        'finished cycle in history', () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);
      final firstCycleId = notifier.progressFor(PlanId.moreEnergyPath).cycleId;
      for (var i = 0; i < 5; i++) {
        notifier.advanceCursorForCircle(
          PlanId.moreEnergyPath,
          'circle-$i',
          isRevisit: false,
        );
      }

      notifier.repeatCycle(PlanId.moreEnergyPath);

      final progress = notifier.progressFor(PlanId.moreEnergyPath);
      expect(progress.cycleId, isNot(firstCycleId));
      expect(progress.forwardCursor, 0);
      expect(progress.status, PlanCycleStatus.inProgress);
      expect(progress.cycleHistory, hasLength(1));
      expect(progress.cycleHistory.single.cycleId, firstCycleId);
    });

    test('the repeated Plan resolves stage 0 again on the next matching '
        'day', () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);
      for (var i = 0; i < 5; i++) {
        notifier.advanceCursorForCircle(
          PlanId.moreEnergyPath,
          'circle-$i',
          isRevisit: false,
        );
      }
      notifier.repeatCycle(PlanId.moreEnergyPath);

      final assignment = notifier.resolveSessionFor(Intention.moreEnergy);

      expect(assignment, isNotNull);
      expect(assignment!.stageId, stageAt(PlanId.moreEnergyPath, 0).id);
    });
  });

  group('persistence / restore', () {
    test('state persists across a fresh container (simulated app '
        'restart)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container1 = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          nowProvider.overrideWithValue(_today),
          eventClockProvider.overrideWithValue(() => _today),
          premiumEntitlementProvider.overrideWithValue(true),
        ],
      );
      container1.read(planProvider.notifier).activatePlan(PlanId.gentlerPacePath);
      container1
          .read(planProvider.notifier)
          .advanceCursorForCircle(PlanId.gentlerPacePath, 'circle-1', isRevisit: false);
      container1.dispose();

      final container2 = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          nowProvider.overrideWithValue(_today),
          eventClockProvider.overrideWithValue(() => _today),
          premiumEntitlementProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container2.dispose);

      final state = container2.read(planProvider);
      expect(state.activePlanId, PlanId.gentlerPacePath);
      expect(
        state.progress[PlanId.gentlerPacePath]!.forwardCursor,
        1,
      );
    });

    test('a corrupt top-level stored value resets every Plan to fresh, '
        'never throws', () async {
      final container = await _containerWith(
        storedPrefs: {plansStateKey: 'not json at all'},
      );
      addTearDown(container.dispose);

      final state = container.read(planProvider);
      expect(state.activePlanId, isNull);
      for (final progress in state.progress.values) {
        expect(progress.forwardCursor, 0);
      }
    });

    test('an incompatible contentVersion for one Plan resets only that '
        'Plan, leaving the other two intact', () async {
      final container = await _containerWith(
        storedPrefs: {
          plansStateKey: jsonEncode({
            'schemaVersion': plansStateSchemaVersion,
            'activePlanId': null,
            'progress': {
              PlanId.moreEnergyPath.name: {
                'planId': PlanId.moreEnergyPath.name,
                'contentVersion': 999, // incompatible future version
                'cycleId': 'x',
                'cycleStartedAt': _today.toIso8601String(),
                'forwardCursor': 3,
                'lastEncounteredStageId': null,
                'pendingRevisit': false,
                'status': PlanCycleStatus.inProgress.name,
                'cycleHistory': <Object?>[],
                'lastAdvancedCircleId': null,
              },
              PlanId.clearerHeadPath.name: {
                'planId': PlanId.clearerHeadPath.name,
                'contentVersion': planContentVersion,
                'cycleId': 'ok-cycle',
                'cycleStartedAt': _today.toIso8601String(),
                'forwardCursor': 2,
                'lastEncounteredStageId': stageAt(PlanId.clearerHeadPath, 1).id,
                'pendingRevisit': false,
                'status': PlanCycleStatus.inProgress.name,
                'cycleHistory': <Object?>[],
                'lastAdvancedCircleId': null,
              },
              PlanId.gentlerPacePath.name: {
                'planId': PlanId.gentlerPacePath.name,
                'contentVersion': planContentVersion,
                'cycleId': 'ok-cycle-2',
                'cycleStartedAt': _today.toIso8601String(),
                'forwardCursor': 0,
                'lastEncounteredStageId': null,
                'pendingRevisit': false,
                'status': PlanCycleStatus.inProgress.name,
                'cycleHistory': <Object?>[],
                'lastAdvancedCircleId': null,
              },
            },
          }),
        },
      );
      addTearDown(container.dispose);

      final notifier = container.read(planProvider.notifier);
      expect(notifier.progressFor(PlanId.moreEnergyPath).forwardCursor, 0);
      expect(notifier.progressFor(PlanId.clearerHeadPath).forwardCursor, 2);
    });

    test('an invalid persisted activePlanId falls back to no active Plan',
        () async {
      final container = await _containerWith(
        storedPrefs: {
          plansStateKey: jsonEncode({
            'schemaVersion': plansStateSchemaVersion,
            'activePlanId': 'not_a_real_plan_id',
            'progress': {
              for (final id in PlanId.values)
                id.name: {
                  'planId': id.name,
                  'contentVersion': planContentVersion,
                  'cycleId': '${id.name}_cycle_1',
                  'cycleStartedAt': _today.toIso8601String(),
                  'forwardCursor': 0,
                  'lastEncounteredStageId': null,
                  'pendingRevisit': false,
                  'status': PlanCycleStatus.inProgress.name,
                  'cycleHistory': <Object?>[],
                  'lastAdvancedCircleId': null,
                },
            },
          }),
        },
      );
      addTearDown(container.dispose);

      expect(container.read(planProvider).activePlanId, isNull);
    });
  });

  group('setLighterDefaultForPlan — Batch 2B (ADR-015)', () {
    test('enables the persistent default and persists it across a fresh '
        'container (simulated restart)', () async {
      final container = await _containerWith();
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);

      notifier.setLighterDefaultForPlan(PlanId.moreEnergyPath, true);
      expect(
        notifier.progressFor(PlanId.moreEnergyPath).lighterDefault,
        isTrue,
      );

      await Future<void>.delayed(Duration.zero);
      final prefs = container.read(sharedPreferencesProvider);
      final restored = <String, Object>{
        for (final key in prefs.getKeys())
          if (prefs.get(key) != null) key: prefs.get(key)!,
      };
      container.dispose();

      final container2 = await _containerWith(storedPrefs: restored);
      addTearDown(container2.dispose);
      expect(
        container2
            .read(planProvider.notifier)
            .progressFor(PlanId.moreEnergyPath)
            .lighterDefault,
        isTrue,
      );
    });

    test('disables it again (reversible)', () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);
      notifier.setLighterDefaultForPlan(PlanId.moreEnergyPath, true);

      notifier.setLighterDefaultForPlan(PlanId.moreEnergyPath, false);

      expect(
        notifier.progressFor(PlanId.moreEnergyPath).lighterDefault,
        isFalse,
      );
    });

    test('is a no-op when already set to the requested value (no duplicate '
        'analytics)', () async {
      final analytics = _RecordingAnalyticsService();
      final container = await _containerWith(analytics: analytics);
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);

      notifier.setLighterDefaultForPlan(PlanId.moreEnergyPath, true);
      notifier.setLighterDefaultForPlan(PlanId.moreEnergyPath, true);

      expect(
        analytics.events
            .where((e) => e == AnalyticsEventType.coachApplicationAccepted),
        hasLength(1),
      );
    });

    test('a repeated cycle inherits the current saved default', () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);
      notifier.setLighterDefaultForPlan(PlanId.moreEnergyPath, true);
      for (var i = 0; i < 5; i++) {
        notifier.advanceCursorForCircle(
          PlanId.moreEnergyPath,
          'circle-$i',
          isRevisit: false,
        );
      }

      notifier.repeatCycle(PlanId.moreEnergyPath);

      expect(
        notifier.progressFor(PlanId.moreEnergyPath).lighterDefault,
        isTrue,
      );
    });

    test('a future resolveSessionFor call respects the saved default as '
        'PlanTreatment.lighter with source savedPreference', () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);
      notifier.setLighterDefaultForPlan(PlanId.moreEnergyPath, true);

      final assignment = notifier.resolveSessionFor(Intention.moreEnergy);

      expect(assignment, isNotNull);
      expect(assignment!.initialTreatment, PlanTreatment.lighter);
      expect(assignment.treatmentSource, PlanTreatmentSource.savedPreference);
    });

    test('without a saved default, resolveSessionFor uses standard '
        'treatment with source ordinaryDefault', () async {
      final container = await _containerWith();
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);

      final assignment = notifier.resolveSessionFor(Intention.moreEnergy);

      expect(assignment, isNotNull);
      expect(assignment!.initialTreatment, PlanTreatment.standard);
      expect(assignment.treatmentSource, PlanTreatmentSource.ordinaryDefault);
    });
  });

}
