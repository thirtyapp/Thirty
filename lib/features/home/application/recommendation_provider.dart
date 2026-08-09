import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/activity_category.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import 'activity_catalog.dart';

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
/// today. Also the value [RecommendationNotifier.chooseIntention] reads
/// *before* overwriting it, on the day it detects a new day has started, to
/// identify "yesterday's" canonical activity for anti-repetition.
const recommendationActivityIdKey = 'recommendation_activity_id';

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
  }) : assert(
         recommendation != null ||
             (status == RecommendationStatus.notStarted &&
                 startedAt == null &&
                 closedAt == null),
         'A Circle must never be started or closed before today\'s '
         'recommendation exists.',
       );

  final Recommendation? recommendation;
  final RecommendationStatus status;

  /// When today's Circle was started. Null iff [status] is [notStarted].
  final DateTime? startedAt;

  /// When today's Circle was closed. Null iff [status] is not [closed].
  final DateTime? closedAt;
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
/// **Known limitation:** the day boundary is only re-evaluated when this
/// provider rebuilds (a fresh [nowProvider] read) — an app instance kept
/// open, uninterrupted, across local midnight will not itself notice the
/// calendar day changed until something causes a rebuild (e.g. the app
/// being backgrounded and resumed). No midnight timer or lifecycle
/// observer is introduced to close that gap in this pass.
class RecommendationNotifier extends Notifier<RecommendationState> {
  @override
  RecommendationState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final today = _dateKey(ref.watch(nowProvider));

    final freshNoRecommendation = RecommendationState(
      recommendation: null,
      status: RecommendationStatus.notStarted,
    );

    // No stored day, or a day that isn't today: nothing valid to restore
    // for *today* — yesterday's (or no) state is silently treated as
    // absent, not carried forward. It is left in SharedPreferences as-is;
    // chooseIntention() reads it back exactly once (for anti-repetition)
    // before overwriting it with today's values.
    if (prefs.getString(recommendationDayKey) != today) {
      return freshNoRecommendation;
    }

    final recommendation = _restoreRecommendation(prefs);
    // Same day, but no valid (intention, activityId) pair persisted yet —
    // the Daily Context Question hasn't been answered today. This also
    // fails safe the same way if the persisted pair is somehow corrupt.
    if (recommendation == null) {
      return freshNoRecommendation;
    }

    final fresh = RecommendationState(
      recommendation: recommendation,
      status: RecommendationStatus.notStarted,
    );

