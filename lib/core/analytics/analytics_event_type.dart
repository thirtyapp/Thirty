/// The raw behavioural events THIRTY's instrumentation records.
///
/// Batch 1 (see
/// `docs/product/adr/ADR-011-batch-1-post-fix-retention-cohort.md`)
/// introduced the smallest set that could derive every metric the frozen
/// post-fix measurement protocol needs:
///
/// - [appOpened] — fired on cold start and on every foreground resume.
///   The earliest [appOpened] row for a tester is their "first observed
///   app use" (never labelled "install" — this app cannot observe an
///   actual install). Every later distinct [wireName]'s `local_date`
///   value across *any* event type is what lets a second-distinct-day
///   return be derived.
/// - [circleStarted] — [RecommendationNotifier.start] actually running
///   (`recommendation_provider.dart`), never fired on a no-op call.
/// - [circleClosed] — [RecommendationNotifier.close] actually running.
///   This is also the frozen protocol's "Daily Check-In completed": per
///   ADR-010, Circle Closed is a factual app interaction only, never
///   evidence of the recommended activity actually being done — Batch 1
///   introduces no new "Check-In" concept, it only names this same
///   existing event for the measurement protocol's own vocabulary.
///
/// Batch 2 (see
/// `docs/product/adr/ADR-012-batch-2-recommendation-diversity.md`) adds one
/// event, to make recommendation exposure — not just Circle start/close —
/// observable:
///
/// - [recommendationShown] — [RecommendationNotifier.chooseIntention]
///   actually resolving today's recommendation, never fired on its no-op
///   early return. Carries `intention` and `activity_id` (both stable
///   identifiers, never display copy) as metadata — see
///   [SupabaseAnalyticsService.track]'s `metadata` parameter.
///
/// Batch 1 / V1 Productization (see
/// `docs/product/adr/ADR-013-v1-free-foundation-and-journal.md`) adds two
/// events for the optional action-report foundation — both fired only when
/// `RecommendationNotifier.reportAttempt`/`reportUsefulness` actually
/// records a response, never speculatively:
///
/// - [circleAttemptReported] — the user answered "Did you try this
///   activity?". Carries `response` (one of
///   [CircleAttemptResponse.wireName]'s values — `circle_journal.dart`) as
///   metadata. A response of `not_today` is a reported non-action, not a
///   failure; there being no event at all (no answer given) is UNKNOWN,
///   never inferred as either.
/// - [circleUsefulnessReported] — the user answered the optional
///   usefulness follow-up. Carries `response` (one of
///   [CircleUsefulnessResponse.wireName]'s values) as metadata. Purely
///   self-reported usefulness — never treated as a verified health or
///   wellbeing outcome.
enum AnalyticsEventType {
  appOpened,
  circleStarted,
  circleClosed,
  recommendationShown,
  circleAttemptReported,
  circleUsefulnessReported,
}

/// The stable string this event is written as in `analytics_events.
/// event_type` — snake_case to match the Supabase table's own `CHECK`
/// constraint (`supabase/migrations/20260905000000_create_analytics_events.sql`,
/// extended for [recommendationShown] by
/// `supabase/migrations/20260906000000_add_recommendation_shown_event.sql`,
/// and for [circleAttemptReported]/[circleUsefulnessReported] by
/// `supabase/migrations/20260906010000_add_action_report_events.sql`),
/// deliberately not [AnalyticsEventType.name] (camelCase) so the raw table
/// reads naturally for manual inspection in Supabase Studio.
extension AnalyticsEventTypeWire on AnalyticsEventType {
  String get wireName => switch (this) {
    AnalyticsEventType.appOpened => 'app_opened',
    AnalyticsEventType.circleStarted => 'circle_started',
    AnalyticsEventType.circleClosed => 'circle_closed',
    AnalyticsEventType.recommendationShown => 'recommendation_shown',
    AnalyticsEventType.circleAttemptReported => 'circle_attempt_reported',
    AnalyticsEventType.circleUsefulnessReported =>
      'circle_usefulness_reported',
  };
}
