/// The Path engine (V2 Phase D, ADR-022): how a Path starts, what each of
/// its Circles is, and what it proposes at the end. Pure and deterministic —
/// no clock, storage or randomness — like Recommendation Engine V2.
///
/// A build tries the pieces short, then one in full, then two together,
/// then a shorter form, and ends with the routine as it stands. Each step
/// reads only the user's explicit answers to earlier Path Circles. No answer
/// is never treated as a bad one: the Path simply carries on in its
/// authored order, and claims nothing personal.
library;

import '../../home/application/activity_catalog.dart';
import '../../home/domain/recommendation_engine.dart';
import '../../home/domain/recommendation_policy.dart';
import 'module_library.dart';
import 'path_catalog.dart';
import 'toolkit_model.dart';

/// An answer's weight: Very useful +2, Somewhat +1, Not useful −2.
int? usefulnessScore(PastUsefulness? usefulness) => switch (usefulness) {
  PastUsefulness.veryUseful => 2,
  PastUsefulness.somewhatUseful => 1,
  PastUsefulness.notUseful => -2,
  null => null,
};

bool _negative(int? score) => score != null && score < 0;
bool _positive(int? score) => score != null && score > 0;

/// Whether [module] may be used for [need]: the user hasn't asked THIRTY
/// not to suggest it there, and it may be offered in this build.
bool moduleAllowed(
  ModuleId module,
  Intention need, {
  required SuggestionControls controls,
  required bool allowSafetyPending,
}) {
  final source = moduleOf(module).source;
  return !controls.notSuggested.contains((source, need)) &&
      isActivityOfferable(source, allowSafetyPending: allowSafetyPending) &&
      moduleOf(module).fitFor(need) != NeedFit.none;
}

/// Whether [module] is resting for [need]: its activity was found "Not
/// useful" for [need] within Phase B's rest, and the user hasn't lifted it
/// with "Suggest again". Premium never brings a resting piece back in — not
/// to seed a Path, adapt one, tune a routine or make one shorter. The rest
/// ends on its own; "Don't suggest" ([moduleAllowed]) is the lasting one.
bool moduleResting(
  ModuleId module,
  Intention need,
  RecommendationMemory memory, {
  RecommendationPolicy policy = RecommendationPolicy.initial,
}) {
  final days = memory.daysSinceNotUseful(moduleOf(module).source, need);
  return days != null && days <= policy.restDays;
}

/// How a build starts: its pieces in order, and why.
class PathSeed {
  const PathSeed({required this.pool, required this.reason, this.useful});

  final List<ModuleId> pool;
  final SeedReason reason;

  /// The piece the user found useful, when that decided the order.
  final ModuleId? useful;
}

/// Seeds a build of [template] from the user's evidence for its need.
///
/// - The user's "Don't suggest" removes a piece outright; content awaiting
///   the safety review is never used.
/// - A piece resting after a recent "Not useful" is left out while it
///   rests ([moduleResting]).
/// - A piece the user found useful for this need goes first.
/// - A piece with negative evidence (its rest over) goes last.
/// - Otherwise the template's own order — a strong neutral start, with
///   nothing claimed about the user.
///
/// `null` when fewer than two pieces are left: there is no honest routine
/// to build, and the Path must not start.
PathSeed? seedBuild(
  PathTemplate template,
  RecommendationMemory memory, {
  required SuggestionControls controls,
  required bool allowSafetyPending,
  RecommendationPolicy policy = RecommendationPolicy.initial,
}) {
  final need = template.need;
  final allowed = [
    for (final module in template.pool)
      if (moduleAllowed(
            module,
            need,
            controls: controls,
            allowSafetyPending: allowSafetyPending,
          ) &&
          !moduleResting(module, need, memory, policy: policy))
        module,
  ];
  if (allowed.length < 2) return null;

  double strength(ModuleId m) => memory.strengthFor(moduleOf(m).source, need);

  final useful = [
    for (final m in allowed)
      if (strength(m) >= policy.usefulThreshold) m,
  ]..sort((a, b) => strength(b).compareTo(strength(a)));
  final against = [
    for (final m in allowed)
      if (strength(m) < 0) m,
  ];
  final neutral = [
    for (final m in allowed)
      if (!useful.contains(m) && !against.contains(m)) m,
  ];
  return PathSeed(
    pool: [...useful, ...neutral, ...against],
    reason: useful.isEmpty ? SeedReason.sparseStart : SeedReason.usefulModule,
    useful: useful.firstOrNull,
  );
}

