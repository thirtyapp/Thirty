# ADR-012 — Batch 2 / Recommendation Diversity

**Status:** Accepted

## Context

Two retained testers gave contrasting, specific feedback on Recommendation
MVP v0 (`recommendation-mvp-v0.md`):

- **T15** (7 check-ins): recommendations repeated within a couple of days,
  relevance felt mixed, recommendations sometimes felt generic, and no
  suggested activity led to a reported offline action. Limited
  recommendations were cited as the reason they would not miss THIRTY.
- **T06** (10 check-ins): explicitly validated the core mechanic — choosing
  a broad direction, letting THIRTY choose the activity, not being shown
  several activities to choose from — and reported real offline actions
  from recommendations.

Read together, this is not evidence against the one-activity mechanic — T06
confirms it works. It is evidence that *what* THIRTY chooses within that
mechanic repeats too easily.

### Root cause

v0's anti-repetition rule (§4 of `recommendation-mvp-v0.md`, as originally
written) compared today's deterministic candidate (`epochDay(today) %
pool.length`) against only *the immediately preceding local calendar day's*
canonical activity — and only when that day's state was still the most
recently persisted "today" record. This was a deliberate v0 minimalism
choice ("no long-term history, no weights, no novelty-score"), not an
oversight, and it correctly prevents back-to-back-day repeats.

It does **not** prevent repeats across a gap of two or more days: with a
pool of length 2 (`moreEnergy`, `gentlerPace`), any even-length gap between
two uses lands on the same `epochDay % 2` remainder, and the old rule never
even looked — a stored day that isn't *exactly* yesterday was treated as no
history at all. This was already documented, and exercised by a passing
test (`recommendation_provider_test.dart`, "does NOT avoid a canonical
activity stored two or more days ago"). A tester who opens THIRTY every
other day or so — exactly a retained-but-not-daily usage pattern — could
see the same activity again well within what reads, subjectively, as "a
couple of days." This mechanically explains T15's complaint without
requiring the content inventory itself to be at fault.

The inventory was independently audited (7 activities: 2 `moreEnergy` / 3
`clearerHead` / 2 `gentlerPace`) and found adequate to fix the reported
defect without new content — see "Content audit" below.

## Decision

**Fix the algorithm, not the mechanic, and not (primarily) the content.**

1. **Anti-repetition is now based on actual exposure count, not calendar
   adjacency.** Each [`Intention`] gets its own bounded, persisted history
   of recently shown [`ActivityId`]s
   (`recommendation_provider.dart`'s `recommendationHistoryKeyFor`),
   capped at `pool.length - 1` entries. `activity_catalog.dart`'s
   `selectActivityId` excludes that history from the day-indexed rotation
   before choosing. This guarantees no repeat until every other activity in
   the pool has been shown at least once since, regardless of how many
   calendar days that took — closing exactly the gap above.
2. **The cap (`pool.length - 1`) is the narrowest window the content
   inventory supports**, not an arbitrary duration: it is derived from pool
   size, guarantees at least one non-excluded candidate always exists (no
   deadlock), and never over-excludes a 2-item pool down to nothing. A
   fixed multi-day window (e.g. "never repeat within 7 days") was
   considered and rejected — it would either be meaningless for a 2-item
   pool (any window ≥2 days forces the *only* alternative every time, which
   the pool-size-based cap already achieves more simply) or arbitrary and
   undocumented for a 3-item pool.
3. **[`ActivityId`] remains the sole stable recommendation identity** — it
   already existed pre-Batch-2 (used for persistence and the old
   single-step anti-repetition check) and is now reused, unchanged, as the
   history entries' type and as the analytics identifier below. No new ID
   scheme was introduced.
4. **Deterministic fallback, never a deadlock:** if a future pool ever
   shrinks to one activity (making the cap 0), `selectActivityId` falls
   back to the full, unfiltered pool rather than excluding every candidate
   — documented on `selectActivityId` itself.
5. **New analytics event, reusing the existing sink:** `recommendationShown`
   (wire name `recommendation_shown`) fires exactly once per real
   `chooseIntention()` resolution — never on its no-op early return —
   carrying `intention` and `activity_id` as metadata on the same
   `analytics_events` table Batch 1 introduced
   (`supabase/migrations/20260906000000_add_recommendation_shown_event.sql`
   only widens that table's `event_type` CHECK constraint; no new table, no
   new column, no broader Supabase usage). Full recommendation display copy
   is never sent — only the stable ID.

### Content audit (Phase D)

All 7 activities were reviewed for direction alignment, specificity,
near-duplication, feasibility, and generic wording. Result: **KEEP, no
change**, for all 7. The three walks (`thirtyMinuteWalk`, `phoneFreeWalk`,
`easyWalk`) remain near-duplicate-*adjacent* across different `Intention`
pools — already known and deliberately accepted in
`recommendation-mvp-v0.md` §3 ("perceived repetition ... wordt gevalideerd
met echte gebruikers, niet vooraf technisch opgelost"), and irrelevant to
same-direction repetition since the diversity guard only ever excludes
within one pool. `moreEnergy` and `gentlerPace`'s smaller (2-item) pools are
noted as a coverage observation for a future, separately product-reviewed
content pass — **not** treated as a defect to fix by inventing new,
safety-unreviewed activities now. The task's own instruction to avoid
"mass-generating filler content" applies directly here: the reported defect
is fully explained and fixed by the algorithm change above, so no new
activities were added in this batch.

## Consequences

- The one-activity mechanic is unchanged: the user still picks exactly one
  `Intention`; THIRTY still resolves exactly one `ActivityId`. No
  multi-choice, reroll, or swipe UI was introduced.
- `recommendation-mvp-v0.md` §4–§5 are updated in place (not superseded) to
  describe the new rule — the document's other sections (Intentions,
  activity inventory, "Why This Today?" rules, Circle Closed semantics) are
  unaffected.
- `recommendation_provider_test.dart`'s old test asserting the two-or-more-
  day gap was *not* protected is replaced with a test asserting it now is —
  that old test was documenting the bug this ADR fixes, not a requirement.
- Any future pool-size change should re-derive the history cap
  (`pool.length - 1`) rather than hard-coding a number — it is intentionally
  computed from `activityPools`, never a literal constant.

## Related documents

- [ADR-009 — Daily Intention Question Is v0's Sole Personalization Signal](ADR-009-daily-intention-question.md)
- [ADR-011 — Batch 1 / Post-Fix Retention Cohort](ADR-011-batch-1-post-fix-retention-cohort.md)
- [`recommendation-mvp-v0.md`](../recommendation-mvp-v0.md)
- [`supabase/README.md`](../../../supabase/README.md)
