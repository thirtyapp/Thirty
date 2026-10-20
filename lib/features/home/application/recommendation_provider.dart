import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/activity_category.dart';
import '../../../core/analytics/analytics_event_type.dart';
import '../../../core/analytics/analytics_service.dart';
import 'dart:convert';

import '../../../core/premium/premium_access.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/utils/date_key.dart';
import '../../personal_circle/application/kept_circles_provider.dart';
import '../../personal_circle/domain/circle_composer.dart';
import '../../personal_circle/domain/circle_elements.dart';
import '../../personal_circle/domain/composed_session.dart';
import '../../plans/application/circle_plans_provider.dart';
import '../../plans/domain/plan_copy.dart';
import '../../plans/domain/plan_stage_provenance.dart';
import '../domain/circle_session.dart';
import '../domain/recommendation_engine.dart';
import 'activity_catalog.dart';
import 'circle_journal.dart';
import 'suggestion_preferences.dart';

/// THIRTY's daily recommendation (V2 Phase B, ADR-020): the user states
/// today's [Intention] and [TimeWindow], and Recommendation Engine V2
/// (`../domain/recommendation_engine.dart`) picks one [ActivityId] from the
/// user's own explicit history — locally and deterministically.
///
/// **V2 Phase D2:** with Premium, today's Circle is a composed Personal
/// Guided Circle instead ([composed]); a kept Circle the user chose with "Use
/// it today" is one too. Phase D's routines and Paths are retired before
/// release (ADR-024): neither can be today's Circle.
///
/// **ADR-024 B3:** on a Premium day whose need is the active Circle Plan's,
/// the Plan's stage steers that composition first ([ComposedSession.stage]).
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
    required this.offeredMinutes,
    this.timeWindow = TimeWindow.firstUse,
    this.reason = RecommendationReason.bestFit,
    this.replacedFrom,
    this.replacementReason,
    this.replacedFromTitle,
    this.replacedFromStage,
    this.retiredSession,
    this.composed,
    this.composerFellBack = false,
  });

  final String intent;

  /// What today's Circle is called: the activity, or a composed Circle's
  /// substance.
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
  /// for a composed Circle, its main piece's art, which stands for the
  /// Circle.
  final ActivityId activityId;

  /// The raw [Intention] this recommendation was resolved for — kept
  /// alongside [intent] (its display label) so the Circle journal
  /// (`circle_journal.dart`) can use the stable enum identity rather than
  /// re-parsing display copy (ADR-013).
  final Intention intention;

  /// This Circle's stable identity — currently always equal to the local
  /// calendar date it belongs to (`date_key.dart`'s [dateKey] format),
  /// since Free is bounded to one Circle per local day (ADR-013 §3/§5).
  final String circleId;

  /// The `activity_catalog.dart` [catalogVersion] active when this
  /// recommendation was resolved (ADR-013 §3 — "relevant content/version
  /// identity").
  final int catalogVersion;

  /// The time the user said they had today (V2 Phase B).
  final TimeWindow timeWindow;

  /// Today's real length: what the ring runs to.
  final int offeredMinutes;

  /// The engine's decisive reason for this offer.
  final RecommendationReason reason;

  /// The one line shown on the Today card in place of the activity's own
  /// reason, or `null`.
  String? get personalReason => reason.visibleCopy;

  /// The activity first offered today, if the user asked for another — for
  /// a composed Circle, its main piece's art.
  final ActivityId? replacedFrom;

  /// Why ("Not this one today"). Today's constraint, never a usefulness
  /// answer.
  final ReplacementReason? replacementReason;

  /// The composed Circle replaced today, by its main piece's name.
  final String? replacedFromTitle;

  /// ADR-024 B5: the Plan stage of the Circle replaced today, when it was a
  /// stage Circle — journalled so the day stays a stage offer.
  final PlanStageProvenance? replacedFromStage;

  /// ADR-024 (pre-release migration): a Phase D routine or Path Circle that
  /// was already started or closed on the day this build was installed. It
  /// can no longer run as one, so the day carries on as its first piece, and
  /// this — its own journal record, read back unchanged — is what the
  /// journal keeps saying it was. Never set for anything new.
  final CircleSessionRecord? retiredSession;

  /// V2 Phase D2: today's Personal Guided Circle, or a kept Circle the user
  /// chose for today — `null` otherwise.
  final ComposedSession? composed;

  /// V2 Phase D2: a Premium day on which no honest composition existed, so
  /// Today is Free's one activity (ADR-023 §4).
  final bool composerFellBack;

  /// Whether "Not this one today" is still available: once a day — for an
  /// activity or a composed Circle alike — and never for something the user
  /// chose themselves ("Use it today").
  bool get canReplace =>
      replacedFrom == null && reason != RecommendationReason.ownChoice;

  /// The session today's Circle runs: the activity as authored, or a
  /// composed Circle's parts one after the other.
  ActivityDefinition get sessionDefinition {
    final composed = this.composed;
    if (composed != null) {
      return sessionForPlan(composed.plan, title: composed.title);
    }
    return activityDefinition(activityId);
  }

  /// What this offer records in the Circle journal.
  CircleOffer get journalOffer => journalOfferWith();

  /// What this offer records in the Circle journal, with the parts the user
  /// skipped so far (V2 Phase D2) — a fact about the day, never an answer.
  CircleOffer journalOfferWith({List<ElementId> skipped = const []}) =>
      CircleOffer(
        timeWindow: timeWindow.name,
        offeredMinutes: offeredMinutes,
        reasonCode: reason.name,
        replacedFrom: replacedFrom,
        replacementReason: replacementReason?.name,
        replacedFromStage: replacedFromStage,
        session: composed != null
            ? CircleSessionRecord(
                title: composed!.title,
                parts: composed!.plan.toWire(),
                skipped: [for (final e in skipped) e.name],
                keptCircleId: composed!.keptCircleId,
                replacedFromTitle: replacedFromTitle,
                planStage: composed!.stage,
              )
            : retiredSession ??
                  (replacedFromTitle == null
                      ? null
                      : CircleSessionRecord(
                          title: activity,
                          replacedFromTitle: replacedFromTitle,
                        )),
      );
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

/// **Retired (V2 Phase B).** Engine V2 derives recency from the Circle
/// journal; this V1 key is no longer read or written, only removed — on the
/// next choice and by Delete.
///
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

/// **Retired (V2 Phase B)** — see [recommendationHistoryKeyFor].
///
/// SharedPreferences key for the [ActivitySemanticFamily.name] of the most
/// recently *shown* Circle, regardless of which [Intention] it belonged to
/// (ADR-013 §2 — cross-direction family avoidance). Deliberately a single,
/// intention-independent key — unlike [recommendationHistoryKeyFor], this
/// guard compares against whatever the immediately prior Circle was, no
/// matter which direction it came from.
const recommendationLastFamilyKey = 'recommendation_last_family';

/// **Retired (V2 Phase D).** Today's V1 Plan context. No longer read or
/// written — only removed, by the V1 Premium retirement and by Delete.
const recommendationPlanIdKey = 'recommendation_plan_id';

