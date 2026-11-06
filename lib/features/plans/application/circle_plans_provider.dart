import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/premium/entitlement_status.dart';
import '../../../core/premium/premium_access.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/storage/confirmed_write.dart';
import '../../../core/storage/preservation_writes.dart';
import '../../../core/storage/store_save_failures.dart';
import '../../../core/utils/date_key.dart';
import '../../home/application/circle_journal.dart';
import '../../home/domain/recommendation_engine.dart';
import '../../personal_circle/domain/circle_composer.dart';
import '../../personal_circle/domain/circle_elements.dart';
import '../domain/circle_plan.dart';
import '../domain/plan_stage_provenance.dart';

/// Where the user's Circle Plans are kept (ADR-024 B3): one versioned JSON
/// record. A new key — nothing from V1's Plans or Phase D's Paths is ever
/// read into it.
const circlePlansKey = 'circle_plans_v2';

/// A record that couldn't be read is kept here, untouched, rather than
/// overwritten.
const circlePlansUnreadableKey = 'circle_plans_v2_unreadable';

/// What a Plan action did.
enum PlanActionResult {
  done,

  /// Running Plans is Premium (ADR-024 §13): nothing changed.
  needsPremium,

  /// The action doesn't apply to the Plan as it stands: nothing changed.
  notAvailable,

  /// The store didn't confirm the change (R8.1, Astra N05 — only from
  /// [CirclePlansNotifier.confirmed]): it isn't saved, and nothing may be
  /// recorded as following from it.
  notSaved,
}

/// The user's explicit usefulness answers in [journal], by Circle id.
StageAnswers stageAnswersFrom(Iterable<CircleJournalEntry> journal) => {
  for (final entry in journal)
    entry.circleId: ?switch (entry.usefulnessResponse) {
      CircleUsefulnessResponse.veryUseful => PastUsefulness.veryUseful,
      CircleUsefulnessResponse.somewhatUseful => PastUsefulness.somewhatUseful,
      CircleUsefulnessResponse.notUseful => PastUsefulness.notUseful,
      null => null,
    },
};

/// The user's Circle Plans. Every change goes through a Plan action or
/// Today's Circle — there is no way to set the state directly — and
/// running a Plan (starting, carrying on, steering, moving on, revisiting)
/// needs an active entitlement, checked here rather than only in the UI.
/// Pausing and leaving never do: what the user saved stays theirs.
class CirclePlansNotifier extends Notifier<CirclePlansState> {
  Future<void> _writes = Future<void>.value();

  /// The Plans as the store last confirmed them (R8.1, Astra N01 / Claude
  /// AUD-1): read from disk at [build], then each state whose save was
  /// confirmed. [state] may be ahead of it — shown, not yet saved — and
  /// nothing that must be durable is ever judged by [state] alone.
  CirclePlansState _durable = CirclePlansState.empty;

  /// The state the last queued save is writing, while it may still land,
  /// and that save — so [ensureSaved] waits for it instead of writing the
  /// same record twice.
  CirclePlansState? _queued;
  Future<void>? _queuedWrite;

  /// How many Delete Circle histories have begun ([forgetStageEvidence]).
  int _deletions = 0;

  /// The most rounds a decision waits for pending Plan changes to settle
  /// before it refuses (R8.2): each round waits for real writes, so only
  /// a user changing the Plans again and again reaches it.
  static const _maxRounds = 8;

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  /// Completes, never failing, once no Plans save is still being written —
  /// each has landed, or failed and been taken back off the screen ([_set])
  /// (R8.2). What a decision that must see the outcome of a pending change
  /// waits for.
  Future<void> idle() async {
    for (;;) {
      final pending = _writes;
      await pending;
      if (identical(pending, _writes)) return;
    }
  }

