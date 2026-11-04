# THIRTY — INDEPENDENT POST-R7 AUDIT

**Verdict: CONDITIONAL PASS.** R1, R2, R3, R4/R4.1, R5, R6c and the copy work hold up in the source and in my own test run. One medium-severity gap means R6's midnight behavior doesn't fully keep its stated guarantee (F-1), and there are five low-severity defects. I found nothing critical or high-severity. The repository was not modified.

## 1. Commit identity

- **Target:** `8ece26f6dbd41f573e854b8fc82f44a6942282e3`. It is the tip of local and `origin/step5-billing-integration`.
- **Parent:** `8bfd42c16693b8f5040ebcf4761db0e9c439981c`, as expected. Author: Thomas Daelman, 2026-11-04 07:27 +0100.
- **What I audited:** a clean copy of the commit extracted with `git archive` into a scratch folder, with LF line endings. I did not use the `step5-billing-integration` worktree, because it has 185 uncommitted entries.
- **Tested tree:** the tree the implementer tested (`33079135…`) differs from the commit only by the R7 evidence folder (24 files) and `THIRTY_V2_DELIVERY_TRACKER.md`. No test reads either of them.
- **Audit inputs:** both audit reports are committed unchanged (sha256 `311c40d0…` and `8bf52ac4…`, LF bytes). A first mismatch I saw was caused by my own line-ending conversion, not by the evidence.
- **File counts** match the handoff exactly:
  - `lib/`: 39 modified, 4 added.
  - tests: 26 modified, 19 added.
  - outside the R7 folder: 97 modified, 73 added, 0 deleted.

## 2. Scope and method

- I read the source of every remediated area: the gateway, entitlement notifier, recommendation provider, deletion, journal, kept store, Insights, Plans credit, the day-rollover listener, voice gating, the Kotlin audio change and the consent copy.
- I compared the source against the handoff's claims and against the A2 findings register.
- I ran the full suite independently, plus five reproduction tests of my own. Those tests are in the scratch copy only, not in the repository.
- Reviewing a single code path closely does not mean the whole file was reviewed (see §9).

## 3. Findings

### F-1 — MEDIUM — A running Circle is dropped when the app is resumed after midnight

Maps to A2-11 and the R6 final midnight behavior. Category **A**: it contradicts a guarantee the handoff makes.

- **Evidence:**
  - `lib/core/app/thirty_app.dart:68`: every resume invalidates `nowProvider`, whatever state the Circle is in.
  - `recommendation_provider.dart:754` rebuilds today from it, and `:916` returns an empty "fresh" state whenever the stored day is not today. That happens even while the stored Circle is `started`.
  - The "never while a Circle is running" protection exists only on the touch path (`_openNewDayIfDue`).
- **Reproduction (P1):**
  1. A Circle is started at 23:40.
  2. The app goes `paused`, then `resumed` at 00:10.
  3. Observed: `status=notStarted`, `circleId=null`. The journal shows the Circle as started and never closed.
- **Impact:**
  - The user cannot Close the Circle or answer its reflection.
  - A Plan-stage Circle is never credited, because the credit only happens on Close.
  - Voice guidance stops.
  - Locking the phone during a voiced Circle is the intended way to use it ("you can put the screen down"), so this is a realistic path.
- **Test gap:** the touch path for a running Circle is tested (`r6b_day_rollover_test.dart:234`). The resume path is tested only with a Circle that was already closed (`thirty_app_test.dart:86`).
- **Note:** this isn't a regression; the resume behavior already existed at `8bfd42c`. But it contradicts the handoff's guarantee that "a Circle started before midnight closes once under its own day."

### F-2 — LOW — A choice made after midnight without a touch is recorded under yesterday

Maps to A2-11.

- **Evidence:** `chooseIntention` (`:1059`, `:1124`) and `useOwnedToday` (`:1541`, `:1578`) take the day and `shownAt` from the cached `nowProvider`. Screen-reader, keyboard or switch activation sends no pointer event, so the cached day is never refreshed.
- **Reproduction (P2):**
  1. The app is open at 23:50 with nothing chosen.
  2. At 00:10, a choice is made without a touch.
  3. Observed: a journal entry with `localDate` `2026-08-01` and `shownAt` `23:50`. The time is false too.
- `start()` then correctly refuses (`:1396`), but yesterday keeps a "shown" record that never happened.
- `shownAt` comes from the cached app-start or resume time even on ordinary days, so it is generally imprecise.

### F-3 — LOW — One damaged shape of the kept-Circle store is written over

Maps to A2-03 / R4.1.