/// **Retired (V2 Phase D).** See [recommendationPlanIdKey].
const recommendationStageIdKey = 'recommendation_stage_id';

/// **Retired (V2 Phase D).** See [recommendationPlanIdKey].
const recommendationPlanCycleIdKey = 'recommendation_plan_cycle_id';

/// **Retired (V2 Phase D).** See [recommendationPlanIdKey].
const recommendationPlanVersionKey = 'recommendation_plan_version';

/// **Retired (V2 Phase D).** See [recommendationPlanIdKey].
const recommendationIsPlanRevisitKey = 'recommendation_is_plan_revisit';

/// **Retired (V2 Phase D).** See [recommendationPlanIdKey].
const recommendationTreatmentKey = 'recommendation_treatment';

/// **Retired (V2 Phase D).** See [recommendationPlanIdKey].
const recommendationTreatmentSourceKey = 'recommendation_treatment_source';

/// V2 Phase B: today's [TimeWindow.name].
const recommendationTimeWindowKey = 'recommendation_time_window';

/// V2 Phase B: today's [Recommendation.offeredMinutes].
const recommendationOfferedMinutesKey = 'recommendation_offered_minutes';

/// V2 Phase B: today's [RecommendationReason.name].
const recommendationReasonKey = 'recommendation_reason';

/// V2 Phase B: the [ActivityId.name] replaced today, if any — its presence
/// is what makes today's one replacement used.
const recommendationReplacedFromKey = 'recommendation_replaced_from';

/// V2 Phase B: today's [ReplacementReason.name], if any.
const recommendationReplacementReasonKey = 'recommendation_replacement_reason';

/// V2 Phase C: when today's started Circle was paused, if it is paused now.
const recommendationPausedAtKey = 'recommendation_paused_at';

/// V2 Phase C: the milliseconds today's Circle spent paused before
/// [recommendationPausedAtKey].
const recommendationPausedMsKey = 'recommendation_paused_ms';

/// V2 Phase C: a Guided Circle's position (`circle_session.dart`'s
/// [guidedFinishPosition]) — where the user is, never what they did.
const recommendationGuidedPositionKey = 'recommendation_guided_position';

/// **Retired (ADR-024, B1).** Today's Phase D routine or Path step, as JSON.
/// No longer written. Read only to keep an already started or closed one's
/// journal record unchanged on the day this build was installed
/// ([Recommendation.retiredSession]); removed on the next choice and by
/// Delete.
const recommendationSessionKey = 'recommendation_session';

/// The composed Circle replaced today, by its main piece's name.
const recommendationReplacedTitleKey = 'recommendation_replaced_title';

/// **Retired (ADR-024, B1).** The Phase D routine replaced today. Read only
/// with [recommendationSessionKey]; removed on the next choice and by
/// Delete.
const recommendationReplacedRoutineKey = 'recommendation_replaced_routine';

/// V2 Phase D2: today's composed Circle ([ComposedSession]), as JSON —
/// absent unless today's Circle is a Personal Guided Circle or a kept one.
const recommendationComposedKey = 'recommendation_composed';

/// V2 Phase D2: present when today was a Premium day on which no honest
/// composition existed (ADR-023 §4).
const recommendationComposerFallbackKey = 'recommendation_composer_fallback';

/// V2 Phase D2: a composed Circle's runtime — the active milliseconds at
/// which its current part was last placed (Start, Next, Back or Skip); the
/// part itself is [recommendationGuidedPositionKey].
const recommendationPartAnchorMsKey = 'recommendation_part_anchor_ms';

/// V2 Phase D2: the elements skipped today, by name.
const recommendationSkippedKey = 'recommendation_skipped';

/// What "Use it today" did (V2 Phase D2, ADR-023 §8).
enum UseTodayResult {
  /// Today's Circle is now one of the user's kept Circles.
  used,

  /// Today's Circle has already started or closed: one Circle a day.
  alreadyStarted,

