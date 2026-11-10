# R8.3.4 — contracts

Founder directive of 10 November 2026. Baseline: `285b5c70` (R8.3.3).

These contracts cover only the three authorized findings: R833-A02, R833-A01 / AUD-R833-1, and R833-A03. They add to `CONTRACTS_R833.md` and replace none of it, except in two places:

- **§1.8 of R8.3.3 is made true.** It said that a refused Delete never stops a waiting application. That was false in the interval R833-A01 found.
- **§2.1 of R8.3.3 is made true.** It said that a Keep under way always holds its id. That was false while the Keep's write was pending (R833-A03).

No new persisted field. No migration. No new subsystem. Three production files change:

- `kept_circles_provider.dart`
- `insights_provider.dart`
- `circle_history_deletion.dart`

## 1. I4 exact-action identity (Astra R833-A02, MEDIUM)

**Invariant.** An I4 snapshot is marked Applied from disk only by the kept Circle that its own attempt created. No other action's kept Circle, including a later I4 of the same source Circle, can supply that proof. Distinct snapshot ids and a progressing clock still don't guarantee that, so the proof never rests on them.

### 1.1 The action identity

An I4 action is identified by two things:

- its snapshot;
- the `keptId` recorded in that snapshot's attempt receipt, written and confirmed before the Keep is queued (R8.3.2 B2).

The receipt lives in the Insights record (`insights_v2`), a single key that is written whole.

### 1.2 Allocation

`KeptCirclesNotifier.newKeptId` never returns an id that any of the following already has:

1. a kept Circle, read or retained (R8.3.3);
2. a Keep under way, until it has **settled** (R8.3.4, §3);
3. **for I4: any attempt receipt in the Insights state.** `_keep` passes `avoiding: _attemptKeptIds()`, which covers every snapshot's `attempt.keptId`, proven or not, landed or not.

If the base id is taken, a `-n` suffix is counted up until a free id is found. This is checked against the same sets, so a stuck clock and stuck random still yield a fresh id (A02-1, A02-2).

### 1.3 Allocation and receipt in one step

`_keep` does two things with no `await` between them:

1. it allocates the id;
2. `_recordAttempt` checks `_stillCurrent`, then `_set` puts the receipt into `state`.

So no other allocation can fall between the two. From that moment, every later I4 allocation avoids the id.

### 1.4 User-owned Keeps are disjoint by construction

Every caller other than I4 allocates without a tag: the Today card, Plan detail and the QA scenario. Their ids are `kept-<µs>-<12 hex>[-n]`. I4 ids end in `-insight` or `-insight-n`.

An untagged id never contains `insight`, so a user's own Keep can never produce an id that an I4 receipt names. This follows from the format, not from probability. Only I4 passes an explicit `id:` to `keepCircle`; this was checked across `lib/`.

### 1.5 Proof

`_appliedOn` marks an I4 snapshot S Applied only when all of the following hold:

- S's attempt target equals S's application (R8.3.2);
- a **readable** kept Circle has exactly S's `keptId` (R8.3.2);
- that Circle's `fromCircleId` is S's source Circle (R8.3.3);
- **R8.3.4: exactly one readable snapshot's receipt names that id.** An id named by two receipts proves neither of them (A02-3). Such a record can only have been written before R8.3.4.

### 1.6 Why the identity cannot be transferred

Let k be a kept Circle created by the Keep of snapshot B. Then `k.id = B.attempt.keptId`. Take any other snapshot A with an attempt receipt. There are four cases.

- **A's receipt was in `state` when B allocated.** B avoided it (§1.2, item 3), so `k.id ≠ A.keptId`.
- **A allocated while B's receipt was in `state`.** A avoided B's id (§1.2, item 3).
- **A allocated while B's Keep was under way.** B's reservation lasts until B's Keep settles (§1.2, item 2), so A avoided it.
- **A allocated after k had landed.** k is in the Kept state (§1.2, item 1), so A avoided it.

Between B's allocation and k landing, B's id is always held by at least one of these: B's receipt (§1.3), B's reservation, or k itself. The order is:

1. `keepCircle` sets state before it returns;
2. only then does the final mark clear the receipt.

Therefore `A.keptId ≠ k.id`, and k can never satisfy A's proof. A user-owned Keep cannot satisfy it either (§1.4).

**Divergent disk.** An uncertain Insights write whose restore also failed can leave a receipt on disk but not in memory. The next Insights write replaces the whole record from memory. B's own receipt write is such a write, and it must be confirmed before B's Keep is queued. So that divergent receipt is gone from disk before k can land.

**Restart.** After a restart, every receipt on disk is in `state` again (A02-2).

### 1.7 Unresolved, retained and malformed records

| Record | Can it ever be proof? |
|---|---|
| Unresolved attempt (uncertain Keep) | Its id stays reserved (§1.2, item 3) while the snapshot is kept. It stays stale until its own Keep is proven, and is never replayed (A02-1, A02-2, A02-5). |
| Retained, unreadable kept record with the recorded id and source | No: proof reads only readable kept Circles (A02-6). |
| Malformed attempt record | No: it makes its whole snapshot unreadable (R8.3.2). That snapshot is kept as stored, and never acted on or proven. |
| Two receipts naming one id (pre-R8.3.4 data) | No: neither is proven (A02-3). |

### 1.8 Persistence, Delete, Export, legacy

