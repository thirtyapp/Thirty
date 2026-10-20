/// StageBriefs (ADR-024 §5, §7, §8): the bounded condition a Circle Plan's
/// stage puts on the Personal Guided Circle composer — and nothing more.
///
/// A brief is pure composition data: which gate-passing Circles count as
/// "this stage today". It never holds a Plan's place, history, entitlement
/// or copy; it never relaxes a hard limit, the quality gate or the ranking
/// ([composeCircle] stays the only composer). Nothing in the live app uses a
/// brief yet — Plans arrive in B3/B4.
library;

import '../../home/application/activity_catalog.dart';
import '../../home/domain/recommendation_engine.dart';
import '../../home/domain/recommendation_policy.dart';
import 'circle_composer.dart';
import 'circle_elements.dart';
import 'composer_policy.dart';

/// The ≈ 20 size a brief that serves up to ≈ 20 composes at on an
/// up-to-30 day (C2).
final int _twentySize = TimeWindow.about20.maxMinutes;

/// One stage's condition on today's Circle.
class StageBrief {
  StageBrief._(
    this._accepts, {
    required this.id,
    required this.need,
    required this.drawsOn,
    required this.servesUpToTwenty,
  });

  /// A fixed stage: its [condition] on the Circle's parts.
  factory StageBrief.of(
    String id,
    Intention need,
    bool Function(List<CirclePart> parts) condition, {
    bool servesUpToTwenty = false,
  }) => StageBrief._(
    (parts, size) =>
        (!servesUpToTwenty || size <= _twentySize) && condition(parts),
    id: id,
    need: need,
    drawsOn: [id],
    servesUpToTwenty: servesUpToTwenty,
  );

  /// Stable, e.g. `getting_going.1`.
  final String id;
  final Intention need;

  /// The fixed stages this brief is made of: itself, or — for a stage-5
  /// brief — the earlier stages it combines.
  final List<String> drawsOn;

  /// Composes at ≈ 20 size on an up-to-30 day (C2: E1, E2).
  final bool servesUpToTwenty;

  final bool Function(List<CirclePart> parts, int size) _accepts;

  /// The window the composer fills for this brief on a [window] day.
  int sizeFor(TimeWindow window) => servesUpToTwenty
      ? (window.maxMinutes < _twentySize ? window.maxMinutes : _twentySize)
      : window.maxMinutes;

  /// Whether a gate-passing Circle of [parts], composed at [size] minutes,
  /// follows this brief. A brief that serves up to ≈ 20 is never followed
  /// by a Circle composed larger.
  bool accepts(List<CirclePart> parts, {required int size}) =>
      _accepts(parts, size);

  /// ADR-024 I2, "Keep this Plan's Circles gentler for now": this brief
  /// with every part low-effort as well — one more condition, nothing
  /// relaxed (C1). Composed one size down ([gentlerWindow]).
  StageBrief gentler() => StageBrief._(
    (parts, size) =>
        _accepts(parts, size) &&
        parts.every((p) => p.definition.effort == ActivityEffort.low),
    id: id,
    need: need,
    drawsOn: drawsOn,
    servesUpToTwenty: servesUpToTwenty,
  );
}

/// ADR-024 I2: the time a gentler stage composes for — one size below
/// today's, never below ≈ 10.
TimeWindow gentlerWindow(TimeWindow window) => switch (window) {
  TimeWindow.upTo30 => TimeWindow.about20,
  TimeWindow.about20 || TimeWindow.about10 => TimeWindow.about10,
};

// ---------------------------------------------------------------------------
// The fifteen launch briefs (ADR-024 §8). Stage 5 is derived (§7).

ElementId _mainOf(List<CirclePart> parts) =>
    parts.firstWhere((p) => partRole(parts, p) == ElementRole.main).element;

CircleElement _mainElement(List<CirclePart> parts) => elementOf(_mainOf(parts));

