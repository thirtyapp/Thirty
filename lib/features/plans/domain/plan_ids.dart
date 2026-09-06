/// Stable identities for THIRTY's V1 Circle Plans — Batch 2A
/// (`docs/product/adr/ADR-014-v1-batch-2a-circle-plans.md`).
///
/// Exactly one [PlanId] per [Intention]
/// (`../../home/application/activity_catalog.dart`) — the frozen recurring
/// Premium architecture's V1 inventory is **3 Plans × 5 stages = 15 stage
/// definitions**, one Plan aligned with each existing broad direction. No
/// additional Plan, pack, or tier is introduced by adding a value here.
library;

import '../../home/application/activity_catalog.dart' show Intention;

/// A Circle Plan's stable identity. Never renumbered or reused for a
/// different direction — every persisted [PlanId.name] (Plan state,
/// journal entries) must keep meaning what it meant when it was written.
enum PlanId { moreEnergyPath, clearerHeadPath, gentlerPacePath }

/// The [Intention] each [PlanId] is aligned with — a Plan never overrides
/// or substitutes the user's chosen broad direction (frozen architecture
/// §5); it only ever supplies a Session once that direction is chosen.
Intention planDirection(PlanId planId) => switch (planId) {
  PlanId.moreEnergyPath => Intention.moreEnergy,
  PlanId.clearerHeadPath => Intention.clearerHead,
  PlanId.gentlerPacePath => Intention.gentlerPace,
};

/// A single authored stage's stable identity within its [PlanId] — a plain
/// string rather than a nested enum, so new content revisions can add
/// clearly-named stages without touching a shared enum every Plan depends
/// on. Human-legible and never renumbered (e.g.
/// `'more_energy_1_establish'`), so a stored [StageId] remains meaningful
/// evidence even after a future content revision.
typedef StageId = String;
