# R8.3 — limitations and residual risks

Each item is either a disclosed design choice inside the approved scope or a risk outside it. None is hidden by a passing test.

## L-1. OPEN — PRE-RELEASE BLOCKER: an unreadable preferences record keeps any Insight attribution inside it (D1)

**Founder disposition, 2026-11-07:** deferred as a mandatory pre-release blocker. Not fixed, not waived. No commercial release until a safe Delete/Export disposition is implemented and verified. R8.3.1 verified that Export omits such a record too (`../r8_3_1_founder_lifecycle_correction_2026-11-07/l1_assessment/L1_ASSESSMENT.md`); see `FOUNDER_DECISIONS.md`.

**What happens.** A Suggestion Preferences record that THIRTY can't read as a whole (another schema version, not JSON, a list field that isn't a list) is never written over except by Reset (R8.1 RL-3). Delete Circle history therefore leaves it exactly as stored, and reports success. A `byInsight` id inside it is not removed.

**Why.** Rewriting a record THIRTY can't read could destroy a newer build's data.

**Evidence.** Control `r83_delete_boundary_test.dart`: "a preferences record THIRTY can't read is left exactly as stored by the Delete".

Individual *items* THIRTY can't read inside a readable record do lose their `byInsight` field.

**Founder options:** see L1_ASSESSMENT.md (truthful Delete notice, export as stored, both, or accept).

## L-2. One provenance record per Plan (unchanged from R8.2)

When a later Insight changes the same Plan, it overwrites the earlier Insight's `appliedInsight`. A retry of the earlier, unmarked Insight then finds no provenance and is reported not available, never applied (D3: "if provenance is absent or overwritten, do not claim").

`_appliedOn` for I1 is not bound to a cycle. The I1 snapshot (`PlanDirection`) names no cycle, so the architecture review's "where the snapshot names one" does not apply. I2 stays bound to its cycle.

## L-3. Typed getters left as they are (D5 scope)

Every typed getter that `main()` or the first frames reach was changed:
- the V1 marker;
- the reminder state;
- analytics consent;
- the tester id and cohort;
- the First Breath date;
- both invitation flags, in the providers and in the cards.

**Not changed:**
- `lib/core/dev_preview/paced_qa_bench_page.dart` (a development preview, not reachable in release);
- `lib/core/qa/qa_scenario.dart:330` (the QA harness);
- `lib/core/qa/qa_shared_preferences.dart` (the QA store's own implementation of the getters).

Today's day keys go through the type-safe `_DayKeys` and were already covered (R8.2 A09).

**Semantics chosen for a value of the wrong type:**
- **V1 marker:** the retirement runs (it only removes V1 records); the value is kept as stored.
- **Reminder:** read as the defaults. A value is written only when the user sets that value: "set time" no longer rewrites the on/off flag, and "turn off" no longer rewrites the time.
- **Analytics consent:** no consent, never written over.
- **Tester id or cohort:** this run uses its own, unsaved.
- **First Breath date:** not played today. The ritual plays and then records today's date, which is a new fact, not a default.
- **Invitation flags:** count as already shown, so they are never written over.

## L-4. R83-F1 — FIXED in R8.3.1 (founder Option B)

See `../r8_3_1_founder_lifecycle_correction_2026-11-07/README.md`. Kept below as originally reported.

### As reported in R8.3

A Circle closed while its Plan was paused before its Start is credited later, once the Plan is active again. This is pre-existing and needs a founder decision; see `R83_F1_FOUNDER_DECISION.md`.

## L-5. Simulated restarts and faults

**What "restart" means.** Every restart in the R8.3 tests is `R8Harness.restart()`: a new `SharedPreferences` over the bytes the simulated disk confirmed, inside one Dart process.

**The new ack-lost fault is also a simulation.** In `FaultDisk.ackLost` the value lands and the call then fails. With `thenStop`, the process stops right after the value lands.

**What they don't prove.** Neither the restarts nor this fault is Android's storage behaviour. Passing them proves nothing about a real process kill, power loss or device storage fault. Those remain device-level release gates, together with S25/TalkBack.

## L-6. The single-writer guard records but doesn't enforce

`FaultDisk.overlaps` records a write that begins while another write to the same key is pending.

**Where it is asserted.** Only in the AUD-N3 scenario (empty there). Delete's first pass may legitimately overlap a stale Today write that it is about to supersede (the epoch design), so the guard is not asserted globally.

## Carried forward unchanged

- RL-4, offset-free historical timestamps. Pre-commercial decision.
- The R8.2 limitations not touched by R8.3:
  - no "starting" indicator;
  - the wording of the first refusal notice;
  - an unreadable Plan's restrictions;
  - the stage-5 lifecycle exceptions, now with dedicated tests: `r83_cross_store_test.dart`.