/// [lead] and [partner] joined as one Circle at the fullest length that
/// stays within [maxCircleMinutes]: both full; else the lead full; else the
/// partner full; else both short. `null` if even both short are too long.
Composition? fullTogether(ModuleId lead, ModuleId partner) {
  for (final (leadShort, partnerShort) in const [
    (false, false),
    (false, true),
    (true, false),
    (true, true),
  ]) {
    final composition = Composition([
      ModuleUse(lead, short: leadShort && moduleOf(lead).hasShortForm),
      ModuleUse(partner, short: partnerShort && moduleOf(partner).hasShortForm),
    ]);
    if (composition.minutes <= maxCircleMinutes) return composition;
  }
  return null;
}

/// Every piece of [composition] in its short form — the same pieces,
/// truly shorter — or `null` if that is no shorter.
Composition? shortFormOf(Composition composition) {
  final short = Composition([
    for (final use in composition.uses)
      ModuleUse(use.module, short: use.definition.hasShortForm),
  ]);
  return short.minutes < composition.minutes ? short : null;
}

/// One Path step: what today's Path Circle would be.
class PathStep {
  const PathStep({
    required this.number,
    required this.composition,
    required this.reason,
    this.about,
    this.instead,
  });

  /// 1-based Circle of the Path.
  final int number;
  final Composition composition;
  final PathStepReason reason;

  /// The piece the reason is about, and the one it replaced, if any.
  final ModuleId? about;
  final ModuleId? instead;

  /// The same step in its truly shorter form, for a day with less time —
  /// or `null` if it has none.
  Composition? get shorter => shortFormOf(composition);

  /// The one line shown on the Today card with this step.
  String get explanation =>
      pathStepExplanation(reason, combined: composition.combined);
}

/// What a Path step says about itself — plain, and only what is true.
///
/// The Today card shows the step's pieces right above this line, so it
/// never repeats their names mid-sentence ("so now write it down" reads as
/// an instruction, not a name): it says "this" or "these together"
/// ([combined]) instead (founder content review).
String pathStepExplanation(PathStepReason reason, {bool combined = false}) =>
    switch (reason) {
      PathStepReason.firstTry => 'A short first try.',
      PathStepReason.startsWithUseful =>
        'You’ve found this useful before, so it comes first.',
      PathStepReason.secondTry => 'Now a short try of something else.',
      PathStepReason.thirdTry => 'And a third piece to try.',
      PathStepReason.otherPairing => 'Another pairing, to compare.',
      PathStepReason.fullPiece => 'Now one piece in full.',
      PathStepReason.repeatUseful =>
        combined
            ? 'You found these together useful, so they stay.'
            : 'You found this useful, so here it is in full.',
      PathStepReason.alternateAfterNegative =>
        combined
            ? 'That pairing didn’t suit you, so this tries another.'
            : 'The first two didn’t suit you, so here’s the third.',
      PathStepReason.together => 'Now the two together.',
      PathStepReason.shorterForm => 'A shorter form, for days with less time.',
      PathStepReason.asItStands => 'Your routine, as it stands.',
      PathStepReason.shorterToFit => 'A shorter form, to fit today’s time.',
      PathStepReason.tuneSwap =>
        'One piece changed, to see if it suits you better.',
      PathStepReason.tuneShorter => 'A shorter version, to try for a few days.',
      PathStepReason.otherShorter => 'The other way to make it shorter.',
    };

/// The answer to each counted Path Circle, keyed by Circle id.
typedef PathAnswers = Map<String, PastUsefulness?>;

