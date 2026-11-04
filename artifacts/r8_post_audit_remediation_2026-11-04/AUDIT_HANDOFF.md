# THIRTY R8: independent re-audit handoff

**For:** both independent auditors, Astra and Claude, auditing separately.
**Status:** founder-accepted at the implementation and reported-test level, 2026-11-04. **This is not an independent audit closure.** Phase E stays on HOLD, and no commercial release is authorized.

## 1. What to audit

| | |
|---|---|
| Repository | `thirtyapp/Thirty` |
| Branch | `step5-billing-integration` |
| Commit | **The single R8 commit that adds this file.** A commit can't contain its own SHA. The full SHA is in the founder's R8 commit report and in the local `R8_PUSH_RECORD.md`. To check it: `git log -1 --format=%H -- artifacts/r8_post_audit_remediation_2026-11-04/AUDIT_HANDOFF.md` |
| Parent (R7 baseline) | `8ece26f6dbd41f573e854b8fc82f44a6942282e3`, unchanged. The original verdicts on it stand: Astra **FAIL**, Claude **CONDITIONAL PASS**. |
| R8 delta | `git diff 8ece26f6dbd41f573e854b8fc82f44a6942282e3 <R8 SHA>` |

Audit the exact pushed commit, not a working tree. Each auditor must inspect the source itself:
- The implementer's PASS statements, this file and `ISSUE_REGISTER.json` are claims to check, not evidence.
- A new finding of your own stays open until it is fixed and re-verified. It is never treated as resolved silently.

## 2. Original audit reports (historical independent results, unchanged)

| Report | Verdict | Path in the commit | Content sha256 (LF, as committed) | Working-copy sha256 (CRLF, as supplied) |
|---|---|---|---|---|
| Astra post-R7 audit | FAIL: R7-A01…A04 HIGH, A05…A08 MEDIUM, one MEDIUM restore defect, one LOW evidence recommendation | `docs/audits/THIRTY_ASTRA_POST_R7_AUDIT_SHARED_REPORT.md` | `6ddfe5e144764cc723841efde41250c2ddd459475033da4d319315b3cdc37dc4` | `e24bf8c1f21b1f19712380f23e8961b661db25c3b0f95886d9da92133f85204f` |
| Claude post-R7 audit | CONDITIONAL PASS: F-1 MEDIUM, F-2…F-6 LOW, plus recommendations | `docs/audits/THIRTY_CLAUDE_POST_R7_AUDIT_REPORT.md` | `6d7e628c074aa62de540fdb98cd87c80e2389a3eb9bb3b26ac4213b656015875` | `c6b396a1b7792b649a794ba4c2ebefe9a6f8c87a013303c2f0daea9338dd7e06` |

The two hashes differ only by line endings. Git stores text with LF, and a Windows checkout restores CRLF.

The extended Library report that the Astra report links to was **not supplied** and was not used.

## 3. Finding-to-fix mapping

The full record is `ISSUE_REGISTER.json`: 20 entries, each with its root cause, files, fix, reproducing tests, failure injection, result on R7 and result after the fix.

