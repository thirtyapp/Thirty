/// The Personal Guided Circle composer (V2 Phase D2, ADR-023 §3): one pure,
/// local, deterministic decision — today's guided session, or none.
///
/// [composeCircle] reads no clock, storage or randomness: the same inputs
/// always give the same Circle. Its inputs are bounded to what the user
/// told THIRTY — today's need and time, their explicit answers, their
/// "Don't suggest" and "Leave this out" choices — and what THIRTY offered
/// before. No profile, no inferred mood, no model.
///
/// **Quality gate.** Premium never composes merely because the user pays.
/// A Circle is composed only when every part is allowed and safe, the parts
/// make a coherent shape (ARRIVE → MAIN → SECOND → SETTLE, no kind twice,
/// a part that builds on another directly after it, outside never mixed with
/// inside-only), the main piece holds a real share of the time, the whole
/// fits the window and uses enough of it, and no part repeats. Otherwise
/// the answer is `null`, and Today is Free's one activity.
///
/// **StageBrief (ADR-024 C1–C2).** An optional [StageBrief] only narrows
/// which gate-passing Circles may be chosen; every hard limit, the gate and
/// the ranking stay exactly as they are. Without one, nothing changes.
library;

import 'dart:convert';

import '../../home/application/activity_catalog.dart';
import '../../home/domain/recommendation_engine.dart';
import '../../home/domain/recommendation_policy.dart';
import 'circle_elements.dart';
import 'composer_policy.dart';
import 'stage_brief.dart';

/// Today's "Not this one today" on a composed Circle: a hard constraint for
/// the one recomposition.
class CompositionConstraint {
  const CompositionConstraint({required this.reason, required this.replacing});

  final ReplacementReason reason;

  /// Today's Circle, which is never offered again today.
  final CirclePlan replacing;
}

/// Everything the user told THIRTY about today.
class ComposerContext {
  const ComposerContext({
    required this.date,
    required this.need,
    required this.window,
    this.constraint,
  });

  final DateTime date;
  final Intention need;
  final TimeWindow window;
  final CompositionConstraint? constraint;
}

/// What the Today card may truthfully say about a composed Circle.
enum CompositionBasis {
  /// At least one part is something the user has found useful for this
  /// need: positive explicit evidence, including a "Very useful" answer,
  /// within the window.
  foundUseful,

  /// Nothing personal to claim: the Circle is sized to today's time.
  sized,
}

/// The composer's answer.
class ComposedCircle {
  const ComposedCircle({
    required this.plan,
    required this.basis,
    required this.score,
    required this.trace,
  });

  final CirclePlan plan;
  final CompositionBasis basis;

  /// For tests and QA — never shown.
  final double score;
  final String trace;
}

/// A past composed Circle's substance — its main and second piece — the
/// parts its answer is about. Read once per Circle.
final _substance = Expando<Set<String>>('substance');

Set<String> _substanceOf(PastCircle circle) => _substance[circle] ??= () {
  final plan = CirclePlan.fromWire(circle.parts);
  if (plan == null) return const <String>{};
  final core = _coreOf(plan);
  return {core.$1.name, ?core.$2?.name};
}();

/// Whether a past composed Circle's answer is evidence about [element]: it
/// was that Circle's main or second piece, and the user didn't skip it. An
/// arrival or a close never takes credit for a day's answer — the answer is
/// about what the session was made of.
bool Function(PastCircle) composedWith(ElementId element) =>
    (c) =>
        c.composed &&
        !c.skipped.contains(element.name) &&
        _substanceOf(c).contains(element.name);

/// How one element stands for one need today, derived fresh from the
/// journal — never stored.
class ElementStanding {
  const ElementStanding({
    required this.element,
    required this.allowed,
    required this.evidence,
    required this.provenUseful,
    this.excludedBecause,
  });

  final CircleElement element;

  /// Whether it may be composed today at all.
  final bool allowed;

  /// Its explicit evidence, from −2 to 2: the confidence-weighted mean of
  /// the answers about its own activity (only where it carries that
  /// activity's evidence) and about composed Circles it was the substance of
  /// (unskipped, at half weight). A mean, not a sum: how often a part was
  /// offered never compounds into how much it is liked. (Routine evidence
  /// is retired with routines, ADR-024.)
  final double evidence;

  /// Whether "things you've found useful" may name it.
  final bool provenUseful;

  /// Why it may not be composed — for QA traces and Memory.
  final String? excludedBecause;
}

