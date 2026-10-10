/// Recommendation Engine V2 (ADR-020): one pure, deterministic decision.
///
/// [recommend] takes today's context, the user's past Circles and the
/// [RecommendationPolicy], and returns one [RecommendationDecision]. It
/// reads no clock, no storage and no randomness: the same inputs always give
/// the same pick. Gathering the inputs (`recommendation_provider.dart`),
/// persisting the decision (the provider and the Circle journal) and
/// presenting it (the Today card) all live elsewhere.
library;

import 'dart:convert';

import '../application/activity_catalog.dart';
import 'recommendation_policy.dart';

/// Roughly how much time the user has today (PRODUCT_V2_CONTRACT — Time
/// windows). It is the room available, never a length to fill.
enum TimeWindow {
  about10(10),
  about20(20),
  upTo30(30);

  const TimeWindow(this.maxMinutes);

  /// The longest offer that fits.
  final int maxMinutes;

  /// The window used when the user has never chosen one.
  static const firstUse = TimeWindow.about20;
}

/// Why the user asked for a different activity today ("Not this one
/// today"). Today's hard constraint; never a usefulness answer.
enum ReplacementReason { cantGoOutside, tooMuch, notFeeling }

/// The decisive evidence behind a pick. At most one is ever shown, and only
/// those with [visibleCopy].
enum RecommendationReason {
  /// A new user's curated start for this need.
  starter,

  /// The best fit today, with nothing personal to say about it.
  bestFit,

  /// The user found this useful for this need before.
  usefulHere,

  /// A secondary fit the user found useful for another need.
  usefulElsewhere,

  /// Deterministic exploration: something not yet tried for this need.
  tryingNew,

  /// A rule had to give way — repetition, a rest — because nothing else fit.
  fallback,

  /// V2 Phase D: today's Circle is the next step of the user's Path; the
  /// engine was not asked. Its own one line is the step's.
  pathStep,

  /// "Can't go outside": an indoor replacement.
  replacedIndoor,

  /// "Too much for today": a lighter replacement.
  replacedLighter,

  /// "Not feeling this one": something different.
  replacedDifferent;

  /// The one line shown on the Today card, or `null` when this reason is
  /// internal only.
  String? get visibleCopy => switch (this) {
    usefulHere || usefulElsewhere => 'You found this useful before.',
    tryingNew => 'Something new to try for this.',
    replacedIndoor => 'An indoor one instead.',
    replacedLighter => 'Something lighter instead.',
    replacedDifferent => 'Something different instead.',
    starter || bestFit || fallback || pathStep => null,
  };
}

/// The user's explicit usefulness answer, as the engine sees it.
enum PastUsefulness { veryUseful, somewhatUseful, notUseful }

/// One past local day's Circle, reduced to what the engine may use.
class PastCircle {
  const PastCircle({
    required this.date,
    required this.need,
    required this.activityId,
    required this.catalogVersion,
    this.usefulness,
    this.replacedFrom,
    this.answeredAt,
    this.window,
    this.routineId,
    this.routineVersionId,
    this.pathRunId,
    this.components = const [],
    this.replacedFromRoutineId,
  });

  /// The local calendar date (time of day ignored).
  final DateTime date;
  final Intention need;

  /// The activity finally offered that day.
  final ActivityId activityId;

  /// The catalogue version the offer was made under — decides whether its
  /// answer may count (`historicalEvidenceEligible`).
  final int catalogVersion;

  /// `null`: no answer — UNKNOWN, zero weight. "Didn't try" is never an
  /// answer here.
  final PastUsefulness? usefulness;

  /// The activity declined that day with "Not this one today", if any.
  final ActivityId? replacedFrom;

  /// When the answer was given (the Circle's close), if known — what a
  /// lifted rest is compared against.
  final DateTime? answeredAt;

  /// The time the user chose that day, if recorded (V2 entries). Only the
  /// memory page's usual-time observation reads it.
  final TimeWindow? window;

  /// V2 Phase D: the user's routine this Circle is evidence for — a Circle
  /// of that routine, or a Path Circle of the same pieces that built it —
  /// and which of its versions.
  final String? routineId;
  final String? routineVersionId;

  /// V2 Phase D: the Path run the Circle belonged to.
  final String? pathRunId;

  /// V2 Phase D: every activity a Circle joining several pieces drew on.
  /// Empty for a single activity.
  final List<ActivityId> components;

  /// V2 Phase D: the routine declined that day with "Not this one today".
  final String? replacedFromRoutineId;

  /// Whether the answer is about something other than [activityId] alone —
  /// a routine, or several pieces joined. Such an answer is that routine's
  /// evidence, never evidence about the activities inside it.
  bool get composite => routineId != null || components.length > 1;

  /// Whether the Circle drew on [activity] at all — what recency sees.
  bool touches(ActivityId activity) =>
      activityId == activity || components.contains(activity);
}