| R8 | Original finding(s) | Fix (main file) | Reproducing tests |
|---|---|---|---|
| R8-01 | Astra R7-A01 HIGH | confirmed `_publish`, write-ahead day record (`recommendation_provider.dart`) | `test/features/home/r8_a01_daily_persistence_test.dart` |
| R8-02 | Astra R7-A02 HIGH, Claude F-3 | a malformed kept collection is unreadable and never overwritten (`kept_circle.dart`, `kept_circles_provider.dart`) | `test/features/personal_circle/r8_kept_ownership_persistence_test.dart` |
| R8-03 | Astra R7-A03 HIGH, Claude F-6 | Keep, Plans and Insights saves confirmed before shown; I4 applied only after its Keep is saved | same file, plus `r8b_precommit_persistence_test.dart` |
| R8-04 | Astra R7-A04 HIGH | Delete: durable intent, every removal confirmed, marker removed last (`circle_history_deletion.dart`) | `r8_a04_delete_durability_test.dart`, `r3_delete_feedback_test.dart` |
| R8-05 | Astra R7-A05 | `recordClosed(startedAt:)` | `r8_a01_daily_persistence_test.dart` |
| R8-06 | Astra R7-A06 | `holdsHistory` enables Copy and Delete for unreadable History | `r8_a06_unreadable_history_controls_test.dart` |
| R8-07 | Astra R7-A07 | damaged saved wording makes the record a `RetainedKept` (never run or voiced) | `r8_kept_ownership_persistence_test.dart` |
| R8-08 | Astra R7-A08, Claude F-1 | midnight carry-over on resume and restart, limited to 6 h (D2) | `test/core/app/r8_midnight_resume_test.dart`, `r8b_precommit_persistence_test.dart` |
| R8-09 | Claude F-2 | real-time choice (`_choiceTime`) | `r8_midnight_resume_test.dart` |
| R8-10 | Claude F-4 | canonical Insight date validation (`insight.dart`) | `test/features/insights/r8_f4_insight_dates_test.dart` |
| R8-11 | Claude F-5 | History write rollback (`writeConfirmed`) | `r8_a01_daily_persistence_test.dart` |
| R8-12 | Claude recommendation | newer-schema journal records kept verbatim | `r8_journal_forward_records_test.dart` |
| R8-13 | Astra MEDIUM restore defect | "restored" only when Premium is active afterwards (`premium_access.dart`) | `test/core/premium/r8_restore_wording_test.dart` |
| R8-14 | Astra LOW, evidence automation | the runner fails on a missing or unsuccessful `done`, an empty run or a non-zero exit (`regression/run_batches.py`) | runner `report` and `cases` |
| R8-15 | Claude recommendation | doc comments | — |
| R8-16 | P2 (pre-commit gate) | a failed recovery-record cleanup is pending retry, not "not saved" | `r8b_precommit_persistence_test.dart` |
| R8-17 | data-loss check (pre-commit gate) | fail-closed: an earlier day's session missing from History is never overwritten | `r8b_precommit_persistence_test.dart` |
| R8-18 | D3 ordering (pre-commit gate) | the write barrier begins only after the intent is confirmed | `r8b_precommit_persistence_test.dart` |
| R8-19 | Astra §4, RevenueCat ordering note | documentation correction only, no code change | — |
| R8-20 | Astra §6, tested-source equivalence | git-blob source manifest compared with the commit (§6 below) | — |

## 4. Failure coverage: thrown exceptions and `false` returns

`test/support/r8_fault_disk.dart` makes the platform store fail for a chosen key, in one of two ways: by **throwing**, or by **returning `false`**.

Every R8 persistence scenario runs under both. Failures are injected into:
- Today's day keys, including the write-ahead record and its removal;
- History;
- kept Circles, Plans and Insights, including the I4 mark after a successful Keep;
- Delete's intent, each removal, and the marker removal.

Each case is checked three ways:
- **in memory:** nothing is shown as saved that isn't;
- **on disk:** nothing is overwritten, and nothing deleted comes back;
- **after a restart:** the state reads back as one of unsaved, pending retry or durably saved (`StoreSaveState.unsaved`).

**Reproduction against the audited R7 code:** `repro_on_r7_tree/REPRO_ON_R7_TREE.json`. 73 R8 tests fail on the R7 tree. The other 21 are guards and pass there, as intended.

**Pre-gate corrections:** `repro_before_fix/r8b_precommit_persistence__before.txt` records 11 failures before the fix.

## 5. Guarantees to verify in the source

**Session (D2, frozen in the contract):**
- A Circle from the day before is carried over midnight for **6 hours of real elapsed time** (`DateTime.difference`, so correct across a DST change). The time counts from Start, or from Close when the reflection is still open.
- The limit is applied only on restore or resume; a Circle running in the foreground is never interrupted.
- After expiry, History keeps the session as stored. No Close or reflection is made up.
- Nothing starts by itself, and the rule that a stale, unstarted offer can't be started is unchanged.

**Persistence:**
- Every user-data write goes through `writeConfirmed`: a throw or `false` is a failure, memory is put back, and `StorageWriteFailed` is raised.
- Nothing is reported as saved before it is on disk.
- Unreadable or newer data is kept byte for byte.
- **Fail-closed (founder-approved):** a new day's choice never overwrites an earlier started or closed session that History doesn't hold yet. That choice is then reported as not saved.

**Deletion (D3, frozen in the contract):**
- The intent is confirmed durable first (one retry), before the write barrier, memory clearing or any removal.
- If it can't be recorded, nothing changes and the user is told.
- A partial Delete never reports success, and the next start completes it.
- A write that is already on its way can't bring deleted data back.

**P2:** once every required key is confirmed, the Circle is durably saved. If the recovery record's removal then fails, the record is left for retry, with no duplicate History entry and no duplicate Plan credit.

## 6. Tested-source equivalence (git blobs)

