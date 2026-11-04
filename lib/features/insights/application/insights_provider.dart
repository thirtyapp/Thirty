import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/premium/premium_access.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/storage/confirmed_write.dart';
import '../../../core/storage/store_save_failures.dart';
import '../../../core/utils/date_key.dart';
import '../../home/application/circle_journal.dart';
import '../../home/application/suggestion_preferences.dart';
import '../../personal_circle/application/kept_circles_provider.dart';
import '../../personal_circle/domain/circle_elements.dart';
import '../../plans/application/circle_plans_provider.dart';
import '../../plans/domain/circle_plan.dart';
import '../domain/insight.dart';
import '../domain/insight_engine.dart';

/// Where Insight snapshots are kept (ADR-024 B5): one versioned JSON record.
/// A new key — V1's retired `insight_snapshots_v1` is never read.
const insightsKey = 'insights_v2';

/// A record that couldn't be read is kept here, untouched.
const insightsUnreadableKey = 'insights_v2_unreadable';

/// What an Insight action did.
enum InsightActionResult {
  done,

  /// It was already so — nothing changed, nothing recorded.
  alreadyApplied,

  /// New Insights and applying them are Premium (ADR-024 §13): nothing
  /// changed.
  needsPremium,

  /// The snapshot isn't current (stale, or acted on): nothing changed.
  notAvailable,

  /// I4: 8 kept Circles already — nothing is replaced.
  keptLimitReached,

  /// "Nothing to change", or a Plan review, whose options live in Plans.
  nothingToApply,

  /// The store didn't confirm what applying it needed to save (audit
  /// remediation R8): nothing is recorded as applied, and it can be tried
  /// again. The user is told ([storeSaveFailuresProvider]).
  notSaved,
}

