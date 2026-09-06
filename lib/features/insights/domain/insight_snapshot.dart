/// THIRTY's bounded local Insight snapshot model — Batch 2C
/// (`docs/product/adr/ADR-016-v1-batch-2c-circle-insights.md`,
/// `RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md` §9, "Local
/// history contract").
///
/// [InsightSnapshot] captures the *identity* of an evaluated
/// `insight_engine.dart` [Insight] at the moment it was assessed — family,
/// target, evidence count/dates, response coverage, generated timestamp,
/// and the rule/template version that produced it. It deliberately does
/// **not** freeze a stage number, an "already applied" flag, or any other
/// value that must "update immediately" — those are always recomputed live
/// from current Plan state by `../application/insight_provider.dart`.
///
/// Device-local only, same single-key-versioned-blob pattern as
/// `../../home/application/circle_journal.dart` and
/// `../../plans/application/plan_provider.dart`.
library;

import '../../plans/domain/plan_ids.dart';
import 'insight.dart';
import 'insight_family.dart';

/// The Insight rule-evaluation semantics version — bump only alongside a
/// reviewed change to `insight_engine.dart`'s eligibility rules. A
/// persisted snapshot's own [InsightSnapshot.ruleVersion] is compared
/// against this by `../application/insight_provider.dart` before trusting
/// it as the *current* Insight — an old snapshot remains valid, readable
/// history regardless.
const insightRuleVersion = 1;

/// The observation/application wording template version — bump only
/// alongside a reviewed copy change to how an [Insight] is rendered
/// (`../presentation/widgets/insight_card.dart`).
const insightTemplateVersion = 1;

/// SharedPreferences key the entire Insight snapshot history is stored
/// under, as one JSON-encoded object.
const insightSnapshotsKey = 'insight_snapshots_v1';

/// The current Insight snapshot wrapper schema version.
const insightSnapshotsSchemaVersion = 1;

/// At most this many of the most recent snapshots are kept, oldest dropped
/// first — "at most 52 weekly Insight snapshots" (frozen architecture §9).
const insightSnapshotMaxCount = 52;

/// One retained record of an Insight assessed at [generatedAt]. Immutable
/// once created; a later assessment appends a new snapshot rather than
/// rewriting this one.
class InsightSnapshot {
  const InsightSnapshot({
    required this.id,
    required this.family,
    required this.applicationType,
    required this.targetPlanId,
    required this.generatedAt,
    required this.ruleVersion,
    required this.templateVersion,
    this.targetStageId,
    this.isPatternClaim = false,
    this.evidenceCount = 0,
    this.evidenceDateKeys = const [],
    this.usefulnessNumerator,
    this.usefulnessDenominator,
  });

  /// Builds the snapshot that records [insight] as it was assessed at
  /// [generatedAt], stamped with the current rule/template versions.
  factory InsightSnapshot.fromInsight(
    Insight insight, {
    required DateTime generatedAt,
  }) {
    return InsightSnapshot(
      id: '${insight.family.name}_${generatedAt.microsecondsSinceEpoch}',
      family: insight.family,
      applicationType: insight.applicationType,
      targetPlanId: insight.targetPlanId,
      targetStageId: insight.targetStageId,
      isPatternClaim: insight.isPatternClaim,
      evidenceCount: insight.evidenceCount,
      evidenceDateKeys: insight.evidenceDateKeys,
      usefulnessNumerator: insight.usefulnessNumerator,
      usefulnessDenominator: insight.usefulnessDenominator,
      generatedAt: generatedAt,
      ruleVersion: insightRuleVersion,
      templateVersion: insightTemplateVersion,
    );
  }

  final String id;
  final InsightFamily family;
  final InsightApplicationType applicationType;
  final PlanId targetPlanId;
  final String? targetStageId;
  final bool isPatternClaim;
  final int evidenceCount;
  final List<String> evidenceDateKeys;
  final int? usefulnessNumerator;
  final int? usefulnessDenominator;
  final DateTime generatedAt;
  final int ruleVersion;
  final int templateVersion;

  /// Whether this snapshot's [family]/[targetPlanId]/[targetStageId]/
  /// [evidenceCount]/[isPatternClaim] describe the same observation as
  /// [insight] — used to decide whether a new assessment is actually a
  /// *new* observation worth appending as history, or the same one already
  /// on record ("no invented novelty quota").
  bool describesSameObservationAs(Insight insight) {
    return family == insight.family &&
        targetPlanId == insight.targetPlanId &&
        targetStageId == insight.targetStageId &&
        isPatternClaim == insight.isPatternClaim &&
        evidenceCount == insight.evidenceCount;
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'family': family.name,
    'applicationType': applicationType.name,
    'targetPlanId': targetPlanId.name,
    'targetStageId': targetStageId,
    'isPatternClaim': isPatternClaim,
    'evidenceCount': evidenceCount,
    'evidenceDateKeys': evidenceDateKeys,
    'usefulnessNumerator': usefulnessNumerator,
    'usefulnessDenominator': usefulnessDenominator,
    'generatedAt': generatedAt.toIso8601String(),
    'ruleVersion': ruleVersion,
    'templateVersion': templateVersion,
  };

  /// Parses one snapshot, or `null` if any required field is missing or
  /// invalid — a single corrupt snapshot is dropped, never allowed to make
  /// the rest of the retained history unreadable (mirrors
  /// `../../home/application/circle_journal.dart`'s own per-entry
  /// fail-safe read path).
  static InsightSnapshot? fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final family = InsightFamily.values.asNameMap()[json['family']];
    final applicationType = InsightApplicationType.values.asNameMap()[json['applicationType']];
    final targetPlanId = PlanId.values.asNameMap()[json['targetPlanId']];
    final generatedAt = DateTime.tryParse('${json['generatedAt']}');
    final ruleVersion = json['ruleVersion'];
    final templateVersion = json['templateVersion'];

    if (id is! String ||
        family == null ||
        applicationType == null ||
        targetPlanId == null ||
        generatedAt == null ||
        ruleVersion is! int ||
        templateVersion is! int) {
      return null;
    }

    final targetStageIdRaw = json['targetStageId'];
    final targetStageId = targetStageIdRaw is String ? targetStageIdRaw : null;
    final evidenceCountRaw = json['evidenceCount'];
    final evidenceCount = evidenceCountRaw is int ? evidenceCountRaw : 0;
    final rawDates = json['evidenceDateKeys'];
    final evidenceDateKeys = rawDates is List
        ? rawDates.whereType<String>().toList()
        : const <String>[];
    final usefulnessNumeratorRaw = json['usefulnessNumerator'];
    final usefulnessNumerator = usefulnessNumeratorRaw is int
        ? usefulnessNumeratorRaw
        : null;
    final usefulnessDenominatorRaw = json['usefulnessDenominator'];
    final usefulnessDenominator = usefulnessDenominatorRaw is int
        ? usefulnessDenominatorRaw
        : null;

    return InsightSnapshot(
      id: id,
      family: family,
      applicationType: applicationType,
      targetPlanId: targetPlanId,
      targetStageId: targetStageId,
      isPatternClaim: json['isPatternClaim'] == true,
      evidenceCount: evidenceCount,
      evidenceDateKeys: evidenceDateKeys,
      usefulnessNumerator: usefulnessNumerator,
      usefulnessDenominator: usefulnessDenominator,
      generatedAt: generatedAt,
      ruleVersion: ruleVersion,
      templateVersion: templateVersion,
    );
  }
}
