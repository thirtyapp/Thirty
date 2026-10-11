/// Toolkit maintenance (V2 Phase D, ADR-022): deterministic offers from
/// explicit evidence only — the user's answers and the time they said they
/// had. Every result is an offer; nothing here changes a routine.
///
/// Below the minimum evidence there is no trigger and no claim. When
/// nothing needs changing, the Toolkit check says so — and that honest
/// "nothing to change" is a result, not a gap to fill.
library;

import '../../home/application/activity_catalog.dart';
import '../../home/domain/recommendation_engine.dart';
import '../../home/domain/recommendation_policy.dart';
import 'module_library.dart';
import 'path_catalog.dart';
import 'path_engine.dart';
import 'toolkit_model.dart';
import 'toolkit_policy.dart';

/// The three automatic trigger families. (The fourth, a user-requested
/// refresh, is the user's own action on a routine — never an offer.)
enum OfferKind {
  /// The routine no longer fits the time the user keeps saying they have.
  timeMisfit,

  /// A routine that used to suit the user suits them less well lately.
  fading,

  /// A need chosen often, with no routine that fits it.
  gap,
}

/// One maintenance offer. Shown one at a time; never applied unasked.
class MaintenanceOffer {
  const MaintenanceOffer({
    required this.kind,
    required this.key,
    required this.need,
    this.routine,
    this.targetMinutes,
    this.window,
    this.template,
    this.observedDays,
    this.matchingDays,
  });

  final OfferKind kind;

  /// What a decline is remembered by.
  final String key;
  final Intention need;
  final Routine? routine;

  /// A shorter version's most minutes.
  final int? targetMinutes;

  /// The time the evidence is about.
  final TimeWindow? window;

  /// A gap's Path.
  final PathTemplateId? template;

  /// The days the evidence looked at, and how many of them showed it — so
  /// the words say exactly what THIRTY saw (ADR-023 §10).
  final int? observedDays;
  final int? matchingDays;

  /// What THIRTY saw — only what the evidence supports. THIRTY knows only
  /// the days the user opened it and the time they chose, never "most days".
  String get evidence => switch (kind) {
    OfferKind.timeMisfit =>
      '${matchingDays == observedDays ? 'On each of your last $observedDays' : 'On $matchingDays of your last $observedDays'} '
          '${intentionLabel(need)} days, you had less than the '
          '${routine!.active.minutes} minutes ${routine!.name} takes.',
    OfferKind.fading =>
      'Your recent answers about ${routine!.name} have been less positive '
          'than before.',
    OfferKind.gap =>
      // "THIRTY can offer": a routine the user asked THIRTY not to suggest
      // for this need is theirs, but doesn't count as fitting it.
      'You chose ${intentionLabel(need)} on $matchingDays of the last '
          '$observedDays days, and no routine THIRTY can offer you fits it in '
          'about ${window!.maxMinutes} minutes.',
  };

  /// What THIRTY offers to do about it.
  String get proposal => switch (kind) {
    OfferKind.timeMisfit =>
      'Want a shorter version for days with about ${window!.maxMinutes} '
          'minutes? Three Circles to try it.',
    OfferKind.fading =>
      'Want to tune it? Three Circles try one change; you decide whether to '
          'keep it.',
    OfferKind.gap =>
      'Want to build one? ${pathTemplate(template!).name} takes seven '
          'Circles.',
  };
}

/// How the Toolkit check reads when it comes round (about every four
/// weeks).
enum CheckState {
  /// Something is worth changing: the one offer.
  action,

  /// Enough evidence, and nothing to change.
  stable,

  /// Too little evidence to say anything personal.
  learning,
}

class ToolkitCheck {
  const ToolkitCheck({
    required this.state,
    this.offer,
    this.working = const [],
    this.coversAll = false,
  });

  final CheckState state;
  final MaintenanceOffer? offer;

  /// [CheckState.stable]: the routines the evidence actually covers — each
  /// with answers in the period, none of them "Not useful".
  final List<String> working;

  /// Whether [working] is every routine in the Toolkit.
  final bool coversAll;

  /// What the check says — never more than its evidence covers (ADR-023
  /// §10): "working well" names only the routines with answers behind it.
  String get message => switch (state) {
    CheckState.action => offer!.evidence,
    CheckState.stable when coversAll && working.length > 1 =>
      'Your routines are working well — nothing to change.',
    CheckState.stable when coversAll =>
      '${working.single} is working well — nothing to change.',
    CheckState.stable =>
      '${_names(working)} ${working.length == 1 ? 'is' : 'are'} working '
          'well. Still learning how the others fit.',
    CheckState.learning => 'Still learning how these fit.',
  };

