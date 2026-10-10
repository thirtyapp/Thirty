/// The Premium module library (V2 Phase D, ADR-022): the reusable pieces
/// Paths try and routines are made of.
///
/// A module is one piece of a live catalogue activity with a job inside a
/// routine. It reuses that activity's own authored content (Phase A) and
/// adds only what a routine needs: its role in the sequence, and a short
/// and a full way to do it. Nothing here is new health content.
///
/// **Three treatments — never levels, difficulty or achievement.** Users
/// never see these words; a Path just tries the piece these ways:
/// - **short** — the piece alone at its short length, with only its core
///   instruction (only where an authored short form exists);
/// - **full** — the piece alone at its natural length, with the idea that
///   makes it work;
/// - **combined** — the piece joined with another as one Circle, in role
///   order ([Composition.combined]). This is what a routine is.
///
/// A Guided module (its activity's named steps) has one authored length,
/// so it has no short treatment: it is tried whole.
library;

import '../../home/application/activity_catalog.dart';

/// A module's stable identity. Stored in journal entries and routines, so a
/// value is never removed or renamed.
enum ModuleId {
  standingStretch,
  musicMove,
  activeTask,
  briskWalk,
  phoneFreeWalk,
  writeDown,
  clearSurface,
  listenOne,
  gentleStretch,
  warmDrink,
  quietMusic,
  easyWalk,
  sitOutside,
}

/// Where a module sits when it is joined with another: openers come first,
/// then the main piece, then anything that winds down.
enum ModuleRole { opener, main, closer }

/// One piece of a routine.
class SessionModule {
  const SessionModule({
    required this.id,
    required this.source,
    required this.name,
    required this.purpose,
    required this.role,
    required this.shortMinutes,
    required this.fullMinutes,
    this.shortInstruction,
    this.fullInstruction,
  }) : assert(shortMinutes <= fullMinutes);

  final ModuleId id;

  /// The live catalogue activity this piece is taken from: its fit, safety
  /// status, setting and effort are the module's.
  final ActivityId source;

  /// How the piece is named inside a routine.
  final String name;

  /// Its job inside a routine — why it earns a place.
  final String purpose;

  final ModuleRole role;

  /// The short treatment's length. Never below the source's minimum.
  final int shortMinutes;

  /// The full treatment's length: the source's natural length.
  final int fullMinutes;

  /// Open modules only: what to do in the short form, and in the full one.
  /// Guided modules use their source's own steps.
  final String? shortInstruction;
  final String? fullInstruction;

  ActivityDefinition get activity => activityDefinition(source);

  /// Whether the piece runs as its source's named steps.
  bool get guided => activity.mode == CircleMode.guidedSteps;

  /// Whether an authored short treatment exists.
  bool get hasShortForm => shortMinutes < fullMinutes;

  NeedFit fitFor(Intention need) => activity.fitFor(need);

  /// The length of this piece at [short] or full.
  int minutes({required bool short}) => short ? shortMinutes : fullMinutes;
}

