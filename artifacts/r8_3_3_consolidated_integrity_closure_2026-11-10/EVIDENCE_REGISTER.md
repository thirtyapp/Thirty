# R8.3.3 — evidence register

## Failing-before outcomes on immutable R8.3.2 (`repro_before_fix/r833_reproduction_on_R832.*`)

| Count | Outcome |
|---:|---|
| 30 | tests |
| 13 | pass |
| 17 | fail |

Of the 17 failures, **16 are defect reproductions** and **1 is a fixture/precondition failure**.

| Test | Class | What R8.3.2 did |
|---|---|---|
| A01 (Astra) | **Auditor finding, reproduced** | The Delete reported success. The Plan the user paused was carried on (`active`). `appliedInsight` held the deleted I1 id. |
| A01-v2 | Same root cause (I2 continuation) | Gentler was turned on after the Delete, and the I2 id survived. |
| A01-v8 | Same root cause (interrupted Delete, finished at startup) | The Plan was carried on. |
| A01-v9 | Same root cause (repeated Delete) | The Plan was carried on. |
| A01-v11 | Same root cause (user-owned choices) | The Plan was carried on, against the user's Pause. |
| A01-x1 | Operation-lifetime extension, I3 (founder decision B) | The part was left out after the Delete. No deleted id survived. |
| A01-x2 | Operation-lifetime extension, I4 (founder decision B) | A Circle was kept from a deleted History day. No deleted id survived. |
| A02-A (Astra) | **Auditor finding, reproduced** | Two kept Circles shared one id. One rename and one removal each affected both. |
| A02-B (Astra) | **Auditor finding, reproduced** | I4-A was marked Applied (2026-11-29) from I4-B's kept Circle. |
| A02-B2 | Same root cause (legacy stored collision) | The collision was taken as proof. |
| A02-C | Contract gap, domain uniqueness | A duplicate caller id was accepted. |
| A02-D | Contract gap, concurrent uniqueness | Both concurrent Keeps with one id landed. |
| A02-E | Contract gap, ambiguous-id mutation | One rename renamed two Circles. |
| A02-I | Same root cause, observed through Delete | One id remained across the two kept Circles. |
| X1 (Claude) | **Auditor finding, reproduced** | The Start went ahead after a different Resume. |
| X2 (Claude) | **Auditor finding, reproduced** | The Start went ahead after a different Resume. |
| A01-v10 | **Fixture/precondition (N/A)** | PRECONDITION: "the Plan is paused after the Delete". It could not be built because the A01 defect had already carried the Plan on. It is not counted as a defect reproduction, nor as a pass. |

**The 13 passes** are the controls:

- A01-v3 (×2), v4, v5, v6, v7;
- A02-F, G, H;
- X2-ctl, X-ctl, X3, X4.

They pass on both trees.

## Not applicable on R8.3.2

`r833_identity_contract_test.dart` (ID-1, ID-2, ID-3) does not compile on R8.3.2: `keptIdRandomProvider` and `newKeptId` are missing there. The record is `repro_before_fix/r833_identity_contract_on_R832.*`. The file is classified **N/A**, never counted as a historical pass or a historical failure.

## After the fix

| Suite | Result | Record |
|---|---|---|
| R8.3.3 reproduction suite | 30/30 | `repro_after_fix/` |
| R8.3.3 identity contract | 3/3 | `repro_after_fix/` |
| Prior focused suites (r81, r82, r83, r832) | 482/482 | `focused/` |
| Final-gate checks | 10/10 | `auditor_controls/` |

**Original auditor controls** (`auditor_controls/`): 26 PASS. **AUD-O3: SUPERSEDED** by N01-C. It is not passed, and its bytes are unchanged.

**Claude's post-R8.3.2 probes, unedited:** 6 completed. X4 fails at its own precondition ("I2 current"): the setup cannot be built, as Claude's report records. X1 and X2 now end `notStarted`, with 0 credits.

## Regression runs (kept separate)

| Run | Folder | Status |
|---|---|---|
| Run 1 | `regression_run1_DIAGNOSTIC_INCOMPLETE/` | **Diagnostic, not counted.** |
| Run 2 | `regression/` | **Definitive.** |

**Run 1:**

- Batches 1–17 ran: 2,981 passed, 1 failed (`qa_scenario_test` determinism).
- Claude Code stopped the driver for low memory during B8.
- It ran on the tree **before** the QA-builder fix.

**Run 2:**

| Measure | Result |
|---|---|
| Files | 206 |
| Passed / failed / skipped | 2,999 / 0 / 0 |
| Year-long profiles | 13/13 declared, each exactly once |
| B8 | 6/6 |
| Validators | EVIDENCE OK; CASES OK; INVENTORY OK |
| Strict raw-log check (`commit_verification/RAW_LOG_VERIFICATION_run2.txt`) | RAW OK |
| Start/end source fingerprints and Git-blob manifests | identical |
