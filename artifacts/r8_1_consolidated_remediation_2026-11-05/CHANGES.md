# R8.1 — changes (uncommitted, on top of 58b179c9)

13 tracked files changed (+735 / −173), 1 new source file, 7 new test files, and 1 test-support capability. No existing test or assertion was modified.

## Production source

| File | Findings | Change |
|---|---|---|
| `lib/core/storage/preservation_writes.dart` (new) | N02 | A small container-scoped tracker for the copies of unreadable Plans/Insights records while their platform write is pending: `keepAside`, `settled(key)`, `settledAll()`. Not a general persistence engine. |
| `lib/core/storage/store_save_failures.dart` | N05 | `UserStore.suggestionPreferences`. |
| `lib/features/plans/application/circle_plans_provider.dart` | N01, N02, N04, N05, N08, AUD-1, AUD-6 | `_durable` (last state the store confirmed); `hasUnsavedChanges`, `ensureSaved()`, `isCreditedDurably()`, `confirmStartNoted()`, `confirmed(action)` with rollback, `PlanActionResult.notSaved`. `recordGuided` / `noteStart` retry what is only in memory. The build-time copy is tracked; `_protectStored` waits for it. `steerToday(circleId:)`. |
| `lib/features/plans/domain/circle_plan.dart` | N07, AUD-3 | Unreadable Plan entries, damaged stage records and unknown wrapper fields are kept and written back; a damaged cycle makes its Plan unreadable instead of being dropped; an unreadable Plan is never started over; Delete removes what may hold evidence. |
| `lib/features/insights/application/insights_provider.dart` | N02, N05, AUD-6 | Tracked build-time copy. `apply` awaits I1/I2 (via `confirmed`) and I3 (via confirmed preferences) and awaits the applied mark only after the target is confirmed. |
| `lib/features/insights/domain/insight.dart` | N07, AUD-4 | A present non-list `snapshots` makes the record unreadable; unknown wrapper fields kept. |
| `lib/features/home/application/suggestion_preferences.dart` | N05 | Serialized commits through `writeConfirmed`; shown only once saved; failures told; methods return whether they were saved. |
| `lib/features/home/presentation/memory_page.dart` | N05 | The three preference snackbars appear only when the change was saved. |
| `lib/features/home/application/recommendation_provider.dart` | N01, N03, N04, N06, N08, N09, AUD-2, AUD-5 | Recovery reads durable credit; `removeAnswer` clears the day keys holding that Circle before History; `_persist` waits for the Start record of a stage Circle; damaged kept wording restored from the kept Circle or never offered/voiced/started; served stage dated by the choice; UTC instants for Start/Close/pause; the new day opens once a carried-over Circle is finished. |
| `lib/features/home/application/circle_history_deletion.dart` | N02 | Waits for pending copies, then clears both aside keys again before removing its intent. |
| `lib/features/personal_circle/domain/composed_session.dart` | N06 | `hasDamagedWording`, `wordingUnverified` (never voiced), `withWording`. |
| `lib/features/personal_circle/application/kept_circles_provider.dart` | N10 | A confirmed save clears Kept Circles' unsaved status. |
| `lib/features/home/presentation/widgets/journal_save_failure_notice.dart` | N10 | Closing a notice re-checks History and store failures. |

## Tests

| File | Tests | Fail on R8 source |
|---|---|---|
| `test/features/r81/r81_n01_durable_plan_credit_test.dart` | 8 | 8 |
| `test/features/r81/r81_n02_preservation_writes_test.dart` | 10 | 7 |
| `test/features/r81/r81_n03_removed_answers_test.dart` | 13 | 8 |
| `test/features/r81/r81_n04_n05_expiry_and_insight_application_test.dart` | 18 | 14 |
| `test/features/r81/r81_n06_n07_damaged_records_test.dart` | 21 | 19 |
| `test/features/r81/r81_n08_n09_aud2_time_test.dart` | 8 | 5 |
| `test/features/r81/r81_n10_failure_notices_test.dart` | 5 | 5 |
| **Total** | **83** | **66** |

`test/support/r8_fault_disk.dart`: `FaultDisk.hold(key)` → `HeldWrite` (`reached`, `release([fault])`) — holds exactly one platform write or removal before the disk, while the cache has already changed, for deterministic interleaving tests. Nothing else in the disk double changed.

## Not changed

Audio, Supabase, RevenueCat configuration, localization (no new user-facing string), Founder Dashboard, V2 contract, ADRs, delivery tracker, the R7/R8 commits, both audit reports.
