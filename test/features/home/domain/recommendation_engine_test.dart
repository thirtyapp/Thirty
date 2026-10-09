import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/home/domain/recommendation_policy.dart';

final _today = DateTime(2026, 11, 20);

DateTime _ago(int days) => _today.subtract(Duration(days: days));

PastCircle _past(
  int daysAgo,
  Intention need,
  ActivityId activity, {
  PastUsefulness? answer,
  int version = catalogVersion,
  ActivityId? replacedFrom,
}) => PastCircle(
  date: _ago(daysAgo),
  need: need,
  activityId: activity,
  catalogVersion: version,
  usefulness: answer,
  replacedFrom: replacedFrom,
);

RecommendationDecision _pick(
  Intention need, {
  TimeWindow window = TimeWindow.about20,
  List<PastCircle> history = const [],
  ReplacementRequest? replacement,
  DateTime? date,
  bool allowSafetyPending = false,
}) => recommend(
  RecommendationContext(
    date: date ?? _today,
    need: need,
    window: window,
    replacement: replacement,
    allowSafetyPending: allowSafetyPending,
  ),
  history,
)!;

const _energy = Intention.moreEnergy;
const _clearer = Intention.clearerHead;
const _gentler = Intention.gentlerPace;
const _very = PastUsefulness.veryUseful;
const _somewhat = PastUsefulness.somewhatUseful;
const _not = PastUsefulness.notUseful;

/// A busy, mixed fortnight of history used by the coverage checks.
final _busy = [
  for (var i = 1; i <= 14; i++)
    _past(
      i,
      Intention.values[i % 3],
      [
        ActivityId.thirtyMinuteWalk,
        ActivityId.writeItDown,
        ActivityId.easyWalk,
        ActivityId.moveToMusic,
        ActivityId.tidyOneSurface,
        ActivityId.quietMusicBreak,
        ActivityId.energisingStretchFlow,
      ][i % 7],
      answer: i.isEven ? _somewhat : _not,
    ),
];

