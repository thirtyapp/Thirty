-- THIRTY — Batch 2A (ADR-014): extend the existing
-- analytics_events.event_type CHECK constraint with five new values for
-- Circle Plans.
--
-- Scope of this exception: same narrow analytics sink introduced by
-- 20260905000000_create_analytics_events.sql and already extended by
-- 20260906000000_add_recommendation_shown_event.sql and
-- 20260906010000_add_action_report_events.sql (see those migrations' own
-- headers, and docs/product/adr/ADR-014-v1-batch-2a-circle-plans.md). This
-- does not broaden Supabase into a general application data layer — it
-- only lets the same insert-only table record five additional, already-
-- narrow event types (`plan_started`, `plan_session_shown`,
-- `plan_cycle_completed`, `plan_revisit_queued`, `plan_revisit_used`). No
-- new table, no new column, no new access pattern, and no Plan/journal
-- content is ever written here — only the same allowlisted `plan_id`/
-- `stage_id` metadata already described by `AnalyticsEventType`'s own doc
-- comments (`lib/core/analytics/analytics_event_type.dart`).
--
-- Rollback: recreate the previous constraint —
-- alter table public.analytics_events drop constraint analytics_events_event_type_check;
-- alter table public.analytics_events add constraint analytics_events_event_type_check
--   check (event_type in (
--     'app_opened', 'circle_started', 'circle_closed', 'recommendation_shown',
--     'circle_attempt_reported', 'circle_usefulness_reported'
--   ));
-- (Supabase CLI migrations are forward-only by convention — there is no
-- paired "down" migration file.)

alter table public.analytics_events
  drop constraint analytics_events_event_type_check;

alter table public.analytics_events
  add constraint analytics_events_event_type_check
  check (event_type in (
    'app_opened', 'circle_started', 'circle_closed', 'recommendation_shown',
    'circle_attempt_reported', 'circle_usefulness_reported',
    'plan_started', 'plan_session_shown', 'plan_cycle_completed',
    'plan_revisit_queued', 'plan_revisit_used'
  ));
