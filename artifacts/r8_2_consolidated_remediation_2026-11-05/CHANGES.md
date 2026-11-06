# R8.2: source changes

- **Baseline:** e935112c408c16d99835280f4e1fafd722d47ed1.
- **State:** committed in the single R8.2 commit on `step5-billing-integration` (parent `e935112c`), after founder acceptance at implementation level (2026-11-06). Not an independent audit pass; not a release.
- **Not changed:** no new dependency, no new persistence engine, no copy change, no audio, billing, Supabase or RevenueCat change.

## Production (`lib/`)

| File | Finding(s) | Change |
|---|---|---|
| `features/plans/application/circle_plans_provider.dart` | A01, A02, A04, A07, A09, NEW-1, NEW-3 | `idle()`: waits until no Plans save is pending.<br>`recordGuided`: resolves a credit against the disk, and waits for a pending change that blocks it (at most 8 rounds, then refuses).<br>`_settleStart` (`noteStart` / `confirmStartNoted(stage, circleId:)`): settles only that Circle's own served record.<br>`confirmed()`: on failure, waits for the queue and checks the confirmed state at leaf level.<br>`keepGentler(cycleId:)`: changes only that cycle.<br>Stage answers come from confirmed History.<br>A deletion generation keeps `_durable` free of deleted evidence; `forgetStageEvidence` clears `_durable` at once.<br>Native-type-safe read, and keep-aside with the native type preserved. |
| `features/plans/domain/circle_plan.dart` | A04, A05 | `keepGentler(cycleId:)`.<br>`ServedStageCircle.source` is written back.<br>A present non-Boolean `startedAfterExpiry`, `revisit` or `gentler`, or non-text `drawsOn`, makes `lastServed` unreadable. It is kept in `extra`. |
| `features/insights/application/insights_provider.dart` | A02, A04, A07, A08, A09 | `idle()`.<br>`assess()` generates nothing while a Delete is under way or pending.<br>Inputs come from confirmed History.<br>`apply()` waits for pending Plans and History writes; I1–I3 record `applyingOn` before their change; a stale, unmarked Insight whose own change is durable is marked without the change being made again.<br>I2 is bound to its cycle.<br>`forgetAll()` clears `_durable` at once, behind a deletion generation.<br>Native-type-safe read and keep-aside. |
| `features/insights/domain/insight.dart` | A05, A08 | `InsightSnapshot.source` is written back.<br>New optional `applyingOn` date, validated like the other date fields. |
| `features/home/application/recommendation_provider.dart` | A03, A06, A09, NEW-1 | `_publish` gates on the payload's own stage (the `stage:` parameter, or the carried choice's), and `_withdrawUnsaveable` takes back a stage Circle that can't be saved.<br>Day key `recommendation_reflection_finished` and `RecommendationState.reflectionFinished` / `reflectionDone`, used by carry-over, `_finishedEarlierDay` and `_openNewDayAfter`; cleared by a new choice and by Delete.<br>`_persist` uses the per-Circle `confirmStartNoted`.<br>`_pendingDayWrite` is native-type-safe.<br>The `noted` Future is marked handled until the queue awaits it. |
| `features/home/application/circle_journal.dart` | A07, A09 | `JournalWrites` tracker (`journalWritesProvider`) and `readConfirmed()`.<br>All journal and preserved-copy reads are native-type-safe; a non-text journal is kept as its JSON text. |
| `features/home/application/circle_history_deletion.dart` | A02, A07, A09 | Resets the History tracker.<br>Waits for the Plans and Insights queues before the last pass, which also runs `insights.forgetAll()` again.<br>The deletion marker counts only when it is `true`.<br>The start-up Plans read is native-type-safe. |
| `features/home/application/suggestion_preferences.dart` | A05, A09 | Each entry keeps the stored map it was read from.<br>Dates must be text.<br>`tryRead(Object?)`; `build` uses `prefs.get`. |
| `features/home/application/phase_d_retirement.dart` | A09 | Start-up reads are native-type-safe. |
| `core/storage/preservation_writes.dart` | A09 | `keepAside(…, Object raw)`, `sameStoredValue`. |
| `core/app/thirty_app.dart` | A06 | The touch-driven new-day check uses `reflectionDone`. |

## Tests (`test/features/r82/`, new)

| File | Covers |
|---|---|
| `r82_a01_pending_lifecycle_credit_test.dart` | A01 |
| `r82_a02_new2_delete_isolation_test.dart` | A02, NEW-2 |
| `r82_a03_new1_stage_publication_test.dart` | A03, NEW-1 |
| `r82_a04_a08_new3_insight_actions_test.dart` | A04, A08 (marker retry), NEW-3 |
| `r82_a05_nested_fields_test.dart` | A05 |
| `r82_a06_reflection_completion_test.dart` | A06 |
| `r82_a07_confirmed_history_test.dart` | A07 (I4 threshold, stage 5) |
| `r82_a09_native_types_test.dart` | A09 |
| `r82_cross_store_adversarial_test.dart` | Cross-store interleavings |

No existing test or assertion was changed.

## Evidence tooling

- `artifacts/r8_2_consolidated_remediation_2026-11-05/regression_final/run_batches.py` (new): the E-1 fix.
- The R8.1 runner and all R8.1 evidence are unchanged.

## Founder decisions A–C (acceptance review, 2026-11-05)

