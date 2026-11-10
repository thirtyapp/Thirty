# THIRTY — INDEPENDENT POST-R8.3.2 DELTA AUDIT

**Audit date:** 10 November 2026.  
**Verdict:** **FAIL — do not accept this immutable commit as THIRTY's technical engineering baseline.**  
**Commercial authorization:** **Phase E remains HOLD.**

The reported R832-G1 ABA correction is supported by the source and the committed regression evidence. The final evidence reconciles to **204 test files, 2,966 passed, 0 failed, 0 skipped**. Nevertheless, the delta introduces two source-established integrity defects: a pre-Delete Insight continuation can restore Plan attribution after Delete's Plans pass, and I4 allocates nonunique kept-Circle identities from a cached clock. The latter can falsely prove an unperformed action and cause removal of one kept Circle to remove another.

**Evidence qualification:** I independently executed Git/object, hash, inventory, raw-log and evidence-validator checks. **I did not execute Flutter, Dart, the analyzer or Android tests:** neither Flutter nor Dart is installed in this environment. The new application findings are source-level counterexamples, with three prepared but **unexecuted** Flutter probes. They are not represented as observed Flutter failures.

## 1. Verified immutable target

| Identifier | Independently verified value |
|---|---|
| Repository | thirtyapp/Thirty |
| Branch, observed again on 10 November | step5-billing-integration |
| Commit | d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2 |
| Sole parent | 9c910773d7bfd3961be75fe3c9a44db41a1b7b27 |
| Target tree | 2f78849d4b85f97ddac4b3bc14ba6ff77f1e8e60 |
| Parent tree | 2480747c36b376189242661d572cbbf467c3ba83 |
| Exported committed blobs | 2,267; every blob matched; no missing or additional export files |

The target commit's raw Git object was reconstructed and its SHA-1 matched the requested commit. Both root tree hashes were reconstructed from paths, modes and object IDs. The parent was checked through its own commit object. The live branch reference matched the requested commit.

The audit used an independently assembled committed-tree export: exact-parent Git objects plus exact-target changed blobs, followed by verification of **all** target blobs. No implementer's working-directory content was accepted as source. The commit's local untracked final handoff is absent from the target; none was supplied separately, so it was not used.

## 2. Audit methodology and execution limits

I reviewed the complete relevant contracts, issue registers, founder decisions, original reports, reproduction matrices, final gates, test changes, manifests and raw regression streams in the four requested evidence directories. Earlier registers and READMEs were treated as chronological records: their B1/B2 and N01-C statements are superseded by CONTRACTS_FINAL.md and CONTRACT_G1.md where those documents explicitly change policy.

Source review followed both the changed code and its unchanged callers: Today, Plans, Insights, preferences, kept Circles, the global History deletion coordinator, serialization, clocks and startup recovery. I inspected the actual parent-to-target production diff, the 11 test/support paths and the original auditor controls.

Independently executed:

- Git commit/tree/blob reconstruction and complete export verification.
- Inventory, source/test manifest, report-hash and evidence-hash reconciliation.
- Independent parsing of complete reporter streams, including starts, completions, failures, skips, suite paths, test names and terminal success.
- The committed Python evidence validator, on disposable copies with only Windows checkout-prefix normalization for this Linux host.
- Sixteen adversarial evidence mutations; all were rejected.

Not executed: application tests, the three new probes, a fresh analyzer run, real process kill, power loss, Android storage faults, S25 or TalkBack. SharedPreferences mock confirmations and reconstructed provider containers are bounded simulation evidence, not operating-system durability proof.

No source correction, migration, staging, commit, push, release or deployment was performed. Audit scripts and proposed probes exist outside the audited export.

## 3. Changed-file and source-manifest integrity

**381 unique changed paths = 364 additions + 17 modifications; zero deletions and zero mode changes.** COMMIT_PATHS.txt contains exactly those 381 paths, without duplicates or omissions.

| Category | Paths |
|---|---:|
| Modified production | 9 |
| Modified existing tests | 7 |
| Modified test support | 1 |
| Added test files | 3 |
| Added original Astra report | 1 |
| Added committed evidence | 360 |
| Total | 381 |

The evidence split is 150 consolidated-closure paths, 100 founder-scope paths, 6 final-gate paths and 104 G1 paths.

All nine production files were inspected and their target Git blobs matched the tested final manifest:

| Production path | Main delta |
|---|---|
| lib/core/storage/confirmed_write.dart | Distinguishes thrown/uncertain outcomes from definitive refusal |
| lib/features/home/application/recommendation_provider.dart | Captures Start conditions and handles cancellation |
| lib/features/home/application/suggestion_preferences.dart | Propagates uncertain preference outcomes |
| lib/features/insights/application/insights_provider.dart | Receipts, action proof and displaced-provenance reconciliation |
| lib/features/insights/domain/insight.dart | Receipt codec and snapshot retention of receipt bytes |
| lib/features/insights/domain/insight_engine.dart | Unresolved receipt makes a snapshot stale |
| lib/features/personal_circle/application/kept_circles_provider.dart | Accepts a caller-chosen kept ID |
| lib/features/plans/application/circle_plans_provider.dart | Confirmed Start preparation, generation and epoch |
| lib/features/plans/domain/circle_plan.dart | Paused-Start identity and preservation through new cycles |

