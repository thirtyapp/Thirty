import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/home/domain/recommendation_policy.dart';

/// V2 Phase D — the user's routines as Engine V2 candidates (ADR-022 §4):
/// ordinary candidates under the same hard limits and the same ranking, with
/// their own evidence — and no Premium bonus of any kind.

final _today = DateTime(2026, 11, 20);

const _wakeUp = RoutineCandidate(
  id: 'wake',
  fit: {
    Intention.moreEnergy: NeedFit.primary,
    Intention.clearerHead: NeedFit.secondary,
  },
  forms: [
    (versionId: 'wake-v1', minutes: 15),
    (versionId: 'wake-v2', minutes: 10),
  ],
  components: [ActivityId.energisingStretchFlow, ActivityId.moveToMusic],
  setting: ActivitySetting.either,
  effort: ActivityEffort.low,
);

PastCircle _routineDay(
  int daysAgo,
  PastUsefulness? usefulness, {
  String id = 'wake',
}) => PastCircle(
  date: _today.subtract(Duration(days: daysAgo)),
  need: Intention.moreEnergy,
  activityId: ActivityId.energisingStretchFlow,
  catalogVersion: catalogVersion,
  usefulness: usefulness,
  routineId: id,
  routineVersionId: '$id-v1',
  components: const [ActivityId.energisingStretchFlow, ActivityId.moveToMusic],
);

