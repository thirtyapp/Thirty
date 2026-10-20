import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/premium/premium_access.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
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
    unawaited(prefs.setString(circlePlansUnreadableKey, raw));
    return CirclePlansState.empty;
  }

  bool get _premium => ref.read(premiumEntitlementProvider);
  String get _today => dateKey(ref.read(nowProvider));

  void _set(CirclePlansState next) {
    state = next;
    final json = jsonEncode(next.toJson());
    final prefs = _prefs;
    _writes = _writes
        .then((_) => prefs.setString(circlePlansKey, json))
        .catchError((Object _) => true);
    unawaited(_writes);
  }

  PlanActionResult _apply(CirclePlansState? next, {required bool running}) {
    if (running && !_premium) return PlanActionResult.needsPremium;
    if (next == null) return PlanActionResult.notAvailable;
    _set(next);
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
    if (!identical(day.state, state)) _set(day.state);
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

  /// Today's stage Circle was started and has now been closed: the stage
  /// is guided and the Plan moves on — once per Circle, and only while
  /// Premium is active.
  void recordGuided(
    PlanStageProvenance stage, {
    required String circleId,
    required List<String> parts,
    required List<String> skipped,
  }) {
    if (!_premium) return;
    final next = state.recordGuided(
      stage,
      circleId: circleId,
      today: _today,
      parts: parts,
      skipped: skipped,
    );
    if (!identical(next, state)) _set(next);
  }

  /// Delete history: the stage evidence goes at once; each Plan's place
  /// stays. A record set aside as unreadable goes too — it may hold stage
  /// evidence, and nothing reads it back. Completes when it is written.
  Future<void> forgetStageEvidence() {
    _set(state.forgetStageEvidence());
    final setAside = _prefs.remove(circlePlansUnreadableKey);
    _writes = _writes.then((_) => setAside).catchError((Object _) => true);
    return _writes;
  }
}

final circlePlansProvider =
    NotifierProvider<CirclePlansNotifier, CirclePlansState>(
      CirclePlansNotifier.new,
    );
