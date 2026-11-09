# R832-G1: lifecycle ABA during a pending Start is not detected (gate HOLD)

**Gate check:** Final Check A (founder directive, 7 Nov 2026, §2).
**Status:** reproduced, NOT fixed. Under §2 the gate stops here for founder review. No commit and no push were made.

## Reproduction

The test is `r832_final_gate_checks_test.dart.txt`, and the raw log is `FINAL_GATE_CHECKS_on_corrected_tree.jsonl`. It was run on the corrected tree, which has the same fingerprint as the 2,944-pass run.

| Case (Start pending while its offer is saved) | Expected | Actual |
|---|---|---|
| A1: Paused → Resume confirmed → Pause confirmed, same cycle | Cancelled | **Started**: a paused Start with its record, so no credit |
| A2: Active → Pause confirmed → Resume confirmed, same cycle | Cancelled | **Started** on the active Plan. A Close would credit it. |
| A3: Active → another Plan started (this one paused) → this one carried on again | Cancelled | **Started** on the active Plan |
| A4: Paused → Resume **refused** | Goes ahead, since no confirmed transition happened; never credited | As expected (PASS) |
| A5: same-day rebuild, then restart, while pending | Cancelled; nothing started | As expected (PASS) |

None of these cases produced a false credit or an orphan record that excludes a later Start:
- A1's record names its own valid paused Start.
- A2 and A3 start on an active Plan under the ordinary rules.

The defect is that the attempt **is not invalidated**, so the Circle starts on its own.

## Root cause

`CirclePlansNotifier.prepareStart` compares only the **final** confirmed lifecycle and cycle with the values captured at the tap (`PlanStartConditions`). A transition that returns to the original value compares equal.

## A candidate fix (not implemented; needs founder approval)

The pending Start lives only in memory: it never survives a restart (A5). So no persisted field is needed.

1. The Plans notifier keeps an **in-memory count of confirmed lifecycle transitions per Plan**. The count goes up when a confirmed save changes that Plan's lifecycle or current cycle compared with the previous confirmed state.
2. The tap captures that count, in addition to the lifecycle and cycle.
3. `prepareStart` cancels the Start whenever the count has changed, or when there is a pending lifecycle change for that Plan at settle time that later lands.
4. Refused changes never increase the count, so A4 keeps going ahead.

Estimated size: about 20 lines in `circle_plans_provider.dart`, plus the A1–A3 tests added to the suite. A full sequential regression is required afterwards.

## Check B: PASS

| Case | Result |
|---|---|
| Ba: the Preferences write throws before storage | Uncertain: no replay, not marked, the receipt stays, status stale |
| Bb: change confirmed, mark refused, no reversal | Opening Insights records the mark with the original date, the receipt is cleared, status applied |
| Bc: another Insight (I1) generated and applied while an I3 receipt is unresolved | The receipt is byte-identical and I3 is never replayed |
| Bd: interrupted Delete (the app stops after its intent) | Finished at the next start: snapshots and receipts are gone, the Leave-it-out choice stays without `byInsight`, and the kept Circle stays |
| Be: I1/I2 overwrite | I2's displaced mark lands and the app stops before I1's own change. After restart, I2 is marked with its original date and the Plan is byte-identical. I1 then applies once. The I2 retry gives `alreadyApplied` and gentler is not re-enabled. |

These add to the 30 founder-scope tests already in the suite. Those cover:
- receipt refused (B1-ctl2);
- mark refused (B1-1, B2-1);
- acknowledgement lost (B1-4, B2-6);
- restart after the receipt (B1-5);
- manual reversal (B1-1, B2-1);
- independent Keep (B2-3);
- the kept limit (B2-4);
- refused saves (B1-3, B2-5);
- restart after the action (B1-6, B2-7);
- reassessment and rebuild (R1);
- malformed and future fields (R2);
- Delete (R3).

## The "absent provenance" claim for I1/I2

I checked by reading the source which code can erase `PlanProgress.appliedInsight`:
- **another Insight's overwrite:** the displaced Insight's mark is reconciled first and confirmed, as tested in D-ctl3 and Be;
- **Delete Circle history:** the snapshots go with it;
- **an unreadable Plan record:** the Plan isn't run, and its Insight resolves to `notAvailable`.

Manual Pause, Leave, Stop gentler and new cycles keep it.

No production path was found where a missing record coexists with an I1/I2 action that actually landed. This holds only for the current set of writers. Any new writer of `appliedInsight` must keep the same reconciliation.