/// The user's explicit suggestion controls (V2 Phase C, ADR-021) — direct
/// choices on the memory page, kept apart from Circle history and never
/// folded into derived scores.
class SuggestionControls {
  const SuggestionControls({
    this.notSuggested = const {},
    this.restsLifted = const {},
    this.routinesNotSuggested = const {},
  });

  static const none = SuggestionControls();

  /// "Don't suggest" for an activity and a need: a hard constraint, never
  /// relaxed by variety, fallback or exploration, until the user reverses
  /// it.
  final Set<(ActivityId, Intention)> notSuggested;

  /// "Suggest again" on a resting activity: answers given before this
  /// moment no longer rest it for that need. The answers stay, and so does
  /// their bounded evidence; a later "Not useful" rests it again.
  final Map<(ActivityId, Intention), DateTime> restsLifted;

  /// V2 Phase D: "Don't suggest" for one of the user's routines and a need
  /// — the same hard constraint, for a routine.
  final Set<(String, Intention)> routinesNotSuggested;
}

/// V2 Phase D: one of the user's routines, as the engine sees it — an
/// ordinary candidate, ranked by exactly the same rules as an activity. Being
/// a routine earns it nothing.
class RoutineCandidate {
  const RoutineCandidate({
    required this.id,
    required this.fit,
    required this.forms,
    required this.components,
    required this.setting,
    required this.effort,
  });

  final String id;

  /// How it fits each need (a missing need is [NeedFit.none]).
  final Map<Intention, NeedFit> fit;

  /// The versions THIRTY may offer and their real lengths, longest first:
  /// today gets the first that fits the window — never a cut-down one.
  final List<({String versionId, int minutes})> forms;

  /// The activities it is made of, in order.
  final List<ActivityId> components;

  final ActivitySetting setting;
  final ActivityEffort effort;

  /// Its first piece: its family is the routine's, for variety.
  ActivityId get anchor => components.first;

  NeedFit fitFor(Intention need) => fit[need] ?? NeedFit.none;
}

/// Today's replacement request.
class ReplacementRequest {
  const ReplacementRequest({
    required this.reason,
    required this.replacing,
    required this.replacingMinutes,
    this.replacingRoutineId,
    this.replacingComponents = const [],
  });

  final ReplacementReason reason;

  /// Today's current offer, which is never offered again today — for a
  /// routine or a Path step, its first piece.
  final ActivityId replacing;
  final int replacingMinutes;

  /// V2 Phase D: today's offer, when it was a routine.
  final String? replacingRoutineId;

  /// V2 Phase D: every piece of today's offer, when it joined several —
  /// none of them is offered again today.
  final List<ActivityId> replacingComponents;

  bool replaces(ActivityId activity) =>
      activity == replacing || replacingComponents.contains(activity);
}

/// Everything the user told THIRTY about today.
class RecommendationContext {
  const RecommendationContext({
    required this.date,
    required this.need,
    required this.window,
    this.replacement,
    this.allowSafetyPending = safetyPendingContentAllowed,
    this.routines = const [],
  });

  /// Today's local date (time of day ignored).
  final DateTime date;
  final Intention need;
  final TimeWindow window;
  final ReplacementRequest? replacement;

  /// Whether content awaiting the safety review may be offered (internal
  /// debug builds only).
  final bool allowSafetyPending;

  /// V2 Phase D: the user's enabled routines — candidates like any other.
  final List<RoutineCandidate> routines;
}

/// The engine's answer.
class RecommendationDecision {
  const RecommendationDecision({
    required this.activityId,
    required this.offeredMinutes,
    required this.reason,
    required this.trace,
    this.routineId,
    this.routineVersionId,
  });

  /// The activity — for a routine, its first piece.
  final ActivityId activityId;

  /// V2 Phase D: the routine picked, and the version that fits today.
  final String? routineId;
  final String? routineVersionId;

  /// A real length of this activity that fits today's window: never padded,
  /// and for Guided/Paced content never cut short.
  final int offeredMinutes;
  final RecommendationReason reason;

  /// How the decision was reached, for tests and QA — never shown.
  final String trace;
}

/// The length [activity] can truthfully be offered at within [window], or
/// `null` if it cannot fit. Open activities may run anywhere from their
/// minimum to their typical length; Guided and Paced content runs at its
/// authored length or not at all.
int? offeredMinutesFor(ActivityDefinition activity, TimeWindow window) {
  if (activity.minMinutes > window.maxMinutes) return null;
  if (activity.mode == CircleMode.open) {
    return activity.typicalMinutes <= window.maxMinutes
        ? activity.typicalMinutes
        : window.maxMinutes;
  }
  return activity.typicalMinutes <= window.maxMinutes
      ? activity.typicalMinutes
      : null;
}

/// A stable, platform-independent 32-bit FNV-1a hash of today's date, the
/// need and the activity: the deterministic tie-break ("date-seeded, never
/// dayIndex % n").
int stableTieBreak(DateTime date, Intention need, ActivityId activity) =>
    _tieBreak(date, need, activity.name);

