# R8.2 consolidated post-R8.1 audit remediation: evidence

- **Baseline:** `e935112c408c16d99835280f4e1fafd722d47ed1` (parent `58b179c9…`), branch `step5-billing-integration`.
- **State:** committed in the single R8.2 commit on `step5-billing-integration` (parent `e935112c`), after founder acceptance at implementation level (2026-11-06). Not an independent audit pass; not a release.
- **Status:** founder-accepted at implementation level (2026-11-06). Independent audits of the R8.2 commit not started; handoff: `INDEPENDENT_AUDIT_HANDOFF_R8_2.md`.

## Inputs

- **Astra post-R8.1 audit (FAIL):** `docs/audits/THIRTY_INDEPENDENT_POST_R8_1_AUDIT.md`. It is untracked and was never edited: sha256 `afb0dd9ad6e82774bb963e67c6749b44a9505c18954af037ac8a3c565c0c375a`, 104,664 bytes.
- **Claude post-R8.1 audit (CONDITIONAL PASS): not found in the workspace at first** (supplied later, on 2026-11-06; see "Original Claude post-R8.1 report: reconciled" below). NEW-1, NEW-2, NEW-3, E-1 and the marker-retry observation are registered from the founder directive's description (see `ISSUE_REGISTER.json`).

## Contents

| Path | What it is |
|---|---|
| `ISSUE_REGISTER.json` | All finding IDs, with auditor, severity, reproduction, root cause, fix, files, tests, status and deduplication. |
| `CHANGES.md` | Every source change, by file and finding. |
| `LIMITATIONS_R8_2.md` | The RL-4 boundary, the superseded R8.1 limitation, and the points for founder review. |
| `repro_before_fix/` | **Definitive failing-before run:** the final 9 R8.2 test files against a `git archive` export of e935112c (`BASELINE.txt`: lib/ blob-identical). 103 tests, of which **73 fail**, all on assertions or runtime type errors, with no compile errors. `SUMMARY.txt` and `SUMMARY.json` summarise the raw `*.jsonl` logs. |
| `repro_before_fix/first_drafts_superseded/` | First drafts run on the unchanged lib/ in this tree: 95 tests, 67 failures. Superseded; see `SUPERSEDED.txt`. |
| `e1_runner_check/` | The E-1 check. The R8.1 runner accepts a missing part, a duplicated part and an undeclared part (`BEFORE_r8_1_runner.txt`, CHECK FAIL). The R8.2 runner rejects all six damaged copies and accepts the intact one (`AFTER_r8_2_runner.txt`, CHECK PASS). |
| `regression_final/` | **The definitive full regression** (see below). The raw `batch_*.jsonl` logs and their summaries; `RUN_LOG.txt`, `MEMORY_LOG.txt`, `REPORT_OUTPUT.txt`, `CASES_OUTPUT.txt`, `COVERAGE_MANIFEST.json`, `CASE_COVERAGE.json`, `FLUTTER_ANALYZE.txt`; the start and end fingerprints, the blob manifest and the source delta against R8.1; `drive_regression.sh` and `run_batches.py`. |
| `AUDIO_VERIFICATION.txt` | 172/172 production and 8/8 framing SHA-1 match; the 180 bundled files are exactly the union of both manifests. |

## Final regression (2026-11-05, 20:58 → 21:47)

- **Runs:** 18 batches, one Flutter process at a time, each waiting for at least 2.5 GB of free memory (no stop was needed). Batch 18 (the year-long profiles) ran as its 5 declared parts, a to e.
- **Totals:** 188/188 test files, **2,702 passed, 0 failed, 0 skipped** (2,599 from R8.1 plus 103 new).
- **Checks:** `report`: EVIDENCE OK, under the stricter R8.2 checks. `cases`: CASES OK, with all 13 year profiles each run exactly once. The six B8 cases all pass (batch 17).
- **Fingerprints:** start equals end (366 files).
- **Source delta against R8.1:** 11 production files changed and 9 test files added. No existing test changed.
- **`flutter analyze`:** no issues.

There are no interrupted or superseded runs inside `regression_final/`.

## Founder decisions A–C (acceptance review, 2026-11-05)

Implemented in the working tree; evidence in `founder_decisions/` (start with its README). Final regression: 191/191 files, 2,748 passed, 0 failed, 0 skipped; EVIDENCE OK; CASES OK; fingerprints identical; analyze clean; audio 172 + 8. The section above records R8.2 as it stood before them. The Claude post-R8.1 report attachment did not reach the session: reconciliation blocked (`founder_decisions/CLAUDE_AUDIT_RECONCILIATION.md`).

## Original Claude post-R8.1 report: reconciled (2026-11-06)

- **The report.** Supplied at 09:08 on 2026-11-06, after the founder decisions were implemented. It is preserved unedited: `docs/audits/THIRTY_CLAUDE_POST_R8_1_AUDIT_REPORT.txt`, SHA-256 `96593e20a24cba993dc45973118d2ed021dcae25c465fa0078ac87b29e4c23a1`, 52,094 bytes.
- **The reconciliation.** See `claude_audit_reconciliation/` (start with its README).
  - Every finding maps to a register entry, and none is open on the current tree.
  - The auditor's own reproductions were run unchanged: on R8.1, 4 pass / 9 fail, exactly as reported. On the current tree, 8 pass / 5 fail; those 5 assert replaced R8.1 behaviour, or are a date-string false positive.
  - The adapted forms fail 6/6 on R8.1 and pass 6/6 now.
- **The one source change.** A new test file holding the report's NEW-1 trigger scenarios.
- **Full regression** (`claude_audit_reconciliation/regression_final/`, 09:24 → 09:54):
  - Totals: **192/192 files, 2,753 passed, 0 failed, 0 skipped**.
  - `report`: EVIDENCE OK. `cases`: CASES OK, with 13/13 year profiles each run once. B8: 6/6.
  - Fingerprints: start and end identical (370 files). The only delta against the founder-decision run is the new test file.
  - `flutter analyze`: no issues. Audio: 172/172 + 8/8.

## Final Plan lifecycle policy (2026-11-06)

- **Implementation.** See `lifecycle_policy/` (start with its README).
- **First full regression.** `lifecycle_policy/regression_final/` was **interrupted** by low memory and is invalid as evidence (see its `INTERRUPTED.txt`).
- **Definitive full regression.** `lifecycle_policy/regression_rerun/`, 12:50 → 13:23, authorized by the founder:
  - Totals: **193/193 files, 2,774 passed, 0 failed, 0 skipped**. That is the 2,753 above plus the 21 lifecycle tests.
  - `report`: EVIDENCE OK. `cases`: CASES OK, with 13/13 year profiles each run once. B8: 6/6. Every batch exited 0.
  - Fingerprints: start, end and preflight identical (371 files).
  - `flutter analyze`: no issues. Audio: 172/172 + 8/8.