/// The second piece directly after the main one, if any.
CircleElement? _secondElement(List<CirclePart> parts) {
  for (final part in parts) {
    if (partRole(parts, part) == ElementRole.second) return part.definition;
  }
  return null;
}

bool _mainIn(List<CirclePart> parts, Set<ElementId> ids) =>
    ids.contains(_mainOf(parts));

/// Whether one of [ids] sits in one of [roles].
bool _inRoles(
  List<CirclePart> parts,
  Set<ElementId> ids,
  Set<ElementRole> roles,
) => parts.any(
  (p) => ids.contains(p.element) && roles.contains(partRole(parts, p)),
);

bool _contains(List<CirclePart> parts, ElementId id) =>
    parts.any((p) => p.element == id);

/// The kinds that "move you" (E2, E3).
const _moving = {ElementKind.movement, ElementKind.music, ElementKind.tidying};

const _mainOrSecond = {ElementRole.main, ElementRole.second};

final List<StageBrief> launchStageBriefs = List.unmodifiable([
  // Getting going — More Energy.
  StageBrief.of(
    'getting_going.1', // Loosen up
    Intention.moreEnergy,
    (parts) =>
        _mainIn(parts, {ElementId.standingStretch, ElementId.gentleStretch}),
    servesUpToTwenty: true,
  ),
  StageBrief.of(
    'getting_going.2', // On your feet
    Intention.moreEnergy,
    (parts) {
      final second = _secondElement(parts);
      return _mainIn(parts, {
            ElementId.moveToMusic,
            ElementId.activeJob,
            ElementId.quickClearUp,
            ElementId.clearCorner,
          }) &&
          (second == null || !_moving.contains(second.kind));
    },
    servesUpToTwenty: true,
  ),
  StageBrief.of(
    'getting_going.3', // Two together
    Intention.moreEnergy,
    (parts) {
      final main = _mainElement(parts).kind;
      final second = _secondElement(parts)?.kind;
      return (_moving.contains(main) || main == ElementKind.walking) &&
          second != null &&
          _moving.contains(second) &&
          second != main;
    },
  ),
  StageBrief.of(
    'getting_going.4', // Fresh air
    Intention.moreEnergy,
    (parts) =>
        _mainElement(parts).kind == ElementKind.walking ||
        _inRoles(parts, {ElementId.daylight}, {ElementRole.second}),
  ),
  // Making room — Clearer Head.
  StageBrief.of(
    'making_room.1', // Out of your head
    Intention.clearerHead,
    (parts) =>
        _inRoles(parts, {ElementId.getItOut}, _mainOrSecond) &&
        !_contains(parts, ElementId.chooseOne) &&
        !_contains(parts, ElementId.firstStep),
  ),
  StageBrief.of(
    'making_room.2', // Room around you
    Intention.clearerHead,
    (parts) => _inRoles(parts, {
      ElementId.clearCorner,
      ElementId.quickClearUp,
      ElementId.tendOne,
    }, _mainOrSecond),
  ),
  StageBrief.of(
    'making_room.3', // Down to one
    Intention.clearerHead,
    (parts) =>
        _contains(parts, ElementId.chooseOne) ||
        _mainOf(parts) == ElementId.oneTask,
  ),
  StageBrief.of(
    'making_room.4', // Less coming in
    Intention.clearerHead,
    (parts) {
      if (_mainOf(parts) == ElementId.phoneFreeWalk) return true;
      final arrival = parts.first;
      return _mainIn(parts, {
            ElementId.listenOne,
            ElementId.readPages,
            ElementId.quietMusic,
            ElementId.sitOutside,
          }) &&
          partRole(parts, arrival) == ElementRole.arrive &&
          {
            ElementId.phoneFaceDown,
            ElementId.closeWhatsOpen,
          }.contains(arrival.element);
    },
  ),
  // Slowing down — Gentler Pace.
  StageBrief.of(
    'slowing_down.1', // Slow hands
    Intention.gentlerPace,
    (parts) => _mainIn(parts, {ElementId.warmDrink, ElementId.tendOne}),
  ),
  StageBrief.of(
    'slowing_down.2', // Ease the body
    Intention.gentlerPace,
    (parts) =>
        _inRoles(parts, {ElementId.gentleStretch}, _mainOrSecond) ||
        _inRoles(
          parts,
          {ElementId.neckAndShoulders},
          {ElementRole.arrive, ElementRole.second},
        ),
  ),
  StageBrief.of(
    'slowing_down.3', // Something quiet
    Intention.gentlerPace,
    (parts) => _mainIn(parts, {
      ElementId.quietMusic,
      ElementId.listenOne,
      ElementId.readPages,
    }),
  ),
  StageBrief.of(
    'slowing_down.4', // Somewhere slower
    Intention.gentlerPace,
    (parts) =>
        _mainIn(parts, {
          ElementId.easyWalk,
          ElementId.sitOutside,
          ElementId.roundTheBlock,
        }) ||
        _inRoles(parts, {ElementId.daylight}, {ElementRole.second}),
  ),
]);

