# THIRTY — INDEPENDENT POST-R8.3 DELTA AUDIT

**Audit date:** 7 November 2026.  
**Target:** `thirtyapp/Thirty`, `step5-billing-integration`, immutable commit `9c910773d7bfd3961be75fe3c9a44db41a1b7b27`.  
**Verdict: FAIL. R8.3 + R8.3.1 cannot yet be accepted as the technical engineering baseline. Phase E remains HOLD.**

The committed regression evidence is internally consistent and matches the committed source manifest. Several specific R8.2 defects are repaired. Nevertheless, the new paused-Start record has two source-established failure paths, and the claimed safe fallback after overwriting Insight provenance is not implemented for a snapshot that becomes current again. These prevent baseline acceptance independently of commercial-release authorization.

**Execution boundary:** Flutter and Dart were unavailable. No Flutter application test, new Flutter reproduction, analyzer run, or device test was executed by this audit. Application findings below are identified as source-established traces or bounded risks. Recorded Flutter results were independently parsed and reconciled; they are not presented as fresh executions.

**L-1 remains OPEN — PRE-RELEASE BLOCKER. NOT FIXED. NOT WAIVED.**

## 1. Verified immutable target and inventory

| Item | Independently verified value |
| --- | --- |
| Repository | `thirtyapp/Thirty` |
| Observed remote branch | `step5-billing-integration` at the requested target when acquired |
| Target commit | `9c910773d7bfd3961be75fe3c9a44db41a1b7b27` |
| Sole parent | `e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8` |
| Git tree | `2480747c36b376189242661d572cbbf467c3ba83` |
| Exported blobs checked against Git object IDs | 1,903 |
| Changed committed paths against parent | 241: 15 production, 10 test/support, 2 audit documents, 214 artifacts |
| Declared commit-path inventory | Exact match; no duplicate paths |
| Source/config blob manifest | 380 entries; exact match to the committed `lib/`, `test/` and three listed root configuration files |
| Blob-manifest SHA-256 | `39df9804a9d906452974c2eb3739c1326eb7ca4245db9cfb410b6c4a4f96949b` |
| Git object integrity | `git fsck --full --strict`: exit 0, no errors |

The source was obtained from Git and exported with `git archive` at the full SHA. The implementer's working directory was neither used nor audited. All source references in this report resolve to this immutable commit. The 241-path comparison is against the expected parent, not against the historical uncommitted R8.3 intermediate state.

The 15 changed production files are:

```text
lib/core/analytics/analytics_consent.dart
lib/core/analytics/tester_identity_provider.dart
lib/features/home/application/circle_history_deletion.dart
lib/features/home/application/first_breath_provider.dart
lib/features/home/application/recommendation_provider.dart
lib/features/home/application/suggestion_preferences.dart
lib/features/home/application/v1_premium_retirement.dart
lib/features/insights/application/insights_provider.dart
lib/features/plans/application/circle_plans_provider.dart
lib/features/plans/domain/circle_plan.dart
lib/features/premium/application/premium_offer_provider.dart
lib/features/premium/presentation/widgets/premium_offer_invitation_card.dart
lib/features/reminder/application/reminder_invitation_provider.dart
lib/features/reminder/application/reminder_provider.dart
lib/features/reminder/presentation/widgets/reminder_invitation_card.dart
```

The test delta adds eight R8.3/R8.3.1 test files and `r83_invariants.dart`, and modifies `r8_fault_disk.dart`. No existing application test file was modified in this commit. The two document additions are the original independent post-R8.2 reports. The complete independently reconciled inventory is [COMMIT_PATHS.txt][inventory].

## 2. Methodology and evidence confidence

The review covered the full [handoff][handoff], both original [Astra][astra82] and [Claude][claude82] post-R8.2 audits, the [pre-R8.3 architecture review][architecture], the [issue register][register], [founder decisions D1–D5 and Option B][decisions], R8.3/R8.3.1 implementation evidence, final regression raw logs, source manifests, limitations, and the relevant frozen product and ADR provisions. The issue register and implementation descriptions were treated as claims.

The source review followed the call chains between Today, Plans, History, Preferences, Insights, deletion coordination and entitlement checks. Particular attention went to optimistic versus confirmed state, the order of asynchronous continuations, process-loss boundaries, and what information survives serialization. Passing tests were checked for what they actually assert.

| Evidence class | Meaning and confidence |
| --- | --- |
| Executed audit control | Git/object checks, independent Python parsing, manifest reconciliation and evidence-validator mutations run here. High confidence in their reported output. |
| Verified recorded test | A committed Flutter raw log reconciled to its manifest, test inventory and summaries. High confidence in the record's internal consistency; not independent proof that the real device behaves the same way. |
| Source-established defect | A concrete reachable sequence follows the target's guards, writes and continuations. High confidence in the code-level contradiction; Flutter scheduling/device reproduction remains unexecuted. |
| Bounded risk or observation | A structural limitation, malformed-input behavior or hypothetical replay whose full UI reachability is not established. Not promoted to an executed or demonstrated production failure. |

The three input-document hashes were independently recomputed:

| Input | Bytes | SHA-256 |
| --- | ---: | --- |
| Original Astra post-R8.2 audit | 99,572 | `a6f5984b0681bb375a407e450de277ce0a29912105d096943006096ca35e9e43` |
| Original Claude post-R8.2 audit | 58,126 | `2fc8766eb1916758e6bf369261e168da622fb00abb4af12a1f64ac457932cc8f` |
| Pre-R8.3 architecture review | 50,004 | `bfb9acfab9419a546f05eb4894dc0bf116864f488749fe04e2cfae6740eb7581` |

No production changes, permanent repository test changes, staging, commits, pushes, migrations or deployments were made. Audit scripts and disposable evidence copies were outside the immutable source export. A final integrity check confirmed that all 1,903 exported blobs still matched the target and that no extra source files had been introduced.

## 3. Prior-finding closure matrix

“FIXED” below refers to the identified defect within its stated scope, not universal correctness of the containing subsystem. Recorded tests are committed evidence, not executions by this audit.