/// The library. Every module is taken from a live activity — never from
/// content awaiting the safety review (tested).
const Map<ModuleId, SessionModule> moduleLibrary = {
  ModuleId.standingStretch: SessionModule(
    id: ModuleId.standingStretch,
    source: ActivityId.energisingStretchFlow,
    name: 'Standing stretch',
    purpose: 'Five minutes that get the body moving — a good way to begin.',
    role: ModuleRole.opener,
    shortMinutes: 5,
    fullMinutes: 5,
  ),
  ModuleId.musicMove: SessionModule(
    id: ModuleId.musicMove,
    source: ActivityId.moveToMusic,
    name: 'Move to music',
    purpose: 'Lifts the pace with songs you like, however you want to move.',
    role: ModuleRole.main,
    shortMinutes: 5,
    fullMinutes: 10,
    shortInstruction: 'Two songs you like. Sway, tap, walk around the room.',
    fullInstruction:
        'Put on a song you really like. Start small, and let the next one be '
        'a bit livelier.',
  ),
  ModuleId.activeTask: SessionModule(
    id: ModuleId.activeTask,
    source: ActivityId.activeHouseholdTask,
    name: 'One active task',
    purpose:
        'Turns moving about into one useful job that keeps you on your '
        'feet.',
    role: ModuleRole.main,
    shortMinutes: 10,
    fullMinutes: 15,
    shortInstruction:
        'One job that keeps you moving — sweeping, carrying, hoovering. Stop '
        'when the time is up.',
    fullInstruction:
        'One job that keeps you on your feet, done a little quicker than '
        'usual. Music on if it helps.',
  ),
  ModuleId.briskWalk: SessionModule(
    id: ModuleId.briskWalk,
    source: ActivityId.thirtyMinuteWalk,
    name: 'A brisk walk',
    purpose: 'Gets you outside and moving at a quicker pace.',
    role: ModuleRole.main,
    shortMinutes: 15,
    fullMinutes: 25,
    shortInstruction:
        'A shorter loop: start easy, then walk a little quicker than usual.',
    fullInstruction:
        'Out the door. Start easy, then brisk — still able to talk. Turn back '
        'about halfway.',
  ),
  ModuleId.phoneFreeWalk: SessionModule(
    id: ModuleId.phoneFreeWalk,
    source: ActivityId.phoneFreeWalk,
    name: 'Phone-free walk',
    purpose: 'Puts distance between you and the screen, and the noise on it.',
    role: ModuleRole.main,
    shortMinutes: 15,
    fullMinutes: 20,
    shortInstruction:
        'Phone on silent and out of sight. Once round the block is enough.',
    fullInstruction:
        'Phone on silent and out of sight. Walk easily, and notice three '
        'things you haven’t before.',
  ),
  ModuleId.writeDown: SessionModule(
    id: ModuleId.writeDown,
    source: ActivityId.writeItDown,
    name: 'Write it down',
    purpose: 'Gets what’s circling out of your head and onto paper.',
    role: ModuleRole.opener,
    shortMinutes: 10,
    fullMinutes: 15,
    shortInstruction:
        'Write whatever’s on your mind, without sorting it. Circle the one '
        'thing that matters next.',
    fullInstruction:
        'Write without sorting — tasks, worries, anything. When you run dry, '
        'ask what else is nagging at you.',
  ),
  ModuleId.clearSurface: SessionModule(
    id: ModuleId.clearSurface,
    source: ActivityId.tidyOneSurface,
    name: 'Clear one surface',
    purpose: 'Clears one small space so the next thing has room.',
    role: ModuleRole.main,
    shortMinutes: 10,
    fullMinutes: 15,
    shortInstruction:
        'One drawer or one corner of the desk. Put back only what belongs.',
    fullInstruction:
        'One desk, drawer or shelf: everything off, then back only what '
        'belongs there.',
  ),
  ModuleId.listenOne: SessionModule(
    id: ModuleId.listenOne,
    source: ActivityId.quietAudioFocus,
    name: 'Listen to one thing',
    purpose: 'Lets one thing hold your attention, with nothing else asked.',
    role: ModuleRole.main,
    shortMinutes: 15,
    fullMinutes: 20,
    shortInstruction:
        'One album or episode, phone face down. If you drift, come back to '
        'the sound.',
    fullInstruction:
        'One album, episode or recording. Phone face down, somewhere '
        'comfortable — nothing else to do.',
  ),
  ModuleId.gentleStretch: SessionModule(
    id: ModuleId.gentleStretch,
    source: ActivityId.gentleStretchPause,
    name: 'Gentle stretch',
    purpose: 'Loosens neck and shoulders, slowly, sitting or standing.',
    role: ModuleRole.opener,
    shortMinutes: 10,
    fullMinutes: 10,
  ),
  ModuleId.warmDrink: SessionModule(
    id: ModuleId.warmDrink,
    source: ActivityId.smallComfortRitual,
    name: 'A slow warm drink',
    purpose: 'A small ritual that sets an unhurried pace for what follows.',
    role: ModuleRole.opener,
    shortMinutes: 10,
    fullMinutes: 10,
    shortInstruction:
        'Make a warm drink you’d enjoy, and wait for it at the counter.',
    fullInstruction:
        'Make a warm drink you’d enjoy. Hold the cup in both hands, phone out '
        'of reach.',
  ),
  ModuleId.quietMusic: SessionModule(
    id: ModuleId.quietMusic,
    source: ActivityId.quietMusicBreak,
    name: 'Quiet music',
    purpose: 'Somewhere comfortable, with nothing to do but listen.',
    role: ModuleRole.closer,
    shortMinutes: 10,
    fullMinutes: 15,
    shortInstruction:
        'Sit or lie down and put on something quiet. Eyes closed if you like.',
    fullInstruction:
        'Somewhere comfortable, something quiet playing. Let one song run '
        'into the next.',
  ),
  ModuleId.easyWalk: SessionModule(
    id: ModuleId.easyWalk,
    source: ActivityId.easyWalk,
    name: 'Easy walk',
    purpose: 'Slower than usual, choosing the route as you go.',
    role: ModuleRole.main,
    shortMinutes: 15,
    fullMinutes: 20,
    shortInstruction:
        'Step outside and walk slowly. Once round the block is '
        'enough.',
    fullInstruction:
        'Step outside without picking a route. Slower than usual; stop for '
        'anything that catches your eye.',
  ),
  ModuleId.sitOutside: SessionModule(
    id: ModuleId.sitOutside,
    source: ActivityId.quietSittingOutside,
    name: 'Sit outside',
    purpose: 'A few unhurried minutes outdoors, looking and listening.',
    role: ModuleRole.closer,
    shortMinutes: 10,
    fullMinutes: 15,
    shortInstruction:
        'Find somewhere outside to sit. Let your eyes rest on something far '
        'away.',
    fullInstruction:
        'Somewhere outside to sit, phone left inside. Listen to what you can '
        'hear, near and far.',
  ),
};

