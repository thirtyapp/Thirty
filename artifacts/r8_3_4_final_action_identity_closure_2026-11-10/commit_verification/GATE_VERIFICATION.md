# R8.3.4 — final targeted verification gates (commit authorization)

Founder directive, 10 November 2026, §3. These are review gates on the actual uncommitted R8.3.4 source. No source or test file was changed for them.

The executed probes are in `gate_probes/r834_gate_probes_test.dart.txt`. They ran only in the disposable checkouts:

- **red:** the exact `285b5c70` export;
- **fixed:** that export plus R8.3.4. Each of its five changed files is equal, by Git blob, to the working tree.

The per-file results are in `gate_probes/GATE_PROBES_perfile.txt`, and the raw reporter logs sit beside them.

## Gate I — the staged code is the tested code

These checks ran before staging:

- The current `lib/`, `test/` and configuration fingerprint equals `regression/SOURCE_FINGERPRINT_end.sha256`.
- The Git-blob manifest equals `regression/SOURCE_MANIFEST_git_blobs_end.txt`, with 386 entries.
- Every changed source and test file was last written before the run started (19:01:59).

## Gate A — I4 ownership: PASS

### Source chain

All line numbers are from the uncommitted R8.3.4 source.

**1. Allocation avoids every recorded attempt.**

- `_keep` allocates with `newKeptId(tag: 'insight', avoiding: _attemptKeptIds())` (`insights_provider.dart:774`).
- `_attemptKeptIds` takes the `attempt.keptId` of every snapshot in `state` (`:513`).
- `newKeptId` suffixes while either of two things holds (`kept_circles_provider.dart:319–326`):
  - `_idTaken` holds: a kept Circle, a retained Circle, or a Keep under way has the id;
  - `avoiding` contains the id.

**2. No await separates allocation from the receipt entering `state`.**

- `_recordAttempt` checks `_stillCurrent` (`:541`) and calls `_set` (`:543`).
- `_set` assigns `state` before its first await (`:172`).

**3. Concurrent applications are serialized.**

- `apply` awaits the Insights `idle()` before reaching `_keep`. So a second I4 never allocates while the first one's receipt write is pending.
- It allocates once that receipt is on disk and in `state`, and while the first Keep is under way and reserved.
- GATE-A1b shows this in execution: `attemptIdB` is `null` while A's write is held.

**4. Pending receipt persistence.**

- A refused receipt write rolls `state` back only when it was the latest save (`:200`), and the attempt then returns `false`: no Keep is made.
- An uncertain write that leaves a receipt on disk but not in memory is overwritten whole by the next Insights write.
- That next write is B's own confirmed receipt, before B's Keep is queued (CONTRACTS_R834 §1.6).

**5. Proof (`:485–505`) requires four things:**

- the target;
- a readable kept Circle with the exact id;
- that Circle's `fromCircleId` equal to the source;
- exactly one snapshot in `state` naming the id (`:496`).

### Executed evidence

| Probe | Result after the fix | Result on R8.3.3 |
|---|---|---|
| GATE-A1b: two current I4s of different sources, applied concurrently under a forced collision, A's attempt write held | A `…-insight` from 2026-10-29 and B `…-insight-1` from 2026-11-27; both Applied by their own Keep | **B lost**: `notAvailable`, only A kept |
| GATE-A1: the same through production `assess()` alone | **PRECONDITION, not constructible on either tree.** The engine never shows two current I4s at once. Not counted as a pass. | same |

The same-source case is covered by the permanent tests (24/24):

- A02-1 and A02-2 (with restart);
- A02-3: two attempts naming one id, identical source, prove neither;
- A02-6: a retained, unreadable record is never proof.

Protection of legacy duplicates stays covered by the unchanged R8.3.3 tests A02-B2 and A02-E, which pass in the 3,023 run.

## Gate B — Delete confirmation: PASS

### Source chain

