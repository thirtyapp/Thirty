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
import '../../toolkit/application/toolkit_provider.dart';
import '../../toolkit/domain/module_library.dart';
import '../../toolkit/domain/path_catalog.dart';
import '../../toolkit/domain/path_engine.dart';
import '../../toolkit/domain/toolkit_model.dart';
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
/// **V2 Phase D:** today's Circle may instead be one of the user's routines
/// (the engine picked it, as an ordinary candidate) or the next step of
/// their Path (it claimed today's matching need) — see [session].
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
    this.session,
    this.replacedFromTitle,
    this.replacedFromRoutineId,
  });

  final String intent;

  /// What today's Circle is called: the activity, the routine, or the Path
  /// step's pieces.
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
  /// for a routine or a Path step joining several pieces, its first piece,
  /// whose World art stands for the Circle.
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
  /// a routine or Path step, its first piece.
  final ActivityId? replacedFrom;

  /// Why ("Not this one today"). Today's constraint, never a usefulness
  /// answer.
  final ReplacementReason? replacementReason;

  /// V2 Phase D: the routine or Path step today's Circle is, or `null` for
  /// a single activity the engine picked.
  final TodaySession? session;

  /// V2 Phase D: the routine or Path step replaced today, by name.
  final String? replacedFromTitle;
  final String? replacedFromRoutineId;

  /// Whether "Not this one today" is still available: once a day — for an
  /// activity, a routine or a Path step alike.
  bool get canReplace => replacedFrom == null;

  /// The session today's Circle runs: the activity as authored; for a
  /// routine or a joined Path step, its pieces one after the other on the
  /// Guided runtime (`sessionFor`); for a single-piece Path step, that
  /// piece's activity.
  ActivityDefinition get sessionDefinition {
    final uses = session?.composition.uses;
    if (uses == null) return activityDefinition(activityId);
    if (uses.length == 1) return uses.single.definition.activity;
    // Running, a Path step goes by its Path's name ("Step 1 of 6 · A lift
    // at home"): the pieces' joined title is already the step heading's
    // job, and would wrap beneath it (S25 finding).
    return sessionFor(
      session!.composition,
      title: session!.pathName ?? session!.title,
    );
  }

  /// What this offer records in the Circle journal.
  CircleOffer get journalOffer => CircleOffer(
    timeWindow: timeWindow.name,
    offeredMinutes: offeredMinutes,
    reasonCode: reason.name,
    replacedFrom: replacedFrom,
    replacementReason: replacementReason?.name,
    session:
        session?.toRecord(
          replacedFromTitle: replacedFromTitle,
          replacedFromRoutineId: replacedFromRoutineId,
        ) ??
        (replacedFromTitle == null
            ? null
            : CircleSessionRecord(
                title: activity,
                replacedFromTitle: replacedFromTitle,
                replacedFromRoutineId: replacedFromRoutineId,
              )),
  );
}

/// V2 Phase D: today's routine or Path step — what it is made of, and
/// where it comes from. Persisted with today's Circle so a restart restores
/// exactly what was offered.
class TodaySession {
  const TodaySession({
    required this.composition,
    required this.title,
    this.planned,
    this.routineId,
    this.routineVersionId,
    this.routineVersionNumber,
    this.pathRunId,
    this.pathKind,
    this.pathName,
    this.pathCircle,
    this.pathCircles,
    this.pathReason,
    this.pathExplanation,
  });

  /// What today's Circle runs.
  final Composition composition;

  /// A Path step's own pieces, before today's time made it shorter.
  final Composition? planned;

  final String title;

  final String? routineId;
  final String? routineVersionId;
  final int? routineVersionNumber;

  final String? pathRunId;
  final PathKind? pathKind;
  final String? pathName;
  final int? pathCircle;
  final int? pathCircles;
  final PathStepReason? pathReason;

  /// The Path step's one line ("Now the two together.").
  final String? pathExplanation;

  bool get isPath => pathRunId != null;
  bool get isRoutine => routineId != null;

