import 'dart:convert';

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

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// R8.3.4.1 — Delete outcome continuity (founder directive, 2026-11-11).
///
/// Astra R834-N01: an I3/I4 already waiting on its attempt (receipt) write
/// misses a Delete intent that was answered UNCERTAIN before the receipt
/// resumed — `intentBeingRecorded` is already `null` and the epoch never
/// moved — so it makes its target although the deletion may be on disk.
///
/// The invariant: an Insight operation already in progress never loses a
/// relevant uncertain Delete outcome because the intent finished first;
/// unrelated later actions are not blocked by it.
///
/// Only APIs present at R8.3.4 (dd9000cd) are used, so the same file runs
/// on that tree and on the corrected one. Each test prints one
/// `R8341-EVIDENCE` line. A step a tree can't construct fails with
/// `PRECONDITION`.
void main() {
  void evidence(String id, Map<String, Object?> facts) {
    // ignore: avoid_print
    print('R8341-EVIDENCE ${jsonEncode({'test': id, ...facts})}');
  }

  void pre(bool holds, String what) {
    if (!holds) fail('PRECONDITION not constructible on this tree: $what');
  }

  final morning = DateTime(2026, 10, 30, 9);
  final today = dateKey(morning);
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

  setUp(() => h = R8Harness(morning));

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

    /// What the action made, on disk: the part left out by this Insight, or
    /// a Circle kept from its source.
    Future<bool> targetOnDisk(String insightId) async {
      if (i3) {
        final prefs = (await h.disk.stored())[suggestionPreferencesKey];
        return prefs is String &&
            prefs.contains('"openWindow"') &&
            prefs.contains(insightId);
      }
      return (await keptOnDisk()).any((k) => k['fromCircleId'] == source);
    }

    /// The same, in memory.
    bool targetInMemory(ProviderContainer c, String insightId) => i3
        ? c
              .read(suggestionPreferencesProvider)
              .elementsLeftOut
              .any((e) => e.byInsight == insightId)
        : c.read(keptCirclesProvider).kept.any((k) => k.fromCircleId == source);

    /// One Delete whose intent is answered [how]: `refused` (both writes
    /// answer false), `uncertain_no_land` (the first throws before landing,
    /// the retry answers false), `uncertain_landed` (the first lands, its
    /// acknowledgement is lost; restores and the retry answer false, so the
    /// cache reads no marker while the disk holds `true`), or `confirmed`.
    /// Completes once the outcome is told; a Delete that never began has
    /// also failed by then.
    Future<(DeletionIntentOutcome, Object?, Future<Object?>)> deleteAnswered(
      ProviderContainer c,
      String how,
    ) async {
      final intent = h.disk.hold(historyDeletionPendingKey);
      final deletion = c.read(circleHistoryDeletionProvider);
      final deleting = outcome(deletion.delete());
      await intent.reached;
      final announced = deletion.intentBeingRecorded;
      pre(announced != null, 'the intent is being recorded');
      if (how != 'confirmed') {
        h.disk.fail(historyDeletionPendingKey, DiskFault.returnsFalse);
      }
      switch (how) {
        case 'refused':
          intent.release(DiskFault.returnsFalse);
        case 'uncertain_no_land':
          intent.release(DiskFault.throws);
        case 'uncertain_landed':
          intent.releaseAckLost();
        case 'confirmed':
          intent.release();
      }
      final answer = await announced!;
      Object? error;
      if (how != 'confirmed') {
        error = await deleting;
        h.disk.heal(historyDeletionPendingKey);
      }
      pre(
        answer ==
            switch (how) {
              'refused' => DeletionIntentOutcome.refused,
              'confirmed' => DeletionIntentOutcome.confirmed,
              _ => DeletionIntentOutcome.uncertain,
            },
        'the intent was answered $how',
      );
      pre(deletion.intentBeingRecorded == null, 'the outcome was told');
      return (answer, error, deleting);
    }

    group('R834-N01 $family — the Delete intent is answered before the held '
        'attempt resumes', () {
      for (final how in [
        'refused',
        'uncertain_no_land',
        'uncertain_landed',
        'confirmed',
      ]) {
        test('$family intent $how first, then the attempt resumes', () async {
          final (c, shown) = await shownInsight();
          final epoch = c.read(historyWriteGateProvider).epoch;
          final receipt = h.disk.hold(insightsKey);
          final applying = insights(c).apply(shown.id);
          await receipt.reached;
          final (answer, deleteError, deleting) = await deleteAnswered(c, how);
          if (how != 'confirmed') {
            pre(deleteError is HistoryDeletionNotStarted, 'Delete not begun');
            pre(
              c.read(historyWriteGateProvider).epoch == epoch,
              'no deletion boundary',
            );
            pre(
              h.prefs.get(historyDeletionPendingKey) == null,
              'the cache reads no marker',
            );
            pre(
              (await h.disk.stored())[historyDeletionPendingKey] ==
                  (how == 'uncertain_landed' ? true : null),
              'the marker on disk',
            );
          }
          // The only ordering difference from R834 I3/I4-UNCERTAIN: the
          // receipt is released after the outcome has been told.
          receipt.release();
          final result = await applying;
          final deleted = await deleting;
          await R8Harness.settle();
          final memory = insights(c).state.byId(shown.id);
          final madeInMemory = targetInMemory(c, shown.id);
          final s = await snapshotOnDisk(shown.id);
          final made = await targetOnDisk(shown.id);
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
          final madeAfterRetry = await targetOnDisk(shown.id);
          final after = await h.disk.stored();
          evidence('$family-$how-intent-first', {
            'answer': answer.name,
            'deleteError': deleteError?.toString(),
            'deleted': deleted?.toString(),
            'apply': result.name,
            'epoch': [epoch, finalEpoch],
            'memory': memory == null
                ? null
                : {
                    'appliedOn': memory.appliedOn,
                    'attempt': memory.attempt?.target,
                  },
            'madeInMemory': madeInMemory,
            'snapshot': s == null
                ? null
                : {'appliedOn': s['appliedOn'], 'attempt': s['attempt']},
            'targetMade': made,
            'pendingOnDisk': stored[historyDeletionPendingKey],
            'journalKept': stored.containsKey(circleJournalKey),
            'restoredStatus': restoredStatus,
            'retry': retry.name,
            'targetMadeAfterRetry': madeAfterRetry,
            'keysAfterRestart': after.keys.toList()..sort(),
          });
          switch (how) {
            case 'refused':
              // The Delete never began: the application goes on.
              expect(result, InsightActionResult.done);
              expect(finalEpoch, epoch);
              expect(memory?.attempt, isNull);
              expect(memory?.appliedOn, today);
              expect(madeInMemory, isTrue);
              expect(s?['attempt'], isNull);
              expect(s?['appliedOn'], today);
              expect(made, isTrue);
              expect(stored[circleJournalKey], isNotNull);
              expect(restoredStatus, InsightStatus.applied.name);
              expect(retry, InsightActionResult.alreadyApplied);
            case 'uncertain_no_land' || 'uncertain_landed':
              expect(
                result,
                InsightActionResult.notAvailable,
                reason:
                    'an application already waiting on its receipt missed '
                    'a completed uncertain Delete outcome',
              );
              expect(finalEpoch, epoch);
              expect(memory?.attempt, isNotNull);
              expect(memory?.appliedOn, isNull);
              expect(madeInMemory, isFalse);
              expect(s?['attempt'], isNotNull);
              expect(s?['appliedOn'], isNull);
              expect(made, isFalse);
              expect(retry, InsightActionResult.notAvailable);
              expect(madeAfterRetry, isFalse);
              if (how == 'uncertain_no_land') {
                // Kept: never made, never made twice; the Insight is stale.
                expect(stored[historyDeletionPendingKey], isNull);
                expect(stored[circleJournalKey], isNotNull);
                expect(restoredStatus, InsightStatus.stale.name);
                expect(after[historyDeletionPendingKey], isNull);
              } else {
                // Kept pending recovery: the next start finishes the
                // deletion, the attempt with it.
                expect(stored[historyDeletionPendingKey], isTrue);
                expect(restored, isNull);
                expect(after.containsKey(historyDeletionPendingKey), isFalse);
                expect(after.containsKey(circleJournalKey), isFalse);
                expect(after.containsKey(insightsKey), isFalse);
              }
            case 'confirmed':
              expect(deleted, isNull);
              expect(result, InsightActionResult.notAvailable);
              expect(finalEpoch, epoch + 1);
              expect(memory, isNull);
              expect(madeInMemory, isFalse);
              expect(s, isNull);
              expect(made, isFalse);
              expect(stored[historyDeletionPendingKey], isNull);
              expect(stored[circleJournalKey], isNull);
              expect(madeAfterRetry, isFalse);
          }
        });
      }
    });

    group('R834-N01 $family — receipt clearance after the intent is '
        'answered', () {
      for (final how in ['refused', 'uncertain_no_land', 'uncertain_landed']) {
        test(
          '$family target refused after an intent answered $how: '
          '${how == 'refused' ? 'the attempt is cleared, a retry makes it '
                    'once' : 'the attempt is kept, nothing is made'}',
          () async {
            final (c, shown) = await shownInsight();
            final targetKey = i3 ? suggestionPreferencesKey : keptCirclesKey;
            final target = h.disk.hold(targetKey);
            final applying = insights(c).apply(shown.id);
            await target.reached;
            pre(
              (await snapshotOnDisk(shown.id))?['attempt'] != null,
              'the attempt is on disk',
            );
            final (_, deleteError, _) = await deleteAnswered(c, how);
            pre(deleteError is HistoryDeletionNotStarted, 'Delete not begun');
            target.release(DiskFault.returnsFalse);
            final result = await applying;
            await R8Harness.settle();
            final memory = insights(c).state.byId(shown.id);
            final s = await snapshotOnDisk(shown.id);
            final status = memory == null
                ? null
                : insights(c).status(memory).name;
            final retry = await insights(c).apply(shown.id);
            await R8Harness.settle();
            final again = await insights(c).apply(shown.id);
            await R8Harness.settle();
            final made = await targetOnDisk(shown.id);
            await h.restart();
            final c2 = h.open();
            final restored = insights(c2).state.byId(shown.id);
            final after = await h.disk.stored();
            final madeAfterRestart = await targetOnDisk(shown.id);
            evidence('$family-clear-after-$how', {
              'apply': result.name,
              'memoryAttempt': memory?.attempt?.target,
              'diskAttempt': s?['attempt'],
              'status': status,
              'retry': retry.name,
              'again': again.name,
              'targetMade': made,
              'restored': restored?.attempt?.target,
              'keysAfterRestart': after.keys.toList()..sort(),
            });
            expect(result, InsightActionResult.notSaved);
            if (how == 'refused') {
              expect(memory?.attempt, isNull);
              expect(s?['attempt'], isNull);
              expect(status, InsightStatus.current.name);
              expect(retry, InsightActionResult.done);
              expect(again, InsightActionResult.alreadyApplied);
              expect(made, isTrue);
              if (!i3) expect(await keptOnDisk(), hasLength(1));
            } else {
              expect(
                memory?.attempt,
                isNotNull,
                reason:
                    'an uncertain Delete answered before the clearance was '
                    'missed',
              );
              expect(s?['attempt'], isNotNull);
              expect(status, InsightStatus.stale.name);
              expect(retry, InsightActionResult.notAvailable);
              expect(again, InsightActionResult.notAvailable);
              expect(made, isFalse);
              expect(madeAfterRestart, isFalse);
              if (how == 'uncertain_landed') {
                expect(restored, isNull);
                expect(after.containsKey(historyDeletionPendingKey), isFalse);
                expect(after.containsKey(insightsKey), isFalse);
              } else {
                expect(restored?.attempt, isNotNull);
              }
            }
          },
        );
      }
    });

    group('R834-N01 $family — later actions and later Deletes', () {
      for (final how in ['uncertain_no_land', 'uncertain_landed']) {
        test('$family a confirmed Delete after the stopped application '
            '($how) removes its attempt; nothing is made', () async {
          final (c, shown) = await shownInsight();
          final receipt = h.disk.hold(insightsKey);
          final applying = insights(c).apply(shown.id);
          await receipt.reached;
          await deleteAnswered(c, how);
          receipt.release();
          final result = await applying;
          await R8Harness.settle();
          pre(
            result == InsightActionResult.notAvailable,
            'the application stopped (R834-N01 corrected)',
          );
          pre(
            (await snapshotOnDisk(shown.id))?['attempt'] != null,
            'its attempt is kept',
          );
          final epoch = c.read(historyWriteGateProvider).epoch;
          await c.read(circleHistoryDeletionProvider).delete();
          await R8Harness.settle();
          final stored = await h.disk.stored();
          final made = await targetOnDisk(shown.id);
          await h.restart();
          final after = await h.disk.stored();
          evidence('$family-confirmed-after-$how', {
            'epoch': [epoch, c.read(historyWriteGateProvider).epoch],
            'memory': insights(c).state.byId(shown.id)?.attempt?.target,
            'keys': stored.keys.toList()..sort(),
            'targetMade': made,
            'keysAfterRestart': after.keys.toList()..sort(),
          });
          expect(c.read(historyWriteGateProvider).epoch, epoch + 1);
          expect(insights(c).state.byId(shown.id), isNull);
          expect(stored.containsKey(insightsKey), isFalse);
          expect(stored.containsKey(historyDeletionPendingKey), isFalse);
          expect(stored.containsKey(circleJournalKey), isFalse);
          expect(jsonEncode(stored).contains(shown.id), isFalse);
          expect(made, isFalse);
          expect(after.containsKey(historyDeletionPendingKey), isFalse);
        });
      }

      for (final how in ['refused', 'uncertain_no_land']) {
        test('$family a fresh action after a completed $how Delete is not '
            'blocked by it', () async {
          final (c, shown) = await shownInsight();
          await deleteAnswered(c, how);
          await R8Harness.settle();
          final result = await insights(c).apply(shown.id);
          await R8Harness.settle();
          final memory = insights(c).state.byId(shown.id);
          final s = await snapshotOnDisk(shown.id);
          final made = await targetOnDisk(shown.id);
          final retry = await insights(c).apply(shown.id);
          evidence('$family-fresh-after-$how', {
            'apply': result.name,
            'appliedOn': s?['appliedOn'],
            'attempt': s?['attempt'],
            'targetMade': made,
            'retry': retry.name,
          });
          expect(result, InsightActionResult.done);
          expect(memory?.appliedOn, today);
          expect(memory?.attempt, isNull);
          expect(targetInMemory(c, shown.id), isTrue);
          expect(s?['appliedOn'], today);
          expect(s?['attempt'], isNull);
          expect(made, isTrue);
          expect(retry, InsightActionResult.alreadyApplied);
        });
      }

      for (final sequence in [
        ['uncertain_no_land', 'refused'],
        ['uncertain_landed', 'refused'],
        ['refused', 'uncertain_no_land'],
        ['refused', 'refused'],
      ]) {
        final stops = sequence.any((how) => how.startsWith('uncertain'));
        test('$family two Deletes answered ${sequence.join(' then ')} '
            'before the attempt resumes: '
            '${stops ? 'it stops, its attempt kept' : 'it goes on'}', () async {
          final (c, shown) = await shownInsight();
          final epoch = c.read(historyWriteGateProvider).epoch;
          final receipt = h.disk.hold(insightsKey);
          final applying = insights(c).apply(shown.id);
          await receipt.reached;
          final answers = <String>[];
          for (final how in sequence) {
            final (answer, error, _) = await deleteAnswered(c, how);
            pre(error is HistoryDeletionNotStarted, 'Delete not begun');
            answers.add(answer.name);
          }
          receipt.release();
          final result = await applying;
          await R8Harness.settle();
          final memory = insights(c).state.byId(shown.id);
          final s = await snapshotOnDisk(shown.id);
          final made = await targetOnDisk(shown.id);
          evidence('$family-sequence-${sequence.join('-')}', {
            'answers': answers,
            'apply': result.name,
            'epoch': [epoch, c.read(historyWriteGateProvider).epoch],
            'memoryAttempt': memory?.attempt?.target,
            'diskAttempt': s?['attempt'],
            'appliedOn': s?['appliedOn'],
            'targetMade': made,
          });
          expect(c.read(historyWriteGateProvider).epoch, epoch);
          if (stops) {
            expect(
              result,
              InsightActionResult.notAvailable,
              reason: 'a later Delete hid an earlier uncertain outcome',
            );
            expect(memory?.attempt, isNotNull);
            expect(s?['attempt'], isNotNull);
            expect(s?['appliedOn'], isNull);
            expect(targetInMemory(c, shown.id), isFalse);
            expect(made, isFalse);
          } else {
            expect(result, InsightActionResult.done);
            expect(s?['attempt'], isNull);
            expect(s?['appliedOn'], today);
            expect(made, isTrue);
          }
        });
      }

      test('$family an uncertain Delete answered before the application '
          'began never stops it; a refused one overlapping it doesn\'t '
          'either', () async {
        final (c, shown) = await shownInsight();
        await deleteAnswered(c, 'uncertain_no_land');
        await R8Harness.settle();
        final receipt = h.disk.hold(insightsKey);
        final applying = insights(c).apply(shown.id);
        await receipt.reached;
        await deleteAnswered(c, 'refused');
        receipt.release();
        final result = await applying;
        await R8Harness.settle();
        final s = await snapshotOnDisk(shown.id);
        final made = await targetOnDisk(shown.id);
        evidence('$family-uncertain-before-then-refused-overlapping', {
          'apply': result.name,
          'attempt': s?['attempt'],
          'appliedOn': s?['appliedOn'],
          'targetMade': made,
        });
        expect(result, InsightActionResult.done);
        expect(s?['attempt'], isNull);
        expect(s?['appliedOn'], today);
        expect(made, isTrue);
      });
    });
  }
}