/// The next step of [run], or `null` once every Circle is counted.
///
/// [base] is the routine version a tune-up or shorter version changes.
/// [resting] — the pieces resting today ([moduleResting]): a build never
/// turns to one of them when another piece will do.
PathStep? nextPathStep(
  PathRun run,
  PathAnswers answers, {
  RoutineVersion? base,
  Set<ModuleId> resting = const {},
}) {
  if (run.finished) return null;
  return switch (run.kind) {
    PathKind.build => _buildStep(run, answers, resting),
    PathKind.tuneUp => base == null ? null : _tuneStep(run, answers, base),
    PathKind.shorter => base == null ? null : _shorterStep(run, answers, base),
  };
}

int? _scoreOf(PathRun run, PathAnswers answers, int number) {
  if (number < 1 || number > run.circles.length) return null;
  return usefulnessScore(answers[run.circles[number - 1].circleId]);
}

/// The single piece a counted Circle used, if it used one.
ModuleId? _single(PathRun run, int number) {
  final uses = run.circles[number - 1].composition.uses;
  return uses.length == 1 ? uses.first.module : null;
}

/// The pieces a counted Circle joined (in role order).
List<ModuleId> _pieces(PathRun run, int number) => [
  for (final use in run.circles[number - 1].composition.uses) use.module,
];