PastCircle _activityDay(
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

RecommendationDecision? _pick(
  List<PastCircle> history, {
  List<RoutineCandidate> routines = const [_wakeUp],
  TimeWindow window = TimeWindow.about20,
  Intention need = Intention.moreEnergy,
  SuggestionControls controls = SuggestionControls.none,
  ReplacementRequest? replacement,
  DateTime? date,
}) => recommend(
  RecommendationContext(
    date: date ?? _today,
    need: need,
    window: window,
    allowSafetyPending: false,
    routines: routines,
    replacement: replacement,
  ),
  history,
  controls: controls,
);

/// A settled More Energy history with no evidence about the routine.
final _settled = [
  for (final (d, a) in [
    (30, ActivityId.thirtyMinuteWalk),
    (27, ActivityId.moveToMusic),
    (24, ActivityId.activeHouseholdTask),
    (21, ActivityId.energisingStretchFlow),
  ])
    _activityDay(d, a, usefulness: PastUsefulness.somewhatUseful),
];

void main() {
  test('no Premium bonus: a routine with no evidence of its own never beats '
      'an activity the user found very useful and is ready again', () {
    final decision = _pick([
      ..._settled,
      _activityDay(
        10,
        ActivityId.activeHouseholdTask,
        usefulness: PastUsefulness.veryUseful,
      ),
    ]);
    expect(decision!.routineId, isNull);
  });

  test('a routine with its own useful answers can win — on that evidence, '
      'with the truthful reason', () {
    final decision = _pick([
      ..._settled,
      _routineDay(12, PastUsefulness.veryUseful),
      _routineDay(8, PastUsefulness.veryUseful),
      _activityDay(6, ActivityId.thirtyMinuteWalk),
      _activityDay(4, ActivityId.moveToMusic),
    ]);
    expect(decision!.routineId, 'wake');
    expect(decision.reason, RecommendationReason.usefulHere);
  });

  test('a routine and an activity with exactly the same standing are '
      'separated only by the same date-seeded tie-break', () {
    // Over many days, neither always wins: no hidden preference.
    final winners = <String>{};
    for (var day = 0; day < 40; day++) {
      final date = _today.add(Duration(days: day));
      final decision = recommend(
        RecommendationContext(
          date: date,
          need: Intention.moreEnergy,
          window: TimeWindow.about20,
          allowSafetyPending: false,
          routines: const [_wakeUp],
        ),
        const [],
      )!;
      winners.add(decision.routineId ?? decision.activityId.name);
    }
    expect(winners, isNot(contains('wake')));
    // With no history at all the curated starter order serves a new user —
    // a routine is never a newcomer's default.
  });

  test('time: the longest version that truly fits — never a cut-down one', () {
    final history = [
      ..._settled,
      _routineDay(12, PastUsefulness.veryUseful),
      _routineDay(8, PastUsefulness.veryUseful),
      _activityDay(6, ActivityId.thirtyMinuteWalk),
      _activityDay(4, ActivityId.moveToMusic),
    ];
    final ten = _pick(history, window: TimeWindow.about10)!;
    expect(ten.routineId, 'wake');
    expect(ten.routineVersionId, 'wake-v2');
    expect(ten.offeredMinutes, 10);

    const longOnly = RoutineCandidate(
      id: 'wake',
      fit: {Intention.moreEnergy: NeedFit.primary},
      forms: [(versionId: 'wake-v1', minutes: 15)],
      components: [ActivityId.energisingStretchFlow, ActivityId.moveToMusic],
      setting: ActivitySetting.either,
      effort: ActivityEffort.low,
    );
    final none = _pick(
      history,
      routines: const [longOnly],
      window: TimeWindow.about10,
    )!;
    expect(none.routineId, isNull);
  });

  test('recency: never yesterday\'s routine, and never a routine holding '
      'yesterday\'s activity', () {
    final strong = [
      ..._settled,
      _routineDay(12, PastUsefulness.veryUseful),
      _routineDay(8, PastUsefulness.veryUseful),
    ];
    expect(_pick([...strong, _routineDay(1, null)])!.routineId, isNull);
    expect(
      _pick([...strong, _activityDay(1, ActivityId.moveToMusic)])!.routineId,
      isNull,
    );
  });

  test('a routine Circle counts for its activities\' recency — they are not '
      'offered the next day either', () {
    final decision = _pick([..._settled, _routineDay(1, null)]);
    expect([
      ActivityId.energisingStretchFlow,
      ActivityId.moveToMusic,
    ], isNot(contains(decision!.activityId)));
  });

  test('a routine\'s answers are its own evidence — never evidence about '
      'the activities inside it', () {
    final memory = RecommendationMemory.of(_today, [
      _routineDay(10, PastUsefulness.veryUseful),
      _routineDay(5, PastUsefulness.notUseful),
    ], RecommendationPolicy.initial);
    expect(memory.strengthFor(ActivityId.moveToMusic, Intention.moreEnergy), 0);
    expect(memory.routineStrength('wake', Intention.moreEnergy), 0);
    expect(
      memory.daysSinceNotUseful(
        ActivityId.energisingStretchFlow,
        Intention.moreEnergy,
      ),
      isNull,
    );
    expect(memory.routineDaysSinceNotUseful('wake', Intention.moreEnergy), 5);
  });

  test('"Not useful" rests a routine like anything else', () {
    final decision = _pick([
      ..._settled,
      _routineDay(12, PastUsefulness.veryUseful),
      _routineDay(6, PastUsefulness.notUseful),
    ]);
    expect(decision!.routineId, isNull);
  });

  test('"Don\'t suggest" — for the routine, or for any piece of it — is a '
      'hard limit; another need is untouched', () {
    final history = [
      ..._settled,
      _routineDay(12, PastUsefulness.veryUseful),
      _routineDay(8, PastUsefulness.veryUseful),
      _activityDay(6, ActivityId.thirtyMinuteWalk),
      _activityDay(4, ActivityId.moveToMusic),
    ];
    expect(_pick(history)!.routineId, 'wake');
    expect(
      _pick(
        history,
        controls: const SuggestionControls(
          routinesNotSuggested: {('wake', Intention.moreEnergy)},
        ),
      )!.routineId,
      isNull,
    );
    expect(
      _pick(
        history,
        controls: const SuggestionControls(
          notSuggested: {(ActivityId.moveToMusic, Intention.moreEnergy)},
        ),
      )!.routineId,
      isNull,
    );
  });

  test('"Not this one today" on a routine never offers it, or any piece of '
      'it, again today', () {
    final decision = _pick(
      [..._settled],
      replacement: const ReplacementRequest(
        reason: ReplacementReason.notFeeling,
        replacing: ActivityId.energisingStretchFlow,
        replacingMinutes: 15,
        replacingRoutineId: 'wake',
        replacingComponents: [
          ActivityId.energisingStretchFlow,
          ActivityId.moveToMusic,
        ],
      ),
    )!;
    expect(decision.routineId, isNull);
    expect([
      ActivityId.energisingStretchFlow,
      ActivityId.moveToMusic,
    ], isNot(contains(decision.activityId)));
  });

  test('a deleted routine is simply not a candidate', () {
    final decision = _pick([
      ..._settled,
      _routineDay(12, PastUsefulness.veryUseful),
      _routineDay(8, PastUsefulness.veryUseful),
    ], routines: const []);
    expect(decision!.routineId, isNull);
  });

  test('a routine is never offered as "something new to try"', () {
    for (var day = 0; day < 30; day++) {
      final decision = _pick(_settled, date: _today.add(Duration(days: day)))!;
      if (decision.routineId != null) {
        expect(decision.reason, isNot(RecommendationReason.tryingNew));
      }
    }
  });

  group('a resting piece keeps its routine out — only while it rests', () {
    // The routine wins on its own evidence here (see "a routine with its
    // own useful answers can win").
    final strong = [
      ..._settled,
      _routineDay(12, PastUsefulness.veryUseful),
      _routineDay(8, PastUsefulness.veryUseful),
      _activityDay(6, ActivityId.thirtyMinuteWalk),
      _activityDay(4, ActivityId.activeHouseholdTask),
    ];
    // 13 days ago: still within the 14-day rest.
    PastCircle musicNotUseful(int daysAgo, {Intention? need}) => _activityDay(
      daysAgo,
      ActivityId.moveToMusic,
      need: need ?? Intention.moreEnergy,
      usefulness: PastUsefulness.notUseful,
    );

    test('baseline: with no rest, the routine is today\'s pick', () {
      expect(_pick(strong)!.routineId, 'wake');
    });

    test('A + F: a piece resting for this need — Memory says "resting" — '
        'keeps the routine out; an ordinary activity wins normally, never '
        'a resting one and never "nothing fits"', () {
      final decision = _pick([...strong, musicNotUseful(13)]);
      expect(decision, isNotNull);
      expect(decision!.routineId, isNull);
      expect(decision.activityId, isNot(ActivityId.moveToMusic));
    });

    test('B: once the rest is over, the routine is eligible again', () {
      expect(_pick([...strong, musicNotUseful(20)])!.routineId, 'wake');
    });

    test('C: "Suggest again" lifts the rest — the routine is eligible '
        'again at once', () {
      final decision = _pick(
        [...strong, musicNotUseful(13)],
        controls: SuggestionControls(
          restsLifted: {
            (ActivityId.moveToMusic, Intention.moreEnergy): _today.subtract(
              const Duration(days: 1),
            ),
          },
        ),
      );
      expect(decision!.routineId, 'wake');
    });

    test('D: "Not useful" about the routine rests the routine — and none of '
        'its pieces: the user can dislike the combination, not each part', () {
      final history = [
        ..._settled,
        _routineDay(12, PastUsefulness.veryUseful),
        _routineDay(3, PastUsefulness.notUseful),
      ];
      final memory = RecommendationMemory.of(
        _today,
        history,
        RecommendationPolicy.initial,
      );
      expect(memory.routineDaysSinceNotUseful('wake', Intention.moreEnergy), 3);
      for (final piece in _wakeUp.components) {
        expect(
          memory.daysSinceNotUseful(piece, Intention.moreEnergy),
          isNull,
          reason: piece.name,
        );
      }
      expect(_pick(history)!.routineId, isNull);
    });

    test('E: a piece resting for another need doesn\'t touch this one', () {
      expect(
        _pick([
          ...strong,
          musicNotUseful(13, need: Intention.clearerHead),
        ])!.routineId,
        'wake',
      );
    });
  });
}
