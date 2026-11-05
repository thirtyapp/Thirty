import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/storage/store_save_failures.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// R8.1 — Astra N01 (HIGH) / Claude AUD-1 (MEDIUM): a Plan credit that is
/// only in memory never satisfies the durable-credit prerequisite, so the
/// next day's choice never writes over the last recoverable evidence of the
/// earlier Circle. Every assertion reads the disk, not only the cache.
void main() {
  final day1 = DateTime(2026, 10, 12, 9);
  late R8Harness h;

  setUp(() async {
    h = R8Harness(day1);
    await h.boot();
  });

  RecommendationNotifier today(ProviderContainer c) =>
      c.read(recommendationProvider.notifier);

  /// The guided records of [circleId] in the Plans JSON on disk.
  Future<int> creditsOnDisk(String circleId) async {
    final raw = (await h.disk.stored())[circlePlansKey];
    if (raw is! String) return 0;
    final plans = (jsonDecode(raw) as Map)['plans'] as Map;
    final plan = plans['getting_going'] as Map?;
    if (plan == null) return 0;
    return [
      for (final cycle in plan['cycles'] as List)
        for (final r in (cycle as Map)['records'] as List)
          if ((r as Map)['circleId'] == circleId) r,
    ].length;
  }

  int creditsInMemory(ProviderContainer c, String circleId) => c
      .read(circlePlansProvider)
      .plans['getting_going']!
      .cycles
      .expand((cy) => cy.records)
      .where((r) => r.circleId == circleId)
      .length;

  /// A Premium stage Circle served and started on day 1 — durably.
  Future<(ProviderContainer, String)> stageStarted() async {
    final c = h.open();
    c.read(circlePlansProvider.notifier).start('getting_going');
    today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
    await R8Harness.settle();
    final rec = c.read(recommendationProvider).recommendation!;
    expect(rec.composed?.stage, isNotNull);
    today(c).start();
    await R8Harness.settle();
    expect((await h.disk.stored())[recommendationStatusKey], 'started');
    return (c, rec.circleId);
  }

  void lapse(ProviderContainer c) =>
      (c.read(entitlementStatusProvider.notifier) as SettableEntitlement).set(
        EntitlementStatus.inactive,
      );

  for (final fault in DiskFault.values) {
    group('${fault.name}:', () {
      test('AUD-1 as reported — Plans store failing across a restart; the '
          'next day\'s choice never overwrites the closed stage Circle whose '
          'credit is only in memory; after healing the credit is recovered '
          'exactly once', () async {
        final (c, id) = await stageStarted();
        h.disk.fail(circlePlansKey, fault);
        h.clock.value = day1.add(const Duration(minutes: 25));
        today(c).close();
        await R8Harness.settle();
        expect(await creditsOnDisk(id), 0, reason: 'the credit write failed');

        // Next day, restart; Plans still refusing; History fine.
        h.clock.value = day1.add(const Duration(days: 1));
        await h.restart(keepFaults: true);
        final next = h.open();
        next.read(recommendationProvider);
        await R8Harness.settle();
        today(next).chooseIntention(Intention.gentlerPace);
        await R8Harness.settle();
        final stored = await h.disk.stored();
        expect(
          stored[recommendationDayKey],
          id,
          reason: 'day keys overwritten while the credit was only in memory',
        );
        expect(stored[recommendationStatusKey], 'closed');

        // Storage healed; restart: recovered from the retained day keys.
        h.disk.healAll();
        await h.restart();
        final healed = h.open();
        healed.read(recommendationProvider);
        await R8Harness.settle();
        expect(await creditsOnDisk(id), 1);
        expect(creditsInMemory(healed, id), 1);
        expect(
          healed
              .read(circleJournalRepositoryProvider)
              .readAll()
              .where((e) => e.circleId == id)
              .single
              .closedAt,
          isNotNull,
        );

        // Duplicate guard: more restarts and the new day's choice never
        // credit it twice.
        await h.restart();
        final again = h.open();
        again.read(recommendationProvider);
        await R8Harness.settle();
        today(again).chooseIntention(Intention.gentlerPace);
        await R8Harness.settle();
        await h.restart();
        h.open().read(recommendationProvider);
        await R8Harness.settle();
        expect(await creditsOnDisk(id), 1);
      });

      test(
        'Astra N01 as reported — only the credit write fails at Close; '
        'Premium lapses; same session, next day, a Free choice: the '
        'credit is retried and durable before the day keys move on',
        () async {
          final (c, id) = await stageStarted();
          h.disk.fail(circlePlansKey, fault, times: 1);
          h.clock.value = day1.add(const Duration(minutes: 25));
          today(c).close();
          await R8Harness.settle();
          expect(await creditsOnDisk(id), 0);
          // R8.1 RL-1 (founder decision 2026-11-05): the refused credit is
          // not kept on screen as if saved; the failure is told.
          expect(creditsInMemory(c, id), 0, reason: 'unsaved credit on screen');
          expect(c.read(storeSaveFailuresProvider).count, greaterThan(0));
          expect(
            c.read(storeSaveFailuresProvider).unsaved,
            contains(UserStore.circlePlans),
          );

          lapse(c);
          h.clock.value = day1.add(const Duration(days: 1));
          c.invalidate(nowProvider);
          expect(c.read(recommendationProvider).recommendation, isNull);
          expect(c.read(premiumEntitlementProvider), isFalse);
          today(c).chooseIntention(Intention.gentlerPace);
          await R8Harness.settle();

          expect(await creditsOnDisk(id), 1, reason: 'credit retried first');
          final stored = await h.disk.stored();
          expect(stored[recommendationDayKey], isNot(id));
          expect(c.read(storeSaveFailuresProvider).unsaved, isEmpty);

          // Restart from the disk: the credit is there, once.
          await h.restart();
          final again = h.open(status: EntitlementStatus.inactive);
          again.read(recommendationProvider);
          await R8Harness.settle();
          expect(creditsInMemory(again, id), 1);
          expect(await creditsOnDisk(id), 1);
        },
      );

      test(
        'Plans store failing persistently in the same session: the next '
        'day\'s Free choice is not saved over yesterday; once the store '
        'heals, the next write credits yesterday and then moves on',
        () async {
          final (c, id) = await stageStarted();
          h.disk.fail(circlePlansKey, fault);
          h.clock.value = day1.add(const Duration(minutes: 25));
          today(c).close();
          await R8Harness.settle();

          lapse(c);
          h.clock.value = day1.add(const Duration(days: 1));
          c.invalidate(nowProvider);
          today(c).chooseIntention(Intention.gentlerPace);
          await R8Harness.settle();
          var stored = await h.disk.stored();
          expect(stored[recommendationDayKey], id);
          expect(stored[recommendationStatusKey], 'closed');
          final newId = c.read(recommendationProvider).recommendation!.circleId;
          expect(newId, isNot(id));
          expect(c.read(journalSaveStatusProvider)[newId], isFalse);

          // Healed: the next write of today's Circle (its Start) publishes.
          h.disk.healAll();
          today(c).start();
          await R8Harness.settle();
          expect(await creditsOnDisk(id), 1);
          stored = await h.disk.stored();
          expect(stored[recommendationDayKey], newId);
          expect(stored[recommendationStatusKey], 'started');
        },
      );

      test('the served-stage Start evidence already noted in memory but not '
          'on disk is written again — never treated as saved because memory '
          'holds it', () async {
        final c = h.open();
        c.read(circlePlansProvider.notifier).start('getting_going');
        today(
          c,
        ).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
        await R8Harness.settle();
        final rec = c.read(recommendationProvider).recommendation!;
        lapse(c);
        h.disk.fail(circlePlansKey, fault, times: 1);
        final plans = c.read(circlePlansProvider.notifier);
        await expectLater(
          plans.noteStart(rec.composed!.stage!, circleId: rec.circleId),
          throwsA(anything),
        );
        // In memory it is noted; the same call again must save it.
        await plans.noteStart(rec.composed!.stage!, circleId: rec.circleId);
        final raw = (await h.disk.stored())[circlePlansKey]! as String;
        expect(raw, contains('"startedAfterExpiry":true'));
      });
    });
  }
}