PathStep _buildStep(PathRun run, PathAnswers answers, Set<ModuleId> resting) {
  final pool = run.pool;
  final a = pool[0];
  final b = pool[1];
  final c = pool.length > 2 ? pool[2] : null;
  final n = run.nextNumber;
  int? score(int number) => _scoreOf(run, answers, number);

  // The piece tried alone in Circles 1–3 that the user rated, by module.
  int? scoreOfPiece(ModuleId module) {
    int? best;
    for (var i = 1; i <= run.circles.length && i <= 3; i++) {
      if (_single(run, i) != module) continue;
      final s = score(i);
      if (s != null && (best == null || s > best)) best = s;
    }
    return best;
  }

  switch (n) {
    case 1:
      return PathStep(
        number: 1,
        composition: Composition([ModuleUse(a, short: true)].normalised),
        reason: run.seed == SeedReason.usefulModule
            ? PathStepReason.startsWithUseful
            : PathStepReason.firstTry,
        about: a,
      );
    case 2:
      return PathStep(
        number: 2,
        composition: Composition([ModuleUse(b, short: true)].normalised),
        reason: PathStepReason.secondTry,
        about: b,
      );
    case 3:
      final sa = score(1);
      final sb = score(2);
      final third = c != null && !resting.contains(c) ? c : null;
      if (_negative(sa) && _negative(sb) && third != null) {
        return PathStep(
          number: 3,
          composition: Composition([ModuleUse(third, short: true)].normalised),
          reason: PathStepReason.alternateAfterNegative,
          about: third,
          instead: a,
        );
      }
      // The better-rated piece — never one resting today when the other
      // isn't.
      var lead = (sb ?? 0) > (sa ?? 0) ? b : a;
      if (resting.contains(lead)) {
        final other = lead == a ? b : a;
        if (!resting.contains(other)) lead = other;
      }
      // A piece of one length was already tried in full: rather than the
      // same Circle again, the third piece gets its try (policy tuning,
      // ADR-022 — A soft landing repeated itself in simulation).
      if (!moduleOf(lead).hasShortForm && third != null) {
        return PathStep(
          number: 3,
          composition: Composition([ModuleUse(third, short: true)].normalised),
          reason: PathStepReason.thirdTry,
          about: third,
        );
      }
      return PathStep(
        number: 3,
        composition: Composition([ModuleUse(lead, short: false)]),
        reason: _positive(lead == a ? sa : sb)
            ? PathStepReason.repeatUseful
            : PathStepReason.fullPiece,
        about: lead,
      );
    default:
      break;
  }

  // From Circle 4: two pieces together. The lead is the piece Circle 3
  // tried in full — or, after a third try, the best-rated of the three;
  // the partner the best remaining piece the user hasn't turned down.
  final third = run.circles[2];
  // Best answer first; on a tie, the Path's own order — deterministic.
  int byAnswer(ModuleId x, ModuleId y) {
    final byScore = (scoreOfPiece(y) ?? 0).compareTo(scoreOfPiece(x) ?? 0);
    return byScore != 0 ? byScore : pool.indexOf(x).compareTo(pool.indexOf(y));
  }

  final settledLead =
      third.reason == PathStepReason.fullPiece ||
          third.reason == PathStepReason.repeatUseful
      ? _single(run, 3) ?? a
      : ([a, b, ?c]..sort(byAnswer)).first;
  // A lead now resting gives way to the best piece that isn't.
  final lead = resting.contains(settledLead)
      ? ([a, b, ?c].where((m) => !resting.contains(m)).toList()..sort(byAnswer))
                .firstOrNull ??
            settledLead
      : settledLead;
  final partners = [
    for (final m in [a, b, ?c])
      if (m != lead) m,
  ]..sort(byAnswer);
  ModuleId? partnerAfter(Set<ModuleId> turnedDown) {
    for (final m in partners) {
      if (turnedDown.contains(m)) continue;
      if (_negative(scoreOfPiece(m))) continue;
      if (resting.contains(m)) continue;
      return m;
    }
    return null;
  }

  Composition together(ModuleId? partner) {
    if (partner == null) return Composition([ModuleUse(lead, short: false)]);
    return fullTogether(lead, partner) ??
        Composition([ModuleUse(lead, short: false)]);
  }

  ModuleId? partnerIn(int number) {
    for (final m in _pieces(run, number)) {
      if (m != lead) return m;
    }
    return null;
  }

  if (n == 4) {
    final partner = partnerAfter(const {});
    return PathStep(
      number: 4,
      composition: together(partner),
      reason: partner == null
          ? PathStepReason.repeatUseful
          : PathStepReason.together,
      about: partner ?? lead,
    );
  }

  // The pair settled by Circle 5: Circle 4's, unless it was turned down.
  final partner4 = partnerIn(4);
  if (n == 5) {
    if (_negative(score(4))) {
      final next = partnerAfter({?partner4});
      return PathStep(
        number: 5,
        composition: together(next),
        reason: PathStepReason.alternateAfterNegative,
        about: next ?? lead,
        instead: partner4,
      );
    }
    if (partner4 != null && resting.contains(partner4)) {
      final next = partnerAfter({partner4});
      if (next != null) {
        return PathStep(
          number: 5,
          composition: together(next),
          reason: PathStepReason.together,
          about: next,
        );
      }
    }
    return PathStep(
      number: 5,
      composition: together(partner4),
      reason: _positive(score(4))
          ? PathStepReason.repeatUseful
          : PathStepReason.together,
      about: partner4 ?? lead,
    );
  }

  final partner5Then = partnerIn(5);
  final partner5 = partner5Then != null && resting.contains(partner5Then)
      ? partnerAfter({partner5Then}) ?? partner5Then
      : partner5Then;
  final current = together(partner5);
  final short = shortFormOf(current);
  // With no shorter form, Circle 6 compares another pairing instead of
  // repeating the same Circle (policy tuning, ADR-022).
  final other = short == null ? partnerAfter({?partner5}) : null;
  if (n == 6) {
    if (short != null) {
      return PathStep(
        number: 6,
        composition: short,
        reason: PathStepReason.shorterForm,
        about: partner5 ?? lead,
      );
    }
    if (other != null) {
      return PathStep(
        number: 6,
        composition: together(other),
        reason: PathStepReason.otherPairing,
        about: other,
        instead: partner5,
      );
    }
    return PathStep(
      number: 6,
      composition: current,
      reason: PathStepReason.together,
      about: partner5 ?? lead,
    );
  }

  // Circle 7: the routine as it stands — the shorter form only when the
  // user rated it above the full one; the other pairing only when it was
  // rated above the first.
  final sixth = run.circles[5].planned;
  final shortPreferred =
      short != null && sixth == short && (score(6) ?? -99) > (score(5) ?? 0);
  final otherPreferred =
      short == null && sixth != current && (score(6) ?? -99) > (score(5) ?? 0);
  return PathStep(
    number: 7,
    composition: shortPreferred
        ? short
        : otherPreferred
        ? sixth
        : current,
    reason: PathStepReason.asItStands,
  );
}

extension on List<ModuleUse> {
  /// A short form a module doesn't have is its one length.
  List<ModuleUse> get normalised => [
    for (final use in this)
      ModuleUse(use.module, short: use.short && use.definition.hasShortForm),
  ];
}

