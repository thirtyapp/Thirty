# R8.3 auditable commit: inventory

- **Parent:** `e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8`.
- **Paths:** `COMMIT_PATHS.txt` (241 lines, this file and that list included).
- **Staging:** from the list only. `lib/` and `test/` were staged normally, so their blobs equal `../regression/SOURCE_MANIFEST_git_blobs_end.txt`. Everything else was staged with `core.autocrlf=false`, so recorded hashes stay byte-exact.

## Included

| Group | Count | What |
|---|---|---|
| Production | 15 | R8.3 corrections and the R8.3.1 Start-eligibility correction (`lib/`) |
| Test support | 2 | `test/support/r8_fault_disk.dart` (changed), `test/support/r83_invariants.dart` (new) |
| Tests | 8 | `test/features/r83/` (new, 98 tests) |
| Original audits | 2 | `docs/audits/THIRTY_INDEPENDENT_POST_R8_2_AUDIT.md`, `docs/audits/THIRTY_CLAUDE_INDEPENDENT_POST_R8_2_AUDIT.txt`, byte-identical |
| Architecture review | 1 | `artifacts/pre_r8_3_architecture_review_2026-11-06/ARCHITECTURE_REVIEW.md` |
| R8.3 evidence | — | `artifacts/r8_3_bounded_integrity_hardening_2026-11-07/`: register, founder decisions (including the L-1 deferral), changes, limitations, audit handoff, repros, auditor controls, E-1, pre-R8.3.1 regression. Run 1: only its `INCOMPLETE.txt` and run logs |
| R8.3.1 evidence | — | `artifacts/r8_3_1_founder_lifecycle_correction_2026-11-07/`: repros, passing-after, the L-1 assessment, auditor controls, the definitive regression, commit verification |

## Excluded, left as found in the working tree

- **Line-ending-only modifications (no content change):**
  - `lib/core/world_rendering/quiet_trail_hero_asset_view.dart`;
  - `test/features/personal_circle/r6_kept_voice_whole_circle_test.dart`.
- **R8.3 run 1's superseded raw logs and summaries** (`regression_run1_INCOMPLETE/batch_*`, `__pycache__`).
- **Unrelated untracked items:** `AGENTS.md`, `android/build/`, older phases' local artifacts and raw logs.
