import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/activity_category.dart';
import '../../../core/analytics/analytics_event_type.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/utils/date_key.dart';
import '../../plans/application/plan_provider.dart';
import '../../plans/domain/plan_ids.dart';
import '../../plans/domain/plan_state.dart';
import 'activity_catalog.dart';
import 'circle_journal.dart';

/// THIRTY's daily recommendation — Recommendation MVP v0
/// (`docs/product/recommendation-mvp-v0.md`): the user picks an [Intention]
/// via the Daily Context Question, and THIRTY deterministically picks one
/// [ActivityId] within it (`activity_catalog.dart`). No scoring, no AI, no
/// personalization beyond that one explicit daily choice.
///
/// Purely content — the day's session/lifecycle state (whether it has been
/// started or closed, and when) lives on [RecommendationState], not here.
class Recommendation {
  const Recommendation({
    required this.intent,
    required this.activity,
    required this.duration,
    required this.why,
    required this.category,
    required this.activityId,
    required this.intention,
    required this.circleId,
    required this.catalogVersion,
    this.planId,
    this.stageId,
    this.planCycleId,
    this.planVersion,
    this.isPlanRevisit = false,
    this.treatmentUsed,
    this.treatmentSource,
  });

  final String intent;
  final String activity;
  final String duration;
  final String why;

  /// Drives which visual identity (see `presentation/illustrations/`)
  /// represents this recommendation — nothing about ranking or selection,
  /// purely a label for that lookup. Shared with the World Engine
  /// (`core/worlds/`) as the single source of truth for this
  /// classification — see [ActivityCategory].
  final ActivityCategory category;

  /// The canonical activity identity this recommendation was built from —
  /// not displayed anywhere, used only for persistence and next-day
  /// anti-repetition (`activity_catalog.dart`'s [selectActivityId]).
  final ActivityId activityId;

  /// The raw [Intention] this recommendation was resolved for — kept
  /// alongside [intent] (its display label) so the Circle journal
  /// (`circle_journal.dart`) and the cross-direction diversity guard's
  /// persistence can use the stable enum identity rather than re-parsing
  /// display copy (ADR-013).
  final Intention intention;

  /// This Circle's stable identity — currently always equal to the local
  /// calendar date it belongs to (`date_key.dart`'s [dateKey] format),
  /// since Free is bounded to one Circle per local day (ADR-013 §3/§5).
  final String circleId;

  /// The `activity_catalog.dart` [catalogVersion] active when this
  /// recommendation was resolved (ADR-013 §3 — "relevant content/version
  /// identity").
  final int catalogVersion;

  /// This Circle's Plan identity, if it was Plan-resolved
  /// (`../../plans/application/plan_provider.dart`'s
  /// `PlanNotifier.resolveSessionFor`) rather than the complete Free
  /// selector (`activity_catalog.dart`'s [selectActivityId]) — `null` for
  /// every Free-selector-resolved Circle. All five Plan-related fields
  /// below are only ever meaningful together with a non-null [planId].
  final PlanId? planId;

  /// The assigned [StageId] — `null` iff [planId] is `null`.
  final StageId? stageId;

  /// The Plan cycle this Circle belonged to
  /// (`../../plans/domain/plan_state.dart`'s `PlanProgress.cycleId`) —
  /// `null` iff [planId] is `null`.
  final String? planCycleId;

  /// The `../../plans/domain/plan_catalog.dart` `planContentVersion`
  /// active when this Circle was resolved — `null` iff [planId] is `null`.
  final int? planVersion;

  /// Whether this Circle was assigned via a queued one-off revisit
  /// (frozen architecture §9) rather than ordinary forward progression —
  /// always `false` when [planId] is `null`.
  final bool isPlanRevisit;

  /// Which of the stage's two authored guidance texts is currently
  /// selected for display (`../../plans/domain/plan_state.dart`'s
  /// `PlanTreatment`) — `null` iff [planId] is `null`. Mutable after
  /// resolution via [RecommendationNotifier.setPlanTreatment]; changing it
  /// never substitutes a different [activityId] (frozen architecture §10).
  final PlanTreatment? treatmentUsed;

  /// Truthfully records *why* [treatmentUsed] is what it is — Batch 2B
  /// (ADR-015 §10) — `null` iff [planId] is `null`. Set to
  /// [PlanTreatmentSource.directChoice] whenever
  /// [RecommendationNotifier.setPlanTreatment] is called; set from
  /// `../../plans/application/plan_provider.dart`'s
  /// `PlanSessionAssignment.treatmentSource` at resolution time otherwise —
  /// never counted as a fresh user choice merely because the resulting
  /// [treatmentUsed] happens to be [PlanTreatment.lighter].
  final PlanTreatmentSource? treatmentSource;
}

/// Today's Circle's lifecycle status. Deliberately only the three states
/// this pass's technical foundation needs — "Active"/"Filling" is product
/// lifecycle terminology (Playbook Ch.2 §3) for the UX that will later sit
/// on top of [started]; no additional technical states (paused, resumed,
/// abandoned, skipped...) are introduced ahead of that UX existing.
enum RecommendationStatus { notStarted, started, closed }

/// SharedPreferences key for the local calendar date (`YYYY-MM-DD`) the
/// persisted status/timestamps below belong to. A day-key mismatch (or no
/// day-key at all) means there is no valid state for *today* — see
/// [RecommendationNotifier.build].
const recommendationDayKey = 'recommendation_day';

/// SharedPreferences key for today's chosen [Intention.name] — absent until
/// [RecommendationNotifier.chooseIntention] has been called for today.
const recommendationIntentionKey = 'recommendation_intention';

/// SharedPreferences key for today's selected [ActivityId.name] — absent
/// until [RecommendationNotifier.chooseIntention] has been called for
/// today.
const recommendationActivityIdKey = 'recommendation_activity_id';