/// The piece of [version] to change first in a tune-up (stored at the start
/// of the run's pool), the other pieces, then the replacements to try.
///
/// The piece with the weakest explicit evidence for the routine's need goes
/// first (ties: the later piece, never the opener the routine starts with).
/// Replacements come from the routine's own Path and then the other Path
/// for the same need — only pieces the user hasn't turned down, hasn't
/// asked THIRTY not to suggest, and that may be offered.
List<ModuleId>? tuneUpPool(
  Routine routine,
  RecommendationMemory memory, {
  required SuggestionControls controls,
  required bool allowSafetyPending,
  RecommendationPolicy policy = RecommendationPolicy.initial,
}) {
  final need = routine.need;
  final pieces = [
    for (final use in routine.active.composition.uses) use.module,
  ];
  double strength(ModuleId m) => memory.strengthFor(moduleOf(m).source, need);
  bool resting(ModuleId m) => moduleResting(m, need, memory, policy: policy);

  // A piece the user has since asked not to see for this need — or one
  // resting after a recent "Not useful" — must be the one replaced: a
  // tune-up that kept it couldn't run. Two of them can't be fixed by
  // changing one piece.
  final disallowed = [
    for (final m in pieces)
      if (!moduleAllowed(
            m,
            need,
            controls: controls,
            allowSafetyPending: allowSafetyPending,
          ) ||
          resting(m))
        m,
  ];
  if (disallowed.length > 1) return null;
  final weakestFirst = [...pieces.reversed]
    ..sort((x, y) {
      final forced = (disallowed.contains(y) ? 1 : 0).compareTo(
        disallowed.contains(x) ? 1 : 0,
      );
      return forced != 0 ? forced : strength(x).compareTo(strength(y));
    });
  final candidates = <ModuleId>[
    for (final template in [
      if (routine.sourceTemplate case final id?) pathTemplate(id),
      ...pathsFor(need),
    ])
      ...template.pool,
  ];
  final replacements = <ModuleId>[];
  for (final m in candidates) {
    if (pieces.contains(m) || replacements.contains(m)) continue;
    if (!moduleAllowed(
      m,
      need,
      controls: controls,
      allowSafetyPending: allowSafetyPending,
    )) {
      continue;
    }
    if (resting(m) || strength(m) < 0) continue;
    replacements.add(m);
  }
  if (replacements.isEmpty) return null;
  return [...weakestFirst, ...replacements];
}

/// [base]'s pieces with [out] swapped for [into], at the fullest length
/// that fits a Circle.
Composition? _swapped(Composition base, ModuleId out, ModuleId into) {
  final kept = [
    for (final use in base.uses)
      if (use.module != out) use.module,
  ];
  if (kept.isEmpty) return Composition([ModuleUse(into, short: false)]);
  if (kept.length == 1) return fullTogether(kept.single, into);
  final full = Composition([
    for (final m in kept) ModuleUse(m, short: false),
    ModuleUse(into, short: false),
  ]);
  if (full.minutes <= maxCircleMinutes) return full;
  final short = shortFormOf(full);
  return short != null && short.minutes <= maxCircleMinutes ? short : null;
}

