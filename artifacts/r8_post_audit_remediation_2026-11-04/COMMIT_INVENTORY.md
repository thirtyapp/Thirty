# R8: proposed inclusion and exclusion inventory for the future audit-ready commit

This is a proposal only. Nothing is staged.

- **Base:** `8ece26f6dbd41f573e854b8fc82f44a6942282e3`, which stays unchanged.
- **Founder decision needed:** whether the paths under "Proposed, founder decision" go in. Everything else follows the R7 rules.

## Include: tested source (must equal `regression/SOURCE_MANIFEST_git_blobs.txt`)

**Modified tracked files with content changes (37):**

`lib/`:
- `lib/core/app/thirty_app.dart`
- `lib/core/premium/premium_access.dart`
- `lib/core/qa/qa_scenario.dart`
- `lib/core/utils/date_key.dart`
- `lib/features/home/application/circle_history_deletion.dart`
- `lib/features/home/application/circle_journal.dart`
- `lib/features/home/application/recommendation_provider.dart`
- `lib/features/home/presentation/widgets/journal_data_controls.dart`
- `lib/features/home/presentation/widgets/journal_save_failure_notice.dart`
- `lib/features/insights/application/insights_provider.dart`
- `lib/features/insights/domain/insight.dart`
- `lib/features/insights/presentation/insights_page.dart`
- `lib/features/personal_circle/application/kept_circles_provider.dart`
- `lib/features/personal_circle/domain/kept_circle.dart`
- `lib/features/personal_circle/presentation/keep_circle_card.dart`
- `lib/features/personal_circle/presentation/kept_circle_page.dart`
- `lib/features/plans/application/circle_plans_provider.dart`
- `lib/features/plans/presentation/plan_detail_page.dart`
- `lib/features/settings/presentation/widgets/you_data_card.dart`

`test/`:
- `test/features/b8/b8_delete_longitudinal_test.dart`
- `test/features/b8/b8_product_simulation_test.dart`
- `test/features/home/r2_make_today_circle_test.dart`
- `test/features/home/r3_delete_feedback_test.dart`
- `test/features/home/r3_persistence_delete_test.dart`
- `test/features/insights/insights_service_test.dart`
- `test/features/insights/presentation/insights_page_test.dart`
- `test/features/insights/r5_i4_keep_after_lapse_test.dart`
- `test/features/personal_circle/premium_today_test.dart`
- `test/features/personal_circle/r41_kept_store_test.dart`
- `test/features/personal_circle/r4_kept_ownership_test.dart`
- `test/features/personal_circle/saved_circle_lapse_attack_test.dart`
- `test/features/plans/circle_plan_today_test.dart`
- `test/features/plans/r2_plan_credit_provenance_test.dart`
- `test/features/premium/b7_entitlement_matrix_test.dart`
- `test/features/settings/presentation/settings_page_test.dart`

Docs:
- `docs/product/PRODUCT_V2_CONTRACT.md` (amendments 2026-11-04: D2, D3, D1)
- `docs/product/THIRTY_V2_DELIVERY_TRACKER.md` (R8 log entries)

**Regenerated generated evidence (2):**
- `artifacts/v2_phase_d2/b8/CONTENT_REVIEW_PACK.md`
- `artifacts/v2_phase_d2/b8/MANIFEST.json`

**New source (16):**
- `lib/core/storage/confirmed_write.dart`
- `lib/core/storage/store_save_failures.dart`
- `test/support/r8_fault_disk.dart`
- `test/support/r8_harness.dart`
- `test/core/app/r8_midnight_resume_test.dart`
- `test/core/premium/r8_restore_wording_test.dart`
- `test/features/home/r8_a01_daily_persistence_test.dart`
- `test/features/home/r8_a04_delete_durability_test.dart`
- `test/features/home/r8_a06_unreadable_history_controls_test.dart`
- `test/features/home/r8_journal_forward_records_test.dart`
- `test/features/home/r8b_notice_copy_test.dart`
- `test/features/home/r8b_precommit_persistence_test.dart`
- `test/features/insights/r8_f4_insight_dates_test.dart`
- `test/features/personal_circle/r8_kept_ownership_persistence_test.dart`
- `docs/audits/THIRTY_ASTRA_POST_R7_AUDIT_SHARED_REPORT.md`: audit input as supplied, unchanged, sha256 `e24bf8c1f21b1f19712380f23e8961b661db25c3b0f95886d9da92133f85204f`.
- `docs/audits/THIRTY_CLAUDE_POST_R7_AUDIT_REPORT.md`: the Claude post-R7 report, verbatim from its session, sha256 `c6b396a1b7792b649a794ba4c2ebefe9a6f8c87a013303c2f0daea9338dd7e06`.

