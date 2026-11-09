# R8.3.2: final founder scope closure (2026-11-07)

**Implementation-level result: PASS.**
- The three founder decisions are implemented: B1 and B2 (FIX REQUIRED) and N01-C (cancel a pending Start).
- **L-1: OPEN, NOT FIXED, NOT WAIVED, PRE-RELEASE BLOCKER.** It is untouched.
- Nothing is staged, committed or pushed. Phase E is on HOLD.

The previous R8.3.2 evidence, including the 2,914-pass pre-final regression, stays unchanged in `../r8_3_2_consolidated_integrity_closure_2026-11-07/`. Its manifest was re-verified.

## Contents

| Path | What it holds |
|---|---|
| `repro_before_fix/` | The new test file, run before any production change, on the R8.3 export and on the frozen pre-final R8.3.2 tree: 11 FAIL / 15 PASS / 4 N/A on each. |
| `final_gate/` | Both R8.3.2 test files (exact final bytes, listed in `SHA256SUMS.txt`) on R8.2, R8.3, pre-final R8.3.2 and the corrected tree (`MATRIX.md`), plus the auditors' 27 original tests on the corrected tree. |
| `CONTRACTS_FINAL.md` | Contract B (final): the durable Insight attempt and confirmation protocol, plus N01-C. |
| `TEST_CHANGES.md` | Every existing test that changed, with the decision that requires the change, and the harness extension. |
| `regression/` | The definitive full regression. The runner was copied unchanged except for `OUT`. |
| `source_diffs/lib_vs_HEAD.diff` | The full production diff against 9c910773. |
| `AUDIO_VERIFICATION.txt`, `UNCHANGED_SURFACES.txt`, `FLUTTER_ANALYZE.txt`, `GIT_STATE_end.txt` | The supporting checks, analyzer output and final git state. |

## Production changes in this pass

These are in addition to the earlier R8.3.2 changes to `circle_plan.dart` and the provider files.

- **`lib/core/storage/confirmed_write.dart`.** `StorageWriteFailed.uncertain` is set when the platform call threw, meaning the value may have landed.
- **`lib/features/home/application/suggestion_preferences.dart`.** New `PreferenceChange.uncertain`. Every other caller treats it as not saved.
- **`lib/features/personal_circle/application/kept_circles_provider.dart`.** `keepCircle(id:)` accepts an id chosen by the caller.
- **`lib/features/insights/domain/insight.dart`.** New `InsightAttempt` record and `InsightSnapshot.attempt`, with its codec.
- **`lib/features/insights/domain/insight_engine.dart`.** An unresolved attempt makes the status `stale`.
- **`lib/features/insights/application/insights_provider.dart`.**
  - The I3/I4 attempt protocol, with proof-only marking.
  - `assess` resolves attempts that are proven.
  - An independent Keep is no longer marked as I4's.
- **`lib/features/plans/application/circle_plans_provider.dart`.** `PlanStartConditions`, `startConditions`, and the cancellation in `prepareStart`.
- **`lib/features/home/application/recommendation_provider.dart`.** The conditions are captured at the Start tap, and the Start is cancelled silently.

No billing, entitlement, dependency, platform or asset change. No migration and no new store.

## Results

| Check | Result |
|---|---|
| `test/features/r832/` | 72/72 (42 + 30) on the corrected tree |
| Auditors' original tests | 26/27. **AUD-O3**, Claude's R8.2 probe, asserts `started` mid-way through "Active → Start pending → Pause", which N01-C cancels. Its question ("credited?") is answered "no". The file is preserved and was not edited. |
| Full regression | 203 files; 2,944 passed, 0 failed, 0 skipped |
| Regression evidence | EVIDENCE OK and CASES OK, with raw logs validated. 13 year-long profiles each ran exactly once. B8 6/6. |
| Source integrity | Fingerprints and Git-blob manifests are identical at start and end. INVENTORY OK: the only count change is the new file, 0 → 30. |
| Analyzer and audio | `flutter analyze` is clean. Audio: 180/180 assets match. |
