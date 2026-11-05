# THIRTY — INDEPENDENT POST-R8 AUDIT

**Verdict: CONDITIONAL PASS.** R8 fixes all fourteen original findings in production code, and my own full test run matches the reported results exactly. I found no CRITICAL or HIGH defect and no unauthorized Premium access. I found one MEDIUM data-loss defect that breaks a guarantee frozen in the R8 pre-commit gate (AUD-1). That defect blocks R8 baseline acceptance until it is fixed, or until the founder explicitly narrows the guarantee. The audited repository was not modified.

## 1. Commit identity

| Item | Verified |
|---|---|
| Target | `58b179c99866e234acd63e4e241590af36b9b186`, the tip of local and `origin/step5-billing-integration` |
| Parent | `8ece26f6dbd41f573e854b8fc82f44a6942282e3`, as expected |
| Author / date | Thomas Daelman, 2026-11-04 17:51 +0100 |
| R8 diff | 157 paths, +26,094 / −392 |
| Audio | No audio file changed |

- **What I audited:** clean `git archive` exports of the target and the parent, placed in my scratch folder. I did not use the local worktree: it is on `main` (`a8b4088`) with 9 uncommitted entries, unchanged before and after this audit.
- **Required inputs, all read:**
  - the handoff;
  - both post-R7 reports;
  - the d89a035 scorecard.

## 2. Method and limitations

**Executed independently (Flutter 3.44.8 / Dart 3.12.2):**
- `pub get --offline --enforce-lockfile`;
- `flutter analyze`;
- the full test suite;
- 5 new reproduction cases of my own.

**Inspected only, not run:**
- `run_batches.py` (its exit logic read, not run);
- the implementer's R7-tree reproduction JSON;
- the Kotlin audio code.

**Static analysis only:**
- partial-key and concurrency reasoning for the write queues;
- the daylight-saving parsing note in AUD-5.

**Not validated:**
- a real device or process kill;
- the Android `SharedPreferences` commit semantics. Whether the platform really reports `false` or throws decides how strong every "confirmed" guarantee is on a phone.
- RevenueCat and Play lifecycle;
- TalkBack;
- backups.

## 3. Closure matrix: original findings

| ID (original severity) | Source | R8 implementation | Status | Test coverage |
|---|---|---|---|---|
| **Astra R7-A01** (HIGH) | `recommendation_provider.dart` `_enqueue` / `_publish` | Every day key goes through `writeConfirmed`. The write-ahead record is confirmed first, failures are reported (`_markUnsaved`), and removing the record is treated as cleanup to retry. | **Fixed** | Meaningful: throw and `false` on every key |
| **Astra R7-A02** (HIGH) + **Claude F-3** (LOW) | `kept_circle.dart` `keptCollectionFromRecord`; `kept_circles_provider.dart` `write` | A non-list `kept` makes the record unreadable, and `write` refuses to overwrite it. Unknown top-level fields are written back. | **Fixed** | Meaningful |
| **Astra R7-A03** (HIGH) + **Claude F-6** (LOW) | `kept_circles_provider.dart` `_commit`; `insights_provider.dart` `_keep` / `apply` | Keep updates state only after the save is confirmed. I4 is marked applied only after its Keep lands. If the I4 mark itself fails, a retry finds the Circle already kept and marks it applied. | **Kept and I4: fixed.** **Plans and Insights: partial.** Failures are no longer silent, but changes are still shown before they are on disk (AUD-6). | Meaningful for Keep and I4. Plans "still on screen" is tested as intended behavior. |
| **Astra R7-A04** (HIGH) | `circle_history_deletion.dart` | The intent is confirmed (one retry) before the barrier, memory clearing or any removal. Every removal is confirmed; `_all` waits for every step; the marker is removed last; startup repeats the deletion. | **Fixed** | Meaningful, including `false` returns |
| **Astra R7-A05** (MEDIUM) | `circle_journal.dart` `recordClosed` | `recordClosed(startedAt:)` fills in a missing Start without changing a recorded one. | **Fixed** | Yes |
| **Astra R7-A06** (MEDIUM) | `you_data_card.dart` | `holdsHistory` covers records it can't read, a journal it can't open, and preserved copies; Insights are also considered. | **Fixed** | Yes |
| **Astra R7-A07** (MEDIUM) | `kept_circle.dart:116–125` | A wording field that is present but damaged turns the record into a `RetainedKept`: never run or voiced, still counted toward the 8. | **Fixed** | Yes |
| **Astra R7-A08** (MEDIUM) + **Claude F-1** (MEDIUM) | `recommendation_provider.dart:912–921` `build`; `carriesOverMidnightAt` | Yesterday's started Circle, or one closed after midnight with its reflection open, is restored on resume or restart within 6 h of elapsed time (`DateTime.difference`). | **Fixed**, but introduces AUD-2 | Yes, including the boundary and DST cases |
| **Claude F-2** (LOW) | `_choiceTime`, `useOwnedToday` | A choice uses real time, never earlier than the cached time. | **Fixed** | Yes |
| **Claude F-4** (LOW) | `insight.dart` `fromJson` | Every snapshot date must be canonical; damaged snapshots are kept as stored. | **Fixed** (but see AUD-4 for the whole-list case) | Yes |
| **Claude F-5** (LOW) | `circle_journal.dart` `_write` | `writeConfirmed` puts memory back on failure. | **Fixed** | Yes |
| Claude recommendation: newer journal records | `circle_journal.dart` | A record with a higher `schemaVersion` is kept verbatim. | **Fixed** | Yes |
| Astra MEDIUM restore defect | `premium_access.dart:103–106` | "Restored" is reported only if the follow-up check returns `active`. | **Fixed** | Yes |
| Astra LOW: evidence automation | `regression/run_batches.py` | `report` and `cases` exit non-zero on any mismatch or a missing `done.success`. | **Fixed** (inspected, not run) | n/a |

