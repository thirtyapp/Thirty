import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/storage/confirmed_write.dart';
import '../../../core/storage/preservation_writes.dart';
import '../../insights/application/insights_provider.dart';
import '../../plans/application/circle_plans_provider.dart';
import '../../plans/domain/circle_plan.dart';
import 'circle_journal.dart';
import 'recommendation_provider.dart';

/// Present from the moment "Delete Circle history" begins until every store
/// has been cleared (audit remediation R3). If the app stops in between, the
/// next start finishes the deletion before anything reads the store
/// ([completeInterruptedHistoryDeletion]) — a deletion is never left half
/// done, and never taken back.
const historyDeletionPendingKey = 'circle_history_deletion_pending';

/// Delete Circle history didn't begin: its intent couldn't be recorded on
/// disk, so nothing was removed (audit remediation R8, Astra R7-A04). The
/// history is exactly as it was; the user can try again.
class HistoryDeletionNotStarted implements Exception {
  const HistoryDeletionNotStarted();

  @override
  String toString() => 'HistoryDeletionNotStarted';
}

/// The barrier between Delete Circle history and the writes that were
/// already on their way when it began (audit remediation R3, J4).
///
/// Each of Today's writes is begun under the current [epoch]. A deletion
/// moves the epoch on: from then, a write begun earlier stops at its next
/// step instead of putting back what was deleted. Writes begun while a
/// deletion runs wait until it has finished ([settled]) — they belong to the
/// empty history, not the deleted one.
class HistoryWriteGate {
  int _epoch = 0;
  Completer<void>? _deleting;
  final _inFlight = <Future<void>, int>{};

  /// The deletion generation writes are begun under.
  int get epoch => _epoch;

  /// Whether a write begun under [epoch] may still land.
  bool isCurrent(int epoch) => epoch == _epoch;

  /// Completes once no deletion is under way.
  Future<void> get settled => _deleting?.future ?? Future<void>.value();

  /// Whether a deletion is under way now.
  bool get isDeleting => _deleting != null;

  /// Tracks [write], begun under [epoch], so a deletion can wait for it.
  void track(int epoch, Future<void> write) {
    _inFlight[write] = epoch;
    unawaited(
      write
          .then((_) {}, onError: (Object _) {})
          .whenComplete(() => _inFlight.remove(write)),
    );
  }

  /// Begins a deletion: every write begun before now is stale. Completes
  /// once each of them has stopped or finished.
  Future<void> _begin() {
    _epoch++;
    _deleting ??= Completer<void>();
    return Future.wait([
      for (final MapEntry(key: write, value: epoch) in _inFlight.entries)
        if (epoch < _epoch) write.then((_) {}, onError: (Object _) {}),
    ]);
  }

  void _end() {
    _deleting?.complete();
    _deleting = null;
  }
}

/// The one [HistoryWriteGate] of this app.
final historyWriteGateProvider = Provider<HistoryWriteGate>(
  (ref) => HistoryWriteGate(),
);

/// "Delete Circle history" (contract, Delete / Export): the journal, today's
/// Circle session, each Circle Plan's stage evidence and reviews, and every
/// Insight snapshot. Kept Circles, each Plan's place and the user's
/// suggestion preferences stay.
class CircleHistoryDeletion {
  CircleHistoryDeletion(this._ref);

  final Ref _ref;

  /// The deletion under way or last run, if any — never failing.
  Future<void>? _running;

  /// Whether a Delete Circle history that didn't finish — it failed, or the
  /// app stopped before the next start could finish it — is still waiting
  /// to be finished. Not one under way now: a Circle begun while a deletion
  /// runs waits for it and belongs to the new history.
  ///
  /// While pending, no new Circle begins (audit remediation R3, founder
  /// decision): it would be erased when the deletion is finished.
  bool get isPending =>
      (_ref
              .read(sharedPreferencesProvider)
              .getBool(historyDeletionPendingKey) ??
          false) &&
      !_ref.read(historyWriteGateProvider).isDeleting;

