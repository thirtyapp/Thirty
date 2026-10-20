/// Which Circle Plan stage a Circle was composed for (ADR-024 §6, B3) —
/// carried by today's composed Circle and kept in its journal record, so a
/// stage Circle is never mistaken for an ordinary one, and an ordinary one
/// never for a stage.
library;

/// One stage Circle's Plan identity.
class PlanStageProvenance {
  const PlanStageProvenance({
    required this.planId,
    required this.cycleId,
    required this.stageNumber,
    required this.stageId,
    this.drawsOn = const [],
    this.revisit = false,
    this.gentler = false,
  });

  /// `getting_going`, `making_room` or `slowing_down`.
  final String planId;

  /// The cycle the stage belongs to.
  final String cycleId;

  /// 1–5.
  final int stageNumber;

  /// The stage's StageBrief id, e.g. `getting_going.2`.
  final String stageId;

  /// Stage 5 only: the earlier stages its Circle combines.
  final List<String> drawsOn;

  /// Served as "This stage again next time": the Plan's place doesn't move.
  final bool revisit;

  /// Composed under "Keep this Plan's Circles gentler for now" (ADR-024
  /// I2): a setting THIRTY applied, so this offer is never evidence for
  /// offering that setting.
  final bool gentler;

  Map<String, Object?> toJson() => {
    'planId': planId,
    'cycleId': cycleId,
    'stageNumber': stageNumber,
    'stageId': stageId,
    if (drawsOn.isNotEmpty) 'drawsOn': drawsOn,
    if (revisit) 'revisit': true,
    if (gentler) 'gentler': true,
  };

  /// `null` for anything that isn't a whole provenance.
  static PlanStageProvenance? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final planId = raw['planId'];
    final cycleId = raw['cycleId'];
    final stageNumber = raw['stageNumber'];
    final stageId = raw['stageId'];
    if (planId is! String ||
        cycleId is! String ||
        stageNumber is! int ||
        stageNumber < 1 ||
        stageNumber > 5 ||
        stageId is! String) {
      return null;
    }
    return PlanStageProvenance(
      planId: planId,
      cycleId: cycleId,
      stageNumber: stageNumber,
      stageId: stageId,
      drawsOn: [
        if (raw['drawsOn'] case final List list)
          for (final id in list)
            if (id is String) id,
      ],
      revisit: raw['revisit'] == true,
      gentler: raw['gentler'] == true,
    );
  }
}
