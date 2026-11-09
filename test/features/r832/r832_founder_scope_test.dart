import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_history_deletion.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/insights/domain/insight_engine.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';
import 'package:thirty/features/plans/domain/plan_stage_provenance.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// R8.3.2 — final founder scope decisions (2026-11-07):
/// - R832-B1 (I3 retried after the user's Put back) and R832-B2 (I4 retried
///   after the user removed the kept Circle): FIX REQUIRED. The Insight never
///   repeats its action, never claims one not durably performed, and an
///   independent Keep is never attributed to I4.
/// - N01-C: a Plan lifecycle change while a Start is unresolved cancels that
///   Start; the user taps Start again.
///
/// Each test prints one `R832F-EVIDENCE` line with what reached the disk. A
/// step a tree can't construct fails with `PRECONDITION` (not applicable).
void main() {
  void evidence(String id, Map<String, Object?> facts) {
    // ignore: avoid_print
    print('R832F-EVIDENCE ${jsonEncode({'test': id, ...facts})}');
  }

  void pre(bool holds, String what) {
    if (!holds) fail('PRECONDITION not constructible on this tree: $what');
  }

  bool marksApplied(String value) => value.contains('"appliedOn"');

  // -----------------------------------------------------------------------
  // B1 / B2 — Insights I3 and I4.

  group('Insights', () {
    final morning = DateTime(2026, 10, 30, 9);
    late R8Harness h;

    setUp(() async {
      h = R8Harness(morning);
      await h.boot();
    });

    CirclePart part(ElementId e) => CirclePart(e, elementOf(e).minutes);
    final window = [
      part(ElementId.openWindow),
      part(ElementId.standingStretch),
      part(ElementId.sitAMinute),
    ];
    final reading = [part(ElementId.phoneFaceDown), part(ElementId.readPages)];
    final writing = [
      part(ElementId.closeWhatsOpen),
      part(ElementId.getItOut),
      part(ElementId.chooseOne),
      part(ElementId.firstStep),
    ];
    const head = Intention.clearerHead;
    const energy = Intention.moreEnergy;

    CircleJournalEntry entry(
      int ago,
      Intention need, {
      List<CirclePart> parts = const [],
      Set<ElementId> skipped = const {},
      bool useful = false,
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
        attemptResponse: useful ? CircleAttemptResponse.yes : null,
        usefulnessResponse: useful
            ? (ago.isEven
                  ? CircleUsefulnessResponse.veryUseful
                  : CircleUsefulnessResponse.somewhatUseful)
            : null,
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

    // I3: "Open a window" skipped in 3 of its last 4 Circles.
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
    // I4: Writing in all 4 useful Clearer Head Circles; keeps 2026-10-29.
    final i4 = <String, Object>{
      circleJournalKey: journalOf([
        for (final ago in [1, 7, 13, 20])
          entry(ago, head, parts: writing, useful: true),
        for (final ago in [3, 9, 16]) entry(ago, head, parts: reading),
      ]),
    };
    const stage = PlanStageProvenance(
      planId: 'getting_going',
      cycleId: 'getting_going#1',
      stageNumber: 1,
      stageId: 'getting_going.1',
    );
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
    final i1 = <String, Object>{
      circleJournalKey: journalOf([
        for (final ago in [1, 5, 9, 13, 14]) entry(ago, head),
      ]),
    };

    InsightsNotifier insights(ProviderContainer c) =>
        c.read(insightsProvider.notifier);

    Future<Map<String, Object?>> json(String key) async {
      final raw = (await h.disk.stored())[key];
      return raw is String ? jsonDecode(raw) as Map<String, Object?> : {};
    }

    Future<Map?> snapshotOnDisk(String id) async {
      for (final s in (await json(insightsKey))['snapshots'] as List? ?? []) {
        if ((s as Map)['id'] == id) return s;
      }
      return null;
    }

    Future<Set<ElementId>> leftOutAfterRestart() async {
      await h.restart();
      return h.open().read(suggestionPreferencesProvider).leftOut;
    }

    Future<List<String?>> keptFromAfterRestart() async {
      await h.restart();
      return [
        for (final k in h.open().read(keptCirclesProvider).kept) k.fromCircleId,
      ];
    }

    Future<(ProviderContainer, InsightSnapshot)> shown(
      Map<String, Object> seed,
      InsightFamily family, {
      EntitlementStatus status = EntitlementStatus.active,
    }) async {
      await h.boot(seed);
      final c = h.open();
      final s = insights(c).assess().added.single;
      expect(s.family, family);
      await R8Harness.settle();
      if (status != EntitlementStatus.active) {
        await h.restart();
        return (h.open(status: status), s);
      }
      return (c, s);
    }

    /// [s] applied with only its applied mark refused by the store.
    Future<InsightActionResult> applyMarkRefused(
      ProviderContainer c,
      InsightSnapshot s,
    ) async {
      h.disk.failWhere(insightsKey, marksApplied);
      final result = await insights(c).apply(s.id);
      await R8Harness.settle();
      h.disk.healAll();
      return result;
    }

    Future<InsightActionResult> retry(String id, {int times = 1}) async {
      late InsightActionResult last;
      for (var n = 0; n < times; n++) {
        await h.restart();
        last = await insights(h.open()).apply(id);
        await R8Harness.settle();
      }
      return last;
    }

    String statusNow(String id) {
      final c = h.open();
      return insights(c).status(insights(c).state.byId(id)!).name;
    }

    // ---------------- R832-B1 (I3) ----------------

    group('R832-B1 — I3 retried after Put back', () {
      test('B1-1 founder sequence: applied, Preferences confirmed, mark '
          'refused, Put back, retried: the part stays available, no action '
          'repeated, no application date', () async {
        final (c, s) = await shown(i3, InsightFamily.skippedPart);
        final first = await applyMarkRefused(c, s);
        pre(first == InsightActionResult.done, 'the I3 change landed');
        pre(
          c
              .read(suggestionPreferencesProvider)
              .leftOut
              .contains(ElementId.openWindow),
          'left out',
        );
        expect(
          await c
              .read(suggestionPreferencesProvider.notifier)
              .putBack(ElementId.openWindow),
          isTrue,
        );
        await R8Harness.settle();
        final retried = await retry(s.id);
        final left = await leftOutAfterRestart();
        evidence('B1-1', {
          'first': first.name,
          'retry': retried.name,
          'status': statusNow(s.id),
          'leftOut': [for (final e in left) e.name],
          'snapshot': await snapshotOnDisk(s.id),
          'prefs': (await h.disk.stored())[suggestionPreferencesKey],
        });
        expect(left, isNot(contains(ElementId.openWindow)));
        expect(retried, isNot(InsightActionResult.done));
        expect((await snapshotOnDisk(s.id))?['appliedOn'], isNull);
      });

      test('B1-2 repeated retries and restarts change nothing', () async {
        final (c, s) = await shown(i3, InsightFamily.skippedPart);
        pre(await applyMarkRefused(c, s) == InsightActionResult.done, 'done');
        await c
            .read(suggestionPreferencesProvider.notifier)
            .putBack(ElementId.openWindow);
        await R8Harness.settle();
        final before = (await h.disk.stored())[suggestionPreferencesKey];
        final results = <String>[];
        for (var n = 0; n < 3; n++) {
          results.add((await retry(s.id)).name);
        }
        evidence('B1-2', {'results': results});
        expect((await h.disk.stored())[suggestionPreferencesKey], before);
        expect((await snapshotOnDisk(s.id))?['appliedOn'], isNull);
      });

      test('B1-3 the Preferences write is refused (returns false): nothing '
          'was done, so a later retry applies it once', () async {
        final (c, s) = await shown(i3, InsightFamily.skippedPart);
        h.disk.fail(suggestionPreferencesKey, DiskFault.returnsFalse);
        final first = await insights(c).apply(s.id);
        await R8Harness.settle();
        h.disk.healAll();
        final status = statusNow(s.id);
        final retried = await retry(s.id);
        final left = await leftOutAfterRestart();
        evidence('B1-3', {
          'first': first.name,
          'statusAfterRefusal': status,
          'retry': retried.name,
          'snapshot': await snapshotOnDisk(s.id),
        });
        expect(first, InsightActionResult.notSaved);
        expect(status, InsightStatus.current.name);
        expect(retried, InsightActionResult.done);
        expect(left, contains(ElementId.openWindow));
        expect((await snapshotOnDisk(s.id))?['appliedOn'], dateKey(morning));
      });

      test('B1-4 the Preferences write lands but its answer is lost: the '
          'outcome is uncertain — no replay, no application claimed', () async {
        final (c, s) = await shown(i3, InsightFamily.skippedPart);
        h.disk.ackLost(suggestionPreferencesKey);
        final first = await insights(c).apply(s.id);
        await R8Harness.settle();
        final afterFirst = (await h.disk.stored())[suggestionPreferencesKey];
        pre(
          afterFirst == null || !'$afterFirst'.contains('byInsight'),
          'the write was put back (no provenance on disk)',
        );
        final retried = await retry(s.id, times: 2);
        final left = await leftOutAfterRestart();
        evidence('B1-4', {
          'first': first.name,
          'retry': retried.name,
          'status': statusNow(s.id),
          'snapshot': await snapshotOnDisk(s.id),
        });
        expect(left, isNot(contains(ElementId.openWindow)));
        expect((await snapshotOnDisk(s.id))?['appliedOn'], isNull);
      });

      test('B1-5 the app stops right after the attempt is recorded, before '
          'the change: no replay after the restart', () async {
        final (c, s) = await shown(i3, InsightFamily.skippedPart);
        h.disk.ackLost(insightsKey, thenStop: true);
        insights(c).apply(s.id).ignore();
        await R8Harness.settle();
        final left0 = await leftOutAfterRestart();
        pre(
          !left0.contains(ElementId.openWindow),
          'the change was not made before the stop (an attempt record is '
          'the first write)',
        );
        final retried = await retry(s.id, times: 2);
        final left = await leftOutAfterRestart();
        evidence('B1-5', {
          'retry': retried.name,
          'status': statusNow(s.id),
          'snapshot': await snapshotOnDisk(s.id),
        });
        expect(left, isNot(contains(ElementId.openWindow)));
        expect((await snapshotOnDisk(s.id))?['appliedOn'], isNull);
      });

      test('B1-6 the app stops after the change lands, before the mark: '
          'after a restart the mark is recorded with the original date, '
          'the change is not made twice', () async {
        final (c, s) = await shown(i3, InsightFamily.skippedPart);
        h.disk.ackLost(suggestionPreferencesKey, thenStop: true);
        insights(c).apply(s.id).ignore();
        await R8Harness.settle();
        h.clock.value = morning.add(const Duration(days: 1));
        await h.restart();
        final c2 = h.open();
        insights(c2).assess();
        await R8Harness.settle();
        final retried = await insights(c2).apply(s.id);
        await R8Harness.settle();
        final left = await leftOutAfterRestart();
        evidence('B1-6', {
          'retry': retried.name,
          'snapshot': await snapshotOnDisk(s.id),
          'prefs': (await h.disk.stored())[suggestionPreferencesKey],
        });
        expect(left, contains(ElementId.openWindow));
        expect((await snapshotOnDisk(s.id))?['appliedOn'], dateKey(morning));
        final prefs =
            jsonDecode(
                  (await h.disk.stored())[suggestionPreferencesKey] as String,
                )
                as Map;
        expect((prefs['elementsLeftOut'] as List).length, 1);
      });

      test(
        'B1-ctl I3 applied normally: left out once, marked that day',
        () async {
          final (c, s) = await shown(i3, InsightFamily.skippedPart);
          expect(await insights(c).apply(s.id), InsightActionResult.done);
          await R8Harness.settle();
          expect(await leftOutAfterRestart(), contains(ElementId.openWindow));
          expect((await snapshotOnDisk(s.id))?['appliedOn'], dateKey(morning));
          expect((await snapshotOnDisk(s.id))?['attempt'], isNull);
        },
      );

      test(
        'B1-ctl2 the attempt record itself is refused: no change is made',
        () async {
          final (c, s) = await shown(i3, InsightFamily.skippedPart);
          h.disk.fail(insightsKey, DiskFault.returnsFalse);
          final first = await insights(c).apply(s.id);
          await R8Harness.settle();
          h.disk.healAll();
          evidence('B1-ctl2', {'first': first.name});
          expect(
            await leftOutAfterRestart(),
            isNot(contains(ElementId.openWindow)),
          );
          expect(first, InsightActionResult.notSaved);
        },
      );
    });

    // ---------------- R832-B2 (I4) ----------------

    group('R832-B2 — I4 retried after the kept Circle was removed', () {
      test('B2-1 founder sequence: kept, Kept Circles confirmed, mark '
          'refused, the user removes it, retried: it stays removed, no '
          'application date', () async {
        final (c, s) = await shown(i4, InsightFamily.usefulInCommon);
        final first = await applyMarkRefused(c, s);
        pre(first == InsightActionResult.done, 'the Keep landed');
        final kept = c.read(keptCirclesProvider).kept;
        pre(kept.length == 1, 'one kept Circle');
        await c.read(keptCirclesProvider.notifier).deleteKept(kept.single.id);
        await R8Harness.settle();
        final retried = await retry(s.id);
        final after = await keptFromAfterRestart();
        evidence('B2-1', {
          'retry': retried.name,
          'status': statusNow(s.id),
          'kept': after,
          'snapshot': await snapshotOnDisk(s.id),
        });
        expect(after, isEmpty);
        expect(retried, isNot(InsightActionResult.done));
        expect((await snapshotOnDisk(s.id))?['appliedOn'], isNull);
      });

      test('B2-2 repeated retries and restarts recreate nothing', () async {
        final (c, s) = await shown(i4, InsightFamily.usefulInCommon);
        pre(await applyMarkRefused(c, s) == InsightActionResult.done, 'done');
        final kept = c.read(keptCirclesProvider).kept.single;
        await c.read(keptCirclesProvider.notifier).deleteKept(kept.id);
        await R8Harness.settle();
        for (var n = 0; n < 3; n++) {
          await retry(s.id);
        }
        expect(await keptFromAfterRestart(), isEmpty);
        expect((await snapshotOnDisk(s.id))?['appliedOn'], isNull);
      });

      test('B2-3 a Keep the user made independently is never attributed to '
          'I4', () async {
        final (c, s) = await shown(i4, InsightFamily.usefulInCommon);
        final target = (s.application as KeepCircleFromHistory).circleId;
        await c
            .read(keptCirclesProvider.notifier)
            .keepCircle(
              plan: CirclePlan(writing),
              need: head,
              circleId: target,
            );
        await R8Harness.settle();
        final result = await insights(c).apply(s.id);
        await R8Harness.settle();
        final after = await keptFromAfterRestart();
        evidence('B2-3', {
          'result': result.name,
          'kept': after,
          'snapshot': await snapshotOnDisk(s.id),
        });
        expect(after, [target], reason: 'one kept Circle, no duplicate');
        expect(
          (await snapshotOnDisk(s.id))?['appliedOn'],
          isNull,
          reason: 'the user\'s own Keep was recorded as I4\'s application',
        );
      });

      test('B2-4 at the kept limit nothing is kept and nothing recorded; '
          'once a place is free, I4 keeps once', () async {
        final (c, s) = await shown(i4, InsightFamily.usefulInCommon);
        final keep = c.read(keptCirclesProvider.notifier);
        for (var n = 0; n < 8; n++) {
          await keep.keepCircle(
            plan: CirclePlan(reading),
            need: head,
            circleId: '2026-09-0${n + 1}',
          );
        }
        await R8Harness.settle();
        final full = await insights(c).apply(s.id);
        await R8Harness.settle();
        final statusFull = statusNow(s.id);
        final snapshotFull = await snapshotOnDisk(s.id);
        await keep.deleteKept(c.read(keptCirclesProvider).kept.first.id);
        await R8Harness.settle();
        final later = await retry(s.id);
        final after = await keptFromAfterRestart();
        evidence('B2-4', {
          'full': full.name,
          'statusFull': statusFull,
          'snapshotFull': snapshotFull,
          'later': later.name,
        });
        expect(full, InsightActionResult.keptLimitReached);
        expect(snapshotFull?['appliedOn'], isNull);
        expect(later, InsightActionResult.done);
        expect(after.where((id) => id == '2026-10-29').length, 1);
        expect(after.length, 8);
      });

      test('B2-5 the Kept Circles write is refused (returns false): nothing '
          'was kept, so a later retry keeps it once', () async {
        final (c, s) = await shown(i4, InsightFamily.usefulInCommon);
        h.disk.fail(keptCirclesKey, DiskFault.returnsFalse);
        final first = await insights(c).apply(s.id);
        await R8Harness.settle();
        h.disk.healAll();
        final status = statusNow(s.id);
        final retried = await retry(s.id);
        final after = await keptFromAfterRestart();
        evidence('B2-5', {
          'first': first.name,
          'status': status,
          'retry': retried.name,
        });
        expect(first, InsightActionResult.notSaved);
        expect(status, InsightStatus.current.name);
        expect(retried, InsightActionResult.done);
        expect(after, ['2026-10-29']);
      });

      test('B2-6 the Kept Circles write lands but its answer is lost: '
          'uncertain — never kept again, never claimed', () async {
        final (c, s) = await shown(i4, InsightFamily.usefulInCommon);
        h.disk.ackLost(keptCirclesKey);
        final first = await insights(c).apply(s.id);
        await R8Harness.settle();
        final retried = await retry(s.id, times: 2);
        final after = await keptFromAfterRestart();
        evidence('B2-6', {
          'first': first.name,
          'retry': retried.name,
          'kept': after,
          'snapshot': await snapshotOnDisk(s.id),
        });
        expect(after.length, lessThanOrEqualTo(1));
        if (after.isEmpty) {
          expect((await snapshotOnDisk(s.id))?['appliedOn'], isNull);
        }
      });

      test('B2-7 the app stops after the Keep lands, before the mark: after '
          'a restart the mark is recorded with the original date; one kept '
          'Circle', () async {
        final (c, s) = await shown(i4, InsightFamily.usefulInCommon);
        h.disk.ackLost(keptCirclesKey, thenStop: true);
        insights(c).apply(s.id).ignore();
        await R8Harness.settle();
        h.clock.value = morning.add(const Duration(days: 1));
        await h.restart();
        final c2 = h.open();
        insights(c2).assess();
        await R8Harness.settle();
        final retried = await insights(c2).apply(s.id);
        await R8Harness.settle();
        final after = await keptFromAfterRestart();
        evidence('B2-7', {
          'retry': retried.name,
          'kept': after,
          'snapshot': await snapshotOnDisk(s.id),
        });
        expect(after, ['2026-10-29']);
        expect((await snapshotOnDisk(s.id))?['appliedOn'], dateKey(morning));
      });

      test('B2-ctl I4 applied normally, also without Premium: kept once, '
          'marked that day', () async {
        for (final status in [
          EntitlementStatus.active,
          EntitlementStatus.inactive,
        ]) {
          final (c, s) = await shown(
            i4,
            InsightFamily.usefulInCommon,
            status: status,
          );
          expect(await insights(c).apply(s.id), InsightActionResult.done);
          await R8Harness.settle();
          expect(await keptFromAfterRestart(), ['2026-10-29']);
          expect((await snapshotOnDisk(s.id))?['appliedOn'], dateKey(morning));
        }
      });
    });

    // ---------------- the attempt record ----------------

    group('The attempt record', () {
      /// B1-1's state: an I3 whose attempt stays unresolved.
      Future<InsightSnapshot> unresolved() async {
        final (c, s) = await shown(i3, InsightFamily.skippedPart);
        pre(await applyMarkRefused(c, s) == InsightActionResult.done, 'done');
        await c
            .read(suggestionPreferencesProvider.notifier)
            .putBack(ElementId.openWindow);
        await R8Harness.settle();
        return s;
      }

      test('R1 it survives reassessment, a rebuild, another snapshot\'s '
          'change and restarts', () async {
        final s = await unresolved();
        final before = (await snapshotOnDisk(s.id))?['attempt'];
        pre(before != null, 'an attempt record on this tree');
        await h.restart();
        final c = h.open();
        insights(c).assess();
        await R8Harness.settle();
        c.invalidate(insightsProvider);
        insights(c).assess();
        await R8Harness.settle();
        h.clock.value = morning.add(const Duration(days: 8));
        await h.restart();
        insights(h.open()).assess();
        await R8Harness.settle();
        evidence('R1', {
          'before': before,
          'after': (await snapshotOnDisk(s.id))?['attempt'],
        });
        expect((await snapshotOnDisk(s.id))?['attempt'], before);
      });

      test('R2 a damaged record makes the snapshot unreadable — kept as '
          'stored; a field this build doesn\'t know is kept', () async {
        final s = await unresolved();
        final stored = await json(insightsKey);
        final snaps = (stored['snapshots'] as List)
            .cast<Map<String, Object?>>();
        final mine = snaps.firstWhere((x) => x['id'] == s.id);
        pre(mine['attempt'] is Map, 'an attempt record on this tree');
        final seen = <String, String>{};
        for (final (label, value) in <(String, Object?)>[
          ('not a map', 'soon'),
          (
            'no day',
            <String, Object?>{'target': (mine['attempt'] as Map)['target']},
          ),
          (
            'bad day',
            <String, Object?>{...(mine['attempt'] as Map), 'on': '30-10-2026'},
          ),
          (
            'other target',
            <String, Object?>{
              ...(mine['attempt'] as Map),
              'target': 'leaveOut:x',
            },
          ),
          (
            'future field',
            <String, Object?>{...(mine['attempt'] as Map), 'future': 1},
          ),
        ]) {
          final raw = {...mine, 'attempt': value};
          final read = InsightSnapshot.fromJson(raw);
          seen[label] = read == null
              ? 'UNREADABLE'
              : jsonEncode(read.toJson()['attempt']);
        }
        evidence('R2', seen);
        expect(seen['not a map'], 'UNREADABLE');
        expect(seen['no day'], 'UNREADABLE');
        expect(seen['bad day'], 'UNREADABLE');
        expect(seen['other target'], 'UNREADABLE');
        expect(jsonDecode(seen['future field']!)['future'], 1);
      });

      test('R3 Delete Circle history removes it with the snapshots; the '
          'user\'s choices stay', () async {
        final s = await unresolved();
        await h.restart();
        final c = h.open();
        await c.read(circleHistoryDeletionProvider).delete();
        await R8Harness.settle();
        expect(await snapshotOnDisk(s.id), isNull);
        expect((await h.disk.stored())[insightsKey], isNull);
        expect(
          await leftOutAfterRestart(),
          isNot(contains(ElementId.openWindow)),
        );
      });
    });

    group('Controls — I1 and I2 unchanged', () {
      test('I1 applied: the Plan is started, marked that day', () async {
        final (c, s) = await shown(i1, InsightFamily.planForNeed);
        expect(await insights(c).apply(s.id), InsightActionResult.done);
        await R8Harness.settle();
        expect((await snapshotOnDisk(s.id))?['appliedOn'], dateKey(morning));
        expect((await snapshotOnDisk(s.id))?['attempt'], isNull);
      });
      test('I2 applied: the cycle is gentler, marked that day', () async {
        final (c, s) = await shown(i2, InsightFamily.planPacing);
        expect(await insights(c).apply(s.id), InsightActionResult.done);
        await R8Harness.settle();
        final plan = (await json(circlePlansKey))['plans'] as Map;
        final cycle = ((plan['getting_going'] as Map)['cycles'] as List).last;
        expect((cycle as Map)['gentlerSince'], isNotNull);
        expect((await snapshotOnDisk(s.id))?['appliedOn'], dateKey(morning));
      });
    });
  });

  // -----------------------------------------------------------------------
  // N01-C — a lifecycle change cancels an unresolved Start.

  group('N01-C — founder temporal policy', () {
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
    RecommendationStatus status(ProviderContainer c) =>
        c.read(recommendationProvider).status;

    Future<Map<String, Object?>> planOnDisk() async {
      final raw = (await h.disk.stored())[circlePlansKey];
      if (raw is! String) return {};
      return (((jsonDecode(raw) as Map)['plans'] as Map)['getting_going']
                  as Map?)
              ?.cast<String, Object?>() ??
          {};
    }

    Future<int> credits(String circleId) async {
      var n = 0;
      for (final c in (await planOnDisk())['cycles'] as List? ?? []) {
        for (final r in (c as Map)['records'] as List) {
          if ((r as Map)['circleId'] == circleId) n++;
        }
      }
      return n;
    }

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

    Future<void> close(ProviderContainer c) async {
      h.clock.value = h.clock.value.add(const Duration(minutes: 25));
      today(c).close();
      await R8Harness.settle();
    }

    /// The Plan [paused] or active; today's stage Circle chosen, its offer
    /// save held; Start tapped — pending.
    Future<(ProviderContainer, String, HeldWrite)> pendingStart({
      required bool paused,
    }) async {
      final c = h.open();
      expect(plans(c).start('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      final held = h.disk.hold(recommendationPendingWriteKey);
      today(
        c,
      ).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await held.reached;
      final id = c.read(recommendationProvider).recommendation!.circleId;
      if (paused) {
        expect(plans(c).pause('getting_going'), PlanActionResult.done);
        await R8Harness.settle();
        pre((await planOnDisk())['lifecycle'] == 'paused', 'paused on disk');
      }
      today(c).start();
      await R8Harness.settle();
      expect(status(c), RecommendationStatus.notStarted);
      return (c, id, held);
    }

    Future<Map<String, Object?>> facts(ProviderContainer c, String id) async =>
        {
          'status': status(c).name,
          'credits': await credits(id),
          'lifecycle': (await planOnDisk())['lifecycle'],
          'startedWhilePaused': (await planOnDisk())['startedWhilePaused'],
          'dayStatus': (await h.disk.stored())[recommendationStatusKey],
        };

    test('N1 Paused → Start pending → Resume confirmed → the prerequisite '
        'resolves: the Start is cancelled; a fresh Start on the active Plan '
        'is credited once', () async {
      final (c, id, held) = await pendingStart(paused: true);
      expect(plans(c).resume('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      held.release();
      await R8Harness.settle();
      final cancelled = await facts(c, id);
      today(c).start();
      await R8Harness.settle();
      final restarted = status(c);
      await close(c);
      await restart(times: 2);
      evidence('N1', {
        'afterPrerequisite': cancelled,
        'freshStart': restarted.name,
        ...await facts(c, id),
      });
      expect(cancelled['status'], RecommendationStatus.notStarted.name);
      expect(cancelled['startedWhilePaused'], isNull);
      expect(restarted, RecommendationStatus.started);
      expect(await credits(id), 1);
    });

    test('N2 Active → Start pending → Pause confirmed → the prerequisite '
        'resolves: the Start is cancelled; a fresh Start on the paused Plan '
        'is never credited', () async {
      final (c, id, held) = await pendingStart(paused: false);
      expect(plans(c).pause('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      held.release();
      await R8Harness.settle();
      final cancelled = await facts(c, id);
      today(c).start();
      await R8Harness.settle();
      final restarted = status(c);
      await close(c);
      expect(plans(c).resume('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      await restart(times: 2);
      evidence('N2', {
        'afterPrerequisite': cancelled,
        'freshStart': restarted.name,
        ...await facts(c, id),
      });
      expect(cancelled['status'], RecommendationStatus.notStarted.name);
      expect(restarted, RecommendationStatus.started);
      expect(await credits(id), 0);
    });

    test('N3 the Pause is refused by the store: the Plan stayed active, so '
        'the pending Start goes ahead and is credited once', () async {
      final (c, id, held) = await pendingStart(paused: false);
      h.disk.fail(circlePlansKey, DiskFault.returnsFalse, times: 1);
      expect(
        await plans(c).confirmed((p) => p.pause('getting_going')),
        PlanActionResult.notSaved,
      );
      held.release();
      await R8Harness.settle();
      final started = status(c);
      await close(c);
      await restart(times: 2);
      evidence('N3', {
        'afterPrerequisite': started.name,
        ...await facts(c, id),
      });
      expect(started, RecommendationStatus.started);
      expect(await credits(id), 1);
    });

    test('N4 the Resume is refused by the store: the Plan stayed paused, so '
        'the pending Start goes ahead without credit', () async {
      final (c, id, held) = await pendingStart(paused: true);
      h.disk.fail(circlePlansKey, DiskFault.returnsFalse, times: 1);
      expect(
        await plans(c).confirmed((p) => p.resume('getting_going')),
        PlanActionResult.notSaved,
      );
      held.release();
      await R8Harness.settle();
      final started = status(c);
      await close(c);
      expect(plans(c).resume('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      await restart(times: 2);
      evidence('N4', {
        'afterPrerequisite': started.name,
        ...await facts(c, id),
      });
      expect(started, RecommendationStatus.started);
      expect(await credits(id), 0);
    });

    test('N5 the paused-Start record is refused: the Start is refused; the '
        'next tap starts without credit', () async {
      final (c, id, held) = await pendingStart(paused: true);
      h.disk.fail(circlePlansKey, DiskFault.returnsFalse, times: 1);
      held.release();
      await R8Harness.settle();
      final refused = status(c);
      today(c).start();
      await R8Harness.settle();
      final again = status(c);
      await close(c);
      expect(plans(c).resume('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      await restart(times: 2);
      evidence('N5', {
        'first': refused.name,
        'again': again.name,
        ...await facts(c, id),
      });
      expect(refused, RecommendationStatus.notStarted);
      expect(again, RecommendationStatus.started);
      expect(await credits(id), 0);
    });

    test('N6 repeated taps during a pending Start, and after its '
        'cancellation, start the Circle once', () async {
      final (c, id, held) = await pendingStart(paused: true);
      today(c).start();
      expect(plans(c).resume('getting_going'), PlanActionResult.done);
      today(c).start();
      await R8Harness.settle();
      held.release();
      await R8Harness.settle();
      today(c).start();
      today(c).start();
      await R8Harness.settle();
      final journal = c
          .read(circleJournalRepositoryProvider)
          .readAll()
          .where((e) => e.circleId == id)
          .toList();
      evidence('N6', {'journal': journal.length, ...await facts(c, id)});
      expect(status(c), RecommendationStatus.started);
      expect(journal.length, 1);
    });

    test('N7 a restart after the cancellation: nothing was started, no '
        'paused-Start record; a fresh Start is credited once', () async {
      final (c, id, held) = await pendingStart(paused: true);
      expect(plans(c).resume('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      held.release();
      await R8Harness.settle();
      pre(status(c) == RecommendationStatus.notStarted, 'cancelled');
      final c2 = await restart();
      final restored = await facts(c2, id);
      today(c2).start();
      await R8Harness.settle();
      await close(c2);
      await restart(times: 2);
      evidence('N7', {'restored': restored, ...await facts(c2, id)});
      expect(restored['status'], RecommendationStatus.notStarted.name);
      expect(restored['startedWhilePaused'], isNull);
      expect(await credits(id), 1);
    });

    test(
      'N8 Resume tapped while the paused Start\'s own record is being '
      'written: the Start is cancelled once the Resume is confirmed; the '
      'record left excludes nothing; a fresh Start is credited once',
      () async {
        final c = h.open();
        expect(plans(c).start('getting_going'), PlanActionResult.done);
        today(
          c,
        ).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
        await R8Harness.settle();
        final id = c.read(recommendationProvider).recommendation!.circleId;
        expect(plans(c).pause('getting_going'), PlanActionResult.done);
        await R8Harness.settle();
        final held = h.disk.hold(circlePlansKey);
        today(c).start();
        var arrived = true;
        await held.reached.timeout(
          const Duration(seconds: 2),
          onTimeout: () => arrived = false,
        );
        pre(arrived, 'a paused-Start write');
        expect(plans(c).resume('getting_going'), PlanActionResult.done);
        held.release();
        await R8Harness.settle();
        final cancelled = await facts(c, id);
        h.clock.value = h.clock.value.add(const Duration(minutes: 1));
        today(c).start();
        await R8Harness.settle();
        final fresh = status(c);
        await close(c);
        await restart(times: 2);
        evidence('N8', {
          'afterRecord': cancelled,
          'freshStart': fresh.name,
          ...await facts(c, id),
        });
        expect(cancelled['status'], RecommendationStatus.notStarted.name);
        expect(fresh, RecommendationStatus.started);
        expect(await credits(id), 1);
      },
    );

    test('N-ctl Start → Pause → Close (a valid Start before the Pause) is '
        'credited once, also after restarts', () async {
      final c = h.open();
      expect(plans(c).start('getting_going'), PlanActionResult.done);
      today(
        c,
      ).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await R8Harness.settle();
      final id = c.read(recommendationProvider).recommendation!.circleId;
      today(c).start();
      await R8Harness.settle();
      expect(status(c), RecommendationStatus.started);
      expect(plans(c).pause('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      await close(c);
      await restart(times: 2);
      expect(await credits(id), 1);
    });
  });
}