| Finding | Status | Independent source/evidence assessment | Residual or new risk |
| --- | --- | --- | --- |
| Astra R82-N01: I1/I2 repeated after manual reversal | **PARTIAL** | `apply` now checks exact retained provenance for both current and stale snapshots before invoking an action. `_markApplied` uses the original date. The original Pause/Leave and Stop Gentler cases are repaired, supported by the 10-case attribution file and original auditor controls. [Insights 317–397][insight-apply] | A later Insight can overwrite that one provenance slot. If the old unmarked snapshot is current again, the code invokes it again. **R83-N03**; the L-2 description is too strong. |
| Astra R82-N02: queued manual I3 falsely attributed | **FIXED** | `apply` waits for Preferences; `_leaveOut` distinguishes `changed` from `unchanged/refused/notSaved`. An unchanged manual exclusion is not marked as this Insight's application. [Insights 317–320, 469–486][insight-i3]; [Preferences 396–460][preferences-change] | The new result type is useful, but its `unchanged` outcome is also used to hide an unreadable-record Delete step; that separate misuse is L-1. |
| Astra R82-N03 / Claude AUD-N1: expiry flag persists and blocks legitimate credit | **FIXED** | Serialization removes all known fields from retained `source` before emitting the current values. A model value of `false` can no longer inherit an old stored `true`; nested stage extensions remain preserved. [Codec 765–786][served-codec]. Covered by codec and original controls. | This repair concerns the expiry flag. It does not repair the new, independently sticky `startedWhilePaused` marker. |
| Astra R82-N04: AppliedInsight extension loss | **FIXED** | `AppliedInsight.fromJson` captures non-known fields; `toJson` writes them back. Ordinary Plan changes preserve the object. A new attribution deliberately creates a new record. [AppliedInsight 644–690][applied-codec] | Unknown-field retention is not a history of prior Insight applications; L-2 remains a separate information-loss problem. |
| Astra R82-N05: pending Start after midnight | **FIXED** | `_startOnceSaved` checks identity, status and the live local date after prerequisite waits, and repeats the checks after the new eligibility write. [Today 1886–1934][start-wait]. The nine Start-boundary cases support the old defect's closure. | Temporal revalidation does not bind the new marker to a completed Start attempt. R83-N01/N02 remain. |
| Claude AUD-N2: timestamps reused after Delete | **FIXED** | `forgetStageEvidence` immediately clears both `_startedAt` and `_closeRequestedAt`. A same-day new session no longer inherits those old action-order maps. [Plans 943–945][delete-plan] | The new paused-Start field is also erased by the domain deletion. No distinct new same-day timestamp leak was established. |
| Claude AUD-N3: Delete saves an optimistic Plan change | **FIXED** | The deletion write computes `_durable.forgetStageEvidence()` at its own queue turn. A preceding failed write is not promoted by Delete; a preceding confirmed write is retained without evidence. The matching shown state is reconciled afterward. [Plans 943–986][delete-plan] | This is a correction of Delete's capture point, not a claim that every optimistic Plan transition is transactional. |
| R83-F1: retroactive credit after paused Start | **PARTIAL** | The normal Option B table, two restarts, next-day catch-up, stage 5, lapse and other-Plan controls are supported by 24 recorded passing tests. `recordGuided` rejects the remembered Circle ID before any lifecycle branch. [Domain 1148–1186][credit-domain] | Marker persistence and Start are not one recoverable fact. R83-N01 loses legitimate credit; R83-N02 permits a paused Start without durable exclusion and later false credit. |
| D1 | **PARTIAL** | Readable Preferences retain user choices and lose `byInsight`, including unreadable individual items within a readable record. Queue ordering and interrupted-Delete recovery are present. [Delete][delete-flow]; [Preferences][preferences-forget] | **L-1 OPEN**: wholly unreadable records survive a successful Delete and are omitted from Export. |
| D2 | **PARTIAL** | The ordinary pending-offer and Pause-before-valid-Start paths now respect the prerequisite wait and recorded lifecycle table. | `startNeedsNoWrite` can accept an optimistic paused-Start marker after provider rebuild. R83-N02 violates the durable prerequisite. R83-N01 records eligibility before a Start exists. |
| D3 | **PARTIAL** | Exact provenance is checked first and its original date retained when that provenance still exists. | R83-N03 repeats an earlier action after another Insight overwrites provenance. |
| D4 | **FIXED** | Same verified correction as AUD-N3. | No fresh Delete promotion of the held, failed Plan write was established. |
| D5 | **FIXED, native-type scope** | The identified startup/first-frame getters inspect native values before using them. Wrong-native-type values are not default-overwritten at those sites. Fifteen recorded startup tests support this. | This is not a guarantee for every semantically unknown string; see §7 observations. |
| E-1: raw reporter validation | **FIXED** | Final source reads and validates raw reporter events and hashes rather than trusting only summary claims. This audit executed the corruption challenge against disposable copies: all 16 damaged cases were rejected by the report validator. | Evidence consistency is not test adequacy or device recovery proof. |

## 4. Six-invariant assessment

| Invariant | Assessment | Reason |
| --- | --- | --- |
| 1. Durable confirmation | **PARTIAL** | Preference changes distinguish confirmed mutation from a no-op; Delete now uses confirmed Plans. But Start's fast predicate compares the durable served record while overlooking whether the new paused-Start marker itself is durable. R83-N02. |
| 2. Exact attribution of Insight actions | **PARTIAL** | I3 no longer claims a queued manual change, and intact I1/I2 provenance repairs only the mark. The single Plan provenance slot cannot support the unconditional D3 promise after overwrite. R83-N03. |
| 3. Idempotent retries and restart recovery | **PARTIAL** | Credit deduplication and existing queue/replay safeguards remain. An orphan marker survives a pre-Start crash and denies a subsequent valid active Start; overwritten Insight provenance can permit reapplication. R83-N01/N03. |
| 4. Temporal validity after asynchronous waits | **PARTIAL** | The local-midnight fix is sound for the reviewed paths. Identity/status/day are rechecked after the eligibility write, but there is no matching commit/cancellation resolution for the eligibility fact itself. Lifecycle changes during that wait are not re-evaluated. |
| 5. Serialization fidelity and unknown fields | **IMPROVED; BOUNDED PASS for the targeted codec fixes** | The expiry known-field overwrite rule and AppliedInsight extension retention are repaired. The new marker is only type-checked as nullable String, not validated as a canonical Circle ID. See §7. Unknown Preferences are preserved rather than destroyed, but remain inaccessible to Export. |
| 6. Complete and truthful Delete | **PARTIAL — OPEN BLOCKER** | The corrected readable-record queues, timestamps and durable Plan snapshot materially improve deletion. L-1 still reports completion while history-derived attribution remains durable and absent from Export. |

The architecture is still a bounded set of local stores with explicit write ordering; no database rewrite is required by this audit. Its unresolved issue is the identity and durability of facts crossing providers. The new eligibility fact sits outside the served-record object checked by older confirmation helpers. Naming both operations “Start confirmation” does not make them validate the same data.

