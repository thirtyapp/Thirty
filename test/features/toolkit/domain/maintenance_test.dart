import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/home/domain/recommendation_policy.dart';
import 'package:thirty/features/toolkit/domain/maintenance.dart';
import 'package:thirty/features/toolkit/domain/module_library.dart';
import 'package:thirty/features/toolkit/domain/path_catalog.dart';
import 'package:thirty/features/toolkit/domain/toolkit_model.dart';

/// V2 Phase D — maintenance (ADR-022): explicit evidence only, enough of it
/// before any claim, one offer at a time, a cooldown after "Not now", and
/// an honest "nothing to change".

final _today = DateTime(2026, 11, 20);
const _v = PastUsefulness.veryUseful;
const _s = PastUsefulness.somewhatUseful;
const _n = PastUsefulness.notUseful;

Routine _routine({
  String id = 'r',
  Intention need = Intention.moreEnergy,
  List<ModuleUse> uses = const [
    ModuleUse(ModuleId.standingStretch, short: false),
    ModuleUse(ModuleId.musicMove, short: false),
  ],
  int createdDaysAgo = 50,
  PathTemplateId template = PathTemplateId.wakeUpIndoors,
  bool withShort = false,
}) {
  final created = _today.subtract(Duration(days: createdDaysAgo));
  final versions = [
    RoutineVersion(
      id: '$id-v1',
      number: 1,
      composition: Composition(uses),
      createdAt: created,
      origin: VersionOrigin.path,
      pathRunId: 'build-$id',
    ),
    if (withShort)
      RoutineVersion(
        id: '$id-v2',
        number: 2,
        composition: Composition([
          for (final u in uses) ModuleUse(u.module, short: true),
        ]),
        createdAt: created,
        origin: VersionOrigin.shorter,
      ),
  ];
  return Routine(
    id: id,
    name: 'My routine',
    need: need,
    versions: versions,
    activeVersionId: '$id-v1',
    shortVersionId: withShort ? '$id-v2' : null,
    createdAt: created,
    sourceTemplate: template,
  );
}

PastCircle _use(
  int daysAgo,
  PastUsefulness? usefulness, {
  String routineId = 'r',
  Intention need = Intention.moreEnergy,
  TimeWindow window = TimeWindow.about20,
  String? pathRunId,
}) => PastCircle(
  date: _today.subtract(Duration(days: daysAgo)),
  need: need,
  pathRunId: pathRunId,
  activityId: ActivityId.energisingStretchFlow,
  catalogVersion: catalogVersion,
  usefulness: usefulness,
  routineId: routineId,
  routineVersionId: '$routineId-v1',
  components: const [ActivityId.energisingStretchFlow, ActivityId.moveToMusic],
  window: window,
);

PastCircle _day(
  int daysAgo,
  Intention need,
  TimeWindow window, {
  ActivityId activity = ActivityId.moveToMusic,
  PastUsefulness? usefulness,
}) => PastCircle(
  date: _today.subtract(Duration(days: daysAgo)),
  need: need,
  activityId: activity,
  catalogVersion: catalogVersion,
  window: window,
  usefulness: usefulness,
);

/// Clearer Head six times in four weeks with about 20 minutes, Free's
/// ordinary picks answered [answers] (`null`: not answered).
List<PastCircle> _clearerHeadDays(List<PastUsefulness?> answers) => [
  for (final (i, d) in const [26, 21, 16, 12, 8, 4].indexed)
    _day(
      d,
      Intention.clearerHead,
      TimeWindow.about20,
      activity: ActivityId.quietAudioFocus,
      usefulness: answers[i],
    ),
];

List<MaintenanceOffer> _offers(
  ToolkitState toolkit,
  List<PastCircle> history, {
  SuggestionControls controls = SuggestionControls.none,
}) => maintenanceOffers(
  toolkit: toolkit,
  history: history,
  today: _today,
  memory: RecommendationMemory.of(
    _today,
    history,
    RecommendationPolicy.initial,
  ),
  controls: controls,
  allowSafetyPending: false,
);

