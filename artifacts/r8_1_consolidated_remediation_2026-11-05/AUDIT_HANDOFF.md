# THIRTY — R8.1 independent audit handoff

**For two independent reviewers.** Accepted by the founder at implementation level on 2026-11-05. This handoff is **not** an audit result, and neither post-R8 audit is claimed as passed. Do not begin until the founder starts the audit.

## 1. What to audit

| Item | Value |
|---|---|
| Repository | `thirtyapp/Thirty` |
| Branch | `step5-billing-integration` |
| Target | The R8.1 commit: the single commit whose **parent is `58b179c99866e234acd63e4e241590af36b9b186`** on `origin/step5-billing-integration`, subject `fix(thirty): close R8.1 independent audit persistence findings`. Resolve it with `git log --format='%H %P %s' origin/step5-billing-integration -1` and check that the parent field is the R8 SHA. This handoff is inside that commit, so it can't contain the commit's own SHA. The founder's push record states the full SHA. |
| Parent (R8, audited by both post-R8 audits) | `58b179c99866e234acd63e4e241590af36b9b186` |
| R7 | `8ece26f6dbd41f573e854b8fc82f44a6942282e3` |

Audit the exact committed tree, preferably a clean `git archive` or detached checkout, not a working copy.

## 2. Inputs (read in full)

| Document | Path | SHA-256 |
|---|---|---|
| Astra post-R8 audit (FAIL: 3 HIGH, 6 MEDIUM, 1 LOW) | `docs/audits/THIRTY_INDEPENDENT_POST_R8_AUDIT.md` | `afc3631cbb54a67aaf02968a99ecc35431645621d71e0d5f0eb50cf9192f0ab1` |
| Claude post-R8 audit (CONDITIONAL PASS: 2 MEDIUM, 4 LOW) | `docs/audits/THIRTY_CLAUDE_POST_R8_AUDIT_REPORT.md` | `2519e0b2e6794dc06532ac8a8a40b83d0fe7debdf4aada825558460d9164f1c0`. This is the delivered text (LF), equal to the committed blob. Verify with `git show <target>:<path> \| sha256sum`. A CRLF checkout reads `8ebec3ce…`. |
| Claude's reproduction file (verbatim; never run from the repository) | `artifacts/r8_1_consolidated_remediation_2026-11-05/audit_inputs/claude_audit_r8_repro_test.dart.txt` | `efd63d49a1147cc18ae2404da0e41e03b2eb90a2163dbe0d06c41f8436b2b36f` |
| Consolidated register (11 entries carrying all 16 IDs, both severities, root cause, fix, tests, failing-before counts, founder decisions) | `artifacts/r8_1_consolidated_remediation_2026-11-05/ISSUE_REGISTER.json` | — |
| Evidence overview and change list | `README.md`, `CHANGES.md` (same folder) | — |
| RL-4 limitation record | `LIMITATION_RL4_OFFSET_FREE_TIMESTAMPS.md` (same folder) | — |
| Earlier context | `docs/audits/THIRTY_ASTRA_POST_R7_AUDIT_SHARED_REPORT.md`, `docs/audits/THIRTY_CLAUDE_POST_R7_AUDIT_REPORT.md`, the d89a035 scorecard `docs/audits/THIRTY_POST_V2_INDEPENDENT_AUDIT_GPT6_ASTRA_d89a035.md` | — |

## 3. Finding → fix → test map