int _tieBreak(DateTime date, Intention need, String subject) {
  var hash = 0x811c9dc5;
  final key = '${_dateKey(date)}|${need.name}|$subject';
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

DateTime _day(DateTime date) => DateTime.utc(date.year, date.month, date.day);

int _daysBetween(DateTime earlier, DateTime later) =>
    _day(later).difference(_day(earlier)).inDays;

/// What the past says, derived fresh from [PastCircle]s every time — never
/// stored (PRODUCT_V2_CONTRACT — Memory contract, "Derived").
class RecommendationMemory {
  RecommendationMemory._(this._today, this._past, this._policy, this._lifted);

  /// The memory of every Circle before [today]. [restsLifted] — the user's
  /// "Suggest again" on resting activities ([SuggestionControls]).
  factory RecommendationMemory.of(
    DateTime today,
    Iterable<PastCircle> history,
    RecommendationPolicy policy, {
    Map<(ActivityId, Intention), DateTime> restsLifted = const {},
  }) {
    final past = history.where((c) => _daysBetween(c.date, today) > 0).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return RecommendationMemory._(today, past, policy, restsLifted);
  }

  final DateTime _today;
  final List<PastCircle> _past;
  final RecommendationPolicy _policy;
  final Map<(ActivityId, Intention), DateTime> _lifted;

  /// Whether the user lifted the rest this answer would cause.
  bool _restLifted(PastCircle c) {
    if (c.composite) return false;
    final liftedAt = _lifted[(c.activityId, c.need)];
    if (liftedAt == null) return false;
    return !(c.answeredAt ?? c.date).isAfter(liftedAt);
  }

  int _age(PastCircle c) => _daysBetween(c.date, _today);

  bool _counts(PastCircle c) =>
      c.usefulness != null &&
      _age(c) <= _policy.evidenceWindowDays &&
      (c.composite ||
          historicalEvidenceEligible(c.activityId, c.catalogVersion));

  double _weight(PastCircle c) =>
      _age(c) > _policy.evidenceHalfLifeDays ? 0.5 : 1.0;

  /// An answer about [activity] alone — never one about a routine or about
  /// several pieces joined.
  static bool Function(PastCircle) _aboutActivity(ActivityId activity) =>
      (c) => !c.composite && c.activityId == activity;

  static bool Function(PastCircle) _aboutRoutine(String routineId) =>
      (c) => c.routineId == routineId;

  double _strength(bool Function(PastCircle) about, Intention need) {
    var strength = 0.0;
    for (final c in _past) {
      if (!about(c) || c.need != need || !_counts(c)) continue;
      strength +=
          _weight(c) *
          switch (c.usefulness!) {
            PastUsefulness.veryUseful => 2,
            PastUsefulness.somewhatUseful => 1,
            PastUsefulness.notUseful => -2,
          };
    }
    return strength;
  }

  double _strengthElsewhere(bool Function(PastCircle) about, Intention need) {
    var best = 0.0;
    for (final other in Intention.values) {
      if (other == need) continue;
      final s = _strength(about, other);
      if (s > best) best = s;
    }
    return best;
  }

  bool _veryUseful(bool Function(PastCircle) about, Intention need) =>
      _past.any(
        (c) =>
            about(c) &&
            c.need == need &&
            c.usefulness == PastUsefulness.veryUseful &&
            _counts(c),
      );

  int? _daysSinceNotUseful(bool Function(PastCircle) about, Intention need) {
    for (final c in _past.reversed) {
      if (about(c) &&
          c.need == need &&
          c.usefulness == PastUsefulness.notUseful &&
          _counts(c) &&
          !_restLifted(c)) {
        return _age(c);
      }
    }
    return null;
  }

  /// The user's explicit evidence for ([activity], [need]): "Very useful"
  /// +2, "Somewhat useful" +1, "Not useful" −2, halved once older than the
  /// half-life, nothing beyond the window. Ineligible V1 answers never
  /// count, and neither do answers about a routine.
  double strengthFor(ActivityId activity, Intention need) =>
      _strength(_aboutActivity(activity), need);

  /// The strongest positive evidence for [activity] under any other need.
  double strengthElsewhere(ActivityId activity, Intention need) =>
      _strengthElsewhere(_aboutActivity(activity), need);

  /// Whether the user answered "Very useful" for ([activity], [need]) within
  /// the window — what a visible "You found this useful before." needs.
  bool veryUsefulFor(ActivityId activity, Intention need) =>
      _veryUseful(_aboutActivity(activity), need);

  /// Whether the user answered "Very useful" for [activity] under another
  /// need within the window.
  bool veryUsefulElsewhere(ActivityId activity, Intention need) =>
      Intention.values.any((o) => o != need && veryUsefulFor(activity, o));

  /// V2 Phase D: the same evidence for one of the user's routines.
  double routineStrength(String routineId, Intention need) =>
      _strength(_aboutRoutine(routineId), need);

  double routineStrengthElsewhere(String routineId, Intention need) =>
      _strengthElsewhere(_aboutRoutine(routineId), need);

  bool routineVeryUseful(String routineId, Intention need) =>
      _veryUseful(_aboutRoutine(routineId), need);

  bool routineVeryUsefulElsewhere(String routineId, Intention need) =>
      Intention.values.any((o) => o != need && routineVeryUseful(routineId, o));

  /// The last [count] Circles of [need], newest first.
  List<PastCircle> lastFor(Intention need, int count) => [
    for (final c in _past.reversed)
      if (c.need == need && _age(c) <= _policy.evidenceWindowDays) c,
  ].take(count).toList();

  /// Days since the latest "Not useful" for ([activity], [need]) that still
  /// rests it — one given after any "Suggest again" — or `null`.
  int? daysSinceNotUseful(ActivityId activity, Intention need) =>
      _daysSinceNotUseful(_aboutActivity(activity), need);

  int? routineDaysSinceNotUseful(String routineId, Intention need) =>
      _daysSinceNotUseful(_aboutRoutine(routineId), need);

  /// Whether another need's recent "Not useful" for [activity] is still
  /// within its rest.
  bool notUsefulElsewhere(ActivityId activity, Intention need) {
    for (final other in Intention.values) {
      if (other == need) continue;
      final days = daysSinceNotUseful(activity, other);
      if (days != null && days <= _policy.restDays) return true;
    }
    return false;
  }

  /// Whether another activity of [activity]'s family was found "Not useful"
  /// for [need] recently.
  bool familyNotUseful(ActivityId activity, Intention need) {
    final family = activityFamily(activity);
    for (final c in _past.reversed) {
      if (_age(c) > _policy.familyCarryOverDays) break;
      if (!c.composite &&
          c.activityId != activity &&
          c.need == need &&
          c.usefulness == PastUsefulness.notUseful &&
          activityFamily(c.activityId) == family &&
          _counts(c)) {
        return true;
      }
    }
    return false;
  }

  /// Days since [activity] was last offered (any need, alone or as a
  /// piece of something larger), or `null`.
  int? daysSinceOffered(ActivityId activity) {
    for (final c in _past.reversed) {
      if (c.touches(activity)) return _age(c);
    }
    return null;
  }

  int? routineDaysSinceOffered(String routineId) {
    for (final c in _past.reversed) {
      if (c.routineId == routineId) return _age(c);
    }
    return null;
  }

  /// Days since [activity] was last declined with "Not this one today".
  int? daysSinceDeclined(ActivityId activity) {
    for (final c in _past.reversed) {
      if (c.replacedFrom == activity && c.replacedFromRoutineId == null) {
        return _age(c);
      }
    }
    return null;
  }

  int? routineDaysSinceDeclined(String routineId) {
    for (final c in _past.reversed) {
      if (c.replacedFromRoutineId == routineId) return _age(c);
    }
    return null;
  }

  /// Offers of any activity of [family] in the last 7 days.
  int familyOffersThisWeek(ActivitySemanticFamily family) => _past
      .where((c) => activityFamily(c.activityId) == family && _age(c) <= 7)
      .length;

  /// Offers of [activity] in the last 7 days.
  int offersThisWeek(ActivityId activity) =>
      _past.where((c) => c.touches(activity) && _age(c) <= 7).length;

  int routineOffersThisWeek(String routineId) =>
      _past.where((c) => c.routineId == routineId && _age(c) <= 7).length;

  /// Yesterday's Circle, if there was one.
  PastCircle? get yesterday {
    final last = _past.isEmpty ? null : _past.last;
    return last != null && _age(last) == 1 ? last : null;
  }

  /// Whether [activity] has ever been offered for [need] within the window.
  bool triedFor(ActivityId activity, Intention need) => _past.any(
    (c) =>
        c.touches(activity) &&
        c.need == need &&
        _age(c) <= _policy.evidenceWindowDays,
  );

  bool routineTriedFor(String routineId, Intention need) => _past.any(
    (c) =>
        c.routineId == routineId &&
        c.need == need &&
        _age(c) <= _policy.evidenceWindowDays,
  );

  /// Circles of [need] within the window.
  int circlesFor(Intention need) => _past
      .where((c) => c.need == need && _age(c) <= _policy.evidenceWindowDays)
      .length;

  /// Explicit usefulness answers for [need] that may count.
  int answersFor(Intention need) =>
      _past.where((c) => c.need == need && _counts(c)).length;

  /// Circles of [need] since the last one that offered something new for
  /// it (everything, if nothing new was ever offered).
  int circlesSinceNew(Intention need) {
    final seen = <String>{};
    var since = 0;
    for (final c in _past) {
      if (c.need != need) continue;
      final subject = c.routineId != null
          ? 'routine:${c.routineId}'
          : c.activityId.name;
      if (seen.add(subject)) {
        since = 0;
      } else {
        since++;
      }
    }
    return since;
  }
}

/// One candidate's standing today: an activity, or one of the user's
/// routines. Both are ranked by exactly the same fields and rules.
class _Candidate {
  _Candidate({
    required this.id,
    required this.minutes,
    required this.primary,
    required this.strength,
    required this.strengthElsewhere,
    required this.daysSinceOffered,
    required this.block,
    required this.penalty,
    required this.starterRank,
    required this.tieBreak,
    required this.tried,
    required this.useful,
    required this.strong,
    required this.strongElsewhere,
    required this.recentForNeed,
    required this.restAge,
    this.routineId,
    this.routineVersionId,
  });

  /// The activity — for a routine, its first piece.
  final ActivityId id;

  /// V2 Phase D: set for a routine, with the version that fits today.
  final String? routineId;
  final String? routineVersionId;

  final int minutes;
  final bool primary;
  final double strength;
  final double strengthElsewhere;
  final int? daysSinceOffered;

  /// 0: nothing against it. Otherwise the fallback level at which it may be
  /// offered: 1 weekly cap, 2 yesterday's, 3 resting after "Not useful" — a
  /// rest outranks every rule about variety.
  final int block;

  /// Soft reasons to prefer something else, counted.
  final int penalty;
  final int starterRank;
  final int tieBreak;
  final bool tried;

  /// Useful for this need, or — for a secondary fit — for another need.
  final bool useful;

  /// A "Very useful" answer for this need / for another need.
  final bool strong;
  final bool strongElsewhere;

  /// Offered in one of the last few Circles of this need.
  final bool recentForNeed;

  /// Days since a "Not useful" for this need (large when none): when a rest
  /// must give way, the one closest to ending goes first.
  final int restAge;

  bool get resting => block == 3;

  bool get isRoutine => routineId != null;

  String get label => isRoutine ? 'routine:$routineId' : id.name;

  /// 0: useful here and ready to come back. 1: a primary fit, or a
  /// secondary fit the user found useful. 2: any other secondary fit.
  int band(RecommendationPolicy policy) {
    final readyAgain =
        daysSinceOffered == null ||
        daysSinceOffered! >= policy.provenSpacingDays;
    if (strength >= policy.usefulThreshold &&
        readyAgain &&
        !recentForNeed &&
        penalty <= policy.usefulMaxSoftPenalties) {
      return 0;
    }
    if (primary || useful) return 1;
    return 2;
  }

  /// Positive evidence lifts a candidate — except straight after it was
  /// offered for this need, so it comes back rather than alternates.
  int get affinity =>
      recentForNeed ? 0 : (strength > 0 ? 2 : (strengthElsewhere > 0 ? 1 : 0));
}

/// Recommendation Engine V2: today's one activity (ADR-020). Returns `null`
/// when nothing may be offered: for a replacement, when nothing else fits
/// today's constraint; for any offer, when the user's own "Don't suggest"
/// choices leave nothing that fits ([controls], ADR-021) — their choice is
/// never overridden to keep up the appearance of a pick.
///
/// 1. **Hard limits, never relaxed:** safety status, fit NONE excluded, the
///    user's "Don't suggest", the time window, and today's replacement
///    constraint.
/// 2. **Protective rules, relaxed only in this order if nothing else is
///    left:** the weekly cap; then yesterday's activity; and only when no
///    fit that isn't resting remains, a "Not useful" rest — the oldest and
///    weakest first. The user's "Not useful" outranks variety. Recency and
///    family variety are soft reasons (below) and never exclude anything.
/// 3. **Ranking:** useful-here-and-ready first; then primary fits and
///    secondary fits the user found useful; then other secondary fits.
///    Within each: fewer soft reasons against (recent, same family as
///    yesterday, a recent "Not useful" nearby), primary before secondary,
///    positive evidence first, the curated starter order while a need is
///    new, then the date-seeded tie-break.
/// 4. **Exploration:** occasionally, something untried for this need —
///    never on a short day, never as a replacement.
///
/// **V2 Phase D — routines.** The user's routines ([RecommendationContext.
/// routines]) are gathered beside the activities under the same hard limits
/// (their own "Don't suggest", a "Don't suggest" on any piece of them, the
/// safety status of every piece, a version that truly fits the window,
/// today's replacement constraint) and ranked by the same comparison on the
/// same fields. Their evidence is their own answers. Nothing about being a
/// routine is scored: a routine wins only when its evidence and fit do.
RecommendationDecision? recommend(
  RecommendationContext context,
  Iterable<PastCircle> history, {
  RecommendationPolicy policy = RecommendationPolicy.initial,
  SuggestionControls controls = SuggestionControls.none,
}) {
  final today = _day(context.date);
  final need = context.need;
  final memory = RecommendationMemory.of(
    today,
    history,
    policy,
    restsLifted: controls.restsLifted,
  );
  bool notSuggested(ActivityId id) =>
      controls.notSuggested.contains((id, need));
  final replacement = context.replacement;
  final sparse = memory.circlesFor(need) < policy.starterCircles;
  final starter = policy.starterOrder[need] ?? const [];
  final yesterday = memory.yesterday;
  final lastForNeed = memory.lastFor(need, policy.provenSpacingCircles);

  /// Whether today's replacement constraint rules out something of this
  /// [setting], [effort] and [family] — and its soft reasons against.
  ({bool excluded, int penalty}) replacementFit({
    required ActivitySetting setting,
    required ActivityEffort effort,
    required ActivitySemanticFamily family,
    required int minutes,
    required bool gentle,
    required bool excludeFamily,
  }) {
    if (replacement == null) return (excluded: false, penalty: 0);
    var penalty = 0;
    switch (replacement.reason) {
      case ReplacementReason.cantGoOutside:
        if (setting == ActivitySetting.outdoor) {
          return (excluded: true, penalty: 0);
        }
      case ReplacementReason.tooMuch:
        if (effort != ActivityEffort.low) return (excluded: true, penalty: 0);
        // Lighter means shorter, and made to be gentle.
        if (minutes >= replacement.replacingMinutes) penalty++;
        if (!gentle) penalty += 2;
      case ReplacementReason.notFeeling:
        if (excludeFamily && family == activityFamily(replacement.replacing)) {
          return (excluded: true, penalty: 0);
        }
    }
    return (excluded: false, penalty: penalty);
  }

  List<_Candidate> gather({required bool excludeFamily}) {
    final candidates = <_Candidate>[];
    for (final MapEntry(key: id, value: activity) in activityCatalog.entries) {
      if (!isActivityOfferable(
        id,
        allowSafetyPending: context.allowSafetyPending,
      )) {
        continue;
      }
      final fit = activity.fitFor(need);
      if (fit == NeedFit.none) continue;
      // The user's own "Don't suggest": never relaxed.
      if (notSuggested(id)) continue;
      final minutes = offeredMinutesFor(activity, context.window);
      if (minutes == null) continue;
      if (replacement != null && replacement.replaces(id)) continue;
      final constraint = replacementFit(
        setting: activity.setting,
        effort: activity.effort,
        family: activity.family,
        minutes: minutes,
        gentle: activity.fitFor(Intention.gentlerPace) == NeedFit.primary,
        excludeFamily: excludeFamily,
      );
      if (constraint.excluded) continue;
      var penalty = constraint.penalty;

      final strength = memory.strengthFor(id, need);
      final elsewhere = memory.strengthElsewhere(id, need);
      final daysSince = memory.daysSinceOffered(id);
      final notUsefulDays = memory.daysSinceNotUseful(id, need);

      var block = 0;
      if (memory.offersThisWeek(id) >= policy.weeklyCap) block = 1;
      if (yesterday != null && yesterday.touches(id)) block = 2;
      if (notUsefulDays != null && notUsefulDays <= policy.restDays) {
        block = 3;
      }

      if (daysSince != null && daysSince <= policy.recentDays) penalty++;
      final declined = memory.daysSinceDeclined(id);
      if (declined != null && declined <= policy.declinedContextDays) {
        penalty++;
      }
      if (yesterday != null &&
          !yesterday.touches(id) &&
          activity.family == activityFamily(yesterday.activityId)) {
        penalty++;
      }
      if (notUsefulDays != null &&
          notUsefulDays > policy.restDays &&
          notUsefulDays <= policy.restDays * 2) {
        penalty++;
      }
      if (memory.notUsefulElsewhere(id, need)) penalty++;
      if (memory.familyNotUseful(id, need)) penalty++;
      // The last Circle of this need: let a need chosen only now and then
      // still feel varied.
      if (lastForNeed.isNotEmpty && lastForNeed.first.touches(id)) penalty++;
      // Family variety across the week, not only day to day.
      if (memory.familyOffersThisWeek(activity.family) >=
          policy.familyWeeklySoftCap) {
        penalty++;
      }
      // Time fit: the window is room, not a target — but an offer using
      // less than half of it is a weaker fit.
      if (minutes * 2 < context.window.maxMinutes) penalty++;

      final rank = starter.indexOf(id);
      candidates.add(
        _Candidate(
          id: id,
          minutes: minutes,
          primary: fit == NeedFit.primary,
          strength: strength,
          strengthElsewhere: elsewhere,
          daysSinceOffered: daysSince,
          block: block,
          penalty: penalty,
          starterRank: rank == -1 ? starter.length : rank,
          tieBreak: stableTieBreak(today, need, id),
          tried: memory.triedFor(id, need),
          useful:
              strength >= policy.usefulThreshold ||
              elsewhere >= policy.usefulThreshold,
          strong: memory.veryUsefulFor(id, need),
          strongElsewhere: memory.veryUsefulElsewhere(id, need),
          recentForNeed: lastForNeed.any((c) => c.touches(id)),
          restAge: block == 3 ? notUsefulDays! : 1 << 20,
        ),
      );
    }

    // V2 Phase D: the user's routines, under the same limits and rules.
    for (final routine in context.routines) {
      final fit = routine.fitFor(need);
      if (fit == NeedFit.none) continue;
      // "Don't suggest" — for the routine, or for any piece of it — is
      // never relaxed.
      if (controls.routinesNotSuggested.contains((routine.id, need))) {
        continue;
      }
      if (routine.components.any(notSuggested)) continue;
      // A piece resting for this need after a recent "Not useful" (not
      // lifted by "Suggest again") keeps the routine out while it rests:
      // Memory says that piece is resting, so Today never brings it back
      // inside a routine. The rest is the piece's own — answers about the
      // routine never rest its pieces — and it ends on its own (ADR-022).
      if (routine.components.any((piece) {
        final days = memory.daysSinceNotUseful(piece, need);
        return days != null && days <= policy.restDays;
      })) {
        continue;
      }
      if (!routine.components.every(
        (piece) => isActivityOfferable(
          piece,
          allowSafetyPending: context.allowSafetyPending,
        ),
      )) {
        continue;
      }
      // The longest version that truly fits — never a cut-down one.
      final form = routine.forms
          .where((f) => f.minutes <= context.window.maxMinutes)
          .firstOrNull;
      if (form == null) continue;
      final minutes = form.minutes;
      if (replacement != null &&
          (replacement.replacingRoutineId == routine.id ||
              routine.components.any(replacement.replaces))) {
        continue;
      }
      final family = activityFamily(routine.anchor);
      final constraint = replacementFit(
        setting: routine.setting,
        effort: routine.effort,
        family: family,
        minutes: minutes,
        gentle: routine.fitFor(Intention.gentlerPace) == NeedFit.primary,
        excludeFamily: excludeFamily,
      );
      if (constraint.excluded) continue;
      var penalty = constraint.penalty;

      final id = routine.id;
      final strength = memory.routineStrength(id, need);
      final elsewhere = memory.routineStrengthElsewhere(id, need);
      final daysSince = memory.routineDaysSinceOffered(id);
      final notUsefulDays = memory.routineDaysSinceNotUseful(id, need);

      var block = 0;
      if (memory.routineOffersThisWeek(id) >= policy.weeklyCap) block = 1;
      if (yesterday != null &&
          (yesterday.routineId == id ||
              routine.components.any(yesterday.touches))) {
        block = 2;
      }
      if (notUsefulDays != null && notUsefulDays <= policy.restDays) {
        block = 3;
      }

      if (daysSince != null && daysSince <= policy.recentDays) penalty++;
      final declined = memory.routineDaysSinceDeclined(id);
      if (declined != null && declined <= policy.declinedContextDays) {
        penalty++;
      }
      if (yesterday != null &&
          yesterday.routineId != id &&
          family == activityFamily(yesterday.activityId)) {
        penalty++;
      }
      if (notUsefulDays != null &&
          notUsefulDays > policy.restDays &&
          notUsefulDays <= policy.restDays * 2) {
        penalty++;
      }
      if (lastForNeed.isNotEmpty && lastForNeed.first.routineId == id) {
        penalty++;
      }
      if (memory.familyOffersThisWeek(family) >= policy.familyWeeklySoftCap) {
        penalty++;
      }
      if (minutes * 2 < context.window.maxMinutes) penalty++;

      candidates.add(
        _Candidate(
          id: routine.anchor,
          routineId: id,
          routineVersionId: form.versionId,
          minutes: minutes,
          primary: fit == NeedFit.primary,
          strength: strength,
          strengthElsewhere: elsewhere,
          daysSinceOffered: daysSince,
          block: block,
          penalty: penalty,
          // Never in the curated starter order: a routine is never a
          // newcomer's default.
          starterRank: starter.length,
          tieBreak: _tieBreak(today, need, 'routine:$id'),
          tried: memory.routineTriedFor(id, need),
          useful:
              strength >= policy.usefulThreshold ||
              elsewhere >= policy.usefulThreshold,
          strong: memory.routineVeryUseful(id, need),
          strongElsewhere: memory.routineVeryUsefulElsewhere(id, need),
          recentForNeed: lastForNeed.any((c) => c.routineId == id),
          restAge: block == 3 ? notUsefulDays! : 1 << 20,
        ),
      );
    }
    return candidates;
  }

  int compare(_Candidate a, _Candidate b) {
    for (final difference in [
      // Only when every fit is resting: the oldest rest, then the weakest
      // negative evidence, gives way first.
      b.restAge.compareTo(a.restAge),
      a.resting && b.resting ? b.strength.compareTo(a.strength) : 0,
      a.band(policy) - b.band(policy),
      a.penalty - b.penalty,
      (a.primary ? 0 : 1) - (b.primary ? 0 : 1),
      b.affinity - a.affinity,
      // While a need is new: something not yet offered for it, in the
      // curated starter order.
      sparse ? (a.tried ? 1 : 0) - (b.tried ? 1 : 0) : 0,
      sparse ? a.starterRank - b.starterRank : 0,
    ]) {
      if (difference != 0) return difference;
    }
    return a.tieBreak.compareTo(b.tieBreak);
  }

  var candidates = gather(excludeFamily: true);
  if (candidates.isEmpty &&
      replacement?.reason == ReplacementReason.notFeeling) {
    candidates = gather(excludeFamily: false);
  }
  if (candidates.isEmpty) {
    // Nothing fits today's constraint. A replacement simply has none.
    if (replacement != null) return null;
    // The user's own "Don't suggest" left nothing in this time: no pick —
    // never another activity's longer length, which they did not choose.
    final userExcludedAFit = activityCatalog.entries.any(
      (e) =>
          notSuggested(e.key) &&
          e.value.fitFor(need) != NeedFit.none &&
          isActivityOfferable(
            e.key,
            allowSafetyPending: context.allowSafetyPending,
          ) &&
          offeredMinutesFor(e.value, context.window) != null,
    );
    if (userExcludedAFit) return null;
    // Otherwise the day's first offer must still exist, so — never reached
    // with today's catalogue, which the coverage tests prove — the shortest
    // offerable fit is offered at its minimum, as a fallback.
    final shortest =
        activityCatalog.entries
            .where(
              (e) =>
                  e.value.fitFor(need) != NeedFit.none &&
                  !notSuggested(e.key) &&
                  isActivityOfferable(
                    e.key,
                    allowSafetyPending: context.allowSafetyPending,
                  ),
            )
            .toList()
          ..sort((a, b) => a.value.minMinutes - b.value.minMinutes);
    if (shortest.isEmpty) return null;
    final fallback = shortest.first;
    return RecommendationDecision(
      activityId: fallback.key,
      offeredMinutes: fallback.value.mode == CircleMode.open
          ? fallback.value.minMinutes
          : fallback.value.typicalMinutes,
      reason: RecommendationReason.fallback,
      trace: 'nothing fits the window',
    );
  }

  for (var relaxation = 0; relaxation <= 3; relaxation++) {
    final eligible = candidates.where((c) => c.block <= relaxation).toList()
      ..sort(compare);
    if (eligible.isEmpty) continue;
    var pick = eligible.first;
    var reason = _reasonFor(pick, policy, sparse);

    final settledNeed =
        !sparse && memory.answersFor(need) >= policy.explorationMinAnswers;
    if (relaxation > 0) {
      reason = RecommendationReason.fallback;
    } else if (replacement == null &&
        context.window != TimeWindow.about10 &&
        settledNeed &&
        !pick.tried &&
        !pick.isRoutine &&
        reason == RecommendationReason.bestFit) {
      // Already something new for a need the user has answered for. A
      // routine the user built is never "something new to try".
      reason = RecommendationReason.tryingNew;
    } else if (replacement == null &&
        context.window != TimeWindow.about10 &&
        pick.tried &&
        settledNeed &&
        memory.circlesSinceNew(need) >= policy.explorationInterval) {
      // Already sorted: an untried primary before an untried secondary.
      final untried = eligible.where((c) => !c.tried && !c.isRoutine);
      if (untried.isNotEmpty) {
        pick = untried.first;
        reason = RecommendationReason.tryingNew;
      }
    }

    if (replacement != null) {
      reason = switch (replacement.reason) {
        ReplacementReason.cantGoOutside => RecommendationReason.replacedIndoor,
        // "Lighter" only when it truly is shorter; otherwise just different.
        ReplacementReason.tooMuch =>
          pick.minutes < replacement.replacingMinutes
              ? RecommendationReason.replacedLighter
              : RecommendationReason.replacedDifferent,
        ReplacementReason.notFeeling => RecommendationReason.replacedDifferent,
      };
    }

    return RecommendationDecision(
      activityId: pick.id,
      routineId: pick.routineId,
      routineVersionId: pick.routineVersionId,
      offeredMinutes: pick.minutes,
      reason: reason,
      trace: [
        'relax=$relaxation',
        for (final c in eligible.take(4))
          '${c.label}(b${c.band(policy)} p${c.penalty}'
              '${c.primary ? ' P' : ' S'} s${c.strength}'
              '${c.block > 0 ? ' blk${c.block}' : ''})',
      ].join(' '),
    );
  }
  return null;
}

/// The decisive evidence behind [pick]. A personal reason only when that
/// evidence actually decided it, and includes a "Very useful" answer.
RecommendationReason _reasonFor(
  _Candidate pick,
  RecommendationPolicy policy,
  bool sparse,
) {
  if (pick.band(policy) == 0 && pick.strong) {
    return RecommendationReason.usefulHere;
  }
  if (!pick.primary &&
      pick.strength < policy.usefulThreshold &&
      pick.strengthElsewhere >= policy.usefulThreshold &&
      pick.strongElsewhere) {
    return RecommendationReason.usefulElsewhere;
  }
  if (sparse && pick.strength == 0) return RecommendationReason.starter;
  return RecommendationReason.bestFit;
}
