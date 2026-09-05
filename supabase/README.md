# Supabase — Batch 1 analytics exception

THIRTY has no Supabase data layer (AGENTS.md §5: "Geen Supabase-datalaag —
Supabase is verbonden maar wordt nog nergens gebruikt om data te lezen of
schrijven"). Circle state, recommendation state, user profiles, content,
configuration, and remote control all remain local-only
(`SharedPreferences`).

**`migrations/20260905000000_create_analytics_events.sql` is one narrow,
explicitly authorised exception to that rule**, scoped only to Batch 1's
behavioural instrumentation (see
[`docs/product/adr/ADR-011-batch-1-post-fix-retention-cohort.md`](../docs/product/adr/ADR-011-batch-1-post-fix-retention-cohort.md)).
It does not authorize any broader Supabase data layer — that remains its
own, separate, future decision.

## What it creates

One table, `public.analytics_events` — insert-only from the app, append-only,
no update/delete path at all. See the migration file itself for the exact
schema and the reasoning behind each column.

## Applying it

This repo does not use the Supabase CLI's local project scaffolding (no
`supabase/config.toml`). Apply the migration by pasting
`migrations/20260905000000_create_analytics_events.sql` into the target
Supabase project's SQL editor (Dashboard → SQL Editor → New query → Run).

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
