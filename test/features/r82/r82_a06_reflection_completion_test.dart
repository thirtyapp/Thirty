import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';

import '../../support/r8_harness.dart';

/// R8.2 — Astra R81-A06 (MEDIUM): finishing the reflection of a Circle
/// carried over midnight is the user's completed act. Removing an answer
/// afterwards — the user's right — removes the answer, never that
/// completion: the finished reflection is not reimposed, the new day stays
/// open, nothing is invented, and the six-hour carry-over is unchanged for
/// a reflection genuinely still open.
void main() {
  final evening = DateTime(2026, 10, 12, 23, 30);
  final afterMidnight = DateTime(2026, 10, 13, 0, 10);
  late R8Harness h;

  setUp(() async {
    h = R8Harness(evening);
    await h.boot();
  });

  RecommendationNotifier today(ProviderContainer c) =>
      c.read(recommendationProvider.notifier);

  /// Start at 23:40, Close at 00:10 — carried over midnight.
  Future<(ProviderContainer, String)> closedAfterMidnight() async {
    final c = h.open(status: EntitlementStatus.inactive);
    today(c).chooseIntention(Intention.clearerHead);
    await R8Harness.settle();
    final id = c.read(recommendationProvider).recommendation!.circleId;
    expect(id, '2026-10-12');
    h.clock.value = DateTime(2026, 10, 12, 23, 40);
    today(c).start();
    await R8Harness.settle();
    h.clock.value = afterMidnight;
    today(c).close();
    await R8Harness.settle();
    expect(c.read(recommendationProvider).recommendation?.circleId, id);
    return (c, id);
  }

  CircleJournalEntry historyOf(ProviderContainer c, String id) => c
      .read(circleJournalRepositoryProvider)
      .readAll()
      .singleWhere((e) => e.circleId == id);

  /// The new day is open, and its Circle can be chosen.
  Future<void> newDayOpens(ProviderContainer c) async {
    expect(
      c.read(recommendationProvider).recommendation,
      isNull,
      reason: 'the finished reflection was reimposed',
    );
    today(c).chooseIntention(Intention.gentlerPace);
    await R8Harness.settle();
    expect(
      c.read(recommendationProvider).recommendation?.circleId,
      '2026-10-13',
    );
    expect((await h.disk.stored())[recommendationDayKey], '2026-10-13');
  }

  final finishes = <String, void Function(RecommendationNotifier)>{
    'Yes and useful': (t) {
      t.reportAttempt(CircleAttemptResponse.yes);
      t.reportUsefulness(CircleUsefulnessResponse.veryUseful);
    },
    'Not today': (t) => t.reportAttempt(CircleAttemptResponse.notToday),
  };

  for (final MapEntry(key: finish, value: answer) in finishes.entries) {
    for (final includingAttempt in [false, true]) {
      if (finish == 'Not today' && !includingAttempt) continue;
      final removed = includingAttempt ? 'both answers' : 'the useful answer';
      test('A06 as reported — "$finish", the new day opens, $removed '
          'removed, restart at 00:20: the reflection stays finished and '
          'the next Circle can be chosen', () async {
        final (c, id) = await closedAfterMidnight();
        answer(today(c));
        await R8Harness.settle();
        expect(c.read(recommendationProvider).recommendation, isNull);

        today(c).removeAnswer(id, includingAttempt: includingAttempt);
        await R8Harness.settle();
        final stored = await h.disk.stored();
        expect(stored[recommendationUsefulnessResponseKey], isNull);
        if (includingAttempt) {
          expect(stored[recommendationAttemptResponseKey], isNull);
        }

        h.clock.value = DateTime(2026, 10, 13, 0, 20);
        await h.restart();
        final again = h.open(status: EntitlementStatus.inactive);
        final entry = historyOf(again, id);
        expect(entry.usefulnessResponse, isNull, reason: 'answer resurrected');
        if (includingAttempt) expect(entry.attemptResponse, isNull);
        expect(entry.closedAt, isNotNull);
        await newDayOpens(again);
        expect(historyOf(again, id).usefulnessResponse, isNull);

        // Repeated restart: still the new day's Circle, nothing invented.
        await h.restart();
        final third = h.open(status: EntitlementStatus.inactive);
        expect(
          third.read(recommendationProvider).recommendation?.circleId,
          '2026-10-13',
        );
        expect(historyOf(third, id).usefulnessResponse, isNull);
      });
    }
  }

  test('the same in one session: recovery at 00:20 (a resume) does not '
      'bring the finished Circle back', () async {
    final (c, id) = await closedAfterMidnight();
    today(c).reportAttempt(CircleAttemptResponse.yes);
    today(c).reportUsefulness(CircleUsefulnessResponse.somewhatUseful);
    await R8Harness.settle();
    today(c).removeAnswer(id, includingAttempt: true);
    await R8Harness.settle();
    h.clock.value = DateTime(2026, 10, 13, 0, 20);
    c.invalidate(nowProvider);
    await newDayOpens(c);
  });

  test('control — a reflection genuinely still open after midnight is '
      'still carried over (no invented answer, no invented completion)', () async {
    final (_, id) = await closedAfterMidnight();
    h.clock.value = DateTime(2026, 10, 13, 0, 20);
    await h.restart();
    final again = h.open(status: EntitlementStatus.inactive);
    final state = again.read(recommendationProvider);
    expect(state.recommendation?.circleId, id);
    expect(state.status, RecommendationStatus.closed);
    expect(state.attemptResponse, isNull);
    today(again).chooseIntention(Intention.gentlerPace);
    expect(again.read(recommendationProvider).recommendation?.circleId, id);
  });

  test('control — an answer only half given ("Yes", no usefulness) is not '
      'a finished reflection: removing nothing, it is still carried over',
      () async {
    final (c, id) = await closedAfterMidnight();
    today(c).reportAttempt(CircleAttemptResponse.yes);
    await R8Harness.settle();
    h.clock.value = DateTime(2026, 10, 13, 0, 20);
    await h.restart();
    final again = h.open(status: EntitlementStatus.inactive);
    expect(again.read(recommendationProvider).recommendation?.circleId, id);
  });

  test('control — six hours after the Close an open reflection is no longer '
      'carried over; a finished one, answers removed, is not either', () async {
    final (c, id) = await closedAfterMidnight();
    today(c).reportAttempt(CircleAttemptResponse.notToday);
    await R8Harness.settle();
    today(c).removeAnswer(id, includingAttempt: true);
    await R8Harness.settle();
    h.clock.value = afterMidnight.add(const Duration(hours: 6, minutes: 1));
    await h.restart();
    final again = h.open(status: EntitlementStatus.inactive);
    await newDayOpens(again);
  });

  test('the completion is the session\'s own: a new day\'s choice clears '
      'it with the rest of the earlier session', () async {
    final (c, _) = await closedAfterMidnight();
    today(c).reportAttempt(CircleAttemptResponse.notToday);
    await R8Harness.settle();
    today(c).chooseIntention(Intention.gentlerPace);
    await R8Harness.settle();
    final stored = await h.disk.stored();
    expect(stored[recommendationDayKey], '2026-10-13');
    expect(
      stored.keys.where((k) => k.startsWith('recommendation_reflection')),
      isEmpty,
    );
  });
}
