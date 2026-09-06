import '../../../core/activity_category.dart';

/// The desired direction the user picks via the Daily Context Question
/// ("What would help most today?") — Recommendation MVP v0
/// (`docs/product/recommendation-mvp-v0.md`). Explicitly selected by the
/// user, never inferred from behavior, mood, or any other signal — see
/// [ADR-009](../../../../docs/product/adr/ADR-009-daily-intention-question.md).
///
/// This is [Decision Framework §4](../../../../docs/product/decision-framework.md#4-intentie-versus-activiteit)'s
/// "Intentie": the first, primary decision. [ActivityId] is the later,
/// narrower "Activiteit" chosen within it.
enum Intention { moreEnergy, clearerHead, gentlerPace }

/// The label shown for [intention] itself (used as
/// `Recommendation.intent` — see `recommendation_provider.dart`).
String intentionLabel(Intention intention) => switch (intention) {
  Intention.moreEnergy => 'More Energy',
  Intention.clearerHead => 'Clearer Head',
  Intention.gentlerPace => 'Gentler Pace',
};

/// The one-line meaning shown for [intention] on the Daily Context Question
/// (`daily_intention_prompt.dart`) — the exact, approved wording from
/// `docs/product/recommendation-mvp-v0.md`. A desired direction the user
/// explicitly recognizes and picks, never a health-state description.
String intentionMeaning(Intention intention) => switch (intention) {
  Intention.moreEnergy =>
    'I want to spend this half-hour being somewhat more active and '
        'engaged.',
  Intention.clearerHead =>
    'I want this half-hour to contain less competing input and more '
        'single-focus attention.',
  Intention.gentlerPace =>
    'I want to use this half-hour without turning it into another '
        'performance or productivity demand.',
};

/// A canonical activity identity, stable across intentions — the "same
/// underlying activity" identity anti-repetition compares against, distinct
/// from how that activity is presented/explained for a given [Intention].
///
/// Every value belongs to exactly one [activityPools] entry in this
/// version, even where two activities are conceptually similar (e.g.
/// [thirtyMinuteWalk], [phoneFreeWalk] and [easyWalk] are three distinct
/// walks, not variants of one canonical activity). The same [ActivityId]
/// appearing in more than one pool remains a supported way to model one
/// activity offered under multiple intentions — see
/// `docs/product/recommendation-mvp-v0.md` — it simply has no current
/// example in this catalogue: every reviewed V1 placement (ADR-013) is
/// concrete and direction-specific enough that sharing an identity across
/// directions would blur, rather than clarify, why it was recommended.
///
/// **V1 catalogue (ADR-013 — Batch 1):** the original 7 (v0) identities are
/// unchanged and reused as-is — reusing stable identities across catalogue
/// revisions is deliberate, so a device's persisted
/// `recommendationActivityIdKey`/history/journal values never need a
/// migration just because the catalogue grew. 14 new identities were added
/// to reach the frozen V1 launch target of 7 reviewed placements per
/// [Intention] (21 total), each contributing a genuinely distinct
/// [ActivitySemanticFamily] — see [activityCatalog].
enum ActivityId {
  // v0 (unchanged identities)
  thirtyMinuteWalk,
  moveToMusic,
  phoneFreeWalk,
  writeItDown,
  quietReading,
  easyWalk,
  quietMusicBreak,
  // V1 / Batch 1 (ADR-013) — More Energy
  briskStepBurst,
  energisingStretchFlow,
  activeMovementSnack,
  energisingBreathReset,
  activeHouseholdTask,
  // V1 / Batch 1 (ADR-013) — Clearer Head
  tidyOneSurface,
  singleTaskFocus,
  quietAudioFocus,
  focusedBreathingCount,
  // V1 / Batch 1 (ADR-013) — Gentler Pace
  restfulBreathingPause,
  gentleStretchPause,
  quietSittingOutside,
  smallComfortRitual,
  unhurriedTidyPause,
}