  /// Nothing by that id, or it can't be offered (turned off, a piece the
  /// user asked THIRTY not to suggest, or content that isn't offerable).
  unavailable,
}

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
    this.pausedAt,
    this.pausedTotal = Duration.zero,
    this.guidedPosition = 0,
    this.noCandidateFor,
    this.partAnchor = Duration.zero,
    this.skipped = const [],
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

  /// V2 Phase C — when the Circle was paused, while it is (or was, if it
  /// was closed paused).
  final DateTime? pausedAt;

  /// V2 Phase C — time spent paused before [pausedAt].
  final Duration pausedTotal;

  /// V2 Phase C — a Guided Circle's position: the step on show, or the
  /// "To finish" page after the last ([guidedFinishPosition]).
  final int guidedPosition;

  /// V2 Phase C — the need and time just asked for, when the user's own
  /// "Don't suggest" choices left nothing to offer. Not persisted.
  final (Intention, TimeWindow)? noCandidateFor;

  /// V2 Phase D2 — a composed Circle's part anchor: the active time at
  /// which [guidedPosition] was last placed. The part on show is derived
  /// from it ([partMomentFor]).
  final Duration partAnchor;

  /// V2 Phase D2 — the elements skipped today. Never a usefulness answer.
  final List<ElementId> skipped;

  /// V2 Phase D2 — a composed Circle's part on show at [now].
  PartMoment? partMomentAt(DateTime now) {
    final composed = recommendation?.composed;
    if (composed == null) return null;
    return partMomentFor(
      composed.plan,
      anchorPosition: guidedPosition,
      anchorElapsed: partAnchor,
      elapsed: activeElapsedAt(now),
    );
  }

  bool get isPaused =>
      status == RecommendationStatus.started && pausedAt != null;

  /// The Circle's active time at [now] (`circle_session.dart`): from Start,
  /// less pauses, until Close.
  Duration activeElapsedAt(DateTime now) {
    final startedAt = this.startedAt;
    if (startedAt == null) return Duration.zero;
    return activeElapsed(
      startedAt: startedAt,
      at: closedAt ?? now,
      pausedAt: pausedAt,
      pausedTotal: pausedTotal,
    );
  }

  /// A copy carrying the session runtime, with the given changes.
  RecommendationState copyWith({
    Recommendation? recommendation,
    RecommendationStatus? status,
    DateTime? startedAt,
    DateTime? closedAt,
    DateTime? pausedAt,
    bool clearPausedAt = false,
    Duration? pausedTotal,
    int? guidedPosition,
    CircleAttemptResponse? attemptResponse,
    bool clearAttempt = false,
    CircleUsefulnessResponse? usefulnessResponse,
    bool clearUsefulness = false,
    Duration? partAnchor,
    List<ElementId>? skipped,
  }) => RecommendationState(
    recommendation: recommendation ?? this.recommendation,
    status: status ?? this.status,
    startedAt: startedAt ?? this.startedAt,
    closedAt: closedAt ?? this.closedAt,
    pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
    pausedTotal: pausedTotal ?? this.pausedTotal,
    guidedPosition: guidedPosition ?? this.guidedPosition,
    attemptResponse: clearAttempt
        ? null
        : (attemptResponse ?? this.attemptResponse),
    usefulnessResponse: clearUsefulness || clearAttempt
        ? null
        : (usefulnessResponse ?? this.usefulnessResponse),
    partAnchor: partAnchor ?? this.partAnchor,
    skipped: skipped ?? this.skipped,
  );
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
  /// Every write runs after the previous one: today's choice, a replacement
  /// moments later and the Circle's lifecycle are persisted in the order
  /// they happened, never interleaved.
  Future<void> _writes = Future<void>.value();

  void _enqueue(Future<void> Function() write) {
    _writes = _writes.then((_) => write()).catchError((Object _) {});
    unawaited(_writes);
  }

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
    // V2 Phase C: the session runtime — a pause and a Guided position.
    final storedPausedAt = DateTime.tryParse(
      prefs.getString(recommendationPausedAtKey) ?? '',
    );
    final storedPausedTotal = Duration(
      milliseconds: (prefs.getInt(recommendationPausedMsKey) ?? 0).clamp(
        0,
        1 << 40,
      ),
    );
    final storedPosition = clampGuidedPosition(
      recommendation.sessionDefinition,
      prefs.getInt(recommendationGuidedPositionKey) ?? 0,
    );
    // V2 Phase D2: a composed Circle's part anchor and today's skips.
    final storedAnchor = Duration(
      milliseconds: (prefs.getInt(recommendationPartAnchorMsKey) ?? 0).clamp(
        0,
        1 << 40,
      ),
    );
    final storedSkipped = [
      for (final name in prefs.getStringList(recommendationSkippedKey) ?? [])
        ?ElementId.values.asNameMap()[name],
    ];

    switch (storedStatus) {
      case RecommendationStatus.started:
        // A "started" record with no valid startedAt is conceptually
        // invalid — fail safe rather than restore a half-formed state.
        if (storedStartedAt == null) return fresh;
        return RecommendationState(
          recommendation: recommendation,
          status: RecommendationStatus.started,
          startedAt: storedStartedAt,
          pausedAt: storedPausedAt,
          pausedTotal: storedPausedTotal,
          guidedPosition: storedPosition,
          partAnchor: storedAnchor,
          skipped: storedSkipped,
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
            .asNameMap()[prefs.getString(recommendationUsefulnessResponseKey)];
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
          pausedAt: storedPausedAt,
          pausedTotal: storedPausedTotal,
          guidedPosition: storedPosition,
          partAnchor: storedAnchor,
          skipped: storedSkipped,
        );

      case RecommendationStatus.notStarted:
      case null:
        // Either an explicit (never actually written) "notStarted", or an
        // unrecognized/corrupt status string — both fail safe the same
        // way as a missing day-key.
        return fresh;
    }
  }

  /// Answers the Daily Context Question for today: Recommendation Engine
  /// V2 decides today's one activity for [intention] and [window] (by
  /// default the time currently chosen, [timeWindowChoiceProvider]) from the
  /// user's own Circle journal, and today's Circle becomes
  /// [RecommendationStatus.notStarted] with it.
  ///
  /// A no-op once today's recommendation already exists: THIRTY decides once
  /// a day, and the decision is restored — never re-made — on rebuilds and
  /// restarts. The only re-selection is [replaceToday].
  ///
  /// Records a [AnalyticsEventType.recommendationShown] event only on this
  /// real, once-per-day resolution.
  ///
  /// **V2 Phase D2:** with Premium, THIRTY composes today's Personal Guided
  /// Circle; when no honest composition exists, Free's one activity, said
  /// plainly. Phase D's Paths and routines are retired (ADR-024): neither
  /// ever takes today's Circle.
  ///
  /// **ADR-024 B3:** first, the active Circle Plan's stage, when today's
  /// need is its need and a Circle honestly follows the stage
  /// ([CirclePlansNotifier.steerToday]); a stage that waits or is set aside
  /// leaves today to the ordinary Personal Guided Circle.
  void chooseIntention(Intention intention, {TimeWindow? window}) {
    if (state.recommendation != null) return;

    final now = ref.read(nowProvider);
    final today = dateKey(now);
    final TimeWindow chosen = ref.read(timeWindowChoiceProvider);
    final timeWindow = window ?? chosen;

    final Recommendation recommendation;
    final history = ref.read(pastCirclesProvider);
    final preferences = ref.read(suggestionPreferencesProvider);
    final decision = recommend(
      RecommendationContext(
        date: now,
        need: intention,
        window: timeWindow,
        allowSafetyPending: ref.read(safetyPendingAllowedProvider),
      ),
      history,
      controls: preferences.controls,
    );
    // V2 Phase D2 (ADR-023 §4): with Premium, THIRTY composes today's
    // Personal Guided Circle — unless no honest composition exists (then
    // Free's one activity, said plainly).
    final premium = ref.read(premiumEntitlementProvider);
    final context = ComposerContext(
      date: now,
      need: intention,
      window: timeWindow,
    );
    final planDay = premium
        ? ref
              .read(circlePlansProvider.notifier)
              .steerToday(
                context,
                history,
                controls: preferences.controls,
                leftOut: preferences.leftOut,
              )
        : null;
    final stageCircle = planDay?.circle;
    final composed = premium
        ? stageCircle ??
              composeCircle(
                context,
                history,
                controls: preferences.controls,
                leftOut: preferences.leftOut,
              )
        : null;
    if (composed != null) {
      recommendation = _fromComposed(
        intention,
        ComposedSession(
          plan: composed.plan,
          basis: composed.basis,
          stage: stageCircle == null ? null : planDay!.stage,
        ),
        today,
        timeWindow,
      );
    } else if (decision == null) {
      // V2 Phase C: the user's own "Don't suggest" choices leave nothing
      // that fits. Say so; never override them.
      state = RecommendationState(
        recommendation: null,
        status: RecommendationStatus.notStarted,
        noCandidateFor: (intention, timeWindow),
      );
      return;
    } else {
      recommendation = _fromDecision(
        intention,
        decision,
        today,
        timeWindow,
        composerFellBack: premium,
      );
    }

    state = RecommendationState(
      recommendation: recommendation,
      status: RecommendationStatus.notStarted,
    );
    _enqueue(
      () => _persistChoice(
        today: today,
        recommendation: recommendation,
        shownAt: now,
      ),
    );
    ref
        .read(analyticsServiceProvider)
        .track(
          AnalyticsEventType.recommendationShown,
          metadata: {
            'intention': intention.name,
            'activity_id': recommendation.activityId.name,
          },
        );
  }

  /// The engine's [decision] as today's Circle: one activity.
  Recommendation _fromDecision(
    Intention intention,
    RecommendationDecision decision,
    String circleId,
    TimeWindow window, {
    Recommendation? replacing,
    ReplacementReason? replacementReason,
    bool composerFellBack = false,
  }) => _buildRecommendation(
    intention,
    decision.activityId,
    circleId,
    window: window,
    offeredMinutes: decision.offeredMinutes,
    reason: decision.reason,
    replacedFrom: replacing?.activityId,
    replacementReason: replacementReason,
    replacedFromTitle: replacing == null ? null : _replacedTitle(replacing),
    replacedFromStage: replacing?.composed?.stage,
    composerFellBack: composerFellBack,
  );

  /// V2 Phase D2: [composed] as today's Circle — its main piece's art and
  /// category stand for it; its one line says only what is true.
  Recommendation _fromComposed(
    Intention intention,
    ComposedSession composed,
    String circleId,
    TimeWindow window, {
    Recommendation? replacing,
    ReplacementReason? replacementReason,
    RecommendationReason reason = RecommendationReason.personalCircle,
  }) => _buildRecommendation(
    intention,
    composed.plan.main.definition.art,
    circleId,
    window: window,
    offeredMinutes: composed.plan.minutes,
    reason: reason,
    replacedFrom: replacing?.activityId,
    replacementReason: replacementReason,
    replacedFromTitle: replacing == null ? null : _replacedTitle(replacing),
    replacedFromStage: replacing?.composed?.stage,
    composed: composed,
  );

  /// How a replaced Circle is named in History: a composed Circle by its
  /// main piece, a single activity by nothing extra (its own label is used).
  static String? _replacedTitle(Recommendation replaced) =>
      replaced.composed?.plan.main.definition.name;

  /// "Not this one today" (V2 Phase B): re-selects today's activity once,
  /// under [reason] as a hard constraint for today. Returns `false` — and
  /// changes nothing — unless today's Circle is offered but not yet
  /// started and has not been replaced already; or if nothing else fits
  /// [reason] today.
  ///
  /// The reason is never a usefulness answer. The journal records the final
  /// activity, the one it replaced and why, so a restart restores the
  /// replacement and never offers a second one.
  bool replaceToday(ReplacementReason reason) {
    final current = state.recommendation;
    if (current == null || !current.canReplace) return false;
    if (state.status != RecommendationStatus.notStarted) return false;

    final now = ref.read(nowProvider);
    // V2 Phase D2: a Personal Guided Circle is recomposed under today's
    // constraint while Premium lasts; only if nothing honest fits does the
    // engine pick one activity instead.
    final composedToday = current.composed;
    if (composedToday != null &&
        !composedToday.isKept &&
        ref.read(premiumEntitlementProvider)) {
      final preferences = ref.read(suggestionPreferencesProvider);
      final context = ComposerContext(
        date: now,
        need: current.intention,
        window: current.timeWindow,
        constraint: CompositionConstraint(
          reason: reason,
          replacing: composedToday.plan,
        ),
      );
      final history = ref.read(pastCirclesProvider);
      // ADR-024 C4: a stage Circle is first recomposed inside its stage;
      // if none follows it, the ordinary composition — and the stage waits.
      final stage = composedToday.stage;
      final inStage = stage == null
          ? null
          : ref
                .read(circlePlansProvider.notifier)
                .replaceStage(
                  stage,
                  context,
                  history,
                  controls: preferences.controls,
                  leftOut: preferences.leftOut,
                );
      final recomposed =
          inStage ??
          composeCircle(
            context,
            history,
            controls: preferences.controls,
            leftOut: preferences.leftOut,
          );
      if (recomposed != null) {
        final replacement = _fromComposed(
          current.intention,
          ComposedSession(
            plan: recomposed.plan,
            basis: recomposed.basis,
            stage: inStage == null ? null : stage,
          ),
          current.circleId,
          current.timeWindow,
          replacing: current,
          replacementReason: reason,
        );
        state = RecommendationState(
          recommendation: replacement,
          status: RecommendationStatus.notStarted,
        );
        _enqueue(() => _persistReplacement(replacement, now));
        return true;
      }
    }
    final decision = recommend(
      RecommendationContext(
        date: now,
        need: current.intention,
        window: current.timeWindow,
        replacement: ReplacementRequest(
          reason: reason,
          replacing: current.activityId,
          replacingMinutes: current.offeredMinutes,
          replacingComponents: current.composed?.plan.activities ?? [],
        ),
        allowSafetyPending: ref.read(safetyPendingAllowedProvider),
      ),
      ref.read(pastCirclesProvider),
      controls: ref.read(suggestionPreferencesProvider).controls,
    );
    if (decision == null) return false;

    final replacement = _fromDecision(
      current.intention,
      decision,
      current.circleId,
      current.timeWindow,
      replacing: current,
      replacementReason: reason,
    );
    state = RecommendationState(
      recommendation: replacement,
      status: RecommendationStatus.notStarted,
    );
    _enqueue(() => _persistReplacement(replacement, now));
    return true;
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
    final snapshot = state;
    _enqueue(() => _persist(snapshot));
    // Fired only on a real transition — the two guard clauses above already
    // make this method a no-op on a repeat call, so a double/duplicate
    // start() can never record a duplicate circleStarted event either
    // (Batch 1, Phase E instrumentation).
    ref.read(analyticsServiceProvider).track(AnalyticsEventType.circleStarted);
  }

  /// Pauses today's started Circle (V2 Phase C): its time stops until
  /// [resume]. A no-op unless started and running. Guided Circles pause on
  /// request; Paced ones also whenever the app leaves the foreground.
  void pause() {
    if (state.status != RecommendationStatus.started || state.isPaused) return;
    state = state.copyWith(pausedAt: ref.read(eventClockProvider)());
    final snapshot = state;
    _enqueue(() => _persist(snapshot));
  }

  /// Resumes a paused Circle: the paused stretch is set aside, never
  /// counted. A no-op unless paused.
  void resume() {
    final pausedAt = state.pausedAt;
    if (!state.isPaused || pausedAt == null) return;
    final now = ref.read(eventClockProvider)();
    final paused = now.difference(pausedAt);
    state = state.copyWith(
      clearPausedAt: true,
      pausedTotal:
          state.pausedTotal + (paused.isNegative ? Duration.zero : paused),
    );
    final snapshot = state;
    _enqueue(() => _persist(snapshot));
  }

  /// Shows [position] of a Guided Circle (V2 Phase C). Where the user is,
  /// never a record that a step was done.
  void moveTo(int position) {
    final recommendation = state.recommendation;
    if (recommendation == null) return;
    if (state.status != RecommendationStatus.started) return;
    final clamped = clampGuidedPosition(
      recommendation.sessionDefinition,
      position,
    );
    if (clamped == state.guidedPosition) return;
    state = state.copyWith(guidedPosition: clamped);
    final snapshot = state;
    _enqueue(() => _persist(snapshot));
  }

  /// V2 Phase D2: places a composed Circle at [position] now — Next, Back,
  /// or after a skip. From here the parts move on by themselves again.
  /// Orientation only: it never records that a part was done.
  void movePart(int position) {
    final composed = state.recommendation?.composed;
    if (composed == null) return;
    if (state.status != RecommendationStatus.started) return;
    final clamped = position.clamp(0, composed.plan.parts.length);
    state = state.copyWith(
      guidedPosition: clamped,
      partAnchor: state.activeElapsedAt(ref.read(eventClockProvider)()),
    );
    final snapshot = state;
    _enqueue(() => _persist(snapshot));
  }

  /// V2 Phase D2 (ADR-023 §7): "Skip this step" — the part on show is set
  /// aside for today and the next one begins. A skip is never a usefulness
  /// answer: it only keeps that part from sharing the day's answer. With
  /// [leaveOut], the user also asks THIRTY to leave it out of their Circles
  /// from now on — an explicit preference, reversible in Memory. The parts
  /// that build on it ("Choose one thing" after "Get it out") are skipped
  /// with it, so no part ever refers to something that didn't happen.
  void skipPart({bool leaveOut = false}) {
    final now = ref.read(eventClockProvider)();
    final moment = state.partMomentAt(now);
    final composed = state.recommendation?.composed;
    if (moment == null || composed == null || moment.finished) return;
    if (state.status != RecommendationStatus.started) return;
    final plan = composed.plan;
    final element = plan.parts[moment.position].element;
    final through = moment.position + plan.partsBuildingOn(moment.position);
    final skippedNow = [
      for (final part in plan.parts.sublist(moment.position, through + 1))
        part.element,
    ];
    state = state.copyWith(
      guidedPosition: through + 1,
      partAnchor: state.activeElapsedAt(now),
      skipped: [
        ...state.skipped,
        for (final id in skippedNow)
          if (!state.skipped.contains(id)) id,
      ],
    );
    final snapshot = state;
    _enqueue(() => _persist(snapshot));
    // Leave it out is a composer control, and Premium (contract, Free /
    // Premium): a Free day's kept Circle skips the part for today only.
    if (leaveOut && ref.read(premiumEntitlementProvider)) {
      unawaited(
        ref.read(suggestionPreferencesProvider.notifier).leaveOut(element),
      );
    }
  }

  /// V2 Phase D2 (ADR-023 §8): "Use it today" — today's Circle becomes one
  /// of the user's kept Circles ([keptCircleId]). Free: what the user owns
  /// is theirs to use. Only before today's Circle has started; still one
  /// Circle a day, replacing today's not-started choice. Today's need stays
  /// the one the user chose; before any choice, it is the kept Circle's own.
  /// It is the user's choice, not a "Not this one today": nothing is
  /// recorded as declined, and no replacement is offered after it.
  UseTodayResult useOwnedToday({required String keptCircleId}) {
    if (state.status != RecommendationStatus.notStarted) {
      return UseTodayResult.alreadyStarted;
    }
    final controls = ref.read(suggestionPreferencesProvider).controls;
    final current = state.recommendation;
    final now = ref.read(nowProvider);
    final today = dateKey(now);

    final kept = ref.read(keptCirclesProvider).keptById(keptCircleId);
    if (kept == null) return UseTodayResult.unavailable;
    final need = current?.intention ?? kept.need;
    if (!kept.plan.parts.every((p) => isElementOfferable(p.definition)) ||
        kept.plan.activities.any(
          (a) => controls.notSuggested.contains((a, need)),
        )) {
      return UseTodayResult.unavailable;
    }
    final chosen = _fromComposed(
      need,
      ComposedSession(
        plan: kept.plan,
        keptCircleId: kept.id,
        keptName: kept.name,
      ),
      today,
      current?.timeWindow ?? _windowFor(kept.minutes),
      reason: RecommendationReason.ownChoice,
    );

    state = RecommendationState(
      recommendation: chosen,
      status: RecommendationStatus.notStarted,
    );
    if (current == null) {
      _enqueue(
        () =>
            _persistChoice(today: today, recommendation: chosen, shownAt: now),
      );
    } else {
      _enqueue(() => _persistReplacement(chosen, now));
    }
    return UseTodayResult.used;
  }

  /// The smallest time window [minutes] fits in.
  static TimeWindow _windowFor(int minutes) => TimeWindow.values.firstWhere(
    (w) => minutes <= w.maxMinutes,
    orElse: () => TimeWindow.upTo30,
  );

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
    final recommendation = state.recommendation;
    if (recommendation == null) return;
    if (state.status != RecommendationStatus.started) return;

    final closedAt = ref.read(eventClockProvider)();
    state = state.copyWith(
      status: RecommendationStatus.closed,
      closedAt: closedAt,
    );
    final snapshot = state;
    _enqueue(() => _persist(snapshot));
    // ADR-024 B3: a stage Circle started and now closed in THIRTY is
    // *guided* — never "done". The Plan moves on once for this Circle.
    final composed = recommendation.composed;
    if (composed?.stage case final stage?) {
      ref
          .read(circlePlansProvider.notifier)
          .recordGuided(
            stage,
            circleId: recommendation.circleId,
            parts: composed!.plan.toWire(),
            skipped: [for (final e in snapshot.skipped) e.name],
          );
    }
    // Fired only on a real transition, for the same reason start() above
    // only fires once per Circle — this is also the frozen post-fix
    // measurement protocol's "Daily Check-In completed" (see
    // AnalyticsEventType.circleClosed's own doc comment).
    ref.read(analyticsServiceProvider).track(AnalyticsEventType.circleClosed);
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
    state = state.copyWith(
      attemptResponse: response,
      clearUsefulness: !isAffirmative,
    );
    final snapshot = state;
    _enqueue(() => _persist(snapshot));
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

    state = state.copyWith(usefulnessResponse: response);
    final snapshot = state;
    _enqueue(() => _persist(snapshot));
    ref
        .read(analyticsServiceProvider)
        .track(
          AnalyticsEventType.circleUsefulnessReported,
          metadata: {'response': response.wireName},
        );
  }

  /// "Remove this answer" (V2 Phase C): removes the usefulness answer of
  /// [circleId] — and, with [includingAttempt], its "Did you try it?"
  /// answer too. The Circle's own record stays. Today's Circle updates at
  /// once; memory and future picks recompute from the journal.
  void removeAnswer(String circleId, {required bool includingAttempt}) {
    final today = state.recommendation;
    if (today != null &&
        today.circleId == circleId &&
        state.status == RecommendationStatus.closed) {
      state = state.copyWith(
        clearAttempt: includingAttempt,
        clearUsefulness: true,
      );
    }
    final snapshot = state;
    final isToday = today?.circleId == circleId;
    _enqueue(() async {
      if (isToday) await _persist(snapshot);
      if (!ref.mounted) return;
      final changed = await ref
          .read(circleJournalRepositoryProvider)
          .removeAnswer(circleId, includingAttempt: includingAttempt);
      if (changed && ref.mounted) {
        ref.invalidate(circleJournalRepositoryProvider);
      }
    });
  }

  /// Builds today's [Recommendation] for ([intention], [activityId]) on local
  /// date [today] — or, with [composed], today's composed Circle.
  Recommendation _buildRecommendation(
    Intention intention,
    ActivityId activityId,
    String today, {
    TimeWindow window = TimeWindow.firstUse,
    int? offeredMinutes,
    RecommendationReason reason = RecommendationReason.bestFit,
    ActivityId? replacedFrom,
    ReplacementReason? replacementReason,
    String? replacedFromTitle,
    PlanStageProvenance? replacedFromStage,
    CircleSessionRecord? retiredSession,
    ComposedSession? composed,
    bool composerFellBack = false,
  }) {
    final minutes =
        offeredMinutes ??
        composed?.plan.minutes ??
        activityTypicalMinutes(activityId);
    return Recommendation(
      intent: intentionLabel(intention),
      // A composed Circle's row names its substance; every part is in its
      // how-to (S25 finding, D2).
      activity:
          composed?.plan.substanceLine ??
          retiredSession?.title ??
          activityLabel(activityId),
      duration: '$minutes minutes',
      why: switch (composed) {
        ComposedSession(isKept: true) => ComposedCopy.keptLine,
        // ADR-024 B4 (C8): on a stage day the stage's line takes the basis
        // line's place — the card is no taller.
        ComposedSession(:final stage?) => _stageLine(stage),
        ComposedSession(:final basis?) => ComposedCopy.basisLine(basis, window),
        _ when composerFellBack && reason.visibleCopy == null =>
          ComposedCopy.fallbackLine,
        _ => activityReasonFor(intention, activityId),
      },
      category: activityCategory(activityId),
      activityId: activityId,
      intention: intention,
      circleId: today,
      catalogVersion: catalogVersion,
      timeWindow: window,
      offeredMinutes: minutes,
      reason: reason,
      replacedFrom: replacedFrom,
      replacementReason: replacementReason,
      replacedFromTitle: replacedFromTitle,
      replacedFromStage: replacedFromStage,
      retiredSession: retiredSession,
      composed: composed,
      composerFellBack: composerFellBack,
    );
  }

  /// A stage Circle's Today line: its stage's own, or stage 5's from what it
  /// combines and what the user said about those stages.
  String _stageLine(PlanStageProvenance stage) {
    final cycle = ref.read(circlePlansProvider).plans[stage.planId]?.cycles;
    return PlanCopy.todayStageLine(
      stage,
      cycle: cycle?.where((c) => c.id == stage.cycleId).firstOrNull,
      answers: stageAnswersFrom(
        ref.read(circleJournalRepositoryProvider).readAll(),
      ),
    );
  }

  /// Restores today's [Recommendation] from [prefs], or `null` if no valid,
  /// direction-compatible (intention, activityId) pair is persisted — the
  /// caller has already confirmed the persisted day matches [today].
  ///
  /// **Identity check (V2, Phase A):** only an unknown [ActivityId] or
  /// [Intention] name is treated as corrupt. Today's Circle was already
  /// offered and shown, so it is restored even if a later catalogue revision
  /// changed that activity's need fit or retired it — rewriting what the
  /// user was actually shown today would be untruthful.
  ///
  /// **ADR-024 (pre-release migration):** a Phase D routine or Path Circle
  /// persisted for today, from before this build, is never run as one. If it
  /// was not started, today's choice is asked again. If it was already
  /// started or closed, the day carries on as its first piece, with its own
  /// journal record kept exactly as it was ([Recommendation.retiredSession])
  /// — never rewritten into something it wasn't.
  Recommendation? _restoreRecommendation(
    SharedPreferences prefs,
    String today,
  ) {
    final intention = Intention.values
        .asNameMap()[prefs.getString(recommendationIntentionKey)];
    final activityId = ActivityId.values
        .asNameMap()[prefs.getString(recommendationActivityIdKey)];
    if (intention == null || activityId == null) return null;

    // V2 Phase B: today's offer. Absent on a day persisted before Phase B —
    // the first-use window and the activity's usual length, then.
    final window =
        TimeWindow.values.asNameMap()[prefs.getString(
          recommendationTimeWindowKey,
        )] ??
        TimeWindow.firstUse;
    final offeredMinutes = prefs.getInt(recommendationOfferedMinutesKey);
    final reason =
        RecommendationReason.values.asNameMap()[prefs.getString(
          recommendationReasonKey,
        )] ??
        RecommendationReason.bestFit;
    final replacedFrom = ActivityId.values
        .asNameMap()[prefs.getString(recommendationReplacedFromKey)];
    final replacementReason = ReplacementReason.values
        .asNameMap()[prefs.getString(recommendationReplacementReasonKey)];

    ComposedSession? composed;
    final rawComposed = prefs.getString(recommendationComposedKey);
    if (rawComposed != null) {
      try {
        composed = ComposedSession.fromJson(jsonDecode(rawComposed));
      } catch (_) {
        composed = null;
      }
    }

    CircleSessionRecord? retiredSession;
    final rawSession = prefs.getString(recommendationSessionKey);
    if (rawSession != null && composed == null) {
      final status = RecommendationStatus.values
          .asNameMap()[prefs.getString(recommendationStatusKey)];
      if (status != RecommendationStatus.started &&
          status != RecommendationStatus.closed) {
        return null;
      }
      try {
        final decoded = jsonDecode(rawSession);
        if (decoded is Map<String, Object?>) {
          retiredSession = CircleSessionRecord.fromJson({
            ...decoded,
            'replacedFromTitle': prefs.getString(
              recommendationReplacedTitleKey,
            ),
            'replacedFromRoutineId': prefs.getString(
              recommendationReplacedRoutineKey,
            ),
          });
        }
      } catch (_) {
        retiredSession = null;
      }
    }

    return _buildRecommendation(
      intention,
      activityId,
      today,
      window: window,
      offeredMinutes: offeredMinutes,
      reason: reason,
      replacedFrom: replacedFrom,
      replacementReason: replacementReason,
      replacedFromTitle: prefs.getString(recommendationReplacedTitleKey),
      retiredSession: retiredSession,
      composed: composed,
      composerFellBack:
          prefs.getBool(recommendationComposerFallbackKey) ?? false,
    );
  }

  /// Persists today's freshly-chosen [recommendation] alongside
  /// [RecommendationStatus.notStarted]. Any started/closed/attempt/
  /// usefulness values from an earlier day are explicitly cleared — a fresh
  /// choice must never inherit a stale session. Also records this Circle's
  /// "shown" journal entry (`circle_journal.dart`).
  Future<void> _persistChoice({
    required String today,
    required Recommendation recommendation,
    required DateTime shownAt,
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final intention = recommendation.intention;
    final activityId = recommendation.activityId;
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
    await prefs.remove(recommendationPausedAtKey);
    await prefs.remove(recommendationPausedMsKey);
    await prefs.remove(recommendationGuidedPositionKey);
    await prefs.remove(recommendationPartAnchorMsKey);
    await prefs.remove(recommendationSkippedKey);
    await _persistOffer(prefs, recommendation);
    // V1 selector history is retired: Engine V2 reads the journal.
    await prefs.remove(recommendationLastFamilyKey);
    for (final need in Intention.values) {
      await prefs.remove(recommendationHistoryKeyFor(need));
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
          offer: recommendation.journalOffer,
        );
    // A plain repository mutation does not itself notify Riverpod
    // watchers — invalidate so an already-mounted reactive reader picks up
    // this write instead of staying stale until something else happens to
    // rebuild it. Mirrors the same invalidate-after-write
    // `journal_data_controls.dart` already does after `clearAll()`.
    if (ref.mounted) ref.invalidate(circleJournalRepositoryProvider);
  }

  /// Today's offer — time window, length, reason and any replacement — in
  /// the per-day keys [build] restores.
  Future<void> _persistOffer(
    SharedPreferences prefs,
    Recommendation recommendation,
  ) async {
    await prefs.setString(
      recommendationTimeWindowKey,
      recommendation.timeWindow.name,
    );
    await prefs.setInt(
      recommendationOfferedMinutesKey,
      recommendation.offeredMinutes,
    );
    await prefs.setString(recommendationReasonKey, recommendation.reason.name);
    final replacedFrom = recommendation.replacedFrom;
    final replacementReason = recommendation.replacementReason;
    if (replacedFrom != null && replacementReason != null) {
      await prefs.setString(recommendationReplacedFromKey, replacedFrom.name);
      await prefs.setString(
        recommendationReplacementReasonKey,
        replacementReason.name,
      );
    } else {
      await prefs.remove(recommendationReplacedFromKey);
      await prefs.remove(recommendationReplacementReasonKey);
    }
    // Retired with Phase D's routines and Paths (ADR-024): never written.
    await prefs.remove(recommendationSessionKey);
    await prefs.remove(recommendationReplacedRoutineKey);
    final composed = recommendation.composed;
    if (composed != null) {
      await prefs.setString(
        recommendationComposedKey,
        jsonEncode(composed.toJson()),
      );
    } else {
      await prefs.remove(recommendationComposedKey);
    }
    if (recommendation.composerFellBack) {
      await prefs.setBool(recommendationComposerFallbackKey, true);
    } else {
      await prefs.remove(recommendationComposerFallbackKey);
    }
    final replacedTitle = recommendation.replacedFromTitle;
    if (replacedTitle != null) {
      await prefs.setString(recommendationReplacedTitleKey, replacedTitle);
    } else {
      await prefs.remove(recommendationReplacedTitleKey);
    }
    // V1 Plan context is retired (V2 Phase D).
    for (final key in retiredPlanDayKeys) {
      await prefs.remove(key);
    }
  }

  /// Persists today's replacement: the per-day keys first (so a restart
  /// restores the replacement and never offers a second), then the journal.
  Future<void> _persistReplacement(
    Recommendation replacement,
    DateTime replacedAt,
  ) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      recommendationActivityIdKey,
      replacement.activityId.name,
    );
    await _persistOffer(prefs, replacement);
    if (!ref.mounted) return;
    await ref
        .read(circleJournalRepositoryProvider)
        .recordReplaced(
          circleId: replacement.circleId,
          localDate: replacement.circleId,
          direction: replacement.intention,
          activityId: replacement.activityId,
          replacedAt: replacedAt,
          offer: replacement.journalOffer,
        );
    if (ref.mounted) ref.invalidate(circleJournalRepositoryProvider);
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

    // V2 Phase C: the session runtime, as timestamps and small state.
    final pausedAt = state.pausedAt;
    if (pausedAt != null) {
      await prefs.setString(
        recommendationPausedAtKey,
        pausedAt.toIso8601String(),
      );
    } else {
      await prefs.remove(recommendationPausedAtKey);
    }
    if (state.pausedTotal > Duration.zero) {
      await prefs.setInt(
        recommendationPausedMsKey,
        state.pausedTotal.inMilliseconds,
      );
    } else {
      await prefs.remove(recommendationPausedMsKey);
    }
    if (state.guidedPosition > 0) {
      await prefs.setInt(recommendationGuidedPositionKey, state.guidedPosition);
    } else {
      await prefs.remove(recommendationGuidedPositionKey);
    }
    if (state.partAnchor > Duration.zero) {
      await prefs.setInt(
        recommendationPartAnchorMsKey,
        state.partAnchor.inMilliseconds,
      );
    } else {
      await prefs.remove(recommendationPartAnchorMsKey);
    }
    if (state.skipped.isNotEmpty) {
      await prefs.setStringList(recommendationSkippedKey, [
        for (final e in state.skipped) e.name,
      ]);
    } else {
      await prefs.remove(recommendationSkippedKey);
    }

    if (recommendation == null) return;
    // See _persistChoice's matching comment — this read also happens after
    // several await points.
    if (!ref.mounted) return;
    final journal = ref.read(circleJournalRepositoryProvider);
    final circleId = recommendation.circleId;
    final direction = recommendation.intention;
    final activityId = recommendation.activityId;
    final offer = recommendation.journalOfferWith(skipped: state.skipped);

    var journalChanged = false;
    switch (state.status) {
      case RecommendationStatus.started:
        await journal.recordStarted(
          circleId: circleId,
          localDate: circleId,
          direction: direction,
          activityId: activityId,
          startedAt: startedAt!,
          offer: offer,
        );
        journalChanged = true;
      case RecommendationStatus.closed:
        await journal.recordClosed(
          circleId: circleId,
          localDate: circleId,
          direction: direction,
          activityId: activityId,
          closedAt: closedAt!,
          offer: offer,
          minutesAtClose: state.activeElapsedAt(closedAt).inMinutes,
        );
        journalChanged = true;
      case RecommendationStatus.notStarted:
        // Nothing to record: "shown" was recorded with the choice.
        break;
    }

    // V2 Phase D2: today's skips, as they happen.
    if (recommendation.composed != null && state.skipped.isNotEmpty) {
      await journal.recordSkipped(
        circleId: circleId,
        skipped: [for (final e in state.skipped) e.name],
      );
      journalChanged = true;
    }
    if (attemptResponse != null) {
      await journal.recordAttempt(
        circleId: circleId,
        localDate: circleId,
        direction: direction,
        activityId: activityId,
        response: attemptResponse,
        respondedAt: closedAt ?? startedAt ?? ref.read(nowProvider),
        offer: offer,
      );
      journalChanged = true;
    }
    if (usefulnessResponse != null) {
      await journal.recordUsefulness(
        circleId: circleId,
        localDate: circleId,
        direction: direction,
        activityId: activityId,
        response: usefulnessResponse,
        respondedAt: closedAt ?? startedAt ?? ref.read(nowProvider),
        offer: offer,
      );
      journalChanged = true;
    }

    // See [_persistChoice]'s matching comment: a plain repository
    // mutation never notifies its own Riverpod watchers, so an
    // already-mounted reactive reader (e.g. the Insights Circle-history
    // calendar kept alive off-screen by `StatefulShellRoute.indexedStack`)
    // must be told to look again.
    if (journalChanged && ref.mounted) {
      ref.invalidate(circleJournalRepositoryProvider);
    }
  }
}

