# THIRTY — DATA INTEGRITY ARCHITECTURE REVIEW & PRE-R8.3 DECISION

- **Date:** 2026-11-06
- **Baseline:** `e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8` on `step5-billing-integration` (parent `e935112c`)
- **Kind:** architecture review only. No source, test, staging, commit, push or deployment was done. This file is the only thing written, and it is untracked.
- **Evidence labels used throughout:**
  - **[EXEC]**: executed by an independent auditor, with the result recorded in their report;
  - **[SRC]**: traced in the source at `e744f505` by me for this review;
  - **[AUD-SRC]**: an auditor's source trace that I re-checked;
  - **[RISK]**: an architectural risk, not an observed defect;
  - **[HYP]**: a hypothesis that has not been demonstrated.
  - I executed no Flutter or Dart tests for this review.

---

## 1. Executive verdict

The SharedPreferences architecture can satisfy THIRTY's integrity guarantees. None of the seven post-R8.2 findings is caused by the lack of transactions or by having several logical stores. Every one traces to five recurring boundary mistakes:

1. **An outcome that hides the difference between "I changed it" and "it was already so".** Source of R82-N02, and part of R82-N01.
2. **A provenance check placed after the decision to act, instead of before it.** Source of R82-N01.
3. **A codec that lays known fields over a retained source map, so a known field can't be cleared, or a known nested record drops unknown fields.** Source of R82-N03/AUD-N1 and R82-N04.
4. **A validity fact checked at the tap but not again at the persistence boundary.** Source of R82-N05.
5. **In-memory or cross-store provenance that the Delete generation doesn't cover.** Source of AUD-N2 and O-1; AUD-N3 is the same boundary seen from the failure-notice side.

The patch-audit cycle keeps recurring because each fix is made locally. The shared rule it should have obeyed is not written down or tested anywhere: R8.2's A05 fix introduced N03, and decision C's mechanism left N01/N02 open.

**Recommendation: Option B, bounded integrity hardening.**
- **Code:** two very small shared contracts (a mutation outcome, and a codec rule), two boundary checklists (revalidate after await; clear on Delete), and fixes in about 6 production files.
- **Tests:** a reusable disk-level invariant oracle and a pairwise adversarial matrix, written to fail first.
- **Ruled out:** Option C (SQLite) would fix none of the seven findings and adds migration risk. Option A would close today's seven and leave the classes open.

**Decision: GO for R8.3 under Option B,** once you accept this review. Three small policy confirmations (§13 D1–D3) are needed; none of them blocks the other items.

THIRTY Phase E remains HOLD.

## 2. Verified SHA and repository state

| Check | Result |
|---|---|
| Local HEAD | `e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8` |
| `origin/step5-billing-integration` tracking ref | `e744f505…` |
| Live `git ls-remote` | `e744f505…` |
| Tracked changes vs HEAD in `lib/`, `test/`, pubspec, analysis_options | none (`git diff HEAD --stat` empty). The two files shown `M` (`quiet_trail_hero_asset_view.dart`, `r6_kept_voice_whole_circle_test.dart`) are line-ending/stat metadata only, as recorded in `COMMIT_INVENTORY.md` |
| Staged | nothing |
| Stash | none |
| Source reviewed | always via `git show e744f505:<path>`, never the working tree |

**Post-R8.2 reports read in full.** Both are untracked and were not modified.

| Report | Lines | SHA-256 | Verdict |
|---|---|---|---|
| `docs/audits/THIRTY_INDEPENDENT_POST_R8_2_AUDIT.md` (Astra) | 1,341 | `a6f5984b0681bb375a407e450de277ce0a29912105d096943006096ca35e9e43` | FAIL (N01–N05; 0 Flutter tests executed) |
| `docs/audits/THIRTY_CLAUDE_INDEPENDENT_POST_R8_2_AUDIT.txt` (Claude) | 325 | `2fc8766eb1916758e6bf369261e168da622fb00abb4af12a1f64ac457932cc8f` | CONDITIONAL PASS (AUD-N1, AUD-N2 blocking; AUD-N3 recommended; 9 adversarial tests executed) |

**Also read:**
- `PRODUCT_V2_CONTRACT.md`: the Delete/Export contract and the midnight amendment;
- `LIMITATIONS_R8_2.md`;
- the R8.2 change log, and the founder-decision and lifecycle-policy records;
- the R8.1 and R8 audit lineage, as summarized in the R8.2 handoff.

## 3. Data ownership matrix

Legend:
- **Opt.** = the in-memory state shown before the disk confirms;
- **Pess.** = state changes only after confirmation;
- **Queue** = the serialization primitive.

