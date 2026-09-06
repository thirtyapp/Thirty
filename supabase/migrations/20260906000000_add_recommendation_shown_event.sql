-- THIRTY — Batch 2 recommendation diversity: extend the existing
-- analytics_events.event_type CHECK constraint with one new value.
--
-- Scope of this exception: same narrow analytics sink introduced by
-- 20260905000000_create_analytics_events.sql (see that migration's own
-- header, docs/product/adr/ADR-011-batch-1-post-fix-retention-cohort.md,
-- and docs/product/adr/ADR-012-batch-2-recommendation-diversity.md). This
-- does not broaden Supabase into a general application data layer — it
-- only lets the same insert-only table record one additional, already-
-- narrow event type. No new table, no new column, no new access pattern.
--
-- Rollback: recreate the original constraint —
-- alter table public.analytics_events drop constraint analytics_events_event_type_check;
-- alter table public.analytics_events add constraint analytics_events_event_type_check
--   check (event_type in ('app_opened', 'circle_started', 'circle_closed'));
-- (Supabase CLI migrations are forward-only by convention — there is no
-- paired "down" migration file.)

alter table public.analytics_events
  drop constraint analytics_events_event_type_check;

alter table public.analytics_events
  add constraint analytics_events_event_type_check
  check (event_type in (
    'app_opened', 'circle_started', 'circle_closed', 'recommendation_shown'
  ));
