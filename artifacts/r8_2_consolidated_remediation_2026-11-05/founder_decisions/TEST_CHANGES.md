# Changes to existing tests (founder decisions A–C)

Every change to an existing test file is listed here. The exact before-and-after diff of each is in `test_change_diffs/`, and the "before" copy of each is in `baseline_r8_2_pre_decisions/test/`. Each of those copies matches the R8.2 regression manifest (`baseline_r8_2_pre_decisions/MANIFEST_CHECK.txt`).

## 1. Timing only: 11 files, 14 inserted lines, nothing removed

Under decision B, a Circle starts only once its own save is confirmed. A test that called today's `start()` and then, in the same instant, `close()` or a skip now has to let the Start's save land first, just as a real tap sequence does. Each change inserts exactly one line, the file's own settle call, after that `start();`. No assertion, expectation, fixture or description changed. This was checked mechanically: every added line matches `await <settle>();` and no line was removed.

| File | Inserted after line(s) | Settle used |
|---|---|---|
| `test/core/qa/qa_scenario_test.dart` | 255 | `pumpEventQueue()` |
| `test/features/b8/b8_delete_longitudinal_test.dart` | 76 (`circle()` helper) | `settle()` |
| `test/features/b8/b8_product_simulation_test.dart` | 276 (the simulated day) | `_settle()` |
| `test/features/home/application/recommendation_provider_test.dart` | 722 | `pumpEventQueue()` |
| `test/features/home/r3_delete_feedback_test.dart` | 62 (widget helper) | `tester.pumpAndSettle()` |
| `test/features/home/r3_persistence_delete_test.dart` | 442 | `settle()` |
| `test/features/personal_circle/personal_circle_simulation_test.dart` | 212 (the simulated day, 13 year profiles) | `_settle()` |
| `test/features/personal_circle/premium_today_test.dart` | 208, 237, 285, 458 | `settle()` |
| `test/features/plans/circle_plan_today_test.dart` | 113 (`walk()` helper) | `settle()` |
| `test/features/plans/r2_plan_credit_provenance_test.dart` | 278, 345 | `settle()` |
| `test/features/premium/b7_entitlement_matrix_test.dart` | 256 | `settle()` |

Lines were inserted only in tests that failed without them. Tests that already settled before Start were left as they were.

## 2. Assertions changed by a founder decision: 5 files

Each change is marked in the test source with the decision that requires it.

| File | Test(s) | Decision | Before → after |
|---|---|---|---|
| `test/features/r82/r82_a01_pending_lifecycle_credit_test.dart` | "the Pause lands …" (×2 faults) | A | **Before:** "a paused Plan is not credited; nothing is credited later" (0 credits). **After:** the Close was durable before the Pause, so exactly 1 credit is saved with the Pause; the Plan stays paused; this survives two restarts. |
| `test/features/r82/r82_a03_new1_stage_publication_test.dart` | "… started while its Plan save was still pending" (×2) | B | **Before:** the Circle shows as started at once, then is taken back. **After:** it isn't started while the save is pending; that save fails, so the Start is refused and the unstarted offer is taken back. Unchanged: the user is told, and nothing is on disk. |
| `test/features/r82/r82_a04_a08_new3_insight_actions_test.dart` | `markRefused` helper; "residual …" | C | **Helper:** it held two Insights writes (intent, then mark). There is no intent write now, so it holds the one mark write. **Residual:** "a later retry cannot attribute it and claims nothing" becomes "the retry finds the Insight's provenance on the Plan, records the mark, and leaves the Plan unchanged". |
| `test/features/r81/r81_n04_n05_expiry_and_insight_application_test.dart` | N04 "as reported" and "the evidence write … once at Start" (×2 faults) | B | **Before:** the Start ran with its Plan record unsaved; the journal status was the told signal; the Close wrote the record first. **After:** that Start is refused and told; the Close is a no-op; a second Start writes the record first, then starts and closes. Every N04 guarantee is still asserted as before: no unauthorized credit, a stored status that is never `closed` without the Start record, and `startedAfterExpiry: true` on disk. |
| `test/features/home/r8b_precommit_persistence_test.dart` | "a stage Circle's Start whose Plans evidence write …" (×2) | B | **Before:** told by History's status (`journalSaveStatus == false`). **After:** the Start is refused (`notStarted`, offer kept) and told by the store notice ("This change couldn't be saved. Please try again."), because the offer itself is saved. Unchanged: nothing is stored as started, and a restart brings back the unstarted offer with no Start in History. |

No other existing test was changed. No test was deleted or skipped.