  static String _names(List<String> names) => names.length == 1
      ? names.single
      : '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
}

DateTime _day(DateTime date) => DateTime.utc(date.year, date.month, date.day);

int _age(DateTime date, DateTime today) =>
    _day(today).difference(_day(date)).inDays;

/// What a routine's answers since it last changed say.
class RoutineStanding {
  const RoutineStanding({required this.rated, required this.fading});

  /// Its answers since its version last changed, oldest first — its own
  /// Circles, and the Path Circles of the same pieces that built it.
  final List<PastUsefulness> rated;
  final bool fading;
}

/// [routine]'s standing in [history] at [today].
///
/// **Fading:** at least [ToolkitPolicy.fadingMinRatedUses] answers since
/// the version last changed; an earlier positive answer (it *used* to
/// suit); and the latest [ToolkitPolicy.fadingRecentAnswers] scoring at or
/// below [ToolkitPolicy.fadingMaxRecentScore]. One middling answer never
/// does it.
RoutineStanding routineStanding(
  Routine routine,
  Iterable<PastCircle> history,
  DateTime today, {
  ToolkitPolicy policy = ToolkitPolicy.initial,
}) {
  final active = routine.active;
  final since = _day(active.createdAt);
  final ordered = [...history]..sort((a, b) => a.date.compareTo(b.date));
  bool counts(PastCircle c) =>
      c.usefulness != null &&
      _age(c.date, today) >= 0 &&
      (c.routineVersionId == active.id || !_day(c.date).isBefore(since));
  // The Path Circles that built this version (its trial, ADR-023 §10), and
  // its real uses since — told apart by what they were, never by date (the
  // last Path Circle and the routine's creation can share a day).
  final built = [
    for (final c in ordered)
      if (c.builtRoutineId == routine.id && counts(c)) c.usefulness!,
  ];
  final used = [
    for (final c in ordered)
      if (c.routineId == routine.id && counts(c)) c.usefulness!,
  ];
  final rated = [...built, ...used];
  bool positive(PastUsefulness u) =>
      u == PastUsefulness.veryUseful || u == PastUsefulness.somewhatUseful;
  int scoreOf(List<PastUsefulness> answers) =>
      answers.fold(0, (sum, u) => sum + usefulnessScore(u)!);
  var fading = false;
  if (rated.length >= policy.fadingMinRatedUses) {
    // "Lately" is the routine in use — never the Path that built it, whose
    // answers can only show that it used to suit.
    for (final (window, limit) in [
      (policy.fadingRecentAnswers, policy.fadingMaxRecentScore),
      (2, policy.fadingMaxLastTwoScore),
    ]) {
      if (used.length < window) continue;
      final recent = used.sublist(used.length - window);
      final earlier = [...built, ...used.sublist(0, used.length - window)];
      if (earlier.any(positive) && scoreOf(recent) <= limit) fading = true;
    }
    if (used.isNotEmpty &&
        used.last == PastUsefulness.notUseful &&
        rated.sublist(0, rated.length - 1).where(positive).length >=
            policy.fadingRestedMinPositives) {
      fading = true;
    }
  }
  return RoutineStanding(rated: rated, fading: fading);
}

/// Whether [routine] may be offered for [need] at all — the user's own
/// controls on it and on every piece of it.
bool routineAllowedFor(
  Routine routine,
  Intention need, {
  required SuggestionControls controls,
  required bool allowSafetyPending,
}) =>
    routine.enabled &&
    !controls.routinesNotSuggested.contains((routine.id, need)) &&
    routine.active.composition.uses.every(
      (use) => moduleAllowed(
        use.module,
        need,
        controls: controls,
        allowSafetyPending: allowSafetyPending,
      ),
    );

TimeWindow? _mostCommon(Iterable<TimeWindow> windows) {
  final counts = <TimeWindow, int>{};
  for (final w in windows) {
    counts[w] = (counts[w] ?? 0) + 1;
  }
  if (counts.isEmpty) return null;
  // Most often; on a tie, the shorter time — the one that must fit.
  final sorted = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0
          ? byCount
          : a.key.maxMinutes.compareTo(b.key.maxMinutes);
    });
  return sorted.first.key;
}

