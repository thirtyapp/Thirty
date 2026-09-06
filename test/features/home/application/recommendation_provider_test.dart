import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/analytics/analytics_event_type.dart';
import 'package:thirty/core/analytics/analytics_service.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';

/// Records every [track] call instead of reaching Supabase — lets Phase E
/// instrumentation tests assert exactly which events fired, in which
/// order, without any network dependency.
class _RecordingAnalyticsService implements AnalyticsService {
  final List<AnalyticsEventType> events = [];

  /// Every [track] call's [type] and [metadata] together — [events] alone
  /// (kept for the existing Batch 1 assertions below) can't tell two same-
  /// type calls' metadata apart.
  final List<(AnalyticsEventType type, Map<String, Object?>? metadata)> calls =
      [];

  @override
  void track(AnalyticsEventType type, {Map<String, Object?>? metadata}) {
    events.add(type);
    calls.add((type, metadata));
  }
}

final _today = DateTime(2026, 8, 2, 9);
final _laterToday = DateTime(2026, 8, 2, 10);
final _evenLaterToday = DateTime(2026, 8, 2, 11);
final _yesterday = DateTime(2026, 8, 1, 9);

/// A [DateTime Function()] a test can move forward on demand, standing in
/// for [eventClockProvider] — a fresh instance per test (never a shared or
/// global mutable clock), which is what makes it safe to mutate freely
/// within one test without leaking state into any other.
class _TestClock {
  _TestClock(this._now);
  DateTime _now;
  DateTime call() => _now;
  void advanceTo(DateTime now) => _now = now;
}

Future<(ProviderContainer, _TestClock)> _containerWith(
  Map<String, Object> storedPrefs, {
  DateTime? now,
  AnalyticsService? analytics,
}) async {
  SharedPreferences.setMockInitialValues(storedPrefs);
  final prefs = await SharedPreferences.getInstance();
  final clock = _TestClock(now ?? _today);

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(now ?? _today),
      eventClockProvider.overrideWithValue(clock.call),
      if (analytics != null)
        analyticsServiceProvider.overrideWithValue(analytics),
    ],
  );
  return (container, clock);
}

/// A stored-prefs map for a today (2026-08-02) that already has an
/// intention/activity chosen — the shape most lifecycle tests below need,
/// since [RecommendationNotifier.start]/`.close()` are no-ops until today's
/// recommendation exists.
Map<String, Object> _chosenToday({
  Intention intention = Intention.moreEnergy,
  ActivityId activityId = ActivityId.thirtyMinuteWalk,
}) => {
  recommendationDayKey: '2026-08-02',
  recommendationIntentionKey: intention.name,
  recommendationActivityIdKey: activityId.name,
};