| # | Component (file) | Owned keys | Durable authority | Optimistic / pending | Serialized form | Queue & ordering | Depends on | Recovery after an interrupted write | Delete & retention | Entitlement checks | Main existing tests |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | **Today** `RecommendationNotifier` (`recommendation_provider.dart`) | ~30 `recommendation_*` day keys (`:224–391`) + WAL `recommendation_pending_write` | The day keys on disk. `_offersOnDisk` mirrors which offer is confirmed (`:754`) | **Opt.** `state` (Start is immediate only if `_readyToStart`, `:1768`; otherwise waits, `:1850`). Memory: `_startVerdicts`, `_offersOnDisk`, `_startWaiting` | One key per field; instants as UTC ISO (`:1353`); the WAL is a JSON map of the whole publication (`:905`) | One `_writes` chain; each write is begun under the `HistoryWriteGate` epoch (`:774–795`) and re-checks it at each step (`_ensureCurrent`, `:806`). **The only writer of History.** | Plans (`confirmServed`, `noteStart`, `confirmStartNoted`, `recordGuided`, `noteStarted`/`noteCloseRequested`), History, the gate, deletion-pending, entitlement | WAL replayed by the next write or the next start (`_pendingDayWrite`). `_mirrorInJournal` catches up History and the credit (`:1137`). `_recordBeforeOverwrite` records an earlier day before the keys move (`:970`) | Day keys cleared in both Delete passes; the notifier is invalidated (`circle_history_deletion.dart:183`) | The Start verdict is frozen at the tap (`:1767`, deliberate, R8.1 RL-1); a stage Start is refused on `wordingUnverified` | `r8_a01`, `r8b_precommit`, `r82_decision_b`, `r82_a03`, `r82_a06`, `r6b_day_rollover`, `r8_midnight_resume`, `circle_session_lifecycle` |
| 2 | **History** `CircleJournalRepository` (`circle_journal.dart`) | `circle_journal_v1`, `circle_journal_preserved_v1` | Disk. `readAll()` reads the SharedPreferences memory cache, pending writes included (`:744`). `readConfirmed()` reads the last confirmed bytes while a write is pending (`:755`) | No queue of its own. **Opt.** through the platform cache | One JSON wrapper (`schemaVersion` 2), capped at 366 entries; unreadable entries written back as stored (`:1258–1293`) | Every call site goes through Today's `_enqueue` (`recommendation_provider.dart:1156, 2261, 2512, 2611, 2725–2775`). The History page and the record-detail page call `recommendationProvider.removeAnswer`, which enqueues (`:2233–2266`) | `JournalWrites`, `journalSaveStatus` | Preserved copies of unreadable History; catch-up from the day keys | Both keys removed in both passes; `JournalWrites.forget()` | none | `circle_journal_test`, `r6_journal_save_failure`, `r6c`, `r8_journal_forward_records`, `r82_a07` |
| 3 | **JournalWrites** (`circle_journal.dart:1424–1473`) | none | The confirmed raw snapshot `_confirmed` | `_pending` count, `_generation` | — | Tracks History writes; `idle()` | — | — | `forget()`: generation +1, confirmed cleared | — | `r82_a07` |
| 4 | **Plans** `CirclePlansNotifier` (`circle_plans_provider.dart`) + domain (`circle_plan.dart`) | `circle_plans_v2`, `circle_plans_v2_unreadable` | `_durable`, **assigned the in-memory model `next` after a confirmed write, never the decoded bytes** (`:205`) | **Opt.** `state`; `_queued`/`_queuedWrite`. Memory-only `_startedAt` / `_closeRequestedAt` (`:309–317`) | One JSON record. `PlanProgress.extra` keeps unknown fields (`circle_plan.dart:607–616`). `ServedStageCircle` keeps a `source` overlay (`:727–734`). `AppliedInsight` writes 3 fields only (`:638–653`). `unreadablePlans` retained | One `_writes` chain; `_deletions` generation (`:205`); `idle()`; `confirmed()` compares leaves after waiting (`:464–518`); waits are bounded to 8 rounds | History `readConfirmed()` (fold, answers); History `readAll()` (the action-order fallback, `:319–323`); entitlement; PreservationWrites | `keepAside` for unreadable records; rollback to `_durable` when the latest save fails (`:228`); credits caught up via Today | `forgetStageEvidence` (`:895–924`) keeps the place (lifecycle, cycles without evidence) and drops `lastServed`, `lastAdvancedCircleId`, `appliedInsight`, `extra` and `unreadablePlans`; the unreadable copy is removed. **`_startedAt`/`_closeRequestedAt` are not cleared.** | Running actions need `active` (`:271, 288`). Pause, Leave and stopGentler are never gated. Credit after a lapse only through `creditsServed` (served under Premium, not `startedAfterExpiry`) | `r2_plan_credit_provenance`, `circle_plan_domain`, `r81_n01`, `r82_a01`, `r82_decision_a`, `r82_lifecycle_policy`, `r82_a05`, `r81b_rl3` |
| 5 | **Insights** `InsightsNotifier` (`insights_provider.dart`) | `insights_v2`, `insights_v2_unreadable` | `_durable` (the model after confirmation, `:151`) | **Opt.** `state`; `_queued` | One JSON record of snapshots | One `_writes` chain; `_deletions`; `idle()` | Plans `confirmedState`; History `readConfirmed`; Preferences `leftOut` (**read from `state`, with no wait on its queue**); Kept | A failed mark leaves the change in place; the retry repairs from provenance **only in the stale branch** (`:316–320`) | `forgetAll()` (`:544–567`); `assess()` blocked while a Delete is under way or pending (`:87, 246`) | Generating and applying need Premium; I4 Keep is not gated (`:307–308`). The check runs after the awaits (`:304–308`) | `insights_service`, `r81_n04_n05`, `r82_a04_a08_new3`, `r82_decision_c`, `r5_i4_keep_after_lapse` |
| 6 | **Preferences** `SuggestionPreferencesNotifier` (`suggestion_preferences.dart`) | `suggestion_preferences_v1` | Disk. **Pess.**: `state` is set only after a confirmed write (`:353–359`) | `_writes` chain. `change(state)` is evaluated at its own turn (`:329`) | One JSON record; items keep `source` (whole-item overlay); `extra`; `unreadable` lists | One `_writes` chain, **no `idle()`** | — | The record is unreadable: writes are refused until Reset (`_storedUnreadable`) | **Not deleted** (contract). `ElementLeftOut.byInsight` survives Delete | none | `suggestion_controls`, `r82_decision_c`, `r82_a05`, `r82_a09` |
| 7 | **Kept Circles** `KeptCirclesNotifier` (`kept_circles_provider.dart`) | `toolkit_v1`, `toolkit_v1_unreadable` | Disk; **Pess.** (`_commit`, `:243–251`) | `_writes` chain | JSON | One `_writes` chain | — | The unreadable store is kept | **Not deleted** (contract) | Keep is never gated; the I4 exception | `r4_kept_ownership`, `r41_kept_store`, `r8_kept_ownership_persistence`, `saved_circle_lapse_attack` |
| 8 | **CircleHistoryDeletion** (`circle_history_deletion.dart`) | `circle_history_deletion_pending` (only `true` counts) | The marker on disk | `_running` chain | bool | Intent first, confirmed and retried once (`:165–173`); then gate epoch +1; then the ordered passes (`:174–209`) | Gate, JournalWrites, Plans, Insights, PreservationWrites, Today, History | `completeInterruptedHistoryDeletion` at start-up (`:273–298`) | — | — | `delete_circle_history`, `r3_persistence_delete`, `r8_a04_delete_durability`, `r82_a02_new2`, `b8_delete_longitudinal` |
| 9 | **HistoryWriteGate** (`circle_history_deletion.dart:41–88`) | none | — | `_epoch`, `_deleting`, `_inFlight` | — | Covers **Today's writes only** | — | — | Moves the epoch on | — | `r3_*`, `r82_a02` |
| 10 | **PreservationWrites** (`preservation_writes.dart`) | Writes `*_unreadable` copies for Plans and Insights | — | `_pending` per key | Native type kept | `settled` / `settledAll` | writeConfirmed | — | Awaited by Delete | — | `r81_n02_preservation_writes`, `r82_a09` |
| 11 | **writeConfirmed** (`confirmed_write.dart`) | — | The platform's Boolean | Restores the previous value to memory and disk on failure (`:37–52`); with `restoreOnFailure:false` (Delete) it never restores | — | **None. It assumes one writer per key at a time.** | SharedPreferences | — | — | — | every store test |
| 12 | **Billing** `entitlementStatusProvider` / `premiumEntitlementProvider` (`premium_access.dart`) | none (RevenueCat SDK state) | Gateway answer | Starts as `initializing`; re-initialized on every resume (`thirty_app.dart:80`) | — | — | Gateway | Fails closed (`unavailable`) | — | `premiumEntitlementProvider` = `active` only | `premium_access`, `entitlement_gateway`, `revenue_cat_entitlement_gateway`, `b7_entitlement_matrix` |
| 13 | **Start-up / resume** (`main.dart`, `thirty_app.dart`) | `v1_premium_retired`, `phase_d_premium_retired` | — | — | — | In order: `getInstance` → `retireV1Premium` (**typed `getBool`, `v1_premium_retirement.dart:26`**) → `retirePhaseDPremium` (`prefs.get`) → `completeInterruptedHistoryDeletion` (try/catch) → providers. Resume: invalidates `nowProvider`, re-initializes entitlement | — | Retirement steps write without confirmation (`prefs.remove`/`setBool`), and they are idempotent | — | — | `pre_release_retirement_test`, `thirty_app_test`, `main_test` |