| Register | Astra | Claude | Fix (production) | Tests (`test/features/r81/`) |
|---|---|---|---|---|
| R81-01 | N01 HIGH | AUD-1 MED | The Plans notifier tracks its confirmed state (`_durable`). `ensureSaved()` writes the record until the store confirms it. `recordGuided` and `noteStart` retry a change that is only in memory. Recovery reads `isCreditedDurably`. | `r81_n01_durable_plan_credit_test.dart` (8) |
| R81-02 | N02 HIGH | — | `lib/core/storage/preservation_writes.dart` tracks every pending aside copy. `_protectStored` waits for it. Delete waits for all of them, then clears both aside keys in its last pass. | `r81_n02_preservation_writes_test.dart` (10). Uses `FaultDisk.hold()`, a one-shot latch on a single platform write. |
| R81-03 | N03 HIGH | — | `removeAnswer` clears the answer from the day keys that hold that Circle, as one confirmed publication, before removing it from History. | `r81_n03_removed_answers_test.dart` (13) |
| R81-04 | N04 MED | — | `_persist` saves a started or closed stage Circle only once its Start record is on disk. Today keeps the Start's billing answer (`_startVerdicts`) to rewrite that record. | `r81_n04_n05_…` N04 group (7) |
| R81-05 | N05 MED | AUD-6 LOW | `CirclePlansNotifier.confirmed()`; Suggestion Preferences commit only once confirmed. I1, I2 and I3 are marked applied only after their own change is confirmed. | `r81_n04_n05_…` N05 group (11) |
| R81-06 | N06 MED | — | `ComposedSession.hasDamagedWording` / `wordingUnverified`. The Circle's words are restored from the kept Circle when possible; otherwise it is never voiced, and an unstarted one is never offered to start. | `r81_n06_n07_…` N06 group (13) |
| R81-07 | N07 MED | AUD-3, AUD-4 LOW | Plans keep unreadable Plan entries, damaged records and unknown fields. A present non-list Insights `snapshots` makes the record unreadable. | `r81_n06_n07_…` N07 group (8) |
| R81-08 | N08 MED | — | `steerToday(circleId:)`, so the served stage carries the choice's own day. | `r81_n08_n09_aud2_time_test.dart` (1) |
| R81-09 | N09 MED | AUD-5 LOW | Day-key Start, Close and pause are stored as UTC instants and read back as local time. | same file (4: both 02:30s of 25 Oct 2026) |
| R81-10 | — | AUD-2 MED | The new day opens once a carried-over Circle's reflection is saved. `chooseIntention` proceeds after an earlier, finished Circle. | same file (3) |
| R81-11 | N10 LOW | — | Closing a notice re-checks pending failures. A confirmed Kept save clears its "unsaved" status. | `r81_n10_failure_notices_test.dart` (5) |

### Founder corrections (2026-11-05)

- **RL-1 / AUD-6 (fixed):**
  - A failed latest Plans or Insights save takes the change back off the screen (state reverts to `_durable`). The store stays marked unsaved until a later save succeeds.
  - Insights decide only from `confirmedState`.
  - Today saves a stage Circle only after `confirmServed`. A pending, in-flight change may show.
  - The Plan action API is unchanged.
  - Tests: `r81b_rl1_pending_state_test.dart` (17).
- **RL-2 (approved copy):**
  - `ComposedCopy.unverifiedWordingTitle` / `unverifiedWordingBody`, shown as the note on every part, inside the part's live-region semantics label.
  - No dialog; never voiced.
  - Tests: `r81b_rl2_unverified_words_copy_test.dart` (3).
  - Localization: `LOCALIZATION_INVENTORY_ADDITIONS_R8_1.csv`.
- **RL-3 (fixed):**
  - `StageRecord.source` makes each stage record write back exactly as read.
  - Cycles and Plans keep `extra` (unknown or damaged fields) and `unreadableRevisits`. A cycle end THIRTY doesn't know makes the Plan unreadable, so it is kept as stored.
  - Suggestion Preferences: `tryRead`; damaged items and unknown fields are kept. A record unreadable as a whole is never written over by a change; only Reset removes it.
  - Tests: `r81b_rl3_field_preservation_test.dart` (12).
- **RL-4 (accepted, not fixed):** offset-free historical timestamps outside the six-hour rule; see the RL-4 record.

