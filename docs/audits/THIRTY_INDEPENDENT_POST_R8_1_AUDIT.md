# THIRTY — INDEPENDENT POST-R8.1 AUDIT

**Audit date:** 5 November 2026  
**Final verdict: FAIL — R8.1 baseline acceptance is blocked.**  
**Commercial release: NOT APPROVED. THIRTY Phase E remains HOLD.**

R8.1 materially improves the original failure paths, and its committed test evidence is internally consistent with the tested-source manifest. It does not establish the required durable data-integrity baseline. Two HIGH findings remain decisive: a pending Plan change can make legitimate credit disappear permanently, and an Insight assessment during Delete can recreate deleted Plan-review metadata after a deletion reported as successful. Six MEDIUM findings and one LOW consistency gap are also recorded below.

These are independent source-analysis conclusions, not independently executed Flutter reproductions. Flutter and Dart were unavailable in the audit environment. No claim in this report converts inspected implementer logs into an independently run product test.

## 1. Immutable target and read-only scope

| Item | Verified value |
|---|---|
| Repository | thirtyapp/Thirty |
| Requested branch | step5-billing-integration |
| Exact audited commit | e935112c408c16d99835280f4e1fafd722d47ed1 |
| Actual parent | 58b179c99866e234acd63e4e241590af36b9b186 — matches the expected parent |
| Commit tree | 6bcc58a949cb1999f9a3da7d1f168efb9e97cef8 |
| Commit subject | fix(thirty): close R8.1 independent audit persistence findings |
| Commit timestamp | 2026-11-05T11:21:54Z |
| Branch identity | The branch ref resolved to the requested commit when checked; conclusions are pinned to the SHA, not to a moving branch |
| Checkout | Detached at the exact target; clean at inspection |
| Git integrity | Independently executed git fsck --full --strict: exit 0 |
| Required handoff | [AUDIT_HANDOFF.md](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/artifacts/r8_1_consolidated_remediation_2026-11-05/AUDIT_HANDOFF.md) |

Only committed target source and evidence were audited. The production/test-source delta is 26 files, 3,780 insertions and 242 deletions: 13 production files, 10 new R8.1 test files, two existing test files and one fault-disk support file. The complete commit also contains documentation and evidence; those are not additional production changes.

No repository source, tests, existing audit reports, contracts or evidence were modified. Evidence-runner challenges used disposable copies outside the checkout. No staging, commit, push, merge, deployment, billing change, Supabase change, audio generation or R8.2 remediation was performed.

## 2. Methodology, inputs and limitations

### Required inputs

The audit read the full R8.1 handoff and ISSUE_REGISTER.json; the original Astra FAIL audit and Claude CONDITIONAL PASS audit; the current PRODUCT_V2_CONTRACT.md; ADR-023 for Personal Guided Circles and ADR-024 for Plans/Insights; the RL-4 limitation record; and the original d89a035 31-dimension scorecard. The issue register supplied navigation and claimed closure, not evidence of correctness.

Primary committed inputs:

