# R8.3.2 — the two contracts

Status: implemented and verified at the implementation level. Not committed. Awaiting founder review and independent re-audit.

## Contract A — Durable Start identity and eligibility

### A.1 States

| State | Where it lives | Meaning |
|---|---|---|
| **Offered** | Today's day keys (`recommendation_*`), confirmed (`_offersOnDisk`) | The Circle is on disk and may be started. |
| **Start preparation pending** | In memory only. Today's queue is inside `CirclePlansNotifier.prepareStart`. | Waiting for every pending Plans change to land or be refused. Then, if the Plan is paused, its record is being written. |
| **Prepared** | `PlanProgress.startedWhilePaused = {circleId, startedAt}` on disk (paused Plan only) | This Start, at this instant, is ineligible for Plan credit **if it becomes valid**. |
| **Valid Start** | `RecommendationState.status = started`, `startedAt = T` (the instant `prepareStart` returned) | The single moment the Circle becomes started. |
| **Cancelled / refused Start** | Nothing new | The prerequisite was refused, the day ended, the offer was replaced or rebuilt, or the app stopped. A record written for it names an instant no saved session has. |
| **Durable started session** | Day keys `startedAt = T`, then History's `startedAt = T` | What every credit path reads. |
| **Durable Close** | Day keys / History `closedAt` | Credit follows only this (R3, unchanged). |
| **Historical eligibility** | Decided by `CirclePlansState.recordGuided` | No credit when `startedWhilePaused` names this Circle **and** this Start's instant. An R8.3.1 record (the day alone) excludes every Start of that Circle. Otherwise the R8.2 lifecycle rules apply unchanged. |

### A.2 Rules

1. **One eligibility decision, on confirmed Plans.**
   - Both Start paths decide on `_durable`, never on the shown Plan.
   - Fast path (`startNeedsNoWrite`): it applies only when all of these hold:
     - no Plans change is pending (`!hasUnsavedChanges`);
     - the Plan is not paused;
     - no record of this Circle exists;
     - the served record is on disk.
   - Waiting path (`prepareStart`): it waits for every pending Plans change (`idle`), rounds bounded. It then samples the Start instant and decides on `_durable`.
   - So a pending or later-refused Resume never authorizes a Start (AUD-R83-2, C3). An optimistic marker left by an earlier tap, or a same-day provider rebuild, never stands in for confirmation (R83-N02).
2. **The record names the Start.**
   - The record is `{circleId, startedAt}`, and the Start is saved with exactly that `startedAt`.
   - A preparation that never became a valid Start excludes no later valid Start (R83-N01, AUD-R83-3).
   - This holds whether the preparation ended because the app stopped, its day-keys save failed, it was cancelled by a rebuild, or its answer was lost.
