# R8.3.2: consolidated integrity closure (2026-11-07)

**Implementation-level result: CONDITIONAL PASS.**

- Every finding from both post-R8.3 audits was reproduced and is fixed.
- The full regression is green: 2,914/0/0.
- Two open items need a founder decision:
  - **R832-B1 / R832-B2.** These are new findings, not in either audit. An I3 or I4 manual reversal followed by a retry repeats the Insight's action.
  - **N01-C.** The linearization choice is implemented conservatively.
- **L-1 is OPEN — not fixed, not waived, a pre-release blocker.**
- Nothing is staged, committed or pushed. Phase E is on HOLD.

## Baseline

| What | Value |
|---|---|
| Local HEAD, remote-tracking HEAD and live origin | All three are `9c910773d7bfd3961be75fe3c9a44db41a1b7b27` |
| Parent of HEAD | `e744f505…` |
| Before-trees | `git archive` exports of R8.3 and R8.2 (scratchpad) |
| `pub get --offline` | Run on both exports; lockfiles unchanged |

## Contents

| Path | What |
|---|---|
| `audit_inputs/` | Both audit reports, verbatim. Claude's original scratchpad files (reproducer, controls, raw full-suite log) were recovered from Claude's audit session. `AUDIT_INPUT_HASHES.txt` lists the hashes. `RENAMES.txt` records `.dart` → `.dart.txt` renames; bytes are unchanged. |
| `repro_before_fix/` | The first gate runs on R8.3 and R8.2, before any production change. |
| `final_gate/` | The **authoritative** runs of the exact final test file (sha `cec71102…`) on R8.2, R8.3 and the corrected tree, plus the auditors' 27 original tests on the corrected tree. `MATRIX.md` gives per-test results. `superseded_iterations/` holds earlier versions of the file. |
| `open_findings/` | The R832-B1/B2 probe and the scope-decision note. |
| `CONTRACTS_R8_3_2.md` | Contract A (Start identity and eligibility) and Contract B (Insight idempotence). |
| `ISSUE_REGISTER_R8_3_2.json` | The consolidated register, with every auditor's original ID. |
| `LIMITATIONS_R8_3_2.md` | Remaining risks, including L-1. |
| `source_diffs/` | Per-file diffs and `EOL_NOTE.txt`. |
| `regression/` | The full regression. It uses the R8.3.1 runner, copied unchanged except OUT (`RUNNER_DIFF_vs_R8_3_1.txt`). |
| `AUDIO_VERIFICATION.txt` | The audio asset check. |
| `UNCHANGED_SURFACES.txt` | Checks that billing, dependencies, platform folders and assets are unchanged. |
| `FLUTTER_ANALYZE.txt` | Analyzer output. |
| `GIT_STATE_end.txt` | Git state at the end. |

## Production changes

4 files, +223/−40 (`source_diffs/`). No billing, entitlement, dependency, platform or asset change. No new store, key or migration.

- **`lib/features/plans/domain/circle_plan.dart`**
  - New `PausedStart {circleId, startedAt}` record.
    - It accepts the legacy R8.3.1 string and treats it as excluding the whole Circle, which fails closed.
    - A malformed value makes the Plan unreadable.
  - `_newCycle` carries the record.
  - `recordGuided` excludes only the recorded Start.
  - `noteStartedWhilePaused(at:)` replaces an earlier record of the same Circle, or removes it when the Plan is not paused.
  - New helpers: `samePausedStart` and `copyWith(clearStartedWhilePaused:)`.
- **`lib/features/plans/application/circle_plans_provider.dart`**
  - `prepareStart` (replaces `noteStartWhilePaused`): it settles pending Plans changes, decides on the confirmed Plans, returns the Start instant, and confirms the record.
  - `startNeedsNoWrite` returns true only if nothing is pending, the Plan is not paused and no record exists for this Circle.
- **`lib/features/home/application/recommendation_provider.dart`**
  - The waiting Start uses the instant `prepareStart` returned as its `startedAt`.
- **`lib/features/insights/application/insights_provider.dart`**
  - `apply` waits for its own pending writes.
  - `_keepDisplacedApplication` records a displaced Insight's mark before its Plan provenance is overwritten. If that write is refused, nothing changes.

## Tests

- **New:** `test/features/r832/r832_reproduction_test.dart`, 42 tests.

| Tree | Fail | Pass | N/A |
|---|---|---|---|
| R8.3 | 23 | 19 | — |
| R8.2 | 18 | 13 | 11 |
| Corrected | 0 | 42 | — |

- **Auditors' original tests:** 27/27 pass on the corrected tree, unmodified. These are Claude's delta file and R8.2 controls, and Astra's Appendix B.
- **Full regression:** 202 files, 2,914 passed, 0 failed, 0 skipped.
  - EVIDENCE OK and CASES OK; raw logs validated.
  - 13 year-long profiles, each run exactly once.
  - B8: 6/6.
  - Fingerprints and Git-blob manifests are identical at start and end.
  - INVENTORY OK: the only count change from R8.3.1 is the new file, 0 → 42.
- **Analyzer:** clean.
- **Audio:** 180/180.
