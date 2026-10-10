import 'package:flutter/foundation.dart';

import '../../../core/activity_category.dart';
import '../../../core/worlds/world_scene_role.dart';
import '../domain/pace_pattern.dart';

/// The need the user picks via the Daily Context Question ("What would help
/// most today?"). Explicitly selected by the user, never inferred from
/// behaviour, mood, or any other signal — see
/// [ADR-009](../../../../docs/product/adr/ADR-009-daily-intention-question.md)
/// and `docs/product/PRODUCT_V2_CONTRACT.md`.
enum Intention { moreEnergy, clearerHead, gentlerPace }

/// The label shown for [intention] itself (used as
/// `Recommendation.intent` — see `recommendation_provider.dart`).
String intentionLabel(Intention intention) => switch (intention) {
  Intention.moreEnergy => 'More Energy',
  Intention.clearerHead => 'Clearer Head',
  Intention.gentlerPace => 'Gentler Pace',
};

/// The one-line meaning shown for [intention] on the Daily Context Question
/// (`daily_intention_prompt.dart`) — a need the user recognises and picks,
/// never a health-state description. V2: no longer tied to "this
/// half-hour", since activities now take their own natural length.
String intentionMeaning(Intention intention) => switch (intention) {
  Intention.moreEnergy => 'I want to feel a little more awake and active.',
  Intention.clearerHead =>
    'I want fewer things competing for my attention, and one thing to focus '
        'on.',
  Intention.gentlerPace =>
    "I want something gentle that doesn't feel like another demand.",
};

/// A canonical activity identity. Stable forever: journal entries, today's
/// persisted Circle and V1 Plans all store these names, so a value is never
/// removed or renamed — a concept that leaves the live catalogue is marked
/// [ActivityStatus.retired] instead, and its history keeps resolving.
enum ActivityId {
  thirtyMinuteWalk,
  moveToMusic,
  phoneFreeWalk,
  writeItDown,
  quietReading,
  easyWalk,
  quietMusicBreak,
  briskStepBurst,
  energisingStretchFlow,
  activeMovementSnack,
  energisingBreathReset,
  activeHouseholdTask,
  tidyOneSurface,
  singleTaskFocus,
  quietAudioFocus,
  focusedBreathingCount,
  restfulBreathingPause,
  gentleStretchPause,
  quietSittingOutside,
  smallComfortRitual,
  unhurriedTidyPause,
}

/// **V1 historical pool membership — NOT the V2 source of truth.**
///
/// The three hard pools of V1 (ADR-013), kept unchanged only because V1
/// Plans (`plan_catalog.dart`, replaced in Phase D) and historical fixtures
/// are defined against them. V2 need fit lives on each [ActivityDefinition]
/// as [NeedFit]; the interim selector uses [legacySelectorPool].
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

/// The catalogue version recorded on every journal entry and today's
/// Circle. **2 = the V2 catalogue (Phase A).** Entries recorded under
/// version 1 describe the V1 experience of an activity; whether their
/// answers may feed V2 learning is decided by [historicalEvidenceEligible].
const int catalogVersion = 2;

/// The catalogue version of the V1 launch catalogue (ADR-013).
const int v1CatalogVersion = 1;

/// A coarse, author-assigned grouping of "what kind of activity this is",
/// used to keep consecutive Circles from feeling like the same thing twice.
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

/// How well an activity fits one need (PRODUCT_V2_CONTRACT — Activity
/// model). There are no hard pools: [primary] and [secondary] are both
/// candidates, [none] never is.
enum NeedFit { primary, secondary, none }

/// The Circle experience an activity needs (PRODUCT_V2_CONTRACT — Circle
/// V2). Phase A records it; the mode runtimes arrive in Phase C.
enum CircleMode { open, guidedSteps, paced }

/// Where an activity happens — only what "Can't go outside" needs to know
/// (V2 Phase B, "Not this one today").
enum ActivitySetting {
  /// Indoors.
  indoor,

  /// Outdoors: never offered after "Can't go outside".
  outdoor,

  /// Wherever suits — inside works.
  either,
}

/// How much an activity asks of the body — only what "Too much for today"
/// needs to know (V2 Phase B). Not a fitness level and never inferred about
/// the user.
enum ActivityEffort {
  /// Easy on the body.
  low,

  /// Asks for a bit of energy: a quicker pace, moving about.
  moderate,
}

/// Whether an activity may be offered at all.
enum ActivityStatus {
  /// Offered in every build.
  live,

  /// Drafted, but breathing/exertion content that has not passed the
  /// separate safety/content review (PRODUCT_V2_CONTRACT — Safety gate).
  /// Offered only in internal debug builds ([safetyPendingContentAllowed]).
  safetyReviewPending,

