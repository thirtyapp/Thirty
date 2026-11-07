# THIRTY — INDEPENDENT POST-R8.2 AUDIT

**Audit date:** 6 November 2026  
**Repository:** thirtyapp/Thirty  
**Branch:** step5-billing-integration  
**Immutable target:** e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8  
**Expected and verified parent:** e935112c408c16d99835280f4e1fafd722d47ed1  
**Final verdict: FAIL — the R8.2 technical baseline should not be accepted at this SHA.**  
**Commercial release remains unauthorized. THIRTY Phase E remains HOLD.**

The source and regression evidence reconcile. The original deletion-resurrection and unsaveable-session defects have substantive fixes. However, this audit establishes remaining source-level violations of application provenance, idempotent marker repair, persistence fidelity and daily identity. Passing regression evidence does not close those violations.

Five new findings are reported: four MEDIUM and one LOW. Their source-level conclusions are independent; their proposed Flutter reproductions were **not executed**, because neither Flutter nor Dart is available in this audit environment. No application-test execution is claimed.

## 1. Exact SHA and immutable source verification

All product conclusions refer to the [target commit](https://github.com/thirtyapp/Thirty/commit/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8), never to the branch's moving working tree.

| Verification performed independently | Result |
|---|---|
| Commit SHA | e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8 |
| Single parent | e935112c408c16d99835280f4e1fafd722d47ed1 |
| Git tree SHA | 623a8ee4717b29fb2fcef97fb610545266c158ca |
| Git object integrity | git fsck --full --strict: exit 0 |
| Actual parent-to-target changed paths versus COMMIT_PATHS.txt | 423 versus 423; no missing, extra or duplicated paths |
| Exported committed blobs versus Git tree | 1,678 checked; zero mismatches |
| Tested-source manifest versus committed lib/, test/ and three configuration files | 371 versus 371; zero missing, extra or mismatched blobs |
| Preflight/start/end source fingerprints | Identical |
| Fingerprints versus committed bytes | 228 exact LF matches; 143 CRLF-equivalent matches; zero unexplained differences |
| Frozen audio files | 172 production + 8 framing = 180; all hashes match; no audio change from parent |

The 423-path change comprises 12 production files, 13 existing tests, 14 new R8.2 tests, two original audit reports and 382 artifact paths. I checked the actual Git inventory, rather than accepting the prose inventory.

The definitive tested-source manifest's SHA-256 is:

837906b7c7b4f5252b6898016069dd0d6c204719f83ad7775e9e5b0abd17530c

The manifest covers the declared 371 source/configuration blobs. It is **not** a claim that every native build input or external dependency was part of that manifest. The wider committed tree was separately byte-verified.

The two original report files match their declared hashes:

| Original report | Bytes | SHA-256 |
|---|---:|---|
| THIRTY_INDEPENDENT_POST_R8_1_AUDIT.md | 104,664 | afb0dd9ad6e82774bb963e67c6749b44a9505c18954af037ac8a3c565c0c375a |
| THIRTY_CLAUDE_POST_R8_1_AUDIT_REPORT.txt | 52,094 | 96593e20a24cba993dc45973118d2ed021dcae25c465fa0078ac87b29e4c23a1 |

These establish byte identity with the committed hash declarations. They are not cryptographic authentication of the reports' authorship.

A separate Git-object clone and archive export were used. No product source or repository test was edited. No staging, commit, push, reset, merge, deployment or remediation was performed. Audit scripts and proposed reproductions were created only outside the audited source tree.

## 2. Independent methodology and limitations

The required R8.2 handoff, ISSUE_REGISTER.json, both complete post-R8.1 audit reports, consolidated change log, founder decisions A–C, final lifecycle policy and LIMITATIONS_R8_2.md were read. The product contract, ADR-023, ADR-024 and billing ADR-017 were read, with the current source taking precedence over historical implementation descriptions. The original d89a035 scorecard and RL-4 record were also examined.

The issue register was used to locate code and tests. Its FIXED/PASS statements were not evidence of correctness.

The source review followed the affected paths across Today publication, Plans, History, Insights, preference queues, deletion, rollback, preservation and entitlement boundaries. I examined the new R8.2 tests and relevant existing assertion changes, including failure controls and restart expectations. This was a focused semantic audit, not a claim to have manually read every assertion in all 193 test files.

| Evidence class | What this audit actually did |
|---|---|
| **Independently executed checks** | Git/tree/blob/hash comparisons; strict parsing and reconciliation of the definitive raw regression logs; reproduction-log parsing; test/profile inventory reconciliation; Python evidence-runner mutation challenges in a disposable copy |
| **Independently verified implementation evidence** | 2,774 passing test events, 193-file coverage, 13 year profiles, six B8 test cases, analyzer output, original/adapted auditor logs and frozen audio hashes |
| **Static source conclusions** | Original-finding dispositions, founder-policy implementation, five new findings and native failure-window analysis |
| **Not executed here** | Flutter tests, Dart tests, analyzer, Android instrumentation, real process kills, device storage faults, TalkBack, actual RevenueCat/Play transactions |

**Independent Flutter/Dart application tests executed: 0.** The seven proposed adversarial cases in Appendix B are explicitly unexecuted specifications. They must not be counted as passing or failing runtime results.

A log's successful terminal event establishes what the retained reporter recorded. Hashes connect that evidence to the stated source. Neither is a signed execution attestation, nor proof that untested interleavings are correct.

## 3. Original finding closure matrix

FIXED below means the reported mechanism is corrected in the exact source, supported by inspected assertions and retained execution evidence. It does not certify every possible native failure.

| Original finding | Disposition | Independent assessment and source evidence |
|---|---|---|
| Astra R81-A01 — pending failed Pause bypasses credit prerequisite | **FIXED** | Credit resolution distinguishes a pending lifecycle state from a durable state and waits/retries before overwriting the prior session. Earned credit is folded into later lifecycle changes. See [Plans credit retry:825–878](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/plans/application/circle_plans_provider.dart#L825-L878), [Today prior-session preservation:970–989](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/home/application/recommendation_provider.dart#L970-L989), r82_a01_pending_lifecycle_credit_test.dart and decision-A tests. |
| Astra R81-A02 — deletion can leave recreated Insight metadata | **FIXED** | Assessment is inhibited during deletion; deletion clears durable rollback baselines, drains writers and performs a final removal. See [deletion coordinator](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/home/application/circle_history_deletion.dart), [Insights deletion:544–567](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/insights/application/insights_provider.dart#L544-L567), r82_a02_new2_delete_isolation_test.dart. |
| Astra R81-A03 — publication validates live offer rather than saved payload | **FIXED** | Publication checks the stage carried by the payload; first publication and Plan prerequisites precede valid Start. A failed prerequisite withdraws only an unstarted offer. See [Today publication:856–963](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/home/application/recommendation_provider.dart#L856-L963), r82_a03_new1_stage_publication_test.dart. New Start defects are separately reported below. |
| Astra R81-A04 — I2 validates cycle A but changes cycle B | **FIXED** | Application waits for Plan writes, checks the confirmed target cycle and passes that cycle to the mutation. See [I2:420–444](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/insights/application/insights_provider.dart#L420-L444), r82_a04_a08_new3_insight_actions_test.dart. |
| Astra R81-A05 — readable nested records lose unknown/damaged data | **PARTIAL** | The reported preference, served-stage and Insight examples are preserved; malformed security-relevant flags are rejected. However, the new AppliedInsight record still drops valid extension fields (N04), and source retention introduces a flag-clearing defect (N03). See [Plan codecs:590–778](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/plans/domain/circle_plan.dart#L590-L778). |
| Astra R81-A06 — removing answers reopens completed overnight reflection | **FIXED** | A distinct persisted reflection-completion marker survives answer removal; a genuinely unfinished reflection remains unfinished. See [Today reflection state and persistence](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/home/application/recommendation_provider.dart), r82_a06_reflection_completion_test.dart. |
| Astra R81-A07 — unconfirmed History becomes durable Insight evidence | **FIXED** | Decision inputs use confirmed History while native writes are pending, rather than the optimistic SharedPreferences cache. Stage-5 composition uses the same boundary. See [History:750–758](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/home/application/circle_journal.dart#L750-L758), [write tracker:1424–1471](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/home/application/circle_journal.dart#L1424-L1471), r82_a07_confirmed_history_test.dart. |
| Astra R81-A08 — target success/marker failure cannot be repaired | **PARTIAL** | Ordinary retries with unchanged targets are repaired from durable provenance. A target made actionable again bypasses repair and repeats the action; queued manual I3 changes can be falsely attributed. N01/N02. See [Insights:303–381](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/insights/application/insights_provider.dart#L303-L381). |
| Astra R81-A09 — wrong native preference type crashes recovery | **FIXED** | Affected store readers inspect native values before casting; Plans/Insights preserve native values, preferences refuse destructive overwrite and History preserves a typed JSON representation. See [preservation helper](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/core/storage/preservation_writes.dart), r82_a09_native_types_test.dart. This does not establish resilience to a platform failure before SharedPreferences itself loads. |
| Claude NEW-1 — legitimate Plan changes strand an already-published Circle | **FIXED** | A superseded served record no longer blocks all subsequent saves of the old Circle. Close and reflection retain their identity. See [confirmStartNoted/_settleStart:698–771](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/plans/application/circle_plans_provider.dart#L698-L771), r82_claude_audit_new1_triggers_test.dart and the original stage-5 reproduction. |
| Claude NEW-2 — deletion rollback/queued save resurrects evidence | **FIXED** | Same deletion root cause as A02, with separate failed-delete/failed-save and queued-writer assertions. See [Plans deletion baseline:895–924](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/plans/application/circle_plans_provider.dart#L895-L924). |
| Claude NEW-3 — false notSaved despite a later queued save carrying the change | **FIXED** | The confirmation path waits for the queue and compares the requested leaf changes with durable state. It distinguishes a carried-forward change from one never saved. See [Plans confirmation:464–518](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/plans/application/circle_plans_provider.dart#L464-L518), positive and negative controls in the Insight-action tests. N03 is a distinct serialization/confirmation inconsistency. |
| Claude E-1 — missing/duplicate/incomplete batch evidence accepted | **FIXED for the reported mechanism** | Independent disposable-copy mutations of the declared part set, completion status, file inventory and command identity are rejected. A remaining raw-log-validation limitation is recorded in §7. |
| Claude I1/I2/I3 marker-retry observation | **PARTIAL** | The target-success/marker-failure split is addressed, but decision C is not upheld across all later actions/concurrency. N01 and N02 are counterexamples. |

Affected earlier guarantees were also traced: no overwrite of the last recoverable session, explicit store-failure reporting, deletion intent/recovery, owned-Circle retention, unknown-record preservation, entitlement-based credit and prior-day Start refusal. The first three are materially improved. Unknown-record preservation, entitlement-record fidelity and prior-day Start refusal have the residuals described below.

## 4. Founder-policy verification

| Policy / ordering | Result at this SHA | Basis and qualification |
|---|---|---|
| A: durable Close before Pause, Leave or a competing Plan | **Implemented for the reviewed cases** | _withEarnedCredits uses confirmed History, then folds the original credit into the lifecycle save. Tests inspect disk and repeat restarts. |
| B: refuse Start until offer publication and necessary Plan Start evidence succeed | **PARTIAL overall** | The intended wait/refusal and retry paths exist and are tested. They wait for prerequisites, not every later History write. N03 shows the confirmed Plan representation can disagree with disk; N05 shows day validity is not rechecked when waiting ends. |
| C: I1/I2 provenance accompanies its Plan change; I3 accompanies its exclusion | **Mechanism present; policy PARTIAL** | Atomic target/provenance writes exist. N01 repeats a prior action despite intact provenance. N02 records a manual action as the Insight's own. |
| Start → Pause → durable Close | **Implemented** | Start timestamp is stamped in the Pause payload; the matching Close credits the paused cycle once. |
| Start → another Plan → durable Close | **Implemented** | Original Plan is credited; the competing Plan remains active and is not advanced. |
| Pause before valid Start | **Implemented: no credit** | No matching startedBeforePause stamp; dedicated negative control. |
| Start → Leave → Close | **Implemented: History retained, no Plan credit** | A Close requested after Leave cannot satisfy closedBeforeLeave. |
| Close requested → Leave while Close storage is pending | **Implemented within the documented persistence model** | The request's exact instant is stamped in the Leave save. Credit waits for the durable Close, then goes to the left cycle. |
| Previous row → Go through again before Close lands | **Implemented** | The stamped served record retains the original cycle; the new cycle does not advance. |
| Failed Close never recoverable | **Implemented: no credit** | Tests distinguish retained WAL/day data from a request that never becomes durable. |
| New Close after restart, following a failed earlier Close and Leave | **Implemented: no credit for the later request** | Exact instant matching avoids substituting a later Close. |
| Stage 5 credited on a paused Plan | **Static implementation verified; dedicated boundary test not found** | recordGuided converts that Plan to ended. It does not reactivate it. This is the disclosed stage-5 exception to “stays paused.” |
| Stage 5 Close requested before Leave | **Static implementation verified; dedicated boundary test not found** | The left-cycle branch precedes the stage-5 reachedEnd branch; the cycle keeps end=left. |
| Premium lapses during an existing session | **Main policy preserved, with N03 residual** | Visual session and owned data remain; voice/service require active entitlement; served-and-started provenance can retain historical credit. A verified-expired Start does not gain the served-credit exception. |

Primary policy code: [lifecycle folding and action-order stamps:282–451](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/plans/application/circle_plans_provider.dart#L282-L451), [credit eligibility and lifecycle transitions:1089–1175](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/plans/domain/circle_plan.dart#L1089-L1175).

The final lifecycle suite's retained logs contain 21 cases: 12 pass/9 fail before the correction, then 21 pass. These are verified recorded executions, not my executions. Their fixtures exercise stage 1; stage-5 lifecycle boundaries should not inherit a runtime PASS merely from those 21 results.

## 5. Newly discovered findings

### R82-N01 — Marker repair repeats an already-applied I1/I2 action after a manual reversal

**Severity: MEDIUM. Confidence: HIGH from source. Baseline blocker. Execution: not run.**

The provenance check is only in the stale branch of InsightsNotifier.apply. A current snapshot goes directly to its target action.

A prior application can become current again:

1. Generate an eligible I1 and persist its snapshot.
2. Apply it successfully to making_room, but fail the subsequent Insights marker write. The Plan durably contains the Insight ID.
3. Manually Pause the Plan, or Leave it, and save that action.
4. Restart while the original evidence still qualifies, then retry the same Insight.
5. The I1 candidate has the same subject and overlapping evidence. Its changed lifecycle action does not make the observation stale.
6. apply takes the current branch. It resumes the paused Plan, or creates another cycle for the left Plan, instead of repairing only the earlier application marker.

The equivalent I2 sequence is successful gentler application → failed marker → manual stopGentler → retry. The current branch can re-enable the setting.

**Required result:** record the original application date from intact provenance without changing the later user-selected Plan state.

**Source result:** the target action runs again. The final appliedOn is generated from the retry date rather than necessarily the original provenance date.

This is not the accepted “one provenance slot overwritten by another Insight” limitation: the correct original provenance is still present.

Sources:

- [apply branch and marker write:303–349](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/insights/application/insights_provider.dart#L303-L349)
- [actual Plan action selection:396–443](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/insights/application/insights_provider.dart#L396-L443)
- [I1 candidate:255–297](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/insights/domain/insight_engine.dart#L255-L297)
- [current/stale comparison:614–638](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/insights/domain/insight_engine.dart#L614-L638)

**Coverage gap:** the test named “provenance survives a later Pause and Go through again” actually executes Leave plus Go through again, leaving the Plan active. That makes I1 stale and exercises the repair branch. It does not test a Plan left paused or left. The existing unchanged-target repair tests also miss this distinction.

### R82-N02 — A queued manual exclusion is falsely recorded as an I3 application

**Severity: MEDIUM. Confidence: HIGH from source. Baseline blocker. Execution: not run.**

1. Persist a current I3 for element E.
2. Manually request leaveOut(E), holding its preference write before acknowledgement.
3. Preferences still expose the previous state, in which E is not left out.
4. Invoke apply on I3. It waits for Plans and History, but not the preference queue, and reads I3 as current.
5. Its leaveOut(E, byInsight: id) queues behind the manual operation.
6. Let the manual write succeed. It persists E with no Insight attribution.
7. The queued Insight operation now finds E already excluded. Its change callback returns null.
8. Preference _save treats that no-op as true. _leaveOut maps true to done, and apply writes appliedOn.

**Required result:** the manual target must not be claimed as this Insight's action.

**Source result:** the snapshot is marked applied although the persisted preference has no matching byInsight. Every write may succeed; no malformed input is necessary. Restart preserves the false application history.

Sources:

- [apply and prerequisite waits:303–344](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/insights/application/insights_provider.dart#L303-L344)
- [I3 Boolean-to-done conversion:453–464](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/insights/application/insights_provider.dart#L453-L464)
- [preference queue/no-op success:323–363](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/home/application/suggestion_preferences.dart#L323-L363)
- [leaveOut conditional mutation:412–427](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/home/application/suggestion_preferences.dart#L412-L427)

**Coverage gap:** the manual-action tests complete the manual change before retrying the Insight. They do not place that change ahead of the Insight in the preference queue.

### R82-N03 — Clearing startedAfterExpiry is not faithfully serialized

**Severity: MEDIUM. Confidence: HIGH for the codec defect; MEDIUM for native end-to-end frequency. Baseline blocker. Execution: not run.**

ServedStageCircle.fromJson retains the original map as source. copyWith(startedAfterExpiry: false) retains that source. toJson spreads source and only writes startedAfterExpiry when the current value is true.

For a decoded record whose stored flag is true:

| Representation | Value after copyWith(false) |
|---|---|
| In-memory startedAfterExpiry | false |
| Serialized startedAfterExpiry | true, inherited from source |
| Value after encode/decode or restart | true |

Plans.noteStart uses this copy operation when a later Start occurs with Premium active. _set can confirm the write and assign the false-valued model to _durable even though the serialized bytes still contain true. This is a false equivalence between confirmed model and stored representation.

A reachable recovery sequence is: a stage offer is durable; a Start after expiry persists the Plan flag, but its Today Start does not become recoverable; restart with the old unstarted offer; Premium is active for the new Start; save it; restart again and lapse before Close. The stale true flag can withhold the served-and-started credit exception although the new Start happened under Premium. A process interruption between the Plan write and Start publication is another way to obtain the same state.

**Required result:** a successful rewrite from the later Start must persist the new entitlement fact.

**Source result:** the old fact survives serialization. No write failure is needed during the defective rewrite itself.

Sources:

- [copyWith and toJson:714–734](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/plans/domain/circle_plan.dart#L714-L734)
- [source retention:743–778](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/plans/domain/circle_plan.dart#L743-L778)
- [credit exception and noteStart:1200–1227](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/plans/domain/circle_plan.dart#L1200-L1227)
- [confirmation path:743–763](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/plans/application/circle_plans_provider.dart#L743-L763)

**Coverage gap:** the new preservation tests test unchanged raw values and malformed flags, not a valid true → false round trip.

LIMITATIONS_R8_2.md says the next Start rewrites a retained expiry note using billing's then-current answer. That mitigation is not reliable on this SHA. This is not merely the accepted harmless leftover-note limitation.

### R82-N04 — Valid AppliedInsight extension fields are silently discarded

**Severity: LOW, bounded forward-compatibility/data-preservation defect. Confidence: HIGH from source. Execution: not run.**

AppliedInsight accepts a valid record containing insightId, cycleId and on, but retains none of its other fields. PlanProgress treats appliedInsight as a known field and only retains the raw value if decoding fails.

A valid record with an additional nested futureProvenance field therefore loses that field on an unrelated Plan save. Malformed provenance is preserved; valid extended provenance is not.

**Required result:** retain unknown nested fields through an unrelated save under the accepted preservation contract.

**Source result:** only the three currently known fields are serialized.

Sources: [PlanProgress handling:590–615](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/plans/domain/circle_plan.dart#L590-L615), [AppliedInsight:623–653](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/plans/domain/circle_plan.dart#L623-L653).

The direct three-field provenance used by this version remains usable. This is not evidence of lost Circle content. It is a concrete remaining hole in A05's broader closure claim.

### R82-N05 — A pending Start can start yesterday's offer after midnight

**Severity: MEDIUM. Confidence: HIGH for the source path. Execution: not run.**

start validates the offer's local day before beginning the asynchronous wait. _startOnceSaved waits for persistence, then checks recommendation object identity and notStarted status, but does not revalidate the day. It sets startedAt from the later clock.

1. Hold first publication of a Free offer at 23:59:59.
2. Tap Start. The Circle remains notStarted while waiting.
3. Advance local time beyond midnight without another touch/resume.
4. Release the write successfully.
5. The waiting continuation sets status=started and a next-day startedAt on the previous-day Circle ID.

**Required result:** the unstarted old-day offer must not become a started Circle after its day expires.

**Source result:** it starts automatically under the old identity. The next resume can then preserve it as a running carry-over.

Sources:

- [day guard:1748–1769](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/home/application/recommendation_provider.dart#L1748-L1769)
- [post-wait transition:1866–1903](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/features/home/application/recommendation_provider.dart#L1866-L1903)
- [root refresh is resume/touch driven:66–135](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/lib/core/app/thirty_app.dart#L66-L135)

The CircleHero midnight timers reviewed concern closed-screen wording/confirmation, not this pending unstarted transition. The existing decision-B tests hold writes but never cross a day boundary.

This finding uses the existing rule that a valid Start occurs after the required save, consistent with both the stored startedAt and “Pause before valid Start” policy. Treating the earlier tap as a retrospective valid Start would be a different policy, not what this implementation records.

## 6. Reproduction scenarios and actual execution results

### Independently executed evidence challenges

All mutations below were made to a disposable evidence copy, never the committed tree.

| Challenge | Actual result |
|---|---|
| Intact report | Exit 0; EVIDENCE OK |
| Remove declared batch part 18c | Exit 1; EVIDENCE MISMATCH |
| Replace 18c summary with duplicate 18b | Exit 1; EVIDENCE MISMATCH |
| Add unexpected part 18f | Exit 1; EVIDENCE MISMATCH |
| Change terminal success metadata to false | Exit 1; EVIDENCE MISMATCH |
| Remove an inventoried test file from summary evidence | Exit 1; EVIDENCE MISMATCH |
| Change a declared command | Exit 1; EVIDENCE MISMATCH |
| Empty only raw batch_18c.jsonl, retaining summaries | Exit 0; EVIDENCE OK — limitation, §7 |
| Case inventory validation | Exit 0; CASES OK |

The proposed application reproductions cover I1 Pause and Leave separately, I2 manual reversal, queued manual I3, the expiry-flag round trip, valid provenance extensions and midnight while waiting. Their actual execution result is **NOT RUN**. Source traces, not invented runtime output, support §5.

### The five original Claude failures

The unmodified post-fix raw reporter contains eight successes, three errors and two assertion failures, with terminal success=false. Its 8/5 summary is accurate.

| Failure | Independent classification | Why |
|---|---|---|
| A2, throws | **Obsolete expected behavior** | The fixture dereferences recommendation after the failed first served-stage publication. R8.2 has withdrawn that unstarted, unsaveable offer. The null assertion fails before testing actual loss of a started Circle. |
| A2, returnsFalse | **Obsolete expected behavior** | Same assumption and failure location, original repro line 124. |
| DIAG A2, returnsFalse once | **Obsolete fixture assumption; diagnostic only** | Line 102 also force-dereferences the withdrawn offer. This diagnostic contains no acceptance assertion establishing a remaining save-loss defect. |
| A3, throws | **Defective final assertion** | The Circle ID is 2026-10-12. A substring search of the entire Plan JSON finds that same date in startedOn/gentlerSince even though records is empty. Earlier record-removal assertions pass. |
| A3, returnsFalse | **Defective final assertion** | Same collision. The raw failure prints an empty records list, not resurrected stage evidence. |

The original three reproduction files match the declared original SHA-256 values:

- audit_r81_diag_test.dart: 29e0e42fef5a792355c0a37edb420d9a6b77723889aaea50648fdd8e6d91198f
- audit_r81_repro_test.dart: e00fc009833f19c76c2ace9774cbdd672e1784c14038eda43343212ea4e83fe3
- audit_r81_stage5_test.dart: 9996c8f0c1ffb7acf75362d7910db6ccace004c53f721c8ca21384505a60bbb3

**Assessment of the adaptations:** the six adapted tests have six successful reporter completions and success=true. Their changes are substantively appropriate:

- A2 accepts either a safely saved execution or an explicitly refused/withdrawn offer, and the observed withdrawal route checks notice, re-choice, Close, reflection and restart.
- A3 parses stage records rather than treating every matching date as deleted evidence.
- Leave → Start and stage-5 → Go through again check the original NEW-1 acceptance condition across restart.

Limitations of those assertions remain: A3's helper permits a missing Plan store as well as zero records, so it is not by itself proof of retained Plan settings. The “I1” stage-5 adaptation calls the Plan action using a proxy Insight ID; it does not exercise full Insight selection and application. The committed NEW-1 test uses the same proxy approach. These tests are useful persistence regressions, not comprehensive decision-C coverage.

I do not adopt the implementer's “all remaining failures are harmless” conclusion globally. It is justified for these five exact failures after inspecting their assertions and raw errors. N01–N05 are separate, uncovered defects.

## 7. Full regression and evidence integrity assessment

The definitive evidence is [lifecycle_policy/regression_rerun](https://github.com/thirtyapp/Thirty/tree/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/artifacts/r8_2_consolidated_remediation_2026-11-05/lifecycle_policy/regression_rerun). Superseded and interrupted runs were not combined with it.

| Claim | Independent result |
|---|---|
| 193/193 files | Confirmed against every committed *_test.dart path and the batch plan; no omitted or extra files |
| 2,774 passed | Confirmed by non-hidden testDone events joined to testStart/suite records |
| 0 failed, 0 skipped | Confirmed in definitive raw events |
| 22 batch reporter logs | Each has one start, one final done(success=true), and exactly one completion per started test, including hidden loaders |
| Duplicate tests | No duplicate file/test-name pair in the counted definitive executions |
| Summary totals, per-file counts and test names | Match independently reconstructed raw-event results |
| 13/13 year profiles | Every named profile appears exactly once; no duplicate substituted profile |
| 6/6 B8 | Six successful test cases verified |
| flutter analyze clean | Committed output says “No issues found,” exit 0; not rerun |
| 371-file manifest | Matches the exact Git blobs and declared source/config scope |
| 180/180 audio | Actual bytes independently hashed against both frozen manifests |

Per-batch pass counts:

| Batch | Passed | Batch | Passed |
|---|---:|---|---:|
| 01 | 76 | 12 | 282 |
| 02 | 99 | 13 | 159 |
| 03 | 121 | 14 | 142 |
| 04 | 157 | 15 | 176 |
| 05 | 88 | 16 | 216 |
| 06 | 226 | 17 | 6 |
| 07 | 241 | 18a | 3 |
| 08 | 154 | 18b | 3 |
| 09 | 164 | 18c | 3 |
| 10 | 267 | 18d | 2 |
| 11 | 187 | 18e | 2 |

The retained run log reports start 12:50:26 and end 13:23:09 on 6 November 2026, UTC+01:00. It records exit 0 for every batch, report and cases checks, and identical fingerprints.

The 13 profiles are p01_sparse_feedback, p02_frequent_feedback, p03_stable_positive, p04_mixed, p05_one_need_dominant, p06_all_three_needs, p07_mostly_10_minutes, p08_mostly_20_minutes, p09_mostly_30_minutes, p10_lapse_and_resubscribe, p11_many_exclusions, p13_no_routine and p14_more_energy_dominant. The absence of p12 is not an omitted current profile.

“6/6 B8” means six test cases, including the voice-entitlement check and an aggregate case over the four main profiles. It does not mean six independent year-long user profiles.

I also parsed the 25 other committed reproduction/targeted JSONL files. Each retained reporter stream reaches a final done event; expected before-fix and original-auditor failures have success=false. Some files begin with dependency-resolution text, followed by a valid reporter stream. There were no malformed JSON events after the reporter began. Those runs are historical corroboration, not additions to 2,774.

### Assertion quality

The lifecycle expectation changes are legitimate responses to explicit founder policy. A paused Plan now retaining valid historical credit is not, by itself, a weakened test. Tests still assert original cycle identity, one credit, retained History, preserved other-Plan activity and negative Leave-before-Close controls.

The timing-only edits add settles after Start. That is appropriate for newly asynchronous Start prerequisites. They also make the long simulations poor evidence about real concurrent interactions; the targeted held-write tests must carry that responsibility.

Material gaps:

- No retained-provenance retry after I1 ends in paused/left state or I2 is manually switched off.
- No manual preference write queued ahead of I3.
- No valid true → false served-flag serialization assertion.
- No valid extended AppliedInsight preservation assertion.
- No pending Start crossing midnight.
- No dedicated paused/left stage-5 boundary regression found.
- The cross-store test labelled “an Insight applied while Delete is under way” calls apply('missing'). It proves that absent-ID path, not a real in-flight application.

### E-1 residual boundary

The report validator now rejects missing, duplicated and malformed summary evidence as required by E-1. However, its report/cases modes can still accept an empty raw JSONL when the summary remains intact. I demonstrated this in the disposable copy.

That is a **LOW evidence-tooling hardening gap**, not evidence that the committed definitive logs are incomplete. I independently parsed those actual logs; they are complete and consistent. A future audit should not treat the validator's EVIDENCE OK as a substitute for reading raw terminal events.

## 8. Persistence, recovery and deletion assessment

**Today versus Plans:** the payload-specific served prerequisite and Start wait fix the major original unsafe-publication path. Later legitimate Plan changes no longer make a published session permanently unsaveable. The pending-start day boundary and expiry serialization residuals prevent unconditional acceptance.

**Plans versus History:** confirmed History is now distinct from optimistic native cache state. Earned credits can be folded into lifecycle changes and recovered before old day data is overwritten. Matching uses Plan/cycle/stage/Circle identity and action instants, with duplicate-credit checks. The model still depends on serialization accurately representing its state; N03 violates that condition.

**Delete versus generation and queued writes:** the deletion intent, generation boundaries, cleared durable baselines, drained queues and final pass address A02/NEW-2. I did not establish a remaining deleted-snapshot resurrection in the reviewed paths. In particular, InsightsState.replacing only replaces existing snapshots; it does not insert a missing old snapshot after deletion. A stale apply continuation is therefore not automatically a resurrection counterexample.

**Delete failure:** “pending deletion” remains distinct from successful deletion. A failed delete may leave disk data awaiting recovery; it must not be described as already erased. The code retains the deletion marker and the reviewed tests recover it on startup. The known original rollback resurrection is corrected.

**Malformed/future data:** native type checks, raw preservation, unreadable-store refusal and nested source retention are real improvements. A05 cannot be called fully closed because the new provenance codec drops extensions. “Preserved” also means retained for recovery/export, not necessarily rendered as usable current data.

**Reflection:** completion is its own fact, not inferred solely from the continued presence of answers. The corrected behavior respects later answer removal without inventing new answers or reopening a finished overnight reflection.

**Partial success:** the stores are not one atomic transaction. Recovery relies on per-store ordering, WAL/day keys, idempotence and preserved target provenance. Ordinary target-success/marker-failure is supported, but N01/N02 show why a successful write alone does not establish correct cross-store attribution.

### Native and restart scope

The locked versions are shared_preferences 2.5.5 and shared_preferences_android 2.4.27.

I independently fetched the corresponding primary implementation sources:

- [Legacy Dart SharedPreferences](https://github.com/flutter/packages/blob/shared_preferences-v2.5.5/packages/shared_preferences/shared_preferences/lib/src/shared_preferences_legacy.dart), blob 06d89f0010c86f640d19501c2a2a5183523b8039.
- [Android LegacySharedPreferencesPlugin](https://github.com/flutter/packages/blob/shared_preferences_android-v2.4.27/packages/shared_preferences/shared_preferences_android/android/src/main/kotlin/io/flutter/plugins/sharedpreferences/LegacySharedPreferencesPlugin.kt), blob bbdb3ecbadb51f6f1454e987be78285146751b89.

The Dart setters update their cache before the platform operation completes. Android's ordinary legacy setters/removal use commit() and return its Boolean result. It would be incorrect to describe all these writes as unchecked Android apply() calls. This audit does not extend that observation to every platform or power-loss behavior.

R8FaultDisk models false/throw without landing, held writes before landing and a stopped-write boundary. R8Harness reconstructs providers from a copied simulated store. It does not literally kill an Android process, and it does not model every “native data landed but acknowledgement was lost” window.

Action-order maps exist only in memory until a Pause/Leave payload saves their stamps. If that payload lands, the ordering evidence is in the same Plan record as the transition. If it does not land, the lifecycle action itself is not confirmed durable. A process kill in that window can lose an unconfirmed request; that is not proof that a confirmed Leave resurrects or that a confirmed credit is lost.

Delayed acknowledgement, native cache/disk divergence after failures, process death between cross-store operations and genuine disk/storage faults still require device tests. I have not established a separate native-only defect from those risks. N03 is a concrete codec defect that can affect restart recovery; it should not be dismissed as merely an untested native concern.

## 9. Premium, credit and ownership assessment

No direct new route granting Premium without the configured RevenueCat entitlement was established. The inspected gateway publishes authoritative entitlement state with ordering tickets; the common Premium provider requires active status. Missing configuration fails closed. Release configuration validation rejects missing/example/non-Play public keys. This is static boundary review, not a live store or penetration-test certificate.

The current adapter maps an absent configured entitlement to inactive; ADR-017's older description says unavailable. Both fail closed for access. The current source is the relevant behavior; the historical prose is not current proof.

A running Circle remains visually usable after lapse, while THIRTY voice and the background guidance service are controlled by the active-entitlement gate. I4 Keep remains the deliberate ownership exception; it is not an unauthorized Premium application.

Kept Circles remain under their own durable store, are not deleted with History, and remain usable/renamable/removable after lapse. No new ownership confiscation or capacity bypass was established in this delta.

Historical Plan credit is not itself a new Premium grant. Its exception depends on the actual served and Start provenance and correct lifecycle ordering. N03 compromises the fidelity of that provenance, principally by withholding legitimate credit after restart. N01 can alter a Plan on a marker retry, and N02 can fabricate application attribution, even with a valid Premium entitlement throughout.

The audit therefore does **not** find a demonstrated billing-access escalation, but does find material integrity failures in paid-feature history and control semantics.

## 10. Review of accepted limitations

| Limitation | Audit disposition |
|---|---|
| RL-4 offset-free historical timestamps | Remains accepted for this technical audit scope, not fixed. The pre-commercial decision remains open. Repeated-hour ambiguity can affect ordering/lifted-rest comparisons and lifecycle fallback/folding; it is not purely display-only. |
| Older offset-free day keys | Remain ambiguous. New UTC day-key instants improve the six-hour rule; they do not retroactively disambiguate old records. |
| Memory-held action order | Bounded as described in §8. No new native-only violation demonstrated; real process-kill proof absent. |
| Stage-5 paused → ended and left-cycle remaining left | Source matches the disclosed behavior. Retain explicit product disposition; do not silently generalize “stays paused” to stage 5. |
| No “starting” indicator | Disclosed UX limitation. Repeated taps are suppressed; a native write that never completes can leave the wait unresolved. This is not proof of false success. |
| First refusal uses the existing History notice | Disclosed wording limitation; the test checks that refusal is told. |
| One provenance record per Plan | Bounded loss of old repair capability after a later Insight overwrites the slot. Does not excuse N01, where the old provenance survives. |
| Expiry note may remain after an uncompleted Start | Its stated mitigation is defective because of N03. Cannot be accepted as harmless on the stated rationale. |
| Unreadable Plan cannot be restarted and lacks explanatory Start copy | Disclosed usability/recovery limitation, not silently “fixed.” |
| Unreadable preferences require explicit Reset | Conservative preservation behavior; reset is an explicit destructive choice, not silent overwrite. |
| Notification-shade carry-over / analytics at interaction | Unchanged disclosed scope; no new device validation claimed. |
| No new S25, TalkBack, native-failure or live billing proof | Remains unverified. Prior phase evidence is not a fresh R8.2 device run. |

## 11. Historical scorecard comparison

The original 31 names and rating scale are preserved. Scale: **0 = absent/untenable; 5 = useful but limited; 10 = exceptionally strongly supported.** HIGH/MEDIUM/LOW indicates confidence in the judgment, not documentation quality.

**NR** means not re-scored in this engineering audit. An original number shown for an NR dimension is historical context only, not endorsement of its current value. Retired Path/Toolkit terminology is retained solely to preserve the historical framework.

| # | Original dimension | d89a035 score / certainty | Post-R8.2 score / certainty |
|---|---|---|---|
| 1 | Core problem clarity | 8 / HIGH | NR |
| 2 | Core problem importance | 5 / LOW | NR |
| 3 | Free product value | 7 / MEDIUM | NR |
| 4 | Day-1 value | 6 / MEDIUM | NR |
| 5 | Day-7 value | 7 / LOW | NR |
| 6 | Day-30 value | 6 / LOW | NR |
| 7 | Recommendation quality | 7 / MEDIUM | NR |
| 8 | Personalization credibility | 7 / MEDIUM | NR |
| 9 | Simplicity | 6 / MEDIUM | NR |
| 10 | Emotional experience | 7 / LOW | NR |
| 11 | Trust | 7 / MEDIUM | **6 / MEDIUM** |
| 12 | Accessibility / robustness | 7 / LOW | **6 / MEDIUM** |
| 13 | Differentiation | 6 / MEDIUM | NR |
| 14 | Free retention potential | 6 / LOW | NR |
| 15 | Premium value | 6 / MEDIUM | NR |
| 16 | Premium differentiation | 6 / MEDIUM | NR |
| 17 | Path value | 6 / MEDIUM | NR |
| 18 | Toolkit value | 6 / MEDIUM | NR |
| 19 | Routine ownership value | 9 / HIGH | **9 / MEDIUM** |
| 20 | Maintenance value | 5 / MEDIUM | NR |
| 21 | Week-7 paid value | 6 / MEDIUM | NR |
| 22 | Month-2 paid value | 6 / MEDIUM | NR |
| 23 | Month-6 paid value | 2 / MEDIUM | NR |
| 24 | Stable-user proposition | 2 / HIGH | NR |
| 25 | Subscription-worthiness | 3 / MEDIUM | NR |
| 26 | Commercial differentiation | 4 / MEDIUM | NR |
| 27 | Content scalability | 8 / HIGH | NR |
| 28 | Founder-labor scalability | 6 / LOW | NR |
| 29 | Pre-release readiness | 7 / MEDIUM | **4 / MEDIUM** |
| 30 | Overall product quality | 7 / MEDIUM | **6 / MEDIUM** |
| 31 | Overall commercial design strength | 5 / MEDIUM | NR |

Comparison with the two post-R8.1 judgments:

| Dimension | Astra post-R8.1 | Claude post-R8.1 | This audit | Reason |
|---|---|---|---|---|
| Trust | 5 / MEDIUM | 7 / MEDIUM | 6 / MEDIUM | Deletion and session preservation improve; false attribution and persistence mismatch remain. |
| Accessibility / robustness | 5 / MEDIUM | 7 / MEDIUM | 6 / MEDIUM | Native-type and reflection repairs are meaningful; no new device/accessibility run, and new boundary defects remain. |
| Routine ownership value | 9 / MEDIUM | 9 / HIGH | 9 / MEDIUM | Kept ownership and lapse rights preserved; confidence limited to reviewed source/evidence. |
| Pre-release readiness | 4 / MEDIUM | 6 / MEDIUM | 4 / MEDIUM | The exact baseline still violates explicit integrity requirements. Strong logs cannot remove that blocker. |
| Overall product quality | 6 / MEDIUM | 7 / MEDIUM | 6 / MEDIUM | Coherent product and substantive fixes, with unresolved cross-store semantics. |

Source: [original scorecard](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/docs/audits/THIRTY_POST_V2_INDEPENDENT_AUDIT_GPT6_ASTRA_d89a035.md), and the two verified original post-R8.1 reports.

No historical total or average is invented. No new aggregate engineering score is substituted for this framework. Product retention, willingness to pay and commercial quality are not inferred from regression simulations.

## 12. Remaining engineering and commercial blockers

### Engineering baseline blockers

1. **N01:** marker repair can repeat a prior I1/I2 change and override a later manual choice.
2. **N02:** queued manual exclusions can become false I3 application history.
3. **N03:** confirmed in-memory Start entitlement provenance can differ from serialized/restored provenance.
4. **N05:** the waiting Start continuation can violate the old-day offer rule.

N04 remains a bounded preservation defect and keeps the broad A05 closure partial. The report validator's raw-log blind spot is a separate LOW tooling limitation.

Acceptance would require independently reviewed evidence addressing these exact counterexamples. This statement identifies acceptance criteria; no remediation was undertaken or authorized by this audit.

Native process-kill/delayed-acknowledgement tests, explicit stage-5 boundary coverage and disposition of the documented limitations remain evidence/product work. They are distinct from the demonstrated source defects.

### Commercial blockers

The technical baseline is not accepted, and passing it later would not authorize release. Phase E remains HOLD. The existing release gates still require their own evidence and authorization, including the applicable device/accessibility checks, live billing and configuration verification, privacy/support/export/migration decisions, the pre-commercial RL-4 disposition, and the existing content/safety and release review.

This audit does not claim those external gates are fulfilled, nor infer that external configuration is absent merely because it is not visible in the repository. Simulated users provide no willingness-to-pay or real retention evidence.

## 13. Final verdict

**FAIL.**

**The R8.2 technical baseline at e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8 should not be accepted.**

The immutable source and definitive regression package are consistent, and many original findings are fixed. Nevertheless, the exact committed source still permits repeated Insight actions, false application attribution, a persisted entitlement-record mismatch and a pending Start under an expired day identity. These contradict the required integrity baseline.

This verdict is based on independent source analysis and independently verified evidence. It does not pretend that the new Flutter reproductions were executed.

**Commercial release remains unauthorized. THIRTY Phase E remains HOLD. No R8.3 work was started.**

---

## Appendix A — Exact definitive test inventory

The following inventory is reconstructed from the committed test tree and raw reporter events. Counts exclude hidden loading events. The year-long test file appears across five disjoint batches; its cases are counted once each.

| Test file | Counted cases | SHA-256 of committed bytes |
|---|---:|---|
| test/core/analytics/analytics_consent_test.dart | 7 | b614dd4e9f66ac65733aaea7e49e201391bdd613212e4217cb0eb782d850241d |
| test/core/analytics/analytics_service_test.dart | 2 | c144160e2cda8c83eb347a694f3b9efc40f2d8f62c6fd014dabaf3cfd6a32dfe |
| test/core/analytics/tester_identity_provider_test.dart | 6 | 77eb08ac94b6df728bc5c891b00d13dccb9cef50b70569b359be9e9c0a412a48 |
| test/core/android_identity_test.dart | 6 | a834d178b2776b0dea8b296aa2e7d6a7608ffa3a9906a9264242d57645cc6e3a |
| test/core/app/r6b_day_rollover_test.dart | 7 | fb4620feb9ce2cb1b5fc95ccba8ecfbae9816e435fde065434b48b32fbffaa73 |
| test/core/app/r8_midnight_resume_test.dart | 9 | 592be225013cb8512decb06418767f1fe774603222f26762d494b75a2cd74336 |
| test/core/app/thirty_app_test.dart | 3 | 69ff34cd7cecf6b89d8efb52bdfc505f2b128f1ae0160d527619482f4ac2c6e0 |
| test/core/branding/thirty_wordmark_view_test.dart | 5 | 8120113ab9d524368e3492a54debb136567db4ef7d2e2076fbcf05649ed516ac |
| test/core/config/release_info_test.dart | 1 | 83059535b49e96c9ec9c24d991ff075d780cf8804ddd01ee7edc9e9e2de599ab |
| test/core/config/revenue_cat_config_test.dart | 13 | 27d31254eabf99ab56519657f6de8bfc4649632db9f6d97e806a963fe33b52e3 |
| test/core/config/supabase_config_test.dart | 6 | 587a6bad5f6c98c746a68bdf4b50984482f6b0c5d0d0a06541afb4f22c7faadc |
| test/core/premium/entitlement_gateway_test.dart | 11 | 649fdecfb4588f035d975b9d48ae68775c6646a51b6bf0539584bc33cf8d9f9e |
| test/core/premium/premium_access_test.dart | 19 | d5ff23d1adaa2c156bec7df0df6836750c06a9bb1e4079df5f14a341b6c6e236 |
| test/core/premium/r8_restore_wording_test.dart | 3 | 39936a3167eac46e3b213809e523de67c45ebf9e242a122ba84d0ff91f138f20 |
| test/core/premium/revenue_cat_entitlement_gateway_test.dart | 23 | 03f3acca4731da119dbf45abc7c15b31e5a0e39808eba893e9e9b4a73c0c05e0 |
| test/core/providers/clock_provider_test.dart | 2 | bd44a74fef95f6d7c02ed7386e2b878a4d85260512d53c8f7d5dd841f5c4382b |
| test/core/providers/shared_preferences_provider_test.dart | 2 | 9797e4f9394bf4a613a5f4a265e73158078a084fcf37738792dacf1258f23814 |
| test/core/providers/theme_mode_provider_test.dart | 13 | d6138bfc910598158b3c263ffc606e54890188e143066cb7405af8790dab8a86 |
| test/core/qa/qa_entitlement_gateway_test.dart | 5 | 43fc9caacfb1d4e1dc6734878fec2d0d0c23a8b42a29e38c4230dd0b61a0dd9b |
| test/core/qa/qa_free_v2_scenarios_test.dart | 6 | 2f3382f2b18a3b449f418ffa4b8aad128ebc61fb60f952cc1e1aca287347de84 |
| test/core/qa/qa_isolation_test.dart | 5 | 868ed5a6004db20b893fc607b0d90797c06c33f5a4f340a5a26c1e83a5a7bba5 |
| test/core/qa/qa_phase_c_scenarios_test.dart | 7 | a88a089de7f86ccc2344f95f6cce8eb0498f2a192501b64e81aea51d4d43879e |
| test/core/qa/qa_premium_gate_test.dart | 7 | 00425c53bf79676e4858a6882241715a101db89cc5e9e1a05cea8119017dd1b5 |
| test/core/qa/qa_premium_harness_test.dart | 7 | a1a7536dcac40eb22752b76f3cd2a9739b6b39df5e1579394ea0aec29d768b62 |
| test/core/qa/qa_scenario_test.dart | 15 | 074619f3a60ed82affc37c62cd7d57e0d0946ff72cbc6155f846b6a10fe58a35 |
| test/core/release_build_guard_test.dart | 6 | 24462dd8cb770071f42387add7f547611130d2dbc33df7a5036fc5e19d5091d0 |
| test/core/reminder/local_notifications_reminder_gateway_test.dart | 7 | 010cc47fde378eda080930ca50f4cf1aff34d09769bc9f165ffe58a9a548c80d |
| test/core/routing/app_router_test.dart | 10 | 74f025254443f3f94c9c16e68be97eabd8d9621fde7e2b0756fa3bdb1962d57e |
| test/core/routing/app_shell_test.dart | 8 | 065c7613cc526cd49bbe9ecc95d4bde9622bbb1bcb799175fa1e5aa102271509 |
| test/core/routing/b7_four_tab_shell_test.dart | 25 | 3df38296d897c37e816b6b62b5af89d77b8dfc94dd929843ad9b146f0c55515d |
| test/core/routing/floating_nav_surface_test.dart | 6 | a7044fdd6286d1028925108649bd5116a8b2d12f6bb26de9a31542b5fc310b35 |
| test/core/routing/premium_billing_navigation_test.dart | 4 | 47a224ab0286a0c4a0a15ebab449b321768ae7e336e115c389ec9b5c1ef15dcb |
| test/core/theme/app_colors_a4_test.dart | 18 | 4acf98400ff8bb40ea174236005e98bbf4742ae2cd322f26a50b864e1764a173 |
| test/core/theme/app_spacing_test.dart | 2 | 22456b8e08b9f0cf72af48fbc19909b487bdd527afdbce9cdd7667c2bc7dd235 |
| test/core/theme/app_theme_a5_test.dart | 3 | b625a8ed17b9093d9c31ec19a214fe2838a913fbb1a9b92152d09270f33aa9d8 |
| test/core/theme/app_theme_test.dart | 17 | e6d76120915f06e25c274e58a32c55181396f85d0c10d7c13006315598290a4c |
| test/core/theme/app_typography_test.dart | 6 | b973235359c6af5630bc4f48b64c95910c2360a42499f7920edee0923e9ebdb2 |
| test/core/theme/snackbar_c5_test.dart | 11 | 8dd96cb5937c3a1f53d9be89d628ca65e2d813810c13a2ca4a2f62df6abb5ccd |
| test/core/utils/date_key_test.dart | 3 | f05a198207ddc24fa53fd6de114565beba57cd12a2226fc0a20d91805e700383 |
| test/core/widgets/r6_button_busy_label_test.dart | 5 | c2a483eb273b86d3bc71a5e87c75c518968a84ecff2d1b74cbda4a2bb1210010 |
| test/core/widgets/thirty_app_bar_test.dart | 14 | ab342d926a5910b297093874f62e9fe28445d78e68f3a2b6b017b6347dd706c1 |
| test/core/widgets/thirty_button_large_text_test.dart | 42 | cd3d81161b9f7ca67a0b200c9335f74319b6ee7a1d0e3b278646b71853c8533b |
| test/core/widgets/thirty_button_shape_test.dart | 8 | 32074f7bfafe0777d86afc48c13f2e04f955da2525f1aad9645757f8d466b298 |
| test/core/widgets/thirty_button_test.dart | 18 | d791e2fca5be527c5b9d60796145148d5413baeac4e52103f097ceaeabdb3c30 |
| test/core/widgets/thirty_card_test.dart | 8 | 55792b32a4a9ade8cf1d6df6476211104a943ce7637ff8e8154bbb64f6ceed5a |
| test/core/widgets/thirty_confirm_dialog_test.dart | 22 | b266291a0f3b230d070278587f14fda63096bb91299ad198530c11f129dc4106 |
| test/core/widgets/thirty_progress_circle_test.dart | 14 | c151e238316e6bf98804e30a31646912b3e17af3fe034dfe9a2d17fdcafb881d |
| test/core/widgets/viewport_visibility_test.dart | 6 | aa2d5218e11cff18e8a623cf14aa0721e2b530b247829be31419581bafa915b2 |
| test/core/world_rendering/quiet_trail_hero_asset_view_test.dart | 5 | 8075955ed503a0b57db0b8a0e6b740a14c74c8be530cf8464706d3369a96d6cf |
| test/core/world_rendering/quiet_trail_hero_view_test.dart | 6 | ca9b572e7a76b46f34d66d688f9277d6ea47de4f7997926020689396d615e644 |
| test/core/worlds/catalog/quiet_trail_test.dart | 3 | d6ab09b2028a8d035375e6f299a30d10bd4b33ea1e863adbc1ed1568c5571ffa |
| test/core/worlds/daypart_test.dart | 9 | 5d0f64cf9e8c628730245b99c62438dfe586f7a9ca8b268e70538de192646420 |
| test/core/worlds/place_test.dart | 3 | 287fd02761661cc5dd267a02aff9c236ca0f6d2e80c1bdf71162bc6e53672e21 |
| test/core/worlds/reference/quiet_trail_hero_scene_test.dart | 13 | 98180f0e7db9a7e5063aeda7d6fb65383735ae2285e1e6eb096f5172e8e94b68 |
| test/core/worlds/registered_worlds_test.dart | 4 | 33868d1ff783192599a299ff100f9b6ddf397eb69203330181f7eed6a5410be0 |
| test/core/worlds/world_art_manifest_test.dart | 12 | d8bde56e190f13b3eea02a305ab47a97d86006bbce74539365f84099e732a744 |
| test/core/worlds/world_registry_test.dart | 15 | e30da15c83b53443b5e9b7c595e9e4d106249936c90e940e5a002137b82e6782 |
| test/core/worlds/world_scene_policy_test.dart | 4 | eb0049c694667b54760b7878673ccd2042b5e6e4d4102e4fdeb892cbab3f844b |
| test/core/worlds/world_test.dart | 9 | e56edaf955f8b16ef3d049676ce040e74868bdc2b74faf830af9a571ff157f45 |
| test/features/b8/b8_delete_longitudinal_test.dart | 5 | d2723c7c46158a0ee4e4ae0443706f596913b2dfc6cb0acedca082b2d5c56566 |
| test/features/b8/b8_live_copy_guard_test.dart | 11 | da4475fbbf195bb852763953a6c86caad235ff9eb921c6ef42467c01d1a842f4 |
| test/features/b8/b8_plan_attack_test.dart | 6 | 43d2a1f189d6966bdf3164f1aecd84c2762b06248a6d4b8c91ed951cbba81f0a |
| test/features/b8/b8_product_simulation_test.dart | 6 | f131146d4a13e1132ab40b48055bdbdb8643184e0f4d3c04b342c7129aae6cf2 |
| test/features/b8/b8_review_pack_test.dart | 1 | e1d9176ed61dffb2380fd522dd624eb081e02674893ce0c444a770a89ea49f70 |
| test/features/home/application/activity_catalog_test.dart | 41 | 2e980a3f65882797c0a6140de4a2ca5ada8f9319fab66a3bf30d200ff4af8c02 |
| test/features/home/application/circle_journal_test.dart | 23 | 7fa873c45ef35216eddc9403bf062cc8f762dafa6c158db6e213e83fdb9bfa00 |
| test/features/home/application/circle_session_lifecycle_test.dart | 12 | 574bbf5c07582178c83f1456678bf11c69446e87ab942861d647f891ee6760bc |
| test/features/home/application/first_breath_provider_test.dart | 4 | b54a4cdc381e6b289cf4f77292b87b86c8e2c77991e61225d9bc6099b9ce41b9 |
| test/features/home/application/recommendation_provider_test.dart | 55 | e05578bbe715b6551a40ae6981aff1818b708eccbbb9e0cd140ce89b05bd5114 |
| test/features/home/application/recommendation_v2_test.dart | 10 | e2c341542d154ffbb05840f3943990b300bca9e51eefff56751a7f0a91d747fa |
| test/features/home/application/world_scene_resolution_test.dart | 22 | aaeab372d7ea376f41947a720ba9678e625a790d93f6c78fea299db195d79881 |
| test/features/home/circle_greeting_test.dart | 33 | d5a51aba81f9b56bf39498b291baafd21064938ad6ee0ddd020cc3d74428d4da |
| test/features/home/delete_circle_history_test.dart | 8 | 6ad033489e8d9d3510fa9a19ca0e4d351531cafd777f35edc453196f20fd3a8e |
| test/features/home/domain/circle_session_test.dart | 15 | 1d34f4e37264cd982ec0d70f9c48821271a1d0d5d1b3af37f73658aeea383b7c |
| test/features/home/domain/recommendation_engine_test.dart | 27 | 0818ccf743f27cb14a1ab6ab39f685c85c34b63309ef0e0a9ae92260cf6ce8aa |
| test/features/home/domain/recommendation_simulation_test.dart | 10 | c1aa74d4db1837577b397eff6c1417ac0a642a52c60e3562e7eb039584614065 |
| test/features/home/domain/suggestion_controls_test.dart | 14 | 390b25220a210fd17a7b54a06025d69c44b1a98cdde30d5accef06078c351d46 |
| test/features/home/greeting_one_line_test.dart | 25 | 70b6b696e64ec95ca755625cc88490eedbaec76797be7b9fe14fdda288e25195 |
| test/features/home/home_cta_nav_layout_test.dart | 18 | 6bb0439da374c729c4d0c061f6f245f10cfcd28bfc85ad2896890a0b778e5c3c |
| test/features/home/home_invitation_session_test.dart | 12 | 5efb46549cba8f83e07ff199b5e4014afb3e6a977c9ead74ba14a6ebebb3d61b |
| test/features/home/home_page_b1_test.dart | 13 | ab78e5a4de380df07be3def2b6afa78d63296327e38413a8ef37354e6293d056 |
| test/features/home/home_page_b2_test.dart | 20 | 3d38ccaf578a47833aa76ec6149d2136fe0f2e8a47a2ae5d4b12ee34e38a95ce |
| test/features/home/home_page_b3_real_font_test.dart | 28 | f65c9e9bd0f1fe24af638e952f23f6ca015162e5daef123ab9d37b20f7fcdabe |
| test/features/home/home_page_b3_test.dart | 27 | e19b3d500b50f6d28a33fa8b06710540ce12ac629c336c749bd4cf0dca61e6c0 |
| test/features/home/home_page_d1_test.dart | 32 | 96a3fa0ee3a1ddb011f91c09ff4fd1b96984762f30963a2acfd6d8e6f2c8bd86 |
| test/features/home/home_page_test.dart | 8 | f711b16a37584792272d01e6be2378ceca54156d268a96a2374af0fbdb244704 |
| test/features/home/pre_release_retirement_test.dart | 12 | e7e58020bb834f6d8aeb5579b3b0569f8e7df607d40051c77a2944a729bc299e |
| test/features/home/presentation/circle_history_page_test.dart | 9 | 4e71e602589d339fa03a0cfc105bf9305e50cef0be49cf058d37385abe49b17d |
| test/features/home/presentation/circle_record_detail_page_test.dart | 3 | d2cc29997c0a8f2d579b8e19705e74f05daae2ece3aed4c937d16010a7f219d1 |
| test/features/home/presentation/phase_c_memory_ui_test.dart | 12 | 1393f5c86993ce342691bb771702238b29f016635edd9a61705fb108eda5282a |
| test/features/home/presentation/phase_c_talkback_test.dart | 9 | b501b6fc03e0390336c659e8ead8f07e0f98cc6132fd4d9ac555a7ae137f0975 |
| test/features/home/presentation/widgets/activity_guide_sheet_test.dart | 8 | 04cccdcf2fef46b2ae61c973a7ca500907a8a1fb01f199fcf3d709e9e09997ca |
| test/features/home/presentation/widgets/circle_hero_test.dart | 56 | fb788c5ed6b0f0aa849e7f5eff376efcb48f9c9fa1b89e29bec7fe622adccd4b |
| test/features/home/presentation/widgets/circle_ready_prompt_test.dart | 10 | 0d997d3e1229914ad65bbc438e6059e546c3ac218b4d403574b6c7ab8a90ccd1 |
| test/features/home/presentation/widgets/circle_reflection_card_test.dart | 11 | 7ae59999dc6df176cf4dc79abb1efef1f3858faea88ec202cec3e08c5922249d |
| test/features/home/presentation/widgets/daily_intention_prompt_test.dart | 6 | 335e92de3b994539b4f15ec149aac8e4db730bbfe66944933cf7c778e9f928ee |
| test/features/home/presentation/widgets/phase_b_ui_test.dart | 10 | ef0a2840d7ce1010af56977f2f209674c9ada59e5c3b9fdab6aa6e5cd13d1481 |
| test/features/home/presentation/widgets/phase_c_session_ui_test.dart | 22 | 6dc3ac3d29285675593c4247d7f3fbf393b151b5f0bc3c464d3ae8cdee456560 |
| test/features/home/presentation/widgets/premium_offer_invitation_card_test.dart | 5 | 8cf541f3e00141207372d266ee6bb50bbb04f59d9791a2a8d47f20c752a4aafb |
| test/features/home/presentation/widgets/today_card_test.dart | 8 | 4d0fda45fd243140b4a99951300a33442f80187997eb9a49d0249768966d1c35 |
| test/features/home/r2_make_today_circle_test.dart | 22 | a83141b394afc8ce07e4ae28afa66f055d5217919b088a54d7467fe8bf075d3f |
| test/features/home/r3_delete_feedback_test.dart | 10 | 4e1906884f5605392260730779c0def726eb9deda619b45eac04cd6f56bd7f97 |
| test/features/home/r3_persistence_delete_test.dart | 41 | b2746dbc1f2a76ecaaa57dcb26d9dffb7bb242ba9c905b33feab28446c548877 |
| test/features/home/r6_free_copy_test.dart | 5 | 6393a4706853546771cc20aac8321c51ad4142237f10029c87417dea2bf6060a |
| test/features/home/r6_journal_save_failure_test.dart | 9 | 19a0c6850c8d287e055c4e3025aaa84a09db36b379a67db9e507d5ce32cf7a32 |
| test/features/home/r6b_journal_unreadable_preserved_test.dart | 4 | 3487ed47f3dca2294472070d04b840c6c87383c1c8858dc7c34221d84d0e8172 |
| test/features/home/r6c_journal_store_safety_test.dart | 11 | 8db6d25b161381531fc353e09ee9dd6feee5cfd3d127b8393e84025d4f979204 |
| test/features/home/r8_a01_daily_persistence_test.dart | 13 | 3e7c832622f9b0ca39456f57619768d9d0ee24b2850540d5e15d76455dc59124 |
| test/features/home/r8_a04_delete_durability_test.dart | 14 | 2062bd89edbd6a0eac620497a5f6fb3af56ded9b03892c7798cb81d427b2a820 |
| test/features/home/r8_a06_unreadable_history_controls_test.dart | 9 | fe8fd3bdd27c9002bb6e0d43afbe020dee3841fd68108d76e61d95381d738a8c |
| test/features/home/r8_journal_forward_records_test.dart | 2 | 39d66f659d9571e2f5f8e16c2c674aac8817ca0c4d42ddb6dfe3c80d03d7f09c |
| test/features/home/r8b_notice_copy_test.dart | 2 | dd8674261fb5bfa7954f53eb76082a8df8c15c36f7fb9a50cacb2e20773a319c |
| test/features/home/r8b_precommit_persistence_test.dart | 34 | 9b8c1be480664fee32a531dd7772b2fe8b2aa498b8186307ed862457c9e94166 |
| test/features/insights/gentler_feasibility_test.dart | 50 | 067af22aa2f57778697613c8f3af3bbf64e780bab16965cef8bafc8e80ea5c78 |
| test/features/insights/insight_engine_test.dart | 80 | c9597927488239ffe1d23c8186f80bdc54bc74b980ce6428a64f82943f0f318d |
| test/features/insights/insight_plan_review_test.dart | 7 | 6a9368a0a00167f8a3d92ef89d7530648ef1ba4d0a9894bc221ed39125667dda |
| test/features/insights/insight_simulation_test.dart | 7 | 2051f20bafcad07b0cae4ed2fb5c04b2e9539f4930def9adfc84c28abef2b4f0 |
| test/features/insights/insights_service_test.dart | 25 | 2a30de95711a45b3ff827b237b90bdcd6b910f922a2c05fb8bb178f385eea8bc |
| test/features/insights/presentation/insights_page_test.dart | 29 | 8986322af4783d1863feea9e7d0130874ed090e3a955cd4dcdc2918dbcaa8621 |
| test/features/insights/presentation/widgets/circle_history_calendar_a11y_test.dart | 11 | ae812795c19075dac3f986259fd5e02a19523cd179ce2d5c85f26a3d8d155146 |
| test/features/insights/presentation/widgets/circle_history_calendar_states_test.dart | 11 | 5e63d4c59851bc98913617cd0a62e309d62f2297b4c28b3618e071fb2bf93df6 |
| test/features/insights/presentation/widgets/circle_history_calendar_test.dart | 12 | 06b16622136b3e84d5b7cfbe0c5b70e117f84c7e4f0cbbc184805ecc3640694f |
| test/features/insights/r5_i4_keep_after_lapse_test.dart | 13 | 6aea0b12b78bac6ae0c43cb2cb7ada43216f1fc055fde9d2dbaad2b50b477165 |
| test/features/insights/r6b_insight_dates_test.dart | 10 | 536ada304fa6056c470f0d1b2379b5c3dd94a434e3232f31d252c6b780b0ce80 |
| test/features/insights/r8_f4_insight_dates_test.dart | 12 | f9f6a46c6a1ba08be3df4793c1872ba5c14352e19f74ecd12d61078886001b12 |
| test/features/personal_circle/circle_composer_test.dart | 26 | 003ba9436e267f3fc5c2b820f376293379ffea6684e8cb5243baff105e860abe |
| test/features/personal_circle/circle_elements_test.dart | 21 | 56aa9c2fc7a6c8bca287e783d1d37622b1914ea91b6af9b78041b8cb0bc8daf3 |
| test/features/personal_circle/composed_ui_test.dart | 33 | e36cf5c6b30f3ee0e343779acde522148439dd07a24fbf9a59982f46ed40ffb6 |
| test/features/personal_circle/composer_baseline_equivalence_test.dart | 1 | 938c64e217d8747dd0e27c710c4cb5e657283d770b2e5f7595c75ea451f94856 |
| test/features/personal_circle/d2_review_pack_test.dart | 4 | be1c131cf9c221897df45676134dc97e53117b4798962f253a4d03b5be8aefcc |
| test/features/personal_circle/f02_f03_framing_lines_test.dart | 40 | 368dd45362194fadcebb34d2b08714c36b05f936109578eadaf8367cdd021259 |
| test/features/personal_circle/guidance_entitlement_test.dart | 13 | ab8a92c6bf9e69362cf984a511fae5f551b0b4091a64cfb4d54209ad0688c291 |
| test/features/personal_circle/guidance_session_test.dart | 2 | 00ef30be2a09a9f26e59259dccbf0c0c0e011c6136a9cdeba1aa71d3c52cd478 |
| test/features/personal_circle/personal_circle_simulation_test.dart | 13 | 35de8a8cc1efaa8f1e4e239b1c4cd4fba78e89f89a5dd318ba732800c62a74d4 |
| test/features/personal_circle/premium_today_test.dart | 16 | 11331994ffd64956761f0bfb8e9ee533c65d9ff8f179456ca049b9e14adcc256 |
| test/features/personal_circle/r41_kept_store_test.dart | 12 | 7662e36f2760f595db58339d1b961ca4b8d6cd111fbd5bdf77951dc8cb88c25d |
| test/features/personal_circle/r4_kept_ownership_test.dart | 25 | fdcb690959e3445f2a36b53ef86f0363414b651ddb9ae7590ce63bc19ec755f6 |
| test/features/personal_circle/r6_kept_voice_whole_circle_test.dart | 8 | fecb7f781eb9b3a93aee181d46aafa876c11d6862d99607aa87c09f5c0e48a89 |
| test/features/personal_circle/r8_kept_ownership_persistence_test.dart | 32 | 3c67c32c9deec63c2e83bf7c5070cfec6d8578bbc0d406b1c3079f10789e6698 |
| test/features/personal_circle/saved_circle_lapse_attack_test.dart | 1 | 9e61e16edf520f6b762f89fe9b97a3951d6aba1046c3ee7aa5692276e489dd2e |
| test/features/personal_circle/stage_brief_test.dart | 78 | 2468dbde2ab76609a5de7bcdea4b4b49821a0406bf07aa2e9e4123ed34f77beb |
| test/features/plans/circle_plan_domain_test.dart | 29 | ae638e3d8f56cf470a089a698263d974de7cf175aca5bc0d78351728641e7ddb |
| test/features/plans/circle_plan_today_test.dart | 24 | abbcdf28385d29d6b95beab481564cd9105977943e09fa589a9a420dae08c47a |
| test/features/plans/plan_copy_guard_test.dart | 2 | b678f4ef4b3edc6eb0b80f29397c7863af2f704c1019dba23027727782eff9c3 |
| test/features/plans/plans_surface_test.dart | 29 | 655134145cb9dd2fd0f4166456ed871b2e87462d721f88726a9a1d50fca572d0 |
| test/features/plans/r2_plan_credit_provenance_test.dart | 26 | b20485fe8c20de469e6af52b214f62d5ffec827221222edcc9a07dca3697bdba |
| test/features/plans/r6_stage5_end_line_test.dart | 6 | 7f4329043f1b4307be38af8273443afc1f55fce7dd23d8f82a4a880e3af2dd3e |
| test/features/premium/application/premium_offer_provider_test.dart | 8 | a4813608157a77957741f6834d1af2526bf4bf17b9d4895296218459e873cda4 |
| test/features/premium/b7_entitlement_matrix_test.dart | 40 | defd628df7977fa0a7fa6ded5c32c6bec145d1cf6e699d661fa0fa0052e61dec |
| test/features/premium/presentation/premium_offer_c2_real_font_test.dart | 24 | cc3d480182a1af35e42d6eabadf67241f3c24f47716ac0c76c5158fd0887bad5 |
| test/features/premium/presentation/premium_offer_c2_test.dart | 13 | 449430d5508a3f91cf0ea479afe7cff839b62e9fe934b5cb3ff49c80b119968d |
| test/features/premium/presentation/premium_offer_copy_guard_test.dart | 7 | 9b040784682c7a8dc64e0f59499720c26985a76f8dda6bafe08a4154a668fe1f |
| test/features/premium/presentation/premium_offer_page_test.dart | 11 | a577755035d0d12ea7e3fafc82611603cd862c9d88f15a2ba30ec970ef748c6d |
| test/features/premium/r6_purchase_busy_label_test.dart | 1 | fd37dab226143fa3495ed00c086810f4a0f5de602960a8b09ea1dc247d87b6a7 |
| test/features/r81/r81_n01_durable_plan_credit_test.dart | 8 | 338de224e750949a38095d22ef77fdd9c8f31f992b1d6eae2c8683994c4429ae |
| test/features/r81/r81_n02_preservation_writes_test.dart | 10 | 8110847360383f4780147a24af68776c13dc563f07253ad1d2275c8b1147d6dc |
| test/features/r81/r81_n03_removed_answers_test.dart | 13 | 8fd97c44f5e2c4577231853490a3a7edc6958348975003ee06645d66856716d1 |
| test/features/r81/r81_n04_n05_expiry_and_insight_application_test.dart | 18 | 6504021e2a310a9c3965189adb50fcf0995494a3c7b6b55c413c9fd92db2d585 |
| test/features/r81/r81_n06_n07_damaged_records_test.dart | 21 | bf3107e5db231a59f252abf6492f8371f382cd1e26245bbc362aac8cba61f13e |
| test/features/r81/r81_n08_n09_aud2_time_test.dart | 8 | 34b369225dd6cf93fb11e571541cdfc1b295e59a38fc1289e8e6c0030dfdde6e |
| test/features/r81/r81_n10_failure_notices_test.dart | 5 | 96b03823ebe3e3787eebfa38f6d7e00f30836383532a4cc8606def51973800bc |
| test/features/r81/r81b_rl1_pending_state_test.dart | 17 | 0fcb85778919a2ae7f29e25ff223b11a107c4d504422be5c163ae24714257a7a |
| test/features/r81/r81b_rl2_unverified_words_copy_test.dart | 3 | 288f869a3ccb804234c282025dbf8e404148d7ee776b8cbb6486f8922c583929 |
| test/features/r81/r81b_rl3_field_preservation_test.dart | 12 | e9612be58519fda5eac8fc0450547d60bb753a085cf36b0fb6e8228a37ed4983 |
| test/features/r82/r82_a01_pending_lifecycle_credit_test.dart | 10 | dec983910b2d4ca7965a1f50203c1d325e09ccbe12713bae684b8744096fec12 |
| test/features/r82/r82_a02_new2_delete_isolation_test.dart | 10 | 256c3a287a01201c08359b3e4b63aaed23d99ea98944f09091c4939e499f2e07 |
| test/features/r82/r82_a03_new1_stage_publication_test.dart | 15 | a5a8342ec64b86115ebd6af24f17c271519f7f791b2bc79f59ca07b034a6d826 |
| test/features/r82/r82_a04_a08_new3_insight_actions_test.dart | 25 | a18dbb8134493e78590f917a9a8ef6a7f9b6fe3e01affc2dc6e8011adbed5436 |
| test/features/r82/r82_a05_nested_fields_test.dart | 8 | 628b7376628e2bcb74a9278c089a61380079e9214d4a6f18c1aeea902f3c54f4 |
| test/features/r82/r82_a06_reflection_completion_test.dart | 8 | bd90d5e33295ff994a55807bd0644f789b611f403cd645db9cc5f1d626fe2a2a |
| test/features/r82/r82_a07_confirmed_history_test.dart | 7 | 392112a0f2c39374f184e510b9836cc399988cd8ed973cddee76ccbeabe272f6 |
| test/features/r82/r82_a09_native_types_test.dart | 14 | 76e12038e04d07f665639b9feb0304245d5eef34ccf26e20f348e4572b3291e4 |
| test/features/r82/r82_claude_audit_new1_triggers_test.dart | 5 | ee7aff28c639db44e30c773ef54a9323b98590e610bc00956700413f2ada38a1 |
| test/features/r82/r82_cross_store_adversarial_test.dart | 6 | 302ca521b1fe7ed6ac12a7e3c64460b7c42ec04b5c4db0be600c78ae08bf8e2e |
| test/features/r82/r82_decision_a_historical_credit_test.dart | 18 | 4250f63859444a5680ded8b4aa0b01d996525e7a409fca359aefac9eb98d5dd7 |
| test/features/r82/r82_decision_b_start_persistence_test.dart | 15 | 9577369d945a099d11e02b4faf2c2279b9f5155ef6f32e0c57f6c7a2f704412c |
| test/features/r82/r82_decision_c_insight_provenance_test.dart | 13 | 862f2aaf3b01183629633964d06d4c8b45642017fcb7ccb065ed34117c870c6e |
| test/features/r82/r82_lifecycle_policy_test.dart | 21 | d1317faa76bce226c6073140406c8227392895df26d82927d14c55814e05ca2b |
| test/features/reminder/application/reminder_after_close_test.dart | 17 | 43af0afa3231deab0b537d9c20c796054645fc5c36241b1c4bd49e88af353bc0 |
| test/features/reminder/application/reminder_personalization_test.dart | 27 | 3f58e78b639b6c6cd86399f715c37a519ef742bf3a5bd33371fd8a7705629ed3 |
| test/features/reminder/application/reminder_provider_test.dart | 24 | 68297061e41337f93b3ff7d10bfb62deefd162f08ad3fe23ae29805271e4c599 |
| test/features/reminder/presentation/widgets/reminder_invitation_card_large_text_test.dart | 9 | 4f0c79e5943a7a9232009d1b0dadc8b92195456c3d1f5b95bb278a8fcb6b9d92 |
| test/features/reminder/presentation/widgets/reminder_invitation_card_test.dart | 7 | 86a3b190ff50494471fc16f852d74e793c758417c37018598490abc7d1a19c56 |
| test/features/settings/application/first_name_provider_test.dart | 23 | 02bacc68fca7ae293bd67dc2b41d457afd458482e84f83ce6df1a614d44f44b1 |
| test/features/settings/presentation/first_name_question_test.dart | 53 | f2bea403d01d8cd5962253d3a1f233ed8da6b09a92b186b9d344658d17b64a58 |
| test/features/settings/presentation/settings_page_test.dart | 16 | f5ec132ad737882292ef336b247b86ca814477212147e3b015cc16b627832959 |
| test/features/settings/presentation/you_b7_hierarchy_test.dart | 3 | 7be295fc0dfad71a1d8d77386086a7972f1169f840878d3018955da9565167f2 |
| test/features/settings/presentation/you_c1_real_font_test.dart | 20 | ca00e0fc09a55f39d0422d06eb270df5c036ea5efc6a55a4fcdc4c5b959413b6 |
| test/features/settings/presentation/you_c1_test.dart | 14 | 8b5b7ac478d10f0477772216e229dd4ca14584becbd68c78cdcfbf31983185ae |
| test/features/settings/presentation/you_first_name_test.dart | 26 | 70d2aeb9641b4b18395b44a4882ae000387f704a5820b84a12f5fe5613c68b82 |
| test/features/settings/presentation/you_north_star_test.dart | 50 | 19227e895b238ebe97a72d5053ae6070e04efb7796b65a6cd67974b44172bb39 |
| test/main_test.dart | 2 | f38a98965eb0f11ce3bd7087dd08b87cf57593bc72dc5640b9ee75966f69e400 |
| test/widget_test.dart | 2 | 1f90b092aaf5715df2ed7596c31cb1b6bb8314cee00cbb75305e74b2ed76b615 |

## Appendix B — Proposed adversarial reproductions: NOT EXECUTED

These seven cases are an audit artifact, not repository modifications. The fixture setup is reused from the target's decision-C test. Relative support imports assume a separate disposable project copy with the file placed under test/features/r82. No compilation or execution is claimed.

```dart
// Independent post-R8.2 adversarial specifications. NOT RUN.
// Created outside the audited repository. No SDK available in audit environment.
// Fixture setup reused from the committed decision-C regression test.
// Relative support imports assume placement in test/features/r82 in a SEPARATE copy.
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';
import 'package:thirty/features/plans/domain/plan_stage_provenance.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';

void main() {
  final morning = DateTime(2026, 10, 30, 9);
  late R8Harness h;

  setUp(() async {
    h = R8Harness(morning);
    await h.boot();
  });

  Future<Map<String, Object?>> json(String key) async {
    final raw = (await h.disk.stored())[key];
    return raw is String ? jsonDecode(raw) as Map<String, Object?> : {};
  }

  CirclePart part(ElementId e) => CirclePart(e, elementOf(e).minutes);
  final window = [
    part(ElementId.openWindow),
    part(ElementId.standingStretch),
    part(ElementId.sitAMinute),
  ];
  final reading = [part(ElementId.phoneFaceDown), part(ElementId.readPages)];

  CircleJournalEntry entry(
    int ago,
    Intention need, {
    List<CirclePart> parts = const [],
    Set<ElementId> skipped = const {},
    PlanStageProvenance? stage,
    PlanStageProvenance? replacedFromStage,
    String? reason,
  }) {
    final date = morning.subtract(Duration(days: ago));
    return CircleJournalEntry(
      schemaVersion: circleJournalSchemaVersion,
      circleId: dateKey(date),
      localDate: dateKey(date),
      direction: need,
      activityId: ActivityId.values.first,
      catalogVersion: catalogVersion,
      shownAt: date,
      startedAt: date,
      closedAt: date,
      replacementReason: reason,
      replacedFromStage: replacedFromStage,
      session: parts.isEmpty
          ? null
          : CircleSessionRecord(
              title: 'Circle',
              parts: CirclePlan(parts).toWire(),
              skipped: [for (final e in skipped) e.name],
              planStage: stage,
            ),
    );
  }

  String journalOf(List<CircleJournalEntry> entries) => jsonEncode({
    'schemaVersion': circleJournalSchemaVersion,
    'entries': [for (final e in entries) e.toJson()],
  });

  const head = Intention.clearerHead;
  const energy = Intention.moreEnergy;
  const stage = PlanStageProvenance(
    planId: 'getting_going',
    cycleId: 'getting_going#1',
    stageNumber: 1,
    stageId: 'getting_going.1',
  );

  final i1 = <String, Object>{
    circleJournalKey: journalOf([
      for (final ago in [1, 5, 9, 13, 14]) entry(ago, head),
    ]),
  };
  final i2 = <String, Object>{
    circlePlansKey: jsonEncode(
      CirclePlansState.empty
          .start('getting_going', today: '2026-10-01')!
          .toJson(),
    ),
    circleJournalKey: journalOf([
      for (final (k, ago) in [2, 5, 9, 13, 17].indexed)
        k.isEven
            ? entry(ago, energy, replacedFromStage: stage, reason: 'tooMuch')
            : entry(ago, energy, parts: window, stage: stage),
    ]),
  };
  final i3 = <String, Object>{
    circleJournalKey: journalOf([
      for (final ago in [2, 4, 6, 8, 10, 12, 15])
        entry(ago, head, parts: reading),
      for (final (k, ago) in [1, 5, 9, 11].indexed)
        entry(
          ago,
          energy,
          parts: window,
          skipped: k == 1 ? const {} : {ElementId.openWindow},
        ),
    ]),
  };

  InsightsNotifier insights(ProviderContainer c) =>
      c.read(insightsProvider.notifier);
  CirclePlansNotifier plans(ProviderContainer c) =>
      c.read(circlePlansProvider.notifier);

  Future<Map?> snapshotOnDisk(String id) async {
    final list = (await json(insightsKey))['snapshots'] as List? ?? [];
    for (final s in list) {
      if ((s as Map)['id'] == id) return s;
    }
    return null;
  }

  Future<Map?> planOnDisk(String planId) async =>
      ((await json(circlePlansKey))['plans'] as Map?)?[planId] as Map?;

  /// [plans] as stored JSON, with [record] as [planId]'s Insight provenance
  /// — written as raw JSON, as another build or an earlier save left it.
  Map<String, Object?> withProvenance(
    CirclePlansState plans,
    String planId,
    Map<String, Object?> record,
  ) {
    final raw =
        jsonDecode(jsonEncode(plans.toJson())) as Map<String, Object?>;
    ((raw['plans'] as Map)[planId] as Map)['appliedInsight'] = record;
    return raw;
  }


  // Independent proposed reproductions. NOT EXECUTED: no Flutter/Dart SDK.
  for (final reversal in ['pause', 'leave']) {
    test('R82-N01 I1 retry repairs only after manual $reversal', () async {
      await h.boot(i1);
      final c = h.open();
      final shown = insights(c).assess().added.single;
      expect(shown.family, InsightFamily.planForNeed);
      await R8Harness.settle();
      h.disk.fail(insightsKey, DiskFault.returnsFalse);
      expect(await insights(c).apply(shown.id), InsightActionResult.done);
      await R8Harness.settle();
      expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNull);
      h.disk.healAll();
      expect(reversal == 'pause'
          ? plans(c).pause('making_room')
          : plans(c).leave('making_room'), PlanActionResult.done);
      await R8Harness.settle();
      final before = jsonEncode(await planOnDisk('making_room'));
      await h.restart();
      final again = h.open();
      expect(await insights(again).apply(shown.id), InsightActionResult.done);
      await R8Harness.settle();
      expect(jsonEncode(await planOnDisk('making_room')), before,
          reason: 'marker repair must not resume or create another cycle');
      expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNotNull);
    });
  }

  test('R82-N01 I2 retry preserves a later manual stopGentler', () async {
    await h.boot(i2);
    final c = h.open();
    final shown = insights(c).assess().added.single;
    expect(shown.family, InsightFamily.planPacing);
    await R8Harness.settle();
    h.disk.fail(insightsKey, DiskFault.returnsFalse);
    expect(await insights(c).apply(shown.id), InsightActionResult.done);
    await R8Harness.settle();
    h.disk.healAll();
    expect(plans(c).stopGentler('getting_going'), PlanActionResult.done);
    await R8Harness.settle();
    final before = jsonEncode(await planOnDisk('getting_going'));
    await h.restart();
    final again = h.open();
    expect(await insights(again).apply(shown.id), InsightActionResult.done);
    await R8Harness.settle();
    expect(jsonEncode(await planOnDisk('getting_going')), before);
    expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNotNull);
  });

  test('R82-N02 queued manual I3 target is never claimed by Insight', () async {
    await h.boot(i3);
    final c = h.open();
    final shown = insights(c).assess().added.single;
    expect(shown.family, InsightFamily.skippedPart);
    await R8Harness.settle();
    final held = h.disk.hold(suggestionPreferencesKey);
    final manual = c.read(suggestionPreferencesProvider.notifier)
        .leaveOut(ElementId.openWindow);
    await held.reached;
    final applying = insights(c).apply(shown.id);
    await R8Harness.settle();
    held.release();
    expect(await manual, isTrue);
    final result = await applying;
    await R8Harness.settle();
    final entries = (await json(suggestionPreferencesKey))['elementsLeftOut'] as List;
    final target = entries.singleWhere(
        (e) => (e as Map)['elementId'] == 'openWindow') as Map;
    expect(target['byInsight'], isNull, reason: 'manual action owns target');
    expect(result, isNot(InsightActionResult.done));
    expect((await snapshotOnDisk(shown.id))?['appliedOn'], isNull,
        reason: 'manual action must not be recorded as an Insight application');
  });

  test('R82-N03 decoded expiry true must serialize a later false', () {
    final raw = <String, Object?>{
      'circleId': '2026-10-30',
      'stage': stage.toJson(),
      'startedAfterExpiry': true,
    };
    final corrected = ServedStageCircle.fromJson(raw)!
        .copyWith(startedAfterExpiry: false);
    expect(corrected.startedAfterExpiry, isFalse);
    final roundTrip = ServedStageCircle.fromJson(corrected.toJson())!;
    expect(roundTrip.startedAfterExpiry, isFalse,
        reason: 'serialized confirmed value must equal model value');
  });

  test('R82-N04 valid AppliedInsight preserves nested extension fields', () {
    final raw = <String, Object?>{
      'insightId': 'I1@example',
      'cycleId': 'making_room#1',
      'on': '2026-10-30',
      'futureProvenance': <String, Object?>{'reason': 'retain exactly'},
    };
    expect(AppliedInsight.fromJson(raw)!.toJson(), raw);
  });

  test('R82-N05 delayed Start must revalidate its local day', () async {
    h.clock.value = DateTime(2026, 10, 30, 23, 59, 59);
    final held = h.disk.hold(recommendationPendingWriteKey);
    final c = h.open(status: EntitlementStatus.inactive);
    c.read(recommendationProvider.notifier).chooseIntention(
        Intention.moreEnergy, window: TimeWindow.about20);
    await held.reached;
    c.read(recommendationProvider.notifier).start();
    await R8Harness.settle();
    expect(c.read(recommendationProvider).status,
        RecommendationStatus.notStarted);
    h.clock.value = DateTime(2026, 10, 31, 0, 0, 1);
    held.release();
    await R8Harness.settle();
    final state = c.read(recommendationProvider);
    expect(state.status, isNot(RecommendationStatus.started),
        reason: 'yesterday offer was still unstarted when midnight passed');
    final stored = await h.disk.stored();
    expect(stored[recommendationStatusKey], isNot('started'));
  });
}


```

## Appendix C — Independently reconstructed verification facts

```json
{
  "identity": [
    "e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8",
    "e935112c408c16d99835280f4e1fafd722d47ed1",
    "623a8ee4717b29fb2fcef97fb610545266c158ca",
    "fix(thirty): close R8.2 cross-store integrity audit findings"
  ],
  "fsck": {
    "returncode": 0,
    "stdout": "",
    "stderr": ""
  },
  "commit_paths": {
    "actual": 423,
    "declared": 423,
    "duplicate": 0,
    "missing": [],
    "extra": []
  },
  "manifest": {
    "entries": 371,
    "tree_entries": 371,
    "missing": [],
    "extra": [],
    "mismatch": [],
    "sha256": "837906b7c7b4f5252b6898016069dd0d6c204719f83ad7775e9e5b0abd17530c"
  },
  "export_blobs": {
    "checked": 1678,
    "mismatch": []
  },
  "fingerprints": {
    "identical": true,
    "LF": 228,
    "CRLF": 143,
    "mismatch": []
  },
  "report_hashes": {
    "docs/audits/THIRTY_INDEPENDENT_POST_R8_1_AUDIT.md": {
      "sha256": "afb0dd9ad6e82774bb963e67c6749b44a9505c18954af037ac8a3c565c0c375a",
      "bytes": 104664
    },
    "docs/audits/THIRTY_CLAUDE_POST_R8_1_AUDIT_REPORT.txt": {
      "sha256": "96593e20a24cba993dc45973118d2ed021dcae25c465fa0078ac87b29e4c23a1",
      "bytes": 52094
    }
  },
  "audio": {
    "artifacts/v2_phase_d2/voice_production/PRODUCTION_SHA1.txt": {
      "entries": 172,
      "mismatch": []
    },
    "artifacts/v2_phase_d2/voice_production/framing_f02_f03/FRAMING_SHA1.txt": {
      "entries": 8,
      "mismatch": []
    },
    "union": {
      "actual": 180,
      "declared": 180,
      "missing": [],
      "extra": [],
      "changed": []
    }
  },
  "year_profiles": {
    "p01_sparse_feedback": 1,
    "p02_frequent_feedback": 1,
    "p03_stable_positive": 1,
    "p04_mixed": 1,
    "p05_one_need_dominant": 1,
    "p06_all_three_needs": 1,
    "p07_mostly_10_minutes": 1,
    "p08_mostly_20_minutes": 1,
    "p09_mostly_30_minutes": 1,
    "p10_lapse_and_resubscribe": 1,
    "p11_many_exclusions": 1,
    "p13_no_routine": 1,
    "p14_more_energy_dominant": 1
  },
  "b8": [
    "B8 \u2014 the whole product over twelve months (structure only) A \u2014 a user who never answers still gets the whole service, and nothing claims what they never said",
    "B8 \u2014 the whole product over twelve months (structure only) B \u2014 a mixed answerer: answers move what is composed, Stage 5 uses only what this cycle allows, reviews say what was said",
    "B8 \u2014 the whole product over twelve months (structure only) C \u2014 More Energy every day at \u224810: no stall, the safety gate holds, repetition measured honestly",
    "B8 \u2014 the whole product over twelve months (structure only) D \u2014 lapse is fair: everything owned stays, new Premium work stops, resubscribing resumes where it was",
    "B8 \u2014 the whole product over twelve months (structure only) voice follows the entitlement: a lapse silences it, the choice is kept",
    "B8 \u2014 the whole product over twelve months (structure only) E \u2014 the twelve-month record of all four, and the report"
  ],
  "independent_runtime": {
    "flutter": null,
    "dart": null,
    "product_tests_executed": 0
  },
  "raw_regression": {
    "totals": {
      "passed": 2774,
      "failed": 0,
      "skipped": 0
    },
    "problems": [],
    "duplicates": [],
    "unique_files": 193,
    "inventory_files": 193,
    "missing": [],
    "extra": [],
    "plan_matches_source_inventory": true,
    "coverage_matches": true,
    "log_hashes": [
      {
        "file": "batch_01.jsonl",
        "sha256": "f5d126f6528925778d603fa188fcc6758da0f50eb69c95717a0eb91a7c13e88c",
        "exit": 0,
        "passed": 76
      },
      {
        "file": "batch_02.jsonl",
        "sha256": "d5cff943982916be021b6b275afa7432e480285f454319e8eeb63878a6d561ff",
        "exit": 0,
        "passed": 99
      },
      {
        "file": "batch_03.jsonl",
        "sha256": "efc54e2e8eeb59121b30867cd850a2d17a85b1c656f1d03ded4511caadc58ce1",
        "exit": 0,
        "passed": 121
      },
      {
        "file": "batch_04.jsonl",
        "sha256": "0c7470544cb7c6f36a19d58accf4137069b6602304c6bb973eb18597a195ccce",
        "exit": 0,
        "passed": 157
      },
      {
        "file": "batch_05.jsonl",
        "sha256": "2050e14f982309e11fc211fbdc3507060891657f77f3be952ce49283d4a5f2a2",
        "exit": 0,
        "passed": 88
      },
      {
        "file": "batch_06.jsonl",
        "sha256": "e55f1cb0da456162b37a2da50c38958b9219aaa760a315bc0b75bbbd9509d4e4",
        "exit": 0,
        "passed": 226
      },
      {
        "file": "batch_07.jsonl",
        "sha256": "ba9fb423716678de1973caaab5b4c5406ed98c73b0e765a0a14fdd08fd537c49",
        "exit": 0,
        "passed": 241
      },
      {
        "file": "batch_08.jsonl",
        "sha256": "7a5f85335d7dd5e5e3c64565bb9a5b43d857ecaf57b6a0f0b7ffdb1cc649755b",
        "exit": 0,
        "passed": 154
      },
      {
        "file": "batch_09.jsonl",
        "sha256": "9ca5e7e05b49dd314d4d19c9f2a98c0c7e888d02afba74ec4907162ecd2ec55f",
        "exit": 0,
        "passed": 164
      },
      {
        "file": "batch_10.jsonl",
        "sha256": "54882bbaeb06c1a87103373d8df3d684bc2ee11680d88a03fd7da2113e63c2c5",
        "exit": 0,
        "passed": 267
      },
      {
        "file": "batch_11.jsonl",
        "sha256": "cbdfde47c225de6e85ac1f7db228a24b231c423b74f4f45b051a9f7326fa652d",
        "exit": 0,
        "passed": 187
      },
      {
        "file": "batch_12.jsonl",
        "sha256": "18c72624bacfa35622a6847430890a8a7b911ada296956b8660cc784043779bd",
        "exit": 0,
        "passed": 282
      },
      {
        "file": "batch_13.jsonl",
        "sha256": "dd09e8f144c5ca2210a296aad7c9e3ae4555fe45916e5d9cb8b142d559951b8c",
        "exit": 0,
        "passed": 159
      },
      {
        "file": "batch_14.jsonl",
        "sha256": "ead5302e3d8ff28df001dd487fe39645b3b6681852b7214a4ff3627b7611aff6",
        "exit": 0,
        "passed": 142
      },
      {
        "file": "batch_15.jsonl",
        "sha256": "374df55f1c963f94d87ee4d4d719a95e49b767adae3d8b66a3ed2d02d6902124",
        "exit": 0,
        "passed": 176
      },
      {
        "file": "batch_16.jsonl",
        "sha256": "a13d86adb016f7876be6a0407fa2d66a7aa9ff4869d04d594e2ce28eab9ca501",
        "exit": 0,
        "passed": 216
      },
      {
        "file": "batch_17.jsonl",
        "sha256": "87f366b0d59c72ca59f284968be80db73a0e2c553da062ec1dd56a00b5ac4f49",
        "exit": 0,
        "passed": 6
      },
      {
        "file": "batch_18a.jsonl",
        "sha256": "fa8799f704d0b1dcb281e595f3de27dcfdb3d1414d89274914eb4da0177b7841",
        "exit": 0,
        "passed": 3
      },
      {
        "file": "batch_18b.jsonl",
        "sha256": "857aaa9f04bc7de9c42f054684e76401a1ced6765c3af158e176dd9281095f66",
        "exit": 0,
        "passed": 3
      },
      {
        "file": "batch_18c.jsonl",
        "sha256": "260ad12188c0d5fa25bb415d68b218d295a6cefd1ef09bcd454b45369a75ea2c",
        "exit": 0,
        "passed": 3
      },
      {
        "file": "batch_18d.jsonl",
        "sha256": "4a1fce7dc666e8898be2f11276f6895470147d04abc3808827036a5763b03e07",
        "exit": 0,
        "passed": 2
      },
      {
        "file": "batch_18e.jsonl",
        "sha256": "e3c7d8364a0cc9b82b432d3d1c504df211c67a842ef3f1947a163240c3e10f6b",
        "exit": 0,
        "passed": 2
      }
    ]
  },
  "other_raw_reporter_logs": {
    "count": 25,
    "all_terminal_done": true,
    "all_json_events_valid": true
  },
  "original_reproduction_hashes": [
    {
      "file": "audit_r81_diag_test.dart.txt",
      "actual": "29e0e42fef5a792355c0a37edb420d9a6b77723889aaea50648fdd8e6d91198f",
      "expected": "29e0e42fef5a792355c0a37edb420d9a6b77723889aaea50648fdd8e6d91198f",
      "matches": true
    },
    {
      "file": "audit_r81_repro_test.dart.txt",
      "actual": "e00fc009833f19c76c2ace9774cbdd672e1784c14038eda43343212ea4e83fe3",
      "expected": "e00fc009833f19c76c2ace9774cbdd672e1784c14038eda43343212ea4e83fe3",
      "matches": true
    },
    {
      "file": "audit_r81_stage5_test.dart.txt",
      "actual": "9996c8f0c1ffb7acf75362d7910db6ccace004c53f721c8ca21384505a60bbb3",
      "expected": "9996c8f0c1ffb7acf75362d7910db6ccace004c53f721c8ca21384505a60bbb3",
      "matches": true
    }
  ],
  "runner_challenges": [
    {
      "case": "intact",
      "exit": 0,
      "last_line": "EVIDENCE OK"
    },
    {
      "case": "missing_part",
      "exit": 1,
      "last_line": "EVIDENCE MISMATCH"
    },
    {
      "case": "duplicate_other_part",
      "exit": 1,
      "last_line": "EVIDENCE MISMATCH"
    },
    {
      "case": "extra_part",
      "exit": 1,
      "last_line": "EVIDENCE MISMATCH"
    },
    {
      "case": "false_done",
      "exit": 1,
      "last_line": "EVIDENCE MISMATCH"
    },
    {
      "case": "missing_file",
      "exit": 1,
      "last_line": "EVIDENCE MISMATCH"
    },
    {
      "case": "wrong_command",
      "exit": 1,
      "last_line": "EVIDENCE MISMATCH"
    },
    {
      "case": "truncated_raw_only",
      "exit": 0,
      "last_line": "EVIDENCE OK"
    },
    {
      "case": "intact_cases",
      "exit": 0,
      "last_line": "CASES OK"
    }
  ]
}
```

## Appendix D — Governing and evidence documents

All repository links below are pinned to the audited SHA.

- [Independent handoff](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/artifacts/r8_2_consolidated_remediation_2026-11-05/INDEPENDENT_AUDIT_HANDOFF_R8_2.md)
- [Issue register](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/artifacts/r8_2_consolidated_remediation_2026-11-05/ISSUE_REGISTER.json)
- [Consolidated changes](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/artifacts/r8_2_consolidated_remediation_2026-11-05/CHANGES.md)
- [Founder decisions A–C](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/artifacts/r8_2_consolidated_remediation_2026-11-05/founder_decisions/README.md)
- [Final lifecycle policy](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/artifacts/r8_2_consolidated_remediation_2026-11-05/lifecycle_policy/README.md)
- [R8.2 limitations](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/artifacts/r8_2_consolidated_remediation_2026-11-05/LIMITATIONS_R8_2.md)
- [Astra post-R8.1 report](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/docs/audits/THIRTY_INDEPENDENT_POST_R8_1_AUDIT.md)
- [Claude post-R8.1 report](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/docs/audits/THIRTY_CLAUDE_POST_R8_1_AUDIT_REPORT.txt)
- [Claude reconciliation and preserved originals](https://github.com/thirtyapp/Thirty/tree/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/artifacts/r8_2_consolidated_remediation_2026-11-05/claude_audit_reconciliation)
- [Post-fix original/adapted raw logs](https://github.com/thirtyapp/Thirty/tree/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/artifacts/r8_2_consolidated_remediation_2026-11-05/lifecycle_policy/auditor_repro_post_fix)
- [Product contract](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/docs/product/PRODUCT_V2_CONTRACT.md)
- [ADR-023](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/docs/product/adr/ADR-023-v2-recurring-premium-personal-guided-circle.md)
- [ADR-024](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/docs/product/adr/ADR-024-v2-circle-plans-insights-and-four-tab-product.md)
- [ADR-017](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/docs/product/adr/ADR-017-v1-step5-revenuecat-billing.md)
- [RL-4 limitation record](https://github.com/thirtyapp/Thirty/blob/e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8/artifacts/r8_1_consolidated_remediation_2026-11-05/LIMITATION_RL4_OFFSET_FREE_TIMESTAMPS.md)

**End of independent audit.**