final recommendationProvider =
    NotifierProvider<RecommendationNotifier, RecommendationState>(
      RecommendationNotifier.new,
    );

/// The retired V1 Plan context of today's Circle (V2 Phase D) — removed
/// whenever today's offer is written, and by Delete.
const retiredPlanDayKeys = [
  recommendationPlanIdKey,
  recommendationStageIdKey,
  recommendationPlanCycleIdKey,
  recommendationPlanVersionKey,
  recommendationIsPlanRevisitKey,
  recommendationTreatmentKey,
  recommendationTreatmentSourceKey,
];

/// Every persisted key holding a recorded Circle outside the journal:
/// today's Circle session (its direction, activity, lifecycle, reflection
/// answers and composed Circle, and the retired Phase D keys) and the
/// selection history drawn from past Circles. "Delete Circle history"
/// removes these together with the journal
/// (`../presentation/widgets/journal_data_controls.dart`), then invalidates
/// [recommendationProvider] so today is re-derived from the empty store.
/// Preferences, the first-breath flag and kept Circles are not Circle
/// history and are left alone.
Future<void> clearRecordedCircleState(SharedPreferences prefs) async {
  for (final key in [
    recommendationDayKey,
    recommendationIntentionKey,
    recommendationActivityIdKey,
    recommendationStatusKey,
    recommendationStartedAtKey,
    recommendationClosedAtKey,
    recommendationAttemptResponseKey,
    recommendationUsefulnessResponseKey,
    recommendationLastFamilyKey,
    recommendationPlanIdKey,
    recommendationStageIdKey,
    recommendationPlanCycleIdKey,
    recommendationPlanVersionKey,
    recommendationIsPlanRevisitKey,
    recommendationTreatmentKey,
    recommendationTreatmentSourceKey,
    recommendationTimeWindowKey,
    recommendationOfferedMinutesKey,
    recommendationReasonKey,
    recommendationReplacedFromKey,
    recommendationReplacementReasonKey,
    recommendationPausedAtKey,
    recommendationPausedMsKey,
    recommendationGuidedPositionKey,
    recommendationSessionKey,
    recommendationReplacedTitleKey,
    recommendationReplacedRoutineKey,
    recommendationComposedKey,
    recommendationComposerFallbackKey,
    recommendationPartAnchorMsKey,
    recommendationSkippedKey,
    for (final intention in Intention.values)
      recommendationHistoryKeyFor(intention),
  ]) {
    await prefs.remove(key);
  }
}

