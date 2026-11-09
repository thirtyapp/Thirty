import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/storage/store_save_failures.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_history_deletion.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';

import '../../support/r83_invariants.dart';
import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// R8.3.1 — founder decision on R83-F1 (2026-11-07, Option B): historical
/// Plan credit depends on the eligibility of the Circle's original valid
/// Start, with the durable Close and entitlement rules. A Circle started
/// while its Plan was paused never earns Plan credit — not at its Close,
/// and not later, whatever lifecycle change, restart or catch-up follows.
/// Its Circle History record stays.
///
/// One test per row of the founder's table, then the required variants:
/// persisted state and restart, pending and failed writes, a lapse and
/// resubscription, a second Plan, stage 5, the next day's catch-up, at
/// most one credit, the record itself and Delete.
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

  Future<bool> closedInHistory(String circleId) async {
    final raw = (await h.disk.stored())[circleJournalKey];
    if (raw is! String) return false;
    return ((jsonDecode(raw) as Map)['entries'] as List).any(
      (e) => (e as Map)['circleId'] == circleId && e['closedAt'] != null,
    );
  }

  Future<List<String>> invariants() async =>
      DurableState(await h.disk.stored()).always();

  /// A restart that lets Today's catch-up run, [times] times.
  Future<ProviderContainer> restart({int times = 1}) async {
    late ProviderContainer c;
    for (var i = 0; i < times; i++) {
      await h.restart();
      c = h.open();
      c.read(circlePlansProvider);
      c.read(recommendationProvider);
      await R8Harness.settle();
    }
    return c;
  }

  /// getting_going started and today's stage Circle offered and saved.
  Future<(ProviderContainer, String)> offered() async {
    final c = h.open();
    expect(plans(c).start('getting_going'), PlanActionResult.done);
    today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
    await R8Harness.settle();
    final rec = c.read(recommendationProvider).recommendation!;
    expect(rec.composed?.stage, isNotNull);
    return (c, rec.circleId);
  }

  Future<void> act(ProviderContainer c, String step) async {
    switch (step) {
      case 'Start':
        today(c).start();
      case 'Pause':
        expect(plans(c).pause('getting_going'), PlanActionResult.done);
      case 'Resume':
        expect(plans(c).resume('getting_going'), PlanActionResult.done);
      case 'Leave':
        expect(plans(c).leave('getting_going'), PlanActionResult.done);
      case 'Close':
        h.clock.value = h.clock.value.add(const Duration(minutes: 25));
        today(c).close();
      default:
        fail('unknown step $step');
    }
    await R8Harness.settle();
  }

  group('the founder\'s table', () {
    final rows = <(List<String>, int)>[
      (['Start', 'Close'], 1),
      (['Start', 'Pause', 'Close'], 1),
      (['Start', 'Pause', 'Resume', 'Close'], 1),
      (['Pause', 'Start', 'Close'], 0),
      (['Pause', 'Start', 'Resume', 'Close'], 0),
      (['Pause', 'Start', 'Close', 'Resume'], 0),
      (['Pause', 'Start', 'Close', 'Resume', 'Pause'], 0),
      (['Start', 'Leave', 'Close'], 0),
      (['Start'], 0),
    ];
    for (final (steps, credit) in rows) {
      test('${steps.join(' → ')}: ${credit == 1 ? 'credited once' : 'no '
          'Plan credit'}, also after two restarts', () async {
        final (c, id) = await offered();
        for (final step in steps) {
          await act(c, step);
        }
        expect(await creditsOnDisk(id), credit, reason: 'in the session');
        if (steps.contains('Close')) {
          expect(await closedInHistory(id), isTrue,
              reason: 'the Close is kept in History');
        }
        await restart(times: 2);
        expect(await creditsOnDisk(id), credit, reason: 'after restarts');
        expect(await invariants(), isEmpty);
      });
    }

    test('Start → Close requested → Leave while it is being saved: the '
        'original cycle credited once, after the Close is durable', () async {
      final (c, id) = await offered();
      await act(c, 'Start');
      final held = h.disk.hold(circleJournalKey);
      h.clock.value = h.clock.value.add(const Duration(minutes: 25));
      today(c).close();
      await held.reached;
      expect(plans(c).leave('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      expect(await creditsOnDisk(id), 0, reason: 'not before it is durable');
      held.release();
      await R8Harness.settle();
      expect(await creditsOnDisk(id), 1);
      expect((await planOnDisk())['lifecycle'], 'left');
      await restart(times: 2);
      expect(await creditsOnDisk(id), 1);
    });

    test('Close never durable: no credit, also after a restart and Resume',
        () async {
      final (c, id) = await offered();
      await act(c, 'Start');
      h.disk.fail(recommendationPendingWriteKey, DiskFault.returnsFalse);
      await act(c, 'Close');
      expect(await creditsOnDisk(id), 0);
      final again = await restart();
      expect(
        again.read(recommendationProvider).status,
        isNot(RecommendationStatus.closed),
      );
      expect(await creditsOnDisk(id), 0);
    });
  });

  group('a Start while paused stays without credit', () {
    test('Start tapped while its offer is being saved, Plan paused, the '
        'Start becomes valid, Close, Resume, restarts: never credited',
        () async {
      final c = h.open();
      plans(c).start('getting_going');
      await R8Harness.settle();
      final held = h.disk.hold(recommendationPendingWriteKey);
      today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await held.reached;
      final id = c.read(recommendationProvider).recommendation!.circleId;
      today(c).start();
      await R8Harness.settle();
      await act(c, 'Pause');
      held.release();
      await R8Harness.settle();
      // R8.3.2 (founder decision on N01-C, 2026-11-07): a lifecycle change
      // while a Start is unresolved cancels that Start; the user taps
      // Start again. Before it, the pending Start went ahead.
      expect(
        c.read(recommendationProvider).status,
        RecommendationStatus.notStarted,
      );
      await act(c, 'Start');
      expect(
        c.read(recommendationProvider).status,
        RecommendationStatus.started,
      );
      await act(c, 'Close');
      await act(c, 'Resume');
      await restart(times: 2);
      expect(await creditsOnDisk(id), 0);
      expect(await closedInHistory(id), isTrue);
    });

    test('the next day: Resume and a new choice catch up yesterday\'s '
        'Circle — it stays without credit, and today\'s Circle earns its '
        'stage', () async {
      final (c, id) = await offered();
      await act(c, 'Pause');
      await act(c, 'Start');
      await act(c, 'Close');
      h.clock.value = day1.add(const Duration(days: 1));
      final c2 = await restart();
      await act(c2, 'Resume');
      today(c2).chooseIntention(
        Intention.moreEnergy,
        window: TimeWindow.about20,
      );
      await R8Harness.settle();
      final next = c2.read(recommendationProvider).recommendation!;
      expect(next.circleId, isNot(id));
      expect(await creditsOnDisk(id), 0, reason: 'caught up the next day');
      await act(c2, 'Start');
      await act(c2, 'Close');
      expect(await creditsOnDisk(next.circleId), 1);
      await restart(times: 2);
      expect(await creditsOnDisk(id), 0);
      expect(await creditsOnDisk(next.circleId), 1);
      expect(await invariants(), isEmpty);
    });

    test('the Start\'s record that it was made while paused is refused by '
        'the store: the Start is refused and the user told; tapped again, '
        'it starts — and is never credited', () async {
      final (c, id) = await offered();
      await act(c, 'Pause');
      h.disk.fail(circlePlansKey, DiskFault.returnsFalse, times: 1);
      await act(c, 'Start');
      expect(
        c.read(recommendationProvider).status,
        RecommendationStatus.notStarted,
        reason: 'started without its eligibility on disk',
      );
      expect(c.read(storeSaveFailuresProvider).last, UserStore.todaysCircle);
      expect((await h.disk.stored())[recommendationStatusKey],
          isNot('started'));
      await act(c, 'Start');
      expect(
        c.read(recommendationProvider).status,
        RecommendationStatus.started,
      );
      await act(c, 'Close');
      await act(c, 'Resume');
      await restart(times: 2);
      expect(await creditsOnDisk(id), 0);
    });

    test('Premium lapsed while paused, Start, Close; resubscribed, Resume, '
        'restarts: never credited', () async {
      final (c, id) = await offered();
      await act(c, 'Pause');
      entitle(c, EntitlementStatus.inactive);
      await act(c, 'Start');
      await act(c, 'Close');
      final c2 = await restart();
      await act(c2, 'Resume');
      await restart(times: 2);
      expect(await creditsOnDisk(id), 0);
    });

    test('control — Start under Premium, lapse, Close: credited once (the '
        'served exception)', () async {
      final (c, id) = await offered();
      await act(c, 'Start');
      entitle(c, EntitlementStatus.inactive);
      await act(c, 'Close');
      expect(await creditsOnDisk(id), 1);
      await restart(times: 2);
      expect(await creditsOnDisk(id), 1);
    });

    test('a second Plan started before this Circle\'s Start pauses this '
        'Plan: no credit, also once this Plan is carried on again', () async {
      final (c, id) = await offered();
      expect(plans(c).start('making_room'), PlanActionResult.done);
      await R8Harness.settle();
      await act(c, 'Start');
      await act(c, 'Close');
      expect(plans(c).start('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      await restart(times: 2);
      expect(await creditsOnDisk(id), 0);
      expect((await planOnDisk('making_room'))['lifecycle'], 'paused');
    });

    test('control — a second Plan started after this Circle\'s Start: this '
        'Plan is credited once, the other stays active', () async {
      final (c, id) = await offered();
      await act(c, 'Start');
      expect(plans(c).start('making_room'), PlanActionResult.done);
      await R8Harness.settle();
      await act(c, 'Close');
      expect(await creditsOnDisk(id), 1);
      expect((await planOnDisk('making_room'))['lifecycle'], 'active');
      await restart(times: 2);
      expect(await creditsOnDisk(id), 1);
    });

    test('at most once: Start, Pause, Close, Resume, three restarts — one '
        'credit', () async {
      final (c, id) = await offered();
      for (final step in ['Start', 'Pause', 'Close', 'Resume']) {
        await act(c, step);
      }
      await restart(times: 3);
      expect(await creditsOnDisk(id), 1);
    });
  });

  group('stage 5', () {
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

    test('Pause, stage 5 started and closed: the Plan stays paused, its '
        'cycle not ended — and carrying on never ends it', () async {
      final c = await atStageFive();
      final id = c.read(recommendationProvider).recommendation!.circleId;
      await act(c, 'Pause');
      await act(c, 'Start');
      await act(c, 'Close');
      expect(await creditsOnDisk(id), 0);
      expect((await planOnDisk())['lifecycle'], 'paused');
      final c2 = await restart();
      await act(c2, 'Resume');
      await restart(times: 2);
      expect(await creditsOnDisk(id), 0);
      final plan = await planOnDisk();
      expect(plan['lifecycle'], 'active');
      expect(((plan['cycles'] as List).last as Map)['end'], isNull);
    });
  });

  group('the record of a Start made while paused', () {
    const stage = <String, Object?>{
      'planId': 'getting_going',
      'cycleId': 'getting_going#1',
      'stageNumber': 1,
      'stageId': 'getting_going.1',
    };

    Map<String, Object?> storedPlans(Object? startedWhilePaused) {
      final s = CirclePlansState.empty.start(
        'getting_going',
        today: '2026-10-12',
      )!;
      final json = jsonDecode(jsonEncode(s.toJson())) as Map<String, Object?>;
      final plan = (json['plans'] as Map)['getting_going'] as Map;
      plan['lastServed'] = {'circleId': '2026-10-12', 'stage': stage};
      plan['startedWhilePaused'] = startedWhilePaused;
      plan['futurePlanField'] = 'kept';
      return json;
    }

    test('stored, it is honoured: an active Plan does not credit that '
        'Circle; a save writes it back with the unknown fields', () {
      final read = CirclePlansState.fromJson(storedPlans('2026-10-12'))!;
      final provenance = read.plans['getting_going']!.lastServed!.stage;
      final after = read.recordGuided(
        provenance,
        circleId: '2026-10-12',
        today: '2026-10-12',
        parts: const [],
        skipped: const [],
      );
      expect(identical(after, read), isTrue, reason: 'credited');
      final out = jsonDecode(jsonEncode(read.pause('getting_going')!.toJson()))
          as Map;
      final plan = (out['plans'] as Map)['getting_going'] as Map;
      expect(plan['startedWhilePaused'], '2026-10-12');
      expect(plan['futurePlanField'], 'kept');
    });

    test('control — another Circle is credited as before', () {
      final read = CirclePlansState.fromJson(storedPlans('2026-10-11'))!;
      final provenance = read.plans['getting_going']!.lastServed!.stage;
      final after = read.recordGuided(
        provenance,
        circleId: '2026-10-12',
        today: '2026-10-12',
        parts: const [],
        skipped: const [],
      );
      expect(identical(after, read), isFalse);
    });

    test('damaged, it is never read as absent: the Plan is kept as stored '
        'and runs nothing', () {
      final read = CirclePlansState.fromJson(storedPlans(42))!;
      expect(read.plans.containsKey('getting_going'), isFalse);
      expect(read.unreadablePlans.containsKey('getting_going'), isTrue);
    });

    test('Delete Circle history removes it with the other stage evidence',
        () async {
      final (c, _) = await offered();
      await act(c, 'Pause');
      await act(c, 'Start');
      await c.read(circleHistoryDeletionProvider).delete();
      await R8Harness.settle();
      expect((await planOnDisk()).containsKey('startedWhilePaused'), isFalse);
      expect((await planOnDisk())['lifecycle'], 'paused');
      expect(DurableState(await h.disk.stored()).deletionResidue(), isEmpty);
    });
  });
}
