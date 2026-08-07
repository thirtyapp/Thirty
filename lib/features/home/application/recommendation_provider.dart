import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/activity_category.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';

/// THIRTY's daily recommendation. Hardcoded for now — no ranking, no
/// personalization; see docs/product/decision-framework.md for how this
/// will eventually be chosen.
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
/// lifecycle state. [startedAt] and [closedAt] are session state, not
/// content — they describe *this run* of today's Circle, not the
/// recommendation itself, which is why they live here rather than on
/// [Recommendation].
class RecommendationState {
  const RecommendationState({
    required this.recommendation,
    required this.status,
    this.startedAt,
    this.closedAt,
  });

  final Recommendation recommendation;
  final RecommendationStatus status;

  /// When today's Circle was started. Null iff [status] is [notStarted].
  final DateTime? startedAt;

  /// When today's Circle was closed. Null iff [status] is not [closed].
  final DateTime? closedAt;
}

const _todaysRecommendation = Recommendation(
  intent: 'More Energy',
  activity: '30 minute walk',
  duration: '30 minutes',
  why: 'A calm walk to help you build energy for the rest of the day.',
  category: ActivityCategory.walking,
);

/// The smallest technical state machine behind today's Circle:
///
/// ```
/// notStarted --start()--> started --close()--> closed
/// ```
///
/// Both transitions are hard no-ops outside their one valid source state
/// (§ "Transition Contract") — calling [start] twice, or [close] before
/// [start], simply does nothing rather than throwing or silently
/// overwriting an already-recorded timestamp. Neither transition is
/// triggered by [Recommendation.duration]; nothing in this class reads
/// clock time to decide when to move between states — only [start] and
/// [close] do, and only because a caller invoked them.
///
/// [start]/[close] read [eventClockProvider], not [nowProvider], for
/// [RecommendationState.startedAt]/[RecommendationState.closedAt] — an
/// event timestamp must reflect the real moment of that call, which
/// [nowProvider]'s one-time-per-container-lifetime cached value cannot
/// guarantee (its own doc comment covers why). [build]'s calendar-day
/// check is the one place [nowProvider] remains the right tool: a coarse
/// "which day is it" comparison doesn't need per-call freshness.
///
/// State is scoped to one local calendar day, the same way
/// [`FirstBreathNotifier`](first_breath_provider.dart) scopes its own one
/// piece of state — [build] restores persisted status/timestamps only when
/// the persisted day-key matches today; anything from an earlier day is
/// treated as absent, and today then starts fresh at [notStarted]. There
/// is deliberately no repository/service layer around this, matching
/// [`FirstBreathNotifier`] and
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

    const fresh = RecommendationState(
      recommendation: _todaysRecommendation,
      status: RecommendationStatus.notStarted,
    );

    // No stored day, or a day that isn't today: nothing valid to restore
    // for *today* — yesterday's (or no) state is silently treated as
    // absent, not carried forward. It is left in SharedPreferences as-is;
    // the next start()/close() overwrites it with today's values.
    if (prefs.getString(recommendationDayKey) != today) {
      return fresh;
    }

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
          recommendation: _todaysRecommendation,
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
          recommendation: _todaysRecommendation,
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

  /// Starts today's Circle. A no-op unless [RecommendationState.status] is
  /// currently [RecommendationStatus.notStarted] — calling this again
  /// while already started or closed does nothing, and in particular never
  /// overwrites an already-recorded [RecommendationState.startedAt].
  void start() {
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

  /// Persists [state] for today. Fired without being awaited by [start]/
  /// [close] so the in-memory [state] assignment above — and the rebuild
  /// it triggers — stays synchronous with the user's tap, exactly as
  /// before this pass; the write happens in the background afterward,
  /// same ordering trade-off already accepted by
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
