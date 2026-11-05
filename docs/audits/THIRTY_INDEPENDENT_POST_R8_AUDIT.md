# THIRTY — INDEPENDENT POST-R8 AUDIT

**Verdict: FAIL — R8 baseline acceptance is blocked.**  
**Audit period:** 4–5 November 2026; report completed 5 November 2026.  
**Evidence basis:** exact committed source, committed regression evidence, independently executed Git/Python integrity checks and runner challenges. **No Flutter tests were independently executed.**

R8 corrects several material R7 defects. Keep no longer confirms ownership before its save succeeds; Boolean storage refusals are checked on the remediated paths; deletion intent precedes its barrier and removals; missing Start evidence can be reconstructed; and the evidence package is substantially more auditable. These improvements do not establish baseline acceptance. This audit identifies **3 HIGH, 6 MEDIUM and 1 LOW finding groups**, including loss of Plan credit, restoration of a removed answer, and unsafe handling of delayed recovery copies.

No CRITICAL finding was established. “New finding” means newly identified in this audit. It does **not** assert that every defect was first introduced by R8.

## 1. Verified immutable target

| Item | Verified value |
|---|---|
| Repository | thirtyapp/Thirty |
| Requested branch | step5-billing-integration |
| Target commit | `58b179c99866e234acd63e4e241590af36b9b186` |
| Actual parent | `8ece26f6dbd41f573e854b8fc82f44a6942282e3` — matches the expected parent |
| Tree | `cd6c6bd59c054e4023d0947ad618806562d877c8` |
| Checkout | Detached, non-shallow, clean; exact target fetched and checked out |
| Git object validation | `git fsck --full --strict` succeeded |
| Required handoff | [artifacts/r8_post_audit_remediation_2026-11-04/AUDIT_HANDOFF.md](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/artifacts/r8_post_audit_remediation_2026-11-04/AUDIT_HANDOFF.md) — read |
| Original post-R7 reports | [Astra post-R7 report](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/docs/audits/THIRTY_ASTRA_POST_R7_AUDIT_SHARED_REPORT.md) and [Claude post-R7 report](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/docs/audits/THIRTY_CLAUDE_POST_R7_AUDIT_REPORT.md) — both read from the target |
| Historical scorecard | [docs/audits/THIRTY_POST_V2_INDEPENDENT_AUDIT_GPT6_ASTRA_d89a035.md](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/docs/audits/THIRTY_POST_V2_INDEPENDENT_AUDIT_GPT6_ASTRA_d89a035.md) — exact dimensions and historical values used |

The branch resolved to the requested commit when checked. Findings are anchored to the immutable SHA, not to subsequent branch movement.

The audited repository was not changed. Temporary verification scripts, altered evidence copies and this new report were created outside it. No source, test, contract or existing audit report was edited; no staging, commit, push, merge or deployment was performed.

## 2. Methodology and limitations

The review traced the R8 changes and neighboring production paths through Today's choice/Start/Close/reflection, journal restoration, Kept Circles, I4, Plans, Insights, deletion and startup recovery. Original findings were checked against production code and regression assertions, rather than closed from the ISSUE_REGISTER.

The fault model included `false`, exceptions, partial key writes, cache-before-disk behavior, marker creation/cleanup failure, repeated restart, damaged/future records and delayed/concurrent operations. Reproduction recipes below specify the expected source-derived failure; they are **not represented as executed Flutter reproductions**.

**Independently executed:** Git identity/object checks; manifest/blob comparison; file fingerprint reconciliation; raw JSONL parsing and summary comparison; inventory/profile reconciliation; audio hashes; committed Python runner report/case commands in a disposable copy, including failure mutations; a Python timezone illustration of timestamp information loss.

**Inspected, not rerun:** all 2,484 reported Flutter test results, relevant Dart assertions and fault harnesses, the R7 reproduction logs, implementation/handoff documents and simulation evidence.

**Unavailable:** no Flutter or Dart executable was installed in this environment. No independent Flutter suite, analyzer, device, Play purchase/restore, RevenueCat service, native audio-focus, accessibility, backup/migration or multilingual QA run was possible. No APK tampering assessment was performed. Static review cannot guarantee exhaustive absence of other defects.

The manifest proves equality between committed blobs and the submitted tested-source manifest. It does not independently attest that the implementer's machine executed those bytes: that linkage still depends on the submitted logs and capture process.

Source abbreviations used below resolve to exact paths in §14; every line link points to the target commit.

## 3. Closure matrix — every original finding

“Fixed” applies to the original defect and its stated reproduction, not to all neighboring failure modes. Tests in this table were inspected, not independently executed.