    final storedStatus = RecommendationStatus.values.asNameMap()[prefs
        .getString(recommendationStatusKey)];
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
        return RecommendationState(
          recommendation: recommendation,
          status: RecommendationStatus.closed,
          startedAt: storedStartedAt,
          closedAt: storedClosedAt,
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
  /// keyed on today's calendar day, and avoids repeating **the previous
  /// local calendar day's** canonical activity when another approved
  /// activity exists in the pool — the product rule is specifically "the
  /// previous local day," not "whenever THIRTY was last opened." That
  /// activity is read directly from whatever is still persisted under
  /// [recommendationActivityIdKey], but only when [recommendationDayKey]
  /// is exactly yesterday's date — a gap of two or more days (the app
  /// wasn't opened yesterday) leaves [previousActivityId] `null`, so
  /// anti-repetition simply doesn't apply, rather than treating stale,
  /// multi-day-old data as if it were yesterday's. No separate "previous
  /// day" key is kept beyond that one same/one-day-old read — matching the
  /// "no longer-term recommendation history" requirement.
  void chooseIntention(Intention intention) {
    if (state.recommendation != null) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final now = ref.read(nowProvider);
    final today = _dateKey(now);

    ActivityId? previousActivityId;
    final storedDay = prefs.getString(recommendationDayKey);
    if (storedDay != null && _isExactlyYesterday(storedDay, now)) {
      previousActivityId = ActivityId.values.asNameMap()[prefs.getString(
        recommendationActivityIdKey,
      )];
    }

    final activityId = selectActivityId(
      intention: intention,
      dayIndex: epochDay(now),
      previousActivityId: previousActivityId,
    );
    final recommendation = _buildRecommendation(intention, activityId);

    state = RecommendationState(
      recommendation: recommendation,
      status: RecommendationStatus.notStarted,
    );
    unawaited(_persistChoice(today, intention, activityId));
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
  }

  /// Closes today's Circle. A no-op unless [RecommendationState.status] is
  /// currently [RecommendationStatus.started] — calling this before a
  /// start, or again after already closed, does nothing, and in
  /// particular never overwrites an already-recorded
  /// [RecommendationState.closedAt]. [RecommendationState.startedAt] is
  /// carried over unchanged.
  ///
  /// Foundation-only in this pass: nothing in the product UI calls this
  /// yet — there is no Close Circle affordance until the Active experience
  /// this state machine is built for actually exists.
  void close() {
    if (state.recommendation == null) return;
    if (state.status != RecommendationStatus.started) return;

    final closedAt = ref.read(eventClockProvider)();
    state = RecommendationState(
      recommendation: state.recommendation,
      status: RecommendationStatus.closed,
      startedAt: state.startedAt,
      closedAt: closedAt,
    );
    unawaited(_persist(state));
  }

  /// Builds today's [Recommendation] from the approved catalog
  /// (`activity_catalog.dart`) for ([intention], [activityId]).
  Recommendation _buildRecommendation(
    Intention intention,
    ActivityId activityId,
  ) {
    return Recommendation(
      intent: intentionLabel(intention),
      activity: activityLabel(activityId),
      duration: '30 minutes',
      why: whyCopyFor(intention, activityId),
      category: activityCategory(activityId),
      activityId: activityId,
    );
  }

  /// Restores today's [Recommendation] from [prefs], or `null` if no valid
  /// (intention, activityId) pair is persisted — the caller has already
  /// confirmed the persisted day matches today.
  Recommendation? _restoreRecommendation(SharedPreferences prefs) {
    final intention = Intention.values.asNameMap()[prefs.getString(
      recommendationIntentionKey,
    )];
    final activityId = ActivityId.values.asNameMap()[prefs.getString(
      recommendationActivityIdKey,
    )];
    if (intention == null || activityId == null) return null;
    return _buildRecommendation(intention, activityId);
  }

  /// Persists [intention]/[activityId] as today's freshly-chosen
  /// recommendation, alongside [RecommendationStatus.notStarted]. Any
  /// started/closed timestamps from an earlier day are explicitly cleared —
  /// a fresh choice must never inherit a stale session.
  Future<void> _persistChoice(
    String today,
    Intention intention,
    ActivityId activityId,
  ) async {
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
  }

  /// Persists [state]'s lifecycle (status/timestamps) for today. Fired
  /// without being awaited by [start]/[close] so the in-memory [state]
  /// assignment above — and the rebuild it triggers — stays synchronous
  /// with the user's tap, exactly as before this pass; the write happens in
  /// the background afterward, same ordering trade-off already accepted by
  /// [`FirstBreathNotifier.markPlayedToday`](first_breath_provider.dart)'s
  /// own callers.
  Future<void> _persist(RecommendationState state) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final today = _dateKey(ref.read(nowProvider));

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
  }

  /// Whether [storedDayKey] (a `_dateKey`-shaped `YYYY-MM-DD` string) names
  /// the local calendar day immediately before [now]'s — i.e. exactly
  /// "yesterday," never "two or more days ago." Compared via
  /// [epochDay] (built on [DateTime.utc]) rather than a local-time
  /// [DateTime.difference], so this can't be perturbed by a daylight-saving
  /// transition landing between the two dates. An unparseable
  /// [storedDayKey] is never "yesterday."
  static bool _isExactlyYesterday(String storedDayKey, DateTime now) {
    final storedDate = DateTime.tryParse(storedDayKey);
    if (storedDate == null) return false;
    return epochDay(storedDate) == epochDay(now) - 1;
  }

  static String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

final recommendationProvider =
    NotifierProvider<RecommendationNotifier, RecommendationState>(
      RecommendationNotifier.new,
    );
