-- THIRTY — Batch 1 / V1 Productization (ADR-013): extend the existing
-- analytics_events.event_type CHECK constraint with two new values for the
-- optional action-report foundation.
--
-- Scope of this exception: same narrow analytics sink introduced by
-- 20260905000000_create_analytics_events.sql and already extended once by
-- 20260906000000_add_recommendation_shown_event.sql (see that migration's
-- own header, docs/product/adr/ADR-011-batch-1-post-fix-retention-cohort.md,
-- ADR-012-batch-2-recommendation-diversity.md, and
-- ADR-013-v1-free-foundation-and-journal.md). This does not broaden
-- Supabase into a general application data layer — it only lets the same
-- insert-only table record two additional, already-narrow event types
-- (`circle_attempt_reported`, `circle_usefulness_reported`). No new table,
-- no new column, no new access pattern, and no journal/history content is
-- ever written here — only the same allowlisted `response` metadata already
-- described by `AnalyticsEventType.circleAttemptReported`/
-- `circleUsefulnessReported`'s own doc comments.
--
-- Rollback: recreate the previous constraint —
-- alter table public.analytics_events drop constraint analytics_events_event_type_check;
-- alter table public.analytics_events add constraint analytics_events_event_type_check
--   check (event_type in (
--     'app_opened', 'circle_started', 'circle_closed', 'recommendation_shown'
--   ));
-- (Supabase CLI migrations are forward-only by convention — there is no
-- paired "down" migration file.)

alter table public.analytics_events
  drop constraint analytics_events_event_type_check;

alter table public.analytics_events
  add constraint analytics_events_event_type_check
  check (event_type in (
    'app_opened', 'circle_started', 'circle_closed', 'recommendation_shown',
    'circle_attempt_reported', 'circle_usefulness_reported'
  ));
