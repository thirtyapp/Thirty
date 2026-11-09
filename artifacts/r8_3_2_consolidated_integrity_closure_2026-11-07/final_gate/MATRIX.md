| Test | R8.2 | R8.3 | corrected |
|---|---|---|---|
| Group A — Claude AUD-R83-1 A1 seq1: Pause → Start → Close → Resume → Leave → Again → restart ×2: never credited | FAIL | FAIL | PASS |
| Group A — Claude AUD-R83-1 A2 seq2: Pause → Start → Resume → Close → Leave → Again → restart ×2: never credited | FAIL | FAIL | PASS |
| Group A — Claude AUD-R83-1 A4 left Plan started again: Pause → Start → Close → Resume → Leave → StartPlan → restart ×2: never credited | FAIL | FAIL | PASS |
| Group A — Claude AUD-R83-1 A5 I1-style Go through again: Pause → Start → Close → Resume → Leave → AgainByInsight → restart ×2: never credited | FAIL | FAIL | PASS |
| Group A — Claude AUD-R83-1 A6 later lifecycle changes: Pause → Start → Close → Resume → Leave → Again → Pause → Resume → Leave → Again → restart ×2: never credited | FAIL | FAIL | PASS |
| Group A — Claude AUD-R83-1 A3 seq1 then the next day's catch-up: never credited | FAIL | FAIL | PASS |
| Group A — Claude AUD-R83-1 A7 Premium lapse verified at Start, then resubscribed: never credited | FAIL | FAIL | PASS |
| Group A — Claude AUD-R83-1 A-ctl1 control: Start → Close → Leave → Again (valid Start): credited once, on the first cycle | PASS | PASS | PASS |
| Group A — Claude AUD-R83-1 A-ctl2 control: Start → Close requested → Leave while the Close is saving → Again: credited once, on the left cycle | PASS | PASS | PASS |
| Group A — Claude AUD-R83-1 A-ctl3 control: Pause → Start → Close → Resume → Leave, no new cycle: never credited | FAIL | PASS | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 B1 (N01-A) the paused-Start prerequisite lands and the process stops before the Start: a later valid active Start is credited once | N/A | FAIL | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 B2 (AUD-R83-3) the prerequisite lands, the Start's own day-keys save fails: after a restart, a later valid active Start is credited once | PASS | FAIL | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 B3 control: the prerequisite lands but its answer is lost (the Start is refused): a later valid active Start is credited once | N/A | PASS | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 B4 (N01-B) a pending paused Start is cancelled by a same-day rebuild; its prerequisite then lands: a later valid active Start is credited once | N/A | FAIL | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 B-tie an abandoned prerequisite, then a later active Start at the very same instant (the harness clock stands still): the abandoned record is superseded first — credited once | N/A | FAIL | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 B7 an abandoned prerequisite whose removal the store refuses: that Start is refused, the record stays; the next tap removes it and starts — credited once | N/A | FAIL | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 B5 (N01-C) Resume tapped while the paused Start's prerequisite is being written, which lands: the Start became valid on the Plan as durably paused — never credited | N/A | PASS | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 B6 control: an abandoned prerequisite, then a genuine paused Start on the still-paused Plan, Close, Resume: never credited | N/A | PASS | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 B-ctl Pause → Start → Close → Resume → restart ×2: never credited | FAIL | PASS | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 B-ctl Start → Pause → Close → restart ×2: credited once | PASS | PASS | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 B-ctl Start → Pause → Resume → Close → restart ×2: credited once | PASS | PASS | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 S1 (Astra single-slot concern) two Circles started while paused on consecutive days, the Plan carried on between, restarts and catch-ups: neither credited | FAIL | PASS | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 B-ctl Delete while the paused-Start prerequisite is being written: no paused-Start fact survives; nothing credited | N/A | PASS | PASS |
| Group C — Astra R83-N02 / Claude AUD-R83-2 C1 (N02) Astra — first prerequisite refused | N/A | FAIL | PASS |
| Group C — Astra R83-N02 / Claude AUD-R83-2 C1b (N02) Astra — first prerequisite lands | N/A | FAIL | PASS |
| Group C — Astra R83-N02 / Claude AUD-R83-2 C1c (N02) Astra — first prerequisite lands, answer lost | N/A | FAIL | PASS |
| Group C — Astra R83-N02 / Claude AUD-R83-2 C2 (AUD-R83-2) Resume refused by the store while Start is tapped: Close, Resume, restarts — never credited | FAIL | FAIL | PASS |
| Group C — Astra R83-N02 / Claude AUD-R83-2 C2b control (AUD-R83-2) the held Resume lands: the Start is on an active Plan — credited once | PASS | PASS | PASS |
| Group C — Astra R83-N02 / Claude AUD-R83-2 C2c (AUD-R83-2) the held Resume lands but its answer is lost (reported refused): Close, Resume, restarts — never credited | FAIL | FAIL | PASS |
| Group C — Astra R83-N02 / Claude AUD-R83-2 C3 a Pause that lands and a Resume the store refuses, both pending at the Start tap: never credited | FAIL | FAIL | PASS |
| Group C — Astra R83-N02 / Claude AUD-R83-2 C4 control: nothing pending, the Plan active — the Start is valid at once (decision B fast path) and credited once | PASS | PASS | PASS |
| D1 (R83-N03) I2 applied, mark refused; gentler off by hand and the Plan paused; I1 carries the Plan on seven days later; the original I2 retried: gentler is never turned on again | FAIL | FAIL | PASS |
| D-ctl1 control: I2 never applied; I1 carries the Plan on later; I2 applied then: gentler turned on, I2 marked that day | PASS | PASS | PASS |
| D-ctl2 control: I2 applied, mark refused, no other Insight: the retry records the mark with the original date and changes nothing | FAIL | PASS | PASS |
| D-ctl3 (R83-N03) the displaced Insight's mark is refused: the later Insight changes nothing, the earlier provenance stays, and both resolve once the store accepts | FAIL | FAIL | PASS |
| Claude H1 — I3 around Delete's final Preferences pass H1 apply-then-delete: no Insight id survives a Delete reported done | PASS | PASS | PASS |
| Claude H1 — I3 around Delete's final Preferences pass H1 apply-then-delete, Preferences write held: no Insight id survives a Delete reported done | PASS | PASS | PASS |
| Claude H1 — I3 around Delete's final Preferences pass H1 delete-then-apply: no Insight id survives a Delete reported done | PASS | PASS | PASS |
| Claude H1 — I3 around Delete's final Preferences pass H1 delete-then-apply, Preferences write held: no Insight id survives a Delete reported done | PASS | PASS | PASS |
| O1 (Astra §7 observation) a value that names no day, or no instant, makes the Plan unreadable — kept as stored, never read as an exclusion that matches nothing | FAIL | FAIL | PASS |
| O2 the record round-trips with its instant and any field this build doesn't know; an R8.3.1 record (the day alone) is read and written back as stored | PASS | FAIL | PASS |
| O3 an R8.3.1 record still excludes every Start of its Circle; a record with an instant excludes only that Start | FAIL | FAIL | PASS |
