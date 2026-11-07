import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';

/// R8.3 — invariant V, serialization fidelity, as a law over the persisted
/// record types: what THIRTY holds as confirmed is what it writes, and
/// what it writes reads back the same.
///
/// - Astra R82-N03 / Claude AUD-N1: a known field THIRTY sets on a record
///   it read (the expiry note on a served stage Circle) must be written as
///   it now is — including false, which is its absence.
/// - Astra R82-N04: a whole, readable Insight-provenance record keeps the
///   fields this build doesn't know.
///
/// Every other row is a control: it holds on R8.2 and must keep holding.
void main() {
  Object? reencode(Object? json) => jsonDecode(jsonEncode(json));

  const stage = <String, Object?>{
    'planId': 'getting_going',
    'cycleId': 'getting_going#1',
    'stageNumber': 1,
    'stageId': 'getting_going.1',
  };

  group('ServedStageCircle — known fields are what the model says', () {
    test('R82-N03 / AUD-N1: a stored expiry note of true, cleared by a '
        'later Start under verified Premium, is written as cleared', () {
      final raw = <String, Object?>{
        'circleId': '2026-10-30',
        'stage': stage,
        'startedAfterExpiry': true,
      };
      final cleared = ServedStageCircle.fromJson(raw)!.copyWith(
        startedAfterExpiry: false,
      );
      expect(cleared.startedAfterExpiry, isFalse);
      final again = ServedStageCircle.fromJson(reencode(cleared.toJson()))!;
      expect(
        again.startedAfterExpiry,
        isFalse,
        reason: 'the confirmed model says false; the bytes say true',
      );
    });

    test('R82-N03 / AUD-N1 through the Plans: noteStart under verified '
        'Premium on a record read from disk credits after a restart', () {
      var plans = CirclePlansState.empty.start(
        'getting_going',
        today: '2026-10-30',
      )!;
      final json = reencode(plans.toJson())! as Map<String, Object?>;
      ((json['plans'] as Map)['getting_going'] as Map)['lastServed'] = {
        'circleId': '2026-10-30',
        'stage': stage,
        'startedAfterExpiry': true,
      };
      plans = CirclePlansState.fromJson(json)!;
      final provenance = plans.plans['getting_going']!.lastServed!.stage;
      final noted = plans.noteStart(
        provenance,
        circleId: '2026-10-30',
        active: true,
      );
      expect(noted.creditsServed(provenance, circleId: '2026-10-30'), isTrue);
      final restarted = CirclePlansState.fromJson(reencode(noted.toJson()))!;
      expect(
        restarted.creditsServed(provenance, circleId: '2026-10-30'),
        isTrue,
        reason: 'started under Premium in memory, after expiry on disk',
      );
    });

    test('control: true is written and read back as true', () {
      final noted = ServedStageCircle.fromJson({
        'circleId': '2026-10-30',
        'stage': stage,
      })!.copyWith(startedAfterExpiry: true);
      expect(
        ServedStageCircle.fromJson(reencode(noted.toJson()))!
            .startedAfterExpiry,
        isTrue,
      );
    });

    test('control: the lifecycle stamps are written as set, and unknown '
        'fields of the record are kept', () {
      final raw = <String, Object?>{
        'circleId': '2026-10-30',
        'stage': stage,
        'futureNote': {'kept': true},
      };
      final stamped = ServedStageCircle.fromJson(raw)!.copyWith(
        startedBeforePause: '2026-10-30T08:00:00.000Z',
        closedBeforeLeave: '2026-10-30T08:30:00.000Z',
      );
      final out = reencode(stamped.toJson())! as Map<String, Object?>;
      expect(out['futureNote'], {'kept': true});
      expect(out['startedBeforePause'], '2026-10-30T08:00:00.000Z');
      expect(out['closedBeforeLeave'], '2026-10-30T08:30:00.000Z');
      expect(out.containsKey('startedAfterExpiry'), isFalse);
    });

    test('control: the stored stage is written back as stored (R8.2 A05), '
        'its unknown fields too', () {
      final storedStage = {...stage, 'futureStageField': 1};
      final raw = {'circleId': '2026-10-30', 'stage': storedStage};
      final out = reencode(ServedStageCircle.fromJson(raw)!.toJson());
      expect((out! as Map)['stage'], storedStage);
    });

    test('control: a damaged flag still makes the record unreadable', () {
      expect(
        ServedStageCircle.fromJson({
          'circleId': '2026-10-30',
          'stage': stage,
          'startedAfterExpiry': 'yes',
        }),
        isNull,
      );
    });
  });

  group('AppliedInsight — a whole record keeps what it does not know', () {
    test('R82-N04: a valid record with an extension field writes it back', () {
      final raw = <String, Object?>{
        'insightId': 'I1@2026-10-30',
        'cycleId': 'making_room#1',
        'on': '2026-10-30',
        'futureProvenance': <String, Object?>{'reason': 'retain exactly'},
      };
      expect(reencode(AppliedInsight.fromJson(raw)!.toJson()), raw);
    });

    test('R82-N04 through the Plans: an unrelated Plan change keeps the '
        'extension', () {
      final plans = CirclePlansState.empty.start(
        'making_room',
        today: '2026-10-30',
      )!;
      final json = reencode(plans.toJson())! as Map<String, Object?>;
      final record = <String, Object?>{
        'insightId': 'I1@2026-10-30',
        'cycleId': 'making_room#1',
        'on': '2026-10-30',
        'futureProvenance': 'kept',
      };
      ((json['plans'] as Map)['making_room'] as Map)['appliedInsight'] =
          record;
      final paused = CirclePlansState.fromJson(json)!.pause('making_room')!;
      final out = reencode(paused.toJson())! as Map;
      expect(((out['plans'] as Map)['making_room'] as Map)['appliedInsight'],
          record);
    });

    test('control: a new record is exactly its three fields', () {
      const applied = AppliedInsight(
        insightId: 'I2@2026-10-30',
        cycleId: 'getting_going#1',
        on: '2026-10-30',
      );
      expect(applied.toJson(), {
        'insightId': 'I2@2026-10-30',
        'cycleId': 'getting_going#1',
        'on': '2026-10-30',
      });
    });

    test('control: a damaged record attributes nothing and is kept as '
        'stored by its Plan', () {
      final plans = CirclePlansState.empty.start(
        'making_room',
        today: '2026-10-30',
      )!;
      final json = reencode(plans.toJson())! as Map<String, Object?>;
      final damaged = {'insightId': 'I1@x', 'on': 'yesterday'};
      ((json['plans'] as Map)['making_room'] as Map)['appliedInsight'] =
          damaged;
      final read = CirclePlansState.fromJson(json)!;
      expect(read.plans['making_room']!.appliedInsight, isNull);
      final out = reencode(read.toJson())! as Map;
      expect(((out['plans'] as Map)['making_room'] as Map)['appliedInsight'],
          damaged);
    });
  });

  group('controls — every other persisted record round-trips', () {
    CirclePlansState plansWithEverything() {
      var s = CirclePlansState.empty.start('getting_going', today: '2026-10-01')!;
      final served = PlanStageProvenanceJson.stage;
      s = s.served(served, circleId: '2026-10-02');
      s = s.recordGuided(
        served,
        circleId: '2026-10-02',
        today: '2026-10-02',
        parts: const ['openWindow:3'],
        skipped: const [],
      );
      s = s.keepGentler('getting_going', today: '2026-10-03')!;
      s = s.start('making_room', today: '2026-10-04')!;
      return s;
    }

    test('CirclePlansState, PlanProgress, PlanCycle and StageRecord: '
        'decode ∘ encode is the identity on THIRTY\'s own bytes', () {
      final json = reencode(plansWithEverything().toJson());
      expect(reencode(CirclePlansState.fromJson(json)!.toJson()), json);
    });

    test('CirclePlansState, PlanProgress, PlanCycle and StageRecord keep '
        'unknown fields through a change', () {
      final json =
          reencode(plansWithEverything().toJson())! as Map<String, Object?>;
      json['futureTop'] = 1;
      final plan = (json['plans'] as Map)['getting_going'] as Map;
      plan['futurePlan'] = 2;
      final cycle = (plan['cycles'] as List).first as Map;
      cycle['futureCycle'] = 3;
      ((cycle['records'] as List).first as Map)['futureRecord'] = 4;
      final changed = CirclePlansState.fromJson(json)!.pause('making_room')!;
      final out = reencode(changed.toJson())! as Map;
      expect(out['futureTop'], 1);
      final outPlan = (out['plans'] as Map)['getting_going'] as Map;
      expect(outPlan['futurePlan'], 2);
      final outCycle = (outPlan['cycles'] as List).first as Map;
      expect(outCycle['futureCycle'], 3);
      expect(((outCycle['records'] as List).first as Map)['futureRecord'], 4);
    });

    test('InsightSnapshot and InsightsState: decode ∘ encode is the '
        'identity, unknown fields kept', () {
      final snapshot = <String, Object?>{
        'id': 'I3@2026-10-30',
        'family': InsightFamily.skippedPart.id,
        'generatedOn': '2026-10-30',
        'wordingVersion': 1,
        'text': 'You often skip Open a window.',
        'facts': {'element': 'openWindow'},
        'evidence': ['2026-10-29'],
        'subject': 'openWindow',
        'application': const LeaveOutPart('openWindow').toJson(),
        'appliedOn': '2026-10-30',
        'futureSnapshot': true,
      };
      final state = InsightsState.fromJson(
        reencode({
          'schemaVersion': insightsSchemaVersion,
          'snapshots': [snapshot],
        }),
      );
      expect(state, isNotNull);
      final out = reencode(state!.toJson())! as Map;
      expect((out['snapshots'] as List).single, snapshot);
    });

    test('Suggestion Preferences and their items: decode ∘ encode is the '
        'identity, unknown fields kept', () {
      final stored = <String, Object?>{
        'schemaVersion': suggestionPreferencesSchemaVersion,
        'notSuggested': [
          {
            'activityId': ActivityId.values.first.name,
            'need': Intention.moreEnergy.name,
            'since': '2026-10-01T09:00:00.000',
            'futureItem': 1,
          },
        ],
        'restsLifted': [
          {
            'activityId': ActivityId.values.first.name,
            'need': Intention.clearerHead.name,
            'at': '2026-10-02T09:00:00.000',
          },
        ],
        'elementsLeftOut': [
          {
            'elementId': ElementId.openWindow.name,
            'since': '2026-10-03T09:00:00.000',
            'byInsight': 'I3@2026-10-03',
            'futureItem': 2,
          },
        ],
        'futureTop': 3,
      };
      final read = SuggestionPreferences.tryRead(jsonEncode(stored));
      expect(read, isNotNull);
      expect(reencode(read!.toJson()), stored);
    });
  });
}

/// The stage provenance the controls serve and credit.
abstract final class PlanStageProvenanceJson {
  static final stage = ServedStageCircle.fromJson({
    'circleId': '2026-10-02',
    'stage': {
      'planId': 'getting_going',
      'cycleId': 'getting_going#1',
      'stageNumber': 1,
      'stageId': 'getting_going.1',
    },
  })!.stage;
}
