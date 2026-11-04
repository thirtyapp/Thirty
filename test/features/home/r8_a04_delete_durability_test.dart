import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_history_deletion.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// Audit remediation R8 — Astra R7-A04 (HIGH): Delete Circle history
/// completes only when every removal is confirmed. The intent is on disk
/// before anything is removed; it stays until every store is cleared; a
/// failed Delete never looks complete, is finished on the next start, and
/// nothing deleted comes back — not through a write already queued.
void main() {
  final morning = DateTime(2026, 10, 12, 9);
  late R8Harness h;

  setUp(() async {
    h = R8Harness(morning);
    await h.boot();
  });

  ProviderContainer open() => h.open(status: EntitlementStatus.active);

  /// A day with history: a closed Circle in the journal and day keys, and a
  /// Plan with stage evidence.
  Future<ProviderContainer> withHistory() async {
    final c = open();
    c.read(circlePlansProvider.notifier).start('getting_going');
    final today = c.read(recommendationProvider.notifier);
    today.chooseIntention(Intention.moreEnergy);
    await R8Harness.settle();
    today.start();
    await R8Harness.settle();
    h.clock.value = morning.add(const Duration(minutes: 25));
    today.close();
    await R8Harness.settle();
    expect(c.read(circleJournalRepositoryProvider).readAll(), isNotEmpty);
    return c;
  }

  Future<Object?> deleting(ProviderContainer c) async {
    try {
      await c.read(circleHistoryDeletionProvider).delete();
      return null;
    } catch (error) {
      return error;
    }
  }

  Future<bool> historyOnDisk() async {
    final stored = await h.disk.stored();
    return stored.containsKey(circleJournalKey) ||
        stored.containsKey(recommendationDayKey);
  }

  Future<void> expectGoneAfterRestart() async {
    await h.restart();
    final again = open();
    again.read(recommendationProvider);
    await R8Harness.settle();
    expect(again.read(circleJournalRepositoryProvider).readAll(), isEmpty);
    expect(again.read(recommendationProvider).recommendation, isNull);
    expect(await historyOnDisk(), isFalse);
    expect(
      (await h.disk.stored()).containsKey(historyDeletionPendingKey),
      isFalse,
    );
  }

  for (final fault in DiskFault.values) {
    group('a removal that ${fault.name}', () {
      test('the journal\'s: Delete fails — never complete; the intent stays '
          'on disk; the next start finishes it', () async {
        final c = await withHistory();
        h.disk.fail(circleJournalKey, fault);
        final error = await deleting(c);
        expect(error, isNotNull, reason: 'Delete looked complete');
        final stored = await h.disk.stored();
        expect(stored[historyDeletionPendingKey], isTrue);
        expect(c.read(circleHistoryDeletionProvider).isPending, isTrue);
        await expectGoneAfterRestart();
      });

      test('a day key\'s: Delete fails; the intent stays', () async {
        final c = await withHistory();
        h.disk.fail(recommendationStatusKey, fault);
        expect(await deleting(c), isNotNull);
        expect((await h.disk.stored())[historyDeletionPendingKey], isTrue);
        await expectGoneAfterRestart();
      });

      test(
        'the Plans\' stage evidence write: Delete fails; the intent stays',
        () async {
          final c = await withHistory();
          h.disk.fail(circlePlansKey, fault);
          expect(await deleting(c), isNotNull);
          expect((await h.disk.stored())[historyDeletionPendingKey], isTrue);
        },
      );

      test('the intent itself: nothing is removed before it is on disk, and '
          'Delete fails', () async {
        final c = await withHistory();
        final before = h.disk.attempts.length;
        h.disk.fail(historyDeletionPendingKey, fault);
        expect(await deleting(c), isNotNull);
        expect(
          await historyOnDisk(),
          isTrue,
          reason: 'history removed with no durable intent',
        );
        final removals = h.disk.attempts
            .skip(before)
            .where((a) => a.startsWith('remove '));
        expect(
          removals.where((a) => !a.endsWith(historyDeletionPendingKey)),
          isEmpty,
        );
      });

      test('the start-up completion\'s: it fails, and the intent stays for '
          'the next start', () async {
        final c = await withHistory();
        h.disk.fail(circleJournalKey, fault);
        await deleting(c);
        // Next start, the disk still refusing the journal.
        await h.restart(keepFaults: true);
        final stored = await h.disk.stored();
        expect(stored[historyDeletionPendingKey], isTrue);
        expect(stored.containsKey(circleJournalKey), isTrue);
        h.disk.healAll();
        await expectGoneAfterRestart();
      });
    });
  }

  test('a failed Delete: a write queued before it never brings anything '
      'back, through the failure and the next start', () async {
    final c = await withHistory();
    h.disk.fail(circleJournalKey, DiskFault.returnsFalse, times: 1);
    final today = c.read(recommendationProvider.notifier);
    today.reportAttempt(CircleAttemptResponse.yes);
    final error = await deleting(c);
    await R8Harness.settle();
    expect(error, isNotNull);
    await expectGoneAfterRestart();
  });

  test('Delete repeated: the second finds nothing and succeeds; history '
      'stays deleted', () async {
    final c = await withHistory();
    expect(await deleting(c), isNull);
    expect(await deleting(c), isNull);
    await expectGoneAfterRestart();
  });

  test('preserved copies of a journal THIRTY couldn\'t read are deleted '
      'with it, and their removal is confirmed too', () async {
    await h.boot({
      circleJournalKey: '{not a journal',
      circleJournalPreservedKey: ['{older'],
    });
    final c = open();
    h.disk.fail(circleJournalPreservedKey, DiskFault.returnsFalse, times: 1);
    expect(await deleting(c), isNotNull);
    expect((await h.disk.stored())[historyDeletionPendingKey], isTrue);
    await h.restart();
    final stored = await h.disk.stored();
    expect(stored.containsKey(circleJournalKey), isFalse);
    expect(stored.containsKey(circleJournalPreservedKey), isFalse);
  });

  test('Insights\' removal refused: Delete fails; the intent stays', () async {
    final c = await withHistory();
    c.read(insightsProvider);
    h.disk.fail(insightsUnreadableKey, DiskFault.returnsFalse);
    expect(await deleting(c), isNotNull);
    expect((await h.disk.stored())[historyDeletionPendingKey], isTrue);
  });
}
