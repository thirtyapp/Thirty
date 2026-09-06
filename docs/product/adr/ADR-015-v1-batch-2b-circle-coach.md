# ADR-015 — V1 Productization Batch 2B / Minimum Circle Coach

**Status:** Accepted

## Context

Batch 2A (ADR-014) shipped three five-stage Circle Plans, their forward-
cursor/one-off-revisit/cycle state, and the daily Plan-vs-Free resolution
rule. The controlling frozen document
[`RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md`](../RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md)
(§36) specifies **Batch 2B: minimum Coach** as the next V1 productization
step — six bounded contextual situation families and the two explicit
application types they can trigger, using working Plan state and optional
local reports. Insights (2C) and billing remain explicitly deferred; this
batch ships only the primitives Insights will later call.

The Coach is not a chatbot, not runtime AI, not free-text coaching, not a
second recommendation engine, and never chooses between multiple specific
activities. It is a bounded deterministic guidance layer that explains or
exposes controls over how an already-permitted Session is approached.

## Decision

### 1. Six situation families (`lib/features/coach/domain/coach_family.dart`)

Exactly the frozen architecture's six bounded `CoachFamily` values:
`stageExplanation`, `lighterPacing`, `actionFeedback`, `resumption`,
`deliberateRevisit`, `cycleTransition`. No seventh family, no open-ended
template set.

### 2. Bounded priority policy (`lib/features/coach/domain/coach_engine.dart`)

`selectCoachCue` is a pure, deterministic function — no randomness, no
runtime AI, no mutation — that returns at most one `CoachCue` following
the frozen architecture's exact order (§7):

1. current explicit treatment/revisit context (`deliberateRevisit` or
   `lighterPacing`)
2. cycle transition (`cycleTransition`)
3. resumption after a qualifying 7+ local-calendar-day gap (`resumption`)
4. relevant recent explicit feedback (`actionFeedback`)
5. ordinary stage explanation (`stageExplanation`) — the fallback

Gap computation compares calendar dates only (`DateTime(y, m, d)`
truncation), never raw `Duration` hours, and is explicitly a display rule
— the resulting copy never counts days, claims inactivity, or implies a
health/fitness state. `"Not today"`/`"a little"` feedback is read exactly
as a truthful attempt-code report, never as motivation, exhaustion, or a
recovery need; a `null` attempt/usefulness value is UNKNOWN and never
triggers `actionFeedback`. A stale/unresolvable stage reference fails safe
to `null` (no cue) rather than fabricating one.

### 3. Two executable application types

