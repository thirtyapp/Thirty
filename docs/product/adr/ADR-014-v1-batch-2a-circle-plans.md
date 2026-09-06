# ADR-014 — V1 Productization Batch 2A / Circle Plans + Guided Sessions

**Status:** Accepted

## Context

Batch 1 (ADR-013) shipped the Free foundation and the prospective local
Circle journal that Premium's later systems would need. The controlling
frozen document
[`RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md`](../RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md)
(§36) specifies **Batch 2A: Circle Plans and Sessions** as the next
V1 productization step — building the forward/revisit/cycle/pacing state
and daily integration for three five-stage Plans, using stable Free
`ActivityId`s and the existing journal. Coach (2B) and Insights (2C) are
explicitly deferred; this batch ships only the primitives those later
batches will call.

No billing, no RevenueCat integration, and no real subscription
entitlement exist yet ([PREMIUM_STRATEGY.md](../PREMIUM_STRATEGY.md),
[ADR-007](ADR-007-premium-never-blocks-the-core-loop.md)) — Circle Plans
therefore ship behind a dependency-injected access seam rather than any
production-reachable paywall.

## Decision

### 1. Frozen V1 Plan catalogue (`lib/features/plans/domain/plan_catalog.dart`)

Exactly **3 Plans × 5 authored stages = 15 stage definitions**, one Plan
per `Intention` (`PlanId.moreEnergyPath`/`clearerHeadPath`/
`gentlerPacePath`, aligned via `planDirection`). Every stage reuses an
existing, reviewed `ActivityId` from that Plan's own direction pool in
`activity_catalog.dart` — no new `ActivityId` value is introduced. Each
`PlanDefinition` carries a `version` and each `StageDefinition` a
`contentVersion`, both currently `planContentVersion = 1`.

