import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';

/// V2 Phase B at the provider boundary: one decision a day, restored — never
/// re-made — across restarts; one replacement; the time choice; and the
/// journal as the engine's only source.

final _today = DateTime(2026, 11, 20, 9);

/// A process: a fresh container over the persisted [stored] values.
Future<ProviderContainer> _launch(
  Map<String, Object> stored, {
  DateTime? now,
}) async {
  SharedPreferences.setMockInitialValues(stored);
  final prefs = await SharedPreferences.getInstance();
  final at = now ?? _today;
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(at),
      eventClockProvider.overrideWithValue(() => at),
    ],
  );
}

/// Everything persisted by [container], as the next launch would find it.
Future<Map<String, Object>> _stored(ProviderContainer container) async {
  await pumpEventQueue();
  final prefs = container.read(sharedPreferencesProvider);
  return {for (final key in prefs.getKeys()) key: prefs.get(key)!};
}

/// A journal holding [entries] (JSON maps), as an earlier build wrote it.
Map<String, Object> _journal(List<Map<String, Object?>> entries) => {
  circleJournalKey: jsonEncode({
    'schemaVersion': circleJournalSchemaVersion,
    'entries': entries,
  }),
};

Map<String, Object?> _entry(
  String date,
  Intention need,
  ActivityId activity, {
  CircleUsefulnessResponse? usefulness,
  CircleAttemptResponse? attempt,
  String? timeWindow,
  int version = catalogVersion,
}) => {
  'schemaVersion': circleJournalSchemaVersion,
  'circleId': date,
  'localDate': date,
  'direction': need.name,
  'activityId': activity.name,
  'catalogVersion': version,
  'shownAt': '${date}T09:00:00.000',
  'startedAt': '${date}T09:01:00.000',
  'closedAt': '${date}T09:20:00.000',
  'attemptResponse': attempt?.name,
  'usefulnessResponse': usefulness?.name,
  'timeWindow': timeWindow,
};