The test helper reinforces this distinction: [`DurableState.always()`][oracle] runs round-trip and off-day checks, not all six invariants. It does not establish that each persisted paused marker corresponds to an actual valid Start, or that every valid paused Start has such a marker. The attribution helper also cannot, by itself, prove historical attribution after a one-slot record has been replaced.

## 5. R83-F1 historical-credit assessment

### What the new record correctly does

`PlanProgress.startedWhilePaused` survives replacement of `lastServed`. This matters because the next day's serve can replace that object before `_recordBeforeOverwrite` catches up the preceding day's Close. The unconditional rejection in `recordGuided` prevents Resume, another Pause, and an ordinary restart from converting the remembered paused Circle into an earned stage.

Valid **Start → Pause → Close** remains supported: the Start is recorded in the action-order map, Pause stamps the matching served record, and `recordGuided` accepts the same Start instant once the Close is durable. The marker is absent because that Start occurred with an active Plan. The committed table test verifies one credit across subsequent restarts. **Start → Close requested → Leave during saving** likewise retains the original-cycle credit under the existing Close stamp. These controls should remain mandatory.

### Single-slot capacity: what is and is not established

The slot is not a complete historical identity record. It remembers one Circle ID without a Start instant, attempt identifier or resolution state.

For the current ordinary forward-day flow, there is a meaningful sequencing defense: new-day publication awaits `_recordBeforeOverwrite`, Today serializes its writes, and a subsequent valid Start waits for its offer. Thus an unresolved previous-day Close is processed before the second paused Start can replace the marker. Ordinary restart catch-up reads the retained day keys; the lifecycle fold examines the current `lastServed`, not every historical journal entry. [Publication/replay 887–988][publish]; [catch-up 1066–1193][catchup]; [fold 406–451][fold].

That defense is narrower than a permanent historical prohibition. A precise **domain-level counterexample** is:

1. Plan P's current cursor is stage 1. Circle A of that stage starts and closes while P is paused; marker = A and no credit.
2. On another day, P is resumed to offer Circle B at the same unadvanced stage, paused, and B starts and closes; marker = B.
3. P is active again. Replay A's original durable Close through `recordGuided`, with the same cycle and stage 1.
4. A is no longer the marker, has no earlier credit record, and the active-current-cycle branch admits it. Stage 1 advances incorrectly.

**Classification:** source-level capacity counterexample; not an executed reproduction and not a demonstrated ordinary UI/restart route. I did not establish a current production caller that performs step 3 after the normal publication barrier has resolved A. It would be incorrect to label the bare domain replay a proven multi-day app regression. Conversely, the one-slot field alone cannot prove the universal historical guarantee. Any future wider journal replay must preserve the exclusion identity or prove the same bound explicitly.

The concrete baseline blockers do not depend on that speculative older replay: R83-N01 and R83-N02 occur with one Circle on one day.

| Requested challenge | Assessment |
| --- | --- |
| Multiple consecutive days and earlier pending Closures | Current serialization gives the bounded defense above. The committed next-day test covers one paused Circle followed by an eligible Circle; it does not execute the two-paused-Circle replay counterexample. |
| Restart after another Circle was offered | Keeping the marker on PlanProgress rather than `lastServed` is appropriate for this exact case; the next-day test and source support it. |
| Resume during eligibility write | Eligibility is sampled before awaiting the write; afterward only identity/status/day are checked. An active Plan at the actual transition can still receive a paused marker. See R83-N01 and §8's unexecuted variant. |
| Another Plan started during the pending operation | If the original Plan is already paused when eligibility is sampled, the marker records it. The settled before/after Start cases have recorded controls. No separately executed overlap test proves every pending interleaving; the refresh defect still applies. |
| Partial write or lost acknowledgement | If the marker lands and the process stops before the Start transition, the record becomes an orphan. R83-N01. Normal write rollback is not enough when the process stops before rollback. |
| Failed write followed by retry | The simple failure-then-retry case is covered and correctly refuses the first Start. A retry after a rebuild while the first write remains pending bypasses the intended wait. R83-N02. |
| Premium lapse/resubscription | The explicit expiry flag remains separate. Recorded controls show paused Start remains uncredited after resubscription and an eligible pre-lapse Start retains the served exception. No new billing-authority bypass was established. |
| Stage 5 | The marker check precedes stage-end processing. A correctly recorded paused Start cannot end the cycle. A valid Start before Pause can still end it under the existing policy. Marker errors can still withhold or manufacture progress. |
| Delete and same-day new sessions | `forgetStageEvidence` removes the marker and both in-memory action timestamps. The coordinated deletion prevents ordinary pre-Delete continuations from committing after success. No distinct new leak was established for readable records. |
| Serialization/malformed values | Nullable String round-trips, non-string values make the Plan unreadable, and future fields survive. Empty/noncanonical strings are accepted and never match a canonical Circle ID; this is weaker than “any damaged marker makes the Plan unreadable.” |

**R83-F1 conclusion: PARTIAL.** The settled founder table is repaired; the historical eligibility invariant is not established across the new marker's own asynchronous and recovery boundaries.

## 6. Founder decisions D1–D5

The controlling authority is the consolidated [founder-decision record][decisions], including the explicit 7 November Option B decision. The earlier R83-F1 decision-request document does not override it.

- **D1 — PARTIAL:** readable preferences lose Insight attribution while retaining the user's exclusion, identity, date and other metadata. Wholly unreadable records violate the requested completed-Delete outcome. L-1 remains open.
- **D2 — PARTIAL:** the original pending-offer boundary is improved; Start is not supposed to become valid on a mere tap. R83-N02 makes a pending, unconfirmed eligibility change appear sufficient after rebuild. R83-N01 records a supposed valid paused Start before one has happened.
- **D3 — PARTIAL:** intact exact provenance repairs the original applied date without repeating the action. The overwrite sequence in R83-N03 re-enables the action instead of safely refusing it. A later manual Stop Gentler can consequently be undone by retry.
- **D4 — FIXED:** the corrected Delete write uses confirmed Plans at queue execution, including a prior write only if that write actually succeeded.
- **D5 — FIXED within the authorized wrong-native-type startup scope:** V1 retirement, reminder state, analytics consent, tester identity/cohort, First Breath and invitation flags no longer rely on unsafe typed reads at those sites. Defaults do not overwrite unexpected native types. A fresh First Breath date after an actual play is a new fact, not a default overwrite. Unknown string values are a separate scope caveat below.

