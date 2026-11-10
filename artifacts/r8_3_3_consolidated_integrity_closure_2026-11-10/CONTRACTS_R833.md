# R8.3.3 — contracts

Founder authorization of 10 November 2026. Baseline: `d4cf8c44` (R8.3.2 + R832-G1).

These contracts apply only to the three authorized findings. They add to `CONTRACTS_FINAL.md` (R8.3.2) and `CONTRACT_G1.md`, and replace neither.

## 1. Delete isolation (Astra R832-A01)

**Invariant.** After Delete Circle history succeeds, no asynchronous operation that began before it has created or restored History-derived evidence.

**Mechanism.** The barrier is the app's existing History-write epoch, `HistoryWriteGate.epoch`. No new subsystem is added.

1. **One epoch per operation.** `InsightsNotifier.apply` captures the epoch once, at entry. The whole application, across every await, runs under that epoch.
2. **When it is checked.** `_stillCurrent(epoch)` is checked at three points:
   - after the prerequisite waits;
   - after every awaited write of the operation's own;
   - immediately before each mutation is queued, in the same synchronous step.
3. **What it holds.** `_stillCurrent(epoch)` requires all three of the following:
   - the provider is still mounted;
   - the epoch has not moved;
   - no deletion is under way or pending.
4. **Mutations it guards.** The check guards every mutation an application can make:
   - the attempt receipt (`_recordAttempt`);
   - a receipt clearance (`_clearAttempt`);
   - a displaced Insight's mark and every Applied mark (`_markApplied`, and the final mark in `apply`);
   - the Plan change (`_direct`, `_gentler`);
   - the left-out part (`_leaveOut`);
   - the kept Circle (`_keep`).
5. **Why this closes the gap.** Delete moves the epoch (`gate._begin()`) synchronously, in the same step, before it queues its first Plans, Insights and Preferences passes. So exactly one of two things is true of any target write:
   - **It was queued before the boundary.** It lands before Delete's own pass in that store's queue, and that pass removes its attribution, as for any earlier write.
   - **It is never queued.** A check fails first.
6. **What the user sees.** A stopped application returns `notAvailable`: its Insight has been deleted. It changes nothing more. The user can make the same change by hand, or apply a fresh Insight later.
7. **Defensive final pass.** Delete's last pass now repeats the Plans stage-evidence pass (`plans.forgetStageEvidence()`).
   - Each Plan keeps its place (lifecycle and cycles); the pass removes stage evidence, including `appliedInsight`.
   - The pass also removes the copy of an unreadable Plans record again. It replaces the earlier separate removal of that key, so no two writes to the key overlap.
   - **This pass is not the fix.** The tests check that the stale continuation never moved the Plan's lifecycle (A01: `lifecycle == paused`). A final pass alone cannot undo a lifecycle change, so those tests prove the barrier, not the pass.
8. **What the barrier does not touch.**
   - A Delete refused before its intent is durable (`HistoryDeletionNotStarted`) does not move the epoch, and a waiting application completes normally (A01-v7).
   - A fresh application after Delete completes runs under the new epoch and works normally, with its own attribution (A01-v10).
   - User-owned data stays: the Plan's lifecycle and gentler choices, kept Circles, and left-out parts (A01-v11).

**Operation-lifetime consequence (disclosed).** The same barrier also stops an I3 (leave a part out) or I4 (keep a Circle) application under these conditions:

- the user tapped it before Delete began;
- Delete began while the application was still recording its attempt.

On R8.3.2, such a continuation left the part out, or kept a Circle from a History day that had just been deleted (A01-x1, A01-x2). Neither left a deleted Insight id behind, so neither is a separate Delete-completeness defect. On R8.3.3 both are cancelled with `notAvailable`.

## 2. I4 kept identity and ownership (Astra R832-A02)

**Invariant.** An Insight's completion proof never comes from a different action or a different user-owned object.

1. **ID allocation.** `KeptCirclesNotifier.newKeptId({tag})` allocates every new kept Circle's id. The id is built as `kept-<event-clock µs>-<48 random bits, hex>[-tag]`:
   - The event clock is the real instant, never the cached `nowProvider`.
   - The random part comes from `Random.secure()`, falling back to `Random()`. Tests can override it through `keptIdRandomProvider`.
   - If that id is somehow taken, a `-n` suffix is added. That makes the id unique against every kept Circle (read or retained) and every Keep under way, even with a stuck clock and stuck random (ID-1).
   - I4 uses the tag `insight`. A user's own Keep never gets an id ending in `-insight`.
