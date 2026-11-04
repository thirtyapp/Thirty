# R7 push record (2026-11-04) — local, deliberately uncommitted

A commit cannot contain its own SHA, so the identity of the R7 commit is recorded here, outside it.

| | |
|---|---|
| Commit (full SHA) | `8ece26f6dbd41f573e854b8fc82f44a6942282e3` |
| Tree | `02f9d3b5d83d7f5030d8517d1aeb9c8ce9b1a160` (equal to the staged tree) |
| Tested source tree | `33079135b2ccc2a425399a2306d05209036cc454`; the commit adds only `artifacts/r7_final_regression_2026-11-04/` (24 files) and the tracker R7 entry |
| Parent | `8bfd42c16693b8f5040ebcf4761db0e9c439981c` (D2 closure) |
| Branch | `step5-billing-integration` → `origin/step5-billing-integration`. Fast-forward, no force. |
| Remote after push | `git ls-remote` gives `8ece26f6dbd41f573e854b8fc82f44a6942282e3` for local, remote and fetched refs |
| Untouched | `main` = `a8b4088` (unchanged). No tag created. No release, deployment, migration or external service change. |
| Message | `fix(thirty): complete R1-R6 pre-release remediation and regression evidence` |
| Files | 194 (97 modified, 97 added, 0 deleted), +23,869 / −692 lines |

## Left uncommitted on purpose (184 status entries, 1,788 files when expanded)

- `lib/core/world_rendering/quiet_trail_hero_asset_view.dart`: modified only in its file stats. Same blob `407beda…`; line endings only, no content change.
- `artifacts/launch_six_language_2026-11-03/` covers six-language and Founder Dashboard planning. It contains drafts, the unapplied Amendment 3, and discontinued KEYBRACE material.
- Raw and intermediate audio: auditions, `raw/`, `listen/`, `raw_retakes/`, mastering and validation material, review folders, social-bank inputs.
- Device screenshots, TalkBack recordings, contact sheets: `artifacts/v2_phase_d2/talkback/`, `screenshots/`, `bg_qa/`, `device_qa/*.png`.
- Earlier local artifacts: `artifacts/v2_phase_a*/b/c/d`, `pacing1_emulator`, `qa1_emulator`, `release_*`, `reminder1`, `visual_qa`, `world_art_qa`, `artwork/`.
- Raw test logs (`*.jsonl`) for R6 and R7, plus the R6 partial `batch_16.jsonl`.
- Remaining non-essential files in the voice integration folders: build/test logs, tools, `GOVERNANCE_DELTA_PROPOSED.md`, `native_lifecycle/`, `s25_acceptance/`, `source/`.
- `android/build/`, `AGENTS.md` (local handbook from 2026-10-13), and two unreferenced PNGs: `assets/worlds/quiet_trail/quiet_trail_walk_{card,hero}_morning_v1.png`.
- This file.

None of these were deleted, moved or modified by R7.

The verification worktree `../Thirty-verify-r7`, detached at `8bfd42c` with the tested tree checked out, is kept for reproduction.