/// [element]'s standing for [need] in [memory].
ElementStanding elementStanding(
  CircleElement element,
  Intention need,
  RecommendationMemory memory, {
  SuggestionControls controls = SuggestionControls.none,
  Set<ElementId> leftOut = const {},
  RecommendationPolicy policy = RecommendationPolicy.initial,
  ComposerPolicy composerPolicy = ComposerPolicy.initial,
}) {
  String? excluded;
  final from = element.from;
  if (!isElementOfferable(element)) {
    excluded = 'not offerable';
  } else if (!element.fits(need)) {
    excluded = 'other need';
  } else if (leftOut.contains(element.id)) {
    excluded = 'left out';
  } else if (from != null && controls.notSuggested.contains((from, need))) {
    excluded = 'don’t suggest';
  } else if (from != null) {
    final days = memory.daysSinceNotUseful(from, need);
    if (days != null && days <= policy.restDays) excluded = 'resting';
  }

  const none = (sum: 0.0, weight: 0.0);
  final carries = element.carriesEvidence && from != null;
  final own = carries
      ? memory.answersWhere((c) => !c.composite && c.activityId == from, need)
      : none;
  final about = composedWith(element.id);
  final composed = memory.answersWhere(about, need);
  final half = composerPolicy.composedEvidenceFactor;
  final sum = own.sum + half * composed.sum;
  final weight = own.weight + half * composed.weight;
  final mean = weight == 0 ? 0.0 : sum / weight;
  // Little evidence counts for little: the mean, scaled by confidence.
  final evidence = mean * weight / (weight + 1);
  final veryUseful =
      (carries && memory.veryUsefulFor(from, need)) ||
      memory.veryUsefulWhere(about, need);
  return ElementStanding(
    element: element,
    allowed: excluded == null,
    evidence: evidence,
    provenUseful: veryUseful && mean >= 1 && weight >= 1,
    excludedBecause: excluded,
  );
}

/// Whether [parts] make a coherent Circle, whatever today's time: at least
/// two parts with a main piece; no element and no kind twice; a part that
/// builds on another comes directly after it; an arrival leads only into
/// what it suits;
/// outside never mixed with inside-only.
bool coherentParts(List<CirclePart> parts, {required int mainIndex}) {
  if (parts.length < 2) return false;
  final ids = <ElementId>{};
  final kinds = <ElementKind>{};
  var outdoor = false;
  var indoor = false;
  for (final (index, part) in parts.indexed) {
    final element = part.definition;
    if (!ids.add(element.id) || !kinds.add(element.kind)) return false;
    // A part that builds on another comes directly after it.
    final after = element.after;
    if (after != null && (index == 0 || parts[index - 1].element != after)) {
      return false;
    }
    switch (element.setting) {
      case ActivitySetting.outdoor:
        outdoor = true;
      case ActivitySetting.indoor:
        indoor = true;
      case ActivitySetting.either:
        break;
    }
  }
  if (outdoor && indoor) return false;
  final main = parts[mainIndex].definition;
  for (final arrival in parts.take(mainIndex)) {
    final leadsInto = arrival.definition.leadsInto;
    if (leadsInto != null && !leadsInto.contains(main.kind)) return false;
  }
  return main.roles.contains(ElementRole.main);
}

/// A stable 32-bit FNV-1a hash: the composer's date-seeded tie-break.
int _hash(String key) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(key)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash;
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// The composer's date-seeded hash of [key] on [date] — the tie-break a
/// StageBrief's stage 5 orders equally positive stages by.
int dateSeededHash(DateTime date, String key) =>
    _hash('${_dateKey(date)}|$key');

/// A plan's substance: its main piece and the second piece after it, if
/// any — what must not loop day after day.
(ElementId, ElementId?) _coreOf(CirclePlan plan) {
  final main = plan.main;
  final index = plan.parts.indexOf(main);
  final after = plan.parts
      .skip(index + 1)
      .where((p) => _roleIn(plan.parts, p) == ElementRole.second);
  return (main.element, after.isEmpty ? null : after.first.element);
}

/// The main element of a past composed Circle, if any.
ElementId? _mainOf(PastCircle circle) {
  final plan = CirclePlan.fromWire(circle.parts);
  return plan?.main.element;
}

/// The role [part] takes in [parts] — what a StageBrief's conditions read.
ElementRole partRole(List<CirclePart> parts, CirclePart part) =>
    _roleIn(parts, part);

/// The role [part] takes in [parts]: arrive before the main piece, then
/// second, then settle — a part's place, never guessed from its name.
ElementRole _roleIn(List<CirclePart> parts, CirclePart part) {
  final index = parts.indexOf(part);
  final mainIndex = parts.indexWhere(
    (p) => p.definition.roles.contains(ElementRole.main),
  );
  if (index < mainIndex) return ElementRole.arrive;
  if (index == mainIndex) return ElementRole.main;
  if (index == parts.length - 1 &&
      part.definition.roles.contains(ElementRole.settle)) {
    return ElementRole.settle;
  }
  return ElementRole.second;
}

