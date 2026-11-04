import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// Audit remediation R8 — Astra R7-A01 (HIGH, daily persistence failures)
/// with Astra R7-A05 (MEDIUM, Close recovered without its Start) and Claude
/// F-5 (LOW, a failed History save shown as saved).
///
/// Today's Circle on the real SharedPreferences over a disk whose writes can
/// throw or return `false`. Every case checks what the user sees, what is in
/// memory, what is on the disk and what a restart brings back.
void main() {
  final morning = DateTime(2026, 10, 12, 9);
  late R8Harness h;
  final circleId = dateKey(morning);

  setUp(() async {
    h = R8Harness(morning);
    await h.boot();
  });

  ProviderContainer open() => h.open(status: EntitlementStatus.inactive);
  RecommendationNotifier today(ProviderContainer c) =>
      c.read(recommendationProvider.notifier);
  CircleJournalEntry? entry(ProviderContainer c) => c
      .read(circleJournalRepositoryProvider)
      .readAll()
      .where((e) => e.circleId == circleId)
      .firstOrNull;
  bool? saved(ProviderContainer c) =>
      c.read(journalSaveStatusProvider)[circleId];

  Future<ProviderContainer> chosen() async {
    final c = open();
    today(c).chooseIntention(Intention.moreEnergy);
    await R8Harness.settle();
    return c;
  }

  Future<ProviderContainer> reopen() async {
    await h.restart();
    final c = open();
    c.read(recommendationProvider);
    await R8Harness.settle();
    return c;
  }

  for (final fault in DiskFault.values) {
    group('a day-key write at Start that ${fault.name}', () {
      test('is shown as not saved; the recovery record stays on disk; a '
          'restart restores the started Circle, and History agrees', () async {
        final c = await chosen();
        h.disk.fail(recommendationStatusKey, fault);
        today(c).start();
        await R8Harness.settle();

        expect(saved(c), isFalse, reason: 'the failure must reach the user');
        final stored = await h.disk.stored();
        expect(
          stored.containsKey(recommendationPendingWriteKey),
          isTrue,
          reason: 'recovery information removed before the write completed',
        );

        final again = await reopen();
        expect(
          again.read(recommendationProvider).status,
          RecommendationStatus.started,
        );
        expect(entry(again)?.startedAt, isNotNull);
      });
    });

    test('the recovery record itself refused (${fault.name}): nothing else '
        'of the write lands, the failure is shown, and History never runs '
        'ahead of the day keys', () async {
      final c = await chosen();
      h.disk.fail(recommendationPendingWriteKey, fault);
      today(c).start();
      await R8Harness.settle();

      expect(saved(c), isFalse);
      final stored = await h.disk.stored();
      expect(stored[recommendationStatusKey], 'notStarted');
      expect(stored.containsKey(recommendationStartedAtKey), isFalse);

      final again = await reopen();
      final state = again.read(recommendationProvider);
      expect(state.status, RecommendationStatus.notStarted);
      expect(state.recommendation?.circleId, circleId);
      expect(entry(again)?.startedAt, isNull);
    });

    test('a choice whose day key didn\'t land (${fault.name}): the Start '
        'after it still writes today\'s Circle — never skipped while History '
        'moves on', () async {
      final c = open();
      h.disk.fail(recommendationDayKey, fault, times: 1);
      today(c).chooseIntention(Intention.moreEnergy);
      await R8Harness.settle();
      final offered = c.read(recommendationProvider).recommendation!;
      today(c).start();
      await R8Harness.settle();

      final stored = await h.disk.stored();
      expect(stored[recommendationDayKey], circleId);
      expect(stored[recommendationStatusKey], 'started');

      final again = await reopen();
      final state = again.read(recommendationProvider);
      expect(state.status, RecommendationStatus.started);
      expect(state.recommendation?.activityId, offered.activityId);
      expect(entry(again)?.activityId, offered.activityId);
      expect(entry(again)?.startedAt, isNotNull);
    });

    test('History refuses the save (${fault.name}): History and the Circles '
        'THIRTY learns from read what is on disk — nothing unsaved is shown '
        'as saved (Claude F-5)', () async {
      h.disk.fail(circleJournalKey, fault);
      final c = await chosen();

      expect(saved(c), isFalse);
      expect(entry(c), isNull, reason: 'unsaved record visible in memory');
      expect(c.read(pastCirclesProvider), isEmpty);
      expect((await h.disk.stored()).containsKey(circleJournalKey), isFalse);
      // The Circle itself is still today's.
      expect(c.read(recommendationProvider).recommendation, isNotNull);

      h.disk.heal(circleJournalKey);
      today(c).start();
      await R8Harness.settle();
      expect(saved(c), isTrue);
      expect(entry(c)?.startedAt, isNotNull);
    });

    test('Start\'s History write lost (${fault.name}), Close recovered after '
        'a restart: the record carries the Start the durable day keys hold — '
        'never a Close without its Start (Astra R7-A05)', () async {
      final c = await chosen();
      h.disk.fail(circleJournalKey, fault);
      today(c).start();
      await R8Harness.settle();
      final startedAt = c.read(recommendationProvider).startedAt!;
      h.clock.value = morning.add(const Duration(minutes: 25));
      today(c).close();
      await R8Harness.settle();

      final again = await reopen();
      final record = entry(again)!;
      expect(record.startedAt, startedAt);
      expect(record.closedAt, isNotNull);
      expect(
        again.read(circleJournalRepositoryProvider).readAll(),
        hasLength(1),
      );
    });

    test('Start\'s History write lost (${fault.name}) once, Close saved in the '
        'same session: one record, with its Start', () async {
      final c = await chosen();
      h.disk.fail(circleJournalKey, fault, times: 1);
      today(c).start();
      await R8Harness.settle();
      final startedAt = c.read(recommendationProvider).startedAt!;
      h.clock.value = morning.add(const Duration(minutes: 25));
      today(c).close();
      await R8Harness.settle();

      expect(entry(c)?.startedAt, startedAt);
      expect(entry(c)?.closedAt, isNotNull);
      final again = await reopen();
      expect(entry(again)?.startedAt, startedAt);
      expect(
        again.read(circleJournalRepositoryProvider).readAll(),
        hasLength(1),
      );
    });
  }

  test('a failed write is retried by the next one, exactly once: the day '
      'keys and History end in one Circle, started and closed', () async {
    final c = await chosen();
    h.disk.fail(recommendationStatusKey, DiskFault.returnsFalse, times: 1);
    today(c).start();
    await R8Harness.settle();
    h.clock.value = morning.add(const Duration(minutes: 25));
    today(c).close();
    await R8Harness.settle();

    expect(saved(c), isTrue);
    final stored = await h.disk.stored();
    expect(stored[recommendationStatusKey], 'closed');
    expect(stored.containsKey(recommendationPendingWriteKey), isFalse);
    final again = await reopen();
    expect(
      again.read(recommendationProvider).status,
      RecommendationStatus.closed,
    );
    final all = again.read(circleJournalRepositoryProvider).readAll();
    expect(all, hasLength(1));
    expect(all.single.startedAt, isNotNull);
    expect(all.single.closedAt, isNotNull);
  });
}
