import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';

import '../../support/r83_invariants.dart';
import '../../support/r8_harness.dart';

/// R8.3 — cross-store controls the directive (§6) names that no finding
/// covers: a write that lands but whose answer is lost, and the stage-5
/// lifecycle boundaries (Astra: "dedicated boundary test not found"). Each
/// is a control of established behaviour, run through a restart from the
/// stored bytes, with the durable-state oracle.
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

  Future<Map<String, Object?>> planOnDisk() async {
    final raw = (await h.disk.stored())[circlePlansKey];
    if (raw is! String) return {};
    return (((jsonDecode(raw) as Map)['plans'] as Map)['getting_going'] as Map)
        .cast<String, Object?>();
  }

  Future<int> creditsOnDisk(String circleId) async {
    var n = 0;
    for (final cycle in ((await planOnDisk())['cycles'] as List? ?? [])) {
      for (final r in (cycle as Map)['records'] as List) {
        if ((r as Map)['circleId'] == circleId) n++;
      }
    }
    return n;
  }

  Future<List<String>> invariants() async =>
      DurableState(await h.disk.stored()).always();

  group('a Plans credit that lands but whose answer is lost', () {
    Future<(ProviderContainer, String)> startedStageCircle() async {
      final c = h.open();
      plans(c).start('getting_going');
      today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await R8Harness.settle();
      final id = c.read(recommendationProvider).recommendation!.circleId;
      today(c).start();
      await R8Harness.settle();
      return (c, id);
    }

    test('the answer is lost: the credit is resolved on what the disk '
        'holds, and after a restart it is there exactly once', () async {
      final (c, id) = await startedStageCircle();
      h.disk.ackLost(circlePlansKey);
      h.clock.value = day1.add(const Duration(minutes: 25));
      today(c).close();
      await R8Harness.settle();
      expect(h.disk.ackLostLog, isNotEmpty);
      await h.restart();
      h.open().read(recommendationProvider);
      await R8Harness.settle();
      expect(await creditsOnDisk(id), 1);
      await h.restart();
      h.open().read(recommendationProvider);
      await R8Harness.settle();
      expect(await creditsOnDisk(id), 1);
      expect(await invariants(), isEmpty);
    });

    test('the app stops right after the credit lands: after a restart it '
        'is there once, never twice', () async {
      final (c, id) = await startedStageCircle();
      h.disk.ackLost(circlePlansKey, thenStop: true);
      h.clock.value = day1.add(const Duration(minutes: 25));
      today(c).close();
      await R8Harness.settle();
      await h.restart();
      h.open().read(recommendationProvider);
      await R8Harness.settle();
      expect(await creditsOnDisk(id), 1);
      expect(await invariants(), isEmpty);
    });
  });

  group('stage 5 lifecycle boundaries', () {
    /// Runs the Plan day by day until today's stage Circle is stage 5;
    /// returns the open container with that Circle offered, not started.
    Future<ProviderContainer> atStageFive() async {
      var c = h.open();
      plans(c).start('getting_going');
      await R8Harness.settle();
      for (var day = 0; day < 8; day++) {
        today(c).chooseIntention(
          Intention.moreEnergy,
          window: TimeWindow.about20,
        );
        await R8Harness.settle();
        final rec = c.read(recommendationProvider).recommendation!;
        if (rec.composed?.stage?.stageNumber == 5) return c;
        today(c).start();
        await R8Harness.settle();
        today(c).close();
        await R8Harness.settle();
        today(c).reportAttempt(CircleAttemptResponse.yes);
        await R8Harness.settle();
        h.clock.value = h.clock.value.add(const Duration(days: 1));
        await h.restart();
        c = h.open();
        c.read(nowProvider);
      }
      fail('stage 5 was never served');
    }

    test('stage 5 started, Plan paused, Close durable: credited once; the '
        'cycle reaches its end and the Plan ends — never active again',
        () async {
      final c = await atStageFive();
      final id = c.read(recommendationProvider).recommendation!.circleId;
      today(c).start();
      await R8Harness.settle();
      expect(plans(c).pause('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      h.clock.value = h.clock.value.add(const Duration(minutes: 25));
      today(c).close();
      await R8Harness.settle();
      expect(await creditsOnDisk(id), 1);
      final plan = await planOnDisk();
      expect(plan['lifecycle'], 'ended');
      expect(((plan['cycles'] as List).last as Map)['end'], 'reachedEnd');
      await h.restart();
      final again = h.open();
      again.read(recommendationProvider);
      await R8Harness.settle();
      expect(await creditsOnDisk(id), 1);
      expect(
        again.read(circlePlansProvider).lifecycleOf('getting_going'),
        PlanLifecycle.ended,
      );
      expect(await invariants(), isEmpty);
    });

    test('stage 5 Close asked for, the Plan left while that Close is still '
        'being saved: credited to the left cycle once; it stays left',
        () async {
      final c = await atStageFive();
      final id = c.read(recommendationProvider).recommendation!.circleId;
      today(c).start();
      await R8Harness.settle();
      final held = h.disk.hold(circleJournalKey);
      h.clock.value = h.clock.value.add(const Duration(minutes: 25));
      today(c).close();
      await held.reached;
      expect(plans(c).leave('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      held.release();
      await R8Harness.settle();
      expect(await creditsOnDisk(id), 1);
      final plan = await planOnDisk();
      expect(plan['lifecycle'], 'left');
      expect(((plan['cycles'] as List).last as Map)['end'], 'left');
      await h.restart();
      h.open().read(recommendationProvider);
      await R8Harness.settle();
      expect(await creditsOnDisk(id), 1);
      expect((await planOnDisk())['lifecycle'], 'left');
      expect(await invariants(), isEmpty);
    });
  });
}