/// The approved activities for each [Intention], in a fixed order —
/// [selectActivityId] indexes into this order deterministically.
///
/// **Frozen V1 launch target (ADR-013):** exactly 7 reviewed placements per
/// [Intention] (21 total), each covering at least 4 genuinely different
/// [ActivitySemanticFamily] values within that direction — see
/// [activityCatalog] and `activity_catalog_test.dart`'s catalogue-coverage
/// group, which enforces both numbers directly so this map can never
/// silently drift below the approved target.
const Map<Intention, List<ActivityId>> activityPools = {
  Intention.moreEnergy: [
    ActivityId.thirtyMinuteWalk,
    ActivityId.moveToMusic,
    ActivityId.briskStepBurst,
    ActivityId.energisingStretchFlow,
    ActivityId.activeMovementSnack,
    ActivityId.energisingBreathReset,
    ActivityId.activeHouseholdTask,
  ],
  Intention.clearerHead: [
    ActivityId.phoneFreeWalk,
    ActivityId.writeItDown,
    ActivityId.quietReading,
    ActivityId.tidyOneSurface,
    ActivityId.singleTaskFocus,
    ActivityId.quietAudioFocus,
    ActivityId.focusedBreathingCount,
  ],
  Intention.gentlerPace: [
    ActivityId.easyWalk,
    ActivityId.quietMusicBreak,
    ActivityId.restfulBreathingPause,
    ActivityId.gentleStretchPause,
    ActivityId.quietSittingOutside,
    ActivityId.smallComfortRitual,
    ActivityId.unhurriedTidyPause,
  ],
};

/// The content/catalogue schema version [activityCatalog] and
/// [activityPools] currently satisfy — carried on
/// `Recommendation`/`RecommendationState` (`recommendation_provider.dart`)
/// and on every `CircleJournalEntry` (`circle_journal.dart`) so a future
/// catalogue revision can tell, per persisted/journalled record, which
/// version of the catalogue produced it. `1` is ADR-013's frozen V1 launch
/// catalogue (the 7 v0 identities plus 14 new ones, 21 total). Bump this
/// only alongside an explicit, reviewed catalogue-content ADR — never as an
/// incidental side effect of an unrelated change.
const int catalogVersion = 1;

/// A genuinely distinct family of activity — the axis
/// [selectActivityId]'s cross-direction diversity guard (ADR-013) compares
/// against, and the axis the "at least 4 genuinely different semantic
/// activity families per direction" launch requirement is checked against.
///
/// Deliberately coarser than [ActivityId] (many activities can share a
/// family) but independent of [ActivityCategory] (the World-rendering
/// axis, WORLD_SYSTEM.md §3) — a family is a content-organisation concept
/// only, and introducing one here never implies a new World/Place exists.
/// [walking] is the one family name shared with [ActivityCategory] by
/// coincidence of vocabulary, not by shared meaning.
enum ActivitySemanticFamily {
  walking,
  musicMovement,
  stepMovement,
  stretchMobility,
  bodyweightMovement,
  breathingEnergizer,
  activeChore,
  reflectiveWriting,
  quietReading,
  tidyReset,
  singleFocusTask,
  quietListening,
  breathingStillness,
  natureSit,
  comfortRitual,
}

/// The full, reviewed definition of one [ActivityId] — everything about it
/// that does not depend on which [Intention] it is being recommended
/// under. See [activityCatalog] for the map every helper in this file
/// (other than [whyCopyFor], which is pair-keyed) reads from.
class ActivityDefinition {
  const ActivityDefinition({
    required this.title,
    required this.firstAction,
    required this.instructions,
    required this.preparation,
    required this.pacingNote,
    required this.family,
    required this.category,
  });

  /// [activityLabel]'s value — intention-independent.
  final String title;

  /// The one immediate action that starts the activity — short enough to
  /// read in a glance, concrete enough that there is nothing left to
  /// figure out before beginning.
  final String firstAction;

  /// Concise, actionable instructions for the roughly thirty-minute
  /// activity itself. Never states or implies a timer requirement — see
  /// `docs/product/recommendation-mvp-v0.md`.
  final String instructions;

  /// What, if anything, the activity requires beyond what's already at
  /// hand — a truthful preparation/equipment/access constraint, not
  /// marketing copy. `'None.'` when nothing beyond the activity itself is
  /// needed.
  final String preparation;

  /// Explicit self-paced/"stop whenever" language — every V1 placement
  /// must make clear there is no pace, count, or duration to actually hit
  /// (`docs/product/recommendation-mvp-v0.md`'s "approximate thirty-minute
  /// framing without a timer requirement").
  final String pacingNote;

  /// The [ActivitySemanticFamily] this activity belongs to — the axis the
  /// "≥4 distinct families per direction" launch requirement and the
  /// cross-direction diversity guard (both ADR-013) are checked against.
  final ActivitySemanticFamily family;