**1. Order inside `_delete`.**

- `_intent` is set synchronously, before the first intent write.
- `refused` is told only when **both** writes answered `false` with no throw (`circle_history_deletion.dart:206–215`). It is told after `writeConfirmed` has put the cache back.
- Any throw is `uncertain` (`:211`, `:220`). Definitive refusal is never inferred from an exception whose storage outcome is unknown.
- `confirmed` is told only after `gate._begin()` has moved the epoch (`:223–224`).

**2. Waiters.**

- The I3 and I4 post-receipt steps (`insights_provider.dart:711–717`, `:784–790`) and `_clearAttempt` (`:568–575`) loop on `_intentAnswer()`.
- Each then runs the unchanged synchronous `_stillCurrent(epoch)` in the same step as the queued change.
- After `confirmed`, the epoch has moved, so no target mutation is queued.
- After `uncertain`, they stop without clearing.
- If unmounted, `_intentAnswer` is `null` and `_stillCurrent` is `false`.

**3. A second Delete serialized behind a refused one.** Its `_intent` and its cached marker are set in one synchronous step. So a waiter that resumes either waits on it, or queues before its boundary, where the deletion pass removes the attribution. GATE-B1 covers this.

### Executed evidence

| Probe | Both trees |
|---|---|
| GATE-B1: an I3 waits on a refused intent, then a second Delete is confirmed | The first Delete is `HistoryDeletionNotStarted`, the second succeeds, and `apply` returns `notAvailable`. No stored key names the Insight; the journal, the Insights and the marker are gone. |

The permanent tests cover the outcomes on R8.3.4:

- REFUSED (I3/I4): **completes**, so nothing is stranded;
- ACCEPTED and RETRIED: stopped, nothing made;
- UNCERTAIN: stopped, attempt kept, never replayed;
- CLEAR-REFUSED (I3/I4): the receipt is cleared and a retry works once;
- CLEAR-ACCEPTED: nothing made.

## Gate C — Keep reservations: PASS

### Source chain

- The reservation is added at `kept_circles_provider.dart:384`.
- It is removed only in `finally` (`:392–394`), after `_commit` has completed. That is after the write is confirmed and `state` is set, or after a refusal or failure.
- `_keepRefused` (`:332`) excludes the Keep's own entry, and any entry whose id is already in state, so nothing is counted twice.

### Executed evidence

| Probe | Result after the fix | Result on R8.3.3 |
|---|---|---|
| GATE-C1: 6 kept, a second valid Keep while the first write is held | Both land: `…-6` and `…-7`, 8 kept | **the second is lost** (`null`, 7 kept) |
| GATE-C2: 7 kept, the 8th Keep's write held and then refused, a 9th requested meanwhile | The 9th is refused (`null`) while the 8th is unresolved; retried after the 8th settles, it lands (8 kept, 8 distinct ids) | The 9th was accepted during the hold, because the 8th's reservation had already vanished |
| A03-1 to A03-4 | 24/24 permanent tests | — |

**Why GATE-C2 is not a rejected legitimate Keep.** When the 9th is requested, capacity does not permit it unless the in-flight 8th fails, and that outcome is not yet known. Counting Keeps under way toward the limit is the documented `keepCircle` rule. R8.3.3's acceptance in this case was a side effect of the defect fixed here (R833-A03). The user's retry after the 8th settles succeeds, no duplicate identity is stored, and this preserves the conservative handling of unresolved writes.

### Erratum to `CONTRACTS_R834.md` §3.3, last row

That row says: "The stored result is the same as on R8.3.3 (A03-4)." This holds when the Keep under way **succeeds** (A03-4). When it fails, R8.3.4 has already refused the over-limit Keep at its call (GATE-C2), whereas R8.3.3 would have kept it. The reviewed document is left unchanged; this note is the correction.

## Verdict

**Gates A, B and C: PASS.** No counterexample to any approved contract was found.
