/// The Personal Guided Circle's elements (V2 Phase D2, ADR-023): the small,
/// authored units Premium composes into one guided session for today.
///
/// An element is one truthful thing to do for a few minutes — arrive, do
/// the main work, an optional second piece, settle. Every field serves the
/// composer or the runtime; there is no metadata for its own sake:
/// - [CircleElement.needs], [roles], [minutes]/[shortMinutes], [setting],
///   [effort], [kind] and [after] decide what may be composed, in what
///   order and at what length;
/// - [from] ties a piece of a live activity to that activity's safety
///   status, the user's "Don't suggest" and its rests, and — only where
///   [carriesEvidence] says the experience is materially the same — to its
///   explicit evidence;
/// - [name] and [instruction] are what the runtime shows (and what spoken
///   guidance would say); [art] is the World art standing for the Circle.
///
/// **Safety (PRODUCT_V2_CONTRACT — Safety gate):** no element breathes,
/// paces or asks for exertion. No element comes from content awaiting the
/// safety review, or from retired content (tested). The composer treats
/// [isElementOfferable] as a hard limit.
library;

import '../../home/application/activity_catalog.dart';

/// A stable element identity. Stored in journal entries and kept Circles,
/// so a value is never removed or renamed — an element that leaves the
/// library is marked [ActivityStatus.retired] instead.
enum ElementId {
  // Arrive.
  phoneFaceDown,
  nameWhatsOn,
  openWindow,
  standAndReach,
  songOn,
  comfortableSpot,
  lookAround,
  // Main work, and second pieces.
  moveToMusic,
  standingStretch,
  activeJob,
  briskWalk,
  roundTheBlock,
  quickClearUp,
  daylight,
  getItOut,
  clearCorner,
  oneTask,
  listenOne,
  readPages,
  phoneFreeWalk,
  closeWhatsOpen,
  lookFar,
  warmDrink,
  gentleStretch,
  neckAndShoulders,
  quietMusic,
  easyWalk,
  sitOutside,
  tendOne,
  // Settle.
  chooseOne,
  firstStep,
  sitAMinute,
  putThingsBack,
  glassOfWater,
  shakeOut,
  whatsNext,
  noteOneThing,
  oneLongReach,
}

/// Where an element may sit. A Circle is shaped
/// ARRIVE → MAIN → optional SECOND → SETTLE; only [main] is required.
enum ElementRole { arrive, main, second, settle }

/// What kind of thing an element is. No Circle holds two of one kind, so a
/// session never does the same sort of thing twice.
enum ElementKind {
  phone,
  orient,
  writing,
  air,
  movement,
  music,
  walking,
  tidying,
  outdoors,
  sorting,
  planning,
  focus,
  listening,
  reading,
  screens,
  looking,
  ritual,
  tending,
  stillness,
}

/// One element of the library.
class CircleElement {
  const CircleElement({
    required this.id,
    required this.name,
    required this.instruction,
    required this.needs,
    required this.roles,
    required this.minutes,
    required this.kind,
    required this.setting,
    required this.art,
    this.shortMinutes,
    this.effort = ActivityEffort.low,
    this.from,
    this.carriesEvidence = false,
    this.after,
    this.leadsInto,
    this.status = ActivityStatus.live,
  }) : assert(shortMinutes == null || shortMinutes < minutes);

  final ElementId id;

  /// Its short name: the step heading while it runs, and its part of the
  /// Today card's line ("Get it out · Choose one thing · …").
  final String name;

  /// What to do, in one or two sentences. Never mentions a length: the
  /// same words hold at [minutes] and [shortMinutes].
  final String instruction;

  /// The needs it truly fits. Never inferred.
  final Set<Intention> needs;

  /// The places it may take in a Circle.
  final Set<ElementRole> roles;

  /// Its authored length, in minutes.
  final int minutes;

  /// An authored shorter length, where doing less of it is still the same
  /// thing (a shorter walk, fewer songs). `null`: one length only.
  final int? shortMinutes;

