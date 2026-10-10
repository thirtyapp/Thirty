import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/domain/memory_overview.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/home/domain/recommendation_policy.dart';

/// V2 Phase C (ADR-021): the user's explicit suggestion controls in Engine
/// V2, and the memory page's view of what the user told THIRTY.
final _today = DateTime(2026, 11, 20);

DateTime _ago(int days) => _today.subtract(Duration(days: days));

PastCircle _past(
  int daysAgo,
  Intention need,
  ActivityId activity, {
  PastUsefulness? answer,
  TimeWindow? window,
  ActivityId? replacedFrom,
}) => PastCircle(
  date: _ago(daysAgo),
  need: need,
  activityId: activity,
  catalogVersion: catalogVersion,
  usefulness: answer,
  answeredAt: _ago(daysAgo).add(const Duration(hours: 9)),
  window: window,
  replacedFrom: replacedFrom,
);

RecommendationDecision? _pick(
  Intention need, {
  TimeWindow window = TimeWindow.about20,
  List<PastCircle> history = const [],
  SuggestionControls controls = SuggestionControls.none,
  DateTime? date,
  ReplacementRequest? replacement,
}) => recommend(
  RecommendationContext(
    date: date ?? _today,
    need: need,
    window: window,
    replacement: replacement,
    allowSafetyPending: false,
  ),
  history,
  controls: controls,
);

const _energy = Intention.moreEnergy;
const _clearer = Intention.clearerHead;
const _gentler = Intention.gentlerPace;
const _very = PastUsefulness.veryUseful;
const _not = PastUsefulness.notUseful;

/// More Energy's five fits at ≈ 10.
const _tenMinuteEnergy = [
  ActivityId.moveToMusic,
  ActivityId.energisingStretchFlow,
  ActivityId.activeHouseholdTask,
  ActivityId.tidyOneSurface,
  ActivityId.gentleStretchPause,
];