I found no weakened assertions in the modified pre-existing tests. The changes are async adaptations (`await apply(...)`) and stricter exception types (`StorageWriteFailed` instead of `StateError`).

## 4. New findings

### AUD-1 — MEDIUM — The next day's choice can overwrite a closed stage Circle whose Plan credit is only in memory (permanent loss of Plan progress)

**This finding blocks baseline acceptance.**

- **Guarantee broken:** R8-17, frozen in the handoff §5 and in the comment at `recommendation_provider.dart:791–795`: the earlier session is never written over "until History holds it, and its Plan credit is saved".
- **Root cause:**
  - `CirclePlansNotifier._set` puts the new state in memory before the write is confirmed, and keeps it there if the write fails (`circle_plans_provider.dart:92–94`).
  - `recordGuided` decides whether a credit is already recorded by looking at that in-memory state (`circle_plans_provider.dart:301–309`, `if (identical(next, state)) return Future.value()`).
  - So in `_recordBeforeOverwrite` (`recommendation_provider.dart:858–877`), the call `await _creditGuided(earlier)` at `:876` succeeds after a failed earlier attempt, even though nothing is on disk. The day keys then move to the new day, and the only source the credit could be recovered from is gone.
- **Reproduction** (`AUD-1`, both `throws` and `returnsFalse`):
  1. Start a Plan, choose its stage Circle, and Start it.
  2. Make the Plans key fail persistently.
  3. Close the Circle.
  4. Next day: restart with the fault kept, and choose a Circle.
  5. Heal the disk and restart.
