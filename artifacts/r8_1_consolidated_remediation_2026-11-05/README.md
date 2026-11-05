# R8.1 — consolidated independent-audit remediation (2026-11-05)

**Status: implemented and verified in the working tree, uncommitted, awaiting founder review.** Neither independent audit is claimed as passed: both verdicts stand unchanged (Astra FAIL; Claude CONDITIONAL PASS), and closure needs a re-audit of a new immutable commit.

## Baseline

- Branch `step5-billing-integration`, HEAD `58b179c99866e234acd63e4e241590af36b9b186` (parent `8ece26f6`), unchanged; nothing staged, committed or pushed.
- Before R8.1, the only working-tree changes were the three stat-only files known since R7/R8 (`git diff` empty) plus untracked artifacts. No earlier R8.1 work existed.

## Audit inputs (read in full; neither edited)

| Report | Path | SHA-256 |
|---|---|---|
| Astra post-R8 (FAIL: 3 HIGH, 6 MEDIUM, 1 LOW) | `docs/audits/THIRTY_INDEPENDENT_POST_R8_AUDIT.md` | `afc3631c…2f0ab1` |
| Claude post-R8 (CONDITIONAL PASS: 2 MEDIUM, 4 LOW) | `docs/audits/THIRTY_CLAUDE_POST_R8_AUDIT_REPORT.md` — verbatim copy of the audit session's final message | `2519e0b2…64f1c0` (the delivered LF text, as committed; a CRLF checkout reads `8ebec3ce…`) |
| Claude's reproduction file | `audit_inputs/claude_audit_r8_repro_test.dart.txt` (verbatim, `.txt` so it never runs) | `efd63d49…2b36f` |

## Register

`ISSUE_REGISTER.json`: 11 deduplicated entries carrying all 16 original identifiers (Astra N01–N10, Claude AUD-1–AUD-6), each with both severities, root cause, fix, files, tests, failing-before count and status. Working severity takes the higher of the two.

## Evidence

| Folder / file | What |
|---|---|
| `repro_before_fix/` | The 83 new tests run on **R8's own `lib/`** (byte-equal to HEAD; only the test-support latch added): **66 fail** (60 failures + 6 errors), 17 pass (regression guards). `SUMMARY.txt`, raw `r81_on_r8_lib.jsonl`. |
| `regression/` | Full suite on the R8.1 tree: R8's memory-bounded runner (copied, output folder only changed), raw JSONL per batch, summaries, `COVERAGE_MANIFEST.json`, `CASE_COVERAGE.json`, start/end source fingerprints. |
| `AUDIO_VERIFICATION.txt` | 172/172 production and 8/8 framing SHA-1; 180 bundled files = union of both manifests; no tracked asset changed. |
| `CHANGES.md` | Every changed or new file and why. |

## Not done here

- No device run (S25 / TalkBack), no real Android `SharedPreferences` failure semantics, no RevenueCat/Play lifecycle — the same limits both audits recorded.
- No change to production audio, Supabase, RevenueCat configuration, localization (no new user-facing string), the Founder Dashboard, the V2 contract or the delivery tracker.
- Phase E HOLD; KEYBRACE OS discontinued.

## Final full regression (2026-11-05)

- **Run 1:** batches 1–9 completed cleanly. Claude Code then stopped the run during batch 10 for low system memory. That partial log is kept in `regression/interrupted_run1_batch10/` and is not counted anywhere.
- **Resumption (founder-authorized, test only):**
  - Preflight: 7.73 GB free, and no leftover test processes.
  - Source fingerprint identical to the start of run 1, so batches 1–9 were kept.
  - Batch 10 was rerun from the beginning. Batches 11–16 then ran in turn, and batch 17 (the year-long simulations) in five name-filtered parts, 17a–17e.
  - One worker at a time; free memory was checked before every batch and stayed at 7.2 GB or more.
- **Totals:**
  - 176 of 176 test files; **2,567 passed, 0 failed, 0 skipped**. That is R8's 2,484 plus the 83 new R8.1 tests.
  - 21 summaries, each with exit 0 and `done.success`. No empty run, no duplicate test, and no file in more than one batch.
  - Runner checks: `report` gave EVIDENCE OK and `cases` gave CASES OK, both exit 0.