/// The user's Insights. Reading what was shown is everyone's; generating a
/// new Insight and applying one are Premium, checked here — never only in
/// a screen — except Insight 4's Keep of the user's own Circle, which is
/// ownership and never gated ([apply]; [keepableWithoutPremium]). Nothing
/// runs in the background: [assess] is called when Insights is opened.
class InsightsNotifier extends Notifier<InsightsState> {
  Future<void> _writes = Future<void>.value();

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  InsightsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(insightsKey);
    if (raw == null) return InsightsState.empty;
    try {
      final state = InsightsState.fromJson(jsonDecode(raw));
      if (state != null) return state;
    } catch (_) {
      // Unreadable: kept aside below.
    }
    // Kept aside at once; a save that follows confirms the copy first
    // ([_protectStored]), so the original is never written over unkept.
    if (prefs.get(insightsUnreadableKey) == null) {
      writeConfirmed(prefs, insightsUnreadableKey, raw).ignore();
    }
    return InsightsState.empty;
  }

  bool get _premium => ref.read(premiumEntitlementProvider);
  DateTime get _now => ref.read(nowProvider);

  /// Shows [next] and saves it. Audit remediation R8 (Claude F-6): the save
  /// must be confirmed by the store ([writeConfirmed]); one that isn't is
  /// shown to the user ([storeSaveFailuresProvider]) and retried by the next
  /// save, which writes the whole record. Never over a stored record THIRTY
  /// can't read until a copy of it is confirmed aside ([_protectStored]).
  /// The returned future fails when the save does.
  Future<void> _set(InsightsState next) {
    state = next;
    final prefs = _prefs;
    final json = next.isEmpty ? null : jsonEncode(next.toJson());
    final write = _writes.then((_) async {
      await _protectStored(prefs);
      await writeConfirmed(prefs, insightsKey, json);
    });
    _writes = write.then(
      (_) {
        if (ref.mounted) {
          ref
              .read(storeSaveFailuresProvider.notifier)
              .saved(UserStore.insights);
        }
      },
      onError: (Object _) {
        if (ref.mounted) {
          ref
              .read(storeSaveFailuresProvider.notifier)
              .record(UserStore.insights);
        }
      },
    );
    return write;
  }

  /// A stored record THIRTY can't read is never written over before it is
  /// kept aside, exactly as stored, and the store has confirmed that (audit
  /// remediation R8). A different record already kept aside is never
  /// replaced: the save is refused instead.
  static Future<void> _protectStored(SharedPreferences prefs) async {
    final raw = prefs.get(insightsKey);
    if (raw == null) return;
    if (raw is String && _readable(raw)) return;
    final text = '$raw';
    final aside = prefs.get(insightsUnreadableKey);
    if (aside == text) return;
    if (aside != null) {
      throw const StorageWriteFailed(
        insightsKey,
        'an earlier unreadable record is already kept aside',
      );
    }
    await writeConfirmed(prefs, insightsUnreadableKey, text);
  }

  static bool _readable(String raw) {
    try {
      return InsightsState.fromJson(jsonDecode(raw)) != null;
    } catch (_) {
      return false;
    }
  }

  /// The facts as they stand today.
  InsightInputs inputs() {
    final collection = ref.read(keptCirclesProvider);
    final kept = collection.kept;
    return InsightInputs(
      today: _now,
      circles: [
        for (final entry in ref.read(circleJournalRepositoryProvider).readAll())
          InsightCircle.fromJournal(entry),
      ],
      plans: ref.read(circlePlansProvider),
      leftOut: ref.read(suggestionPreferencesProvider).leftOut,
      keptFromCircles: {
        for (final k in kept)
          if (k.fromCircleId != null) k.fromCircleId!,
      },
      // Every kept Circle counts, one THIRTY can't read too (R4).
      keptCount: collection.count,
    );
  }

  /// What is kept, as it stands today — for everyone, Premium or not.
  InsightAssessment read() =>
      assessInsights(inputs(), state.snapshots, generate: false);

  /// Opening Insights: with Premium, Plan reviews appear at once and at
  /// most one new ordinary Insight per 7 days; without, nothing new is
  /// generated and what was shown stays readable.
  InsightAssessment assess() {
    if (!_premium) return read();
    final result = assessInsights(inputs(), state.snapshots, generate: true);
    if (result.added.isNotEmpty ||
        result.snapshots.length != state.snapshots.length) {
      _set(state.withSnapshots(result.snapshots)).ignore();
    }
    return result;
  }

  /// What [snapshot] is today.
  InsightStatus status(InsightSnapshot snapshot) =>
      statusOf(snapshot, inputs());

  /// Applies [snapshotId]'s application through its own domain — and
  /// records it only when that succeeded. Safe to repeat.
  ///
  /// Audit remediation R8 (Astra R7-A03): Insight 4's Keep completes only
  /// once the kept Circle is on disk; until then, and if it fails, I4 is
  /// not recorded as applied and can be tried again
  /// ([InsightActionResult.notSaved]). An I4 whose Circle is already kept —
  /// an earlier Keep whose own record didn't land — is recorded as applied
  /// then, never kept twice.
  ///
  /// Applying is Premium, with one exception (audit remediation R5,
  /// A2-05): Insight 4's Keep of a Circle already in the user's History is
  /// ownership, and Keep is never gated (contract "Kept Circles and
  /// Yours"; ADR-024 §3). A valid I4 shown while Premium was active keeps
  /// that Keep after a lapse — through the same checks below: the snapshot
  /// must still be current, and the kept Circles' duplicate and limit
  /// rules apply. Nothing new is generated without Premium ([assess]).
  Future<InsightActionResult> apply(String snapshotId) async {
    final snapshot = state.byId(snapshotId);
    final keepsOwnCircle = snapshot?.application is KeepCircleFromHistory;
    if (!_premium && !keepsOwnCircle) return InsightActionResult.needsPremium;
    if (snapshot == null) return InsightActionResult.notAvailable;
    final i = inputs();
    switch (statusOf(snapshot, i)) {
      case InsightStatus.applied:
        return InsightActionResult.alreadyApplied;
      case InsightStatus.current:
        break;
      case _:
        return InsightActionResult.notAvailable;
    }
    final result = switch (snapshot.application) {
      PlanDirection(:final planId) => _direct(planId),
      KeepGentler(:final planId, :final cycleId) => _gentler(planId, cycleId),
      LeaveOutPart(:final element) => _leaveOut(element, i),
      KeepCircleFromHistory(:final circleId) => await _keep(circleId),
      OpenPlanReview() ||
      NothingToChange() => InsightActionResult.nothingToApply,
    };
    final keptAlready =
        snapshot.application is KeepCircleFromHistory &&
        result == InsightActionResult.alreadyApplied;
    if (result == InsightActionResult.done || keptAlready) {
      final current = state.byId(snapshotId) ?? snapshot;
      _set(
        state.replacing(current.copyWith(appliedOn: dateKey(_now))),
      ).ignore();
    }
    return result;
  }

  InsightActionResult _direct(String planId) {
    final plans = ref.read(circlePlansProvider.notifier);
    final result = switch (ref.read(circlePlansProvider).lifecycleOf(planId)) {
      PlanLifecycle.active => null,
      PlanLifecycle.paused => plans.resume(planId),
      PlanLifecycle.neverStarted => plans.start(planId),
      PlanLifecycle.ended || PlanLifecycle.left => plans.goThroughAgain(planId),
    };
    return _fromPlan(result);
  }

  InsightActionResult _gentler(String planId, String cycleId) {
    final plan = ref.read(circlePlansProvider).plans[planId];
    if (plan == null || plan.current.id != cycleId) {
      return InsightActionResult.notAvailable;
    }
    if (plan.current.isGentler) return InsightActionResult.alreadyApplied;
    return _fromPlan(
      ref.read(circlePlansProvider.notifier).keepGentler(planId),
    );
  }

  InsightActionResult _fromPlan(PlanActionResult? result) => switch (result) {
    null => InsightActionResult.alreadyApplied,
    PlanActionResult.done => InsightActionResult.done,
    PlanActionResult.needsPremium => InsightActionResult.needsPremium,
    PlanActionResult.notAvailable => InsightActionResult.notAvailable,
  };

  InsightActionResult _leaveOut(String wire, InsightInputs i) {
    final element = ElementId.values.asNameMap()[wire];
    if (element == null) return InsightActionResult.notAvailable;
    if (i.leftOut.contains(element)) return InsightActionResult.alreadyApplied;
    unawaited(
      ref.read(suggestionPreferencesProvider.notifier).leaveOut(element),
    );
    return InsightActionResult.done;
  }

  Future<InsightActionResult> _keep(String circleId) async {
    InsightActionResult? refused(KeptCircles kept) {
      if (kept.kept.any((k) => k.fromCircleId == circleId)) {
        return InsightActionResult.alreadyApplied;
      }
      if (kept.isFull) return InsightActionResult.keptLimitReached;
      return null;
    }

    if (refused(ref.read(keptCirclesProvider)) case final result?) {
      return result;
    }
    CircleJournalEntry? entry;
    for (final e in ref.read(circleJournalRepositoryProvider).readAll()) {
      if (e.circleId == circleId) entry = e;
    }
    final plan = CirclePlan.fromWire(entry?.session?.parts);
    if (entry == null || plan == null) return InsightActionResult.notAvailable;
    try {
      final circle = await ref
          .read(keptCirclesProvider.notifier)
          .keepCircle(plan: plan, need: entry.direction, circleId: circleId);
      if (circle != null) return InsightActionResult.done;
      return refused(ref.read(keptCirclesProvider)) ??
          InsightActionResult.notAvailable;
    } on StorageWriteFailed {
      return InsightActionResult.notSaved;
    }
  }

  /// "Not now": this evidence set is hidden for 28 days; materially new
  /// evidence for the same claim may qualify again ([isQuiet]). Nothing
  /// else changes — not History, not what THIRTY suggests. A Plan review
  /// isn't dismissed here: Plans owns it.
  InsightActionResult notNow(String snapshotId) =>
      _quieten(snapshotId, (s, on) => s.copyWith(notNowOn: on));

  /// I3's "Keep it": a dismissal, exactly like [notNow] — no preference, no
  /// answer, no ranking evidence, no second exclusion. The part simply isn't
  /// left out; only this evidence set is hidden.
  InsightActionResult keepPart(String snapshotId) {
    final snapshot = state.byId(snapshotId);
    if (snapshot != null && snapshot.family != InsightFamily.skippedPart) {
      return InsightActionResult.notAvailable;
    }
    return _quieten(snapshotId, (s, on) => s.copyWith(declinedOn: on));
  }

  InsightActionResult _quieten(
    String snapshotId,
    InsightSnapshot Function(InsightSnapshot, String) mark,
  ) {
    if (!_premium) return InsightActionResult.needsPremium;
    final snapshot = state.byId(snapshotId);
    if (snapshot == null ||
        !snapshot.family.isOrdinary ||
        statusOf(snapshot, inputs()) != InsightStatus.current) {
      return InsightActionResult.notAvailable;
    }
    _set(state.replacing(mark(snapshot, dateKey(_now)))).ignore();
    return InsightActionResult.done;
  }

  /// Delete Circle history: every snapshot is derived from the journal, so
  /// every one goes. What the user applied — a left-out part, a kept
  /// Circle, a Plan's gentler setting — is theirs and stays. A record set
  /// aside as unreadable goes too: nothing reads it back. Completes when it
  /// is written — and, unlike the other writes here, fails if it couldn't be
  /// (audit remediation R3: Delete never reports what didn't happen).
  ///
  /// Audit remediation R8 (Astra R7-A04): both removals must be confirmed by
  /// the store ([writeConfirmed]).
  Future<void> forgetAll() {
    state = InsightsState.empty;
    final prefs = _prefs;
    // Removed at once, and confirmed (the intent to delete is already on
    // disk): nothing set aside stays readable while earlier writes finish.
    final setAside = writeConfirmed(
      prefs,
      insightsUnreadableKey,
      null,
      restoreOnFailure: false,
    )..ignore();
    final written = _writes
        .then(
          (_) =>
              writeConfirmed(prefs, insightsKey, null, restoreOnFailure: false),
        )
        .then((_) => setAside);
    _writes = written.then((_) {}, onError: (Object _) {});
    return written;
  }
}

/// Without Premium, the one Insight still offered with its action: the
/// newest current I4 whose Keep would keep a Circle from the user's own
/// History (audit remediation R5, A2-05). Nothing else — no other family,
/// and never an Insight generated without Premium.
InsightSnapshot? keepableWithoutPremium(
  List<InsightSnapshot> snapshots,
  InsightInputs i,
) {
  for (final s in snapshots.reversed) {
    if (s.application is KeepCircleFromHistory &&
        statusOf(s, i) == InsightStatus.current) {
      return s;
    }
  }
  return null;
}

final insightsProvider = NotifierProvider<InsightsNotifier, InsightsState>(
  InsightsNotifier.new,
);
