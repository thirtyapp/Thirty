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

import '../../support/r83_invariants.dart';
import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// R8.3 — the Start boundary (invariants IV and V).
///
/// - Astra R82-N05: a Start still waiting for its save when local midnight
///   passes must not start yesterday's offer; nothing starts by itself, and
///   the new day opens as it does for a tap after midnight.
/// - Claude AUD-N1 (= Astra R82-N03, end to end): a Start under verified
///   Premium after an earlier Start's expiry note landed must be credited
///   after a restart, as it is without one.
/// - Founder decision D2 (Claude O-3): a Pause before a valid, durably
///   confirmed Start earns no credit. (A later Resume does credit such a
///   Circle — finding R83-F1, reported for a founder decision, reproduced
///   in the R8.3 evidence; not changed here.)
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
  void entitle(ProviderContainer c, EntitlementStatus s) =>
      (c.read(entitlementStatusProvider.notifier) as SettableEntitlement).set(
        s,
      );

  Future<Map<String, Object?>> planOnDisk([
    String planId = 'getting_going',
  ]) async {
    final raw = (await h.disk.stored())[circlePlansKey];
    if (raw is! String) return {};
    final stored = (jsonDecode(raw) as Map)['plans'] as Map?;
    return (stored?[planId] as Map?)?.cast<String, Object?>() ?? {};
  }

  Future<int> creditsOnDisk(String circleId) async {
    final raw = (await h.disk.stored())[circlePlansKey];
    if (raw is! String) return 0;
    var n = 0;
    for (final plan in ((jsonDecode(raw) as Map)['plans'] as Map).values) {
      for (final cycle in ((plan as Map)['cycles'] as List)) {
        for (final r in (cycle as Map)['records'] as List) {
          if ((r as Map)['circleId'] == circleId) n++;
        }
      }
    }
    return n;
  }

  Future<List<String>> invariants() async =>
      DurableState(await h.disk.stored()).always();

  group('R82-N05 — a pending Start does not cross local midnight', () {
    test('a Free offer tapped at 23:59:59 whose save lands after midnight '
        'is not started; the new day opens', () async {
      h.clock.value = DateTime(2026, 10, 30, 23, 59, 59);
      final held = h.disk.hold(recommendationPendingWriteKey);
      final c = h.open(status: EntitlementStatus.inactive);
      today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await held.reached;
      today(c).start();
      await R8Harness.settle();
      expect(
        c.read(recommendationProvider).status,
        RecommendationStatus.notStarted,
      );
      h.clock.value = DateTime(2026, 10, 31, 0, 0, 1);
      held.release();
      await R8Harness.settle();
      final state = c.read(recommendationProvider);
      expect(
        state.status,
        isNot(RecommendationStatus.started),
        reason: 'yesterday\'s offer was still unstarted when midnight passed',
      );
      final stored = await h.disk.stored();
      expect(stored[recommendationStatusKey], isNot('started'));
      expect(stored[recommendationStartedAtKey], isNull);
      expect(state.recommendation?.circleId, isNot('2026-10-30'));
      expect(await invariants(), isEmpty);
      await h.restart();
      final again = h.open(status: EntitlementStatus.inactive);
      expect(
        again.read(recommendationProvider).status,
        isNot(RecommendationStatus.started),
      );
      expect(await invariants(), isEmpty);
    });

    test('a stage Circle whose Start record is still being saved at '
        'midnight is not started, and earns nothing', () async {
      h.clock.value = DateTime(2026, 10, 30, 23, 59);
      final c = h.open();
      expect(plans(c).start('getting_going'), PlanActionResult.done);
      today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await R8Harness.settle();
      final rec = c.read(recommendationProvider).recommendation!;
      expect(rec.composed?.stage, isNotNull);
      // A verified lapse makes the Start record a real Plans write, which
      // the Start waits for.
      entitle(c, EntitlementStatus.inactive);
      final held = h.disk.hold(circlePlansKey);
      today(c).start();
      await held.reached;
      h.clock.value = DateTime(2026, 10, 31, 0, 0, 5);
      held.release();
      await R8Harness.settle();
      expect(
        c.read(recommendationProvider).status,
        isNot(RecommendationStatus.started),
      );
      expect((await h.disk.stored())[recommendationStatusKey], isNot('started'));
      expect(await creditsOnDisk(rec.circleId), 0);
      expect(await invariants(), isEmpty);
    });

    test('control — the same save landing before midnight starts the '
        'Circle, which carries on past midnight', () async {
      h.clock.value = DateTime(2026, 10, 30, 23, 59, 50);
      final held = h.disk.hold(recommendationPendingWriteKey);
      final c = h.open(status: EntitlementStatus.inactive);
      today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await held.reached;
      today(c).start();
      await R8Harness.settle();
      h.clock.value = DateTime(2026, 10, 30, 23, 59, 55);
      held.release();
      await R8Harness.settle();
      expect(
        c.read(recommendationProvider).status,
        RecommendationStatus.started,
      );
      expect((await h.disk.stored())[recommendationStatusKey], 'started');
      h.clock.value = DateTime(2026, 10, 31, 0, 10);
      c.invalidate(nowProvider);
      expect(
        c.read(recommendationProvider).status,
        RecommendationStatus.started,
      );
      expect(await invariants(), isEmpty);
    });
  });

  group('Claude AUD-N1 — an expiry note cleared by a later Start', () {
    test('Start after a verified expiry; the app stops after the Plans note '
        'lands; resubscribed, Start under Premium; Premium lapses and the '
        'app restarts before Close: credited once', () async {
      final c = h.open();
      expect(plans(c).start('getting_going'), PlanActionResult.done);
      today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await R8Harness.settle();
      final id = c.read(recommendationProvider).recommendation!.circleId;
      entitle(c, EntitlementStatus.inactive);
      h.disk.stopAfter = h.disk.log.length + 1;
      today(c).start();
      await R8Harness.settle();
      expect(
        ((await planOnDisk())['lastServed'] as Map)['startedAfterExpiry'],
        true,
      );
      await h.restart();
      final c2 = h.open();
      c2.read(circlePlansProvider);
      expect(
        c2.read(recommendationProvider).status,
        RecommendationStatus.notStarted,
      );
      today(c2).start();
      await R8Harness.settle();
      expect((await h.disk.stored())[recommendationStatusKey], 'started');
      expect(
        ((await planOnDisk())['lastServed'] as Map)['startedAfterExpiry'],
        isNot(true),
        reason: 'the Start under Premium is not what the disk says',
      );
      await h.restart();
      final c3 = h.open(status: EntitlementStatus.inactive);
      c3.read(circlePlansProvider);
      h.clock.value = day1.add(const Duration(minutes: 25));
      today(c3).close();
      await R8Harness.settle();
      expect((await h.disk.stored())[recommendationStatusKey], 'closed');
      expect(await creditsOnDisk(id), 1);
      await h.restart();
      h.open(status: EntitlementStatus.inactive).read(recommendationProvider);
      await R8Harness.settle();
      expect(await creditsOnDisk(id), 1, reason: 'credited twice');
      expect(await invariants(), isEmpty);
    });

    test('control — the same sequence without the last restart is credited '
        'once', () async {
      final c = h.open();
      plans(c).start('getting_going');
      today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await R8Harness.settle();
      final id = c.read(recommendationProvider).recommendation!.circleId;
      entitle(c, EntitlementStatus.inactive);
      h.disk.stopAfter = h.disk.log.length + 1;
      today(c).start();
      await R8Harness.settle();
      await h.restart();
      final c2 = h.open();
      c2.read(circlePlansProvider);
      today(c2).start();
      await R8Harness.settle();
      entitle(c2, EntitlementStatus.inactive);
      h.clock.value = day1.add(const Duration(minutes: 25));
      today(c2).close();
      await R8Harness.settle();
      expect(await creditsOnDisk(id), 1);
    });

    test('control — a Start after a verified expiry, never resubscribed, '
        'earns nothing after a restart', () async {
      final c = h.open();
      plans(c).start('getting_going');
      today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await R8Harness.settle();
      final id = c.read(recommendationProvider).recommendation!.circleId;
      entitle(c, EntitlementStatus.inactive);
      today(c).start();
      await R8Harness.settle();
      expect((await h.disk.stored())[recommendationStatusKey], 'started');
      await h.restart();
      final c2 = h.open(status: EntitlementStatus.inactive);
      c2.read(circlePlansProvider);
      h.clock.value = day1.add(const Duration(minutes: 25));
      today(c2).close();
      await R8Harness.settle();
      expect(await creditsOnDisk(id), 0);
      expect(await invariants(), isEmpty);
    });
  });

  group('founder decision D2 — Pause while a Start is pending', () {
    /// A stage Circle tapped Start while its offer is still being saved;
    /// the Plan is paused before that save lands.
    Future<(ProviderContainer, String)> pausedWhileStartPending() async {
      final c = h.open();
      expect(plans(c).start('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      final held = h.disk.hold(recommendationPendingWriteKey);
      today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await held.reached;
      final id = c.read(recommendationProvider).recommendation!.circleId;
      today(c).start();
      await R8Harness.settle();
      expect(
        c.read(recommendationProvider).status,
        RecommendationStatus.notStarted,
      );
      expect(plans(c).pause('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      held.release();
      await R8Harness.settle();
      return (c, id);
    }

    test('the Circle starts and closes; the Plan stays paused and earns '
        'nothing, also after a restart', () async {
      final (c, id) = await pausedWhileStartPending();
      expect(
        c.read(recommendationProvider).status,
        RecommendationStatus.started,
      );
      expect((await planOnDisk())['lifecycle'], 'paused');
      expect(
        ((await planOnDisk())['lastServed'] as Map?)?['startedBeforePause'],
        isNull,
        reason: 'the Pause came before the valid Start',
      );
      h.clock.value = day1.add(const Duration(minutes: 25));
      today(c).close();
      await R8Harness.settle();
      final journal = c
          .read(circleJournalRepositoryProvider)
          .readAll()
          .firstWhere((e) => e.circleId == id);
      expect(journal.closedAt, isNotNull, reason: 'the Circle itself ran');
      expect(await creditsOnDisk(id), 0);
      await h.restart();
      final again = h.open();
      again.read(recommendationProvider);
      await R8Harness.settle();
      expect(await creditsOnDisk(id), 0);
      expect(again.read(circlePlansProvider).lifecycleOf('getting_going'),
          PlanLifecycle.paused);
      expect(await invariants(), isEmpty);
    });

    test('control — the Plan paused after a valid Start is credited at the '
        'durable Close (lifecycle policy)', () async {
      final c = h.open();
      plans(c).start('getting_going');
      today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await R8Harness.settle();
      final id = c.read(recommendationProvider).recommendation!.circleId;
      today(c).start();
      await R8Harness.settle();
      expect(plans(c).pause('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      h.clock.value = day1.add(const Duration(minutes: 25));
      today(c).close();
      await R8Harness.settle();
      expect(await creditsOnDisk(id), 1);
      expect((await planOnDisk())['lifecycle'], 'paused');
      await h.restart();
      h.open().read(recommendationProvider);
      await R8Harness.settle();
      expect(await creditsOnDisk(id), 1);
    });

    test('control — a Pause whose save is refused while the Start is '
        'pending leaves the Plan active; the Start then credits normally',
        () async {
      final c = h.open();
      plans(c).start('getting_going');
      await R8Harness.settle();
      final held = h.disk.hold(recommendationPendingWriteKey);
      today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await held.reached;
      final id = c.read(recommendationProvider).recommendation!.circleId;
      today(c).start();
      h.disk.fail(circlePlansKey, DiskFault.returnsFalse, times: 1);
      final paused = await plans(c).confirmed((p) => p.pause('getting_going'));
      expect(paused, PlanActionResult.notSaved);
      held.release();
      await R8Harness.settle();
      expect((await planOnDisk())['lifecycle'], 'active');
      h.clock.value = day1.add(const Duration(minutes: 25));
      today(c).close();
      await R8Harness.settle();
      expect(await creditsOnDisk(id), 1);
    });
  });
}
