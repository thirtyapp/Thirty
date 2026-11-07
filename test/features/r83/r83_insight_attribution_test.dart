import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/insights/domain/insight_engine.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';
import 'package:thirty/features/plans/domain/plan_stage_provenance.dart';

import '../../support/r83_invariants.dart';
import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// R8.3 — Insight attribution and idempotence (invariants II and III).
///
/// - Astra R82-N01: a retry of an Insight whose own change already landed —
///   only its applied mark failed — must record the mark from that
///   provenance and never make the change again, even after the user has
///   reversed it by hand (founder decision D3: the later manual choice is
///   authoritative; the mark carries the original date).
/// - Astra R82-N02: a manual "Leave this out" queued ahead of an I3 must
///   never be recorded as the Insight's application.
///
/// The fixtures are those of `r82_decision_c_insight_provenance_test.dart`.
void main() {
  final morning = DateTime(2026, 10, 30, 9);
  late R8Harness h;

  setUp(() async {
    h = R8Harness(morning);
    await h.boot();
  });

  Future<Map<String, Object?>> json(String key) async {
    final raw = (await h.disk.stored())[key];
    return raw is String ? jsonDecode(raw) as Map<String, Object?> : {};
  }

  CirclePart part(ElementId e) => CirclePart(e, elementOf(e).minutes);
  final window = [
    part(ElementId.openWindow),
    part(ElementId.standingStretch),
    part(ElementId.sitAMinute),
  ];
  final reading = [part(ElementId.phoneFaceDown), part(ElementId.readPages)];

  CircleJournalEntry entry(
    int ago,
    Intention need, {
    List<CirclePart> parts = const [],
    Set<ElementId> skipped = const {},
    PlanStageProvenance? stage,
    PlanStageProvenance? replacedFromStage,
    String? reason,
  }) {
    final date = morning.subtract(Duration(days: ago));
    return CircleJournalEntry(
      schemaVersion: circleJournalSchemaVersion,
      circleId: dateKey(date),
      localDate: dateKey(date),
      direction: need,
      activityId: ActivityId.values.first,
      catalogVersion: catalogVersion,
      shownAt: date,
      startedAt: date,
      closedAt: date,
      replacementReason: reason,
      replacedFromStage: replacedFromStage,
      session: parts.isEmpty
          ? null
          : CircleSessionRecord(
              title: 'Circle',
              parts: CirclePlan(parts).toWire(),
              skipped: [for (final e in skipped) e.name],
              planStage: stage,
            ),
    );
  }

  String journalOf(List<CircleJournalEntry> entries) => jsonEncode({
    'schemaVersion': circleJournalSchemaVersion,
    'entries': [for (final e in entries) e.toJson()],
  });

  const head = Intention.clearerHead;
  const energy = Intention.moreEnergy;
  const stage = PlanStageProvenance(
    planId: 'getting_going',
    cycleId: 'getting_going#1',
    stageNumber: 1,
    stageId: 'getting_going.1',
  );

  final i1 = <String, Object>{
    circleJournalKey: journalOf([
      for (final ago in [1, 5, 9, 13, 14]) entry(ago, head),
    ]),
  };
  final i2 = <String, Object>{
    circlePlansKey: jsonEncode(
      CirclePlansState.empty
          .start('getting_going', today: '2026-10-01')!
          .toJson(),
    ),
    circleJournalKey: journalOf([
      for (final (k, ago) in [2, 5, 9, 13, 17].indexed)
        k.isEven
            ? entry(ago, energy, replacedFromStage: stage, reason: 'tooMuch')
            : entry(ago, energy, parts: window, stage: stage),
    ]),
  };
  final i3 = <String, Object>{
    circleJournalKey: journalOf([
      for (final ago in [2, 4, 6, 8, 10, 12, 15])
        entry(ago, head, parts: reading),
      for (final (k, ago) in [1, 5, 9, 11].indexed)
        entry(
          ago,
          energy,
          parts: window,
          skipped: k == 1 ? const {} : {ElementId.openWindow},
        ),
    ]),
  };

  InsightsNotifier insights(ProviderContainer c) =>
      c.read(insightsProvider.notifier);
  CirclePlansNotifier plans(ProviderContainer c) =>
      c.read(circlePlansProvider.notifier);

  Future<Map?> snapshotOnDisk(String id) async {
    final list = (await json(insightsKey))['snapshots'] as List? ?? [];
    for (final s in list) {
      if ((s as Map)['id'] == id) return s;
    }
    return null;
  }

  Future<Map?> planOnDisk(String planId) async =>
      ((await json(circlePlansKey))['plans'] as Map?)?[planId] as Map?;

  Future<List<String>> invariants() async =>
      DurableState(await h.disk.stored()).always();

  /// The Insight is shown, applied — its own change lands with its
  /// provenance — and only its applied mark is refused by the store.
  Future<(ProviderContainer, InsightSnapshot)> appliedMarkRefused(
    Map<String, Object> seed,
    InsightFamily family,
  ) async {
    await h.boot(seed);
    final c = h.open();
    final shown = insights(c).assess().added.single;
    expect(shown.family, family);
    await R8Harness.settle();
    h.disk.fail(insightsKey, DiskFault.returnsFalse);
    expect(await insights(c).apply(shown.id), InsightActionResult.done);
    await R8Harness.settle();
    h.disk.healAll();
    expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNull);
    return (c, shown);
  }

  group('R82-N01 — a retry after a manual reversal repairs only the mark', () {
    for (final reversal in ['Pause', 'Leave']) {
      test('I1 — the Insight started the Plan, its mark was refused, the '
          'user then chose $reversal: after a restart the retry records the '
          'mark, and the Plan stays as the user left it', () async {
        final (c, shown) = await appliedMarkRefused(
          i1,
          InsightFamily.planForNeed,
        );
        final onDay = ((await planOnDisk('making_room'))?['appliedInsight']
            as Map)['on'];
        expect(
          reversal == 'Pause'
              ? plans(c).pause('making_room')
              : plans(c).leave('making_room'),
          PlanActionResult.done,
        );
        await R8Harness.settle();
        final userChoice = jsonEncode(await planOnDisk('making_room'));
        await h.restart();
        final again = h.open();
        final retried = await insights(again).apply(shown.id);
        await R8Harness.settle();
        expect(
          jsonEncode(await planOnDisk('making_room')),
          userChoice,
          reason: 'the retry made the Insight\'s change again over the '
              'user\'s $reversal',
        );
        expect(retried, InsightActionResult.done);
        expect((await snapshotOnDisk(shown.id))?['appliedOn'], onDay);
        await h.restart();
        expect(
          h.open().read(circlePlansProvider).lifecycleOf('making_room'),
          reversal == 'Pause' ? PlanLifecycle.paused : PlanLifecycle.left,
        );
        expect(await invariants(), isEmpty);
      });
    }

    test('I2 — the Insight made the cycle gentler, its mark was refused, '
        'the user then turned gentler off: the retry records the mark and '
        'never turns it on again', () async {
      final (c, shown) = await appliedMarkRefused(i2, InsightFamily.planPacing);
      expect(plans(c).stopGentler('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      final userChoice = jsonEncode(await planOnDisk('getting_going'));
      await h.restart();
      final again = h.open();
      expect(await insights(again).apply(shown.id), InsightActionResult.done);
      await R8Harness.settle();
      expect(
        jsonEncode(await planOnDisk('getting_going')),
        userChoice,
        reason: 'gentler was turned on again over the user\'s choice',
      );
      expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNotNull);
      expect(await invariants(), isEmpty);
    });

    test('D3 — the mark carries the day the change was made, not the day '
        'of the retry', () async {
      final (c, shown) = await appliedMarkRefused(
        i1,
        InsightFamily.planForNeed,
      );
      expect(plans(c).pause('making_room'), PlanActionResult.done);
      await R8Harness.settle();
      h.clock.value = morning.add(const Duration(days: 1));
      await h.restart();
      final again = h.open();
      // Precondition: the observation still holds the next day, so the
      // retry meets a current Insight, not a stale one.
      expect(
        insights(again).status(insights(again).state.byId(shown.id)!),
        InsightStatus.current,
      );
      expect(await insights(again).apply(shown.id), InsightActionResult.done);
      await R8Harness.settle();
      expect(
        (await snapshotOnDisk(shown.id))?['appliedOn'],
        dateKey(morning),
        reason: 'the mark must carry the original application date',
      );
      expect(
        (await planOnDisk('making_room'))?['lifecycle'],
        'paused',
        reason: 'the Plan was resumed by the retry',
      );
    });

    test('control (III) — with no reversal, repeated retries and restarts '
        'record the mark once and never change the Plan', () async {
      final (_, shown) = await appliedMarkRefused(
        i1,
        InsightFamily.planForNeed,
      );
      final target = jsonEncode(await planOnDisk('making_room'));
      final results = <InsightActionResult>[];
      for (var i = 0; i < 3; i++) {
        await h.restart();
        results.add(await insights(h.open()).apply(shown.id));
        await R8Harness.settle();
        expect(jsonEncode(await planOnDisk('making_room')), target);
      }
      expect(results, [
        InsightActionResult.done,
        InsightActionResult.alreadyApplied,
        InsightActionResult.alreadyApplied,
      ]);
      expect(
        DurableState(await h.disk.stored()).appliedWithoutProvenance(),
        isEmpty,
      );
    });

    test('control — the mark\'s own write lands but its answer is lost: the '
        'change stands, the retry records the mark once, the Plan is not '
        'changed again', () async {
      await h.boot(i1);
      final c = h.open();
      final shown = insights(c).assess().added.single;
      await R8Harness.settle();
      h.disk.ackLost(insightsKey);
      expect(await insights(c).apply(shown.id), InsightActionResult.done);
      await R8Harness.settle();
      expect(h.disk.ackLostLog, ['set $insightsKey']);
      final target = jsonEncode(await planOnDisk('making_room'));
      await h.restart();
      final retried = await insights(h.open()).apply(shown.id);
      await R8Harness.settle();
      expect(retried, anyOf(
        InsightActionResult.done,
        InsightActionResult.alreadyApplied,
      ));
      expect(jsonEncode(await planOnDisk('making_room')), target);
      expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNotNull);
      expect(await invariants(), isEmpty);
    });

    test('control — the app stops right after the mark lands: after a '
        'restart it is applied, and a retry changes nothing', () async {
      await h.boot(i1);
      final c = h.open();
      final shown = insights(c).assess().added.single;
      await R8Harness.settle();
      h.disk.ackLost(insightsKey, thenStop: true);
      insights(c).apply(shown.id).ignore();
      await R8Harness.settle();
      await h.restart();
      final target = jsonEncode(await planOnDisk('making_room'));
      expect(
        await insights(h.open()).apply(shown.id),
        InsightActionResult.alreadyApplied,
      );
      await R8Harness.settle();
      expect(jsonEncode(await planOnDisk('making_room')), target);
    });
  });

  group('R82-N02 — a manual change queued ahead is never the Insight\'s', () {
    test('I3 — "Leave this out" by hand is still being written when the '
        'Insight is applied: the part is left out by the user, the Insight '
        'is not marked applied, and no attribution is invented', () async {
      await h.boot(i3);
      final c = h.open();
      final shown = insights(c).assess().added.single;
      expect(shown.family, InsightFamily.skippedPart);
      await R8Harness.settle();
      final held = h.disk.hold(suggestionPreferencesKey);
      final manual = c
          .read(suggestionPreferencesProvider.notifier)
          .leaveOut(ElementId.openWindow);
      await held.reached;
      final applying = insights(c).apply(shown.id);
      await R8Harness.settle();
      held.release();
      expect(await manual, isTrue);
      final result = await applying;
      await R8Harness.settle();
      final entries =
          (await json(suggestionPreferencesKey))['elementsLeftOut'] as List;
      final target =
          entries.singleWhere((e) => (e as Map)['elementId'] == 'openWindow')
              as Map;
      expect(target.containsKey('byInsight'), isFalse);
      expect(result, isNot(InsightActionResult.done));
      expect(
        (await snapshotOnDisk(shown.id))?['appliedOn'],
        isNull,
        reason: 'a manual exclusion recorded as the Insight\'s application',
      );
      await h.restart();
      expect(
        DurableState(await h.disk.stored()).appliedWithoutProvenance(),
        isEmpty,
      );
    });

    test('control — the I3 applied alone is done, saved with its '
        'provenance, and marked', () async {
      await h.boot(i3);
      final c = h.open();
      final shown = insights(c).assess().added.single;
      await R8Harness.settle();
      expect(await insights(c).apply(shown.id), InsightActionResult.done);
      await R8Harness.settle();
      final entries =
          (await json(suggestionPreferencesKey))['elementsLeftOut'] as List;
      expect((entries.single as Map)['byInsight'], shown.id);
      expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNotNull);
      expect(await invariants(), isEmpty);
    });

    test('control — the Plans equivalent: a manual Start still being '
        'written when I1 is applied is never claimed', () async {
      await h.boot(i1);
      final c = h.open();
      final shown = insights(c).assess().added.single;
      await R8Harness.settle();
      final held = h.disk.hold(circlePlansKey);
      expect(plans(c).start('making_room'), PlanActionResult.done);
      await held.reached;
      final applying = insights(c).apply(shown.id);
      await R8Harness.settle();
      held.release();
      final result = await applying;
      await R8Harness.settle();
      expect(result, isNot(InsightActionResult.done));
      expect((await planOnDisk('making_room'))?['appliedInsight'], isNull);
      expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNull);
    });
  });
}
