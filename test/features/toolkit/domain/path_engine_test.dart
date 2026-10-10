import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/home/domain/recommendation_policy.dart';
import 'package:thirty/features/toolkit/domain/module_library.dart';
import 'package:thirty/features/toolkit/domain/path_catalog.dart';
import 'package:thirty/features/toolkit/domain/path_engine.dart';
import 'package:thirty/features/toolkit/domain/toolkit_model.dart';

/// V2 Phase D — the Path engine (ADR-022): seeded from explicit evidence
/// only, adapting to explicit answers only, never claiming anything when
/// there are none, never cutting a step short to fit a day.

final _today = DateTime(2026, 11, 20);
final _wakeUp = pathTemplate(PathTemplateId.wakeUpIndoors);

PastCircle _past(
  int daysAgo,
  ActivityId activity, {
  Intention need = Intention.moreEnergy,
  PastUsefulness? usefulness,
}) => PastCircle(
  date: _today.subtract(Duration(days: daysAgo)),
  need: need,
  activityId: activity,
  catalogVersion: catalogVersion,
  usefulness: usefulness,
);

RecommendationMemory _memory(List<PastCircle> history) =>
    RecommendationMemory.of(_today, history, RecommendationPolicy.initial);

PathRun _run(List<ModuleId> pool, {SeedReason seed = SeedReason.sparseStart}) =>
    PathRun(
      id: 'run',
      kind: PathKind.build,
      need: Intention.moreEnergy,
      startedAt: _today,
      pool: pool,
      seed: seed,
      template: PathTemplateId.wakeUpIndoors,
    );

/// Runs the build through [answers] (one per Circle; `null`: not answered),
/// counting each step as planned. Returns the run and every step taken.
(PathRun, List<PathStep>, PathAnswers) _walk(
  PathRun start,
  List<PastUsefulness?> answers, {
  Set<ModuleId> resting = const {},
}) {
  var run = start;
  final steps = <PathStep>[];
  final given = <String, PastUsefulness?>{};
  for (final (index, answer) in answers.indexed) {
    final step = nextPathStep(run, given, resting: resting)!;
    steps.add(step);
    final id = 'c${index + 1}';
    run = run.withCircle(
      PathCircle(
        circleId: id,
        number: step.number,
        composition: step.composition,
        reason: step.reason,
      ),
    );
    given[id] = answer;
  }
  return (run, steps, given);
}

/// A lift at home as a user who found Move to music useful starts it.
const _seeded = [
  ModuleId.musicMove,
  ModuleId.standingStretch,
  ModuleId.activeTask,
];

const _v = PastUsefulness.veryUseful;
const _s = PastUsefulness.somewhatUseful;
const _n = PastUsefulness.notUseful;

