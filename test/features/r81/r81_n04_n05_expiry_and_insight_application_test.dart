import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/storage/store_save_failures.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';
import 'package:thirty/features/plans/domain/plan_stage_provenance.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// R8.1 — Astra N04 (MEDIUM): a failed record of a Start after a verified
/// expiry is never bypassed by a later Close, pause or recovery write.
/// Astra N05 (MEDIUM) / Claude AUD-6 (LOW): I1, I2 and I3 are recorded as
/// applied only once their own change is confirmed on disk; I4 after a
/// lapse still works. RevenueCat's answer stays the only entitlement.
void main() {
  final morning = DateTime(2026, 10, 30, 9);
  late R8Harness h;

  setUp(() async {
    h = R8Harness(morning);
    await h.boot();
  });

  RecommendationNotifier today(ProviderContainer c) =>
      c.read(recommendationProvider.notifier);
  void set(ProviderContainer c, EntitlementStatus s) =>
      (c.read(entitlementStatusProvider.notifier) as SettableEntitlement).set(
        s,
      );

  Future<Map<String, Object?>> json(String key) async {
    final raw = (await h.disk.stored())[key];
    return raw is String
        ? (jsonDecode(raw) as Map).cast<String, Object?>()
        : const {};
  }

  Future<int> creditsOnDisk(String circleId) async {
    final plans = (await json(circlePlansKey))['plans'] as Map? ?? const {};
    final plan = plans['getting_going'] as Map?;
    if (plan == null) return 0;
    return [
      for (final cycle in plan['cycles'] as List)
        for (final r in (cycle as Map)['records'] as List)
          if ((r as Map)['circleId'] == circleId) r,
    ].length;
  }

  // -------------------------------------------------------------- N04
  group('N04 — expiry at Start', () {
    Future<(ProviderContainer, String)> servedThenLapsed() async {
      final c = h.open();
      c.read(circlePlansProvider.notifier).start('getting_going');
      today(
        c,
      ).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await R8Harness.settle();
      final rec = c.read(recommendationProvider).recommendation!;
      expect(rec.composed?.stage, isNotNull);
      set(c, EntitlementStatus.inactive);
      return (c, rec.circleId);
    }

    for (final fault in DiskFault.values) {
      test('as reported (${fault.name}, Plans refusing): Start after a '
          'verified expiry, then Close with daily and History writes allowed '
          '— a restart never credits the Plan', () async {
        final (c, id) = await servedThenLapsed();
        h.disk.fail(circlePlansKey, fault);
        today(c).start();
        await R8Harness.settle();
        h.clock.value = morning.add(const Duration(minutes: 25));
        today(c).close();
        await R8Harness.settle();
        expect(c.read(journalSaveStatusProvider)[id], isFalse);

        h.disk.healAll();
        await h.restart();
        final again = h.open(status: EntitlementStatus.inactive);
        again.read(recommendationProvider);
        again.read(circlePlansProvider);
        await R8Harness.settle();
        expect(await creditsOnDisk(id), 0, reason: 'unauthorized credit');
        expect(
          again
              .read(circlePlansProvider)
              .plans['getting_going']!
              .current
              .records,
          isEmpty,
        );
        // And never a Close saved without its Start provenance.
        final stored = await h.disk.stored();
        expect(stored[recommendationStatusKey], isNot('closed'));
      });

      test(
        'the evidence write ${fault.name} once at Start: the Close '
        'writes it first, then saves — no credit, now or after a restart',
        () async {
          final (c, id) = await servedThenLapsed();
          h.disk.fail(circlePlansKey, fault, times: 1);
          today(c).start();
          await R8Harness.settle();
          h.clock.value = morning.add(const Duration(minutes: 25));
          today(c).close();
          await R8Harness.settle();
          final stored = await h.disk.stored();
          expect(stored[recommendationStatusKey], 'closed');
          expect(stored[circlePlansKey], contains('"startedAfterExpiry":true'));
          expect(await creditsOnDisk(id), 0);
          await h.restart();
          h
              .open(status: EntitlementStatus.inactive)
              .read(recommendationProvider);
          await R8Harness.settle();
          expect(await creditsOnDisk(id), 0);
        },
      );

      test('the evidence write ${fault.name} at Start, then a pause: the '
          'pause never saves a started Circle without it', () async {
        final (c, _) = await servedThenLapsed();
        h.disk.fail(circlePlansKey, fault);
        today(c).start();
        await R8Harness.settle();
        today(c).pause();
        await R8Harness.settle();
        expect((await h.disk.stored())[recommendationStatusKey], 'notStarted');
      });
    }

    test('regression — served and started under Premium, lapsed before Close: '
        'the legitimate credit still lands once', () async {
      final c = h.open();
      c.read(circlePlansProvider.notifier).start('getting_going');
      today(
        c,
      ).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await R8Harness.settle();
      final id = c.read(recommendationProvider).recommendation!.circleId;
      today(c).start();
      await R8Harness.settle();
      set(c, EntitlementStatus.inactive);
      expect(c.read(premiumEntitlementProvider), isFalse);
      h.clock.value = morning.add(const Duration(minutes: 25));
      today(c).close();
      await R8Harness.settle();
      expect(await creditsOnDisk(id), 1);
    });
  });

  // -------------------------------------------------------------- N05
  group('N05 — Insight application is recorded only once it is durable', () {
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

    final cases = <String, (Map<String, Object>, String, InsightFamily)>{
      'I1 (Plan direction)': (
        {
          circleJournalKey: journalOf([
            for (final ago in [1, 5, 9, 13, 14]) entry(ago, head),
          ]),
        },
        circlePlansKey,
        InsightFamily.planForNeed,
      ),
      'I2 (gentler Plan)': (
        {
          circlePlansKey: jsonEncode(
            CirclePlansState.empty
                .start('getting_going', today: '2026-10-01')!
                .toJson(),
          ),
          circleJournalKey: journalOf([
            for (final (k, ago) in [2, 5, 9, 13, 17].indexed)
              k.isEven
                  ? entry(
                      ago,
                      energy,
                      replacedFromStage: stage,
                      reason: 'tooMuch',
                    )
                  : entry(ago, energy, parts: window, stage: stage),
          ]),
        },
        circlePlansKey,
        InsightFamily.planPacing,
      ),
      'I3 (leave a part out)': (
        {
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
        },
        suggestionPreferencesKey,
        InsightFamily.skippedPart,
      ),
    };

    /// Whether the target change of [family] is on disk.
    Future<bool> targetOnDisk(InsightFamily family) async {
      switch (family) {
        case InsightFamily.planForNeed:
          final plans = (await json(circlePlansKey))['plans'] as Map? ?? {};
          return (plans['making_room'] as Map?)?['lifecycle'] == 'active';
        case InsightFamily.planPacing:
          final plans = (await json(circlePlansKey))['plans'] as Map? ?? {};
          final cycles = (plans['getting_going'] as Map)['cycles'] as List;
          return (cycles.last as Map)['gentlerSince'] != null;
        default:
          return '${(await h.disk.stored())[suggestionPreferencesKey]}'
              .contains('openWindow');
      }
    }

    Future<bool> appliedOnDisk(String snapshotId) async {
      final list = (await json(insightsKey))['snapshots'] as List? ?? [];
      return list.any(
        (s) => (s as Map)['id'] == snapshotId && s['appliedOn'] != null,
      );
    }

    for (final MapEntry(key: name, value: (seed, targetKey, family))
        in cases.entries) {
      for (final fault in DiskFault.values) {
        test('$name — its own store ${fault.name}: not saved, not recorded '
            'as applied (memory and disk), the user is told; after a '
            'restart it applies, durably', () async {
          await h.boot(seed);
          final c = h.open();
          final shown = c.read(insightsProvider.notifier).assess().added.single;
          expect(shown.family, family);
          await R8Harness.settle();
          h.disk.fail(targetKey, fault);
          final result = await c
              .read(insightsProvider.notifier)
              .apply(shown.id);
          await R8Harness.settle();
          expect(result, InsightActionResult.notSaved);
          expect(c.read(insightsProvider).byId(shown.id)!.appliedOn, isNull);
          expect(await appliedOnDisk(shown.id), isFalse);
          expect(await targetOnDisk(family), isFalse);
          expect(c.read(storeSaveFailuresProvider).count, greaterThan(0));

          h.disk.healAll();
          await h.restart();
          final again = h.open();
          again.read(insightsProvider);
          final retried = await again
              .read(insightsProvider.notifier)
              .apply(shown.id);
          await R8Harness.settle();
          expect(retried, InsightActionResult.done);
          expect(await targetOnDisk(family), isTrue);
          expect(await appliedOnDisk(shown.id), isTrue);
        });
      }

      test('$name — its change saved, the applied mark refused: the change '
          'is durable and the failure told; nothing claims the mark is '
          'saved', () async {
        await h.boot(seed);
        final c = h.open();
        final shown = c.read(insightsProvider.notifier).assess().added.single;
        await R8Harness.settle();
        h.disk.fail(insightsKey, DiskFault.returnsFalse);
        await c.read(insightsProvider.notifier).apply(shown.id);
        await R8Harness.settle();
        expect(await targetOnDisk(family), isTrue);
        expect(await appliedOnDisk(shown.id), isFalse);
        // R8.1 RL-1 (founder decision 2026-11-05): the refused mark is not
        // kept on screen as if saved; the failure is told.
        expect(c.read(insightsProvider).byId(shown.id)!.appliedOn, isNull);
        expect(c.read(storeSaveFailuresProvider).count, greaterThan(0));
        expect(
          c.read(storeSaveFailuresProvider).unsaved,
          contains(UserStore.insights),
        );
      });
    }

    test(
      'I1 retried in the same session once the store heals: the Plan '
      'already on screen is saved first, then the Insight is marked',
      () async {
        await h.boot(cases['I1 (Plan direction)']!.$1);
        final c = h.open();
        final shown = c.read(insightsProvider.notifier).assess().added.single;
        await R8Harness.settle();
        h.disk.fail(circlePlansKey, DiskFault.returnsFalse);
        expect(
          await c.read(insightsProvider.notifier).apply(shown.id),
          InsightActionResult.notSaved,
        );
        h.disk.healAll();
        final again = await c.read(insightsProvider.notifier).apply(shown.id);
        await R8Harness.settle();
        expect(again, isNot(InsightActionResult.notSaved));
        expect(await targetOnDisk(InsightFamily.planForNeed), isTrue);
        expect(await appliedOnDisk(shown.id), isTrue);
      },
    );

    test('a suggestion preference the store refuses is not shown as saved '
        '(returnsFalse is a failure, not success)', () async {
      final c = h.open();
      h.disk.fail(suggestionPreferencesKey, DiskFault.returnsFalse);
      await c
          .read(suggestionPreferencesProvider.notifier)
          .leaveOut(ElementId.openWindow);
      await R8Harness.settle();
      expect(c.read(suggestionPreferencesProvider).leftOut, isEmpty);
      expect(c.read(storeSaveFailuresProvider).count, greaterThan(0));
      expect(
        (await h.disk.stored()).containsKey(suggestionPreferencesKey),
        isFalse,
      );
    });
  });
}