  CircleSessionRecord toRecord({
    String? replacedFromTitle,
    String? replacedFromRoutineId,
  }) => CircleSessionRecord(
    title: title,
    modules: composition.toWire(),
    routineId: routineId,
    routineVersionId: routineVersionId,
    routineVersionNumber: routineVersionNumber,
    pathRunId: pathRunId,
    pathKind: pathKind?.name,
    pathName: pathName,
    pathCircle: pathCircle,
    pathCircles: pathCircles,
    pathReason: pathReason?.name,
    replacedFromTitle: replacedFromTitle,
    replacedFromRoutineId: replacedFromRoutineId,
  );

  Map<String, Object?> toJson() => {
    'modules': composition.toWire(),
    'planned': planned?.toWire(),
    'title': title,
    'routineId': routineId,
    'routineVersionId': routineVersionId,
    'routineVersionNumber': routineVersionNumber,
    'pathRunId': pathRunId,
    'pathKind': pathKind?.name,
    'pathName': pathName,
    'pathCircle': pathCircle,
    'pathCircles': pathCircles,
    'pathReason': pathReason?.name,
    'pathExplanation': pathExplanation,
  };

  static TodaySession? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final composition = Composition.fromWire(raw['modules']);
    final title = raw['title'];
    if (composition == null || title is! String) return null;
    String? text(String key) => raw[key] is String ? raw[key] as String : null;
    int? number(String key) => raw[key] is int ? raw[key] as int : null;
    final pathRunId = text('pathRunId');
    final pathReason = PathStepReason.values.asNameMap()[raw['pathReason']];
    // A Path step is only restored whole.
    if (pathRunId != null && pathReason == null) return null;
    return TodaySession(
      composition: composition,
      planned: Composition.fromWire(raw['planned']),
      title: title,
      routineId: text('routineId'),
      routineVersionId: text('routineVersionId'),
      routineVersionNumber: number('routineVersionNumber'),
      pathRunId: pathRunId,
      pathKind: PathKind.values.asNameMap()[raw['pathKind']],
      pathName: text('pathName'),
      pathCircle: number('pathCircle'),
      pathCircles: number('pathCircles'),
      pathReason: pathReason,
      pathExplanation: text('pathExplanation'),
    );
  }
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

/// V2 Phase D: today's routine or Path step ([TodaySession]), as JSON —
/// absent for a single activity.
const recommendationSessionKey = 'recommendation_session';

