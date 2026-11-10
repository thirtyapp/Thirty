# THIRTY — Independent post-R8.3.2 delta audit

**Verdict: CONDITIONAL PASS.** This commit can be accepted as THIRTY's technical engineering baseline, provided the one new LOW finding below (AUD-R832-1) is recorded as a known defect. It cannot be accepted unconditionally. It does not authorise a commercial release: L-1 is still **open, not fixed, not waived, and a pre-release blocker**, and Phase E stays on HOLD.

## 1. Verified immutable target

| Item | Expected | Found |
|---|---|---|
| SHA | `d4cf8c44f8f9…88edd2` | ✅ commit exists; `origin/step5-billing-integration` points to it |
| Parent | `9c910773d7bf…7b27` | ✅ |
| Tree | `2f78849d4b85…f85e60` | ✅ |

I audited the committed tree, exported with `git archive` and `core.autocrlf=false` into my scratchpad. I did not use the implementer's working directory, which has unrelated line-ending changes and untracked files.

I was not given the untracked handoff file, so it plays no part in this audit.

## 2. Methodology and execution limits

- **Read in full:**
  - the production diff, 9 files;
  - `CONTRACTS_FINAL.md`, `CONTRACT_G1.md`, `FINDING_R832_G1_LIFECYCLE_ABA.md` and `TEST_CHANGES.md`;
  - the issue register;
  - the G1 test file;
  - the R832 Group D tests;
  - the original AUD-O3 probe.
- **Ran myself** (Flutter 3.44.8, Dart 3.12.2, Windows):
  - the full regression;
  - `flutter analyze`;
  - the auditors' 27 original tests;
  - the final-gate checks;
  - the G1 tests on both the committed provider and a pre-G1 provider I rebuilt myself;
  - 7 new adversarial probes of my own.
- **Taken from the record and only cross-checked:** the 13 year-long profiles and B8 run individually per batch (I re-ran them only inside my full run), and the audio check.
- **Not established by anything here:**
  - real Android process kill or power loss;
  - real storage-failure behaviour (`FaultDisk` simulates faults; it is not a device);
  - S25 and TalkBack testing.

## 3. Changed files and source-manifest integrity

- **381 changed paths**, the same as `COMMIT_PATHS.txt` line for line (364 added, 17 modified):
  - 9 production files;
  - 11 test and support paths (7 changed tests, 3 new `r832` tests, `r8_fault_disk.dart`);
  - 1 file under `docs/audits/`;
  - 360 evidence files (150 + 100 + 6 + 104).
- **Nothing unauthorised changed.** There is no diff under `assets/`, `android/`, `ios/`, `pubspec.*`, `lib/core/premium` or any billing file. There are 180 audio files, all unchanged.
- **Tested source equals committed source.** All 383 entries of `SOURCE_MANIFEST_git_blobs_end.txt` equal the committed blobs, with none missing or extra. The start and end manifests are identical.
- **Committed provider equals the tested one.** In CRLF form the committed provider hashes to `f08ed391…`, the end fingerprint of the G1 run.
- **Evidence manifests verify:**
  - 149, 99 and 103 entries all OK;
  - final-gate `SHA256SUMS` 5 of 5 OK;
  - `AUDIT_INPUT_HASHES` OK.
- **Original audit documents are unchanged:**
  - Astra `89a61f9f…` (both copies);
  - Claude `d1e5e700…`;
  - my R8.3 probe file `6c3983e3…`, byte-identical to my own scratchpad copy from session 5091d12d.
- **Analyzer:** "No issues found!", re-run by me.

## 4. Prior-finding closure matrix

