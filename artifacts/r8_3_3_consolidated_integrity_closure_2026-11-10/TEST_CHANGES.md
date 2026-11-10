# R8.3.3 — test changes

## New files (2)

| File | Tests | Runs on R8.3.2? |
|---|---:|---|
| `test/features/r833/r833_reproduction_test.dart` | 30 | Yes. It uses only APIs that exist at `d4cf8c44`. |
| `test/features/r833/r833_identity_contract_test.dart` | 3 | No. It uses `keptIdRandomProvider` and `newKeptId`, which are new in R8.3.3, so it does not compile on R8.3.2. It is reported as **not applicable**, never as a failing-before test. |

Final SHA-256 of both files: `repro_after_fix/TEST_FILES.sha256`.

- **`r833_reproduction_test.dart` (8d82bcb1…).** The definitive before-fix run, the after-fix run and the definitive full regression used exactly these bytes.
- **`r833_identity_contract_test.dart`, two hashes.**
  - *a4891572…* is the version in `repro_before_fix/TEST_FILES.sha256`. The after-fix 3/3 run in `repro_after_fix/` used it.
  - *b2baca74…* is the final version. It removes one unused import that `flutter analyze` reported, and is otherwise byte-identical.
  - The definitive regression (run 2) used the final version.
  - On R8.3.2, both versions fail to compile, for the same reason: the new APIs are missing. Both are N/A there.

## Existing test files

No existing test or support file was modified.

## Supporting production change found by the regression

Diagnostic run 1 (`regression_run1_DIAGNOSTIC_INCOMPLETE/`) failed `test/core/qa/qa_scenario_test.dart`: "the same scenario and reference date always build the same store".

- **Cause.** The QA store builder (`lib/core/qa/qa_scenario.dart`) keeps Circles through the production `keepCircle`. Since R832-A02, a kept Circle's id has a random part.
- **Fix.** The builder's own container now overrides `keptIdRandomProvider` with `Random(0)`. Its documented contract — the same inputs build the same store — holds again.
- **Production is unchanged.** The app's own ids stay random. The test was not modified.

## Edits made to the new suite before it was frozen (full disclosure)

The suite was written before any production change. These edits were made while it was being developed. None of them changed a reproduction's substantive assertion.

1. **Compile fix (before any run).** A helper returned `Future<Future<void>>`. Dart flattens that type, so the helper now returns a record, `({Future<void> run})`.
2. **A01-v7, before the fix.** The control first set `fail(times: 2)` on the deletion intent. `writeConfirmed`'s own restore write took the second fault, so the Delete went ahead. The fault is now unbounded and is healed once the Delete has given up. The purpose is unchanged: a Delete refused before its intent is durable.
3. **A02-G, before the fix.** The control first used a plain `ackLost`. `writeConfirmed` restores the previous value after a thrown write, so nothing stays on disk; this is the existing B2-6 semantics. The control now uses `ackLost(thenStop: true)`, the process stopping after the Keep lands, as in the existing B2-7. It checks proof with the original date.
4. **A01-v3, after the fix.** The expected result was `notSaved`. It is now `notSaved` *or* `notAvailable`:
   - R8.3.2 returns `notSaved`.
   - R8.3.3 returns `notAvailable`, because the Insight is being deleted.

   The substantive assertions are unchanged:
   - the Delete succeeds;
   - no deleted id survives;
   - the Plan stays paused.
5. **A01-v10, after the fix.** The post-Delete History first had 5 Circles over 5 days. The engine's pattern gate needs at least 5 Circles over at least 14 days, so no fresh I1 could be generated. The History is now 5 Circles over 16 days, three weeks after the Delete, in the same process, with `nowProvider` invalidated. On R8.3.2 the test stops at an earlier PRECONDITION: the Plan is already active after the Delete, because of the A01 defect.

## Original auditor material (unchanged bytes)

The following were run unedited in a disposable copy (`tree_fixed` in the session scratchpad), whose `lib/` is identical to the working tree:

- Claude's post-R8.3.2 probe file. Copied from its audit session; its SHA-256 is in `audit_inputs/AUDIT_INPUT_HASHES.txt`.
- The four original pre-R8.3.2 auditor files, renamed back from `.dart.txt`.
- The final-gate checks.

Astra's three post-R8.3.2 probes were **not available**. No evidence ZIP was found on this machine. They were reconstructed from the report's §10 source chains as A01, A02-A and A02-B.