/// V2 Phase D: the routine or Path step replaced today, by name and (for a
/// routine) id.
const recommendationReplacedTitleKey = 'recommendation_replaced_title';
const recommendationReplacedRoutineKey = 'recommendation_replaced_routine';

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
  /// **V2 Phase D:**
  /// - A Path under way whose need is today's need claims today's Circle —
  ///   only with Premium, only when its next step's pieces are all still
  ///   allowed, and only at a truthful length that fits today's time (its
  ///   own, or its truly shorter form). Otherwise the Path waits, untouched,
  ///   and the engine decides as on any day.
  /// - The engine weighs the user's enabled routines as ordinary candidates
  ///   — whatever Premium's state: routines stay the user's.
  void chooseIntention(Intention intention, {TimeWindow? window}) {
    if (state.recommendation != null) return;

    final now = ref.read(nowProvider);
    final today = dateKey(now);
    final TimeWindow chosen = ref.read(timeWindowChoiceProvider);
    final timeWindow = window ?? chosen;

    final pathStep = _pathStepToday(intention, timeWindow, today);
    final Recommendation recommendation;
    if (pathStep != null) {
      recommendation = pathStep;
    } else {
      final decision = recommend(
        RecommendationContext(
          date: now,
          need: intention,
          window: timeWindow,
          allowSafetyPending: ref.read(safetyPendingAllowedProvider),
          routines: ref.read(routineCandidatesProvider),
        ),
        ref.read(toolkitHistoryProvider),
        controls: ref.read(suggestionPreferencesProvider).controls,
      );
      if (decision == null) {
        // V2 Phase C: the user's own "Don't suggest" choices leave nothing
        // that fits. Say so; never override them.
        state = RecommendationState(
          recommendation: null,
          status: RecommendationStatus.notStarted,
          noCandidateFor: (intention, timeWindow),
        );
        return;
      }
      recommendation = _fromDecision(intention, decision, today, timeWindow);
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

  /// Today's Path step, when the Path under way may claim today (see
  /// [chooseIntention]) — else `null`.
  Recommendation? _pathStepToday(
    Intention intention,
    TimeWindow window,
    String today,
  ) {
    final toolkit = ref.read(toolkitProvider);
    final run = toolkit.path;
    if (run == null || run.finished || run.need != intention) return null;
    // Progressing a Path is Premium: without it, the Path is saved, waiting.
    if (!ref.read(premiumEntitlementProvider)) return null;
    final base = run.routineId == null
        ? null
        : toolkit.routineById(run.routineId!)?.versionById(run.baseVersionId!);
    if (run.kind != PathKind.build && base == null) return null;
    final resting = ref.read(pathRestingProvider);
    final step = nextPathStep(
      run,
      ref.read(pathAnswersProvider),
      base: base,
      resting: resting,
    );
    if (step == null) return null;
    if (!stepAllowed(
      step,
      intention,
      controls: ref.read(suggestionPreferencesProvider).controls,
      allowSafetyPending: ref.read(safetyPendingAllowedProvider),
      resting: resting,
    )) {
      return null;
    }
    final fit = fitToWindow(step, window);
    if (fit == null) return null;
    final composition = fit.composition;
    // What the user told THIRTY outranks the time line: a step that changed
    // because of an answer says so even on a shorter day — the offered
    // length on the card already shows it is shorter (S25 finding, D-D).
    final explanation = fit.reason == step.reason || step.reason.fromAnswers
        ? step.explanation
        : pathStepExplanation(fit.reason, combined: composition.combined);
    final routine = run.routineId == null
        ? null
        : toolkit.routineById(run.routineId!);
    return _buildRecommendation(
      intention,
      composition.anchor,
      today,
      window: window,
      offeredMinutes: composition.minutes,
      reason: RecommendationReason.pathStep,
      session: TodaySession(
        composition: composition,
        planned: step.composition,
        title: composition.combined
            ? composition.title
            : composition.uses.single.definition.activity.title,
        pathRunId: run.id,
        pathKind: run.kind,
        pathName: switch (run.kind) {
          PathKind.build => pathTemplate(run.template!).name,
          PathKind.tuneUp => 'Tuning ${routine?.name ?? 'a routine'}',
          PathKind.shorter => 'Shortening ${routine?.name ?? 'a routine'}',
        },
        pathCircle: step.number,
        pathCircles: run.length,
        pathReason: fit.reason,
        pathExplanation: explanation,
      ),
    );
  }

  /// The engine's [decision] as today's Circle: an activity, or one of the
  /// user's routines at the version that fits.
  Recommendation _fromDecision(
    Intention intention,
    RecommendationDecision decision,
    String circleId,
    TimeWindow window, {
    Recommendation? replacing,
    ReplacementReason? replacementReason,
  }) {
    final routineId = decision.routineId;
    final routine = routineId == null
        ? null
        : ref.read(toolkitProvider).routineById(routineId);
    final version = routine?.versionById(decision.routineVersionId ?? '');
    return _buildRecommendation(
      intention,
      decision.activityId,
      circleId,
      window: window,
      offeredMinutes: decision.offeredMinutes,
      reason: decision.reason,
      replacedFrom: replacing?.activityId,
      replacementReason: replacementReason,
      replacedFromTitle: replacing?.session?.title,
      replacedFromRoutineId: replacing?.session?.routineId,
      session: routine == null || version == null
          ? null
          : TodaySession(
              composition: version.composition,
              title: routine.name,
              routineId: routine.id,
              routineVersionId: version.id,
              routineVersionNumber: version.number,
            ),
    );
  }

  /// "Not this one today" (V2 Phase B): re-selects today's activity once,
  /// under [reason] as a hard constraint for today. Returns `false` — and
  /// changes nothing — unless today's Circle is offered but not yet
  /// started and has not been replaced already; or if nothing else fits
  /// [reason] today.
  ///
  /// The reason is never a usefulness answer. The journal records the final
  /// activity, the one it replaced and why, so a restart restores the
  /// replacement and never offers a second one.
  ///
  /// **V2 Phase D:** a routine or a Path step is replaced the same way, by
  /// the engine — never by another Path step. A replaced Path step doesn't
  /// count: the Path waits where it was.
  bool replaceToday(ReplacementReason reason) {
    final current = state.recommendation;
    if (current == null || !current.canReplace) return false;
    if (state.status != RecommendationStatus.notStarted) return false;

    final now = ref.read(nowProvider);
    final decision = recommend(
      RecommendationContext(
        date: now,
        need: current.intention,
        window: current.timeWindow,
        replacement: ReplacementRequest(
          reason: reason,
          replacing: current.activityId,
          replacingMinutes: current.offeredMinutes,
          replacingRoutineId: current.session?.routineId,
          replacingComponents: current.session?.composition.activities ?? [],
        ),
        allowSafetyPending: ref.read(safetyPendingAllowedProvider),
        routines: ref.read(routineCandidatesProvider),
      ),
      ref.read(toolkitHistoryProvider),
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
    state = state.copyWith(
      status: RecommendationStatus.closed,
      closedAt: closedAt,
    );
    final snapshot = state;
    _enqueue(() => _persist(snapshot));
    // Fired only on a real transition, for the same reason start() above
    // only fires once per Circle — this is also the frozen post-fix
    // measurement protocol's "Daily Check-In completed" (see
    // AnalyticsEventType.circleClosed's own doc comment).
    ref.read(analyticsServiceProvider).track(AnalyticsEventType.circleClosed);

    // V2 Phase D: a real Close of today's Path step counts it — once (the
    // guard clauses above make a repeat close a no-op). Close moves the
    // Path on; it never says the step was done.
    final session = recommendation.session;
    if (session != null && session.isPath && session.pathReason != null) {
      ref
          .read(toolkitProvider.notifier)
          .recordPathCircle(
            runId: session.pathRunId!,
            circleId: recommendation.circleId,
            composition: session.composition,
            planned: session.planned ?? session.composition,
            reason: session.pathReason!,
          );
    }
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
  /// date [today] — or, with [session], today's routine or Path step.
  Recommendation _buildRecommendation(
    Intention intention,
    ActivityId activityId,
    String today, {
    TimeWindow window = TimeWindow.firstUse,
    int? offeredMinutes,
    RecommendationReason reason = RecommendationReason.bestFit,
    ActivityId? replacedFrom,
    ReplacementReason? replacementReason,
    TodaySession? session,
    String? replacedFromTitle,
    String? replacedFromRoutineId,
  }) {
    final minutes =
        offeredMinutes ??
        session?.composition.minutes ??
        activityTypicalMinutes(activityId);
    return Recommendation(
      intent: intentionLabel(intention),
      activity: session?.title ?? activityLabel(activityId),
      duration: '$minutes minutes',
      why: switch (session) {
        null => activityReasonFor(intention, activityId),
        TodaySession(:final pathExplanation?) => pathExplanation,
        final routine => _piecesLine(routine.composition),
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
      session: session,
      replacedFromTitle: replacedFromTitle,
      replacedFromRoutineId: replacedFromRoutineId,
    );
  }

  /// "Standing stretch, then Move to music."
  static String _piecesLine(Composition composition) {
    final names = [for (final use in composition.uses) use.definition.name];
    final line = [
      names.first,
      for (final name in names.skip(1))
        '${name[0].toLowerCase()}${name.substring(1)}',
    ].join(', then ');
    return '$line.';
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
  /// **V2 Phase D:** today's routine or Path step is restored from its own
  /// key exactly as offered — even if the routine has since been renamed or
  /// changed. An unreadable one restores the plain activity (its first
  /// piece) rather than nothing.
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

    TodaySession? session;
    final rawSession = prefs.getString(recommendationSessionKey);
    if (rawSession != null) {
      try {
        session = TodaySession.fromJson(jsonDecode(rawSession));
      } catch (_) {
        session = null;
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
      session: session,
      replacedFromTitle: prefs.getString(recommendationReplacedTitleKey),
      replacedFromRoutineId: prefs.getString(recommendationReplacedRoutineKey),
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
    final session = recommendation.session;
    if (session != null) {
      await prefs.setString(
        recommendationSessionKey,
        jsonEncode(session.toJson()),
      );
    } else {
      await prefs.remove(recommendationSessionKey);
    }
    final replacedTitle = recommendation.replacedFromTitle;
    if (replacedTitle != null) {
      await prefs.setString(recommendationReplacedTitleKey, replacedTitle);
    } else {
      await prefs.remove(recommendationReplacedTitleKey);
    }
    final replacedRoutine = recommendation.replacedFromRoutineId;
    if (replacedRoutine != null) {
      await prefs.setString(recommendationReplacedRoutineKey, replacedRoutine);
    } else {
      await prefs.remove(recommendationReplacedRoutineKey);
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

    if (recommendation == null) return;
    // See _persistChoice's matching comment — this read also happens after
    // several await points.
    if (!ref.mounted) return;
    final journal = ref.read(circleJournalRepositoryProvider);
    final circleId = recommendation.circleId;
    final direction = recommendation.intention;
    final activityId = recommendation.activityId;
    final offer = recommendation.journalOffer;

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
/// answers, routine or Path step) and the selection history drawn from past
/// Circles. "Delete Circle history" removes these together with the
/// journal (`../presentation/widgets/journal_data_controls.dart`), then
/// invalidates [recommendationProvider] so today is re-derived from the
/// empty store. Preferences, the first-breath flag and the Toolkit are not
/// Circle history and are left alone.
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
/// **V2 Phase D:** a Circle of one of [routines] is that routine's evidence,
/// never the evidence of the activities in it; so is a Path Circle of the
/// very pieces a version of it was built from. A Circle that joined several
/// pieces lists them all, so recency sees each one.
List<PastCircle> pastCirclesFrom(
  Iterable<CircleJournalEntry> entries, {
  List<Routine> routines = const [],
}) => [
  for (final entry in entries)
    if (DateTime.tryParse(entry.localDate) case final date?)
      _pastCircle(entry, date, routines),
];

PastCircle _pastCircle(
  CircleJournalEntry entry,
  DateTime date,
  List<Routine> routines,
) {
  final session = entry.session;
  final uses = [
    for (final m in session?.modules ?? const []) ?ModuleUse.fromWire(m),
  ];
  var routineId = session?.routineId;
  var routineVersionId = session?.routineVersionId;
  final pathRunId = session?.pathRunId;
  if (routineId == null && pathRunId != null && uses.isNotEmpty) {
    // A Path Circle of the very pieces a version was built from: the
    // version of exactly that form first (a full and a shorter version share
    // their pieces), else the earliest of those pieces.
    final ran = Composition(uses);
    RoutineVersion? sameForm;
    RoutineVersion? samePieces;
    String? owner;
    for (final routine in routines) {
      for (final version in routine.versions) {
        if (version.pathRunId != pathRunId) continue;
        final modules = version.composition.modules;
        if (modules.length != ran.modules.length ||
            !modules.containsAll(ran.modules)) {
          continue;
        }
        owner = routine.id;
        if (version.composition == ran) sameForm ??= version;
        samePieces ??= version;
      }
    }
    if (owner != null) {
      routineId = owner;
      routineVersionId = (sameForm ?? samePieces)!.id;
    }
  }
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
    routineId: routineId,
    routineVersionId: routineVersionId,
    pathRunId: pathRunId,
    components: uses.length > 1
        ? [for (final use in uses) use.definition.source]
        : const [],
    replacedFromRoutineId: session?.replacedFromRoutineId,
  );
}