**Notes**
- **Single writer per key** holds today, but only by convention:
  - Each user store has one queue.
  - History has exactly one writer path, Today's queue.
  - Delete is the only concurrent writer. It is coordinated by the epoch, `idle()`, ordering behind `_writes`, and a second pass.
  - `writeConfirmed`'s restore-on-failure is safe only under this rule [RISK]. Two overlapping writers to one key could have a failing first write restore its pre-image over a second write that already landed.
  - Nothing enforces or tests the rule. §9 proposes a cheap test-level guard.
- **The two retirement steps confirm nothing.**
  - They write with plain `prefs.remove` and `setBool`/`setString`.
  - `retireV1Premium` reads its marker with a typed getter, inside the awaited part of `main()`. A wrong native type under `v1_premium_retired` would throw before `runApp` [SRC, not executed].
  - This is an addition to Claude's O-2 list; it was not named there.

## 4. Write dependency and ordering map

Notation: `A ⟶ B` means B starts only after A is confirmed. `‖` means concurrent.

**F1: Choice of today's stage Circle**
- Plans `steerToday` → `_set(served)` (Plans queue, optimistic).
- Today queue: `_publish` → `confirmServed` (waits until Plans `_durable` holds the served stage, `:891–901`) ⟶ WAL record ⟶ each day key ⟶ WAL removal ⟶ History `recordShown`.
- Failure: an unstarted offer is withdrawn (`_withdrawUnsaveable`).

**F2: Start (decision B)**
- At the tap: the day check (`:1759`); the verdict is frozen (`:1767`).
  - **Fast path** (offer on disk and the Plans note already right): state becomes `started` at once. Then Plans `noteStart` ⟶ day keys ⟶ History `recordStarted`.
  - **Wait path** (`:1850–1905`): Plans `noteStart` is queued **at the tap**. The Today queue saves the offer if it isn't on disk ⟶ awaits `noted` ⟶ **checks the identity and the `notStarted` status only** ⟶ state becomes `started` with `startedAt = now` (`:1895`) ⟶ `noteStarted` in memory ⟶ `_persist`.
- **Cross-store window:** the Plans note can land while the Today Start never does. This is AUD-N1's precondition, and it is legitimate. The defect is that a later Start can't clear the note (cluster C3).

**F3: Close and credit.** Today `close()` → queue: `_persist` (Plans `confirmStartNoted` ⟶ day keys ⟶ History `recordClosed`) ⟶ Plans `recordGuided` (`:2127–2131`). The order History ⟶ Plans is what makes "the credit follows a durable Close" true. Recovery comes from `_mirrorInJournal` / `_recordBeforeOverwrite`.

**F4: Plan lifecycle** (Pause, Leave, Start another, Go through again)
- `_lifecycle` (`:282–301`) builds one Plans save holding:
  - (a) the credits folded in from **confirmed** History;
  - (b) the action-order stamps from the in-memory maps, with the fallback History `readAll()` (optimistic);
  - (c) the change;
  - (d) `appliedInsight`, when the change is an Insight's.
- Atomic within one key.

**F5: Insight apply**
- `apply` waits for Plans `idle()` and History `idle()` (`:304–305`). **It does not wait for Preferences.**
- It then decides current/stale on confirmed inputs ⟶ the target change with its provenance in the same save (Plans or Preferences; Kept for I4) ⟶ the Insights mark save.
- A failed mark leaves the target in place; the repair is from provenance.

**F6: Delete**
- Intent ⟶ epoch +1 ⟶ synchronous memory clears (`JournalWrites.forget`, Plans and Insights `_durable`/`state`, invalidating History and Today) ‖ first-pass removals ‖ the Plans and Insights forget writes, chained behind their queues ‖ waiting for stale Today writes and PreservationWrites.
- ⟶ Plans and Insights `idle()` ⟶ second pass (journal and day keys, Insights, the Plans unreadable copy) ⟶ marker removed.
- **Not covered:** the Plans action-order maps (AUD-N2) and Preferences `byInsight` (O-1).
- **Plans forget write:** computed from the **optimistic** `state` at the moment of Delete, with `_queued` dropped (`:896–900`), which is the source of AUD-N3.

**F7: Start-up.** Retirements ⟶ interrupted-Delete completion ⟶ build: Plans and Insights read and keep unreadable copies aside; Today restores, replays the WAL, and catches up History and credits. Entitlement is `initializing` until the gateway answers, asynchronously.

**F8: Resume.** `nowProvider` is invalidated (Today rebuilds; a waiting Start continues, guarded only by identity and status) and entitlement is re-initialized.

**Values fixed at the user's action vs re-evaluated at the persistence boundary** (Invariant IV)

