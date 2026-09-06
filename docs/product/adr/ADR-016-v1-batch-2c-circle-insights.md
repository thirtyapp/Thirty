# ADR-016 — V1 Productization Batch 2C / Minimum Circle Insights

**Status:** Accepted

## Context

Batch 2B (ADR-015) shipped the minimum Circle Coach — six bounded
situation families and the two explicit application types (Plan-level
lighter default, one-off revisit) — using working Plan state (ADR-014) and
the prospective local journal (ADR-013). The controlling frozen document
[`RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md`](../RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md)
(§9, §36) specifies **Batch 2C: minimum Circle Insights** as the final V1
productization step — three bounded observation/application families in
one compact "Your path" surface, using the journal and Plan/Coach
primitives that already exist. No new control system, no runtime AI, no
dashboard.

An Insight is a truthful observation paired with a useful application. It
is not a count, a chart, a streak, or unsupported personalization. The
user remains the decision-maker.

## Decision

### 1. Three bounded Insight families (`lib/features/insights/domain/insight_family.dart`)

Exactly the frozen architecture's three families:
`directionPathContinuity`, `chosenPacing`, `deliberateRevisits`. No fourth
family, no open-ended generator.

### 2. Evaluation policy (`lib/features/insights/domain/insight_engine.dart`)

`evaluateInsight` is a pure, deterministic function of `(journal,
plansState, now)` — no randomness, no internal clock read, no mutation. It
returns at most one `Insight`, checked in a fixed order (direction/path
continuity, then chosen pacing, then deliberate revisits) so the "at most
one observation and one application" rule holds by construction. This
ordering is a design choice, not specified numerically by the frozen
architecture: direction/path continuity is checked first because it is the
only family available without an active Plan or any reflections at all.

**Claim-specific evidence, one unified design gate.** A *pattern* claim
(chosen count, e.g. "5 recent Plan Circles") requires the frozen design
guardrail: at least 5 relevant records, across at least 3 distinct dates,
spanning at least 14 days, evaluated within the last 28 days
(`insightMinRecordCount`/`insightMinDistinctDates`/`insightMinSpanDays`/
`insightEvaluationWindowDays`). This gate is applied uniformly to all three
families' pattern claims — the frozen architecture's illustrative wording
("revisited stage 1 twice") is read as a style example for truthful
count/date phrasing, not as license to drop the gate for one family only;
applying it uniformly is the more conservative reading and keeps every
family's threshold inspectable and identical.

**One exemption:** `directionPathContinuity`'s plain current-place fact
("Clearer Head's Plan is saved at stage 3") needs no record count at all —
"a current-place observation is useful from the first saved Plan
transition" (frozen architecture §9). This is the only family with a
no-evidence fallback; `chosenPacing` and `deliberateRevisits` return no
Insight at all when their pattern gate is unmet.

**Load-bearing treatment-source distinction.** `chosenPacing` counts only
journal entries with `treatmentSource == 'directChoice'` — an automatic
application of an already-saved `PlanProgress.lighterDefault`
(`treatmentSource == 'savedPreference'`) never counts as a fresh
endorsement, however many times it recurs. Dedicated tests
(`test/features/insights/domain/insight_engine_test.dart`) exercise this
distinction directly.

**Usefulness denominators.** A usefulness-specific statement additionally
requires at least 3 relevant responses — a response following an
affirmative attempt (`yes`/`aLittle`) with a recorded usefulness rating.
`notToday` and a missing response are never counted; below 3, the
denominator/numerator are `null` and the sentence is simply omitted, never
shown as a misleadingly small count.

**Duplicate-application exclusion is evaluated inside the engine, not just
at render time:** `chosenPacing` returns no Insight once
`PlanProgress.lighterDefault` is already `true`; `deliberateRevisits`
returns no Insight once `PlanProgress.pendingRevisit` is already `true`;
`directionPathContinuity`'s pattern claim is skipped when its target
Plan is already active.

### 3. Snapshot model (`lib/features/insights/domain/insight_snapshot.dart`)

`InsightSnapshot` captures an evaluated `Insight`'s *identity* — family,
application type, target Plan/stage, evidence count/dates, usefulness
numerator/denominator, generated timestamp, and the rule/template version
that produced it. It deliberately does **not** freeze a stage number or an
"already applied" flag — anything that must "update immediately" per the
frozen architecture is instead recomputed live from current Plan state
(§4). At most `insightSnapshotMaxCount` (52) are retained, oldest dropped
first, in one versioned JSON blob (`insight_snapshots_v1`) — the same
single-key pattern `circle_journal.dart` and `plan_provider.dart` already
established. A single corrupt snapshot is dropped individually, mirroring
`CircleJournalEntry`'s own fail-safe read path.

### 4. Orchestration (`lib/features/insights/application/insight_provider.dart`)

`InsightNotifier.refreshIfDue()` re-assesses at most once per
`insightCadenceDays` (7) — "assess a new current Insight at most once per
seven-day interval when the user opens the relevant surface." Only a
*new* observation (family/target/evidence-count actually differing from
the latest retained snapshot) is appended as a fresh snapshot; an
unchanged re-assessment still advances `lastAssessedAt` without adding
history — "no invented novelty quota." `PlanPathPage` triggers this from
`initState`'s post-frame callback, never during `build`, since it may
write persisted state.