- **Year-long simulations:** all 13 profiles ran exactly once (p01–p11, p13, p14; the inventory has no p12). All 6 B8 simulations passed (A–D, voice-entitlement, E).
- **Source fingerprint:** start = end, 354 files.
- **`flutter analyze`:** no issues (`regression/FLUTTER_ANALYZE.txt`).
- **Audio:** 172/172 production and 8/8 framing SHA-1 match. The 180 bundled files are exactly the files the two manifests name (`AUDIO_VERIFICATION_final.txt`).

> **Superseded as final evidence:** the 2,567-test run above (`regression/`, see `SUPERSEDED.txt`) tested the tree *before* the founder's RL corrections.

## Founder corrections RL-1 / RL-2 / RL-3, and the RL-4 record (2026-11-05, later)

- **RL-1 / AUD-6 (fixed, Plan action API unchanged):**
  - A failed latest Plans or Insights save takes the change back off the screen; state reverts to what the store confirmed.
  - Insights decide from the confirmed Plans (`confirmedState`).
  - A stage Circle is saved only once its served-stage record is on disk (`confirmServed`).
  - Today keeps the Start's billing answer, so a failed Start record is rewritten from that same answer.
  - Tests: `test/features/r81/r81b_rl1_pending_state_test.dart` (17).
- **RL-2 (fixed):**
  - The approved copy is the part note on every part of a started Circle whose saved words couldn't be recovered.
  - It sits in the part's live-region label. No dialog, no interruption, never voiced.
  - Recorded in `LOCALIZATION_INVENTORY_ADDITIONS_R8_1.csv`.
  - Tests: `r81b_rl2_unverified_words_copy_test.dart` (3).
- **RL-3 (fixed):**
  - Plans: stage records are written back exactly as read. Revisit entries that aren't stage numbers, and damaged or unknown cycle and Plan fields, are kept. A cycle end THIRTY doesn't know keeps the whole Plan as stored.
  - Suggestion preferences: damaged items and unknown fields are kept. A record THIRTY can't read as a whole is never written over by a change (the user is told); only Reset removes it.
  - Tests: `r81b_rl3_field_preservation_test.dart` (12).
- **RL-4 (accepted, not fixed):** `LIMITATION_RL4_OFFSET_FREE_TIMESTAMPS.md`.
- **Failing before the fix:** 20 failures, plus the RL-2 file failing to compile (its copy didn't exist yet). Evidence in `repro_before_fix_rl/`.
- **Existing assertions changed per founder decision RL-1:**
  - `r8b_precommit_persistence_test.dart`: the "still on screen" test (×2 faults) now requires the change to be taken off the screen.
  - `r3_persistence_delete_test.dart` J4: the precondition now requires Today's stage write to wait behind the held Plans write.
  - Two of R8.1's own uncommitted tests: memory credit and applied mark are not kept on screen.
- **Review pack:** `artifacts/v2_phase_d2/b8/` was regenerated with `EXPORT_B8_PACK=true`. The diff is the 2 approved strings plus header and counts.

## Final full regression (`regression_final/`)

- **Run:** memory-gated (free memory at least 6.2 GB before every batch), one worker at a time, sequential.
- **Aborted first attempt:** kept in `aborted_attempt1_review_pack_stale/` and not counted. It stopped at batch 6 because the review pack was stale.
- **Totals:**
  - 179 of 179 test files; **2,599 passed, 0 failed, 0 skipped**. That is 2,567 plus the 32 new RL tests.
  - 21 summaries, each with exit 0 and `done.success`; no duplicates; EVIDENCE OK and CASES OK.
- **Simulations:** all 13 year profiles ran exactly once, and all 6 B8 simulations passed.
- **Source fingerprint:** start = end, 357 files.
- **`flutter analyze`:** no issues.
- **Audio:** 172/172 and 8/8 SHA-1 match, and the 180 bundled files are exactly those the manifests name (`AUDIO_VERIFICATION_after_RL.txt`).
