# Supabase — Batch 1 analytics exception

THIRTY has no Supabase data layer (AGENTS.md §5: "Geen Supabase-datalaag —
Supabase is verbonden maar wordt nog nergens gebruikt om data te lezen of
schrijven"). Circle state, recommendation state, the local Circle journal
(`docs/product/adr/ADR-013-v1-free-foundation-and-journal.md`), user
profiles, content, configuration, and remote control all remain local-only
(`SharedPreferences`).

**`migrations/20260905000000_create_analytics_events.sql` is one narrow,
explicitly authorised exception to that rule**, scoped only to Batch 1's
behavioural instrumentation (see
[`docs/product/adr/ADR-011-batch-1-post-fix-retention-cohort.md`](../docs/product/adr/ADR-011-batch-1-post-fix-retention-cohort.md)).
It does not authorize any broader Supabase data layer — that remains its
own, separate, future decision.

`migrations/20260906000000_add_recommendation_shown_event.sql` is Batch 2's
one additive change to that same table — it only widens the existing
`event_type` CHECK constraint to also allow `recommendation_shown` (see
[`docs/product/adr/ADR-012-batch-2-recommendation-diversity.md`](../docs/product/adr/ADR-012-batch-2-recommendation-diversity.md)).
No new table, column, or access pattern.

`migrations/20260906010000_add_action_report_events.sql` is Batch 1 / V1
Productization's additive change to the same table — it widens the same
`event_type` CHECK constraint again, to also allow
`circle_attempt_reported` and `circle_usefulness_reported` (see
[`docs/product/adr/ADR-013-v1-free-foundation-and-journal.md`](../docs/product/adr/ADR-013-v1-free-foundation-and-journal.md)).
Still no new table, column, or access pattern — and still no journal
content of any kind, only the same allowlisted `response` metadata.

## What it creates

One table, `public.analytics_events` — insert-only from the app, append-only,
no update/delete path at all. See the migration file itself for the exact
schema and the reasoning behind each column.

## Applying it

This repo does not use the Supabase CLI's local project scaffolding (no
`supabase/config.toml`). Apply each migration, in filename (date) order, by
pasting it into the target Supabase project's SQL editor (Dashboard → SQL
Editor → New query → Run):
`migrations/20260905000000_create_analytics_events.sql`, then
`migrations/20260906000000_add_recommendation_shown_event.sql`, then
`migrations/20260906010000_add_action_report_events.sql`.

## Rolling back

```sql
drop table if exists public.analytics_events;
```

Supabase CLI migrations are forward-only by convention — there is no paired
"down" migration file. Run the statement above directly against the
project, then remove the migration file from this repo.

## Reading the data

There is no read path from the app (RLS permits `insert` only for the
`anon` role — no `select`/`update`/`delete` policy exists at all). Analysis
happens by querying the table directly in the Supabase SQL editor or
Table Editor, using the project's own credentials — never the app's
publishable key.