## 7. Newly discovered defects and bounded observations

### R83-N01 — Orphan paused-Start evidence suppresses a later legitimate Start

**Severity: MEDIUM. Engineering baseline blocker. Introduced by R8.3.1.**  
**Evidence:** source-established recovery sequence; Flutter reproduction unexecuted.

The marker is persisted before `RecommendationStatus.started` and `startedAt` exist. It contains only the day/Circle ID. No recovery code distinguishes a completed paused Start from an abandoned prerequisite write; an active Start does not clear or supersede it.

**Exact sequence:**

1. Offer Circle C for active Plan P and let the offer and served record become durable. Pause P and let that save complete.
2. Tap Start. `_startOnceSaved` reaches `noteStartWhilePaused`; its Plan write lands.
3. Stop the process after that write lands but before its acknowledgement/continuation. Day keys still describe an unstarted offer; there is no valid paused Start.
4. Restart from stored bytes, resume P, and Start C with active Premium while P is active. This is C's first actual valid Start. Close it durably.
5. The old marker remains C. `recordGuided` returns immediately and withholds the owed credit. Repeated restart does not repair it.

**Source chain:** [marker write 790–806][marker-write] → [await then later Start assignment 1913–1941][start-wait] → [copyWith retains marker 543–557][progress] → [active Start creates no new marker 1295–1311][marker-domain] → [unconditional denial 1159–1160][credit-domain].

The committed fault harness can express the exact stop point with `ackLost(circlePlansKey, thenStop: true)`. This is a proposed reproduction, not an execution. The defect does not rely on assuming that a failed write committed: the precondition explicitly specifies that the platform write landed before process loss.

There is also a same-process cancellation route: hold the marker write, refresh `nowProvider` on foreground resume, release the write successfully, and let the original continuation fail its recommendation-identity check. It leaves an unstarted offer plus the durable marker. A subsequent Resume and valid active Start still receives no credit.

**Resume during a successful held write:** the implementation records the pre-wait paused state even if P becomes active before the actual Start transition. Under D2/Option B's valid-Start boundary, this deserves its own regression. No documented founder exception authorizes moving eligibility back to the earlier tap or pre-confirmation sample. The orphan-after-restart case above establishes the defect even without resolving that linearization interpretation.

**Required acceptance property, not an implementation:** recovery must distinguish an eligibility preparation from the actual Start it belongs to, and a failed/cancelled attempt must not poison a later valid attempt. Do not fix this by blindly clearing all paused markers when a Plan resumes; that would recreate R83-F1.

### R83-N02 — A resumed app can start on an optimistic, unconfirmed paused marker

**Severity: MEDIUM. Engineering baseline blocker. Introduced by R8.3.1.**  
**Evidence:** source-established asynchronous sequence; Flutter reproduction unexecuted.

`startNeedsNoWrite` asks whether applying the paused marker to the **shown** Plan would change it. If an earlier write already placed that marker in optimistic state, the answer is “no change.” Its subsequent durable comparison serializes only `lastServed`; the marker is outside that object. `_settleStart` and later `_persist` also check only the served record/expiry state.

**Exact sequence:**

1. Offer C durably; pause its Plan durably.
2. Hold the `circlePlansKey` write triggered by Start's new marker. The shown Plan contains marker C; the confirmed Plan does not. Today is still `notStarted`.
3. Background/foreground the app, or equivalently advance the event clock within the same day and invalidate/read `nowProvider`/Today. `build` restores the unstarted offer and clears `_startWaiting`; the durable offer identity remains recognized.
4. Tap Start again before releasing the held write. The optimistic marker makes `noteStartedWhilePaused` a no-op, and the unchanged served record matches the confirmed one. The fast path changes Today to `started` before the marker is confirmed.
5. Release the first marker write with `returnsFalse`. The Plan rolls back to its confirmed paused state without the marker. The first Start continuation reports a refusal, but it does not roll back the second Start's state.
6. The queued second Start persists through `_persist`, which reconfirms the served/expiry record but not the paused marker. Close durably while paused. Resume the Plan, then restart so catch-up runs: the now-active Plan can credit C because its historical exclusion was never stored.

**Source chain:** [real resume invalidates time 65–80][app-resume] → [Today rebuild resets `_startWaiting` 1014–1039][today-build] → [incomplete fast predicate 717–743][fast-start] → [fast Start assignment 1764–1808][start-fast] → [served-only comparison 751–819][settle-start] → [later persistence 2692–2706][persist-start] → [active credit branch 1175–1186][credit-domain].

The first violation is already visible at step 4: Start has become valid without its new prerequisite. The later false-credit outcome additionally follows the rollback and catch-up path. This is not merely the accepted lack of a “starting” indicator or an ordinary second-tap suppression issue.

**Required acceptance property:** both fast and waiting paths must establish the same durable eligibility fact, and provider rebuilds must not convert an in-flight preparation into confirmation. Controls must exercise both success and failure of the held write.

### R83-N03 — Overwritten provenance permits an old Insight to repeat its action

**Severity: MEDIUM. Engineering baseline blocker for D3 closure. Inherited information-capacity defect, not newly introduced storage behavior.**  
**Evidence:** source-established multi-Insight sequence; Flutter reproduction unexecuted.

L-2 says an older unmarked Insight whose provenance was overwritten is reported unavailable and never applied. The code only does that when the snapshot is **stale**. A **current** snapshot without matching provenance falls through to the action switch.

**Concrete sequence using the existing I2 fixture and real cadence rules:**

1. On 30 October, P = `getting_going` is active in the same cycle. Five stage offers at ages 2, 5, 9, 13 and 17 days include three “tooMuch” replacements, so I2 qualifies.
2. Apply I2. The gentler setting and I2 provenance save successfully; the Insights applied-mark write fails.
3. The user manually turns gentler off and pauses P. Those saves succeed.
4. Seven days later, the five More Energy records are still inside the 28-day window, spanning at least 14 days. With P paused, I1 for that need can be generated; the ordinary seven-day cadence permits it. Apply I1 to resume P. Its provenance replaces I2's slot, and its own mark saves.
5. The original I2 remains unmarked. P is active, the same cycle is not gentler, and the same stage-offer evidence remains, so I2 is current again.
6. Retry I2. `_appliedOn` finds I1, returns null; the current branch falls through; `_gentler` re-enables gentler and marks I2 with the retry date. The user's later manual Stop Gentler has been overridden.

