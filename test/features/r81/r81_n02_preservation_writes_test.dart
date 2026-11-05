import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_history_deletion.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// R8.1 — Astra N02 (HIGH): a copy of an unreadable Plans or Insights
/// record, begun when the store is first read, is a pending platform write
/// — its value is in the SharedPreferences cache before the disk has it.
/// It never counts as a confirmed preserved copy, and it can never land
/// after a successful Delete Circle history.
///
/// The [FaultDisk.hold] latch holds exactly that platform write; no other
/// operation is held.
void main() {
  final morning = DateTime(2026, 10, 12, 9);
  late R8Harness h;

  setUp(() => h = R8Harness(morning));

  const plansRaw = '{"schemaVersion":1,"plans":"not a map — damaged"}';
  const insightsRaw = '{not json at all';

  /// Each store: its keys, its seed, and a mutation that writes it whole.
  final stores =
      <
        String,
        (String, String, String, Future<void> Function(ProviderContainer))
      >{
        'Plans': (
          circlePlansKey,
          circlePlansUnreadableKey,
          plansRaw,
          (c) async {
            c.read(circlePlansProvider.notifier).start('getting_going');
          },
        ),
        'Insights': (
          insightsKey,
          insightsUnreadableKey,
          insightsRaw,
          (c) async {
            c.read(insightsProvider.notifier).assess();
          },
        ),
      };

  for (final MapEntry(key: name, value: (mainKey, asideKey, raw, mutate))
      in stores.entries) {
    for (final fault in DiskFault.values) {
      test('$name — reproduction A: the build\'s copy is pending when a save '
          'follows; the copy then ${fault.name}: the original is never '
          'written over unkept — on disk, after a restart', () async {
        await h.boot({mainKey: raw, circleJournalKey: _i4Journal(morning)});
        final held = h.disk.hold(asideKey);
        final c = h.open(status: EntitlementStatus.active);
        c.read(circlePlansProvider);
        c.read(insightsProvider);
        await held.reached;
        expect(h.prefs.get(asideKey), raw, reason: 'cache shows the copy');
        await mutate(c);
        await R8Harness.settle();
        held.release(fault);
        await R8Harness.settle();

        await h.restart();
        final stored = await h.disk.stored();
        expect(
          stored[mainKey] == raw || stored[asideKey] == raw,
          isTrue,
          reason: 'the unreadable original is gone from the disk',
        );
      });
    }

    test('$name — the copy failing every time: the original stays exactly '
        'as stored, and nothing is written over it', () async {
      await h.boot({mainKey: raw, circleJournalKey: _i4Journal(morning)});
      h.disk.fail(asideKey, DiskFault.returnsFalse);
      final c = h.open(status: EntitlementStatus.active);
      c.read(circlePlansProvider);
      c.read(insightsProvider);
      await mutate(c);
      await R8Harness.settle();
      final stored = await h.disk.stored();
      expect(stored[mainKey], raw);
      expect(stored.containsKey(asideKey), isFalse);
    });

    test('$name — retries are idempotent: a copy that lands, then a restart '
        'and another save, leaves one copy, byte for byte', () async {
      await h.boot({mainKey: raw, circleJournalKey: _i4Journal(morning)});
      final c = h.open(status: EntitlementStatus.active);
      c.read(circlePlansProvider);
      c.read(insightsProvider);
      await R8Harness.settle();
      await mutate(c);
      await R8Harness.settle();
      await h.restart();
      final again = h.open(status: EntitlementStatus.active);
      again.read(circlePlansProvider);
      again.read(insightsProvider);
      await mutate(again);
      await R8Harness.settle();
      expect((await h.disk.stored())[asideKey], raw);
    });
  }

  test('reproduction B — both copies pending when Delete Circle history '
      'runs: Delete completes only after them, and no raw retained evidence '
      'is on disk afterwards', () async {
    await h.boot({
      circlePlansKey: plansRaw,
      insightsKey: insightsRaw,
      circleJournalKey: _i4Journal(morning),
    });
    final plansCopy = h.disk.hold(circlePlansUnreadableKey);
    final insightsCopy = h.disk.hold(insightsUnreadableKey);
    final c = h.open();
    c.read(circlePlansProvider);
    c.read(insightsProvider);
    await plansCopy.reached;
    await insightsCopy.reached;

    var done = false;
    Object? error;
    final deleting = c
        .read(circleHistoryDeletionProvider)
        .delete()
        .then((_) => done = true, onError: (Object e) => error = e);
    await R8Harness.settle();
    // The delayed copies reach the disk only now.
    plansCopy.release();
    insightsCopy.release();
    await deleting;
    await R8Harness.settle();
    expect(error, isNull);
    expect(done, isTrue);

    final stored = await h.disk.stored();
    expect(stored.containsKey(circlePlansUnreadableKey), isFalse);
    expect(stored.containsKey(insightsUnreadableKey), isFalse);
    expect(stored.containsKey(historyDeletionPendingKey), isFalse);
    expect(stored.containsKey(circleJournalKey), isFalse);
    await h.restart();
    final after = await h.disk.stored();
    expect(after.containsKey(circlePlansUnreadableKey), isFalse);
    expect(after.containsKey(insightsUnreadableKey), isFalse);
  });

  test('reproduction B, the copy failing as Delete runs: Delete still '
      'completes and nothing is left behind', () async {
    await h.boot({circlePlansKey: plansRaw});
    final copy = h.disk.hold(circlePlansUnreadableKey);
    final c = h.open();
    c.read(circlePlansProvider);
    await copy.reached;
    final deleting = c.read(circleHistoryDeletionProvider).delete();
    await R8Harness.settle();
    copy.release(DiskFault.throws);
    await deleting;
    await R8Harness.settle();
    final stored = await h.disk.stored();
    expect(stored.containsKey(circlePlansUnreadableKey), isFalse);
    expect(stored.containsKey(historyDeletionPendingKey), isFalse);
  });
}

/// A journal from which, with Premium, Insights generate an Insight 4.
String _i4Journal(DateTime morning) {
  CirclePart part(ElementId e) => CirclePart(e, elementOf(e).minutes);
  final writing = [
    part(ElementId.closeWhatsOpen),
    part(ElementId.getItOut),
    part(ElementId.chooseOne),
    part(ElementId.firstStep),
  ];
  final reading = [part(ElementId.phoneFaceDown), part(ElementId.readPages)];
  CircleJournalEntry entry(int ago, List<CirclePart> parts, bool useful) {
    final date = morning.subtract(Duration(days: ago));
    return CircleJournalEntry(
      schemaVersion: circleJournalSchemaVersion,
      circleId: dateKey(date),
      localDate: dateKey(date),
      direction: Intention.clearerHead,
      activityId: ActivityId.values.first,
      catalogVersion: catalogVersion,
      shownAt: date,
      startedAt: date,
      closedAt: date,
      attemptResponse: useful ? CircleAttemptResponse.yes : null,
      usefulnessResponse: useful ? CircleUsefulnessResponse.veryUseful : null,
      session: CircleSessionRecord(
        title: 'Circle',
        parts: CirclePlan(parts).toWire(),
      ),
    );
  }

  return jsonEncode({
    'schemaVersion': circleJournalSchemaVersion,
    'entries': [
      for (final ago in [1, 7, 13, 20]) entry(ago, writing, true).toJson(),
      for (final ago in [3, 9, 16]) entry(ago, reading, false).toJson(),
    ],
  });
}
