import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/storage/store_save_failures.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_history_deletion.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// R8.2 founder decision B (acceptance review, 2026-11-05) — a failed save
/// during Start. A Circle enters the started state only once its own first
/// publication — today's offer in the day keys and, for a stage Circle, the
/// Plan's served record and record of the Start — is confirmed on disk.
/// If that fails the Start is refused: the Circle stays as it was, the user
/// is told, and Start can be tapped again. A Circle validly started never
/// disappears because of a later Plan failure, and nothing of a refused
/// Start — no Start, Close or credit — is ever recorded.
void main() {
  final morning = DateTime(2026, 10, 30, 9);
  late R8Harness h;

  setUp(() async {
    h = R8Harness(morning);
    await h.boot();
  });

  RecommendationNotifier today(ProviderContainer c) =>
      c.read(recommendationProvider.notifier);
  CirclePlansNotifier plans(ProviderContainer c) =>
      c.read(circlePlansProvider.notifier);
  RecommendationStatus status(ProviderContainer c) =>
      c.read(recommendationProvider).status;

  CircleJournalEntry? historyOf(ProviderContainer c, String id) => c
      .read(circleJournalRepositoryProvider)
      .readAll()
      .where((e) => e.circleId == id)
      .firstOrNull;

  Future<String?> statusOnDisk() async =>
      (await h.disk.stored())[recommendationStatusKey] as String?;

  /// Nothing of a Start is on disk for [id].
  Future<void> noStartRecorded(String id) async {
    final stored = await h.disk.stored();
    expect(stored[recommendationStatusKey], isNot('started'));
    expect(stored[recommendationStartedAtKey], isNull);
    final raw = stored[circleJournalKey];
    if (raw is String) {
      final entries = (jsonDecode(raw) as Map)['entries'] as List;
      for (final e in entries) {
        if ((e as Map)['circleId'] == id) expect(e['startedAt'], isNull);
      }
    }
  }

  /// A Free Circle chosen today (no Plan involved).
  Future<(ProviderContainer, String)> freeChoice() async {
    final c = h.open(status: EntitlementStatus.inactive);
    today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
    final id = c.read(recommendationProvider).recommendation!.circleId;
    return (c, id);
  }

  group('pending writes', () {
    test('Start tapped while the offer is still being saved: not started '
        'until the store confirms it, then started and saved', () async {
      final held = h.disk.hold(recommendationPendingWriteKey);
      final (c, id) = await freeChoice();
      await held.reached;
      today(c).start();
      await R8Harness.settle();
      expect(status(c), RecommendationStatus.notStarted);
      await noStartRecorded(id);
      held.release();
      await R8Harness.settle();
      expect(status(c), RecommendationStatus.started);
      expect(await statusOnDisk(), 'started');
      expect(historyOf(c, id)?.startedAt, isNotNull);
    });

    test('a stage Circle tapped while its Plan save is pending: started '
        'only once the served stage is on disk', () async {
      final c = h.open();
      final held = h.disk.hold(circlePlansKey);
      plans(c).start('getting_going');
      await held.reached;
      today(
        c,
      ).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      final rec = c.read(recommendationProvider).recommendation!;
      expect(rec.composed?.stage, isNotNull);
      today(c).start();
      await R8Harness.settle();
      expect(status(c), RecommendationStatus.notStarted);
      held.release();
      await R8Harness.settle();
      expect(status(c), RecommendationStatus.started);
      expect(await statusOnDisk(), 'started');
      expect(
        plans(c).confirmedState.wasServed(
          rec.composed!.stage!,
          circleId: rec.circleId,
        ),
        isTrue,
      );
    });

    test('fast repeated taps while pending start the Circle once', () async {
      final held = h.disk.hold(recommendationPendingWriteKey);
      final (c, id) = await freeChoice();
      await held.reached;
      for (var i = 0; i < 5; i++) {
        today(c).start();
      }
      held.release();
      await R8Harness.settle();
      expect(status(c), RecommendationStatus.started);
      final startedAt = c.read(recommendationProvider).startedAt;
      for (var i = 0; i < 3; i++) {
        today(c).start();
      }
      await R8Harness.settle();
      expect(c.read(recommendationProvider).startedAt, startedAt);
      expect(historyOf(c, id)?.startedAt, isNotNull);
    });
  });

  for (final fault in DiskFault.values) {
    group('${fault.name}:', () {
      test('the offer was never saved: Start is refused with the user told, '
          'nothing is recorded; tapped again once the store heals, it '
          'starts and saves', () async {
        h.disk.fail(recommendationPendingWriteKey, fault);
        final (c, id) = await freeChoice();
        await R8Harness.settle();
        final before = c.read(storeSaveFailuresProvider).count;
        today(c).start();
        await R8Harness.settle();
        expect(status(c), RecommendationStatus.notStarted);
        expect(c.read(recommendationProvider).recommendation?.circleId, id);
        expect(c.read(storeSaveFailuresProvider).count, before + 1);
        expect(
          c.read(storeSaveFailuresProvider).unsaved.map((s) => s.name),
          contains('todaysCircle'),
        );
        await noStartRecorded(id);

        // Each refused Start is told.
        today(c).start();
        await R8Harness.settle();
        expect(status(c), RecommendationStatus.notStarted);
        expect(c.read(storeSaveFailuresProvider).count, before + 2);

        h.disk.healAll();
        today(c).start();
        await R8Harness.settle();
        expect(status(c), RecommendationStatus.started);
        expect(await statusOnDisk(), 'started');
        expect((await h.disk.stored())[recommendationDayKey], id);
        expect(historyOf(c, id)?.startedAt, isNotNull);
        expect(
          c.read(storeSaveFailuresProvider).unsaved.map((s) => s.name),
          isNot(contains('todaysCircle')),
        );
      });

      test('the pending offer write fails while Start waits: the Start is '
          'refused, never started', () async {
        final held = h.disk.hold(recommendationPendingWriteKey);
        final (c, id) = await freeChoice();
        await held.reached;
        today(c).start();
        h.disk.fail(recommendationPendingWriteKey, fault);
        held.release(fault);
        await R8Harness.settle();
        expect(status(c), RecommendationStatus.notStarted);
        await noStartRecorded(id);
        // Told once: the offer's own failed save raised History's notice
        // during this Start, so the refusal adds no second one.
        expect(c.read(journalSaveStatusProvider)[id], isFalse);
        expect(c.read(storeSaveFailuresProvider).count, 0);
        expect(
          c.read(storeSaveFailuresProvider).unsaved.map((s) => s.name),
          contains('todaysCircle'),
        );
        // The next refusal is told by its own notice.
        today(c).start();
        await R8Harness.settle();
        expect(status(c), RecommendationStatus.notStarted);
        expect(c.read(storeSaveFailuresProvider).count, 1);
      });

      test('a stage Circle whose Start record the Plans store refuses (a '
          'verified expiry since it was served): refused, then started on '
          'the retry with its record saved first', () async {
        final c = h.open();
        plans(c).start('getting_going');
        today(
          c,
        ).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
        await R8Harness.settle();
        final id = c.read(recommendationProvider).recommendation!.circleId;
        (c.read(entitlementStatusProvider.notifier) as SettableEntitlement)
            .set(EntitlementStatus.inactive);
        h.disk.fail(circlePlansKey, fault);
        today(c).start();
        await R8Harness.settle();
        expect(status(c), RecommendationStatus.notStarted);
        expect(c.read(recommendationProvider).recommendation?.circleId, id);
        await noStartRecorded(id);
        expect(
          (await h.disk.stored())[circlePlansKey],
          isNot(contains('"startedAfterExpiry":true')),
        );

        h.disk.healAll();
        today(c).start();
        await R8Harness.settle();
        expect(status(c), RecommendationStatus.started);
        expect(await statusOnDisk(), 'started');
        expect(
          (await h.disk.stored())[circlePlansKey],
          contains('"startedAfterExpiry":true'),
        );
      });

      test('restart after a refused Start: nothing was started, and the '
          'offer on disk starts normally', () async {
        final c = h.open();
        plans(c).start('getting_going');
        today(
          c,
        ).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
        await R8Harness.settle();
        final id = c.read(recommendationProvider).recommendation!.circleId;
        (c.read(entitlementStatusProvider.notifier) as SettableEntitlement)
            .set(EntitlementStatus.inactive);
        h.disk.fail(circlePlansKey, fault);
        today(c).start();
        await R8Harness.settle();
        await h.restart();
        final again = h.open(status: EntitlementStatus.inactive);
        expect(again.read(recommendationProvider).recommendation?.circleId, id);
        expect(status(again), RecommendationStatus.notStarted);
        await noStartRecorded(id);
        today(again).start();
        await R8Harness.settle();
        expect(status(again), RecommendationStatus.started);
        expect(await statusOnDisk(), 'started');
      });

      test('a Plan action after a confirmed Start fails: the started Circle '
          'stays, closes and is saved; its credit catches up later', () async {
        final c = h.open();
        plans(c).start('getting_going');
        today(
          c,
        ).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
        await R8Harness.settle();
        final id = c.read(recommendationProvider).recommendation!.circleId;
        today(c).start();
        expect(status(c), RecommendationStatus.started, reason: 'fast path');
        await R8Harness.settle();
        expect(await statusOnDisk(), 'started');

        h.disk.fail(circlePlansKey, fault);
        plans(c).pause('getting_going');
        await R8Harness.settle();
        plans(c).keepGentler('getting_going');
        await R8Harness.settle();
        plans(c).leave('getting_going');
        await R8Harness.settle();
        expect(c.read(circlePlansProvider).active?.planId, 'getting_going');
        expect(status(c), RecommendationStatus.started);
        expect(c.read(recommendationProvider).recommendation?.circleId, id);

        h.clock.value = morning.add(const Duration(minutes: 25));
        today(c).close();
        await R8Harness.settle();
        expect(status(c), RecommendationStatus.closed);
        expect(await statusOnDisk(), 'closed');
        expect(historyOf(c, id)?.closedAt, isNotNull);

        h.disk.healAll();
        await h.restart();
        final again = h.open();
        again.read(recommendationProvider);
        await R8Harness.settle();
        expect(
          plans(again).isCreditedDurably('getting_going', circleId: id),
          isTrue,
        );
      });
    });
  }

  test('after Delete Circle history, the same offer chosen again but not '
      'saved is never taken as saved: its Start is refused', () async {
    final (c, id) = await freeChoice();
    await R8Harness.settle();
    expect((await h.disk.stored())[recommendationDayKey], id);
    await c.read(circleHistoryDeletionProvider).delete();
    await R8Harness.settle();
    expect(c.read(recommendationProvider).recommendation, isNull);
    h.disk.fail(recommendationPendingWriteKey, DiskFault.returnsFalse);
    today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
    await R8Harness.settle();
    expect(c.read(recommendationProvider).recommendation?.circleId, id);
    today(c).start();
    await R8Harness.settle();
    expect(status(c), RecommendationStatus.notStarted);
    await noStartRecorded(id);
  });

  test('a Free Circle whose offer is already saved starts at once', () async {
    final (c, _) = await freeChoice();
    await R8Harness.settle();
    today(c).start();
    expect(status(c), RecommendationStatus.started);
  });
}
