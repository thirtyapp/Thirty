# THIRTY: bounded independent acceptance of L-1 Option B (exact SHA)

**Do not begin until the founder launches it.** This is not a general R8 architecture audit.

**Target:** the commit on `step5-billing-integration` that contains this file.
- Its sole parent is the frozen R8 baseline `d9369795a92aa24505c475fa1417d03132300c4a`.
- The exact SHA and tree are in the founder's report and the push record.
- Audit an exact-SHA export only (`git -c core.autocrlf=false archive <sha>`).
- Don't trust the implementer's PASS: rerun everything below.

## Scope

**1. L-1A: truthful, qualified Delete.**
- History, today's session, the Insights and Plan stage evidence are deleted and confirmed. The Plan's place and kept Circles stay.
- A Suggestion Preferences record THIRTY can't read as a whole (newer schema, damaged text, a list field that isn't a list, a non-text native value) stays byte- and type-identical, and is never rewritten or applied.
- The notice "Some saved preferences couldn’t be checked" appears only after a Delete that succeeded. It must never appear after an intent that was refused or uncertain, after a History removal that was refused, or after one that landed with a lost answer.
- The confirmation's one-sentence qualifier appears only for an unreadable record.
- Readable records keep the full attribution removal: a refused write fails the Delete and keeps it pending.

**2. Start-up recovery.**
- An interrupted Delete finishes on the next start. Repeated starts are idempotent.
- Being unreadable never leaves the marker set and never blocks a new Circle.

**3. L-1B: export fidelity.**
- `suggestionPreferencesStored` carries the value typed and losslessly: text and string lists as they are, an int as decimal text, a double as `ieee754Hex`.
- It appears only for an unreadable record, and then `suggestionPreferences` is absent.
- It works from History, You and the memory page, and Copy is enabled when the record is the only data.
- A failed export or clipboard call says so and never says "Copied".
- A Copy taken while a Reset is being written exports the last confirmed record.

**4. L-1C: Reset and transparency.**
- The memory notice is derived from the store and survives a restart.
- Reset is reachable with its own warning, which reads "…show or restore." (founder D-2).
- Cancelling writes nothing.
- A Reset that is refused, uncertain, or lands with a lost answer keeps both the record and the notice.
- A confirmed Reset removes both, and they stay gone after a restart.
- Readable-preferences Reset is unchanged.

**5. Storage confirmation.** The R8 confirmed-write semantics must be unchanged. In particular, `_change` still refuses every write over an unreadable record except Reset (`erase`).

**6. B8 integrity.**
- `b8_live_copy_guard_test.dart`, `b8_review_pack_test.dart` and `support/live_copy.dart` are byte-identical to `d9369795` (`resumption/B8_TEST_SOURCES_sha256.txt`).
- Regenerate the pack from the target and confirm that it matches the committed one apart from the timestamp. Check `resumption/B8_PACK_DIFF_CLASSIFICATION.md`: the diff must be L-1 copy only.

**7. Regression evidence.**
- `regression_definitive/` is the authoritative run, on the exact committed bytes.
- `regression_final/` passed but is superseded, because two L-1 test files were then normalized from CRLF to LF (`resumption/LF_NORMALIZATION_RECORD.md`).
- `regression/` is the earlier failed run, kept on purpose. It is not a pass.
- Rerun the full suite on the clean export if possible.

**8. Directly affected R8 guarantees.**
- The Delete engine is untouched: `circle_history_deletion.dart` is identical to the parent.
- Check the R834-N01 tests, the r81–r834 suites and kept-Circle and Plan ownership.

## Inputs

- Failing-before: `repro_before_fix/`. The frozen tree plus the L-1 tests gave 33 passed and 55 failed.
  - Rerunning the target's `test/features/l1/` on an export of `d9369795` should give the same split.
  - One literal now differs from that run: "restore" in `l1_fixture.dart`. That assertion fails on the frozen tree either way, because Reset isn't shown there.
- Discovery probes: `discovery/*.dart.txt`, characterisation only.

## Classification rules

- Setup or compile errors are not defects.
- A precondition that can't be set up is N/A, not PASS.
- Count a probe only if it actually ran.
- Report anything that weakens user-data preservation as at least MEDIUM.