**R8 evidence:** `artifacts/r8_post_audit_remediation_2026-11-04/`
- README, CHANGES, ISSUE_REGISTER, COMMIT_INVENTORY, LOCALIZATION_INVENTORY_ADDITIONS_R8.csv
- `repro_on_r7_tree/`, `repro_before_fix/`, `gate_probe/`
- `regression/`:
  - runner, plan, summaries;
  - `COVERAGE_MANIFEST.json`, `CASE_COVERAGE.json`;
  - `SOURCE_FINGERPRINT_*.sha256`, `SOURCE_MANIFEST_git_blobs.txt`.

## Proposed, founder decision
- **R8 raw reporter logs, `regression/*.jsonl` (about 1.7 MB).** Recommended: include. Astra §6/§8 asks for the raw logs.
- **`regression_run1_superseded/` (2.1 MB).** This is the first full R8 run (2,448/0), made before the pre-commit corrections. Recommended: include the summaries and the coverage manifest; leave its `.jsonl` logs out.
- **R7's raw logs and push record.** These are `artifacts/r7_final_regression_2026-11-04/*.jsonl` (about 1.5 MB) and `R7_PUSH_RECORD.md`. Recommended: include. This adds history and rewrites nothing.

## Exclude (they stay local and are not deleted)
- **Content-identical to HEAD, changed in file stats only:**
  - `lib/core/world_rendering/quiet_trail_hero_asset_view.dart`
  - `lib/features/home/application/phase_d_retirement.dart`
  - `test/features/personal_circle/r6_kept_voice_whole_circle_test.dart`
- **Planning and drafts:** the six-language and Founder Dashboard planning folder `artifacts/launch_six_language_2026-11-03/`.
- **Media and screenshots:** raw and intermediate audio, auditions, listening files, device screenshots and recordings.
- **Earlier local artifacts:** the earlier-phase artifacts, `android/build/`, `AGENTS.md`, and two unreferenced Quiet Trail PNGs.

## Tested-source equivalence check, at commit time

```
git ls-tree -r <new-commit> -- lib test pubspec.yaml pubspec.lock analysis_options.yaml \
  | awk '{print $3" "$4}' | LC_ALL=C sort -k2 \
  | diff - artifacts/r8_post_audit_remediation_2026-11-04/regression/SOURCE_MANIFEST_git_blobs.txt
```

The output must be empty. The manifest lists 346 files, and its sha256 is `862b924b5a1d3132b22a33aabc2ea2409bea09f2e1faaf553fe8946fc3213eee`.

## Final decisions (founder, 2026-11-04, R8 commit directive)

- **Included:**
  - the R8 raw reporter logs, `regression/*.jsonl`;
  - from `regression_run1_superseded/`: the summaries, plan, coverage and fingerprints, with a new `SUPERSEDED.md`;
  - `artifacts/r7_final_regression_2026-11-04/R7_PUSH_RECORD.md`, as a historical record, unchanged. Its heading says "deliberately uncommitted", which was true for R7;
  - both post-R7 audit reports;
  - `AUDIT_HANDOFF.md`.
- **Excluded:**
  - R7's raw `*.jsonl` logs;
  - `regression_run1_superseded/*.jsonl`;
  - the three stat-only files;
  - everything under "Exclude" above;
  - `R8_PUSH_RECORD.md`, written after the push because a commit cannot hold its own SHA.
- **Privacy note:** the raw logs and the before-fix outputs contain the build machine's absolute paths. HEAD already contains the same kind of path. They hold no user data, credentials or device data.
