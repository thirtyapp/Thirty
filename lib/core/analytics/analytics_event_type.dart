/// The three raw behavioural events Batch 1's instrumentation records —
/// deliberately the smallest set that can derive every metric the frozen
/// post-fix measurement protocol needs (see
/// `docs/product/adr/ADR-011-batch-1-post-fix-retention-cohort.md`):
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
enum AnalyticsEventType { appOpened, circleStarted, circleClosed }

/// The stable string this event is written as in `analytics_events.
/// event_type` — snake_case to match the Supabase table's own `CHECK`
/// constraint (`supabase/migrations/20260905000000_create_analytics_events.sql`),
/// deliberately not [AnalyticsEventType.name] (camelCase) so the raw table
/// reads naturally for manual inspection in Supabase Studio.
extension AnalyticsEventTypeWire on AnalyticsEventType {
  String get wireName => switch (this) {
    AnalyticsEventType.appOpened => 'app_opened',
    AnalyticsEventType.circleStarted => 'circle_started',
    AnalyticsEventType.circleClosed => 'circle_closed',
  };
}