void main() {
  group('recommendationProvider', () {
    test(
      'a new day with no stored state has no recommendation and is notStarted',
      () async {
        final (container, _) = await _containerWith({});
        addTearDown(container.dispose);

        final state = container.read(recommendationProvider);

        expect(state.recommendation, isNull);
        expect(state.status, RecommendationStatus.notStarted);
        expect(state.startedAt, isNull);
        expect(state.closedAt, isNull);
      },
    );

    group('chooseIntention()', () {
      test('resolves a recommendation and sets status to notStarted', () async {
        final (container, _) = await _containerWith({}, now: _today);
        addTearDown(container.dispose);

        container
            .read(recommendationProvider.notifier)
            .chooseIntention(Intention.clearerHead);
        final state = container.read(recommendationProvider);

        expect(state.recommendation, isNotNull);
        expect(state.recommendation!.intent, 'Clearer Head');
        expect(state.status, RecommendationStatus.notStarted);
        expect(state.startedAt, isNull);
        expect(state.closedAt, isNull);
      });

      test('is a no-op once today\'s recommendation already exists', () async {
        final (container, _) = await _containerWith(
          _chosenToday(
            intention: Intention.gentlerPace,
            activityId: ActivityId.easyWalk,
          ),
          now: _today,
        );
        addTearDown(container.dispose);

        final before = container.read(recommendationProvider).recommendation;
        container
            .read(recommendationProvider.notifier)
            .chooseIntention(Intention.moreEnergy);
        final after = container.read(recommendationProvider).recommendation;

        expect(after!.intent, before!.intent);
        expect(after.activityId, before.activityId);
      });

      test(
        'persists intention and activityId so a restart restores them',
        () async {
          final (container, _) = await _containerWith({}, now: _today);
          addTearDown(container.dispose);

          container
              .read(recommendationProvider.notifier)
              .chooseIntention(Intention.moreEnergy);
          // The persist write is fire-and-forget; pump the microtask queue.
          await Future<void>.delayed(Duration.zero);
          final prefs = container.read(sharedPreferencesProvider);

          expect(prefs.getString(recommendationDayKey), '2026-08-02');
          expect(prefs.getString(recommendationIntentionKey), 'moreEnergy');
          expect(prefs.getString(recommendationActivityIdKey), isNotNull);
          expect(prefs.getString(recommendationStatusKey), 'notStarted');
        },
      );

      test('avoids repeating the previously shown activity in this '
          'intention\'s pool when chosen again the very next day', () async {
        final (container, _) = await _containerWith({}, now: _yesterday);
        addTearDown(container.dispose);

        container
            .read(recommendationProvider.notifier)
            .chooseIntention(Intention.moreEnergy);
        final yesterdayActivity = container
            .read(recommendationProvider)
            .recommendation!
            .activityId;
        await Future<void>.delayed(Duration.zero);

        final prefs = container.read(sharedPreferencesProvider);
        final (container2, _) = await _containerWith({
          for (final key in prefs.getKeys()) key: prefs.get(key)!,
        }, now: _today);
        addTearDown(container2.dispose);

        container2
            .read(recommendationProvider.notifier)
            .chooseIntention(Intention.moreEnergy);
        final todayActivity = container2
            .read(recommendationProvider)
            .recommendation!
            .activityId;

        expect(todayActivity, isNot(yesterdayActivity));
      });

      test('still avoids repeating the previously shown activity after a '
          'gap of two or more days — Batch 2 (ADR-012) fixes v0\'s '
          'calendar-adjacency-only limitation', () async {
        // The app was last opened on 2026-07-31 (two days before
        // _today, 2026-08-02) — not "yesterday." v0's original rule
        // would have treated this as no history at all; Batch 2's
        // per-intention history must still exclude it.
        final (container, _) = await _containerWith(
          {},
          now: DateTime(2026, 7, 31, 9),
        );
        addTearDown(container.dispose);

        container
            .read(recommendationProvider.notifier)
            .chooseIntention(Intention.moreEnergy);
        final staleActivity = container
            .read(recommendationProvider)
            .recommendation!
            .activityId;
        await Future<void>.delayed(Duration.zero);

        final prefs = container.read(sharedPreferencesProvider);
        final (container2, _) = await _containerWith({
          for (final key in prefs.getKeys()) key: prefs.get(key)!,
        }, now: _today);
        addTearDown(container2.dispose);

        container2
            .read(recommendationProvider.notifier)
            .chooseIntention(Intention.moreEnergy);
        final todayActivity = container2
            .read(recommendationProvider)
            .recommendation!
            .activityId;

        expect(todayActivity, isNot(staleActivity));
      });

      test('across many consecutive days, the same activity never repeats '
          'until every other pool member has been shown, and the persisted '
          'history never exceeds pool.length - 1 entries', () async {
        final pool = activityPools[Intention.clearerHead]!;
        final historyKey = recommendationHistoryKeyFor(Intention.clearerHead);
        final historyCap = pool.length - 1;

        Map<String, Object> storedPrefs = {};
        final chosen = <ActivityId>[];

        for (var i = 0; i < 8; i++) {
          final day = DateTime(2026, 8, 1 + i, 9);
          final (container, _) = await _containerWith(storedPrefs, now: day);
          container
              .read(recommendationProvider.notifier)
              .chooseIntention(Intention.clearerHead);
          chosen.add(
            container.read(recommendationProvider).recommendation!.activityId,
          );
          await Future<void>.delayed(Duration.zero);

          final prefs = container.read(sharedPreferencesProvider);
          storedPrefs = {
            for (final key in prefs.getKeys()) key: prefs.get(key)!,
          };
          container.dispose();

          final history = prefs.getStringList(historyKey);
          expect(history, isNotNull);
          expect(history!.length, lessThanOrEqualTo(historyCap));
        }

        // No activity repeats within any window of historyCap consecutive
        // picks — e.g. for a 3-item pool, no two picks within the last 2
        // are the same.
        for (var i = historyCap; i < chosen.length; i++) {
          final window = chosen.sublist(i - historyCap, i);
          expect(window, isNot(contains(chosen[i])));
        }
      });

      test('an empty/absent history (fresh install, or after clear-storage) '
          'behaves exactly like first-ever use — the plain rotation '
          'candidate, no crash', () async {
        final (container, _) = await _containerWith({}, now: _today);
        addTearDown(container.dispose);

        container
            .read(recommendationProvider.notifier)
            .chooseIntention(Intention.gentlerPace);
        final state = container.read(recommendationProvider);

        expect(
          state.recommendation!.activityId,
          selectActivityId(
            intention: Intention.gentlerPace,
            dayIndex: epochDay(_today),
          ),
        );
      });
    });

    group('the (recommendation == null) state invariant', () {
      test('a fresh, never-chosen day always has notStarted status and null '
          'timestamps', () async {
        final (container, _) = await _containerWith({}, now: _today);
        addTearDown(container.dispose);

        final state = container.read(recommendationProvider);
        expect(state.recommendation, isNull);
        expect(state.status, RecommendationStatus.notStarted);
        expect(state.startedAt, isNull);
        expect(state.closedAt, isNull);
      });

      test(
        'start() is a no-op before today\'s recommendation exists',
        () async {
          final (container, _) = await _containerWith({}, now: _today);
          addTearDown(container.dispose);

          container.read(recommendationProvider.notifier).start();
          final state = container.read(recommendationProvider);

          expect(state.recommendation, isNull);
          expect(state.status, RecommendationStatus.notStarted);
          expect(state.startedAt, isNull);
        },
      );

      test(
        'close() is a no-op before today\'s recommendation exists',
        () async {
          final (container, _) = await _containerWith({}, now: _today);
          addTearDown(container.dispose);

          container.read(recommendationProvider.notifier).close();
          final state = container.read(recommendationProvider);

          expect(state.recommendation, isNull);
          expect(state.status, RecommendationStatus.notStarted);
          expect(state.closedAt, isNull);
        },
      );
    });

    test('start() moves notStarted to started and records startedAt', () async {
      final (container, _) = await _containerWith(_chosenToday(), now: _today);
      addTearDown(container.dispose);

      container.read(recommendationProvider.notifier).start();
      final state = container.read(recommendationProvider);

      expect(state.status, RecommendationStatus.started);
      expect(state.startedAt, _today);
      expect(state.closedAt, isNull);
    });

    test('start() uses the real moment of the call, not a stale build-time '
        'snapshot', () async {
      final (container, clock) = await _containerWith(
        _chosenToday(),
        now: _today,
      );
      addTearDown(container.dispose);

      // Force build() to run — and read the clock providers once — before
      // time moves on, so this proves start() doesn't reuse whatever was
      // current back then.
      container.read(recommendationProvider);
      clock.advanceTo(_laterToday);

      container.read(recommendationProvider.notifier).start();

      final state = container.read(recommendationProvider);
      expect(state.startedAt, _laterToday);
      expect(state.startedAt, isNot(_today));
    });

    test(
      'a second start() is a no-op and does not overwrite startedAt',
      () async {
        final (container, clock) = await _containerWith(
          _chosenToday(),
          now: _today,
        );
        addTearDown(container.dispose);

        container.read(recommendationProvider.notifier).start();
        expect(container.read(recommendationProvider).startedAt, _today);

        clock.advanceTo(_laterToday);
        container.read(recommendationProvider.notifier).start();

        final state = container.read(recommendationProvider);
        expect(state.status, RecommendationStatus.started);
        expect(state.startedAt, _today);
      },
    );

    test('close() moves started to closed, keeps startedAt, records the real '
        'moment of the close() call as closedAt', () async {
      final (container, clock) = await _containerWith(
        _chosenToday(),
        now: _today,
      );
      addTearDown(container.dispose);

      container.read(recommendationProvider.notifier).start();
      clock.advanceTo(_laterToday);
      container.read(recommendationProvider.notifier).close();

      final state = container.read(recommendationProvider);
      expect(state.status, RecommendationStatus.closed);
      expect(state.startedAt, _today);
      expect(state.closedAt, _laterToday);
    });

    test('close() from notStarted is a no-op', () async {
      final (container, _) = await _containerWith(_chosenToday(), now: _today);
      addTearDown(container.dispose);

      container.read(recommendationProvider.notifier).close();

      final state = container.read(recommendationProvider);
      expect(state.status, RecommendationStatus.notStarted);
      expect(state.startedAt, isNull);
      expect(state.closedAt, isNull);
    });

    test(
      'a second close() is a no-op and does not overwrite closedAt',
      () async {
        final (container, clock) = await _containerWith(
          _chosenToday(),
          now: _today,
        );
        addTearDown(container.dispose);

        container.read(recommendationProvider.notifier).start();
        clock.advanceTo(_laterToday);
        container.read(recommendationProvider.notifier).close();
        expect(container.read(recommendationProvider).closedAt, _laterToday);

        clock.advanceTo(_evenLaterToday);
        container.read(recommendationProvider.notifier).close();

        final state = container.read(recommendationProvider);
        expect(state.status, RecommendationStatus.closed);
        expect(state.closedAt, _laterToday);
      },
    );

    test('restores a started state persisted earlier today', () async {
      final (container, _) = await _containerWith({
        ..._chosenToday(),
        recommendationStatusKey: 'started',
        recommendationStartedAtKey: _today.toIso8601String(),
      }, now: _laterToday);
      addTearDown(container.dispose);

      final state = container.read(recommendationProvider);
      expect(state.recommendation, isNotNull);
      expect(state.status, RecommendationStatus.started);
      expect(state.startedAt, _today);
      expect(state.closedAt, isNull);
    });

    test('restoring a started state ignores a stale closedAt key from an '
        'earlier session', () async {
      final (container, _) = await _containerWith({
        ..._chosenToday(),
        recommendationStatusKey: 'started',
        recommendationStartedAtKey: _today.toIso8601String(),
        // Stale leftover — must never surface as this started state's
        // closedAt.
        recommendationClosedAtKey: _yesterday.toIso8601String(),
      }, now: _laterToday);
      addTearDown(container.dispose);

      final state = container.read(recommendationProvider);
      expect(state.status, RecommendationStatus.started);
      expect(state.closedAt, isNull);
    });

    test('restores a closed state persisted earlier today', () async {
      final (container, _) = await _containerWith({
        ..._chosenToday(),
        recommendationStatusKey: 'closed',
        recommendationStartedAtKey: _today.toIso8601String(),
        recommendationClosedAtKey: _laterToday.toIso8601String(),
      }, now: _evenLaterToday);
      addTearDown(container.dispose);

      final state = container.read(recommendationProvider);
      expect(state.recommendation, isNotNull);
      expect(state.status, RecommendationStatus.closed);
      expect(state.startedAt, _today);
      expect(state.closedAt, _laterToday);
    });

    test(
      'a closed record missing its closedAt fails safe to notStarted',
      () async {
        final (container, _) = await _containerWith({
          ..._chosenToday(),
          recommendationStatusKey: 'closed',
          recommendationStartedAtKey: _today.toIso8601String(),
          // No recommendationClosedAtKey at all.
        }, now: _laterToday);
        addTearDown(container.dispose);

        final state = container.read(recommendationProvider);
        expect(state.recommendation, isNotNull);
        expect(state.status, RecommendationStatus.notStarted);
        expect(state.startedAt, isNull);
        expect(state.closedAt, isNull);
      },
    );

    test('a closed record with closedAt before startedAt fails safe to '
        'notStarted', () async {
      final (container, _) = await _containerWith({
        ..._chosenToday(),
        recommendationStatusKey: 'closed',
        recommendationStartedAtKey: _laterToday.toIso8601String(),
        // Impossible ordering: closed before it started.
        recommendationClosedAtKey: _today.toIso8601String(),
      }, now: _evenLaterToday);
      addTearDown(container.dispose);

      final state = container.read(recommendationProvider);
      expect(state.recommendation, isNotNull);
      expect(state.status, RecommendationStatus.notStarted);
      expect(state.startedAt, isNull);
      expect(state.closedAt, isNull);
    });

    test('a state persisted on an earlier calendar day resets to no '
        'recommendation, notStarted', () async {
      final (container, _) = await _containerWith({
        ..._chosenToday(),
        recommendationDayKey: '2026-08-01',
        recommendationStatusKey: 'started',
        recommendationStartedAtKey: _yesterday.toIso8601String(),
      }, now: _today);
      addTearDown(container.dispose);

      final state = container.read(recommendationProvider);
      expect(state.recommendation, isNull);
      expect(state.status, RecommendationStatus.notStarted);
      expect(state.startedAt, isNull);
      expect(state.closedAt, isNull);
    });

    test(
      'a corrupt/incomplete persisted record fails safe to notStarted',
      () async {
        // Same day, status says "started", but startedAt is unparseable.
        final (container, _) = await _containerWith({
          ..._chosenToday(),
          recommendationStatusKey: 'started',
          recommendationStartedAtKey: 'not-a-date',
        }, now: _today);
        addTearDown(container.dispose);

        final state = container.read(recommendationProvider);
        expect(state.recommendation, isNotNull);
        expect(state.status, RecommendationStatus.notStarted);
        expect(state.startedAt, isNull);
        expect(state.closedAt, isNull);
      },
    );

    test('a same-day record with an unrecognized intention/activityId falls '
        'back to no recommendation, notStarted', () async {
      final (container, _) = await _containerWith({
        recommendationDayKey: '2026-08-02',
        recommendationIntentionKey: 'not-a-real-intention',
        recommendationActivityIdKey: 'not-a-real-activity',
      }, now: _today);
      addTearDown(container.dispose);

      final state = container.read(recommendationProvider);
      expect(state.recommendation, isNull);
      expect(state.status, RecommendationStatus.notStarted);
      expect(state.startedAt, isNull);
      expect(state.closedAt, isNull);
    });

    group('Batch 1 instrumentation (Phase E)', () {
      test('start() records exactly one circleStarted event', () async {
        final analytics = _RecordingAnalyticsService();
        final (container, _) = await _containerWith(
          _chosenToday(),
          now: _today,
          analytics: analytics,
        );
        addTearDown(container.dispose);

        container.read(recommendationProvider.notifier).start();

        expect(analytics.events, [AnalyticsEventType.circleStarted]);
      });

      test('close() records exactly one circleClosed event', () async {
        final analytics = _RecordingAnalyticsService();
        final (container, _) = await _containerWith(
          _chosenToday(),
          now: _today,
          analytics: analytics,
        );
        addTearDown(container.dispose);

        container.read(recommendationProvider.notifier).start();
        container.read(recommendationProvider.notifier).close();

        expect(analytics.events, [
          AnalyticsEventType.circleStarted,
          AnalyticsEventType.circleClosed,
        ]);
      });

      test(
        'a no-op start() (already started) records no additional event',
        () async {
          final analytics = _RecordingAnalyticsService();
          final (container, _) = await _containerWith(
            _chosenToday(),
            now: _today,
            analytics: analytics,
          );
          addTearDown(container.dispose);

          container.read(recommendationProvider.notifier).start();
          container.read(recommendationProvider.notifier).start();

          expect(analytics.events, [AnalyticsEventType.circleStarted]);
        },
      );

      test('a no-op close() (already closed, or before start()) records no '
          'additional event', () async {
        final analytics = _RecordingAnalyticsService();
        final (container, _) = await _containerWith(
          _chosenToday(),
          now: _today,
          analytics: analytics,
        );
        addTearDown(container.dispose);

        // Before start(): no-op.
        container.read(recommendationProvider.notifier).close();
        expect(analytics.events, isEmpty);

        container.read(recommendationProvider.notifier).start();
        container.read(recommendationProvider.notifier).close();
        container.read(recommendationProvider.notifier).close();

        expect(analytics.events, [
          AnalyticsEventType.circleStarted,
          AnalyticsEventType.circleClosed,
        ]);
      });
    });

    group('Batch 2 instrumentation (Phase F) — recommendationShown', () {
      test(
        'chooseIntention() records exactly one recommendationShown event, '
        'carrying the stable intention and activity_id, never display copy',
        () async {
          final analytics = _RecordingAnalyticsService();
          final (container, _) = await _containerWith(
            {},
            now: _today,
            analytics: analytics,
          );
          addTearDown(container.dispose);

          container
              .read(recommendationProvider.notifier)
              .chooseIntention(Intention.moreEnergy);
          final activityId = container
              .read(recommendationProvider)
              .recommendation!
              .activityId;

          expect(analytics.events, [AnalyticsEventType.recommendationShown]);
          final (type, metadata) = analytics.calls.single;
          expect(type, AnalyticsEventType.recommendationShown);
          expect(metadata, {
            'intention': Intention.moreEnergy.name,
            'activity_id': activityId.name,
          });
        },
      );

      test('a no-op chooseIntention() (recommendation already exists today) '
          'records no additional event', () async {
        final analytics = _RecordingAnalyticsService();
        final (container, _) = await _containerWith(
          _chosenToday(),
          now: _today,
          analytics: analytics,
        );
        addTearDown(container.dispose);

        container
            .read(recommendationProvider.notifier)
            .chooseIntention(Intention.clearerHead);

        expect(analytics.events, isEmpty);
      });

      test('start() and close() still record only their own Batch 1 events — '
          'unaffected by the new recommendationShown event', () async {
        final analytics = _RecordingAnalyticsService();
        final (container, _) = await _containerWith(
          {},
          now: _today,
          analytics: analytics,
        );
        addTearDown(container.dispose);

        container
            .read(recommendationProvider.notifier)
            .chooseIntention(Intention.moreEnergy);
        container.read(recommendationProvider.notifier).start();
        container.read(recommendationProvider.notifier).close();

        expect(analytics.events, [
          AnalyticsEventType.recommendationShown,
          AnalyticsEventType.circleStarted,
          AnalyticsEventType.circleClosed,
        ]);
      });
    });

    group('Recommendation content (ADR-013 §3)', () {
      test(
        'carries circleId (== today), the raw intention, and catalogVersion',
        () async {
          final (container, _) = await _containerWith({}, now: _today);
          addTearDown(container.dispose);

          container
              .read(recommendationProvider.notifier)
              .chooseIntention(Intention.gentlerPace);
          final recommendation = container
              .read(recommendationProvider)
              .recommendation!;

          expect(recommendation.circleId, '2026-08-02');
          expect(recommendation.intention, Intention.gentlerPace);
          expect(recommendation.catalogVersion, catalogVersion);
        },
      );

      test('a restored recommendation carries the same circleId/intention/'
          'catalogVersion as a freshly chosen one', () async {
        final (container, _) = await _containerWith(
          _chosenToday(
            intention: Intention.clearerHead,
            activityId: ActivityId.quietReading,
          ),
          now: _today,
        );
        addTearDown(container.dispose);

        final recommendation = container
            .read(recommendationProvider)
            .recommendation!;

        expect(recommendation.circleId, '2026-08-02');
        expect(recommendation.intention, Intention.clearerHead);
        expect(recommendation.catalogVersion, catalogVersion);
      });
    });

    group(
      'invalid stored activity/intention combination (ADR-013 §2) recovers '
      'safely',
      () {
        test(
          'an activityId that does not belong to the stored intention\'s '
          'pool is treated as no recommendation, not silently trusted',
          () async {
            final (container, _) = await _containerWith({
              recommendationDayKey: '2026-08-02',
              recommendationIntentionKey: Intention.moreEnergy.name,
              // quietReading only belongs to clearerHead's pool.
              recommendationActivityIdKey: ActivityId.quietReading.name,
            }, now: _today);
            addTearDown(container.dispose);

            final state = container.read(recommendationProvider);

            expect(state.recommendation, isNull);
            expect(state.status, RecommendationStatus.notStarted);
          },
        );

        test(
          'the same incompatible pair does not crash chooseIntention() — a '
          'fresh, compatible choice can still be made afterward',
          () async {
            final (container, _) = await _containerWith({
              recommendationDayKey: '2026-08-02',
              recommendationIntentionKey: Intention.moreEnergy.name,
              recommendationActivityIdKey: ActivityId.quietReading.name,
            }, now: _today);
            addTearDown(container.dispose);

            container
                .read(recommendationProvider.notifier)
                .chooseIntention(Intention.gentlerPace);
            final state = container.read(recommendationProvider);

            expect(state.recommendation, isNotNull);
            expect(state.recommendation!.intent, 'Gentler Pace');
            expect(
              activityPools[Intention.gentlerPace],
              contains(state.recommendation!.activityId),
            );
          },
        );
      },
    );

    group('optional action-report foundation (ADR-013 §4)', () {
      test('reportAttempt() is a no-op before today\'s Circle is closed', () async {
        final (container, _) = await _containerWith(_chosenToday(), now: _today);
        addTearDown(container.dispose);

        // notStarted:
        container
            .read(recommendationProvider.notifier)
            .reportAttempt(CircleAttemptResponse.yes);
        expect(
          container.read(recommendationProvider).attemptResponse,
          isNull,
        );

        // started:
        container.read(recommendationProvider.notifier).start();
        container
            .read(recommendationProvider.notifier)
            .reportAttempt(CircleAttemptResponse.yes);
        expect(
          container.read(recommendationProvider).attemptResponse,
          isNull,
        );
      });

      for (final response in CircleAttemptResponse.values) {
        test('reportAttempt(${response.name}) is recorded once closed, and '
            'never required to close or to receive a recommendation', () async {
          final (container, _) = await _containerWith(
            _chosenToday(),
            now: _today,
          );
          addTearDown(container.dispose);

          container.read(recommendationProvider.notifier).start();
          container.read(recommendationProvider.notifier).close();
          container
              .read(recommendationProvider.notifier)
              .reportAttempt(response);

          final state = container.read(recommendationProvider);
          expect(state.attemptResponse, response);
          // Close already happened without any answer, and this answer
          // changes nothing about the Circle's own lifecycle status.
          expect(state.status, RecommendationStatus.closed);
        });
      }

      test('no answer at all leaves attemptResponse null — UNKNOWN, never a '
          'failure', () async {
        final (container, _) = await _containerWith(_chosenToday(), now: _today);
        addTearDown(container.dispose);

        container.read(recommendationProvider.notifier).start();
        container.read(recommendationProvider.notifier).close();

        expect(
          container.read(recommendationProvider).attemptResponse,
          isNull,
        );
      });

      test('reportAttempt() overwrites an earlier answer for the same day '
          '— changing your mind is allowed', () async {
        final (container, _) = await _containerWith(_chosenToday(), now: _today);
        addTearDown(container.dispose);

        container.read(recommendationProvider.notifier).start();
        container.read(recommendationProvider.notifier).close();
        container
            .read(recommendationProvider.notifier)
            .reportAttempt(CircleAttemptResponse.notToday);
        container
            .read(recommendationProvider.notifier)
            .reportAttempt(CircleAttemptResponse.yes);

        expect(
          container.read(recommendationProvider).attemptResponse,
          CircleAttemptResponse.yes,
        );
      });

      test(
        'reportUsefulness() is a no-op without an affirmative attempt '
        'response first',
        () async {
          final (container, _) = await _containerWith(
            _chosenToday(),
            now: _today,
          );
          addTearDown(container.dispose);

          container.read(recommendationProvider.notifier).start();
          container.read(recommendationProvider.notifier).close();

          // No attempt answer at all yet:
          container
              .read(recommendationProvider.notifier)
              .reportUsefulness(CircleUsefulnessResponse.veryUseful);
          expect(
            container.read(recommendationProvider).usefulnessResponse,
            isNull,
          );

          // An explicit non-affirmative attempt:
          container
              .read(recommendationProvider.notifier)
              .reportAttempt(CircleAttemptResponse.notToday);
          container
              .read(recommendationProvider.notifier)
              .reportUsefulness(CircleUsefulnessResponse.veryUseful);
          expect(
            container.read(recommendationProvider).usefulnessResponse,
            isNull,
          );
        },
      );

      for (final attempt in [
        CircleAttemptResponse.yes,
        CircleAttemptResponse.aLittle,
      ]) {
        test('reportUsefulness() is recorded after an affirmative '
            '${attempt.name} attempt', () async {
          final (container, _) = await _containerWith(
            _chosenToday(),
            now: _today,
          );
          addTearDown(container.dispose);

          container.read(recommendationProvider.notifier).start();
          container.read(recommendationProvider.notifier).close();
          container.read(recommendationProvider.notifier).reportAttempt(attempt);
          container
              .read(recommendationProvider.notifier)
              .reportUsefulness(CircleUsefulnessResponse.somewhatUseful);

          expect(
            container.read(recommendationProvider).usefulnessResponse,
            CircleUsefulnessResponse.somewhatUseful,
          );
        });
      }

      test('changing the attempt answer to a non-affirmative one clears a '
          'previously recorded usefulness response', () async {
        final (container, _) = await _containerWith(_chosenToday(), now: _today);
        addTearDown(container.dispose);

        container.read(recommendationProvider.notifier).start();
        container.read(recommendationProvider.notifier).close();
        container
            .read(recommendationProvider.notifier)
            .reportAttempt(CircleAttemptResponse.yes);
        container
            .read(recommendationProvider.notifier)
            .reportUsefulness(CircleUsefulnessResponse.veryUseful);
        expect(
          container.read(recommendationProvider).usefulnessResponse,
          isNotNull,
        );

        container
            .read(recommendationProvider.notifier)
            .reportAttempt(CircleAttemptResponse.notToday);

        expect(
          container.read(recommendationProvider).usefulnessResponse,
          isNull,
        );
      });

      test('reporting an attempt/usefulness response never itself changes '
          'today\'s recommendation, and causes no automatic repeat or '
          'progression', () async {
        final (container, _) = await _containerWith(_chosenToday(), now: _today);
        addTearDown(container.dispose);

        final before = container.read(recommendationProvider).recommendation;
        container.read(recommendationProvider.notifier).start();
        container.read(recommendationProvider.notifier).close();
        container
            .read(recommendationProvider.notifier)
            .reportAttempt(CircleAttemptResponse.yes);
        container
            .read(recommendationProvider.notifier)
            .reportUsefulness(CircleUsefulnessResponse.veryUseful);
        // Calling chooseIntention again must still be the ordinary no-op —
        // an action report must never re-open today's choice.
        container
            .read(recommendationProvider.notifier)
            .chooseIntention(Intention.gentlerPace);

        final after = container.read(recommendationProvider).recommendation;
        expect(after!.activityId, before!.activityId);
        expect(after.intention, before.intention);
      });

      test('a closed state with valid attempt/usefulness responses '
          'restores correctly', () async {
        final (container, _) = await _containerWith({
          ..._chosenToday(),
          recommendationStatusKey: 'closed',
          recommendationStartedAtKey: _today.toIso8601String(),
          recommendationClosedAtKey: _laterToday.toIso8601String(),
          recommendationAttemptResponseKey: CircleAttemptResponse.aLittle.name,
          recommendationUsefulnessResponseKey:
              CircleUsefulnessResponse.notUseful.name,
        }, now: _evenLaterToday);
        addTearDown(container.dispose);

        final state = container.read(recommendationProvider);
        expect(state.attemptResponse, CircleAttemptResponse.aLittle);
        expect(state.usefulnessResponse, CircleUsefulnessResponse.notUseful);
      });

      test('a stored usefulness response is dropped on restore if the '
          'stored attempt response is not affirmative — an invalid '
          'combination is never trusted', () async {
        final (container, _) = await _containerWith({
          ..._chosenToday(),
          recommendationStatusKey: 'closed',
          recommendationStartedAtKey: _today.toIso8601String(),
          recommendationClosedAtKey: _laterToday.toIso8601String(),
          recommendationAttemptResponseKey: CircleAttemptResponse.notToday.name,
          recommendationUsefulnessResponseKey:
              CircleUsefulnessResponse.veryUseful.name,
        }, now: _evenLaterToday);
        addTearDown(container.dispose);

        final state = container.read(recommendationProvider);
        expect(state.attemptResponse, CircleAttemptResponse.notToday);
        expect(state.usefulnessResponse, isNull);
      });

      test('action-report analytics fire only on a genuine recorded '
          'response, never on a no-op call', () async {
        final analytics = _RecordingAnalyticsService();
        final (container, _) = await _containerWith(
          _chosenToday(),
          now: _today,
          analytics: analytics,
        );
        addTearDown(container.dispose);

        // No-op: not closed yet.
        container
            .read(recommendationProvider.notifier)
            .reportAttempt(CircleAttemptResponse.yes);
        expect(analytics.events, isEmpty);

        container.read(recommendationProvider.notifier).start();
        container.read(recommendationProvider.notifier).close();
        // No-op: no affirmative attempt yet.
        container
            .read(recommendationProvider.notifier)
            .reportUsefulness(CircleUsefulnessResponse.veryUseful);
        expect(
          analytics.events,
          [AnalyticsEventType.circleStarted, AnalyticsEventType.circleClosed],
        );

        container
            .read(recommendationProvider.notifier)
            .reportAttempt(CircleAttemptResponse.yes);
        container
            .read(recommendationProvider.notifier)
            .reportUsefulness(CircleUsefulnessResponse.veryUseful);

        expect(analytics.events, [
          AnalyticsEventType.circleStarted,
          AnalyticsEventType.circleClosed,
          AnalyticsEventType.circleAttemptReported,
          AnalyticsEventType.circleUsefulnessReported,
        ]);
        final attemptCall = analytics.calls.firstWhere(
          (call) => call.$1 == AnalyticsEventType.circleAttemptReported,
        );
        expect(attemptCall.$2, {'response': 'yes'});
        final usefulnessCall = analytics.calls.firstWhere(
          (call) => call.$1 == AnalyticsEventType.circleUsefulnessReported,
        );
        expect(usefulnessCall.$2, {'response': 'veryUseful'});
      });
    });

    group('Circle journal integration (ADR-013 §5)', () {
      test('chooseIntention() creates a journal entry for today, carrying '
          'the resolved direction/activity/catalogVersion', () async {
        final (container, _) = await _containerWith({}, now: _today);
        addTearDown(container.dispose);

        container
            .read(recommendationProvider.notifier)
            .chooseIntention(Intention.moreEnergy);
        await Future<void>.delayed(Duration.zero);

        final journal = CircleJournalRepository(
          container.read(sharedPreferencesProvider),
        );
        final entries = journal.readAll();
        expect(entries, hasLength(1));
        final entry = entries.single;
        expect(entry.circleId, '2026-08-02');
        expect(entry.localDate, '2026-08-02');
        expect(entry.direction, Intention.moreEnergy);
        expect(entry.catalogVersion, catalogVersion);
        expect(entry.startedAt, isNull);
        expect(entry.closedAt, isNull);
      });

      test('start()/close() update the same day\'s journal entry rather '
          'than creating additional ones', () async {
        final (container, clock) = await _containerWith({}, now: _today);
        addTearDown(container.dispose);

        container
            .read(recommendationProvider.notifier)
            .chooseIntention(Intention.moreEnergy);
        await Future<void>.delayed(Duration.zero);

        container.read(recommendationProvider.notifier).start();
        await Future<void>.delayed(Duration.zero);
        clock.advanceTo(_laterToday);
        container.read(recommendationProvider.notifier).close();
        await Future<void>.delayed(Duration.zero);

        final journal = CircleJournalRepository(
          container.read(sharedPreferencesProvider),
        );
        final entries = journal.readAll();
        expect(entries, hasLength(1));
        expect(entries.single.startedAt, isNotNull);
        expect(entries.single.closedAt, isNotNull);
      });

      test('is self-healing: start() still records a journal entry even if '
          'the "shown" write for today never happened (e.g. an app kill '
          'between chooseIntention and Start, restored in a later session)',
          () async {
        final (container, _) = await _containerWith(
          _chosenToday(
            intention: Intention.gentlerPace,
            activityId: ActivityId.easyWalk,
          ),
          now: _today,
        );
        addTearDown(container.dispose);

        // No journal key seeded at all — only the live per-day prefs.
        container.read(recommendationProvider.notifier).start();
        await Future<void>.delayed(Duration.zero);

        final journal = CircleJournalRepository(
          container.read(sharedPreferencesProvider),
        );
        final entries = journal.readAll();
        expect(entries, hasLength(1));
        expect(entries.single.circleId, '2026-08-02');
        expect(entries.single.direction, Intention.gentlerPace);
        expect(entries.single.activityId, ActivityId.easyWalk);
        expect(entries.single.startedAt, isNotNull);
      });

      test('reportAttempt()/reportUsefulness() update the same journal '
          'entry', () async {
        final (container, _) = await _containerWith(_chosenToday(), now: _today);
        addTearDown(container.dispose);

        container.read(recommendationProvider.notifier).start();
        container.read(recommendationProvider.notifier).close();
        container
            .read(recommendationProvider.notifier)
            .reportAttempt(CircleAttemptResponse.aLittle);
        container
            .read(recommendationProvider.notifier)
            .reportUsefulness(CircleUsefulnessResponse.somewhatUseful);
        await Future<void>.delayed(Duration.zero);

        final journal = CircleJournalRepository(
          container.read(sharedPreferencesProvider),
        );
        final entry = journal.readAll().single;
        expect(entry.attemptResponse, CircleAttemptResponse.aLittle);
        expect(entry.usefulnessResponse, CircleUsefulnessResponse.somewhatUseful);
      });

      test('never fabricates historical entries from Batch 2\'s '
          'per-intention anti-repetition history — only today\'s live '
          'choice produces a journal entry', () async {
        final (container, _) = await _containerWith({
          // Pre-existing Batch 2 history, but no journal key at all, and
          // no chooseIntention() call today.
          recommendationHistoryKeyFor(Intention.moreEnergy): [
            ActivityId.thirtyMinuteWalk.name,
          ],
        }, now: _today);
        addTearDown(container.dispose);

        final journal = CircleJournalRepository(
          container.read(sharedPreferencesProvider),
        );
        expect(journal.readAll(), isEmpty);
      });
    });
  });
}
