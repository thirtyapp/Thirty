# L-1 Option B: Gate 4 HOLD (11 November 2026)

**Result: HOLD.** The definitive regression ran to completion with 3,141 tests passed and **2 failed**. Hard stops 9 and 11 apply.

Nothing was staged, committed or pushed. HEAD, upstream and live origin are all still `d9369795`. The founder's working tree is byte-identical to its state at Gate 0.

## The run (`../regression/`)

| Item | Result |
|---|---|
| Test files | 210 (208 + 2 new) |
| Tests | 3,143 (3,055 + 88) |
| Raw logs | 24 |
| Duplicates / skips / incomplete batches / unexpected suites | none |
| Year-long profiles | all 13, each run exactly once |
| B8 simulation | 6/6 |
| Fingerprints and blob manifests | identical at start and end |
| Failures | the 2 below, both in batch 6 |

## The two failures: existing B8 content guards, not behaviour

**1. `test/features/b8/b8_live_copy_guard_test.dart`, "unsupported health claim"**
- The guard's pattern `\brecover\w*` matches the founder-recommended Reset warning: "…choices THIRTY can’t currently show or **recover**."
- The word is not a health claim.
- The guard is frozen ADR-024 B8 policy. Clearing the failure requires one of two things:
  - editing that existing test's allowlist, which is not an authorized path; or
  - changing the founder-recommended word.
- A disposable preview replaced "recover" with "restore" in the copy and in the L-1 test literal. The guard then passed, and so did the L-1 UI suite: 82/82 (`PREVIEW_restore_guard_run.jsonl`).

**2. `test/features/b8/b8_review_pack_test.dart`, "the review pack … matches its manifest"**
- By design, any change to live copy fails this test until `artifacts/v2_phase_d2/b8/CONTENT_REVIEW_PACK.md` and its `MANIFEST.json` are regenerated (`--dart-define=EXPORT_B8_PACK=true`) and reviewed.
- Those are existing committed artifacts, outside the authorized paths. Mandate §16 also requires existing evidence to stay unchanged.
- In the preview the regenerated pack differs only by the L-1 copy (`PACK_DIFF_with_L1_copy.diff`):
  - nine new or changed live strings (666 → 675);
  - "Close" ×6 → ×7;
  - "Copy as text" counted again per surface;
  - the generation header and hash.

## Founder decisions requested

- **D-1 (needed for any copy change at all).** Authorize regenerating and committing `artifacts/v2_phase_d2/b8/CONTENT_REVIEW_PACK.md` and `MANIFEST.json` from the final tree, in the repository so `gitHead` is filled, as part of the L-1 commit, after the founder has reviewed their diff.
- **D-2, the word "recover".** Either:
  - (a) **recommended:** the warning reads "…choices THIRTY can’t currently show or **restore**", with no change to any existing test; or
  - (b) keep "recover", and authorize one allowlist entry in `b8_live_copy_guard_test.dart`.

After both decisions, the correction needs the copy and L-1 test change (if D-2(a)), the pack regeneration, a rerun of the L-1 and focused tests, a new full regression, and then Gates 5–7.
