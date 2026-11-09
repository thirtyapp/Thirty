# R832-B1 / R832-B2: founder scope decision requested

These are new findings. Neither independent audit reported them. They came up while I exercised Contract B ("Later explicit manual reversal"). I have reproduced them but **not** implemented them. Fixing them needs a design choice outside the authorized Groups A–D.

## The findings

| ID | Sequence (executed) | R8.2 | R8.3 | Corrected tree |
|---|---|---|---|---|
| R832-B1 | I3 applied: the part is left out, `byInsight` is saved, and the applied mark is refused. The user taps **Put back**. After a restart, I3 is `current` again. The retry leaves the part out again, with the I3 mark on the retry day. | FAIL | FAIL | FAIL |
| R832-B2 | I4 applied: the Circle is kept, and the applied mark is refused. The user **removes that kept Circle**. After a restart, I4 is `current`. The retry keeps the Circle again. | FAIL | FAIL | FAIL |

- **Probe:** `r832_open_findings_probe_test.dart.txt`. It is the reproduction file plus these two tests. Run it with `--run-skipped --name R832-B`.
- **Raw logs:** `../final_gate/OPEN_FINDINGS_probe_on_{r82,r83,after}.jsonl`.

## Why this is a D3 violation

D3 says a retry of an Insight whose own action already landed must never repeat that action, and a later manual change is authoritative.

- **Where provenance lives.** For I1 and I2 it lives on the Plan, and Pause, Leave and Stop gentler keep it (R8.3).
- **I3.** Put back deletes the `ElementLeftOut` entry, and with it `byInsight`.
- **I4.** The kept Circle's `fromCircleId` is the only trace of the application, and removing the Circle removes it.
- **Why the retry repeats.** After either erasure, nothing durable says the action ever happened. So the retry repeats it.

## Same root cause as R83-N03, different eraser

The root cause is the same. An Insight's application is identified only by provenance in the target store, and that provenance can disappear while the Insight's own mark is not on disk.

- For R83-N03, the eraser was a later Insight's overwrite. R8.3.2 closes that case: the displaced mark is recorded first.
- Here, the eraser is the user's own action in another store (Preferences, Kept Circles).

## Options

### Option 1 (recommended): an attempt record on the Insight snapshot

Write `attemptedOn` to the Insights store before the action.

**How a retry decides:**
- if the target's provenance names the Insight, it records the mark (D3);
- if there is an attempt but no provenance, it declines as ambiguous, with no action;
- if there is no attempt, it is a first application.

**Properties:**
- Uniform for I1–I4.
- One additive optional snapshot field. Unknown snapshot fields are already preserved.
- No migration.

**Cost:**
- It reverses R8.2 decision C's stated design ("no separate record of the intent is needed").
- An Insights store that refuses writes now refuses Apply.
- About 8 existing fault-injection test files that refuse the Insights store around Apply need their fault moved to the mark write.

### Option 2: repair before erase in the erasing stores

Put back, Reset and kept-Circle removal first record the mark of an unmarked Insight they name.

**Properties:**
- No schema change.

**Cost:**
- Cross-store coupling: Preferences → Insights, and Kept Circles → Insights.
- A user's Put back or removal can then be refused because the Insights store refuses.
- I4 has no Insight id on the kept Circle, so it has to search for the snapshot.

### Option 3: accept as a documented limitation

The retry is a fresh user tap on an Insight shown as current, after the user was told its first save failed.

**Cost:**
- D3 stays violated for I3 and I4.

**Requested:** choose 1, 2 or 3, or another option, before R8.3.2 is accepted. Until then, Contract B is complete for I1 and I2 (overwrite and manual reversal) and open for I3 and I4 manual reversal.