/// Every maintenance offer that holds today, highest priority first:
/// a strong time misfit, then fading, then a gap. Declined offers stay
/// away for [ToolkitPolicy.declineCooldownDays]. Nothing is offered while a
/// Path is under way: one thing at a time.
List<MaintenanceOffer> maintenanceOffers({
  required ToolkitState toolkit,
  required List<PastCircle> history,
  required DateTime today,
  required RecommendationMemory memory,
  required SuggestionControls controls,
  required bool allowSafetyPending,
  ToolkitPolicy policy = ToolkitPolicy.initial,
  RecommendationPolicy recommendationPolicy = RecommendationPolicy.initial,
}) {
  if (toolkit.path != null) return const [];
  bool cooling(String key) {
    final declinedAt = toolkit.declined[key];
    return declinedAt != null &&
        _age(declinedAt, today) < policy.declineCooldownDays;
  }

  final misfits = <MaintenanceOffer>[];
  final fading = <MaintenanceOffer>[];
  for (final routine in toolkit.routines) {
    if (!routineAllowedFor(
      routine,
      routine.need,
      controls: controls,
      allowSafetyPending: allowSafetyPending,
    )) {
      continue;
    }

    // Time misfit: the routine's need, on the most recent days with a time.
    final needDays = [
      for (final c in [...history]..sort((a, b) => b.date.compareTo(a.date)))
        if (c.need == routine.need &&
            c.window != null &&
            _age(c.date, today) > 0 &&
            _age(c.date, today) <= policy.timeMisfitWindowDays)
          c.window!,
    ].take(policy.timeMisfitRecentDays).toList();
    final tooShort = [
      for (final w in needDays)
        if (w.maxMinutes < routine.active.minutes) w,
    ];
    if (tooShort.length >= policy.timeMisfitMinMisfits) {
      final window = _mostCommon(tooShort)!;
      final coveredByShort =
          routine.shortVersion != null &&
          routine.shortVersion!.minutes <= window.maxMinutes;
      // Only a real shorter version — every piece, each at an authored
      // length (shorterVersionsOf) — and never with a piece resting after
      // a "Not useful". Otherwise the routine simply doesn't fit that time
      // yet, and THIRTY says nothing.
      final resting = routine.active.composition.uses.any(
        (use) => moduleResting(
          use.module,
          routine.need,
          memory,
          policy: recommendationPolicy,
        ),
      );
      final buildable = resting
          ? null
          : shorterVersionOf(routine.active.composition, window.maxMinutes);
      final key = 'timeMisfit:${routine.id}:${window.maxMinutes}';
      if (!coveredByShort && buildable != null && !cooling(key)) {
        misfits.add(
          MaintenanceOffer(
            kind: OfferKind.timeMisfit,
            key: key,
            need: routine.need,
            routine: routine,
            targetMinutes: window.maxMinutes,
            window: window,
            observedDays: needDays.length,
            matchingDays: tooShort.length,
          ),
        );
      }
    }

    // Fading: explicit answers only, after enough of them.
    final standing = routineStanding(routine, history, today, policy: policy);
    final fadingKey = 'fading:${routine.id}:${routine.activeVersionId}';
    if (standing.fading &&
        !cooling(fadingKey) &&
        tuneUpPool(
              routine,
              memory,
              controls: controls,
              allowSafetyPending: allowSafetyPending,
              policy: recommendationPolicy,
            ) !=
            null) {
      fading.add(
        MaintenanceOffer(
          kind: OfferKind.fading,
          key: fadingKey,
          need: routine.need,
          routine: routine,
        ),
      );
    }
  }

  // Gap: a need chosen often lately, with no routine that fits it in the
  // usual time — for a Toolkit that already has routines and still has
  // room. The first routine is the Toolkit's own invitation, not a gap.
  final gaps = <MaintenanceOffer>[];
  if (toolkit.routines.isNotEmpty &&
      toolkit.routines.length < policy.gapMaxRoutines) {
    for (final need in Intention.values) {
      final days = [
        for (final c in history)
          if (c.need == need &&
              _age(c.date, today) > 0 &&
              _age(c.date, today) <= policy.gapWindowDays)
            c,
      ];
      if (days.length < policy.gapMinDays) continue;
      // Free's own picks for this need, as the user rated them — never a
      // routine, a Path Circle or a composed Circle (ADR-023). Too few
      // answers: THIRTY doesn't know Free falls short, so it claims no gap.
      // Free already serves it well ("Somewhat useful" counts too):
      // nothing to build.
      final answers = [
        for (final c in days)
          if (c.routineId == null && c.pathRunId == null && !c.composed)
            ?c.usefulness,
      ];
      if (answers.length < policy.gapMinAnswers) continue;
      final served =
          answers.fold<double>(
            0,
            (sum, u) =>
                sum +
                switch (u) {
                  PastUsefulness.veryUseful => 1,
                  PastUsefulness.somewhatUseful => policy.gapSomewhatWeight,
                  PastUsefulness.notUseful => 0,
                },
          ) /
          answers.length;
      if (served >= policy.gapServedWellScore) continue;
      final usual = _mostCommon([for (final c in days) ?c.window]);
      if (usual == null) continue;
      // Covered only by a routine built for this need: a routine for
      // another need that happens to fit it too isn't one the user built
      // for it.
      final covered = toolkit.routines.any(
        (routine) =>
            routine.need == need &&
            routineAllowedFor(
              routine,
              need,
              controls: controls,
              allowSafetyPending: allowSafetyPending,
            ) &&
            routine.offerableVersions.any((v) => v.minutes <= usual.maxMinutes),
      );
      if (covered) continue;
      final key = 'gap:${need.name}';
      if (cooling(key)) continue;
      final built = {
        for (final routine in toolkit.routines) ?routine.sourceTemplate,
      };
      for (final template in pathsFor(need)) {
        if (built.contains(template.id)) continue;
        final seed = seedBuild(
          template,
          memory,
          controls: controls,
          allowSafetyPending: allowSafetyPending,
          policy: recommendationPolicy,
        );
        if (seed == null) continue;
        // Only a Path whose routine can fit the usual time.
        if (_shortestTogether(seed.pool) > usual.maxMinutes) continue;
        gaps.add(
          MaintenanceOffer(
            kind: OfferKind.gap,
            key: key,
            need: need,
            window: usual,
            template: template.id,
            observedDays: policy.gapWindowDays,
            matchingDays: days.length,
          ),
        );
        break;
      }
    }
  }
  return [...misfits, ...fading, ...gaps];
}