  /// [activityCategory]'s value — the World-rendering axis. See
  /// [ActivityCategory]'s own doc comment for why only genuinely
  /// walking-based activities resolve to [ActivityCategory.walking].
  final ActivityCategory category;
}

/// The single source of truth for every [ActivityId]'s reviewed content —
/// see [ActivityDefinition] for what each entry carries. [whyCopyFor] is
/// the one piece of per-activity copy kept separate from this map, because
/// it is keyed on the (intention, activityId) pair rather than on
/// [ActivityId] alone.
const Map<ActivityId, ActivityDefinition> activityCatalog = {
  ActivityId.thirtyMinuteWalk: ActivityDefinition(
    title: '30-minute walk',
    firstAction:
        'Step outside (or start walking wherever you already are) and '
        'begin.',
    instructions:
        'Walk at whatever pace feels natural for about half an hour — any '
        'route, any surface, any direction.',
    preparation: 'None — comfortable shoes help, but nothing is required.',
    pacingNote: 'There\'s no pace or distance to hit. Stop when it feels done.',
    family: ActivitySemanticFamily.walking,
    category: ActivityCategory.walking,
  ),
  ActivityId.moveToMusic: ActivityDefinition(
    title: 'Move to music',
    firstAction: 'Put on a song you actually like.',
    instructions:
        'Move however that music makes you want to move — dancing, '
        'swaying, pacing the room — for about half an hour.',
    preparation: 'A phone, speaker, or anything that plays music.',
    pacingNote:
        'No steps to learn and no one watching. Stop whenever you\'ve had '
        'enough.',
    family: ActivitySemanticFamily.musicMovement,
    category: ActivityCategory.generalWellness,
  ),
  ActivityId.phoneFreeWalk: ActivityDefinition(
    title: 'Phone-free walk',
    firstAction:
        'Leave your phone behind, or put it fully out of reach, then '
        'start walking.',
    instructions:
        'Walk for about half an hour with nothing to check and nothing '
        'playing — just you and where you\'re walking.',
    preparation: 'None — just a place you can walk safely without your phone.',
    pacingNote: 'Turn back whenever you\'re ready; there\'s no route to finish.',
    family: ActivitySemanticFamily.walking,
    category: ActivityCategory.walking,
  ),
  ActivityId.writeItDown: ActivityDefinition(
    title: 'Write it down',
    firstAction:
        'Grab any paper or a blank note, and write the first thing on '
        'your mind.',
    instructions:
        'Spend about half an hour writing down the tasks, reminders and '
        'loose thoughts competing for your attention, in any order — no '
        'need to solve or organise them.',
    preparation:
        'Paper and something to write with, or a blank note on your '
        'phone or computer.',
    pacingNote:
        'There\'s no length to hit or list to finish. Stop when your head '
        'feels clearer.',
    family: ActivitySemanticFamily.reflectiveWriting,
    category: ActivityCategory.generalWellness,
  ),
  ActivityId.quietReading: ActivityDefinition(
    title: 'Quiet reading',
    firstAction: 'Pick up whatever you\'re already reading, or something nearby.',
    instructions:
        'Read for about half an hour, with notifications out of reach — '
        'one thing to focus on instead of many.',
    preparation:
        'Something to read — a book, article, or anything else already '
        'at hand.',
    pacingNote: 'No page count to reach. Put it down whenever you\'re ready.',
    family: ActivitySemanticFamily.quietReading,
    category: ActivityCategory.generalWellness,
  ),
  ActivityId.easyWalk: ActivityDefinition(
    title: 'Easy walk',
    firstAction:
        'Step outside, or just start walking, without deciding on a '
        'route first.',
    instructions:
        'Walk slowly and without hurry for about half an hour — wherever '
        'feels easiest, with nothing to hit or beat.',
    preparation: 'None.',
    pacingNote: 'Slower is fine. Turn back whenever you want to.',
    family: ActivitySemanticFamily.walking,
    category: ActivityCategory.walking,
  ),
  ActivityId.quietMusicBreak: ActivityDefinition(
    title: 'Quiet music break',
    firstAction: 'Sit or lie down somewhere comfortable, and put on something quiet.',
    instructions:
        'Listen for about half an hour, with nothing else to do and '
        'nothing to accomplish.',
    preparation: 'A phone, speaker, or anything that plays quiet music.',
    pacingNote: 'No goal attached. Stop the moment it\'s no longer helping.',
    family: ActivitySemanticFamily.quietListening,
    category: ActivityCategory.generalWellness,
  ),
  ActivityId.briskStepBurst: ActivityDefinition(
    title: 'Brisk stairs or a slope',
    firstAction: 'Find a staircase, a hill, or any incline nearby.',
    instructions:
        'For about half an hour, go up and down stairs or walk a slope at '
        'a pace that raises your breathing a little — resting between '
        'rounds whenever you need to.',
    preparation: 'Stairs or a slope, and shoes you can move in.',
    pacingNote: 'Go at whatever pace you can keep up. Slow down or rest any time.',
    family: ActivitySemanticFamily.stepMovement,
    category: ActivityCategory.generalWellness,
  ),
  ActivityId.energisingStretchFlow: ActivityDefinition(
    title: 'Energising stretch flow',
    firstAction: 'Stand up and reach both arms overhead.',
    instructions:
        'Move through a simple standing stretch sequence — reaches, side '
        'bends, gentle twists — for about half an hour, repeating '
        'whatever feels good.',
    preparation: 'None — enough space to stand and stretch your arms.',
    pacingNote:
        'There\'s no sequence to complete correctly. Repeat what helps, '
        'skip what doesn\'t.',
    family: ActivitySemanticFamily.stretchMobility,
    category: ActivityCategory.generalWellness,
  ),
  ActivityId.activeMovementSnack: ActivityDefinition(
    title: 'Active movement snack',
    firstAction:
        'Pick one simple move — marching in place, wall push-ups, or '
        'slow squats.',
    instructions:
        'Repeat that move (or switch between a few) at your own pace for '
        'about half an hour, resting between sets whenever you like.',
    preparation: 'None — a clear patch of floor, and a wall if you choose wall push-ups.',
    pacingNote: 'No rep count to hit. Do a little, rest, do a little more.',
    family: ActivitySemanticFamily.bodyweightMovement,
    category: ActivityCategory.generalWellness,
  ),
  ActivityId.energisingBreathReset: ActivityDefinition(
    title: 'Standing breath reset',
    firstAction: 'Stand up, roll your shoulders back, and take one deep breath.',
    instructions:
        'Spend about half an hour alternating brisk, deliberate breaths '
        'with a straighter posture and a few shoulder rolls — sitting '
        'back down whenever you want.',
    preparation: 'None.',
    pacingNote: 'Breathe at whatever pace feels comfortable. Stop the moment it doesn\'t.',
    family: ActivitySemanticFamily.breathingEnergizer,
    category: ActivityCategory.generalWellness,
  ),
  ActivityId.activeHouseholdTask: ActivityDefinition(
    title: 'One active household task',
    firstAction:
        'Pick one physical task — sweeping, tidying, carrying, or a bit '
        'of gardening.',
    instructions:
        'Spend about half an hour on that one task, moving at a pace '
        'that keeps you a little more active than sitting still.',
    preparation: 'Whatever the chosen task needs — nothing more than that.',
    pacingNote: 'Pick a task you can stop partway through without it mattering.',
    family: ActivitySemanticFamily.activeChore,
    category: ActivityCategory.generalWellness,
  ),
  ActivityId.tidyOneSurface: ActivityDefinition(
    title: 'Tidy one surface',
    firstAction: 'Pick exactly one desk, drawer, or shelf.',
    instructions:
        'Spend about half an hour tidying that one surface only — '
        'nothing else in the room.',
    preparation: 'None.',
    pacingNote: 'One surface is the whole task. Stop even if it isn\'t perfect.',
    family: ActivitySemanticFamily.tidyReset,
    category: ActivityCategory.generalWellness,
  ),
  ActivityId.singleTaskFocus: ActivityDefinition(
    title: 'One task, full attention',
    firstAction: 'Choose exactly one task already on your mind.',
    instructions:
        'Give that single task your full attention for about half an '
        'hour, setting other tabs, apps and tasks aside.',
    preparation: 'Whatever that one task itself needs.',
    pacingNote: 'Only one task. If your attention drifts, just come back to the same one.',
    family: ActivitySemanticFamily.singleFocusTask,
    category: ActivityCategory.generalWellness,
  ),
  ActivityId.quietAudioFocus: ActivityDefinition(
    title: 'One quiet recording, phone face down',
    firstAction: 'Choose one album, podcast episode, or recording.',
    instructions:
        'Listen to it for about half an hour with your phone face down '
        'and nothing else open — one audio source, nothing layered on '
        'top.',
    preparation: 'A phone, speaker, or headphones.',
    pacingNote: 'No need to finish the recording. Stop whenever you want to.',
    family: ActivitySemanticFamily.quietListening,
    category: ActivityCategory.generalWellness,
  ),
  ActivityId.focusedBreathingCount: ActivityDefinition(
    title: 'Counted breathing pause',
    firstAction: 'Sit down somewhere quiet and close your eyes if that\'s comfortable.',
    instructions:
        'For about half an hour, breathe slowly and count each breath, '
        'starting over at ten whenever your attention wanders.',
    preparation: 'None.',
    pacingNote: 'Losing count is normal — just start again. Stop whenever you\'re ready.',
    family: ActivitySemanticFamily.breathingStillness,
    category: ActivityCategory.generalWellness,
  ),
  ActivityId.restfulBreathingPause: ActivityDefinition(
    title: 'Slow breathing pause',
    firstAction: 'Sit or lie down somewhere comfortable.',
    instructions:
        'Breathe slowly for about half an hour, with nothing to count '
        'and nothing to achieve.',
    preparation: 'None.',
    pacingNote: 'No pattern to follow. Stop the moment you feel ready to.',
    family: ActivitySemanticFamily.breathingStillness,
    category: ActivityCategory.generalWellness,
  ),
  ActivityId.gentleStretchPause: ActivityDefinition(
    title: 'Gentle stretch pause',
    firstAction: 'Stand or sit, and move into whatever stretch feels easiest first.',
    instructions:
        'Move slowly through a few gentle stretches for about half an '
        'hour, holding each only as long as it feels good.',
    preparation: 'None.',
    pacingNote: 'No stretch to force and no sequence to finish. Stop anytime.',
    family: ActivitySemanticFamily.stretchMobility,
    category: ActivityCategory.generalWellness,
  ),
  ActivityId.quietSittingOutside: ActivityDefinition(
    title: 'Sitting outside, unhurried',
    firstAction: 'Find somewhere outside to sit — a balcony, step, bench, or garden.',
    instructions:
        'Sit outside for about half an hour with your phone away, '
        'without needing to do anything else there.',
    preparation: 'Somewhere outside you can sit for a while.',
    pacingNote:
        'No destination and nothing to observe on purpose. Come back in '
        'whenever you\'re ready.',
    family: ActivitySemanticFamily.natureSit,
    category: ActivityCategory.generalWellness,
  ),
  ActivityId.smallComfortRitual: ActivityDefinition(
    title: 'A slow warm drink',
    firstAction: 'Make a warm drink — tea, coffee, or anything else you\'d enjoy.',
    instructions:
        'Spend about half an hour having it slowly, with your phone out '
        'of reach and nothing else demanding attention.',
    preparation: 'Whatever you\'d use to make a warm drink.',
    pacingNote: 'No pace to keep. Finish whenever you\'re done, sooner or later.',
    family: ActivitySemanticFamily.comfortRitual,
    category: ActivityCategory.generalWellness,
  ),
  ActivityId.unhurriedTidyPause: ActivityDefinition(
    title: 'Tend to one small thing',
    firstAction: 'Pick one small, low-pressure thing — a plant, a bedside table, a single shelf.',
    instructions:
        'Spend about half an hour tending to that one small thing, at '
        'whatever pace feels unhurried.',
    preparation: 'Whatever that one small thing needs.',
    pacingNote: 'It doesn\'t need to be finished. Stop whenever you\'re ready.',
    family: ActivitySemanticFamily.tidyReset,
    category: ActivityCategory.generalWellness,
  ),
};

