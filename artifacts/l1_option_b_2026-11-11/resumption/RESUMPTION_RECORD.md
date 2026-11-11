# L-1 Option B: resumption after the Gate 4 HOLD (11 November 2026)

## Founder decisions (11 November 2026)

- **D-1, APPROVED.** Regenerate and commit only `artifacts/v2_phase_d2/b8/CONTENT_REVIEW_PACK.md` and `MANIFEST.json`, provided every substantive change in them comes from approved L-1 copy.
- **D-2, APPROVED.** In the L-1 Reset warning, "show or recover" becomes "show or restore".
- The B8 guard, its regexes, its allowlist and its tests are not modified.

## What was done

1. **Gate 0.** The isolated tree was intact and byte-identical to the source of the first run. Its lib, test, pubspec and analysis fingerprint equals `../regression/SOURCE_FINGERPRINT_start.sha256`.
   - All 2,677 tracked paths were hashed again; exactly the 6 authorized files differ (`GATE0_TRACKED_PATHS_recheck.txt`).
   - The original checkout is unchanged: same status, and the two line-ending-only files still match their hashes.
   - Live origin and upstream are `d9369795`.
2. **Gate 1.** The failing-before evidence is kept exactly as it was: `../repro_before_fix/`, 88 tests with 33 passing and 55 failing.
   - The red tree's 387 lib, test and pubspec paths equal HEAD (`GATE1_RED_TREE_SOURCE_vs_HEAD.txt`).
   - Its L-1 test bytes match `../after_fix/L1_TEST_FILES_sha256.txt`.
   - It was not rerun.
   - Since then one word changed in `test/features/l1/l1_fixture.dart`: the expected Reset-warning literal, "recover" → "restore". The failing-before result for that assertion doesn't depend on the word: on the frozen tree the Reset control isn't shown at all.
3. **D-2.** That one word was changed in `lib/features/home/presentation/widgets/journal_data_controls.dart` (`UnreadablePreferencesCopy.resetBody`) and in the L-1 fixture's matching literal. Nothing else changed.
4. **D-1.** The pack was regenerated with the unmodified generator, in an isolated clean clone at `d9369795` holding only the final L-1 files, so that `gitHead` is real.
   - The bytes were copied into the tested tree.
   - Every changed line is classified in `B8_PACK_DIFF_CLASSIFICATION.md` (all of it is L-1 copy or mechanical metadata).
5. **Gate 3.**
   - `flutter analyze`: clean.
   - B8 live-copy guard: 11/11, and B8 review pack: 1/1 (expanded logs here).
   - L-1 suite: 88/88 (`l1_suite_final.jsonl`).
   - Focused R8 controls: 973/973, the same 973 tests in the same 60 files as `../after_fix/` (`focused_r8_controls_final.jsonl`).
6. **Gate 4.** A fresh full regression ran: `../regression_final/` (3,143 passed, 0 failed, 0 skipped). It was authoritative when it ran and is **superseded by step 7**.
   - The first run, `../regression/` (3,141 passed and 2 failed), is kept unchanged as the HOLD record (`../gate4_hold/HOLD_RECORD.md`).
   - It is not a pass.
7. **Before staging.** Two L-1 test files were found to be CRLF; they were normalized to LF (`LF_NORMALIZATION_RECORD.md`). The L-1 suite was rerun (88/88), and a new definitive regression ran: `../regression_definitive/` is **authoritative**, and `../regression_final/` is superseded.
