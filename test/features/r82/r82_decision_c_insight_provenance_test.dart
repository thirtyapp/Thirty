import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

/// R8.2 founder decision C (acceptance review, 2026-11-05) — repairing an
/// Insight's applied mark. A Plan being active (or a cycle gentler, or a
/// part left out) is never on its own evidence that an Insight was applied:
/// a retry may record the mark only from persisted provenance linking that
/// Insight's own action to its target — the Insight's id, saved in the
/// change's own write. A change the user made some other way is never
/// claimed; an application that can't be attributed is reported as not
/// applied, never invented. The disclosed residual — the Insights store
/// refusing every write — is checked here too.
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

  /// [plans] as stored JSON, with [record] as [planId]'s Insight provenance
  /// — written as raw JSON, as another build or an earlier save left it.
  Map<String, Object?> withProvenance(
    CirclePlansState plans,
    String planId,
    Map<String, Object?> record,
  ) {
    final raw =
        jsonDecode(jsonEncode(plans.toJson())) as Map<String, Object?>;
    ((raw['plans'] as Map)[planId] as Map)['appliedInsight'] = record;
    return raw;
  }

  /// The app stops while [targetKey] — the Insight's own change — is
  /// still being written: it never lands. Returns the Insight shown.
  Future<String> interruptedApplication(
    Map<String, Object> seed,
    String targetKey,
    InsightFamily family,
  ) async {
    await h.boot(seed);
    final c = h.open();
    final shown = insights(c).assess().added.single;
    expect(shown.family, family);
    await R8Harness.settle();
    final held = h.disk.hold(targetKey);
    insights(c).apply(shown.id).ignore();
    await held.reached;
    await h.restart();
    return shown.id;
  }

  group('a change made some other way is never claimed', () {
    test('I1 — the app stopped while the Insight\'s Plan change was being '
        'written; the user then started the Plan themselves: the retry '
        'reports it not available and records nothing', () async {
      final id = await interruptedApplication(
        i1,
        circlePlansKey,
        InsightFamily.planForNeed,
      );
      final again = h.open();
      expect(
        again.read(circlePlansProvider).lifecycleOf('making_room'),
        PlanLifecycle.neverStarted,
      );
      expect(plans(again).start('making_room'), PlanActionResult.done);
      await R8Harness.settle();
      await h.restart();
      final third = h.open();
      final result = await insights(third).apply(id);
      await R8Harness.settle();
      expect(result, isNot(InsightActionResult.done));
      expect(result, isNot(InsightActionResult.alreadyApplied));
      expect((await snapshotOnDisk(id))?['appliedOn'], isNull);
      expect((await planOnDisk('making_room'))?['appliedInsight'], isNull);
    });

    test('I3 — the app stopped while the Insight\'s left-out part was being '
        'written; the user then left the part out from a skip: never claimed',
        () async {
      final id = await interruptedApplication(
        i3,
        suggestionPreferencesKey,
        InsightFamily.skippedPart,
      );
      final again = h.open();
      expect(again.read(suggestionPreferencesProvider).leftOut, isEmpty);
      await again
          .read(suggestionPreferencesProvider.notifier)
          .leaveOut(ElementId.openWindow);
      await R8Harness.settle();
      await h.restart();
      final third = h.open();
      final result = await insights(third).apply(id);
      await R8Harness.settle();
      expect(result, isNot(InsightActionResult.done));
      expect((await snapshotOnDisk(id))?['appliedOn'], isNull);
    });

    test('I1 — provenance naming another Insight attributes nothing', () async {
      await h.boot(i1);
      final c = h.open();
      final shown = insights(c).assess().added.single;
      await R8Harness.settle();
      final active = withProvenance(
        CirclePlansState.empty.start('making_room', today: '2026-10-30')!,
        'making_room',
        {
          'insightId': 'another',
          'cycleId': 'making_room#1',
          'on': '2026-10-30',
        },
      );
      await h.boot({
        ...await h.disk.stored(),
        circlePlansKey: jsonEncode(active),
      });
      final again = h.open();
      expect(
        await insights(again).apply(shown.id),
        InsightActionResult.notAvailable,
      );
      expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNull);
    });

    test('I2 — provenance for another cycle attributes nothing', () async {
      await h.boot(i2);
      final c = h.open();
      final shown = insights(c).assess().added.single;
      await R8Harness.settle();
      var other = CirclePlansState.empty.start('getting_going', today: 'x')!;
      other = other.leave('getting_going', today: '2026-10-29')!;
      other = other.goThroughAgain('getting_going', today: '2026-10-29')!;
      other = other.keepGentler('getting_going', today: '2026-10-30')!;
      expect(other.plans['getting_going']!.current.id, 'getting_going#2');
      await h.boot({
        ...await h.disk.stored(),
        circlePlansKey: jsonEncode(
          withProvenance(other, 'getting_going', {
            'insightId': shown.id,
            'cycleId': 'getting_going#2',
            'on': '2026-10-30',
          }),
        ),
      });
      final again = h.open();
      expect(
        await insights(again).apply(shown.id),
        isNot(InsightActionResult.done),
      );
      expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNull);
    });
  });

  group('the Insight\'s own change is recognized, never repeated', () {
    // R8.3.2 (founder scope decision B1): I3 records its attempt first, and
    // "a failed receipt write must not permit an unprotected target
    // mutation" — so with every Insights write refused its change is never
    // made. That case is below; I1 and I2 are unchanged.
    final cases = <String, (Map<String, Object>, InsightFamily)>{
      'I1': (i1, InsightFamily.planForNeed),
      'I2': (i2, InsightFamily.planPacing),
    };
    for (final fault in DiskFault.values) {
      test('I3 — the Insights store refuses every write (${fault.name}): '
          'its attempt can\'t be recorded, so nothing is left out; once the '
          'store takes it, the retry applies it once', () async {
        await h.boot(i3);
        final c = h.open();
        final shown = insights(c).assess().added.single;
        expect(shown.family, InsightFamily.skippedPart);
        await R8Harness.settle();
        h.disk.fail(insightsKey, fault);
        expect(
          await insights(c).apply(shown.id),
          InsightActionResult.notSaved,
        );
        await R8Harness.settle();
        expect(
          jsonEncode(await json(suggestionPreferencesKey)),
          isNot(contains(shown.id)),
          reason: 'the part was left out without its attempt record',
        );
        h.disk.healAll();
        await h.restart();
        final again = h.open();
        expect(
          await insights(again).apply(shown.id),
          InsightActionResult.done,
        );
        await R8Harness.settle();
        expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNotNull);
        expect(
          jsonEncode(await json(suggestionPreferencesKey)),
          contains(shown.id),
        );
      });
    }
    for (final MapEntry(key: name, value: (seed, family)) in cases.entries) {
      for (final fault in DiskFault.values) {
        test('$name — residual: the Insights store refuses every write '
            '(${fault.name}); the change lands with its provenance; after a '
            'restart the retry records the mark and changes nothing', () async {
          await h.boot(seed);
          final c = h.open();
          final shown = insights(c).assess().added.single;
          expect(shown.family, family);
          await R8Harness.settle();
          h.disk.fail(insightsKey, fault);
          expect(await insights(c).apply(shown.id), InsightActionResult.done);
          await R8Harness.settle();
          expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNull);
          final targets = jsonEncode([
            await json(circlePlansKey),
            await json(suggestionPreferencesKey),
          ]);
          expect(targets, contains(shown.id), reason: 'no provenance saved');

          h.disk.healAll();
          await h.restart();
          final again = h.open();
          final retried = await insights(again).apply(shown.id);
          await R8Harness.settle();
          expect(retried, InsightActionResult.done);
          expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNotNull);
          expect(
            jsonEncode([
              await json(circlePlansKey),
              await json(suggestionPreferencesKey),
            ]),
            targets,
            reason: 'the change was made again',
          );
          await h.restart();
          expect(
            await insights(h.open()).apply(shown.id),
            InsightActionResult.alreadyApplied,
          );
        });
      }
    }

    test('I1 — provenance survives a later Pause and Go through again of '
        'the same Plan: the earlier application is still recorded', () async {
      await h.boot(i1);
      final c = h.open();
      final shown = insights(c).assess().added.single;
      await R8Harness.settle();
      h.disk.fail(insightsKey, DiskFault.returnsFalse);
      await insights(c).apply(shown.id);
      await R8Harness.settle();
      h.disk.healAll();
      plans(c).leave('making_room');
      plans(c).goThroughAgain('making_room');
      await R8Harness.settle();
      expect(
        ((await planOnDisk('making_room'))?['appliedInsight'] as Map?)?['insightId'],
        shown.id,
      );
      await h.restart();
      final again = h.open();
      expect(
        await insights(again).apply(shown.id),
        InsightActionResult.done,
      );
      expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNotNull);
    });
  });

  group('the provenance record', () {
    test('a damaged record attributes nothing, and a later save writes it '
        'back exactly as stored', () async {
      await h.boot(i1);
      final c = h.open();
      final shown = insights(c).assess().added.single;
      await R8Harness.settle();
      final damaged = {'insightId': shown.id, 'on': 'yesterday'};
      await h.boot({
        ...await h.disk.stored(),
        circlePlansKey: jsonEncode(
          withProvenance(
            CirclePlansState.empty.start('making_room', today: '2026-10-30')!,
            'making_room',
            damaged,
          ),
        ),
      });
      final again = h.open();
      expect(
        await insights(again).apply(shown.id),
        InsightActionResult.notAvailable,
      );
      expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNull);
      expect(plans(again).pause('making_room'), PlanActionResult.done);
      await R8Harness.settle();
      expect((await planOnDisk('making_room'))?['lifecycle'], 'paused');
      expect((await planOnDisk('making_room'))?['appliedInsight'], damaged);
    });

    test('a manual Plan action carries none', () async {
      final c = h.open();
      plans(c).start('making_room');
      plans(c).pause('making_room');
      plans(c).resume('making_room');
      await R8Harness.settle();
      expect((await planOnDisk('making_room'))?['appliedInsight'], isNull);
    });
  });
}
