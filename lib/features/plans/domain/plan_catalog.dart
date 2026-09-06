/// THIRTY's frozen V1 Circle Plan content — Batch 2A
/// (`docs/product/adr/ADR-014-v1-batch-2a-circle-plans.md`,
/// `RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md` §5).
///
/// Exactly **3 Plans × 5 authored stages = 15 stage definitions**, one Plan
/// per [Intention] (`activity_catalog.dart`). Every stage reuses an
/// existing, reviewed [ActivityId] from that Plan's own direction pool
/// (`activityPools`) — no new [ActivityId] value is introduced by this
/// file. General-wellness/lifestyle guidance only: no fitness, mental-
/// health, or sleep/stress outcome is promised, and nothing here implies
/// THIRTY has measured the user's physiological or emotional state.
///
/// A stage's authoring role (establish / develop / apply / purposeful
/// revisit / consolidate — see each Plan's stage order below) is a private
/// authoring discipline, not a visible UI label — [StageDefinition] does
/// not carry a role field, only the content that role produced.
library;

import '../../home/application/activity_catalog.dart' show ActivityId;
import 'plan_ids.dart';

/// One authored stage within a [PlanDefinition].
///
/// [standardGuidance] and [lighterGuidance] both guide the *same*
/// [activityId] — choosing lighter treatment for a Plan Session
/// (`../application/plan_provider.dart`'s `PlanTreatment`) never changes
/// which activity is recommended, only which of these two guidance strings
/// is shown alongside it. Both are additional, Plan-specific context layered
/// on top of `activity_catalog.dart`'s own intention-independent
/// instructions — they do not repeat or replace that copy.
class StageDefinition {
  const StageDefinition({
    required this.id,
    required this.activityId,
    required this.purpose,
    required this.rationale,
    required this.standardGuidance,
    required this.lighterGuidance,
    required this.contentVersion,
  });

  /// This stage's stable identity within its Plan (e.g.
  /// `'more_energy_1_establish'`) — never renumbered; a future content
  /// revision that must change a stage's meaning introduces a new
  /// [StageId] rather than repurposing this one, so an old persisted
  /// [StageId] (Plan state, journal entries) never silently starts meaning
  /// something else.
  final StageId id;

  /// The reused, existing [ActivityId] this stage assigns — always a
  /// member of this stage's Plan's own [planDirection]'s
  /// `activityPools` entry.
  final ActivityId activityId;

  /// One concise, non-clinical sentence: this stage's purpose within the
  /// path.
  final String purpose;

  /// Why this stage belongs here — its connection to the stage(s) around
  /// it. Every stage's [rationale] must still make sense with any
  /// decorative copy removed.
  final String rationale;

  /// Practical guidance for the standard treatment of [activityId] in this
  /// stage's context.
  final String standardGuidance;

  /// A reviewed, genuinely lighter treatment of the *same* [activityId] —
  /// never a different activity, never merely a shorter copy-paste of
  /// [standardGuidance].
  final String lighterGuidance;

  /// The content-schema version this stage definition was authored under.
  /// See [planContentVersion].
  final int contentVersion;
}

/// One of THIRTY's three V1 Circle Plans.
class PlanDefinition {
  // Every catalogue entry is a compile-time `const`, so this constructor
  // cannot assert `stages.length == 5` (instance member access is not a
  // constant expression) — `plan_catalog_test.dart`'s catalogue-shape
  // group is what actually enforces "exactly five stages per Plan."
  const PlanDefinition({
    required this.id,
    required this.version,
    required this.name,
    required this.purpose,
    required this.stages,
  });

  /// This Plan's stable identity. See [planDirection] for the [Intention]
  /// it is aligned with.
  final PlanId id;

  /// The content-schema version this [PlanDefinition] (including all of
  /// its [stages]) was authored under. See [planContentVersion].
  final int version;

  /// The Plan's display name (e.g. `'More Energy Path'`).
  final String name;

  /// One concise, non-clinical sentence: this Plan's overall purpose. No
  /// guaranteed health, productivity, or sleep outcome.
  final String purpose;

  /// This Plan's five ordered stages — authored in the fixed sequence
  /// establish → develop → apply → purposeful revisit → consolidate (see
  /// `plan_catalog.dart`'s own doc comment for why that role is not itself
  /// a field on [StageDefinition]). [PlanProgress.forwardCursor]
  /// (`../application/plan_state.dart`) indexes directly into this list.
  final List<StageDefinition> stages;
}

