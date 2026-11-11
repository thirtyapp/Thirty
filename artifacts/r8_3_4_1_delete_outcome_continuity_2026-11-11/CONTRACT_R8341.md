# R8.3.4.1 — Delete outcome continuity (Astra R834-N01)

Founder directive, 11 November 2026. Baseline `dd9000cdd461c41d52a727f323b8e5c1003fefa0` (parent `285b5c70`). Nothing staged, committed or pushed.

## 1. Root cause (reproduced on dd9000cd)

- `CircleHistoryDeletion._delete.told()` clears `_intent` and then completes the outcome future.
- `InsightsNotifier._intentAnswer()` reads `intentBeingRecorded`. Once an intent has been answered, it returns `null`. A continuation that resumes after that point therefore never sees the outcome.
- An uncertain outcome does not move `HistoryWriteGate.epoch`. `writeConfirmed` restores the SharedPreferences cache, so `isPending` reads `false`, even when the marker is `true` on disk (lost acknowledgement).
- The result: an I3/I4 whose receipt write was held across the whole intent passes `_stillCurrent(epoch)` and makes its target.

## 2. Correction (2 production files)

**`CircleHistoryDeletion`** keeps two in-memory integers:

- `_intents`: how many Delete intents have begun being recorded. These are serialized by `delete()`.
- `_lastUncertain`: the serial number of the latest intent that was answered `uncertain`.

Two new members read them:

- `intentsAnswered`: the number of intents answered by now. An intent still being recorded is not counted.
- `uncertainSince(answered)`: `_lastUncertain > answered`.

`told()` records the serial only when it actually completes the outcome. The outer catch's second `told(uncertain)`, which runs after a `refused`, is ignored. A later intent never lowers `_lastUncertain`. So a newer `refused` or `confirmed` intent cannot hide an older uncertain one.

**`InsightsNotifier.apply`** captures `intentsAnswered` in the same synchronous step as the epoch. That value is threaded to the I3/I4 steps and checked as `_uncertainIntentSince(answered)` at three places:

1. Before the attempt (receipt) is recorded. If an overlapping intent is already known to be uncertain, the step returns `notAvailable` and writes no receipt; the Insight stays current.
2. In the post-receipt step, together with `_stillCurrent(epoch)`, after the R8.3.4 `_intentAnswer` loop. This check is synchronous with queuing the target, so the attempt is kept and nothing is made.
3. In `_clearAttempt`, together with `_stillCurrent(epoch)`. The attempt is kept, and the Insight becomes stale, exactly as when the R8.3.4 loop observes uncertainty.

## 3. Outcome contract

| Delete intent, relative to an I3/I4 already in progress | Result |
|---|---|
| Confirmed (either ordering) | Epoch moves, so `notAvailable`. Delete removes the snapshot and its receipt. Nothing is made. |
| Definitely refused (either ordering) | Goes on: done, Applied, receipt cleared. A refused target clears its receipt, and a retry makes the action once. |
| Uncertain, not landed (either ordering) | `notAvailable`. Receipt kept in memory and on disk, nothing made, Insight stale. Never replayed after restart. |
| Uncertain, landed with lost ack (either ordering) | `notAvailable`. Receipt kept. Next start finishes the deletion and the receipt goes with it. Nothing made. |
| An intent answered before `apply` began | Never stops the action. There is no global flag, so a fresh action after a completed refused or uncertain Delete behaves as at R8.3.4. |
| Several Deletes overlapping one action | Stops if any of them was uncertain, in any order. A later refused intent does not hide an earlier uncertain one. |

## 4. Not changed

- I4 identity and ownership.
- Kept id reservation and capacity, including the Gate C erratum.
- Plan pending-save Start authorization.
- Historical credit.
- I1/I2 attribution and their Plan targets.
- The final Applied mark.
- Conservative recovery of uncertain target writes.
- User-owned data preservation.
- The legacy duplicate-id policy.
- L-1.
- No persistent state, migration or new dependency was added.

## 5. Disclosed limitation

I1/I2 (Plan targets) were not changed (directive §5; R8.3.4 CONTRACTS §2.5). They write no receipt and do not wait on the intent. Their target check is the synchronous `_stillCurrent(epoch)`. The only await between `apply`'s entry check and that target check is `_keepDisplacedApplication`'s mark of an earlier Insight. In principle, an uncertain intent answered during that await would not stop the I1/I2. This has not been reproduced or measured, and it is not remediated here. It is reported for founder triage.
