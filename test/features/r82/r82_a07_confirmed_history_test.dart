import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';
import 'package:thirty/features/plans/domain/plan_stage_provenance.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// R8.2 — Astra R81-A07 (MEDIUM): a History change still being written —
/// in the store's memory, not yet confirmed by the disk — is never the
/// premise of a durable decision. Insights (I4's threshold) and the Plan's
/// stage 5 read History as the disk confirmed it; once the write lands they
/// see it, and if it is refused nothing based on it survives.
void main() {
  final morning = DateTime(2026, 10, 30, 9);
  late R8Harness h;

  setUp(() async {
    h = R8Harness(morning);
    await h.boot();
  });

  RecommendationNotifier today(ProviderContainer c) =>
      c.read(recommendationProvider.notifier);
  String day(int ago) => dateKey(morning.subtract(Duration(days: ago)));

  // ------------------------------------------------------------------ I4
  group('I4 — the 4/7 → 4/6 threshold', () {
    CirclePart part(ElementId e) => CirclePart(e, elementOf(e).minutes);
    final writing = [
      part(ElementId.closeWhatsOpen),
      part(ElementId.getItOut),
      part(ElementId.chooseOne),
      part(ElementId.firstStep),
    ];
    final reading = [part(ElementId.phoneFaceDown), part(ElementId.readPages)];

    /// Seven useful Circles — four with writing, three without — and three
    /// more without writing, not answered useful: writing is 4/7 of the
    /// useful ones, below two thirds. Remove one useful non-writing answer
    /// and it is 4/6.
    String journal() {
      CircleJournalEntry entry(int ago, List<CirclePart> parts, bool useful) {
        final date = morning.subtract(Duration(days: ago));
        return CircleJournalEntry(
          schemaVersion: circleJournalSchemaVersion,
          circleId: dateKey(date),
          localDate: dateKey(date),
          direction: Intention.clearerHead,
          activityId: ActivityId.values.first,
          catalogVersion: catalogVersion,
          shownAt: date,
          startedAt: date,
          closedAt: date,
          attemptResponse: useful ? CircleAttemptResponse.yes : null,
          usefulnessResponse: useful
              ? CircleUsefulnessResponse.veryUseful
              : null,
          session: CircleSessionRecord(
            title: 'Circle',
            parts: CirclePlan(parts).toWire(),
          ),
        );
      }

      return jsonEncode({
        'schemaVersion': circleJournalSchemaVersion,
        'entries': [
          for (final ago in [1, 7, 13, 20]) entry(ago, writing, true).toJson(),
          for (final ago in [2, 9, 16]) entry(ago, reading, true).toJson(),
          for (final ago in [3, 10, 17]) entry(ago, reading, false).toJson(),
        ],
      });
    }

    Future<List<String>> familiesOnDisk() async {
      final raw = (await h.disk.stored())[insightsKey];
      if (raw is! String) return const [];
      return [
        for (final s in ((jsonDecode(raw) as Map)['snapshots'] as List?) ?? [])
          (s as Map)['family'] as String,
      ];
    }

    test('control — with History as it is (4/7), no I4 qualifies', () async {
      await h.boot({circleJournalKey: journal()});
      final c = h.open();
      final added = c.read(insightsProvider.notifier).assess().added;
      expect(
        added.map((s) => s.family),
        isNot(contains(InsightFamily.usefulInCommon)),
      );
    });

    for (final fault in DiskFault.values) {
      test('A07 as reported (${fault.name}) — a useful answer removed, its '
          'History write still pending; Insights opened: no I4 is generated '
          'from it, and none survives the refusal or two restarts', () async {
        await h.boot({circleJournalKey: journal()});
        final c = h.open();
        c.read(recommendationProvider);
        final held = h.disk.hold(circleJournalKey);
        today(c).removeAnswer(day(2), includingAttempt: false);
        await held.reached;
        expect(
          c
              .read(circleJournalRepositoryProvider)
              .readAll()
              .singleWhere((e) => e.circleId == day(2))
              .usefulnessResponse,
          isNull,
          reason: 'the pending value is in the store\'s memory',
        );
        final added = c.read(insightsProvider.notifier).assess().added;
        expect(
          added.map((s) => s.family),
          isNot(contains(InsightFamily.usefulInCommon)),
          reason: 'an Insight counted from History not on disk',
        );
        held.release(fault);
        await R8Harness.settle();
        expect(
          await familiesOnDisk(),
          isNot(contains(InsightFamily.usefulInCommon.id)),
        );
        for (var i = 0; i < 2; i++) {
          await h.restart();
          final again = h.open();
          expect(
            again
                .read(circleJournalRepositoryProvider)
                .readAll()
                .singleWhere((e) => e.circleId == day(2))
                .usefulnessResponse,
            CircleUsefulnessResponse.veryUseful,
          );
          expect(
            await familiesOnDisk(),
            isNot(contains(InsightFamily.usefulInCommon.id)),
          );
        }
      });
    }

    test('control — the removal lands first: then I4 is generated from the '
        'confirmed 4/6', () async {
      await h.boot({circleJournalKey: journal()});
      final c = h.open();
      c.read(recommendationProvider);
      today(c).removeAnswer(day(2), includingAttempt: false);
      await R8Harness.settle();
      final added = c.read(insightsProvider.notifier).assess().added;
      expect(
        added.map((s) => s.family),
        contains(InsightFamily.usefulInCommon),
      );
    });

    test('the removal lands while Insights is open: the next opening sees '
        'it', () async {
      await h.boot({circleJournalKey: journal()});
      final c = h.open();
      c.read(recommendationProvider);
      final held = h.disk.hold(circleJournalKey);
      today(c).removeAnswer(day(2), includingAttempt: false);
      await held.reached;
      c.read(insightsProvider.notifier).read();
      held.release();
      await R8Harness.settle();
      final added = c.read(insightsProvider.notifier).assess().added;
      expect(
        added.map((s) => s.family),
        contains(InsightFamily.usefulInCommon),
      );
    });
  });

  // ------------------------------------------------------------ Stage 5
  group('Plan stage 5 — the answers it is composed from', () {
    PlanStageProvenance stage(int n) => PlanStageProvenance(
      planId: 'getting_going',
      cycleId: 'getting_going#1',
      stageNumber: n,
      stageId: 'getting_going.$n',
    );

    /// Stages 1–4 guided, every answer "Not useful": by the confirmed
    /// History no stage 5 is made (case D).
    Map<String, Object> seed() {
      var s = CirclePlansState.empty.start('getting_going', today: day(9))!;
      for (var n = 1; n <= 4; n++) {
        s = s.recordGuided(
          stage(n),
          circleId: day(9 - n),
          today: day(9 - n),
          parts: const ['openWindow:2'],
          skipped: const [],
        );
      }
      return {
        circlePlansKey: jsonEncode(s.toJson()),
        circleJournalKey: jsonEncode({
          'schemaVersion': circleJournalSchemaVersion,
          'entries': [
            for (var n = 1; n <= 4; n++)
              CircleJournalEntry(
                schemaVersion: circleJournalSchemaVersion,
                circleId: day(9 - n),
                localDate: day(9 - n),
                direction: Intention.moreEnergy,
                activityId: ActivityId.values.first,
                catalogVersion: catalogVersion,
                shownAt: morning.subtract(Duration(days: 9 - n)),
                startedAt: morning.subtract(Duration(days: 9 - n)),
                closedAt: morning.subtract(Duration(days: 9 - n)),
                attemptResponse: CircleAttemptResponse.yes,
                usefulnessResponse: CircleUsefulnessResponse.notUseful,
              ).toJson(),
          ],
        }),
      };
    }

    for (final fault in DiskFault.values) {
      test('an answer removal still pending (${fault.name}, then refused) '
          'when today\'s Circle is chosen: the Plan decides exactly as the '
          'confirmed History says', () async {
        await h.boot(seed());
        final base = h.open();
        today(
          base,
        ).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
        await R8Harness.settle();
        final expected = (await h.disk.stored())[circlePlansKey];

        await h.boot(seed());
        final c = h.open();
        c.read(recommendationProvider);
        final held = h.disk.hold(circleJournalKey);
        today(c).removeAnswer(day(5), includingAttempt: false);
        await held.reached;
        today(
          c,
        ).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
        held.release(fault);
        await R8Harness.settle();
        expect(
          (await h.disk.stored())[circlePlansKey],
          expected,
          reason: 'stage 5 decided from an answer removal not on disk',
        );
      });
    }
  });
}