Each Plan's five stages follow the frozen architecture's authored
sequence — establish → develop → apply → purposeful revisit →
consolidate — as a private authoring discipline, not a visible field or
UI label. Stage 4 (purposeful revisit) deliberately reuses stage 1's
`ActivityId` in every Plan: an explicit editorial callback to the path's
own starting practice, not a general pattern permitting arbitrary
duplication — the other four stages per Plan are mutually distinct
activities. Every stage carries `purpose`, `rationale`,
`standardGuidance`, and a genuinely distinct `lighterGuidance` for the
same `ActivityId`. Content is general-wellness/lifestyle guidance only:
no fitness, mental-health, or sleep/stress outcome is promised, and
nothing implies THIRTY has measured the user's physiological state
(`plan_catalog_test.dart`'s forbidden-phrase check).

### 2. Plan state model (`lib/features/plans/domain/plan_state.dart`)

`PlanProgress` keeps **forward progress and one-off revisit as
independent fields**: `forwardCursor` (0–4 = current stage index, 5 =
past stage 5/completed) and `pendingRevisit` (paired with
`lastEncounteredStageId`). No method ever derives one from the other —
this is the frozen architecture's explicit requirement that "a revisit
must never overwrite or corrupt the forward cursor." `lastAdvancedCircleId`
makes cursor advancement idempotent under a duplicated or corrupted
restore. `cycleHistory` (a list of `PlanCycleRecord`) is append-only,
preserving every prior cycle once repeated over.

`PlansState` holds one `PlanProgress` per `PlanId` at all times — "V1
supports ONE ACTIVE PLAN but preserve the saved state of all three
direction Plans locally" — plus the single `activePlanId`.

### 3. Plan orchestration (`lib/features/plans/application/plan_provider.dart`)

`PlanNotifier` persists all Plan state as one versioned JSON blob
(`plans_state_v1`), mirroring `circle_journal.dart`'s exact single-key
pattern. Restore is fail-safe **per Plan**: a missing, corrupt, or
content-version-incompatible entry, or a `lastEncounteredStageId` that no
longer resolves in the current catalogue, resets only that one Plan to a
fresh `PlanProgress` — never the other two, and never a fabricated stage.

- `activatePlan`/`deactivatePlan` switch which Plan is active without
  mutating any `PlanProgress`.
- `queueRevisit`/`clearQueuedRevisit` operate only on `pendingRevisit`.
- `repeatCycle` only runs once a cycle is `completed`; it appends the
  finished cycle to history, generates a new `cycleId`, and resets
  `forwardCursor` to 0.
- `resolveSessionFor(Intention)` is the sole daily-resolution entry point
  (see §4) — it returns `null` unless the user is entitled, a Plan is
  active, its direction matches, and its cycle is `inProgress`. A queued
  revisit takes priority and is consumed (cleared) at this call, without
  touching `forwardCursor`.
- `advanceCursorForCircle(planId, circleId, {isRevisit})` is the sole
  progression entry point (see §4). Idempotent per `circleId`. A
  revisit-sourced Circle never advances `forwardCursor`.

### 4. Daily integration (`lib/features/home/application/recommendation_provider.dart`)

`Recommendation` gains five additive nullable fields — `planId`,
`stageId`, `planCycleId`, `planVersion`, `treatmentUsed` — plus a
non-nullable `isPlanRevisit` (default `false`). All are `null`/`false`
for a Free-selector-resolved Circle; the existing Free path is otherwise
byte-for-byte unchanged.

`chooseIntention(intention)` — still a hard no-op once
`state.recommendation != null` — now calls
`PlanNotifier.resolveSessionFor(intention)` before falling through to
`selectActivityId`. A non-null result substitutes that Plan's assigned
`ActivityId`; `null` is the exact, unmodified Free path. **A Plan never
overrides the user's chosen `intention`** — it only ever supplies which
activity fulfils it, exactly as the frozen architecture requires.

`close()` — after its existing real-transition write — calls
`PlanNotifier.advanceCursorForCircle` only when
`recommendation.planId != null`, passing `recommendation.isPlanRevisit`
through unchanged. Because this sits behind `close()`'s own existing
no-op guards (only fires on `started → closed`), a duplicate `close()`
call can never advance the cursor twice — reinforced independently by
`advanceCursorForCircle`'s own `lastAdvancedCircleId` idempotency guard.

**Same-day identity freeze:** nothing about `activatePlan`,
`deactivatePlan`, `repeatCycle`, `queueRevisit`, or an entitlement change
ever calls `chooseIntention` — today's already-resolved `Recommendation`
is untouched by any of them, exactly like the existing "no reroll on
theme/foreground change" guarantee ADR-013 already relied on.

### 5. Treatment toggle

`RecommendationNotifier.setPlanTreatment(PlanTreatment)` is a no-op
outside a Plan-resolved Circle. It rebuilds `Recommendation` with a new
`treatmentUsed` value only — `activityId` and every identity field are
carried over unchanged. This is the frozen architecture's "lighter
guidance may alter HOW the same already-resolved activity is approached;
it may never substitute a new `ActivityId`."

### 6. Journal extension (`lib/features/home/application/circle_journal.dart`)

`CircleJournalEntry` gains five additive nullable fields: `planId`,
`planVersion`, `stageId`, `planCycleId`, `treatmentUsed`, plus nullable
`revisitUsed`. All `record*` methods on `CircleJournalRepository` gain the
same optional named parameters (default `null`), threaded through
`_upsert`. A synthesized (self-healing) entry carries them only when
supplied at creation; once set, a later `record*` call without them never
erases the entry's existing Plan identity (`CircleJournalEntry.copyWith`
preserves them by default). An old, pre-Batch-2A record with none of
these fields decodes exactly as before —
`circle_journal_test.dart`'s dedicated fixture test exercises this
directly. `circle_journal.dart` deliberately does not import
`features/plans/` (which itself depends on `activity_catalog.dart`) to
avoid an import cycle — Plan-field validity is `PlanNotifier`'s
responsibility, not the journal's.

