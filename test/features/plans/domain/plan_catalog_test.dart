import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/plans/domain/plan_catalog.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';

void main() {
  group('planCatalog (Batch 2A content contract)', () {
    test('has exactly 3 Plans', () {
      expect(planCatalog.length, 3);
      expect(planCatalog.keys.toSet(), PlanId.values.toSet());
    });

    test('every Plan has exactly 5 stages — 15 stage definitions total', () {
      var total = 0;
      for (final plan in planCatalog.values) {
        expect(plan.stages, hasLength(5));
        total += plan.stages.length;
      }
      expect(total, 15);
    });

    test('each Plan aligns with a distinct existing direction', () {
      final directions = PlanId.values.map(planDirection).toSet();
      expect(directions, Intention.values.toSet());
    });

    test('every stage id is unique within its own Plan', () {
      for (final plan in planCatalog.values) {
        final ids = plan.stages.map((s) => s.id).toList();
        expect(ids.toSet(), hasLength(ids.length));
      }
    });

    test('every stage id is unique across all Plans (globally stable)', () {
      final allIds = [
        for (final plan in planCatalog.values) ...plan.stages.map((s) => s.id),
      ];
      expect(allIds.toSet(), hasLength(allIds.length));
    });

    test('every stage\'s activityId belongs to its Plan\'s own direction '
        'pool', () {
      for (final entry in planCatalog.entries) {
        final pool = activityPools[planDirection(entry.key)]!;
        for (final stage in entry.value.stages) {
          expect(
            pool.contains(stage.activityId),
            isTrue,
            reason:
                '${stage.id} assigns ${stage.activityId}, which is not in '
                '${planDirection(entry.key)}\'s pool',
          );
        }
      }
    });

    test('no stage introduces an ActivityId outside the existing Free '
        'catalogue', () {
      final catalogueIds = activityCatalog.keys.toSet();
      for (final plan in planCatalog.values) {
        for (final stage in plan.stages) {
          expect(catalogueIds.contains(stage.activityId), isTrue);
        }
      }
    });

    test('every required copy field is non-empty for every stage', () {
      for (final plan in planCatalog.values) {
        expect(plan.name, isNotEmpty);
        expect(plan.purpose, isNotEmpty);
        for (final stage in plan.stages) {
          expect(stage.purpose, isNotEmpty);
          expect(stage.rationale, isNotEmpty);
          expect(stage.standardGuidance, isNotEmpty);
          expect(stage.lighterGuidance, isNotEmpty);
        }
      }
    });

    test('standard and lighter guidance are distinct texts for every '
        'stage', () {
      for (final plan in planCatalog.values) {
        for (final stage in plan.stages) {
          expect(stage.standardGuidance, isNot(stage.lighterGuidance));
        }
      }
    });

    test('stage 4 (purposeful revisit) reuses an earlier stage\'s '
        'activityId in every Plan — an explicit, structural callback, not '
        'coincidence', () {
      for (final plan in planCatalog.values) {
        final earlierActivityIds = plan.stages
            .take(3)
            .map((s) => s.activityId)
            .toSet();
        expect(earlierActivityIds.contains(plan.stages[3].activityId), isTrue);
      }
    });

    test('stages 1, 2, 3 and 5 use four mutually distinct activities per '
        'Plan', () {
      for (final plan in planCatalog.values) {
        final nonRevisitIds = [
          plan.stages[0].activityId,
          plan.stages[1].activityId,
          plan.stages[2].activityId,
          plan.stages[4].activityId,
        ];
        expect(nonRevisitIds.toSet(), hasLength(4));
      }
    });

    test('every stage carries the current planContentVersion', () {
      for (final plan in planCatalog.values) {
        expect(plan.version, planContentVersion);
        for (final stage in plan.stages) {
          expect(stage.contentVersion, planContentVersion);
        }
      }
    });

    test('no Plan/stage copy makes a fitness, mental-health, or sleep/'
        'stress treatment claim', () {
      const forbiddenPhrases = [
        'guarantee',
        'cure',
        'diagnos',
        'treat your',
        'fix your',
        'proven to',
        'improves your health',
      ];
      for (final plan in planCatalog.values) {
        for (final text in [
          plan.purpose,
          ...plan.stages.map((s) => s.purpose),
          ...plan.stages.map((s) => s.rationale),
          ...plan.stages.map((s) => s.standardGuidance),
          ...plan.stages.map((s) => s.lighterGuidance),
        ]) {
          final lower = text.toLowerCase();
          for (final phrase in forbiddenPhrases) {
            expect(
              lower.contains(phrase),
              isFalse,
              reason: '"$text" contains forbidden phrase "$phrase"',
            );
          }
        }
      }
    });
  });

  group('planDefinitionFor / stageAt / findStage', () {
    test('planDefinitionFor returns the matching PlanDefinition', () {
      expect(planDefinitionFor(PlanId.moreEnergyPath).id, PlanId.moreEnergyPath);
    });

    test('stageAt indexes directly into the ordered stage list', () {
      final plan = planDefinitionFor(PlanId.clearerHeadPath);
      expect(stageAt(PlanId.clearerHeadPath, 0), plan.stages[0]);
      expect(stageAt(PlanId.clearerHeadPath, 4), plan.stages[4]);
    });

    test('findStage locates a real stage by id', () {
      final stage = findStage(PlanId.gentlerPacePath, 'gentler_pace_3_apply');
      expect(stage, isNotNull);
      expect(stage!.id, 'gentler_pace_3_apply');
    });

    test('findStage returns null for an unknown/stale stage id', () {
      expect(findStage(PlanId.gentlerPacePath, 'not_a_real_stage'), isNull);
    });

    test('findStage returns null when the stage id belongs to a different '
        'Plan', () {
      expect(
        findStage(PlanId.gentlerPacePath, 'more_energy_1_establish'),
        isNull,
      );
    });
  });
}