**A. Plan-level lighter default** (`PlanProgress.lighterDefault`,
`lib/features/plans/domain/plan_state.dart`) — a new persistent boolean
per Plan, alongside the new `PlanTreatmentSource` enum
(`ordinaryDefault`/`directChoice`/`savedPreference`) that truthfully
records *why* a Session's treatment is what it is. `PlanNotifier.
setLighterDefaultForPlan` (`lib/features/plans/application/plan_provider.dart`)
sets it; a no-op if already at the requested value. `resolveSessionFor`
now seeds a freshly resolved Session's `PlanSessionAssignment.
initialTreatment`/`treatmentSource` from this saved value —
`PlanTreatment.lighter`/`PlanTreatmentSource.savedPreference` when set,
`PlanTreatment.standard`/`PlanTreatmentSource.ordinaryDefault` otherwise —
rather than the previous hardcoded `PlanTreatment.standard`. `repeatCycle`
carries the current `lighterDefault` value into the fresh cycle's
`PlanProgress` unchanged — repeat cycles inherit the current preference,
they never reset it. Never touches an already-resolved
`Recommendation` — only a later `resolveSessionFor` call reads the new
value.

**B. Queue a one-off revisit** — the existing Batch 2A
`PlanNotifier.queueRevisit`/`clearQueuedRevisit` primitive, unchanged.
Coach exposes it contextually (a shortcut button on the `actionFeedback`
cue) rather than duplicating it with new machinery, per this batch's
"expose, never invent" rule.

### 4. Current-Session override vs. saved default

`RecommendationNotifier.setPlanTreatment`
(`lib/features/home/application/recommendation_provider.dart`) always
records the resulting `Recommendation.treatmentSource` as
`PlanTreatmentSource.directChoice` — it is only ever called for an
explicit choice about *today's* Session, and never itself changes
`PlanProgress.lighterDefault`. A user may therefore choose standard
treatment for one Session without disturbing a saved lighter default, and
vice versa. The two persisted preferences (`recommendation_treatment` /
`recommendation_treatment_source`) mirror the in-memory `Recommendation`
fields exactly the way the Batch 2A treatment key already did.

### 5. Coach decision inputs (`lib/features/coach/application/coach_provider.dart`)

`coachCueProvider` (`Provider.family<CoachCue?, PlanId>`) only ever
produces a cue for the currently **active** Plan, gathered from three
explicit local sources: `PlanNotifier`'s state, today's Plan-resolved
`Recommendation` (if any), and the immediately preceding matching Plan
journal entry's truthful attempt/usefulness report and local date (via
`CircleJournalRepository.readAll()`, excluding today's own `circleId`).
No mood, wearable, location, or other inferred signal is read — only what
§7 of the frozen architecture permits.

### 6. Treatment-source journal field (`lib/features/home/application/circle_journal.dart`)

`CircleJournalEntry` gains one additive nullable `treatmentSource` field,
threaded through every `record*` method identically to the existing
`treatmentUsed` field — `null` for every pre-Batch-2B record and for every
Free-selector Circle. This is the durable evidence a future Insight needs
to distinguish an automatic application of an already-saved preference
from a genuine new user choice (§10 of this batch's governing prompt);
Batch 2B itself computes no aggregate or pattern from it.

### 7. Presentation (`lib/features/coach/presentation/widgets/coach_cue_banner.dart`)

`CoachCueBanner` renders the resolved cue's message as a quiet inline
sentence, plus — only when the resolved cue calls for it — a bounded
shortcut button to an *existing* control (`setPlanTreatment(lighter)` or
`queueRevisit()`), stacked vertically rather than side-by-side so the
labels remain legible at large text-scale settings without overflowing.
`PlanSessionPanel` renders it with `suppressStageExplanation: true` (its
own purpose/rationale text already covers that family, so repeating it
would be redundant); `PlanPathPage`'s `_PlanCard` renders it unsuppressed,
and only for the active Plan. Exposure telemetry
(`AnalyticsEventType.coachCueShown`) fires once per distinct family
transition via `ref.listen`, never on every rebuild.

A new `Switch.adaptive` in `PlanSessionPanel`, labelled "Use lighter
guidance as the default for this Plan" and announced via `Semantics(
toggled: ...)`, is the only control that writes
`setLighterDefaultForPlan`. `PlanPathPage`'s card additionally shows a
plain read-only line ("Lighter guidance is this Plan's default.") when
set, so the preference remains visible outside the daily Session too.

### 8. Analytics (`lib/core/analytics/analytics_event_type.dart`)

Three new bounded events — `coachCueShown`, `coachApplicationAccepted`,
`coachApplicationCleared` — carrying only `plan_id`/`family` or
`plan_id`/`application_type` metadata, never narrative text or journal
content. `coachApplicationAccepted`/`Cleared` fire from
`setLighterDefaultForPlan` (`application_type: 'lighter_default'`) and
from `queueRevisit`/`clearQueuedRevisit` (`application_type: 'revisit'`,
alongside the existing Batch 2A `planRevisitQueued` event, which measures
Plan-layer state rather than the Coach application itself). The Supabase
`analytics_events.event_type` CHECK constraint is widened by
`supabase/migrations/20260906030000_add_coach_events.sql`, following the
same narrow, insert-only pattern as every prior batch's own migration.
Analytics failure never blocks Coach behavior — every `track()` call sits
behind the same fire-and-forget discipline the rest of the app already
uses.

## Consequences

- The existing Free daily mechanic and every Batch 2A Plan behavior are
  unchanged for a non-entitled or non-Plan-resolved Circle — verified
  directly by the full pre-existing 371-test suite passing unmodified
  against this batch's code.
- `PlanProgress`/`PlanSessionAssignment`/`Recommendation`/
  `CircleJournalEntry`'s new fields are purely additive; every pre-Batch-
  2B persisted record decodes with `lighterDefault: false` /
  `treatmentSource: null`, exactly like Batch 2A's own fields decoded
  against pre-Batch-2A records.
- No Insights, billing, or Premium Atmosphere code exists in this batch.
  Pre-existing Premium Pass visual WIP
  (`thirty_progress_circle.dart`, `circle_hero.dart`,
  `crafted_circle_geometry.dart` and their tests, `docs/design/circle/`,
  `tool/generate_circle_geometry.dart`) is entirely untouched — this batch
  was implemented in an isolated worktree/branch created directly from
  canonical `origin/main`, never touching that WIP.
- Coach never issues a second activity and never changes `ActivityId`
  after a Circle's daily identity is resolved — every Coach mutation
  (`setLighterDefaultForPlan`, `queueRevisit`, `clearQueuedRevisit`,
  `setPlanTreatment`) only ever affects a future unresolved Circle or the
  current Circle's `treatmentUsed`/`treatmentSource`, never `activityId`.

## Related documents

- [RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md](../RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md) — the controlling frozen Premium document; authoritative above this ADR for Premium product scope
- [PREMIUM_STRATEGY.md](../PREMIUM_STRATEGY.md)
- [ADR-010 — Circle Closed Is Not Verified Activity Completion](ADR-010-circle-closed-not-completion.md)
- [ADR-014 — V1 Productization Batch 2A / Circle Plans + Guided Sessions](ADR-014-v1-batch-2a-circle-plans.md)
