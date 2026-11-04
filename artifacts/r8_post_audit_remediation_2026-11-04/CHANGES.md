# R8 — files changed (uncommitted, on top of `8ece26f6`)

## New production files
- `lib/core/storage/confirmed_write.dart`: `writeConfirmed`, `StorageWriteFailed`.
- `lib/core/storage/store_save_failures.dart`: failure events for kept Circles, Plans and Insights saves.

## Changed production files
- `lib/features/home/application/recommendation_provider.dart`:
  - confirmed `_publish`; the write-ahead record kept until every key lands;
  - an unpublished choice carried with the next write; failures reported;
  - midnight carry-over (`carriesOverMidnightAt`, `midnightCarryOverLimit`) and `reflectionAnswered`;
  - real-time choices (`_choiceTime`); "Use it today" never replaces an earlier day's offer;
  - Close records the Start it follows;
  - confirmed `clearRecordedCircleState`;
  - the duplicated `close()` doc comment removed.
- `lib/features/home/application/circle_journal.dart`:
  - confirmed write with rollback (F-5);
  - newer per-record versions kept verbatim;
  - `holdsHistory`;
  - `recordClosed(startedAt:)`;
  - confirmed `clearAll`.
- `lib/features/home/application/circle_history_deletion.dart`:
  - the intent first, confirmed and retried once, with `HistoryDeletionNotStarted`;
  - every removal confirmed, and all steps awaited;
  - confirmed start-up completion.
- `lib/features/personal_circle/domain/kept_circle.dart`:
  - a present but malformed `kept` field makes the record unreadable;
  - unknown wrapper fields returned in `extra`;
  - damaged saved wording makes the record a `RetainedKept`.
- `lib/features/personal_circle/application/kept_circles_provider.dart`:
  - changes are confirmed before they are shown;
  - concurrent Keeps are counted;
  - unknown fields are written back (retired Phase D fields excepted);
  - a write over an unreadable record fails loudly;
  - a non-string stored value counts as unreadable.
- `lib/features/insights/application/insights_provider.dart`:
  - `apply` is asynchronous, and I4 counts as applied only once its Circle is saved;
  - `InsightActionResult.notSaved` added;
  - saves are confirmed, reported and protected against unreadable stored data;
  - `forgetAll` is confirmed.
- `lib/features/insights/domain/insight.dart`: snapshot dates validated; unreadable snapshots kept as stored.
- `lib/features/plans/application/circle_plans_provider.dart`:
  - saves are confirmed, reported and protected;
  - `noteStart` and `recordGuided` fail when their write fails;
  - `forgetStageEvidence` is confirmed.
- `lib/core/premium/premium_access.dart`: "restored" only when billing then says active.
- `lib/core/app/thirty_app.dart`: uses `reflectionAnswered`; comment on the resume path.
- `lib/core/utils/date_key.dart`: doc comment restored to `dateKey`.
- UI call sites, now awaiting the asynchronous results:
  - `insights_page.dart`
  - `keep_circle_card.dart`
  - `kept_circle_page.dart`
  - `plan_detail_page.dart`
  - `qa_scenario.dart`
- `journal_data_controls.dart`, `you_data_card.dart`: Copy and Delete are enabled from `holdsHistory`; the not-started Delete notice (PROPOSED copy).
- `journal_save_failure_notice.dart`: also shows failed kept-Circle, Plans and Insights saves (PROPOSED title).

## New tests
- `test/support/r8_fault_disk.dart`: a platform store whose writes throw or return `false`.
- `test/support/r8_harness.dart`: the shared R8 test harness.
- `test/features/home/r8_a01_daily_persistence_test.dart` (13)
- `test/features/home/r8_a04_delete_durability_test.dart` (14)
- `test/features/home/r8_a06_unreadable_history_controls_test.dart` (9)
- `test/features/home/r8_journal_forward_records_test.dart` (2)
- `test/features/personal_circle/r8_kept_ownership_persistence_test.dart` (32)
- `test/features/insights/r8_f4_insight_dates_test.dart` (12)
- `test/core/app/r8_midnight_resume_test.dart` (9)
- `test/core/premium/r8_restore_wording_test.dart` (3)

## Edits to existing tests
No assertion was weakened. Each edit is listed with its reason.

**Mechanical `await`s.** Keep and Insights `apply` became asynchronous, so these tests now await them, with line reflow only:
- `b8_delete_longitudinal`
- `b8_product_simulation`
- `r2_make_today_circle`
- `insights_service`
- `insights_page`
- `r5_i4_keep_after_lapse`
- `premium_today`
- `r4_kept_ownership`
- `saved_circle_lapse_attack`
- `circle_plan_today`
- `r2_plan_credit_provenance`
- `b7_entitlement_matrix`

**`r41_kept_store_test`:**
- A direct write over an unreadable record now must throw `StorageWriteFailed`; it used to return silently. The bytes must still be unchanged.
- The test's `keep` helper is now asynchronous.

**`r3_persistence_delete_test`:**
- The disk's error now reaches the caller as the normalized `StorageWriteFailed` rather than the raw `StateError`.
- "A choice made while the deletion is still running" now holds the first removal instead of the intent. The intent is now confirmed before anything is removed; the property under test is unchanged.

**`r3_delete_feedback_test`:**
- The row "the intent, once, fails" moved out of the shared loop. It now expects the retried intent to let the deletion complete, with no message.
- New test: an intent that can't be recorded at all deletes nothing, and shows the PROPOSED not-started notice.

**`settings_page_test`:** the fake gateway now leaves Premium active after a found restore, as the store does. The success message is asserted unchanged.

## Test drafts corrected during R8 (not production)

These were found before the final runs. The `repro_on_r7_tree/` evidence uses the corrected versions.
- **A04 intent case:** it counted removals made by its own setup.
- **F-4:** it matched a valid snapshot freshly regenerated under the same id. Map comparisons now use encoded JSON.
- **Midnight resume:** each resume now moves the clock forward, as a real resume does. A same-time invalidation doesn't rebuild.

## Pre-commit gate (2026-11-04)
- `recommendation_provider.dart`:
  - P2: a recovery-record removal that fails is cleanup, not a failed save;
  - `_recordBeforeOverwrite` / `_journalHolds`: an earlier session History doesn't hold is never written over;
  - the six-hour limit documented as frozen.
- `circle_history_deletion.dart`: the write barrier begins after the intent is confirmed.
- `store_save_failures.dart`: `StoreSaveState` (count, last, unsaved); `record(notify:)`; `saved()`.
- `circle_plans_provider.dart`, `insights_provider.dart`: a confirmed save marks the store durably saved; a failure marks it unsaved, and Today's own reports don't notify a second time.
- `journal_save_failure_notice.dart`: D1 body "Please try again." (`changeNotSavedBody`).
- `journal_data_controls.dart`: D1 copy marked founder-approved.
- `docs/product/PRODUCT_V2_CONTRACT.md`: dated amendments 2026-11-04 for D2, D3 and D1.
- New tests:
  - `test/features/home/r8b_precommit_persistence_test.dart` (34)
  - `test/features/home/r8b_notice_copy_test.dart` (2)
- Existing test edit: `r3_delete_feedback_test.dart` (an R8-added test) now asserts the not-started notice is announced by its title.
- New audit inputs:
  - `docs/audits/THIRTY_ASTRA_POST_R7_AUDIT_SHARED_REPORT.md` (supplied)
  - `docs/audits/THIRTY_CLAUDE_POST_R7_AUDIT_REPORT.md` (verbatim copy)