  /// No longer part of the live catalogue. Kept only so history resolves.
  retired,
}

/// Whether V1 (catalogue version 1) answers about an activity may feed V2
/// learning (PRODUCT_V2_CONTRACT — Historical-learning compatibility).
enum LearningCompatibility {
  /// The V2 activity is materially the same experience as V1.
  compatible,

  /// The V2 activity is a materially different experience; V1 answers stay
  /// in history and export but are not V2 evidence.
  reset,
}

/// One named step of a Guided Steps activity.
class GuidedStep {
  const GuidedStep({
    required this.name,
    required this.instruction,
    required this.cue,
  });

  final String name;
  final String instruction;

  /// How long, or how many — e.g. "about 1 minute", "5 slow reaches".
  final String cue;
}

/// One activity of the V2 catalogue.
class ActivityDefinition {
  const ActivityDefinition({
    required this.title,
    required this.fit,
    required this.minMinutes,
    required this.typicalMinutes,
    required this.mode,
    required this.status,
    required this.v1Learning,
    required this.reasons,
    required this.firstAction,
    required this.ending,
    required this.family,
    required this.category,
    required this.worldRole,
    required this.setting,
    required this.effort,
    this.preparation,
    this.whileYoureThere = const [],
    this.steps = const [],
    this.lighter,
    this.safetyNote,
    this.pace,
  });

  final String title;

  /// Fit for every [Intention]; a missing key means [NeedFit.none].
  final Map<Intention, NeedFit> fit;

  /// The shortest length that is still this activity, in minutes.
  final int minMinutes;

  /// The natural length THIRTY offers, in minutes (≤ 30). The Circle's ring
  /// runs to this.
  final int typicalMinutes;

  final CircleMode mode;
  final ActivityStatus status;
  final LearningCompatibility v1Learning;

  /// Why this might fit what the user asked for — one human sentence per
  /// [NeedFit.primary] need (secondary-fit reasons arrive with Phase B).
  final Map<Intention, String> reasons;

  /// The concrete thing to do first.
  final String firstAction;

  /// What to have ready, only where something is needed.
  final String? preparation;

  /// Open mode: two or three ideas for while you're doing it.
  final List<String> whileYoureThere;

  /// Guided Steps mode: the named steps, in order.
  final List<GuidedStep> steps;

  /// A shorter or lighter way to do it, where that is meaningful.
  final String? lighter;

  /// Plain stop/comfort guidance, where the activity needs it.
  final String? safetyNote;

  /// Paced mode: the reviewed pacing pattern. Deliberately absent on every
  /// activity until the separate safety/content review supplies one; a
  /// Paced activity without it never paces (ADR-021).
  final PacePattern? pace;

  /// One calm line for the end.
  final String ending;

  final ActivitySemanticFamily family;
  final ActivityCategory category;
  final WorldSceneRole worldRole;

  /// Inside, outside or either (Phase B replacement constraints).
  final ActivitySetting setting;

  /// Low or moderate effort (Phase B replacement constraints).
  final ActivityEffort effort;

  NeedFit fitFor(Intention intention) => fit[intention] ?? NeedFit.none;
}

const _p = NeedFit.primary;
const _s = NeedFit.secondary;
const _energy = Intention.moreEnergy;
const _clearer = Intention.clearerHead;
const _gentler = Intention.gentlerPace;