### 7. Premium access seam (`lib/core/premium/premium_access.dart`)

```dart
final premiumEntitlementProvider = Provider<bool>((ref) => false);
```

Production default is unentitled. No code path overrides this to `true`
in a shipping build; tests and any future manual verification override it
via `ProviderScope`, the same dependency-injection pattern already used
for `sharedPreferencesProvider`. `HomePage`'s "Your path" AppBar icon
(→ `/plans`, `PlanPathPage`) only renders when this provider is `true` —
in production today, that is never. `PlanNotifier.resolveSessionFor` also
checks this provider independently, so even a forced direct navigation to
`/plans` can never produce a Plan-resolved Circle without entitlement.
This is **not** a paywall, **not** a fake local purchase record, and
**not** a persisted "isPremium" flag — it is the smallest DI seam a future
RevenueCat integration can replace without touching any calling code.

### 8. Presentation

`PlanSessionPanel` (`lib/features/plans/presentation/widgets/`) renders
beneath `CircleHero`/`ActionReportPrompt` only when today's Circle is
Plan-resolved: Plan name, "Stage N of 5", the stage's `purpose`/
`rationale`, and the Standard/Lighter toggle. `PlanPathPage`
(`lib/features/plans/presentation/`) lists all three Plans with
Activate/Resume, queue/clear revisit, and — only once a cycle is
`completed` — the plain "This guided cycle is finished." state with
Repeat/choose-another-direction (the latter is simply activating a
different Plan; no separate code path). Neither surface redesigns the
Circle or introduces a second daily activity choice.

`CircleHistoryPage`'s existing read-only entry card additionally shows one
bounded line — "Plan: \<name\>, stage N of 5 (cycle \<id\>)" — only for a
Plan-resolved entry, never for a Free-selector one. This remains a plain
factual record, not an activity browser or dashboard.

### 9. Analytics

Five new `AnalyticsEventType` values — `planStarted`, `planSessionShown`,
`planCycleCompleted`, `planRevisitQueued`, `planRevisitUsed` — carrying
only stable `plan_id`/`stage_id` metadata, fired exclusively from
`PlanNotifier`'s real-transition branches. `plan_session_shown` is
exposure only, never completion evidence (ADR-010 applies here exactly as
it does to `recommendationShown`). The Supabase `analytics_events`
`event_type` CHECK constraint is widened by
`supabase/migrations/20260906020000_add_circle_plan_events.sql`, following
the same narrow, insert-only pattern as ADR-013's own migration.

## Consequences

- The existing Free daily mechanic (one `Intention` → one deterministic
  `ActivityId`) is unchanged for every non-entitled or non-matching-Plan
  Circle — verified directly by the full pre-existing 291-test suite
  passing unmodified against this batch's code.
- `Recommendation`/`CircleJournalEntry`'s new fields are purely additive;
  no existing consumer of either type needed to change.
- No Coach, Insights, billing, or Premium Atmosphere code exists in this
  batch — `premiumEntitlementProvider` is the only new cross-cutting
  seam, and it grants nothing by default.
- Pre-existing Premium Pass visual WIP (`thirty_progress_circle.dart`,
  `circle_hero.dart`, `crafted_circle_geometry.dart` and their tests,
  `docs/design/circle/`, `tool/generate_circle_geometry.dart`) is entirely
  untouched by this batch.

## Related documents

- [RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md](../RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md) — the controlling frozen Premium document; authoritative above this ADR for Premium product scope
- [PREMIUM_STRATEGY.md](../PREMIUM_STRATEGY.md)
- [ADR-007 — Premium Never Blocks the Core Loop](ADR-007-premium-never-blocks-the-core-loop.md)
- [ADR-010 — Circle Closed Is Not Verified Activity Completion](ADR-010-circle-closed-not-completion.md)
- [ADR-013 — V1 Productization Batch 1 / Free Foundation + Prospective Local Journal](ADR-013-v1-free-foundation-and-journal.md)