/// [activityId]'s display name — intention-independent, unlike
/// [whyCopyFor].
String activityLabel(ActivityId activityId) => activityCatalog[activityId]!.title;

/// [activityId]'s [ActivityCategory], for illustration purposes only.
///
/// Only genuinely walking-based activities resolve to
/// [ActivityCategory.walking] — every other V1 activity resolves to
/// [ActivityCategory.generalWellness], a neutral category with no approved
/// Place of its own yet (see that enum's own doc comment). This mapping
/// exists so `Recommendation.category` stays a truthful description of the
/// activity, even though, currently, every category renders the same
/// illustration in `circle_hero.dart`.
ActivityCategory activityCategory(ActivityId activityId) =>
    activityCatalog[activityId]!.category;

/// [activityId]'s [ActivitySemanticFamily] — see [ActivityDefinition.family].
ActivitySemanticFamily activityFamily(ActivityId activityId) =>
    activityCatalog[activityId]!.family;

/// [activityId]'s one immediate first action. See [ActivityDefinition.firstAction].
String activityFirstAction(ActivityId activityId) =>
    activityCatalog[activityId]!.firstAction;

/// [activityId]'s concise instructions. See [ActivityDefinition.instructions].
String activityInstructions(ActivityId activityId) =>
    activityCatalog[activityId]!.instructions;

