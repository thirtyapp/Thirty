# Original Claude post-R8.1 audit: reconciliation with the R8.2 register

- **Date:** 2026-11-06.
- **State:** committed in the single R8.2 commit on `step5-billing-integration` (parent `e935112c`), after founder acceptance at implementation level (2026-11-06). Not an independent audit pass; not a release.
- **Supersedes:** the BLOCKED note `founder_decisions/CLAUDE_AUDIT_RECONCILIATION.md`. It is kept here unchanged as `CLAUDE_AUDIT_RECONCILIATION_BLOCKED_superseded_2026-11-06T0009.md`.

## 1. The report

| | |
|---|---|
| Path | `docs/audits/THIRTY_CLAUDE_POST_R8_1_AUDIT_REPORT.txt` (untracked; not edited) |
| SHA-256 | `96593e20a24cba993dc45973118d2ed021dcae25c465fa0078ac87b29e4c23a1` |
| Size | 52,094 bytes, 308 lines. LF line endings, no BOM. With `core.autocrlf=true`, a CRLF checkout of a future commit would hash differently; check against the committed blob. |
| On disk since | 2026-11-06 09:08:31 +01:00 |
| Verdict (verbatim) | "CONDITIONAL PASS. R8.1 baseline acceptance is blocked at e935112 until NEW-1 is fixed and delta re-audited." |
| Input hashes it cites | Astra `afc3631c…2f0ab1` and Claude `2519e0b2…64f1c0` both equal the R8.1 handoff (`artifacts/r8_1_consolidated_remediation_2026-11-05/AUDIT_HANDOFF.md`). |

**Timing, stated plainly.**
- The R8.2 remediation (2026-11-05) and founder decisions A–C (regression finished 2026-11-06 00:29) were implemented without this report. They were built from the founder directive's description of it.
- The report first became available at 09:08 on 2026-11-06.
- Everything below was done after that, against the unchanged tree. The tree matched the founder-decision regression's end fingerprint byte for byte (`SOURCE_FINGERPRINT_before_new_test.sha256`).

## 2. Finding-by-finding reconciliation

| Original finding | Register entry | Same root cause? | Differences from the directive's description | Status on the current tree |
|---|---|---|---|---|
| **NEW-1** MEDIUM, blocking. A stage Circle becomes unsaveable once `lastServed` no longer matches it. | NEW-1, with R81-A03 kept as a related, distinct entry | Yes: `confirmServed` checked against the Plan's single mutable `lastServed`, which `_newCycle` never restores. | The register reproduced only "Leave + Go through it again". The original also names three more triggers: **stage 5 → Plan ended → "Go through it again"** (its "most natural case"), **the I1 application**, and **Leave, then Start the same Plan**. It also names **Trigger B**: *one* transient Plans failure at choice time, after which the whole Circle could be run, closed and lost, with "not even 'shown'" left in History. Its acceptance condition asks for a regression test for both triggers. | **Fixed.** All of the original's scenarios pass (§3). The register's R8.2 tests covered the mechanism, not these exact scenarios, so they are now in the suite: `test/features/r82/r82_claude_audit_new1_triggers_test.dart`, 5 tests, failing on R8.1 and passing now (§4). |
| **NEW-2** LOW. After a failed Delete, a later failed Plans or Insights save brings deleted evidence back into memory. | R81-A02 / NEW-2 (merged) | Yes: rollback to a `_durable` that still held pre-deletion evidence. | None material. The original's sequence (Delete fails, unrelated save fails, store heals, next save) is the R8.2 test "Delete whose Plan evidence write fails, then an unrelated Plan…". | **Fixed.** Memory holds 0 records after the failed save, 0 on disk after the heal, 0 after a restart (DIAG A3, R-A3). |
| **NEW-3** LOW. `confirmed()` can report notSaved for a change that is on disk. | NEW-3 | Yes | None. | **Fixed.** The original A4 (×2 faults) passes unchanged. |
| **Related observation** (not a finding). If only the I1/I2/I3 applied mark fails, a retry returns **`alreadyApplied`** without marking. | R81-A08 / marker-retry observation (merged), then FD-C | Yes | **Wording.** The register (from Astra A08) says the retry returns `notAvailable`. Both are exits of the same gap: `alreadyApplied` while the Insight still reads as current (target already in place), `notAvailable` once it reads as stale. | **Fixed by FD-C.** The A08 tests cover both a same-session retry and a retry after a restart. Both require the mark to be recorded from the change's own provenance, with the change not made again. |
| **E-1** LOW, evidence tooling. `report` doesn't detect a missing part. | E-1 | Yes | The original mutation is removing one part summary. The register's test covers that and more (a copied part, an undeclared part). | **Fixed.** The original mutation on a disposable copy of the R8.2 runner gives `report` exit 1 EVIDENCE MISMATCH and `cases` exit 1 CASES MISMATCH. The intact copy gives EVIDENCE OK (`e1_mutation/`). |
| **Closure matrix:** 19 R8.1 findings closed; RL-1 PARTIAL "because its new gate causes NEW-1". | n/a | n/a | n/a | RL-1's residual is NEW-1, now closed. The other R8.1 closures are protected by the existing suite, which passes in full (§5). |
| **"Must not be closed silently":** a corrected description of the "pending-then-failed" limitation. | `LIMITATIONS_R8_2.md` | n/a | The R8.2 file recorded only that the limitation was superseded. | **Done.** The corrected description is added to `LIMITATIONS_R8_2.md`, followed by what replaced it. |
| **"Must not be closed silently":** the founder's pre-commercial decision on RL-4. | RL-4 | n/a | n/a | **Still open, for the founder.** Unchanged. |
| **Commercial gates** (A2-06, A2-07, billing and APK security, six-language localization, multilingual audio, real-device QA, final commercial audit) | n/a | n/a | n/a | **All still OPEN.** Untouched. Phase E remains HOLD. |

