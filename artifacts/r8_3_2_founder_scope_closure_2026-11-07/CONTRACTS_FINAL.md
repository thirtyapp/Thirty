# R8.3.2 final founder scope: contracts

This document supersedes §A.4 and §B.3 of `../r8_3_2_consolidated_integrity_closure_2026-11-07/CONTRACTS_R8_3_2.md`. The rest of that document stands.

## Contract B (final): durable Insight attempt and confirmation

### Which Insights need an attempt receipt

| Insight | Can a manual reversal erase every trace of the action? | Receipt |
|---|---|---|
| I1: Plan direction | No. Pause, Leave and a new cycle keep `PlanProgress.appliedInsight`. An overwrite by another Insight first records the displaced Insight's mark (R83-N03). | **None.** Absent provenance proves the action never landed. |
| I2: gentler | No. Stop gentler keeps `appliedInsight`. Overwrites are handled the same way. | **None.** |
| I3: Leave it out | **Yes.** Put back (and Reset) remove the `ElementLeftOut` entry, together with its `byInsight`. | **Required.** |
| I4: Keep from History | **Yes.** Removing the kept Circle removes the only trace. | **Required.** |

### The receipt

`InsightSnapshot.attempt` is stored as:

```
{"on": "<YYYY-MM-DD>", "target": "leaveOut:<element>" | "keep:<day>", "keptId": "<id>"}
```

- **`target`** must match the snapshot's own application.
- **`keptId`** is required for I4 and forbidden otherwise. It is the id the kept Circle is created with: `keepCircle(id:)`.
- **Unknown fields** are kept and written back.
- **Damaged receipts.** A receipt that is present but not whole makes the snapshot unreadable, so it is kept as stored and never read as "no attempt". This means a receipt that isn't a map, has a bad day or another target, or is an I4 receipt without `keptId`.
- **What it survives.** It is part of the snapshot record, so reassessment, a provider rebuild, restarts and other snapshots' writes all keep it. Test R1 checks this.
- **Delete.** Delete Circle history removes it together with the snapshots (test R3).

### Protocol

1. **Exact proof first.** This step applies to current and stale snapshots, and is also run on opening Insights (`assess`, Premium or not).
   - What counts as proof:
     - for I3, the part left out with this Insight's id;
     - for I4, the kept Circle with the receipt's `keptId`.
   - If the proof is on disk, the applied mark is recorded with the **action's own date** (`since` or `createdAt`). The receipt is cleared and the action is never repeated.
2. **An unresolved receipt is never offered again.**
   - A receipt with no proof means one of three things: the action never ran, its outcome was uncertain, or the user reversed it.
   - Such a snapshot has `statusOf` = `stale`. It is shown as "No longer current" and is never shown as applied.
   - If the user taps an already rendered button, `apply` returns `notAvailable`. Nothing is replayed and nothing is marked.
3. **Refusals known without writing** come before any receipt:
   - the part is already left out → `alreadyApplied`;
   - the day's Circle is already kept by another Keep → `alreadyApplied`, **not marked** (an independent Keep is never attributed to I4, B2-3);
   - the kept limit is reached → `keptLimitReached`;
   - the History entry is missing → `notAvailable`.
4. **Receipt write.** The receipt is written and must be confirmed. If it isn't confirmed, the result is `notSaved` and **no target mutation happens** (B1-ctl2; R8.2 decision C residual test, I3).
5. **Target action.** Outcomes:

| Outcome | How it is known | Receipt | Result |
|---|---|---|---|
| Durably confirmed | `PreferenceChange.changed`, or a kept Circle returned | Cleared by the mark write. If the mark is refused, the receipt stays, and step 1 records the mark later from the proof. | `done` |
| Definitively refused | The store answered `false`, the stored record is unreadable (`refused`), or a Keep was refused before writing (limit, duplicate, concurrent) | Cleared, so a retry is allowed (B1-3, B2-5, B2-4). If clearing fails, the receipt stays: no replay. | `notSaved` / `keptLimitReached` / `alreadyApplied` |
| Done meanwhile by something else | `PreferenceChange.unchanged` | Cleared | `alreadyApplied`, not marked |
| **Uncertain** | The platform call **threw**: `StorageWriteFailed.uncertain`, or `PreferenceChange.uncertain`. This includes an acknowledgement lost after the write landed. | **Kept** | `notSaved`. Never replayed, never claimed (B1-4, B2-6). |

6. **Interruption.**
   - If the app stops after the receipt and before the action, the snapshot is unresolved: no replay (B1-5).
   - If the app stops after the action and before the mark, the proof is on disk and the mark is recorded with the original date (B1-6, B2-7).

### User-visible behaviour

- An Insight whose application can't be proven either way is not offered again and shows "No longer current".
- It is never shown as "Applied" unless proven.
- The user can still make the change themselves (Leave it out, or Keep from History).

No new copy or UI was added.

### Known limits

- **A thrown write is conservatively uncertain.** On some platforms a throw may happen before anything lands. Such an I3 or I4 is then not offered again even though nothing changed.
- **Older records.** An I4 applied before R8.3.2 with a lost mark has no receipt. Its Circle can't be told apart from an independent Keep, so it stays unmarked and gives "That's already in place."

## Contract A, §A.4 (final): N01-C, the founder temporal policy

- **At the tap.** A Start records the Plan's lifecycle and current cycle as the user saw them: `CirclePlansNotifier.startConditions`.
- **After the prerequisites settle.** `prepareStart` waits for every pending Plans change, then compares the **confirmed** Plan with what the tap recorded. Either value changing means the Start is **cancelled** (`PlanStartCancelled`):
  - a Resume or Pause confirmed meanwhile;
  - a refused change the tap was made on;
  - a new cycle, a Leave, or another Plan started.
- **Re-check.** The same comparison is made again if a lifecycle change was asked for while the paused Start's own record was being written.
- **On cancellation:**
  - nothing starts, and no durable started session is written;
  - no notice is shown (the same as other cancellations, such as a day change or a rebuilt offer);
  - the user taps Start again;
  - a record already written names an instant no session has, and the next Start replaces it, so it never affects a later valid Start.
- **Unchanged:**
  - The fast path still starts at once, because it requires no pending Plans change, which means the confirmed Plan and the shown Plan are the same.
  - A refused lifecycle change leaves the Start going ahead (N3, N4).
  - A fresh Start after a confirmed Resume follows the active-Plan rules (N1, N7, N8).
  - A fresh Start while the Plan is paused gets no credit (N2).
  - Billing and the Premium-at-Start rules are unchanged.