  final ElementKind kind;

  /// Inside, outside or either. One Circle never mixes outside with
  /// inside-only.
  final ActivitySetting setting;
  final ActivityEffort effort;

  /// The World art and category standing for a Circle whose main piece
  /// this is. Presentation only — never evidence or control.
  final ActivityId art;

  /// The live activity this element is, or is a piece of. Its safety
  /// status, the user's "Don't suggest" and a rest after "Not useful" for
  /// it apply to this element too.
  final ActivityId? from;

  /// Whether the element is materially the same experience as [from], so
  /// the user's explicit answers about [from] are evidence about it too. A
  /// fragment (a few stretches from a longer sequence) carries none.
  final bool carriesEvidence;

  /// An element that only makes sense after another in the same Circle
  /// ("Choose one thing" needs "Get it out" first).
  final ElementId? after;

  /// An arrival that only makes sense before a main piece of these kinds
  /// ("A comfortable spot" leads into listening or reading, never a walk).
  /// `null`: any.
  final Set<ElementKind>? leadsInto;

  final ActivityStatus status;

  /// Its lengths, longest first.
  List<int> get lengths => [minutes, ?shortMinutes];

  bool fits(Intention need) => needs.contains(need);
}

const _energy = Intention.moreEnergy;
const _head = Intention.clearerHead;
const _gentle = Intention.gentlerPace;

const _arrive = ElementRole.arrive;
const _main = ElementRole.main;
const _second = ElementRole.second;
const _settle = ElementRole.settle;

const _either = ActivitySetting.either;
const _indoor = ActivitySetting.indoor;
const _outdoor = ActivitySetting.outdoor;