/// The single source of truth for every activity THIRTY knows about. Its
/// key order is the deterministic order [legacySelectorPool] uses.
const Map<ActivityId, ActivityDefinition> activityCatalog = {
  ActivityId.thirtyMinuteWalk: ActivityDefinition(
    title: 'A brisk walk',
    fit: {_energy: _p, _clearer: _s},
    minMinutes: 15,
    typicalMinutes: 25,
    mode: CircleMode.open,
    status: ActivityStatus.live,
    // V1 was a natural-pace half hour; V2 asks for a brisk pace — a
    // materially different experience (founder decision, Phase A).
    v1Learning: LearningCompatibility.reset,
    reasons: {_energy: 'Fresh air and a quicker pace to get you moving.'},
    firstAction: 'Put on shoes you can walk in and head out the door.',
    preparation: 'Comfortable shoes, and a layer if it’s cool.',
    whileYoureThere: [
      'Start easy, then walk a little quicker than usual — brisk, but still '
          'able to talk.',
      'Let your arms swing.',
      'Turn back about halfway through your time.',
    ],
    lighter: 'A shorter loop is fine on a busy day.',
    ending: 'Slow down for the last few minutes on the way back.',
    family: ActivitySemanticFamily.walking,
    category: ActivityCategory.walking,
    worldRole: WorldSceneRole.walk,
    setting: ActivitySetting.outdoor,
    effort: ActivityEffort.moderate,
  ),
  ActivityId.moveToMusic: ActivityDefinition(
    title: 'Move to music',
    fit: {_energy: _p, _clearer: _s},
    minMinutes: 5,
    typicalMinutes: 10,
    mode: CircleMode.open,
    status: ActivityStatus.live,
    v1Learning: LearningCompatibility.compatible,
    reasons: {_energy: 'A few songs you like, and moving however feels good.'},
    firstAction: 'Put on a song you really like and turn it up a little.',
    preparation: 'Something that plays music.',
    whileYoureThere: [
      'Start small — sway, tap, walk around the room.',
      'Let the next song be a bit livelier.',
      'Nobody’s watching. There’s no right way to do this.',
    ],
    lighter: 'Two songs are enough.',
    ending: 'Let the last song be a slower one, then sit for a moment.',
    family: ActivitySemanticFamily.musicMovement,
    category: ActivityCategory.movement,
    worldRole: WorldSceneRole.move,
    setting: ActivitySetting.indoor,
    effort: ActivityEffort.moderate,
  ),
  ActivityId.phoneFreeWalk: ActivityDefinition(
    title: 'Phone-free walk',
    fit: {_energy: _s, _clearer: _p, _gentler: _s},
    minMinutes: 15,
    typicalMinutes: 20,
    mode: CircleMode.open,
    status: ActivityStatus.live,
    v1Learning: LearningCompatibility.compatible,
    reasons: {
      _clearer: 'Nothing to check, so your attention can follow one thing.',
    },
    firstAction:
        'Put your phone on silent, out of sight in a pocket or bag, and '
        'start walking.',
    preparation: 'A route you know, so you won’t need a map.',
    whileYoureThere: [
      'Notice three things you haven’t noticed before.',
      'If a thought pulls at you, let it go and look around again.',
      'Keep the pace easy enough to take things in.',
    ],
    lighter: 'Once round the block is enough.',
    ending: 'Before you take your phone out again, stand still for a moment.',
    family: ActivitySemanticFamily.walking,
    category: ActivityCategory.walking,
    worldRole: WorldSceneRole.walk,
    setting: ActivitySetting.outdoor,
    effort: ActivityEffort.low,
  ),
  ActivityId.writeItDown: ActivityDefinition(
    title: 'Write it down',
    fit: {_clearer: _p, _gentler: _s},
    minMinutes: 10,
    typicalMinutes: 15,
    mode: CircleMode.open,
    status: ActivityStatus.live,
    v1Learning: LearningCompatibility.compatible,
    reasons: {_clearer: 'Get it onto paper so you don’t have to hold it all.'},
    firstAction:
        'Grab paper or a blank note and write the first thing on your mind.',
    preparation: 'Paper and a pen, or a blank note.',
    whileYoureThere: [
      'Keep writing without sorting — tasks, worries, reminders, anything.',
      'When you run dry, ask yourself: what else is nagging at me?',
      'Don’t try to solve anything yet.',
    ],
    lighter: 'Ten minutes of writing is enough.',
    ending:
        'Circle the one thing that matters most next, then put the list '
        'away.',
    family: ActivitySemanticFamily.reflectiveWriting,
    category: ActivityCategory.quietFocus,
    worldRole: WorldSceneRole.write,
    setting: ActivitySetting.either,
    effort: ActivityEffort.low,
  ),
  ActivityId.quietReading: ActivityDefinition(
    title: 'Quiet reading',
    fit: {_clearer: _p, _gentler: _s},
    minMinutes: 15,
    typicalMinutes: 20,
    mode: CircleMode.open,
    status: ActivityStatus.live,
    v1Learning: LearningCompatibility.compatible,
    reasons: {_clearer: 'One thing to read, with nothing else competing.'},
    firstAction: 'Pick up what you’re already reading, or anything nearby.',
    preparation: 'Something to read, and notifications out of reach.',
    whileYoureThere: [
      'Find a comfortable spot with good light.',
      'If your mind wanders, reread the last line and carry on.',
      'A book or e-reader is easier than a phone, if you have one.',
    ],
    ending: 'Mark your place and look up for a moment before you move on.',
    family: ActivitySemanticFamily.quietReading,
    category: ActivityCategory.quietFocus,
    worldRole: WorldSceneRole.read,
    setting: ActivitySetting.either,
    effort: ActivityEffort.low,
  ),
  ActivityId.easyWalk: ActivityDefinition(
    title: 'Easy walk',
    fit: {_energy: _s, _clearer: _s, _gentler: _p},
    minMinutes: 15,
    typicalMinutes: 20,
    mode: CircleMode.open,
    status: ActivityStatus.live,
    v1Learning: LearningCompatibility.compatible,
    reasons: {_gentler: 'A slow walk with nowhere to get to.'},
    firstAction: 'Step outside and start walking, without picking a route.',
    preparation: 'Comfortable shoes.',
    whileYoureThere: [
      'Walk slower than you normally would.',
      'Let each corner decide the route.',
      'Stop to look at anything that catches your eye.',
    ],
    lighter: 'Once round the block is enough.',
    ending: 'Take the last few minutes even slower on the way back.',
    family: ActivitySemanticFamily.walking,
    category: ActivityCategory.walking,
    worldRole: WorldSceneRole.walk,
    setting: ActivitySetting.outdoor,
    effort: ActivityEffort.low,
  ),
  ActivityId.quietMusicBreak: ActivityDefinition(
    title: 'Quiet music break',
    fit: {_clearer: _s, _gentler: _p},
    minMinutes: 10,
    typicalMinutes: 15,
    mode: CircleMode.open,
    status: ActivityStatus.live,
    v1Learning: LearningCompatibility.compatible,
    reasons: {_gentler: 'A few quiet songs, with nothing else to do.'},
    firstAction:
        'Sit or lie down somewhere comfortable and put on something quiet.',
    preparation: 'Something that plays music. Headphones if it’s noisy.',
    whileYoureThere: [
      'Close your eyes if you like.',
      'Let one song run into the next without choosing.',
      'There’s nothing to do but listen.',
    ],
    ending: 'When the music stops, stay where you are for a moment.',
    family: ActivitySemanticFamily.quietListening,
    category: ActivityCategory.quietFocus,
    worldRole: WorldSceneRole.listen,
    setting: ActivitySetting.either,
    effort: ActivityEffort.low,
  ),
  ActivityId.briskStepBurst: ActivityDefinition(
    title: 'Stairs or a slope',
    fit: {_energy: _p},
    minMinutes: 5,
    typicalMinutes: 10,
    mode: CircleMode.guidedSteps,
    status: ActivityStatus.safetyReviewPending,
    v1Learning: LearningCompatibility.reset,
    reasons: {
      _energy: 'Short climbs, with rests, get your breathing up a little.',
    },
    firstAction: 'Find a staircase or a gentle slope nearby.',
    preparation: 'Shoes with grip, and a handrail if you use stairs.',
    steps: [
      GuidedStep(
        name: 'Warm up',
        instruction: 'Walk on the flat, or take the stairs slowly once.',
        cue: 'about 1 minute',
      ),
      GuidedStep(
        name: 'Climb',
        instruction: 'Go up at a pace that makes you breathe a little harder.',
        cue: 'one flight or one stretch of slope',
      ),
      GuidedStep(
        name: 'Rest',
        instruction: 'Walk back down slowly and let your breathing settle.',
        cue: 'as long as you need',
      ),
      GuidedStep(
        name: 'Repeat',
        instruction: 'Climb and rest again.',
        cue: '3 to 5 rounds',
      ),
      GuidedStep(
        name: 'Cool down',
        instruction: 'Finish with easy walking on the flat.',
        cue: 'about 1 minute',
      ),
    ],
    lighter: 'Two slow rounds are plenty.',
    safetyNote:
        'Stop if you feel pain, dizziness or chest discomfort. Use the '
        'handrail.',
    ending: 'Walk easily for a minute before you sit down.',
    family: ActivitySemanticFamily.stepMovement,
    category: ActivityCategory.walking,
    worldRole: WorldSceneRole.walk,
    setting: ActivitySetting.either,
    effort: ActivityEffort.moderate,
  ),
  ActivityId.energisingStretchFlow: ActivityDefinition(
    title: 'A quick standing stretch',
    fit: {_energy: _p, _clearer: _s},
    // The authored sequence takes about four to five minutes; the length
    // follows it, and nothing is added to fill a longer Circle.
    minMinutes: 5,
    typicalMinutes: 5,
    mode: CircleMode.guidedSteps,
    status: ActivityStatus.live,
    v1Learning: LearningCompatibility.reset,
    reasons: {_energy: 'A short standing sequence for when you’ve been still.'},
    firstAction: 'Stand up and reach both arms overhead.',
    preparation: 'Enough space to stretch your arms out.',
    steps: [
      GuidedStep(
        name: 'Reach up',
        instruction: 'Reach both arms overhead and stretch tall, then lower.',
        cue: '5 slow reaches',
      ),
      GuidedStep(
        name: 'Side bend',
        instruction:
            'One arm overhead, lean gently to the other side. Then switch.',
        cue: '3 each side',
      ),
      GuidedStep(
        name: 'Shoulder rolls',
        instruction: 'Roll your shoulders back in slow circles, then forward.',
        cue: 'about 30 seconds',
      ),
      GuidedStep(
        name: 'Gentle twist',
        instruction:
            'Hands on hips, turn your upper body slowly left, then '
            'right.',
        cue: '5 each way',
      ),
      GuidedStep(
        name: 'March',
        instruction: 'March on the spot, lifting your knees a little.',
        cue: 'about 1 minute',
      ),
    ],
    lighter: 'Just the reaches and the shoulder rolls.',
    safetyNote: 'Move only as far as is comfortable. Skip anything that hurts.',
    ending: 'Finish with one more long reach, then let your arms drop.',
    family: ActivitySemanticFamily.stretchMobility,
    category: ActivityCategory.movement,
    worldRole: WorldSceneRole.stretch,
    setting: ActivitySetting.either,
    effort: ActivityEffort.low,
  ),
  ActivityId.activeMovementSnack: ActivityDefinition(
    title: 'Movement snack',
    fit: {_energy: _p},
    minMinutes: 5,
    typicalMinutes: 8,
    mode: CircleMode.guidedSteps,
    status: ActivityStatus.safetyReviewPending,
    v1Learning: LearningCompatibility.reset,
    reasons: {_energy: 'A few simple moves at home, with rests in between.'},
    firstAction: 'Clear a small space near a wall and a sturdy chair.',
    preparation:
        'A clear patch of floor, a wall, and a chair that won’t slide.',
    steps: [
      GuidedStep(
        name: 'March',
        instruction: 'March on the spot at an easy pace.',
        cue: 'about 1 minute',
      ),
      GuidedStep(
        name: 'Wall push',
        instruction:
            'Hands on the wall at shoulder height. Bend your elbows, then '
            'push back.',
        cue: '8 to 10 slow ones',
      ),
      GuidedStep(
        name: 'Rest',
        instruction: 'Stand easy and let your breathing settle.',
        cue: 'about 30 seconds',
      ),
      GuidedStep(
        name: 'Sit to stand',
        instruction: 'From the chair, stand up slowly, then sit back down.',
        cue: '8 to 10 slow ones',
      ),
      GuidedStep(
        name: 'Again, if you like',
        instruction: 'Go through the moves once more, or stop here.',
        cue: 'optional',
      ),
    ],
    lighter: 'One round only.',
    safetyNote:
        'Stop if you feel pain, dizziness or chest discomfort. Use a chair '
        'that won’t slide.',
    ending: 'Finish with a minute of easy marching, slowing down.',
    family: ActivitySemanticFamily.bodyweightMovement,
    category: ActivityCategory.movement,
    worldRole: WorldSceneRole.move,
    setting: ActivitySetting.indoor,
    effort: ActivityEffort.moderate,
  ),
  // RETIRED (founder decision 1, PRODUCT_V2_CONTRACT — Catalogue status):
  // the long/brisk breathing concept is not carried into V2. Kept only so
  // history and V1 Plans still resolve; never offered, never V2 evidence.
  ActivityId.energisingBreathReset: ActivityDefinition(
    title: 'Standing breath reset',
    fit: {},
    minMinutes: 0,
    typicalMinutes: 0,
    mode: CircleMode.paced,
    status: ActivityStatus.retired,
    v1Learning: LearningCompatibility.reset,
    reasons: {
      _energy:
          'For more energy: an upright posture and a brisk breathing '
          'pattern, nothing more.',
    },
    firstAction: '',
    ending: '',
    family: ActivitySemanticFamily.breathingEnergizer,
    category: ActivityCategory.stillness,
    worldRole: WorldSceneRole.breathe,
    setting: ActivitySetting.either,
    effort: ActivityEffort.low,
  ),
  ActivityId.activeHouseholdTask: ActivityDefinition(
    title: 'One active household task',
    fit: {_energy: _p, _clearer: _s},
    minMinutes: 10,
    typicalMinutes: 15,
    mode: CircleMode.open,
    status: ActivityStatus.live,
    v1Learning: LearningCompatibility.compatible,
    reasons: {_energy: 'A job you’d do anyway, done on your feet.'},
    firstAction:
        'Pick one task that keeps you on your feet: sweeping, hoovering, '
        'carrying, or some gardening.',
    preparation: 'Whatever that one task needs.',
    whileYoureThere: [
      'Move a little quicker than you normally would.',
      'Put some music on if it helps.',
      'Stop when your time is up, even if the job isn’t finished.',
    ],
    ending: 'Put things away and leave the rest for another day.',
    family: ActivitySemanticFamily.activeChore,
    category: ActivityCategory.homeCare,
    worldRole: WorldSceneRole.tend,
    setting: ActivitySetting.either,
    effort: ActivityEffort.moderate,
  ),
  ActivityId.tidyOneSurface: ActivityDefinition(
    title: 'Tidy one surface',
    fit: {_energy: _s, _clearer: _p, _gentler: _s},
    minMinutes: 10,
    typicalMinutes: 15,
    mode: CircleMode.open,
    status: ActivityStatus.live,
    v1Learning: LearningCompatibility.compatible,
    reasons: {_clearer: 'One small space you can actually finish.'},
    firstAction: 'Pick exactly one desk, drawer or shelf.',
    whileYoureThere: [
      'Take everything off or out first.',
      'Put back only what belongs there.',
      'Anything that lives elsewhere goes in one pile for later.',
    ],
    lighter: 'A single drawer is enough.',
    ending: 'Stop when that one surface is clear. The rest can wait.',
    family: ActivitySemanticFamily.tidyReset,
    category: ActivityCategory.homeCare,
    worldRole: WorldSceneRole.tend,
    setting: ActivitySetting.indoor,
    effort: ActivityEffort.low,
  ),
  ActivityId.singleTaskFocus: ActivityDefinition(
    title: 'One task, full attention',
    fit: {_clearer: _p},
    minMinutes: 20,
    typicalMinutes: 25,
    mode: CircleMode.open,
    status: ActivityStatus.live,
    v1Learning: LearningCompatibility.compatible,
    reasons: {_clearer: 'One thing, no switching, instead of juggling it all.'},
    firstAction:
        'Choose one task that’s been on your mind, and close everything that '
        'isn’t it.',
    preparation: 'Whatever that task needs. Other tabs and apps closed.',
    whileYoureThere: [
      'Write the task down in one line, so it’s clear what you’re doing.',
      'If something else comes up, jot it down and come back.',
      'You don’t have to finish — giving it your attention is the point.',
    ],
    ending: 'Note where you got to, so it’s easy to pick up later.',
    family: ActivitySemanticFamily.singleFocusTask,
    category: ActivityCategory.quietFocus,
    worldRole: WorldSceneRole.write,
    setting: ActivitySetting.either,
    effort: ActivityEffort.low,
  ),
  ActivityId.quietAudioFocus: ActivityDefinition(
    title: 'Listen to one thing',
    fit: {_clearer: _p, _gentler: _s},
    minMinutes: 15,
    typicalMinutes: 20,
    mode: CircleMode.open,
    status: ActivityStatus.live,
    v1Learning: LearningCompatibility.compatible,
    reasons: {_clearer: 'One thing to listen to, with your phone face down.'},
    firstAction:
        'Choose one album, podcast episode or recording, and press play.',
    preparation: 'Headphones or a speaker.',
    whileYoureThere: [
      'Put your phone face down once it’s playing.',
      'Sit or lie somewhere comfortable — no need to do anything else.',
      'If you drift into thought, come back to the sound.',
    ],
    ending: 'When you stop it, sit for a moment in the quiet.',
    family: ActivitySemanticFamily.quietListening,
    category: ActivityCategory.quietFocus,
    worldRole: WorldSceneRole.listen,
    setting: ActivitySetting.either,
    effort: ActivityEffort.low,
  ),
  // Paced breathing: pace parameters are deliberately absent until the
  // separate safety/content review supplies them.
  ActivityId.focusedBreathingCount: ActivityDefinition(
    title: 'Counted breathing',
    fit: {_clearer: _p, _gentler: _s},
    minMinutes: 3,
    typicalMinutes: 5,
    mode: CircleMode.paced,
    status: ActivityStatus.safetyReviewPending,
    v1Learning: LearningCompatibility.reset,
    reasons: {_clearer: 'Counting breaths: one small thing for a busy mind.'},
    firstAction: 'Sit down somewhere quiet and let your shoulders drop.',
    safetyNote:
        'Breathe gently, at a pace that feels comfortable. If you feel '
        'light-headed, breathe normally and stop.',
    ending: 'Let the counting go and breathe normally for a moment.',
    family: ActivitySemanticFamily.breathingStillness,
    category: ActivityCategory.stillness,
    worldRole: WorldSceneRole.breathe,
    setting: ActivitySetting.either,
    effort: ActivityEffort.low,
  ),
  ActivityId.restfulBreathingPause: ActivityDefinition(
    title: 'Slow breathing pause',
    fit: {_clearer: _s, _gentler: _p},
    minMinutes: 3,
    typicalMinutes: 5,
    mode: CircleMode.paced,
    status: ActivityStatus.safetyReviewPending,
    v1Learning: LearningCompatibility.reset,
    reasons: {_gentler: 'Slow, easy breathing, with nothing to get right.'},
    firstAction: 'Sit or lie down somewhere comfortable.',
    safetyNote:
        'Breathe gently, at a pace that feels comfortable. If you feel '
        'light-headed, breathe normally and stop.',
    ending: 'Stay still for a moment before you get up.',
    family: ActivitySemanticFamily.breathingStillness,
    category: ActivityCategory.stillness,
    worldRole: WorldSceneRole.breathe,
    setting: ActivitySetting.either,
    effort: ActivityEffort.low,
  ),
  ActivityId.gentleStretchPause: ActivityDefinition(
    title: 'Gentle stretch pause',
    fit: {_energy: _s, _clearer: _s, _gentler: _p},
    minMinutes: 8,
    typicalMinutes: 10,
    mode: CircleMode.guidedSteps,
    status: ActivityStatus.live,
    v1Learning: LearningCompatibility.reset,
    reasons: {_gentler: 'Slow, easy stretches that don’t ask much of you.'},
    firstAction:
        'Sit on the edge of a chair, or stand somewhere with a little space.',
    steps: [
      GuidedStep(
        name: 'Neck',
        instruction:
            'Let your head tip slowly towards one shoulder, then the '
            'other.',
        cue: '3 each side',
      ),
      GuidedStep(
        name: 'Shoulders',
        instruction:
            'Lift your shoulders up towards your ears, then let them '
            'drop.',
        cue: '5 times',
      ),
      GuidedStep(
        name: 'Open the chest',
        instruction:
            'Hold the sides of the chair, or clasp your hands behind '
            'you, and gently open your chest.',
        cue: '5 slow breaths',
      ),
      GuidedStep(
        name: 'Seated twist',
        instruction:
            'Sit tall and turn gently to one side, one hand on the chair. Then '
            'the other side.',
        cue: '5 slow breaths each side',
      ),
      GuidedStep(
        name: 'Fold forward',
        instruction:
            'Let your upper body fold forward slowly, arms heavy. Come up '
            'slowly.',
        cue: '5 slow breaths',
      ),
    ],
    lighter: 'Just the neck and shoulders.',
    safetyNote:
        'Stay well within what feels comfortable. Skip anything that '
        'hurts.',
    ending: 'Sit still for a moment before you get up.',
    family: ActivitySemanticFamily.stretchMobility,
    category: ActivityCategory.movement,
    worldRole: WorldSceneRole.stretch,
    setting: ActivitySetting.either,
    effort: ActivityEffort.low,
  ),
  ActivityId.quietSittingOutside: ActivityDefinition(
    title: 'Sitting outside, unhurried',
    fit: {_clearer: _s, _gentler: _p},
    minMinutes: 10,
    typicalMinutes: 15,
    mode: CircleMode.open,
    status: ActivityStatus.live,
    v1Learning: LearningCompatibility.compatible,
    reasons: {_gentler: 'Somewhere outside to sit, with nowhere to be.'},
    firstAction: 'Find somewhere outside to sit — a step, a bench, a balcony.',
    preparation: 'A warm layer if it’s cool out.',
    whileYoureThere: [
      'Leave your phone inside, or face down.',
      'Let your eyes rest on something far away.',
      'Listen to what you can hear, near and far.',
    ],
    ending: 'Take one last look around before you go back in.',
    family: ActivitySemanticFamily.natureSit,
    category: ActivityCategory.stillness,
    worldRole: WorldSceneRole.breathe,
    setting: ActivitySetting.outdoor,
    effort: ActivityEffort.low,
  ),
  ActivityId.smallComfortRitual: ActivityDefinition(
    title: 'A slow warm drink',
    fit: {_clearer: _s, _gentler: _p},
    minMinutes: 10,
    typicalMinutes: 10,
    mode: CircleMode.open,
    status: ActivityStatus.live,
    v1Learning: LearningCompatibility.compatible,
    reasons: {_gentler: 'A small, warm pause that asks nothing of you.'},
    firstAction: 'Put the kettle on and make a drink you’d enjoy.',
    preparation: 'Whatever you need for a warm drink.',
    whileYoureThere: [
      'Wait for it at the counter, instead of doing something else.',
      'Hold the cup in both hands for a moment.',
      'Keep your phone out of reach while you drink.',
    ],
    ending: 'Rinse the cup, and take your time getting back to things.',
    family: ActivitySemanticFamily.comfortRitual,
    category: ActivityCategory.homeCare,
    worldRole: WorldSceneRole.comfort,
    setting: ActivitySetting.indoor,
    effort: ActivityEffort.low,
  ),
  ActivityId.unhurriedTidyPause: ActivityDefinition(
    title: 'Tend to one small thing',
    fit: {_clearer: _s, _gentler: _p},
    minMinutes: 10,
    typicalMinutes: 15,
    mode: CircleMode.open,
    status: ActivityStatus.live,
    v1Learning: LearningCompatibility.compatible,
    reasons: {
      _gentler: 'Caring for one small thing, slowly, with no deadline.',
    },
    firstAction:
        'Pick one small thing to look after: a plant, a bedside table, a '
        'single shelf.',
    whileYoureThere: [
      'Go slower than you would if you were in a hurry.',
      'Water, wipe, straighten — whatever it needs.',
      'It doesn’t need to be finished.',
    ],
    ending: 'Stand back and look at it for a moment.',
    family: ActivitySemanticFamily.tidyReset,
    category: ActivityCategory.homeCare,
    worldRole: WorldSceneRole.tend,
    setting: ActivitySetting.indoor,
    effort: ActivityEffort.low,
  ),
};

