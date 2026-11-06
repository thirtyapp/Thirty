# R8.2 founder decisions A–C: evidence

- **Asked for by:** the R8.2 founder acceptance review ("final required corrections", 2026-11-05).
- **Baseline:** the R8.2 working tree, on HEAD `e935112c408c16d99835280f4e1fafd722d47ed1`.
- **State:** committed in the single R8.2 commit on `step5-billing-integration` (parent `e935112c`), after founder acceptance at implementation level (2026-11-06). Not an independent audit pass; not a release.

## Contents

| Path | What it is |
|---|---|
| `baseline_r8_2_pre_decisions/` | The R8.2 production files, the test files changed here, and the R8.2 documents, exactly as they stood before this work. Code is stored as `*.dart.txt`, so the project-wide `flutter analyze` ignores it. `MANIFEST_CHECK.txt` shows all 27 files match the R8.2 regression's own blob manifest. |
| `repro_before_fix/` | **Failing-before.** The three decision test files run on a git-archive of HEAD with that baseline overlaid: **45 tests, 30 failed, 15 passed** (the passes are controls), with no load errors. A first attempt that didn't compile on the baseline is kept in `first_attempt_superseded/`, with a note. |
| `cross_store_review/` | The interaction review, and the two defects it found and fixed before the regression (FD-B-1, FD-B-2), with logs from before and after the fix. |
| `TEST_CHANGES.md`, `test_change_diffs/` | Every change to an existing test, each with its exact diff. 11 files are timing-only (inserted settle lines; checked mechanically). 5 files change assertions as the decisions require. |
| `CLAUDE_AUDIT_RECONCILIATION.md` | Was **BLOCKED**: the attached Claude post-R8.1 report never reached this session. **Superseded 2026-11-06:** the report was supplied and reconciled. See `../claude_audit_reconciliation/`, where the BLOCKED text is kept unchanged. |
| `AUDIO_VERIFICATION.txt` | 172/172 production and 8/8 framing SHA-1 hashes match. The 180 bundled files equal the union of both manifests. `assets` is unchanged against HEAD. |
| `regression_final/` | **The definitive full regression** (see below). |

The register (`../ISSUE_REGISTER.json`, with entries FD-A, FD-B, FD-C, FD-B-1 and FD-B-2, and amendments to R81-A01, R81-A03 and R81-A08), `../CHANGES.md` and `../LIMITATIONS_R8_2.md` are updated. Their R8.2 versions are in `baseline_r8_2_pre_decisions/docs/`.

## Failing-before → passing-after

| File | Tests | Failing on R8.2 | Passing now |
|---|---|---|---|
| `r82_decision_a_historical_credit_test.dart` | 18 | 13 (paused, left, left + go through again, restarted, lapsed, repeated restarts, another Plan started) | 18 |
| `r82_decision_b_start_persistence_test.dart` | 15 | 8 (pending offer, pending Plan save, never saved, pending then failed, refused Start record) | 15 |
| `r82_decision_c_insight_provenance_test.dart` | 13 | 9 (manual I1 start claimed, manual I3 leave-out claimed, residual × 6, provenance across a later Leave) | 13 |

- **Decision B's 15th test** ("after Delete Circle history …") was added after the failing-before run. Its own before-and-after evidence is in `cross_store_review/`.
- **Controls passing on both trees:** no duplicate credit; Premium rules kept; both "not extended" policy cases; fast repeated taps; a restart after a refusal; a Plan action after a confirmed Start; provenance naming another Insight or cycle; a damaged record; a manual action carrying no provenance.

## Full regression (2026-11-06, 00:06 → 00:29)

- **Run:** 18 batches, one Flutter process at a time, each started only with at least 2.5 GB free (no stop was needed). Batch 18 (the 13 year profiles) ran as its 5 declared parts, 18a–e.
- **Totals:** **191/191 test files: 2,748 passed, 0 failed, 0 skipped.** That is R8.2's 2,702 plus 46 new tests.
- **`report`:** EVIDENCE OK, under the strict R8.2 checks.
- **`cases`:** CASES OK. All 13 year profiles were declared, run, and each run exactly once.
- **B8:** 6/6 (batch 17).
- **Fingerprints:** start and end are identical (369 files). The tree still equals the end fingerprint.
- **`flutter analyze`:** no issues (`FLUTTER_ANALYZE.txt`).
- **Source delta** (`SOURCE_DELTA_vs_R8_2.txt`, `SOURCE_DELTA_vs_R8_1.txt`):
  - Against R8.2: 7 production files changed, 16 existing tests changed, 3 tests added.
  - Against R8.1: 12 production files and 13 tracked tests changed, 12 tests added, 0 removed.

No interrupted or superseded run is mixed into `regression_final/`.
