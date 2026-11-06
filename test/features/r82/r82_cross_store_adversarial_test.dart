import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_history_deletion.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// R8.2 — cross-store adversarial review: the interleavings the R8.2
/// findings sit between, run together, every outcome read from the disk
/// and from fresh processes.
void main() {
  final morning = DateTime(2026, 10, 12, 9);
  late R8Harness h;

  setUp(() async {
    h = R8Harness(morning);
    await h.boot();
  });

  RecommendationNotifier today(ProviderContainer c) =>
      c.read(recommendationProvider.notifier);
  CirclePlansNotifier plans(ProviderContainer c) =>
      c.read(circlePlansProvider.notifier);

  Future<Map<String, Object?>> json(String key) async {
    final raw = (await h.disk.stored())[key];
    return raw is String ? jsonDecode(raw) as Map<String, Object?> : {};
  }

  Future<int> credits(String circleId) async {
    final stored = (await json(circlePlansKey))['plans'] as Map? ?? {};
    final plan = stored['getting_going'] as Map?;
    if (plan == null) return 0;
    return [
      for (final cycle in plan['cycles'] as List)
        for (final r in (cycle as Map)['records'] as List)
          if ((r as Map)['circleId'] == circleId) r,
    ].length;
  }

  Future<(ProviderContainer, String)> stageStarted() async {
    final c = h.open();
    plans(c).start('getting_going');
    today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
    await R8Harness.settle();
    final id = c.read(recommendationProvider).recommendation!.circleId;
    today(c).start();
    await R8Harness.settle();
    return (c, id);
  }

  for (final fault in DiskFault.values) {
    test('a Plan action while Today\'s Close is still being written: the '
        'Pause is refused (${fault.name}); the Close lands and is credited '
        'once, and a restart agrees', () async {
      final (c, id) = await stageStarted();
      final heldClose = h.disk.hold(recommendationPendingWriteKey);
      h.clock.value = morning.add(const Duration(minutes: 25));
      today(c).close();
      await heldClose.reached;
      final heldPause = h.disk.hold(circlePlansKey);
      plans(c).pause('getting_going');
      await heldPause.reached;
      heldClose.release();
      await R8Harness.settle();
      heldPause.release(fault);
      await R8Harness.settle();
      expect((await h.disk.stored())[recommendationStatusKey], 'closed');
      expect(await credits(id), 1);
      await h.restart();
      h.open().read(recommendationProvider);
      await R8Harness.settle();
      expect(await credits(id), 1);
    });
  }

  test('three queued Plan changes, the first two refused, the last landing: '
      'the last carries the first, and confirmed() of the first says done; '
      'a change no save carried says not saved', () async {
    final c = h.open();
    final held = h.disk.hold(circlePlansKey);
    final first = plans(c).confirmed((p) => p.start('getting_going'));
    await held.reached;
    h.disk.fail(circlePlansKey, DiskFault.returnsFalse, times: 2);
    plans(c).keepGentler('getting_going');
    plans(c).stopGentler('getting_going');
    held.release(DiskFault.throws);
    expect(await first, PlanActionResult.done);
    await R8Harness.settle();
    final stored = (await json(circlePlansKey))['plans'] as Map;
    expect((stored['getting_going'] as Map)['lifecycle'], 'active');

    // Every save of a change refused: genuinely not saved.
    h.disk.fail(circlePlansKey, DiskFault.throws);
    expect(
      await plans(c).confirmed((p) => p.pause('getting_going')),
      PlanActionResult.notSaved,
    );
    expect(c.read(circlePlansProvider).active?.planId, 'getting_going');
  });

  test('an answer removal still being written when Delete begins: the '
      'answer never comes back, History is empty, restarts agree', () async {
    final date = morning.subtract(const Duration(days: 3));
    await h.boot({
      circleJournalKey: jsonEncode({
        'schemaVersion': circleJournalSchemaVersion,
        'entries': [
          CircleJournalEntry(
            schemaVersion: circleJournalSchemaVersion,
            circleId: dateKey(date),
            localDate: dateKey(date),
            direction: Intention.clearerHead,
            activityId: ActivityId.values.first,
            catalogVersion: catalogVersion,
            shownAt: date,
            startedAt: date,
            closedAt: date,
            attemptResponse: CircleAttemptResponse.yes,
            usefulnessResponse: CircleUsefulnessResponse.veryUseful,
          ).toJson(),
        ],
      }),
    });
    final c = h.open();
    c.read(recommendationProvider);
    final held = h.disk.hold(circleJournalKey);
    today(c).removeAnswer(dateKey(date), includingAttempt: true);
    await held.reached;
    final deleting = c.read(circleHistoryDeletionProvider).delete();
    await R8Harness.settle();
    held.release();
    await deleting;
    await R8Harness.settle();
    expect((await h.disk.stored()).containsKey(circleJournalKey), isFalse);
    for (var i = 0; i < 2; i++) {
      await h.restart();
      final again = h.open();
      expect(again.read(circleJournalRepositoryProvider).readAll(), isEmpty);
      expect(again.read(insightsProvider).snapshots, isEmpty);
    }
  });

  test('an Insight applied while Delete is under way: nothing it derived is '
      'left after the deletion, and Delete still succeeds', () async {
    final c = h.open();
    plans(c).start('getting_going');
    await R8Harness.settle();
    final held = h.disk.hold(circlePlansKey);
    final deleting = c.read(circleHistoryDeletionProvider).delete();
    await held.reached;
    expect(c.read(insightsProvider.notifier).assess().added, isEmpty);
    unawaited(
      c
          .read(insightsProvider.notifier)
          .apply('missing')
          .then((_) {}, onError: (Object _) {}),
    );
    held.release();
    await deleting;
    await R8Harness.settle();
    expect((await h.disk.stored()).containsKey(insightsKey), isFalse);
    expect(
      (await h.disk.stored()).containsKey(historyDeletionPendingKey),
      isFalse,
    );
  });

  test('a Circle closed after midnight while its Plan is being left, then '
      'its reflection finished and an answer removed: the Close and the '
      'finished reflection stay; the new day opens', () async {
    h.clock.value = DateTime(2026, 10, 12, 23, 30);
    final c = h.open();
    plans(c).start('getting_going');
    today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
    await R8Harness.settle();
    final id = c.read(recommendationProvider).recommendation!.circleId;
    h.clock.value = DateTime(2026, 10, 12, 23, 40);
    today(c).start();
    await R8Harness.settle();
    final held = h.disk.hold(circlePlansKey);
    plans(c).leave('getting_going');
    await held.reached;
    h.clock.value = DateTime(2026, 10, 13, 0, 10);
    today(c).close();
    await R8Harness.settle();
    held.release(DiskFault.returnsFalse);
    await R8Harness.settle();
    today(c).reportAttempt(CircleAttemptResponse.notToday);
    await R8Harness.settle();
    today(c).removeAnswer(id, includingAttempt: true);
    await R8Harness.settle();
    h.clock.value = DateTime(2026, 10, 13, 0, 20);
    await h.restart();
    final again = h.open();
    expect(again.read(recommendationProvider).recommendation, isNull);
    final entry = again
        .read(circleJournalRepositoryProvider)
        .readAll()
        .singleWhere((e) => e.circleId == id);
    expect(entry.closedAt, isNotNull);
    expect(entry.attemptResponse, isNull);
    expect(await credits(id), 1, reason: 'the refused Leave never landed');
  });
}