void main() {
  group('"Don\'t suggest" — a hard constraint the engine never relaxes', () {
    test('never offered for that need — not even when it is the user\'s '
        'favourite, across 60 days of fallback, exploration and every '
        'window', () {
      const controls = SuggestionControls(
        notSuggested: {(ActivityId.moveToMusic, _energy)},
      );
      final history = <PastCircle>[];
      for (var day = 0; day < 60; day++) {
        final date = _today.add(Duration(days: day));
        final window = TimeWindow.values[day % 3];
        final d = _pick(
          _energy,
          window: window,
          history: history,
          controls: controls,
          date: date,
        )!;
        expect(d.activityId, isNot(ActivityId.moveToMusic), reason: '$day');
        history.add(
          PastCircle(
            date: date,
            need: _energy,
            activityId: d.activityId,
            catalogVersion: catalogVersion,
            // Rejects everything it is offered: fallback pressure is high.
            usefulness: _not,
          ),
        );
      }
      // Even the user's own past "Very useful" doesn't bring it back.
      expect(
        _pick(
          _energy,
          history: [
            _past(9, _energy, ActivityId.moveToMusic, answer: _very),
            _past(5, _energy, ActivityId.moveToMusic, answer: _very),
          ],
          controls: controls,
        )!.activityId,
        isNot(ActivityId.moveToMusic),
      );
    });

    test('nor as a replacement', () {
      const controls = SuggestionControls(
        notSuggested: {(ActivityId.tidyOneSurface, _clearer)},
      );
      for (final reason in ReplacementReason.values) {
        final d = _pick(
          _clearer,
          controls: controls,
          replacement: ReplacementRequest(
            reason: reason,
            replacing: ActivityId.writeItDown,
            replacingMinutes: 15,
          ),
        );
        expect(d?.activityId, isNot(ActivityId.tidyOneSurface));
      }
    });

    test('is per need: it never leaks into another need', () {
      const controls = SuggestionControls(
        notSuggested: {(ActivityId.easyWalk, _energy)},
      );
      // Easy walk is Gentler Pace's curated start, untouched.
      expect(
        _pick(_gentler, controls: controls)!.activityId,
        ActivityId.easyWalk,
      );
    });

    test('when it leaves nothing that fits, there is no pick at all — '
        'never an override, never another time or need', () {
      final controls = SuggestionControls(
        notSuggested: {for (final id in _tenMinuteEnergy) (id, _energy)},
      );
      expect(
        _pick(_energy, window: TimeWindow.about10, controls: controls),
        isNull,
      );
      // Another time still has fits.
      expect(_pick(_energy, controls: controls), isNotNull);
    });
  });

  group('"Suggest again" on a rest', () {
    final history = [
      _past(6, _energy, ActivityId.activeHouseholdTask),
      _past(3, _energy, ActivityId.moveToMusic, answer: _not),
      _past(2, _energy, ActivityId.energisingStretchFlow),
      _past(1, _energy, ActivityId.thirtyMinuteWalk),
    ];

    test('lifts the current rest without rewriting the answer: eligible '
        'again, its negative evidence still counted', () {
      // Resting: never offered for 10 days at ≈ 10.
      for (var day = 0; day < 10; day++) {
        final d = _pick(
          _energy,
          window: TimeWindow.about10,
          history: history,
          date: _today.add(Duration(days: day)),
        )!;
        expect(d.activityId, isNot(ActivityId.moveToMusic));
      }
      final lifted = SuggestionControls(
        restsLifted: {
          (ActivityId.moveToMusic, _energy): _today.subtract(
            const Duration(hours: 2),
          ),
        },
      );
      final memory = RecommendationMemory.of(
        _today,
        history,
        RecommendationPolicy.initial,
        restsLifted: lifted.restsLifted,
      );
      expect(
        memory.daysSinceNotUseful(ActivityId.moveToMusic, _energy),
        isNull,
      );
      expect(memory.strengthFor(ActivityId.moveToMusic, _energy), -2);
      // Somewhere in the next fortnight it comes up — under the normal
      // rules, not forced to be tomorrow's pick.
      final offered = {
        for (var day = 0; day < 14; day++)
          _pick(
            _energy,
            window: TimeWindow.about10,
            history: history,
            controls: lifted,
            date: _today.add(Duration(days: day)),
          )!.activityId,
      };
      expect(offered, contains(ActivityId.moveToMusic));
    });

    test('a later "Not useful" rests it again', () {
      final liftedAt = _ago(3).add(const Duration(hours: 12));
      final memory = RecommendationMemory.of(
        _today,
        [...history, _past(1, _energy, ActivityId.moveToMusic, answer: _not)],
        RecommendationPolicy.initial,
        restsLifted: {(ActivityId.moveToMusic, _energy): liftedAt},
      );
      expect(memory.daysSinceNotUseful(ActivityId.moveToMusic, _energy), 1);
    });

    test('is per need, like the answer itself', () {
      final memory = RecommendationMemory.of(
        _today,
        [_past(3, _gentler, ActivityId.easyWalk, answer: _not)],
        RecommendationPolicy.initial,
        restsLifted: {(ActivityId.easyWalk, _energy): _today},
      );
      expect(memory.daysSinceNotUseful(ActivityId.easyWalk, _gentler), 3);
    });
  });

  group('the memory page: only what the user said, per need', () {
    NeedMemory memoryOf(
      Intention need,
      List<PastCircle> history, {
      SuggestionControls controls = SuggestionControls.none,
    }) => needMemoryOf(
      today: _today,
      need: need,
      history: history,
      controls: controls,
      allowSafetyPending: false,
    );

    final history = [
      _past(
        20,
        _clearer,
        ActivityId.quietReading,
        answer: PastUsefulness.somewhatUseful,
      ),
      _past(12, _energy, ActivityId.thirtyMinuteWalk, answer: _very),
      _past(9, _clearer, ActivityId.writeItDown, answer: _very),
      // Offered, started, closed — no answer: says nothing.
      _past(7, _energy, ActivityId.activeHouseholdTask),
      _past(4, _gentler, ActivityId.easyWalk, answer: _not),
      _past(30, _gentler, ActivityId.quietMusicBreak, answer: _not),
      // Today's own answer counts at once.
      _past(0, _clearer, ActivityId.tidyOneSurface, answer: _not),
    ];

    test('useful, resting and "not useful before" from the latest answer '
        'for that need alone', () {
      final clearer = memoryOf(_clearer, history);
      expect(clearer.usefulBefore.map((r) => r.activity), [
        ActivityId.writeItDown,
        ActivityId.quietReading,
      ]);
      expect(clearer.resting.single.activity, ActivityId.tidyOneSurface);
      expect(clearer.resting.single.restsUntil, DateTime.utc(2026, 12, 4));

      final gentler = memoryOf(_gentler, history);
      expect(gentler.resting.single.activity, ActivityId.easyWalk);
      expect(
        gentler.notUsefulBefore.single.activity,
        ActivityId.quietMusicBreak,
      );
      // An answer for one need is never shown for another.
      expect(memoryOf(_energy, history).usefulBefore.map((r) => r.activity), [
        ActivityId.thirtyMinuteWalk,
      ]);
    });

    test('no answer is not "not tried": an unanswered Circle appears in no '
        'section, and "not come up yet" counts only what was never '
        'offered', () {
      final energy = memoryOf(_energy, history);
      for (final section in [
        energy.usefulBefore,
        energy.resting,
        energy.notUsefulBefore,
      ]) {
        expect(
          section.map((r) => r.activity),
          isNot(contains(ActivityId.activeHouseholdTask)),
        );
      }
      final fits = ActivityId.values.where(
        (id) =>
            activityDefinition(id).fitFor(_energy) != NeedFit.none &&
            isActivityOfferable(id, allowSafetyPending: false),
      );
      expect(energy.notOfferedYet, fits.length - 2);
    });

    test('"Don\'t suggest" shows as the user\'s own choice, for that need '
        'only, in place of its answers', () {
      const controls = SuggestionControls(
        notSuggested: {(ActivityId.writeItDown, _clearer)},
      );
      final clearer = memoryOf(_clearer, history, controls: controls);
      expect(clearer.notSuggested, [ActivityId.writeItDown]);
      expect(
        clearer.usefulBefore.map((r) => r.activity),
        isNot(contains(ActivityId.writeItDown)),
      );
      expect(
        memoryOf(_gentler, history, controls: controls).notSuggested,
        isEmpty,
      );
    });

    test('a lifted rest is no longer resting, and says so', () {
      final lifted = SuggestionControls(
        restsLifted: {(ActivityId.easyWalk, _gentler): _ago(1)},
      );
      final gentler = memoryOf(_gentler, history, controls: lifted);
      expect(gentler.resting, isEmpty);
      expect(
        gentler.notUsefulBefore.map((r) => r.activity),
        contains(ActivityId.easyWalk),
      );
    });

    test('the memory page and the engine agree: what rests is never '
        'offered while anything else fits', () {
      final gentler = memoryOf(_gentler, history);
      final resting = gentler.resting.map((r) => r.activity).toSet();
      for (var day = 0; day < 10; day++) {
        final d = _pick(
          _gentler,
          history: history,
          date: _today.add(Duration(days: day + 1)),
        )!;
        expect(resting, isNot(contains(d.activityId)));
      }
    });

    test('a usual time only from three or more explicit choices with a '
        'clear leader', () {
      List<PastCircle> choices(List<TimeWindow> windows) => [
        for (final (i, window) in windows.indexed)
          _past(i + 1, _clearer, ActivityId.writeItDown, window: window),
      ];
      const t10 = TimeWindow.about10;
      const t20 = TimeWindow.about20;
      expect(memoryOf(_clearer, choices([t20, t20])).usualTime, isNull);
      expect(memoryOf(_clearer, choices([t20, t20, t20])).usualTime, t20);
      expect(memoryOf(_clearer, choices([t20, t20, t10])).usualTime, t20);
      expect(
        memoryOf(_clearer, choices([t20, t20, t10, t10])).usualTime,
        isNull,
      );
      expect(
        memoryOf(_clearer, choices([t20, t20, t10, t10, t20])).usualTime,
        t20,
      );
      // Choices for another need never count.
      expect(memoryOf(_energy, choices([t20, t20, t20])).usualTime, isNull);
    });

    test('with no history, nothing is claimed — but what the user chose '
        'stays (Delete keeps "Don\'t suggest")', () {
      const controls = SuggestionControls(
        notSuggested: {(ActivityId.moveToMusic, _energy)},
      );
      final energy = memoryOf(_energy, const [], controls: controls);
      expect(energy.hasAnswers, isFalse);
      expect(energy.usualTime, isNull);
      expect(energy.notSuggested, [ActivityId.moveToMusic]);
    });
  });
}