The eleven test/support paths are:

- test/features/home/r8b_precommit_persistence_test.dart
- test/features/personal_circle/r8_kept_ownership_persistence_test.dart
- test/features/r81/r81_n04_n05_expiry_and_insight_application_test.dart
- test/features/r82/r82_a04_a08_new3_insight_actions_test.dart
- test/features/r82/r82_decision_c_insight_provenance_test.dart
- test/features/r83/r831_start_eligibility_test.dart
- test/features/r83/r83_start_boundary_test.dart
- test/features/r832/r832_reproduction_test.dart
- test/features/r832/r832_founder_scope_test.dart
- test/features/r832/r832_g1_lifecycle_generation_test.dart
- test/support/r8_fault_disk.dart

The final manifest contains **383 entries**, exactly the complete lib/ and test/ file sets plus analysis_options.yaml, pubspec.yaml and pubspec.lock. All 383 Git blobs match the target. Start and end manifests are identical. The corresponding working-file SHA-256 fingerprints reconcile as **230 byte-identical files and 153 CRLF equivalents**, with no other content differences. Thus “byte-identical tested working files” needs the line-ending qualification; “same committed source/test blobs” is verified.

The founder-scope 2,944-test manifest differs from the target only in the subsequent Plans-provider correction among its 382 entries; the new G1 test is the additional final entry. Earlier consolidated manifests correctly describe an earlier stage, not the final target.

Original post-R8.3 report SHA-256 values were verified:

| Report | SHA-256 |
|---|---|
| Astra | 89a61f9f09ec38388a098fd436c1387da1aa98ebafd335a6abcf9719da647f9a |
| Claude | d1e5e700ade77ad55df69a069899069a357a953ab1c46b3929e52538de6d60a3 |

All 20 audit-input hash entries match exactly. The three closure evidence manifests verify 149, 99 and 103 entries respectively; the final-gate SHA256SUMS verifies all five listed files. Four of the 16 older baseline-auditor fingerprints match only their recorded CRLF representation; the two current original reports have exact byte matches.

The independent diff shows no billing/entitlement implementation, dependency, asset or platform changes. All **180 bundled audio files retain the same Git blob IDs**. The recorded 172-production/8-framing split is consistent with the claimed total. No Premium grant or purchase/restore change was found in the delta; this does not replace real billing validation.

## 4. Prior-finding closure matrix

“FIXED” below applies to the identified reported defect and its relevant paths, not to every possible interleaving of the subsystem. Test results in this table are **recorded evidence verified by this audit**, not fresh Flutter executions.