### Changes to existing assertions (founder-approved, RL-1)

1. **`test/features/home/r8b_precommit_persistence_test.dart`, R8 test "a Plan action the store refuses …"** (one definition, run for both `throws` and `returnsFalse`):
   - The expectation `active, isNotNull` ("the change stays on screen") is now `active, isNull` ("an unsaved change shown as made").
   - Everything else is unchanged: the store is marked unsaved, the disk has no Plans, the restart shows only what is durable, and the retry makes it durable.
2. **`test/features/home/r3_persistence_delete_test.dart`, J4 test "Today, Plan and Insight writes all queued at once …"**:
   - The precondition `heldToday.reached.isCompleted, isTrue` is now `isFalse`. Today's stage-Circle write now waits behind the held Plans write it depends on.
   - All of that test's deletion assertions are unchanged.
3. **Two of R8.1's own tests, before commit:**
   - the N01 "Astra N01 as reported" test: credit in memory 1 → 0 (not kept on screen);
   - N05 "applied mark refused": the mark is not kept in memory, and the failure is still told.

Diffs: `git diff 58b179c9 <target> -- test/features/home/r8b_precommit_persistence_test.dart test/features/home/r3_persistence_delete_test.dart`.

### Failing-before evidence

- **`repro_before_fix/`:** the 83 first-round R8.1 tests run on R8's own `lib/`: 66 not passing (60 failures + 6 errors).
- **`repro_before_fix_rl/`:** the 32 RL tests run on the first-round R8.1 `lib/`: 20 failures, plus the RL-2 file failing to compile because its copy didn't exist yet.
- **Caveat:** these logs record the tests as they were then written. Later edits were formatting and the founder-approved RL-1 assertion change in two first-round tests.

### Other committed change

The B8 content review pack (`artifacts/v2_phase_d2/b8/CONTENT_REVIEW_PACK.md`, `MANIFEST.json`) was regenerated with `--dart-define=EXPORT_B8_PACK=true`. The diff is:
- the 2 RL-2 strings;
- the header timestamp and HEAD;
- one apostrophe count (91 → 92);
- the manifest counts and hash.

## 4. Test inventory and evidence

- **Final regression:** `artifacts/r8_1_consolidated_remediation_2026-11-05/regression_final/`
  - **Totals:** 179 of 179 test files, **2,599 passed, 0 failed, 0 skipped**. 21 summaries, each with exit 0 and `done.success`; no duplicate test; no file in two batches.
  - **Runner checks:** `run_batches.py report` → EVIDENCE OK; `cases` → CASES OK.
  - **Simulations:** 13 year profiles each ran exactly once (p01–p11, p13, p14; the inventory has no p12). All 6 B8 simulations passed (A–D, voice-entitlement, E).
  - **Inventory:** the full list is `batch_plan.json` → `inventory`; per-file counts are in `COVERAGE_MANIFEST.json` → `perFile`.
  - **Execution:** sequential, one worker, free memory at least 6.2 GB (`MEMORY_LOG.txt`). The raw `batch_*.jsonl` logs are included.
  - **`flutter analyze`:** no issues (`FLUTTER_ANALYZE.txt`).
  - **Audio:** 172/172 production and 8/8 framing SHA-1 match; the 180 bundled files are exactly those the manifests name (`AUDIO_VERIFICATION_after_RL.txt`).
- **Superseded, not final evidence** (summaries only; raw logs not committed):
  - `regression/`: the earlier 2,567-test run before the RL corrections (`SUPERSEDED.txt`);
  - `regression/interrupted_run1_batch10/`: stopped by Claude Code for low memory;
  - `regression_final/aborted_attempt1_review_pack_stale/`: stopped at batch 6 on the stale review pack.
- **About the raw logs:** they contain absolute paths from the build machine (`C:/Users/<account>/…`). They hold no user data, credentials or device data.

## 5. Verifying the tested source equals the commit