/// The release element library — every element founder-reviewable in the
/// D2 content pack, none from safety-pending or retired content (tested).
const Map<ElementId, CircleElement> elementLibrary = {
  // ARRIVE — a minute or so to begin.
  ElementId.phoneFaceDown: CircleElement(
    id: ElementId.phoneFaceDown,
    name: 'Phone face down',
    instruction:
        'Silence your notifications and put your phone face down for the '
        'rest of this Circle.',
    needs: {_head, _gentle},
    roles: {_arrive},
    minutes: 1,
    kind: ElementKind.phone,
    setting: _either,
    art: ActivityId.quietAudioFocus,
  ),
  ElementId.nameWhatsOn: CircleElement(
    id: ElementId.nameWhatsOn,
    name: 'Name what’s on',
    instruction:
        'In a few words, jot down what’s taking up the most room in your '
        'head right now.',
    needs: {_head},
    roles: {_arrive},
    minutes: 1,
    kind: ElementKind.writing,
    setting: _either,
    art: ActivityId.writeItDown,
  ),
  ElementId.openWindow: CircleElement(
    id: ElementId.openWindow,
    name: 'Open a window',
    instruction:
        'Open a window or a door, and take a moment to look outside before '
        'you begin.',
    needs: {_energy, _head},
    roles: {_arrive},
    minutes: 1,
    kind: ElementKind.air,
    setting: _indoor,
    art: ActivityId.quietSittingOutside,
  ),
  ElementId.standAndReach: CircleElement(
    id: ElementId.standAndReach,
    name: 'Stand and reach',
    instruction:
        'Stand up, reach both arms overhead and stretch tall, then lower '
        'them slowly. Three or four times.',
    needs: {_energy, _head},
    roles: {_arrive},
    minutes: 1,
    kind: ElementKind.movement,
    setting: _either,
    art: ActivityId.energisingStretchFlow,
    from: ActivityId.energisingStretchFlow,
  ),
  ElementId.songOn: CircleElement(
    id: ElementId.songOn,
    name: 'Put a song on',
    instruction:
        'Put on a song you really like, a little louder than usual, and let '
        'it play while you start.',
    needs: {_energy},
    roles: {_arrive},
    minutes: 1,
    kind: ElementKind.music,
    setting: _indoor,
    art: ActivityId.moveToMusic,
    from: ActivityId.moveToMusic,
  ),
  ElementId.comfortableSpot: CircleElement(
    id: ElementId.comfortableSpot,
    name: 'A comfortable spot',
    instruction:
        'Find somewhere comfortable to sit or lie, and let your shoulders '
        'drop.',
    needs: {_gentle, _head},
    roles: {_arrive},
    minutes: 1,
    kind: ElementKind.orient,
    setting: _either,
    art: ActivityId.quietMusicBreak,
    leadsInto: {
      ElementKind.listening,
      ElementKind.reading,
      ElementKind.writing,
      ElementKind.focus,
      ElementKind.ritual,
    },
  ),
  ElementId.lookAround: CircleElement(
    id: ElementId.lookAround,
    name: 'Look around',
    instruction:
        'Look slowly around you, and find three things you hadn’t noticed '
        'before.',
    needs: {_gentle, _head},
    roles: {_arrive, _settle},
    minutes: 1,
    kind: ElementKind.looking,
    setting: _either,
    art: ActivityId.quietSittingOutside,
  ),

  // MAIN WORK — and the shorter pieces that can come second.
  ElementId.moveToMusic: CircleElement(
    id: ElementId.moveToMusic,
    name: 'Move to music',
    instruction:
        'Put on songs you like and move however feels good — sway, step, '
        'walk around the room. Let each song be a little livelier.',
    needs: {_energy},
    roles: {_main, _second},
    minutes: 8,
    shortMinutes: 5,
    kind: ElementKind.music,
    setting: _indoor,
    effort: ActivityEffort.moderate,
    art: ActivityId.moveToMusic,
    from: ActivityId.moveToMusic,
    carriesEvidence: true,
  ),
  ElementId.standingStretch: CircleElement(
    id: ElementId.standingStretch,
    name: 'Standing stretch',
    instruction:
        'Reach up, bend to each side, roll your shoulders, twist gently, '
        'then march on the spot. Only as far as is comfortable.',
    needs: {_energy, _head},
    roles: {_main, _second},
    minutes: 5,
    kind: ElementKind.movement,
    setting: _either,
    art: ActivityId.energisingStretchFlow,
    from: ActivityId.energisingStretchFlow,
    carriesEvidence: true,
  ),
  ElementId.activeJob: CircleElement(
    id: ElementId.activeJob,
    name: 'One active job',
    instruction:
        'Pick one job that keeps you on your feet — sweeping, hoovering, '
        'carrying — and do it a little quicker than usual. Stop when the '
        'time’s up.',
    needs: {_energy},
    roles: {_main},
    minutes: 12,
    shortMinutes: 8,
    kind: ElementKind.tidying,
    setting: _either,
    effort: ActivityEffort.moderate,
    art: ActivityId.activeHouseholdTask,
    from: ActivityId.activeHouseholdTask,
    carriesEvidence: true,
  ),
  ElementId.briskWalk: CircleElement(
    id: ElementId.briskWalk,
    name: 'A brisk walk',
    instruction:
        'Head out. Start easy, then walk a little quicker — brisk, but '
        'still able to talk. Turn back about halfway.',
    needs: {_energy},
    roles: {_main},
    minutes: 20,
    shortMinutes: 15,
    kind: ElementKind.walking,
    setting: _outdoor,
    effort: ActivityEffort.moderate,
    art: ActivityId.thirtyMinuteWalk,
    from: ActivityId.thirtyMinuteWalk,
    carriesEvidence: true,
  ),
  ElementId.roundTheBlock: CircleElement(
    id: ElementId.roundTheBlock,
    name: 'Round the block',
    instruction:
        'Step outside and walk once round the block, at whatever pace feels '
        'right today.',
    needs: {_energy, _head, _gentle},
    roles: {_main},
    minutes: 10,
    kind: ElementKind.walking,
    setting: _outdoor,
    art: ActivityId.easyWalk,
    from: ActivityId.easyWalk,
  ),
  ElementId.quickClearUp: CircleElement(
    id: ElementId.quickClearUp,
    name: 'Quick clear-up',
    instruction:
        'Pick one room and put away as many things as you can. Don’t sort — '
        'just put things back where they live.',
    needs: {_energy, _head},
    roles: {_main, _second},
    minutes: 5,
    kind: ElementKind.tidying,
    setting: _indoor,
    effort: ActivityEffort.moderate,
    art: ActivityId.tidyOneSurface,
  ),
  ElementId.daylight: CircleElement(
    id: ElementId.daylight,
    name: 'Into the daylight',
    instruction:
        'Step outside, or stand at an open door or window, and spend a few '
        'minutes in the daylight.',
    needs: {_energy, _head, _gentle},
    roles: {_second},
    minutes: 4,
    kind: ElementKind.outdoors,
    // Begun from inside — never after a walk that is already out there.
    setting: _indoor,
    art: ActivityId.quietSittingOutside,
  ),
  ElementId.getItOut: CircleElement(
    id: ElementId.getItOut,
    name: 'Get it out',
    instruction:
        'Write down everything on your mind — tasks, worries, reminders — '
        'without sorting. When you run dry, ask what else is nagging at you.',
    needs: {_head, _gentle},
    roles: {_main, _second},
    minutes: 6,
    shortMinutes: 4,
    kind: ElementKind.writing,
    setting: _either,
    art: ActivityId.writeItDown,
    from: ActivityId.writeItDown,
    carriesEvidence: true,
  ),
  ElementId.clearCorner: CircleElement(
    id: ElementId.clearCorner,
    name: 'Clear one corner',
    instruction:
        'One corner of a desk, one drawer or one shelf: take everything off, '
        'then put back only what belongs there.',
    needs: {_head, _energy},
    roles: {_main, _second},
    minutes: 8,
    shortMinutes: 5,
    kind: ElementKind.tidying,
    setting: _indoor,
    art: ActivityId.tidyOneSurface,
    from: ActivityId.tidyOneSurface,
    carriesEvidence: true,
  ),
  ElementId.oneTask: CircleElement(
    id: ElementId.oneTask,
    name: 'One task, no switching',
    instruction:
        'Pick one task that’s been on your mind. Close everything that isn’t '
        'it, and give it your attention until the time’s up — finished or '
        'not.',
    needs: {_head},
    roles: {_main},
    minutes: 15,
    shortMinutes: 10,
    kind: ElementKind.focus,
    setting: _either,
    art: ActivityId.singleTaskFocus,
    from: ActivityId.singleTaskFocus,
    carriesEvidence: true,
  ),
  ElementId.listenOne: CircleElement(
    id: ElementId.listenOne,
    name: 'Listen to one thing',
    instruction:
        'Put on one album, episode or recording. Phone face down, somewhere '
        'comfortable — nothing else to do but listen.',
    needs: {_head, _gentle},
    roles: {_main},
    minutes: 12,
    shortMinutes: 8,
    kind: ElementKind.listening,
    setting: _either,
    art: ActivityId.quietAudioFocus,
    from: ActivityId.quietAudioFocus,
    carriesEvidence: true,
  ),
  ElementId.readPages: CircleElement(
    id: ElementId.readPages,
    name: 'Read a few pages',
    instruction:
        'Pick up what you’re reading, or anything nearby, and read with '
        'nothing else competing. If your mind wanders, reread the last line.',
    needs: {_head, _gentle},
    roles: {_main, _second},
    minutes: 10,
    shortMinutes: 6,
    kind: ElementKind.reading,
    setting: _either,
    art: ActivityId.quietReading,
    from: ActivityId.quietReading,
    carriesEvidence: true,
  ),
  ElementId.phoneFreeWalk: CircleElement(
    id: ElementId.phoneFreeWalk,
    name: 'Phone-free walk',
    instruction:
        'Phone on silent and out of sight. Walk easily, and notice three '
        'things you haven’t noticed before.',
    needs: {_head, _gentle, _energy},
    roles: {_main},
    minutes: 15,
    shortMinutes: 10,
    kind: ElementKind.walking,
    setting: _outdoor,
    art: ActivityId.phoneFreeWalk,
    from: ActivityId.phoneFreeWalk,
    carriesEvidence: true,
  ),
  ElementId.closeWhatsOpen: CircleElement(
    id: ElementId.closeWhatsOpen,
    name: 'Close what’s open',
    instruction:
        'Close every tab, window and app you don’t need right now. Leave '
        'only what the next thing needs.',
    needs: {_head},
    roles: {_arrive},
    minutes: 3,
    kind: ElementKind.screens,
    setting: _either,
    art: ActivityId.singleTaskFocus,
    leadsInto: {
      ElementKind.focus,
      ElementKind.writing,
      ElementKind.reading,
      ElementKind.listening,
    },
  ),
  ElementId.lookFar: CircleElement(
    id: ElementId.lookFar,
    name: 'Look far away',
    instruction:
        'Look out of a window, or outside, at the furthest thing you can '
        'see, and let your eyes rest there.',
    needs: {_head, _gentle},
    roles: {_second, _settle},
    minutes: 2,
    kind: ElementKind.looking,
    setting: _either,
    art: ActivityId.quietSittingOutside,
  ),
  ElementId.warmDrink: CircleElement(
    id: ElementId.warmDrink,
    name: 'A slow warm drink',
    instruction:
        'Make a warm drink you’d enjoy. Hold the cup in both hands, and drink '
        'it slowly, phone out of reach.',
    needs: {_gentle, _head},
    roles: {_main},
    minutes: 10,
    kind: ElementKind.ritual,
    setting: _indoor,
    art: ActivityId.smallComfortRitual,
    from: ActivityId.smallComfortRitual,
    carriesEvidence: true,
  ),
  ElementId.gentleStretch: CircleElement(
    id: ElementId.gentleStretch,
    name: 'Gentle stretch',
    instruction:
        'Slowly: neck, shoulders, open the chest, a gentle seated twist, then '
        'fold forward with heavy arms. Stay well within what’s comfortable.',
    needs: {_gentle, _head, _energy},
    roles: {_main, _second},
    minutes: 8,
    kind: ElementKind.movement,
    setting: _either,
    art: ActivityId.gentleStretchPause,
    from: ActivityId.gentleStretchPause,
    carriesEvidence: true,
  ),
  ElementId.neckAndShoulders: CircleElement(
    id: ElementId.neckAndShoulders,
    name: 'Neck and shoulders',
    instruction:
        'Let your head tip slowly towards one shoulder, then the other. Lift '
        'your shoulders to your ears and let them drop. A few times each.',
    needs: {_gentle, _head, _energy},
    roles: {_arrive, _second},
    minutes: 2,
    kind: ElementKind.movement,
    setting: _either,
    art: ActivityId.gentleStretchPause,
    from: ActivityId.gentleStretchPause,
  ),
  ElementId.quietMusic: CircleElement(
    id: ElementId.quietMusic,
    name: 'Quiet music',
    instruction:
        'Somewhere comfortable, put on something quiet. Close your eyes if '
        'you like, and let one song run into the next.',
    needs: {_gentle, _head},
    roles: {_main, _second},
    minutes: 10,
    shortMinutes: 6,
    kind: ElementKind.listening,
    setting: _either,
    art: ActivityId.quietMusicBreak,
    from: ActivityId.quietMusicBreak,
    carriesEvidence: true,
  ),
  ElementId.easyWalk: CircleElement(
    id: ElementId.easyWalk,
    name: 'Easy walk',
    instruction:
        'Step outside without picking a route. Walk slower than usual, and '
        'stop for anything that catches your eye.',
    needs: {_gentle, _head},
    roles: {_main},
    minutes: 15,
    shortMinutes: 10,
    kind: ElementKind.walking,
    setting: _outdoor,
    art: ActivityId.easyWalk,
    from: ActivityId.easyWalk,
    carriesEvidence: true,
  ),
  ElementId.sitOutside: CircleElement(
    id: ElementId.sitOutside,
    name: 'Sit outside',
    instruction:
        'Find somewhere outside to sit, phone left inside. Listen to what '
        'you can hear, near and far.',
    needs: {_gentle, _head},
    roles: {_main, _second},
    minutes: 10,
    shortMinutes: 5,
    kind: ElementKind.outdoors,
    setting: _outdoor,
    art: ActivityId.quietSittingOutside,
    from: ActivityId.quietSittingOutside,
    carriesEvidence: true,
  ),
  ElementId.tendOne: CircleElement(
    id: ElementId.tendOne,
    name: 'Tend to one thing',
    instruction:
        'Pick one small thing to look after — a plant, a bedside table, a '
        'shelf — and go slower than you would in a hurry.',
    needs: {_gentle, _head},
    roles: {_main, _second},
    minutes: 8,
    shortMinutes: 5,
    kind: ElementKind.tending,
    setting: _indoor,
    art: ActivityId.unhurriedTidyPause,
    from: ActivityId.unhurriedTidyPause,
    carriesEvidence: true,
  ),

  // SETTLE — a minute or two to close.
  ElementId.chooseOne: CircleElement(
    id: ElementId.chooseOne,
    name: 'Choose one thing',
    instruction:
        'Look over what you wrote, and circle the one thing that matters '
        'most next.',
    needs: {_head},
    roles: {_second, _settle},
    minutes: 1,
    kind: ElementKind.sorting,
    setting: _either,
    art: ActivityId.writeItDown,
    after: ElementId.getItOut,
  ),
  ElementId.firstStep: CircleElement(
    id: ElementId.firstStep,
    name: 'Write the first step',
    instruction:
        'For the thing you circled, write the very first small step — small '
        'enough to start with.',
    needs: {_head},
    roles: {_settle},
    minutes: 2,
    kind: ElementKind.planning,
    setting: _either,
    art: ActivityId.writeItDown,
    after: ElementId.chooseOne,
  ),
  ElementId.sitAMinute: CircleElement(
    id: ElementId.sitAMinute,
    name: 'Sit for a minute',
    instruction:
        'Sit still for a minute or two before you move on. There’s nothing '
        'to do.',
    needs: {_gentle, _head, _energy},
    roles: {_settle},
    minutes: 2,
    kind: ElementKind.stillness,
    setting: _either,
    art: ActivityId.quietMusicBreak,
  ),
  ElementId.putThingsBack: CircleElement(
    id: ElementId.putThingsBack,
    name: 'Put things back',
    instruction: 'Put away what you used, and leave the space ready for later.',
    needs: {_gentle, _head, _energy},
    roles: {_settle},
    minutes: 2,
    kind: ElementKind.tidying,
    setting: _either,
    art: ActivityId.unhurriedTidyPause,
  ),
  ElementId.glassOfWater: CircleElement(
    id: ElementId.glassOfWater,
    name: 'A glass of water',
    instruction: 'Pour a glass of water and drink it before you carry on.',
    needs: {_energy, _head},
    roles: {_settle},
    minutes: 2,
    kind: ElementKind.ritual,
    setting: _indoor,
    art: ActivityId.smallComfortRitual,
  ),
  ElementId.shakeOut: CircleElement(
    id: ElementId.shakeOut,
    name: 'Shake it out',
    instruction:
        'Shake out your hands and arms loosely, then stand easy for a '
        'moment.',
    needs: {_energy},
    roles: {_settle},
    minutes: 1,
    kind: ElementKind.movement,
    setting: _either,
    art: ActivityId.energisingStretchFlow,
  ),
  ElementId.whatsNext: CircleElement(
    id: ElementId.whatsNext,
    name: 'Choose what’s next',
    instruction: 'Decide the one thing you’ll do next, and go to it.',
    needs: {_energy, _head},
    roles: {_settle},
    minutes: 1,
    kind: ElementKind.sorting,
    setting: _either,
    art: ActivityId.singleTaskFocus,
  ),
  ElementId.noteOneThing: CircleElement(
    id: ElementId.noteOneThing,
    name: 'Note one thing',
    instruction: 'Note down one small thing from today you’d like to remember.',
    needs: {_gentle, _head},
    roles: {_settle},
    minutes: 1,
    kind: ElementKind.writing,
    setting: _either,
    art: ActivityId.writeItDown,
  ),
  ElementId.oneLongReach: CircleElement(
    id: ElementId.oneLongReach,
    name: 'One long reach',
    instruction:
        'Finish with one long reach overhead, then let your arms drop.',
    needs: {_energy, _head},
    roles: {_settle},
    minutes: 1,
    kind: ElementKind.movement,
    setting: _either,
    art: ActivityId.energisingStretchFlow,
    from: ActivityId.energisingStretchFlow,
  ),
};

