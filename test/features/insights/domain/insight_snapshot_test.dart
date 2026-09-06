import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/insights/domain/insight_family.dart';
import 'package:thirty/features/insights/domain/insight_snapshot.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';

void main() {
  group('InsightSnapshot — round-trip', () {
    test('toJson/fromJson round-trips every field', () {
      final snapshot = InsightSnapshot(
        id: 'a',
        family: InsightFamily.chosenPacing,
        applicationType: InsightApplicationType.setLighterDefault,
        targetPlanId: PlanId.clearerHeadPath,
        generatedAt: DateTime(2026, 9, 1),
        ruleVersion: insightRuleVersion,
        templateVersion: insightTemplateVersion,
        isPatternClaim: true,
        evidenceCount: 5,
        evidenceDateKeys: const ['2026-08-20', '2026-09-01'],
        usefulnessNumerator: 2,
        usefulnessDenominator: 3,
      );

      final restored = InsightSnapshot.fromJson(snapshot.toJson());
      expect(restored, isNotNull);
      expect(restored!.family, snapshot.family);
      expect(restored.applicationType, snapshot.applicationType);
      expect(restored.targetPlanId, snapshot.targetPlanId);
      expect(restored.evidenceCount, 5);
      expect(restored.evidenceDateKeys, snapshot.evidenceDateKeys);
      expect(restored.usefulnessNumerator, 2);
      expect(restored.usefulnessDenominator, 3);
      expect(restored.generatedAt, snapshot.generatedAt);
    });

    test('fromJson returns null for a missing required field', () {
      final snapshot = InsightSnapshot(
        id: 'a',
        family: InsightFamily.directionPathContinuity,
        applicationType: InsightApplicationType.activateOrResumePlan,
        targetPlanId: PlanId.moreEnergyPath,
        generatedAt: DateTime(2026, 9, 1),
        ruleVersion: insightRuleVersion,
        templateVersion: insightTemplateVersion,
      );
      final json = snapshot.toJson()..remove('targetPlanId');
      expect(InsightSnapshot.fromJson(json), isNull);
    });

    test('fromJson returns null for an unrecognized enum value', () {
      final snapshot = InsightSnapshot(
        id: 'a',
        family: InsightFamily.directionPathContinuity,
        applicationType: InsightApplicationType.activateOrResumePlan,
        targetPlanId: PlanId.moreEnergyPath,
        generatedAt: DateTime(2026, 9, 1),
        ruleVersion: insightRuleVersion,
        templateVersion: insightTemplateVersion,
      );
      final json = snapshot.toJson();
      json['family'] = 'somethingUnknown';
      expect(InsightSnapshot.fromJson(json), isNull);
    });
  });

  group('InsightSnapshot.describesSameObservationAs', () {
    test('true for an identical family/target/count/pattern-claim', () {
      final snapshot = InsightSnapshot.fromInsight(
        const Insight(
          family: InsightFamily.chosenPacing,
          applicationType: InsightApplicationType.setLighterDefault,
          targetPlanId: PlanId.clearerHeadPath,
          isPatternClaim: true,
          evidenceCount: 5,
        ),
        generatedAt: DateTime(2026, 9, 1),
      );
      const sameInsight = Insight(
        family: InsightFamily.chosenPacing,
        applicationType: InsightApplicationType.setLighterDefault,
        targetPlanId: PlanId.clearerHeadPath,
        isPatternClaim: true,
        evidenceCount: 5,
      );
      expect(snapshot.describesSameObservationAs(sameInsight), isTrue);
    });

    test('false when the evidence count changed', () {
      final snapshot = InsightSnapshot.fromInsight(
        const Insight(
          family: InsightFamily.chosenPacing,
          applicationType: InsightApplicationType.setLighterDefault,
          targetPlanId: PlanId.clearerHeadPath,
          isPatternClaim: true,
          evidenceCount: 5,
        ),
        generatedAt: DateTime(2026, 9, 1),
      );
      const changedInsight = Insight(
        family: InsightFamily.chosenPacing,
        applicationType: InsightApplicationType.setLighterDefault,
        targetPlanId: PlanId.clearerHeadPath,
        isPatternClaim: true,
        evidenceCount: 6,
      );
      expect(snapshot.describesSameObservationAs(changedInsight), isFalse);
    });
  });
}