void main() {
  _cardFit();
  _activeRests();

  group('seeding', () {
    test('with too little evidence: the template\'s own order, and nothing '
        'claimed about the user', () {
      final seed = seedBuild(
        _wakeUp,
        _memory(const []),
        controls: SuggestionControls.none,
        allowSafetyPending: false,
      )!;
      expect(seed.pool, _wakeUp.pool);
      expect(seed.reason, SeedReason.sparseStart);
      expect(seed.useful, isNull);
    });

    test('a piece found useful for this need comes first, and says so', () {
      final seed = seedBuild(
        _wakeUp,
        _memory([_past(5, ActivityId.moveToMusic, usefulness: _v)]),
        controls: SuggestionControls.none,
        allowSafetyPending: false,
      )!;
      expect(seed.pool.first, ModuleId.musicMove);
      expect(seed.reason, SeedReason.usefulModule);
      expect(seed.useful, ModuleId.musicMove);
    });

    test('useful for another need is not useful for this one', () {
      final seed = seedBuild(
        _wakeUp,
        _memory([
          _past(
            5,
            ActivityId.moveToMusic,
            need: Intention.clearerHead,
            usefulness: _v,
          ),
        ]),
        controls: SuggestionControls.none,
        allowSafetyPending: false,
      )!;
      expect(seed.reason, SeedReason.sparseStart);
    });

    test('a piece resting after a recent "Not useful" is left out while it '
        'rests; once the rest is over it may come back — last', () {
      final resting = seedBuild(
        _wakeUp,
        _memory([_past(3, ActivityId.energisingStretchFlow, usefulness: _n)]),
        controls: SuggestionControls.none,
        allowSafetyPending: false,
      )!;
      expect(resting.pool, isNot(contains(ModuleId.standingStretch)));
      expect(resting.pool, hasLength(2));

      final over = seedBuild(
        _wakeUp,
        _memory([_past(20, ActivityId.energisingStretchFlow, usefulness: _n)]),
        controls: SuggestionControls.none,
        allowSafetyPending: false,
      )!;
      expect(over.pool.last, ModuleId.standingStretch);
    });

    test('"Don\'t suggest" removes a piece outright; with fewer than two '
        'left there is no honest routine to build, and no Path', () {
      final one = seedBuild(
        _wakeUp,
        _memory(const []),
        controls: const SuggestionControls(
          notSuggested: {(ActivityId.moveToMusic, Intention.moreEnergy)},
        ),
        allowSafetyPending: false,
      )!;
      expect(one.pool, isNot(contains(ModuleId.musicMove)));
      expect(one.pool, hasLength(2));

      final none = seedBuild(
        _wakeUp,
        _memory(const []),
        controls: const SuggestionControls(
          notSuggested: {
            (ActivityId.moveToMusic, Intention.moreEnergy),
            (ActivityId.activeHouseholdTask, Intention.moreEnergy),
          },
        ),
        allowSafetyPending: false,
      );
      expect(none, isNull);
    });

    test('"Don\'t suggest" for another need doesn\'t touch this one', () {
      final seed = seedBuild(
        _wakeUp,
        _memory(const []),
        controls: const SuggestionControls(
          notSuggested: {(ActivityId.moveToMusic, Intention.clearerHead)},
        ),
        allowSafetyPending: false,
      )!;
      expect(seed.pool, contains(ModuleId.musicMove));
    });
  });

  group('the build, Circle by Circle', () {
    test('with every answer positive: short tries, the better piece in '
        'full, the two together, a shorter form, the routine as it stands', () {
      final (run, steps, answers) = _walk(_run(_seeded), [
        _v,
        _s,
        _v,
        _v,
        _v,
        _s,
        _v,
      ]);
      expect(run.finished, isTrue);
      expect(nextPathStep(run, answers), isNull);
      expect(steps.map((s) => s.reason), [
        PathStepReason.firstTry,
        PathStepReason.secondTry,
        // Circle 3's piece was found very useful — and it says so.
        PathStepReason.repeatUseful,
        PathStepReason.together,
        PathStepReason.repeatUseful,
        PathStepReason.shorterForm,
        PathStepReason.asItStands,
      ]);
      expect(steps[0].composition.minutes, 5);
      expect(steps[1].composition.minutes, 5);
      // Circle 3: music (very useful) beats the stretch (somewhat), in full.
      expect(steps[2].composition.modules, {ModuleId.musicMove});
      expect(steps[2].composition.minutes, 10);
      expect(steps[3].composition.modules, {
        ModuleId.standingStretch,
        ModuleId.musicMove,
      });
      expect(steps[3].composition.minutes, 15);
      expect(steps[5].composition.minutes, 10);
      expect(steps[6].composition.minutes, 15);
    });

    test('with no answers at all: the authored order, with no personal claim '
        'anywhere', () {
      final (run, steps, answers) = _walk(_run(_seeded), List.filled(7, null));
      expect(run.finished, isTrue);
      for (final step in steps) {
        expect([
          PathStepReason.repeatUseful,
          PathStepReason.alternateAfterNegative,
          PathStepReason.startsWithUseful,
        ], isNot(contains(step.reason)));
        expect(step.explanation, isNot(contains('useful')));
      }
      final proposal = proposalFor(run, answers)!;
      expect(proposal.facts.anyAnswers, isFalse);
      expect(proposal.facts.positiveForResult, 0);
    });

    test('a Circle 4 turned down: Circle 5 tries another partner, and says '
        'why', () {
      final (_, steps, _) = _walk(_run(_seeded), [_v, _v, _v, _n, null]);
      expect(steps[4].reason, PathStepReason.alternateAfterNegative);
      expect(steps[4].composition.modules, {
        ModuleId.musicMove,
        ModuleId.activeTask,
      });
      expect(steps[4].explanation, contains('didn’t suit you'));
    });

    test('pieces of one length: Circle 3 tries the third piece instead of '
        'repeating, and Circle 6 compares another pairing', () {
      final (run, steps, answers) = _walk(
        _run(const [
          ModuleId.warmDrink,
          ModuleId.gentleStretch,
          ModuleId.quietMusic,
        ]),
        [_v, _v, _s, _s, _s, _v, null],
      );
      expect(steps[2].reason, PathStepReason.thirdTry);
      expect(steps[2].composition.modules, {ModuleId.quietMusic});
      expect(steps[3].composition.modules, {
        ModuleId.warmDrink,
        ModuleId.gentleStretch,
      });
      expect(steps[5].reason, PathStepReason.otherPairing);
      expect(steps[5].composition.modules, {
        ModuleId.warmDrink,
        ModuleId.quietMusic,
      });
      // The other pairing was rated above the first: it becomes the routine.
      expect(steps[6].composition.modules, {
        ModuleId.warmDrink,
        ModuleId.quietMusic,
      });
      expect(proposalFor(run, answers)!.composition.modules, {
        ModuleId.warmDrink,
        ModuleId.quietMusic,
      });
      // No two Circles of this Path were the same Circle twice in a row
      // until it settled.
      for (var i = 1; i < 6; i++) {
        expect(
          steps[i].composition == steps[i - 1].composition &&
              steps[i].reason != PathStepReason.repeatUseful &&
              steps[i].reason != PathStepReason.together,
          isFalse,
          reason: 'Circle ${i + 1}',
        );
      }
    });

    test('both first tries turned down: Circle 3 tries the third piece', () {
      final (_, steps, _) = _walk(_run(_seeded), [_n, _n, null]);
      expect(steps[2].reason, PathStepReason.alternateAfterNegative);
      expect(steps[2].composition.modules, {ModuleId.activeTask});
    });

    test('a shorter form rated above the full one becomes the routine', () {
      final (run, _, answers) = _walk(_run(_seeded), [
        _v,
        _s,
        _v,
        _s,
        _s,
        _v,
        null,
      ]);
      final proposal = proposalFor(run, answers)!;
      expect(proposal.composition.minutes, 10);
    });

    test('a turned-down shorter form isn\'t kept as a shorter version', () {
      final (run, _, answers) = _walk(_run(_seeded), [
        _v,
        _s,
        _v,
        _v,
        _v,
        _n,
        _v,
      ]);
      final proposal = proposalFor(run, answers)!;
      expect(proposal.composition.minutes, 15);
      expect(proposal.shorter, isNull);
    });

    test('the review counts only answers about the routine\'s own pieces '
        'together', () {
      final (run, _, answers) = _walk(_run(_seeded), [
        _v,
        _s,
        _v,
        _v,
        _v,
        _s,
        _v,
      ]);
      final facts = proposalFor(run, answers)!.facts;
      expect(facts.piecesTried, [ModuleId.musicMove, ModuleId.standingStretch]);
      expect(facts.answeredForResult, 4);
      expect(facts.positiveForResult, 4);
    });
  });

  group('today\'s time', () {
    test('a step fits at its own length; else its truly shorter form, said '
        'so; else not at all — the Path waits', () {
      final step = PathStep(
        number: 4,
        composition: Composition(const [
          ModuleUse(ModuleId.standingStretch, short: false),
          ModuleUse(ModuleId.musicMove, short: false),
        ]),
        reason: PathStepReason.together,
      );
      expect(fitToWindow(step, TimeWindow.about20)!.reason, step.reason);
      final short = fitToWindow(step, TimeWindow.about10)!;
      expect(short.composition.minutes, 10);
      expect(short.reason, PathStepReason.shorterToFit);

      final walk = PathStep(
        number: 3,
        composition: Composition(const [
          ModuleUse(ModuleId.briskWalk, short: false),
        ]),
        reason: PathStepReason.fullPiece,
      );
      expect(fitToWindow(walk, TimeWindow.about10), isNull);
    });

    test('a step whose piece the user has since asked not to see can\'t be '
        'today\'s Circle', () {
      final step = PathStep(
        number: 1,
        composition: Composition(const [
          ModuleUse(ModuleId.musicMove, short: true),
        ]),
        reason: PathStepReason.firstTry,
      );
      expect(
        stepAllowed(
          step,
          Intention.moreEnergy,
          controls: const SuggestionControls(
            notSuggested: {(ActivityId.moveToMusic, Intention.moreEnergy)},
          ),
          allowSafetyPending: false,
        ),
        isFalse,
      );
    });
  });

  group('tune-ups and shorter versions', () {
    final routine = Routine(
      id: 'r',
      name: 'My pick-me-up',
      need: Intention.moreEnergy,
      versions: [
        RoutineVersion(
          id: 'r-v1',
          number: 1,
          composition: Composition(const [
            ModuleUse(ModuleId.standingStretch, short: false),
            ModuleUse(ModuleId.musicMove, short: false),
          ]),
          createdAt: _today,
          origin: VersionOrigin.path,
        ),
      ],
      activeVersionId: 'r-v1',
      createdAt: _today,
      sourceTemplate: PathTemplateId.wakeUpIndoors,
    );

    test('a tune-up changes the piece with the weakest evidence, for one '
        'the user hasn\'t turned down or asked not to see', () {
      final pool = tuneUpPool(
        routine,
        _memory([_past(4, ActivityId.moveToMusic, usefulness: _v)]),
        controls: const SuggestionControls(
          notSuggested: {
            (ActivityId.activeHouseholdTask, Intention.moreEnergy),
          },
        ),
        allowSafetyPending: false,
      )!;
      expect(pool.first, ModuleId.standingStretch);
      expect(pool, isNot(contains(ModuleId.activeTask)));
      final run = PathRun(
        id: 't',
        kind: PathKind.tuneUp,
        need: Intention.moreEnergy,
        startedAt: _today,
        pool: pool,
        seed: SeedReason.sparseStart,
        routineId: 'r',
        baseVersionId: 'r-v1',
      );
      final step = nextPathStep(run, const {}, base: routine.active)!;
      expect(step.reason, PathStepReason.tuneSwap);
      expect(step.composition.modules, contains(ModuleId.musicMove));
      expect(
        step.composition.modules,
        isNot(contains(ModuleId.standingStretch)),
      );
      expect(step.composition.minutes, lessThanOrEqualTo(maxCircleMinutes));
    });

    test('a tune-up never proposes a resting piece as the fix, and changes '
        'a resting piece of the routine first; after the rest, the piece '
        'may be the fix again', () {
      // One active task found "Not useful" 3 days ago: resting.
      final resting = tuneUpPool(
        routine,
        _memory([_past(3, ActivityId.activeHouseholdTask, usefulness: _n)]),
        controls: SuggestionControls.none,
        allowSafetyPending: false,
      );
      expect(resting ?? const [], isNot(contains(ModuleId.activeTask)));
      // Move to music (in the routine) resting: it is the piece to change.
      final musicResting = tuneUpPool(
        routine,
        _memory([
          _past(3, ActivityId.moveToMusic, usefulness: _n),
          _past(30, ActivityId.energisingStretchFlow, usefulness: _n),
          _past(20, ActivityId.energisingStretchFlow, usefulness: _n),
        ]),
        controls: SuggestionControls.none,
        allowSafetyPending: false,
      )!;
      expect(musicResting.first, ModuleId.musicMove);
      // Rest over: One active task may be the fix again.
      final over = tuneUpPool(
        routine,
        _memory([_past(40, ActivityId.activeHouseholdTask, usefulness: _v)]),
        controls: SuggestionControls.none,
        allowSafetyPending: false,
      )!;
      expect(over, contains(ModuleId.activeTask));
    });

    test('a piece the user has since asked not to see is the one a tune-up '
        'replaces — whatever its evidence; two such pieces: no tune-up', () {
      final pool = tuneUpPool(
        routine,
        // Music has the stronger evidence, but the user asked not to see it.
        _memory([_past(4, ActivityId.moveToMusic, usefulness: _v)]),
        controls: const SuggestionControls(
          notSuggested: {(ActivityId.moveToMusic, Intention.moreEnergy)},
        ),
        allowSafetyPending: false,
      )!;
      expect(pool.first, ModuleId.musicMove);
      final run = PathRun(
        id: 't',
        kind: PathKind.tuneUp,
        need: Intention.moreEnergy,
        startedAt: _today,
        pool: pool,
        seed: SeedReason.sparseStart,
        routineId: 'r',
        baseVersionId: 'r-v1',
      );
      final step = nextPathStep(run, const {}, base: routine.active)!;
      expect(step.composition.modules, isNot(contains(ModuleId.musicMove)));
      expect(
        tuneUpPool(
          routine,
          _memory(const []),
          controls: const SuggestionControls(
            notSuggested: {
              (ActivityId.moveToMusic, Intention.moreEnergy),
              (ActivityId.energisingStretchFlow, Intention.moreEnergy),
            },
          ),
          allowSafetyPending: false,
        ),
        isNull,
      );
    });

    test('a shorter version is the same routine: every piece, in order, '
        'each full or in its authored short form — never one piece alone, '
        'never a cut timer (founder quality principle)', () {
      final base = routine.active.composition;
      final ten = shorterVersionOf(base, 10)!;
      expect(ten.minutes, 10);
      expect(
        [for (final u in ten.uses) u.module],
        [for (final u in base.uses) u.module],
      );
      // Nothing shorter keeps every piece: no "shorter routine" that is
      // really one ordinary activity.
      expect(shorterVersionOf(base, 5), isNull);
      expect(shorterVersionsOf(base, 30).map((c) => c.minutes), [10]);
    });

    test('every routine any Path can build: its shorter versions keep all '
        'of its pieces, or there is none', () {
      for (final template in pathCatalog) {
        for (final a in template.pool) {
          for (final b in template.pool) {
            if (a == b) continue;
            final base = fullTogether(a, b);
            if (base == null) continue;
            for (final target in const [10, 20, 30]) {
              for (final shorter in shorterVersionsOf(base, target)) {
                expect(shorter.modules, base.modules, reason: base.title);
                expect(shorter.minutes, lessThan(base.minutes));
                expect(shorter.minutes, lessThanOrEqualTo(target));
              }
            }
          }
        }
      }
    });

    test('two pieces of one length each have no shorter version at all — '
        'the routine just doesn\'t fit a shorter day yet', () {
      final pause = Composition(const [
        ModuleUse(ModuleId.warmDrink, short: false),
        ModuleUse(ModuleId.gentleStretch, short: false),
      ]);
      expect(shorterVersionsOf(pause, 10), isEmpty);
      expect(shorterVersionsOf(pause, 20), isEmpty);
    });

    test('a single-piece routine may be made shorter only by its own '
        'authored short form', () {
      final single = Composition(const [
        ModuleUse(ModuleId.musicMove, short: false),
      ]);
      expect(
        shorterVersionOf(single, 5),
        Composition(const [ModuleUse(ModuleId.musicMove, short: true)]),
      );
    });
  });
}