3. **A Circle is validly started once.**
   - When a Start of Circle C is being prepared, any record already naming C must come from an attempt that never became valid.
   - It is replaced (paused Plan) or removed (Plan not paused) and confirmed **before** the Start is valid.
   - If that write is refused, the Start is refused (decision B). The user can tap again (B7).
   - This also covers a frozen or rolled-back clock (B-tie, and Claude's original AUD-R83-3 test with the harness clock standing still).
4. **The exclusion survives everything that can still process the original Close.**
   - `_newCycle` carries `startedWhilePaused`, both for Go through again and for Start on a left or ended Plan, including when an Insight does it (AUD-R83-1).
   - Restart catch-up, the next day's `_recordBeforeOverwrite`, and the lifecycle fold all reach `recordGuided` with the session's own `startedAt`.
   - Only these remove it:
     - Delete Circle history (stage evidence, unchanged);
     - a later Start preparation of the same Circle (rule 3);
     - a newer paused Start of a later Circle (single slot, see LIMITATIONS).
   - **Resuming a Plan never removes it.**
5. **Unchanged.** These all keep their behaviour:
   - Start → Pause → Close credits once, on the original cycle (`startedBeforePause`).
   - Close requested → Leave while saving credits the left cycle once (`closedBeforeLeave`).
   - Durable Close before credit.
   - No duplicate credit (`lastAdvancedCircleId`, records).
   - The served / expiry rules (`creditsServed`, `startedAfterExpiry`), billing authority, and the Free/Premium boundaries.

### A.3 Persisted form

| Value | Read as | Written as |
|---|---|---|
| `{"circleId": "<YYYY-MM-DD>", "startedAt": "<ISO 8601 instant>", …unknown}` | Exact record; unknown fields kept | The same, unknown fields written back |
| `"<YYYY-MM-DD>"` (written by R8.3.1) | Legacy record: excludes every Start of that Circle | Unchanged, as stored |
| Anything else: `""`, a non-day string, a number, an object without a day or without an instant | **The Plan is unreadable**. It is kept as stored and runs nothing. | Unchanged, as stored |

Downgrade: an R8.3.1 build reading the object form treats the Plan as unreadable and keeps it as stored. That is fail-closed and nothing is lost. The R8.3 build is not released.

### A.4 Founder-visible linearization (decision point)

- **The case.** A Plan change is tapped while a paused Start's own record is being written (Astra N01-C). For example: Pause → tap Start → tap Resume, with the Resume tapped before the record is confirmed.
- **How it is ordered.** That change is ordered **after** the Start.
- **Why.** The confirmed Plan when the Start became valid was paused, so there is no credit. This matches:
  - the tap order, which is the founder-table row "Pause → Start → Resume → Close = no credit";
  - R8.3's behaviour;
  - the rule that the shown Plan is never taken for the confirmed Plan.
- **The alternative.** Wait for that pending change too, and credit if a Resume lands. That would grant credit in a case no decision authorizes, so it was not chosen. Test: B5.

## Contract B — Durable Insight idempotence

### B.1 States, and how each is told apart

| State | Evidence | Retry outcome |
|---|---|---|
| Never applied | No `appliedOn`. No provenance names it. | Applied normally (D-ctl1). |
| Target action durably applied, mark pending or refused | The target store's provenance names it: the Plan's `appliedInsight`, or `ElementLeftOut.byInsight` | Mark recorded with the **original** date. Never re-applied (D3, D-ctl2). |
| Mark recorded | `appliedOn` | `alreadyApplied` |
| Later explicit manual reversal (I1/I2) | Provenance stays on the Plan. A Pause, Leave or Stop gentler keeps `appliedInsight`. | Mark only. The manual choice stands (R8.3, unchanged). |
| A later, different Insight applied to the same Plan | **R8.3.2.** Before the later change replaces the Plan's provenance, the displaced Insight's mark is written from that provenance, with its date. If that write is refused, the later Insight changes nothing (`notSaved`) and the provenance stays (D-ctl3). | The displaced Insight is `applied`. Its retry gives `alreadyApplied`. No duplicate mutation and no false date (D1). |
| Original Insight retried after its provenance was overwritten | This can no longer happen for a Plan: an overwrite only ever happens once the displaced mark is durable. | — |

### B.2 Why it is bounded

- Plans still hold **one** provenance record, and there is no new field or history.
- The extra Insights write happens only when the displaced Insight is unmarked and present, which needs an earlier refused mark.
- Delete still clears both.
- `apply` now also waits for the Insights store's own pending writes, so that the "is it marked?" check is made on confirmed marks.

### B.3 Not covered — OPEN (R832-B1, R832-B2)

- **The two cases.** A manual reversal that **erases** an Insight's only provenance:
  - I3: **Put back** removes the `ElementLeftOut` entry;
  - I4: **removing the kept Circle**.
- **Why a retry repeats the action.** Either erasure leaves the Insight current again, and a retry repeats the action.
- **Status.** Reproduced on R8.2, R8.3 and the corrected tree. Not implemented: it needs a design choice outside the authorized groups. See `open_findings/R832_B1_B2_SCOPE_DECISION.md`.