`regression/SOURCE_MANIFEST_git_blobs.txt` gives the git blob id of every file in `lib/`, `test/`, `pubspec.yaml`, `pubspec.lock` and `analysis_options.yaml`, as tested:
- 346 files;
- the manifest's sha256 is `862b924b5a1d3132b22a33aabc2ea2409bea09f2e1faaf553fe8946fc3213eee`.

Check it against the commit:

```
git ls-tree -r <R8 SHA> -- lib test pubspec.yaml pubspec.lock analysis_options.yaml \
  | awk '{print $3" "$4}' | LC_ALL=C sort -k2 \
  | diff - artifacts/r8_post_audit_remediation_2026-11-04/regression/SOURCE_MANIFEST_git_blobs.txt
```

The output must be empty. Blob ids don't depend on line endings.

`SOURCE_FINGERPRINT_start.sha256` and `SOURCE_FINGERPRINT_end.sha256` (working-tree bytes) are identical, so the source didn't change during the run.

## 7. Test evidence

| | |
|---|---|
| Full suite | **169/169 test files; 2,484 passed, 0 failed, 0 skipped.** Run as memory-bounded sequential batches. |
| Year profiles | all 13 ran, each exactly once (`regression/CASE_COVERAGE.json`) |
| Raw reporter logs | `regression/batch_*.jsonl`, committed |
| Runner checks | `python regression/run_batches.py report` → EVIDENCE OK; `… cases` → CASES OK. Both exit non-zero on any mismatch. |
| Static analysis | `flutter analyze`: no issues |
| Audio | 172/172 guidance clips and 8/8 framing clips match by SHA-1, 180 files; no audio file is changed by R8 |
| Superseded | `regression_run1_superseded/`: the first run (2,448/0), before the gate corrections. Kept for history only. |

**About the raw logs:** they contain absolute paths from the build machine (`C:/Users/<account>/…`). They hold no user data, credentials or device data.

## 8. Known limitations

- **Analytics:** `circle_started` and `circle_closed` fire at the tap, before persistence. They record the interaction, not the save.
- **Resume after a brief interruption:** a "resumed" event after only `inactive` (for example, the notification shade) applies the 6-hour expiry. A Circle left running in the foreground for more than 6 hours is dropped at such a resume; it stays in History as started.
- **Persistent History failure:**
  - today's choice isn't durable, and the user is told each time;
  - an earlier offer that was never started isn't protected by the fail-closed rule; it is recorded by the normal catch-up.
- **No device QA:** the R8 results come from automated tests only.
- **RevenueCat ordering:** the gateway stops an older answer from replacing a newer *published* one. An older answer can still be published while a newer request is unresolved, and is then replaced. The R7 handoff overstated this (R8-19).

## 9. Verdict and scoring requested

Each auditor, independently:
1. Gives a verdict: **PASS**, **CONDITIONAL PASS** or **FAIL**.
2. Lists findings by severity with source evidence. A new finding is never silently treated as resolved.
3. Gives numerical scores. **The original framework has a limitation, stated here before any scoring:**
   - **The post-R7 audits had no numerical scores**, and neither did the two D2 independent audits of 2026-10-21. No earlier score out of 100 exists for any THIRTY audit.
   - **The only numerical framework on record** is the 31-dimension product and commercial scorecard in `docs/audits/THIRTY_POST_V2_INDEPENDENT_AUDIT_GPT6_ASTRA_d89a035.md`:
     - scale 0–10, with a certainty level for each score;
     - explicitly no overall average;
     - previous scores recorded there as UNKNOWN.
     - It assesses product and commercial design, not remediation quality.
   - **Requested:**
     - (a) Where that scorecard is reused, use its exact dimensions and 0–10 scale, and compare with the d89a035 values. Only dimensions affected by R8 need rescoring, for example 11 Trust, 12 Accessibility / robustness, 29 Pre-release readiness and 30 Overall product quality.
     - (b) Any per-category score or total out of 100 is a **new, non-comparable** score. State its rubric and weights before scoring, and label it as having no historical baseline.
     - (c) Don't invent historical scores, and don't silently replace the original method.

## 10. Release gates still open (unaffected by any R8 verdict)

- A2-06: privacy, analytics retention and deletion.
- A2-07: Android backup, device migration and Premium restoration.
- Commercial subscription and APK security checks.
- Six-language localization:
  - zero unapproved hardcoded user-facing text;
  - complete multilingual audio libraries;
  - native-language QA.
- The final commercial release audit.

The KEYBRACE Founder Dashboard is a separate project, and KEYBRACE OS is discontinued. THIRTY Phase E stays on HOLD.