SessionModule moduleOf(ModuleId id) => moduleLibrary[id]!;

/// One module at one length: a piece of a Circle.
class ModuleUse {
  const ModuleUse(this.module, {required this.short});

  final ModuleId module;

  /// The short treatment rather than the full one.
  final bool short;

  SessionModule get definition => moduleOf(module);

  int get minutes => definition.minutes(short: short);

  /// `"writeDown:short"` — how a use is stored.
  String get wire => '${module.name}:${short ? 'short' : 'full'}';

  static ModuleUse? fromWire(Object? raw) {
    if (raw is! String) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final id = ModuleId.values.asNameMap()[parts[0]];
    if (id == null || (parts[1] != 'short' && parts[1] != 'full')) {
      return null;
    }
    final use = ModuleUse(id, short: parts[1] == 'short');
    // A short form a module doesn't have is its one length.
    return use.short && !use.definition.hasShortForm
        ? ModuleUse(id, short: false)
        : use;
  }

  @override
  bool operator ==(Object other) =>
      other is ModuleUse && other.module == module && other.short == short;

  @override
  int get hashCode => Object.hash(module, short);
}

/// What one Circle is made of: one module, or several joined in role
/// order. Its length is exactly the sum of its pieces — never padded or cut.
class Composition {
  Composition(List<ModuleUse> uses)
    : uses = List.unmodifiable(_inRoleOrder(uses));

  /// Openers, then main pieces, then closers — pieces of one role keep the
  /// order they were given in (a stable sort; `List.sort` is not).
  static List<ModuleUse> _inRoleOrder(List<ModuleUse> uses) => [
    for (final role in ModuleRole.values)
      ...uses.where((use) => use.definition.role == role),
  ];

  final List<ModuleUse> uses;

  int get minutes => uses.fold(0, (sum, use) => sum + use.minutes);

  bool get combined => uses.length > 1;

  Set<ModuleId> get modules => {for (final use in uses) use.module};

  /// The activities this Circle draws on — what recency and safety see.
  List<ActivityId> get activities => [
    for (final use in uses) use.definition.source,
  ];

  /// The first piece's activity: its World art and category stand for the
  /// Circle.
  ActivityId get anchor => uses.first.definition.source;