/// The shortest any two of [pool] can be together.
int _shortestTogether(List<ModuleId> pool) {
  var shortest = 1 << 20;
  for (var i = 0; i < pool.length; i++) {
    for (var j = i + 1; j < pool.length; j++) {
      final together = fullTogether(pool[i], pool[j]);
      if (together == null) continue;
      final minutes = (shortFormOf(together) ?? together).minutes;
      if (minutes < shortest) shortest = minutes;
    }
  }
  return shortest;
}

/// The Toolkit check, when it's due: at least
/// [ToolkitPolicy.checkCadenceDays] after the last one (or after the first
/// routine). `null` when not due, or with no routines to check.
ToolkitCheck? toolkitCheck({
  required ToolkitState toolkit,
  required List<PastCircle> history,
  required DateTime today,
  required MaintenanceOffer? offer,
  ToolkitPolicy policy = ToolkitPolicy.initial,
}) {
  if (toolkit.routines.isEmpty) return null;
  // A Path under way is the change already being made: the check waits
  // for it rather than calling the Toolkit settled (S25 finding, D-J3).
  if (toolkit.path != null) return null;
  final firstRoutine = toolkit.routines
      .map((r) => r.createdAt)
      .reduce((a, b) => a.isBefore(b) ? a : b);
  final since = toolkit.lastCheckAt ?? firstRoutine;
  if (_age(since, today) < policy.checkCadenceDays) return null;
  if (offer != null) {
    return ToolkitCheck(state: CheckState.action, offer: offer);
  }
  final recentRated = history.where(
    (c) =>
        c.routineId != null &&
        c.usefulness != null &&
        toolkit.routineById(c.routineId!) != null &&
        _age(c.date, today) > 0 &&
        _age(c.date, today) <= policy.checkCadenceDays,
  );
  // "Working well" only when it is: enough answers, and none of them
  // "Not useful" — a declined offer must not turn into a false all-clear.
  // And only for the routines those answers are about: one routine's
  // answers never vouch for another (ADR-023 §10).
  final stable =
      recentRated.length >= policy.stableMinRatedUses &&
      recentRated.every((c) => c.usefulness != PastUsefulness.notUseful);
  if (!stable) return const ToolkitCheck(state: CheckState.learning);
  final answered = {for (final c in recentRated) c.routineId!};
  return ToolkitCheck(
    state: CheckState.stable,
    working: [
      for (final routine in toolkit.routines)
        if (answered.contains(routine.id)) routine.name,
    ],
    coversAll: toolkit.routines.every((r) => answered.contains(r.id)),
  );
}
