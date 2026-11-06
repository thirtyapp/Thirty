import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/activity_category.dart';
import '../../../core/analytics/analytics_event_type.dart';
import '../../../core/analytics/analytics_service.dart';

import '../../../core/premium/entitlement_status.dart';
import '../../../core/premium/premium_access.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/storage/confirmed_write.dart';
import '../../../core/storage/store_save_failures.dart';
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
import 'circle_history_deletion.dart';
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

  /// An ordinary Free offer: decided without Premium — one activity, not a
  /// Premium day's fallback, not the user's own choice, not replaced. Once
  /// Premium is verified, the user may turn it into today's composed Circle
  /// (audit remediation R2, founder decision D1;
  /// [RecommendationNotifier.upgradeToday]).
  bool get isFreeDecision =>
      composed == null &&
      !composerFellBack &&
      reason != RecommendationReason.ownChoice &&
      replacedFrom == null &&
      retiredSession == null;

  /// The session today's Circle runs: the activity as authored, or a
  /// composed Circle's parts one after the other.
  ActivityDefinition get sessionDefinition {
    final composed = this.composed;
    if (composed != null) {
      return sessionForPlan(
        composed.plan,
        title: composed.title,
        wording: composed.wording,
      );
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

/// SharedPreferences key for [RecommendationState.reflectionFinished]
/// (R8.2, Astra R81-A06): `true` once the user has finished the closed
/// Circle's reflection; absent otherwise, as on every record written before
/// it — which then reads exactly as before, from the answers it holds.
/// Removing an answer later never removes it; a fresh day's choice and
/// Delete Circle history do.
const recommendationReflectionFinishedKey =
    'recommendation_reflection_finished';

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

/// Audit remediation R3 (J5): a write of today's keys that may not have
/// reached every key yet — the complete set of values it writes, as one JSON
/// record, saved before any of them and removed once all are. Reading today
/// ([build]) takes these values over the keys, so a write cut short by the
/// app stopping is read as written in full, never as a mix of two days or
/// two offers. The next write carries it forward.
const recommendationPendingWriteKey = 'recommendation_pending_write';

/// The values of [recommendationPendingWriteKey] (key → value; `null`
/// removes the key), or none.
Map<String, Object?> _pendingDayWrite(SharedPreferences prefs) {
  // R8.2 (Astra R81-A09): a value that isn't text is no record at all.
  final raw = prefs.get(recommendationPendingWriteKey);
  if (raw is! String) return const {};
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map<String, Object?> ? decoded : const {};
  } catch (_) {
    return const {};
  }
}

/// Today's keys as last written: a write in progress
/// ([recommendationPendingWriteKey]) over what is stored.
class _DayKeys {
  _DayKeys(this._prefs) : _pending = _pendingDayWrite(_prefs);

  final SharedPreferences _prefs;
  final Map<String, Object?> _pending;

  Object? _value(String key) =>
      _pending.containsKey(key) ? _pending[key] : _prefs.get(key);

  String? getString(String key) => switch (_value(key)) {
    final String value => value,
    _ => null,
  };

  int? getInt(String key) => switch (_value(key)) {
    final int value => value,
    _ => null,
  };

  bool? getBool(String key) => switch (_value(key)) {
    final bool value => value,
    _ => null,
  };

  List<String>? getStringList(String key) => switch (_value(key)) {
    final List<Object?> value => [
      for (final item in value)
        if (item is String) item,
    ],
    _ => null,
  };
}

/// How long after its Start (or, closed after midnight, its Close) a
/// Circle of the day before is still brought back when THIRTY is resumed or
/// restarted after midnight (audit remediation R8, Astra R7-A08 / Claude
/// F-1). **Frozen by founder decision D2 (2026-11-04;
/// PRODUCT_V2_CONTRACT, Circle V2 amendment 2026-11-04)**: real elapsed time
/// — `DateTime.difference`, correct across midnight and daylight-saving
/// changes — long enough for a Circle started late in the evening, paused
/// and finished after midnight; short enough that one abandoned in the
/// morning never holds the next day's Circle.
const midnightCarryOverLimit = Duration(hours: 6);

/// A write begun before Delete Circle history began: it stops here.
class _StaleWrite implements Exception {
  const _StaleWrite();
}

/// What "Use it today" did (V2 Phase D2, ADR-023 §8).
enum UseTodayResult {
  /// Today's Circle is now one of the user's kept Circles.
  used,

  /// Today's Circle has already started or closed: one Circle a day.
  alreadyStarted,

  /// Nothing by that id, or it can't be offered (turned off, a piece the
  /// user asked THIRTY not to suggest, or content that isn't offerable).
  unavailable,

  /// A Delete Circle history that didn't finish must be finished first
  /// (audit remediation R3): nothing changed.
  historyDeletionPending,
}

/// What "Make today's Circle" did (audit remediation R2, founder decision
/// D1).
enum UpgradeTodayResult {
  /// Today's Free offer is now the Circle THIRTY made for the same need and
  /// time.
  upgraded,

  /// No Circle could honestly be made for today's need and time: today's
  /// offer stays exactly as it was.
  noComposition,

  /// Nothing to make: Premium isn't verified active, or today's offer isn't
  /// an unstarted ordinary Free one.
  notAvailable,
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
    this.reflectionFinished = false,
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

  /// Whether "Your next Circle opens tomorrow." is true at [at]: this Circle
  /// is closed and [at] is still on its own day (its circle id). Past that
  /// day — closed after midnight, or a closed Circle still on show across
  /// it — the next Circle can already begin: never a longer wait.
  bool nextCircleIsTomorrowAt(DateTime at) =>
      status == RecommendationStatus.closed && isOnItsOwnDayAt(at);

  /// Whether [at] is still this Circle's own day (its circle id) — so a
  /// Close now leaves the next Circle for tomorrow.
  bool isOnItsOwnDayAt(DateTime at) => recommendation?.circleId == dateKey(at);

  /// The closed Circle's reflection is answered as far as it goes.
  bool get reflectionAnswered => switch (attemptResponse) {
    null => false,
    CircleAttemptResponse.notToday => true,
    _ => usefulnessResponse != null,
  };

  /// R8.2 (Astra R81-A06): the user finished this Circle's reflection —
  /// it was answered as far as it goes, once. A fact about what the user
  /// did, kept when they later remove an answer ([RecommendationNotifier
  /// .removeAnswer]), which is their right: removing feedback never hands
  /// the finished reflection back to them.
  final bool reflectionFinished;

  /// The reflection is done: finished once, or answered now.
  bool get reflectionDone => reflectionFinished || reflectionAnswered;

  /// Audit remediation R8 (Astra R7-A08, Claude F-1): at [now], this
  /// earlier day's Circle is still the user's to finish when THIRTY comes
  /// back after midnight — resumed or restarted, as when it stays in the
  /// foreground (R6b): one started within [midnightCarryOverLimit] and not
  /// yet closed, or one closed after its own day, within it, whose
  /// reflection isn't answered yet. A Circle left running long before is
  /// not brought back as running: it stays in History as started.
  bool carriesOverMidnightAt(DateTime now) => switch (status) {
    RecommendationStatus.started =>
      startedAt != null && now.difference(startedAt!) <= midnightCarryOverLimit,
    RecommendationStatus.closed =>
      closedAt != null &&
          !isOnItsOwnDayAt(closedAt!) &&
          !reflectionDone &&
          now.difference(closedAt!) <= midnightCarryOverLimit,
    RecommendationStatus.notStarted => false,
  };

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
    bool? reflectionFinished,
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
    reflectionFinished: reflectionFinished ?? this.reflectionFinished,
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
  ///
  /// Audit remediation R3 (J4): each write is begun under Delete Circle
  /// history's [HistoryWriteGate] — one begun before a deletion stops at its
  /// next step ([_ensureCurrent]); one begun during a deletion waits for it.
  Future<void> _writes = Future<void>.value();

  /// Billing's answer at each stage Circle's Start, by Circle (R8.1 RL-1):
  /// what its Plan record of the Start is written from — again, if that
  /// save failed and was taken back off the screen — never a later answer.
  final _startVerdicts = <String, EntitlementStatus>{};

  /// Today's offers the store has confirmed in the day keys, by Circle —
  /// as [_offerIdentity] (R8.2, founder decision B): what a Start needs on
  /// disk before the Circle is started.
  final _offersOnDisk = <String, String>{};

  /// The offer whose Start is waiting for it to be saved first (founder
  /// decision B): a second tap meanwhile does nothing.
  Recommendation? _startWaiting;

  /// Whether [build] has run: its first run reads what the store holds.
  var _built = false;

  ///
  /// Audit remediation R8 (Astra R7-A01): a write that fails is never
  /// silent. Each step reports its own failure where it happens — the day
  /// keys and History as this Circle not saved ([journalSaveStatusProvider]),
  /// a Plan credit as a Plans save not confirmed — and anything else that
  /// stops a write is reported here, for the Circle it was for. The queue
  /// itself carries on: the next write of the same Circle carries what
  /// didn't land ([_publish]).
  ///
  /// [forCircle] names the Circle the write is for — needed while [build]
  /// runs, when [state] can't be read yet; otherwise today's Circle.
  void _enqueue(Future<void> Function(int epoch) write, {String? forCircle}) {
    final gate = ref.read(historyWriteGateProvider);
    final epoch = gate.epoch;
    final circleId = forCircle ?? state.recommendation?.circleId;
    _writes = _writes
        .then((_) async {
          if (!gate.isCurrent(epoch)) return;
          await gate.settled;
          await write(epoch);
        })
        .catchError((Object error) {
          if (error is _StaleWrite ||
              error is JournalWriteRefused ||
              error is StorageWriteFailed ||
              circleId == null) {
            return;
          }
          _markUnsaved(circleId);
        });
    gate.track(epoch, _writes);
    unawaited(_writes);
  }

  /// [circleId]'s save didn't complete: the user is told
  /// ([JournalSaveFailureNotice]), never shown it as saved.
  void _markUnsaved(String circleId) {
    if (!ref.mounted) return;
    ref.read(journalSaveStatusProvider.notifier).record(circleId, saved: false);
  }

  /// Throws [_StaleWrite] once Delete Circle history has begun after the
  /// write begun under [epoch].
  void _ensureCurrent(int epoch) {
    if (!ref.mounted || !ref.read(historyWriteGateProvider).isCurrent(epoch)) {
      throw const _StaleWrite();
    }
  }

  /// Writes [values] (key → value; `null` removes the key) for today's
  /// Circle [circleId], as one publication (audit remediation R3, J5): the
  /// whole set is first saved as one record ([recommendationPendingWriteKey],
  /// with any earlier write still in it), then each key, then the record is
  /// removed. Cut short anywhere, today reads as either before or after it.
  ///
  /// Only today's choice ([newDay]) starts a session; anything else lands
  /// only on [circleId]'s own, never on another day's. The journal is kept
  /// by Circle, so the caller records it either way.
  ///
  /// **Audit remediation R8 (Astra R7-A01).** Every step is confirmed by the
  /// store ([writeConfirmed]): a write that throws or returns `false` is put
  /// back out of memory, the Circle is reported as not saved, and this
  /// throws [StorageWriteFailed]. Until every key has landed the record
  /// stays — on disk, once it was confirmed — so a restart, or the next
  /// write, reads and completes it; nothing else is written if the record
  /// itself wasn't confirmed. When today's choice never reached the disk,
  /// its day is published with the next write of the same Circle, so that
  /// write is never skipped while History moves on; another day's session
  /// is never written over.
  ///
  /// **R8 pre-commit gate (founder directive 2026-11-04).**
  /// - Another day's started or closed session is never written over until
  ///   History holds it, and its Plan credit is saved
  ///   ([_recordBeforeOverwrite]): an unresolved Close is never destroyed
  ///   by the next day's choice. If History still refuses, nothing is
  ///   written — the new day's Circle is reported not saved — and the
  ///   earlier session stays in the day keys for the next attempt.
  /// - Once every key has landed the Circle is durably saved. If only the
  ///   record's own removal fails, the record stays (pending retry): it
  ///   holds exactly the values now stored, so the next write removes it
  ///   and a restart reads the same Circle. That is never reported as "not
  ///   saved".
  ///
  /// **R8.2 (Astra R81-A03, Claude NEW-1).** What authorizes a stage
  /// Circle's publication is the Circle being written — [stage], the stage
  /// of the payload in [values] (or of today's choice carried with it) —
  /// never whichever Circle is on show when the write runs. Its served
  /// stage must be on disk first ([CirclePlansNotifier.confirmServed]).
  /// A write that publishes no stage Circle — a Start, Close or answer of a
  /// Circle already published — needs nothing more: once published, a
  /// stage Circle stays saveable whatever a later Plan action does to the
  /// Plan's last served record. A stage Circle whose served stage can't be
  /// confirmed is never saved, and is taken back ([_withdrawUnsaveable]).
  Future<void> _publish(
    int epoch, {
    required String circleId,
    required Map<String, Object?> values,
    bool newDay = false,
    PlanStageProvenance? stage,
  }) async {
    _ensureCurrent(epoch);
    final prefs = ref.read(sharedPreferencesProvider);
    final stored = _DayKeys(prefs).getString(recommendationDayKey);
    final carry = <String, Object?>{};
    PlanStageProvenance? carriedStage;
    if (!newDay && stored != circleId) {
      final current = state.recommendation;
      final unpublished =
          current != null &&
          current.circleId == circleId &&
          (stored == null || stored.compareTo(circleId) < 0);
      if (!unpublished) return;
      carry.addAll(_choiceValues(current));
      carriedStage = current.composed?.stage;
    }
    final all = {..._pendingDayWrite(prefs), ...carry, ...values};
    // The stage Circle this write publishes, if any: the payload's own, or
    // the carried choice's. A record of an earlier write in progress was
    // authorized when it was written.
    final publishing = values.containsKey(recommendationComposedKey)
        ? stage
        : carry.containsKey(recommendationComposedKey)
        ? carriedStage
        : null;
    try {
      // R8.1 RL-1: a stage Circle is saved only once the Plan state it was
      // composed from — its served stage — is on disk; never on a Plan
      // change still pending or one that failed.
      if (publishing != null) {
        try {
          await ref
              .read(circlePlansProvider.notifier)
              .confirmServed(publishing, circleId: circleId);
        } on StorageWriteFailed {
          _withdrawUnsaveable(circleId, publishing);
          rethrow;
        }
        _ensureCurrent(epoch);
      }
      if (stored != null && stored != circleId) {
        await _recordBeforeOverwrite(epoch, _DayKeys(prefs), stored);
      }
      await writeConfirmed(
        prefs,
        recommendationPendingWriteKey,
        jsonEncode(all),
      );
      for (final MapEntry(:key, :value) in all.entries) {
        _ensureCurrent(epoch);
        await writeConfirmed(prefs, key, value);
      }
      _ensureCurrent(epoch);
    } on StorageWriteFailed {
      _markUnsaved(circleId);
      rethrow;
    } on JournalWriteRefused {
      _markUnsaved(circleId);
      rethrow;
    }
    // Founder decision B: a choice carried with this write is on disk now.
    final carried = state.recommendation;
    if (carry.isNotEmpty && carried != null && carried.circleId == circleId) {
      _offersOnDisk[circleId] = _offerIdentity(carried);
    }
    // Every key is on disk: durably saved. The record's removal is cleanup —
    // retried by the next write if the store refuses it now.
    try {
      await writeConfirmed(prefs, recommendationPendingWriteKey, null);
    } on StorageWriteFailed {
      // Pending retry, not a failed save: the record equals what is stored.
    }
  }

  /// [circleId]'s stage Circle of [stage] can never be saved: the Plan
  /// state it was composed from didn't land, and is off the screen (R8.1
  /// RL-1). When it is still the Circle on show — offered, started or
  /// closed — it is taken back too, so no session runs that can't be saved
  /// (R8.2, Astra R81-A03): today's choice opens again, as after a restart,
  /// and the user has been told ([_markUnsaved]).
  ///
  /// Founder decision B (R8.2): only an offer not yet started. A Start
  /// waits for its offer to be saved ([start]), so a started Circle's own
  /// publication is always on disk, and nothing a Plan does later takes it
  /// back.
  void _withdrawUnsaveable(String circleId, PlanStageProvenance stage) {
    if (!ref.mounted) return;
    if (state.status != RecommendationStatus.notStarted) return;
    final shown = state.recommendation;
    final shownStage = shown?.composed?.stage;
    if (shown == null ||
        shown.circleId != circleId ||
        shownStage == null ||
        jsonEncode(shownStage.toJson()) != jsonEncode(stage.toJson())) {
      return;
    }
    _startVerdicts.remove(circleId);
    state = RecommendationState(
      recommendation: null,
      status: RecommendationStatus.notStarted,
    );
  }

  /// Before the day keys move to a new day, the session of [storedDay] they
  /// hold — when it was started or closed — is recorded in History and its
  /// Plan credited, once (R8 pre-commit gate). Throws when History or the
  /// Plans refuse, so the caller writes nothing over it. An offer never
  /// started is recorded by the ordinary catch-up ([_mirrorInJournal]).
  Future<void> _recordBeforeOverwrite(
    int epoch,
    _DayKeys prefs,
    String storedDay,
  ) async {
    final earlier = _restoredOn(prefs, storedDay);
    final recommendation = earlier.recommendation;
    if (recommendation == null ||
        earlier.status == RecommendationStatus.notStarted) {
      return;
    }
    final entry = _journalFor(
      epoch,
    ).readAll().where((e) => e.circleId == recommendation.circleId).firstOrNull;
    if (!_journalHolds(earlier, entry)) {
      await _recordInJournal(epoch, earlier);
    }
    _ensureCurrent(epoch);
    await _creditGuided(earlier);
  }

  /// Whether History's [entry] already holds [session]'s Start, Close and
  /// answers.
  static bool _journalHolds(
    RecommendationState session,
    CircleJournalEntry? entry,
  ) =>
      entry != null &&
      entry.startedAt != null &&
      (session.closedAt == null || entry.closedAt != null) &&
      (session.attemptResponse == null ||
          entry.attemptResponse == session.attemptResponse) &&
      (session.usefulnessResponse == null ||
          entry.usefulnessResponse == session.usefulnessResponse);

  /// The Circle journal, for one step of the write begun under [epoch] —
  /// checked first, so a write begun before Delete Circle history never
  /// re-creates a deleted record.
  CircleJournalRepository _journalFor(int epoch) {
    _ensureCurrent(epoch);
    return ref.read(circleJournalRepositoryProvider);
  }

  @override
  RecommendationState build() {
    final prefs = _DayKeys(ref.watch(sharedPreferencesProvider));
    final today = dateKey(ref.watch(nowProvider));
    final restored = _restoredOn(prefs, today);
    _startWaiting = null;
    // R8.2 (founder decision B): at the process's start the keys are what
    // the store holds — today's offer restored from them is on disk.
    if (!_built) {
      _built = true;
      if (restored.recommendation case final offer?) {
        _offersOnDisk[offer.circleId] = _offerIdentity(offer);
      }
    } else {
      // Later rebuilds — Delete Circle history clearing the keys, a new
      // day — only ever forget: an offer the keys no longer hold is never
      // taken as saved.
      final shown = restored.recommendation;
      _offersOnDisk.removeWhere(
        (circleId, identity) =>
            shown == null ||
            shown.circleId != circleId ||
            _offerIdentity(shown) != identity,
      );
    }
    _notePlanActions(restored);
    _mirrorInJournal(restored);
    // Audit remediation R3: a session of an earlier day, still the one
    // stored (a Close just before midnight, cut short), catches up too —
    // under its own day, never as today's.
    if (_earlierSession(prefs, today) case final earlier?) {
      _notePlanActions(earlier);
      _mirrorInJournal(earlier);
      // Audit remediation R8 (Astra R7-A08, Claude F-1): yesterday's Circle
      // still under way — running, or closed after midnight with its
      // reflection open — stays on show after a resume or a restart, on its
      // own day, until the user finishes it; then the new day opens. Never
      // one of an older day, and never one that wasn't started.
      if (restored.recommendation == null &&
          earlier.recommendation?.circleId == _dayBefore(today) &&
          earlier.carriesOverMidnightAt(ref.read(eventClockProvider)())) {
        return earlier;
      }
    }
    return restored;
  }

  /// The local date before [today] (`YYYY-MM-DD`).
  static String _dayBefore(String today) {
    final parts = today.split('-').map(int.parse).toList();
    return dateKey(DateTime(parts[0], parts[1], parts[2] - 1));
  }

  /// The session stored for a day before [today], when it was started or
  /// closed — read as that day's, exactly as stored; `null` otherwise. It is
  /// never today's Circle: only its own records catch up from it.
  RecommendationState? _earlierSession(_DayKeys prefs, String today) {
    final stored = prefs.getString(recommendationDayKey);
    if (stored == null || stored.compareTo(today) >= 0) return null;
    final earlier = _restoredOn(prefs, stored);
    return earlier.status == RecommendationStatus.notStarted ? null : earlier;
  }

  /// A closed stage Circle's credit to its Plan (ADR-024 B3), on the
  /// Circle's own day — once per Circle, as [CirclePlansNotifier.recordGuided]
  /// guarantees. Nothing for any other Circle.
  Future<void> _creditGuided(RecommendationState closed) {
    final recommendation = closed.recommendation;
    final composed = recommendation?.composed;
    final stage = composed?.stage;
    if (recommendation == null ||
        stage == null ||
        closed.status != RecommendationStatus.closed) {
      return Future<void>.value();
    }
    return ref
        .read(circlePlansProvider.notifier)
        .recordGuided(
          stage,
          circleId: recommendation.circleId,
          on: recommendation.circleId,
          parts: composed!.plan.toWire(),
          skipped: [for (final e in closed.skipped) e.name],
          startedAt: closed.startedAt,
          closedAt: closed.closedAt,
        );
  }

  /// R8.2 Plan lifecycle policy (founder directive, 2026-11-06): tells the
  /// Plans the moment the user started, or asked to close, a stage Circle
  /// ([CirclePlansNotifier.noteStarted],
  /// [CirclePlansNotifier.noteCloseRequested]) — at the action itself, or
  /// as restored after a restart — so a later Pause or Leave keeps the
  /// actual order of the two, however slow storage is.
  void _notePlanActions(RecommendationState session) {
    final circleId = session.recommendation?.circleId;
    if (circleId == null || session.recommendation?.composed?.stage == null) {
      return;
    }
    final plans = ref.read(circlePlansProvider.notifier);
    if (session.startedAt case final at?) plans.noteStarted(circleId, at);
    if (session.status == RecommendationStatus.closed) {
      if (session.closedAt case final at?) {
        plans.noteCloseRequested(circleId, at);
      }
    }
  }

  /// Whether a Delete Circle history that didn't finish is still waiting
  /// to be: no new Circle begins until it is (audit remediation R3).
  bool get _historyDeletionPending =>
      ref.read(circleHistoryDeletionProvider).isPending;

  /// Audit remediation R3: the journal says what today's keys say. Today's
  /// keys are published whole ([_publish]) and the journal after them, so
  /// the app stopping in between leaves the journal behind — never ahead.
  /// On restoring, it catches up from them: a Circle not yet started is
  /// named as offered (a replacement, or "Make today's Circle", that didn't
  /// reach History yet); one started or closed is recorded as such. Nothing
  /// is made up: no answer, Close or stage that today's keys don't hold.
  ///
  /// A closed stage Circle's Plan credit catches up the same way: the Close
  /// is saved first and the credit after it ([close]), so a durable Close
  /// is what the credit follows — never the other way round.
  void _mirrorInJournal(RecommendationState restored) {
    final recommendation = restored.recommendation;
    if (recommendation == null) return;
    final entry = ref
        .read(circleJournalRepositoryProvider)
        .readAll()
        .where((e) => e.circleId == recommendation.circleId)
        .firstOrNull;
    if (restored.status == RecommendationStatus.notStarted) {
      if (entry != null &&
          (entry.startedAt != null || _namesOffer(entry, recommendation))) {
        return;
      }
      // When it was first shown isn't kept outside the journal: now is the
      // closest honest estimate, as for a missing record at Start.
      final at = ref.read(eventClockProvider)();
      _enqueue((epoch) async {
        final journal = _journalFor(epoch);
        if (entry == null) {
          await journal.recordShown(
            circleId: recommendation.circleId,
            localDate: recommendation.circleId,
            direction: recommendation.intention,
            activityId: recommendation.activityId,
            shownAt: at,
            offer: recommendation.journalOffer,
          );
        } else {
          await journal.recordReplaced(
            circleId: recommendation.circleId,
            localDate: recommendation.circleId,
            direction: recommendation.intention,
            activityId: recommendation.activityId,
            replacedAt: at,
            offer: recommendation.journalOffer,
          );
        }
        if (ref.mounted) ref.invalidate(circleJournalRepositoryProvider);
      }, forCircle: recommendation.circleId);
      return;
    }
    final mirrored = _journalHolds(restored, entry);
    final stage = recommendation.composed?.stage;
    // R8.1 (Astra N01): credited means credited on disk — a credit only in
    // memory is caught up (written again) like a missing one.
    final credited =
        restored.status != RecommendationStatus.closed ||
        stage == null ||
        ref
            .read(circlePlansProvider.notifier)
            .isCreditedDurably(stage.planId, circleId: recommendation.circleId);
    if (mirrored && credited) return;
    _enqueue((epoch) async {
      if (!mirrored) await _recordInJournal(epoch, restored);
      _ensureCurrent(epoch);
      await _creditGuided(restored);
    }, forCircle: recommendation.circleId);
  }

  /// Whether [entry] names [recommendation]'s offer as History shows it.
  static bool _namesOffer(
    CircleJournalEntry entry,
    Recommendation recommendation,
  ) {
    final offer = recommendation.journalOffer;
    return entry.activityId == recommendation.activityId &&
        entry.offeredMinutes == offer.offeredMinutes &&
        entry.reasonCode == offer.reasonCode &&
        entry.timeWindow == offer.timeWindow &&
        (offer.replacedFrom == null ||
            entry.replacedFrom == offer.replacedFrom) &&
        (entry.session?.parts ?? const []).join(' ') ==
            (offer.session?.parts ?? const []).join(' ');
  }

  /// The session of [today] (a local date) as stored: the keys, read
  /// through any write in progress.
  RecommendationState _restoredOn(_DayKeys prefs, String today) {
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
    final storedStartedAt = _storedInstant(
      prefs.getString(recommendationStartedAtKey),
    );
    // V2 Phase C: the session runtime — a pause and a Guided position.
    final storedPausedAt = _storedInstant(
      prefs.getString(recommendationPausedAtKey),
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
        final storedClosedAt = _storedInstant(
          prefs.getString(recommendationClosedAtKey),
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
          reflectionFinished:
              prefs.getBool(recommendationReflectionFinishedKey) ?? false,
        );

      case RecommendationStatus.notStarted:
      case null:
        // Either an explicit (never actually written) "notStarted", or an
        // unrecognized/corrupt status string — both fail safe the same
        // way as a missing day-key.
        return fresh;
    }
  }

  /// A stored Start, Close or pause, read back as local time (R8.1, Astra
  /// N09 / Claude AUD-5). Written as a UTC instant ([_instantValue]), it is
  /// exactly the moment it happened — each 02:30 of an autumn clock change
  /// its own. An older value without an offset reads as before, as local
  /// time; its offset was never stored and is never guessed.
  static DateTime? _storedInstant(String? raw) =>
      DateTime.tryParse(raw ?? '')?.toLocal();

  /// [at] as stored: a UTC instant (R8.1, Astra N09 / Claude AUD-5).
  static String? _instantValue(DateTime? at) => at?.toUtc().toIso8601String();

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
    final now = _choiceTime();
    final today = dateKey(now);
    // R8.1 (Claude AUD-2): an earlier day's Circle still on show once it is
    // finished — closed, its reflection answered — no longer holds today's
    // choice, with or without a touch or a resume.
    if (state.recommendation != null && !_finishedEarlierDay(today)) return;
    // Audit remediation R3: never a Circle a pending deletion would erase.
    if (_historyDeletionPending) return;

    // An earlier day's Close that is saved but not yet credited counts
    // before today's Plan stage is chosen. Not confirmed here: the day's
    // publication waits for it ([_recordBeforeOverwrite]).
    final stored = _DayKeys(ref.read(sharedPreferencesProvider));
    if (_earlierSession(stored, today) case final earlier?) {
      _creditGuided(earlier).ignore();
    }
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
    final composed = premium
        ? _composeToday(
            ComposerContext(date: now, need: intention, window: timeWindow),
            history,
            preferences,
            circleId: today,
          )
        : null;
    if (composed != null) {
      recommendation = _fromComposed(intention, composed, today, timeWindow);
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
      (epoch) => _persistChoice(
        epoch,
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

  /// Whether the Circle on show is an earlier day's, finished: closed, and
  /// either closed on its own day or its reflection answered (R8.1, Claude
  /// AUD-2) — so the day [today] can begin. A running Circle, or one closed
  /// after midnight with its reflection still open, never is.
  bool _finishedEarlierDay(String today) {
    final shown = state.recommendation;
    final closedAt = state.closedAt;
    return shown != null &&
        shown.circleId.compareTo(today) < 0 &&
        state.status == RecommendationStatus.closed &&
        closedAt != null &&
        (state.reflectionDone || state.isOnItsOwnDayAt(closedAt));
  }

  /// When a choice is being made (audit remediation R8, Claude F-2): the
  /// real time — so "shown" is when it was — and the day it falls on. A
  /// screen reader, keyboard or switch brings no touch for the app to notice
  /// midnight by, so the cached day is never trusted past it.
  DateTime _choiceTime() {
    final cached = ref.read(nowProvider);
    final real = ref.read(eventClockProvider)();
    return real.isBefore(cached) ? cached : real;
  }

  /// Today's Premium composition for [context]: the active Circle Plan's
  /// stage first, when it steers today; otherwise the ordinary Personal
  /// Guided Circle — or `null` when no honest composition exists. The
  /// caller has already checked Premium.
  ///
  /// [circleId] is the Circle being composed (R8.1, Astra N08): a stage it
  /// follows is served under that Circle's own day.
  ComposedSession? _composeToday(
    ComposerContext context,
    List<PastCircle> history,
    SuggestionPreferences preferences, {
    required String circleId,
  }) {
    final planDay = ref
        .read(circlePlansProvider.notifier)
        .steerToday(
          context,
          history,
          controls: preferences.controls,
          leftOut: preferences.leftOut,
          circleId: circleId,
        );
    final stageCircle = planDay.circle;
    final composed =
        stageCircle ??
        composeCircle(
          context,
          history,
          controls: preferences.controls,
          leftOut: preferences.leftOut,
        );
    if (composed == null) return null;
    return ComposedSession(
      plan: composed.plan,
      basis: composed.basis,
      stage: stageCircle == null ? null : planDay.stage,
    );
  }

  /// "Make today's Circle" (audit remediation R2, founder decision D1):
  /// today's ordinary Free offer — decided before Premium was verified —
  /// becomes the Circle THIRTY makes for the same need and time, through
  /// the same composition a Premium choice gets ([_composeToday]). Only on
  /// the user's tap, only while Premium is verified active, and only before
  /// Start: never a second Circle, never a swap of something started,
  /// replaced, kept or already composed. Still one decision a day: once
  /// made, today's Circle is composed, so a repeat call is
  /// [UpgradeTodayResult.notAvailable]. When nothing honest can be made,
  /// today's offer stays exactly as it was.
  ///
  /// The journal keeps one record for today, now naming the composed
  /// Circle; it is no "Not this one today", so the day's one replacement
  /// is still there.
  UpgradeTodayResult upgradeToday() {
    final current = state.recommendation;
    if (current == null ||
        !current.isFreeDecision ||
        state.status != RecommendationStatus.notStarted ||
        !ref.read(premiumEntitlementProvider)) {
      return UpgradeTodayResult.notAvailable;
    }
    final now = ref.read(nowProvider);
    final composed = _composeToday(
      ComposerContext(
        date: now,
        need: current.intention,
        window: current.timeWindow,
      ),
      ref.read(pastCirclesProvider),
      ref.read(suggestionPreferencesProvider),
      circleId: current.circleId,
    );
    if (composed == null) return UpgradeTodayResult.noComposition;
    final upgraded = _fromComposed(
      current.intention,
      composed,
      current.circleId,
      current.timeWindow,
    );
    state = RecommendationState(
      recommendation: upgraded,
      status: RecommendationStatus.notStarted,
    );
    _enqueue((epoch) => _persistReplacement(epoch, upgraded, now));
    return UpgradeTodayResult.upgraded;
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
    // R8.2 (founder decision B): Start was tapped and waits for this
    // Circle to be saved — it isn't replaced meanwhile.
    if (identical(_startWaiting, current)) return false;

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
        _enqueue((epoch) => _persistReplacement(epoch, replacement, now));
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
    _enqueue((epoch) => _persistReplacement(epoch, replacement, now));
    return true;
  }

  /// Starts today's Circle. A no-op unless today's recommendation already
  /// exists and [RecommendationState.status] is currently
  /// [RecommendationStatus.notStarted] — calling this before
  /// [chooseIntention], or again while already started or closed, does
  /// nothing, and in particular never overwrites an already-recorded
  /// [RecommendationState.startedAt].
  void start() {
    final recommendation = state.recommendation;
    if (recommendation == null) return;
    if (state.status != RecommendationStatus.notStarted) return;
    // R8.1 (Astra N06): never a kept Circle whose words aren't its own.
    if (recommendation.composed?.wordingUnverified ?? false) return;
    // R6 final (founder decision 2026-11-03): one Circle a day — an offer
    // not started before local midnight is never started afterwards under
    // its day. Start opens the new day instead, and nothing starts; the
    // user then chooses today's Circle. Also reached by a screen reader's
    // activation, which brings no touch for the app's own check.
    if (recommendation.circleId != dateKey(ref.read(eventClockProvider)())) {
      ref.invalidate(nowProvider);
      return;
    }

    // R8.2 (founder decision B): a Start already waiting for its Circle to
    // be saved — a second tap — does nothing.
    if (identical(_startWaiting, recommendation)) return;
    final verdict = ref.read(entitlementStatusProvider);
    if (!_readyToStart(recommendation, verdict)) {
      _startOnceSaved(recommendation, verdict);
      return;
    }

    // A stage Circle's start is noted on its served evidence first
    // (CirclePlansNotifier.noteStart), and saved before the start itself.
    final noted = switch (recommendation.composed?.stage) {
      final stage? => () {
        _startVerdicts[recommendation.circleId] = verdict;
        return ref
            .read(circlePlansProvider.notifier)
            .noteStart(
              stage,
              circleId: recommendation.circleId,
              status: verdict,
            );
      }(),
      null => Future<void>.value(),
    };
    // Awaited by the Start's own write below, once the writes before it
    // have run; its failure is handled there, not lost meanwhile.
    noted.ignore();
    final startedAt = ref.read(eventClockProvider)();
    state = RecommendationState(
      recommendation: recommendation,
      status: RecommendationStatus.started,
      startedAt: startedAt,
    );
    _notePlanActions(state);
    final snapshot = state;
    _enqueue((epoch) async {
      // Audit remediation R8: a Start whose Plans evidence wasn't confirmed
      // is never saved without it (R2) — the Circle is reported not saved.
      try {
        await noted;
      } catch (_) {
        _markUnsaved(recommendation.circleId);
        rethrow;
      }
      await _persist(epoch, snapshot);
    });
    // Fired only on a real transition — the two guard clauses above already
    // make this method a no-op on a repeat call, so a double/duplicate
    // start() can never record a duplicate circleStarted event either
    // (Batch 1, Phase E instrumentation).
    ref.read(analyticsServiceProvider).track(AnalyticsEventType.circleStarted);
  }

  /// Whether [recommendation] can start at once (R8.2, founder decision B):
  /// its offer is on disk in the day keys ([_offersOnDisk]) and, for a
  /// stage Circle, its Plan's served record is on disk and already says
  /// what this Start records ([CirclePlansNotifier.startNeedsNoWrite]).
  bool _readyToStart(Recommendation recommendation, EntitlementStatus verdict) {
    if (_offersOnDisk[recommendation.circleId] !=
        _offerIdentity(recommendation)) {
      return false;
    }
    final stage = recommendation.composed?.stage;
    return stage == null ||
        ref
            .read(circlePlansProvider.notifier)
            .startNeedsNoWrite(
              stage,
              circleId: recommendation.circleId,
              status: verdict,
            );
  }

  /// The Start of a Circle that isn't saved yet (R8.2, founder decision
  /// B): the Circle stays as it is — not started — while, after the writes
  /// before it, its offer is saved (again, if that write failed) and, for
  /// a stage Circle, its Plan's record of the Start. Only once the store
  /// has confirmed both is it started, and its Start saved. If either is
  /// refused, it isn't started: nothing of the Start is recorded, the user
  /// is told ([_refuseStart]), and Start can simply be tapped again. A
  /// stage Circle whose served stage can't be saved is taken back, as
  /// before ([_withdrawUnsaveable]): today's choice opens again.
  ///
  /// A stage Circle's Start is noted on its served record at the tap
  /// itself, as before (R2): from that moment no credit is ever granted on
  /// billing's earlier answer — only the Circle's started state waits.
  void _startOnceSaved(Recommendation recommendation, EntitlementStatus verdict) {
    final circleId = recommendation.circleId;
    final stage = recommendation.composed?.stage;
    _startWaiting = recommendation;
    final toldBefore = ref.read(journalSaveStatusProvider)[circleId] == false;
    final noted = switch (stage) {
      final stage? => () {
        _startVerdicts[circleId] = verdict;
        return ref
            .read(circlePlansProvider.notifier)
            .noteStart(stage, circleId: circleId, status: verdict);
      }(),
      null => Future<void>.value(),
    };
    // Awaited below, once the writes before it have run.
    noted.ignore();
    _enqueue((epoch) async {
      try {
        if (_offersOnDisk[circleId] != _offerIdentity(recommendation)) {
          await _publish(
            epoch,
            circleId: circleId,
            newDay: true,
            values: _choiceValues(recommendation),
            stage: stage,
          );
          _offersOnDisk[circleId] = _offerIdentity(recommendation);
        }
        _ensureCurrent(epoch);
        await noted;
        _ensureCurrent(epoch);
      } catch (error) {
        if (identical(_startWaiting, recommendation)) _startWaiting = null;
        if (error is! _StaleWrite) _refuseStart(circleId, toldBefore);
        rethrow;
      }
      if (identical(_startWaiting, recommendation)) _startWaiting = null;
      // Replaced, taken back or already started meanwhile: nothing starts.
      if (!identical(state.recommendation, recommendation) ||
          state.status != RecommendationStatus.notStarted) {
        return;
      }
      state = RecommendationState(
        recommendation: recommendation,
        status: RecommendationStatus.started,
        startedAt: ref.read(eventClockProvider)(),
      );
      _notePlanActions(state);
      final snapshot = state;
      ref
          .read(analyticsServiceProvider)
          .track(AnalyticsEventType.circleStarted);
      ref.read(storeSaveFailuresProvider.notifier).saved(UserStore.todaysCircle);
      await _persist(epoch, snapshot);
    }, forCircle: circleId);
  }

  /// [circleId]'s Start was refused because what it needs couldn't be
  /// saved (founder decision B): the user is told once for each refusal —
  /// by History's own notice when this failure is what raised it
  /// ([_markUnsaved]; [toldBefore] says it was already showing for an
  /// earlier one), otherwise "This change couldn't be saved. Please try
  /// again."
  void _refuseStart(String circleId, bool toldBefore) {
    if (!ref.mounted) return;
    final toldNow = ref.read(journalSaveStatusProvider)[circleId] == false;
    ref
        .read(storeSaveFailuresProvider.notifier)
        .record(UserStore.todaysCircle, notify: toldBefore || !toldNow);
  }

  /// Pauses today's started Circle (V2 Phase C): its time stops until
  /// [resume]. A no-op unless started and running. Guided Circles pause on
  /// request; Paced ones also whenever the app leaves the foreground.
  void pause() {
    if (state.status != RecommendationStatus.started || state.isPaused) return;
    state = state.copyWith(pausedAt: ref.read(eventClockProvider)());
    final snapshot = state;
    _enqueue((epoch) => _persist(epoch, snapshot));
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
    _enqueue((epoch) => _persist(epoch, snapshot));
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
    _enqueue((epoch) => _persist(epoch, snapshot));
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
    _enqueue((epoch) => _persist(epoch, snapshot));
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
    _enqueue((epoch) => _persist(epoch, snapshot));
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
    // R8.2 (founder decision B): a Start tapped and still waiting for its
    // Circle to be saved counts as started here — never swapped meanwhile.
    if (state.status != RecommendationStatus.notStarted ||
        (_startWaiting != null &&
            identical(_startWaiting, state.recommendation))) {
      return UseTodayResult.alreadyStarted;
    }
    // Audit remediation R3: never a Circle a pending deletion would erase.
    if (_historyDeletionPending) return UseTodayResult.historyDeletionPending;
    final controls = ref.read(suggestionPreferencesProvider).controls;
    final now = _choiceTime();
    final today = dateKey(now);
    // An offer of an earlier day is never replaced under it: the kept
    // Circle is today's own choice (audit remediation R8, Claude F-2).
    final current = switch (state.recommendation) {
      final offered? when offered.circleId == today => offered,
      _ => null,
    };

    final kept = ref.read(keptCirclesProvider).keptById(keptCircleId);
    if (kept == null) return UseTodayResult.unavailable;
    final need = current?.intention ?? kept.need;
    // Audit remediation R4: a part no longer offered — retired, or awaiting
    // the safety review — is never run because it was saved.
    if (keptPartsNotOffered(kept, ref.read(partOfferableProvider)).isNotEmpty ||
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
        wording: kept.wording,
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
        (epoch) => _persistChoice(
          epoch,
          today: today,
          recommendation: chosen,
          shownAt: now,
        ),
      );
    } else {
      _enqueue((epoch) => _persistReplacement(epoch, chosen, now));
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
    _notePlanActions(state);
    final snapshot = state;
    // ADR-024 B3: a stage Circle started and now closed in THIRTY is
    // *guided* — never "done". The Plan moves on once for this Circle.
    // Audit remediation R3: credited once the Close itself is saved — the
    // credit follows a durable Close. Cut short in between, the next start
    // finds the Close and credits it then, on its own day
    // ([_mirrorInJournal]); cut short before, nothing was closed.
    _enqueue((epoch) async {
      await _persist(epoch, snapshot);
      _ensureCurrent(epoch);
      await _creditGuided(snapshot);
    });
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
    state = _finishing(
      state.copyWith(attemptResponse: response, clearUsefulness: !isAffirmative),
    );
    final snapshot = state;
    _enqueue((epoch) async {
      await _persist(epoch, snapshot);
      _openNewDayAfter(snapshot);
    });
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

    state = _finishing(state.copyWith(usefulnessResponse: response));
    final snapshot = state;
    _enqueue((epoch) async {
      await _persist(epoch, snapshot);
      _openNewDayAfter(snapshot);
    });
    ref
        .read(analyticsServiceProvider)
        .track(
          AnalyticsEventType.circleUsefulnessReported,
          metadata: {'response': response.wireName},
        );
  }

  /// Once [finished] — an earlier day's Circle, carried over, its
  /// reflection now answered and saved — is still the one on show, the new
  /// day opens (R8.1, Claude AUD-2): no resume or touch is needed, so a
  /// screen reader, keyboard or switch reaches today's choice too.
  void _openNewDayAfter(RecommendationState finished) {
    if (!ref.mounted || !finished.reflectionDone) return;
    final circleId = finished.recommendation?.circleId;
    final today = dateKey(ref.read(eventClockProvider)());
    if (circleId == null || circleId.compareTo(today) >= 0) return;
    if (state.recommendation?.circleId != circleId) return;
    ref.invalidate(nowProvider);
    ref.invalidateSelf();
  }

  /// [answered], marked finished once its reflection is answered as far as
  /// it goes (R8.2, Astra R81-A06) — and finished it stays.
  static RecommendationState _finishing(RecommendationState answered) =>
      answered.reflectionAnswered
      ? answered.copyWith(reflectionFinished: true)
      : answered;

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
    // R8.1 (Astra N03): the day's recovery keys are cleared first —
    // whichever day they hold — and History only once they are, so a
    // removed answer is never written back from them. Cut short before
    // History, the answer stays everywhere and the user is told.
    _enqueue((epoch) async {
      if (isToday) {
        await _persist(epoch, snapshot);
      } else {
        await _removeFromDayKeys(
          epoch,
          circleId,
          includingAttempt: includingAttempt,
        );
      }
      final changed = await _journalFor(
        epoch,
      ).removeAnswer(circleId, includingAttempt: includingAttempt);
      if (changed && ref.mounted) {
        ref.invalidate(circleJournalRepositoryProvider);
      }
    }, forCircle: circleId);
  }

  /// [circleId]'s answers removed from the day keys, when they hold that
  /// Circle — not on show, as on the next day before a new Circle is chosen
  /// (R8.1, Astra N03) — as one publication ([_publish]).
  Future<void> _removeFromDayKeys(
    int epoch,
    String circleId, {
    required bool includingAttempt,
  }) async {
    final keys = _DayKeys(ref.read(sharedPreferencesProvider));
    if (keys.getString(recommendationDayKey) != circleId) return;
    final values = <String, Object?>{
      if (keys.getString(recommendationUsefulnessResponseKey) != null)
        recommendationUsefulnessResponseKey: null,
      if (includingAttempt &&
          keys.getString(recommendationAttemptResponseKey) != null)
        recommendationAttemptResponseKey: null,
    };
    if (values.isEmpty) return;
    await _publish(epoch, circleId: circleId, values: values);
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
  Recommendation? _restoreRecommendation(_DayKeys prefs, String today) {
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
    if (composed != null && composed.isKept) {
      composed = _withKeptWording(composed);
      // R8.1 (Astra N06): a kept Circle whose words can't be shown to be its
      // own is never offered to run. Not started, today's choice is asked
      // again; the stored bytes stay as they were until a new choice.
      if (composed.wordingUnverified) {
        final status = RecommendationStatus.values
            .asNameMap()[prefs.getString(recommendationStatusKey)];
        if (status != RecommendationStatus.started &&
            status != RecommendationStatus.closed) {
          return null;
        }
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

  /// Today's kept Circle [composed] with its saved words as the kept Circle
  /// itself holds them (R8.1, Astra N06), when Today's copy of them is
  /// damaged or missing and the kept Circle is readable with the same
  /// parts: its own words, never today's catalogue's. Otherwise [composed]
  /// as it is — still unverified when its stored words were damaged.
  ComposedSession _withKeptWording(ComposedSession composed) {
    if (!composed.wordingUnverified && composed.wording != null) {
      return composed;
    }
    final kept = ref.read(keptCirclesProvider).keptById(composed.keptCircleId!);
    if (kept == null ||
        kept.wording == null ||
        jsonEncode(kept.plan.toWire()) != jsonEncode(composed.plan.toWire())) {
      return composed;
    }
    return composed.withWording(kept.wording);
  }

  /// Persists today's freshly-chosen [recommendation] alongside
  /// [RecommendationStatus.notStarted]. Any started/closed/attempt/
  /// usefulness values from an earlier day are explicitly cleared — a fresh
  /// choice must never inherit a stale session. Also records this Circle's
  /// "shown" journal entry (`circle_journal.dart`).
  ///
  /// Audit remediation R3 (J5): published as one write ([_publish]), so a
  /// new day cut short never shows the day before's Circle as today's.
  Future<void> _persistChoice(
    int epoch, {
    required String today,
    required Recommendation recommendation,
    required DateTime shownAt,
  }) async {
    final intention = recommendation.intention;
    final activityId = recommendation.activityId;
    await _publish(
      epoch,
      circleId: today,
      newDay: true,
      values: _choiceValues(recommendation),
      stage: recommendation.composed?.stage,
    );
    _offersOnDisk[today] = _offerIdentity(recommendation);

    await _journalFor(epoch).recordShown(
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
    // rebuild it. Mirrors the same invalidate-after-write Delete Circle
    // history does (`circle_history_deletion.dart`).
    if (ref.mounted) ref.invalidate(circleJournalRepositoryProvider);
  }

  /// [recommendation]'s offer as one comparable value (R8.2, founder
  /// decision B): which Circle, and everything about it the day keys hold.
  static String _offerIdentity(Recommendation recommendation) => jsonEncode([
    recommendation.circleId,
    recommendation.intention.name,
    recommendation.activityId.name,
    _offerValues(recommendation),
  ]);

  /// Today's freshly chosen [recommendation], not started, as the per-day
  /// keys: any started/closed/attempt/usefulness values of an earlier day
  /// cleared — a fresh choice never inherits a stale session.
  static Map<String, Object?> _choiceValues(Recommendation recommendation) => {
    recommendationDayKey: recommendation.circleId,
    recommendationIntentionKey: recommendation.intention.name,
    recommendationActivityIdKey: recommendation.activityId.name,
    recommendationStatusKey: RecommendationStatus.notStarted.name,
    recommendationStartedAtKey: null,
    recommendationClosedAtKey: null,
    recommendationAttemptResponseKey: null,
    recommendationUsefulnessResponseKey: null,
    recommendationReflectionFinishedKey: null,
    recommendationPausedAtKey: null,
    recommendationPausedMsKey: null,
    recommendationGuidedPositionKey: null,
    recommendationPartAnchorMsKey: null,
    recommendationSkippedKey: null,
    ..._offerValues(recommendation),
    // V1 selector history is retired: Engine V2 reads the journal.
    recommendationLastFamilyKey: null,
    for (final need in Intention.values)
      recommendationHistoryKeyFor(need): null,
  };

  /// Today's offer — time window, length, reason and any replacement — as
  /// the per-day keys [build] restores.
  static Map<String, Object?> _offerValues(Recommendation recommendation) {
    final replacedFrom = recommendation.replacedFrom;
    final replacementReason = recommendation.replacementReason;
    final replaced = replacedFrom != null && replacementReason != null;
    return {
      recommendationTimeWindowKey: recommendation.timeWindow.name,
      recommendationOfferedMinutesKey: recommendation.offeredMinutes,
      recommendationReasonKey: recommendation.reason.name,
      recommendationReplacedFromKey: replaced ? replacedFrom.name : null,
      recommendationReplacementReasonKey: replaced
          ? replacementReason.name
          : null,
      // Retired with Phase D's routines and Paths (ADR-024): never written.
      recommendationSessionKey: null,
      recommendationReplacedRoutineKey: null,
      recommendationComposedKey: switch (recommendation.composed) {
        final composed? => jsonEncode(composed.toJson()),
        null => null,
      },
      recommendationComposerFallbackKey: recommendation.composerFellBack
          ? true
          : null,
      recommendationReplacedTitleKey: recommendation.replacedFromTitle,
      // V1 Plan context is retired (V2 Phase D).
      for (final key in retiredPlanDayKeys) key: null,
    };
  }

  /// Persists today's replacement — or its upgrade, "Make today's Circle"
  /// — the per-day keys first (so a restart restores it and never offers a
  /// second), then the journal. One publication (audit remediation R3): cut
  /// short, today is the offer before it or the one after, never a mix.
  Future<void> _persistReplacement(
    int epoch,
    Recommendation replacement,
    DateTime replacedAt,
  ) async {
    await _publish(
      epoch,
      circleId: replacement.circleId,
      values: {
        recommendationActivityIdKey: replacement.activityId.name,
        ..._offerValues(replacement),
      },
      stage: replacement.composed?.stage,
    );
    _offersOnDisk[replacement.circleId] = _offerIdentity(replacement);
    await _journalFor(epoch).recordReplaced(
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
  ///
  /// Audit remediation R3: the day written is the Circle's own
  /// ([Recommendation.circleId]), never the clock's when the write runs, and
  /// the keys are one publication ([_publish]).
  ///
  /// R8.1 (Astra N04): a started or closed stage Circle is saved only once
  /// its Plan's record of the Start is on disk exactly as shown
  /// ([CirclePlansNotifier.confirmStartNoted]) — so no Close, pause or
  /// answer is ever saved over a Start whose evidence didn't land, and a
  /// restart can never credit what this session refused.
  Future<void> _persist(int epoch, RecommendationState state) async {
    final recommendation = state.recommendation;
    if (recommendation == null) return;
    final circleId = recommendation.circleId;
    final startedAt = state.startedAt;
    final closedAt = state.closedAt;
    final attemptResponse = state.attemptResponse;
    final usefulnessResponse = state.usefulnessResponse;
    final stage = recommendation.composed?.stage;
    if (stage != null && state.status != RecommendationStatus.notStarted) {
      final plans = ref.read(circlePlansProvider.notifier);
      final verdict = _startVerdicts[circleId];
      try {
        // Written from the Start's own billing answer when this session
        // started it (R8.1 RL-1); otherwise it was saved before a restart.
        // R8.2 (Claude NEW-1): this Circle's own record only.
        await (verdict != null
            ? plans.noteStart(stage, circleId: circleId, status: verdict)
            : plans.confirmStartNoted(stage, circleId: circleId));
      } on StorageWriteFailed {
        _markUnsaved(circleId);
        rethrow;
      }
      _ensureCurrent(epoch);
    }

    await _publish(
      epoch,
      circleId: circleId,
      values: {
        recommendationDayKey: circleId,
        recommendationStatusKey: state.status.name,
        recommendationStartedAtKey: ?_instantValue(startedAt),
        // A started (not yet closed) persist must never leave a stale
        // closedAt from an earlier day/session behind. build()'s `started`
        // restore branch already never reads this key regardless, but an
        // explicit clear keeps the persisted record itself honest, not just
        // the code path that happens to read it today.
        recommendationClosedAtKey: _instantValue(closedAt),
        recommendationAttemptResponseKey: attemptResponse?.name,
        recommendationUsefulnessResponseKey: usefulnessResponse?.name,
        recommendationReflectionFinishedKey: state.reflectionFinished
            ? true
            : null,
        // V2 Phase C: the session runtime, as timestamps and small state.
        recommendationPausedAtKey: _instantValue(state.pausedAt),
        recommendationPausedMsKey: state.pausedTotal > Duration.zero
            ? state.pausedTotal.inMilliseconds
            : null,
        recommendationGuidedPositionKey: state.guidedPosition > 0
            ? state.guidedPosition
            : null,
        recommendationPartAnchorMsKey: state.partAnchor > Duration.zero
            ? state.partAnchor.inMilliseconds
            : null,
        recommendationSkippedKey: state.skipped.isNotEmpty
            ? [for (final e in state.skipped) e.name]
            : null,
      },
    );
    await _recordInJournal(epoch, state);
  }

  /// The journal half of [_persist]: [state]'s lifecycle, skips and answers
  /// on its Circle's record.
  Future<void> _recordInJournal(int epoch, RecommendationState state) async {
    final recommendation = state.recommendation;
    if (recommendation == null) return;
    final circleId = recommendation.circleId;
    final startedAt = state.startedAt;
    final closedAt = state.closedAt;
    final attemptResponse = state.attemptResponse;
    final usefulnessResponse = state.usefulnessResponse;
    final direction = recommendation.intention;
    final activityId = recommendation.activityId;
    final offer = recommendation.journalOfferWith(skipped: state.skipped);

    var journalChanged = false;
    switch (state.status) {
      case RecommendationStatus.started:
        await _journalFor(epoch).recordStarted(
          circleId: circleId,
          localDate: circleId,
          direction: direction,
          activityId: activityId,
          startedAt: startedAt!,
          offer: offer,
        );
        journalChanged = true;
      case RecommendationStatus.closed:
        await _journalFor(epoch).recordClosed(
          circleId: circleId,
          localDate: circleId,
          direction: direction,
          activityId: activityId,
          closedAt: closedAt!,
          // Audit remediation R8 (Astra R7-A05): the Start this Close
          // follows, from the same durable session — so a record whose
          // Start never reached History gets it with its Close.
          startedAt: startedAt,
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
      await _journalFor(epoch).recordSkipped(
        circleId: circleId,
        skipped: [for (final e in state.skipped) e.name],
      );
      journalChanged = true;
    }
    if (attemptResponse != null) {
      await _journalFor(epoch).recordAttempt(
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
      await _journalFor(epoch).recordUsefulness(
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
/// answers and composed Circle, a write of them in progress, and the retired
/// Phase D keys) and the selection history drawn from past Circles. "Delete
/// Circle history" removes these together with the journal
/// (`circle_history_deletion.dart`), then invalidates
/// [recommendationProvider] so today is re-derived from the empty store.
/// Preferences, the first-breath flag and kept Circles are not Circle
/// history and are left alone.
///
/// Every removal is begun at once (audit remediation R3), so none of these
/// keys is still readable while another is awaited — and each must be
/// confirmed by the store (audit remediation R8, [writeConfirmed]).
Future<void> clearRecordedCircleState(SharedPreferences prefs) => Future.wait([
  for (final key in [
    recommendationPendingWriteKey,
    recommendationDayKey,
    recommendationIntentionKey,
    recommendationActivityIdKey,
    recommendationStatusKey,
    recommendationStartedAtKey,
    recommendationClosedAtKey,
    recommendationAttemptResponseKey,
    recommendationUsefulnessResponseKey,
    recommendationReflectionFinishedKey,
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
  ])
    writeConfirmed(prefs, key, null, restoreOnFailure: false),
]);

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