PathStep? _tuneStep(PathRun run, PathAnswers answers, RoutineVersion base) {
  final size = base.composition.uses.length;
  if (run.pool.length <= size) return null;
  final weakest = run.pool.first;
  final other = size > 1 ? run.pool[1] : null;
  final replacements = run.pool.sublist(size);
  final first = _swapped(base.composition, weakest, replacements.first);
  if (first == null) return null;
  final n = run.nextNumber;
  if (n == 1) {
    return PathStep(
      number: 1,
      composition: first,
      reason: PathStepReason.tuneSwap,
      about: replacements.first,
      instead: weakest,
    );
  }
  final s1 = _scoreOf(run, answers, 1);
  // Circle 2: again — or, if the first change was turned down, another.
  Composition second = first;
  var reason = _positive(s1)
      ? PathStepReason.repeatUseful
      : PathStepReason.tuneSwap;
  ModuleId? about = replacements.first;
  ModuleId? instead = weakest;
  if (_negative(s1)) {
    final alternative = replacements.length > 1
        ? _swapped(base.composition, weakest, replacements[1])
        : (other == null
              ? null
              : _swapped(base.composition, other, replacements.first));
    if (alternative != null) {
      second = alternative;
      reason = PathStepReason.alternateAfterNegative;
      about = replacements.length > 1 ? replacements[1] : replacements.first;
      instead = replacements.length > 1 ? weakest : other;
    }
  }
  if (n == 2) {
    return PathStep(
      number: 2,
      composition: second,
      reason: reason,
      about: about,
      instead: instead,
    );
  }
  // Circle 3: the better of the two (ties: the later).
  final s2 = _scoreOf(run, answers, 2);
  final settled = (s1 ?? 0) > (s2 ?? 0)
      ? run.circles[0].planned
      : run.circles[1].planned;
  return PathStep(
    number: 3,
    composition: settled,
    reason: PathStepReason.asItStands,
  );
}

/// Every truly shorter version of [base] within [targetMinutes], fullest
/// first. A shorter version is the **same routine**: every one of its
/// pieces, in the same order, each at its full length or its authored
/// short form — never a piece dropped, a timer cut or a step skipped
/// (founder quality principle, ADR-022). So a routine whose pieces have no
/// shorter forms that fit has no shorter version at all: THIRTY then
/// doesn't offer one, rather than calling one ordinary activity "your
/// routine, shorter".
List<Composition> shorterVersionsOf(Composition base, int targetMinutes) {
  var versions = <List<ModuleUse>>[[]];
  for (final use in base.uses) {
    versions = [
      for (final head in versions) ...[
        [...head, ModuleUse(use.module, short: false)],
        if (use.definition.hasShortForm)
          [...head, ModuleUse(use.module, short: true)],
      ],
    ];
  }
  final shorter = [
    for (final uses in versions)
      if (Composition(uses) case final version
          when version.minutes < base.minutes &&
              version.minutes <= targetMinutes)
        version,
  ]..sort((a, b) => b.minutes.compareTo(a.minutes));
  return shorter;
}

/// The fullest truly shorter version of [base] within [targetMinutes] (see
/// [shorterVersionsOf]), or `null`.
Composition? shorterVersionOf(Composition base, int targetMinutes) =>
    shorterVersionsOf(base, targetMinutes).firstOrNull;

PathStep? _shorterStep(PathRun run, PathAnswers answers, RoutineVersion base) {
  final target = run.targetMinutes ?? maxCircleMinutes;
  final versions = shorterVersionsOf(base.composition, target);
  if (versions.isEmpty) return null;
  final first = versions.first;
  final n = run.nextNumber;
  if (n == 1) {
    return PathStep(
      number: 1,
      composition: first,
      reason: PathStepReason.tuneShorter,
    );
  }
  final s1 = _scoreOf(run, answers, 1);
  // Circle 2: again — or, if it was turned down, the routine's other
  // truly shorter version, when there is one (still every piece).
  var second = first;
  var reason = _positive(s1)
      ? PathStepReason.repeatUseful
      : PathStepReason.tuneShorter;
  if (_negative(s1) && versions.length > 1) {
    second = versions[1];
    reason = PathStepReason.otherShorter;
  }
  if (n == 2) {
    return PathStep(number: 2, composition: second, reason: reason);
  }
  final s2 = _scoreOf(run, answers, 2);
  return PathStep(
    number: 3,
    composition: (s1 ?? 0) > (s2 ?? 0)
        ? run.circles[0].planned
        : run.circles[1].planned,
    reason: PathStepReason.asItStands,
  );
}

/// The step as today's Circle: [step] at its own length when it fits
/// [window]; else its truly shorter form, said so; else `null` — the Path
/// waits rather than cutting anything short.
({Composition composition, PathStepReason reason})? fitToWindow(
  PathStep step,
  TimeWindow window,
) {
  if (step.composition.minutes <= window.maxMinutes) {
    return (composition: step.composition, reason: step.reason);
  }
  final shorter = step.shorter;
  if (shorter != null && shorter.minutes <= window.maxMinutes) {
    return (composition: shorter, reason: PathStepReason.shorterToFit);
  }
  return null;
}