  /// "Standing stretch + Move to music".
  String get title => uses.map((use) => use.definition.name).join(' + ');

  List<String> toWire() => [for (final use in uses) use.wire];

  static Composition? fromWire(Object? raw) {
    if (raw is! List || raw.isEmpty) return null;
    final uses = <ModuleUse>[];
    for (final item in raw) {
      final use = ModuleUse.fromWire(item);
      if (use == null) return null;
      uses.add(use);
    }
    return Composition(uses);
  }

  /// Whether every piece fits [need] at all.
  bool fitsNeed(Intention need) =>
      uses.every((use) => use.definition.fitFor(need) != NeedFit.none);

  /// Whether every piece may be offered in this build.
  bool offerable({required bool allowSafetyPending}) => uses.every(
    (use) => isActivityOfferable(
      use.definition.source,
      allowSafetyPending: allowSafetyPending,
    ),
  );

  @override
  bool operator ==(Object other) =>
      other is Composition &&
      other.uses.length == uses.length &&
      [
        for (var i = 0; i < uses.length; i++) other.uses[i] == uses[i],
      ].every((same) => same);

  @override
  int get hashCode => Object.hashAll(uses);
}

/// The longest any Circle may be (PRODUCT_V2_CONTRACT — natural duration up
/// to about 30 minutes).
const maxCircleMinutes = 30;

/// The Guided-shaped session a [composition] runs as in the Circle — so a
/// routine or a joined Path step uses Phase C's Guided runtime (one part at
/// a time, Back / Next, Pause, the natural end) rather than a new one.
///
/// A single piece is its source activity exactly as authored; only a
/// joined Circle needs this. An Open piece is one part ("About 10
/// minutes"); a Guided piece contributes its own named steps. The ending is
/// the last piece's own ending line.
ActivityDefinition sessionFor(Composition composition, {String? title}) {
  final first = composition.uses.first.definition.activity;
  final last = composition.uses.last.definition.activity;
  final steps = <GuidedStep>[
    for (final use in composition.uses)
      if (use.definition.guided)
        ...use.definition.activity.steps
      else
        GuidedStep(
          name: use.definition.name,
          instruction:
              (use.short
                  ? use.definition.shortInstruction
                  : use.definition.fullInstruction) ??
              use.definition.activity.firstAction,
          cue: 'About ${use.minutes} minutes',
        ),
  ];
  final settings = {
    for (final use in composition.uses) use.definition.activity.setting,
  };
  final efforts = {
    for (final use in composition.uses) use.definition.activity.effort,
  };
  final safety = [
    for (final use in composition.uses) ?use.definition.activity.safetyNote,
  ];
  return ActivityDefinition(
    title: title ?? composition.title,
    fit: {
      for (final need in Intention.values)
        need: composition.fitsNeed(need)
            ? (composition.uses.every(
                    (u) => u.definition.fitFor(need) == NeedFit.primary,
                  )
                  ? NeedFit.primary
                  : NeedFit.secondary)
            : NeedFit.none,
    },
    minMinutes: composition.minutes,
    typicalMinutes: composition.minutes,
    mode: CircleMode.guidedSteps,
    status: ActivityStatus.live,
    v1Learning: LearningCompatibility.reset,
    reasons: {
      for (final need in Intention.values)
        need:
            'Your pieces, one after the other: '
            '${composition.uses.map((u) => u.definition.name).join(', then ')}.',
    },
    firstAction: steps.first.instruction,
    preparation: [
      for (final use in composition.uses) ?use.definition.activity.preparation,
    ].join(' ').nullIfEmpty,
    steps: steps,
    safetyNote: safety.isEmpty ? null : safety.first,
    ending: last.ending,
    family: first.family,
    category: first.category,
    worldRole: first.worldRole,
    setting: settings.contains(ActivitySetting.outdoor)
        ? ActivitySetting.outdoor
        : settings.contains(ActivitySetting.indoor)
        ? ActivitySetting.indoor
        : ActivitySetting.either,
    effort: efforts.contains(ActivityEffort.moderate)
        ? ActivityEffort.moderate
        : ActivityEffort.low,
  );
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