/// Whether this build may offer activities awaiting the safety/content
/// review. Only internal debug builds may — never profile or release
/// builds (PRODUCT_V2_CONTRACT — Safety gate).
const bool safetyPendingContentAllowed = kDebugMode;

/// Whether [activityId] may be offered as a Circle in this build.
bool isActivityOfferable(
  ActivityId activityId, {
  bool allowSafetyPending = safetyPendingContentAllowed,
}) => switch (activityCatalog[activityId]!.status) {
  ActivityStatus.live => true,
  ActivityStatus.safetyReviewPending => allowSafetyPending,
  ActivityStatus.retired => false,
};

/// Whether an answer recorded about [activityId] under [recordedCatalogVersion]
/// may count as evidence for V2 learning (PRODUCT_V2_CONTRACT —
/// Historical-learning compatibility). History itself is never affected.
bool historicalEvidenceEligible(
  ActivityId activityId,
  int recordedCatalogVersion,
) {
  final activity = activityCatalog[activityId]!;
  if (activity.status == ActivityStatus.retired) return false;
  if (recordedCatalogVersion >= catalogVersion) return true;
  return activity.v1Learning == LearningCompatibility.compatible;
}

/// **TEMPORARY — Phase A only; replaced by Engine V2 in Phase B.**
///
/// The candidate list the V1 rotation selector ([selectActivityId]) still
/// uses until Engine V2 exists: every offerable activity with a
/// [NeedFit.primary] fit for [intention], in catalogue order. Secondary fit
/// is deliberately unused here — weighing it is Engine V2's job.
List<ActivityId> legacySelectorPool(
  Intention intention, {
  bool allowSafetyPending = safetyPendingContentAllowed,
}) => [
  for (final entry in activityCatalog.entries)
    if (entry.value.fitFor(intention) == NeedFit.primary &&
        isActivityOfferable(entry.key, allowSafetyPending: allowSafetyPending))
      entry.key,
];