/// Whether [step] can be today's Circle at all: every piece allowed for its
/// need (the user may have changed their mind mid-Path), and none resting
/// today ([resting]). Otherwise the Path waits; nothing is forced.
bool stepAllowed(
  PathStep step,
  Intention need, {
  required SuggestionControls controls,
  required bool allowSafetyPending,
  Set<ModuleId> resting = const {},
}) => step.composition.uses.every(
  (use) =>
      !resting.contains(use.module) &&
      moduleAllowed(
        use.module,
        need,
        controls: controls,
        allowSafetyPending: allowSafetyPending,
      ),
);

/// What a finished Path proposes — and the facts its review may show.
class PathProposal {
  const PathProposal({
    required this.composition,
    required this.facts,
    this.shorter,
  });

  /// The routine (a build), the tuned routine (a tune-up) or the shorter
  /// version (a shorter run).
  final Composition composition;

  /// A build's shorter form, kept as the routine's shorter version when the
  /// user didn't turn it down.
  final Composition? shorter;

  final PathFacts facts;
}

/// Only what happened: pieces tried, answers given, changes made.
class PathFacts {
  const PathFacts({
    required this.piecesTried,
    required this.answers,
    required this.changes,
    required this.positiveForResult,
    required this.answeredForResult,
  });

  /// In the order they first appeared.
  final List<ModuleId> piecesTried;

  /// Each counted Circle's pieces and its answer (`null`: not answered).
  final List<({int number, Composition composition, PastUsefulness? answer})>
  answers;

  /// "Circle 5 tried Clear one surface instead of Standing stretch."
  final List<String> changes;

  /// Answers about the proposed pieces together, and how many were
  /// positive — what a stronger claim may rest on.
  final int positiveForResult;
  final int answeredForResult;

  bool get anyAnswers => answers.any((a) => a.answer != null);
}

/// The proposal of a finished [run].
PathProposal? proposalFor(PathRun run, PathAnswers answers) {
  if (!run.finished) return null;
  // What the Path settled on — unless its last Circle had to run a truly
  // shorter form to fit the user's time: then that form, the one they
  // actually did and answered, is the result (policy tuning, ADR-022: a
  // tune-up that only ever ran shorter must not keep a longer version).
  final last = run.circles.last;
  final result = last.reason == PathStepReason.shorterToFit
      ? last.composition
      : last.planned;
  final pieces = <ModuleId>[];
  for (final circle in run.circles) {
    for (final use in circle.composition.uses) {
      if (!pieces.contains(use.module)) pieces.add(use.module);
    }
  }
  final changes = <String>[];
  for (final circle in run.circles) {
    if (circle.reason != PathStepReason.alternateAfterNegative &&
        circle.reason != PathStepReason.tuneSwap) {
      continue;
    }
    changes.add('Circle ${circle.number} tried ${circle.composition.title}.');
  }
  var positive = 0;
  var answered = 0;
  for (final circle in run.circles) {
    if (!circle.composition.modules.containsAll(result.modules) ||
        circle.composition.modules.length != result.modules.length) {
      continue;
    }
    final score = usefulnessScore(answers[circle.circleId]);
    if (score == null) continue;
    answered++;
    if (score > 0) positive++;
  }

  Composition? shorter;
  if (run.kind == PathKind.build) {
    final candidate = shortFormOf(result);
    final sixth = run.circles.length >= 6 ? run.circles[5] : null;
    final turnedDown =
        sixth != null &&
        sixth.planned == candidate &&
        _negative(usefulnessScore(answers[sixth.circleId]));
    if (candidate != null && !turnedDown) shorter = candidate;
  }

  return PathProposal(
    composition: result,
    shorter: shorter,
    facts: PathFacts(
      piecesTried: pieces,
      answers: [
        for (final circle in run.circles)
          (
            number: circle.number,
            composition: circle.composition,
            answer: answers[circle.circleId],
          ),
      ],
      changes: changes,
      positiveForResult: positive,
      answeredForResult: answered,
    ),
  );
}