| Finding | Assessment | Source and executable evidence |
|---|---|---|
| Astra R83-N01 — orphan paused-Start evidence | **FIXED** | PausedStart contains Circle/instant identity; a fresh Start supersedes or clears abandoned evidence. [Plan model 714–759](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/domain/circle_plan.dart#L714-L759), [Plan model 1384–1425](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/domain/circle_plan.dart#L1384-L1425), [Plans provider 892–936](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/application/circle_plans_provider.dart#L892-L936). Reproduction B1/B2/B4/B7/B-tie and founder N1/N7/N8. |
| Astra R83-N02 — optimistic Start authorization | **FIXED** | Fast path rejects pending Plans changes; waiting path uses confirmed state. [Plans provider 788–814](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/application/circle_plans_provider.dart#L788-L814), [Plans provider 892–976](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/application/circle_plans_provider.dart#L892-L976). C1/C1b/C1c, C3 and G6/G7. |
| Astra R83-N03 — overwritten provenance allows repeat | **FIXED for the reported overwrite sequence** | Displaced unmarked action is marked durably before a later action. [Insights provider 357–375](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/application/insights_provider.dart#L357-L375), [Insights provider 487–513](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/application/insights_provider.dart#L487-L513). D1, D-ctl1/2/3 and final-gate Be. Cross-Delete continuation remains defective: A01 below. |
| Claude AUD-R83-1 — exclusion lost through new cycle | **FIXED** | New cycle carries the marker; recordGuided checks it before credit. [Plan model 1032–1055](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/domain/circle_plan.dart#L1032-L1055), [Plan model 1225–1262](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/domain/circle_plan.dart#L1225-L1262). A1–A7, next-day and repeated restart controls. |
| Claude AUD-R83-2 — Start during refused Resume | **FIXED** | Confirmed lifecycle/cycle/generation must match the accepted conditions. [Plans provider 945–976](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/application/circle_plans_provider.dart#L945-L976). C2/C2b/C2c and G6/G7. |
| Claude AUD-R83-3 — failed Start poisons later Start | **FIXED** | Fresh Start replaces/removes the orphan before becoming valid, including equal-clock instants. [Plans provider 916–936](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/application/circle_plans_provider.dart#L916-L936), [Plan model 1384–1410](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/domain/circle_plan.dart#L1384-L1410). B2/B3/B7/B-tie. |
| R832-B1 — I3 replay after Put back | **FIXED, with disclosed conservative refusal** | Receipt survives reversal and blocks replay without proof. [Insights provider 578–603](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/application/insights_provider.dart#L578-L603), [Insight engine 614–622](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/domain/insight_engine.dart#L614-L622). B1-1…6, controls and final-gate Ba/Bb/Bc. |
| R832-B2 — I4 replay after removal | **PARTIAL** | Original removal/retry sequence is fixed by the receipt. B2-1/2/3/7 pass. The broader exact-action-proof/identity guarantee fails in A02: [Insights provider 421–425](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/application/insights_provider.dart#L421-L425), [Insights provider 631–643](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/application/insights_provider.dart#L631-L643), [Kept Circles 292–316](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/personal_circle/application/kept_circles_provider.dart#L292-L316). |
| R832-G1 — lifecycle ABA | **FIXED for reported ABA paths** | Per-Plan generation plus epoch; confirmed and uncertain changes invalidate the pending boundary. [Plans provider 109–165](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/application/circle_plans_provider.dart#L109-L165), [Plans provider 278–285](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/application/circle_plans_provider.dart#L278-L285), [Plans provider 945–976](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/application/circle_plans_provider.dart#L945-L976). G1 suite A1–A5, G1–G7, R1–R8, C1/C2; see coverage qualifications below. |
| N01-C — cancellation after relevant lifecycle change | **FIXED** | Cancellation returns before started state/persistence; fresh tap is required. [Today 1925–1956](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/home/application/recommendation_provider.dart#L1925-L1956). Founder N1–N8; AUD-O3 is superseded, not passed. |
| R8.2 Astra R82-N01 | **FIXED for original I1/I2 retry** | Exact provenance is checked before either current or stale execution. [Insights provider 343–355](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/application/insights_provider.dart#L343-L355), [Insights provider 402–410](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/application/insights_provider.dart#L402-L410). r83_insight_attribution and original Appendix B controls. |
| R8.2 Astra R82-N02 | **FIXED** | Waits for preferences; unchanged/manual exclusion is not this Insight's changed result. [Insights provider 332–337](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/application/insights_provider.dart#L332-L337), [Insights provider 578–603](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/application/insights_provider.dart#L578-L603), [Preferences 428–468](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/home/application/suggestion_preferences.dart#L428-L468). Original I3 attribution control. |
| R8.2 Astra R82-N03 / Claude AUD-N1 | **FIXED** | ServedStageCircle removes old known keys before serializing current flags. [Plan model 834–860](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/domain/circle_plan.dart#L834-L860). Codec-law and restart/end-to-end controls. |
| R8.2 Astra R82-N04 | **FIXED** | AppliedInsight extension fields round-trip. [Plan model 652–699](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/domain/circle_plan.dart#L652-L699). Codec-law and original control. |
| R8.2 Astra R82-N05 | **FIXED** | Rechecks actual event-clock day after waits and before started state. [Today 1898–1908](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/home/application/recommendation_provider.dart#L1898-L1908), [Today 1939–1949](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/home/application/recommendation_provider.dart#L1939-L1949). Midnight Free/stage controls. |
| R8.2 Claude AUD-N2 | **FIXED for original stale Start/Close maps** | Both in-memory action-order maps clear synchronously. [Plans provider 1113–1119](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/application/circle_plans_provider.dart#L1113-L1119). r83_delete_boundary and original control. A01 is a different surviving-attribution path. |
| R8.2 Claude AUD-N3 | **FIXED for original optimistic promotion** | Delete computes its Plans write at queue execution from confirmed state. [Plans provider 1129–1138](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/application/circle_plans_provider.dart#L1129-L1138). Refused/accepted held-write and refused-intent controls. |
| Founder D1 | **PARTIAL** | Readable preference attribution is removed while choices remain. [Preferences 230–260](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/home/application/suggestion_preferences.dart#L230-L260), [Preferences 365–376](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/home/application/suggestion_preferences.dart#L365-L376), [Preferences 578–590](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/home/application/suggestion_preferences.dart#L578-L590). L-1 remains an explicit exception. |
| Founder D2 | **FIXED within tested lifecycle policy** | No credit for Pause before a valid Start; no tap-time retroactive credit. [Plans provider 892–936](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/application/circle_plans_provider.dart#L892-L936), [Plan model 1236–1262](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/domain/circle_plan.dart#L1236-L1262). Founder N2 and G1 C1/C2. |
| Founder D3 | **PARTIAL** | Original I1/I2 retry and I3/I4 no-replay paths close. I4's new ID collision breaks exact attribution and original-date repair in A02. |
| Founder D4 | **FIXED for its specific requirement** | Refused optimistic Plans changes are not promoted by Delete. [Plans provider 1129–1138](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/application/circle_plans_provider.dart#L1129-L1138). This does not establish global Delete completeness. |
| Founder D5 | **FIXED for demonstrated native-type startup sites** | Type-safe startup/initialization reads remain in place; r83_startup_types controls retained. [Startup retirement 26–38](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/home/application/v1_premium_retirement.dart#L26-L38), [Analytics identity 60–89](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/core/analytics/tester_identity_provider.dart#L60-L89). Unknown cohort strings remain the separate inherited low-impact limitation. |

The register's older “B1/B2 OPEN” entries are superseded by the final founder-scope implementation, but that does not authorize ignoring A02 or broadening original passing controls into universal guarantees.

## 5. R832-G1 generation and ABA assessment

The essential correction is sound for the reported problem. A comparison of final lifecycle/cycle alone cannot detect ABA. _confirm now counts each confirmed change for every affected Plan; automatic Pause is included. startConditions captures epoch, generation and shown lifecycle/cycle. prepareStart revalidates after settling writes and after its own marker write. [Plans provider 149–165](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/application/circle_plans_provider.dart#L149-L165), [Plans provider 892–976](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/application/circle_plans_provider.dart#L892-L976).

| Challenge | Assessment |
|---|---|
| Paused → Active → Paused while pending | Generation advances twice although final lifecycle matches; cancellation is supported by A1 and G1. |
| Active → Paused → Active while pending | Same protection; A2 verifies cancellation followed by a creditable fresh Start. |
| Automatic Pause from another Plan | _countChanges visits all Plan keys; A3 covers switching away and back. |
| Multiple lifecycle writes already pending at tap | Allowance is at most one transition from confirmed to shown state. More transitions cancel conservatively. **Coverage caveat:** G2 calls pendingStart before queuing Pause/Resume despite its title; it is not a direct multi-write-before-tap test. C3 covers a before-tap mixed success/refusal chain. |
| Transition refused before persistence | A definitive false refusal is not counted; a valid pending Start remains allowed unless it was asked for on a shown transition that never became real. A4/G3/G7 cover this distinction. |
| Transition throws before landing | A throw is treated as uncertain, not proven refusal; G4 cancels safely, even when this particular simulation knows no bytes landed. |
| Write lands, acknowledgement lost | _set counts the uncertain movement; G5 cancels. Memory/disk disagreement remains possible until a later confirmed save/restart and is disclosed. |
| Plans provider rebuild | New epoch invalidates old conditions; R1/R2/R5. These tests do not exhaust rebuilds during every underlying SharedPreferences cache phase. |
| Pending Start during Delete | Global Delete invalidates Today and its History-write epoch; the earlier held-prerequisite Delete control supports no session/marker resurrection. G1 R3/R4 call Plans.forgetStageEvidence directly; R4's “allowed” result is not authorization for a full Today Start after global Delete. |
| Failed eligibility write, fresh Start | The failed attempt is refused; fresh preparation replaces/clears evidence. B7, founder N5 and G4 fresh-Start control. |
| Cycle changes and later lifecycle becomes equivalent | Current-cycle ID is part of _samePlace and accepted conditions. A matching lifecycle alone cannot restore eligibility. Historical new-cycle tests cover retained exclusion; not every cycle/generation interleaving is separately executed in G1. |
| Start during pending Resume; cancellation with another Today write queued | One Resume already shown at the tap is the explicit +1 allowance: accepted if confirmed, cancelled if refused/uncertain. G6/G7. Cancellation returns before started persistence, while Today retains its serialized queue. Independent application execution of every separate queued-Today permutation remains absent. |

Confirmed intermediate changes cannot disappear merely because the Plan ends in its original place. The documented conservative cancellations do not grant credit or authorize an uncertain action. The generation is intentionally in memory: it protects an in-memory pending Start, not a persisted cross-process transaction.

## 6. Start identity and historical-credit assessment

A new paused marker is a Circle ID plus UTC Start instant; legacy day-only markers remain conservative. The waiting Start persists the same instant returned by preparation. A cancelled or abandoned attempt's marker is superseded before a later Start of the same Circle. Malformed marker values are retained as unreadable Plan data rather than silently becoming “no exclusion.” [Plan model 714–759](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/domain/circle_plan.dart#L714-L759), [Plans provider 916–936](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/application/circle_plans_provider.dart#L916-L936), [Today 1945–1956](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/home/application/recommendation_provider.dart#L1945-L1956).

| Required sequence | Source/evidence conclusion |
|---|---|
| Valid Start → Pause → durable Close | One credit on the eligible original cycle; G1 C1 and reproduction controls |
| Pause → valid Start → Close | No credit, including subsequent Resume/restart; G1 C2 |
| Excluded historical Circle → new cycle/next-day catch-up | Exclusion is carried and checked first; reproduction A1–A7 and S1 |
| Close requested before Leave, Close completes durably later | Original-cycle credit remains permitted by founder policy; A-ctl2 |
| Start abandoned, then Plan resumed | Resuming alone does not manufacture a started session or credit; B1/B2/B4/B-tie/B7 |
| Close never durably saved | Does not become confirmed History credit |

The existing single paused-Start slot is a **bounded production-path guarantee**. The committed limitation expressly acknowledges that arbitrary replay of an older excluded Circle after a newer marker replaces it would not be protected at the domain API alone. Current production ordering resolves the older day before publishing the next and folds only lastServed; S1 exercises that boundary. This is not permission to introduce wider historical replay.

RL-4 remains open for offset-free historical timestamps. New UTC marker timestamps do not fix ambiguous historical instants throughout the data model.

## 7. I3/I4 receipt assessment

The intended protocol is implemented in the correct order: durable receipt, target action, then Applied marker. Receipt existence by itself never authorizes Applied. Definitive refusal can clear the receipt; a throw retains it and blocks replay. [Insights provider 449–479](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/application/insights_provider.dart#L449-L479), [Insights provider 578–652](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/application/insights_provider.dart#L578-L652), [Insight engine 614–622](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/domain/insight_engine.dart#L614-L622).

| Case | Assessment |
|---|---|
| Receipt refused | No target mutation; B1-ctl2 and changed receipt-first controls |
| Receipt confirmed before target | Awaited explicitly; simulated stop-after-receipt control |
| Target returns false | Receipt clears if that clearing write succeeds; later retry allowed |
| Target throws before landing | Conservatively unresolved; no replay even though that can suppress an unperformed action |
| Target lands but acknowledgement lost | Uncertain; no replay without exact current proof |
| Action confirmed, marker refused | Proof may repair marker using action date; B1/B2 controls and final-gate Bb |
| Stop between receipt/action/marker | Recorded mock-store controls cover both unresolved and proof-repair states; not Android kill proof |
| Manual Put back/removal; repeated retries and restart | Original B1/B2 replay bugs close |
| Reassessment/another Insight | Receipt retained in ordinary retained snapshots; final-gate Bc and R1 |
| Independent manual Keep | Existing original control remains correct; its default ID differs from the I4 suffix |
| Kept limit and later removal | Eight-item limit and definite pre-action refusals remain; B2-4 |
| Delete during operation | Snapshot/receipt deletion is coordinated, but whole-apply operations are not globally serialized; do not infer universal Delete safety from receipt R3 |
| Malformed/future data | Bad present receipt makes its snapshot unreadable; required target/date/ID checked; unknown fields round-trip. Future whole-store schema remains unreadable/preserved. [Insight model 355–415](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/domain/insight.dart#L355-L415), [Insight model 426–483](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/domain/insight.dart#L426-L483) |

**I4 exact proof is not reliable:** its keptId can collide across distinct actions in the same cached-clock epoch, and the proof lookup does not compare the target Circle. A02 invalidates an unconditional receipt-protocol PASS.

**Availability limitation:** an unresolved receipt can suppress the original requested action indefinitely while that snapshot remains retained, even when a throw occurred before the action. There is no automatic safe retry. This is truthfully disclosed in CONTRACTS_FINAL.md, including the “No longer current” presentation and manual-action alternative. That label does not explain uncertainty to the user, but the implementation documentation does. This is an accepted conservative limitation, not proof that the action happened.

Retention is also bounded: ordinary pruning caps snapshots at 52 and does not specially pin unresolved receipts forever. A pruned snapshot cannot be retried by its old ID in this build; do not interpret “survives reassessment” as unlimited archival retention. [Insight engine 871–895](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/domain/insight_engine.dart#L871-L895).

## 8. I1/I2 provenance assessment

The original overwrite defect is closed for its documented sequence:

1. The first action lands with Plan provenance, but its Insight mark fails.
2. A manual reversal preserves that provenance.
3. Before another Insight overwrites it, _keepDisplacedApplication identifies the old snapshot and records its original application date.
4. A failed reconciliation prevents the new action.
5. A restart after reconciliation but before the second action retains the first action's durable mark.

This is visible in [Insights provider 487–538](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/application/insights_provider.dart#L487-L538) and supported by D1, D-ctl3 and final-gate Be. The original-date repair occurs before target mutation, rather than treating missing final provenance as proof the older action never occurred.

The guarantee is conditional on operation boundaries. apply waits for individual store queues, captures inputs and then awaits reconciliation; it does not hold one transaction/operation lock or recheck Delete afterward. The original I1/I2 serial overwrite test therefore does not establish global concurrency safety. **A01 crosses that await and restores attribution after Delete.**

CONTRACTS_FINAL.md's statement that absent provenance proves an action never landed is not an independent premise of this audit. It can only be a consequence of preserving/reconciling evidence under the supported lifecycle and retention assumptions. Missing, pruned, unreadable or deliberately deleted evidence cannot be generalized into universal proof of non-execution.

## 9. Cross-store, Delete and restart assessment

The global coordinator first confirms a persistent deletion intent, invalidates History writes, clears Plans evidence/Insights, strips readable preference attribution, drains queues, performs final clearing, then removes the intent. Interrupted deletion is completed during startup. [History Delete 156–228](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/home/application/circle_history_deletion.dart#L156-L228), [History Delete 285–311](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/home/application/circle_history_deletion.dart#L285-L311).

The specific inherited fixes remain: stale Start/Close maps clear, unreadable copies are waited for, refused optimistic Plans state is not promoted, readable user preferences and kept Circles remain user-owned, and many queued-write cases are covered.

However, **store queue drainage is not equivalent to draining an entire async Insight application**. An application can be suspended before it has queued its target write. Plans is sanitized only in the first pass; the final pass clears Insights/preferences and the unreadable Plans copy but does not sanitize Plans again. A01 uses exactly this gap.

Simulated restarts reconstruct providers from FaultDisk's stored bytes and run startup recovery. They establish behavior under that harness. They do not establish Android SharedPreferences fsync semantics, atomic multi-key persistence, process-kill timing or power-loss safety.

L-1 remains a second, distinct Delete-completeness failure. It concerns wholly unreadable preferences and requires no attribution-restoration race.

## 10. New findings with severity and exact source references

### R832-A01 — HIGH — pre-Delete Insight continuation restores Plan attribution

**Status: OPEN; source-established counterexample; Flutter probe prepared, not run.**

Source chain:

- apply captures the snapshot/inputs before awaiting displaced provenance: [Insights provider 332–364](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/application/insights_provider.dart#L332-L364).
- _keepDisplacedApplication awaits the old Insight's marker, then returns success: [Insights provider 487–513](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/application/insights_provider.dart#L487-L513).
- The continuation executes _direct without checking a deletion epoch or whether its snapshot still exists: [Insights provider 364–375](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/application/insights_provider.dart#L364-L375), [Insights provider 516–538](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/application/insights_provider.dart#L516-L538).
- Delete sanitizes Plans once, then waits on Insights; its final pass does not repeat Plans sanitation: [History Delete 181–219](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/home/application/circle_history_deletion.dart#L181-L219).
- A new Plans write created after the first pass captures the **new** _deletions value and therefore retains its new appliedInsight: [Plans provider 250–263](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/plans/application/circle_plans_provider.dart#L250-L263).

Reachable sequence, extending the already committed R83-N03 fixture:

1. I2 applies successfully; only its Insight Applied marker is refused.
2. User turns gentler off and pauses the Plan.
3. Seven days later, a valid I1 is generated.
4. Apply I1 and hold the Insights write that reconciles I2.
5. Begin full Delete. Let the intent and Plans evidence-clearing write land; Delete is still waiting for the held Insights queue.
6. Release the reconciliation write successfully.
7. I1 resumes the preserved paused Plan and writes fresh I1 attribution.
8. Delete drains queues and finishes its final pass, but never clears that new Plan attribution.

**Predicted confirmed bytes:** deletion intent absent; Insights absent; Plans.appliedInsight still names the deleted I1. The provider's confirmed Plans state contains that attribution too. Startup has no pending deletion intent to remove it.

This is not L-1: it uses valid current-schema data and successful relevant writes. It is a new await boundary introduced by the delta interacting with an unchanged deletion coordinator. The discarded snapshot is not reinserted by InsightsState.replacing; the surviving record is in **Plans**.

Prepared probe: INDEPENDENT-A01 in r832_independent_adversarial_test.dart.

### R832-A02 — MEDIUM — nonunique I4 IDs permit false proof and collateral removal

**Status: OPEN; source-established identity defect and counterexamples; two Flutter probes prepared, not run.**

Exact cause:

- Insights._now reads nowProvider: [Insights provider 125–125](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/application/insights_provider.dart#L125-L125).
- nowProvider is a cached DateTime, explicitly documented as unsuitable for event identity: [Clock 3–17](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/core/providers/clock_provider.dart#L3-L17).
- Every I4 in that cached epoch uses the same value: kept-[cached microseconds]-insight. [Insights provider 631–643](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/application/insights_provider.dart#L631-L643).
- keepCircle accepts that caller ID without uniqueness validation; it only rejects duplicate source days/limits: [Kept Circles 285–316](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/personal_circle/application/kept_circles_provider.dart#L285-L316).
- I4 proof matches keptId alone, without checking fromCircleId against the receipt target: [Insights provider 421–425](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/application/insights_provider.dart#L421-L425).
- renameKept/deleteKept affect every item with the matching ID: [Kept Circles 329–359](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/personal_circle/application/kept_circles_provider.dart#L329-L359).

A normal retained-snapshot sequence permits two different I4 targets in one cached-clock epoch:

1. Keep a generated I4 snapshot unacted-on for at least 28 days; its evidence remains within the 90-day window.
2. Accumulate new useful Circles of the same subject. The old snapshot remains current through overlapping evidence, so it initially suppresses a new snapshot.
3. Apply the older snapshot now.
4. Reassess. The old generation is outside its repeat window. New relevant evidence is not wholly covered by its old evidence set, so a newer I4 can be generated for a different, more recent Circle.
5. Apply that I4 without invalidating nowProvider.

**Successful-action variant:** both kept records receive the same ID. Removing one by ID removes both; renaming one renames both.

**Uncertain-action variant:** the first target write throws before landing, leaving only its receipt. The newer I4 keeps a different Circle with the same ID. Reassessment finds that ID and marks the older, never-executed action Applied, using the other Circle's createdAt date.

The generation/reassessment conditions are visible in [Insight engine 630–646](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/domain/insight_engine.dart#L630-L646), [Insight engine 670–710](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/domain/insight_engine.dart#L670-L710), [Insight engine 803–820](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/insights/domain/insight_engine.dart#L803-L820); the probe generates the original snapshot through production assess(), retains its bytes, then adds later History. It does not require a hand-crafted receipt or colliding manual ID.

**Predicted confirmed bytes:** either two kept records with identical id and different fromCircleId values, or an Applied mark for the older Insight while no kept record exists for its target. The duplicate identities also remain in memory until removal.

Prepared probes: INDEPENDENT-A02 false proof and INDEPENDENT-A02 ownership.

## 11. Executed adversarial reproductions

| Independent execution | Result |
|---|---|
| Raw commit/tree/blob checks | PASS; exact requested objects and all 2,267 export blobs |
| Parent-to-target inventory and final tested manifest | PASS; 381 paths, 383 source/config/test blobs |
| Independent raw-log re-summary | PASS; final 204 files and 2,966/0/0; no duplicate/missing completions or test-name pairs |
| Committed report validator on disposable baseline | EVIDENCE OK, exit 0 |
| Committed profile-case validator | CASES OK, exit 0 |
| Sixteen damaged-evidence controls | All rejected with EVIDENCE MISMATCH, exit 1 |
| New Flutter application probes | **NOT RUN — Flutter/Dart unavailable** |
| Full Flutter suite/analyzer/device testing | **NOT RUN by this auditor** |

The sixteen negative controls covered missing/duplicate/extra part summaries, wrong identity/command/files, incomplete summary, nonzero exit, missing/empty/truncated raw logs, missing initial event, duplicate terminal event, duplicate test completion, unmatched test start and a false terminal-success value. Structural-event mutations had their raw hashes recomputed, so rejection did not rely solely on noticing a changed SHA-256.

The accompanying evidence bundle contains the verification scripts/results and the three proposed probes. They are executable test material for a disposable exact-target checkout, not production corrections or claimed runtime evidence.

## 12. Full regression-evidence verification

| Recorded run | Files | Passed | Failed | Skipped | Audit treatment |
|---|---:|---:|---:|---:|---|
| Original parent full-suite log | 201 | 2,872 | 0 | 0 | Decompressed, hash checked and independently parsed |
| Consolidated R8.3.2 | 202 | 2,914 | 0 | 0 | All raw batches reconciled |
| Founder-scope closure | 203 | 2,944 | 0 | 0 | All raw batches reconciled |
| Final G1 target | 204 | 2,966 | 0 | 0 | All raw batches reconciled against target manifest |

Final per-file differences from the original run are exactly the three added files: **42 + 30 + 22 = 94** tests. All previously present files retain their recorded totals. Final coverage is 19 declared batches, with the profile batch split into five declared parts, producing 23 raw logs.

Each of the 13 profiles appears once: p01, p02, p03, p04, p05, p06, p07, p08, p09, p10, p11, p13 and p14. There is no undeclared p12 requirement. B8 contributes six successful tests.

The final recorded analyzer output is clean, exit 0; this was read and verified as committed evidence, not rerun.

Focused evidence is consistent with the correction history:

- Original post-R8.3 reproduction gate: 19 pass/23 fail; corrected consolidated gate: 42 pass.
- Founder combined gate: 72 pass on its corrected tree; original controls: 26 pass/1 fail.
- Final gate before G1: 7 pass/3 fail.
- Definitive combined final gate plus G1: **18 pass/14 fail before correction; 32 pass/0 fail after**.
- Definitive standalone G1 before-fix run: 11 pass/11 fail.
- Final target original controls remain **26 pass/1 fail**, not 27 passes.

The earlier G1 run-1 dead-process/held-write harness artifact and run-2 mistaken fresh-offer assumption are explicitly superseded. I did not use them as definitive before/after proof. The final G1 test SHA-256 is 807cd5d2257fd89b358f61e973f03e11d168c3a85673169f3a1e99ccb7d02ae6; the final-gate test hash is e24013d7f3cd4848189dd674c77efdfa5a0eebc852d685ba267b11e1724106af. Both match the committed at-run manifest.

Reporter failures designated N/A because an old tree lacks the needed precondition remain failures in the raw counts; they are not silently converted into passing or skipped tests. Extracted fact-only EVIDENCE files are not mistaken for complete reporter streams.

These checks establish strong internal consistency and binding to the exact committed source. They do not independently attest that the historical Flutter process ran as reported, nor do passing cases cover the new A01/A02 sequences.

## 13. Obsolete AUD-O3 adjudication

**Adjudication: genuinely superseded by N01-C; still a recorded failing control, not a PASS.**

The unchanged original control holds the Today offer save, taps Start, confirms status notStarted, requests Plan Pause, releases the held write, and then asserts status **started**. Under founder-approved N01-C, the confirmed intervening Pause cancels that unresolved Start, so the expected state is notStarted. Its intermediate assertion is therefore obsolete. [Original AUD-O3 20–32](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/artifacts/r8_3_2_consolidated_integrity_closure_2026-11-07/audit_inputs/claude_original_scratchpad/zz_audit/audit_r82_order_test.dart.txt#L20-L32).

The original test never makes a final credit assertion: it prints the records after Close. Its title's credit question must not be treated as a passing credit control when execution stops at the obsolete status assertion. [Original AUD-O3 33–43](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/artifacts/r8_3_2_consolidated_integrity_closure_2026-11-07/audit_inputs/claude_original_scratchpad/zz_audit/audit_r82_order_test.dart.txt#L33-L43).

The replacement expectations are independently appropriate: cancellation before a session exists; a fresh paused Start can run but earns zero credit; a valid pre-Pause Start retains its founder-authorized credit. Those are covered separately by founder N2, the updated R8.3/R8.3.1 tests and G1 C1/C2.

Report the original suite exactly as **26 PASS + 1 FAIL, with that failure adjudicated superseded**.

## 14. Six-invariant assessment

| Invariant | Assessment |
|---|---|
| 1. Durable confirmation | **PARTIAL / bounded support.** Receipt and target writes await API confirmation; refusal/uncertainty are distinguished. SharedPreferences acknowledgements and mock-store tests do not prove physical durability or cross-store atomicity. |
| 2. Exact attribution of Insight actions | **FAIL.** A02 permits another I4's kept record to prove an unperformed action. Original I1/I2 and manual-I3 attribution fixes remain supported. |
| 3. Idempotence | **PARTIAL.** Original retry/reversal paths no longer replay, with conservative availability loss. Nonunique action IDs prevent an unconditional action-identity guarantee. |
| 4. Temporal validity | **PARTIAL.** G1 closes the reported Start ABA and day-boundary paths. A01 permits an older Insight continuation to act across Delete; RL-4 remains outside the fix. |
| 5. Serialization fidelity | **PASS for inspected changed codecs, qualified.** Known fields clear correctly and valid extension/receipt fields round-trip. This is bounded codec evidence, not a universal claim over future schemas or ambiguous historical time semantics. |
| 6. Delete completeness | **FAIL.** A01 restores current-schema Plan attribution; L-1 retains wholly unreadable preference attribution and omits it from export. |

**No full six-invariant PASS is supportable.** Even without the new findings, L-1 requires an explicit exception and blocks unconditional acceptance.

## 15. L-1 and remaining release blockers

**L-1: OPEN — PRE-RELEASE BLOCKER — NOT FIXED — NOT WAIVED.**

For a wholly unreadable Suggestion Preferences record, Delete's attribution-removal step leaves the stored record intact, and export uses the empty/readable in-memory preferences rather than exporting the unreadable record. [Preferences 365–376](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/home/application/suggestion_preferences.dart#L365-L376), [Preferences 578–590](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/home/application/suggestion_preferences.dart#L578-L590), [Export 90–104](https://github.com/thirtyapp/Thirty/blob/d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2/lib/features/home/presentation/widgets/journal_data_controls.dart#L90-L104). A stored byInsight can survive a Delete reported successful. The current build does not apply that unreadable record to recommendations, but that does not erase the privacy/integrity failure.

L-1 independently prevents **unconditional engineering acceptance of Delete completeness**. An organization could explicitly track it in a conditional development checkpoint; that would not close or waive it. It does not excuse A01, which affects valid current-schema data.

Remaining qualifications/gates are unchanged: RL-4; conservative uncertain-write behavior; in-memory-only generations; simulated recovery; persistent-storage failure limits; actual Android recovery/storage checks; S25 and TalkBack; privacy/analytics/retention; backup/migration and real Premium restore; billing/release-APK review; localization/audio QA; final commercial audit.

I do not expand these into new remediation scope. No commercial release authorization follows from this audit. **Phase E remains HOLD.**

## 16. Final PASS, CONDITIONAL PASS or FAIL

**FAIL.**

The immutable target is authentic and the reported final regression evidence is internally consistent and bound to its source/test blobs. The reported R832-G1 ABA defect and the specific earlier Start/credit failures are closed within the inspected and recorded coverage.

Nevertheless, **this commit cannot be accepted as THIRTY's technical engineering baseline** because the new A01 Delete-continuation defect and A02 I4 action-identity defect violate the requested integrity guarantees. This conclusion rests on exact source control flow and prepared counterexamples; those new probes remain unexecuted and are not presented as measured Flutter failures.

L-1 remains **OPEN — PRE-RELEASE BLOCKER — NOT FIXED — NOT WAIVED**. Commercial release is independently unauthorized: **Phase E HOLD**.