`regression_final/SOURCE_MANIFEST_git_blobs.txt` lists 357 `<blob-sha> <path>` lines for `lib/`, `test/`, `pubspec.yaml`, `pubspec.lock` and `analysis_options.yaml`, taken from the exact tested working tree (`git hash-object`). Check it against the commit:

```sh
git ls-tree -r <target> -- lib test pubspec.yaml pubspec.lock analysis_options.yaml \
  | awk '{print $3" "$4}' | LC_ALL=C sort -k2 > /tmp/committed.txt
LC_ALL=C sort -k2 SOURCE_MANIFEST_git_blobs.txt | diff - /tmp/committed.txt   # must print nothing
```

`SOURCE_FINGERPRINT_start.sha256` and `SOURCE_FINGERPRINT_end.sha256` are byte-identical working-tree SHA-256 lists taken before and after the run. Line endings may differ on checkout, so the blob manifest is the authoritative check.

## 6. Please challenge, specifically

1. Cross-store durability and optimistic state: Plans, Insights, Today, the journal, Kept Circles and preferences. Can memory still lead the disk anywhere a decision depends on it?
2. Delayed preservation writes and Delete races. Is any writer still outside the preservation tracker or the History gate?
3. Removed History answers coming back through recovery: the day keys, the pending-write record, restarts, interrupted removals.
4. Plan credit and expiry provenance: `noteStart`, `_startVerdicts`, `confirmServed`, `recordGuided`, lapses mid-session.
5. Durability of I1, I2 and I3 versus I4 actions, including lapse and the two-store interleavings.
6. Unknown or malformed persisted records in every store. Look for lossless round-trips and refusal paths that strand users.
7. Midnight, the six-hour carry-over and time zones: both 02:30 occurrences, legacy offset-free values, no-touch activation.
8. Historical content and voice fallback for kept Circles: the `wordingUnverified` paths and the RL-2 note.
9. Realistic concurrency and restart sequences beyond the latch tests. This includes the real Android `SharedPreferences` commit semantics, which were not validated.
10. Defects newly introduced by R8.1, outside the old register. Example: rollback when several saves are queued, `ensureSaved` deduplication, and the stage-Circle publication now waiting on Plans.

## 7. Scoring

- **Historical scorecard:** reuse the original 31-dimension d89a035 scorecard (0–10 with certainty, no overall average) where relevant, and mark dimensions not reassessed.
- **No invented totals:** no R7, R8 or R8.1 historical totals exist, so don't invent one.
- **New engineering total:** any score out of 100 must define its rubric up front and be labelled **NEW — NOT HISTORICALLY COMPARABLE**.

## 8. Known LOW limitations (founder-accepted for this engineering baseline; not commercial approval)

- **RL-4:** offset-free times in History, Kept Circles and preferences. A displayed time can be off by one hour on the clock-change night; the six-hour rule is unaffected.
- **Pending-then-failed stage Circle:** a stage Circle composed while its Plan change was still being written, after which the write failed, stays on screen. It is never saved and never credited; the notice is told; it is gone after a restart.
- **Unreadable Plan entry:** a stored Plan THIRTY can't read can't be started over. Start does nothing, with no message, because a message would need new copy.
- **Unreadable Suggestion Preferences:** changes are refused (and told each time) until the user uses Reset.
- **Unchanged, previously approved:** notification-shade resume handling; analytics events firing at the tap.
- **Not validated:** no device QA (S25, TalkBack, real Android storage failures, process kill).

## 9. Open release gates (all still open)

A2-06 analytics/privacy · A2-07 Android backup, migration and Premium restoration · pre-commercial billing and APK security · six-language localization and native-language QA · multilingual audio · real-device QA · final commercial release audit.

The standalone KEYBRACE Founder Dashboard stays separate. KEYBRACE OS is discontinued. **THIRTY Phase E remains HOLD. No release is authorized.**