| Finding | Status | Evidence |
|---|---|---|
| Astra R83-N01 (orphan paused Start) | **FIXED** | `PausedStart` now names the Start's instant (`circle_plan.dart:714`). Tests B1, B-tie, B7 and both AUD-R83-3 originals pass. |
| Astra R83-N02 (optimistic Start) | **FIXED** | The fast path refuses any unsaved change or a paused confirmed Plan (`circle_plans_provider.dart:793`). Tests C1, C1b, C1c and C3 pass. |
| Astra R83-N03 (Insight provenance overwritten) | **FIXED** | `_keepDisplacedApplication` (`insights_provider.dart:487`). Tests D1, D-ctl3 and Be pass. |
| AUD-R83-1 | **FIXED** | `startedWhilePaused` is carried into the new cycle (`circle_plan.dart:1054`). The 5 original probes pass. |
| AUD-R83-2 | **FIXED** | The original probe passes. |
| AUD-R83-3 | **FIXED** | Both original probes pass. |
| R832-B1 (I3 replayed after Put back) | **FIXED (bounded)** | Receipt protocol (`insights_provider.dart:449, 578`). |
| R832-B2 (I4 replayed after the kept Circle is removed) | **FIXED (bounded)** | `keptId` proof (`insights_provider.dart:610`). |
| **R832-G1** (lifecycle ABA during a pending Start) | **PARTIAL** | All 27 listed cases pass, but one remaining path escapes (AUD-R832-1, §10). |
| N01-C (cancel a pending Start) | **FIXED** | `prepareStart` and `PlanStartCancelled` (`recommendation_provider.dart:1929`). It shares the AUD-R832-1 gap. |
| Original R8.2 findings (R82-N01…N05, AUD-N1, AUD-N2, AUD-N3) | **FIXED** | All original probes pass on this commit. |
| D1 (Delete reports success only when complete) | **PARTIAL** | L-1 is still open. |
| D2 (a Pause while the Start is pending earns no credit) | **PARTIAL** | Still violated through AUD-R832-1. |
| D3 (original date, no repeated action) | **FIXED (bounded)** | Only for the attempt protocol's limits (§7). |
| D4 (Delete write computed from the confirmed state) | **FIXED** | Delete goes through `_confirm(kept)` (`circle_plans_provider.dart:1138`). |
| D5 (no default written over an unexpected stored value) | **PARTIAL (recorded)** | The analytics-cohort default overwrite is a register item, OPEN LOW. I did not re-test it. |

## 5. R832-G1 generation and ABA assessment

**The mechanism** (`circle_plans_provider.dart:104-165, 250-296, 892-975`):
- The per-Plan count is incremented only in `_confirm`, and on an uncertain write failure.
- The epoch is renewed on every `build()`.
- `prepareStart` checks the conditions after the waits and again after the paused-Start record's own write.

The only direct assignment of `_durable` outside `_confirm` is Delete's optimistic forget at line 1119, which changes no lifecycle or cycle.

**Challenge cases from the brief:**
- **Cases 1–4, 6, 7, 10 and 11:** cancelled as required (A1–A3, G1, G2, G5, R1, R2, R5 and G6).
- **Case 5** (a transition refused before it is saved): not counted (A4, G3).
- **Case 8** (a pending Start during Delete): allowed (R4) and cancelled after an ABA (R3).
- **Case 9** (a failed eligibility write, then a fresh Start): handled (B2, B7).
- **Case 12** (cancellation while a Today write is still queued): cancels silently and leaves no record (AUD-O3′ below).

**Failing-before, run myself.** I rebuilt the pre-G1 provider by reverse-applying `G1_vs_2944_tree.diff`; its CRLF hash `4197ebad…` equals the 2,944-pass fingerprint. On it I got exactly the recorded **14 failures**: Check A1–A3, G1 A1–A3, G1, G2, G4, G5, R1, R2, R3 and R5. On the committed provider: **32 of 32 pass**.

**The gap (AUD-R832-1).** `startConditions` adds +1 whenever the shown Plan differs from the confirmed Plan (line 947). That +1 is meant to stand for *the* change the user saw being saved, but nothing ties it to that particular change. If that change is refused, a different later confirmed change can satisfy the count.

**What fails safe.** Uncertain writes, rebuilds, restarts and multiple pending writes all fail safe, as `CONTRACT_G1` documents.

## 6. Start identity and historical-credit assessment

| Rule | Result |
|---|---|
| Start → Pause → durable Close is credited once | ✅ (C1) |
| Pause → Start → Close is never credited | ✅ (C2) |
| New cycle or next-day catch-up never credits an excluded Circle | ✅ (AUD-R83-1 originals) |
| Close before Leave is credited to the original cycle | ✅ (A-ctl2) |
| An abandoned Start is never credited because the Plan was resumed | ✅ (A1, AUD-O3′) |
| A cancelled Start leaves no session, no record and no exclusion of a later Start | ✅ (A1–A3, G1, G2, G4, G5, G7, R7, R8) |

**Exception: AUD-R832-1 (X2).** A Start pending on an active Plan can be credited after the user pauses and resumes, which breaks D2. It needs one storage refusal to reach. The credit does match the lifecycle the store confirmed at the moment the Circle actually started.