void _activeRests() {
  group('an active rest (Phase B "Not useful") is respected by Premium', () {
    test('"Don\'t suggest" stays harder than a rest: it holds after the rest '
        'is over', () {
      final seed = seedBuild(
        _wakeUp,
        _memory([_past(20, ActivityId.moveToMusic, usefulness: _n)]),
        controls: const SuggestionControls(
          notSuggested: {(ActivityId.moveToMusic, Intention.moreEnergy)},
        ),
        allowSafetyPending: false,
      )!;
      expect(seed.pool, isNot(contains(ModuleId.musicMove)));
    });

    test('a Don\'t-suggest and a rest together leave too little: the Path '
        'can\'t be built now — nothing is forced', () {
      expect(
        seedBuild(
          _wakeUp,
          _memory([_past(3, ActivityId.energisingStretchFlow, usefulness: _n)]),
          controls: const SuggestionControls(
            notSuggested: {(ActivityId.moveToMusic, Intention.moreEnergy)},
          ),
          allowSafetyPending: false,
        ),
        isNull,
      );
    });

    test('adapting, a Path never switches into a resting piece: two '
        'first tries turned down, and the third piece resting — Circle 3 '
        'goes back to a tried piece instead', () {
      final (_, steps, _) = _walk(
        _run(_seeded),
        [_n, _n, null],
        resting: {ModuleId.activeTask},
      );
      expect(
        steps[2].composition.modules,
        isNot(contains(ModuleId.activeTask)),
      );
      // Without the rest, it would have tried it.
      final (_, free, _) = _walk(_run(_seeded), [_n, _n, null]);
      expect(free[2].composition.modules, contains(ModuleId.activeTask));
    });

    test('a partner resting today is never joined in', () {
      final (_, steps, _) = _walk(
        _run(_seeded),
        [_v, _s, _v, null, null],
        resting: {ModuleId.standingStretch},
      );
      for (final step in steps.skip(3)) {
        expect(
          step.composition.modules,
          isNot(contains(ModuleId.standingStretch)),
          reason: 'Circle ${step.number}',
        );
      }
    });

    test('a step that would need a resting piece waits: it can\'t be '
        'today\'s Circle', () {
      final step = nextPathStep(_run(_seeded), const {})!;
      expect(
        stepAllowed(
          step,
          Intention.moreEnergy,
          controls: SuggestionControls.none,
          allowSafetyPending: false,
          resting: {step.composition.uses.first.module},
        ),
        isFalse,
      );
    });
  });
}

void _cardFit() {
  test('every Path step line fits the two lines of the Today card beside '
      'the World art (at most 60 characters, as Phase A\'s reasons), and '
      'every pairing\'s name at most two lines (40 characters) — so Start '
      'Circle stays on the first screen (S25 finding)', () {
    final tooLong = <String>{
      for (final reason in PathStepReason.values)
        for (final combined in const [false, true])
          if (pathStepExplanation(reason, combined: combined) case final line
              when line.length > 60)
            line,
      // A Path joins two pieces of its own pool; a tune-up may bring in a
      // piece from the need's other Path.
      for (final need in Intention.values)
        for (final a in {for (final t in pathsFor(need)) ...t.pool})
          for (final b in {for (final t in pathsFor(need)) ...t.pool})
            if (a != b)
              if (Composition([
                    ModuleUse(a, short: false),
                    ModuleUse(b, short: false),
                  ]).title
                  case final title when title.length > 40)
                title,
    };
    expect(tooLong, isEmpty);
  });
}
