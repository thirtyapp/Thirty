# R8 — post-independent-audit remediation (2026-11-04)

**Status (2026-11-04, final): ACCEPTED by the founder at implementation and reported-test level, committed as one R8 commit on top of `8ece26f6` and pushed to `origin/step5-billing-integration`. Not an independent audit closure: see `AUDIT_HANDOFF.md`. The sections below are kept as written at each stage; where they conflict, the later section wins.**

R8 is not an audit closure. The audited commit `8ece26f6dbd41f573e854b8fc82f44a6942282e3` stays unchanged, and so do both audit verdicts on it:
- Astra: FAIL;
- Claude: CONDITIONAL PASS.

Both auditors must review a new SHA, or the R8 delta against `8ece26f6`.

## Inputs

**Claude post-R7 audit (CONDITIONAL PASS, F-1…F-6 plus recommendations).** I read it in full.

**Astra post-R7 audit (FAIL, R7-A01…A08).** The report is **not on this machine** and was **not read**. Finding IDs, severities and the alleged behaviour are taken from the founder's R8 directive. Each allegation was first confirmed against the source, then reproduced by a test that was actually run. Astra's own reproduction scenarios have **not** been cross-checked; they should be before acceptance.

**Original R7 handoff:** `artifacts/r7_final_regression_2026-11-04/AUDIT_HANDOFF.md`.

## Shared root cause and the bounded fix

Most of the findings come down to two habits:
- **Write results were not checked.** Every store treated a `false` write as a success. The write queues swallowed exceptions.
- **The in-memory cache was trusted.** `shared_preferences` updates its cache before the disk write, so THIRTY read back values that were never saved.

The fix is one primitive, `lib/core/storage/confirmed_write.dart` → `writeConfirmed`:
- a throw and a `false` are both failures;
- on failure, the key is put back as it was and `StorageWriteFailed` is thrown;
- Delete's own removals are the one exception: they are not put back, per the R3 founder rule.

Every user-data store now writes through `writeConfirmed`: Today's day keys, the journal, kept Circles, Plans, Insights and Delete.

Failures reach the user through the existing app-shell notice:
- History failures use the approved copy.
- Kept-Circle, Plans and Insights failures use a new title, **proposed** below.

Nothing beyond that was rewritten.

## Results

**Reproduction against the audited code.** Every R8 test was run in final form against the R7 source tree (`33079135…` in `../Thirty-verify-r7`). **73 tests fail there.** 21 pass, as intended guards. See `repro_on_r7_tree/REPRO_ON_R7_TREE.json`.

**After the fix: all pass.**

`repro_before_fix/` holds the first runs, made with earlier drafts of the same tests on the same R7 code. Two drafts had test bugs, fixed before the final run and listed in `CHANGES.md`.

**Full regression** (`regression/`):
- Run as memory-bounded sequential batches.
- **167 of 167 test files; 2,448 passed, 0 failed, 0 skipped.**
- `report` reports EVIDENCE OK and exits 0.
- `cases` reports CASES OK and exits 0: all 13 year profiles ran, each exactly once.
- `SOURCE_FINGERPRINT_start/end.sha256` hash every file in `lib/`, `test/`, `pubspec.*` and `analysis_options.yaml`. They are identical, so the tested source did not change during the run.

**Static and asset checks:**
- `flutter analyze`: no issues.
- Audio 172/172 and 8/8 SHA-1 OK; 180 files; no audio file was touched.

**B8 review pack:** regenerated. Its diff contains exactly the three proposed strings.

## Files

| Path | What |
|---|---|
| `ISSUE_REGISTER.json` | 15 entries, overlapping findings deduplicated, every auditor and ID kept. Each entry has the root cause, files, fix, reproducing tests, failure injection, the result on the R7 tree, the result after the fix, and limitations |
| `CHANGES.md` | every changed file, and every edit to an existing test with its reason |
| `repro_on_r7_tree/` | authoritative before-fix runs: JSON logs, `summarize.py`, `REPRO_ON_R7_TREE.json` |
| `repro_before_fix/` | the first pre-fix runs, from earlier test drafts |
| `regression/` | runner, plan, per-batch summaries and logs, `COVERAGE_MANIFEST.json`, `CASE_COVERAGE.json`, source fingerprints |