## 7. I3/I4 receipt assessment

**The protocol** (`insights_provider.dart:249, 435-486, 578-655`):
- A receipt is confirmed before the target is changed.
- An uncertain outcome keeps the receipt, and nothing is replayed.
- The Insight is marked applied only from exact proof: `byInsight`, or the `keptId`.
- A damaged receipt makes the snapshot unreadable, and the snapshot is kept as stored.
- Delete removes receipts.
- Founder-scope tests (30 of 30) and Check B Ba–Be pass in my run.

**Limitation: a receipt can block an Insight forever.** If a write throws before anything lands, the receipt stays forever. That snapshot is then permanently `stale`, because `insight_engine.dart:621` treats any unresolved receipt as stale. Only Delete clears it. The user can still make the change by hand. `CONTRACTS_FINAL` "Known limits" discloses this. However, the label the user sees, "No longer current", does not truthfully say "outcome unknown". I count this as a disclosure gap, not a defect.

**Older records.** An I4 applied before R8.3.2 whose mark was lost cannot be attributed. This is disclosed.

## 8. I1/I2 provenance assessment

- A provenance record is replaced only after the displaced Insight's mark has been reconciled and that mark is durable. If the mark is refused, the later Insight is refused too (D-ctl3).
- **Concurrent I1 + I2 on one Plan (probe X4):** the setup could not be built, because I1 needs the Plan paused and I2 needs it active. `apply` also waits for pending mark writes before it starts.
- **Absence of provenance as proof.** If an uncertain Plans write's restore write also fails, the disk and memory can briefly disagree. The next whole-record save resolves this, and replaying the same change is harmless. This is CONTRACT_G1 limitation 4. Absent provenance is therefore sound as proof only for the current set of writers, which `FINDING_R832_G1` states.

## 9. Cross-store, Delete and restart assessment

- **Delete and Insights:** snapshots and receipts are removed. The Leave-it-out choice and the kept Circle are kept; only the `byInsight` attribution is removed (Bd, R3).
- **Delete and the paused-Start record:** no record survives (original "Delete × paused Start" probes).
- **Interrupted Delete** finishes at the next start (Bd).
- **Queued writes don't bring deleted data back** (AUD-N3 original, R8.2 A02 path).
- **Restart:** tested only by simulation.

## 10. New findings

**AUD-R832-1 — LOW (D2 / G1 intent): the pending +1 allowance can be satisfied by the wrong change.**

- **Where:**
  - `lib/features/plans/application/circle_plans_provider.dart:947` (`final pending = … ? 0 : 1`);
  - `:959-966` (`_startStillValid` compares only the count).
- **Scenario:**
  1. The Plan is paused on disk.
  2. A Resume is being saved (W1, held).
  3. Start is tapped while the offer save is held, so the accepted state is `(active, gen 1)`.
  4. The user taps Pause (W2) and then Resume (W3).
  5. W1 is refused (`returnsFalse`). It is not the latest write, so nothing is rolled back.
  6. W2 lands: paused to paused, so nothing is counted.
  7. W3 lands: paused to active, so the count becomes 1.
  8. The offer lands.
- **Result:** the Start goes ahead. After Close and two restarts there is **1 credit** and the Plan is active.
- **Control (X2-ctl):** the same taps with W1 landing are **cancelled**, with 0 credits. This is the A2 behaviour the gate required.
- **The fix doesn't touch this path:** X2 gives the same result on the pre-G1 provider.
- **Weaker variant (X1):** the Resume is refused and rolled back, the user resumes again, and the Start goes ahead and is credited. Under the G7 reasoning ("the Plan the Start was asked for on never existed"), this arguably should cancel.
- **Why LOW:**
  - it needs a storage refusal plus two more taps while the Start is pending;
  - it leaves no orphan record and no exclusion of a later Start;
  - the credit matches the lifecycle confirmed at the Start instant, which is the same harm class the founder accepted when G1 was opened.
- **Why it still matters:** it contradicts the contract's claim that the extra +1 "is the one change the user saw still being saved", and it breaks D2.

**Disclosure gap, not a defect:** an unresolved receipt shows "No longer current" when the real state is "outcome unknown" (§7).

## 11. Adversarial reproductions I ran