No finding in the original is missing from the register. No original reproduction reveals a defect on the current tree.

## 3. The auditor's own reproductions, run unchanged

The files were taken from the auditor's scratch folder named in report §5. They are kept verbatim as `original_auditor_repro/*.dart.txt`, and the SHA-256 of each copy equals its original's. They ran in scratch exports (`git archive e935112`, with the working tree's `lib/` and `test/` overlaid for "current"), never from the repository.

| Test | R8.1 (e935112) | Current tree |
|---|---|---|
| A1: Start; Leave + Go through it again; Close | FAIL (the report's result) | PASS |
| A1: Closed; Leave + Go through it again; answer | FAIL | PASS |
| A2 throws / returnsFalse: one transient failure at choice | FAIL ×2 | FAIL ×2 *(see below)* |
| A3 throws / returnsFalse: failed Delete, then a failed save | FAIL ×2 | FAIL ×2 *(see below)* |
| A4 throws / returnsFalse: `confirmed()` notSaved | FAIL ×2 | PASS ×2 |
| Stage 5 → "Go through it again" → answers | FAIL (`saveStatus=false`, attempt null) | PASS (`saveStatus=true`, answers in History and on disk) |
| CONTROL A1 | PASS | PASS |
| DIAG A1 | prints: disk stays `started`, no Close in History, after a restart too | prints: `closed`, answered, in History, after a restart too |
| DIAG A2 | prints: closed in memory, nothing on disk or in History | FAIL *(see below)* |
| DIAG A3 | prints: in memory `afterFailedSave=1`, on disk after heal `1` | prints: `0`, `0`, `0` after a restart |
| **Totals** | **4 pass / 9 fail**, matching report §5: 8/8 reproductions fail, stage-5 fails, the control passes | **8 pass / 5 fail** |

**Why five original tests still fail on the current tree. Neither reason is a defect:**

- **A2 ×2 and DIAG A2: an assertion of R8.1 behaviour that was intentionally replaced.**
  - These tests dereference `recommendation!` after the failed choice. A2's own reason string is "stays on screen (accepted limitation)", the R8.1 limitation the report criticises.
  - On the current tree the unsaveable, unstarted offer is **taken back, and the user is told** (R81-A03, narrowed by founder decision B). The dereference therefore throws `Null check operator used on a null value`.
  - The report's own acceptance condition is "never silently run and then lost". The adapted test R-A2 checks exactly that, and it holds (§4).
- **A3 ×2: a false positive in the test's last check.**
  - The memory assertion that failed on R8.1 now passes.
  - The final `isNot(contains(id))` fails only because the Circle id is the date `2026-10-12`, which is also the cycle's own `startedOn` and `gentlerSince`.
  - The stored Plans read `"records":[]`. DIAG A3 and R-A3 count 0 records on disk, also after a restart.

## 4. Adapted reproductions and the new regression test

- **`adapted_repro/audit_r81_reconciliation_adapted_test.dart.txt`** (scratch only; never in the repository). It contains:
  - R-A2 ×2: the acceptance condition "never run and then lost", either branch;
  - R-A3 ×2: stage records counted on disk;
  - R-L: Leave, then Start the same Plan;
  - R-I1: stage 5 ended, then the I1 application's `goThroughAgain`, and a restart.
  - **R8.1: 0 pass / 6 fail. Current: 6 pass / 0 fail.**
- **`test/features/r82/r82_claude_audit_new1_triggers_test.dart`**: the only source change in this pass. It is a new test file; no production code and no existing test changed. SHA-256 `ee7aff28c639db44e30c773ef54a9323b98590e610bc00956700413f2ada38a1`.
  - Trigger A: the stage 5 review's "Go through it again"; the I1 application (`confirmed(goThroughAgain(byInsight:))`, the call `InsightsNotifier._direct` makes); Leave, then Start the same Plan.
  - Trigger B ×2 faults: the offer is taken back before it can start, the user is told, and the next choice is saved, runs, and reaches History across a restart.
  - **Failing before, on R8.1: 5 of 5 fail** (`new_regression_test/new_test_before_r81.*`). The R8.1 copy differs only in dropping `byInsight:`, which R8.1 lacks (`R8_1_VARIANT.diff`).
  - **Passing after: 5 of 5** (`new_test_after.*`).

## 5. Verification after the change

See `regression_final/`, and `../README.md` for totals.
- **Audio:** `AUDIO_VERIFICATION.txt` (172/172 and 8/8 SHA-1, 180 = union of the manifests, no asset changed).
- **Analyze:** `FLUTTER_ANALYZE.txt`.
