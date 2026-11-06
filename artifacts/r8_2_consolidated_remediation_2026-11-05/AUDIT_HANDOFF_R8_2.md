# R8.2 audit handoff: the original Claude auditor reproductions

- **Scope:** this note explains the five original auditor tests that still fail on the R8.2 tree, as the founder directive of 2026-11-06 (§3) requires.
- **Status:** it is not an audit pass. The remediation evidence is in this folder (see `README.md`).

## 1. The auditor's files and how they were run

- **The files.** `audit_r81_repro_test.dart`, `audit_r81_diag_test.dart` and `audit_r81_stage5_test.dart` come from the auditor's scratch folder, named in report §5 of `docs/audits/THIRTY_CLAUDE_POST_R8_1_AUDIT_REPORT.txt` (SHA-256 `96593e20…4c23a1`).
- **Preserved unchanged** in `claude_audit_reconciliation/original_auditor_repro/`:

  | File | SHA-256 |
  |---|---|
  | `audit_r81_repro_test.dart` | `e00fc009…a4e83fe3` |
  | `audit_r81_diag_test.dart` | `29e0e42f…6d91198f` |
  | `audit_r81_stage5_test.dart` | `9996c8f0…a60bbb3` |

  The copies' hashes equal the originals'. They were never edited, and they never ran from the repository.
- **How they were run.** In scratch exports: `git archive`, with the tree's `lib/` and `test/` overlaid for "current".

| Tree | Result | Log |
|---|---|---|
| R8.1 (e935112) | 4 pass / 9 fail, exactly as report §5 states | `claude_audit_reconciliation/original_repro_on_R8_1/` |
| R8.2 before the lifecycle policy | 8 pass / 5 fail | `claude_audit_reconciliation/original_repro_on_current/` |
| R8.2 with the lifecycle policy (final) | 8 pass / 5 fail, the same five | `lifecycle_policy/auditor_repro_post_fix/` |

## 2. The five current-tree failures, one by one

### F1, F2: `throws: A2` and `returnsFalse: A2`, "ONE transient failure of the served-stage write…"

- **Exact failure.**
  - `audit_r81_repro_test.dart:124:66` throws `Null check operator used on a null value`.
  - The line is `final rec = c.read(recommendationProvider).recommendation!;`. It precedes the assertion at :125–126, `expect(rec.composed?.stage, isNotNull, reason: 'stays on screen (accepted limitation)')`.
- **What the auditor expected.** After one refused Plans write at choice time, the stage Circle *stays on screen*. That was the R8.1 accepted limitation, which the report criticises. The user starts, runs and closes it, and History must record it. On R8.1 it fails at :137: the Close never reaches History.
- **What R8.2 does.**
  - Once it is certain the Circle's served stage can't be saved, the unsaveable offer, not yet started, is taken back (R81-A03, narrowed by founder decision B).
  - The user is told: `journalSaveStatus[circle] == false`, plus the existing notice.
  - Nothing of that Circle is on disk.
  - Today's choice opens again. The next choice is saved, starts, closes and reaches History, also after a restart.
- **Why this is correct.** The report's own acceptance condition (NEW-1) reads: "A Circle that can't be confirmed must either be saved without stage credit or be refused at Start. It must never be silently run and then lost." R8.2 refuses it before it can start, which is stricter than refusing at Start.
  - The fixture asserts the *old* behaviour as its precondition, so it can't pass on a tree that fixed the defect.
  - The test is not altered.
- **Verified by:**
  - `test/features/r82/r82_claude_audit_new1_triggers_test.dart`, "Trigger B (throws)" and "Trigger B (returnsFalse)": 5/5 fail on R8.1, pass on R8.2.
  - `r82_a03_new1_stage_publication_test.dart`, "a stage Circle whose served stage is refused, not yet started…" and its Start-pending variant.
  - Adapted `R-A2` ×2 (`claude_audit_reconciliation/adapted_repro/`): fail on R8.1, pass on R8.2.

### F3: `DIAG A2 (returnsFalse once at choice): run it; restart`

- **Exact failure.**
  - `audit_r81_diag_test.dart:102:61` throws `Null check operator used on a null value`.
  - The line is `final id = c.read(recommendationProvider).recommendation!.circleId;`.
  - This test has no `expect`. It only prints diagnostics, and fails only because of this dereference.
