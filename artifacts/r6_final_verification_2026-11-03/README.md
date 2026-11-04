# R6 final verification — memory-bounded full suite (2026-11-03)

**Result: 159 of 159 test files, 2,353 tests passed, 0 failed, 0 skipped.** `flutter analyze`: no issues.

**Tree:** working tree on `step5-billing-integration` at HEAD `8bfd42c` (uncommitted R1–R6 work).

## Why batches

One monolithic `flutter test` was stopped by the host for low memory. Free RAM was about 5.6 GB of 31.8 GB, with another application holding about 5 GB. The suite was therefore run as sequential, separate processes, each with `--concurrency=1` and the JSON reporter, so memory was released between batches.

## Commands (from the repository root)

```
python -I artifacts/r6_final_verification_2026-11-03/run_batches.py plan
python -I artifacts/r6_final_verification_2026-11-03/run_batches.py run <1..15>
python -I artifacts/r6_final_verification_2026-11-03/run_batches.py runpart 16 a "p0[1-4]_"
python -I artifacts/r6_final_verification_2026-11-03/run_batches.py runpart 16 b "p0[5-8]_"
python -I artifacts/r6_final_verification_2026-11-03/run_batches.py runpart 16 c "p09_"
python -I artifacts/r6_final_verification_2026-11-03/run_batches.py runpart 16 e "p1[01]_"
python -I artifacts/r6_final_verification_2026-11-03/run_batches.py runpart 16 d "p1[34]_"
python -I artifacts/r6_final_verification_2026-11-03/run_batches.py report
```

Each batch runs: `flutter test --concurrency=1 --reporter json <files>`.

## Files

| File | What it is |
|---|---|
| `batch_plan.json` | the test-file inventory (159) and the 16 batches: 14 of up to 12 files, plus the two `long`-tagged year simulations alone |
| `batch_NN.jsonl` / `batch_NN.summary.json` | each batch's raw JSON reporter log and its counts per file |
| `COVERAGE_MANIFEST.json` | the union check: covered files, files not run (none), unexpected files (none), incomplete batches (none), and totals per file |

## Interruptions, disclosed

- **Batch 16** (`personal_circle_simulation_test.dart`, 13 year-long profiles) was stopped by the host for low memory while running in the background.
  - Its partial log `batch_16.jsonl` has no summary and **is not counted**.
  - The file was rerun in parts by test-name pattern, in the foreground: 16a p01–p04, 16b p05–p08, 16c p09, 16e p10–p11, 16d p13–p14. That gives 13 of 13 profiles, all passing.
- **A first attempt at parts c and d** passed a `|` in the name pattern. On Windows `cmd` treated it as a pipe, and the runs exited without running any test.
  - Those records were overwritten by the reruns above, which use patterns without `|`.

## Also checked

- **Audio:** `assets/audio/guidance` matches `PRODUCTION_SHA1.txt` (172/172) and `FRAMING_SHA1.txt` (8/8). No audio file has been modified since the 2026-11-02 Heather integration.
