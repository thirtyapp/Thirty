# R8.2 commit inventory

- **Authorization.** The founder authorized one audit-ready R8.2 commit on 2026-11-06, with parent `e935112c` on `step5-billing-integration`.
- **How it was staged.** From the exact path list `COMMIT_PATHS.txt`, one path per line; that list includes this file and itself. Nothing was staged with `git add -A` or by directory.
- **How it was checked.** The staged set was verified against that list before committing, and the commit's file list against it afterwards.

## Included

| Group | Paths | Rule |
|---|---|---|
| Production source | 12 files under `lib/` | Every `lib/` file with a content change since `e935112c` |
| Existing tests | 13 files under `test/` | Every existing test with a content change: timing settles, plus the assertion changes listed in `CHANGES.md` |
| New tests | `test/features/r82/` (14 files) | All R8.2 regression tests |
| Original audits | `docs/audits/THIRTY_INDEPENDENT_POST_R8_1_AUDIT.md`, `docs/audits/THIRTY_CLAUDE_POST_R8_1_AUDIT_REPORT.txt` | Unchanged, byte-identical (LF) |
| R8.2 evidence | `artifacts/r8_2_consolidated_remediation_2026-11-05/` | Register, changes, limitations, both handoffs, founder-decision and lifecycle records, failing-before and passing-after runs with their raw logs, the runner (E-1), and the definitive regression `lifecycle_policy/regression_rerun/` complete with its raw reporter logs |

**Superseded and interrupted runs.** These are committed as short, labelled records: summaries, run, report and cases output, fingerprints, manifests and runners, plus a `SUPERSEDED.txt` or `INTERRUPTED.txt` label. Their raw `batch_*.jsonl` logs are **not** committed and stay in the local working tree. The runs are:
- `regression_final/`;
- `founder_decisions/regression_final/`;
- `claude_audit_reconciliation/regression_final/`;
- `lifecycle_policy/regression_final/` (interrupted).

Likewise, the raw logs of the two superseded first-draft reproduction folders are not committed: `repro_before_fix/first_drafts_superseded/` and `founder_decisions/repro_before_fix/first_attempt_superseded/`.

**Test support.** `test/support/r8_harness.dart` and `r8_fault_disk.dart` are unchanged since R8.1, so they are already in the parent commit.

## Excluded (left in the working tree, not deleted)

| Path | Reason |
|---|---|
| `lib/core/world_rendering/quiet_trail_hero_asset_view.dart`, `test/features/personal_circle/r6_kept_voice_whole_circle_test.dart` | Reported modified, but the working blob equals HEAD's (line-ending or stat metadata only). The commit keeps HEAD's blob, which is what the regression tested. |
| `AGENTS.md`, `artwork/`, `android/build/` | Not approved, or a build product |
| `assets/worlds/quiet_trail/quiet_trail_walk_{card,hero}_morning_v1.png` | Pre-existing, unrelated |
| Raw `.jsonl` logs of superseded or interrupted runs, `regression_final/__pycache__/` | Historical raw logs; a cache |
| Every other untracked artifact (earlier phases, R6–R8.1 raw logs, `R8_1_PUSH_RECORD.md`, voice and QA material) | Unrelated to R8.2 |

## Checks before staging

- No secrets: a scan for RevenueCat, Google and Stripe keys, JWTs, private keys and Supabase service keys found nothing.
- No `.dart` file under `artifacts/`.
- Every `lib/` and `test/` file equals the definitive run's `SOURCE_MANIFEST_git_blobs.txt`, and the fingerprint still matches.
- Both audit reports' SHA-256 equal the recorded values.