/// Whether content awaiting the safety review may be offered: only internal
/// debug builds ([safetyPendingContentAllowed]). The QA harness pins it off,
/// so a QA walkthrough always shows exactly what a release build would.
final safetyPendingAllowedProvider = Provider<bool>(
  (ref) => safetyPendingContentAllowed,
);

/// The time window chosen on today's Daily Context Question (V2 Phase B).
///
/// Starts from the most recent explicit choice in the Circle journal, or
/// [TimeWindow.firstUse] — so it is derived, never a separate profile: once
/// Circle history is deleted, it starts from first use again.
class TimeWindowChoice extends Notifier<TimeWindow> {
  @override
  TimeWindow build() {
    final entries = ref.watch(circleJournalRepositoryProvider).readAll();
    for (final entry in entries.reversed) {
      final window = TimeWindow.values.asNameMap()[entry.timeWindow];
      if (window != null) return window;
    }
    return TimeWindow.firstUse;
  }

  void choose(TimeWindow window) => state = window;
}

final NotifierProvider<TimeWindowChoice, TimeWindow> timeWindowChoiceProvider =
    NotifierProvider<TimeWindowChoice, TimeWindow>(TimeWindowChoice.new);

/// The Circle journal as Recommendation Engine V2 sees it: one past Circle
/// per entry, with only its explicit usefulness answer. "Didn't try" ("Not
/// today") is no usefulness answer; Close alone is never evidence.
///
/// A Personal Guided Circle (or a kept Circle) lists its parts and skips;
/// its answer is never evidence about an activity. A historical Phase D
/// routine or Path Circle (retired, ADR-024) keeps exactly what it was: a
/// routine Circle stays the routine's ([PastCircle.routineId]), and one that
/// joined several pieces lists their activities ([historicalModuleActivities])
/// — so neither answer ever counts as evidence about one activity, and
/// recency still sees each piece.
List<PastCircle> pastCirclesFrom(Iterable<CircleJournalEntry> entries) => [
  for (final entry in entries)
    if (DateTime.tryParse(entry.localDate) case final date?)
      _pastCircle(entry, date),
];