2. **The Kept Circles domain enforces uniqueness.** `keepCircle(id:)` refuses, with `null` and nothing written, any id that one of the following already has:
   - a kept Circle;
   - a retained Circle that THIRTY can't read;
   - a Keep under way.

   The id is checked twice: at the call, and again inside the serialized commit (A02-C, A02-D, ID-3). An existing Circle is never overwritten.
3. **The attempt names both identities.** The persisted I4 attempt records two things:
   - `keptId`, the exact kept identity;
   - `target` = `keep:<source Circle>`, the original source. This field is unchanged from R8.3.2.
4. **Applied proof matches both.** `_appliedOn` for I4 marks the Insight Applied only when three things hold:
   - the attempt's target equals this snapshot's application;
   - a kept Circle has exactly the recorded `keptId`;
   - that Circle's `fromCircleId` is this Insight's own source Circle.

   A collision forced through the random seam (ID-2), or a legacy stored collision (A02-B2), therefore never proves another action.
5. **Rename and remove act on one Circle only.** If an id addresses more than one kept Circle, `renameKept` and `deleteKept` change none of them (A02-E). This can only happen in a record that R8.3.2 wrote. Such legacy duplicates are kept exactly as stored, through restart, export and Delete. They are never merged, re-identified or removed automatically.
   - **Open founder question (data-repair policy).** As of R8.3.3, the user cannot rename or remove either of two legacy Circles that share one id. Only a build of `d4cf8c44` can have written such a record: it needs two I4 applications on one cached day. That build was never released. A repair policy is needed, for example re-identifying the second record on read. It would change stored ownership identifiers, so it has not been implemented. See README §15.
6. **Boundaries kept.**
   - I4's Keep stays ungated without Premium (A02-F).
   - Acknowledgement lost and process stop: proof with the original date (A02-G).
   - Definite refusal: the attempt clears and a retry works once (A02-H).
   - Delete keeps both kept Circles, distinct (A02-I).

## 3. Pending-Start write identity (Claude AUD-R832-1)

**Invariant.** A pending Start can be authorized only by the Plan transition on which the user acted.

1. **Every Plans save is numbered.** `_set` gives each save its own number (`_saves`, in memory). It also records, per Plan, the save that last moved the Plan's shown place (`_shownMovedBy`). The place is the lifecycle plus the current cycle.
2. **Which save made each counted change.** When a counted change is confirmed (`_confirm`) or uncertain (`onError`, a thrown write), the number of the save that made it is recorded per Plan (`_countedFrom`).
3. **The Start records the save it was tapped on.** When the shown place differs from the confirmed place, `startConditions` keeps R832-G1's +1 allowance. It also records `pendingSave`, the save that moved the Plan to where the user saw it.
4. **The Start goes ahead only on that save.** `_startStillValid` requires the existing G1 conditions:
   - the same epoch;
   - the same generation;
   - the same lifecycle and cycle.

   When `pendingSave` is set, it also requires that the one change counted since the tap was made by that very save. A different later Resume with the same numeric generation never authorizes the Start (X1, X2).
5. **Outcomes.**
   - **Same Resume confirmed:** the Start goes ahead and is credited once (X-ctl, G6).
   - **That Resume refused or uncertain, and any later change confirmed instead:** the original Start is cancelled (X1, X2, X3).
   - **After a cancellation:**
     - nothing is started;
     - there is no History Start;
     - nothing is credited;
     - no paused-Start record is left.

     A new explicit Start under the then-confirmed Plan works and is credited once.
   - **Restart before the Start resolves:** nothing was started and nothing is owed (X4).
6. **Scope.** Everything stays in memory and nothing is persisted. There is no lifecycle event log and no transaction subsystem. A rebuild already cancels through the G1 epoch, and the save numbers are cleared together with it.
7. **UX consequence.** When several lifecycle saves are pending at the tap, the allowance is bound to the latest save that moved the shown place. A tap whose shown place came from a save that is later refused, while a different save produces the same place, is now cancelled; R8.3.2 started it. The user taps Start again. This follows the N01-C cancel policy and does not change it.