- **Evidence:** `kept_circle.dart:198`. A version-1 wrapper whose `kept` field is missing or not a list is read as a valid, empty store. `kept_circles_provider.dart:87` therefore allows the next write.
- **Reproduction (P3):** with `{"schemaVersion":1,"kept":{"note":"damaged"}}` stored, one Keep replaces it completely. The read reported `unreadable=0` and `isFull=false`.
- The journal's equivalent check (`_classifyStored`) treats this same shape as unreadable, so the two stores are inconsistent.
- **Related:** extra top-level fields in the wrapper are also dropped on write (`:228`).

### F-4 — LOW — The A2-09 date fix does not cover Insight dates

Maps to A2-09.

- **Evidence:**
  - Insight snapshot dates (`generatedOn`, `appliedOn`, `notNowOn`, `declinedOn`, `facts.endedOn`) are accepted as any string (`insight.dart:324`, `:331`).
  - They then reach the unchecked `int.parse` in `insight_engine.dart:189`.
- **Reproduction (P4):** a stored snapshot with `generatedOn: "garbage"` and 20 days of journal history makes `assess()` throw `FormatException`.
- Only the app writes these values, so the likelihood is low.

### F-5 — LOW — After a failed History save, History still shows the Circle in that session

Maps to R6 (visible save failures).

- **Evidence:** `shared_preferences` 2.5.5 updates its in-memory cache before the disk write (`_setValue`). `circle_journal.dart:1200` has no rollback, although the preserved-copy path does have one.
- **Reproduction (P5):** with the disk refusing the journal key:
  - The save status is correctly `{…: false}` and the notice appears.
  - But `readAll()` still returns the entry in memory, while nothing is on disk.
- Within that session, History and Insights show the Circle even though the notice says it wasn't saved. The next successful save writes it to disk, so the notice can become outdated.
- Nothing stored is overwritten, so the copy "existing saved data wasn't overwritten" holds.

### F-6 — LOW — Kept-Circle saves can fail silently

Maps to R6 (visible failures, outside its journal-only scope).

- **Evidence:** `kept_circles_provider.dart:183` swallows write errors, and `write()` ignores the result of `setString`.
- A Keep whose disk write fails looks successful and is lost on restart, with no notice.
- I did not run a reproduction for this; it is from reading the code. The Plans and Insights writes follow the same pattern.

### Recommendations (category C)

- **Journal record versions:** a journal record with a higher per-record `schemaVersion` inside a readable wrapper is accepted. Its unknown fields are dropped on the next save, because `CircleJournalEntry.toJson` only writes the fields this build knows. Kept Circles, by contrast, keep unknown fields.
- **Doc comment:** in `date_key.dart:1–13`, `dateKey`'s doc comment now sits on top of `isCanonicalDateKey`.
- **Duplicate doc:** `close()` has its doc paragraph written twice (`recommendation_provider.dart:1593–1605`).

## 4. Verified remediations (source + tests)

| ID | Result |
|---|---|
| **A2-01 / R1** | ✅ An absent entitlement maps to `inactive`; any lookup or SDK error maps to `unavailable`; only `isActive` grants Premium. The overlapping-refresh handling (J18) is correct: a stale answer returns the newer published state. `premiumEntitlementProvider` is true only for `active`. The QA override is debug-only (`kDebugMode && THIRTY_QA_PREMIUM`). |
| **A2-02 / F1 / R2** | ✅ "Make today's Circle" upgrade is allowed only for an untouched Free choice (`isFreeDecision`), before Start, under verified `active`. A Start after a verified expiry earns no credit; `initializing`/`unavailable` record nothing. Provenance-based credit is correct. Exception: **F-1** can lose the credit. |
| **A2-04 / R3** | ✅ Each day's write is published as one record; the deletion barrier stops writes started earlier. Deletion clears twice, keeps a pending marker and finishes it at start-up. The Plans credit can't land after `forgetStageEvidence`: the credit's state change is synchronous after `_ensureCurrent`, and the writes are ordered. |
| **A2-03 / F2 / R4, R4.1** | ✅ Saved lengths and words are used; unreadable records are kept in place; unknown per-record fields are kept; the store is full while its count is unknown; retired or unsafe parts are never run. Exception: **F-3**. |
| **A2-05 / m2 / R5** | ✅ Only `KeepCircleFromHistory` bypasses the Premium gate. The snapshot must still be current, and the duplicate and 8-slot checks still apply. Generating Insights, "Not now", I3 and Plan actions stay Premium. |
| **D-B / R6 voice** | ✅ A Circle is voiced only if every part's words equal the recorded words. Clips depend on name and instruction only, so saved lengths can't cause a mismatch. |
| **R6c journal** | ✅ A newer-schema journal is refused before any write. An unreadable wrapper is copied aside, and the save goes ahead only once that copy is confirmed on disk. Unreadable entries are written back as stored. No other production code path writes the journal key. Exception: **F-5**. |
| **A2-08** | ✅ The date range now covers every Circle the denominator counts. |
| **A2-09** | ✅ for the journal (canonical date check at the read boundary). Exception: **F-4**. |
| **A2-11** | ⚠️ Touch path ✅; resume path **F-1**; no-touch path **F-2**. |
| **A2-06 copy** | ✅ The copy names exactly the 6 event types sent and their fields (`tester_id`, `occurred_at`/`local_date`, `app_version`, `cohort`, allowlisted metadata). |
| **m5** | ✅ The LF rule is in `.gitattributes`. The manifests are ASCII/LF, and `sha1sum -c` passes. |
| **A2-10, m1/m3/m6, accessibility busy state** | Present and covered by tests; I only checked these superficially. |

