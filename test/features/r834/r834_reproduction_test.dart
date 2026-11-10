import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_history_deletion.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/insights/domain/insight_engine.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/kept_circle.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// Every call answers the same: two ids allocated at one event-clock instant
/// collide unless the Kept Circles domain itself keeps them apart.
class _StuckRandom implements Random {
  @override
  int nextInt(int max) => 7 % max;
  @override
  double nextDouble() => 0.5;
  @override
  bool nextBool() => false;
}

/// R8.3.4 — final action identity closure: the reproduction gate (founder
/// directive, 2026-11-10).
///
/// - R833-A02 (Astra, MEDIUM): a later I4 of the SAME source Circle, its
///   kept id forced equal to an earlier unresolved I4 attempt's, falsely
///   proves that earlier attempt.
/// - R833-A01 / AUD-R833-1 (Astra / Claude, LOW): an I3/I4 attempt lands
///   while a Delete intent is in the store's memory but not confirmed; the
///   Delete is then refused, and the attempt is stranded, its action never
///   made.
/// - R833-A03 (Astra, LOW): a Keep's id reservation ends before its write
///   settles, so a second valid Keep under a forced collision is lost.
///
/// Only APIs present at R8.3.3 (285b5c70) are used, so the same file runs
/// on that tree and on the corrected one. Each test prints one
/// `R834-EVIDENCE` line with what reached the disk. A step a tree can't
/// construct fails with `PRECONDITION` (not applicable there).
void main() {
  void evidence(String id, Map<String, Object?> facts) {
    // ignore: avoid_print
    print('R834-EVIDENCE ${jsonEncode({'test': id, ...facts})}');
  }

  void pre(bool holds, String what) {
    if (!holds) fail('PRECONDITION not constructible on this tree: $what');
  }

  final morning = DateTime(2026, 10, 30, 9);
  late R8Harness h;

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
      session: parts.isEmpty
          ? null
          : CircleSessionRecord(
              title: 'Circle',
              parts: CirclePlan(parts).toWire(),
              skipped: [for (final e in skipped) e.name],
            ),
    );
  }

  String journalOf(List<CircleJournalEntry> entries) => jsonEncode({
    'schemaVersion': circleJournalSchemaVersion,
    'entries': [for (final e in entries) e.toJson()],
  });

  // I3: "Open a window" skipped in 3 of its last 4 Circles.
  final i3Journal = [
    for (final ago in [2, 4, 6, 8, 10, 12, 15])
      entry(ago, head, parts: reading),
    for (final (k, ago) in [1, 5, 9, 11].indexed)
      entry(
        ago,
        energy,
        parts: window,
        skipped: k == 1 ? const {} : {ElementId.openWindow},
      ),
  ];
  // I4: Writing in all 4 useful Clearer Head Circles; keeps 2026-10-29.
  final i4Journal = [
    for (final ago in [1, 7, 13, 20])
      entry(ago, head, parts: writing, useful: true),
    for (final ago in [3, 9, 16]) entry(ago, head, parts: reading),
  ];
  const source = '2026-10-29';

  InsightsNotifier insights(ProviderContainer c) =>
      c.read(insightsProvider.notifier);
  KeptCirclesNotifier keptN(ProviderContainer c) =>
      c.read(keptCirclesProvider.notifier);

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

  Future<List<Map>> keptOnDisk() async => [
    for (final k in (await json(keptCirclesKey))['kept'] as List? ?? [])
      k as Map,
  ];

  Future<Object?> outcome(Future<void> deleting) =>
      deleting.then<Object?>((_) => null, onError: (Object e) => e);

  final stuck = keptIdRandomProvider.overrideWithValue(_StuckRandom());

  // =======================================================================
  // R833-A02 — exact I4 action identity, same source Circle.

  group('R833-A02 — a later I4 of the same source never proves an earlier '
      'unresolved attempt', () {
    setUp(() async {
      h = R8Harness(morning);
      await h.boot();
    });

    /// I4-A generated by production assess() on 2026-10-30, keeping
    /// [source]; retained thirty days, no newer useful Circle added. Its
    /// Keep throws before landing (uncertain): its attempt stays, nothing
    /// is kept. Every id from here on is allocated at one event-clock
    /// instant with a stuck random part.
    Future<(ProviderContainer, InsightSnapshot, Map)> olderUncertain({
      bool restartAfterAttempt = false,
    }) async {
      await h.boot({circleJournalKey: journalOf(i4Journal)});
      final c = h.open();
      final older = insights(c).assess().added.single;
      pre(older.family == InsightFamily.usefulInCommon, 'I4-A generated');
      await R8Harness.settle();
      final stored = await h.disk.stored();
      h.clock.value = morning.add(const Duration(days: 30));
      await h.boot(stored);
      var c2 = h.open(overrides: [stuck]);
      h.disk.fail(keptCirclesKey, DiskFault.throws, times: 1);
      final first = await insights(c2).apply(older.id);
      pre(first == InsightActionResult.notSaved, 'I4-A\'s Keep throws');
      await R8Harness.settle();
      final receipt = (await snapshotOnDisk(older.id))?['attempt'] as Map?;
      pre(receipt != null, 'I4-A\'s attempt retained (uncertain)');
      pre((await keptOnDisk()).isEmpty, 'nothing landed for I4-A');
      if (restartAfterAttempt) {
        await h.restart();
        c2 = h.open(overrides: [stuck]);
      }
      return (c2, older, receipt!);
    }

    /// I4-B: generated by production assess(), a distinct snapshot of the
    /// very same source Circle.
    Future<InsightSnapshot> sameSourceNewer(
      ProviderContainer c,
      InsightSnapshot older,
    ) async {
      final newer = insights(c)
          .assess()
          .added
          .where((s) => s.family == InsightFamily.usefulInCommon)
          .firstOrNull;
      await R8Harness.settle();
      pre(newer != null, 'I4-B generated');
      pre(newer!.id != older.id, 'I4-B is a distinct snapshot');
      pre(
        (newer.application as KeepCircleFromHistory).circleId == source,
        'I4-B keeps the same source Circle',
      );
      return newer;
    }

    for (final restart in [false, true]) {
      final label = restart ? 'A02-2' : 'A02-1';
      test('$label (Astra R833-A02) I4-B of the same source applied under '
          'a forced collision${restart ? ', after a restart' : ''}: only B '
          'is Applied; A keeps its unresolved attempt through reassessment, '
          'retry and restart; one kept Circle', () async {
        final (c, older, receiptA) = await olderUncertain(
          restartAfterAttempt: restart,
        );
        final newer = await sameSourceNewer(c, older);
        final applied = await insights(c).apply(newer.id);
        await R8Harness.settle();
        final kept = await keptOnDisk();
        insights(c).assess();
        await R8Harness.settle();
        final aAfterAssess = await snapshotOnDisk(older.id);
        final retryA = await insights(c).apply(older.id);
        await R8Harness.settle();
        await h.restart();
        final c3 = h.open();
        insights(c3).assess();
        await R8Harness.settle();
        final aAfterRestart = await snapshotOnDisk(older.id);
        final bAfterRestart = await snapshotOnDisk(newer.id);
        evidence('$label same-source', {
          'receiptA': receiptA,
          'applyB': applied.name,
          'kept': [
            for (final k in kept) [k['id'], k['fromCircleId']],
          ],
          'aAfterAssess': {
            'appliedOn': aAfterAssess?['appliedOn'],
            'attempt': aAfterAssess?['attempt'],
          },
          'retryA': retryA.name,
          'aAfterRestart': {
            'appliedOn': aAfterRestart?['appliedOn'],
            'attempt': aAfterRestart?['attempt'],
          },
          'bAfterRestart': {
            'appliedOn': bAfterRestart?['appliedOn'],
            'attempt': bAfterRestart?['attempt'],
          },
        });
        expect(applied, InsightActionResult.done);
        expect(
          aAfterAssess?['appliedOn'],
          isNull,
          reason: 'I4-A marked Applied by I4-B\'s Keep',
        );
        expect(aAfterAssess?['attempt'], receiptA);
        expect(retryA, InsightActionResult.notAvailable);
        expect(aAfterRestart?['appliedOn'], isNull);
        expect(aAfterRestart?['attempt'], receiptA);
        expect(bAfterRestart?['appliedOn'], dateKey(h.clock.value));
        expect(bAfterRestart?['attempt'], isNull);
        expect(kept, hasLength(1), reason: 'no second kept Circle');
        expect(kept.single['fromCircleId'], source);
        expect(kept.single['id'], isNot(receiptA['keptId']));
      });
    }

    test('A02-3 a stored record in which two attempts name one kept id (only '
        'writable before R8.3.4) proves neither of them', () async {
      final (c, older, receiptA) = await olderUncertain();
      final newer = await sameSourceNewer(c, older);
      final keptId = receiptA['keptId'] as String;
      // The kept Circle with that very id, from the same source.
      final made = await keptN(c).keepCircle(
        plan: CirclePlan(writing),
        need: head,
        circleId: source,
        id: keptId,
      );
      await R8Harness.settle();
      pre(made?.id == keptId, 'the kept Circle with the recorded id');
      final stored = await h.disk.stored();
      final record = jsonDecode(stored[insightsKey]! as String) as Map;
      record['snapshots'] = [
        for (final s in record['snapshots'] as List)
          (s as Map)['id'] == newer.id ? {...s, 'attempt': receiptA} : s,
      ];
      await h.boot({...stored, insightsKey: jsonEncode(record)});
      final c2 = h.open();
      insights(c2).assess();
      await R8Harness.settle();
      final a = await snapshotOnDisk(older.id);
      final b = await snapshotOnDisk(newer.id);
      evidence('A02-3 one id, two attempts', {
        'keptId': keptId,
        'a': {'appliedOn': a?['appliedOn'], 'attempt': a?['attempt']},
        'b': {'appliedOn': b?['appliedOn'], 'attempt': b?['attempt']},
        'kept': [
          for (final k in await keptOnDisk()) [k['id'], k['fromCircleId']],
        ],
      });
      expect(a?['appliedOn'], isNull, reason: 'an id two attempts name');
      expect(b?['appliedOn'], isNull, reason: 'an id two attempts name');
      expect(a?['attempt'], receiptA);
      expect(b?['attempt'], receiptA);
      expect(await keptOnDisk(), hasLength(1));
    });

    test('A02-4 control: I4\'s own Keep lands and the app stops before the '
        'mark; reassessed after a restart, it is Applied from its own kept '
        'Circle', () async {
      await h.boot({circleJournalKey: journalOf(i4Journal)});
      final c = h.open(overrides: [stuck]);
      final shown = insights(c).assess().added.single;
      await R8Harness.settle();
      h.disk.ackLost(keptCirclesKey, thenStop: true);
      insights(c).apply(shown.id).ignore();
      await R8Harness.settle();
      await h.restart();
      final c2 = h.open();
      insights(c2).assess();
      await R8Harness.settle();
      final s = await snapshotOnDisk(shown.id);
      final kept = await keptOnDisk();
      evidence('A02-4 own proof', {
        'snapshot': {'appliedOn': s?['appliedOn'], 'attempt': s?['attempt']},
        'kept': [
          for (final k in kept) [k['id'], k['fromCircleId']],
        ],
      });
      expect(kept, hasLength(1));
      expect(s?['appliedOn'], dateKey(morning));
      expect(s?['attempt'], isNull);
    });

    test('A02-5 control: the user\'s own Keep of the same source under the '
        'forced collision is never I4-A\'s proof', () async {
      final (c, older, receiptA) = await olderUncertain();
      final manual = await keptN(
        c,
      ).keepCircle(plan: CirclePlan(writing), need: head, circleId: source);
      await R8Harness.settle();
      insights(c).assess();
      await R8Harness.settle();
      final a = await snapshotOnDisk(older.id);
      final retry = await insights(c).apply(older.id);
      evidence('A02-5 manual Keep', {
        'receiptA': receiptA,
        'manual': manual?.id,
        'a': {'appliedOn': a?['appliedOn'], 'attempt': a?['attempt']},
        'retry': retry.name,
      });
      expect(manual, isNotNull);
      expect(manual!.id, isNot(receiptA['keptId']));
      expect(a?['appliedOn'], isNull);
      expect(a?['attempt'], receiptA);
      expect(retry, InsightActionResult.notAvailable);
      expect(await keptOnDisk(), hasLength(1));
    });

    test('A02-6 control: a retained (unreadable) kept record with the '
        'recorded id and the same source is never proof', () async {
      final (_, older, receiptA) = await olderUncertain();
      final stored = await h.disk.stored();
      await h.boot({
        ...stored,
        keptCirclesKey: jsonEncode({
          'schemaVersion': keptCirclesSchemaVersion,
          'kept': [
            {
              'id': receiptA['keptId'],
              'name': 'Damaged',
              'fromCircleId': source,
              'parts': 'not parts',
            },
          ],
        }),
      });
      final c2 = h.open();
      pre(
        c2.read(keptCirclesProvider).retained.length == 1,
        'the record is retained, unread',
      );
      insights(c2).assess();
      await R8Harness.settle();
      final a = await snapshotOnDisk(older.id);
      evidence('A02-6 retained record', {
        'a': {'appliedOn': a?['appliedOn'], 'attempt': a?['attempt']},
      });
      expect(a?['appliedOn'], isNull);
      expect(a?['attempt'], receiptA);
    });

    test('A02-7 control: Delete Circle history after the same-source case '
        'removes both snapshots; the one kept Circle stays, as stored, with '
        'no Insight id in it', () async {
      final (c, older, _) = await olderUncertain();
      final newer = await sameSourceNewer(c, older);
      expect(await insights(c).apply(newer.id), InsightActionResult.done);
      await R8Harness.settle();
      final before = await keptOnDisk();
      await c.read(circleHistoryDeletionProvider).delete();
      await R8Harness.settle();
      final after = await keptOnDisk();
      final stored = await h.disk.stored();
      evidence('A02-7 Delete', {
        'keptBefore': before,
        'keptAfter': after,
        'insights': stored[insightsKey],
      });
      expect(stored[insightsKey], isNull);
      expect(after, before);
      expect(after.single.keys.toSet(), {
        'id',
        'name',
        'need',
        'parts',
        'createdAt',
        'fromCircleId',
        'wording',
      });
      final text = jsonEncode(after);
      expect(text.contains(older.id) || text.contains(newer.id), isFalse);
    });
  });

  // =======================================================================
  // R833-A01 / AUD-R833-1 — a Delete intent that isn't confirmed yet.

  group('R833-A01 / AUD-R833-1 — an I3/I4 attempt landing while a Delete '
      'intent is being recorded', () {
    setUp(() async {
      h = R8Harness(morning);
      await h.boot();
    });

    /// The intent's two writes: `refused` both answer false; `uncertain` the
    /// first throws, the second answers false; `retried` the first answers
    /// false and the second lands; `accepted` the first lands.
    Future<void> answerIntent(HeldWrite intent, String how) async {
      switch (how) {
        case 'refused':
          h.disk.fail(historyDeletionPendingKey, DiskFault.returnsFalse);
          intent.release(DiskFault.returnsFalse);
        case 'uncertain':
          h.disk.fail(historyDeletionPendingKey, DiskFault.returnsFalse);
          intent.release(DiskFault.throws);
        case 'retried':
          intent.release(DiskFault.returnsFalse);
        case 'accepted':
          intent.release();
      }
    }

    for (final family in ['I3', 'I4']) {
      final i3 = family == 'I3';

      Future<(ProviderContainer, InsightSnapshot)> shownInsight() async {
        await h.boot({circleJournalKey: journalOf(i3 ? i3Journal : i4Journal)});
        final c = h.open();
        final shown = insights(c).assess().added.single;
        pre(
          shown.family ==
              (i3 ? InsightFamily.skippedPart : InsightFamily.usefulInCommon),
          '$family generated',
        );
        await R8Harness.settle();
        return (c, shown);
      }

      /// What the action made, on disk: the part left out by this Insight,
      /// or a Circle kept from its source.
      Future<bool> targetMade(String insightId) async {
        if (i3) {
          final prefs = (await h.disk.stored())[suggestionPreferencesKey];
          return prefs is String &&
              prefs.contains('"openWindow"') &&
              prefs.contains(insightId);
        }
        return (await keptOnDisk()).any((k) => k['fromCircleId'] == source);
      }

      for (final how in ['refused', 'accepted', 'uncertain', 'retried']) {
        test('$family-${how.toUpperCase()} the attempt lands while the '
            'intent is held; the intent is then $how', () async {
          final (c, shown) = await shownInsight();
          final epoch = c.read(historyWriteGateProvider).epoch;
          final receipt = h.disk.hold(insightsKey);
          final applying = insights(c).apply(shown.id);
          await receipt.reached;
          final intent = h.disk.hold(historyDeletionPendingKey);
          final deleting = outcome(
            c.read(circleHistoryDeletionProvider).delete(),
          );
          await intent.reached;
          pre(
            h.prefs.get(historyDeletionPendingKey) == true,
            'the intent is in the store\'s memory',
          );
          pre(
            (await h.disk.stored())[historyDeletionPendingKey] == null,
            'the intent is not on disk',
          );
          receipt.release();
          await R8Harness.settle();
          await answerIntent(intent, how);
          final deleteError = await deleting;
          h.disk.heal(historyDeletionPendingKey);
          final result = await applying;
          await R8Harness.settle();
          final s = await snapshotOnDisk(shown.id);
          final made = await targetMade(shown.id);
          final stored = await h.disk.stored();
          final finalEpoch = c.read(historyWriteGateProvider).epoch;
          await h.restart();
          final c2 = h.open();
          final restored = insights(c2).state.byId(shown.id);
          final restoredStatus = restored == null
              ? null
              : insights(c2).status(restored).name;
          final retry = await insights(c2).apply(shown.id);
          await R8Harness.settle();
          final madeAfterRetry = await targetMade(shown.id);
          final keptAfter = await keptOnDisk();
          evidence('$family-$how', {
            'apply': result.name,
            'deleteError': deleteError?.toString(),
            'epoch': [epoch, finalEpoch],
            'snapshot': s == null
                ? null
                : {'appliedOn': s['appliedOn'], 'attempt': s['attempt']},
            'targetMade': made,
            'pendingOnDisk': stored[historyDeletionPendingKey],
            'journalKept': stored.containsKey(circleJournalKey),
            'restoredStatus': restoredStatus,
            'retry': retry.name,
            'targetMadeAfterRetry': madeAfterRetry,
            'kept': keptAfter.length,
          });
          switch (how) {
            case 'refused':
              expect(deleteError, isA<HistoryDeletionNotStarted>());
              expect(finalEpoch, epoch);
              expect(stored[historyDeletionPendingKey], isNull);
              expect(stored[circleJournalKey], isNotNull);
              expect(
                result,
                InsightActionResult.done,
                reason: 'a refused Delete stranded the attempt',
              );
              expect(s?['attempt'], isNull);
              expect(s?['appliedOn'], dateKey(morning));
              expect(made, isTrue);
              expect(restoredStatus, InsightStatus.applied.name);
              expect(retry, InsightActionResult.alreadyApplied);
              if (!i3) expect(keptAfter, hasLength(1));
            case 'uncertain':
              // Fail safe: the deletion may be on disk; nothing is made, the
              // attempt stays, and it is never made later.
              expect(deleteError, isA<HistoryDeletionNotStarted>());
              expect(finalEpoch, epoch);
              expect(result, InsightActionResult.notAvailable);
              expect(s?['attempt'], isNotNull);
              expect(s?['appliedOn'], isNull);
              expect(made, isFalse);
              expect(restoredStatus, InsightStatus.stale.name);
              expect(retry, InsightActionResult.notAvailable);
              expect(madeAfterRetry, isFalse);
            case 'accepted' || 'retried':
              // The deletion began: nothing is made, its Insight is gone.
              expect(deleteError, isNull);
              expect(finalEpoch, epoch + 1);
              expect(result, InsightActionResult.notAvailable);
              expect(s, isNull);
              expect(made, isFalse);
              expect(stored[historyDeletionPendingKey], isNull);
              expect(stored[circleJournalKey], isNull);
              expect(madeAfterRetry, isFalse);
          }
        });
      }

      for (final how in ['refused', 'accepted']) {
        test('$family-CLEAR-${how.toUpperCase()} the action\'s own write is '
            'refused while the intent is held; the intent is then $how: '
            '${how == 'refused' ? 'the attempt is cleared and a retry makes '
                      'the action once' : 'nothing is made'}', () async {
          final (c, shown) = await shownInsight();
          final targetKey = i3 ? suggestionPreferencesKey : keptCirclesKey;
          final target = h.disk.hold(targetKey);
          final applying = insights(c).apply(shown.id);
          await target.reached;
          pre(
            (await snapshotOnDisk(shown.id))?['attempt'] != null,
            'the attempt is on disk',
          );
          final intent = h.disk.hold(historyDeletionPendingKey);
          final deleting = outcome(
            c.read(circleHistoryDeletionProvider).delete(),
          );
          await intent.reached;
          target.release(DiskFault.returnsFalse);
          await R8Harness.settle();
          await answerIntent(intent, how);
          final deleteError = await deleting;
          h.disk.heal(historyDeletionPendingKey);
          final result = await applying;
          await R8Harness.settle();
          final s = await snapshotOnDisk(shown.id);
          final status = insights(c).state.byId(shown.id) == null
              ? null
              : insights(c).status(insights(c).state.byId(shown.id)!).name;
          final retry = await insights(c).apply(shown.id);
          await R8Harness.settle();
          final again = await insights(c).apply(shown.id);
          await R8Harness.settle();
          final made = await targetMade(shown.id);
          final keptAfter = await keptOnDisk();
          evidence('$family-clear-$how', {
            'apply': result.name,
            'deleteError': deleteError?.toString(),
            'attemptAfter': s?['attempt'],
            'status': status,
            'retry': retry.name,
            'again': again.name,
            'targetMade': made,
            'kept': keptAfter.length,
          });
          expect(result, InsightActionResult.notSaved);
          if (how == 'refused') {
            expect(deleteError, isA<HistoryDeletionNotStarted>());
            expect(
              s?['attempt'],
              isNull,
              reason:
                  'a refused Delete left the attempt of an action '
                  'known not to have been made',
            );
            expect(status, InsightStatus.current.name);
            expect(retry, InsightActionResult.done);
            expect(again, InsightActionResult.alreadyApplied);
            expect(made, isTrue);
            if (!i3) expect(keptAfter, hasLength(1));
          } else {
            expect(deleteError, isNull);
            expect(s, isNull);
            expect(made, isFalse);
          }
        });
      }
    }
  });

  // =======================================================================
  // R833-A03 — a Keep holds its id until it has settled.

  group('R833-A03 — Keep id reservations last until the Keep settles', () {
    setUp(() async {
      h = R8Harness(morning);
      await h.boot();
    });

    test('A03-1 (Astra R833-A03) a second Keep of another day while the '
        'first write is held, under a forced collision: both succeed, with '
        'distinct ids', () async {
      final c = h.open(overrides: [stuck]);
      final held = h.disk.hold(keptCirclesKey);
      final first = keptN(
        c,
      ).keepCircle(plan: CirclePlan(writing), need: head, circleId: source);
      await held.reached;
      final second = keptN(c).keepCircle(
        plan: CirclePlan(reading),
        need: head,
        circleId: '2026-10-27',
      );
      final third = keptN(c).keepCircle(
        plan: CirclePlan(window),
        need: energy,
        circleId: '2026-10-26',
      );
      held.release();
      final a = await first;
      final b = await second;
      final d = await third;
      await R8Harness.settle();
      final ids = [for (final k in await keptOnDisk()) k['id']];
      evidence('A03-1 held write', {
        'results': [a?.id, b?.id, d?.id],
        'onDisk': ids,
      });
      expect(a, isNotNull);
      expect(b, isNotNull, reason: 'a valid Keep lost to a reused id');
      expect(d, isNotNull);
      expect({a!.id, b!.id, d!.id}, hasLength(3));
      expect(ids, [a.id, b.id, d.id]);
    });

    test('A03-2 control: an id a Keep under way holds is refused for another '
        'Keep; nothing duplicated', () async {
      final c = h.open(overrides: [stuck]);
      final held = h.disk.hold(keptCirclesKey);
      final first = keptN(
        c,
      ).keepCircle(plan: CirclePlan(writing), need: head, circleId: source);
      await held.reached;
      final heldId =
          (jsonDecode(h.prefs.getString(keptCirclesKey)!)
                  as Map)['kept'][0]['id']
              as String;
      final second = keptN(c).keepCircle(
        plan: CirclePlan(reading),
        need: head,
        circleId: '2026-10-27',
        id: heldId,
      );
      held.release();
      final a = await first;
      final b = await second;
      await R8Harness.settle();
      final ids = [for (final k in await keptOnDisk()) k['id']];
      evidence('A03-2 held id', {'heldId': heldId, 'b': b?.id, 'onDisk': ids});
      expect(a?.id, heldId);
      expect(b, isNull);
      expect(ids, [heldId]);
    });

    for (final fault in DiskFault.values) {
      test('A03-3 control: a Keep whose write ${fault.name} releases its id; '
          'the next Keep is given it, and only one record is stored', () async {
        final c = h.open(overrides: [stuck]);
        final expected = keptN(c).newKeptId();
        h.disk.fail(keptCirclesKey, fault, times: 1);
        Object? error;
        try {
          await keptN(
            c,
          ).keepCircle(plan: CirclePlan(writing), need: head, circleId: source);
        } catch (e) {
          error = e;
        }
        await R8Harness.settle();
        final next = await keptN(c).keepCircle(
          plan: CirclePlan(reading),
          need: head,
          circleId: '2026-10-27',
        );
        await R8Harness.settle();
        final ids = [for (final k in await keptOnDisk()) k['id']];
        evidence('A03-3 ${fault.name}', {
          'error': error?.toString(),
          'next': next?.id,
          'onDisk': ids,
        });
        expect(error, isNotNull);
        expect(next?.id, expected);
        expect(ids, [expected]);
      });
    }

    test('A03-4 control: Keeps under way count toward the limit; a Keep of a '
        'day already being kept is refused', () async {
      final c = h.open(overrides: [stuck]);
      for (var d = 1; d <= maxKeptCircles - 1; d++) {
        expect(
          await keptN(c).keepCircle(
            plan: CirclePlan(reading),
            need: head,
            circleId: '2026-09-${'$d'.padLeft(2, '0')}',
          ),
          isNotNull,
        );
      }
      await R8Harness.settle();
      final held = h.disk.hold(keptCirclesKey);
      final last = keptN(
        c,
      ).keepCircle(plan: CirclePlan(writing), need: head, circleId: source);
      await held.reached;
      final overKeep = keptN(c).keepCircle(
        plan: CirclePlan(reading),
        need: head,
        circleId: '2026-10-27',
      );
      final sameDayKeep = keptN(
        c,
      ).keepCircle(plan: CirclePlan(writing), need: head, circleId: source);
      held.release();
      final over = await overKeep;
      final sameDay = await sameDayKeep;
      final landed = await last;
      await R8Harness.settle();
      final kept = await keptOnDisk();
      evidence('A03-4 limit', {
        'over': over?.id,
        'sameDay': sameDay?.id,
        'landed': landed?.id,
        'count': kept.length,
      });
      expect(over, isNull);
      expect(sameDay, isNull);
      expect(landed, isNotNull);
      expect(kept, hasLength(maxKeptCircles));
      expect({for (final k in kept) k['id']}, hasLength(maxKeptCircles));
    });
  });
}
