import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// R8.1 — Astra N03 (HIGH): an answer the user removed from History is
/// never written back from the day's recovery keys — same day, next day
/// before a new Circle is chosen, across restarts and when the removal is
/// cut short. Removing it never invents or reverses anything else.
void main() {
  final day1 = DateTime(2026, 10, 12, 9);
  late R8Harness h;

  setUp(() async {
    h = R8Harness(day1);
    await h.boot();
  });

  RecommendationNotifier today(ProviderContainer c) =>
      c.read(recommendationProvider.notifier);

  /// [id]'s record in the journal on disk.
  Future<Map<String, Object?>?> onDisk(String id) async {
    final raw = (await h.disk.stored())[circleJournalKey];
    if (raw is! String) return null;
    for (final e in (jsonDecode(raw) as Map)['entries'] as List) {
      if ((e as Map)['circleId'] == id) return e.cast<String, Object?>();
    }
    return null;
  }

  /// Day 1: a Free Circle started, closed and answered — durably.
  Future<String> answeredDay1() async {
    final c = h.open(status: EntitlementStatus.inactive);
    today(c).chooseIntention(Intention.moreEnergy);
    await R8Harness.settle();
    final id = c.read(recommendationProvider).recommendation!.circleId;
    today(c).start();
    await R8Harness.settle();
    h.clock.value = day1.add(const Duration(minutes: 25));
    today(c).close();
    today(c).reportAttempt(CircleAttemptResponse.yes);
    today(c).reportUsefulness(CircleUsefulnessResponse.notUseful);
    await R8Harness.settle();
    expect((await onDisk(id))!['usefulnessResponse'], isNotNull);
    return id;
  }

  Future<ProviderContainer> nextDay({bool restart = true}) async {
    h.clock.value = day1.add(const Duration(days: 1));
    if (restart) await h.restart();
    final c = h.open(status: EntitlementStatus.inactive);
    expect(c.read(recommendationProvider).recommendation, isNull);
    await R8Harness.settle();
    return c;
  }

  Future<void> expectRemoved(
    String id, {
    required bool attemptToo,
    ProviderContainer? c,
  }) async {
    final e = (await onDisk(id))!;
    expect(e['usefulnessResponse'], isNull, reason: 'usefulness came back');
    if (attemptToo) expect(e['attemptResponse'], isNull);
    expect(e['closedAt'], isNotNull, reason: 'the Circle itself stays');
    if (c != null) {
      final past = c
          .read(pastCirclesProvider)
          .where((p) => p.date.day == day1.day);
      expect(past.single.usefulness, isNull, reason: 'future picks use it');
    }
  }

  for (final attemptToo in [false, true]) {
    final what = attemptToo ? 'both answers' : 'the usefulness answer';

    test('next day, before a new Circle is chosen: $what removed, then a '
        'restart — never written back', () async {
      final id = await answeredDay1();
      final c = await nextDay();
      today(c).removeAnswer(id, includingAttempt: attemptToo);
      await R8Harness.settle();
      await expectRemoved(id, attemptToo: attemptToo, c: c);

      await h.restart();
      final again = h.open(status: EntitlementStatus.inactive);
      again.read(recommendationProvider);
      await R8Harness.settle();
      await expectRemoved(id, attemptToo: attemptToo, c: again);
    });

    test(
      'next day, before a new Circle is chosen: $what removed, then the '
      'day\'s choice (before-overwrite recording) — never written back',
      () async {
        final id = await answeredDay1();
        final c = await nextDay();
        today(c).removeAnswer(id, includingAttempt: attemptToo);
        await R8Harness.settle();
        today(c).chooseIntention(Intention.gentlerPace);
        await R8Harness.settle();
        await expectRemoved(id, attemptToo: attemptToo, c: c);
        expect((await h.disk.stored())[recommendationDayKey], isNot(id));
      },
    );

    test('next day in the same session (no restart): $what removed, then a '
        'choice and a restart — never written back', () async {
      final id = await answeredDay1();
      final c = h.open(status: EntitlementStatus.inactive);
      c.read(recommendationProvider);
      h.clock.value = day1.add(const Duration(days: 1));
      c.invalidate(nowProvider);
      expect(c.read(recommendationProvider).recommendation, isNull);
      today(c).removeAnswer(id, includingAttempt: attemptToo);
      await R8Harness.settle();
      today(c).chooseIntention(Intention.gentlerPace);
      await R8Harness.settle();
      await h.restart();
      final again = h.open(status: EntitlementStatus.inactive);
      again.read(recommendationProvider);
      await R8Harness.settle();
      await expectRemoved(id, attemptToo: attemptToo, c: again);
    });

    test(
      'same day: $what removed, then a restart — never written back',
      () async {
        final id = await answeredDay1();
        final c = h.open(status: EntitlementStatus.inactive);
        expect(
          c.read(recommendationProvider).status,
          RecommendationStatus.closed,
        );
        today(c).removeAnswer(id, includingAttempt: attemptToo);
        await R8Harness.settle();
        await h.restart();
        final again = h.open(status: EntitlementStatus.inactive);
        again.read(recommendationProvider);
        await R8Harness.settle();
        await expectRemoved(id, attemptToo: attemptToo, c: again);
        expect(again.read(recommendationProvider).usefulnessResponse, isNull);
      },
    );
  }

  for (final fault in DiskFault.values) {
    test('next day, the removal cut short — the day keys\' write '
        '${fault.name}: History keeps the answer (nothing half-removed), '
        'the user is told, and a retry removes it for good', () async {
      final id = await answeredDay1();
      final c = await nextDay();
      h.disk.fail(recommendationPendingWriteKey, fault, times: 1);
      today(c).removeAnswer(id, includingAttempt: false);
      await R8Harness.settle();
      expect((await onDisk(id))!['usefulnessResponse'], 'notUseful');
      expect(c.read(journalSaveStatusProvider)[id], isFalse);

      today(c).removeAnswer(id, includingAttempt: false);
      await R8Harness.settle();
      await expectRemoved(id, attemptToo: false);
      await h.restart();
      h.open(status: EntitlementStatus.inactive).read(recommendationProvider);
      await R8Harness.settle();
      await expectRemoved(id, attemptToo: false);
    });

    test(
      'next day, History\'s removal ${fault.name} after the day keys '
      'were cleared: the answer stays in History and is reported; a '
      'restart neither loses nor duplicates it; a retry removes it',
      () async {
        final id = await answeredDay1();
        final c = await nextDay();
        h.disk.fail(circleJournalKey, fault, times: 1);
        today(c).removeAnswer(id, includingAttempt: false);
        await R8Harness.settle();
        expect((await onDisk(id))!['usefulnessResponse'], 'notUseful');
        expect(c.read(journalSaveStatusProvider)[id], isFalse);

        await h.restart();
        final again = h.open(status: EntitlementStatus.inactive);
        again.read(recommendationProvider);
        await R8Harness.settle();
        expect((await onDisk(id))!['usefulnessResponse'], 'notUseful');
        today(again).removeAnswer(id, includingAttempt: false);
        await R8Harness.settle();
        await expectRemoved(id, attemptToo: false, c: again);
      },
    );
  }

  test('an answer never given is never invented by a removal, and other '
      'Circles\' answers are untouched', () async {
    final id = await answeredDay1();
    final c = await nextDay();
    today(c).chooseIntention(Intention.gentlerPace);
    await R8Harness.settle();
    final id2 = c.read(recommendationProvider).recommendation!.circleId;
    today(c).start();
    h.clock.value = day1.add(const Duration(days: 1, minutes: 25));
    today(c).close();
    await R8Harness.settle();
    today(c).removeAnswer(id, includingAttempt: true);
    await R8Harness.settle();
    await expectRemoved(id, attemptToo: true);
    final e2 = (await onDisk(id2))!;
    expect(e2['attemptResponse'], isNull);
    expect(e2['usefulnessResponse'], isNull);
    expect(e2['closedAt'], isNotNull);
  });
}