The probe file is in a disposable copy outside the repository: `C:\Users\thoma\AppData\Local\Temp\claude\b7fd4c17e92f619e\fbb08042-2678-44a1-ab6c-f2fcf240c1a3\scratchpad\aside\zz_audit\audit_r832_delta_test.dart`.

| Probe | Committed tree | Pre-G1 provider |
|---|---|---|
| X1 (refused Resume, then Resume again) | started, 1 credit | started, 1 credit |
| **X2** (refused Resume, then Pause + Resume) | **started, 1 credit** | started, 1 credit |
| X2-ctl (Resume lands, then Pause + Resume) | cancelled, 0 credits ✅ | started (the original G1 defect) |
| X3 (Pause write's acknowledgement lost, then a fresh Start, process death) | the restore write puts the disk back to active; consistent, 1 credit | same |
| X3-ctl (same, no process death) | 1 credit, consistent | same |
| AUD-O3′ | cancelled, no record; fresh Start on the paused Plan; 0 credits; 1 History Start ✅ | — |
| X4 (concurrent I1 + I2) | setup can't be built (lifecycle preconditions exclude each other) | — |

## 12. Full regression-evidence verification

**My own full run:** `flutter test -r json --concurrency=4` on the committed export gave **2,966 passed, 0 failed, 0 skipped, in 204 files**, with exit code 0 and an empty stderr.

**Focused runs:**
- r81, r82, r83 and r832: 482 of 482 passed;
- auditor originals + final gate + G1: 64 passed, 2 failed (AUD-O3, and my X4 precondition).

**Recorded logs:** I recomputed the totals from the 23 raw batch logs and got 2,966 / 0 / 0 in 204 files.
- 13 year-long profiles (batches 19a–e: 3 + 3 + 3 + 2 + 2);
- B8 6 of 6 (batch 18);
- every batch reports `done.success = true`.

The claims reconcile.

## 13. AUD-O3 adjudication

The original probe (`audit_r82_order_test.dart:14-43`) asserted `started` only as an intermediate step on the way to an exploratory question ("credited?"). It printed the answer and asserted nothing about credit.

Under N01-C, a Pause confirmed while the Start is pending cancels that Start. That makes the `started` step obsolete by design.

My AUD-O3′ asks the original question directly. The Start is cancelled with no record left, and a fresh Start on the paused Plan, followed by Close and Resume, is never credited.

**Verdict:** truly superseded, not a defect. Count it as **26 PASS + 1 SUPERSEDED**, not as 27 PASS.

## 14. Six-invariant assessment

| Invariant | Assessment |
|---|---|
| 1. Durable confirmation | PASS, bounded to `FaultDisk` simulation |
| 2. Exact attribution of Insight actions | PASS, bounded (legacy I4 can't be attributed; receipt can block an Insight for good) |
| 3. Idempotence | PASS, bounded |
| 4. Temporal validity | **QUALIFIED** by AUD-R832-1 and RL-4 (historical timestamps without a time-zone offset) |
| 5. Serialization fidelity | PASS for the changed codecs (`InsightAttempt`, `PausedStart`: unknown fields kept, damaged records read as unreadable) |
| 6. Delete completeness | **NOT MET** while L-1 is open |

A full six-invariant PASS cannot be claimed.

## 15. L-1 and remaining blockers

- **L-1:** OPEN, NOT FIXED, NOT WAIVED, PRE-RELEASE BLOCKER. It is untouched by this commit and blocks commercial release. It does not block accepting this commit as an engineering baseline, because it is a known defect that was deliberately left for a separate fix.
- **Also outstanding:**
  - AUD-R832-1 (LOW): fix it or explicitly accept it;
  - RL-4;
  - real-device process-kill and storage-fault testing;
  - S25 and TalkBack testing;
  - the receipt disclosure wording (§7);
  - the D5 cohort item.

## 16. Final verdict: CONDITIONAL PASS

| Question | Answer |
|---|---|
| Can `d4cf8c44` be accepted as THIRTY's technical engineering baseline? | **Yes, conditionally.** All prior findings verify as fixed apart from R832-G1, which is partial. The evidence is complete and reproducible, and my independent full regression matches the record. The condition is that AUD-R832-1 is recorded as a known LOW defect for the founder to fix or accept. |
| Unconditional engineering acceptance? | **No.** |
| Commercial release? | **Not authorised.** L-1 is a blocker and Phase E is HOLD. |

No source, staging, commit or push was made. All test copies are under the session scratchpad. I can also put this report on a private shareable page if that's useful.
