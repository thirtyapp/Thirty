# R8.3.2 + R832-G1 commit: inventory

- **Parent:** `9c910773d7bfd3961be75fe3c9a44db41a1b7b27`.
- **Paths:** `COMMIT_PATHS.txt` (381 lines; it includes this file, that list and `../EVIDENCE_MANIFEST.sha256`).

**Staging.** Everything was staged from the list only.
- `lib/` and `test/` were staged normally. Their blobs therefore equal `../regression/SOURCE_MANIFEST_git_blobs_end.txt`.
- Everything else was staged with `core.autocrlf=false`. Recorded hashes therefore stay byte-exact.

## Included

| Group | Count | What |
|---|---|---|
| Production | 9 | **R8.3.2:** the post-R8.3 findings, the B1/B2 attempt protocol and N01-C. **R832-G1:** the generation counter in `circle_plans_provider.dart`. |
| Test support | 1 | `test/support/r8_fault_disk.dart`, with the `failWhere` harness extension |
| Tests, changed | 7 | Adapted to the founder decisions; each change is listed in `../../r8_3_2_founder_scope_closure_2026-11-07/TEST_CHANGES.md` |
| Tests, new | 3 | `test/features/r832/`: reproduction (42), founder scope (30) and G1 (22) |
| Original audit | 1 | `docs/audits/THIRTY_INDEPENDENT_POST_R8_3_DELTA_AUDIT.md` (Astra), byte-identical (sha256 `89a61f9f…`) |
| Evidence | 360 | These four folders, complete except `__pycache__` (none present): `artifacts/r8_3_2_consolidated_integrity_closure_2026-11-07/` (150, including Claude's original report and scratchpad as audit inputs), `artifacts/r8_3_2_founder_scope_closure_2026-11-07/` (100), `artifacts/r8_3_2_final_gate_2026-11-08/` (6) and `artifacts/r8_3_2_g1_closure_2026-11-09/` (104) |

## Excluded, left as found in the working tree

- **Line-ending-only modifications (no content change):**
  - `lib/core/world_rendering/quiet_trail_hero_asset_view.dart`;
  - `test/features/personal_circle/r6_kept_voice_whole_circle_test.dart`.
- **Unrelated untracked items:**
  - `AGENTS.md`, `android/build/`, `artwork/`;
  - two `assets/worlds/quiet_trail/*_morning_v1.png` files;
  - older phases' local artifacts and raw logs;
  - `artifacts/r8_3_1_founder_lifecycle_correction_2026-11-07/R8_3_PUSH_RECORD.md` (a local push record, as before);
  - the R8.3 run-1 superseded logs.
