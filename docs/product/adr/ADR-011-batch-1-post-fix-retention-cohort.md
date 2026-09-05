# ADR-011 — Batch 1 / Post-Fix Retention Cohort

**Status:** Accepted

## Context

Testers reported that closing today's Circle led to an ambiguous dead end:
nothing warned them the action was irreversible for the day, and the
resulting "Circle closed" disabled button read as broken rather than as an
intentional daily boundary. This is a known retention confound — it
contaminates any read on whether THIRTY's core loop itself is working.

Separately, THIRTY had no behavioural instrumentation at all: no way to
observe first use, Circle starts/closes, or return behaviour across
testers, and no way to distinguish testers who used THIRTY before this fix
from testers whose first exposure is already the fixed build.

## Decision

**"THIRTY — BATCH 1 / POST-FIX RETENTION COHORT"** ships as one narrowly
scoped release (`pubspec.yaml` `1.1.0+2`,
[`ReleaseInfo.appVersion`](../../../lib/core/config/release_info.dart)):

1. An explicit confirmation ("Close today's Circle?" / "You won't be able
   to reopen it until tomorrow.") before the irreversible Close Circle
   transition
   ([`CircleHero._confirmCloseCircle`](../../../lib/features/home/presentation/widgets/circle_hero.dart)).
2. A replacement for the ambiguous closed dead end: "Done for today" / "Your
   next Circle opens tomorrow." — no invented reset time, only the existing
   authoritative local-calendar-day reset already implemented by
   [`RecommendationNotifier`](../../../lib/features/home/application/recommendation_provider.dart).
3. A daily-reset correctness fix: [`nowProvider`](../../../lib/core/providers/clock_provider.dart)
   is invalidated on every app foreground resume
   ([`_ThirtyAppState`](../../../lib/core/app/thirty_app.dart)), so an app
   backgrounded overnight and reopened the next day correctly shows a fresh
   Circle instead of yesterday's stale lifecycle.
4. Minimal behavioural instrumentation
   (`lib/core/analytics/`) — see below.

Nothing about the core mechanic changes: the user still chooses a broad
intention and THIRTY still chooses exactly one activity. Recommendation
logic, content, onboarding, and visual identity are unchanged.

## Instrumentation (Phase E)

**Exception, explicitly scoped:** Supabase's `analytics_events` table
(`supabase/migrations/20260905000000_create_analytics_events.sql`,
`supabase/README.md`) is the one narrow, explicitly authorised exception to
"no Supabase data layer yet" (AGENTS.md §5). It does not authorize any
broader use of Supabase — Circle state, recommendation state, user
profiles, content, and configuration remain local-only. Reads only happen
via the Supabase dashboard/SQL editor; the app has insert-only access.

Three raw events are recorded
([`AnalyticsEventType`](../../../lib/core/analytics/analytics_event_type.dart)):
`app_opened` (cold start + every foreground resume), `circle_started`, and
`circle_closed` — the last of these is also the frozen measurement
protocol's "Daily Check-In completed." Per
[ADR-010](ADR-010-circle-closed-not-completion.md), this introduces no new
"Check-In" concept and is never treated as evidence the recommended
activity was actually done — it is the same existing, factual Circle Closed
event, only named for the measurement protocol's own vocabulary.

Every row also carries: a pseudonymous, locally-generated `tester_id`
([`TesterIdentityNotifier`](../../../lib/core/analytics/tester_identity_provider.dart) —
never a name, email, or account; THIRTY has none, ADR-006), the local
calendar date the event occurred on, the app/build version, and cohort
membership.

Naming discipline: nothing is ever labelled "install" — this app cannot
observe an actual install. The earliest `app_opened` row per tester is
"first observed app use," not "first install."

## Cohort integrity (Phase F)

Two cohorts: `PRE_FIX` and `POST_FIX_BATCH_1`. The rule is decided once per
device, the first time analytics ever runs on it (necessarily the device's
first launch of the Batch 1 build, since no analytics existed before it):

- If [`recommendationDayKey`](../../../lib/features/home/application/recommendation_provider.dart)
  or [`firstBreathLastPlayedDateKey`](../../../lib/features/home/application/first_breath_provider.dart)
  is already present in `SharedPreferences`, this device already used
  THIRTY before Batch 1 → `PRE_FIX`.
- Otherwise, this is the device's first-ever observed exposure to THIRTY,
  already on the Batch 1 build → `POST_FIX_BATCH_1`.

The result is persisted and never re-evaluated afterward — a later app
update cannot silently convert a tester's cohort, and a `PRE_FIX` tester's
historical events are never retroactively relabeled. This is the entire
rule: no experimentation framework, no server-side assignment, just one
local, one-time read of state that already existed before analytics did.

## Consequences

- The evaluation cohort for the frozen post-fix measurement protocol is
  `POST_FIX_BATCH_1` only; `PRE_FIX` testers are retained as
  historical/qualitative evidence, never pooled into the new threshold
  calculation.
- Any future Supabase usage beyond `analytics_events` requires its own ADR
  — this one does not open a general data layer.
- The user-visible areas this batch touches (Close Circle confirmation,
  post-close state, daily reset UX) are frozen for the `POST_FIX_BATCH_1`
  evaluation cohort until a later, explicit decision — see the Batch 1
  implementation report for the full frozen list.

## Related documents

- [ADR-006 — No Account Before First Value](ADR-006-no-account-before-first-value.md)
- [ADR-010 — Circle Closed Is Not Verified Activity Completion](ADR-010-circle-closed-not-completion.md)
- [`supabase/README.md`](../../../supabase/README.md)