/// The past Circles the engine and the composer read, from the journal.
final pastCirclesProvider = Provider<List<PastCircle>>(
  (ref) =>
      pastCirclesFrom(ref.watch(circleJournalRepositoryProvider).readAll()),
);

/// The activity each Phase D session module stood for, by the name stored in
/// historical journal records (`writeDown:short`). Read-only history: no
/// module is ever offered again (ADR-024).
const historicalModuleActivities = <String, ActivityId>{
  'standingStretch': ActivityId.energisingStretchFlow,
  'musicMove': ActivityId.moveToMusic,
  'activeTask': ActivityId.activeHouseholdTask,
  'briskWalk': ActivityId.thirtyMinuteWalk,
  'phoneFreeWalk': ActivityId.phoneFreeWalk,
  'writeDown': ActivityId.writeItDown,
  'clearSurface': ActivityId.tidyOneSurface,
  'listenOne': ActivityId.quietAudioFocus,
  'gentleStretch': ActivityId.gentleStretchPause,
  'warmDrink': ActivityId.smallComfortRitual,
  'quietMusic': ActivityId.quietMusicBreak,
  'easyWalk': ActivityId.easyWalk,
  'sitOutside': ActivityId.quietSittingOutside,
};

/// [wire]'s activity (`writeDown:short` → Write it down), or `null`.
ActivityId? _historicalModuleActivity(String wire) {
  final parts = wire.split(':');
  if (parts.length != 2 || (parts[1] != 'short' && parts[1] != 'full')) {
    return null;
  }
  return historicalModuleActivities[parts[0]];
}