/// SharedPreferences key prefix for [intention]'s bounded recent-activity
/// history (Batch 2 — see
/// [ADR-012](../../../../docs/product/adr/ADR-012-batch-2-recommendation-diversity.md)),
/// stored as a `StringList` of [ActivityId.name] values, oldest first.
///
/// One list per [Intention] (never a single shared list) — the anti-
/// repetition guard only ever needs to compare against activities drawn
/// from the *same* pool, and keeping the lists separate means switching
/// intentions from one day to the next never spends down another
/// intention's history budget. Bounded to `pool.length - 1` entries by
/// [RecommendationNotifier.chooseIntention] itself (see
/// [selectActivityId]'s own doc comment for why that specific cap) —
/// nothing enforces the cap at read time, so a corrupt/oversized stored
/// list is simply truncated the next time it's written, never rejected.
///
/// Survives normal app restart (it's SharedPreferences, like every other
/// key here); a device-level clear-storage legitimately wipes it, which
/// simply resets that intention's diversity guard to "no history," the
/// same safe starting state a first-ever use has.
String recommendationHistoryKeyFor(Intention intention) =>
    'recommendation_history_${intention.name}';

/// SharedPreferences key for [RecommendationStatus.name] — `'started'` or
/// `'closed'` only; a `notStarted` day is represented by the day-key not
/// matching today, never by an explicitly persisted `'notStarted'` value.
const recommendationStatusKey = 'recommendation_status';

/// SharedPreferences key for [RecommendationState.startedAt], persisted as
/// [DateTime.toIso8601String].
const recommendationStartedAtKey = 'recommendation_started_at';

/// SharedPreferences key for [RecommendationState.closedAt], persisted as
/// [DateTime.toIso8601String].
const recommendationClosedAtKey = 'recommendation_closed_at';

/// SharedPreferences key for [RecommendationState.attemptResponse]'s
/// [CircleAttemptResponse.name] (ADR-013 §4) — absent whenever no answer
/// has been given yet, cleared alongside every other per-day key by
/// [RecommendationNotifier._persistChoice] on a fresh day.
const recommendationAttemptResponseKey = 'recommendation_attempt_response';

/// SharedPreferences key for [RecommendationState.usefulnessResponse]'s
/// [CircleUsefulnessResponse.name] (ADR-013 §4). See
/// [recommendationAttemptResponseKey].
const recommendationUsefulnessResponseKey =
    'recommendation_usefulness_response';

/// SharedPreferences key for the [ActivitySemanticFamily.name] of the most
/// recently *shown* Circle, regardless of which [Intention] it belonged to
/// (ADR-013 §2 — cross-direction family avoidance). Deliberately a single,
/// intention-independent key — unlike [recommendationHistoryKeyFor], this
/// guard compares against whatever the immediately prior Circle was, no
/// matter which direction it came from.
const recommendationLastFamilyKey = 'recommendation_last_family';

/// SharedPreferences key for today's [Recommendation.planId]'s
/// [PlanId.name] (Batch 2A) — absent for a Free-selector-resolved Circle.
/// All five `recommendationPlan*`/`recommendationStageId*`/
/// `recommendationTreatment*` keys below are only ever meaningful together;
/// see [_restoreRecommendation].
const recommendationPlanIdKey = 'recommendation_plan_id';

/// SharedPreferences key for today's [Recommendation.stageId]. See
/// [recommendationPlanIdKey].
const recommendationStageIdKey = 'recommendation_stage_id';

/// SharedPreferences key for today's [Recommendation.planCycleId]. See
/// [recommendationPlanIdKey].
const recommendationPlanCycleIdKey = 'recommendation_plan_cycle_id';

/// SharedPreferences key for today's [Recommendation.planVersion]. See
/// [recommendationPlanIdKey].
const recommendationPlanVersionKey = 'recommendation_plan_version';

/// SharedPreferences key for today's [Recommendation.isPlanRevisit]. See
/// [recommendationPlanIdKey].
const recommendationIsPlanRevisitKey = 'recommendation_is_plan_revisit';

/// SharedPreferences key for today's [Recommendation.treatmentUsed]'s
/// [PlanTreatment.name] — the one Plan-related field
/// [RecommendationNotifier.setPlanTreatment] can change after resolution.
const recommendationTreatmentKey = 'recommendation_treatment';

/// SharedPreferences key for today's [Recommendation.treatmentSource]'s
/// [PlanTreatmentSource.name] (Batch 2B) — mirrors [recommendationTreatmentKey]
/// one-for-one: both are set together at resolution, and both are updated
/// together by [RecommendationNotifier.setPlanTreatment].
const recommendationTreatmentSourceKey = 'recommendation_treatment_source';

/// Today's Circle: its content ([recommendation]) plus its session/
/// lifecycle state.
///
/// [recommendation] is `null` until the Daily Context Question has been
/// answered for today (see [RecommendationNotifier.chooseIntention]) — the
/// UI is responsible for showing that question instead of the Circle while
/// it is null (`home_page.dart`).
///
/// **Invariant:** whenever [recommendation] is `null`, [status] is always
/// [RecommendationStatus.notStarted] and both [startedAt]/[closedAt] are
/// `null` — a Circle can never be started or closed before today's
/// recommendation exists. Enforced by this constructor's assertion, and by
/// [RecommendationNotifier.start]/[RecommendationNotifier.close] refusing to
/// act while [recommendation] is `null`.
class RecommendationState {
  RecommendationState({
    required this.recommendation,
    required this.status,
    this.startedAt,
    this.closedAt,
    this.attemptResponse,
    this.usefulnessResponse,
  }) : assert(
         recommendation != null ||
             (status == RecommendationStatus.notStarted &&
                 startedAt == null &&
                 closedAt == null),
         'A Circle must never be started or closed before today\'s '
         'recommendation exists.',
       ),
       assert(
         attemptResponse == null || status == RecommendationStatus.closed,
         'An attempt response can only exist once today\'s Circle is '
         'closed.',
       ),
       assert(
         usefulnessResponse == null ||
             attemptResponse == CircleAttemptResponse.yes ||
             attemptResponse == CircleAttemptResponse.aLittle,
         'A usefulness response can only follow an affirmative attempt '
         'response.',
       );