**Source:** [current/stale dispatch and `_appliedOn` 317–397][insight-apply]; [gentler mutation 436–459][insight-gentler]; [single-slot attribution 382–392][insight-slot]; [I1/I2 qualifying evidence 280–370][insight-qualify]; [current status 614–643 and cadence 713–719][insight-status]; [L-2's incompatible claim][limitations].

This extends the exact original manual-reversal reproduction: R8.3 repairs it while the original provenance survives, but not after another legitimate Insight overwrites that slot. A missing marker alone cannot distinguish “never executed” from “executed, acknowledgement lost, provenance superseded.”

**Required acceptance property:** an already-executed old action must remain distinguishable from an unapplied one, or the ambiguous retry must safely decline. The report does not prescribe a migration or authorize remediation.

### Additional observations — not conflated with the three blockers

| Observation | Classification | Exact consequence |
| --- | --- | --- |
| `startedWhilePaused` accepts `""` and non-date strings | LOW, new input-robustness gap; source-verified, malformed-input case | `PlanProgress.fromJson` only rejects non-null non-strings at lines 608–611. An impossible Circle ID behaves like no matching exclusion. The committed malformed-value test exercises `42`, not malformed strings. Do not claim all damaged values fail closed. [Parser][progress] |
| Unknown analytics cohort string can be overwritten by a default | LOW, inherited scope caveat; source-verified | `tester_identity_provider.dart` lines 74–87 preserves wrong native types but explicitly writes a derived cohort when the unrecognized raw value is a String. A future enum value is not protected. D5's native-type fix is real; a broader “all unexpected stored values are preserved” claim is not. [Cohort][cohort] |
| Single paused-Circle slot cannot independently prove arbitrary historical replay safety | Bounded architectural risk | Precise two-Circle domain counterexample in §5. Ordinary production replay of the older Close after the second paused Start was not established. Not counted as an additional demonstrated UI defect. |
| Generic durability helpers do not include the new eligibility fact | Source-established hidden coupling | R83-N02 is the concrete manifestation. The served-record JSON boundary predates the separate PlanProgress marker. |

No new entitlement-granting bypass, kept-content confiscation, audio change or additional readable-record Delete resurrection was established in the reviewed delta. That statement is bounded by the lack of runtime and device execution.

## 8. Executed adversarial reproductions and unexecuted application recipes

### Executed here

The E-1 corruption exercise used the committed raw-evidence checker against disposable copies of historical evidence. Because recorded paths are Windows paths and this audit ran on Linux, only path-to-test-root normalization was adapted; validation logic and original artifacts were unchanged.

| Evidence mutation | Report validator outcome |
| --- | --- |
| Intact control | ACCEPTED |
| Declared split part missing | REJECTED |
| Split summary replaced by another part | REJECTED |
| Undeclared extra split part | REJECTED |
| Summary terminal success falsified | REJECTED |
| Test file omitted from summary | REJECTED |
| Summary command changed | REJECTED |
| Split raw log emptied | REJECTED |
| Split raw log deleted | REJECTED |
| Ordinary raw log emptied | REJECTED |
| Ordinary log truncated before terminal `done` | REJECTED |
| Ordinary log truncated halfway | REJECTED |
| Split raw log replaced with another part's | REJECTED |
| Ordinary raw log replaced with another batch's | REJECTED |
| Passed raw test changed to failure | REJECTED |
| Raw test completion duplicated | REJECTED |
| Second terminal `done` appended | REJECTED |

**Result: 17 scenarios, comprising one intact control and 16 corruptions; all expected report outcomes obtained. Historical source evidence unchanged.** The narrower `cases` subcommand rejected corruption of the split profile evidence it owns and accepted unrelated ordinary-batch damage; the overall `report` command rejected every damaged case. This is expected division of responsibility, not a claim that each subcommand checks all evidence.

An independent Python parser, separate from the implementer's report summaries, also read all final raw logs, joined suite/test-start/test-done events, reconciled the inventory and terminal results, verified the raw SHA-256 values, and counted the cases reported in §9.

### Not executed here

**Flutter reproductions executed by this audit: 0. Full Flutter suite rerun: no. Analyzer rerun: no.** The following are concrete reproduction recipes derived from the source, not test results:

| Recipe | Fault/order | Contract outcome | Source-predicted target outcome |
| --- | --- | --- | --- |
| N01-A | Durable offer; Pause; `ackLost(circlePlansKey, thenStop: true)` at marker write; restart; Resume; Start; Close | One credit for the first valid active Start | Zero credits; orphan marker survives |
| N01-B | Hold marker write; advance same-day clock; invalidate/read time and Today; release success; Resume; new Start; Close | Cancelled first attempt must not determine later Start eligibility | Zero credits from marker left by cancelled continuation |
| N01-C | Hold marker write; Resume while held; release success; Close | Eligibility tied to the actual valid Start boundary, with any different linearization explicitly authorized | Marker still describes pre-wait paused state; no lifecycle recheck |
| N02 | Hold marker write; same-day provider rebuild; second Start before release; release false; Close; Resume; restart | No Start until marker confirmed; paused Start never later credited | Second Start appears early; rollback removes marker; later active catch-up can credit |
| N03 | I2 action succeeds/mark fails; manual Stop Gentler + Pause; seven days; I1 resumes same Plan; retry old current I2 | No repeated I2 mutation | Gentler re-enabled and retry date recorded |
| Single-slot domain probe | Two paused Starts A/B in same unadvanced cycle, then active replay of A | A stays uncredited | Domain accepts A; current UI route to that replay unproven |

For N01/N02, use the committed `offered()` setup from [r831_start_eligibility_test.dart][r831-test], keep Premium active, and inspect **both** confirmed disk data and shown provider state. Advancing the clock within the same day before invalidation avoids a no-change clock value masking the rebuild. For N03, the existing `i2` fixture in [r83_insight_attribution_test.dart][attribution-test] provides the evidence ages listed above. These instructions were not inserted into the repository.

Required controls include normal Start → Pause → Close = one credit; Pause → Start → Close → Resume = zero; held-marker success versus failure; repeated restarts; no Start or Close made durable = no invented credit; and same-day Delete followed by a genuinely new session.

## 9. Full regression evidence verification

The authoritative final run is [R8.3.1 `regression/`][regression]. Earlier R8.3 results and incomplete attempts were not combined with it.

| Reported claim | Audit result |
| --- | --- |
| 201/201 test files | **Verified.** Exact source test-file inventory covered, including split handling of the year-long file. |
| 2,872 passed | **Verified in raw events.** No duplicate file/test pair counted. |
| 0 failed, 0 skipped | **Verified for the final regression.** |
| Terminal success | **Verified.** All 23 final logs have the expected start/terminal structure and successful final `done`; per-batch summaries record exit 0. |
| 13 year-long profiles | **Verified once each:** p01–p11, p13, p14. There is no source-declared p12 in this inventory. |
| B8 6/6 | **Verified.** Four behavioral profiles, one voice case and the aggregate/report case; not six separate year-long user profiles. |
| `flutter analyze` clean | **Committed evidence verified:** “No issues found! (ran in 5.7s)”, exit 0. Not rerun here. |
| 180 unchanged audio assets | **Verified:** 172 production files plus eight framing files; hashes match manifests, no parent-to-target asset changes. |
| 380 source/config blob entries | **Verified.** Exact target-tree objects; start/end blob manifests identical. |
| 241 committed paths | **Verified.** Exact parent-to-target inventory. |

Per-batch pass counts independently recovered from the final logs:

| Batch | Passes | Batch | Passes | Batch | Passes |
| --- | ---: | --- | ---: | --- | ---: |
| 01 | 76 | 09 | 164 | 17 | 117 |
| 02 | 99 | 10 | 267 | 18 | 6 |
| 03 | 121 | 11 | 187 | 19a | 3 |
| 04 | 157 | 12 | 282 | 19b | 3 |
| 05 | 88 | 13 | 159 | 19c | 3 |
| 06 | 226 | 14 | 142 | 19d | 2 |
| 07 | 241 | 15 | 153 | 19e | 2 |
| 08 | 154 | 16 | 220 | Total | **2,872** |

New-test breakdown:

| File under `test/features/r83/` | Recorded passes |
| --- | ---: |
| `r831_start_eligibility_test.dart` | 24 |
| `r83_codec_law_test.dart` | 14 |
| `r83_cross_store_test.dart` | 4 |
| `r83_delete_boundary_test.dart` | 12 |
| `r83_harness_selftest_test.dart` | 10 |
| `r83_insight_attribution_test.dart` | 10 |
| `r83_start_boundary_test.dart` | 9 |
| `r83_startup_types_test.dart` | 15 |
| Total | **98** |

The preflight/start/end SHA-256 source fingerprints agree. Compared with this LF Git export, 237 entries match the original bytes directly and 143 match the documented CRLF checkout form; there are zero unexplained differences. This is why a Windows fingerprint and an LF export should not be rejected merely for differing line endings. The Git-blob comparison independently binds all 380 entries to the target tree.

The historical evidence is also coherent: the 24-case R8.3.1 file records 13 passes and 11 failures on both the R8.2 export and the pre-R8.3.1 R8.3 tree. The R8.2 raw file additionally includes six D2 probes, explaining its aggregate 16 successes/14 failures. The old R8.3 test set has 74 passes after that implementation; the final set has 98. The earlier 2,848-pass full run is pre-R8.3.1 evidence, not the final target total.

Original-auditor control runs are **not entirely green**: the R8.3.1 control log has 30 successful cases and five non-successes, comprising three errors and two assertion failures in obsolete R8.1 originals. The three errors assume a refused offer still exists and null-assert it; the two assertions reject a date that now legitimately remains in Plan place/gentler metadata after stage evidence has been erased. The original Astra R8.2 Appendix B cases and Claude AUD-N1/N2/N3 controls pass. This explains the documented obsolete failures without reclassifying those raw outcomes as passes or adding them to the final 2,872.

**Evidence adequacy:** strong reproducibility bookkeeping, meaningful fault simulations, and credible closure evidence for the original narrow cases. It does not cover the newly identified orphan marker, rebuild-during-marker, or overwritten-provenance/current-again sequence. The 13 long-horizon simulations remain architectural checks, not real user retention or willingness-to-pay evidence.

## 10. L-1 — OPEN, privacy/data integrity and baseline consequences

**Status: OPEN — PRE-RELEASE BLOCKER. NOT FIXED. NOT WAIVED.**

The source confirms the [L-1 assessment][l1]: a future-schema record, malformed list field or non-JSON Preferences record is read as empty. Both the normal deletion helper and startup helper leave the opaque record unchanged. Normal Delete treats that as no work and removes the deletion-intent marker. Export serializes only the decoded, apparently empty Preferences model and therefore omits the record. [Preferences 359–385, 566–576][preferences-forget]; [Delete 190–220, 285–311][delete-flow]; [Export 90–103][export].

**Privacy consequence:** the app can announce deletion while a local durable record still contains an Insight identifier derived from the history the user requested to remove. Such identifiers can carry family/date/subject information. The deleted journal itself is not thereby shown to survive, and no network disclosure was established. Nevertheless, retained bytes remain available to storage inspection or any later reader capable of interpreting the record. The inaccessible Export makes the discrepancy difficult for the user to discover or preserve before an intentional Reset.

**Application consequence:** the current decoder does not apply the opaque content to recommendation selection, Plan stage 5 or Insight evidence. That narrow statement is supported. A broader statement that it has no effect on application decisions is inaccurate: `_storedUnreadable` refuses ordinary preference mutations until Reset. Future recognition or restore of the record is a residual reactivation risk, not an observed current-build recommendation leak.

**Scope and severity:** the documentation correctly identifies an unresolved Delete/Export contract violation and a release blocker. The absence of a current legitimate writer for such a record does not waive it: corruption, downgrade/restore and future-schema preservation are explicitly within the design being defended. The audit does not claim that arbitrary non-JSON text can be safely selectively redacted.

**Technical baseline:** L-1 prevents an unconditional assertion that all six invariants or D1 are satisfied. An explicitly incomplete internal engineering milestone could carry it as a named release blocker; that would be a conditional milestone, not a fix or waiver. This target fails baseline acceptance independently because of R83-N01/N02/N03, even if L-1 is treated as an authorized scope deferral.

**Safe pre-release remediation requirements:**

1. Preserve opaque user-owned data exactly; do not guess at a future schema or silently destroy preferences.
2. Export the unreadable record in a clearly labeled, lossless form, preserving its stored native type where relevant.
3. Report an incomplete/unverified Delete disposition truthfully while history-derived residue cannot be ruled out. Do not show ordinary full-success copy.
4. Persist the unresolved disposition across restart, or provide an equally explicit durable contract; a future compatible reader must not silently reactivate supposedly deleted provenance.
5. Where a schema is actually understood, remove only authorized history-derived fields and retain user choices. A destructive Reset requires the user's explicit decision and must not be silently substituted for Delete.
6. Verify normal flow, restart, repeated Delete, failed writes, later schema recognition, Export and user-authorized Reset together.

These are acceptance requirements only. No remediation was performed or authorized by this audit.

### Fresh Delete race review

For readable stores, the corrected path confirms deletion intent before clearing state, begins the History epoch, drains stale Today writes, sanitizes Plan fallback state, clears Insight fallback state, waits for Preferences, then performs a final clear and removes the intent. An in-flight preference application lands before the queued attribution removal; the second pass handles writes queued while the first pass drains. Pending Plan writes from the earlier deletion generation cannot restore stage evidence to `_durable`. [Delete coordination][delete-flow]; [Plan write generation 193–228][plan-set]; [Insight deletion 566–588][insight-delete].

The new paused-Start write is queued with Plan writes. Delete clears its shown/confirmed evidence and invalidates Today; its old continuation encounters the epoch check. Same-day new sessions start after successful deletion with both timestamp maps and the marker cleared. Source inspection and the committed Delete tests support these paths. No fresh, separately established readable-record resurrection is reported. This is bounded evidence, not a proof against arbitrary concurrent external mutation of SharedPreferences.

## 11. Other accepted limitations and device recovery

- **RL-4 remains accepted for the technical baseline and unfixed.** Historical journal, kept-Circle and preference timestamps can lack UTC offsets. The repeated DST hour can be ambiguous; preference-rest comparisons and a lifecycle fold using historical instants can be affected. Newer day-key UTC instants protect the six-hour carry-over mechanism, but do not retroactively disambiguate old records. The required pre-commercial timestamp/export disposition remains outstanding. [RL-4 record][rl4]
- **Device recovery is unproven by these logs.** `FaultDisk` and `R8Harness.restart()` simulate stored bytes and restarts inside one Dart process. They do not establish Android disk durability, real process-kill behavior, power-loss behavior, or OEM-specific storage handling. No new S25/TalkBack/device-storage run was executed in this audit.
- **The single-writer recorder is not a global enforcement mechanism.** `FaultDisk.overlaps` records overlapping attempts; it is not asserted across every scenario. Intentional Delete supersession can overlap stale Today work. It cannot be cited as global single-writer proof.
- **Pending-Start presentation and refusal copy remain known limitations.** There is no separate starting indicator; some first-refusal wording refers to History. These do not excuse R83-N02, where confirmation is actually bypassed.
- **Unreadable Plan restrictions remain.** A Plan that cannot be read cannot be safely started over; explanatory UI is limited. Unknown Preferences ordinarily refuse changes until Reset. These data-protection choices do not resolve L-1's success/export mismatch.
- **Stage-5 lifecycle exceptions remain scoped policy.** A valid pre-Pause Start can complete stage 5 and end the cycle while the Plan was paused; a left cycle retains its left status when the allowed earlier Close is credited. R8.3 adds dedicated cross-store controls. No new product-policy waiver is inferred.
- **One provenance record per Plan is not accepted here as safely non-actionable after overwrite.** L-2's stated fallback fails in R83-N03. The storage bound can remain a design choice only if the promised safe behavior is actually established.
- **Commercial and device gates remain separate.** This source audit does not authorize live billing, release, marketing claims or a change to Phase E. Existing physical-device results from earlier product stages do not prove these new persistence boundaries.

## 12. Historical scorecard comparison

The five dimensions below were explicitly rescored by the original post-R8.2 Astra audit. Its original 0–10 scale is retained: 0 = absent/untenable; 5 = useful but limited; 10 = exceptionally strongly supported. Confidence describes the judgment. This narrower delta audit does **not** fabricate a new complete product scorecard or average.

| Dimension | Original d89a035 | Post-R8.2 Astra | Post-R8.3 delta assessment |
| --- | --- | --- | --- |
| Trust | 7 / MEDIUM | 6 / MEDIUM | Positive closure of specific deletion/attribution defects, but L-1 and the new failure paths prevent a supported upgrade. Not numerically rescored. |
| Accessibility / robustness | 7 / LOW | 6 / MEDIUM | Startup native-type robustness improves; no fresh device/accessibility run and new asynchronous recovery gaps remain. Not numerically rescored. |
| Routine ownership value — historical label | 9 / HIGH | 9 / MEDIUM | No new loss of kept ownership or lapse rights established. The retired terminology is retained only for comparison. Not numerically rescored. |
| Pre-release readiness | 7 / MEDIUM | 4 / MEDIUM | Engineering and release blockers remain; test-count growth does not establish release readiness. Not numerically rescored. |
| Overall product quality | 7 / MEDIUM | 6 / MEDIUM | The bounded architecture and substantive fixes remain valuable, but this target still violates integrity contracts. Not numerically rescored. |

Source: [post-R8.2 historical scorecard and its original-source link][scorecard]. The other 26 original dimensions are not rescored. No commercial validation, retention improvement or revenue implication is inferred from the simulations.

## 13. Engineering baseline blockers versus commercial release blockers

| Gate | Required disposition | Current outcome |
| --- | --- | --- |
| Engineering: R83-N01 | Eligibility evidence must not outlive a cancelled/uncommitted attempt as if a valid paused Start occurred; later legitimate credit must survive restart | **BLOCKED** |
| Engineering: R83-N02 | Every Start path must confirm the same eligibility fact, including rebuild and retry while a write is held | **BLOCKED** |
| Engineering: R83-N03 / D3 | An already-applied old Insight must not repeat its action after provenance overwrite and return to current status | **BLOCKED** |
| Full D1/Delete/Export conformance | Safe, truthful disposition of wholly unreadable Preferences | **L-1 OPEN — PRE-RELEASE BLOCKER; no unconditional invariant sign-off** |
| Regression bookkeeping | Exact SHA, inventory, manifests, raw logs and reported totals reconcile | **VERIFIED** |
| Runtime confirmation of this audit's new findings | Execute the adversarial recipes and controls on the exact target/corrected target as applicable | **NOT EXECUTED HERE** |
| Commercial/device release | L-1, RL-4 disposition, required real-device recovery and entitlement/accessibility checks, and remaining founder release gates | **HOLD; no authorization** |

The medium severity of a bounded credit or retry defect does not make it non-blocking: these are explicit acceptance contracts for this hardening pass. Conversely, stronger regression evidence is a real improvement and should be retained; it simply cannot compensate for a missing behavioral invariant.

## 14. Final verdict

**FAIL. Do not accept `9c910773d7bfd3961be75fe3c9a44db41a1b7b27` as the completed R8.3 technical engineering baseline.**

The target is authentic and the reported final regression totals reconcile. The expiry codec, extension preservation, midnight recheck, queued I3 attribution and two corrected Plan Delete paths have credible closure evidence. However, the new eligibility marker can survive without a valid Start and can be mistaken for durable while still optimistic; the one-record Insight fallback also permits a previously executed action to repeat. R83-F1, D2 and D3 are therefore only partially closed.

This verdict is independent of commercial-release permission and does not rely solely on L-1. **L-1 remains OPEN — PRE-RELEASE BLOCKER, not fixed and not waived. Phase E remains HOLD.** No remediation, commit, push, migration or deployment was performed.

---

## Source index

All inline source links are pinned to the audited SHA. Line references in the report refer to that committed tree. Additional controlling documents and evidence entry points:

- [Frozen product contract][contract], [ADR-024: Plans and Insights][adr24], [ADR-023: recurring Premium and ownership][adr23], [ADR-017: billing authority][adr17].
- [Final source/config blob manifest][manifest], [final coverage manifest][coverage], [analyzer output][analyzer].
- [E-1 executable corruption challenge][e1], [R8.3.1 original-auditor raw control log][controls].

[handoff]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/artifacts/r8_3_bounded_integrity_hardening_2026-11-07/INDEPENDENT_AUDIT_HANDOFF_R8_3.md
[astra82]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/docs/audits/THIRTY_INDEPENDENT_POST_R8_2_AUDIT.md
[claude82]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/docs/audits/THIRTY_CLAUDE_INDEPENDENT_POST_R8_2_AUDIT.txt
[architecture]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/artifacts/pre_r8_3_architecture_review_2026-11-06/ARCHITECTURE_REVIEW.md
[register]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/artifacts/r8_3_bounded_integrity_hardening_2026-11-07/ISSUE_REGISTER.json
[decisions]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/artifacts/r8_3_bounded_integrity_hardening_2026-11-07/FOUNDER_DECISIONS.md
[inventory]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/artifacts/r8_3_1_founder_lifecycle_correction_2026-11-07/commit_verification/COMMIT_PATHS.txt
[regression]: https://github.com/thirtyapp/Thirty/tree/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/artifacts/r8_3_1_founder_lifecycle_correction_2026-11-07/regression
[limitations]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/artifacts/r8_3_bounded_integrity_hardening_2026-11-07/LIMITATIONS_R8_3.md
[l1]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/artifacts/r8_3_1_founder_lifecycle_correction_2026-11-07/l1_assessment/L1_ASSESSMENT.md
[rl4]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/artifacts/r8_1_consolidated_remediation_2026-11-05/LIMITATION_RL4_OFFSET_FREE_TIMESTAMPS.md
[scorecard]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/docs/audits/THIRTY_INDEPENDENT_POST_R8_2_AUDIT.md#L427-L479
[insight-apply]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/insights/application/insights_provider.dart#L317-L397
[insight-i3]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/insights/application/insights_provider.dart#L469-L486
[insight-gentler]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/insights/application/insights_provider.dart#L436-L459
[insight-delete]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/insights/application/insights_provider.dart#L566-L588
[preferences-change]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/home/application/suggestion_preferences.dart#L396-L460
[preferences-forget]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/home/application/suggestion_preferences.dart#L353-L577
[served-codec]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/plans/domain/circle_plan.dart#L765-L786
[applied-codec]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/plans/domain/circle_plan.dart#L644-L690
[progress]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/plans/domain/circle_plan.dart#L490-L635
[credit-domain]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/plans/domain/circle_plan.dart#L1148-L1235
[marker-domain]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/plans/domain/circle_plan.dart#L1290-L1311
[plan-set]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/plans/application/circle_plans_provider.dart#L193-L231
[insight-slot]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/plans/application/circle_plans_provider.dart#L382-L392
[fold]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/plans/application/circle_plans_provider.dart#L406-L451
[fast-start]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/plans/application/circle_plans_provider.dart#L717-L743
[settle-start]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/plans/application/circle_plans_provider.dart#L751-L819
[marker-write]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/plans/application/circle_plans_provider.dart#L790-L806
[delete-plan]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/plans/application/circle_plans_provider.dart#L943-L989
[today-build]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/home/application/recommendation_provider.dart#L1014-L1039
[start-fast]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/home/application/recommendation_provider.dart#L1748-L1814
[start-wait]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/home/application/recommendation_provider.dart#L1850-L1942
[publish]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/home/application/recommendation_provider.dart#L887-L988
[catchup]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/home/application/recommendation_provider.dart#L1066-L1193
[persist-start]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/home/application/recommendation_provider.dart#L2692-L2706
[delete-flow]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/home/application/circle_history_deletion.dart#L156-L311
[export]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/home/presentation/widgets/journal_data_controls.dart#L90-L123
[app-resume]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/core/app/thirty_app.dart#L65-L80
[cohort]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/core/analytics/tester_identity_provider.dart#L74-L87
[insight-qualify]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/insights/domain/insight_engine.dart#L280-L370
[insight-status]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/lib/features/insights/domain/insight_engine.dart#L614-L719
[r831-test]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/test/features/r83/r831_start_eligibility_test.dart
[attribution-test]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/test/features/r83/r83_insight_attribution_test.dart
[oracle]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/test/support/r83_invariants.dart#L218
[contract]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/docs/product/PRODUCT_V2_CONTRACT.md
[adr24]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/docs/product/adr/ADR-024-v2-circle-plans-insights-and-four-tab-product.md
[adr23]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/docs/product/adr/ADR-023-v2-recurring-premium-personal-guided-circle.md
[adr17]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/docs/product/adr/ADR-017-v1-step5-revenuecat-billing.md
[manifest]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/artifacts/r8_3_1_founder_lifecycle_correction_2026-11-07/regression/SOURCE_MANIFEST_git_blobs_end.txt
[coverage]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/artifacts/r8_3_1_founder_lifecycle_correction_2026-11-07/regression/COVERAGE_MANIFEST.json
[analyzer]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/artifacts/r8_3_1_founder_lifecycle_correction_2026-11-07/FLUTTER_ANALYZE.txt
[e1]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/artifacts/r8_3_bounded_integrity_hardening_2026-11-07/e1_raw_validation/check_raw_evidence.py
[controls]: https://github.com/thirtyapp/Thirty/blob/9c910773d7bfd3961be75fe3c9a44db41a1b7b27/artifacts/r8_3_1_founder_lifecycle_correction_2026-11-07/auditor_controls/auditor_tests_on_R8_3_1.jsonl
