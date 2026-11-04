import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/premium/entitlement_status.dart';
import '../../../core/premium/premium_access.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/storage/confirmed_write.dart';
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

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  CirclePlansState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(circlePlansKey);
    if (raw == null) return CirclePlansState.empty;
    try {
      final state = CirclePlansState.fromJson(jsonDecode(raw));
      if (state != null) return state;
    } catch (_) {
      // Unreadable: kept aside below.
    }
    // Kept aside at once; a save that follows confirms the copy first
    // ([_protectStored]), so the original is never written over unkept.
    if (prefs.get(circlePlansUnreadableKey) == null) {
      writeConfirmed(prefs, circlePlansUnreadableKey, raw).ignore();
    }
    return CirclePlansState.empty;
  }

  bool get _premium => ref.read(premiumEntitlementProvider);
  String get _today => dateKey(ref.read(nowProvider));

  /// Shows [next] and saves it. Audit remediation R8 (Claude F-6): the save
  /// must be confirmed by the store ([writeConfirmed]). One that isn't stays
  /// in memory — a Plan's served-stage evidence included, so Today's credit
  /// rules still hold in this session — is retried by the next save, which
  /// writes the whole record, and, with [report], is shown to the user
  /// ([storeSaveFailuresProvider]); Today reports its own. Never over a
  /// stored record THIRTY can't read until a copy is confirmed aside
  /// ([_protectStored]). The returned future fails when the save does.
  Future<void> _set(CirclePlansState next, {bool report = true}) {
    state = next;
    final json = jsonEncode(next.toJson());
    final prefs = _prefs;
    final write = _writes.then((_) async {
      await _protectStored(prefs);
      await writeConfirmed(prefs, circlePlansKey, json);
    });
    _writes = write.then(
      (_) {
        if (ref.mounted) {
          ref
              .read(storeSaveFailuresProvider.notifier)
              .saved(UserStore.circlePlans);
        }
      },
      onError: (Object _) {
        if (ref.mounted) {
          ref
              .read(storeSaveFailuresProvider.notifier)
              .record(UserStore.circlePlans, notify: report);
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
    final raw = prefs.get(circlePlansKey);
    if (raw == null) return;
    if (raw is String && _readable(raw)) return;
    final text = '$raw';
    final aside = prefs.get(circlePlansUnreadableKey);
    if (aside == text) return;
    if (aside != null) {
      throw const StorageWriteFailed(
        circlePlansKey,
        'an earlier unreadable record is already kept aside',
      );
    }
    await writeConfirmed(prefs, circlePlansUnreadableKey, text);
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

  /// Start [planId] (pausing any other active Plan at its place); a paused
  /// one carries on where it was.
  PlanActionResult start(String planId) =>
      _apply(state.start(planId, today: _today), running: true);

  PlanActionResult pause(String planId) =>
      _apply(state.pause(planId), running: false);

  /// "Carry on".
  PlanActionResult resume(String planId) =>
      _apply(state.resume(planId), running: true);

  PlanActionResult leave(String planId) =>
      _apply(state.leave(planId, today: _today), running: false);

  PlanActionResult goThroughAgain(String planId) =>
      _apply(state.goThroughAgain(planId, today: _today), running: true);

  /// "This stage again next time" / "Try this stage".
  PlanActionResult requestRevisit(String planId, int stageNumber) =>
      _apply(state.requestRevisit(planId, stageNumber), running: true);

  /// ADR-024 I2's application, approved by the user: "Keep this Plan's
  /// Circles gentler for now" for the current cycle. Never stacked.
  PlanActionResult keepGentler(String planId) =>
      _apply(state.keepGentler(planId, today: _today), running: true);

  /// Turns the gentler setting off — giving a setting up is never gated.
  PlanActionResult stopGentler(String planId) =>
      _apply(state.stopGentler(planId), running: false);

  StageAnswers _answers() =>
      stageAnswersFrom(ref.read(circleJournalRepositoryProvider).readAll());

  /// Today's Circle for the active Plan ([planToday]): today's set-asides
  /// and any end are kept. Without Premium, nothing applies and nothing
  /// changes.
  PlanDay steerToday(
    ComposerContext context,
    Iterable<PastCircle> history, {
    SuggestionControls controls = SuggestionControls.none,
    Set<ElementId> leftOut = const {},
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
        ? day.state.served(stage, circleId: _today)
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
  Future<void> noteStart(
    PlanStageProvenance stage, {
    required String circleId,
  }) {
    final next = switch (ref.read(entitlementStatusProvider)) {
      EntitlementStatus.active => state.noteStart(
        stage,
        circleId: circleId,
        active: true,
      ),
      EntitlementStatus.inactive => state.noteStart(
        stage,
        circleId: circleId,
        active: false,
      ),
      EntitlementStatus.initializing || EntitlementStatus.unavailable => state,
    };
    if (identical(next, state)) return Future<void>.value();
    // Today reports a Start whose evidence wasn't saved (audit remediation
    // R8): it never saves the Start without it.
    return _set(next, report: false);
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
  Future<void> recordGuided(
    PlanStageProvenance stage, {
    required String circleId,
    required List<String> parts,
    required List<String> skipped,
    String? on,
  }) {
    if (!_premium && !state.creditsServed(stage, circleId: circleId)) {
      return Future<void>.value();
    }
    final next = state.recordGuided(
      stage,
      circleId: circleId,
      today: on ?? _today,
      parts: parts,
      skipped: skipped,
    );
    if (identical(next, state)) return Future<void>.value();
    return _set(next);
  }

  /// Delete history: the stage evidence goes at once; each Plan's place
  /// stays. A record set aside as unreadable goes too — it may hold stage
  /// evidence, and nothing reads it back. Completes when it is written —
  /// and, unlike the Plans' other writes, fails if it couldn't be (audit
  /// remediation R3: Delete never reports what didn't happen).
  ///
  /// Audit remediation R8 (Astra R7-A04): the write and the removal must both
  /// be confirmed by the store ([writeConfirmed]).
  Future<void> forgetStageEvidence() {
    final next = state.forgetStageEvidence();
    state = next;
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
        .then((_) => setAside);
    _writes = written.then((_) {}, onError: (Object _) {});
    return written;
  }
}

final circlePlansProvider =
    NotifierProvider<CirclePlansNotifier, CirclePlansState>(
      CirclePlansNotifier.new,
    );
