# R8.2 consolidated post-R8.1 audit remediation: evidence

- **Baseline:** `e935112c408c16d99835280f4e1fafd722d47ed1` (parent `58b179c9…`), branch `step5-billing-integration`.
- **State:** working tree only. Nothing is staged, committed or pushed.
- **Status:** awaiting founder review. This is not an audit pass.

## Inputs

- **Astra post-R8.1 audit (FAIL):** `docs/audits/THIRTY_INDEPENDENT_POST_R8_1_AUDIT.md`. It is untracked and was never edited: sha256 `afb0dd9ad6e82774bb963e67c6749b44a9505c18954af037ac8a3c565c0c375a`, 104,664 bytes.
- **Claude post-R8.1 audit (CONDITIONAL PASS): not found in the workspace.** NEW-1, NEW-2, NEW-3, E-1 and the marker-retry observation are registered from the founder directive's description (see `ISSUE_REGISTER.json`).

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
