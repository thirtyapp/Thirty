# R8.1 — commit inventory (founder authorization, 2026-11-05)

One commit on `step5-billing-integration`, parent `58b179c99866e234acd63e4e241590af36b9b186`. Staged by explicit path list; no `git add -A`.

## Included (143 paths)

| Group | Paths |
|---|---|
| Production code (12 modified + 1 new) | `lib/core/storage/preservation_writes.dart` (new), `store_save_failures.dart`, `circle_history_deletion.dart`, `recommendation_provider.dart`, `suggestion_preferences.dart`, `memory_page.dart`, `journal_save_failure_notice.dart`, `insights_provider.dart`, `insight.dart`, `kept_circles_provider.dart`, `composed_session.dart`, `circle_plans_provider.dart`, `circle_plan.dart` |
| Test support | `test/support/r8_fault_disk.dart` (adds the `hold()` latch) |
| Adjusted existing tests (founder-approved, RL-1) | `test/features/home/r8b_precommit_persistence_test.dart`, `test/features/home/r3_persistence_delete_test.dart` |
| New R8.1 tests (10 files, 115 tests) | `test/features/r81/*.dart` |
| Independent post-R8 audit reports, byte-for-byte | `docs/audits/THIRTY_INDEPENDENT_POST_R8_AUDIT.md` (sha256 `afc3631c…`), `docs/audits/THIRTY_CLAUDE_POST_R8_AUDIT_REPORT.md` (sha256 `2519e0b2…`: the delivered LF text, as committed; a CRLF checkout reads `8ebec3ce…`) |
| Regenerated B8 review pack | `artifacts/v2_phase_d2/b8/CONTENT_REVIEW_PACK.md`, `MANIFEST.json` |
| R8.1 evidence | `artifacts/r8_1_consolidated_remediation_2026-11-05/`: README, AUDIT_HANDOFF, CHANGES, ISSUE_REGISTER, this inventory, the RL-4 record, the localization additions, three audio verification files, audit inputs, `repro_before_fix/` and `repro_before_fix_rl/` (with raw logs), `regression_final/` (raw logs, summaries, manifests, fingerprints, blob manifest, runner, analyzer and memory logs), and the labelled summaries of the superseded runs |

## Excluded from the evidence folder (kept on disk, not deleted)

- Raw JSONL logs of superseded or abandoned runs:
  - `regression/batch_*.jsonl` (the 2,567-test run before the RL corrections);
  - `regression/interrupted_run1_batch10/batch_10_INTERRUPTED.jsonl`;
  - `regression_final/aborted_attempt1_review_pack_stale/batch_0*.jsonl`.

  Their summaries and labelling notes are committed.
- `R8_1_PUSH_RECORD.md`: a local record, written after the push.

## Excluded working-tree material (left in place)

- **Metadata-only files** (same blob as HEAD): `lib/core/world_rendering/quiet_trail_hero_asset_view.dart`, `lib/features/home/application/phase_d_retirement.dart`, `test/features/personal_circle/r6_kept_voice_whole_circle_test.dart`.
- **Local or earlier-phase material:** `AGENTS.md`, `android/build/`, `artwork/`, two untracked quiet_trail PNGs, `artifacts/r8_post_audit_remediation_2026-11-04/R8_PUSH_RECORD.md` and its superseded run-1 logs, and the R6/R7 raw JSONL logs.
- **Planning, media and build products:**
  - six-language and Founder Dashboard planning: `artifacts/launch_six_language_2026-11-03/`;
  - KEYBRACE material;
  - earlier-phase QA media, screenshots, device captures, audio auditions and intermediate voice production under `artifacts/v2_phase_*`, `artifacts/release_*`, `artifacts/pacing1_emulator`, `artifacts/qa1_emulator`, `artifacts/reminder1`, `artifacts/visual_qa`, `artifacts/world_art_qa`.