/// [launchStageBriefs] by id.
final Map<String, StageBrief> stageBriefById = Map.unmodifiable({
  for (final brief in launchStageBriefs) brief.id: brief,
});

/// The stage-5 ids, one per Plan, and the need each serves.
const Map<String, Intention> stageFiveIds = {
  'getting_going.5': Intention.moreEnergy,
  'making_room.5': Intention.clearerHead,
  'slowing_down.5': Intention.gentlerPace,
};

// ---------------------------------------------------------------------------
// Composing a stage (C1–C4).

/// Why a would-be stage Circle is blocked by the user's own controls.
enum StageBlockReason { leftOut, notSuggested, resting }

/// One part of a Circle that would follow the brief, blocked by a control.
class StageBlock {
  const StageBlock(this.element, this.role, this.reason);

  final ElementId element;
  final ElementRole role;
  final StageBlockReason reason;
}

/// Today's answer for a stage.
sealed class StageComposition {
  const StageComposition();
}

/// A Circle follows the stage today.
final class StageComposed extends StageComposition {
  const StageComposed(this.circle, this.brief);

  final ComposedCircle circle;

  /// The brief it follows — for stage 5, which combination.
  final StageBrief brief;
}

/// No Circle follows the stage today for a temporary reason — time,
/// yesterday's main piece, today's constraint — or because nothing honest
/// exists. The stage stays where it is (C3).
final class StageWaits extends StageComposition {
  const StageWaits();
}

/// No Circle follows the stage today, and one would if the user's own
/// controls were ignored (C3): [blocks] are that Circle's blocked parts.
final class StageSetAside extends StageComposition {
  const StageSetAside(this.blocks);

  final List<StageBlock> blocks;
}

/// Every rest the user's own answers caused, lifted — for the set-aside
/// probe only.
final DateTime _beyondEveryAnswer = DateTime.utc(9999);

