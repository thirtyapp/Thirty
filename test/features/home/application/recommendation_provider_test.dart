import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';

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
}) async {
  SharedPreferences.setMockInitialValues(storedPrefs);
  final prefs = await SharedPreferences.getInstance();
  final clock = _TestClock(now ?? _today);

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(now ?? _today),
      eventClockProvider.overrideWithValue(clock.call),
    ],
  );
  return (container, clock);
}

void main() {
  group('recommendationProvider', () {
    test('a new day defaults to notStarted with null timestamps', () async {
      final (container, _) = await _containerWith({});
      addTearDown(container.dispose);

      final state = container.read(recommendationProvider);

      expect(state.status, RecommendationStatus.notStarted);
      expect(state.startedAt, isNull);
      expect(state.closedAt, isNull);
    });

    test('start() moves notStarted to started and records startedAt', () async {
      final (container, _) = await _containerWith({}, now: _today);
      addTearDown(container.dispose);

      container.read(recommendationProvider.notifier).start();
      final state = container.read(recommendationProvider);

      expect(state.status, RecommendationStatus.started);
      expect(state.startedAt, _today);
      expect(state.closedAt, isNull);
    });

    test(
      'start() uses the real moment of the call, not a stale build-time '
      'snapshot',
      () async {
        final (container, clock) = await _containerWith({}, now: _today);
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
      },
    );

    test('a second start() is a no-op and does not overwrite startedAt', () async {
      final (container, clock) = await _containerWith({}, now: _today);
      addTearDown(container.dispose);

      container.read(recommendationProvider.notifier).start();
      expect(container.read(recommendationProvider).startedAt, _today);

      clock.advanceTo(_laterToday);
      container.read(recommendationProvider.notifier).start();

      final state = container.read(recommendationProvider);
      expect(state.status, RecommendationStatus.started);
      expect(state.startedAt, _today);
    });

    test(
      'close() moves started to closed, keeps startedAt, records the real '
      'moment of the close() call as closedAt',
      () async {
        final (container, clock) = await _containerWith({}, now: _today);
        addTearDown(container.dispose);

        container.read(recommendationProvider.notifier).start();
        clock.advanceTo(_laterToday);
        container.read(recommendationProvider.notifier).close();

        final state = container.read(recommendationProvider);
        expect(state.status, RecommendationStatus.closed);
        expect(state.startedAt, _today);
        expect(state.closedAt, _laterToday);
      },
    );

    test('close() from notStarted is a no-op', () async {
      final (container, _) = await _containerWith({}, now: _today);
      addTearDown(container.dispose);

      container.read(recommendationProvider.notifier).close();

      final state = container.read(recommendationProvider);
      expect(state.status, RecommendationStatus.notStarted);
      expect(state.startedAt, isNull);
      expect(state.closedAt, isNull);
    });

    test('a second close() is a no-op and does not overwrite closedAt', () async {
      final (container, clock) = await _containerWith({}, now: _today);
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
    });

    test('restores a started state persisted earlier today', () async {
      final (container, _) = await _containerWith({
        recommendationDayKey: '2026-08-02',
        recommendationStatusKey: 'started',
        recommendationStartedAtKey: _today.toIso8601String(),
      }, now: _laterToday);
      addTearDown(container.dispose);

      final state = container.read(recommendationProvider);
      expect(state.status, RecommendationStatus.started);
      expect(state.startedAt, _today);
      expect(state.closedAt, isNull);
    });

    test(
      'restoring a started state ignores a stale closedAt key from an '
      'earlier session',
      () async {
        final (container, _) = await _containerWith({
          recommendationDayKey: '2026-08-02',
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
      },
    );

    test('restores a closed state persisted earlier today', () async {
      final (container, _) = await _containerWith({
        recommendationDayKey: '2026-08-02',
        recommendationStatusKey: 'closed',
        recommendationStartedAtKey: _today.toIso8601String(),
        recommendationClosedAtKey: _laterToday.toIso8601String(),
      }, now: _evenLaterToday);
      addTearDown(container.dispose);

      final state = container.read(recommendationProvider);
      expect(state.status, RecommendationStatus.closed);
      expect(state.startedAt, _today);
      expect(state.closedAt, _laterToday);
    });

    test(
      'a closed record missing its closedAt fails safe to notStarted',
      () async {
        final (container, _) = await _containerWith({
          recommendationDayKey: '2026-08-02',
          recommendationStatusKey: 'closed',
          recommendationStartedAtKey: _today.toIso8601String(),
          // No recommendationClosedAtKey at all.
        }, now: _laterToday);
        addTearDown(container.dispose);

        final state = container.read(recommendationProvider);
        expect(state.status, RecommendationStatus.notStarted);
        expect(state.startedAt, isNull);
        expect(state.closedAt, isNull);
      },
    );

    test(
      'a closed record with closedAt before startedAt fails safe to '
      'notStarted',
      () async {
        final (container, _) = await _containerWith({
          recommendationDayKey: '2026-08-02',
          recommendationStatusKey: 'closed',
          recommendationStartedAtKey: _laterToday.toIso8601String(),
          // Impossible ordering: closed before it started.
          recommendationClosedAtKey: _today.toIso8601String(),
        }, now: _evenLaterToday);
        addTearDown(container.dispose);

        final state = container.read(recommendationProvider);
        expect(state.status, RecommendationStatus.notStarted);
        expect(state.startedAt, isNull);
        expect(state.closedAt, isNull);
      },
    );

    test(
      'a state persisted on an earlier calendar day resets to notStarted',
      () async {
        final (container, _) = await _containerWith({
          recommendationDayKey: '2026-08-01',
          recommendationStatusKey: 'started',
          recommendationStartedAtKey: _yesterday.toIso8601String(),
        }, now: _today);
        addTearDown(container.dispose);

        final state = container.read(recommendationProvider);
        expect(state.status, RecommendationStatus.notStarted);
        expect(state.startedAt, isNull);
        expect(state.closedAt, isNull);
      },
    );

    test(
      'a corrupt/incomplete persisted record fails safe to notStarted',
      () async {
        // Same day, status says "started", but startedAt is unparseable.
        final (container, _) = await _containerWith({
          recommendationDayKey: '2026-08-02',
          recommendationStatusKey: 'started',
          recommendationStartedAtKey: 'not-a-date',
        }, now: _today);
        addTearDown(container.dispose);

        final state = container.read(recommendationProvider);
        expect(state.status, RecommendationStatus.notStarted);
        expect(state.startedAt, isNull);
        expect(state.closedAt, isNull);
      },
    );
  });
}