ActivityDefinition activityDefinition(ActivityId activityId) =>
    activityCatalog[activityId]!;

String activityLabel(ActivityId activityId) =>
    activityCatalog[activityId]!.title;

ActivityCategory activityCategory(ActivityId activityId) =>
    activityCatalog[activityId]!.category;

WorldSceneRole activityWorldRole(ActivityId activityId) =>
    activityCatalog[activityId]!.worldRole;

ActivitySemanticFamily activityFamily(ActivityId activityId) =>
    activityCatalog[activityId]!.family;

/// The length THIRTY offers for [activityId], in minutes. A retired
/// activity restored from history has no V2 length and falls back to the
/// V1 half hour it was offered with.
int activityTypicalMinutes(ActivityId activityId) {
  final minutes = activityCatalog[activityId]!.typicalMinutes;
  return minutes > 0 ? minutes : 30;
}

/// Why [activityId] might fit [intention]: its reason for that need, or —
/// for a pairing without one (a V1 Plan stage, or a secondary fit before
/// Phase B) — its first authored reason.
String activityReasonFor(Intention intention, ActivityId activityId) {
  final reasons = activityCatalog[activityId]!.reasons;
  return reasons[intention] ?? reasons.values.first;
}

/// The number of days since the Unix epoch for [date]'s local calendar
/// date — the deterministic day index the interim selector rotates by.
int epochDay(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

/// **TEMPORARY — Phase A only; replaced by Engine V2 in Phase B.**
///
/// Picks today's activity for [intention] from [legacySelectorPool] by
/// day-index rotation, first excluding [recentActivityIds] and then any
/// candidate sharing [lastShownFamily] — each exclusion skipped if it would
/// empty the pool. Unchanged V1 behaviour on the V2 catalogue.
ActivityId selectActivityId({
  required Intention intention,
  required int dayIndex,
  Set<ActivityId> recentActivityIds = const {},
  ActivitySemanticFamily? lastShownFamily,
  bool allowSafetyPending = safetyPendingContentAllowed,
}) {
  final pool = legacySelectorPool(
    intention,
    allowSafetyPending: allowSafetyPending,
  );

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