## 5. Tests I ran myself

- **Toolchain:** Flutter 3.44.8 / Dart 3.12.2, the same as the reported run.
- **Setup:** `flutter pub get --offline --enforce-lockfile` succeeded, so no dependencies changed.
- **Analyze:** `flutter analyze` reported no issues.
- **Full suite:** `flutter test --concurrency=3` (the default command; nothing excludes the `long` tag):
  - **2,353 passed, 0 failed, 0 skipped, 159 files**, exit code 0.
  - This independently confirms the reported total. My run differs from the implementer's in one way: I ran one process at concurrency 3, not memory-bounded batches.
- **File inventory:** 159 test files on disk, the same set as `batch_plan.json`.
- **Year-long simulations:** all 13 profiles are declared (p01–p11, p13, p14; there is no p12), and their assertions are meaningful.
- **Weakened tests:** none found. The assertions changed in modified tests follow intended behavior changes (R4.1 storage in place, the F02 opening line).
- **Reproduction tests:** 5 written; **all 5 failed, confirming F-1 to F-5.**
- **Audio:** 172/172 and 8/8 SHA-1 OK; 180 files bundled. The 9 modified clips are all `voice_heather_v1`, and each one's previous hash (in the parent commit) is in the pre-correction records.
- **Secrets and personal data:** none found in the diff. The only key-like string is the test fake `goog_r1`.

## 6. Known release gates (category B — not resolved, and not marked as resolved)

- **A2-06:** analytics retention, server-side deletion, privacy policy and Supabase verification.
- **A2-07:** Android backup and device migration, and Premium restore.
- **Pre-commercial billing security:**
  - APK tampering and entitlement bypass. Editing local data on a rooted device could make Insight 4 Keep snapshots or journal sessions, which turns them into free kept Circles.
  - Removing the production QA override.
  - A real Play purchase and lapse.
- **Six languages,** zero hard-coded user-facing text, multilingual voice libraries and native-language QA.
- **Final commercial audits.** Phase E stays on HOLD.

## 7. Limitations / not verified

- No device or emulator run. Not exercised: midnight on a device, a real process restart, a real RevenueCat lapse, audio focus, and the Kotlin `afterCurrent` queue (native code with no Flutter test).
- Not every line of the 39 modified `lib` files was reviewed; UI widgets (`circle_hero`, `kept_circle_page`, `plan_view`) were only partly read. Of the 1,603-line `r3_persistence_delete_test`, I read only selected parts.
- The founder approvals of audio and copy can only be traced through committed records, not independently confirmed.
- Plans-store date validation (`plan_copy.dart:276`) was not checked.

## 8. Verdict

**CONDITIONAL PASS** for the R7 remediation baseline at implementation and test level. This is not commercial release approval.

**Condition:** fix F-1, so that a resume (and ideally a restart) never drops a started Circle of an earlier day, and add a resume test with the Circle running. The alternative is that you explicitly narrow the stated midnight guarantee to "foreground touch only." F-2 to F-6 are low-severity and can be scheduled before public release. Under the tracker's own rule, any fix means a new SHA to re-audit, at least as a targeted delta review.

The probe test file is at `C:\Users\thoma\AppData\Local\Temp\claude\b7fd4c17e92f619e\34f1e4c2-f052-4f9d-a108-5943503bfa63\scratchpad\snap\audit_repro\audit_repro_test.dart` if you want to hand the reproductions to the implementer. I can also publish this report as a private page you can share.