| Value | Today | Should be | Status |
|---|---|---|---|
| Entitlement verdict for a stage Start record | Frozen at the tap (`:1767`) | Frozen (R8.1 RL-1: never a later answer) | Correct |
| Premium for running a Plan action / applying an Insight | At the mutation (`_lifecycle :288`; `apply :308` after the awaits) | Boundary | Correct |
| Premium for credit | At the credit (`recordGuided :836`), with the served exception | Boundary + provenance | Correct (provenance fidelity broken by C3) |
| **Local day for a Start** | **The tap only** (`:1759`) | **The boundary:** the valid Start is post-save (`startedAt` = post-save clock, `:1895`) | **Defect, R82-N05** |
| Offer identity | Boundary (`identical`, `:1888`) | Boundary | Correct |
| Deletion generation (disk writes) | Boundary (epoch; `_deletions`; `JournalWrites._generation`) | Boundary | Correct |
| Deletion generation (in-memory action order) | **Not scoped** | Boundary | **Defect, AUD-N2** |
| Plan/cycle identity for I2 | Bound (`cycleId`) | Bound | Correct (R81-A04 fixed) |
| "Already applied" for I1–I3 | Checked only when the snapshot is stale | Checked **before** any action | **Defect, R82-N01** |
| Preferences state for I3 | Insights reads `state` with no wait; `leaveOut` re-evaluates at its turn but reports a no-op as success | Outcome-aware at the boundary | **Defect, R82-N02** |

## 5. Six-invariant assessment matrix