- **Observed:** after step 4 the day key holds the new day (yesterday's session was overwritten). History holds yesterday's Close, but the credit count for that Circle is **0**. Nothing recovers it after any number of restarts.
- **Mitigation:** the user does see a "Plans not saved" notice. The credit is lost only if the Plans store keeps failing until the app restarts.
- **Test gap:** the "persistent History failure" test covers only a failing journal, never a failing Plans store.

### AUD-2 — MEDIUM — After a carried-over Circle is finished, today's Circle can't be chosen until the app is resumed again

- **Evidence:**
  - The resume invalidates `nowProvider`, so `_newDay` (`thirty_app.dart:110–111`) is `false` from then on.
  - `_openNewDayIfDue` therefore never opens the new day.
  - `chooseIntention` returns early while any recommendation exists (`recommendation_provider.dart:1213–1214`).
  - R8's own test accepts this explicitly: "Answered: the next resume opens the new day" (`r8_midnight_resume_test.dart:141`).
- **Reproduction** (`AUD-2`):
  1. A Circle is started at 23:40.
  2. The app is resumed at 00:10, the Circle is closed and the reflection answered.
  3. The user taps the screen and calls `chooseIntention`.
- **Observed:** today's Circle is still `2026-08-01`, closed, and the choice does nothing.
- **Impact:** in that session, Today stays on yesterday's finished Circle until the user backgrounds or restarts the app. No data is lost.
- **Contract:** the handoff says "until the user finishes it; then the new day opens". Either fix this, or the founder explicitly narrows that wording to "the next resume".

### AUD-3 — LOW — A Plan or cycle this build can't read is silently dropped on the next Plans save

This predates R8, but it contradicts R8's claim that "unreadable or newer data is kept byte for byte".

- **Evidence:**
  - `circle_plan.dart:444`: an unknown `planId` makes `PlanProgress.fromJson` return null.
  - `circle_plan.dart:546–549` (`?PlanProgress.fromJson`): such a Plan is simply skipped, and `:452` skips a damaged cycle the same way.
  - The record as a whole stays "readable", so `_protectStored` never sets anything aside.
- **Reproduction** (`AUD-3`): add `future_plan` to the stored record, then pause `getting_going`. The stored Plans now hold only `[getting_going]`, and nothing was set aside.
- **Impact:** a downgrade or a damaged record loses Plan progress permanently.

### AUD-4 — LOW — An Insights record whose `snapshots` field isn't a list is overwritten without being kept

This is the same shape as R7-A02, but in the Insights store.

- **Evidence:** `insight.dart:418–421` reads a non-list `snapshots` as an empty list, so `_readable` (`insights_provider.dart:124–137`) treats the record as readable.
- **Reproduction** (`AUD-4`): store `{"schemaVersion":1,"snapshots":{"original":"recoverable payload"}}`, then run `assess()`.
- **Observed:** the payload is replaced and `insightsUnreadableKey` stays null.
- **Impact:** applied, "Not now" and declined decisions are lost.

### AUD-5 — LOW (static analysis only) — Session times are stored as local time without an offset

- **Evidence:** `recommendation_provider.dart:2227` and `:2233` store `toIso8601String()` of a local `DateTime`.
- **Impact:** a Start inside the repeated hour on the night the clocks go back reads back ambiguously, so the 6-hour carry-over can be off by one hour. This is a narrow edge.

### AUD-6 — LOW — Plans and Insights changes are shown, and reported as done, before they are on disk

- **Evidence:**
  - `circle_plans_provider.dart:150`, `:214`: `_set(...).ignore()`.
  - `insights_provider.dart:93–94`.
  - `PlanActionResult.done` and `InsightActionResult.done` are returned before the write is confirmed.
- **Impact:** a failure is announced and retried on the next save, so it is not silent. But the handoff's R8-03 wording "confirmed before shown" is true only for Keep. This pattern is also the root cause of AUD-1.

### Recorded but not counted as findings

These are the handoff's own stated limitations, and I agree with how they are described:
- A Circle left running in the foreground for more than 6 hours is dropped by a resume after only `inactive` (for example, the notification shade).
- Analytics events fire at the tap, before persistence.

## 5. Reproduction file

- **Where:** `C:\Users\thoma\AppData\Local\Temp\claude\b7fd4c17e92f619e\e03b043d-dedb-4c90-bb8a-44a62e1206ad\scratchpad\repro\test\zz_audit\audit_r8_repro_test.dart`. It is in a scratch export only, never in the repository.
- **How it runs:** it uses the commit's own `R8Harness` / `FaultDisk`.
- **Result:** 5 cases, **all 5 fail**, which confirms AUD-1 (twice, once per fault type) through AUD-4.

## 6. Tests I ran myself

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| `flutter test --concurrency=3 --reporter=json` (one process, not batches) | **2,484 passed, 0 failed, 0 skipped; 169 files; `done.success=true`; exit 0** (about 15.7 min) |
| My suite list vs. test files on disk | Identical (169) |
| Audit reproductions | 5 of 5 fail, as described in §4 |

This independently confirms the reported total. It does not mean the suite covers AUD-1 to AUD-4.

## 7. Evidence and source equivalence

- **Git-blob manifest:** the `git ls-tree` output for the commit, diffed against `SOURCE_MANIFEST_git_blobs.txt`, is **empty**. That is 346 blobs, and the manifest's sha256 `862b924b…3eee` matches the claim.
- **Raw logs:** I parsed `batch_*.jsonl` with my own script, not the implementer's:
  - 2,484 / 0 / 0;
  - 169 suites, identical to the files on disk;
  - all 20 batches have `done.success=true`.
- **Year profiles:** p01–p11, p13 and p14 are present (13 profiles, no p12), and `CASE_COVERAGE` says each ran exactly once.
- **Source fingerprints:** the start and end fingerprints are byte-identical. These are working-tree bytes, so the blob manifest is the authoritative check.
- **Audio:** 172/172 production clips and 8/8 framing clips pass SHA-1; 180 files are bundled; R8 changed no audio.
- **Not reproduced:** I inspected the implementer's R7-tree reproduction ("73 tests fail on R7") but did not run it. Many of those tests rely on APIs that only exist in R8.

## 8. Premium and ownership

- **RevenueCat authority is unchanged:** only `active` grants Premium.
- **Restore** no longer claims success when the follow-up check is inactive or unavailable.
- **Insight 4's historical Keep:**
  - still works after a lapse;
  - is owned only once its save is confirmed;
  - is applied only once its Keep has landed.
- **Duplicate Keeps and the 8-Circle limit** hold under concurrent taps: `_keeping` is counted in the limit, and the change runs serialized under `_commit`.
- **Gating:** I3, Plan actions, "Not now" and generating Insights stay Premium.
- **Carry-over and lapse:** a Premium Circle carried over after a lapse is the continuation of a Circle already started under Premium. It is legitimate, not a new grant.

**No unauthorized access was established.**

## 9. Data integrity and recovery

**Strong:**
- The journal and Kept Circles stores are honest: confirmed before anything is shown, with memory put back on failure.
- Deletion ordering and its retry at startup are sound. Writes still in flight that put data back are cleared by the second pass, because the barrier waits for them.
- The write-ahead record keeps partial-key writes consistent.
- No duplicate History entry or duplicate Plan credit was found; writes are upserts keyed by Circle id, guarded by provenance.

**Weak:**
- Plans and Insights keep unsaved changes only in memory. This is the cause of AUD-1 and AUD-6.
- Damaged-data handling is not applied the same way in every store (AUD-3, AUD-4).

## 10. 31-dimension scorecard (d89a035 framework: 0–10, certainty, no overall average)

**How to read this comparison:**
- d89a035 is an earlier product version (Paths/Toolkit).
- There are no R7 numerical scores to compare against.
- I rescored only the dimensions R8 affects. The other 26 are **not reassessed**.

| # | Dimension | d89a035 | Post-R8 | What changed |
|---|---|---|---|---|
| 11 | Trust | 7 (MEDIUM) | 7 (MEDIUM) | **Up:** honest save failures, durable ownership, safe Delete. **Down:** AUD-1 and AUD-6, where memory can be ahead of disk. |
| 12 | Accessibility / robustness | 7 (LOW) | 7 (MEDIUM) | **Certainty raised:** the suite and fault injection were reproduced independently. **Score held back by:** no device QA, and AUD-2. |
| 19 | Routine ownership value | 9 (HIGH) | 9 (HIGH) | Historical Keep after a lapse is confirmed and durable. |
| 29 | Pre-release readiness | 7 (MEDIUM) | 7 (MEDIUM) | The baseline is close; one MEDIUM condition remains, and the commercial gates are still open. |
| 30 | Overall product quality | 7 (MEDIUM) | 7 (MEDIUM) | Coherent, and well tested on its happy paths; no runtime certification. |

## 11. Engineering score — NEW, NOT HISTORICALLY COMPARABLE

This rubric was defined before scoring. It has no historical baseline.

| Area | Weight | Score | Reason |
|---|---|---|---|
| Persistence correctness and honesty | 30 | 25 | AUD-1, AUD-6 |
| Recovery and deletion | 20 | 19 | — |
| Entitlement security and ownership | 15 | 14 | — |
| Test and evidence integrity | 15 | 14 | Everything reproduces; gaps for AUD-1 to AUD-4 |
| Time and day semantics | 10 | 7 | AUD-2, AUD-5, the foreground 6-hour drop |
| Damaged and future-schema data | 10 | 6 | AUD-3, AUD-4 |
| **Total** | **100** | **85** | |

## 12. Commercial release gates (separate from R8; all still OPEN)

- A2-06: analytics retention, deletion and privacy policy.
- A2-07: device migration, backup and Premium restoration.
- Pre-commercial billing and APK security.
- Six-language localization and native-language QA.
- Complete multilingual audio.
- The final commercial release audit.

THIRTY Phase E stays on **HOLD**. KEYBRACE OS is discontinued.

## 13. What blocks R8 baseline acceptance

1. **AUD-1 (blocking):** make the guarantee depend on a confirmed save. Either `_recordBeforeOverwrite` waits for a confirmed Plans save, or `recordGuided`'s already-credited check uses the durable state. Add a test where the Plans store fails persistently.
2. **AUD-2 (condition):** fix it, so the new day opens once the carried-over Circle is finished. The alternative is for the founder to explicitly narrow the contract to "the next resume".

AUD-3 to AUD-6 are LOW. They can be scheduled before public release, but must not be closed silently. Any fix produces a new SHA, which needs at least a targeted delta re-audit.

**Final verdict: CONDITIONAL PASS.** This is not a commercial release approval.

I can also publish this report as a private page for the founder or the implementer.