void main() {
  test('the chosen time decides the offer, and both are recorded in the '
      'journal and today\'s Circle', () async {
    final c = await _launch({});
    addTearDown(c.dispose);
    c.read(timeWindowChoiceProvider.notifier).choose(TimeWindow.about10);
    c
        .read(recommendationProvider.notifier)
        .chooseIntention(Intention.moreEnergy);
    final r = c.read(recommendationProvider).recommendation!;
    expect(r.timeWindow, TimeWindow.about10);
    expect(r.offeredMinutes, lessThanOrEqualTo(10));
    // A brisk walk (15 minutes at least) can't be today's ≈10 offer.
    expect(r.activityId, isNot(ActivityId.thirtyMinuteWalk));

    await pumpEventQueue();
    final entry = c.read(circleJournalRepositoryProvider).readAll().single;
    expect(entry.timeWindow, 'about10');
    expect(entry.offeredMinutes, r.offeredMinutes);
    expect(entry.reasonCode, r.reason.name);
  });

  test('tomorrow the time starts from the last explicit choice', () async {
    final c = await _launch(
      _journal([
        _entry(
          '2026-11-18',
          Intention.clearerHead,
          ActivityId.writeItDown,
          timeWindow: 'upTo30',
        ),
        _entry('2026-11-19', Intention.clearerHead, ActivityId.quietReading),
      ]),
    );
    addTearDown(c.dispose);
    expect(c.read(timeWindowChoiceProvider), TimeWindow.upTo30);
  });

  group('one decision a day, restored', () {
    for (final (label, act) in [
      ('before Start', (RecommendationNotifier n) {}),
      ('running', (RecommendationNotifier n) => n.start()),
      (
        'closed',
        (RecommendationNotifier n) {
          n.start();
          n.close();
        },
      ),
      (
        'replaced before Start',
        (RecommendationNotifier n) =>
            n.replaceToday(ReplacementReason.cantGoOutside),
      ),
    ]) {
      test('$label: a restart restores the same offer — even after new '
          'evidence lands in the journal', () async {
        final first = await _launch({});
        first
            .read(recommendationProvider.notifier)
            .chooseIntention(Intention.gentlerPace);
        await pumpEventQueue();
        act(first.read(recommendationProvider.notifier));
        final before = first.read(recommendationProvider);
        final stored = await _stored(first);
        first.dispose();

        final again = await _launch(stored);
        addTearDown(again.dispose);
        final after = again.read(recommendationProvider);
        expect(after.status, before.status);
        final a = after.recommendation!, b = before.recommendation!;
        expect(a.activityId, b.activityId);
        expect(a.offeredMinutes, b.offeredMinutes);
        expect(a.reason, b.reason);
        expect(a.timeWindow, b.timeWindow);
        expect(a.replacedFrom, b.replacedFrom);
        expect(a.canReplace, b.canReplace);

        // Choosing again changes nothing: no hidden reroll.
        again
            .read(recommendationProvider.notifier)
            .chooseIntention(Intention.moreEnergy);
        expect(
          again.read(recommendationProvider).recommendation!.activityId,
          b.activityId,
        );
      });
    }
  });

  group('Not this one today', () {
    test('one replacement, under its constraint, recorded truthfully — and '
        'never a second, even after a restart', () async {
      final c = await _launch({});
      final notifier = c.read(recommendationProvider.notifier);
      notifier.chooseIntention(Intention.gentlerPace);
      final original = c.read(recommendationProvider).recommendation!;
      expect(original.activityId, ActivityId.easyWalk);
      expect(original.canReplace, isTrue);

      expect(notifier.replaceToday(ReplacementReason.cantGoOutside), isTrue);
      final replaced = c.read(recommendationProvider).recommendation!;
      expect(replaced.activityId, isNot(ActivityId.easyWalk));
      expect(
        activityDefinition(replaced.activityId).setting,
        isNot(ActivitySetting.outdoor),
      );
      expect(replaced.replacedFrom, ActivityId.easyWalk);
      expect(replaced.replacementReason, ReplacementReason.cantGoOutside);
      expect(replaced.personalReason, 'An indoor one instead.');
      expect(replaced.canReplace, isFalse);
      expect(notifier.replaceToday(ReplacementReason.notFeeling), isFalse);

      await pumpEventQueue();
      final entry = c.read(circleJournalRepositoryProvider).readAll().single;
      expect(entry.activityId, replaced.activityId);
      expect(entry.replacedFrom, ActivityId.easyWalk);
      expect(entry.replacementReason, 'cantGoOutside');
      // A replacement is never a usefulness answer.
      expect(entry.usefulnessResponse, isNull);

      final stored = await _stored(c);
      c.dispose();
      final again = await _launch(stored);
      addTearDown(again.dispose);
      expect(
        again.read(recommendationProvider).recommendation!.activityId,
        replaced.activityId,
      );
      expect(
        again
            .read(recommendationProvider.notifier)
            .replaceToday(ReplacementReason.tooMuch),
        isFalse,
      );
    });

    test('not once the Circle has started', () async {
      final c = await _launch({});
      addTearDown(c.dispose);
      final notifier = c.read(recommendationProvider.notifier);
      notifier.chooseIntention(Intention.moreEnergy);
      notifier.start();
      expect(notifier.replaceToday(ReplacementReason.tooMuch), isFalse);
    });
  });

  group('the journal is the engine\'s only source', () {
    test('"Didn\'t try" and no answer carry no usefulness at all', () {
      final circles = pastCirclesFrom([
        for (final json in [
          _entry(
            '2026-11-17',
            Intention.moreEnergy,
            ActivityId.moveToMusic,
            attempt: CircleAttemptResponse.notToday,
          ),
          _entry('2026-11-18', Intention.moreEnergy, ActivityId.moveToMusic),
          _entry(
            '2026-11-19',
            Intention.moreEnergy,
            ActivityId.moveToMusic,
            attempt: CircleAttemptResponse.yes,
            usefulness: CircleUsefulnessResponse.notUseful,
          ),
        ])
          CircleJournalEntry.fromJson(json)!,
      ]);
      expect(circles.map((c) => c.usefulness), [
        null,
        null,
        PastUsefulness.notUseful,
      ]);
    });

    test('a "Very useful" answer in the journal changes a later pick, with '
        'its reason', () async {
      final c = await _launch(
        _journal([
          _entry(
            '2026-11-14',
            Intention.clearerHead,
            ActivityId.quietReading,
            attempt: CircleAttemptResponse.yes,
            usefulness: CircleUsefulnessResponse.veryUseful,
          ),
          _entry(
            '2026-11-16',
            Intention.clearerHead,
            ActivityId.tidyOneSurface,
          ),
          _entry('2026-11-18', Intention.clearerHead, ActivityId.writeItDown),
        ]),
      );
      addTearDown(c.dispose);
      c
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.clearerHead);
      final r = c.read(recommendationProvider).recommendation!;
      expect(r.activityId, ActivityId.quietReading);
      expect(r.personalReason, 'You found this useful before.');
    });
  });
}
