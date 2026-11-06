import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/home/application/circle_history_deletion.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';
import 'package:thirty/features/plans/domain/plan_stage_provenance.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// R8.2 — Astra R81-A02 (HIGH) and Claude NEW-2: a Delete Circle history
/// that reports success leaves nothing derived from the deleted evidence —
/// no Plan review, no Insight snapshot — whatever runs during it: an
/// Insight assessment, a write captured before it, a failed Delete followed
/// by a rollback, or a later unrelated write. Every assertion reads the
/// disk, then fresh processes.
void main() {
  final morning = DateTime(2026, 10, 30, 9);
  const plan = 'making_room';
  late R8Harness h;

  PlanStageProvenance stage(int n) => PlanStageProvenance(
    planId: plan,
    cycleId: '$plan#1',
    stageNumber: n,
    stageId: '$plan.$n',
  );

  /// A cycle guided through stage 5 by Circles `2026-10-1n`: its review is
  /// what an Insight 5 refers to.
  String completedPlans() {
    var s = CirclePlansState.empty.start(plan, today: '2026-10-10')!;
    for (var n = 1; n <= 5; n++) {
      s = s.recordGuided(
        stage(n),
        circleId: '2026-10-1$n',
        today: '2026-10-1$n',
        parts: const ['getItOut:6'],
        skipped: const [],
      );
    }
    expect(s.plans[plan]!.current.hasReview, isTrue);
    return jsonEncode(s.toJson());
  }

  setUp(() async {
    h = R8Harness(morning);
    await h.boot({circlePlansKey: completedPlans()});
  });

  InsightsNotifier insights(ProviderContainer c) =>
      c.read(insightsProvider.notifier);
  CircleHistoryDeletion deletion(ProviderContainer c) =>
      c.read(circleHistoryDeletionProvider);

  /// Nothing on disk derived from the deleted cycle: no Insight snapshot,
  /// and the Plan's stage evidence gone.
  Future<void> nothingDerivedOnDisk() async {
    final stored = await h.disk.stored();
    final rawInsights = stored[insightsKey];
    if (rawInsights is String) {
      final snapshots = (jsonDecode(rawInsights) as Map)['snapshots'] as List?;
      expect(snapshots ?? const [], isEmpty, reason: 'deleted Insight data');
    }
    final rawPlans = stored[circlePlansKey]! as String;
    for (final id in ['2026-10-11', '2026-10-13', '2026-10-15']) {
      expect(rawPlans, isNot(contains(id)), reason: 'deleted stage evidence');
    }
    expect(stored.containsKey(historyDeletionPendingKey), isFalse);
  }

  Future<void> restartsShowNothingDeleted() async {
    for (var i = 0; i < 2; i++) {
      await h.restart();
      final again = h.open();
      expect(again.read(insightsProvider).snapshots, isEmpty);
      insights(again).assess();
      await R8Harness.settle();
      expect(again.read(insightsProvider).snapshots, isEmpty);
      expect(
        again.read(circlePlansProvider).plans[plan]!.current.records,
        isEmpty,
      );
      await nothingDerivedOnDisk();
    }
  }

  test('A02 as reported — Insights opened while Delete waits for the Plan '
      'evidence write: no review is recreated, and Delete succeeds with '
      'nothing derived left on disk or after restarts', () async {
    final c = h.open();
    final review = insights(c).assess().added.single;
    expect(review.family, InsightFamily.planReview);
    await R8Harness.settle();
    expect((await h.disk.stored())[insightsKey], contains(review.id));

    final held = h.disk.hold(circlePlansKey);
    final deleted = deletion(c).delete();
    await held.reached;
    expect(c.read(insightsProvider).snapshots, isEmpty);
    final during = insights(c).assess();
    expect(
      during.added,
      isEmpty,
      reason: 'an Insight generated from evidence being deleted',
    );
    held.release();
    await deleted;
    await R8Harness.settle();
    expect(c.read(insightsProvider).snapshots, isEmpty);
    await nothingDerivedOnDisk();
    await restartsShowNothingDeleted();
  });

  test('NEW-2 — an assessment queued during Delete whose payload lands only '
      'after the deletion is never written', () async {
    final c = h.open();
    final heldPlans = h.disk.hold(circlePlansKey);
    final deleted = deletion(c).delete();
    await heldPlans.reached;
    // Generated now, its save queued behind Delete's own Insights removal.
    insights(c).assess();
    heldPlans.release();
    await deleted;
    await R8Harness.settle();
    await nothingDerivedOnDisk();
    await restartsShowNothingDeleted();
  });

  test('a stale Insight payload captured before Delete and still being '
      'written lands before the deletion, never after it', () async {
    final c = h.open();
    final heldInsights = h.disk.hold(insightsKey);
    final review = insights(c).assess().added.single;
    await heldInsights.reached;
    final deleted = deletion(c).delete();
    await R8Harness.settle();
    heldInsights.release();
    await deleted;
    await R8Harness.settle();
    expect((await h.disk.stored())[insightsKey], isNot(contains(review.id)));
    await nothingDerivedOnDisk();
    await restartsShowNothingDeleted();
  });

  for (final fault in DiskFault.values) {
    group('${fault.name}:', () {
      test('Delete whose Plan evidence write fails, then an unrelated Plan '
          'action that also fails: the screen never goes back to the '
          'deleted evidence, and no later write republishes it', () async {
        final c = h.open();
        h.disk.fail(circlePlansKey, fault, times: 1);
        await expectLater(deletion(c).delete(), throwsA(anything));
        expect(
          c.read(circlePlansProvider).plans[plan]!.current.records,
          isEmpty,
        );
        expect(deletion(c).isPending, isTrue);

        h.disk.fail(circlePlansKey, fault, times: 1);
        c.read(circlePlansProvider.notifier).start('getting_going');
        await R8Harness.settle();
        expect(
          c.read(circlePlansProvider).plans[plan]!.current.records,
          isEmpty,
          reason: 'rolled back to the pre-delete Plans',
        );
        expect(
          insights(c).assess().added,
          isEmpty,
          reason: 'an Insight from deleted evidence during a pending Delete',
        );

        // An unrelated write that lands must not carry the evidence back.
        c.read(circlePlansProvider.notifier).start('getting_going');
        await R8Harness.settle();
        final raw = (await h.disk.stored())[circlePlansKey]! as String;
        expect(raw, isNot(contains('2026-10-13')));

        await deletion(c).resolvePending();
        await R8Harness.settle();
        await nothingDerivedOnDisk();
        await restartsShowNothingDeleted();
      });

      test('Delete whose Insights removal fails, then a failing Insights '
          'save: the deleted snapshots are never shown or saved again',
          () async {
        final c = h.open();
        final review = insights(c).assess().added.single;
        await R8Harness.settle();
        // Both the Plan evidence write and the Insights removal fail.
        h.disk.fail(circlePlansKey, fault, times: 1);
        h.disk.fail(insightsKey, fault, times: 1);
        await expectLater(deletion(c).delete(), throwsA(anything));
        expect(c.read(insightsProvider).snapshots, isEmpty);

        // Insights opened while the Delete is pending; its save fails and
        // is rolled back — never to the deleted snapshots.
        h.disk.fail(insightsKey, fault, times: 1);
        insights(c).assess();
        await R8Harness.settle();
        expect(c.read(insightsProvider).byId(review.id), isNull);
        expect(c.read(insightsProvider).snapshots, isEmpty);

        h.disk.healAll();
        await deletion(c).resolvePending();
        await R8Harness.settle();
        expect((await h.disk.stored())[insightsKey], isNull);
        await restartsShowNothingDeleted();
      });

      test('an interrupted Delete (process stopped mid-way) is finished at '
          'the next start: nothing derived survives two restarts', () async {
        final c = h.open();
        insights(c).assess();
        await R8Harness.settle();
        final held = h.disk.hold(circlePlansKey);
        unawaited(deletion(c).delete().then((_) {}, onError: (Object _) {}));
        await held.reached;
        insights(c).assess();
        h.disk.stopAfter = h.disk.log.length;
        held.release(fault);
        await R8Harness.settle();
        h.disk.stopAfter = null;
        await h.restart();
        expect(
          (await h.disk.stored()).containsKey(historyDeletionPendingKey),
          isFalse,
        );
        await restartsShowNothingDeleted();
      });
    });
  }

  test('History is gone too, and the journal stays empty across restarts', () async {
    await h.boot({
      circlePlansKey: completedPlans(),
      circleJournalKey: jsonEncode({
        'schemaVersion': circleJournalSchemaVersion,
        'entries': <Object?>[],
      }),
    });
    final c = h.open();
    await deletion(c).delete();
    await R8Harness.settle();
    expect((await h.disk.stored()).containsKey(circleJournalKey), isFalse);
    await restartsShowNothingDeleted();
  });
}