  final Recommendation? recommendation;
  final RecommendationStatus status;

  /// When today's Circle was started. Null iff [status] is [notStarted].
  final DateTime? startedAt;

  /// When today's Circle was closed. Null iff [status] is not [closed].
  final DateTime? closedAt;

  /// The user's optional "Did you try this activity?" answer (ADR-013
  /// §4) — `null` means no answer was given, never a negative. Only ever
  /// non-null while [status] is [RecommendationStatus.closed].
  final CircleAttemptResponse? attemptResponse;

  /// The user's optional self-reported usefulness rating (ADR-013 §4) —
  /// only ever non-null alongside an affirmative [attemptResponse]
  /// ([CircleAttemptResponse.yes] or [CircleAttemptResponse.aLittle]).
  final CircleUsefulnessResponse? usefulnessResponse;
}

/// The smallest technical state machine behind today's Circle:
///
/// ```
/// (no recommendation) --chooseIntention()--> notStarted --start()--> started --close()--> closed
/// ```
///
/// All three transitions are hard no-ops outside their one valid source
/// state (§ "Transition Contract") — calling [chooseIntention] again once
/// today's recommendation already exists, [start] twice, or [close] before
/// [start], simply does nothing rather than throwing or silently
/// overwriting already-recorded state. Neither [start] nor [close] is
/// triggered by [Recommendation.duration]; nothing in this class reads
/// clock time to decide when to move between states — only explicit calls
/// do.
///
/// [start]/[close] read [eventClockProvider], not [nowProvider], for
/// [RecommendationState.startedAt]/[RecommendationState.closedAt] — an
/// event timestamp must reflect the real moment of that call, which
/// [nowProvider]'s one-time-per-container-lifetime cached value cannot
/// guarantee (its own doc comment covers why). [build]'s calendar-day
/// check, and [chooseIntention]'s deterministic-selection day index, are
/// the places [nowProvider] remains the right tool: a coarse "which day is
/// it" read doesn't need per-call freshness.
///
/// State is scoped to one local calendar day, the same way
/// [`FirstBreathNotifier`](first_breath_provider.dart) scopes its own one
/// piece of state — [build] restores persisted intention/activity/status/
/// timestamps only when the persisted day-key matches today; anything from
/// an earlier day is treated as absent, and today then starts fresh with no
/// recommendation. There is deliberately no repository/service layer around
/// this, matching [`FirstBreathNotifier`] and
/// [`ThemeModeNotifier`](../../../core/providers/theme_mode_provider.dart).
///
/// **Known limitation:** the day boundary is only re-evaluated when
/// [nowProvider] is invalidated and re-read — Batch 1 (Phase D) closes the
/// main real-world gap by invalidating it on every app foreground resume
/// (`core/app/thirty_app.dart`'s `_ThirtyAppState`), so an app backgrounded
/// overnight and reopened the next day correctly lands on a fresh Circle.
/// An app instance kept open, uninterrupted, in the foreground across local
/// midnight without ever backgrounding still will not notice until some
/// other rebuild happens — no midnight timer is introduced to close that
/// narrower remaining gap.
class RecommendationNotifier extends Notifier<RecommendationState> {
  @override
  RecommendationState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final today = dateKey(ref.watch(nowProvider));

    final freshNoRecommendation = RecommendationState(
      recommendation: null,
      status: RecommendationStatus.notStarted,
    );

    // No stored day, or a day that isn't today: nothing valid to restore
    // for *today* — yesterday's (or no) state is silently treated as
    // absent, not carried forward. It is left in SharedPreferences as-is;
    // only chooseIntention()'s own per-intention history key
    // (recommendationHistoryKeyFor) is read for anti-repetition, never this
    // stale "today" record.
    if (prefs.getString(recommendationDayKey) != today) {
      return freshNoRecommendation;
    }

    final recommendation = _restoreRecommendation(prefs, today);
    // Same day, but no valid, direction-compatible (intention, activityId)
    // pair persisted yet — the Daily Context Question hasn't been answered
    // today. This also fails safe the same way if the persisted pair is
    // somehow corrupt or no longer belongs to that intention's pool (ADR-013
    // §2 — "invalid stored activity/intention combinations recover safely").
    if (recommendation == null) {
      return freshNoRecommendation;
    }

    final fresh = RecommendationState(
      recommendation: recommendation,
      status: RecommendationStatus.notStarted,
    );

    final storedStatus = RecommendationStatus.values
        .asNameMap()[prefs.getString(recommendationStatusKey)];
    final storedStartedAt = DateTime.tryParse(
      prefs.getString(recommendationStartedAtKey) ?? '',
    );