- [R8.1 issue register](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/artifacts/r8_1_consolidated_remediation_2026-11-05/ISSUE_REGISTER.json).
- [Original Astra post-R8 audit — FAIL](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/docs/audits/THIRTY_INDEPENDENT_POST_R8_AUDIT.md).
- [Original Claude post-R8 audit — CONDITIONAL PASS](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/docs/audits/THIRTY_CLAUDE_POST_R8_AUDIT_REPORT.md).
- [Product contract](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/docs/product/PRODUCT_V2_CONTRACT.md), including Delete/Export, retained ownership, feedback and Premium boundaries.
- [ADR-023](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/docs/product/adr/ADR-023-v2-recurring-premium-personal-guided-circle.md) and [ADR-024](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/docs/product/adr/ADR-024-v2-circle-plans-insights-and-four-tab-product.md).
- [Original historical scorecard](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/docs/audits/THIRTY_POST_V2_INDEPENDENT_AUDIT_GPT6_ASTRA_d89a035.md#L75).

Input hashes independently reconciled with committed bytes:

| Input | SHA-256 |
|---|---|
| Astra post-R8 report | afc3631cbb54a67aaf02968a99ecc35431645621d71e0d5f0eb50cf9192f0ab1 |
| Claude post-R8 report, canonical LF | 2519e0b2e6794dc06532ac8a8a40b83d0fe7debdf4aada825558460d9164f1c0 |
| Preserved Claude reproduction text | efd63d49a1147cc18ae2404da0e41e03b2eb90a2163dbe0d06c41f8436b2b36f |

### Three different kinds of evidence

| Kind | Work actually performed | What it establishes |
|---|---|---|
| Independently executed checks | Git identity/integrity; complete manifest comparison; SHA-256 and audio SHA-1 recomputation; independent JSONL reporter parsing; inventory/profile/case reconciliation; evidence-runner positive and negative checks on disposable copies | Identity and internal consistency of the supplied evidence; whether its validators reject specified corruptions |
| Inspected implementer execution | 21 final raw Flutter reporter logs, summaries, completion events, analyzer output, before-fix failures, year simulations and B8 outputs | The committed logs report the stated outcomes, tied to matching source fingerprints; not independent re-execution |
| Static source analysis | Production queue/rollback/recovery paths, native preference-cache behavior, domains, UI call sites, contracts and regression assertions | Reachable code interleavings and missing invariants described in the findings |

All 179 tracked test files received a full-content automated scan and per-file reconciliation: 59,699 lines and 2,159,363 bytes. The scan recorded hashes, imports, test declarations, assertion calls, failure/restart signals and reported cases. Manual semantic review concentrated on all 10 new R8.1 files, the changed assertions, fault-disk support, neighboring persistence/entitlement/ownership tests and both simulation implementations. **This is not a claim that all 59,699 test lines received exhaustive manual semantic review.** Appendix A enumerates all 179 files and their reported cases.

**Not executed:** flutter test, flutter analyze, Dart adversarial tests, Android instrumentation, S25/TalkBack QA, real process-kill/power-loss tests, native purchase/restore transactions or release APK security tests. No runtime defect reproduction is claimed. Source-level reproduction recipes below are designed for a separate controlled run; they are not passed-off mock execution.

The dependency check used the locked SharedPreferences versions and their upstream implementation, including shared_preferences 2.5.5 and shared_preferences_android 2.4.27. The [legacy Dart implementation](https://github.com/flutter/packages/blob/shared_preferences-v2.5.5/packages/shared_preferences/shared_preferences/lib/src/shared_preferences_legacy.dart) mutates its cache before awaiting the platform result (inspected source blob 06d89f0010c86f640d19501c2a2a5183523b8039). The [Android legacy plugin](https://github.com/flutter/packages/blob/shared_preferences_android-v2.4.27/packages/shared_preferences/shared_preferences_android/android/src/main/kotlin/io/flutter/plugins/sharedpreferences/LegacySharedPreferencesPlugin.kt) uses native commit() and returns its Boolean result (inspected source blob bbdb3ecbadb51f6f1454e987be78285146751b89). Therefore this report does not assume Android writes merely use fire-and-forget apply(). It also does not treat a successful mocked return as a power-loss durability certificate. The package's [versioned documentation](https://pub.dev/packages/shared_preferences/versions/2.5.5) does not promise general critical-data persistence guarantees across all platforms.

Severity means practical consequence: HIGH for lost durable progress or violated successful deletion; MEDIUM for wrong durable provenance/application, recoverable-data loss or meaningful recovery/availability failure; LOW for a bounded historical/status inconsistency. Finding confidence is high in the specified source path; occurrence frequency and real-device timing are not measured.

## 3. Original finding closure matrix

**FIXED** means the original described reproduction has a production correction supported by source review and the inspected regression evidence. It does not certify neighboring behavior. **PARTIAL** means the exact example improved but the claimed invariant still fails. None of these rows relies on independently executed Flutter tests.

The production references and new-finding numbers below are expanded in sections 4 and 7. The test counts are inspected successful cases, not independent executions.

### Astra N01–N10

| Finding | Actual production correction and original reproduction | Failure modes / restart consistency / remaining vulnerability | Verdict |
|---|---|---|---|
| N01 — durable Plan credit | Plans tracks _durable; duplicate credit checks distinguish stored credit; recovery uses isCreditedDurably; ensureSaved deduplicates a pending identical snapshot. Eight N01 cases cover original Astra/Claude examples, false/throw and retry. | Correct for a credit already pending or retried without a competing lifecycle change. A pending Pause makes the domain return a successful no-op, allowing next-day overwrite although credit is absent from _durable. Repeated restarts cannot recover it after overwrite. A01. | **PARTIAL** |
| N02 — preservation copies / Delete | Container-scoped PreservationWrites tracks build-time copies. Overwrite protection awaits them; Delete awaits all tracked copies and removes aside keys again before removing its intent. Ten cases include held and failed copies. | Original pending-cache preservation and late aside-copy resurrection paths are closed. Failure retains the original or deletion intent. A different writer, new Insight generation from old confirmed Plans during Delete, remains A02; that is not the original untracked-copy mechanism. | **FIXED, original scope** |
| N03 — removed answers resurrect | removeAnswer clears matching daily recovery keys, even when that Circle is no longer on screen, before changing History. Thirteen cases include usefulness/both answers, next choice, restart and failures. | Original answer resurrection is closed. A failed second-store step is not atomic: day keys may already be clear while History still has the answer; failure is reported and retry is required. No automatic resurrection is needed for this to remain partial removal. Successful removal of an overnight answer can reopen finished reflection: new A06. | **FIXED, original scope** |
| N04 — failed expiry-at-Start bypass | Later lifecycle persistence waits for Start evidence; Today retains the original Start entitlement verdict and can recreate the refused Plan record. Seven N04 cases include false/throw, restart and legitimate lapse credit. | The original later-Close/pause bypass is corrected. No new unauthorized entitlement grant established. Current verified Premium at Close is an explicit pre-existing test policy, discussed in section 8. A01 still affects loss of legitimate credit. | **FIXED** |
| N05 — I1–I3 applied before target saved | apply awaits confirmed Plan actions or serialized preference saves; applied marker is awaited afterward. Preferences treat false as failure. Eleven N05 cases cover target/marker refusal and retry. | Original target-fails-but-applied example is corrected. I2 validates one confirmed cycle and mutates another optimistic cycle (A04). Target success followed by marker failure has no I1–I3 repair path (A08). | **PARTIAL** |
| N06 — damaged historical wording / voice | Damaged present wording is distinguished from absent wording. Exact matching Kept wording is recovered; otherwise an unstarted damaged offer is withheld, and an already-started Circle is unvoiced and marked unverified. Thirteen cases. | Raw damaged daily data is not silently re-authored. Already-started fallback shows current instructions only with the founder-approved RL-2 notice, without THIRTY voice. No broader fallback or new audio change established. | **FIXED** |
| N07 — lossy Plans/Insights decoding | Unknown Plans and damaged cycles/records are retained; wrapper fields survive. Non-list Insights objects become unreadable and are preserved. Eight original N07 cases. | Exact wrapper/unknown-Plan cases are corrected. Accepted readable nested fields can still be filtered and lost on the next successful save: A05. Whole future-schema wrappers must be distinguished from these current-schema nested shapes. | **PARTIAL** |
| N08 — no-touch midnight provenance | steerToday receives the actual Circle ID; Today passes the event-time day, including upgrade paths. One focused case. | Source no longer uses the stale cached day to mark this served Circle. Date remains its own day through credit. No remaining defect established in the original path. | **FIXED** |
| N09 — DST / six-hour elapsed time | New daily Start, Close and pause writes use UTC instants, read back locally. Four cases cover both repeated 02:30 occurrences, distinct storage and legacy reading. | Correct for newly written instants. Older offset-free daily values remain ambiguous; no offset can be reconstructed. Other stores remain RL-4, explicitly accepted rather than fixed. | **FIXED for new writes; RL-4 separate** |
| N10 — failure notices | Closing a notice rechecks both journal and store failures; confirmed Kept save clears stale unsaved status. Five cases include accessibility label and overlapping failures. | Multiple failures may be coalesced into a generic notice; they are not silently discarded merely because one notice was open. Native assistive-technology behavior was not rerun. | **FIXED** |

### Claude AUD-1–AUD-6 and founder corrections

| Finding | Actual correction / original coverage | Durable/restart assessment and remaining vulnerability | Verdict |
|---|---|---|---|
| AUD-1 — credit prerequisite | The same _durable/ensureSaved fix as N01; both original fault variants represented in the eight N01 cases. | A01 still permits overwrite without confirmed credit under a competing pending Plan action. | **PARTIAL** |
| AUD-2 — next day after carried-over completion | _openNewDayAfter invalidates the day after saved reflection; chooseIntention accepts a finished earlier Circle. Three focused cases, with/without touch and reflection-open control. | Original completed-flow lockout is corrected. Removing its answer later can undo that completion across recovery: A06. | **FIXED, original scope** |
| AUD-3 — unknown Plan / damaged cycle loss | Unknown Plan entries retained by key; unreadable cycles retain their enclosing Plan; starting over an unreadable Plan is refused. Original reproduction included. | The original future_plan plus ordinary Pause survives save/restart. Nested readable metadata remains a separate A05 hole. | **FIXED, original scope** |
| AUD-4 — non-list snapshots overwrite | Present non-null non-list snapshots makes the wrapper unreadable; preservation precedes replacement. Original recoverable object reproduction included. | The original object payload is retained. A null snapshots field is still treated as empty; that does not reproduce the original nonempty recoverable-object loss. A05 concerns accepted nested payloads. | **FIXED, original scope** |
| AUD-5 — offset-free instants | Same UTC daily-session correction as N09. | New session instants distinguish the repeated hour. Legacy values and other stores remain the accepted RL-4 boundary. | **FIXED for new writes; RL-4 separate** |
| AUD-6 — optimistic state reported as done | Latest failed Plans/Insights write rolls visible state back to _durable; confirmed actions and preferences wait for storage. Original synchronous Plan API still returns an action-accepted result before saving. | The founder permits pending display, not durable consequences from unconfirmed state. A01/A03/A04/A07 show that boundary is incomplete; A08 covers target/marker disagreement. | **PARTIAL** |
| RL-1 — remove effects of failed optimistic changes | Seventeen cases cover latest-write rollback, pending assessment, served-stage publication and original Start verdict retry. | Rollback itself works for the latest failed snapshot. Live/confirmed identity is mixed in other decisions, and the publication gate examines the wrong snapshot. A01/A02/A03/A04/A07. | **PARTIAL** |
| RL-2 — explain unrecoverable historical wording | Three widget cases; the approved title/body is a note on every affected part and included in the live-region label. Never voiced. | Correct within the approved already-started continuation exception. No native screen-reader or localization approval inferred. | **FIXED** |
| RL-3 — field preservation | StageRecord.source preserves original fields; malformed revisit items and unknown/damaged Plan/cycle fields are retained; unreadable preferences refuse changes until Reset. Twelve cases. | The explicitly listed StageRecord-list/revisit examples are fixed. The broader handoff claim about field preservation is incomplete for readable preference entries, served metadata and Insight snapshots: A05. | **PARTIAL overall; original list cases fixed** |

**RL-4: ACCEPTED — NOT FIXED.** It is not counted as an OPEN blocker merely because the limitation exists. Its precise boundary is reviewed in section 9.

## 4. Newly established findings and reproduction scenarios

All nine findings in this section were established by static source analysis. **Executed Flutter reproductions: zero.** “Expected actual result” below means the result entailed by the cited code under the stated ordering; it is not an observed device trace.

### R81-A01 — HIGH — A pending failed Pause bypasses the durable-credit prerequisite

**Baseline blocker. Related closure: N01, AUD-1, RL-1.**

Sources: [Plans _set, lines 169–204](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/plans/application/circle_plans_provider.dart#L169); [recordGuided, lines 450–476](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/plans/application/circle_plans_provider.dart#L450); [domain recordGuided, lines 895–909](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/plans/domain/circle_plan.dart#L895); [Today pre-overwrite gate, lines 875–894](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/home/application/recommendation_provider.dart#L875); [recovery credit check, lines 1039–1054](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/home/application/recommendation_provider.dart#L1039); [next-day credit attempt, lines 1246–1252](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/home/application/recommendation_provider.dart#L1246).

The new durable duplicate check only handles credit already present in visible state. It does not distinguish “no credit is required” from “an unconfirmed lifecycle change prevented credit.” Domain recordGuided returns the same state when its Plan is paused. The notifier then finds no optimistic credit to retry and returns a successfully completed Future, even when the durable Plan is active and still entitled to that saved Close.

Reproduction:

1. Durably serve and Start a stage Circle under verified Premium on day D.
2. Save its Close to Today and History, but refuse its Plan-credit write. Wait for rollback: durable and visible Plans are active, uncredited.
3. Advance to D+1, let any recovery retry fail and settle, and verify entitlement inactive. The original served/started provenance still legitimately permits this credit after lapse.
4. Begin Pause and hold its Plan-store result. Visible state becomes paused; _durable remains active.
5. Choose a Free Circle for D+1 while Pause is pending. Both the early credit attempt and the pre-overwrite credit gate see the optimistic paused Plan and successfully do nothing.
6. Let the new day's daily-key and History writes succeed, then release Pause with false or an exception.
7. Restart twice.

Expected actual result: Pause rolls back, but the active Plan still lacks D's guided record. D's last recoverable daily session has been overwritten. History has the Close, but the production catch-up path does not scan old History to reconstruct Plan credit. Restart cannot repair it.

The original failure notice does not make the later data loss acceptable. No write success was fabricated; a successful no-op was incorrectly accepted as evidence of durable credit. This is more than the accepted temporary pending display.

### R81-A02 — HIGH — Delete can successfully finish with recreated Insight metadata

**Baseline blocker. New interaction introduced by reading confirmed Plans during deletion.**

Sources: [Delete sequence, lines 157–209](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/home/application/circle_history_deletion.dart#L157); [final History clear contents, lines 222–231](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/home/application/circle_history_deletion.dart#L222); [Plan evidence deletion, lines 487–512](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/plans/application/circle_plans_provider.dart#L487); [Insight inputs and assessment, lines 181–217](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/insights/application/insights_provider.dart#L181); [Insight deletion, lines 415–435](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/insights/application/insights_provider.dart#L415); [review generation, lines 557–577](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/insights/domain/insight_engine.dart#L557); [snapshot generation, lines 781–819](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/insights/domain/insight_engine.dart#L781); [snapshot retention, lines 867–871](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/insights/domain/insight_engine.dart#L867); [opening Insights schedules assessment](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/insights/presentation/insights_page.dart#L79).

forgetStageEvidence removes visible evidence immediately but leaves _durable unchanged until the Plan write completes. Insights now uses that old _durable value. assess and _set neither consult the History deletion gate nor carry a deletion epoch. Delete waits the forgetAll Future it captured, not an assessment queued afterward. Its final pass clears History, daily state and aside keys, not a newly written normal insightsKey.

Reproduction:

1. Seed a durably completed Plan cycle with a review and historical Circle IDs; keep Premium active.
2. Start Delete Circle history and confirm its intent. Hold the main Plan evidence-clearing write.
3. After Insights has been cleared in memory, open Insights while Delete is still awaiting storage, or invoke its production assess entry point.
4. Assessment reads the old confirmed Plan, creates its I5 review snapshot again and queues a save after forgetAll.
5. Release the Plan clear successfully; allow all writes and Delete to finish.
6. Restart.

Expected actual result: the deletion marker is removed and Delete can report success, yet the newly saved snapshot retains the old Plan/cycle/date and evidence Circle IDs. It becomes a stale readable snapshot after Plan evidence is cleared; pruning does not remove it merely because it is stale. This is deleted derived metadata, not a claim that full deleted journal answers are reconstructed.

The original delayed preservation-copy race is fixed. This is a separate post-delete writer. The contract explicitly deletes all Insight snapshots and forbids residue from deleted evidence. Native serial execution does not cure the defect: the old assessment is computed before deletion completes and its captured payload can be written afterward.

### R81-A03 — MEDIUM — Stage publication checks the live offer instead of the payload being saved

**Baseline blocker. Escalates the accepted “pending stage only remains visible” limitation.**

Sources: [Today write queue, lines 738–758](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/home/application/recommendation_provider.dart#L738); [_publish, especially lines 828–839](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/home/application/recommendation_provider.dart#L809); [useOwnedToday, lines 1766–1820](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/home/application/recommendation_provider.dart#L1766); [captured choice publication, lines 2224–2236](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/home/application/recommendation_provider.dart#L2224); [confirmServed, lines 272–283](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/plans/application/circle_plans_provider.dart#L272).

_persistChoice captures a Recommendation. _publish writes values from that captured recommendation but decides whether to await confirmServed from the live state.recommendation. A later same-day Kept choice has no stage and suppresses the prerequisite for the earlier queued stage payload.

Reproduction:

1. Have a valid durably Kept Circle. Keep an earlier Today queue operation pending on a storage Future so later UI actions can queue behind it.
2. Begin a Plan Start, hold its store write, and choose a stage Circle from the optimistic Plan.
3. Before the queued choice reaches _publish, use the Kept Circle today. Visible state now has no stage; both writes are still queued.
4. Let the earlier Today operation finish. Refuse all pending Plan Start/served writes.
5. Let the captured stage-choice publication succeed; refuse the later Kept replacement's write-ahead-record write, or interrupt before that replacement.
6. Restart.

Expected actual result: daily storage contains a stage Circle whose Plan/served state never became durable. The gate is skipped because the current Kept offer has no stage. The stage offer can survive restart, rather than being merely transient and disappearing after a failed Plan save.

This scenario does not establish a RevenueCat entitlement bypass: the stage was composed while Premium was active. It establishes invalid durable provenance and contradicts the handoff's “never saved” bound.

### R81-A04 — MEDIUM — I2 checks cycle A but applies gentler to pending cycle B

**Baseline blocker. Related closure: N05, AUD-6, RL-1.**

Sources: [apply status gate, lines 249–280](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/insights/application/insights_provider.dart#L249); [_gentler, lines 310–323](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/insights/application/insights_provider.dart#L310); [Plan actions, lines 298–311](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/plans/application/circle_plans_provider.dart#L298); [domain keepGentler, lines 870–878](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/plans/domain/circle_plan.dart#L870); [I2 current-cycle status, lines 630–635](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/insights/domain/insight_engine.dart#L630).

_gentler validates the snapshot cycle against confirmedState. Its confirmed callback then runs keepGentler against the optimistic state, with only planId and no expected cycle ID.

Reproduction:

1. Keep cycle A active and durable, with a current, unapplied I2 for cycle A.
2. Hold a Leave write for A, then choose Go through again. Visible state now holds active cycle B, while confirmedState still holds A.
3. Apply the original I2. Both current-status and _gentler validation read A.
4. Allow the queued Leave, new-cycle and gentler writes to succeed, then allow the Insight marker.
5. Restart.

Expected actual result: B receives gentlerSince, while the marked-applied Insight names A. All writes can return true. Serializing writes alone does not make the validated target identical to the mutated target.

### R81-A05 — MEDIUM — Readable nested records still lose unknown or damaged fields

**Baseline blocker under the requested lossless recovery scope. Related closure: N07, RL-3.**

Sources: [NotSuggested codec, lines 34–46](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/home/application/suggestion_preferences.dart#L34); [RestLifted codec, lines 64–76](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/home/application/suggestion_preferences.dart#L64); [ElementLeftOut codec, lines 95–105](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/home/application/suggestion_preferences.dart#L95); [preference retention classification, lines 221–232](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/home/application/suggestion_preferences.dart#L221); [served-stage codec, lines 619–635](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/plans/domain/circle_plan.dart#L619); [Insight serialization, lines 299–312](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/insights/domain/insight.dart#L299); [Insight decode filtering, lines 321–373](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/insights/domain/insight.dart#L321).

The fixes retain invalid whole items and selected raw fields, but an item that is otherwise accepted is rebuilt from known fields. Its unrecognized nested fields are then lost without an aside copy.

Concrete reproductions, with healthy storage:

- Add futureRule: {keep: true} to an otherwise valid elementsLeftOut entry. Load preferences, leave out a different valid part, save and restart. The first entry survives but futureRule does not. The same pattern affects readable notSuggested and restsLifted entries.
- Add unknown metadata to a valid Plan lastServed record. An ordinary unrelated Plan save rebuilds it without that metadata. A present malformed startedAfterExpiry value is also coerced to false rather than retained as unreadable; it can alter lapse-credit interpretation.
- Add an object-valued fact, a non-string evidence item, or an unknown field to an otherwise accepted Insight snapshot/application. Generate or dismiss an unrelated Insight and save. Filtering/reconstruction drops the original nested values; the whole wrapper still passes the readable guard.

Expected actual result: after the successful save and repeated restarts, discarded values are gone from both the main store and preservation storage.

This does **not** allege that the fixed unknown-Plan, damaged-cycle or StageRecord-list reproductions still fail. Nor does it confuse a future wrapper schema with unknown nested fields inside a currently accepted schema. The remaining defect is incomplete lossless handling at those accepted nested boundaries.

### R81-A06 — MEDIUM — Removing an overnight answer reopens finished reflection

**Baseline blocker for the requested History/recovery/next-day lifecycle. New interaction between N03 and AUD-2 fixes.**

Sources: [reflection completion and carry-over, lines 550–570](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/home/application/recommendation_provider.dart#L550); [restoring carry-over, lines 934–938](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/home/application/recommendation_provider.dart#L934); [choice guard](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/home/application/recommendation_provider.dart#L1242); [finished-earlier-day test, lines 1329–1336](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/home/application/recommendation_provider.dart#L1329); [open new day, lines 1948–1955](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/home/application/recommendation_provider.dart#L1948); [answer removal, lines 1962–2015](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/home/application/recommendation_provider.dart#L1962).

Completion of carried-over reflection is inferred solely from currently retained answers. There is no separate durable acknowledgement that the user finished that flow. The N03 correction now removes those answers from the recovery keys as well as History, so a legitimate removal can undo navigation completion.

Reproduction:

1. Start a Circle at 23:40 on D; Close at 00:10 on D+1.
2. Answer “Yes” and give usefulness; let every save finish. Today's new choice opens.
3. Before choosing D+1's Circle, remove D's usefulness answer, or both answers, from History; let removal succeed.
4. Restart or trigger recovery at 00:20.

Expected actual result: D's completed Circle is restored as an unfinished carried-over reflection because reflectionAnswered is false. chooseIntention for D+1 returns without choosing. The user must supply an answer again, or wait until carry-over expires and the day is re-evaluated.

The deleted answer itself is not resurrected. The defect is that exercising the right to remove feedback can reimpose a completed feedback flow and block the next choice. It is not covered by the original same-day/removal tests or the original completion-only midnight tests.

### R81-A07 — MEDIUM — Pending History cache state can create a durable Insight

**Baseline blocker for the explicit unconfirmed-state requirement. Newly identified neighboring weakness.**

Sources: [writeConfirmed, lines 31–52](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/core/storage/confirmed_write.dart#L31); [journal answer removal, lines 1045–1062](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/home/application/circle_journal.dart#L1045); [journal write, lines 1229–1252](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/home/application/circle_journal.dart#L1229); [journal cache read, lines 1327–1346](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/home/application/circle_journal.dart#L1327); [Insight inputs, lines 181–200](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/insights/application/insights_provider.dart#L181); [I4 arithmetic, lines 409–479](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/insights/domain/insight_engine.dart#L409).

Rollback corrects SharedPreferences cache after a failed result, but readers can consume the unconfirmed value while the platform Future is pending. Insights reads History directly from that cache; it has no equivalent of the confirmed Plans snapshot.

A concrete I4 fixture:

1. Seed valid composed History for one need across at least 14 days within the 90-day window, with no skips. Seven Circles are called useful: four contain writing as main/second, three contain a different kind. At least three other Circles lack writing and are unanswered/not useful. Choose parts so no other kind qualifies.
2. Before removal, writing is 4/7 of useful Circles, below the two-thirds threshold; no writing I4 qualifies.
3. Remove usefulness from one of the three useful non-writing Circles that is not the Circle held in daily recovery keys. Hold the journal platform write after the Dart cache changes.
4. Open Insights under Premium. Its cached view has six useful Circles and four comparison Circles: writing is 4/6 versus 0/4, so I4 qualifies and its text/facts are captured.
5. Return false or throw for the journal write, allowing rollback to the durable 4/7 record. Allow the Insight save to succeed, then restart.

Expected actual result: a dated Insight survives whose generated counts were never confirmed History. It may now be stale, but it remains retained and can affect cadence/repeat handling. A platform queue that executes the Insight write later does not fix the already captured false premise.

Plan Stage-5 answer collection also reads the same journal readAll path at [lines 317–318](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/plans/application/circle_plans_provider.dart#L317); that is an additional decision boundary needing verification. The concrete finding and reproduction above are the durable I4 snapshot, not a claim that a Stage-5 variant was executed.

### R81-A08 — LOW — I1–I3 cannot repair a failed applied marker after target success

**Does not independently block baseline acceptance; retain as an open consistency issue.**

Sources: [apply, lines 249–286](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/insights/application/insights_provider.dart#L249); [target helpers, lines 289–340](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/insights/application/insights_provider.dart#L289); [I1 active-Plan exclusion, lines 255–278](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/insights/domain/insight_engine.dart#L255); [I2 gentler exclusion, lines 304–308](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/insights/domain/insight_engine.dart#L304); [status and I3 exclusion, lines 614–650](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/insights/domain/insight_engine.dart#L614).

Reproduction: apply a valid I1, I2 or I3; let the target store succeed, but refuse the applied-marker write. The target stays durable and the marker rolls back, with a failure notice. Restart and retry that Insight.

Expected actual result: the successful target makes the old candidate no longer current: the Plan is active, the cycle is already gentler, or the part is left out. apply exits at the status gate before its helper can recognize the existing target. Unlike I4, there is no repair path that records the earlier successful application.

No unsaved target is falsely marked applied, and ownership is not lost. The gap is an incomplete application history and unusable retry after partial two-store success. The existing marker-failure test checks the immediate disagreement but not eventual repair.

### R81-A09 — MEDIUM — Wrong native preference types bypass unreadable-store recovery

**Baseline recovery blocker; newly discovered, not established as newly introduced.**

Sources: [Plans initial read, lines 90–108](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/plans/application/circle_plans_provider.dart#L90); [Insights initial read, lines 79–97](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/insights/application/insights_provider.dart#L79); [Preferences build, lines 247–253](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/home/application/suggestion_preferences.dart#L247); [History initial read, lines 1327–1331](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/home/application/circle_journal.dart#L1327).

Reproduction: store a native integer or Boolean under one of the JSON-string keys, for example circlePlansKey, insightsKey or suggestionPreferencesKey, then create the corresponding production provider.

Expected actual result: SharedPreferences.getString performs a cast and throws before the application's JSON try/catch or tryRead is reached. There is no unreadable fallback or preservation operation for that read. Repeated restarts encounter the same typed value. Affected provider/routes fail to load; a whole-application crash is not asserted without runtime verification.

This is distinct from storing the string “42” or “true”, which reaches JSON decoding. It also exceeds the accepted “unreadable Preferences can be reset” case: the notifier does not finish normal initialization into the protected unreadable state. No data overwrite is asserted for this example; the defect is persistent availability and recovery failure.

## 5. Independently executed verification and test evidence

### Execution ledger

| Check | Independent result |
|---|---|
| Exact commit / parent / tree | Matched |
| Clean committed checkout and Git object integrity | Passed |
| Complete tested-source Git-blob manifest comparison | 357/357 matched; no missing or extra scoped files |
| Start/end source fingerprints | Identical; reconciled with target bytes, including line endings |
| Raw JSONL parsing | 21 final logs; 2,599 successful non-loading tests, 0 failed, 0 skipped |
| Completion events | Exactly one successful done event per final log; summary exit codes all 0 |
| Inventory union | All 179 tracked test files represented |
| Per-file/test-name reconciliation | Matches summaries and COVERAGE_MANIFEST; no duplicated file/name test result |
| Declared year profiles | All 13 present exactly once |
| B8 cases | All six named cases present exactly once |
| Evidence runner, clean disposable copy | report exit 0, EVIDENCE OK; cases exit 0, CASES OK |
| Runner negative challenges | false doneSuccess, missing batch, missing file, duplicate profile and missing profile were rejected with exit 1 |
| Frozen audio byte hashes | 172 production + 8 framing = 180/180 matched |
| Independent Flutter tests / analyzer / adversarial Dart tests | **Not run — SDK unavailable** |

The runner challenges only executed Python evidence validation. They did not execute application behavior. The runner's report command trusts summary JSON; this audit separately parsed the raw JSONL to avoid treating that summary check as independent raw-log verification.

### Final raw reporter totals

| Final log | Successful tests | done.success | Summary exit |
|---|---:|---|---:|
| batch_01.jsonl | 76 | true | 0 |
| batch_02.jsonl | 99 | true | 0 |
| batch_03.jsonl | 121 | true | 0 |
| batch_04.jsonl | 157 | true | 0 |
| batch_05.jsonl | 88 | true | 0 |
| batch_06.jsonl | 226 | true | 0 |
| batch_07.jsonl | 241 | true | 0 |
| batch_08.jsonl | 154 | true | 0 |
| batch_09.jsonl | 164 | true | 0 |
| batch_10.jsonl | 267 | true | 0 |
| batch_11.jsonl | 187 | true | 0 |
| batch_12.jsonl | 282 | true | 0 |
| batch_13.jsonl | 159 | true | 0 |
| batch_14.jsonl | 173 | true | 0 |
| batch_15.jsonl | 186 | true | 0 |
| batch_16.jsonl | 6 | true | 0 |
| batch_17a.jsonl | 3 | true | 0 |
| batch_17b.jsonl | 3 | true | 0 |
| batch_17c.jsonl | 3 | true | 0 |
| batch_17d.jsonl | 2 | true | 0 |
| batch_17e.jsonl | 2 | true | 0 |
| **Total** | **2,599** | **21/21 true** | **21/21 zero** |

The union is 179 unique files. The year-long simulation file is deliberately loaded in five filtered batches, 17a–17e. Accordingly, the handoff's phrase “no file in two batches” should not be read literally: the meaningful invariant is no duplicated executed simulation profile/test case. All 13 declared profiles are accounted for once.

### New R8.1 regression coverage

| Test file under test/features/r81 | Reported cases |
|---|---:|
| r81_n01_durable_plan_credit_test.dart | 8 |
| r81_n02_preservation_writes_test.dart | 10 |
| r81_n03_removed_answers_test.dart | 13 |
| r81_n04_n05_expiry_and_insight_application_test.dart | 18 |
| r81_n06_n07_damaged_records_test.dart | 21 |
| r81_n08_n09_aud2_time_test.dart | 8 |
| r81_n10_failure_notices_test.dart | 5 |
| r81b_rl1_pending_state_test.dart | 17 |
| r81b_rl2_unverified_words_copy_test.dart | 3 |
| r81b_rl3_field_preservation_test.dart | 12 |
| **Total new cases** | **115** |

The 115 new results reconcile the prior 2,484 with the final 2,599. The older 83-case figure describes the pre-founder-correction tranche, not the final total. The two existing assertion changes were inspected: the refused Plan action now rolls back rather than staying active; and the Today write now waits behind the held Plan write. Those changes are consistent with the approved RL-1 intent, but they do not exercise A01–A07.

Before-fix raw evidence was inspected independently:

- Original R8.1 tranche: 83 testDone outcomes — 60 failure, 6 error, 17 success; final done.success false.
- Founder-correction tranche: 30 emitted outcomes — 20 failure, 1 error, 9 success; final done.success false. A compile/load error prevents equating those events with all 32 final source cases.
- These runs used earlier source/assertion shapes. They support the remediation chronology; they are not proof that every exact final assertion was executed unchanged against the parent.

The superseded regression directory and the aborted stale-review-pack attempt were excluded from final totals. Their existence was disclosed by the handoff. No evidence fabrication was established.

### All thirteen year-long profiles

| Declared profile | Raw successful executions |
|---|---:|
| p01_sparse_feedback | 1 |
| p02_frequent_feedback | 1 |
| p03_stable_positive | 1 |
| p04_mixed | 1 |
| p05_one_need_dominant | 1 |
| p06_all_three_needs | 1 |
| p07_mostly_10_minutes | 1 |
| p08_mostly_20_minutes | 1 |
| p09_mostly_30_minutes | 1 |
| p10_lapse_and_resubscribe | 1 |
| p11_many_exclusions | 1 |
| p13_no_routine | 1 |
| p14_more_energy_dominant | 1 |

The committed inventory intentionally has no p12. That is not a missing fourteenth profile.

### Six B8 cases

| Case | Scope inspected | Raw successful executions |
|---|---|---:|
| A | Never answers; no invented feedback and whole service remains available | 1 |
| B | Mixed answers; composition, Stage 5 and reviews follow explicit responses | 1 |
| C | More Energy at approximately 10 minutes; safety gate and repetition | 1 |
| D | Lapse/resubscribe; retained ownership and stopped new Premium work | 1 |
| Voice | Entitlement controls voice while the user's choice is retained | 1 |
| E | Aggregate assertions/report over A–D | 1 |

E is an aggregate test, not a fifth independently simulated user. Both year-long and B8 implementations were inspected. These are valuable deterministic structural simulations, not measured retention, willingness to pay, live billing or adversarial cross-store scheduling. A year of simulated days does not automatically cover a millisecond-scale failure interleaving.

### Analyzer evidence

The final committed analyzer output reports “No issues found! (ran in 6.6s)”. It was inspected, not rerun. Static analyzer success does not prove transaction ordering, deletion completeness or disk durability.

## 6. Evidence, source-manifest and audio verification

The authoritative [Git-blob manifest](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/artifacts/r8_1_consolidated_remediation_2026-11-05/regression_final/SOURCE_MANIFEST_git_blobs.txt) contains all 357 scoped files in lib/, test/, pubspec.yaml, pubspec.lock and analysis_options.yaml. Every path/blob pair matched git ls-tree at the exact target.

Manifest SHA-256:

784401a39b7770e024dacda34fe9e9c2530c9260e8dd170b54c0d2fc194fe72a

SOURCE_FINGERPRINT_start.sha256 and SOURCE_FINGERPRINT_end.sha256 are identical. Of the 357 entries, 210 match LF checkout bytes directly and 147 reconcile through the tested Windows CRLF form. There were zero unexplained mismatches. This is a line-ending reconciliation, not permission to ignore changed source.

The manifest is strong evidence of source identity within its stated scope. It is not a cryptographic attestation that an untrusted machine ran those bytes, and it does not cover a released APK, native toolchain, resolved package-cache contents, device state or server configuration.

All audio hashes were recomputed from actual committed asset bytes:

| Manifest | Entries | Matching assets |
|---|---:|---:|
| artifacts/v2_phase_d2/voice_production/PRODUCTION_SHA1.txt | 172 | 172 |
| artifacts/v2_phase_d2/voice_production/framing_f02_f03/FRAMING_SHA1.txt | 8 | 8 |
| Exact union of bundled guidance assets | 180 | 180 |

No audio asset changed between parent and target. SHA-1 here checks equality to the frozen manifests; this is not an assessment of SHA-1 as a modern signing primitive, acoustic quality, multilingual readiness or content safety.

The complete final raw evidence is under [regression_final](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/artifacts/r8_1_consolidated_remediation_2026-11-05/regression_final). Appendix A provides the 179-file reconciliation. Independent check outputs were produced outside the repository; the original evidence remained unchanged.

## 7. Durable data-integrity assessment

### Queue and rollback behavior

Plans and Insights now have a useful distinction between visible state and the last confirmed snapshot. On the latest failure, the visible state rolls back to _durable. Earlier failed queued writes do not roll back over a newer pending state. A later successful whole-state write can include changes incorporated from an earlier failed snapshot. This is consolidated-snapshot persistence, not an isolated transaction for each action.

ensureSaved waits the existing Future when state is identical to the latest queued snapshot. It does not silently spawn a second identical write. After failure and rollback, state may equal _durable and ensureSaved may correctly return immediately; retrying a failed semantic action requires recreating that action. Today keeps the original Start verdict for that purpose. It is inaccurate to describe ensureSaved alone as an unconditional replay of every failed action.

Those local mechanisms do not ensure that every caller evaluates the same confirmed object it later saves. A01, A03 and A04 are concrete failures at that boundary.

### Store-by-store conclusions

| Area | Verified improvement | Remaining assessment |
|---|---|---|
| Today daily keys | Write-ahead payload, confirmed per-key writes, cleanup retry and pre-overwrite History/credit gate | **FAIL:** A01 successful no-op credit gate; A03 payload/visible-stage mismatch; A06 reflection completion depends on removable answers |
| History | Failed false/throw writes roll cache back; unknown records/future wrappers have preservation/refusal paths; removal clears matching daily recovery answers first | Original N03 fixed. **FAIL for decision isolation:** A07 exposes pending cache data to durable Insights. Partial removal across stores remains non-atomic but reported |
| Plans | _durable, deduplication, Start verdict retention and confirmed served/Start checks | **FAIL:** legitimate credit loss and wrong-cycle application; nested metadata/type recovery holes |
| Insights | Target must succeed before applied marker; latest failed state rolls back; confirmed Plans used for assessment | **FAIL:** deletion regeneration, cached History premise, wrong-cycle target; marker repair gap |
| Kept Circles | Serialized transform against current state, publish after confirmation, duplicate and capacity reservations | No new ownership-capacity or lapse-rights bypass established; damaged/future records conservatively count or refuse new Keep |
| Suggestion Preferences | Serialized changes, publish after confirmed save, false/throw notices, unreadable-wrapper refusal until Reset | Improved, but accepted readable entries still lose nested extras; wrong native type fails before protected initialization |
| Preservation copies | Pending build-time copies tracked and awaited; Delete clears both aside keys in final pass | Original copy race fixed. Does not govern normal Insight generation during Delete |
| Delete marker / recovery | Intent confirmed first, retried once; failures retain marker; startup recovery; successful marker removal last | **FAIL:** the set of governed writers is incomplete, A02 |
| Notices | Multiple pending failure sources rechecked after notice closes; successful Keep clears its stale store failure | Original N10 corrected; a notice is not a transaction or repair mechanism |

The code's “durable” means the last application-level storage call confirmed successfully. It is not a fresh read of actual disk on every access. SharedPreferences cache, provider memory, confirmed snapshots and native storage are four distinct states. A01/A02 use a stale but formerly confirmed snapshot incorrectly; A07 uses a not-yet-confirmed cache value.

No claim of universal crash atomicity is warranted. The test fault disk models calls that return false, throw or wait; it does not establish every real platform outcome, such as a storage operation taking effect before the process loses its acknowledgement. Nor were multi-engine cache coherence and real power loss independently tested.

## 8. Premium, ownership and data security

RevenueCat remains the entitlement authority. [_statusFor, lines 87–91](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/core/premium/revenue_cat_entitlement_gateway.dart#L87) grants Premium only for the configured active entitlement. [premiumEntitlementProvider](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/core/premium/premium_access.dart#L29) requires EntitlementStatus.active; unavailable/initializing do not grant new Premium actions. R8.1 does not change billing source or dependency versions.

Restore still requires authoritative active state: [gateway restore](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/core/premium/revenue_cat_entitlement_gateway.dart#L149) and [notifier restore, lines 98–108](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/core/premium/premium_access.dart#L98). A generic successful SDK return is insufficient. No new false restoration confirmation was established. Live account, purchase and restore behavior remains unexecuted.

| Required boundary | Audit conclusion |
|---|---|
| Unauthorized Premium access | No new local entitlement bypass established by R8.1 source review; no release-security certificate |
| Invalid or missing Plan credit | Original failed inactive-Start bypass corrected; **legitimate credit can still be lost, A01**. A03 creates invalid persisted stage provenance; malformed served flags are part of A05 |
| Historical I4 Keep after lapse | Retained. apply explicitly permits an existing valid KeepCircleFromHistory without active Premium; current-status, duplicate and capacity checks still apply |
| Eight-Circle limit | No bypass established. _keeping reserves in-flight requests; serialized _commit rechecks count and duplicate at execution; unreadable records count, or unknown capacity refuses Keep |
| Ownership after lapse | Existing Kept Circles, reading retained history/Insights and permitted ownership actions remain accessible; new Premium generation remains gated |
| Personal History | Original removed-answer resurrection corrected; broader durable integrity still fails through A01/A05/A07 and recovery availability A09 |
| User-deleted data | **FAIL:** A02 can preserve recreated deleted Insight metadata after successful Delete |
| Historical wording/audio | Exact saved wording recovered where possible; damaged already-started continuation clearly marked and unvoiced; 180 frozen hashes unchanged |

Ownership references: [Kept commit](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/personal_circle/application/kept_circles_provider.dart#L243), [Keep capacity/reservations](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/personal_circle/application/kept_circles_provider.dart#L281), and [I4 lapse exception and application](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/lib/features/insights/application/insights_provider.dart#L234).

**Start/Close policy qualification:** the existing [R2 test at lines 341–354](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/plans/r2_plan_credit_provenance_test.dart#L341) explicitly expects credit when Start occurred after verified expiry but Premium is verified again by Close. The production guard implements that exception. Some broad comments say an after-expiry Start earns no credit; the executable policy is more specific. I do not report that pre-existing, explicitly tested resubscription behavior as a new unauthorized grant. It should be stated consistently in the product policy; the passing test alone is not authority to invent a broader entitlement rule.

## 9. Accepted limitations reviewed separately

| Limitation | Independent disposition |
|---|---|
| RL-4 — legacy offset-free timestamps | **Accepted, not fixed.** New daily Start/Close/pause are UTC; old offset-free daily values remain ambiguous. History/Kept/preference local timestamps still lack an offset. Lifted-rest comparison can be affected within the repeated hour, as the limitation itself acknowledges; this is not exclusively display-only. No automatic baseline escalation solely for this accepted scope |
| Pending-then-failed stage Circle remains visible | The isolated no-further-action case remains a bounded pending-display limitation. **Its claimed “never saved” bound is disproved by A03**, so the broader case cannot retain LOW acceptance |
| Unreadable Plan Start lacks explanatory copy | Ordinary unreadable Plan entry is preserved and Start refused. Accepted usability limitation; no authority to overwrite it. Native typed-store failure is a different A09 issue |
| Unreadable Preferences require Reset | Protected unreadable-string case refuses ordinary saves and tells the user. Accepted. A05 nested loss and A09 pre-initialization cast failure fall outside this accepted behavior |
| Notification-shade carry-over | Previously accepted lifecycle behavior is unchanged in the R8.1 delta. Resume invalidates the day; native shade/TalkBack/device timing was not rerun. No independent release approval inferred |
| Analytics at interaction | Still records the interaction rather than confirmed persistence. Accepted as interaction semantics, not proof that a durable Circle/action exists. A2-06 privacy/retention work remains open |

The [RL-4 record](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/artifacts/r8_1_consolidated_remediation_2026-11-05/LIMITATION_RL4_OFFSET_FREE_TIMESTAMPS.md) requires a pre-commercial disposition. Its “six-hour rule unaffected” language must be limited to newly written UTC daily instants, not retroactively extended to older ambiguous daily values. No offset should be guessed.

## 10. Numerical scorecard comparison

The original d89a035 framework is retained exactly: same 31 names, 0–10 scale and HIGH/MEDIUM/LOW certainty labels. Original certainty values are preserved in their own column. Only five dimensions were meaningfully reassessed here. “Not reassessed” is not a fresh endorsement of the old score.

| # | Exact historical dimension | d89a035 score | Original certainty | R8.1 score | R8.1 certainty | Change vs d89a035 |
|---:|---|---:|---|---|---|---|
| 1 | Core problem clarity | 8 | HIGH | Not reassessed | — | — |
| 2 | Core problem importance | 5 | LOW | Not reassessed | — | — |
| 3 | Free product value | 7 | MEDIUM | Not reassessed | — | — |
| 4 | Day-1 value | 6 | MEDIUM | Not reassessed | — | — |
| 5 | Day-7 value | 7 | LOW | Not reassessed | — | — |
| 6 | Day-30 value | 6 | LOW | Not reassessed | — | — |
| 7 | Recommendation quality | 7 | MEDIUM | Not reassessed | — | — |
| 8 | Personalization credibility | 7 | MEDIUM | Not reassessed | — | — |
| 9 | Simplicity | 6 | MEDIUM | Not reassessed | — | — |
| 10 | Emotional experience | 7 | LOW | Not reassessed | — | — |
| 11 | Trust | 7 | MEDIUM | **5** | MEDIUM | -2 |
| 12 | Accessibility / robustness | 7 | LOW | **5** | MEDIUM | -2 |
| 13 | Differentiation | 6 | MEDIUM | Not reassessed | — | — |
| 14 | Free retention potential | 6 | LOW | Not reassessed | — | — |
| 15 | Premium value | 6 | MEDIUM | Not reassessed | — | — |
| 16 | Premium differentiation | 6 | MEDIUM | Not reassessed | — | — |
| 17 | Path value | 6 | MEDIUM | Not reassessed | — | — |
| 18 | Toolkit value | 6 | MEDIUM | Not reassessed | — | — |
| 19 | Routine ownership value | 9 | HIGH | **9** | MEDIUM | 0 |
| 20 | Maintenance value | 5 | MEDIUM | Not reassessed | — | — |
| 21 | Week-7 paid value | 6 | MEDIUM | Not reassessed | — | — |
| 22 | Month-2 paid value | 6 | MEDIUM | Not reassessed | — | — |
| 23 | Month-6 paid value | 2 | MEDIUM | Not reassessed | — | — |
| 24 | Stable-user proposition | 2 | HIGH | Not reassessed | — | — |
| 25 | Subscription-worthiness | 3 | MEDIUM | Not reassessed | — | — |
| 26 | Commercial differentiation | 4 | MEDIUM | Not reassessed | — | — |
| 27 | Content scalability | 8 | HIGH | Not reassessed | — | — |
| 28 | Founder-labor scalability | 6 | LOW | Not reassessed | — | — |
| 29 | Pre-release readiness | 7 | MEDIUM | **4** | MEDIUM | -3 |
| 30 | Overall product quality | 7 | MEDIUM | **6** | MEDIUM | -1 |
| 31 | Overall commercial design strength | 5 | MEDIUM | Not reassessed | — | — |

Comparison with the actual post-R8 audit values:

| Dimension | Original d89a035 | Astra post-R8 | Claude post-R8 | This R8.1 audit | Explanation |
|---|---|---|---|---|---|
| Trust | 7 MEDIUM | 5 MEDIUM | 7 MEDIUM | **5 MEDIUM** | Many exact failures corrected, but successful deletion and legitimate progress remain unreliable. No rise from Astra's 5; −2 versus original and Claude |
| Accessibility / robustness | 7 LOW | 5 MEDIUM | 7 MEDIUM | **5 MEDIUM** | No-touch completion, UTC instants and failure notices improve; A06/A09 and absent native QA prevent a robustness uplift. −2 versus original/Claude |
| Routine ownership value | 9 HIGH | 8 MEDIUM | 9 HIGH | **9 MEDIUM** | Kept persistence/capacity, historical wording handling and I4 Keep rights survive lapse; no new ownership bypass found. +1 versus Astra, same number as original/Claude, lower certainty than their HIGH |
| Pre-release readiness | 7 MEDIUM | 4 MEDIUM | 7 MEDIUM | **4 MEDIUM** | Evidence integrity is strong; remaining baseline blockers and unexecuted native checks prevent acceptance. Same as Astra, −3 versus original/Claude |
| Overall product quality | 7 MEDIUM | 6 MEDIUM | 7 MEDIUM | **6 MEDIUM** | Coherent implementation with substantive repairs, but unresolved cross-store semantics. Same as Astra, −1 versus original/Claude |

“Routine ownership value” retains the historical name; the assessed present-day analogue is retained Kept-Circle ownership. Obsolete framework names such as “Path value” were not silently renamed or rescored.

These numbers are engineering/product judgments with stated certainty, not a function of test pass percentage. No previous aggregate has been invented. No new engineering score out of 100 is supplied, and the 31 dimensions are not averaged.

## 11. Remaining blockers and acceptance boundary

### R8.1 engineering baseline

A01 and A02 each independently block baseline acceptance. They contradict the two central remediation claims: unresolved legitimate credit cannot be destroyed by the next day's choice, and successful Delete leaves no deleted derived data.

A03–A07 and A09 are additional MEDIUM blockers within the requested persistence, recovery and malformed-data scope. A08 is a LOW open consistency issue and does not independently require FAIL. The report distinguishes newly introduced interactions from newly discovered pre-existing holes; an unchanged defect is not automatically acceptable when it lies inside the requested integrity baseline.

Acceptance would require independent evidence that the specified outcomes no longer occur, including held/false/throw variants, competing operations, partial success and fresh-container restarts. This is an acceptance condition, not authorization to implement remediation. No R8.2 work has begun.

### Commercial release

Even a future baseline PASS would not approve commercial release. The handoff's open gates remain open:

- A2-06 analytics/privacy/retention and timestamp/export disposition.
- A2-07 Android backup, migration and real Premium restoration.
- Pre-commercial billing and release-APK security review.
- Six-language localization/native-language QA and multilingual audio readiness.
- Real-device QA, including storage failures, process kill, assistive technology and lifecycle behavior.
- Applicable content-safety/public-build gates and the final commercial release audit.

The structural simulations do not establish retention, conversion or subscription willingness to pay. This audit does not rescore those commercial dimensions or authorize external/public content use.

## 12. Final verdict

**FAIL. Exact baseline e935112c408c16d99835280f4e1fafd722d47ed1 is not accepted.**

The evidence pack is substantially verifiable: 357 matching source blobs, 179 represented test files, 2,599 reported successful results, 13/13 declared year profiles, six B8 cases and 180/180 unchanged audio hashes. Those successes coexist with persistence failures established by source analysis outside the tested interleavings.

R8.1 corrects many original examples but does not close all blocking integrity findings without regressions. The decisive failures are missing legitimate Plan credit after a pending failed lifecycle change and recreated deleted Insight metadata. Additional provenance, cycle-target, field-retention, recovery and cache-isolation gaps remain.

**Commercial release is not approved. THIRTY Phase E remains HOLD. Audit only; no remediation performed.**

## Appendix A — All 179 test files reconciled

Every listed file was read in full by the automated content scan and matched to the final raw reporter inventory. The case column is the number of successful implementer-reported test executions, excluding suite-loading pseudo-tests; it is not an independent execution count. Line counts and complete-content hashes were independently computed. Deep manual review was risk-directed as stated in section 2.

| Committed test file | Lines | Reported successful cases |
|---|---:|---:|
| [test/core/analytics/analytics_consent_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/analytics/analytics_consent_test.dart) | 120 | 7 |
| [test/core/analytics/analytics_service_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/analytics/analytics_service_test.dart) | 65 | 2 |
| [test/core/analytics/tester_identity_provider_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/analytics/tester_identity_provider_test.dart) | 110 | 6 |
| [test/core/android_identity_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/android_identity_test.dart) | 107 | 6 |
| [test/core/app/r6b_day_rollover_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/app/r6b_day_rollover_test.dart) | 274 | 7 |
| [test/core/app/r8_midnight_resume_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/app/r8_midnight_resume_test.dart) | 294 | 9 |
| [test/core/app/thirty_app_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/app/thirty_app_test.dart) | 143 | 3 |
| [test/core/branding/thirty_wordmark_view_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/branding/thirty_wordmark_view_test.dart) | 106 | 5 |
| [test/core/config/release_info_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/config/release_info_test.dart) | 22 | 1 |
| [test/core/config/revenue_cat_config_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/config/revenue_cat_config_test.dart) | 122 | 13 |
| [test/core/config/supabase_config_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/config/supabase_config_test.dart) | 45 | 6 |
| [test/core/premium/entitlement_gateway_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/premium/entitlement_gateway_test.dart) | 118 | 11 |
| [test/core/premium/premium_access_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/premium/premium_access_test.dart) | 427 | 19 |
| [test/core/premium/r8_restore_wording_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/premium/r8_restore_wording_test.dart) | 71 | 3 |
| [test/core/premium/revenue_cat_entitlement_gateway_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/premium/revenue_cat_entitlement_gateway_test.dart) | 598 | 23 |
| [test/core/providers/clock_provider_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/providers/clock_provider_test.dart) | 33 | 2 |
| [test/core/providers/shared_preferences_provider_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/providers/shared_preferences_provider_test.dart) | 40 | 2 |
| [test/core/providers/theme_mode_provider_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/providers/theme_mode_provider_test.dart) | 81 | 13 |
| [test/core/qa/qa_entitlement_gateway_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/qa/qa_entitlement_gateway_test.dart) | 65 | 5 |
| [test/core/qa/qa_free_v2_scenarios_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/qa/qa_free_v2_scenarios_test.dart) | 115 | 6 |
| [test/core/qa/qa_isolation_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/qa/qa_isolation_test.dart) | 178 | 5 |
| [test/core/qa/qa_phase_c_scenarios_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/qa/qa_phase_c_scenarios_test.dart) | 206 | 7 |
| [test/core/qa/qa_premium_gate_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/qa/qa_premium_gate_test.dart) | 137 | 7 |
| [test/core/qa/qa_premium_harness_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/qa/qa_premium_harness_test.dart) | 240 | 7 |
| [test/core/qa/qa_scenario_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/qa/qa_scenario_test.dart) | 357 | 15 |
| [test/core/release_build_guard_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/release_build_guard_test.dart) | 94 | 6 |
| [test/core/reminder/local_notifications_reminder_gateway_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/reminder/local_notifications_reminder_gateway_test.dart) | 207 | 7 |
| [test/core/routing/app_router_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/routing/app_router_test.dart) | 242 | 10 |
| [test/core/routing/app_shell_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/routing/app_shell_test.dart) | 197 | 8 |
| [test/core/routing/b7_four_tab_shell_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/routing/b7_four_tab_shell_test.dart) | 447 | 25 |
| [test/core/routing/floating_nav_surface_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/routing/floating_nav_surface_test.dart) | 193 | 6 |
| [test/core/routing/premium_billing_navigation_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/routing/premium_billing_navigation_test.dart) | 105 | 4 |
| [test/core/theme/app_colors_a4_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/theme/app_colors_a4_test.dart) | 231 | 18 |
| [test/core/theme/app_spacing_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/theme/app_spacing_test.dart) | 16 | 2 |
| [test/core/theme/app_theme_a5_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/theme/app_theme_a5_test.dart) | 39 | 3 |
| [test/core/theme/app_theme_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/theme/app_theme_test.dart) | 157 | 17 |
| [test/core/theme/app_typography_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/theme/app_typography_test.dart) | 132 | 6 |
| [test/core/theme/snackbar_c5_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/theme/snackbar_c5_test.dart) | 245 | 11 |
| [test/core/utils/date_key_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/utils/date_key_test.dart) | 19 | 3 |
| [test/core/widgets/r6_button_busy_label_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/widgets/r6_button_busy_label_test.dart) | 89 | 5 |
| [test/core/widgets/thirty_app_bar_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/widgets/thirty_app_bar_test.dart) | 244 | 14 |
| [test/core/widgets/thirty_button_large_text_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/widgets/thirty_button_large_text_test.dart) | 273 | 42 |
| [test/core/widgets/thirty_button_shape_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/widgets/thirty_button_shape_test.dart) | 202 | 8 |
| [test/core/widgets/thirty_button_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/widgets/thirty_button_test.dart) | 293 | 18 |
| [test/core/widgets/thirty_card_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/widgets/thirty_card_test.dart) | 146 | 8 |
| [test/core/widgets/thirty_confirm_dialog_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/widgets/thirty_confirm_dialog_test.dart) | 346 | 22 |
| [test/core/widgets/thirty_progress_circle_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/widgets/thirty_progress_circle_test.dart) | 197 | 14 |
| [test/core/widgets/viewport_visibility_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/widgets/viewport_visibility_test.dart) | 148 | 6 |
| [test/core/world_rendering/quiet_trail_hero_asset_view_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/world_rendering/quiet_trail_hero_asset_view_test.dart) | 117 | 5 |
| [test/core/world_rendering/quiet_trail_hero_view_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/world_rendering/quiet_trail_hero_view_test.dart) | 178 | 6 |
| [test/core/worlds/catalog/quiet_trail_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/worlds/catalog/quiet_trail_test.dart) | 32 | 3 |
| [test/core/worlds/daypart_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/worlds/daypart_test.dart) | 32 | 9 |
| [test/core/worlds/place_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/worlds/place_test.dart) | 45 | 3 |
| [test/core/worlds/reference/quiet_trail_hero_scene_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/worlds/reference/quiet_trail_hero_scene_test.dart) | 225 | 13 |
| [test/core/worlds/registered_worlds_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/worlds/registered_worlds_test.dart) | 46 | 4 |
| [test/core/worlds/world_art_manifest_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/worlds/world_art_manifest_test.dart) | 181 | 12 |
| [test/core/worlds/world_registry_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/worlds/world_registry_test.dart) | 199 | 15 |
| [test/core/worlds/world_scene_policy_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/worlds/world_scene_policy_test.dart) | 48 | 4 |
| [test/core/worlds/world_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/core/worlds/world_test.dart) | 109 | 9 |
| [test/features/b8/b8_delete_longitudinal_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/b8/b8_delete_longitudinal_test.dart) | 299 | 5 |
| [test/features/b8/b8_live_copy_guard_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/b8/b8_live_copy_guard_test.dart) | 265 | 11 |
| [test/features/b8/b8_plan_attack_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/b8/b8_plan_attack_test.dart) | 371 | 6 |
| [test/features/b8/b8_product_simulation_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/b8/b8_product_simulation_test.dart) | 969 | 6 |
| [test/features/b8/b8_review_pack_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/b8/b8_review_pack_test.dart) | 436 | 1 |
| [test/features/home/application/activity_catalog_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/application/activity_catalog_test.dart) | 900 | 41 |
| [test/features/home/application/circle_journal_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/application/circle_journal_test.dart) | 566 | 23 |
| [test/features/home/application/circle_session_lifecycle_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/application/circle_session_lifecycle_test.dart) | 504 | 12 |
| [test/features/home/application/first_breath_provider_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/application/first_breath_provider_test.dart) | 67 | 4 |
| [test/features/home/application/recommendation_provider_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/application/recommendation_provider_test.dart) | 1252 | 55 |
| [test/features/home/application/recommendation_v2_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/application/recommendation_v2_test.dart) | 278 | 10 |
| [test/features/home/application/world_scene_resolution_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/application/world_scene_resolution_test.dart) | 331 | 22 |
| [test/features/home/circle_greeting_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/circle_greeting_test.dart) | 357 | 33 |
| [test/features/home/delete_circle_history_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/delete_circle_history_test.dart) | 347 | 8 |
| [test/features/home/domain/circle_session_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/domain/circle_session_test.dart) | 237 | 15 |
| [test/features/home/domain/recommendation_engine_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/domain/recommendation_engine_test.dart) | 642 | 27 |
| [test/features/home/domain/recommendation_simulation_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/domain/recommendation_simulation_test.dart) | 609 | 10 |
| [test/features/home/domain/suggestion_controls_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/domain/suggestion_controls_test.dart) | 380 | 14 |
| [test/features/home/greeting_one_line_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/greeting_one_line_test.dart) | 239 | 25 |
| [test/features/home/home_cta_nav_layout_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/home_cta_nav_layout_test.dart) | 683 | 18 |
| [test/features/home/home_invitation_session_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/home_invitation_session_test.dart) | 434 | 12 |
| [test/features/home/home_page_b1_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/home_page_b1_test.dart) | 290 | 13 |
| [test/features/home/home_page_b2_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/home_page_b2_test.dart) | 385 | 20 |
| [test/features/home/home_page_b3_real_font_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/home_page_b3_real_font_test.dart) | 164 | 28 |
| [test/features/home/home_page_b3_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/home_page_b3_test.dart) | 470 | 27 |
| [test/features/home/home_page_d1_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/home_page_d1_test.dart) | 582 | 32 |
| [test/features/home/home_page_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/home_page_test.dart) | 214 | 8 |
| [test/features/home/pre_release_retirement_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/pre_release_retirement_test.dart) | 362 | 12 |
| [test/features/home/presentation/circle_history_page_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/presentation/circle_history_page_test.dart) | 326 | 9 |
| [test/features/home/presentation/circle_record_detail_page_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/presentation/circle_record_detail_page_test.dart) | 150 | 3 |
| [test/features/home/presentation/phase_c_memory_ui_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/presentation/phase_c_memory_ui_test.dart) | 536 | 12 |
| [test/features/home/presentation/phase_c_talkback_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/presentation/phase_c_talkback_test.dart) | 371 | 9 |
| [test/features/home/presentation/widgets/activity_guide_sheet_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/presentation/widgets/activity_guide_sheet_test.dart) | 249 | 8 |
| [test/features/home/presentation/widgets/circle_hero_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/presentation/widgets/circle_hero_test.dart) | 1508 | 56 |
| [test/features/home/presentation/widgets/circle_ready_prompt_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/presentation/widgets/circle_ready_prompt_test.dart) | 270 | 10 |
| [test/features/home/presentation/widgets/circle_reflection_card_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/presentation/widgets/circle_reflection_card_test.dart) | 239 | 11 |
| [test/features/home/presentation/widgets/daily_intention_prompt_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/presentation/widgets/daily_intention_prompt_test.dart) | 188 | 6 |
| [test/features/home/presentation/widgets/phase_b_ui_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/presentation/widgets/phase_b_ui_test.dart) | 375 | 10 |
| [test/features/home/presentation/widgets/phase_c_session_ui_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/presentation/widgets/phase_c_session_ui_test.dart) | 858 | 22 |
| [test/features/home/presentation/widgets/premium_offer_invitation_card_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/presentation/widgets/premium_offer_invitation_card_test.dart) | 161 | 5 |
| [test/features/home/presentation/widgets/today_card_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/presentation/widgets/today_card_test.dart) | 286 | 8 |
| [test/features/home/r2_make_today_circle_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/r2_make_today_circle_test.dart) | 498 | 22 |
| [test/features/home/r3_delete_feedback_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/r3_delete_feedback_test.dart) | 322 | 10 |
| [test/features/home/r3_persistence_delete_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/r3_persistence_delete_test.dart) | 1610 | 41 |
| [test/features/home/r6_free_copy_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/r6_free_copy_test.dart) | 75 | 5 |
| [test/features/home/r6_journal_save_failure_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/r6_journal_save_failure_test.dart) | 264 | 9 |
| [test/features/home/r6b_journal_unreadable_preserved_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/r6b_journal_unreadable_preserved_test.dart) | 108 | 4 |
| [test/features/home/r6c_journal_store_safety_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/r6c_journal_store_safety_test.dart) | 205 | 11 |
| [test/features/home/r8_a01_daily_persistence_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/r8_a01_daily_persistence_test.dart) | 212 | 13 |
| [test/features/home/r8_a04_delete_durability_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/r8_a04_delete_durability_test.dart) | 187 | 14 |
| [test/features/home/r8_a06_unreadable_history_controls_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/r8_a06_unreadable_history_controls_test.dart) | 147 | 9 |
| [test/features/home/r8_journal_forward_records_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/r8_journal_forward_records_test.dart) | 60 | 2 |
| [test/features/home/r8b_notice_copy_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/r8b_notice_copy_test.dart) | 66 | 2 |
| [test/features/home/r8b_precommit_persistence_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/home/r8b_precommit_persistence_test.dart) | 665 | 34 |
| [test/features/insights/gentler_feasibility_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/insights/gentler_feasibility_test.dart) | 168 | 50 |
| [test/features/insights/insight_engine_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/insights/insight_engine_test.dart) | 1911 | 80 |
| [test/features/insights/insight_plan_review_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/insights/insight_plan_review_test.dart) | 174 | 7 |
| [test/features/insights/insight_simulation_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/insights/insight_simulation_test.dart) | 440 | 7 |
| [test/features/insights/insights_service_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/insights/insights_service_test.dart) | 790 | 25 |
| [test/features/insights/presentation/insights_page_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/insights/presentation/insights_page_test.dart) | 906 | 29 |
| [test/features/insights/presentation/widgets/circle_history_calendar_a11y_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/insights/presentation/widgets/circle_history_calendar_a11y_test.dart) | 304 | 11 |
| [test/features/insights/presentation/widgets/circle_history_calendar_states_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/insights/presentation/widgets/circle_history_calendar_states_test.dart) | 292 | 11 |
| [test/features/insights/presentation/widgets/circle_history_calendar_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/insights/presentation/widgets/circle_history_calendar_test.dart) | 389 | 12 |
| [test/features/insights/r5_i4_keep_after_lapse_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/insights/r5_i4_keep_after_lapse_test.dart) | 406 | 13 |
| [test/features/insights/r6b_insight_dates_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/insights/r6b_insight_dates_test.dart) | 149 | 10 |
| [test/features/insights/r8_f4_insight_dates_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/insights/r8_f4_insight_dates_test.dart) | 141 | 12 |
| [test/features/personal_circle/circle_composer_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/personal_circle/circle_composer_test.dart) | 569 | 26 |
| [test/features/personal_circle/circle_elements_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/personal_circle/circle_elements_test.dart) | 391 | 21 |
| [test/features/personal_circle/composed_ui_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/personal_circle/composed_ui_test.dart) | 994 | 33 |
| [test/features/personal_circle/composer_baseline_equivalence_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/personal_circle/composer_baseline_equivalence_test.dart) | 31 | 1 |
| [test/features/personal_circle/d2_review_pack_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/personal_circle/d2_review_pack_test.dart) | 506 | 4 |
| [test/features/personal_circle/f02_f03_framing_lines_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/personal_circle/f02_f03_framing_lines_test.dart) | 968 | 40 |
| [test/features/personal_circle/guidance_entitlement_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/personal_circle/guidance_entitlement_test.dart) | 577 | 13 |
| [test/features/personal_circle/guidance_session_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/personal_circle/guidance_session_test.dart) | 52 | 2 |
| [test/features/personal_circle/personal_circle_simulation_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/personal_circle/personal_circle_simulation_test.dart) | 639 | 13 |
| [test/features/personal_circle/premium_today_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/personal_circle/premium_today_test.dart) | 573 | 16 |
| [test/features/personal_circle/r41_kept_store_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/personal_circle/r41_kept_store_test.dart) | 521 | 12 |
| [test/features/personal_circle/r4_kept_ownership_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/personal_circle/r4_kept_ownership_test.dart) | 749 | 25 |
| [test/features/personal_circle/r6_kept_voice_whole_circle_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/personal_circle/r6_kept_voice_whole_circle_test.dart) | 312 | 8 |
| [test/features/personal_circle/r8_kept_ownership_persistence_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/personal_circle/r8_kept_ownership_persistence_test.dart) | 439 | 32 |
| [test/features/personal_circle/saved_circle_lapse_attack_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/personal_circle/saved_circle_lapse_attack_test.dart) | 348 | 1 |
| [test/features/personal_circle/stage_brief_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/personal_circle/stage_brief_test.dart) | 980 | 78 |
| [test/features/plans/circle_plan_domain_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/plans/circle_plan_domain_test.dart) | 779 | 29 |
| [test/features/plans/circle_plan_today_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/plans/circle_plan_today_test.dart) | 836 | 24 |
| [test/features/plans/plan_copy_guard_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/plans/plan_copy_guard_test.dart) | 78 | 2 |
| [test/features/plans/plans_surface_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/plans/plans_surface_test.dart) | 791 | 29 |
| [test/features/plans/r2_plan_credit_provenance_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/plans/r2_plan_credit_provenance_test.dart) | 729 | 26 |
| [test/features/plans/r6_stage5_end_line_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/plans/r6_stage5_end_line_test.dart) | 90 | 6 |
| [test/features/premium/application/premium_offer_provider_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/premium/application/premium_offer_provider_test.dart) | 170 | 8 |
| [test/features/premium/b7_entitlement_matrix_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/premium/b7_entitlement_matrix_test.dart) | 374 | 40 |
| [test/features/premium/presentation/premium_offer_c2_real_font_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/premium/presentation/premium_offer_c2_real_font_test.dart) | 145 | 24 |
| [test/features/premium/presentation/premium_offer_c2_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/premium/presentation/premium_offer_c2_test.dart) | 306 | 13 |
| [test/features/premium/presentation/premium_offer_copy_guard_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/premium/presentation/premium_offer_copy_guard_test.dart) | 155 | 7 |
| [test/features/premium/presentation/premium_offer_page_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/premium/presentation/premium_offer_page_test.dart) | 308 | 11 |
| [test/features/premium/r6_purchase_busy_label_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/premium/r6_purchase_busy_label_test.dart) | 85 | 1 |
| [test/features/r81/r81_n01_durable_plan_credit_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/r81/r81_n01_durable_plan_credit_test.dart) | 237 | 8 |
| [test/features/r81/r81_n02_preservation_writes_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/r81/r81_n02_preservation_writes_test.dart) | 217 | 10 |
| [test/features/r81/r81_n03_removed_answers_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/r81/r81_n03_removed_answers_test.dart) | 221 | 13 |
| [test/features/r81/r81_n04_n05_expiry_and_insight_application_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/r81/r81_n04_n05_expiry_and_insight_application_test.dart) | 395 | 18 |
| [test/features/r81/r81_n06_n07_damaged_records_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/r81/r81_n06_n07_damaged_records_test.dart) | 375 | 21 |
| [test/features/r81/r81_n08_n09_aud2_time_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/r81/r81_n08_n09_aud2_time_test.dart) | 286 | 8 |
| [test/features/r81/r81_n10_failure_notices_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/r81/r81_n10_failure_notices_test.dart) | 147 | 5 |
| [test/features/r81/r81b_rl1_pending_state_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/r81/r81b_rl1_pending_state_test.dart) | 321 | 17 |
| [test/features/r81/r81b_rl2_unverified_words_copy_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/r81/r81b_rl2_unverified_words_copy_test.dart) | 181 | 3 |
| [test/features/r81/r81b_rl3_field_preservation_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/r81/r81b_rl3_field_preservation_test.dart) | 253 | 12 |
| [test/features/reminder/application/reminder_after_close_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/reminder/application/reminder_after_close_test.dart) | 445 | 17 |
| [test/features/reminder/application/reminder_personalization_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/reminder/application/reminder_personalization_test.dart) | 284 | 27 |
| [test/features/reminder/application/reminder_provider_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/reminder/application/reminder_provider_test.dart) | 631 | 24 |
| [test/features/reminder/presentation/widgets/reminder_invitation_card_large_text_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/reminder/presentation/widgets/reminder_invitation_card_large_text_test.dart) | 212 | 9 |
| [test/features/reminder/presentation/widgets/reminder_invitation_card_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/reminder/presentation/widgets/reminder_invitation_card_test.dart) | 236 | 7 |
| [test/features/settings/application/first_name_provider_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/settings/application/first_name_provider_test.dart) | 180 | 23 |
| [test/features/settings/presentation/first_name_question_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/settings/presentation/first_name_question_test.dart) | 688 | 53 |
| [test/features/settings/presentation/settings_page_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/settings/presentation/settings_page_test.dart) | 525 | 16 |
| [test/features/settings/presentation/you_b7_hierarchy_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/settings/presentation/you_b7_hierarchy_test.dart) | 188 | 3 |
| [test/features/settings/presentation/you_c1_real_font_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/settings/presentation/you_c1_real_font_test.dart) | 251 | 20 |
| [test/features/settings/presentation/you_c1_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/settings/presentation/you_c1_test.dart) | 403 | 14 |
| [test/features/settings/presentation/you_first_name_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/settings/presentation/you_first_name_test.dart) | 551 | 26 |
| [test/features/settings/presentation/you_north_star_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/features/settings/presentation/you_north_star_test.dart) | 680 | 50 |
| [test/main_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/main_test.dart) | 37 | 2 |
| [test/widget_test.dart](https://github.com/thirtyapp/Thirty/blob/e935112c408c16d99835280f4e1fafd722d47ed1/test/widget_test.dart) | 73 | 2 |
| **Total: 179 files** | **59,699** | **2,599** |

