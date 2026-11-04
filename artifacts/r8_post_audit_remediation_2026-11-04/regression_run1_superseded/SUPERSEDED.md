# SUPERSEDED: R8 first full regression run (historical only)

**Do not use this folder as evidence for the R8 commit.** The authoritative run is `../regression/`: 169/169 files, 2,484 passed, 0 failed, 0 skipped.

This folder is the first full R8 run, made before the founder's pre-commit gate corrections:
- 167/167 files; 2,448 passed, 0 failed, 0 skipped.
- Its source fingerprint was unchanged during the run, but it describes the **pre-gate** source. That source didn't yet have R8-16 (P2), R8-17 (overwrite protection), R8-18 (Delete ordering), the explicit unsaved state, the D1 body copy or the D2 boundary tests.
- Kept for history, as founder-directed (2026-11-04).

**Committed here:** the per-batch summaries, `batch_plan.json`, `COVERAGE_MANIFEST.json`, `CASE_COVERAGE.json` and the source fingerprints.

**Not committed:** the raw `.jsonl` reporter logs. They stay local and were not deleted.