CircleElement elementOf(ElementId id) => elementLibrary[id]!;

/// Whether [element] may be composed at all: live itself, and — for a
/// piece of an activity — that activity live too. Content awaiting the
/// safety review is never composed, in any build: Premium value is never
/// built on it (ADR-023).
bool isElementOfferable(CircleElement element) {
  if (element.status != ActivityStatus.live) return false;
  final from = element.from;
  return from == null || activityDefinition(from).status == ActivityStatus.live;
}

/// One element at one of its authored lengths: a part of a Circle.
class CirclePart {
  const CirclePart(this.element, this.minutes);

  final ElementId element;
  final int minutes;

  CircleElement get definition => elementOf(element);

  /// `"getItOut:4"` — how a part is stored.
  String get wire => '${element.name}:$minutes';

  /// A stored part, or `null` if it isn't one of the element's authored
  /// lengths — never a made-up length.
  static CirclePart? fromWire(Object? raw) {
    if (raw is! String) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final id = ElementId.values.asNameMap()[parts[0]];
    final minutes = int.tryParse(parts[1]);
    if (id == null || minutes == null) return null;
    if (!elementOf(id).lengths.contains(minutes)) return null;
    return CirclePart(id, minutes);
  }

  @override
  bool operator ==(Object other) =>
      other is CirclePart &&
      other.element == element &&
      other.minutes == minutes;