void main() {
  group('fading', () {
    test('too few answers about the routine in use: no claim at all', () {
      final routine = _routine();
      final history = [_use(6, _v), _use(2, _n)];
      expect(routineStanding(routine, history, _today).fading, isFalse);
      expect(_offers(ToolkitState(routines: [routine]), history), isEmpty);
    });

    test('the Path that built it shows it used to suit — but "lately" is '
        'the routine in use, never the build', () {
      final routine = _routine(createdDaysAgo: 10);
      // The build's Circles of these pieces: very useful, all three.
      final build = [
        for (final d in [20, 16, 12]) _use(d, _v, pathRunId: 'build-r'),
      ];
      // A "Somewhat" in use: nothing to say.
      expect(
        routineStanding(routine, [...build, _use(4, _s)], _today).fading,
        isFalse,
      );
      // A "Not useful" in use, after a build that clearly suited: the engine
      // now rests it — and THIRTY offers to tune it rather than let it
      // quietly disappear.
      expect(
        routineStanding(routine, [...build, _use(4, _n)], _today).fading,
        isTrue,
      );
    });

    test('a build nobody answered, then one "Somewhat" and one "Not '
        'useful": too little evidence for any claim', () {
      final routine = _routine(createdDaysAgo: 10);
      final build = [
        for (final d in [20, 16, 12]) _use(d, null, pathRunId: 'build-r'),
      ];
      expect(
        routineStanding(routine, [
          ...build,
          _use(4, _s),
          _use(2, _n),
        ], _today).fading,
        isFalse,
      );
    });

    test('one middling answer after a good run is not fading', () {
      final history = [
        _use(20, _v),
        _use(16, _v),
        _use(12, _v),
        _use(8, _s),
        _use(4, _v),
        _use(2, _s),
      ];
      expect(routineStanding(_routine(), history, _today).fading, isFalse);
    });

    test('steady "somewhat useful" is steady, not fading', () {
      final history = [_use(20, _v), _use(12, _s), _use(8, _s), _use(4, _s)];
      expect(routineStanding(_routine(), history, _today).fading, isFalse);
    });

    test('used to suit, suits less well lately: a tune-up is offered', () {
      final history = [
        _use(30, _v),
        _use(24, _v),
        _use(18, _s),
        _use(12, _n),
        _use(6, _s),
      ];
      final routine = _routine();
      expect(routineStanding(routine, history, _today).fading, isTrue);
      final offers = _offers(ToolkitState(routines: [routine]), history);
      expect(offers.single.kind, OfferKind.fading);
      expect(offers.single.evidence, contains('hasn’t suited you as well'));
    });

    test('never positive is not "fading": the claim needs an earlier good '
        'answer', () {
      final history = [_use(20, _s), _use(16, _n), _use(12, _n), _use(8, _s)];
      expect(
        routineStanding(_routine(), [...history.skip(1)], _today).fading,
        isFalse,
      );
    });
  });

  group('time misfit', () {
    test('most recent days with less time than the routine takes: a '
        'shorter version is offered, saying exactly that', () {
      final routine = _routine();
      final history = [
        for (final d in [12, 9, 6, 4, 2])
          _day(d, Intention.moreEnergy, TimeWindow.about10),
      ];
      final offer = _offers(ToolkitState(routines: [routine]), history).single;
      expect(offer.kind, OfferKind.timeMisfit);
      expect(offer.targetMinutes, 10);
      expect(
        offer.evidence,
        'You’ve had about 10 minutes most days lately, and My routine takes '
        '15.',
      );
    });

    test('a routine with no truthful shorter version (its pieces have one '
        'length each) is never offered one: it just doesn\'t fit a shorter '
        'day yet', () {
      final pause = _routine(
        need: Intention.gentlerPace,
        uses: const [
          ModuleUse(ModuleId.warmDrink, short: false),
          ModuleUse(ModuleId.gentleStretch, short: false),
        ],
        template: PathTemplateId.softLanding,
      );
      final history = [
        for (final d in [12, 9, 6, 4, 2])
          _day(d, Intention.gentlerPace, TimeWindow.about10),
      ];
      expect(_offers(ToolkitState(routines: [pause]), history), isEmpty);
    });

    test('never made shorter while one of its pieces is resting after a '
        '"Not useful" — and offered again once the rest is over', () {
      List<PastCircle> withNotUseful(int daysAgo) => [
        _day(
          daysAgo,
          Intention.moreEnergy,
          TimeWindow.about20,
          activity: ActivityId.moveToMusic,
          usefulness: _n,
        ),
        for (final d in [12, 9, 6, 4, 2])
          _day(
            d,
            Intention.moreEnergy,
            TimeWindow.about10,
            activity: ActivityId.easyWalk,
          ),
      ];
      final toolkit = ToolkitState(routines: [_routine()]);
      expect(_offers(toolkit, withNotUseful(3)), isEmpty);
      expect(
        _offers(toolkit, withNotUseful(20)).single.kind,
        OfferKind.timeMisfit,
      );
    });

    test('three short days is not "most days"', () {
      final history = [
        _day(12, Intention.moreEnergy, TimeWindow.about20),
        _day(9, Intention.moreEnergy, TimeWindow.about20),
        _day(6, Intention.moreEnergy, TimeWindow.about20),
        for (final d in [4, 3, 2])
          _day(d, Intention.moreEnergy, TimeWindow.about10),
      ];
      expect(_offers(ToolkitState(routines: [_routine()]), history), isEmpty);
    });

    test('only the routine\'s own need counts', () {
      final history = [
        for (final d in [12, 9, 6, 4, 2])
          _day(d, Intention.clearerHead, TimeWindow.about10),
      ];
      expect(
        _offers(
          ToolkitState(routines: [_routine()]),
          history,
        ).where((o) => o.kind == OfferKind.timeMisfit),
        isEmpty,
      );
    });

    test('already solved by its shorter version: nothing to offer', () {
      final history = [
        for (final d in [12, 9, 6, 4, 2])
          _day(d, Intention.moreEnergy, TimeWindow.about10),
      ];
      expect(
        _offers(ToolkitState(routines: [_routine(withShort: true)]), history),
        isEmpty,
      );
    });
  });

  group('gap', () {
    // D — the one case a gap is real: a need chosen often, Free's own picks
    // for it rated weak, and no routine of the user's for it.
    test('D: repeated need, genuinely weak Free answers, no routine for '
        'it: one build may be offered — never a routine that exists', () {
      final offer = _offers(
        ToolkitState(routines: [_routine()]),
        _clearerHeadDays(const [_n, _s, _n, _n, _s, _n]),
      ).single;
      expect(offer.kind, OfferKind.gap);
      expect(offer.need, Intention.clearerHead);
      expect(offer.template, PathTemplateId.clearTheDecks);
      expect(
        offer.evidence,
        'You’ve often chosen Clearer Head lately, and no routine THIRTY can '
        'offer you fits it in about 20 minutes.',
      );
    });

    test('A: five "Somewhat useful" answers are Free serving the need — no '
        'gap is invented for Premium', () {
      expect(
        _offers(
          ToolkitState(routines: [_routine()]),
          _clearerHeadDays(const [_s, _s, _s, _s, _s, null]),
        ),
        isEmpty,
      );
    });

    test('B: mixed strong positive answers — no gap', () {
      expect(
        _offers(
          ToolkitState(routines: [_routine()]),
          _clearerHeadDays(const [_v, _s, _n, _v, _s, _v]),
        ),
        isEmpty,
      );
    });

    test('C: mostly unanswered — too little to say Free falls short, so no '
        'gap is claimed', () {
      expect(
        _offers(
          ToolkitState(routines: [_routine()]),
          _clearerHeadDays(const [null, _n, null, null, _n, null]),
        ),
        isEmpty,
      );
      expect(
        _offers(
          ToolkitState(routines: [_routine()]),
          _clearerHeadDays(const [null, null, null, null, null, null]),
        ),
        isEmpty,
      );
    });

    test('E: a routine of the user\'s already covers it — no gap; nor for a '
        'first routine (the Toolkit invites it), nor in a full Toolkit', () {
      final history = _clearerHeadDays(const [_n, _s, _n, _n, _s, _n]);
      expect(_offers(ToolkitState.empty, history), isEmpty);
      final covered = _routine(
        id: 'c',
        need: Intention.clearerHead,
        uses: const [
          ModuleUse(ModuleId.writeDown, short: true),
          ModuleUse(ModuleId.clearSurface, short: true),
        ],
        template: PathTemplateId.clearTheDecks,
      );
      expect(
        _offers(ToolkitState(routines: [_routine(), covered]), history),
        isEmpty,
      );
      final full = [for (var i = 0; i < 6; i++) _routine(id: 'r$i')];
      expect(_offers(ToolkitState(routines: full), history), isEmpty);
    });

    test('answers about a routine or a Path never stand in for Free\'s '
        'own picks', () {
      final routineAnswers = [
        for (final d in const [26, 21, 16, 12, 8, 4])
          _use(d, _n, need: Intention.clearerHead, routineId: 'other'),
      ];
      expect(
        _offers(ToolkitState(routines: [_routine()]), routineAnswers),
        isEmpty,
      );
    });
  });

  group('one at a time', () {
    test('priority: time misfit, then fading, then a gap', () {
      final routine = _routine();
      final history = [
        _use(40, _v),
        _use(36, _v),
        _use(26, _s),
        _use(20, _n),
        _use(15, _s),
        for (final d in [12, 9, 6, 4, 2])
          _day(d, Intention.moreEnergy, TimeWindow.about10),
        for (final d in [27, 22, 17, 13, 8, 3])
          _day(
            d,
            Intention.clearerHead,
            TimeWindow.about20,
            activity: ActivityId.quietAudioFocus,
            usefulness: d.isEven ? _n : _s,
          ),
      ];
      final kinds = _offers(
        ToolkitState(routines: [routine]),
        history,
      ).map((o) => o.kind);
      expect(kinds.first, OfferKind.timeMisfit);
      expect(kinds, containsAllInOrder([OfferKind.timeMisfit, OfferKind.gap]));
    });

    test('nothing is offered while a Path is under way', () {
      final history = [
        for (final d in [12, 9, 6, 4, 2])
          _day(d, Intention.moreEnergy, TimeWindow.about10),
      ];
      final busy = ToolkitState(
        routines: [_routine()],
        path: PathRun(
          id: 'p',
          kind: PathKind.build,
          need: Intention.gentlerPace,
          startedAt: _today,
          pool: const [ModuleId.warmDrink, ModuleId.gentleStretch],
          seed: SeedReason.sparseStart,
          template: PathTemplateId.softLanding,
        ),
      );
      expect(_offers(busy, history), isEmpty);
    });

    test('"Not now" keeps an offer away for three weeks, then it may come '
        'back', () {
      final history = [
        for (final d in [12, 9, 6, 4, 2])
          _day(d, Intention.moreEnergy, TimeWindow.about10),
      ];
      final key = _offers(
        ToolkitState(routines: [_routine()]),
        history,
      ).single.key;
      expect(
        _offers(
          ToolkitState(
            routines: [_routine()],
            declined: {key: _today.subtract(const Duration(days: 5))},
          ),
          history,
        ),
        isEmpty,
      );
      expect(
        _offers(
          ToolkitState(
            routines: [_routine()],
            declined: {key: _today.subtract(const Duration(days: 22))},
          ),
          history,
        ),
        hasLength(1),
      );
    });

    test('a routine the user asked not to see for its need gets no offers', () {
      final history = [
        for (final d in [12, 9, 6, 4, 2])
          _day(d, Intention.moreEnergy, TimeWindow.about10),
      ];
      expect(
        _offers(
          ToolkitState(routines: [_routine()]),
          history,
          controls: const SuggestionControls(
            routinesNotSuggested: {('r', Intention.moreEnergy)},
          ),
        ),
        isEmpty,
      );
    });
  });

  group('the Toolkit check', () {
    test('not due before four weeks; then stable when steady answers say '
        'so — or still learning when there are too few', () {
      final fresh = ToolkitState(routines: [_routine(createdDaysAgo: 10)]);
      expect(
        toolkitCheck(
          toolkit: fresh,
          history: const [],
          today: _today,
          offer: null,
        ),
        isNull,
      );
      final routine = _routine(createdDaysAgo: 40);
      final steady = [_use(20, _v), _use(14, _s), _use(7, _v)];
      final stable = toolkitCheck(
        toolkit: ToolkitState(routines: [routine]),
        history: steady,
        today: _today,
        offer: null,
      )!;
      expect(stable.state, CheckState.stable);
      expect(
        stable.message,
        'Your routines are working well — nothing to change.',
      );
      final learning = toolkitCheck(
        toolkit: ToolkitState(routines: [routine]),
        history: [_use(7, _v)],
        today: _today,
        offer: null,
      )!;
      expect(learning.state, CheckState.learning);
      expect(learning.message, 'Still learning how these fit.');
    });

    test('never "working well" with a "Not useful" in the period, and not '
        'at all while a Path is under way (S25 finding)', () {
      final routine = _routine(createdDaysAgo: 40);
      final mixed = toolkitCheck(
        toolkit: ToolkitState(routines: [routine]),
        history: [_use(20, _v), _use(14, _n), _use(7, _v)],
        today: _today,
        offer: null,
      )!;
      expect(mixed.state, CheckState.learning);
      final tuning = toolkitCheck(
        toolkit: ToolkitState(
          routines: [routine],
          path: PathRun(
            id: 'p',
            kind: PathKind.tuneUp,
            need: Intention.moreEnergy,
            startedAt: _today,
            pool: const [ModuleId.musicMove, ModuleId.activeTask],
            seed: SeedReason.sparseStart,
            routineId: routine.id,
          ),
        ),
        history: [_use(20, _v), _use(14, _v), _use(7, _v)],
        today: _today,
        offer: null,
      );
      expect(tuning, isNull);
    });

    test('seen recently: not due again for four weeks', () {
      final routine = _routine(createdDaysAgo: 60);
      expect(
        toolkitCheck(
          toolkit: ToolkitState(
            routines: [routine],
            lastCheckAt: _today.subtract(const Duration(days: 10)),
          ),
          history: const [],
          today: _today,
          offer: null,
        ),
        isNull,
      );
    });
  });

  group('the store', () {
    test('round-trips, and skips only what it can\'t read', () {
      final routine = _routine(withShort: true);
      final state = ToolkitState(
        routines: [routine],
        declined: {'gap:clearerHead': _today},
        lastCheckAt: _today,
      );
      final back = ToolkitState.fromJson(
        jsonDecode(jsonEncode(state.toJson())),
      )!;
      expect(back.routines.single.versions, hasLength(2));
      expect(back.routines.single.shortVersion?.minutes, 10);
      expect(back.declined.keys, ['gap:clearerHead']);

      final raw = state.toJson()
        ..['routines'] = [
          routine.toJson(),
          {'id': 'broken'},
          routine.toJson(), // a duplicate id is read once
        ];
      final salvaged = ToolkitState.fromJson(jsonDecode(jsonEncode(raw)))!;
      expect(salvaged.routines, hasLength(1));
      expect(ToolkitState.fromJson({'schemaVersion': 99}), isNull);
    });

    test('a routine whose active version is lost is not guessed at', () {
      final json = _routine().toJson()..['activeVersionId'] = 'missing';
      expect(Routine.fromJson(json), isNull);
    });

    test('a Path with a gap in its Circles stops at the gap', () {
      final run = PathRun(
        id: 'p',
        kind: PathKind.build,
        need: Intention.moreEnergy,
        startedAt: _today,
        pool: const [ModuleId.musicMove, ModuleId.standingStretch],
        seed: SeedReason.sparseStart,
        template: PathTemplateId.wakeUpIndoors,
      );
      final json = run.toJson()
        ..['circles'] = [
          {
            'circleId': 'a',
            'number': 1,
            'modules': ['musicMove:short'],
            'reason': 'firstTry',
          },
          {
            'circleId': 'c',
            'number': 3,
            'modules': ['musicMove:full'],
            'reason': 'fullPiece',
          },
        ];
      expect(PathRun.fromJson(json)!.circles, hasLength(1));
    });
  });
}