/// Today's Circle for a stage whose [briefs] are tried in order — one
/// brief for a fixed stage, a stage-5 brief's candidates in preference
/// order. Pure: nothing is read or written beyond its arguments.
///
/// 1. The first brief [composeCircle] composes for → [StageComposed].
/// 2. Else the same, with the user's own controls ignored — no Leave it
///    out, no Don't suggest, every rest from their answers lifted — while
///    safety, the window, yesterday's main piece and today's constraint
///    stay in force. Composes → [StageSetAside].
/// 3. Else → [StageWaits].
///
/// "Not this one today" is a [ComposerContext.constraint] like any other:
/// one recomposition inside the brief. What follows a wait — the ordinary
/// Personal Guided Circle, then Free — is the caller's (C4).
StageComposition composeStage(
  ComposerContext context,
  Iterable<PastCircle> history,
  List<StageBrief> briefs, {
  SuggestionControls controls = SuggestionControls.none,
  Set<ElementId> leftOut = const {},
  RecommendationPolicy policy = RecommendationPolicy.initial,
  ComposerPolicy composerPolicy = ComposerPolicy.initial,
}) {
  if (briefs.isEmpty) throw ArgumentError.value(briefs, 'briefs', 'empty');
  for (final brief in briefs) {
    final circle = composeCircle(
      context,
      history,
      controls: controls,
      leftOut: leftOut,
      policy: policy,
      composerPolicy: composerPolicy,
      brief: brief,
    );
    if (circle != null) return StageComposed(circle, brief);
  }
  final ignored = SuggestionControls(
    restsLifted: {
      for (final activity in ActivityId.values)
        (activity, context.need): _beyondEveryAnswer,
    },
  );
  for (final brief in briefs) {
    final probe = composeCircle(
      context,
      history,
      controls: ignored,
      policy: policy,
      composerPolicy: composerPolicy,
      brief: brief,
    );
    if (probe == null) continue;
    final memory = RecommendationMemory.of(
      context.date,
      history,
      policy,
      restsLifted: controls.restsLifted,
    );
    final parts = probe.plan.parts;
    return StageSetAside([
      for (final part in parts)
        if (!elementStanding(
          part.definition,
          context.need,
          memory,
          controls: controls,
          leftOut: leftOut,
          policy: policy,
          composerPolicy: composerPolicy,
        ).allowed)
          StageBlock(
            part.element,
            partRole(parts, part),
            leftOut.contains(part.element)
                ? StageBlockReason.leftOut
                : controls.notSuggested.contains((
                    part.definition.from,
                    context.need,
                  ))
                ? StageBlockReason.notSuggested
                : StageBlockReason.resting,
          ),
    ]);
  }
  return const StageWaits();
}

// ---------------------------------------------------------------------------
// Stage 5 (§7).

/// What the caller knows of one earlier stage this cycle: only whether it
/// was set aside and the user's answer, if any — never whether anything
/// was done, or worked.
class EarlierStage {
  const EarlierStage(this.stageId, {this.setAside = false, this.answer});

  final String stageId;
  final bool setAside;
  final PastUsefulness? answer;
}

/// Which of §7's cases stage 5 is built from.
enum StageFiveBasis {
  /// A — no positive answer: earlier stages that weren't rejected, mixed.
  noAnswers,

  /// B — one positive stage, leading.
  onePositive,

  /// C — several positive stages, the most positive two together.
  severalPositive,
}

/// Why no last Circle is made.
enum NoStageFiveReason {
  /// D — every earlier stage that wasn't set aside was "Not useful".
  allRejected,

  /// Every earlier stage was set aside.
  allSetAside,
}

sealed class StageFive {
  const StageFive();
}

/// Stage 5's briefs, in the order [composeStage] tries them.
final class StageFiveBriefs extends StageFive {
  const StageFiveBriefs(this.basis, this.briefs);

  final StageFiveBasis basis;
  final List<StageBrief> briefs;
}

/// No last Circle is composed (case D) — never forced from rejected stages.
final class NoStageFive extends StageFive {
  const NoStageFive(this.reason);

  final NoStageFiveReason reason;
}

