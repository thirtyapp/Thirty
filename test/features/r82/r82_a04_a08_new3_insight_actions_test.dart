import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';
import 'package:thirty/features/plans/domain/plan_stage_provenance.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// R8.2 — Insight actions:
///
/// - Astra R81-A04 (MEDIUM): I2 validates and changes the same Plan cycle
///   — never cycle A checked and cycle B made gentler.
/// - Astra R81-A08 (LOW) and Claude's I1/I2/I3 marker-retry observation:
///   when the target change landed and only the applied mark was refused,
///   a retry records the mark without repeating the change.
/// - Claude NEW-3 (LOW): an action whose own write failed but whose exact
///   change a later write made durable is not reported as not saved — and
///   a change that never landed is never reported as saved.
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

  Future<List<Map>> cyclesOnDisk(String planId) async {
    final stored = (await json(circlePlansKey))['plans'] as Map? ?? {};
    return [
      for (final c in ((stored[planId] as Map?)?['cycles'] as List?) ?? [])
        c as Map,
    ];
  }

  Future<Map?> snapshotOnDisk(String id) async {
    final list = (await json(insightsKey))['snapshots'] as List? ?? [];
    for (final s in list) {
      if ((s as Map)['id'] == id) return s;
    }
    return null;
  }

  // ------------------------------------------------------------------ A04
  group('A04 — I2 changes the cycle it was validated for', () {
    test('A04 as reported — a pending Leave, then Go through it again; I2 '
        'for cycle A applied: cycle B is never made gentler, and the Insight '
        'is not marked applied for a change it did not make', () async {
      await h.boot(i2);
      final c = h.open();
      final shown = insights(c).assess().added.single;
      expect(shown.family, InsightFamily.planPacing);
      expect(shown.cycleId, 'getting_going#1');
      await R8Harness.settle();

      final held = h.disk.hold(circlePlansKey);
      plans(c).leave('getting_going');
      await held.reached;
      plans(c).goThroughAgain('getting_going');
      expect(
        c.read(circlePlansProvider).plans['getting_going']!.current.id,
        'getting_going#2',
      );
      final applying = insights(c).apply(shown.id);
      held.release();
      final result = await applying;
      await R8Harness.settle();

      final cycles = await cyclesOnDisk('getting_going');
      expect(cycles.last['id'], 'getting_going#2');
      expect(
        cycles.last['gentlerSince'],
        isNull,
        reason: 'gentler applied to a cycle the Insight was not about',
      );
      expect(result, isNot(InsightActionResult.done));
      expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNull);

      await h.restart();
      final again = h.open();
      expect(
        again
            .read(circlePlansProvider)
            .plans['getting_going']!
            .current
            .isGentler,
        isFalse,
      );
    });

    for (final fault in DiskFault.values) {
      test('A04 (${fault.name}) — the competing Leave and Go through again '
          'are refused and rolled back: I2 then applies to cycle A itself, '
          'durably', () async {
        await h.boot(i2);
        final c = h.open();
        final shown = insights(c).assess().added.single;
        await R8Harness.settle();
        final held = h.disk.hold(circlePlansKey);
        plans(c).leave('getting_going');
        await held.reached;
        plans(c).goThroughAgain('getting_going');
        // The Leave's put-back, the Go through again and its put-back:
        // both changes are refused and nothing of them lands.
        h.disk.fail(circlePlansKey, fault, times: 3);
        final applying = insights(c).apply(shown.id);
        held.release(fault);
        final result = await applying;
        await R8Harness.settle();
        final cycles = await cyclesOnDisk('getting_going');
        expect(cycles, hasLength(1));
        expect(cycles.single['gentlerSince'], isNotNull);
        expect(result, InsightActionResult.done);
        expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNotNull);
      });
    }

    test('domain: Keep it gentler names its cycle — another cycle is never '
        'changed', () {
      var s = CirclePlansState.empty.start('getting_going', today: 'x')!;
      s = s.leave('getting_going', today: 'x')!;
      s = s.goThroughAgain('getting_going', today: 'x')!;
      final next = s.keepGentler('getting_going', today: 'x');
      expect(next?.plans['getting_going']!.current.id, 'getting_going#2');
      expect(next!.plans['getting_going']!.cycles.first.isGentler, isFalse);
    });
  });

  // ------------------------------------------------------- A08 / marker
  group('A08 — repairing a refused applied mark', () {
    /// Applies [id] with its change landing and only the applied mark
    /// refused, as [fault]. (Founder decision C: the change carries the
    /// Insight's provenance, so there is no separate intent write before it
    /// — the only Insights write is the mark.)
    Future<InsightActionResult> markRefused(
      ProviderContainer c,
      String id,
      DiskFault fault,
    ) async {
    // R8.3.2 (founder scope decisions B1/B2): an I3 or I4 first records its
    // attempt, so the fault is put on the write that carries the applied
    // mark — the same scenario. For I1 and I2 that is still the first
    // Insights write.
      h.disk.failWhere(
        insightsKey,
        (value) => value.contains('"appliedOn"'),
        fault: fault,
        times: 1,
      );
      return insights(c).apply(id);
    }

    final cases = <String, (Map<String, Object>, InsightFamily)>{
      'I1 (Plan direction)': (i1, InsightFamily.planForNeed),
      'I2 (gentler Plan)': (i2, InsightFamily.planPacing),
      'I3 (leave a part out)': (i3, InsightFamily.skippedPart),
    };

    /// The target change as it stands on disk, as one comparable value.
    Future<String> target(InsightFamily family) async => switch (family) {
      InsightFamily.planForNeed => jsonEncode(
        ((await json(circlePlansKey))['plans'] as Map?)?['making_room'],
      ),
      InsightFamily.planPacing => jsonEncode(
        await cyclesOnDisk('getting_going'),
      ),
      _ => jsonEncode((await json(suggestionPreferencesKey))['elementsLeftOut']),
    };

    for (final MapEntry(key: name, value: (seed, family)) in cases.entries) {
      for (final fault in DiskFault.values) {
        test('$name — change saved, mark refused (${fault.name}); retried '
            'after a restart: the mark is recorded, the change is not made '
            'again', () async {
          await h.boot(seed);
          final c = h.open();
          final shown = insights(c).assess().added.single;
          expect(shown.family, family);
          await R8Harness.settle();
          expect(
            await markRefused(c, shown.id, fault),
            InsightActionResult.done,
          );
          await R8Harness.settle();
          expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNull);
          final changed = await target(family);

          await h.restart();
          final again = h.open();
          final retried = await insights(again).apply(shown.id);
          await R8Harness.settle();
          expect(
            retried,
            isIn([InsightActionResult.done, InsightActionResult.alreadyApplied]),
            reason: 'the retry could not record the earlier application',
          );
          expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNotNull);
          expect(await target(family), changed, reason: 'change repeated');
          expect(
            again.read(insightsProvider).byId(shown.id)!.appliedOn,
            isNotNull,
          );

          await h.restart();
          final third = h.open();
          expect(
            await insights(third).apply(shown.id),
            InsightActionResult.alreadyApplied,
          );
          expect(await target(family), changed);
        });
      }

      test('$name — the same retry in the same session, without a restart',
          () async {
        await h.boot(seed);
        final c = h.open();
        final shown = insights(c).assess().added.single;
        await R8Harness.settle();
        await markRefused(c, shown.id, DiskFault.returnsFalse);
        await R8Harness.settle();
        final changed = await target(family);
        final retried = await insights(c).apply(shown.id);
        await R8Harness.settle();
        expect(
          retried,
          isIn([InsightActionResult.done, InsightActionResult.alreadyApplied]),
        );
        expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNotNull);
        expect(await target(family), changed);
      });

      test('$name — the repair keeps the entitlement check: after a lapse '
          'nothing is recorded', () async {
        await h.boot(seed);
        final c = h.open();
        final shown = insights(c).assess().added.single;
        await R8Harness.settle();
        await markRefused(c, shown.id, DiskFault.throws);
        await R8Harness.settle();
        (c.read(entitlementStatusProvider.notifier) as SettableEntitlement)
            .set(EntitlementStatus.inactive);
        expect(c.read(premiumEntitlementProvider), isFalse);
        expect(
          await insights(c).apply(shown.id),
          InsightActionResult.needsPremium,
        );
        await R8Harness.settle();
        expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNull);
      });
    }

    test('I2 — the cycle changes after the change landed (Leave, Go through '
        'it again): the repair records the original cycle\'s application, '
        'and the new cycle is not made gentler', () async {
      await h.boot(i2);
      final c = h.open();
      final shown = insights(c).assess().added.single;
      await R8Harness.settle();
      await markRefused(c, shown.id, DiskFault.returnsFalse);
      await R8Harness.settle();
      plans(c).leave('getting_going');
      plans(c).goThroughAgain('getting_going');
      await R8Harness.settle();
      await h.restart();
      final again = h.open();
      final retried = await insights(again).apply(shown.id);
      await R8Harness.settle();
      expect(
        retried,
        isIn([InsightActionResult.done, InsightActionResult.alreadyApplied]),
      );
      final cycles = await cyclesOnDisk('getting_going');
      expect(cycles.first['gentlerSince'], isNotNull);
      expect(cycles.last['gentlerSince'], isNull);
      expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNotNull);
    });

    test('I1 — a Plan the user started some other way after the Insight '
        'was shown is never claimed as its application', () async {
      await h.boot(i1);
      final c = h.open();
      final shown = insights(c).assess().added.single;
      await R8Harness.settle();
      plans(c).start('making_room');
      await R8Harness.settle();
      await h.restart();
      final again = h.open();
      expect(
        await insights(again).apply(shown.id),
        InsightActionResult.notAvailable,
      );
      expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNull);
    });

    // Founder decision C (R8.2 acceptance review, 2026-11-05): the residual
    // case this test disclosed — the Insights store refusing every write, so
    // nothing could attribute the change — is investigated and closed: the
    // attribution now travels in the change's own save, not in the Insights
    // store, so the retry repairs the mark from it.
    test('residual, closed — the Insights store refuses every write: the '
        'change still lands, as before, and the user is told; after a '
        'restart the retry finds the Insight\'s own provenance on the Plan '
        'and records the mark, without changing the Plan again', () async {
      await h.boot(i2);
      final c = h.open();
      final shown = insights(c).assess().added.single;
      await R8Harness.settle();
      h.disk.fail(insightsKey, DiskFault.returnsFalse);
      expect(await insights(c).apply(shown.id), InsightActionResult.done);
      await R8Harness.settle();
      expect(
        (await cyclesOnDisk('getting_going')).single['gentlerSince'],
        isNotNull,
      );
      expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNull);
      final changed = jsonEncode(await cyclesOnDisk('getting_going'));
      h.disk.healAll();
      await h.restart();
      final again = h.open();
      expect(
        await insights(again).apply(shown.id),
        InsightActionResult.done,
      );
      await R8Harness.settle();
      expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNotNull);
      expect(jsonEncode(await cyclesOnDisk('getting_going')), changed);
    });

    test('I3 — a part left out by the user before the Insight was shown is '
        'not claimed as the Insight\'s application', () async {
      await h.boot(i3);
      final c = h.open();
      final shown = insights(c).assess().added.single;
      await R8Harness.settle();
      // Left out an earlier day, from Memory: not this Insight's change.
      await h.boot({
        ...await h.disk.stored(),
        suggestionPreferencesKey: jsonEncode({
          'schemaVersion': suggestionPreferencesSchemaVersion,
          'elementsLeftOut': [
            {'elementId': 'openWindow', 'since': '2026-10-01T09:00:00.000'},
          ],
        }),
      });
      final again = h.open();
      expect(
        await insights(again).apply(shown.id),
        isNot(InsightActionResult.done),
      );
      await R8Harness.settle();
      expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNull);
    });
  });

  // ---------------------------------------------------------------- NEW-3
  group('NEW-3 — saved means what is on disk', () {
    for (final fault in DiskFault.values) {
      test('I2 (${fault.name}) — its own write refused, a later queued Plans '
          'write landed with the same change: reported done, and marked',
          () async {
        await h.boot(i2);
        final c = h.open();
        final shown = insights(c).assess().added.single;
        await R8Harness.settle();
        final held = h.disk.hold(circlePlansKey);
        final applying = insights(c).apply(shown.id);
        await held.reached;
        expect(plans(c).start('making_room'), PlanActionResult.done);
        held.release(fault);
        final result = await applying;
        await R8Harness.settle();
        final cycles = await cyclesOnDisk('getting_going');
        expect(cycles.single['gentlerSince'], isNotNull, reason: 'durable');
        expect(result, InsightActionResult.done, reason: 'false not-saved');
        expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNotNull);
      });

      test('I2 (${fault.name}) — the later write is refused too: genuinely '
          'not saved, never reported as saved', () async {
        await h.boot(i2);
        final c = h.open();
        final shown = insights(c).assess().added.single;
        await R8Harness.settle();
        final held = h.disk.hold(circlePlansKey);
        final applying = insights(c).apply(shown.id);
        await held.reached;
        plans(c).start('making_room');
        h.disk.fail(circlePlansKey, fault);
        held.release(fault);
        final result = await applying;
        await R8Harness.settle();
        expect(result, InsightActionResult.notSaved);
        final cycles = await cyclesOnDisk('getting_going');
        expect(cycles.single['gentlerSince'], isNull);
        expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNull);
      });
    }

    test('Plans.confirmed — an earlier write refused, the later one holding '
        'the change confirmed: done', () async {
      final c = h.open();
      final held = h.disk.hold(circlePlansKey);
      final starting = plans(
        c,
      ).confirmed((p) => p.start('getting_going'));
      await held.reached;
      plans(c).requestRevisit('getting_going', 1);
      plans(c).keepGentler('getting_going');
      held.release(DiskFault.returnsFalse);
      expect(await starting, PlanActionResult.done);
      expect(
        ((await json(circlePlansKey))['plans'] as Map)['getting_going'],
        isNotNull,
      );
    });
  });
}
