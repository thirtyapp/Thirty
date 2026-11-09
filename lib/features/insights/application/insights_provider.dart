import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/premium/premium_access.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/storage/confirmed_write.dart';
import '../../../core/storage/preservation_writes.dart';
import '../../../core/storage/store_save_failures.dart';
import '../../../core/utils/date_key.dart';
import '../../home/application/circle_history_deletion.dart';
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

  /// The Insights as the store last confirmed them, and the latest save
  /// queued (R8.1 RL-1): a failed latest save puts [state] back to it.
  InsightsState _durable = InsightsState.empty;
  InsightsState? _queued;

  /// How many Delete Circle histories have begun ([forgetAll]).
  int _deletions = 0;

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  /// Completes, never failing, once no Insights save is being written.
  Future<void> idle() async {
    for (;;) {
      final pending = _writes;
      await pending;
      if (identical(pending, _writes)) return;
    }
  }

  /// Whether Delete Circle history is under way, or waiting to be finished
  /// (R8.2, Astra R81-A02 / Claude NEW-2): nothing new is generated from
  /// the evidence it is deleting.
  bool get _deletionUnderWay =>
      ref.read(historyWriteGateProvider).isDeleting ||
      ref.read(circleHistoryDeletionProvider).isPending;

  @override
  InsightsState build() {
    final read = _read(ref.watch(sharedPreferencesProvider));
    _durable = read;
    _queued = null;
    return read;
  }

  InsightsState _read(SharedPreferences prefs) {
    // R8.2 (Astra R81-A09): a stored value that isn't text is a record
    // THIRTY can't read, never a crash.
    final raw = prefs.get(insightsKey);
    if (raw == null) return InsightsState.empty;
    if (raw is String) {
      try {
        final state = InsightsState.fromJson(jsonDecode(raw));
        if (state != null) return state;
      } catch (_) {
        // Unreadable: kept aside below.
      }
    }
    // Kept aside at once — a tracked write (R8.1, Astra N02): a save that
    // follows waits for it and confirms the copy first ([_protectStored]),
    // and Delete Circle history waits for it, so the original is never
    // written over unkept and the copy never lands after a deletion.
    if (prefs.get(insightsUnreadableKey) == null) {
      ref
          .read(preservationWritesProvider)
          .keepAside(prefs, insightsUnreadableKey, raw);
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
  ///
  /// R8.1 RL-1 (founder decision 2026-11-05): a new Insight, "Not now" or
  /// "Keep it" whose save the store refuses is never left on screen as
  /// made: when the latest save fails, the Insights go back to what the
  /// store holds, and the user is told. Pending while being written.
  Future<void> _set(InsightsState next) {
    state = next;
    _queued = next;
    final prefs = _prefs;
    final json = next.isEmpty ? null : jsonEncode(next.toJson());
    final preservations = ref.read(preservationWritesProvider);
    final generation = _deletions;
    final write = _writes.then((_) async {
      await _protectStored(prefs, preservations);
      await writeConfirmed(prefs, insightsKey, json);
      // R8.2 (Astra R81-A02): a save queued before Delete Circle history
      // began lands before the deletion's own removal, but is never again
      // what the Insights fall back to.
      _durable = generation == _deletions ? next : InsightsState.empty;
    });
    _writes = write.then(
      (_) {
        if (identical(_queued, next)) _queued = null;
        if (ref.mounted && identical(state, _durable)) {
          ref
              .read(storeSaveFailuresProvider.notifier)
              .saved(UserStore.insights);
        }
      },
      onError: (Object _) {
        final latest = identical(_queued, next);
        if (latest) _queued = null;
        if (!ref.mounted) return;
        ref.read(storeSaveFailuresProvider.notifier).record(UserStore.insights);
        if (latest && identical(state, next)) state = _durable;
      },
    );
    return write;
  }

  /// A stored record THIRTY can't read is never written over before it is
  /// kept aside, exactly as stored, and the store has confirmed that (audit
  /// remediation R8). A different record already kept aside is never
  /// replaced: the save is refused instead.
  ///
  /// R8.1 (Astra N02): a copy still being written is waited for first, so
  /// a value that is only in the store's memory never counts as kept.
  static Future<void> _protectStored(
    SharedPreferences prefs,
    PreservationWrites preservations,
  ) async {
    await preservations.settled(insightsUnreadableKey);
    final raw = prefs.get(insightsKey);
    if (raw == null) return;
    if (raw is String && _readable(raw)) return;
    // R8.2 (Astra R81-A09): kept as stored, its native type included.
    final aside = prefs.get(insightsUnreadableKey);
    if (sameStoredValue(aside, raw)) return;
    if (aside != null) {
      throw const StorageWriteFailed(
        insightsKey,
        'an earlier unreadable record is already kept aside',
      );
    }
    await writeConfirmed(prefs, insightsUnreadableKey, raw);
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
      // R8.2 (Astra R81-A07): History as its store has confirmed it — never
      // an answer, or a removal, still being written.
      circles: [
        for (final entry
            in ref.read(circleJournalRepositoryProvider).readConfirmed())
          InsightCircle.fromJournal(entry),
      ],
      // R8.1 RL-1: the Plans as confirmed on disk — an Insight is never
      // generated, withdrawn or counted on a Plan change still pending.
      plans: ref.read(circlePlansProvider.notifier).confirmedState,
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
  ///
  /// R8.2 (Astra R81-A02, Claude NEW-2): never while Delete Circle history
  /// is under way or still to be finished — what it would be generated
  /// from is being deleted.
  ///
  /// R8.3.2 (founder scope decisions B1/B2): first, any Insight whose
  /// action was recorded as being made, and is proven on disk, is marked
  /// applied — Premium or not ([_withProvenAttempts]).
  InsightAssessment assess() {
    if (_deletionUnderWay) return read();
    final proven = _withProvenAttempts(state, inputs());
    if (!identical(proven, state)) _set(proven).ignore();
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
  ///
  /// R8.1 (Astra N05, Claude AUD-6): the same holds for every Insight —
  /// I1's and I2's Plan change and I3's left-out part complete only once
  /// their own store has confirmed them; until then, and if they fail,
  /// nothing is recorded as applied, nothing claims success
  /// ([InsightActionResult.notSaved]) and it can be tried again. The
  /// applied record itself is awaited: if only it fails, the change stands
  /// (it was confirmed) and the failure is told.
  ///
  /// R8.2 (Astra R81-A04/A07): decided on what is on disk — a Plan change
  /// or History write still pending is waited for first, so the cycle, Plan
  /// or part it validates is the one it changes ([CirclePlansNotifier
  /// .keepGentler] names its cycle).
  ///
  /// R8.2 (Astra R81-A08, Claude's marker-retry observation; founder
  /// decision C): I1–I3 save their change with the Insight's own id on it —
  /// the Plan ([PlanProgress.appliedInsight], with its cycle) or the
  /// left-out part ([ElementLeftOut.byInsight]) — in the change's own save,
  /// so that provenance is on disk exactly when the change is. When the
  /// change landed and only the applied mark didn't, the Insight is no
  /// longer current; a retry finds that provenance ([_appliedOn]) and
  /// records the mark, never making the change again. The Plan being
  /// active, the cycle gentler or the part left out is never enough on its
  /// own: a change the user made some other way carries no such record and
  /// is never claimed — the Insight is then reported not available, never
  /// applied. No separate record of the intent is needed, so none can fail
  /// apart from the change.
  ///
  /// R8.3 (Astra R82-N01, founder decision D3; architecture review contract
  /// 2): that provenance is looked for first, whatever the Insight's claim
  /// says today. A change the user reversed by hand since — a Plan paused
  /// or left, gentler turned off — can make the claim hold again; the
  /// Insight's own change already happened, so its mark is recorded, on the
  /// day of that change, and the change is never made again over the
  /// user's later choice. Without that provenance — never made, or another
  /// Insight's since — nothing is claimed.
  ///
  /// R8.3 (Astra R82-N02): the preferences are waited for too, so a part
  /// left out by hand and still being written is seen as left out; and the
  /// Insight is marked applied only when its own change was the one saved
  /// ([PreferenceChange.changed]).
  ///
  /// R8.3.2 (Astra R83-N03): a Plan holds the provenance of one Insight —
  /// the last whose own change it carries. Before this Insight's change
  /// replaces it, an earlier Insight it names whose applied mark isn't on
  /// disk is recorded as applied, from that provenance, on its own date
  /// ([_keepDisplacedApplication]); if that can't be saved, nothing is
  /// changed. So no Insight whose change landed is ever taken for one never
  /// applied, and its retry never makes the change again.
  Future<InsightActionResult> apply(String snapshotId) async {
    await ref.read(circlePlansProvider.notifier).idle();
    await ref.read(journalWritesProvider).idle();
    await ref.read(suggestionPreferencesProvider.notifier).idle();
    // R8.3.2: the marks as confirmed — one still being written may fail.
    await idle();
    final snapshot = state.byId(snapshotId);
    final keepsOwnCircle = snapshot?.application is KeepCircleFromHistory;
    if (!_premium && !keepsOwnCircle) return InsightActionResult.needsPremium;
    if (snapshot == null) return InsightActionResult.notAvailable;
    final i = inputs();
    final status = statusOf(snapshot, i);
    switch (status) {
      case InsightStatus.applied:
        return InsightActionResult.alreadyApplied;
      case InsightStatus.current || InsightStatus.stale:
        if (_appliedOn(snapshot, i) case final on?) {
          return _markApplied(snapshot, on);
        }
        if (status == InsightStatus.stale) {
          return InsightActionResult.notAvailable;
        }
      case _:
        return InsightActionResult.notAvailable;
    }
    switch (snapshot.application) {
      case PlanDirection(:final planId) || KeepGentler(:final planId):
        if (!await _keepDisplacedApplication(planId, snapshotId, i)) {
          return InsightActionResult.notSaved;
        }
      case _:
    }
    final result = switch (snapshot.application) {
      PlanDirection(:final planId) => await _direct(planId, snapshotId),
      KeepGentler(:final planId, :final cycleId) => await _gentler(
        planId,
        cycleId,
        snapshotId,
      ),
      LeaveOutPart(:final element) => await _leaveOut(element, i, snapshot),
      KeepCircleFromHistory(:final circleId) => await _keep(circleId, snapshot),
      OpenPlanReview() ||
      NothingToChange() => InsightActionResult.nothingToApply,
    };
    // R8.3.2 (founder scope decision B2): a day's Circle already kept by
    // some other Keep is never recorded as this Insight's application.
    if (result == InsightActionResult.done) {
      final current = state.byId(snapshotId) ?? snapshot;
      try {
        await _set(
          state.replacing(
            current.copyWith(appliedOn: dateKey(_now), clearAttempt: true),
          ),
        );
      } on StorageWriteFailed {
        // The change itself is confirmed; only its record here isn't — and
        // the user is told ([_set]). It is never shown as recorded; its
        // provenance lets a retry record it ([_appliedOn]).
      }
    }
    return result;
  }

  /// The day [snapshot]'s own change was made, when that change is on disk
  /// carrying this Insight's id although the Insight isn't marked applied
  /// (R8.2, Astra R81-A08, founder decision C): its Plan changed by it
  /// ([PlanProgress.appliedInsight]) — for I2, on the very cycle it names —
  /// or its part left out by it ([ElementLeftOut.byInsight]). Whatever has
  /// happened to the Plan or cycle since. `null` otherwise: the same state
  /// reached some other way is never this Insight's application.
  String? _appliedOn(InsightSnapshot snapshot, InsightInputs i) {
    switch (snapshot.application) {
      case PlanDirection(:final planId):
        final by = i.plans.plans[planId]?.appliedInsight;
        return by?.insightId == snapshot.id ? by!.on : null;
      case KeepGentler(:final planId, :final cycleId):
        final by = i.plans.plans[planId]?.appliedInsight;
        return by?.insightId == snapshot.id && by!.cycleId == cycleId
            ? by.on
            : null;
      case LeaveOutPart(:final element):
        for (final e in ref.read(suggestionPreferencesProvider).elementsLeftOut) {
          if (e.element.name == element && e.byInsight == snapshot.id) {
            return dateKey(e.since);
          }
        }
        return null;
      // R8.3.2 (founder scope decision B2): the kept Circle with the id its
      // attempt recorded — never another Keep of the same day.
      case KeepCircleFromHistory():
        final keptId = snapshot.attempt?.keptId;
        if (keptId == null) return null;
        for (final k in ref.read(keptCirclesProvider).kept) {
          if (k.id == keptId) return dateKey(k.createdAt);
        }
        return null;
      case _:
        return null;
    }
  }

  /// [from] with every Insight whose action was recorded as being made and
  /// is proven on disk ([_appliedOn]) marked applied on that action's day.
  InsightsState _withProvenAttempts(InsightsState from, InsightInputs i) {
    var next = from;
    for (final s in from.snapshots) {
      if (s.attempt == null || s.appliedOn != null) continue;
      if (_appliedOn(s, i) case final on?) {
        next = next.replacing(s.copyWith(appliedOn: on, clearAttempt: true));
      }
    }
    return next;
  }

  /// R8.3.2 (founder scope decisions B1/B2): records, and waits for the
  /// store to confirm, that [snapshot]'s action is about to be made. `false`
  /// when it isn't confirmed: the action is then never made.
  Future<bool> _recordAttempt(InsightSnapshot snapshot, {String? keptId}) async {
    final target = InsightAttempt.targetOf(snapshot.application)!;
    try {
      await _set(
        state.replacing(
          snapshot.copyWith(
            attempt: InsightAttempt(
              on: dateKey(_now),
              target: target,
              keptId: keptId,
            ),
          ),
        ),
      );
      return true;
    } on StorageWriteFailed {
      return false;
    }
  }

  /// [snapshotId]'s action is known not to have been made: its attempt
  /// record goes, so it can be tried again. If that isn't saved, the record
  /// stays and the Insight is never offered again — never made twice.
  Future<void> _clearAttempt(String snapshotId) async {
    final s = state.byId(snapshotId);
    if (s?.attempt == null) return;
    try {
      await _set(state.replacing(s!.copyWith(clearAttempt: true)));
    } on StorageWriteFailed {
      // Kept: the Insight stays unavailable.
    }
  }

  /// R8.3.2 (Astra R83-N03): before [insightId]'s own change replaces
  /// [planId]'s provenance, the Insight that provenance names — when it is
  /// a snapshot here not yet marked applied, its own change being on disk
  /// ([_appliedOn]) — is marked applied on that change's date. `false` when
  /// that mark isn't confirmed: the provenance must then stay.
  Future<bool> _keepDisplacedApplication(
    String planId,
    String insightId,
    InsightInputs i,
  ) async {
    final by = i.plans.plans[planId]?.appliedInsight;
    if (by == null || by.insightId == insightId) return true;
    final displaced = state.byId(by.insightId);
    if (displaced == null || displaced.appliedOn != null) return true;
    final on = _appliedOn(displaced, i);
    if (on == null) return true;
    return await _markApplied(displaced, on) == InsightActionResult.done;
  }

  /// Records [snapshot] as applied on [on] — its change already on disk.
  Future<InsightActionResult> _markApplied(
    InsightSnapshot snapshot,
    String on,
  ) async {
    try {
      await _set(
        state.replacing(snapshot.copyWith(appliedOn: on, clearAttempt: true)),
      );
      return InsightActionResult.done;
    } on StorageWriteFailed {
      return InsightActionResult.notSaved;
    }
  }

  Future<InsightActionResult> _direct(String planId, String insightId) async {
    final lifecycle = ref
        .read(circlePlansProvider.notifier)
        .confirmedState
        .lifecycleOf(planId);
    if (lifecycle == PlanLifecycle.active) {
      return InsightActionResult.alreadyApplied;
    }
    return _fromPlan(
      await ref
          .read(circlePlansProvider.notifier)
          .confirmed(
            (plans) => switch (lifecycle) {
              PlanLifecycle.paused => plans.resume(planId, byInsight: insightId),
              PlanLifecycle.neverStarted => plans.start(
                planId,
                byInsight: insightId,
              ),
              _ => plans.goThroughAgain(planId, byInsight: insightId),
            },
          ),
    );
  }

  Future<InsightActionResult> _gentler(
    String planId,
    String cycleId,
    String insightId,
  ) async {
    final plan = ref
        .read(circlePlansProvider.notifier)
        .confirmedState
        .plans[planId];
    if (plan == null || plan.current.id != cycleId) {
      return InsightActionResult.notAvailable;
    }
    if (plan.current.isGentler) return InsightActionResult.alreadyApplied;
    return _fromPlan(
      await ref
          .read(circlePlansProvider.notifier)
          .confirmed(
            (plans) => plans.keepGentler(
              planId,
              cycleId: cycleId,
              byInsight: insightId,
            ),
          ),
    );
  }

  InsightActionResult _fromPlan(PlanActionResult result) => switch (result) {
    PlanActionResult.done => InsightActionResult.done,
    PlanActionResult.needsPremium => InsightActionResult.needsPremium,
    PlanActionResult.notAvailable => InsightActionResult.notAvailable,
    PlanActionResult.notSaved => InsightActionResult.notSaved,
  };

  /// R8.3.2 (founder scope decision B1): the user's Put back removes the
  /// left-out part with this Insight's id on it, so the attempt is recorded
  /// first ([_recordAttempt]). A change known not to have been made clears
  /// it; one that may be on disk all the same ([PreferenceChange.uncertain])
  /// keeps it, and the Insight is never offered again.
  Future<InsightActionResult> _leaveOut(
    String wire,
    InsightInputs i,
    InsightSnapshot snapshot,
  ) async {
    final element = ElementId.values.asNameMap()[wire];
    if (element == null) return InsightActionResult.notAvailable;
    if (i.leftOut.contains(element)) return InsightActionResult.alreadyApplied;
    if (!await _recordAttempt(snapshot)) return InsightActionResult.notSaved;
    final outcome = await ref
        .read(suggestionPreferencesProvider.notifier)
        .leaveOutChange(element, byInsight: snapshot.id);
    switch (outcome) {
      case PreferenceChange.changed:
        return InsightActionResult.done;
      case PreferenceChange.uncertain:
        return InsightActionResult.notSaved;
      case PreferenceChange.unchanged ||
          PreferenceChange.refused ||
          PreferenceChange.notSaved:
        await _clearAttempt(snapshot.id);
        // Left out by something else meanwhile: never this Insight's.
        return outcome == PreferenceChange.unchanged
            ? InsightActionResult.alreadyApplied
            : InsightActionResult.notSaved;
    }
  }

  /// R8.3.2 (founder scope decision B2): removing the kept Circle removes
  /// every trace of this Keep, so the attempt is recorded first, with the id
  /// the kept Circle is given ([_recordAttempt]). A day's Circle kept some
  /// other way is never this Insight's: nothing is kept, nothing recorded.
  Future<InsightActionResult> _keep(
    String circleId,
    InsightSnapshot snapshot,
  ) async {
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
    final keptId = 'kept-${_now.microsecondsSinceEpoch}-insight';
    if (!await _recordAttempt(snapshot, keptId: keptId)) {
      return InsightActionResult.notSaved;
    }
    try {
      final circle = await ref
          .read(keptCirclesProvider.notifier)
          .keepCircle(
            plan: plan,
            need: entry.direction,
            circleId: circleId,
            id: keptId,
          );
      if (circle != null) return InsightActionResult.done;
      // Refused before anything was written.
      await _clearAttempt(snapshot.id);
      return refused(ref.read(keptCirclesProvider)) ??
          InsightActionResult.notAvailable;
    } on StorageWriteFailed catch (failure) {
      if (!failure.uncertain) await _clearAttempt(snapshot.id);
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
  ///
  /// R8.2 (Astra R81-A02, Claude NEW-2): from this moment nothing deleted
  /// is what the Insights fall back to — a save that fails later is never
  /// rolled back onto the deleted snapshots, even if this removal fails
  /// (the intent to delete is on disk; the next start finishes it).
  Future<void> forgetAll() {
    state = InsightsState.empty;
    _deletions++;
    _durable = InsightsState.empty;
    _queued = null;
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
        .then((_) => setAside)
        .then((_) => _durable = InsightsState.empty);
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
