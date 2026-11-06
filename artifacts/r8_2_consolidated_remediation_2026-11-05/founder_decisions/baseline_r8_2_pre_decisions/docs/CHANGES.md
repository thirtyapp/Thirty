# R8.2: source changes

- **Baseline:** e935112c408c16d99835280f4e1fafd722d47ed1.
- **State:** working tree only, uncommitted, unstaged.
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