/// [activityId]'s preparation/equipment/access constraint. See
/// [ActivityDefinition.preparation].
String activityPreparation(ActivityId activityId) =>
    activityCatalog[activityId]!.preparation;

/// [activityId]'s explicit self-paced/stop language. See
/// [ActivityDefinition.pacingNote].
String activityPacingNote(ActivityId activityId) =>
    activityCatalog[activityId]!.pacingNote;

/// The "Why This Today?" copy for ([intention], [activityId]) — deliberately
/// keyed on the pair, not on [activityId] alone, so a future activity
/// shared across pools (see [ActivityId]'s own doc comment) could carry a
/// different reason per intention even though the activity itself is the
/// same.
///
/// Every string here may reference only (1) the intention the user
/// explicitly selected, and (2) a truthful, practical characteristic of the
/// activity — never a claim of hidden knowledge about the user (no "your
/// body needs...", no "based on your energy...", no medical or emotional
/// claims). See `docs/product/recommendation-mvp-v0.md` for the full rule.
const Map<(Intention, ActivityId), String> _whyCopy = {
  (Intention.moreEnergy, ActivityId.thirtyMinuteWalk):
      'For more energy: a 30-minute walk, wherever you are — no pace or '
      'distance to keep up with.',
  (Intention.moreEnergy, ActivityId.moveToMusic):
      'For more energy: moving to your own music, at whatever pace feels '
      'good.',
  (Intention.moreEnergy, ActivityId.briskStepBurst):
      'For more energy: brisk stairs or a slope, at whatever pace raises '
      'your breathing a little — with rest whenever you need it.',
  (Intention.moreEnergy, ActivityId.energisingStretchFlow):
      'For more energy: a standing stretch flow that wakes up your body, '
      'no equipment or routine to learn.',
  (Intention.moreEnergy, ActivityId.activeMovementSnack):
      'For more energy: simple, repeated movement — no gym, no '
      'equipment, no set count to reach.',
  (Intention.moreEnergy, ActivityId.energisingBreathReset):
      'For more energy: an upright posture and a brisk breathing '
      'pattern, nothing more.',
  (Intention.moreEnergy, ActivityId.activeHouseholdTask):
      'For more energy: one physically active task, chosen by you, done '
      'at your own pace.',
  (Intention.clearerHead, ActivityId.phoneFreeWalk):
      'For a clearer head: a walk with your phone\'s content set aside — '
      'just you and where you\'re walking.',
  (Intention.clearerHead, ActivityId.writeItDown):
      'For a clearer head: spend about 30 minutes writing down the tasks, '
      'reminders and loose thoughts competing for your attention, in any '
      'order. No need to solve or organise them.',
  (Intention.clearerHead, ActivityId.quietReading):
      'For a clearer head: quiet reading, one thing to focus on instead '
      'of many.',
  (Intention.clearerHead, ActivityId.tidyOneSurface):
      'For a clearer head: one contained surface to tidy, and nothing '
      'wider than that.',
  (Intention.clearerHead, ActivityId.singleTaskFocus):
      'For a clearer head: exactly one task, chosen by you, without '
      'switching between others.',
  (Intention.clearerHead, ActivityId.quietAudioFocus):
      'For a clearer head: a single recording, with nothing else '
      'competing for your attention.',
  (Intention.clearerHead, ActivityId.focusedBreathingCount):
      'For a clearer head: one simple counting anchor, and nothing else '
      'to track.',
  (Intention.gentlerPace, ActivityId.easyWalk):
      'For a gentler pace: an easy, unhurried walk with nothing to hit '
      'or beat.',
  (Intention.gentlerPace, ActivityId.quietMusicBreak):
      'For a gentler pace: a quiet music break, just for you, with no '
      'goal attached.',
  (Intention.gentlerPace, ActivityId.restfulBreathingPause):
      'For a gentler pace: slow, unhurried breathing, with nothing to '
      'get right.',
  (Intention.gentlerPace, ActivityId.gentleStretchPause):
      'For a gentler pace: slow, gentle stretching, with nothing to '
      'push through.',
  (Intention.gentlerPace, ActivityId.quietSittingOutside):
      'For a gentler pace: simply sitting outside, with nowhere to be '
      'and nothing to do there.',
  (Intention.gentlerPace, ActivityId.smallComfortRitual):
      'For a gentler pace: a slow drink, with nothing else asked of you.',
  (Intention.gentlerPace, ActivityId.unhurriedTidyPause):
      'For a gentler pace: one small, low-pressure thing to tend to, '
      'with no deadline.',
};