/// The content-schema version [planCatalog] currently satisfies — carried
/// on every [PlanDefinition]/[StageDefinition] and, at runtime, on
/// `PlanProgress.contentVersion` and every Plan-related
/// `CircleJournalEntry` field, so a future content revision can tell which
/// version of the catalogue produced a given piece of persisted or
/// journalled state (mirrors `activity_catalog.dart`'s [catalogVersion]).
/// Bump this only alongside an explicit, reviewed content-ADR — never as an
/// incidental side effect of an unrelated change.
const int planContentVersion = 1;

/// The single source of truth for THIRTY's three V1 Circle Plans.
///
/// Each Plan's stage 4 deliberately reuses stage 1's [ActivityId] — the
/// authored "purposeful revisit" role calling back to the path's own
/// starting practice, once later stages have made it feel different. This
/// is a single, explicit editorial choice made once per Plan, not a
/// general pattern that lets any two stages collide; the other four stages
/// in every Plan use four further distinct activities from that direction's
/// pool.
const Map<PlanId, PlanDefinition> planCatalog = {
  PlanId.moreEnergyPath: PlanDefinition(
    id: PlanId.moreEnergyPath,
    version: planContentVersion,
    name: 'More Energy Path',
    purpose:
        'A five-part path that builds a small amount of everyday physical '
        'energy, without turning it into a fitness plan.',
    stages: [
      StageDefinition(
        id: 'more_energy_1_establish',
        activityId: ActivityId.energisingBreathReset,
        purpose:
            'Start the path with the simplest possible way to feel a '
            'little more awake, with no equipment or space needed.',
        rationale:
            'This works anywhere, in any clothes, and takes under a '
            'minute to begin. Every later stage in this path builds on '
            'the small lift it gives you.',
        standardGuidance:
            'Stand up, roll your shoulders back, and alternate brisk, '
            'deliberate breaths with a straighter posture and a few '
            'shoulder rolls, for about half an hour.',
        lighterGuidance:
            'If half an hour feels like too much today, do this for as '
            'little as a minute or two — stand, breathe a little more '
            'deliberately than usual, then stop. A short version still '
            'counts as this stage.',
        contentVersion: planContentVersion,
      ),
      StageDefinition(
        id: 'more_energy_2_develop',
        activityId: ActivityId.energisingStretchFlow,
        purpose:
            'Build on the lift from stage one by adding some actual '
            'movement to the body.',
        rationale:
            'Once posture and breathing feel more awake, a simple '
            'stretch flow is the next small step up — still no '
            'equipment, and nothing stage one hasn\'t already asked of '
            'you.',
        standardGuidance:
            'Move through a simple standing stretch sequence — reaches, '
            'side bends, gentle twists — for about half an hour, '
            'repeating whatever feels good.',
        lighterGuidance:
            'Do two or three stretches instead of a full sequence, then '
            'stop. A shorter stretch flow, done lightly, still counts as '
            'this stage.',
        contentVersion: planContentVersion,
      ),
      StageDefinition(
        id: 'more_energy_3_apply',
        activityId: ActivityId.thirtyMinuteWalk,
        purpose:
            'Take the energy from the first two stages somewhere else — '
            'outside the room you\'ve been standing in.',
        rationale:
            'A walk is a different setting from indoor breathing and '
            'stretching, but it uses the same lift in energy. This is '
            'where the path moves from preparation into something you '
            'can do out in the world.',
        standardGuidance:
            'Walk at whatever pace feels natural for about half an hour '
            '— any route, any surface, any direction.',
        lighterGuidance:
            'Walk a shorter stretch, or just around the block instead of '
            'a longer route. A short, easy walk still counts as this '
            'stage.',
        contentVersion: planContentVersion,
      ),
      StageDefinition(
        id: 'more_energy_4_revisit',
        activityId: ActivityId.energisingBreathReset,
        purpose:
            'Come back to the breath reset from stage one, now that '
            'stretching and walking are also part of the path.',
        rationale:
            'Revisiting the simplest stage on purpose — not because '
            'anything went wrong, but because the same brisk breathing '
            'tends to feel different once it isn\'t the only thing in '
            'the path.',
        standardGuidance:
            'Return to the standing breath reset from earlier in this '
            'path — brisk, deliberate breathing with a straighter '
            'posture — for about half an hour.',
        lighterGuidance:
            'A minute or two of the same breathing is enough to count as '
            'this stage.',
        contentVersion: planContentVersion,
      ),
      StageDefinition(
        id: 'more_energy_5_consolidate',
        activityId: ActivityId.moveToMusic,
        purpose:
            'End this cycle with something easy to keep doing on its '
            'own, whether or not you start the path again.',
        rationale:
            'The path closes with a flexible, everyday form of movement '
            '— a natural stopping point, and something you could keep '
            'doing even without a Plan attached to it.',
        standardGuidance:
            'Put on a song you actually like and move however it makes '
            'you want to move — dancing, swaying, pacing the room — for '
            'about half an hour.',
        lighterGuidance:
            'One song\'s worth of moving is enough to count as this '
            'stage.',
        contentVersion: planContentVersion,
      ),
    ],
  ),
  PlanId.clearerHeadPath: PlanDefinition(
    id: PlanId.clearerHeadPath,
    version: planContentVersion,
    name: 'Clearer Head Path',
    purpose:
        'A five-part path that reduces competing input for a while, '
        'without promising to fix focus or productivity.',
    stages: [
      StageDefinition(
        id: 'clearer_head_1_establish',
        activityId: ActivityId.tidyOneSurface,
        purpose:
            'Start with the smallest possible way to reduce visual '
            'clutter.',
        rationale:
            'One surface is a contained, low-effort starting point — '
            'nothing to plan, nothing to fail at, and a visible result '
            'in half an hour.',
        standardGuidance:
            'Spend about half an hour tidying one desk, drawer, or shelf '
            'only — nothing else in the room.',
        lighterGuidance:
            'Tidy for a few minutes, or only part of the surface. A '
            'partial tidy still counts as this stage.',
        contentVersion: planContentVersion,
      ),
      StageDefinition(
        id: 'clearer_head_2_develop',
        activityId: ActivityId.singleTaskFocus,
        purpose:
            'Move from tidying your surroundings to tidying your '
            'attention onto one thing.',
        rationale:
            'A clearer surface makes it easier to give one task your '
            'full attention next — a connected next step, not an '
            'unrelated jump.',
        standardGuidance:
            'Choose exactly one task already on your mind and give it '
            'your full attention for about half an hour, setting other '
            'tabs, apps and tasks aside.',
        lighterGuidance:
            'Give the one task ten or fifteen minutes instead of the '
            'full half hour. A shorter, focused stretch still counts as '
            'this stage.',
        contentVersion: planContentVersion,
      ),
      StageDefinition(
        id: 'clearer_head_3_apply',
        activityId: ActivityId.phoneFreeWalk,
        purpose:
            'Carry that single-focus practice outside, away from tasks '
            'and screens altogether.',
        rationale:
            'This transfers the same one-thing-at-a-time idea into a '
            'different setting — walking with nothing to check — rather '
            'than adding another indoor task.',
        standardGuidance:
            'Leave your phone behind, then walk for about half an hour '
            'with nothing to check and nothing playing.',
        lighterGuidance:
            'Walk for a shorter stretch, phone still left behind. A '
            'short walk still counts as this stage.',
        contentVersion: planContentVersion,
      ),
      StageDefinition(
        id: 'clearer_head_4_revisit',
        activityId: ActivityId.tidyOneSurface,
        purpose:
            'Return to tidying one surface, on purpose, now that focus '
            'and a phone-free walk are also part of the path.',
        rationale:
            'Revisiting the first stage lets you notice whether a '
            'contained tidy feels different once single-focus and '
            'phone-free practice are already familiar — not a sign '
            'anything was missed the first time.',
        standardGuidance:
            'Pick one surface again — the same one or a different one — '
            'and tidy it for about half an hour.',
        lighterGuidance:
            'A few minutes of tidying is enough to count as this stage.',
        contentVersion: planContentVersion,
      ),
      StageDefinition(
        id: 'clearer_head_5_consolidate',
        activityId: ActivityId.quietReading,
        purpose:
            'Close the cycle with a calm, single-focus activity that '
            'needs nothing further from this path to keep doing.',
        rationale:
            'Reading closes the path on the same one-thing, fully-'
            'attended-to idea the whole path has been building, in a '
            'form that doesn\'t require a plan to repeat.',
        standardGuidance:
            'Read for about half an hour, with notifications out of '
            'reach.',
        lighterGuidance:
            'A few pages or a few minutes is enough to count as this '
            'stage.',
        contentVersion: planContentVersion,
      ),
    ],
  ),
  PlanId.gentlerPacePath: PlanDefinition(
    id: PlanId.gentlerPacePath,
    version: planContentVersion,
    name: 'Gentler Pace Path',
    purpose:
        'A five-part path that gives you permission to slow down for half '
        'an hour, without treating rest as something to fix or measure.',
    stages: [
      StageDefinition(
        id: 'gentler_pace_1_establish',
        activityId: ActivityId.restfulBreathingPause,
        purpose:
            'Start with the simplest way to slow down, needing nothing '
            'but somewhere to sit or lie down.',
        rationale:
            'Slow breathing with nothing to count and nothing to '
            'achieve is the gentlest possible entry point into this '
            'path.',
        standardGuidance:
            'Sit or lie down somewhere comfortable and breathe slowly '
            'for about half an hour, with nothing to count and nothing '
            'to achieve.',
        lighterGuidance:
            'A few slow breaths are enough to count as this stage.',
        contentVersion: planContentVersion,
      ),
      StageDefinition(
        id: 'gentler_pace_2_develop',
        activityId: ActivityId.gentleStretchPause,
        purpose:
            'Add a small amount of gentle movement to the stillness from '
            'stage one.',
        rationale:
            'A gentle stretch is a natural next step from slow breathing '
            '— still unhurried, still nothing to force.',
        standardGuidance:
            'Move slowly through a few gentle stretches for about half '
            'an hour, holding each only as long as it feels good.',
        lighterGuidance:
            'One or two stretches, held briefly, is enough to count as '
            'this stage.',
        contentVersion: planContentVersion,
      ),
      StageDefinition(
        id: 'gentler_pace_3_apply',
        activityId: ActivityId.quietSittingOutside,
        purpose: 'Take the same unhurried pace outside, into a different setting.',
        rationale:
            'This carries the pace established indoors into a new '
            'context, without adding anything to do there.',
        standardGuidance:
            'Sit outside for about half an hour with your phone away, '
            'without needing to do anything else there.',
        lighterGuidance:
            'A few minutes outside is enough to count as this stage.',
        contentVersion: planContentVersion,
      ),
      StageDefinition(
        id: 'gentler_pace_4_revisit',
        activityId: ActivityId.restfulBreathingPause,
        purpose:
            'Return to the slow breathing from stage one, on purpose, '
            'now that stretching and sitting outside are also familiar.',
        rationale:
            'Revisiting the first stage on purpose is a chance to notice '
            'it without needing anything new — not a sign the path has '
            'run out of ideas.',
        standardGuidance:
            'Breathe slowly again for about half an hour, with nothing '
            'to count and nothing to achieve.',
        lighterGuidance:
            'A few slow breaths are enough to count as this stage.',
        contentVersion: planContentVersion,
      ),
      StageDefinition(
        id: 'gentler_pace_5_consolidate',
        activityId: ActivityId.smallComfortRitual,
        purpose:
            'Close the cycle with a small, ordinary comfort that needs '
            'no plan to repeat.',
        rationale:
            'A slow drink is a natural, low-key ending — something you '
            'could keep doing on your own, whether or not you start '
            'this path again.',
        standardGuidance:
            'Make a warm drink and have it slowly for about half an '
            'hour, with your phone out of reach.',
        lighterGuidance:
            'A few unhurried sips is enough to count as this stage.',
        contentVersion: planContentVersion,
      ),
    ],
  ),
};

/// [planId]'s [PlanDefinition]. Throws if [planId] has no entry, which can
/// only happen if [PlanId] and [planCatalog] have drifted out of sync — a
/// programming error, not a runtime condition (mirrors
/// `activity_catalog.dart`'s [whyCopyFor] doc comment).
PlanDefinition planDefinitionFor(PlanId planId) => planCatalog[planId]!;

/// [planId]'s stage at [index] (0-based, `0 <= index < 5`).
StageDefinition stageAt(PlanId planId, int index) =>
    planDefinitionFor(planId).stages[index];

/// Finds [stageId] within [planId]'s stages, or `null` if no stage with
/// that id exists in the current catalogue — the caller's fail-safe path
/// for a [StageId] that belonged to an earlier, incompatible content
/// version.
StageDefinition? findStage(PlanId planId, StageId stageId) {
  for (final stage in planDefinitionFor(planId).stages) {
    if (stage.id == stageId) return stage;
  }
  return null;
}
