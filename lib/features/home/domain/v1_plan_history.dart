/// The retired V1 Circle Plans (V2 Phase D, ADR-022) — only what History
/// needs to read their old records truthfully. Plans themselves are gone:
/// nothing here is offered, resumed or migrated into a V2 Path.
library;

const _plans = {
  'moreEnergyPath': (
    'More Energy',
    [
      'more_energy_1_establish',
      'more_energy_2_develop',
      'more_energy_3_apply',
      'more_energy_4_revisit',
      'more_energy_5_consolidate',
    ],
  ),
  'clearerHeadPath': (
    'Clearer Head',
    [
      'clearer_head_1_establish',
      'clearer_head_2_develop',
      'clearer_head_3_apply',
      'clearer_head_4_revisit',
      'clearer_head_5_consolidate',
    ],
  ),
  'gentlerPacePath': (
    'Gentler Pace',
    [
      'gentler_pace_1_establish',
      'gentler_pace_2_develop',
      'gentler_pace_3_apply',
      'gentler_pace_4_revisit',
      'gentler_pace_5_consolidate',
    ],
  ),
};

/// "From an earlier Plan: More Energy · stage 2 of 5" for a Circle a V1
/// Plan supplied — or `null` when [planId] isn't one. Said as what it was,
/// never as a V2 Path.
String? v1PlanLabel(String? planId, String? stageId) {
  final plan = _plans[planId];
  if (plan == null) return null;
  final (need, stages) = plan;
  final index = stageId == null ? -1 : stages.indexOf(stageId);
  final stage = index < 0 ? '' : ' · stage ${index + 1} of ${stages.length}';
  return 'From an earlier Plan: $need$stage';
}