/// The "why" explanation for choosing [activityId] under [intention].
///
/// Throws a [StateError] if the pair has no copy defined — this can only
/// happen if [activityPools] and [_whyCopy] have drifted out of sync, which
/// is a programming error, not a runtime condition to recover from.
String whyCopyFor(Intention intention, ActivityId activityId) {
  final why = _whyCopy[(intention, activityId)];
  if (why == null) {
    throw StateError('No why-copy defined for ($intention, $activityId).');
  }
  return why;
}

/// A stable, calendar-derived integer for [date]'s local calendar day —
/// the same value for every [DateTime] on the same local date, regardless
/// of time-of-day, and strictly increasing from one calendar day to the
/// next. Built from [DateTime.utc] (never a local-time difference) so it
/// can never be perturbed by daylight-saving transitions.
///
/// This is the deterministic "which day is it, as a number" primitive
/// [selectActivityId] rotates through [activityPools] with — never a
/// hash code, and never randomness.
int epochDay(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

/// Deterministically picks one [ActivityId] from [intention]'s pool.
///
/// - **Deterministic:** the same ([dayIndex], [intention],
///   [recentActivityIds], [lastShownFamily]) always resolves to the same
///   [ActivityId] — no scoring, no AI, no probabilistic ranking, no
///   randomness.
/// - **Per-intention anti-repetition (Batch 2 — see
///   [ADR-012](../../../../docs/product/adr/ADR-012-batch-2-recommendation-diversity.md)):**
///   [recentActivityIds] is excluded from the candidate pool first.
/// - **Cross-direction family avoidance (Batch 1 / V1 — ADR-013):** among
///   whatever survives that first filter, any candidate sharing
///   [lastShownFamily] (the semantic family of the immediately prior
///   Circle, regardless of which [Intention] it belonged to) is excluded
///   next — but only when doing so still leaves at least one candidate;
///   otherwise this second filter is skipped entirely rather than
///   emptying the pool. This is a second, independent, fixed exclusion
///   step — not a scored or weighted rule, and not a general recommendation
///   engine.
///
/// [RecommendationNotifier] (`recommendation_provider.dart`) is the sole
/// caller and is responsible for keeping [recentActivityIds] bounded to at
/// most `pool.length - 1` entries for [intention] (see
/// [recommendationHistoryKeyFor]'s own doc comment) — that cap is what
/// guarantees the first filter alone can never empty the pool. If a caller
/// ever violates that cap (e.g. a future pool shrinks below what the cap
/// assumes), the documented fallback at each stage is to ignore that
/// stage's exclusion entirely for this call and fall through to the next
/// stage (or, at the last stage, the full unfiltered pool) — never a
/// deadlock, and never a cross-[Intention] substitution.
ActivityId selectActivityId({
  required Intention intention,
  required int dayIndex,
  Set<ActivityId> recentActivityIds = const {},
  ActivitySemanticFamily? lastShownFamily,
}) {
  final pool = activityPools[intention]!;

  final afterHistory = pool
      .where((id) => !recentActivityIds.contains(id))
      .toList();
  final historyFiltered = afterHistory.isEmpty ? pool : afterHistory;

  final afterFamily = historyFiltered
      .where((id) => activityFamily(id) != lastShownFamily)
      .toList();
  final effectivePool = afterFamily.isEmpty ? historyFiltered : afterFamily;

  return effectivePool[dayIndex % effectivePool.length];
}