- **No new persisted field.** Kept records keep exactly their seven fields (A02-7). Receipts are unchanged.
- **Delete Circle history** removes every snapshot with its receipt. It keeps the kept Circles as stored, with no Insight id in them (A02-7).
- **Export** is unchanged.
- **Legacy duplicate kept ids** are preserved as stored, with no repair (founder policy).

**Disclosed limitation.** A record already written by an unreleased R8.3.3 build may have given a receipt's id to another I4's Keep of the same source, after which that other I4's receipt was cleared on success. Such a record cannot be told apart on read: only one receipt names the id. This needs a forced collision, or a 48-bit random collision within one microsecond, on a build that was never released. No repair is made.

## 2. A Delete intent that isn't confirmed yet (Astra R833-A01 / Claude AUD-R833-1, LOW)

These two findings have one root cause. `_stillCurrent` reads `isPending`, and `isPending` reads the SharedPreferences cache. That cache holds the intent before the platform confirms it. So an I3/I4 continuation stopped on a Delete that might still be refused, and left its receipt behind.

### 2.1 The barrier

`CircleHistoryDeletion.intentBeingRecorded` is non-null only while the intent's writes are under way: the first write, plus the one retry. It completes with one of three outcomes (`DeletionIntentOutcome`):

| Outcome | Meaning | When it is told |
|---|---|---|
| `confirmed` | The intent is on disk. | After `gate._begin()` has moved the epoch. |
| `refused` | Both writes answered `false`; nothing was written. | Before `HistoryDeletionNotStarted` is thrown. |
| `uncertain` | A write threw, or anything unexpected happened; the intent may be on disk. | Before the error propagates. |

### 2.2 Where an Insight waits

Two places wait for the outcome before their own synchronous `_stillCurrent` check:

- the I3 and I4 target steps after the receipt;
- `_clearAttempt`.

At each, the caller loops: while an intent is being recorded, it awaits the outcome. Then `_stillCurrent(epoch)` runs in the same synchronous step as the queued change. When no intent is being recorded, nothing is awaited, so timing is exactly as in R8.3.3.

### 2.3 Outcomes

| Delete intent | Application |
|---|---|
| Confirmed (durably accepted) | The epoch has moved, so the application stops (`notAvailable`). Delete removes the snapshot and its receipt. Nothing is made (I3/I4-ACCEPTED, I3/I4-RETRIED, CLEAR-ACCEPTED). |
| Definitively refused (never began) | The application goes on as if no Delete had been asked. The action is made and marked Applied, and the receipt is cleared (I3/I4-REFUSED). A refused target clears its receipt, and a retry makes the action once (I3/I4-CLEAR-REFUSED). |
| Uncertain | It fails safe: the application stops (`notAvailable`), its receipt is kept, the action is not made, and it is never replayed (I3/I4-UNCERTAIN). If the intent did land, the next start finishes the deletion and removes the receipt. |

### 2.4 Invariants kept

- No action proceeds after a confirmed Delete boundary. The epoch check is unchanged and still synchronous with each queued change.
- No action is replayed when its own target outcome is uncertain. The R8.3.2 receipts are unchanged.
- The cached deletion flag is never ignored. It is waited on until confirmed or refused. An earlier pending deletion that is durable (marker `true`) still stops every application.

### 2.5 Not changed (disclosed)

- An Insight tapped while an intent is being recorded still stops at the `apply` entry, or at the receipt pre-check, with `notAvailable`. No receipt is written, so nothing is stranded and the Insight stays current. This is an availability nuisance only.
- I1/I2 Plan targets and the final Applied mark are unchanged. A skipped mark is recovered later from the change's own provenance (R8.2 / R8.3.2).

## 3. Kept id reservation lifetime (Astra R833-A03, LOW)

### 3.1 One map of Keeps under way

`_keeping` is a map from kept id to the day being kept. It replaces R8.3.3's two sets.

- An entry is added at the call.
- It is removed only in `keepCircle`'s `finally`, once the commit has settled: confirmed, refused (`null`), or failed (a refused or uncertain write).
- It is never removed when the write begins.

### 3.2 Refusal (`_keepRefused`), at the call and again in the serialized commit

A Keep is refused when any of the following holds:

- the count isn't known;
- the confirmed count, plus the other Keeps under way that the state doesn't hold yet, reaches `maxKeptCircles`;
- the day is kept, or another Keep of it is under way;
- the id is taken.

A Keep that has landed but not yet released its entry is in the state already. It is not counted twice.

### 3.3 Outcomes

| Case | Result |
|---|---|
| Two valid Keeps while the first write is held, under a forced collision | Both succeed, with distinct ids (`base`, `base-1`, `base-2`), and all of them are stored (A03-1). |
| An id held by an unsettled Keep | Refused for any other Keep; nothing is duplicated (A03-2). |
| A refused or uncertain Keep | Releases its id; the next Keep is given it, and one record is stored (A03-3). |
| Capacity and same-day limits | They count Keeps under way, and refuse at the call rather than later in the commit. The stored result is the same as on R8.3.3 (A03-4). |

### 3.4 Uncertain writes and rebuilds stay conservative

- **Uncertain write.** `writeConfirmed` puts memory back. The Kept record is one key written whole, so the next Kept write replaces any copy that diverged on disk. For I4, the id stays avoided through its receipt (§1.2, item 3).
- **Rebuild.** A rebuilt notifier reads the store's cache, which already holds a write in flight, so it sees that Keep as kept and avoids its id.

### 3.5 Not added

- No global identity service.
- No new database.
