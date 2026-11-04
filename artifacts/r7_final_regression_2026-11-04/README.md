# R7 final regression — memory-bounded full suite on the exact commit tree (2026-11-04)

**Result: 159 of 159 test files, 2,353 tests passed, 0 failed, 0 skipped.** No empty run, no non-zero exit, no incomplete batch. `flutter analyze`: no issues. Audio: 172/172 (`PRODUCTION_SHA1.txt`) and 8/8 (`FRAMING_SHA1.txt`) SHA-1 OK; 180 bundled files, each named by exactly one manifest.

## What was tested

Not the working tree. The R7 inclusion manifest was written into a separate Git index, giving source tree `33079135b2ccc2a425399a2306d05209036cc454` (`8bfd42c` + 97 modified + 73 added paths, no deletions). That tree was checked out into a fresh, detached worktree (`git worktree add --detach … 8bfd42c`, then `git read-tree -u -m 8bfd42c <tree>`), so nothing excluded from the commit — untracked files, local configuration, build output — could take part.

- `flutter pub get --offline`, then `flutter analyze` and the batches below, all in that worktree (Flutter 3.44.8 stable).
- The commit adds only this evidence folder and the R7 tracker entry to that tree. No test reads either. (Checked: tests that read repository files read `lib/`, `pubspec.yaml`, `config/*.example.json`, Android build files, ADR-024 and `artifacts/v2_phase_d2/b8`.)
- After the run the worktree's tracked files were unchanged, apart from `flutter pub get` rewriting seven generated plugin registrants (linux/macos/windows) with different line endings only (`git diff --ignore-cr-at-eol` empty).

## Method (from the repository root)

```
python -I artifacts/r7_final_regression_2026-11-04/run_batches.py plan
python -I artifacts/r7_final_regression_2026-11-04/run_batches.py run <1..15>
python -I artifacts/r7_final_regression_2026-11-04/run_batches.py runpart 16 a "p0[1-3]_"
python -I artifacts/r7_final_regression_2026-11-04/run_batches.py runpart 16 b "p0[4-9]_"
python -I artifacts/r7_final_regression_2026-11-04/run_batches.py runpart 16 c "p1[0-9]_"
python -I artifacts/r7_final_regression_2026-11-04/run_batches.py report
python -I artifacts/r7_final_regression_2026-11-04/run_batches.py cases
```

Each batch is a separate, sequential, foreground process: `flutter test --concurrency=1 --reporter json <files>`. The runner is the R6 runner with three additions:

- every summary records each test's name;
- `report` lists any run with zero tests (`emptyRuns`) and any non-zero exit (`nonZeroExit`); neither counts as a success;
- `cases` checks that the name-filtered parts of a split file ran every test the file declares, exactly once, and nothing undeclared.

## Batches

| Batch | Files | Passed | Seconds |
|---|---|---|---|
| 1–13 | 12 each | 86, 98, 117, 151, 94, 251, 219, 161, 253, 196, 250, 209, 247 | 16–49 each |
| 14 | 1 | 2 | 4 |
| 15 — `b8_product_simulation_test.dart` (whole file, all 6 tests incl. the 4 `long` year runs) | 1 | 6 | 248 |
| 16a — `personal_circle_simulation_test.dart`, p01–p03 | 1 | 3 | 212 |
| 16b — p04–p09 | 1 | 6 | 508 |
| 16c — p10, p11, p13, p14 | 1 | 4 | 319 |

**Year-long profiles:** the file declares 13 (`p01`–`p11`, `p13`, `p14`; there is no `p12`), all in its one `test(` loop. `CASE_COVERAGE.json`: declared 13, ran 13, each exactly once, none undeclared. The JSON logs show no other test started in those parts (one hidden loader per part).

**Against R6:** the per-file passed/failed/skipped counts are identical to `artifacts/r6_final_verification_2026-11-03/COVERAGE_MANIFEST.json` for all 159 files.

## Files

| File | What it is |
|---|---|
| `run_batches.py` | the runner (standard library only) |
| `batch_plan.json` | test-file inventory (159) and the 16 batches |
| `batch_NN*.summary.json` | per batch or part: counts per file, test names, exit code, command, duration |
| `COVERAGE_MANIFEST.json` | union check: 159/159 covered, none not run, none unexpected, none incomplete, none empty, none non-zero |
| `CASE_COVERAGE.json` | the split file's case check |
| `AUDIT_HANDOFF.md` | the handoff for the independent reviewers |

The raw JSON reporter logs (`batch_NN*.jsonl`, about 1.5 MB) are kept locally and not committed; the summaries are derived from them by `run_batches.py` and the run is reproducible.

## Not covered here

Device QA was not repeated in R7 (no S25 or emulator run). R1–R6 device evidence is as recorded in the tracker log.