**Live recheck, decoupled from cadence.** `currentInsightProvider` (and
its underlying `liveInsightView`) recomputes the *displayed* Insight's
validity against the current `planProvider` state on every read — this is
what makes "the current Plan position updates immediately" and "a
factually invalid... Insight is withdrawn immediately" true regardless of
the 7-day cadence: cadence only gates when a *new* snapshot may be
appended to history, never how long a now-invalid application stays
displayed.

`InsightNotifier.applyCurrent()` rechecks the current snapshot's validity
immediately before executing anything — a stale application (state changed
elsewhere since assessment) is withdrawn, `insight_application_invalidated`
fires, and no Plan mutation happens. A valid application calls exactly one
existing Plan primitive (`activatePlan`, `setLighterDefaultForPlan`, or
`queueRevisit`) — Insights create no new control system.

### 5. Application adapter — exactly three targets

- `directionPathContinuity` → `PlanNotifier.activatePlan` (the same call
  whether the Plan was never started or is being resumed; only the button
  label differs).
- `chosenPacing` → `PlanNotifier.setLighterDefaultForPlan(planId, true)`.
- `deliberateRevisits` → `PlanNotifier.queueRevisit()`.

None of these ever touch `Recommendation`/today's resolved `activityId` —
by construction, since none of the three underlying primitives do
(ADR-014 §4, ADR-015 §7). Same-day identity is therefore preserved without
any additional guard in the Insights layer itself.

### 6. Presentation (`lib/features/insights/presentation/widgets/insight_card.dart`)

`InsightCard` renders at most one observation and one application inside
`PlanPathPage` ("Your path"), as the first item of its existing list — no
new route, no dashboard, no chart, no streak. Renders nothing
(`SizedBox.shrink()`) when there is no eligible or valid Insight. Wording
is composed from counts/dates/saved state only (frozen architecture §14) —
no causal, comparative, or health claim. A lightweight evidence line
("Based on 5 recorded visits between ... and ...") is shown only for a
pattern claim, never for the plain current-place fact. Exposure
(`insight_shown`) and invalidation (`insight_application_invalidated`)
telemetry fire from a `ref.listen` transition, exactly once per distinct
observation change — mirroring `coach_cue_banner.dart`'s own pattern.

### 7. Journal/history integration

Insight computation reads `CircleJournalRepository.readAll()` and
`PlanNotifier`'s state only — both already local, both already existing.
No new data is written to the journal by this batch. Deleting the local
Circle history (`circle_history_page.dart`'s "Delete all") now also calls
`InsightNotifier.clearAll()` — a derived observation must never outlive
the evidence it was drawn from ("stop derived personalization... remove
its dependent snapshots").

### 8. Analytics (`lib/core/analytics/analytics_event_type.dart`)

Three new bounded events — `insightShown`, `insightApplicationAccepted`,
`insightApplicationInvalidated` — carrying only `family`/`plan_id`/
`application_type` metadata, never narrative observation text, evidence
dates, or journal content. The Supabase `analytics_events.event_type`
CHECK constraint is widened by
`supabase/migrations/20260906040000_add_insight_events.sql`, following the
same narrow, insert-only pattern as every prior batch's migration.
Analytics failure never blocks Insight generation or application — every
`track()` call sits behind the same fire-and-forget discipline the rest of
the app already uses.

## Consequences

- The existing Free daily mechanic and every Batch 2A/2B Plan/Coach
  behavior are unchanged — verified directly by the full pre-existing
  415-test suite passing unmodified against this batch's code, now 460
  with this batch's own 45 new tests.
- No billing, Premium Atmosphere, or runtime AI code exists in this batch.
  Pre-existing Premium Pass visual WIP (`thirty_progress_circle.dart`,
  `circle_hero.dart`, `crafted_circle_geometry.dart` and their tests,
  `docs/design/circle/`, `tool/generate_circle_geometry.dart`) is entirely
  untouched — this batch was implemented in an isolated worktree/branch
  created directly from canonical `origin/main`, never touching that WIP.
- Insights never create a new control system: every application calls an
  existing Batch 2A/2B primitive, unchanged.

## Related documents

- [RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md](../RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md) — the controlling frozen Premium document; authoritative above this ADR for Premium product scope
- [PREMIUM_STRATEGY.md](../PREMIUM_STRATEGY.md)
- [ADR-010 — Circle Closed Is Not Verified Activity Completion](ADR-010-circle-closed-not-completion.md)
- [ADR-013 — V1 Productization Batch 1 / Free Foundation + Prospective Local Journal](ADR-013-v1-free-foundation-and-journal.md)
- [ADR-014 — V1 Productization Batch 2A / Circle Plans + Guided Sessions](ADR-014-v1-batch-2a-circle-plans.md)
- [ADR-015 — V1 Productization Batch 2B / Minimum Circle Coach](ADR-015-v1-batch-2b-circle-coach.md)