  @override
  int get hashCode => Object.hash(element, minutes);

  @override
  String toString() => wire;
}

/// A composed Circle's parts, in order. Its length is exactly the sum of
/// its parts — never padded, never cut.
class CirclePlan {
  CirclePlan(List<CirclePart> parts) : parts = List.unmodifiable(parts);

  final List<CirclePart> parts;

  int get minutes => parts.fold(0, (sum, part) => sum + part.minutes);

  Set<ElementId> get elements => {for (final p in parts) p.element};

  /// The main piece: its art stands for the Circle.
  CirclePart get main => parts.firstWhere(
    (p) => p.definition.roles.contains(ElementRole.main),
    orElse: () => parts.first,
  );

  /// The live activities this Circle draws on — what recency sees.
  List<ActivityId> get activities => [
    for (final p in parts) ?p.definition.from,
  ];

  /// "Get it out · Choose one thing · Sit for a minute".
  String get line => parts.map((p) => p.definition.name).join(' · ');

  List<String> toWire() => [for (final p in parts) p.wire];

  static CirclePlan? fromWire(Object? raw) {
    if (raw is! List || raw.isEmpty) return null;
    final parts = <CirclePart>[];
    for (final item in raw) {
      final part = CirclePart.fromWire(item);
      if (part == null) return null;
      parts.add(part);
    }
    return CirclePlan(parts);
  }

  @override
  bool operator ==(Object other) =>
      other is CirclePlan &&
      other.parts.length == parts.length &&
      [
        for (var i = 0; i < parts.length; i++) other.parts[i] == parts[i],
      ].every((same) => same);

  @override
  int get hashCode => Object.hashAll(parts);

  @override
  String toString() => toWire().join(' ');
}
