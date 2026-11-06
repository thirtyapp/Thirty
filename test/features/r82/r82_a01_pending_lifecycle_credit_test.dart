import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';
import 'package:thirty/features/plans/domain/plan_stage_provenance.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// R8.2 — Astra R81-A01 (HIGH): a Plan change still being saved — Pause,
/// Leave — makes the guided credit a no-op on screen. That no-op is not
/// durable completion: until the change lands or is rolled back, the
/// earlier day's credit is unresolved, and the next day's choice never
/// writes over the last recoverable session. Every assertion reads the
/// disk, and the outcome survives repeated restarts.
void main() {
  final day1 = DateTime(2026, 10, 12, 9);
  late R8Harness h;

  setUp(() async {
    h = R8Harness(day1);
    await h.boot();
  });

  RecommendationNotifier today(ProviderContainer c) =>
      c.read(recommendationProvider.notifier);
  CirclePlansNotifier plans(ProviderContainer c) =>
      c.read(circlePlansProvider.notifier);
  void lapse(ProviderContainer c) =>
      (c.read(entitlementStatusProvider.notifier) as SettableEntitlement).set(
        EntitlementStatus.inactive,
      );

  /// The guided records of [circleId] in the Plans JSON on disk.
  Future<int> creditsOnDisk(String circleId) async {
    final raw = (await h.disk.stored())[circlePlansKey];
    if (raw is! String) return 0;
    final stored = (jsonDecode(raw) as Map)['plans'] as Map;
    final plan = stored['getting_going'] as Map?;
    if (plan == null) return 0;
    return [
      for (final cycle in plan['cycles'] as List)
        for (final r in (cycle as Map)['records'] as List)
          if ((r as Map)['circleId'] == circleId) r,
    ].length;
  }

  Future<String?> lifecycleOnDisk() async {
    final raw = (await h.disk.stored())[circlePlansKey];
    if (raw is! String) return null;
    final stored = (jsonDecode(raw) as Map)['plans'] as Map;
    return (stored['getting_going'] as Map?)?['lifecycle'] as String?;
  }

  /// Day 1: a Premium stage Circle served, started and closed — its Start,
  /// Close and History durable — while every Plans write is refused, so its
  /// credit is not on disk (and, RL-1, not on screen). Day 2: Premium has
  /// lapsed and the recovery retry has also been refused. Then the Plans
  /// store heals.
  Future<(ProviderContainer, String)> uncreditedClose(DiskFault fault) async {
    final c = h.open();
    plans(c).start('getting_going');
    today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
    await R8Harness.settle();
    final rec = c.read(recommendationProvider).recommendation!;
    expect(rec.composed?.stage, isNotNull);
    today(c).start();
    await R8Harness.settle();
    h.disk.fail(circlePlansKey, fault);
    h.clock.value = day1.add(const Duration(minutes: 25));
    today(c).close();
    await R8Harness.settle();
    final stored = await h.disk.stored();
    expect(stored[recommendationStatusKey], 'closed');
    expect(await creditsOnDisk(rec.circleId), 0);

    lapse(c);
    h.clock.value = day1.add(const Duration(days: 1));
    c.invalidate(nowProvider);
    c.read(recommendationProvider);
    await R8Harness.settle();
    expect(await creditsOnDisk(rec.circleId), 0, reason: 'retry refused');
    h.disk.healAll();
    expect(c.read(circlePlansProvider).active?.planId, 'getting_going');
    expect(plans(c).hasUnsavedChanges, isFalse);
    return (c, rec.circleId);
  }

  /// Two fresh processes on what reached the disk, Premium lapsed.
  Future<ProviderContainer> restartTwice() async {
    await h.restart();
    h.open(status: EntitlementStatus.inactive).read(recommendationProvider);
    await R8Harness.settle();
    await h.restart();
    final again = h.open(status: EntitlementStatus.inactive);
    again.read(recommendationProvider);
    await R8Harness.settle();
    return again;
  }

  CircleJournalEntry? historyOf(ProviderContainer c, String id) => c
      .read(circleJournalRepositoryProvider)
      .readAll()
      .where((e) => e.circleId == id)
      .firstOrNull;

  for (final fault in DiskFault.values) {
    group('${fault.name}:', () {
      test('A01 as reported — a pending Pause, the next day\'s Free choice, '
          'then the Pause fails: the earlier day\'s credit is saved before '
          'the day keys move on, and survives two restarts', () async {
        final (c, id) = await uncreditedClose(fault);
        final held = h.disk.hold(circlePlansKey);
        expect(plans(c).pause('getting_going'), PlanActionResult.done);
        await held.reached;
        expect(c.read(circlePlansProvider).active, isNull, reason: 'pending');
        today(c).chooseIntention(Intention.gentlerPace);
        await R8Harness.settle();
        expect(
          (await h.disk.stored())[recommendationDayKey],
          id,
          reason:
              'the earlier session was written over while its credit was '
              'blocked by a Plan change still being saved',
        );

        held.release(fault);
        await R8Harness.settle();
        expect(c.read(circlePlansProvider).active?.planId, 'getting_going');
        expect(await creditsOnDisk(id), 1, reason: 'credit resolved');
        final newId = c.read(recommendationProvider).recommendation!.circleId;
        expect((await h.disk.stored())[recommendationDayKey], newId);

        final again = await restartTwice();
        expect(await creditsOnDisk(id), 1);
        expect(historyOf(again, id)?.closedAt, isNotNull);
        expect(again.read(circlePlansProvider).active?.planId, 'getting_going');
      });

      test('a pending Leave, the next day\'s choice, then the Leave fails: '
          'the credit is saved first — never lost to a competing Plan action '
          'that did not land', () async {
        final (c, id) = await uncreditedClose(fault);
        final held = h.disk.hold(circlePlansKey);
        expect(plans(c).leave('getting_going'), PlanActionResult.done);
        await held.reached;
        today(c).chooseIntention(Intention.gentlerPace);
        await R8Harness.settle();
        expect((await h.disk.stored())[recommendationDayKey], id);
        held.release(fault);
        await R8Harness.settle();
        expect(await creditsOnDisk(id), 1);
        expect(await lifecycleOnDisk(), 'active');
        await restartTwice();
        expect(await creditsOnDisk(id), 1);
      });

      // Founder decision A (R8.2 acceptance review, 2026-11-05) replaces the
      // earlier expectation here ("a paused Plan is not credited — nothing
      // is credited later"): a Close durably recorded before the Pause keeps
      // its credit, saved with the Pause itself.
      test('the Pause lands: the Close was durable before it, so its credit '
          'lands with the Pause — once, on the original cycle — the day keys '
          'move on, and the Plan stays paused across two restarts', () async {
        final (c, id) = await uncreditedClose(fault);
        final held = h.disk.hold(circlePlansKey);
        plans(c).pause('getting_going');
        await held.reached;
        today(c).chooseIntention(Intention.gentlerPace);
        await R8Harness.settle();
        held.release();
        await R8Harness.settle();
        expect(await lifecycleOnDisk(), 'paused');
        final newId = c.read(recommendationProvider).recommendation!.circleId;
        expect((await h.disk.stored())[recommendationDayKey], newId);
        expect(await creditsOnDisk(id), 1);
        final again = await restartTwice();
        expect(await creditsOnDisk(id), 1);
        expect(await lifecycleOnDisk(), 'paused');
        expect(historyOf(again, id)?.closedAt, isNotNull);
      });

      test('a restart while the Pause is still pending reads only the disk: '
          'the active Plan is credited from the retained day keys', () async {
        final (c, id) = await uncreditedClose(fault);
        final held = h.disk.hold(circlePlansKey);
        plans(c).pause('getting_going');
        await held.reached;
        today(c).chooseIntention(Intention.gentlerPace);
        await R8Harness.settle();
        expect((await h.disk.stored())[recommendationDayKey], id);
        await h.restart();
        held.release(fault);
        final again = h.open(status: EntitlementStatus.inactive);
        again.read(recommendationProvider);
        await R8Harness.settle();
        expect(await creditsOnDisk(id), 1);
        await restartTwice();
        expect(await creditsOnDisk(id), 1);
      });
    });
  }

  test('the credit itself is refused again after the Pause fails: the day '
      'keys still never move on; once healed, the next write credits '
      'yesterday exactly once, then moves on', () async {
    final (c, id) = await uncreditedClose(DiskFault.returnsFalse);
    final held = h.disk.hold(circlePlansKey);
    plans(c).pause('getting_going');
    await held.reached;
    today(c).chooseIntention(Intention.gentlerPace);
    await R8Harness.settle();
    h.disk.fail(circlePlansKey, DiskFault.throws);
    held.release(DiskFault.returnsFalse);
    await R8Harness.settle();
    expect(await creditsOnDisk(id), 0);
    expect((await h.disk.stored())[recommendationDayKey], id);
    final newId = c.read(recommendationProvider).recommendation!.circleId;
    expect(c.read(journalSaveStatusProvider)[newId], isFalse);

    h.disk.healAll();
    today(c).start();
    await R8Harness.settle();
    expect(await creditsOnDisk(id), 1);
    expect((await h.disk.stored())[recommendationDayKey], newId);
    await restartTwice();
    expect(await creditsOnDisk(id), 1);
  });

  test('domain: a paused or left Plan is never credited — the policy the '
      'notifier distinguishes from a pending change', () {
    final active = CirclePlansState.empty.start(
      'getting_going',
      today: '2026-10-12',
    )!;
    final stage = PlanStageProvenance(
      planId: 'getting_going',
      cycleId: active.plans['getting_going']!.current.id,
      stageNumber: 1,
      stageId: circlePlanById['getting_going']!.stage(1).id,
    );
    CirclePlansState credit(CirclePlansState s) => s.recordGuided(
      stage,
      circleId: '2026-10-12',
      today: '2026-10-12',
      parts: const ['getItOut:6'],
      skipped: const [],
    );
    expect(identical(credit(active), active), isFalse);
    final paused = active.pause('getting_going')!;
    expect(identical(credit(paused), paused), isTrue);
    final left = active.leave('getting_going', today: '2026-10-12')!;
    expect(identical(credit(left), left), isTrue);
  });
}