- **What the auditor expected.** The same R8.1 situation as F1 and F2. The Circle stays on screen so its in-session and after-restart state can be printed. On R8.1 it printed "closed in memory, nothing on disk or in History".
- **What R8.2 does.** The same as F1 and F2: there is no offer to dereference, because it was taken back.
- **Why this is correct.** It is the same reason as F1 and F2. The diagnostic depends on the replaced behaviour.
- **Verified by:** the same tests as F1 and F2.

### F4, F5: `throws: A3` and `returnsFalse: A3`, "a failed Delete leaves _durable at pre-deletion evidence…"

- **Exact failure.**
  - `audit_r81_repro_test.dart:179:9` fails the assertion `expect((await disk())[circlePlansKey], isNot(contains(id)), reason: 'deleted stage evidence written back to disk')` (:179–183).
  - The reported value is `Expected: not contains '2026-10-12'`. The actual value is `{"schemaVersion":1,"activePlanId":"getting_going","plans":{"getting_going":{"lifecycle":"active","cycles":[{"id":"getting_going#1","number":1,"startedOn":"2026-10-12","cursor":2,"records":[],"gentlerSince":"2026-10-12"}]}}}`.
- **What the auditor expected.**
  - After a failed Delete and a later failed save, deleted stage evidence must not come back into memory. This is asserted at :169–175, and it **passes** on R8.2, though it failed on R8.1.
  - After the store heals, the next save must not write the evidence to disk (:179–183).
- **What R8.2 does.** The stored Plans hold `"records":[]`: no stage record, in memory, on disk, or after a restart.
- **Why the fixture is invalid.** The test checks for the evidence as a substring: the Circle id `2026-10-12`. But Circle ids are day keys, and the same date is also the cycle's own `startedOn` and `gentlerSince`, which are not evidence and are kept by design ("each Plan's place stays"). So the substring is present whether or not evidence came back. On R8.1 the test failed earlier, at the real memory defect, so this weakness never showed there.
- **Verified by:**
  - the auditor's own `DIAG A3` in the same report set. It passes unchanged on R8.2 and prints `memRecords afterDelete=0 afterFailedSave=0 diskRecordsAfterHeal=0 … diskRecordsAfterRestart=0 memAfterRestart=0`. On R8.1 it printed `afterFailedSave=1 diskRecordsAfterHeal=1`.
  - `r82_a02_new2_delete_isolation_test.dart`, "Delete whose Plan evidence write fails, then an unrelated Plan …" (throws and returnsFalse).
  - adapted `R-A3` ×2, which counts stage records on disk: fails on R8.1, passes on R8.2.

## 3. Everything else from the auditor's files

These pass unchanged on R8.2. Each failed on R8.1, except the controls.
- A1 ×2;
- A4 ×2 (NEW-3);
- the stage-5 "Go through it again" test;
- CONTROL A1, DIAG A1 and DIAG A3.

The founder's lifecycle policy correction (`lifecycle_policy/`) didn't change any of these outcomes.

## 4. Full regression evidence for this tree

- **Definitive run:** `lifecycle_policy/regression_rerun/` (2026-11-06, 12:50 → 13:23). 193/193 files, 2,774 passed, 0 failed, 0 skipped. EVIDENCE OK, CASES OK (13/13 year profiles once each), B8 6/6, every batch exit 0, fingerprints identical.
- **Not evidence:** `lifecycle_policy/regression_final/`. It was interrupted by low memory, and then by my stopping its live test processes. It is kept only as the record of that interruption (`INTERRUPTED.txt`), and none of its results are combined into the definitive run.

## 5. Process-kill and restart: what is and isn't verified

- **What the tests do.** Every "restart" in these tests is simulated inside one test process (`test/support/r8_harness.dart`, `restart()`).
  - It discards all app state and rebuilds the app on exactly what reached the simulated disk (`FaultDisk`), as a new process would. A held or refused write that never landed is therefore lost, as on a real kill.
  - Faults are healed unless `keepFaults` is set.
  - It runs the same interrupted-Delete completion as `main.dart`.
- **What is not verified.**
  - No real OS process kill was tested: no kill mid-write against Android's native SharedPreferences, and no kill between the platform write and its confirmation.
  - No real Android storage failure was tested.
  - No S25 or TalkBack run of R8.2 was done.
- **Lifecycle policy specifically.** The order of the user's Start or Close relative to a Pause or Leave is held in memory until that Pause or Leave is saved.
  - If the process dies first, the Pause or Leave itself was never saved, so there is nothing to order.
  - After a restart, Today reports the restored Start and Close again before any Plan action can be taken.
  - This remains an accepted LOW limitation (`lifecycle_policy/README.md` §5).