PastCircle _pastCircle(CircleJournalEntry entry, DateTime date) {
  final session = entry.session;
  final pieces = [
    for (final m in session?.modules ?? const <String>[])
      ?_historicalModuleActivity(m),
  ];
  final parts = [
    for (final p in session?.parts ?? const <String>[])
      if (CirclePart.fromWire(p) != null) p,
  ];
  final plan = CirclePlan.fromWire(parts);
  return PastCircle(
    date: date,
    need: entry.direction,
    activityId: entry.activityId,
    catalogVersion: entry.catalogVersion,
    usefulness: switch (entry.usefulnessResponse) {
      CircleUsefulnessResponse.veryUseful => PastUsefulness.veryUseful,
      CircleUsefulnessResponse.somewhatUseful => PastUsefulness.somewhatUseful,
      CircleUsefulnessResponse.notUseful => PastUsefulness.notUseful,
      null => null,
    },
    replacedFrom: entry.replacedFrom,
    answeredAt: entry.closedAt,
    window: TimeWindow.values.asNameMap()[entry.timeWindow],
    routineId: session?.routineId,
    components: plan != null
        ? plan.activities
        : pieces.length > 1
        ? pieces
        : const [],
    replacedFromRoutineId: session?.replacedFromRoutineId,
    parts: plan == null ? const [] : parts,
    skipped: session?.skipped ?? const [],
    keptCircleId: session?.keptCircleId,
  );
}