| Invariant | Holds where | Violated by | Boundary that allows it |
|---|---|---|---|
| **I. Durable confirmation** | `writeConfirmed`; each store's `_set`/`_save`; Today WAL; `confirmed()` leaf check; Delete marker last | **AUD-N3** (an inverted false failure: the user is told the save failed although Delete later wrote it). Start-up retirement writes are unconfirmed [RISK, LOW] | Delete takes over the Plans queue state without settling it (`circle_plans_provider.dart:896–900`) |
| **II. Attribution** | Decision-C provenance in the same save; `_appliedOn` for stale snapshots | **R82-N02** (a no-op counted as this Insight's change); **R82-N01** (a re-application attributed again and re-dated) | `SuggestionPreferencesNotifier._save` returns `true` for a no-op (`:330`); `_leaveOut` maps `true` to `done` (`insights_provider.dart:461–464`); apply doesn't wait for Preferences (`:304–305`) |
| **III. Idempotence** | `recordGuided` at most once (`lastAdvancedCircleId` + record check); kept-Circle duplicate check; WAL replay | **R82-N01** (retry repeats I1/I2 over a later manual Pause, Leave or stopGentler) | The provenance check sits only in the stale branch (`insights_provider.dart:311–323`). "Current" means "the claim still holds", not "not yet applied" (`insight_engine.dart:614–629`; `_stepFor` returns `carryOn` for a paused Plan, `:255–261`) [SRC] |
| **IV. Temporal validity** | See the table in §4 | **R82-N05**; **AUD-N2** (stale session identity) | The day isn't checked again after the await (`recommendation_provider.dart:1886–1896`); Circle ids are day keys, reused after Delete |
| **V. Serialization fidelity** | Unknown-field retention in `PlanProgress.extra`, preference items and History; native-type reads (A09) | **R82-N03 / AUD-N1** (`startedAfterExpiry` can't be cleared); **R82-N04** (`AppliedInsight` drops extension fields); `_durable` is the model, not the bytes; O-2 typed getters | `ServedStageCircle.toJson` spreads `source`, then writes known fields only when truthy or non-null (`circle_plan.dart:727–734`); `AppliedInsight.toJson` (`:638–642`); `_set` (`circle_plans_provider.dart:205`) |
| **VI. Delete completeness** | Two passes; generations; intent first; queues drained; Plans `appliedInsight` dropped | **AUD-N2** (the deleted Start instant is written back); **O-1** (`byInsight` kept in Preferences, a founder decision). Kept Circles, Plan place and preferences preserved: correct | The Plans memory maps aren't cleared by `forgetStageEvidence` (`:895–924`); Delete has no Preferences step |

## 6. Root-cause clusters

| Cluster | Shared cause | Findings | Fix shape |
|---|---|---|---|
| **C1. Outcome ambiguity** | A store mutation reports success without saying whether it changed anything | R82-N02 (primary), R82-N01 (partly), AUD-N3 (the inverse: a reported failure later carried by another write) | A mutation outcome `changed / unchanged / refused / notSaved` at the Preferences boundary, mapped faithfully by Insights. Plans already distinguishes `notAvailable` |
| **C2. Provenance placement** | "Already applied" is decided from the Insight mark only, and the provenance proof is consulted only when the claim is stale | R82-N01 | Order in `apply()`: (1) own provenance on disk → mark from it and never act; (2) then current/stale |
| **C3. Codec overlay asymmetry** | Retained `source` plus conditional known fields means known fields can only be added, never cleared. A known nested type without retention loses extensions. `_durable` holds the model, so the divergence is invisible until restart | R82-N03 = AUD-N1, R82-N04 | One codec rule ("known fields authoritative, including absence; unknown fields retained"), applied to `ServedStageCircle` and `AppliedInsight`, and proven by a round-trip law test over every persisted record type |
| **C4. Validity not checked again at the boundary** | Validity checked at the tap, while the valid event is post-save | R82-N05; related policy point O-3 (Pause during a pending Start) | A boundary checklist; check the day again in the wait-path continuation |
| **C5. Delete boundary incomplete** | The Delete generation covers disk writes, but not memory caches or provenance in a retained store | AUD-N2, O-1, AUD-N3 | Delete clears every History-derived memory fact in its synchronous phase; the Plans forget write is computed at its own turn in the queue; the `byInsight` disposition per D1 |
| **C6. Evidence and test architecture** | Tests assert outcomes and memory more than disk-after-restart; settles serialize every action; no "ack-lost" fault; the validator trusts summaries | All seven escaped; raw-log validation gap | §11 |

Two items sit outside the clusters:
- **O-2**, native typed getters: input robustness, invariant V. It is the same class as A09.
- **The raw-log validator**: tooling.

## 7. Analysis of the seven audit findings

| Finding | Demonstrated? | Invariant | Cluster | Boundary (source) | Verdict |
|---|---|---|---|---|---|
| **Astra R82-N01**: I1/I2 repeated after a manual reversal | **[AUD-SRC]**, confirmed by my trace (`insights_provider.dart:311–323, 396–418`; `insight_engine.dart:255–261, 614–629`). Not executed by anyone | III, II | C2 (+C1) | `apply()` acts on a "current" snapshot without checking its own provenance first | **Real. Fix in R8.3.** §13 D3 confirms the UX consequence |
| **Astra R82-N02**: queued manual I3 falsely attributed | **[AUD-SRC]**, confirmed (`suggestion_preferences.dart:329–330, 412–427`; `insights_provider.dart:453–464, 304–305`). Not executed | II, I | C1 | A no-op save returns `true`, mapped to `done`, then marked | **Real. Fix in R8.3** |
| **Astra R82-N03 / Claude AUD-N1**: expiry provenance serialization | **[EXEC]** by Claude: domain test fails on R8.2 and passes on R8.1; end-to-end gives 0 credits, expected 1. **[SRC]** `circle_plan.dart:714–734`, `1211–1227` | V (and IV via credit) | C3 | `toJson` spreads `source` and writes `startedAfterExpiry` only when true | **Real, introduced by R8.2. Fix in R8.3.** Withholds credit, never grants it |
| **Astra R82-N04**: `AppliedInsight` extension loss | **[SRC]** `circle_plan.dart:592, 614–615, 638–653`. Not executed | V | C3 | A valid record keeps 3 fields; only an invalid one is kept raw | **Real, LOW. Fix with the codec rule** (same change set as N03) |
| **Astra R82-N05**: pending Start crossing midnight | **[SRC]** `recommendation_provider.dart:1759` (tap only) vs `1886–1896` (no day check). Not executed. **Contract:** "An offer of the day before that was never started still can't be started after midnight", "Nothing starts by itself" (`PRODUCT_V2_CONTRACT.md` midnight amendment) | IV | C4 | The continuation checks identity and status, not the day | **Real. Fix in R8.3.** The existing rule is applied at the right point; no new semantics |
| **Claude AUD-N2**: deleted Start instant retained | **[EXEC]** by Claude (fails on R8.2, passes on R8.1). **[SRC]** `circle_plans_provider.dart:309–317, 357–366, 895–924` | VI, IV | C5 | `_startedAt`/`_closeRequestedAt` survive Delete; the Circle id is the day key, so a same-day re-serve matches | **Real, introduced by R8.2, LOW impact** (no wrong credit). **Fix in R8.3** (clear in `forgetStageEvidence`) |
| **Claude AUD-N3**: false failure notice around Delete | **[EXEC]** by Claude on both R8.2 and R8.1. **[SRC]** `circle_plans_provider.dart:896–900`, `219–229`; `circle_history_deletion.dart:180` | I (inverse) | C5/C1 | Delete writes `state.forgetStageEvidence()` from the optimistic `state` and drops `_queued`, so the failing save's rollback is skipped and the unconfirmed Pause is written by Delete | **Real, pre-existing, LOW.** No data loss and no false confirmation. **Recommended for R8.3 (D4)** |

**The additional points you asked about**
- **Insight provenance left in Preferences after Delete (O-1).** Static, confirmed (`ElementLeftOut.byInsight`; Delete has no Preferences step).
  - The ids encode an Insight's family and date.
  - Plans' own `appliedInsight` **is** dropped by Delete (`circle_plan.dart:1268–1279`), so the two stores currently apply different Delete boundaries to the same kind of provenance.
  - It does not influence recommendations.
  - It is a founder decision (D1).
- **Native typed getters (O-2).** Confirmed static. Two groups:
  - Claude's list: `analytics_consent.dart:29`, `tester_identity_provider.dart:62/69`, `first_breath_provider.dart:29`.
  - **Also:**
    - `v1_premium_retirement.dart:26`, in `main()`'s awaited start-up, where it could block launch [SRC, HYP impact];
    - `reminder_provider.dart:121–123`;
    - the invitation flags (`premium_offer_provider.dart:45`, `reminder_invitation_provider.dart:42`, and the two widgets).
  - Today's day keys use the type-safe `_DayKeys` and are not affected.
- **Start pending before Pause (Claude O-3).** [EXEC] by Claude: 0 credits.
  - It follows the letter of "Pause before a valid Start earns no credit", because the valid Start is post-save (decision B).
  - The user, though, tapped Start first.
  - This is a policy question (D2), not a defect.
- **Incomplete raw-log validation.** [EXEC] by Astra: an emptied raw `batch_18c.jsonl` with its summary intact still gives EVIDENCE OK. A tooling gap only; both auditors parsed the committed raw logs and found them complete.

## 8. Assessment of Options A, B and C

| Criterion | A: isolated fixes | **B: bounded hardening** | C: SQLite / transactional |
|---|---|---|---|
| Closes the 7 findings | Yes | Yes | **No.** None of the seven is a multi-key atomicity failure: N01, N02, N05 and AUD-N2 are logic or boundary errors, N03 and N04 codec errors, AUD-N3 a queue-takeover error. All would still need the B changes on top |
| Prevents recurrence of the classes | Weak: no shared rule, oracle or law test. R8 → R8.1 → R8.2 each introduced a same-class defect | **Strong for C1–C5,** through 2 contracts + 2 checklists + the invariant oracle and codec law | Only for atomicity, which isn't the failing property |
| Change size | ~6 files, small | ~6–7 files, small, plus test support | New dependency (CLAUDE.md §2/§5: a dependency change is an explicit decision); a migration of ~45 keys and 6 JSON stores; a rewrite of every store |
| Existing user data | No migration | No migration. Stored bytes change only where fields are now written faithfully | A one-time migration with its own interruption, recovery and rollback semantics; export compatibility; new failure surfaces |
| Test burden | Small, but repeats the pattern | Medium: one shared harness and oracle, ~80–120 new deterministic tests, reusable | Very large: FaultDisk and R8Harness are SharedPreferences-based, so a new harness is needed, and all 2,774 tests would have to be re-validated |
| Founder workload | Low | Low: 3 confirmations (§13) | High: device migration QA, S25 runs, a new audit cycle |
| Business-rule complexity remaining | Unchanged | Unchanged, but codified | Unchanged. The lifecycle, provenance and midnight rules stay identical |
| Risk | Low per change, high recurrence | Low–medium | High |

**Choice: Option B,** the smallest option that meets the frozen contract with a credible chance of ending the cycle.

SharedPreferences on Android (legacy plugin, `commit()`; both auditors read the plugin source) is adequate, provided the single-writer-per-key rule is kept and tested.

## 9. Recommended minimal target architecture

The existing stores, keys, queues, WAL, generations and domain models are kept. The changes are two small shared contracts and two boundary rules.

**Contract 1: mutation outcome (C1).**
- A store mutation that may be a no-op says which it was: `changed`, `unchanged` (already in the requested state, not by this call), `refused` (not available, or unreadable), `notSaved`.
- **Rule:** an Insight is marked applied only on `changed` by its own call with its provenance, or on provenance proof (Contract 2's order).
- Scope:
  - `SuggestionPreferencesNotifier` gets an internal outcome-returning `_save`, plus an `idle()` like Plans and Insights. The public `Future<bool>` API stays for the UI callers.
  - `InsightsNotifier._leaveOut` maps `unchanged` to `alreadyApplied`, with no mark. That is the existing meaning of `alreadyApplied` in `_leaveOut :460`.
  - Plans already returns `notAvailable` for a no-op.
- **Not** a new framework.

**Contract 2: provenance-first apply (C2).**
- `apply()` order:
  1. waits for its target stores (Plans, History and **Preferences**);
  2. if the target store holds **this** Insight's provenance (`_appliedOn`), it records the mark from that provenance and never acts, whatever current/stale says;
  3. only then does it check current/stale and act.
- `_appliedOn` for I1 should also bind to the provenance's `cycleId` as I2 does, where the snapshot names one.
  - Today it accepts any record naming the Insight; see LIMITATIONS point 3.
  - This is a hardening, not a new semantic.

**Codec rule (C3).** For every persisted record that keeps a `source` or `extra` map:
- Encode = `source` **minus every known key**, then each known field from the model, with absence for false/null where absence is the canonical form.
- Unknown keys are kept; known keys always reflect the model, including clearing.
- Apply to `ServedStageCircle.toJson` (`startedAfterExpiry`, `startedBeforePause`, `closedBeforeLeave`).
  - `stage` is still taken from `source` when present, which is intentional (A05).
- Apply to `AppliedInsight`: retain the unknown fields of a valid record.
- **Proof** is a table-driven round-trip law over every persisted record type (§11). `_durable` stays the model: re-decoding the bytes at run time would break the identity-based `hasUnsavedChanges` (`:138`), so the law test is the right enforcement point.

**Boundary rule A: revalidate after every await that ends in a user-visible transition (C4).**
- A checklist applied to the continuations: `_startOnceSaved`, `apply()`, `recordGuided`, the Delete passes.
- For each: day, session identity (offer identity plus circleId), Plan/cycle identity, entitlement where the policy says boundary, deletion generation.
- The only missing check today is the day in `_startOnceSaved`.
  - Fix: if the day has passed, do not start. Do what a tap after midnight already does (`ref.invalidate(nowProvider)`), with no new copy.
  - The offer was saved before midnight under its own day, so nothing else changes.

**Boundary rule B: Delete clears every History-derived fact it can reach (C5).**
1. `forgetStageEvidence` clears `_startedAt` and `_closeRequestedAt` (AUD-N2).
2. The Plans forget write is computed **at its turn in the Plans queue**, from the settled state (`_durable` after earlier saves landed or rolled back), with the deletion applied. It no longer comes from the optimistic snapshot taken when Delete began. Memory is still cleared at once, so "deleted stays deleted" holds (AUD-N3, D4).
3. `byInsight`, per D1.

**Architecture acceptance answers (§8 of the directive)**

1. **Can SharedPreferences support the guarantees?** Yes.
   - Cross-store atomicity is avoided by design: a change and its provenance share one key; cross-store flows are ordered plus idempotent catch-up.
   - The residual risks are device-level (ack-lost, power loss), not architectural.
2. **Which guarantees need explicit cross-store coordination?**
   - Close ⟶ credit (History ⟶ Plans);
   - Start (Plans note ⟶ day keys ⟶ History);
   - Insight apply (target store ⟶ Insights mark);
   - Delete (all stores);
   - the earlier-day overwrite (History + Plans ⟶ day keys).
   - All five exist and are ordered. Insight apply lacks the Preferences wait and outcome (C1).
3. **Is the WAL / deletion-generation approach sufficient?**
   - Yes for disk writes. The WAL (day keys) and the epoch, `_deletions` and `_generation` counters cover queued and in-flight writes.
   - Not for in-memory caches unless they are registered with the Delete (rule B).
4. **Are shared primitives necessary?** Two tiny ones (the mutation outcome; the codec rule as one helper), plus one shared **test** primitive (the invariant oracle and fault extension). No new storage primitive.
5. **Smallest design change:** §10.
6. **Exact files:** §10.
7. **Regression and migration risk:** low–medium, with no data migration (§12).
8. **Existing tests protecting each invariant:**
   - I: `r8_a01`, `r8b_precommit`, `r81_n01`, `r81_n10`, `r81b_rl1`, `r6_journal_save_failure`, `r8_a04`;
   - II: `r82_decision_c`, `r82_a04_a08_new3`, `r81_n04_n05`;
   - III: `r82_a01`, `r82_decision_a`, `r2_plan_credit_provenance`, `r8_kept_ownership_persistence`;
   - IV: `r6b_day_rollover`, `r8_midnight_resume`, `r81_n08_n09_aud2_time`, `r82_lifecycle_policy`, `b7_entitlement_matrix`;
   - V: `r81_n06_n07`, `r81b_rl3`, `r82_a05`, `r82_a09`, `r81_n02`;
   - VI: `r3_persistence_delete`, `r8_a04_delete_durability`, `r82_a02_new2`, `b8_delete_longitudinal`.
   - The seven findings show where each family stops: §11.
9. **New tests needed before implementation:** §11, written failing-first.
10. **Product policy requiring a founder decision:** §13.

## 10. Exact bounded implementation scope (proposed for R8.3, not authorized here)

| # | File | Change | Findings |
|---|---|---|---|
| 1 | `lib/features/plans/domain/circle_plan.dart` | `ServedStageCircle.toJson`: the source minus known keys, then known fields, so clearing works. `AppliedInsight`: retain unknown fields of a valid record (a `source`/`extra` map, written back) | R82-N03/AUD-N1, R82-N04 |
| 2 | `lib/features/plans/application/circle_plans_provider.dart` | `forgetStageEvidence` clears `_startedAt`/`_closeRequestedAt`. **(D4)** the forget write is computed at its queue turn from the settled state | AUD-N2, AUD-N3 |
| 3 | `lib/features/insights/application/insights_provider.dart` | `apply()`: wait for Preferences too; provenance-first order (Contract 2); map the Preferences outcome; I1 `_appliedOn` bound to the cycle where named | R82-N01, R82-N02 |
| 4 | `lib/features/home/application/suggestion_preferences.dart` | An internal outcome-returning `_save`; `leaveOut(…)` exposes `changed` vs `unchanged` to Insights; `idle()`. **(D1)** if decided: `forgetInsightProvenance()` strips `byInsight` and keeps the elements | R82-N02, O-1 |
| 5 | `lib/features/home/application/recommendation_provider.dart` | `_startOnceSaved` continuation: check the day again before `started`; if it has passed, nothing starts and the new day opens as on a tap | R82-N05 |
| 6 | `lib/features/home/application/circle_history_deletion.dart` | Only if D1 says strip: one confirmed Preferences step in Delete (before the marker removal) | O-1 |
| 7 | `lib/features/home/application/v1_premium_retirement.dart` | **(D5)** a type-safe marker read (`prefs.get(...) == true`, as Phase D's retirement already does) | O-2 (start-up) |
| 8 | `test/support/r8_fault_disk.dart` | Add `DiskFault.landsThenFails` (the write reaches the disk, and the call reports failure: the ack-lost window). Add a single-writer guard: fail a test if two writes to one key overlap | C6 |
| 9 | `test/support/` (new `r83_invariants.dart`) | A disk-level invariant oracle for I–VI, used after every scenario and after `restart()` | C6 |
| 10 | `test/features/r83/` (new) | The codec round-trip law; the 7 finding reproductions; the pairwise matrix; targeted triples (§11) | all |
| 11 | Evidence runner (copied into the R8.3 evidence folder, as for E-1) | `report`/`cases` also parse each raw `.jsonl`: one `done` with `success=true`, and per-file pass counts equal to the summaries | Raw-log gap |

- **Not in scope:**
  - no new dependency, migration, key rename or data-format version bump;
  - no change to billing, RevenueCat, Supabase, audio, localization, copy or the Founder Dashboard;
  - no refactor beyond these lines.
- O-2's non-start-up sites (analytics consent, tester id, first breath, reminder, invitations) are optional under D5.

## 11. Deterministic adversarial test plan

**Why the 2,774 tests missed these** (by your categories)

| Finding | Missing scenario | Missing failure injection | Incorrect oracle | Insufficient persisted-state assertion | Timing assumption | Incomplete round trip | Cross-provider concurrency gap |
|---|---|---|---|---|---|---|---|
| R82-N01 | ✔ manual reversal between a failed mark and the retry | | ✔ the test named "a later Pause and Go through again" runs Leave (Astra) | ✔ no Plan-state-after-retry assertion | | | |
| R82-N02 | | | ✔ checks the result, not `byInsight` on disk | ✔ | ✔ the manual write always completed first | | ✔ manual queued ahead of the Insight |
| R82-N03/AUD-N1 | ✔ restart between the Plans note and the Today Start | ✔ stop-after-write rarely combined with a later Start | | ✔ | | ✔ no true → false round trip | |
| R82-N04 | | | | | | ✔ no valid-extension round trip | |
| R82-N05 | ✔ clock advanced while a write is held | | | | ✔ the clock is constant across `settle()` | | |
| AUD-N2 | ✔ same-day re-serve after Delete | | ✔ Delete oracles check History and day keys, not Plans stamps | ✔ | | | |
| AUD-N3 | | ✔ a held failing write released during Delete | ✔ the notice is never compared with the disk | | | | ✔ |

Two structural reasons sit behind the table:
- `R8Harness.settle()` drains every queue between actions. Long simulations therefore never interleave, so concurrency is covered only by hand-written held-write tests.
- Oracles mostly read memory or results; few read `disk.stored()` after `restart()`.

**Reusable techniques**

1. **Invariant oracle** (`checkInvariants(disk, before:)`), run after every scenario and again after `restart()`:
   - **I:** every user-visible `done` is on disk; every failure notice for a store means its change is absent from disk, or the notice is cleared by a later confirmed save of it.
   - **II:** every I1–I3 snapshot with `appliedOn` has provenance on disk naming it (Plans `appliedInsight.insightId`, plus the cycle for I2; or `ElementLeftOut.byInsight`).
   - **III:** replaying the last user action, or the restart catch-up, leaves the disk byte-identical; a manual reversal recorded after an apply survives every retry.
   - **IV:** no day key holds `status=started` for a circleId whose day had passed at its `startedAt`, except the six-hour carry-over of a Start made before midnight; credits on paused or left Plans only with matching stamps.
   - **V:** for every record: decode∘encode is the identity on known fields; unknown keys are preserved; and the state restored after `restart()` equals the confirmed pre-restart state on `startedAfterExpiry`, the stamps, `appliedInsight`, `lastAdvancedCircleId` and the cycles.
   - **VI:** after a successful Delete and `restart()`, none of these remain: History, day keys, snapshots, stage evidence, stamps (and `byInsight` per D1). Kept Circles, preferences and each Plan's place equal their pre-Delete values.
2. **Codec round-trip law:** table-driven over:
   - `ServedStageCircle`, `AppliedInsight`, `PlanProgress`, `PlanCycle`, `StageRecord`, `CirclePlansState`;
   - `InsightSnapshot`, `InsightsState`;
   - `NotSuggested`, `RestLifted`, `ElementLeftOut`, `SuggestionPreferences`;
   - `CircleJournalEntry`, `CircleSessionRecord`;
   - the kept-Circle records.
   - Each row: stored map (canonical, with unknown keys, with malformed known keys, future version) × each known field set → cleared → changed.
3. **The `landsThenFails` fault** (the ack-lost window) and the **single-writer guard** in FaultDisk.
4. **Interleaving driver:** a scenario is a list of events, each one of:
   - a user action;
   - `hold(key)` / `release(fault?)`;
   - `clock.advance`;
   - `entitlement.set`;
   - `restart`;
   - `delete(accept|refuse)`.

   The driver runs both orders of each chosen pair without `settle()` in between, then settles, runs the oracle, restarts, and runs the oracle again.

**Matrix factors** (levels)

1. **Write outcome:** confirmed, false, throw, delayed (held), landsThenFails, stopped.
2. **Cross-provider landing order:** in order, or reversed, for these pairs: (Plans, day keys), (Plans, History), (Preferences, Insights), (Plans, Insights), (Kept, Insights).
3. **Retry after partial success:** none, the same operation, or after a restart.
4. **Restart with confirmed bytes only:** none, after the first landed write, or after all.
5. **Delete:** none, intent accepted, intent refused, or interrupted (stopped mid-pass).
6. **Same-day re-serve after Delete:** no or yes.
7. **Local midnight while pending:** no or yes.
8. **Entitlement:** active, inactive, initializing, or changing during the wait.
9. **Insight vs manual:** none, manual before, manual queued ahead, or manual reversal after.
10. **Plan lifecycle vs Close:** none, Pause before Start, Pause after Start, Leave before the Close request, or Leave after the Close request.
11. **Schema:** canonical, unknown fields, malformed known field, future version, or wrong native type.

**Coverage**
- **Pairwise** over factors 1–11 with a fixed, committed covering array, generated once and checked in as data: about 40–50 scenarios, each run through the oracle and a restart.
- **Targeted higher-order cases.** Each needs three or more interacting events:
  1. R82-N01 ×3: I1 after Pause, I1 after Leave, I2 after stopGentler. Each is failed mark + manual reversal + restart/retry.
  2. R82-N02: manual leaveOut held + Insight apply + release.
  3. R82-N03/AUD-N1: Start after expiry + stop after the Plans note + restart, resubscribe, Start, lapse, restart, Close.
  4. R82-N05: held offer publication + midnight + release.
  5. AUD-N2: Start + Delete + same-day re-serve + Pause, and its Leave/Close variant.
  6. AUD-N3: held failing Pause + Delete + release.
  7. Start pending + Pause + Close (O-3/D2, the policy oracle).
  8. landsThenFails on a Plans credit + restart + catch-up (credit once).
  9. landsThenFails on the Insights mark + retry (no second action).
  10. Delete interrupted + restart + a queued Insight apply resumed (nothing recreated).
  11. Entitlement `initializing` → `inactive` during a pending stage Start + Close (no credit) and `initializing` → `active` (credit).
  12. A stage-5 Close requested + Leave pending + Close lands (left cycle stays "left") and the paused stage-5 variant. Astra found no dedicated test.
- **Codec law:** about 15 record types × 4–6 rows.
- **Estimated total:** about 80–120 new tests. Each must fail on `e744f505` where it targets a defect, and pass after.
- **Simulated restart vs Android death.**
  - Every "restart" above is `R8Harness.restart()`: a new SharedPreferences over the confirmed FaultDisk bytes, inside one Dart process.
  - It is not an Android process kill, a power loss, or a real storage fault.
  - Those stay device-level release gates (§12 and §14).

## 12. Risks of the recommended approach

| Risk | Level | Mitigation |
|---|---|---|
| Codec change alters stored bytes (`startedAfterExpiry` dropped when false; the stamps written faithfully) | Low | Intended. Old records still decode. The round-trip law and restart tests guard it. No version bump |
| The Preferences outcome ripples to UI callers | Low | Keep the public `Future<bool>`; add the outcome internally for Insights |
| Provenance-first apply changes UX: a retry of an unmarked, already-applied I1 records the mark and leaves a later manual Pause in place | Low, but visible | D3 confirmation; follows your Invariant III |
| N05 fix: a Start that completes after midnight doesn't start | Low | Same behaviour as an existing tap after midnight; no new copy |
| AUD-N3 fix touches Delete ordering, the most sensitive flow | Medium | Make it optional (D4); held-write tests first; oracle VI after every Delete scenario |
| The new oracle or ack-lost fault reveals further defects | Medium (scope creep) | Rule: newly found defects are reported to you and not fixed automatically |
| Regression runtime and memory (2,774 + ~100) | Medium operationally | Same sequential runner and memory preflight (6–8 GB) as the R8.2 rerun |
| Native risks stay untested (ack-lost on device, power loss, S25/TalkBack) | Unchanged | Device gates before commercial release; not claimed by R8.3 |

**Overall regression risk:** low–medium. **Migration risk:** none (no migration).

## 13. Remaining founder decisions

| ID | Question | Options | Recommendation |
|---|---|---|---|
| **D1** | Insight provenance (`ElementLeftOut.byInsight`) after Delete | (a) strip the id and keep the left-out element; (b) keep as is | **(a).** Consistent with Plans, which already drops `appliedInsight` on Delete, and with "no residue from deleted journal evidence". It adds one confirmed Preferences step to Delete. Your preference itself stays |
| **D2** | A Start still waiting for its save, then a Plan Pause, then Close (Claude O-3) | (a) keep: the valid Start is post-save, so no credit; (b) order by the tap: credit | **(a)** unless you prefer (b). (a) keeps decision B and the confirmed "Pause before a valid Start earns no credit" unchanged; (b) is a new semantic |
| **D3** | Retrying an Insight whose own change is already on disk (only its mark failed), after you manually reversed that change | (a) record the mark only and keep your later choice; (b) apply again | **(a).** Your Invariant III requires it |
| **D4** | AUD-N3 (pre-existing LOW false failure notice around Delete) in R8.3? | Include / defer | **Include,** behind held-write tests. Claude rates it recommended, not blocking |
| **D5** | O-2 typed getters scope | (a) start-up-critical only (`v1_premium_retirement.dart`); (b) all listed sites; (c) defer | **(a)** in R8.3, (b) later as separate hardening |
| — | RL-4 pre-commercial decision | Unchanged | Not R8.3 |

## 14. GO / HOLD / FAIL for R8.3 implementation

**GO** for R8.3 under **Option B**, limited to §10.

**Conditions**
1. You accept this review.
2. You answer D1–D5. Items 1–3 and 5 of §10, and the test support, don't depend on them and may start on acceptance.
3. Failing-before tests (§11) are written and recorded before any production change.
4. No scope beyond §10; newly found defects are reported to you.
5. A full sequential regression on the exact tree, then an independent delta audit by both auditors.

**Not authorized by this review:** implementation, staging, commit, push or deployment.

**Still open for release:**
- real Android process-kill, ack-lost and storage-failure tests;
- S25 and TalkBack verification;
- RL-4;
- the commercial gates.

THIRTY Phase E remains **HOLD**.