/// Every shape that passes the quality gate for [window] from [allowed]
/// elements — ARRIVE? → MAIN → SECOND? → SETTLE?, each part at one of its
/// authored lengths. What the composer ranks, and what the coverage report
/// counts.
///
/// - The whole fits the window and uses at least
///   [ComposerPolicy.minUtilization] of it.
/// - At most [ComposerPolicy.maxParts] parts ([ComposerPolicy.maxPartsShortDay]
///   on a ≈ 10-minute day); at least two.
/// - The main piece holds at least [ComposerPolicy.minMainShare] of it, and
///   a second piece is never longer than the main one.
/// - [coherentParts].
/// - Today's [constraint], when there is one: never the same Circle; for
///   "Not feeling this one", another main piece of another kind; for "Too
///   much for today", shorter.
Iterable<List<CirclePart>> gatePassingShapes(
  List<CircleElement> allowed, {
  required int window,
  CompositionConstraint? constraint,
  bool Function(CircleElement element)? mainAllowed,
  ComposerPolicy policy = ComposerPolicy.initial,
}) sync* {
  List<CirclePart> options(ElementRole role) => [
    for (final element in allowed)
      if (element.roles.contains(role))
        for (final minutes in element.lengths) CirclePart(element.id, minutes),
  ];
  final arrives = <CirclePart?>[null, ...options(ElementRole.arrive)];
  final mains = [
    for (final part in options(ElementRole.main))
      if (mainAllowed == null || mainAllowed(part.definition)) part,
  ];
  final seconds = <CirclePart?>[null, ...options(ElementRole.second)];
  final settles = <CirclePart?>[null, ...options(ElementRole.settle)];
  final least = (policy.minUtilization * window).ceil();
  for (final main in mains) {
    if (main.minutes > window) continue;
    if (constraint != null &&
        constraint.reason == ReplacementReason.notFeeling &&
        (main.element == constraint.replacing.main.element ||
            main.definition.kind ==
                constraint.replacing.main.definition.kind)) {
      continue;
    }
    for (final arrive in arrives) {
      final withArrive = main.minutes + (arrive?.minutes ?? 0);
      if (withArrive > window) continue;
      for (final second in seconds) {
        // A second piece never outweighs the main one.
        if (second != null && second.minutes > main.minutes) continue;
        final withSecond = withArrive + (second?.minutes ?? 0);
        if (withSecond > window) continue;
        for (final settle in settles) {
          final total = withSecond + (settle?.minutes ?? 0);
          if (total > window || total < least) continue;
          final parts = [?arrive, main, ?second, ?settle];
          if (parts.length >
              (window <= 10 ? policy.maxPartsShortDay : policy.maxParts)) {
            continue;
          }
          if (main.minutes < policy.minMainShare * total) continue;
          if (!coherentParts(parts, mainIndex: arrive == null ? 0 : 1)) {
            continue;
          }
          if (constraint != null) {
            if (CirclePlan(parts) == constraint.replacing) continue;
            if (constraint.reason == ReplacementReason.tooMuch &&
                total >= constraint.replacing.minutes) {
              continue;
            }
          }
          yield parts;
        }
      }
    }
  }
}

