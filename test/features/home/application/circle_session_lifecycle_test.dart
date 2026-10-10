import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/dev_preview/paced_qa_bench_page.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/home/domain/circle_session.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/home/domain/recommendation_policy.dart';

/// V2 Phase C — today's Circle across the app's lifecycle (ADR-021): the
/// runtime is a few timestamps and a little state, so a resume from the
/// background (which rebuilds today's Circle from storage) and a process
/// restart (a fresh container over the same storage) land exactly where
/// time says. Answers, suggestion preferences, Delete, Reset and Export
/// keep their boundaries.

final _morning = DateTime(2026, 11, 20, 9);
const _day = '2026-11-20';

late DateTime _clock;
late SharedPreferences _prefs;

ProviderContainer _open({DateTime? now}) {
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(_prefs),
      nowProvider.overrideWithValue(now ?? _morning),
      eventClockProvider.overrideWithValue(() => _clock),
      safetyPendingAllowedProvider.overrideWithValue(false),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Today's Circle already offered: [activity] for [need], [minutes] long.
Map<String, Object> _offered(
  Intention need,
  ActivityId activity,
  int minutes,
) => {
  recommendationDayKey: _day,
  recommendationIntentionKey: need.name,
  recommendationActivityIdKey: activity.name,
  recommendationTimeWindowKey: TimeWindow.about20.name,
  recommendationOfferedMinutesKey: minutes,
  recommendationReasonKey: RecommendationReason.bestFit.name,
};

Future<void> _settle() => Future<void>.delayed(Duration.zero);

Future<void> _setUp([Map<String, Object> stored = const {}]) async {
  SharedPreferences.setMockInitialValues(stored);
  _prefs = await SharedPreferences.getInstance();
  _clock = _morning;
}

void main() {
  group('Open: wall-clock time, through background and restart', () {
    test('elapsed is the clock since Start; a resume rebuild and a '
        'restart both restore it; the natural end never closes the '
        'Circle', () async {
      await _setUp(_offered(Intention.clearerHead, ActivityId.writeItDown, 15));
      final c = _open();
      c.read(recommendationProvider.notifier).start();
      await _settle();

      _clock = _morning.add(const Duration(minutes: 6));
      expect(
        c.read(recommendationProvider).activeElapsedAt(_clock),
        const Duration(minutes: 6),
      );

      // Backgrounded for 20 minutes; on resume THIRTY rebuilds today's
      // Circle from storage (thirty_app.dart invalidates nowProvider).
      _clock = _morning.add(const Duration(minutes: 26));
      c.invalidate(nowProvider);
      final resumed = c.read(recommendationProvider);
      expect(resumed.status, RecommendationStatus.started);
      expect(resumed.activeElapsedAt(_clock), const Duration(minutes: 26));
      expect(
        naturalEndReached(
          resumed.activeElapsedAt(_clock),
          const Duration(minutes: 15),
        ),
        isTrue,
      );

      // The process was killed: a fresh container over the same storage.
      final restarted = _open().read(recommendationProvider);
      expect(restarted.status, RecommendationStatus.started);
      expect(restarted.startedAt, _morning);
      expect(restarted.activeElapsedAt(_clock), const Duration(minutes: 26));
    });

    test('an early close is neutral and factual: the minutes it ran, and '
        'no usefulness evidence from Close alone', () async {
      await _setUp(_offered(Intention.clearerHead, ActivityId.writeItDown, 15));
      final c = _open();
      final notifier = c.read(recommendationProvider.notifier);
      notifier.start();
      _clock = _morning.add(const Duration(minutes: 4, seconds: 30));
      notifier.close();
      await _settle();

      final entry = c.read(circleJournalRepositoryProvider).readAll().single;
      expect(entry.closedAt, _clock);
      expect(entry.minutesAtClose, 4);
      expect(entry.attemptResponse, isNull);
      expect(entry.usefulnessResponse, isNull);
      expect(pastCirclesFrom([entry]).single.usefulness, isNull);
    });
  });

  group('Guided: the position, a pause, and nothing claimed', () {
    Future<ProviderContainer> started() async {
      await _setUp(
        _offered(Intention.moreEnergy, ActivityId.energisingStretchFlow, 5),
      );
      final c = _open();
      c.read(recommendationProvider.notifier).start();
      await _settle();
      return c;
    }

    test('Next and Back move the step on show; it survives a resume and a '
        'restart; it is clamped to the steps and "To finish"', () async {
      final c = await started();
      final notifier = c.read(recommendationProvider.notifier);
      notifier.moveTo(1);
      notifier.moveTo(2);
      notifier.moveTo(1);
      await _settle();
      expect(c.read(recommendationProvider).guidedPosition, 1);

      c.invalidate(nowProvider);
      expect(c.read(recommendationProvider).guidedPosition, 1);
      expect(_open().read(recommendationProvider).guidedPosition, 1);

      notifier.moveTo(99);
      expect(c.read(recommendationProvider).guidedPosition, 5);
      notifier.moveTo(-4);
      expect(c.read(recommendationProvider).guidedPosition, 0);
    });

    test(
      'a pause stops the Circle\'s time — through the background and a '
      'restart — until Resume; time away while paused never counts',
      () async {
        final c = await started();
        final notifier = c.read(recommendationProvider.notifier);
        _clock = _morning.add(const Duration(minutes: 1));
        notifier.pause();
        await _settle();

        _clock = _morning.add(const Duration(minutes: 21));
        c.invalidate(nowProvider);
        final resumed = c.read(recommendationProvider);
        expect(resumed.isPaused, isTrue);
        expect(resumed.activeElapsedAt(_clock), const Duration(minutes: 1));

        final restarted = _open();
        expect(restarted.read(recommendationProvider).isPaused, isTrue);
        expect(
          restarted.read(recommendationProvider).activeElapsedAt(_clock),
          const Duration(minutes: 1),
        );

        notifier.resume();
        _clock = _morning.add(const Duration(minutes: 23));
        expect(
          c.read(recommendationProvider).activeElapsedAt(_clock),
          const Duration(minutes: 3),
        );
      },
    );

    test('closing while paused records the active minutes; no step, '
        'position or "completed" reaches the journal', () async {
      final c = await started();
      final notifier = c.read(recommendationProvider.notifier);
      notifier.moveTo(5); // "To finish"
      _clock = _morning.add(const Duration(minutes: 2));
      notifier.pause();
      _clock = _morning.add(const Duration(minutes: 30));
      notifier.close();
      await _settle();

      final entry = c.read(circleJournalRepositoryProvider).readAll().single;
      expect(entry.minutesAtClose, 2);
      expect(entry.attemptResponse, isNull);
      final keys = entry.toJson().keys.join(' ').toLowerCase();
      for (final word in ['step', 'position', 'complet', 'done']) {
        expect(keys, isNot(contains(word)));
      }
    });

    test('a new day starts with no runtime left over', () async {
      final c = await started();
      final notifier = c.read(recommendationProvider.notifier);
      notifier.moveTo(3);
      notifier.pause();
      for (var i = 0; i < 5; i++) {
        await _settle();
      }
      // The next morning.
      final tomorrow = _morning.add(const Duration(days: 1));
      _clock = tomorrow;
      final next = _open(now: tomorrow);
      expect(next.read(recommendationProvider).recommendation, isNull);
      next
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.gentlerPace);
      for (var i = 0; i < 5; i++) {
        await _settle();
      }
      final fresh = next.read(recommendationProvider);
      expect((fresh.guidedPosition, fresh.pausedAt), (0, null));
      expect(_prefs.getInt(recommendationGuidedPositionKey), isNull);
      expect(_prefs.getString(recommendationPausedAtKey), isNull);
    });
  });

  group('Paced (internal QA bench): pauses when hidden, stays paused', () {
    test('pause freezes the phase; a restart keeps it paused; only Resume '
        'continues', () async {
      await _setUp();
      final c = _open();
      final bench = c.read(pacedQaProvider.notifier);
      await bench.start();
      _clock = _morning.add(const Duration(seconds: 13));
      await bench.pause();
      _clock = _morning.add(const Duration(minutes: 5));

      final restarted = _open();
      final again = restarted.read(pacedQaProvider.notifier);
      expect(restarted.read(pacedQaProvider).pausedAt, isNotNull);
      final moment = paceMomentFor(pacedQaFixture, again.elapsedAt(_clock));
      expect((moment.cycle, moment.phaseIndex), (1, 0));
      expect(moment.phaseElapsed, const Duration(seconds: 3));

      await again.resume();
      _clock = _morning.add(const Duration(minutes: 5, seconds: 2));
      expect(again.elapsedAt(_clock), const Duration(seconds: 15));
    });
  });

  group('Remove this answer', () {
    Map<String, Object> closedAnswered() => {
      ..._offered(Intention.clearerHead, ActivityId.writeItDown, 15),
      recommendationStatusKey: 'closed',
      recommendationStartedAtKey: _morning.toIso8601String(),
      recommendationClosedAtKey: _morning
          .add(const Duration(minutes: 15))
          .toIso8601String(),
      recommendationAttemptResponseKey: 'yes',
      recommendationUsefulnessResponseKey: 'veryUseful',
    };

    Future<void> seedJournal(ProviderContainer c) async {
      final journal = c.read(circleJournalRepositoryProvider);
      await journal.recordShown(
        circleId: '2026-11-18',
        localDate: '2026-11-18',
        direction: Intention.gentlerPace,
        activityId: ActivityId.easyWalk,
        shownAt: DateTime(2026, 11, 18, 8),
      );
      await journal.recordClosed(
        circleId: '2026-11-18',
        localDate: '2026-11-18',
        direction: Intention.gentlerPace,
        activityId: ActivityId.easyWalk,
        closedAt: DateTime(2026, 11, 18, 8, 30),
      );
      await journal.recordAttempt(
        circleId: '2026-11-18',
        localDate: '2026-11-18',
        direction: Intention.gentlerPace,
        activityId: ActivityId.easyWalk,
        response: CircleAttemptResponse.yes,
        respondedAt: DateTime(2026, 11, 18, 8, 31),
      );
      await journal.recordUsefulness(
        circleId: '2026-11-18',
        localDate: '2026-11-18',
        direction: Intention.gentlerPace,
        activityId: ActivityId.easyWalk,
        response: CircleUsefulnessResponse.notUseful,
        respondedAt: DateTime(2026, 11, 18, 8, 31),
      );
      await journal.recordClosed(
        circleId: _day,
        localDate: _day,
        direction: Intention.clearerHead,
        activityId: ActivityId.writeItDown,
        closedAt: _morning.add(const Duration(minutes: 15)),
      );
      await journal.recordAttempt(
        circleId: _day,
        localDate: _day,
        direction: Intention.clearerHead,
        activityId: ActivityId.writeItDown,
        response: CircleAttemptResponse.yes,
        respondedAt: _morning,
      );
      await journal.recordUsefulness(
        circleId: _day,
        localDate: _day,
        direction: Intention.clearerHead,
        activityId: ActivityId.writeItDown,
        response: CircleUsefulnessResponse.veryUseful,
        respondedAt: _morning,
      );
    }

    test('today\'s usefulness goes — from the Circle and the journal — and '
        'the record stays; the question can be answered again', () async {
      await _setUp(closedAnswered());
      final c = _open();
      await seedJournal(c);
      c
          .read(recommendationProvider.notifier)
          .removeAnswer(_day, includingAttempt: false);
      await _settle();
      await _settle();

      final state = c.read(recommendationProvider);
      expect(state.attemptResponse, CircleAttemptResponse.yes);
      expect(state.usefulnessResponse, isNull);
      final entry = c
          .read(circleJournalRepositoryProvider)
          .readAll()
          .firstWhere((e) => e.circleId == _day);
      expect(entry.usefulnessResponse, isNull);
      expect(entry.attemptResponse, CircleAttemptResponse.yes);
      expect(entry.closedAt, isNotNull);
      // Reloaded, the same.
      expect(_open().read(recommendationProvider).usefulnessResponse, isNull);
    });

    test('removing the attempt takes its usefulness with it; a past '
        'record\'s answer goes, its rest with it', () async {
      await _setUp(closedAnswered());
      final c = _open();
      await seedJournal(c);
      final notifier = c.read(recommendationProvider.notifier);
      notifier.removeAnswer(_day, includingAttempt: true);
      notifier.removeAnswer('2026-11-18', includingAttempt: false);
      await _settle();
      await _settle();

      final entries = c.read(circleJournalRepositoryProvider).readAll();
      expect(entries, hasLength(2));
      final today = entries.firstWhere((e) => e.circleId == _day);
      expect((today.attemptResponse, today.usefulnessResponse), (null, null));
      final past = entries.firstWhere((e) => e.circleId == '2026-11-18');
      expect(past.attemptResponse, CircleAttemptResponse.yes);
      expect(past.usefulnessResponse, isNull);
      // Engine V2 recomputes from the journal: Easy walk no longer rests.
      final memory = RecommendationMemory.of(
        DateTime(2026, 11, 21),
        pastCirclesFrom(entries),
        RecommendationPolicy.initial,
      );
      expect(
        memory.daysSinceNotUseful(ActivityId.easyWalk, Intention.gentlerPace),
        isNull,
      );
    });
  });

  group('the user\'s explicit preferences', () {
    test('"Don\'t suggest" persists, holds in the daily choice, and '
        'leaves another need alone; when nothing is left it says so and '
        'records nothing', () async {
      await _setUp({recommendationTimeWindowKey: 'about10'});
      final c = _open();
      final prefs = c.read(suggestionPreferencesProvider.notifier);
      for (final id in [
        ActivityId.moveToMusic,
        ActivityId.energisingStretchFlow,
        ActivityId.activeHouseholdTask,
        ActivityId.tidyOneSurface,
        ActivityId.gentleStretchPause,
      ]) {
        await prefs.dontSuggest(id, Intention.moreEnergy);
      }
      expect(
        _open().read(suggestionPreferencesProvider).notSuggested,
        hasLength(5),
      );

      final notifier = c.read(recommendationProvider.notifier);
      notifier.chooseIntention(
        Intention.moreEnergy,
        window: TimeWindow.about10,
      );
      await _settle();
      final state = c.read(recommendationProvider);
      expect(state.recommendation, isNull);
      expect(state.noCandidateFor, (Intention.moreEnergy, TimeWindow.about10));
      expect(c.read(circleJournalRepositoryProvider).readAll(), isEmpty);

      notifier.chooseIntention(
        Intention.gentlerPace,
        window: TimeWindow.about10,
      );
      expect(c.read(recommendationProvider).recommendation, isNotNull);
    });

    test('Delete Circle history keeps them; Reset keeps the history', () async {
      await _setUp(_offered(Intention.clearerHead, ActivityId.writeItDown, 15));
      final c = _open();
      final notifier = c.read(recommendationProvider.notifier);
      notifier.start();
      notifier.close();
      notifier.reportAttempt(CircleAttemptResponse.yes);
      notifier.reportUsefulness(CircleUsefulnessResponse.notUseful);
      await _settle();
      final prefs = c.read(suggestionPreferencesProvider.notifier);
      await prefs.dontSuggest(ActivityId.moveToMusic, Intention.moreEnergy);
      await prefs.liftRest(ActivityId.writeItDown, Intention.clearerHead);

      // Reset suggestion preferences: history and its answers stay.
      await prefs.reset();
      expect(c.read(suggestionPreferencesProvider).isEmpty, isTrue);
      final kept = c.read(circleJournalRepositoryProvider).readAll().single;
      expect(kept.usefulnessResponse, CircleUsefulnessResponse.notUseful);

      // Delete Circle history (journal_data_controls.dart's own steps):
      // every derived thing goes; the user's choices stay.
      await prefs.dontSuggest(ActivityId.moveToMusic, Intention.moreEnergy);
      await c.read(circleJournalRepositoryProvider).clearAll();
      await clearRecordedCircleState(_prefs);
      c.invalidate(circleJournalRepositoryProvider);
      c.invalidate(recommendationProvider);
      expect(c.read(circleJournalRepositoryProvider).readAll(), isEmpty);
      expect(c.read(recommendationProvider).recommendation, isNull);
      expect(
        c
            .read(suggestionPreferencesProvider)
            .isNotSuggested(ActivityId.moveToMusic, Intention.moreEnergy),
        isTrue,
      );
      expect(
        _open()
            .read(suggestionPreferencesProvider)
            .isNotSuggested(ActivityId.moveToMusic, Intention.moreEnergy),
        isTrue,
      );
    });

    test('Export carries the journal\'s V2 fields and, apart from it, the '
        'user\'s preferences — and nothing derived', () async {
      await _setUp(_offered(Intention.clearerHead, ActivityId.writeItDown, 15));
      final c = _open();
      final notifier = c.read(recommendationProvider.notifier);
      notifier.start();
      _clock = _morning.add(const Duration(minutes: 9));
      notifier.close();
      await _settle();
      await c
          .read(suggestionPreferencesProvider.notifier)
          .dontSuggest(ActivityId.moveToMusic, Intention.moreEnergy);

      final preferences = c.read(suggestionPreferencesProvider);
      final exported =
          jsonDecode(
                c
                    .read(circleJournalRepositoryProvider)
                    .exportAsJson(suggestionPreferences: preferences.toJson()),
              )
              as Map<String, Object?>;
      final entry = (exported['entries']! as List).single as Map;
      expect(entry['minutesAtClose'], 9);
      expect(entry['offeredMinutes'], 15);
      expect(entry['timeWindow'], 'about20');
      final exportedPrefs = exported['suggestionPreferences']! as Map;
      expect((exportedPrefs['notSuggested']! as List).single, {
        'activityId': 'moveToMusic',
        'need': 'moreEnergy',
        'since': _morning.add(const Duration(minutes: 9)).toIso8601String(),
      });
      final text = jsonEncode(exported).toLowerCase();
      for (final derived in ['strength', 'score', 'rest_until', 'band']) {
        expect(text, isNot(contains(derived)));
      }
      // Without preferences, the export is the journal as before.
      expect(
        jsonDecode(c.read(circleJournalRepositoryProvider).exportAsJson()),
        isNot(contains('suggestionPreferences')),
      );
    });
  });
}
