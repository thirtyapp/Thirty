Run 1 (2026-11-10 10:45) — DIAGNOSTIC, INCOMPLETE. Not counted.
- Batches 1-17 completed: 3,079 passed, 1 failed, 0 skipped.
  FAIL test/core/qa/qa_scenario_test.dart: "the same scenario and reference date always build
  the same store" — the QA store builder drives production keepCircle, whose id gained a
  random part in R8.3.3 (R832-A02), so two builds differed. Fixed afterwards in
  lib/core/qa/qa_scenario.dart (seeded keptIdRandomProvider in the builder's container).
- Batch 18 (B8 year-long simulation; recorded "exit 1, 2 passed, done=False" because its process was stopped) was running when Claude Code stopped the driver because
  the system was critically low on memory (host-level reap, not a test failure). Batch 18 and
  parts 19a-e never completed; no report/cases step ran. The orphaned B8 test process tree
  (cmd 7708) was stopped afterwards.
- Source under test: the R8.3.3 tree BEFORE the qa_scenario.dart fix (start fingerprint here).
- The driver bash survived the reap and started part 19a after the orphaned B8 tree was stopped; it was then stopped too (19a never completed).