/// Today's Personal Guided Circle, or `null` when no composition passes
/// the quality gate — then Today is Free's one activity (ADR-023 §4).
///
/// 1. **Hard limits, never relaxed:** safety, need fit, the user's "Leave
///    this out", "Don't suggest" for an element's activity, a rest after
///    "Not useful" on it, the time window, today's replacement constraint,
///    and never yesterday's main piece again (consecutive repetition is not
///    composed — Free decides instead).
/// 2. **Shape:** the quality gate above.
/// 3. **Ranking:** explicit evidence first — relevant before varied —
///    then using the window well, a settling close, a gentle arrival; less
///    recent parts, mains and identical sessions; full lengths before
///    shorter ones; then a date-seeded tie-break. Variety only ever chooses
///    among sessions the evidence rates alike: a part the user found very
///    useful is not dropped to look varied.
/// 4. **A [brief], when given:** only the Circles above that it accepts —
///    composed at ≈ 20 size on an up-to-30 day when it serves up to ≈ 20.
///    Nothing it rejects is ever broadened back in; `null` when none is left.
ComposedCircle? composeCircle(
  ComposerContext context,
  Iterable<PastCircle> history, {
  SuggestionControls controls = SuggestionControls.none,
  Set<ElementId> leftOut = const {},
  RecommendationPolicy policy = RecommendationPolicy.initial,
  ComposerPolicy composerPolicy = ComposerPolicy.initial,
  StageBrief? brief,
}) {
  final need = context.need;
  if (brief != null && brief.need != need) {
    throw ArgumentError.value(brief.id, 'brief', 'is for another need');
  }
  final window = brief?.sizeFor(context.window) ?? context.window.maxMinutes;
  final memory = RecommendationMemory.of(
    context.date,
    history,
    policy,
    restsLifted: controls.restsLifted,
  );
  final constraint = context.constraint;

  final standings = <ElementId, ElementStanding>{
    for (final element in elementLibrary.values)
      element.id: elementStanding(
        element,
        need,
        memory,
        controls: controls,
        leftOut: leftOut,
        policy: policy,
        composerPolicy: composerPolicy,
      ),
  };

  bool constraintAllows(CircleElement element) {
    if (constraint == null) return true;
    return switch (constraint.reason) {
      ReplacementReason.cantGoOutside =>
        element.setting != ActivitySetting.outdoor,
      ReplacementReason.tooMuch => element.effort == ActivityEffort.low,
      ReplacementReason.notFeeling => true,
    };
  }

  final allowed = [
    for (final s in standings.values)
      if (s.allowed && constraintAllows(s.element)) s.element,
  ];
  // Recency, from what THIRTY offered before today.
  final recent = memory.recentCircles;
  final yesterday = memory.yesterday;
  final yesterdayMain = yesterday == null
      ? null
      : (yesterday.composed ? _mainOf(yesterday) : null);
  bool touchedYesterday(CircleElement element) =>
      yesterday != null &&
      (yesterdayMain == element.id ||
          (!yesterday.composed &&
              element.from != null &&
              yesterday.touches(element.from!)));
  final lastComposed = recent.where((c) => c.composed && c.need == need);
  final lastPlan = lastComposed.isEmpty
      ? null
      : CirclePlan.fromWire(lastComposed.first.parts);

  final daysSinceComposed = <ElementId, int>{};
  final weeklyParts = <ElementId, int>{};
  for (final c in recent.reversed) {
    if (!c.composed) continue;
    for (final part in CirclePlan.fromWire(c.parts)?.parts ?? const []) {
      daysSinceComposed[part.element] = memory.ageOf(c);
      if (memory.ageOf(c) <= 7) {
        weeklyParts[part.element] = (weeklyParts[part.element] ?? 0) + 1;
      }
    }
  }

  int mainOffersThisWeek(CircleElement element) => recent
      .where(
        (c) =>
            memory.ageOf(c) <= 7 &&
            (c.composed
                ? _mainOf(c) == element.id
                : element.from != null && c.touches(element.from!)),
      )
      .length;

  final recentPlans = [
    for (final c in recent)
      if (c.composed && memory.ageOf(c) <= composerPolicy.samePlanDays)
        ?CirclePlan.fromWire(c.parts)?.elements,
  ];
  bool samePlanRecently(Set<ElementId> elements) => recentPlans.any(
    (seen) => seen.length == elements.length && seen.containsAll(elements),
  );

  // The main pieces composed for this need in the last month.
  final mainsThisMonth = {
    for (final c in recent)
      if (c.composed &&
          c.need == need &&
          memory.ageOf(c) <= composerPolicy.untriedMainDays)
        ?_mainOf(c),
  };

  // Identical sessions within the week: not composed again while anything
  // else passes the gate.
  final weekPlans = [
    for (final c in recent)
      if (c.composed && memory.ageOf(c) <= composerPolicy.identicalPlanDays)
        ?CirclePlan.fromWire(c.parts)?.elements,
  ];
  bool identicalThisWeek(Set<ElementId> elements) => weekPlans.any(
    (seen) => seen.length == elements.length && seen.containsAll(elements),
  );

  // The session's substance — its main and second piece — within the week.
  final recentCores = <(ElementId, ElementId?)>{};
  for (final c in recent) {
    if (!c.composed || memory.ageOf(c) > composerPolicy.coreRepeatDays) {
      continue;
    }
    final plan = CirclePlan.fromWire(c.parts);
    if (plan != null) recentCores.add(_coreOf(plan));
  }

  double scorePart(CirclePart part, {required bool main}) {
    final element = part.definition;
    final standing = standings[element.id]!;
    var score =
        composerPolicy.evidenceWeight *
        standing.evidence *
        (main
            ? composerPolicy.mainEvidenceFactor
            : composerPolicy.supportEvidenceFactor);
    if (part.minutes < element.minutes) score -= composerPolicy.shortFormCost;
    // Something not yet tried as the main piece for this need lately — so a
    // few early favourites never stop everything else from being met.
    if (main &&
        standing.evidence >= 0 &&
        !mainsThisMonth.contains(element.id)) {
      score += composerPolicy.untriedMainBonus;
    }
    final since = daysSinceComposed[element.id];
    if (since != null && since <= composerPolicy.recentPartDays) {
      score -= main
          ? composerPolicy.recentMainCost
          : composerPolicy.recentPartCost;
    }
    final from = element.from;
    if (from != null) {
      final declined = memory.daysSinceDeclined(from);
      if (declined != null && declined <= policy.declinedContextDays) {
        score -= composerPolicy.declinedCost;
      }
    }
    return score;
  }

  final partScores = <(CirclePart, bool), double>{};
  double partScore(CirclePart part, {required bool main}) =>
      partScores[(part, main)] ??= scorePart(part, main: main);

  final dateKey = _dateKey(context.date);
  ComposedCircle? best;
  var considered = 0;
  var relaxed = false;
  // First within the weekly caps; only if nothing passes the gate there,
  // without them — the composer's version of Free's relaxation order.
  for (final capped in [true, false]) {
    final within = capped
        ? [
            for (final element in allowed)
              if ((weeklyParts[element.id] ?? 0) < composerPolicy.partWeeklyCap)
                element,
          ]
        : allowed;
    for (final parts in gatePassingShapes(
      within,
      window: window,
      constraint: constraint,
      // Never yesterday's main piece again; within the caps, never a main
      // piece already offered twice this week.
      mainAllowed: (element) =>
          !touchedYesterday(element) &&
          (!capped ||
              mainOffersThisWeek(element) < composerPolicy.mainWeeklyCap),
      policy: composerPolicy,
    )) {
      if (brief != null && !brief.accepts(parts, size: window)) continue;
      final plan = CirclePlan(parts);
      if (capped && identicalThisWeek(plan.elements)) continue;
      considered++;
      final main = plan.main;
      var score = 0.0;
      for (final part in parts) {
        score += partScore(part, main: part == main);
      }
      final total = plan.minutes;
      final use = total / window;
      score += composerPolicy.fillWeight * use;
      // At or above the target, a bonus; below it, a cost that grows with
      // what is left unused — a short session must earn its place.
      score += use >= composerPolicy.targetUtilization
          ? composerPolicy.targetUseBonus
          : composerPolicy.targetUseBonus -
                (composerPolicy.targetUtilization - use) *
                    composerPolicy.underUseCost;
      bool has(ElementRole role) =>
          parts.any((p) => p != main && _roleIn(parts, p) == role);
      if (has(ElementRole.settle)) score += composerPolicy.settleBonus;
      if (has(ElementRole.arrive)) score += composerPolicy.arriveBonus;
      if (has(ElementRole.second) && window >= 20) {
        score += composerPolicy.secondBonus;
      }
      if (recentCores.contains(_coreOf(plan))) {
        score -= composerPolicy.coreRepeatCost;
      }
      if (samePlanRecently(plan.elements)) score -= composerPolicy.samePlanCost;
      if (lastPlan != null) {
        if (lastPlan.parts.first.element == parts.first.element) {
          score -= composerPolicy.sameEdgeCost;
        }
        if (lastPlan.parts.last.element == parts.last.element) {
          score -= composerPolicy.sameEdgeCost;
        }
      }
      final key = plan.toWire().join(',');
      // A fraction far below any real difference: it only separates ties.
      score += _hash('$dateKey|${need.name}|$key') / 0x100000000 * 0.01;

      if (best == null || score > best.score) {
        best = ComposedCircle(
          plan: plan,
          basis: CompositionBasis.sized,
          score: score,
          trace: '',
        );
      }
    }
    if (best != null) break;
    relaxed = true;
  }
  if (best == null) return null;

  final plan = best.plan;
  final proven = plan.parts.any((p) => standings[p.element]!.provenUseful);
  return ComposedCircle(
    plan: plan,
    basis: proven ? CompositionBasis.foundUseful : CompositionBasis.sized,
    score: best.score,
    trace: [
      if (brief != null) 'brief=${brief.id}',
      if (relaxed) 'relaxed',
      'considered=$considered',
      'score=${best.score.toStringAsFixed(2)}',
      for (final p in plan.parts)
        '${p.wire}(e${standings[p.element]!.evidence.toStringAsFixed(1)}'
            '${standings[p.element]!.provenUseful ? ' U' : ''})',
    ].join(' '),
  );
}
