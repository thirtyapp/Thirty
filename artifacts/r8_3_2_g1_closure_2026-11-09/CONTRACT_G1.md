# R832-G1: the per-Plan generation contract (founder authorization, 2026-11-09)

**Scope:** one production file, `lib/features/plans/application/circle_plans_provider.dart`. Today (`recommendation_provider.dart`) passes `accepted` through unchanged, so no change was needed there.

There is no new persistent field, store, migration or transaction framework. Every other R8.3.2 fix is unchanged.

## Mechanism

| Element | What it does |
|---|---|
| `_generations: Map<String, int>` | Per Plan, the number of lifecycle or current-cycle changes the store has confirmed since `_epoch` began. It lives in memory only. |
| `_epoch: Object` | A new identity at every `build()`, and `_generations` is cleared at the same moment. Conditions captured before a rebuild can never match after it. A new process or container gets a new notifier, so it gets a new epoch. |
| `_confirm(next)` | Replaces both assignments of `_durable` after a confirmed write: in `_set`, and in Delete's own write. For every Plan whose lifecycle or `current.id` differs between the previous `_durable` and `next`, the count goes up by one. A Plan that is added or removed also counts as a change. |
| `_set` `onError` | If the store **refused** the write (`StorageWriteFailed` with `uncertain == false`), nothing is counted. If the outcome is **uncertain** (the platform call threw, so the write may have landed) or the error is unexpected, the count goes up for every Plan the write would have moved. This is the fail-safe route. |
| `PlanStartConditions` | Now `{lifecycle, cycleId, generation, epoch}`. It is captured at the Start tap, as before. |
| `startConditions` | `generation` is the confirmed count, plus 1 when the Plan shown differs in lifecycle or cycle from the Plan as confirmed. That extra 1 is the one change the user saw still being saved, and the Start was asked for on it. |
| `prepareStart` | Cancels the Start with `PlanStartCancelled` if any of these holds: the notifier is unmounted, the epoch differs, the count differs from `accepted.generation`, or the confirmed lifecycle or cycle differs. It checks this at the first decision, after all prerequisite waits, and again after the paused-Start record's own write. That last check waits for any Plan change still being saved. |

No count is made for:
- a write the store refused;
- a no-op (an action that returns `notAvailable` writes nothing; a save that leaves a Plan's lifecycle and cycle unchanged moves nothing);
- a change only shown (`state` is not `_durable`);
- the optimistic `_durable` update at the start of Delete Circle history, which changes only stage evidence.

## The founder's requirements, mapped

| Requirement | Where it is met | Test |
|---|---|---|
| Count up when a lifecycle or cycle change is durably confirmed | `_confirm` | A1–A3, G1, G2 |
| Track every affected Plan, including the automatic Pause when another Plan starts | `_countChanges` covers every Plan key in the confirmed state | A3 |
| Never count a failed write, a no-op or an optimistic change | Counting happens only in `_confirm` and on uncertain failure | A4, G3, G6, R4, R6 |
| A refused intermediate change does not cancel a valid Start | A refused change is not counted | A4, G3 |
| An uncertain confirmation fails safe | `onError` counts uncertain failures | G4 (throws), G5 (ack lost) |
| Capture at the pending Start boundary, verify after all waits | `startConditions`, `_startStillValid` in `prepareStart` | all |
| Cancel on a different count even when lifecycle and cycle are back where they were | count comparison | A1, A2, A3, G1, G2 |
| A rebuild, Delete, stale continuation or restart cannot bypass the check | Epoch and mount check; Delete never resets the count; a pending Start dies with its process | R1, R2, R3, R5, R7, R8, A5 |
| Start, Close, Pause, Leave and Premium credit policy unchanged | No change to the credit or lifecycle code paths | C1, C2, A2/A1 fresh Starts, the whole regression |

## Known limitations (all fail safe: a Start is cancelled and the user taps Start again)

1. At the tap, the pending allowance is at most **one** change. If two or more lifecycle or cycle changes are still being saved at the moment of the tap, and they all land, the Start is cancelled. The same happens if a pending chain returns the shown Plan to its confirmed place (shown equals confirmed, but changes are in flight).
2. A Plans rebuild (`build()` re-run, or a new notifier) cancels any Start captured before it, even with no transition. In production the Plans provider rebuilds only when `sharedPreferencesProvider` changes, which means once per process.
3. An uncertain failure of the unreadable-record copy that is set aside before a write (`_protectStored`) is also counted for the Plans the write would have moved, even though the main write never ran.
4. If an uncertain write did land on disk while memory rolled back, the disk and memory disagree until the next whole-record save. That is pre-existing (R8.3.2 B1/B2 contract). G1 only makes sure that no pending Start is authorized across it.
5. The count is in memory only. That is sufficient because a pending Start is in memory only (A5, R7, R8). A Start that was confirmed before a restart is not affected.

These limitations narrow nothing the founder's policy allows: each one cancels, never authorizes.