Applied on top of the R8.2 changes above (all in the same R8.2 commit). The R8.2 state of these files is kept in `founder_decisions/baseline_r8_2_pre_decisions/`.

| File | Decision | Change |
|---|---|---|
| `features/plans/application/circle_plans_provider.dart` | A, B, C | **A:** `_lifecycle` makes `start`, `pause`, `resume`, `leave` and `goThroughAgain` on the Plans with `_withEarnedCredits` first. That folds in the credit of the active Plan's last served Circle when History has confirmed its Close, under `recordGuided`'s Premium rules. `recordGuided` re-resolves a folded-in credit whose save was refused, instead of failing at once.<br>**B:** `startNeedsNoWrite`.<br>**C:** an optional `byInsight` on `start`, `resume`, `goThroughAgain` and `keepGentler` records `appliedInsight` in the same save. |
| `features/plans/domain/circle_plan.dart` | C | `AppliedInsight` (`insightId`, `cycleId`, `on`) and `PlanProgress.appliedInsight`. It is read, written back, carried into a new cycle, and dropped by Delete. A damaged record is kept as stored in `extra`.<br>`CirclePlansState.withAppliedInsight`. |
| `features/home/application/recommendation_provider.dart` | B | `start()` starts at once only when `_readyToStart` holds. Otherwise `_startOnceSaved` saves the offer if needed, awaits the Start record (noted at the tap), and then starts. Refused: `_refuseStart` gives one notice per refusal.<br>`_offersOnDisk` and `_offerIdentity`: set by a confirmed publication, seeded at the first build, and only forgotten by later builds.<br>A waiting Start blocks `replaceToday`, `useOwnedToday` and repeated taps.<br>`_withdrawUnsaveable` only takes back an unstarted offer. |
| `core/storage/store_save_failures.dart` | B | `UserStore.todaysCircle`. It uses the existing notice copy, so there is no new copy. |
| `features/insights/application/insights_provider.dart` | C | The applying intent (`_beginApplying`) is removed. I1–I3 pass the Insight's id to their change. `_appliedOn` repairs only from provenance that names this Insight, and for I2 its cycle. |
| `features/insights/domain/insight.dart` | C | `InsightSnapshot.applyingOn` is removed. It was introduced in R8.2 and never committed. |
| `features/home/application/suggestion_preferences.dart` | C | `ElementLeftOut.byInsight`, and `leaveOut(element, byInsight:)`. |

**New tests:** `test/features/r82/r82_decision_a_historical_credit_test.dart`, `…_decision_b_start_persistence_test.dart` and `…_decision_c_insight_provenance_test.dart`.

**Existing tests:** see `founder_decisions/TEST_CHANGES.md`. 11 files changed timing only, with inserted settle lines; 5 files changed assertions as the decisions require.

## Reconciliation with the original Claude post-R8.1 report (2026-11-06)

The report was supplied at 09:08 on 2026-11-06 and is preserved unedited (`docs/audits/THIRTY_CLAUDE_POST_R8_1_AUDIT_REPORT.txt`, SHA-256 `96593e20…4c23a1`).

| File | Change |
|---|---|
| `test/features/r82/r82_claude_audit_new1_triggers_test.dart` (new) | The report's own NEW-1 trigger scenarios, which its acceptance condition asks to have regression tests. Trigger A: stage 5 → "Go through it again"; the I1 application; Leave, then Start the same Plan. Trigger B ×2 faults: one transient failure at choice time. 5 tests: 5/5 fail on R8.1, 5/5 pass now. |

No production code and no existing test changed. See `claude_audit_reconciliation/README.md`.

## Final Plan lifecycle policy (founder directive, 2026-11-06)

Exact diffs are in `lifecycle_policy/source_diffs/` and `lifecycle_policy/test_change_diffs/`. The pre-fix copies are in `lifecycle_policy/baseline_pre_fix/`.

| File | Change |
|---|---|
| `features/plans/domain/circle_plan.dart` | `ServedStageCircle.startedBeforePause` and `closedBeforeLeave` hold UTC instants; a malformed value makes the record unreadable. `copyWith`, `sameInstant` and `instant` are added. `PlanProgress.withCycle` is added. `stampServed` is added. `recordGuided(startedAt:, closedAt:)` credits a paused Plan's current cycle, or a left cycle, only for the stamped Start or Close. `_newCycle` keeps a Close-before-Leave stamp. `activePlanId` is cleared only for the credited Plan itself. |
| `features/plans/application/circle_plans_provider.dart` | `noteStarted` and `noteCloseRequested` keep the order in memory. `_withActionOrder` stamps the order inside the Pause or Leave save, with History as the fallback. `_withEarnedCredits` now also covers paused Plans. `recordGuided` passes the Circle's own instants. |
| `features/home/application/recommendation_provider.dart` | `_notePlanActions` reports the Start or Close of a stage Circle (including after a restart). `_creditGuided` passes `startedAt` and `closedAt`. 27 lines added, none removed. |

**New test:** `test/features/r82/r82_lifecycle_policy_test.dart`, 21 tests. 9 fail on the pre-fix tree; 21/21 pass now.

**Existing tests (assertions, per the policy):**
- `r82_decision_a_historical_credit_test.dart`: the two "not extended" Pause cases;
- `plans/r2_plan_credit_provenance_test.dart`: the paused-Plan test.