| Original ID / severity | Root cause and affected production source | Actual R8 implementation and meaningful regression coverage | Disposition / remaining failure |
|---|---|---|---|
| **Astra R7-A01 — HIGH** | Daily publication ignored Boolean failures and the queue swallowed exceptions before History's failure reporting. `lib/features/home/application/recommendation_provider.dart`; shared write helper. | [Today:803–850](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/recommendation_provider.dart#L803-L850) confirms the WAL and each key; failure marks the Circle unsaved. [Confirmed:32–55](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/core/storage/confirmed_write.dart#L32-L55) rejects false/throw and attempts cache rollback. Daily-persistence and precommit tests assert failed Start/Close publication, marker failure, disk state and restart. | **Fixed for the original publication/reporting defect.** End-to-end reliability is still blocked by N01/N04 and N10's notice scheduling gap. |
| **Astra R7-A02 — HIGH; Claude F-3 — LOW** | Present non-list `kept` decoded as an empty readable store; wrapper fields were discarded. `lib/features/personal_circle/domain/kept_circle.dart`. | [KeptModel:208–230](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/personal_circle/domain/kept_circle.dart#L208-L230) rejects malformed present `kept`; repository refuses overwrite. Unknown wrapper fields are retained. Tests cover object/string/number/null/bool, unchanged bytes across restarts, mixed readable/unreadable records and extra fields. | **Fixed.** Missing `kept` is deliberately accepted for the legacy Phase D shape, with unknown fields retained; this is distinct from a present damaged list. Analogous Plans/Insights loss remains N07. |
| **Astra R7-A03 — HIGH; Claude F-6 — LOW** | Keep returned success and published ownership before storage; I4 could persist “applied” without a kept Circle. F-6 also noted similar Plans/Insights writes. `lib/features/personal_circle/application/kept_circles_provider.dart`, `lib/features/insights/application/insights_provider.dart`, `lib/features/plans/application/circle_plans_provider.dart`. | [Kept:243–261](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/personal_circle/application/kept_circles_provider.dart#L243-L261) serializes commits, awaits confirmed persistence and then updates state. [Insights:221–237](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/insights/application/insights_provider.dart#L221-L237) awaits I4 Keep. Tests assert false/throw, inactive/active entitlement, restart, duplicate Keep and two concurrent Keeps with one place remaining. | **A03 fixed; F-6 fixed for Kept Circles, partially fixed across its broader Plans/Insights observation.** Plans/Insights report failures but still publish optimistic state; N01/N02/N05 remain. N10 leaves stale Kept failure bookkeeping. |
| **Astra R7-A04 — HIGH** | Delete started clearing before intent was durable and ignored false removals. `lib/features/home/application/circle_history_deletion.dart`. | [Delete:151–193](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/circle_history_deletion.dart#L151-L193) confirms intent, then starts the epoch barrier/removals, waits tracked work, clears again and removes intent last. Tests exercise false/throw, retries, restart, failed marker creation/cleanup and queued Today writes. | **Partially fixed end to end.** Original ordering/Boolean reproductions are fixed. Untracked Plans/Insights preservation writes can outlive successful deletion: N02. |
| **Astra R7-A05 — MEDIUM** | Closed-state recovery detected missing Start but only restored Close. `lib/features/home/application/circle_journal.dart` and Today provider. | [Journal:872–919](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/circle_journal.dart#L872-L919) accepts the actual original Start; [Today:2282–2293](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/recommendation_provider.dart#L2282-L2293) passes it. Tests assert original Start, Close and one journal record after same-session recovery and restart. | **Fixed.** This is reconstruction from stored evidence, not invention of an activity or Close. |
| **Astra R7-A06 — MEDIUM** | Copy/Delete enablement only counted readable History. `lib/features/settings/presentation/widgets/you_data_card.dart`, `lib/features/home/presentation/widgets/journal_data_controls.dart`. | [Journal:713–717](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/circle_journal.dart#L713-L717) counts unopened raw, preserved and individually unreadable History. Both controls use it. Widget assertions cover damaged/future wrappers, preserved-only data and unreadable records; Copy exports and Delete acts after confirmation. | **Fixed for the original unreadable-History control defect.** This does not establish completeness of every other store's export/backup. |
| **Astra R7-A07 — MEDIUM** | Damaged saved wording became null, triggering current catalogue wording and voice compatibility. `lib/features/personal_circle/domain/kept_circle.dart`, `composed_session.dart`, `circle_elements.dart`. | [KeptModel:118–125](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/personal_circle/domain/kept_circle.dart#L118-L125) rejects a present malformed saved-wording field. Tests retain raw malformed Kept records, prevent executable ownership and permit genuinely legacy absent wording. | **Partially fixed.** The Kept-record entry point is fixed; the saved Today composed-session decoder still allows the same fallback, N06. |
| **Astra R7-A08 — MEDIUM; Claude F-1 — MEDIUM** | Resume changed the day and discarded a running previous-day Circle. `lib/core/app/thirty_app.dart`, Today provider. | [Today:562–571](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/recommendation_provider.dart#L562-L571) and [Today:902–924](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/recommendation_provider.dart#L902-L924) carry yesterday's running session, or its post-midnight open reflection, for up to six hours. Widget/unit assertions cover resume/restart, own-day attribution, boundary, abandonment and single Plan credit. | **Partially fixed against the full R8 time contract.** Original 23:58→00:01 reproduction is fixed. Offset-free persisted timestamps fail the ambiguous DST case, N09. Notification-shade expiry remains a disclosed behavioral limitation (§6). |
| **Claude F-2 — LOW** | Choice day and shown time came from cached `nowProvider`, including no-touch activation. Today provider and Plan provider. | [Today:1218–1225](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/recommendation_provider.dart#L1218-L1225) / [Today:1301–1305](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/recommendation_provider.dart#L1301-L1305) and `useOwnedToday` use event time for the Circle and shownAt. Tests assert no-touch choice and ordinary-day event time. | **Partially fixed end to end.** The direct Circle/History reproduction is fixed; Plan served-stage identity still uses cached day, N08. |
| **Claude F-4 — LOW** | Arbitrary Insight date strings reached unchecked parsing. `lib/features/insights/domain/insight.dart`. | Canonical validation at [InsightModel:321–350](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/insights/domain/insight.dart#L321-L350) covers generatedOn, appliedOn, notNowOn, declinedOn and facts.endedOn. Rejected snapshots remain raw unreadable entries. Tests exercise each invalid field with active/inactive entitlement. | **Fixed for the original date failure.** Wrapper decoding remains N07, a separate defect. |
| **Claude F-5 — LOW** | Failed History saves left the SharedPreferences cache ahead of disk. `lib/features/home/application/circle_journal.dart`. | [Journal:1229–1253](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/circle_journal.dart#L1229-L1253) uses confirmed writes with rollback; tests compare journal reads, learning history and underlying disk after false/throw. | **Fixed after the failed operation settles in the tested path.** The helper is not read isolation: pending cache values still require care, as N02 demonstrates elsewhere. |

### Additional original report items

- **Astra's separate MEDIUM restore-confirmation defect:** fixed at [Premium:98–108](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/core/premium/premium_access.dart#L98-L108). “Restored” requires active entitlement after refresh; inactive/unavailable return unavailable. The inspected restore-wording tests cover the three follow-up outcomes. This does not close A2-07's real-device restoration gate.
- **Astra's LOW evidence recommendation:** substantially addressed. Raw logs, source manifest and `done.success` are retained; report/case commands reject the independently injected discrepancies (§8).
- **Claude's future per-record journal recommendation:** addressed. A future record schema inside a current wrapper is retained as unreadable raw data rather than decoded and reserialized destructively; both preservation and export assertions were inspected.
- **Claude's duplicated/misplaced comments:** corrected; no functional closure is inferred from comments alone.

### Principal regression assertions inspected

[test/features/home/r8_a01_daily_persistence_test.dart:56](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/test/features/home/r8_a01_daily_persistence_test.dart#L56); [test/features/home/r8b_precommit_persistence_test.dart:114](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/test/features/home/r8b_precommit_persistence_test.dart#L114); [test/features/home/r8_a04_delete_durability_test.dart:77](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/test/features/home/r8_a04_delete_durability_test.dart#L77); [test/features/home/r8_a06_unreadable_history_controls_test.dart](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/test/features/home/r8_a06_unreadable_history_controls_test.dart); [test/features/personal_circle/r8_kept_ownership_persistence_test.dart:118](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/test/features/personal_circle/r8_kept_ownership_persistence_test.dart#L118); [test/core/app/r8_midnight_resume_test.dart:97](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/test/core/app/r8_midnight_resume_test.dart#L97); [test/features/insights/r8_f4_insight_dates_test.dart:96](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/test/features/insights/r8_f4_insight_dates_test.dart#L96); [test/features/home/r8_journal_forward_records_test.dart:36](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/test/features/home/r8_journal_forward_records_test.dart#L36); [test/core/premium/r8_restore_wording_test.dart:51](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/test/core/premium/r8_restore_wording_test.dart#L51).

These assertions meaningfully cover many original reproductions. The missing sequences below explain why their passing evidence is insufficient.

## 4. New findings, ranked

All findings below are established by source tracing. The reproduction steps are instructions for a Flutter fault-harness or device follow-up; none is claimed to have been independently run in Flutter here.

### N01 — HIGH — Failed Plan credit is treated as durable and its recovery source can be overwritten

**Evidence:** [Plans:92–116](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/plans/application/circle_plans_provider.dart#L92-L116), [Plans:291–309](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/plans/application/circle_plans_provider.dart#L291-L309), [PlanModel:707–721](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/plans/domain/circle_plan.dart#L707-L721), [Today:858–891](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/recommendation_provider.dart#L858-L891), [Today:1022–1042](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/recommendation_provider.dart#L1022-L1042).

Plans updates provider state before saving. When that save fails, the credited record and advanced cursor remain in memory. A subsequent `recordGuided` sees the duplicate and returns an already-completed Future instead of retrying the unsaved whole record. The new before-overwrite guard awaits that no-op and is allowed to replace the previous day's persisted Circle. Restoration likewise checks credited provider memory, not confirmed durable Plan state.

**Reproduce:**

1. Durably serve and Start a Premium Plan-stage Circle on day D.
2. Make only `circlePlansKey` fail on the credit write at Close; allow the daily Close and History writes. Wait for the failure.
3. Make entitlement inactive before choosing the next day, so composition does not incidentally write the optimistic Plan state. Advance to D+1 and choose a Free Circle.
4. The previous day's duplicate credit attempt returns without saving. Its day keys are replaced.
5. Restart from actual disk with storage working. The Plan lacks the guided credit; the only daily recovery slot now holds D+1. History still contains the old Close, but this code does not rebuild all missing Plan credits by scanning History.

**Impact:** lost Plan progress and a false premise in the new durable-before-overwrite protection. The issue is not duplicate credit; it is loss of an unsaved credit after the duplicate guard mistakes memory for disk.

**Test gap:** the persistent-History test at [test/features/home/r8b_precommit_persistence_test.dart:208](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/test/features/home/r8b_precommit_persistence_test.dart#L208) exercises History refusal, not a failed Plan credit followed by rollover without another Plan save. Plan failure tests only assert unsaved reporting/state.

**Acceptance:** blocks R8 baseline acceptance.

### N02 — HIGH — Untracked preservation writes can lose unreadable data or survive successful deletion

**Evidence:** [Plans:63–78](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/plans/application/circle_plans_provider.dart#L63-L78), [Plans:123–137](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/plans/application/circle_plans_provider.dart#L123-L137), [Plans:320–344](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/plans/application/circle_plans_provider.dart#L320-L344); equivalent Insights paths [Insights:66–82](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/insights/application/insights_provider.dart#L66-L82), [Insights:124–138](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/insights/application/insights_provider.dart#L124-L138), [Insights:352–370](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/insights/application/insights_provider.dart#L352-L370); [Delete:151–193](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/circle_history_deletion.dart#L151-L193); [Confirmed:32–55](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/core/storage/confirmed_write.dart#L32-L55).

Plans and Insights launch unreadable-store side copies from `build()` with `.ignore()`. Those writes are outside their `_writes` queue and the History gate. SharedPreferences exposes a pending value in its cache before the platform write completes. `_protectStored` accepts `aside == text` as confirmation, although it may only be that pending cached value.

**Reproduction A — permanent loss of the preserved bytes:**

1. Seed an unreadable Plans or Insights string, with no unreadable-side-copy key.
2. Read the provider and hold the platform Future for creation of the side copy. Allow its cache update.
3. Immediately start a Plan, or assess an eligible new Insight. Let the main-store write succeed.
4. The guard sees matching cached side-copy text and permits the overwrite without waiting for its durability.
5. Release the original side-copy Future as `false` or an exception, with no disk copy written; allow rollback removal to complete.
6. Restart. The main raw record was replaced and no preserved copy exists.

**Reproduction B — deleted raw evidence returns on disk:**

1. Hold that build-triggered side-copy write before its disk mutation.
2. Run Delete Circle History. Allow intent, the side-copy removal, the tracked queues, both clear passes and intent cleanup to succeed.
3. After Delete resolves, allow the delayed original side-copy write to reach disk.
4. Raw Plan-stage/Insight history now exists again without a pending deletion marker.

This second scenario requires a backend/test double that allows the delayed write to land after a later removal; there is no app-level ordering that prevents it. It is an adversarial asynchronous-store result, not a claim of observed ordering on a particular Android device. The returned data is **raw retained disk evidence**; the finding does not claim that this side-copy key is automatically rendered as ordinary History.

**Test gap:** preservation tests at [test/features/personal_circle/r8_kept_ownership_persistence_test.dart:411](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/test/features/personal_circle/r8_kept_ownership_persistence_test.dart#L411) explicitly settle the build-triggered copy before the next action. Delete tests track Today/domain queued writes, not this untracked build Future.

**Acceptance:** blocks R8 baseline acceptance; original A04 cannot be closed end to end.

### N03 — HIGH — A successfully removed historical answer is restored by daily recovery

**Evidence:** [Today:1881–1905](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/recommendation_provider.dart#L1881-L1905), [Today:881–891](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/recommendation_provider.dart#L881-L891), [Today:902–924](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/recommendation_provider.dart#L902-L924), [Today:981–1042](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/recommendation_provider.dart#L981-L1042), [Today:2309–2332](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/recommendation_provider.dart#L2309-L2332). User-facing actions: [RecordUI:75–101](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/presentation/circle_record_detail_page.dart#L75-L101) and [MemoryUI:654–670](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/presentation/memory_page.dart#L654-L670).

Removing an answer updates daily state/keys only if the current recommendation has that Circle ID. On a fresh next day with no choice, yesterday's completed Circle still occupies the daily recovery keys but is no longer the current recommendation. Removing its answer changes only History. Subsequent recovery regards the old non-null answer in those keys as authoritative and writes it back.

**Reproduce without any storage failure:**

1. On D, Start, Close before midnight, and save the attempt/usefulness answers.
2. On D+1, open the fresh day without choosing a Circle. The old daily keys remain.
3. From History or Memory, remove D's usefulness answer, or both answers. Wait for the journal removal to succeed and verify the answer is absent on disk.
4. Restart, or choose D+1's Circle so `_recordBeforeOverwrite` runs.
5. The old answer is written back into History from D's recovery keys and can influence future recommendations again.

**Impact:** explicit removal is undone, including the UI promise that THIRTY stops using the answer. This is a normal-storage path.

**Related interruption weakness:** a same-day removal writes nulls into daily keys before the separate journal removal; recovery's one-way null checks do not express an explicit deletion tombstone. This is another reason that “missing” and “removed” must not be treated as equivalent recovery evidence.

**Test gap:** no inspected regression combines next-day empty state, removal of the last stored day's answer and a subsequent restore/overwrite.

**Acceptance:** blocks R8 baseline acceptance.

### N04 — MEDIUM — A failed expiry-at-Start write can be bypassed by a later lifecycle write

**Evidence:** [Today:1556–1601](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/recommendation_provider.dart#L1556-L1601), [Today:1788–1809](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/recommendation_provider.dart#L1788-L1809), [Today:2212–2252](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/recommendation_provider.dart#L2212-L2252), [Plans:252–272](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/plans/application/circle_plans_provider.dart#L252-L272), [Plans:291–309](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/plans/application/circle_plans_provider.dart#L291-L309), [PlanModel:783–816](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/plans/domain/circle_plan.dart#L783-L816).

Start correctly waits for `noteStart` before its own persistence, but already publishes a started UI state. If the Plan write fails, Close/pause and other lifecycle persistence do not retain that failed prerequisite. They can save a started/closed Circle without the durable `startedAfterExpiry` evidence.

**Reproduce:**

1. Persist a stage Circle served under active Premium.
2. Switch entitlement to verified inactive; fail the Plan write that records Start after expiry.
3. Call Start; wait for the reported failure. Continue to Close; permit daily and journal writes.
4. In memory, the unsaved expiry flag denies credit. Restart from disk, where the old served record still has the default false expiry flag.
5. Recovery now treats that Close as creditable served ownership and records Plan progress despite the verified inactive Start.

**Impact:** bounded unauthorized Plan progression and inconsistent provenance. This does not turn RevenueCat entitlement active or unlock all Premium features.

**Test gap:** [test/features/home/r8b_precommit_persistence_test.dart:319](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/test/features/home/r8b_precommit_persistence_test.dart#L319) stops after failed Start and reopens. It never Close/pause-persists the optimistic started state first.

**Acceptance:** blocks baseline acceptance because the claimed Start/provenance invariant does not hold across subsequent actions.

### N05 — MEDIUM — I1/I2/I3 can persist “applied” while their actual change is not durable

**Evidence:** [Insights:207–278](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/insights/application/insights_provider.dart#L207-L278), [Plans:147–178](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/plans/application/circle_plans_provider.dart#L147-L178), [Plans:92–116](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/plans/application/circle_plans_provider.dart#L92-L116), [Prefs:194–203](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/suggestion_preferences.dart#L194-L203), [Prefs:252–264](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/suggestion_preferences.dart#L252-L264).

Only I4 awaits the ownership action. Plan-direction/gentler actions return synchronously while their save runs, and LeaveOut is explicitly unawaited. Insights then independently saves `appliedOn`. Suggestion-preference writes additionally ignore Boolean refusal.

**Reproduce:**

1. Persist a current I1, I2 or I3 snapshot under active Premium.
2. For I1/I2, refuse the Plan-store action but allow the Insight-store save. For I3, return false for `suggestionPreferencesKey` while allowing Insights.
3. Apply and let the queues settle; restart from actual disk.
4. The snapshot remains applied, while the Plan change or excluded element is absent. The applied marker prevents the normal apply retry. The I3 false-result path need not issue a save-failure notice.

**Impact:** false action confirmation, cross-store inconsistency and loss of the intended change. Durable Keep ordering fixes I4's original ownership defect but does not make the general Insight application protocol durable.

**Test gap:** inspected I4 tests have meaningful two-store assertions; there is no equivalent refused target-store / successful applied-marker test for these other actions.

**Acceptance:** blocks baseline acceptance; part of the unresolved broader F-6 observation.

### N06 — MEDIUM — Damaged saved Today wording still falls back to current content and voice

**Evidence:** [Composed:191–216](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/personal_circle/domain/composed_session.dart#L191-L216), [Composed:135–160](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/personal_circle/domain/composed_session.dart#L135-L160), [Words:1007–1015](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/personal_circle/domain/circle_elements.dart#L1007-L1015), [Today:1995–2071](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/recommendation_provider.dart#L1995-L2071).

The Kept decoder now rejects malformed saved wording, but the composed-session decoder used to restore Today's saved choice still passes the wording parser's null result through. Execution then substitutes current wording and can return `voiced == true`.

**Reproduce:**

1. Use a valid Kept Circle with saved wording as Today's Circle, so the composed session is stored.
2. Damage one item, or the length/type, of the `wording` field in the saved `recommendationComposedKey` value; retain valid parts and keptCircleId. The original Kept collection can remain intact.
3. Restart on the same day with Premium and bundled audio available.
4. The restored composed session remains executable with null saved wording, displays current catalogue text and can enable current audio.

**Impact:** historical wording is silently substituted in a running/restored owned Circle. Audio hash equality does not prevent this selection/decoder error.

**Test gap:** malformed-wording tests target Kept collection decoding, not the already-chosen Today session JSON.

**Acceptance:** blocks baseline acceptance; A07 remains partially fixed.

### N07 — MEDIUM — Neighboring Plans/Insights decoders still discard damaged or unknown data on a successful write

**Evidence:** [InsightModel:408–432](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/insights/domain/insight.dart#L408-L432), [Insights:124–138](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/insights/application/insights_provider.dart#L124-L138), [PlanModel:357–388](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/plans/domain/circle_plan.dart#L357-L388), [PlanModel:443–462](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/plans/domain/circle_plan.dart#L443-L462), [PlanModel:539–557](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/plans/domain/circle_plan.dart#L539-L557), [Plans:123–137](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/plans/application/circle_plans_provider.dart#L123-L137).

A current-schema Insights wrapper with a present non-list `snapshots` value becomes readable empty state. Its overwrite guard therefore skips preservation. Plans similarly drops unrecognized Plan entries and malformed nested cycles/records while treating the resulting wrapper as readable.

**Reproduce A:** seed Insights with `{"schemaVersion":1,"snapshots":{"recoverable":"original payload"}}`, plus journal evidence that produces an Insight. Assess under Premium and let all writes succeed. The new normal wrapper replaces the original bytes without an unreadable side copy.

**Reproduce B:** take a valid Plans wrapper and add an unknown Plan entry, or a damaged record alongside a readable cycle. Perform a valid Plan mutation that writes the whole store. The filtered data is absent from the new JSON and was never preserved by the whole-store readability guard.

**Impact:** silent loss of recoverable information, even with healthy storage. Future **wrapper** versions and unknown/damaged **records inside a readable wrapper** must be distinguished; a correct whole-wrapper fallback does not cover the latter.

**Test gap:** R8 covers malformed Kept wrappers, malformed whole Plans/Insights strings, Insight dates and future journal entries. These neighboring readable-wrapper shapes are not covered by those assertions.

**Acceptance:** blocks baseline acceptance under the requested damaged/future-record integrity scope.

### N08 — MEDIUM — No-touch midnight choice still dates Plan served ownership under yesterday

**Evidence:** [Today:1218–1254](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/recommendation_provider.dart#L1218-L1254), [Today:1301–1305](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/recommendation_provider.dart#L1301-L1305), [Plans:81–82](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/plans/application/circle_plans_provider.dart#L81-L82), [Plans:191–215](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/plans/application/circle_plans_provider.dart#L191-L215), [Plans:252–272](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/plans/application/circle_plans_provider.dart#L252-L272), [PlanModel:794–805](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/plans/domain/circle_plan.dart#L794-L805).

The corrected Circle choice uses real event time. `steerToday` composes using that context but stores served provenance with `_today`, which still reads cached `nowProvider`.

**Reproduce:**

1. Have an active Plan and active Premium; leave a no-choice screen foregrounded from D at 23:50.
2. At D+1 00:10, activate a choice without a pointer event, retaining cached day D.
3. The Circle ID is D+1, but its served-stage circleId is D.
4. Start under active Premium; then lapse before Close.
5. `noteStart` and `creditsServed` cannot match the Circle identity. The legitimately served/started Circle loses the credit that should survive lapse.

**Impact:** incorrect ownership provenance and lost authorized Plan progress. Free Circle date tests do not establish correctness of the Premium Plan path.

**Test gap:** [test/core/app/r8_midnight_resume_test.dart:259](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/test/core/app/r8_midnight_resume_test.dart#L259) checks choice/History timestamps without this Plan and entitlement-transition combination.

**Acceptance:** blocks baseline acceptance; F-2 is only partially closed across all dependent stores.

### N09 — MEDIUM — Offset-free local timestamps cannot enforce real six-hour carry-over after an ambiguous DST Close

**Evidence:** [Today:562–571](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/recommendation_provider.dart#L562-L571), [Today:1090–1105](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/recommendation_provider.dart#L1090-L1105), [Today:1136–1151](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/recommendation_provider.dart#L1136-L1151), [Today:2221–2237](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/recommendation_provider.dart#L2221-L2237).

`DateTime.difference` is appropriate while the original instants are retained. Persistence serializes local Start/Close/pause using `toIso8601String()` without normalizing to UTC or storing the offset. At an autumn clock rollback, two different instants have the same serialized local time. Restoration cannot reconstruct both correctly.

**Concrete reproduction pair — Europe/Brussels, 25 October 2026:**

- Start on 24 October, Close after midnight at the **first** 02:30 (+02:00), leave reflection open, restart at 08:00 (+01:00): actual elapsed **6h30**, so it must expire.
- Repeat with Close at the **second** 02:30 (+01:00), same restart time: actual elapsed **5h30**, so it must carry over.
- Both local Close values serialize to the same offset-free 02:30 string. The decoder must produce the same result for both, so at least one violates the real-elapsed-time contract.

The two elapsed values were independently checked with Python's timezone database as an information-loss illustration. **This was not a Dart timezone test.**

**Test gap:** [test/features/home/r8b_precommit_persistence_test.dart:594](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/test/features/home/r8b_precommit_persistence_test.dart#L594) uses an unambiguous 23:30 Start and adapts its expectation if the machine has no DST transition. It neither requires a DST timezone nor distinguishes both occurrences of an ambiguous saved Close.

**Acceptance:** blocks the explicit R8 real-elapsed-time acceptance requirement.

### N10 — LOW — Failure notices can be missed and Kept unsaved status can remain stale

**Evidence:** [Notice:74–111](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/presentation/widgets/journal_save_failure_notice.dart#L74-L111), [Kept:243–261](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/personal_circle/application/kept_circles_provider.dart#L243-L261), [Failures:18–32](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/core/storage/store_save_failures.dart#L18-L32).

Two distinct reporting weaknesses remain:

1. While one notice is open, a later provider failure is ignored because `_showing` is true. Dialog completion only resets the Boolean; it does not recheck outstanding failures. Reproduce with a History failure notice, then a pending Plan/Insights failure while that dialog is displayed; dismiss and make no further state change. The later failure can remain untold.
2. Kept `_commit` records failure but never calls `saved(UserStore.keptCircles)` after a successful retry. Reproduce failed Keep followed by successful Keep/rename: ownership can be durable while the shared unsaved set still contains Kept Circles.

**Impact:** unreliable failure/status presentation. The first case does not require the user to press through a modal: a previously queued asynchronous operation can fail while it is open.

**Test gap:** Keep retry tests validate records/counts, not clearing the failure state; copy tests do not cover pending notices across stores.

**Acceptance:** nonblocking LOW issue on its own; it must remain open and must not be cited as proof that every failure is visibly reported.

## 5. Adversarial persistence and recovery assessment

| Challenge | Supported behavior at this SHA | Residual risk / result |
|---|---|---|
| Store returns false | Confirmed helper rejects it on remediated daily, journal, Kept, Plan/Insight and Delete paths. | Suggestion preferences still ignore false; N05. A checked failure does not make optimistic Plan state durable; N01/N04. |
| Store throws | The helper rejects and attempts rollback; relevant regression assertions cover throws. | Cross-store prerequisites and deferred notice delivery remain incomplete. |
| Only some keys succeed | Daily WAL retains the intended publication until key writes complete; Delete retains intent on incomplete work. | This is not a transaction across Today, journal, Plans and Insights. N01/N04/N05 remain. |
| Cache changes before disk | Settled failed History writes are rolled back in the checked path. | Pending cache is still read as durable by preservation guards, N02. Rollback itself is best effort and its failure is swallowed by the helper. |
| Recovery-marker creation fails | Daily publication stops; Delete retries intent once and refuses before its barrier/removals if both attempts fail. | No preservation guarantee can be inferred from a cached marker before its Future resolves. |
| Recovery-marker cleanup fails | Daily publication can leave a replayable pending record. Delete reports failure and retains/reasserts intent for retry. | Tracked ordering is materially improved; untracked side-copy work can still outlive Delete, N02. |
| History fails across restarts | The before-overwrite guard retains the previous started/closed daily evidence and refuses a newer durable choice until journal persistence succeeds. | Supported for the covered journal path. Failed Plan credit is mistakenly considered complete, N01; removed-answer semantics are not safe, N03. |
| Damaged/future records | Kept malformed wrapper guard, future/unreadable journal preservation and canonical Insight dates are improved. | Today wording and readable Plans/Insights wrapper filtering still lose semantics/raw data, N06/N07. |
| Concurrent/delayed operations | Today and Kept queues plus deletion epochs protect many repeated actions; Kept reserves pending places. | Not all writers participate in those queues; N02. Async Insight target/marker sequencing is incomplete, N05. |

**Outcome risks established:**

- **False success:** I1/I2/I3 applied marker despite failed target change (N05); deferred failure notice gaps (N10).
- **Silent/raw data loss:** unreadable copy race and decoder filtering (N02/N07).
- **Deleted data returning:** a removed answer reappears in ordinary History (N03); delayed raw preservation residue can return on disk (N02).
- **Lost/incorrect Plan credit:** N01, N04 and N08.
- **Content/voice mismatch with saved ownership:** N06.
- **UI/provider/disk divergence:** optimistic Plans/Insights and lifecycle state are material to N01/N04/N05.

**No new duplicate History entry or duplicate Plan-credit counterexample was established in the inspected ordinary retry paths.** The journal upserts by Circle ID and Plan records reject duplicate circle IDs. That bounded result is not a concurrency certification and does not cure lost or improperly authorized credit.

For an interrupted daily publication, the WAL provides recoverable intent when its creation succeeded. For an interrupted deletion, the durable marker normally causes startup completion before regular use. Recovery is nevertheless not globally safe while the untracked writers and divergent authoritative copies above remain.

## 6. Six-hour Circle carry-over assessment

| Requirement | Finding |
|---|---|
| Exact six-hour boundary | Source uses `<=`; inspected tests cover 5h59, 6h00 and 6h01 for relevant restore states. Exactly six hours remains eligible. |
| Real elapsed time | In-memory differences are appropriate; persisted ambiguous local times are not, N09. |
| Resume and restart | Yesterday's started Circle can return inside the limit, as can a post-midnight Close with unfinished reflection. Original midnight failure is repaired for that case. |
| Foreground behavior | Touch-driven day opening protects an active Circle/open reflection. It is not a continuously enforced six-hour timeout. |
| Abandoned sessions | Sessions beyond the carry-over rule, and those more than one local day old, are not reopened as running. Unstarted old offers do not carry. |
| Date attribution | Restored Circle, journal writes and normal Plan credit use the Circle's own day. New no-touch Plan served provenance remains N08. |
| Close/reflection fabrication | No automatic invented Close or positive reflection was found in this path; abandoning/expiry can leave a started-only History record. |
| Plan credit | Normally waits for an actual saved Close and deduplicates. Failure/retry and expiry-at-Start exceptions remain N01/N04. |
| Notification shade interruption | Every `resumed` event invalidates time ([App:65–87](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/core/app/thirty_app.dart#L65-L87)). No preceding `paused` requirement distinguishes a brief inactive/resumed shade interruption. An older carried Circle beyond the limit can disappear after that interruption even though uninterrupted foreground interaction would retain it. |

The notification-shade behavior is explicitly disclosed in the R8 handoff. It is not silently credited as solved, nor presented here as a newly discovered undisclosed defect. No device experiment was performed to establish which OS interactions emit each lifecycle sequence. The source consequence is clear for an inactive→resumed sequence.

## 7. Premium, Keep and ownership assessment

**RevenueCat authority:** the reviewed gateway derives access from entitlement status, and only active status grants Premium. Persistence changes were not found to mint active entitlement. Missing/failed configuration and unavailable/inactive states do not become Premium solely from local Circle data. See [RevenueCat:40–45](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/core/premium/revenue_cat_entitlement_gateway.dart#L40-L45), [RevenueCat:52–91](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/core/premium/revenue_cat_entitlement_gateway.dart#L52-L91), [Premium:29–31](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/core/premium/premium_access.dart#L29-L31).

**Ordering limit:** RevenueCat tickets protect the latest published result, not necessarily the newest outstanding request. This documented behavior was not promoted to a new demonstrated bypass. No live service race or purchase lifecycle was independently exercised.

**Historical rights:** I4 Keep after lapse is legitimate historical ownership. The explicit exception in [Insights:207–225](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/insights/application/insights_provider.dart#L207-L225) is appropriate; other Insight mutations remain gated. Existing owned Circles remain usable after lapse. This is not unauthorized Premium access.

**Ownership persistence:** successful Keep waits for storage; failed Keep does not enter confirmed provider ownership. False/throw, retry and concurrent-limit assertions are meaningful. Eight places are enforced with pending reservations and a queued recheck; unreadable retained entries count conservatively, and an unknown count blocks creation. No ninth-Keep path was established in the inspected single-container concurrent actions.

**I4 two-store interruption:** if Keep fails, I4 is not marked applied. If Keep succeeds but the I4 applied-marker save fails, the Circle is already owned. Inspected tests demonstrate the intended manual retry path after restart: recognize already-kept ownership, avoid a duplicate and apply the marker, including while lapsed. The stores are not atomic, and automatic recovery of every changed/expired Insight context was not proven. That limitation is different from the original false-ownership defect.

**Subscription restoration:** misleading success after an inactive/unavailable refresh is fixed. Production identity continuity, device migration and actual Play/RevenueCat restoration remain A2-07 work.

**Security qualification:** N04 permits inappropriate Plan credit after a failed verified-expiry Start record; N08 can deny legitimate credit after lapse. These are provenance failures, not evidence of full subscription entitlement escalation. No claim is made about resistance to a tampered APK or locally forged data.

## 8. Test/evidence integrity and source equivalence

### Independent checks completed

| Evidence | Independent result | What it does and does not establish |
|---|---|---|
| 169 test files | Actual tracked `*_test.dart` inventory, batch plan and raw-log file union reconcile exactly. | Coverage inventory, not completeness of assertions. |
| 2,484 passing tests | Parsed all **20 final raw JSONL logs**: **2,484 success results; 0 failed; 0 skipped**. Each has one successful done event, no error events, and recorded exit 0. Names/counts/per-file results match summaries. | Confirms submitted evidence's consistency. These are **implementer-run results**, not an independent Flutter run. |
| 13 year-long profiles | All 13 declared profiles occur once across the final logs, with no repeated/undeclared/missing profile. | Simulated structural behavior; not measured retention, wellbeing, willingness to pay or device behavior. |
| 346 Git blobs | Every manifest path/blob ID equals the target's `git ls-tree` result for lib/test/pubspec.yaml/pubspec.lock/analysis_options.yaml. | Exact committed-source equality to the manifest. It does not provide independent execution attestation. |
| Start/end source fingerprints | Byte-identical fingerprint files. All 346 paths reconcile: 204 LF/unchanged; 142 CRLF-equivalent; 0 mismatches. | Cross-platform checkout line endings explain the byte-level variation without changing Git blob identity. |
| Frozen audio | **172/172** production SHA1 plus **8/8** framing SHA1 match; their union equals the **180** bundled guidance files. No R8 audio changes relative to parent. | Byte integrity only; no listening/native-language QA and no protection from N06's wrong fallback selection. |
| Runner happy evidence | Disposable-copy `report` and `cases` return exit 0 and EVIDENCE OK / CASES OK. | Independently executed Python evidence checks. |
| Runner failure evidence | Injected missing/false done success, done=false, nonzero exit, empty totals and failed-result mutations each return exit 1. A removed declared profile returns exit 1. | Runner validation catches these tested corruptions. |
| Raw summarizer fault distinction | Synthetic raw success, false success and missing done produce distinct `(done, doneSuccess)` results. | Independently executed Python, not Flutter. |
| R7 reproduction evidence | Summary says 73 failed, 21 passed. Raw reporter results reconcile to **58 failure + 15 error = 73 non-passing**, plus 21 success. | Evidence inspected; the 15 reporter “error” results should not be described as 15 extra passing guards or silently called assertion failures. No R7 Flutter rerun occurred here. |
| Analyzer | Handoff/README report analysis success; no separate raw analyzer log was found in the inspected evidence package. | Reported only, not independently reproduced. |

The 13 exact profile IDs are:

`p01_sparse_feedback`, `p02_frequent_feedback`, `p03_stable_positive`, `p04_mixed`, `p05_one_need_dominant`, `p06_all_three_needs`, `p07_mostly_10_minutes`, `p08_mostly_20_minutes`, `p09_mostly_30_minutes`, `p10_lapse_and_resubscribe`, `p11_many_exclusions`, `p13_no_routine`, `p14_more_energy_dominant`.

There is no declared p12 in this 13-profile inventory; a numbering gap is not a missing executed case. Separate B8 evidence contains four year profiles A–D, the voice-entitlement case and the aggregate E report case; those were not substituted for the 13-profile check.

Relevant committed evidence: [source manifest](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/artifacts/r8_post_audit_remediation_2026-11-04/regression/SOURCE_MANIFEST_git_blobs.txt), [batch plan](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/artifacts/r8_post_audit_remediation_2026-11-04/regression/batch_plan.json), [coverage manifest](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/artifacts/r8_post_audit_remediation_2026-11-04/regression/COVERAGE_MANIFEST.json), [case coverage](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/artifacts/r8_post_audit_remediation_2026-11-04/regression/CASE_COVERAGE.json), [runner](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/artifacts/r8_post_audit_remediation_2026-11-04/regression/run_batches.py), [R7 reproduction summary](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/artifacts/r8_post_audit_remediation_2026-11-04/repro_on_r7_tree/REPRO_ON_R7_TREE.json).

**Manifest SHA-256:** `862b924b5a1d3132b22a33aabc2ea2409bea09f2e1faaf553fe8946fc3213eee`.

Both original audit file hashes also match the handoff:

- Astra: `6ddfe5e144764cc723841efde41250c2ddd459475033da4d319315b3cdc37dc4`.
- Claude: `6d7e628c074aa62de540fdb98cd87c80e2389a3eb9bb3b26ac4213b656015875`.

**Runner caveat:** `report` and `cases` consume summaries. They do not independently authenticate raw logs against source. This audit separately re-parsed the raw logs and compared their results with those summaries.

### Reproduction environment for outstanding findings

Use a disposable checkout at the target SHA and the patterns in [test/support/r8_fault_disk.dart](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/test/support/r8_fault_disk.dart). Keep platform/disk state separate from the SharedPreferences cache; restart containers from the former. For N02, add a latch before the selected underlying side-copy mutation and do not block subsequent independent operations. For N09, use an explicit DST-observing timezone and both offset-distinct Close instants. Each new test should assert provider state, actual disk state, restart state and relevant UI/action result.

No such new Dart test was run or added to the audited repository during this audit.

## 9. Original 31-dimension scorecard comparison

Historical source: [original d89a035 scorecard](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/docs/audits/THIRTY_POST_V2_INDEPENDENT_AUDIT_GPT6_ASTRA_d89a035.md), SCORECARD section, lines 75–110.

The exact framework is preserved: **0 = absent/untenable; 5 = usable but limited; 10 = exceptionally well substantiated**. HIGH/MEDIUM/LOW expresses certainty in the judgment, not documentation quality or a predicted conversion percentage. No overall average is inferred.

The historical scores below belong to **d89a035**, not to R7. Neither post-R7 report supplies a replacement numerical 31-dimension scorecard. Therefore no “R7 score” or numerical R7→R8 improvement is invented.

This source/persistence audit revises the five dimensions directly supported by its evidence. “Not re-scored” explicitly leaves a dimension's present value unassessed; it does not endorse the historical number as current. In particular, legacy **Path value**, **Toolkit value** and **Routine ownership value** labels are preserved rather than silently renamed. The ownership assessment applies to the current Kept-Circle equivalent of retained user-owned content.

| # | Exact dimension | Historical score | Historical certainty | Post-R8 audit score | Current certainty |
|---|---|---:|---|---:|---|
| 1 | Core problem clarity | 8 | HIGH | Not re-scored | — |
| 2 | Core problem importance | 5 | LOW | Not re-scored | — |
| 3 | Free product value | 7 | MEDIUM | Not re-scored | — |
| 4 | Day-1 value | 6 | MEDIUM | Not re-scored | — |
| 5 | Day-7 value | 7 | LOW | Not re-scored | — |
| 6 | Day-30 value | 6 | LOW | Not re-scored | — |
| 7 | Recommendation quality | 7 | MEDIUM | Not re-scored | — |
| 8 | Personalization credibility | 7 | MEDIUM | Not re-scored | — |
| 9 | Simplicity | 6 | MEDIUM | Not re-scored | — |
| 10 | Emotional experience | 7 | LOW | Not re-scored | — |
| 11 | Trust | 7 | MEDIUM | 5 | MEDIUM |
| 12 | Accessibility / robustness | 7 | LOW | 5 | MEDIUM |
| 13 | Differentiation | 6 | MEDIUM | Not re-scored | — |
| 14 | Free retention potential | 6 | LOW | Not re-scored | — |
| 15 | Premium value | 6 | MEDIUM | Not re-scored | — |
| 16 | Premium differentiation | 6 | MEDIUM | Not re-scored | — |
| 17 | Path value | 6 | MEDIUM | Not re-scored | — |
| 18 | Toolkit value | 6 | MEDIUM | Not re-scored | — |
| 19 | Routine ownership value | 9 | HIGH | 8 | MEDIUM |
| 20 | Maintenance value | 5 | MEDIUM | Not re-scored | — |
| 21 | Week-7 paid value | 6 | MEDIUM | Not re-scored | — |
| 22 | Month-2 paid value | 6 | MEDIUM | Not re-scored | — |
| 23 | Month-6 paid value | 2 | MEDIUM | Not re-scored | — |
| 24 | Stable-user proposition | 2 | HIGH | Not re-scored | — |
| 25 | Subscription-worthiness | 3 | MEDIUM | Not re-scored | — |
| 26 | Commercial differentiation | 4 | MEDIUM | Not re-scored | — |
| 27 | Content scalability | 8 | HIGH | Not re-scored | — |
| 28 | Founder-labor scalability | 6 | LOW | Not re-scored | — |
| 29 | Pre-release readiness | 7 | MEDIUM | 4 | MEDIUM |
| 30 | Overall product quality | 7 | MEDIUM | 6 | MEDIUM |
| 31 | Overall commercial design strength | 5 | MEDIUM | Not re-scored | — |

### Reasons for revised scores

- **Trust: 7 → 5 (MEDIUM).** Durable Keep and checked deletion improve the R7 failure paths; removed answers returning, incomplete Insight application and recovery-copy loss prevent the historical trust rating.
- **Accessibility / robustness: 7 → 5 (MEDIUM).** Real-time no-touch choice is improved, but Plan provenance still uses the cached day; recovery, ambiguous DST timestamps and delayed-write failures remain. Device accessibility is not revalidated.
- **Routine ownership value: 9 → 8 (MEDIUM).** Keep now waits for persistence, remains usable after lapse, and enforces eight places. The executable saved-session wording gap prevents full confidence in preservation of owned content.
- **Pre-release readiness: 7 → 4 (MEDIUM).** Evidence is substantially more auditable, but three HIGH source-established data-integrity defects and six MEDIUM baseline issues remain. The separate commercial gates are also still open.
- **Overall product quality: 7 → 6 (MEDIUM).** Substantial working product and meaningful remediation are supported; cross-store inconsistencies and removal/restore failures prevent a seven. No runtime certification or user-outcome inference.

These lower values against the historical scorecard are an evidence-based reassessment, not proof that every defect was introduced since that old audit. R8 materially improves several unscored R7 defects while still failing current acceptance. The remaining 26 product/commercial dimensions require a broader current product review and, for many, user evidence.

**Separate engineering total:** none issued. No historical total exists to compare, and a new 100-point average would obscure the blocking integrity failures. Consequently no “NEW — NOT HISTORICALLY COMPARABLE” rubric is needed or implied.

## 10. R8 baseline acceptance gates

| Gate | Result |
|---|---|
| Exact target/source access | PASS |
| Original report and scorecard access | PASS |
| Source manifest / submitted raw evidence consistency | PASS, within the attestation limits above |
| Original Keep ownership false-success reproduction | FIXED |
| Original Delete false-return and initial intent-ordering reproduction | FIXED |
| End-to-end deletion / delayed preservation writes | FAIL — N02 |
| Durable Plan credit before overwrite | FAIL — N01 |
| Respect for answer removal across recovery | FAIL — N03 |
| Failed Start prerequisite across later lifecycle writes | FAIL — N04 |
| Durable application of non-I4 Insights | FAIL — N05 |
| Historical executable wording | FAIL — N06 |
| Damaged/readable-wrapper preservation | FAIL — N07 |
| No-touch Plan provenance | FAIL — N08 |
| Real six-hour rule after ambiguous DST persistence | FAIL — N09 |
| Failure/status reporting completeness | OPEN LOW — N10 |
| Independent Flutter/device execution | NOT PERFORMED |

**Blocking findings:** N01–N03 (HIGH) independently prevent baseline acceptance. N04–N09 (MEDIUM) also remain baseline acceptance requirements because they violate the persistence, entitlement provenance, historical-content or time guarantees specifically included in this audit. N10 is nonblocking by itself.

Acceptance requires correction and verification on a new immutable target; this report approves no implementation or release.

## 11. Separate commercial release gates

These remain **OPEN**, independently of the R8 source defects:

| Gate | Remaining requirement |
|---|---|
| A2-06 | Analytics retention, deletion, privacy policy and backing-service/Supabase verification |
| A2-07 | Device migration, Android backup and real Premium restoration/identity continuity |
| Pre-commercial billing and APK security | Actual billing lifecycle, restore scenarios and tamper/security assessment |
| Six-language localization | Full implementation and native-language QA |
| Multilingual audio | Complete libraries plus language/content/playback verification |
| Final commercial release audit | Final integrated product, privacy, billing, security and release review |

The corrected restoration wording is not closure of A2-07. Byte-frozen audio is not completion of multilingual audio. Simulation success is not commercial validation.

**THIRTY Phase E remains HOLD. KEYBRACE OS is discontinued.**

## 12. Final verdict

**FAIL. R8 baseline acceptance is not supported at commit `58b179c99866e234acd63e4e241590af36b9b186`.**

The evidence package is internally consistent and substantially stronger than the earlier one, and several original defects are genuinely repaired. However, the exact source still permits lost Plan credit, restoration of explicitly removed answers, unsafe preservation/deletion ordering, incorrect action completion and additional provenance/content/time failures.

This conclusion rests on the source paths and reproducible sequences above, not on distrust of a passing test count. The 2,484 passing results remain **inspected implementer evidence**, not an independently reproduced Flutter result. No fixes were implemented.

## 13. Independent verification notes

The following kinds of read-only checks were executed against the detached target:

```text
git rev-parse HEAD
git rev-parse HEAD^
git rev-parse HEAD^{tree}
git status --porcelain=v1
git rev-parse --is-shallow-repository
git fsck --full --strict
git ls-tree -r <target> -- lib test pubspec.yaml pubspec.lock analysis_options.yaml
```

Python verification then compared the exact manifest, fingerprints, raw reporter events, summary names/counts, test inventory, simulation names and audio hashes. The committed runner was executed only from a disposable evidence copy, since its reporting commands write generated summaries/manifests. Fault mutations were confined to that copy.

Final audited-repository status was clean. The evidence verifier and temporary reproductions did not change committed or uncommitted repository content.

## 14. Exact source-path index

All links in this report are fixed to the verified target SHA.

| Abbreviation | Exact source path |
|---|---|
| Today | [lib/features/home/application/recommendation_provider.dart](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/recommendation_provider.dart) |
| Plans | [lib/features/plans/application/circle_plans_provider.dart](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/plans/application/circle_plans_provider.dart) |
| PlanModel | [lib/features/plans/domain/circle_plan.dart](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/plans/domain/circle_plan.dart) |
| Insights | [lib/features/insights/application/insights_provider.dart](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/insights/application/insights_provider.dart) |
| InsightModel | [lib/features/insights/domain/insight.dart](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/insights/domain/insight.dart) |
| Kept | [lib/features/personal_circle/application/kept_circles_provider.dart](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/personal_circle/application/kept_circles_provider.dart) |
| KeptModel | [lib/features/personal_circle/domain/kept_circle.dart](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/personal_circle/domain/kept_circle.dart) |
| Composed | [lib/features/personal_circle/domain/composed_session.dart](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/personal_circle/domain/composed_session.dart) |
| Words | [lib/features/personal_circle/domain/circle_elements.dart](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/personal_circle/domain/circle_elements.dart) |
| Journal | [lib/features/home/application/circle_journal.dart](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/circle_journal.dart) |
| Delete | [lib/features/home/application/circle_history_deletion.dart](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/circle_history_deletion.dart) |
| Confirmed | [lib/core/storage/confirmed_write.dart](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/core/storage/confirmed_write.dart) |
| Failures | [lib/core/storage/store_save_failures.dart](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/core/storage/store_save_failures.dart) |
| Notice | [lib/features/home/presentation/widgets/journal_save_failure_notice.dart](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/presentation/widgets/journal_save_failure_notice.dart) |
| Prefs | [lib/features/home/application/suggestion_preferences.dart](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/application/suggestion_preferences.dart) |
| App | [lib/core/app/thirty_app.dart](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/core/app/thirty_app.dart) |
| Premium | [lib/core/premium/premium_access.dart](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/core/premium/premium_access.dart) |
| RevenueCat | [lib/core/premium/revenue_cat_entitlement_gateway.dart](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/core/premium/revenue_cat_entitlement_gateway.dart) |
| Data | [lib/features/settings/presentation/widgets/you_data_card.dart](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/settings/presentation/widgets/you_data_card.dart) |
| Controls | [lib/features/home/presentation/widgets/journal_data_controls.dart](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/presentation/widgets/journal_data_controls.dart) |
| RecordUI | [lib/features/home/presentation/circle_record_detail_page.dart](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/presentation/circle_record_detail_page.dart) |
| MemoryUI | [lib/features/home/presentation/memory_page.dart](https://github.com/thirtyapp/Thirty/blob/58b179c99866e234acd63e4e241590af36b9b186/lib/features/home/presentation/memory_page.dart) |

