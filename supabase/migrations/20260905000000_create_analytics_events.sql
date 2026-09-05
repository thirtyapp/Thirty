-- THIRTY — Batch 1 behavioural instrumentation.
--
-- Scope of this exception: this migration exists ONLY to support the
-- frozen Batch 1 post-fix retention measurement (Close Circle confirmation
-- + post-close clarity — see
-- docs/product/adr/ADR-011-batch-1-post-fix-retention-cohort.md). It does
-- NOT authorize a general Supabase data layer. Circle application state,
-- recommendation state, user profiles, content, configuration, and remote
-- control all remain local-only (SharedPreferences) — see AGENTS.md §5.
-- Any future use of Supabase beyond this one append-only analytics surface
-- requires its own explicit, separate decision.
--
-- Rollback: drop table if exists public.analytics_events;
-- (Supabase CLI migrations are forward-only by convention — there is no
-- paired "down" migration file. To roll back, run the statement above
-- directly against the project, then remove this migration file.)

create table if not exists public.analytics_events (
  id bigint generated always as identity primary key,

  -- Pseudonymous, locally-generated per-device identifier
  -- (core/analytics/tester_identity_provider.dart) — never a name, email,
  -- or account. THIRTY has no accounts (ADR-006).
  tester_id text not null check (char_length(tester_id) between 1 and 100),

  -- The smallest raw event set Batch 1's measurement protocol needs — see
  -- core/analytics/analytics_event_type.dart's own doc comment for exactly
  -- what each derives and why there are only three.
  event_type text not null
    check (event_type in ('app_opened', 'circle_started', 'circle_closed')),

  -- The real moment the event happened on-device (event_clock, not a
  -- coarse build-time snapshot).
  occurred_at timestamptz not null,

  -- When this row reached Supabase — for auditability only, never used in
  -- place of occurred_at for any derived metric.
  received_at timestamptz not null default now(),

  -- The device's local calendar date (YYYY-MM-DD) occurred_at falls on —
  -- the same definition core/utils/date_key.dart uses everywhere else in
  -- the app. This is what "Circle/day identity" and distinct-day
  -- return/Check-In counts are derived from.
  local_date text not null check (local_date ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'),

  -- core/config/release_info.dart's ReleaseInfo.appVersion at the moment
  -- this event fired — every row is traceable to the exact build/version
  -- boundary it happened under.
  app_version text not null check (char_length(app_version) between 1 and 50),

  -- Decided once per device, never rewritten afterward — see
  -- core/analytics/tester_identity_provider.dart's own doc comment for the
  -- exact, auditable classification rule (Phase F, cohort integrity).
  cohort text not null check (cohort in ('PRE_FIX', 'POST_FIX_BATCH_1')),

  -- Optional, minimal, non-identifying context — never free text, never
  -- secrets/tokens. Nothing currently populates this; reserved for a
  -- narrow, later addition if a specific derived metric turns out to need
  -- it, not filled speculatively now.
  metadata jsonb
);

create index if not exists analytics_events_tester_id_idx
  on public.analytics_events (tester_id);
create index if not exists analytics_events_local_date_idx
  on public.analytics_events (local_date);
create index if not exists analytics_events_event_type_idx
  on public.analytics_events (event_type);

alter table public.analytics_events enable row level security;

-- Insert-only from the app's anon (publishable) key. No select/update/
-- delete policy exists for anon or authenticated, so RLS's default-deny
-- leaves this table unreadable and unmodifiable from client code — reads
-- happen only via the Supabase dashboard/SQL editor (service role, never
-- shipped in the app) for manual analysis of the Batch 1 cohort.
create policy "analytics_events_insert_anon"
  on public.analytics_events
  for insert
  to anon
  with check (true);