    switch (storedStatus) {
      case RecommendationStatus.started:
        // A "started" record with no valid startedAt is conceptually
        // invalid — fail safe rather than restore a half-formed state.
        if (storedStartedAt == null) return fresh;
        return RecommendationState(
          recommendation: recommendation,
          status: RecommendationStatus.started,
          startedAt: storedStartedAt,
        );

      case RecommendationStatus.closed:
        final storedClosedAt = DateTime.tryParse(
          prefs.getString(recommendationClosedAtKey) ?? '',
        );
        // Same reasoning as above: a "closed" record needs both a valid
        // startedAt and closedAt to be conceptually valid — and a closedAt
        // that precedes its own startedAt is just as invalid as either
        // being missing, so it fails safe the same way.
        if (storedStartedAt == null || storedClosedAt == null) return fresh;
        if (storedClosedAt.isBefore(storedStartedAt)) return fresh;

        // Attempt/usefulness responses (ADR-013 §4) are restored only
        // alongside a conceptually valid closed state — the constructor's
        // own assertions require this ordering regardless, so an invalid
        // stored pairing (e.g. a usefulness answer without an affirmative
        // attempt) is simply dropped rather than restored.
        final storedAttempt = CircleAttemptResponse.values
            .asNameMap()[prefs.getString(recommendationAttemptResponseKey)];
        final storedUsefulnessRaw = CircleUsefulnessResponse.values
            .asNameMap()[prefs.getString(
              recommendationUsefulnessResponseKey,
            )];
        final attemptIsAffirmative =
            storedAttempt == CircleAttemptResponse.yes ||
            storedAttempt == CircleAttemptResponse.aLittle;
        final storedUsefulness = attemptIsAffirmative
            ? storedUsefulnessRaw
            : null;

        return RecommendationState(
          recommendation: recommendation,
          status: RecommendationStatus.closed,
          startedAt: storedStartedAt,
          closedAt: storedClosedAt,
          attemptResponse: storedAttempt,
          usefulnessResponse: storedUsefulness,
        );

      case RecommendationStatus.notStarted:
      case null:
        // Either an explicit (never actually written) "notStarted", or an
        // unrecognized/corrupt status string — both fail safe the same
        // way as a missing day-key.
        return fresh;
    }
  }

  /// Answers the Daily Context Question for today: resolves and persists
  /// today's [Recommendation] for [intention], then transitions today's
  /// Circle to [RecommendationStatus.notStarted] with it.
  ///
  /// A no-op once today's recommendation already exists — "once selected,
  /// the day's intention becomes fixed" (`docs/product/recommendation-mvp-v0.md`):
  /// this can only meaningfully run once per local calendar day.
  ///
  /// The activity is chosen deterministically
  /// (`activity_catalog.dart`'s [selectActivityId]) from [intention]'s pool,
  /// keyed on today's calendar day, and avoids repeating any activity still
  /// in [intention]'s bounded recent-history list
  /// ([recommendationHistoryKeyFor]) — Batch 2's diversity guard (see
  /// [ADR-012](../../../../docs/product/adr/ADR-012-batch-2-recommendation-diversity.md)),
  /// which replaces v0's narrower "only the immediately preceding local
  /// calendar day" rule. Unlike that superseded rule, this history is keyed
  /// on *how many times [intention] was actually chosen*, not on calendar
  /// adjacency — a multi-day gap between uses no longer defeats the guard.
  /// Capped at `pool.length - 1` entries so at least one alternative always
  /// remains (see [selectActivityId]'s own doc comment for the exhaustion
  /// fallback this cap exists to make unreachable in practice).
  ///
  /// Also records a [AnalyticsEventType.recommendationShown] event (Batch 2,
  /// Phase F) — but only on this real, once-per-day resolution, never on
  /// the no-op early return above, matching [start]/[close]'s own
  /// "only a genuine transition is measured" discipline.
  ///
  /// **Circle Plans (Batch 2A):** before falling through to the Free
  /// selector above, this first asks
  /// `../../plans/application/plan_provider.dart`'s
  /// `PlanNotifier.resolveSessionFor` whether [intention] matches an
  /// active, in-progress Plan — the frozen architecture's "daily
  /// resolution rule." A non-null result substitutes that Plan's assigned
  /// [ActivityId] (and carries the Plan/stage/cycle identity into
  /// [Recommendation]) in place of [selectActivityId]; a `null` result
  /// (no entitlement, no active Plan, a direction mismatch, or a completed
  /// cycle with no repeat chosen) is the exact, unmodified Free path. A
  /// Plan never overrides the user's chosen [intention] — it only ever
  /// supplies which activity fulfils it.
  void chooseIntention(Intention intention) {
    if (state.recommendation != null) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final now = ref.read(nowProvider);
    final today = dateKey(now);

    final planAssignment = ref
        .read(planProvider.notifier)
        .resolveSessionFor(intention);

    final ActivityId activityId;
    String? historyKey;
    List<String>? cappedHistory;

    if (planAssignment != null) {
      activityId = planAssignment.activityId;
    } else {
      final pool = activityPools[intention]!;
      historyKey = recommendationHistoryKeyFor(intention);
      final storedHistory = prefs.getStringList(historyKey) ?? const [];
      final recentActivityIds = storedHistory
          .map((name) => ActivityId.values.asNameMap()[name])
          .whereType<ActivityId>()
          .toSet();
      final lastShownFamily = ActivitySemanticFamily.values
          .asNameMap()[prefs.getString(recommendationLastFamilyKey)];

      activityId = selectActivityId(
        intention: intention,
        dayIndex: epochDay(now),
        recentActivityIds: recentActivityIds,
        lastShownFamily: lastShownFamily,
      );

      // Bounded to pool.length - 1 most-recent entries — see
      // recommendationHistoryKeyFor's own doc comment for why that
      // specific cap. Only maintained for a Free-selector resolution — a
      // Plan-resolved day's activity comes from the Plan's own state, not
      // this diversity guard.
      final updatedHistory = [...storedHistory, activityId.name];
      final historyCap = pool.length - 1;
      cappedHistory = updatedHistory.length > historyCap
          ? updatedHistory.sublist(updatedHistory.length - historyCap)
          : updatedHistory;
    }

    final recommendation = _buildRecommendation(
      intention,
      activityId,
      today,
      planAssignment: planAssignment,
    );

    state = RecommendationState(
      recommendation: recommendation,
      status: RecommendationStatus.notStarted,
    );
    unawaited(
      _persistChoice(
        today: today,
        intention: intention,
        activityId: activityId,
        historyKey: historyKey,
        cappedHistory: cappedHistory,
        shownAt: now,
        planAssignment: planAssignment,
      ),
    );
    ref
        .read(analyticsServiceProvider)
        .track(
          AnalyticsEventType.recommendationShown,
          metadata: {
            'intention': intention.name,
            'activity_id': activityId.name,
          },
        );
  }

  /// Starts today's Circle. A no-op unless today's recommendation already
  /// exists and [RecommendationState.status] is currently
  /// [RecommendationStatus.notStarted] — calling this before
  /// [chooseIntention], or again while already started or closed, does
  /// nothing, and in particular never overwrites an already-recorded
  /// [RecommendationState.startedAt].
  void start() {
    if (state.recommendation == null) return;
    if (state.status != RecommendationStatus.notStarted) return;

    final startedAt = ref.read(eventClockProvider)();
    state = RecommendationState(
      recommendation: state.recommendation,
      status: RecommendationStatus.started,
      startedAt: startedAt,
    );
    unawaited(_persist(state));
    // Fired only on a real transition — the two guard clauses above already
    // make this method a no-op on a repeat call, so a double/duplicate
    // start() can never record a duplicate circleStarted event either
    // (Batch 1, Phase E instrumentation).
    ref.read(analyticsServiceProvider).track(AnalyticsEventType.circleStarted);
  }

  /// Closes today's Circle. A no-op unless [RecommendationState.status] is
  /// currently [RecommendationStatus.started] — calling this before a
  /// start, or again after already closed, does nothing, and in
  /// particular never overwrites an already-recorded
  /// [RecommendationState.closedAt]. [RecommendationState.startedAt] is
  /// carried over unchanged.
  ///
  /// Closes today's Circle. A no-op unless [RecommendationState.status] is
  /// currently [RecommendationStatus.started] — calling this before a
  /// start, or again after already closed, does nothing, and in
  /// particular never overwrites an already-recorded
  /// [RecommendationState.closedAt]. [RecommendationState.startedAt] is
  /// carried over unchanged.
  ///
  /// **Critical semantics (ADR-013 §3):** closing today's Circle does
  /// **not** mean the recommended activity was actually done, does not
  /// mean thirty minutes elapsed, and does not prove any wellbeing
  /// benefit — it is a factual app interaction only (ADR-010). The
  /// optional [reportAttempt]/[reportUsefulness] foundation this unlocks is
  /// the only place a user's own account of what happened is recorded, and
  /// even that is always self-reported, never verified.
  void close() {
    if (state.recommendation == null) return;
    if (state.status != RecommendationStatus.started) return;

    final recommendation = state.recommendation!;
    final closedAt = ref.read(eventClockProvider)();
    state = RecommendationState(
      recommendation: recommendation,
      status: RecommendationStatus.closed,
      startedAt: state.startedAt,
      closedAt: closedAt,
    );
    unawaited(_persist(state));
    // Fired only on a real transition, for the same reason start() above
    // only fires once per Circle — this is also the frozen post-fix
    // measurement protocol's "Daily Check-In completed" (see
    // AnalyticsEventType.circleClosed's own doc comment).
    ref.read(analyticsServiceProvider).track(AnalyticsEventType.circleClosed);

    // Circle Plans (Batch 2A): a real Close of a Plan-resolved Circle
    // advances that Plan's forward guidance cursor exactly once (frozen
    // architecture §8) — never on the no-op guard clauses above, so a
    // duplicate close() can never advance it twice. A revisit-sourced
    // Circle never advances the cursor (see
    // `PlanNotifier.advanceCursorForCircle`'s own doc comment).
    final planId = recommendation.planId;
    if (planId != null) {
      ref
          .read(planProvider.notifier)
          .advanceCursorForCircle(
            planId,
            recommendation.circleId,
            isRevisit: recommendation.isPlanRevisit,
          );
    }
  }

  /// Switches which of a Plan Session's two authored guidance texts is
  /// currently shown for today's Circle (frozen architecture §10). A
  /// no-op unless today's recommendation exists and is Plan-resolved
  /// (`Recommendation.planId != null`) — Free-selector Circles have no
  /// treatment to switch. Never changes [Recommendation.activityId] or any
  /// other identity field — only [Recommendation.treatmentUsed], and the
  /// journal's own `treatmentUsed` record for today's Circle.
  ///
  /// Always records [Recommendation.treatmentSource] as
  /// [PlanTreatmentSource.directChoice] (Batch 2B, ADR-015 §10) — this
  /// method is only ever called for an explicit current-Session choice,
  /// never for the automatic application of a saved Plan-level default
  /// (that happens once, at resolution, inside
  /// `../../plans/application/plan_provider.dart`'s `resolveSessionFor`).
  void setPlanTreatment(PlanTreatment treatment) {
    final recommendation = state.recommendation;
    if (recommendation == null || recommendation.planId == null) return;
    if (recommendation.treatmentUsed == treatment) return;

    final updated = Recommendation(
      intent: recommendation.intent,
      activity: recommendation.activity,
      duration: recommendation.duration,
      why: recommendation.why,
      category: recommendation.category,
      activityId: recommendation.activityId,
      intention: recommendation.intention,
      circleId: recommendation.circleId,
      catalogVersion: recommendation.catalogVersion,
      planId: recommendation.planId,
      stageId: recommendation.stageId,
      planCycleId: recommendation.planCycleId,
      planVersion: recommendation.planVersion,
      isPlanRevisit: recommendation.isPlanRevisit,
      treatmentUsed: treatment,
      treatmentSource: PlanTreatmentSource.directChoice,
    );
    state = RecommendationState(
      recommendation: updated,
      status: state.status,
      startedAt: state.startedAt,
      closedAt: state.closedAt,
      attemptResponse: state.attemptResponse,
      usefulnessResponse: state.usefulnessResponse,
    );
    unawaited(_persist(state));
  }

  /// Records the user's optional "Did you try this activity?" answer
  /// (ADR-013 §4) for today's Circle. A no-op unless today's Circle is
  /// currently [RecommendationStatus.closed] — this can never be answered
  /// before Close, and is never required to Close or to receive tomorrow's
  /// Circle.
  ///
  /// Overwrites any earlier answer for today — changing your mind is
  /// allowed. Answering anything other than [CircleAttemptResponse.yes] or
  /// [CircleAttemptResponse.aLittle] clears any previously recorded
  /// [RecommendationState.usefulnessResponse] for today, since usefulness
  /// may only ever follow an affirmative attempt.
  ///
  /// Fires [AnalyticsEventType.circleAttemptReported] with the response as
  /// allowlisted metadata — never free text, never a health claim.
  void reportAttempt(CircleAttemptResponse response) {
    final recommendation = state.recommendation;
    if (recommendation == null) return;
    if (state.status != RecommendationStatus.closed) return;

    final isAffirmative =
        response == CircleAttemptResponse.yes ||
        response == CircleAttemptResponse.aLittle;
    state = RecommendationState(
      recommendation: recommendation,
      status: state.status,
      startedAt: state.startedAt,
      closedAt: state.closedAt,
      attemptResponse: response,
      usefulnessResponse: isAffirmative ? state.usefulnessResponse : null,
    );
    unawaited(_persist(state));
    ref
        .read(analyticsServiceProvider)
        .track(
          AnalyticsEventType.circleAttemptReported,
          metadata: {'response': response.wireName},
        );
  }

  /// Records the user's optional self-reported usefulness rating (ADR-013
  /// §4). A no-op unless today's Circle is closed **and**
  /// [RecommendationState.attemptResponse] is already affirmative
  /// ([CircleAttemptResponse.yes] or [CircleAttemptResponse.aLittle]) — this
  /// question is only ever offered as a follow-up to an affirmative
  /// attempt, never standalone. See [reportAttempt] for the shared
  /// "never required, always self-reported" semantics.
  void reportUsefulness(CircleUsefulnessResponse response) {
    final recommendation = state.recommendation;
    if (recommendation == null) return;
    if (state.status != RecommendationStatus.closed) return;
    final attempt = state.attemptResponse;
    final isAffirmative =
        attempt == CircleAttemptResponse.yes ||
        attempt == CircleAttemptResponse.aLittle;
    if (!isAffirmative) return;

    state = RecommendationState(
      recommendation: recommendation,
      status: state.status,
      startedAt: state.startedAt,
      closedAt: state.closedAt,
      attemptResponse: attempt,
      usefulnessResponse: response,
    );
    unawaited(_persist(state));
    ref
        .read(analyticsServiceProvider)
        .track(
          AnalyticsEventType.circleUsefulnessReported,
          metadata: {'response': response.wireName},
        );
  }

  /// Builds today's [Recommendation] from the approved catalog
  /// (`activity_catalog.dart`) for ([intention], [activityId]), resolved on
  /// local date [today]. [planAssignment] (Batch 2A), when non-null, folds
  /// that Plan Session's identity in and defaults
  /// [Recommendation.treatmentUsed]/[Recommendation.treatmentSource] to
  /// [PlanSessionAssignment.initialTreatment]/
  /// [PlanSessionAssignment.treatmentSource] (Batch 2B, ADR-015 §7) — a
  /// freshly-resolved Session already respects a saved Plan-level lighter
  /// default, never a hardcoded standard.
  Recommendation _buildRecommendation(
    Intention intention,
    ActivityId activityId,
    String today, {
    PlanSessionAssignment? planAssignment,
    PlanTreatment? treatmentOverride,
    PlanTreatmentSource? treatmentSourceOverride,
  }) {
    return Recommendation(
      intent: intentionLabel(intention),
      activity: activityLabel(activityId),
      duration: '30 minutes',
      why: whyCopyFor(intention, activityId),
      category: activityCategory(activityId),
      activityId: activityId,
      intention: intention,
      circleId: today,
      catalogVersion: catalogVersion,
      planId: planAssignment?.planId,
      stageId: planAssignment?.stageId,
      planCycleId: planAssignment?.planCycleId,
      planVersion: planAssignment?.planVersion,
      isPlanRevisit: planAssignment?.isRevisit ?? false,
      treatmentUsed: planAssignment == null
          ? null
          : (treatmentOverride ?? planAssignment.initialTreatment),
      treatmentSource: planAssignment == null
          ? null
          : (treatmentSourceOverride ?? planAssignment.treatmentSource),
    );
  }

  /// Restores today's [Recommendation] from [prefs], or `null` if no valid,
  /// direction-compatible (intention, activityId) pair is persisted — the
  /// caller has already confirmed the persisted day matches [today].
  ///
  /// **Compatibility check (ADR-013 §2):** a persisted [activityId] that no
  /// longer belongs to the persisted [Intention]'s pool — e.g. after a
  /// hypothetical future catalogue revision moved it elsewhere — is treated
  /// exactly like a missing/corrupt value, not silently trusted, since
  /// activity identity and direction compatibility must always be
  /// validated together.
  ///
  /// **Plan fields (Batch 2A):** restored only if every one of
  /// [recommendationPlanIdKey]/[recommendationStageIdKey]/
  /// [recommendationPlanCycleIdKey]/[recommendationPlanVersionKey] parses
  /// validly together — a partially corrupt subset never invalidates the
  /// whole day's activity (§20's "never silently replace today's resolved
  /// activity"): the base [Recommendation] is still restored, simply
  /// without its Plan context. [recommendationTreatmentKey] defaults to
  /// [PlanTreatment.standard] when the Circle is Plan-resolved but no
  /// treatment was ever explicitly persisted.
  Recommendation? _restoreRecommendation(SharedPreferences prefs, String today) {
    final intention = Intention.values
        .asNameMap()[prefs.getString(recommendationIntentionKey)];
    final activityId = ActivityId.values
        .asNameMap()[prefs.getString(recommendationActivityIdKey)];
    if (intention == null || activityId == null) return null;
    if (!activityPools[intention]!.contains(activityId)) return null;

    final planId = PlanId.values.asNameMap()[prefs.getString(recommendationPlanIdKey)];
    final stageId = prefs.getString(recommendationStageIdKey);
    final planCycleId = prefs.getString(recommendationPlanCycleIdKey);
    final planVersion = prefs.getInt(recommendationPlanVersionKey);
    final isValidPlanRecord =
        planId != null &&
        stageId != null &&
        planCycleId != null &&
        planVersion != null;

    if (!isValidPlanRecord) {
      return _buildRecommendation(intention, activityId, today);
    }

    final isRevisit = prefs.getBool(recommendationIsPlanRevisitKey) ?? false;
    final treatment = PlanTreatment.values
            .asNameMap()[prefs.getString(recommendationTreatmentKey)] ??
        PlanTreatment.standard;
    // Batch 2B: absent on any record persisted before this batch shipped —
    // falls back to ordinaryDefault, the same honest "no explicit choice
    // recorded" meaning that state already carries.
    final treatmentSource = PlanTreatmentSource.values
            .asNameMap()[prefs.getString(recommendationTreatmentSourceKey)] ??
        PlanTreatmentSource.ordinaryDefault;

    return _buildRecommendation(
      intention,
      activityId,
      today,
      planAssignment: PlanSessionAssignment(
        planId: planId,
        stageId: stageId,
        activityId: activityId,
        planCycleId: planCycleId,
        planVersion: planVersion,
        isRevisit: isRevisit,
        initialTreatment: treatment,
        treatmentSource: treatmentSource,
      ),
      treatmentOverride: treatment,
      treatmentSourceOverride: treatmentSource,
    );
  }

  /// Persists [intention]/[activityId] as today's freshly-chosen
  /// recommendation, alongside [RecommendationStatus.notStarted], and
  /// [cappedHistory] under [historyKey] (Batch 2's diversity guard — see
  /// [recommendationHistoryKeyFor]) — both `null` when [planAssignment] is
  /// non-null, since a Plan-resolved day never touches that guard. Any
  /// started/closed/attempt/usefulness values from an earlier day are
  /// explicitly cleared — a fresh choice must never inherit a stale
  /// session. Also records this Circle's "shown" journal entry
  /// (`circle_journal.dart`), this activity's [ActivitySemanticFamily] as
  /// the new cross-direction diversity-guard baseline
  /// ([recommendationLastFamilyKey]), and — only when [planAssignment] is
  /// non-null — today's Plan identity (Batch 2A).
  Future<void> _persistChoice({
    required String today,
    required Intention intention,
    required ActivityId activityId,
    required String? historyKey,
    required List<String>? cappedHistory,
    required DateTime shownAt,
    PlanSessionAssignment? planAssignment,
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(recommendationDayKey, today);
    await prefs.setString(recommendationIntentionKey, intention.name);
    await prefs.setString(recommendationActivityIdKey, activityId.name);
    await prefs.setString(
      recommendationStatusKey,
      RecommendationStatus.notStarted.name,
    );
    await prefs.remove(recommendationStartedAtKey);
    await prefs.remove(recommendationClosedAtKey);
    await prefs.remove(recommendationAttemptResponseKey);
    await prefs.remove(recommendationUsefulnessResponseKey);
    if (historyKey != null && cappedHistory != null) {
      await prefs.setStringList(historyKey, cappedHistory);
    }
    await prefs.setString(
      recommendationLastFamilyKey,
      activityFamily(activityId).name,
    );

    if (planAssignment != null) {
      await prefs.setString(recommendationPlanIdKey, planAssignment.planId.name);
      await prefs.setString(recommendationStageIdKey, planAssignment.stageId);
      await prefs.setString(
        recommendationPlanCycleIdKey,
        planAssignment.planCycleId,
      );
      await prefs.setInt(
        recommendationPlanVersionKey,
        planAssignment.planVersion,
      );
      await prefs.setBool(
        recommendationIsPlanRevisitKey,
        planAssignment.isRevisit,
      );
      await prefs.setString(
        recommendationTreatmentKey,
        planAssignment.initialTreatment.name,
      );
      await prefs.setString(
        recommendationTreatmentSourceKey,
        planAssignment.treatmentSource.name,
      );
    } else {
      await prefs.remove(recommendationPlanIdKey);
      await prefs.remove(recommendationStageIdKey);
      await prefs.remove(recommendationPlanCycleIdKey);
      await prefs.remove(recommendationPlanVersionKey);
      await prefs.remove(recommendationIsPlanRevisitKey);
      await prefs.remove(recommendationTreatmentKey);
      await prefs.remove(recommendationTreatmentSourceKey);
    }

    // Guards the read below, which runs after several await points — if
    // this Notifier's container was disposed in the meantime (e.g. a test
    // tearing down without awaiting this fire-and-forget call; see
    // [_persist]'s own doc comment), `ref` is no longer usable and must not
    // be read again.
    if (!ref.mounted) return;
    await ref
        .read(circleJournalRepositoryProvider)
        .recordShown(
          circleId: today,
          localDate: today,
          direction: intention,
          activityId: activityId,
          shownAt: shownAt,
          planId: planAssignment?.planId.name,
          planVersion: planAssignment?.planVersion,
          stageId: planAssignment?.stageId,
          planCycleId: planAssignment?.planCycleId,
          treatmentUsed: planAssignment?.initialTreatment.name,
          revisitUsed: planAssignment?.isRevisit,
          treatmentSource: planAssignment?.treatmentSource.name,
        );
  }

  /// Persists [state]'s lifecycle and optional attempt/usefulness responses
  /// for today, mirroring it into both the live per-day preference keys
  /// (read back by [build]) and the durable Circle journal
  /// (`circle_journal.dart`). Fired without being awaited by
  /// [start]/[close]/[reportAttempt]/[reportUsefulness] so the in-memory
  /// [state] assignment above — and the rebuild it triggers — stays
  /// synchronous with the user's tap, exactly as before this pass; the
  /// write happens in the background afterward, same ordering trade-off
  /// already accepted by
  /// [`FirstBreathNotifier.markPlayedToday`](first_breath_provider.dart)'s
  /// own callers. [CircleJournalRepository]'s own upsert methods are
  /// self-healing against this fire-and-forget ordering — see their doc
  /// comments.
  Future<void> _persist(RecommendationState state) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final today = dateKey(ref.read(nowProvider));
    final recommendation = state.recommendation;

    await prefs.setString(recommendationDayKey, today);
    await prefs.setString(recommendationStatusKey, state.status.name);

    final startedAt = state.startedAt;
    if (startedAt != null) {
      await prefs.setString(
        recommendationStartedAtKey,
        startedAt.toIso8601String(),
      );
    }

    final closedAt = state.closedAt;
    if (closedAt != null) {
      await prefs.setString(
        recommendationClosedAtKey,
        closedAt.toIso8601String(),
      );
    } else {
      // A started (not yet closed) persist must never leave a stale
      // closedAt from an earlier day/session behind. build()'s `started`
      // restore branch already never reads this key regardless, but an
      // explicit clear keeps the persisted record itself honest, not just
      // the code path that happens to read it today.
      await prefs.remove(recommendationClosedAtKey);
    }

    final attemptResponse = state.attemptResponse;
    if (attemptResponse != null) {
      await prefs.setString(
        recommendationAttemptResponseKey,
        attemptResponse.name,
      );
    } else {
      await prefs.remove(recommendationAttemptResponseKey);
    }

    final usefulnessResponse = state.usefulnessResponse;
    if (usefulnessResponse != null) {
      await prefs.setString(
        recommendationUsefulnessResponseKey,
        usefulnessResponse.name,
      );
    } else {
      await prefs.remove(recommendationUsefulnessResponseKey);
    }

    // Circle Plans (Batch 2A): mirror today's current treatment choice —
    // `setPlanTreatment` is the only method that can change it after
    // resolution, but every call to `_persist` (start/close/reportAttempt/
    // reportUsefulness too) re-writes the current value so it never drifts
    // out of sync with in-memory state.
    final treatmentUsed = recommendation?.treatmentUsed;
    if (treatmentUsed != null) {
      await prefs.setString(recommendationTreatmentKey, treatmentUsed.name);
    }
    // Batch 2B: mirrors treatmentSource the same way treatmentUsed is
    // mirrored just above — see that block's own doc comment.
    final treatmentSource = recommendation?.treatmentSource;
    if (treatmentSource != null) {
      await prefs.setString(
        recommendationTreatmentSourceKey,
        treatmentSource.name,
      );
    }

    if (recommendation == null) return;
    // See _persistChoice's matching comment — this read also happens after
    // several await points.
    if (!ref.mounted) return;
    final journal = ref.read(circleJournalRepositoryProvider);
    final circleId = recommendation.circleId;
    final direction = recommendation.intention;
    final activityId = recommendation.activityId;
    final planId = recommendation.planId?.name;
    final planVersion = recommendation.planVersion;
    final stageId = recommendation.stageId;
    final planCycleId = recommendation.planCycleId;
    final treatmentUsedName = treatmentUsed?.name;
    final treatmentSourceName = treatmentSource?.name;
    final revisitUsed = recommendation.planId == null
        ? null
        : recommendation.isPlanRevisit;

    switch (state.status) {
      case RecommendationStatus.started:
        await journal.recordStarted(
          circleId: circleId,
          localDate: circleId,
          direction: direction,
          activityId: activityId,
          startedAt: startedAt!,
          planId: planId,
          planVersion: planVersion,
          stageId: stageId,
          planCycleId: planCycleId,
          treatmentUsed: treatmentUsedName,
          revisitUsed: revisitUsed,
          treatmentSource: treatmentSourceName,
        );
      case RecommendationStatus.closed:
        await journal.recordClosed(
          circleId: circleId,
          localDate: circleId,
          direction: direction,
          activityId: activityId,
          closedAt: closedAt!,
          planId: planId,
          planVersion: planVersion,
          stageId: stageId,
          planCycleId: planCycleId,
          treatmentUsed: treatmentUsedName,
          revisitUsed: revisitUsed,
          treatmentSource: treatmentSourceName,
        );
      case RecommendationStatus.notStarted:
        break;
    }

    if (attemptResponse != null) {
      await journal.recordAttempt(
        circleId: circleId,
        localDate: circleId,
        direction: direction,
        activityId: activityId,
        response: attemptResponse,
        respondedAt: closedAt ?? startedAt ?? ref.read(nowProvider),
        planId: planId,
        planVersion: planVersion,
        stageId: stageId,
        planCycleId: planCycleId,
        treatmentUsed: treatmentUsedName,
        revisitUsed: revisitUsed,
        treatmentSource: treatmentSourceName,
      );
    }
    if (usefulnessResponse != null) {
      await journal.recordUsefulness(
        circleId: circleId,
        localDate: circleId,
        direction: direction,
        activityId: activityId,
        response: usefulnessResponse,
        respondedAt: closedAt ?? startedAt ?? ref.read(nowProvider),
        planId: planId,
        planVersion: planVersion,
        stageId: stageId,
        planCycleId: planCycleId,
        treatmentUsed: treatmentUsedName,
        revisitUsed: revisitUsed,
        treatmentSource: treatmentSourceName,
      );
    }
  }
}

final recommendationProvider =
    NotifierProvider<RecommendationNotifier, RecommendationState>(
      RecommendationNotifier.new,
    );
