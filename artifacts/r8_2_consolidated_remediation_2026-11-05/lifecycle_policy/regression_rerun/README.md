# R8.2 complete regression rerun (definitive): 2026-11-06, 12:50 → 13:23

- **Authorized by:** the founder, as one new complete run of the current R8.2 working tree, for verification only. No source was changed.
- **Replaces:** the interrupted run in `../regression_final/` (see its `INTERRUPTED.txt`). Nothing from that run is used or combined here. It is kept only as a record of the interruption.

## Preflight

- **Memory.** Free physical memory was 3.2–4.8 GB at 12:35–12:36, so the run was not started then (reported to the founder). After the founder freed memory, it was 8.27–8.45 GB at 12:49.
- **Processes.** No process from the earlier run survived. The only Dart processes were VS Code's own (language server, tooling daemon, devtools, Flutter daemon), all started at 09:07. None was touched.
- **Tree.** `SOURCE_FINGERPRINT_preflight.sha256` equals the interrupted run's start fingerprint (371 files).
- **Git.** `GIT_STATE_start.txt`: HEAD `e935112c` equal to upstream; nothing staged; no stash; 27 tracked files changed.

## The run

- **Driver.** `drive_regression.sh` and `run_batches.py`, copied from `../regression_final/`. `RUNNER_DIFF_vs_regression_final.txt` lists every change:
  - the output folder;
  - the memory guard raised from 2.5 GB to 4.0 GB;
  - the driver PID and the number of live test processes logged before each batch.
- **Execution.** 18 batches with batch 18 in its 5 declared parts (a–e). One `flutter test --concurrency=1` process at a time, sequentially.
- **Memory.** Before every batch, free memory was 6.77–9.9 GB, and 0 test processes were alive from the batch before. No wait or stop was needed (`MEMORY_LOG.txt`). The driver (PID 2552) exited 0.

## Results

| Check | Result |
|---|---|
| Batches | 1–17 and 18a–e: every one exit 0, `done=True` with success (`RUN_LOG.txt`, `batch_*.summary.json`) |
| Totals | **193/193 files, 2,774 passed, 0 failed, 0 skipped** |
| `report` | **EVIDENCE OK**: nothing missing, stray, incomplete, empty, non-zero or not successful |
| `cases` | **CASES OK**: 13/13 year profiles (p01–p11, p13, p14), each exactly once, across 18a–e |
| B8 | 6/6 (batch 17): cases A–E and "voice follows the entitlement" |
| Inventory (`INVENTORY_RECONCILIATION.txt`, independent of the runner) | 193 planned = 193 on disk = 193 suites in the raw logs; no (file, test) pair twice; 2,774 success. Against the 2,753 run: the only count change is `r82_lifecycle_policy_test.dart` 0 → 21 |
| Fingerprints | start = end = preflight (371 files): no source or test file changed during the run |
| Source manifest | `SOURCE_MANIFEST_git_blobs.txt` (371 files, same list as the fingerprint). Against the 2,753 run's manifest it differs in exactly the 3 production files, the 2 test files whose expectations changed, and the new lifecycle test file |
| `flutter analyze` | No issues (`FLUTTER_ANALYZE.txt`) |
| Audio | 172/172 production and 8/8 framing SHA-1 match; 180 bundled files = union of the manifests; no asset diff (`AUDIO_VERIFICATION.txt`) |