  /// Finishes a pending deletion, if there is one, before a new Circle
  /// begins. Completes with whether none is pending any more; when it still
  /// can't be finished, the intent stays recorded and nothing is claimed.
  Future<bool> resolvePending() async {
    if (_running case final running?) await running;
    if (!isPending) return true;
    try {
      await delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Deletes the history. Completes only once every store has been cleared
  /// and the deletion is durable; if anything fails it completes with that
  /// error, and the deletion is finished on the next start.
  ///
  /// In order: the intent is recorded — and confirmed on disk before
  /// anything is removed (audit remediation R8, Astra R7-A04), so the
  /// deletion survives the app stopping; what is in memory goes at once, so
  /// nothing deleted stays on screen or feeds a new write; every write begun
  /// before the deletion stops or finishes; then everything is cleared again
  /// — whatever such a write managed to put back goes too — and only then is
  /// the intent removed. Every removal must be confirmed by the store
  /// ([writeConfirmed]): one that throws or returns `false` fails the
  /// deletion, and the intent stays.
  ///
  /// R8.1 (Astra N02): a copy of an unreadable Plans or Insights record
  /// still being written ([PreservationWrites]) is one of those writes —
  /// waited for, and its key cleared again in the last pass — so none can
  /// land after a deletion that succeeded.
  Future<void> delete() {
    final run = switch (_running) {
      final previous? => previous.then((_) => _delete()),
      null => _delete(),
    };
    _running = run.then((_) {}, onError: (Object _) {});
    return run;
  }

  Future<void> _delete() async {
    final gate = _ref.read(historyWriteGateProvider);
    final prefs = _ref.read(sharedPreferencesProvider);
    final plans = _ref.read(circlePlansProvider.notifier);
    final insights = _ref.read(insightsProvider.notifier);
    final preservations = _ref.read(preservationWritesProvider);
    // The intent first, confirmed on disk — tried once more if the store
    // refuses it — before anything else: no write is stopped, nothing is
    // cleared from memory and nothing is removed until it is (founder
    // decision D3, 2026-11-04). A Delete that never began leaves every write
    // on its way to land.
    try {
      await writeConfirmed(prefs, historyDeletionPendingKey, true);
    } on StorageWriteFailed {
      try {
        await writeConfirmed(prefs, historyDeletionPendingKey, true);
      } on StorageWriteFailed {
        throw const HistoryDeletionNotStarted();
      }
    }
    final stale = gate._begin();
    try {
      final firstPass = _clearRecordedCircles(prefs);
      final evidence = plans.forgetStageEvidence();
      final snapshots = insights.forgetAll();
      _ref.invalidate(circleJournalRepositoryProvider);
      _ref.invalidate(recommendationProvider);
      // Every step is awaited, even once one has failed, so none is left
      // running behind the error.
      await _all([
        firstPass,
        stale,
        evidence,
        snapshots,
        preservations.settledAll(),
      ]);
      await _all([
        _clearRecordedCircles(prefs),
        for (final key in [circlePlansUnreadableKey, insightsUnreadableKey])
          writeConfirmed(prefs, key, null, restoreOnFailure: false),
      ]);
      await writeConfirmed(prefs, historyDeletionPendingKey, null);
    } catch (_) {
      // Not finished: the intent stays recorded, so the next start finishes
      // it — written again in case a step put it back.
      try {
        await writeConfirmed(prefs, historyDeletionPendingKey, true);
      } catch (_) {
        // The store refuses every write: nothing more can be done now.
      }
      rethrow;
    } finally {
      gate._end();
    }
  }
}

/// The app's [CircleHistoryDeletion].
final circleHistoryDeletionProvider = Provider<CircleHistoryDeletion>(
  CircleHistoryDeletion.new,
);

/// The journal and today's Circle session, removed together. Every removal
/// is begun at once, so none of them is left readable while the others are
/// awaited; each must be confirmed (audit remediation R8).
Future<void> _clearRecordedCircles(SharedPreferences prefs) => _all([
  writeConfirmed(prefs, circleJournalKey, null, restoreOnFailure: false),
  // R6c: and every copy kept of a journal THIRTY couldn't read.
  writeConfirmed(
    prefs,
    circleJournalPreservedKey,
    null,
    restoreOnFailure: false,
  ),
  clearRecordedCircleState(prefs),
]);

/// Waits for every one of [steps] and then fails with the first failure, if
/// any — never before all have finished, so nothing is left running behind
/// an error.
Future<void> _all(List<Future<void>> steps) async {
  Object? failure;
  for (final step in steps) {
    try {
      await step;
    } catch (error) {
      failure ??= error;
    }
  }
  if (failure != null) throw failure;
}

/// Finishes a Delete Circle history the app stopped in the middle of, or
/// that failed ([historyDeletionPendingKey]) — before anything reads the
/// store (`main.dart`). Clears what the deletion clears, from the stored
/// records themselves: the journal, today's session, each Plan's stage
/// evidence (its place stays) and every Insight snapshot. Every step is
/// begun at once, so even if one fails nothing deleted is read back; the
/// marker goes last, only when all of them were confirmed (audit remediation
/// R8: a removal that throws or returns `false` is a failure), and otherwise
/// this completes with the error. Safe to repeat.
Future<void> completeInterruptedHistoryDeletion(SharedPreferences prefs) async {
  if (!(prefs.getBool(historyDeletionPendingKey) ?? false)) return;
  final rawPlans = prefs.getString(circlePlansKey);
  await _all([
    _clearRecordedCircles(prefs),
    if (rawPlans != null)
      writeConfirmed(
        prefs,
        circlePlansKey,
        jsonEncode(
          (_plansFrom(rawPlans) ?? CirclePlansState.empty)
              .forgetStageEvidence()
              .toJson(),
        ),
        restoreOnFailure: false,
      ),
    for (final key in [
      circlePlansUnreadableKey,
      insightsKey,
      insightsUnreadableKey,
    ])
      writeConfirmed(prefs, key, null, restoreOnFailure: false),
  ]);
  await writeConfirmed(prefs, historyDeletionPendingKey, null);
}

CirclePlansState? _plansFrom(String raw) {
  try {
    return CirclePlansState.fromJson(jsonDecode(raw));
  } catch (_) {
    return null;
  }
}