void main() {
  group('determinism', () {
    test('the same snapshot always gives the same decision', () {
      final a = _pick(_clearer, history: _busy);
      final b = _pick(_clearer, history: [..._busy.reversed]);
      expect(b.activityId, a.activityId);
      expect(b.offeredMinutes, a.offeredMinutes);
      expect(b.reason, a.reason);
      expect(b.trace, a.trace);
    });

    test('the tie-break is a stable FNV-1a hash, never a process hash', () {
      expect(
        stableTieBreak(DateTime(2026, 11, 20), _energy, ActivityId.easyWalk),
        stableTieBreak(
          DateTime(2026, 11, 20, 23, 59),
          _energy,
          ActivityId.easyWalk,
        ),
      );
      // Pinned: changing the algorithm changes every user's picks.
      expect(
        stableTieBreak(DateTime(2026, 11, 20), _energy, ActivityId.easyWalk),
        0x51cdba89,
      );
    });
  });

  group('hard limits', () {
    test('never NONE fit, never gated, never retired — any need, any '
        'window, any constraint', () {
      for (final need in Intention.values) {
        for (final window in TimeWindow.values) {
          for (final history in [const <PastCircle>[], _busy]) {
            final first = _pick(need, window: window, history: history);
            final offers = [
              first,
              for (final reason in ReplacementReason.values)
                ?recommend(
                  RecommendationContext(
                    date: _today,
                    need: need,
                    window: window,
                    allowSafetyPending: false,
                    replacement: ReplacementRequest(
                      reason: reason,
                      replacing: first.activityId,
                      replacingMinutes: first.offeredMinutes,
                    ),
                  ),
                  history,
                ),
            ];
            for (final o in offers) {
              final a = activityDefinition(o.activityId);
              final what = '${need.name} ${window.name}: ${o.activityId}';
              expect(a.fitFor(need), isNot(NeedFit.none), reason: what);
              expect(a.status, ActivityStatus.live, reason: what);
              expect(o.offeredMinutes, lessThanOrEqualTo(window.maxMinutes));
            }
          }
        }
      }
    });

    test('every need, window and constraint has a replacement — nothing '
        'ever leaves the user without one', () {
      for (final need in Intention.values) {
        for (final window in TimeWindow.values) {
          final first = _pick(need, window: window);
          for (final reason in ReplacementReason.values) {
            final replacement = recommend(
              RecommendationContext(
                date: _today,
                need: need,
                window: window,
                allowSafetyPending: false,
                replacement: ReplacementRequest(
                  reason: reason,
                  replacing: first.activityId,
                  replacingMinutes: first.offeredMinutes,
                ),
              ),
              const [],
            );
            expect(
              replacement,
              isNotNull,
              reason: '${need.name} ${window.name} ${reason.name}',
            );
          }
        }
      }
    });

    test('content awaiting the safety review is only ever offered to '
        'internal debug builds', () {
      final offered = <ActivityId>{};
      for (var day = 0; day < 60; day++) {
        for (final need in Intention.values) {
          offered.add(
            _pick(need, date: _today.add(Duration(days: day))).activityId,
          );
        }
      }
      expect(
        offered.where(
          (id) => activityDefinition(id).status != ActivityStatus.live,
        ),
        isEmpty,
      );
    });
  });

  group('time', () {
    test('Open activities run between their minimum and typical length; '
        'Guided ones only at their authored length', () {
      final walk = activityDefinition(ActivityId.thirtyMinuteWalk);
      expect(offeredMinutesFor(walk, TimeWindow.about10), isNull);
      expect(offeredMinutesFor(walk, TimeWindow.about20), 20);
      expect(offeredMinutesFor(walk, TimeWindow.upTo30), 25);

      final stretch = activityDefinition(ActivityId.energisingStretchFlow);
      // A natural 5-minute activity fits ≈10 at 5 — never padded.
      expect(offeredMinutesFor(stretch, TimeWindow.about10), 5);
      expect(offeredMinutesFor(stretch, TimeWindow.upTo30), 5);

      final gentle = activityDefinition(ActivityId.gentleStretchPause);
      expect(offeredMinutesFor(gentle, TimeWindow.about10), 10);
      // Guided steps are never cut short: an 8-minute window wouldn't fit.
      expect(gentle.mode, CircleMode.guidedSteps);
    });

    test('a short window only offers what genuinely fits it', () {
      for (final need in Intention.values) {
        final d = _pick(need, window: TimeWindow.about10, history: _busy);
        expect(
          activityDefinition(d.activityId).minMinutes,
          lessThanOrEqualTo(10),
        );
        expect(d.offeredMinutes, lessThanOrEqualTo(10));
      }
    });
  });

  group('evidence', () {
    test('Day 1: the curated start, with nothing personal to say', () {
      for (final (need, start) in [
        (_energy, ActivityId.thirtyMinuteWalk),
        (_clearer, ActivityId.writeItDown),
        (_gentler, ActivityId.easyWalk),
      ]) {
        final d = _pick(need);
        expect(d.activityId, start);
        expect(d.reason, RecommendationReason.starter);
        expect(d.reason.visibleCopy, isNull);
      }
    });

    test('"Very useful" brings an activity back, with its reason', () {
      final d = _pick(
        _clearer,
        history: [
          _past(6, _clearer, ActivityId.quietReading, answer: _very),
          _past(4, _clearer, ActivityId.tidyOneSurface),
          _past(2, _clearer, ActivityId.writeItDown),
        ],
      );
      expect(d.activityId, ActivityId.quietReading);
      expect(d.reason, RecommendationReason.usefulHere);
      expect(d.reason.visibleCopy, 'You found this useful before.');
    });

    test('"Somewhat useful" twice counts, but earns no visible claim', () {
      final d = _pick(
        _clearer,
        history: [
          _past(8, _clearer, ActivityId.quietReading, answer: _somewhat),
          _past(6, _clearer, ActivityId.quietReading, answer: _somewhat),
          _past(4, _clearer, ActivityId.tidyOneSurface),
          _past(2, _clearer, ActivityId.writeItDown),
        ],
      );
      expect(d.activityId, ActivityId.quietReading);
      expect(d.reason.visibleCopy, isNull);
    });

    test('no answer is UNKNOWN and carries no weight', () {
      final none = [
        _past(6, _clearer, ActivityId.quietReading),
        _past(4, _clearer, ActivityId.tidyOneSurface),
        _past(2, _clearer, ActivityId.writeItDown),
      ];
      final positive = [
        _past(6, _clearer, ActivityId.quietReading, answer: _very),
        ...none.skip(1),
      ];
      expect(_pick(_clearer, history: none).reason.visibleCopy, isNull);
      expect(
        _pick(_clearer, history: positive).reason,
        RecommendationReason.usefulHere,
      );
    });

    test('"Not useful" rests the activity for that need, then lets it '
        'back', () {
      final history = [
        _past(3, _energy, ActivityId.moveToMusic, answer: _not),
        _past(2, _energy, ActivityId.energisingStretchFlow),
        _past(1, _energy, ActivityId.activeHouseholdTask),
      ];
      final offered = <ActivityId>{};
      for (var day = 0; day < 10; day++) {
        offered.add(
          _pick(
            _energy,
            window: TimeWindow.about10,
            history: history,
            date: _today.add(Duration(days: day)),
          ).activityId,
        );
      }
      expect(offered, isNot(contains(ActivityId.moveToMusic)));

      // Well after the rest it may come back: not a permanent ban.
      final later = _pick(
        _energy,
        window: TimeWindow.about10,
        date: _today.add(const Duration(days: 40)),
        history: [
          _past(3, _energy, ActivityId.moveToMusic, answer: _not),
          _past(-37, _energy, ActivityId.energisingStretchFlow),
          _past(-38, _energy, ActivityId.activeHouseholdTask),
        ],
      );
      expect(later.activityId, ActivityId.moveToMusic);
    });

    test('compatible V1 answers count; RESET and retired ones never do', () {
      // Write it down is LEARNING_COMPATIBLE.
      final compatible = _pick(
        _clearer,
        history: [
          _past(
            10,
            _clearer,
            ActivityId.writeItDown,
            answer: _very,
            version: 1,
          ),
          _past(4, _clearer, ActivityId.tidyOneSurface),
          _past(2, _clearer, ActivityId.quietReading),
        ],
      );
      expect(compatible.activityId, ActivityId.writeItDown);
      expect(compatible.reason, RecommendationReason.usefulHere);

      // A brisk walk and A quick standing stretch are LEARNING_RESET.
      for (final reset in [
        ActivityId.thirtyMinuteWalk,
        ActivityId.energisingStretchFlow,
      ]) {
        final memory = RecommendationMemory.of(_today, [
          _past(10, _energy, reset, answer: _very, version: 1),
          _past(8, _energy, reset, answer: _very, version: 1),
        ], RecommendationPolicy.initial);
        expect(memory.strengthFor(reset, _energy), 0, reason: reset.name);
      }
      // The retired breath reset never contributes, from any version.
      final retired = RecommendationMemory.of(_today, [
        _past(5, _energy, ActivityId.energisingBreathReset, answer: _very),
      ], RecommendationPolicy.initial);
      expect(retired.strengthFor(ActivityId.energisingBreathReset, _energy), 0);
    });

    test('answers are contextual to the need they were given for', () {
      final memory = RecommendationMemory.of(_today, [
        _past(5, _energy, ActivityId.easyWalk, answer: _not),
      ], RecommendationPolicy.initial);
      expect(memory.strengthFor(ActivityId.easyWalk, _energy), -2);
      expect(memory.strengthFor(ActivityId.easyWalk, _gentler), 0);
      // Easy walk is still Gentler Pace's curated start the next day.
      final d = _pick(
        _gentler,
        history: [_past(5, _energy, ActivityId.easyWalk, answer: _not)],
      );
      expect(d.activityId, isNot(ActivityId.easyWalk));
    });

    test('a secondary fit the user found very useful elsewhere is promoted '
        'when the primaries are tired, and says why', () {
      final d = _pick(
        _energy,
        window: TimeWindow.about10,
        history: [
          _past(9, _gentler, ActivityId.gentleStretchPause, answer: _very),
          _past(3, _energy, ActivityId.activeHouseholdTask, answer: _not),
          _past(2, _energy, ActivityId.energisingStretchFlow),
          _past(1, _energy, ActivityId.moveToMusic),
        ],
      );
      expect(d.activityId, ActivityId.gentleStretchPause);
      expect(d.reason, RecommendationReason.usefulElsewhere);
    });
  });

  group('"Not useful" outranks variety', () {
    // At ≈ 10, More Energy has exactly five fits.
    const tenMinuteFits = [
      ActivityId.moveToMusic,
      ActivityId.energisingStretchFlow,
      ActivityId.activeHouseholdTask,
      ActivityId.tidyOneSurface,
      ActivityId.gentleStretchPause,
    ];

    test('yesterday\'s activity repeats before a resting one is offered', () {
      final d = _pick(
        _energy,
        window: TimeWindow.about10,
        history: [
          _past(6, _energy, ActivityId.energisingStretchFlow, answer: _not),
          _past(5, _energy, ActivityId.activeHouseholdTask, answer: _not),
          _past(4, _energy, ActivityId.tidyOneSurface, answer: _not),
          _past(3, _energy, ActivityId.moveToMusic, answer: _very),
          _past(2, _energy, ActivityId.gentleStretchPause, answer: _not),
          _past(1, _energy, ActivityId.moveToMusic, answer: _somewhat),
        ],
      );
      expect(d.activityId, ActivityId.moveToMusic);
      // Repeating is a fallback, and it claims nothing.
      expect(d.reason, RecommendationReason.fallback);
      expect(d.reason.visibleCopy, isNull);
    });

    test('a capped favourite repeats before a resting one is offered', () {
      final d = _pick(
        _energy,
        window: TimeWindow.about10,
        history: [
          _past(6, _energy, ActivityId.moveToMusic, answer: _very),
          _past(5, _energy, ActivityId.energisingStretchFlow, answer: _not),
          _past(4, _energy, ActivityId.moveToMusic, answer: _very),
          _past(3, _energy, ActivityId.activeHouseholdTask, answer: _not),
          _past(2, _energy, ActivityId.tidyOneSurface, answer: _not),
          _past(1, _energy, ActivityId.gentleStretchPause, answer: _not),
        ],
      );
      expect(d.activityId, ActivityId.moveToMusic);
      expect(d.reason, RecommendationReason.fallback);
    });

    test('only when every fit is resting: the rest that ends soonest gives '
        'way, without a personal reason, and is not shortened', () {
      final history = [
        for (var i = 0; i < tenMinuteFits.length; i++)
          _past(5 - i, _energy, tenMinuteFits[i], answer: _not),
      ];
      final d = _pick(_energy, window: TimeWindow.about10, history: history);
      expect(d.activityId, ActivityId.moveToMusic); // rested 5 days ago
      expect(d.reason, RecommendationReason.fallback);
      expect(d.reason.visibleCopy, isNull);
      // Deterministic, whatever order the journal is read in.
      expect(
        _pick(
          _energy,
          window: TimeWindow.about10,
          history: [...history.reversed],
        ).trace,
        d.trace,
      );

      // Being offered — even attempted — does not end its rest.
      final tomorrow = _today.add(const Duration(days: 1));
      final after = [...history, _past(0, _energy, d.activityId)];
      final memory = RecommendationMemory.of(
        tomorrow,
        after,
        RecommendationPolicy.initial,
      );
      expect(memory.daysSinceNotUseful(d.activityId, _energy), 6);
    });

    test('among equally old rests, the weaker evidence gives way first', () {
      final d = _pick(
        _energy,
        window: TimeWindow.about10,
        history: [
          _past(30, _energy, ActivityId.moveToMusic, answer: _not),
          for (final id in tenMinuteFits) _past(5, _energy, id, answer: _not),
        ],
      );
      // Move to music has two "Not useful" answers; the others one each.
      expect(d.activityId, isNot(ActivityId.moveToMusic));
      expect(d.reason, RecommendationReason.fallback);
    });
  });

  group('recency and variety', () {
    test('never yesterday\'s activity while anything else fits', () {
      for (final need in Intention.values) {
        for (final window in TimeWindow.values) {
          final first = _pick(need, window: window, history: _busy);
          final next = _pick(
            need,
            window: window,
            date: _today.add(const Duration(days: 1)),
            history: [
              ..._busy,
              _past(0, need, first.activityId, answer: _very),
            ],
          );
          expect(next.activityId, isNot(first.activityId));
        }
      }
    });

    test('at most twice in any week, even when it is the favourite', () {
      final history = <PastCircle>[];
      for (var day = 0; day < 21; day++) {
        final d = _pick(
          _energy,
          date: _today.add(Duration(days: day)),
          history: history,
        );
        history.add(
          PastCircle(
            date: _today.add(Duration(days: day)),
            need: _energy,
            activityId: d.activityId,
            catalogVersion: catalogVersion,
            usefulness: d.activityId == ActivityId.thirtyMinuteWalk
                ? _very
                : null,
          ),
        );
      }
      for (var i = 0; i + 7 <= history.length; i++) {
        expect(
          history
              .skip(i)
              .take(7)
              .where((c) => c.activityId == ActivityId.thirtyMinuteWalk)
              .length,
          lessThanOrEqualTo(2),
        );
      }
    });

    test('an activity declined yesterday is not offered straight back', () {
      final d = _pick(
        _gentler,
        history: [
          _past(
            1,
            _gentler,
            ActivityId.quietMusicBreak,
            replacedFrom: ActivityId.easyWalk,
          ),
        ],
      );
      expect(d.activityId, isNot(ActivityId.easyWalk));
    });
  });

  group('exploration', () {
    List<PastCircle> settled() => [
      for (var i = 0; i < 8; i++)
        _past(
          16 - i * 2,
          _clearer,
          i.isEven ? ActivityId.writeItDown : ActivityId.quietReading,
          answer: _very,
        ),
    ];

    test('once a need has answers, something untried is offered now and '
        'then — honestly labelled', () {
      final d = _pick(_clearer, history: settled());
      expect(d.reason, RecommendationReason.tryingNew);
      expect(d.reason.visibleCopy, 'Something new to try for this.');
      final memory = RecommendationMemory.of(
        _today,
        settled(),
        RecommendationPolicy.initial,
      );
      expect(memory.triedFor(d.activityId, _clearer), isFalse);
    });

    test('never on a short day, never as a replacement, never without '
        'answers', () {
      expect(
        _pick(_clearer, window: TimeWindow.about10, history: settled()).reason,
        isNot(RecommendationReason.tryingNew),
      );
      final unanswered = [
        for (final c in settled())
          PastCircle(
            date: c.date,
            need: c.need,
            activityId: c.activityId,
            catalogVersion: c.catalogVersion,
          ),
      ];
      expect(
        _pick(_clearer, history: unanswered).reason,
        isNot(RecommendationReason.tryingNew),
      );
    });
  });

  group('Not this one today', () {
    RecommendationDecision replace(
      Intention need,
      ActivityId current,
      ReplacementReason reason, {
      TimeWindow window = TimeWindow.about20,
      int minutes = 20,
    }) => recommend(
      RecommendationContext(
        date: _today,
        need: need,
        window: window,
        allowSafetyPending: false,
        replacement: ReplacementRequest(
          reason: reason,
          replacing: current,
          replacingMinutes: minutes,
        ),
      ),
      const [],
    )!;

    test('"Can\'t go outside": an indoor one, and it says so', () {
      final d = replace(
        _energy,
        ActivityId.thirtyMinuteWalk,
        ReplacementReason.cantGoOutside,
      );
      expect(
        activityDefinition(d.activityId).setting,
        isNot(ActivitySetting.outdoor),
      );
      expect(d.reason.visibleCopy, 'An indoor one instead.');
    });

    test('"Too much for today": genuinely low effort and lighter', () {
      final d = replace(
        _energy,
        ActivityId.thirtyMinuteWalk,
        ReplacementReason.tooMuch,
      );
      final a = activityDefinition(d.activityId);
      expect(a.effort, ActivityEffort.low);
      expect(d.offeredMinutes, lessThan(20));
      expect(d.reason.visibleCopy, 'Something lighter instead.');
    });

    test('"Not feeling this one": something from a different family', () {
      final d = replace(
        _gentler,
        ActivityId.easyWalk,
        ReplacementReason.notFeeling,
      );
      expect(
        activityFamily(d.activityId),
        isNot(activityFamily(ActivityId.easyWalk)),
      );
      expect(d.reason.visibleCopy, 'Something different instead.');
    });
  });
}