  @override
  CirclePlansState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final read = _read(prefs);
    _durable = read;
    _queued = null;
    _queuedWrite = null;
    return read;
  }

  CirclePlansState _read(SharedPreferences prefs) {
    // R8.2 (Astra R81-A09): read as whatever native type is stored — a
    // value that isn't text is a record THIRTY can't read, never a crash.
    final raw = prefs.get(circlePlansKey);
    if (raw == null) return CirclePlansState.empty;
    if (raw is String) {
      try {
        final state = CirclePlansState.fromJson(jsonDecode(raw));
        if (state != null) return state;
      } catch (_) {
        // Unreadable: kept aside below.
      }
    }
    // Kept aside at once — a tracked write (R8.1, Astra N02): a save that
    // follows waits for it and confirms the copy first ([_protectStored]),
    // and Delete Circle history waits for it, so the original is never
    // written over unkept and the copy never lands after a deletion.
    if (prefs.get(circlePlansUnreadableKey) == null) {
      ref
          .read(preservationWritesProvider)
          .keepAside(prefs, circlePlansUnreadableKey, raw);
    }
    return CirclePlansState.empty;
  }

  /// Whether what is shown holds a change the store hasn't confirmed —
  /// pending: one still being written (R8.1 RL-1; a failed one is taken
  /// back off the screen, [_set]).
  bool get hasUnsavedChanges => !identical(state, _durable);

  /// The Plans as the store has confirmed them (R8.1 RL-1, founder decision
  /// 2026-11-05): what decisions that depend on the Plans — Insights, and
  /// whether a stage Circle may be saved ([confirmServed]) — read, never a
  /// change still pending.
  CirclePlansState get confirmedState => _durable;

  /// Completes once the store holds the Plans as shown — at once when it
  /// already does, otherwise by (re)writing the whole record; fails with
  /// [StorageWriteFailed] when the store doesn't confirm it (R8.1, Astra
  /// N01/N04/N05). Never reports as saved what is only in memory.
  Future<void> ensureSaved() {
    if (!hasUnsavedChanges) return Future<void>.value();
    if (identical(state, _queued) && _queuedWrite != null) {
      return _queuedWrite!;
    }
    return _set(state);
  }

  /// Whether the store holds [circleId]'s guided credit on [planId] — what
  /// recovery reads, never memory (R8.1, Astra N01).
  bool isCreditedDurably(String planId, {required String circleId}) =>
      _credited(_durable, planId, circleId);

  static bool _credited(
    CirclePlansState plans,
    String planId,
    String circleId,
  ) =>
      plans.plans[planId]?.cycles.any(
        (c) => c.records.any((r) => r.circleId == circleId),
      ) ??
      false;

  bool get _premium => ref.read(premiumEntitlementProvider);
  String get _today => dateKey(ref.read(nowProvider));

  /// Shows [next] and saves it. Audit remediation R8 (Claude F-6): the save
  /// must be confirmed by the store ([writeConfirmed]). One that isn't is,
  /// with [report], shown to the user ([storeSaveFailuresProvider]); Today
  /// reports its own, and keeps what it needs to write it again (the
  /// Start's billing answer, [noteStart]). Never over a
  /// stored record THIRTY can't read until a copy is confirmed aside
  /// ([_protectStored]). The returned future fails when the save does.
  ///
  /// R8.1 (Astra N01): once confirmed, [next] is what the store holds
  /// ([_durable]).
  ///
  /// R8.1 RL-1 (founder decision 2026-11-05): a change the store refuses is
  /// never left on screen as if it were made. When the latest save fails,
  /// the Plans go back to what the store holds — the change, and anything
  /// computed from it, is undone in memory — and the user is told. A change
  /// still being written is pending: shown, but nothing that must be
  /// durable is decided on it ([confirmedState], [confirmServed]).
  Future<void> _set(CirclePlansState next, {bool report = true}) {
    state = next;
    final json = jsonEncode(next.toJson());
    final prefs = _prefs;
    final preservations = ref.read(preservationWritesProvider);
    final generation = _deletions;
    final write = _writes.then((_) async {
      await _protectStored(prefs, preservations);
      await writeConfirmed(prefs, circlePlansKey, json);
      // R8.2 (Astra R81-A02): a save queued before Delete Circle history
      // began lands before the deletion's own write — but its stage
      // evidence is never again what the Plans fall back to or decide on.
      _durable = generation == _deletions ? next : next.forgetStageEvidence();
    });
    _queued = next;
    _queuedWrite = write;
    _writes = write.then(
      (_) {
        if (identical(_queued, next)) _queued = _queuedWrite = null;
        if (ref.mounted && !hasUnsavedChanges) {
          ref
              .read(storeSaveFailuresProvider.notifier)
              .saved(UserStore.circlePlans);
        }
      },
      onError: (Object _) {
        final latest = identical(_queued, next);
        if (latest) _queued = _queuedWrite = null;
        if (!ref.mounted) return;
        ref
            .read(storeSaveFailuresProvider.notifier)
            .record(UserStore.circlePlans, notify: report);
        // The latest save failed: what is shown goes back to what is on
        // disk, so nothing unsaved stays on screen (R8.1 RL-1). The store
        // stays marked unsaved until a later save of it is confirmed.
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
    await preservations.settled(circlePlansUnreadableKey);
    final raw = prefs.get(circlePlansKey);
    if (raw == null) return;
    if (raw is String && _readable(raw)) return;
    // R8.2 (Astra R81-A09): kept as stored — a value of another native
    // type keeps its type.
    final aside = prefs.get(circlePlansUnreadableKey);
    if (sameStoredValue(aside, raw)) return;
    if (aside != null) {
      throw const StorageWriteFailed(
        circlePlansKey,
        'an earlier unreadable record is already kept aside',
      );
    }
    await writeConfirmed(prefs, circlePlansUnreadableKey, raw);
  }

  static bool _readable(String raw) {
    try {
      return CirclePlansState.fromJson(jsonDecode(raw)) != null;
    } catch (_) {
      return false;
    }
  }

  PlanActionResult _apply(CirclePlansState? next, {required bool running}) {
    if (running && !_premium) return PlanActionResult.needsPremium;
    if (next == null) return PlanActionResult.notAvailable;
    _set(next).ignore();
    return PlanActionResult.done;
  }

  /// A change of a Plan's lifecycle — pausing, leaving, starting or carrying
  /// on a Plan (which pauses the active one), going through one again —
  /// made on the Plans with every credit already earned folded in first
  /// ([_withEarnedCredits]), in the same save (R8.2, founder decision A).
  /// [byInsight] names the Insight whose own action this is ([_byInsight]).
  PlanActionResult _lifecycle(
    String planId,
    CirclePlansState? Function(CirclePlansState plans) change, {
    required bool running,
    String? byInsight,
  }) {
    if (running && !_premium) return PlanActionResult.needsPremium;
    final earned = _withEarnedCredits(state);
    final next = change(earned);
    if (next == null) {
      // The Plan as it stands doesn't allow the change — a credit folded
      // in may have just ended it. The credit is still saved.
      if (!identical(earned, state)) _set(earned).ignore();
      return PlanActionResult.notAvailable;
    }
    return _apply(
      _byInsight(_withActionOrder(earned, next), planId, byInsight),
      running: running,
    );
  }

  /// R8.2 Plan lifecycle policy (founder directive, 2026-11-06): what the
  /// user did to today's stage Circle, and when — told by Today at the
  /// moment of the action, before anything is saved, so the actual order
  /// of a Start or Close and a later Pause or Leave is known however slow
  /// storage is. In memory only; after a restart Today tells it again from
  /// what it restores, and History's record stands in.
  final Map<String, DateTime> _startedAt = {};
  final Map<String, DateTime> _closeRequestedAt = {};

  /// Today's stage Circle [circleId] was started at [at].
  void noteStarted(String circleId, DateTime at) => _startedAt[circleId] = at;

  /// The user asked to close today's stage Circle [circleId] at [at].
  void noteCloseRequested(String circleId, DateTime at) =>
      _closeRequestedAt[circleId] = at;

  CircleJournalEntry? _shownInHistory(String circleId) => ref
      .read(circleJournalRepositoryProvider)
      .readAll()
      .where((e) => e.circleId == circleId)
      .firstOrNull;

  /// [after] — a lifecycle change made on [before] — with the order of the
  /// user's own actions on each Plan's served Circle recorded in the same
  /// save ([CirclePlansState.stampServed]):
  /// - a Plan paused (by Pause, or by starting another Plan) after its
  ///   served Circle was started: that Start came first;
  /// - a Plan left after the user asked to close its served Circle — the
  ///   Close may still be being saved: that Close came first.
  /// Nothing is credited here: [recordGuided] credits only a durable Close,
  /// and only the very Start and Close recorded. A Circle already credited
  /// needs nothing.
  CirclePlansState _withActionOrder(
    CirclePlansState before,
    CirclePlansState after,
  ) {
    var next = after;
    for (final MapEntry(key: planId, value: now) in after.plans.entries) {
      final was = before.plans[planId];
      final served = was?.lastServed;
      if (was == null || served == null) continue;
      if (served.stage.cycleId != was.current.id || was.current.isOver) {
        continue;
      }
      final circleId = served.circleId;
      if (_credited(before, planId, circleId)) continue;
      final pausing =
          was.lifecycle == PlanLifecycle.active &&
          now.lifecycle == PlanLifecycle.paused;
      final leaving =
          now.lifecycle == PlanLifecycle.left &&
          (was.lifecycle == PlanLifecycle.active ||
              (was.lifecycle == PlanLifecycle.paused &&
                  served.startedBeforePause != null));
      if (pausing) {
        final at =
            _startedAt[circleId] ?? _shownInHistory(circleId)?.startedAt;
        if (at != null) {
          next = next.stampServed(
            planId,
            circleId: circleId,
            startedBeforePause: at,
          );
        }
      } else if (leaving) {
        final at =
            _closeRequestedAt[circleId] ?? _shownInHistory(circleId)?.closedAt;
        if (at != null) {
          next = next.stampServed(
            planId,
            circleId: circleId,
            closedBeforeLeave: at,
          );
        }
      }
    }
    return next;
  }

  /// [next] with [planId] marked as changed by Insight [insightId]'s own
  /// action ([PlanProgress.appliedInsight], R8.2 founder decision C) — in
  /// the same save as the change, so it is on disk exactly when the change
  /// is.
  CirclePlansState _byInsight(
    CirclePlansState next,
    String planId,
    String? insightId,
  ) => insightId == null
      ? next
      : next.withAppliedInsight(planId, insightId, today: _today);

  /// [plans] with the guided credit of every stage Circle already started
  /// and closed folded in (R8.2, founder decision A): the active Plan's last
  /// served Circle, when History's store has confirmed its Close
  /// ([CircleJournalRepository.readConfirmed]) and its credit isn't
  /// recorded yet — because the credit's own save failed, or hasn't run.
  /// The Close was durably recorded before the change about to be made, so
  /// that change can't erase what it earned: the credit goes to the
  /// original cycle and Circle, under the same rules as [recordGuided]
  /// (served under Premium and not started after a verified expiry, or
  /// Premium now), at most once. A Close not yet confirmed — a Pause or
  /// Leave before it was durable — is not folded in: that order keeps the
  /// rule that a paused or left Plan earns no credit.
  CirclePlansState _withEarnedCredits(CirclePlansState plans) {
    var next = plans;
    List<CircleJournalEntry>? journal;
    for (final plan in plans.plans.values) {
      final served = plan.lastServed;
      // R8.2 Plan lifecycle policy: a paused Plan's served Circle started
      // before the Pause is owed its credit too ([recordGuided] decides).
      if ((plan.lifecycle != PlanLifecycle.active &&
              plan.lifecycle != PlanLifecycle.paused) ||
          served == null ||
          served.stage.cycleId != plan.current.id) {
        continue;
      }
      journal ??= ref.read(circleJournalRepositoryProvider).readConfirmed();
      final closed = journal
          .where(
            (e) =>
                e.circleId == served.circleId &&
                e.startedAt != null &&
                e.closedAt != null,
          )
          .firstOrNull;
      final session = closed?.session;
      final recorded = session?.planStage;
      if (closed == null ||
          session == null ||
          recorded == null ||
          !served.matches(recorded, circleId: closed.circleId)) {
        continue;
      }
      final stage = served.stage;
      if (!_premium && !next.creditsServed(stage, circleId: closed.circleId)) {
        continue;
      }
      next = next.recordGuided(
        stage,
        circleId: closed.circleId,
        today: closed.localDate,
        parts: session.parts,
        skipped: session.skipped,
        startedAt: closed.startedAt,
        closedAt: closed.closedAt,
      );
    }
    return next;
  }

  /// [action] — one of this notifier's Plan actions — completed only once
  /// the store has confirmed the Plans as they then stand (R8.1, Astra N05):
  /// [PlanActionResult.done] means saved; [PlanActionResult.notSaved] that
  /// it isn't — the change is then off the screen ([_set]) — and nothing may
  /// be recorded as following from it.
  ///
  /// R8.2 (Claude NEW-3): saved means on disk, whichever save put it there.
  /// When this action's own save fails, the saves still queued behind it
  /// are waited for; if one of them landed holding exactly the change this
  /// action made, it is [PlanActionResult.done]. A change no save landed is
  /// never reported as saved.
  Future<PlanActionResult> confirmed(
    PlanActionResult Function(CirclePlansNotifier plans) action,
  ) async {
    final before = state;
    final result = action(this);
    if (result != PlanActionResult.done) return result;
    final after = state;
    try {
      await ensureSaved();
      return PlanActionResult.done;
    } on StorageWriteFailed {
      await idle();
      return _holdsChange(_durable, before, after)
          ? PlanActionResult.done
          : PlanActionResult.notSaved;
    }
  }

  /// Whether [stored] holds every value that changed from [before] to
  /// [after] — added, changed or removed — whatever else it holds.
  static bool _holdsChange(
    CirclePlansState stored,
    CirclePlansState before,
    CirclePlansState after,
  ) {
    final was = _leaves(before.toJson());
    final now = _leaves(after.toJson());
    final disk = _leaves(stored.toJson());
    for (final path in {...was.keys, ...now.keys}) {
      if (was[path] != now[path] && disk[path] != now[path]) return false;
    }
    return true;
  }

  /// [json] as its leaf values, by path.
  static Map<String, String> _leaves(Object? json, [String path = '']) {
    final out = <String, String>{};
    void walk(Object? value, String at) {
      switch (value) {
        case final Map<Object?, Object?> map when map.isNotEmpty:
          for (final MapEntry(:key, :value) in map.entries) {
            walk(value, '$at/$key');
          }
        case final List<Object?> list when list.isNotEmpty:
          for (final (i, item) in list.indexed) {
            walk(item, '$at[$i]');
          }
        default:
          out[at] = jsonEncode(value);
      }
    }

    walk(json, path);
    return out;
  }

  /// Completes once the store holds [stage] as served for [circleId] — the
  /// Plan state that stage Circle was composed from (R8.1 RL-1): at once
  /// when it already does; after the pending save when that save holds it;
  /// otherwise it fails with [StorageWriteFailed]. Today saves a stage
  /// Circle only after this, so no Circle is ever saved on a Plan change
  /// that didn't land.
  Future<void> confirmServed(
    PlanStageProvenance stage, {
    required String circleId,
  }) async {
    if (_durable.wasServed(stage, circleId: circleId)) return;
    if (state.wasServed(stage, circleId: circleId)) await ensureSaved();
    if (!_durable.wasServed(stage, circleId: circleId)) {
      throw const StorageWriteFailed(
        circlePlansKey,
        'the stage this Circle was composed for is not on disk',
      );
    }
  }

  /// Start [planId] (pausing any other active Plan at its place); a paused
  /// one carries on where it was.
  ///
  /// [byInsight]: the Insight whose own action this is (R8.2, founder
  /// decision C) — recorded with the change ([PlanProgress.appliedInsight]).
  PlanActionResult start(String planId, {String? byInsight}) => _lifecycle(
    planId,
    (plans) => plans.start(planId, today: _today),
    running: true,
    byInsight: byInsight,
  );

  PlanActionResult pause(String planId) =>
      _lifecycle(planId, (plans) => plans.pause(planId), running: false);

  /// "Carry on". [byInsight] as for [start].
  PlanActionResult resume(String planId, {String? byInsight}) => _lifecycle(
    planId,
    (plans) => plans.resume(planId),
    running: true,
    byInsight: byInsight,
  );

  PlanActionResult leave(String planId) => _lifecycle(
    planId,
    (plans) => plans.leave(planId, today: _today),
    running: false,
  );

  /// [byInsight] as for [start].
  PlanActionResult goThroughAgain(String planId, {String? byInsight}) =>
      _lifecycle(
        planId,
        (plans) => plans.goThroughAgain(planId, today: _today),
        running: true,
        byInsight: byInsight,
      );

  /// "This stage again next time" / "Try this stage".
  PlanActionResult requestRevisit(String planId, int stageNumber) =>
      _apply(state.requestRevisit(planId, stageNumber), running: true);

  /// ADR-024 I2's application, approved by the user: "Keep this Plan's
  /// Circles gentler for now" for the current cycle. Never stacked.
  ///
  /// R8.2 (Astra R81-A04): with [cycleId], only that cycle — I2 changes the
  /// cycle it was shown for, or nothing. [byInsight] as for [start].
  PlanActionResult keepGentler(
    String planId, {
    String? cycleId,
    String? byInsight,
  }) => _apply(
    switch (state.keepGentler(planId, today: _today, cycleId: cycleId)) {
      final next? => _byInsight(next, planId, byInsight),
      null => null,
    },
    running: true,
  );

  /// Turns the gentler setting off — giving a setting up is never gated.
  PlanActionResult stopGentler(String planId) =>
      _apply(state.stopGentler(planId), running: false);

  /// The user's answers as History's store has confirmed them (R8.2, Astra
  /// R81-A07): a stage — stage 5 above all — is never composed from an
  /// answer, or a removal, still being written.
  StageAnswers _answers() => stageAnswersFrom(
    ref.read(circleJournalRepositoryProvider).readConfirmed(),
  );

  /// Today's Circle for the active Plan ([planToday]): today's set-asides
  /// and any end are kept. Without Premium, nothing applies and nothing
  /// changes.
  ///
  /// [circleId] is the Circle the stage is served for (R8.1, Astra N08):
  /// the day of the choice itself — by default [context]'s date, never the
  /// cached day, which a choice after midnight with no touch still holds.
  PlanDay steerToday(
    ComposerContext context,
    Iterable<PastCircle> history, {
    SuggestionControls controls = SuggestionControls.none,
    Set<ElementId> leftOut = const {},
    String? circleId,
  }) {
    final premium = _premium;
    if (!premium || state.active == null) return PlanDay(state);
    final day = planToday(
      state,
      premium: premium,
      context: context,
      history: history,
      answers: _answers(),
      controls: controls,
      leftOut: leftOut,
    );
    // A stage Circle served now, under Premium, is remembered with its
    // stage: what credits it at Close (recordGuided).
    final stage = day.stage;
    final next = stage != null && day.circle != null
        ? day.state.served(stage, circleId: circleId ?? dateKey(context.date))
        : day.state;
    if (!identical(next, state)) _set(next).ignore();
    return day;
  }

  /// "Not this one today" on today's stage Circle: one recomposition inside
  /// the stage, or `null` (then the stage waits). Premium only.
  ComposedCircle? replaceStage(
    PlanStageProvenance stage,
    ComposerContext context,
    Iterable<PastCircle> history, {
    SuggestionControls controls = SuggestionControls.none,
    Set<ElementId> leftOut = const {},
  }) {
    if (!_premium) return null;
    final briefs = briefsForServedStage(
      state,
      stage,
      answers: _answers(),
      date: context.date,
    );
    if (briefs == null) return null;
    return replaceStageCircle(
      briefs,
      context: stage.gentler ? gentlerContext(context) : context,
      history: history,
      controls: controls,
      leftOut: leftOut,
    );
  }

  /// Today's stage Circle [circleId] is being started (R2, founder decision
  /// on the expiry before Start). Only billing's verified answer counts: a
  /// Circle started once Premium has verifiably ended
  /// ([EntitlementStatus.inactive]) keeps its served evidence but earns no
  /// credit of its own; one started under verified Premium does. Still
  /// being checked or unavailable proves nothing, so nothing is recorded.
  /// Completes once the record is written, so the start that follows can
  /// never be saved without it.
  ///
  /// [status] is billing's answer at the Start itself — by default, now.
  /// R8.1 RL-1: Today keeps it, so a record whose save failed (and so is
  /// off the screen) is written again from the same answer, never from a
  /// later one.
  Future<void> noteStart(
    PlanStageProvenance stage, {
    required String circleId,
    EntitlementStatus? status,
  }) {
    final EntitlementStatus verdict =
        status ?? ref.read(entitlementStatusProvider);
    return _settleStart(stage, circleId, switch (verdict) {
      EntitlementStatus.active => true,
      EntitlementStatus.inactive => false,
      EntitlementStatus.initializing || EntitlementStatus.unavailable => null,
    });
  }

  /// Completes once [circleId]'s served-stage evidence — what [noteStart]
  /// recorded about its Start — is on disk exactly as shown; fails with
  /// [StorageWriteFailed] otherwise (R8.1, Astra N04). Today's later
  /// lifecycle writes of a stage Circle wait for it, so no Close, pause or
  /// recovery is ever saved over a Start record that didn't land.
  ///
  /// R8.2 (Claude NEW-1): about [circleId]'s own record only. A later Plan
  /// action — a new cycle, another Circle served — that replaced it is not
  /// its concern: once nothing shown or stored holds that record, there is
  /// nothing left of it to save, and its Close is never held back by it.
  Future<void> confirmStartNoted(
    PlanStageProvenance stage, {
    required String circleId,
  }) => _settleStart(stage, circleId, null);

  /// Whether [circleId]'s Start under billing's [status] needs no Plans
  /// write (R8.2, founder decision B): the stage it was served for is on
  /// disk exactly as shown, and already says what [noteStart] would record.
  /// Otherwise Today waits for [noteStart] before the Circle is started.
  bool startNeedsNoWrite(
    PlanStageProvenance stage, {
    required String circleId,
    required EntitlementStatus status,
  }) {
    final stored = _servedRecord(_durable, stage, circleId);
    if (stored == null || _servedRecord(state, stage, circleId) != stored) {
      return false;
    }
    final active = switch (status) {
      EntitlementStatus.active => true,
      EntitlementStatus.inactive => false,
      EntitlementStatus.initializing || EntitlementStatus.unavailable => null,
    };
    return active == null ||
        identical(
          _durable.noteStart(stage, circleId: circleId, active: active),
          _durable,
        );
  }

  /// [noteStart] and [confirmStartNoted]: with [active], the Start is noted
  /// on the served record first. Completes once that record is as shown on
  /// disk too — or, when a pending change no longer shows it, once that
  /// change has settled (it may have been rolled back, and the record with
  /// it).
  Future<void> _settleStart(
    PlanStageProvenance stage,
    String circleId,
    bool? active,
  ) async {
    for (var round = 0; ; round++) {
      if (round > _maxRounds) {
        throw const StorageWriteFailed(
          circlePlansKey,
          'the Start record waits on Plan changes still being saved',
        );
      }
      if (active != null) {
        final next = state.noteStart(stage, circleId: circleId, active: active);
        // Today reports a Start whose evidence wasn't saved (audit
        // remediation R8): it never saves the Start without it.
        if (!identical(next, state)) return _set(next, report: false);
      }
      final shown = _servedRecord(state, stage, circleId);
      final stored = _servedRecord(_durable, stage, circleId);
      if (shown == stored) return;
      // R8.1 (Astra N01/N04): already noted but still pending is not saved.
      if (shown != null) {
        await ensureSaved();
      } else {
        await idle();
      }
    }
  }

  /// [circleId]'s served record in [plans], as stored text, or `null`.
  static String? _servedRecord(
    CirclePlansState plans,
    PlanStageProvenance stage,
    String circleId,
  ) {
    final served = plans.plans[stage.planId]?.lastServed;
    if (served == null || !served.matches(stage, circleId: circleId)) {
      return null;
    }
    return jsonEncode(served.toJson());
  }

  /// Today's stage Circle was started and has now been closed: the stage
  /// is guided and the Plan moves on — once per Circle. Credit follows
  /// where the Circle came from, not billing at the moment of Close (audit
  /// remediation R2, founder decision D2): the stage Circle THIRTY served
  /// under Premium ([CirclePlansState.wasServed]) is credited even if the
  /// entitlement is still being checked, unavailable or has since ended.
  /// Any other stage needs Premium now. A Circle can only gain a stage
  /// while Premium is active (steerToday, replaceStage), so nothing served
  /// after an expiry is ever credited — nor is a served Circle started only
  /// after one ([noteStart]).
  ///
  /// Completes once the credit is written (audit remediation R3). Today
  /// credits a Close only once the Close itself is saved, and catches up a
  /// saved Close not yet credited on the next start.
  ///
  /// [on] is the Circle's own day (audit remediation R3) — by default, today.
  ///
  /// R8.2 (Astra R81-A01): completes only once the credit is resolved on
  /// disk — never because the Plans *shown* make it a no-op:
  /// - credited on disk already: done;
  /// - credited on screen, not yet on disk (pending): it is saved first;
  /// - not owed by the Plans on disk either — a Plan paused, left or moved
  ///   on to another cycle there, a Circle not eligible: legitimately
  ///   unnecessary, done;
  /// - owed on disk but a no-op on screen, because a Plan change is still
  ///   being saved: blocked. That change is waited for — it lands, or it
  ///   fails and is rolled back, and the credit is resolved again. A credit
  ///   still blocked after [_maxRounds] fails with [StorageWriteFailed], so
  ///   Today never writes over the session it belongs to.
  ///
  /// Founder decision A (R8.2 acceptance review): a Pause, Leave or another
  /// Plan started after this Close was durable folds the credit into its
  /// own save ([_withEarnedCredits]) — the later change never erases it.
  ///
  /// R8.2 Plan lifecycle policy (founder directive, 2026-11-06): [startedAt]
  /// and [closedAt] are this Circle's own Start and Close. A Plan paused
  /// after that Start, or left after that Close was asked for, is still
  /// credited ([CirclePlansState.recordGuided], [_withActionOrder]); a Plan
  /// paused before the Start or left before the Close is not.
  Future<void> recordGuided(
    PlanStageProvenance stage, {
    required String circleId,
    required List<String> parts,
    required List<String> skipped,
    String? on,
    DateTime? startedAt,
    DateTime? closedAt,
  }) async {
    final today = on ?? _today;
    CirclePlansState? credit(CirclePlansState plans) {
      if (!_premium && !plans.creditsServed(stage, circleId: circleId)) {
        return null;
      }
      final next = plans.recordGuided(
        stage,
        circleId: circleId,
        today: today,
        parts: parts,
        skipped: skipped,
        startedAt: startedAt,
        closedAt: closedAt,
      );
      return identical(next, plans) ? null : next;
    }

    for (var round = 0; ; round++) {
      if (credit(state) case final next?) return _set(next);
      if (_credited(_durable, stage.planId, circleId)) return;
      // R8.1 (Astra N01 / Claude AUD-1): a credit already in memory but not
      // on disk is not a recorded credit — it is written again, and this
      // completes only once the store confirms it.
      // Founder decision A (R8.2): it may be in memory because a Pause or
      // Leave folded it in ([_withEarnedCredits]); if that save fails, both
      // are rolled back and the credit is resolved again on what the disk
      // then holds.
      if (_credited(state, stage.planId, circleId)) {
        try {
          await ensureSaved();
        } on StorageWriteFailed {
          if (round >= _maxRounds) rethrow;
        }
        continue;
      }
      if (credit(_durable) == null) return;
      if (round >= _maxRounds) {
        throw const StorageWriteFailed(
          circlePlansKey,
          'the credit waits on a Plan change still being saved',
        );
      }
      await idle();
    }
  }

  /// Delete history: the stage evidence goes at once; each Plan's place
  /// stays. A record set aside as unreadable goes too — it may hold stage
  /// evidence, and nothing reads it back. Completes when it is written —
  /// and, unlike the Plans' other writes, fails if it couldn't be (audit
  /// remediation R3: Delete never reports what didn't happen).
  ///
  /// Audit remediation R8 (Astra R7-A04): the write and the removal must both
  /// be confirmed by the store ([writeConfirmed]).
  ///
  /// R8.2 (Astra R81-A02, Claude NEW-2): from this moment the evidence is
  /// gone from what the Plans fall back to and decide on, too
  /// ([confirmedState]) — even before the write lands, and if it fails:
  /// the intent to delete is on disk, so the next start removes it from
  /// the store whatever happens. No Insight is ever assessed, and no failed
  /// save ever rolled back, onto the deleted evidence.
  Future<void> forgetStageEvidence() {
    final next = state.forgetStageEvidence();
    state = next;
    _deletions++;
    _durable = _durable.forgetStageEvidence();
    _queued = _queuedWrite = null;
    final json = jsonEncode(next.toJson());
    final prefs = _prefs;
    // Removed at once, and confirmed (the intent to delete is already on
    // disk): nothing set aside stays readable while earlier writes finish.
    final setAside = writeConfirmed(
      prefs,
      circlePlansUnreadableKey,
      null,
      restoreOnFailure: false,
    )..ignore();
    final written = _writes
        .then(
          (_) => writeConfirmed(
            prefs,
            circlePlansKey,
            json,
            restoreOnFailure: false,
          ),
        )
        .then((_) => setAside)
        .then((_) => _durable = next);
    _writes = written.then((_) {}, onError: (Object _) {});
    return written;
  }
}

final circlePlansProvider =
    NotifierProvider<CirclePlansNotifier, CirclePlansState>(
      CirclePlansNotifier.new,
    );