/// Stage 5 of [stageFiveId] from the cycle's [earlier] stages on [date].
///
/// Negative and set-aside stages are never used; nothing is fabricated.
/// Positive answers order Very before Somewhat, ties by the composer's
/// date-seeded hash. A candidate that draws on a brief serving up to ≈ 20
/// is tried as composed at today's size, then at ≈ 20 size.
StageFive stageFive(
  String stageFiveId,
  List<EarlierStage> earlier,
  DateTime date,
) {
  final need = stageFiveIds[stageFiveId];
  if (need == null) {
    throw ArgumentError.value(stageFiveId, 'stageFiveId', 'not a stage 5');
  }
  final plan = stageFiveId.substring(0, stageFiveId.indexOf('.'));
  int strength(EarlierStage stage) => switch (stage.answer) {
    PastUsefulness.veryUseful => 2,
    PastUsefulness.somewhatUseful => 1,
    _ => 0,
  };
  final eligible = <StageBrief>[];
  final positive = <EarlierStage>[];
  for (final stage in earlier) {
    final brief = stageBriefById[stage.stageId];
    if (brief == null || !stage.stageId.startsWith('$plan.')) {
      throw ArgumentError.value(stage.stageId, 'earlier', 'not this Plan');
    }
    if (stage.setAside || stage.answer == PastUsefulness.notUseful) continue;
    eligible.add(brief);
    if (strength(stage) > 0) positive.add(stage);
  }
  if (eligible.isEmpty) {
    return NoStageFive(
      earlier.every((s) => s.setAside)
          ? NoStageFiveReason.allSetAside
          : NoStageFiveReason.allRejected,
    );
  }

  StageBrief combine(
    List<StageBrief> members,
    bool Function(Iterable<bool> accepted) rule,
  ) => StageBrief._(
    (parts, size) =>
        rule([for (final m in members) m.accepts(parts, size: size)]),
    id: stageFiveId,
    need: need,
    drawsOn: [for (final m in members) m.id],
    servesUpToTwenty: false,
  );

  /// [brief], then — when it draws on a brief serving up to ≈ 20 — the
  /// same at ≈ 20 size.
  Iterable<StageBrief> sized(StageBrief brief) sync* {
    yield brief;
    final members = [for (final id in brief.drawsOn) stageBriefById[id]!];
    if (!brief.servesUpToTwenty && members.any((m) => m.servesUpToTwenty)) {
      yield StageBrief._(
        brief._accepts,
        id: brief.id,
        need: need,
        drawsOn: brief.drawsOn,
        servesUpToTwenty: true,
      );
    }
  }

  StageBrief alone(StageBrief brief) => StageBrief._(
    brief._accepts,
    id: stageFiveId,
    need: need,
    drawsOn: [brief.id],
    servesUpToTwenty: brief.servesUpToTwenty,
  );

  if (positive.isEmpty) {
    // A — and D with unanswered stages: a mix of at least two, else one.
    return StageFiveBriefs(StageFiveBasis.noAnswers, [
      if (eligible.length > 1)
        ...sized(combine(eligible, (a) => a.where((x) => x).length >= 2)),
      ...sized(combine(eligible, (a) => a.any((x) => x))),
    ]);
  }
  if (positive.length == 1) {
    // B — led by the positive stage, with another that wasn't rejected;
    // else the positive stage alone, as a deliberate return.
    final lead = stageBriefById[positive.single.stageId]!;
    final others = [
      for (final b in eligible)
        if (b != lead) b,
    ];
    return StageFiveBriefs(StageFiveBasis.onePositive, [
      if (others.isNotEmpty)
        ...sized(
          combine([lead, ...others], (a) {
            final accepted = a.toList();
            return accepted.first && accepted.skip(1).any((x) => x);
          }),
        ),
      alone(lead),
    ]);
  }
  // C — the most positive pair first, then the next pairs, else the single
  // most positive stage.
  final ranked = [...positive]
    ..sort((a, b) {
      final byStrength = strength(b).compareTo(strength(a));
      if (byStrength != 0) return byStrength;
      return dateSeededHash(
        date,
        b.stageId,
      ).compareTo(dateSeededHash(date, a.stageId));
    });
  final briefs = [for (final s in ranked) stageBriefById[s.stageId]!];
  return StageFiveBriefs(StageFiveBasis.severalPositive, [
    for (var i = 0; i < briefs.length; i++)
      for (var j = i + 1; j < briefs.length; j++)
        ...sized(combine([briefs[i], briefs[j]], (a) => a.every((x) => x))),
    alone(briefs.first),
  ]);
}