## Needs the founder

1. **Proposed copy:**
   - "This change couldn’t be saved." (body: the approved "Your existing saved data wasn’t overwritten.")
   - "Your history wasn’t deleted." / "Nothing was changed. You can try again."
2. **`midnightCarryOverLimit` = 6 hours** (TUNABLE, proposed). This is how long a Circle from the day before is brought back after a resume or restart after midnight.
3. **R3 timing change (deliberate, required by R7-A04).** Delete now clears memory once its intent is confirmed on disk, not before. An intent that fails once is retried, and the deletion completes. One that can't be recorded at all deletes nothing.
4. **The Astra report itself**, to cross-check its reproduction scenarios.

## Not done (out of scope, as directed)

- No device QA.
- No commit or push.
- No change to localization, pricing, Supabase, RevenueCat configuration, the Founder Dashboard or audio.
- A2-06, A2-07, the pre-commercial security review, the six-language launch and the final audits stay OPEN.
- Phase E: HOLD.

---

## Pre-commit gate — 2026-11-04 (later the same day)

**Founder decisions applied:**
- **D1 copy.** Typographic apostrophes, as elsewhere in the app. Both notices announce their title to TalkBack and close with "Close".
  - Save not confirmed: "This change couldn’t be saved." / "Please try again."
  - Delete never began: "Your history wasn’t deleted." / "Nothing was changed. You can try again."
  - The four strings are listed in `LOCALIZATION_INVENTORY_ADDITIONS_R8.csv`.
- **D2: six hours of real elapsed time.** Frozen in the contract (Circle V2 amendment 2026-11-04).
- **D3: the Delete intent is confirmed first.** Frozen in the contract (Delete / Export amendment 2026-11-04). The write barrier now begins only after the intent is confirmed (R8-18).

**Corrections, each written as a failing test first** (`repro_before_fix/r8b_precommit_persistence__before.txt`: 11 failures on the pre-gate R8 code):
- **R8-16 (P2):** a recovery-record cleanup that fails is pending retry, never reported as "not saved".
- **R8-17:** the next day's choice never writes over an earlier Close that History doesn't hold yet.
- **R8-18:** a Delete that never began stops no write on its way.
- **Unsaved state:** "unsaved, pending retry" vs "durably saved" is now explicit (`StoreSaveState.unsaved`).

**Additional failure-injection tests:**
- the I4 mark throwing after a Keep succeeded;
- a different unreadable copy already set aside (Plans and Insights);
- the final step failing after every key landed (P2, and Delete's marker);
- a refused Plans write that stays visible as unsaved;
- a restart before any retry;
- a Start whose Plans evidence write fails;
- removing a kept Circle failing;
- a stage Circle carried over midnight, credited once;
- the six-hour boundaries for restart, resume and a closed Circle;
- the daylight-saving change of 25 October 2026.

**Astra report:** now read in full (`docs/audits/THIRTY_ASTRA_POST_R7_AUDIT_SHARED_REPORT.md`). The extended Library report it links was not supplied.

**Final regression** (`regression/`; the first run is kept in `regression_run1_superseded/`):
- **169 of 169 test files; 2,484 passed, 0 failed, 0 skipped.** EVIDENCE OK, CASES OK (13 of 13 year profiles, each once).
- The source fingerprint was identical before and after the run. Git blob manifest: `regression/SOURCE_MANIFEST_git_blobs.txt`.
- `flutter analyze`: no issues. Audio 172/172 and 8/8; 180 files; no audio file was touched.

**Commit proposal:** `COMMIT_INVENTORY.md`.
