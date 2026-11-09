| Test | R8.2 | R8.3 | R8.3.2-pre | corrected |
|---|---|---|---|---|
| Group A — Claude AUD-R83-1 A1 seq1: Pause → Start → Close → Resume → Leave → Again → restart ×2: never credited | FAIL | FAIL | PASS | PASS |
| Group A — Claude AUD-R83-1 A2 seq2: Pause → Start → Resume → Close → Leave → Again → restart ×2: never credited | FAIL | FAIL | PASS | PASS |
| Group A — Claude AUD-R83-1 A4 left Plan started again: Pause → Start → Close → Resume → Leave → StartPlan → restart ×2: never credited | FAIL | FAIL | PASS | PASS |
| Group A — Claude AUD-R83-1 A5 I1-style Go through again: Pause → Start → Close → Resume → Leave → AgainByInsight → restart ×2: never credited | FAIL | FAIL | PASS | PASS |
| Group A — Claude AUD-R83-1 A6 later lifecycle changes: Pause → Start → Close → Resume → Leave → Again → Pause → Resume → Leave → Again → restart ×2: never credited | FAIL | FAIL | PASS | PASS |
| Group A — Claude AUD-R83-1 A3 seq1 then the next day's catch-up: never credited | FAIL | FAIL | PASS | PASS |
| Group A — Claude AUD-R83-1 A7 Premium lapse verified at Start, then resubscribed: never credited | FAIL | FAIL | PASS | PASS |
| Group A — Claude AUD-R83-1 A-ctl1 control: Start → Close → Leave → Again (valid Start): credited once, on the first cycle | PASS | PASS | PASS | PASS |
| Group A — Claude AUD-R83-1 A-ctl2 control: Start → Close requested → Leave while the Close is saving → Again: credited once, on the left cycle | PASS | PASS | PASS | PASS |
| Group A — Claude AUD-R83-1 A-ctl3 control: Pause → Start → Close → Resume → Leave, no new cycle: never credited | FAIL | PASS | PASS | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 B1 (N01-A) the paused-Start prerequisite lands and the process stops before the Start: a later valid active Start is credited once | N/A | FAIL | PASS | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 B2 (AUD-R83-3) the prerequisite lands, the Start's own day-keys save fails: after a restart, a later valid active Start is credited once | PASS | FAIL | PASS | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 B3 control: the prerequisite lands but its answer is lost (the Start is refused): a later valid active Start is credited once | N/A | PASS | PASS | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 B4 (N01-B) a pending paused Start is cancelled by a same-day rebuild; its prerequisite then lands: a later valid active Start is credited once | N/A | FAIL | PASS | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 B-tie an abandoned prerequisite, then a later active Start at the very same instant (the harness clock stands still): the abandoned record is superseded first — credited once | N/A | FAIL | PASS | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 B7 an abandoned prerequisite whose removal the store refuses: that Start is refused, the record stays; the next tap removes it and starts — credited once | N/A | FAIL | PASS | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 B5 (N01-C) Resume tapped while the paused Start's prerequisite is being written, which lands: that Start is cancelled; a fresh Start on the active Plan is credited once | N/A | FAIL | FAIL | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 B6 control: an abandoned prerequisite, then a genuine paused Start on the still-paused Plan, Close, Resume: never credited | N/A | PASS | PASS | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 B-ctl Pause → Start → Close → Resume → restart ×2: never credited | FAIL | PASS | PASS | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 B-ctl Start → Pause → Close → restart ×2: credited once | PASS | PASS | PASS | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 B-ctl Start → Pause → Resume → Close → restart ×2: credited once | PASS | PASS | PASS | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 S1 (Astra single-slot concern) two Circles started while paused on consecutive days, the Plan carried on between, restarts and catch-ups: neither credited | FAIL | PASS | PASS | PASS |
| Group B — Astra R83-N01 / Claude AUD-R83-3 B-ctl Delete while the paused-Start prerequisite is being written: no paused-Start fact survives; nothing credited | N/A | PASS | PASS | PASS |
| Group C — Astra R83-N02 / Claude AUD-R83-2 C1 (N02) Astra — first prerequisite refused | N/A | FAIL | PASS | PASS |
| Group C — Astra R83-N02 / Claude AUD-R83-2 C1b (N02) Astra — first prerequisite lands | N/A | FAIL | PASS | PASS |
| Group C — Astra R83-N02 / Claude AUD-R83-2 C1c (N02) Astra — first prerequisite lands, answer lost | N/A | FAIL | PASS | PASS |
| Group C — Astra R83-N02 / Claude AUD-R83-2 C2 (AUD-R83-2) Resume refused by the store while Start is tapped: Close, Resume, restarts — never credited | FAIL | FAIL | PASS | PASS |
| Group C — Astra R83-N02 / Claude AUD-R83-2 C2b control (AUD-R83-2) the held Resume lands: the Start is on an active Plan — credited once | PASS | PASS | PASS | PASS |
| Group C — Astra R83-N02 / Claude AUD-R83-2 C2c (AUD-R83-2) the held Resume lands but its answer is lost (reported refused): Close, Resume, restarts — never credited | FAIL | FAIL | PASS | PASS |
| Group C — Astra R83-N02 / Claude AUD-R83-2 C3 a Pause that lands and a Resume the store refuses, both pending at the Start tap: never credited | FAIL | FAIL | PASS | PASS |
| Group C — Astra R83-N02 / Claude AUD-R83-2 C4 control: nothing pending, the Plan active — the Start is valid at once (decision B fast path) and credited once | PASS | PASS | PASS | PASS |
| D1 (R83-N03) I2 applied, mark refused; gentler off by hand and the Plan paused; I1 carries the Plan on seven days later; the original I2 retried: gentler is never turned on again | FAIL | FAIL | PASS | PASS |
| D-ctl1 control: I2 never applied; I1 carries the Plan on later; I2 applied then: gentler turned on, I2 marked that day | PASS | PASS | PASS | PASS |
| D-ctl2 control: I2 applied, mark refused, no other Insight: the retry records the mark with the original date and changes nothing | FAIL | PASS | PASS | PASS |
| D-ctl3 (R83-N03) the displaced Insight's mark is refused: the later Insight changes nothing, the earlier provenance stays, and both resolve once the store accepts | FAIL | FAIL | PASS | PASS |
| Claude H1 — I3 around Delete's final Preferences pass H1 apply-then-delete: no Insight id survives a Delete reported done | PASS | PASS | PASS | PASS |
| Claude H1 — I3 around Delete's final Preferences pass H1 apply-then-delete, Preferences write held: no Insight id survives a Delete reported done | PASS | PASS | PASS | PASS |
| Claude H1 — I3 around Delete's final Preferences pass H1 delete-then-apply: no Insight id survives a Delete reported done | PASS | PASS | PASS | PASS |
| Claude H1 — I3 around Delete's final Preferences pass H1 delete-then-apply, Preferences write held: no Insight id survives a Delete reported done | PASS | PASS | PASS | PASS |
| O1 (Astra §7 observation) a value that names no day, or no instant, makes the Plan unreadable — kept as stored, never read as an exclusion that matches nothing | FAIL | FAIL | PASS | PASS |
| O2 the record round-trips with its instant and any field this build doesn't know; an R8.3.1 record (the day alone) is read and written back as stored | PASS | FAIL | PASS | PASS |
| O3 an R8.3.1 record still excludes every Start of its Circle; a record with an instant excludes only that Start | FAIL | FAIL | PASS | PASS |
| Insights R832-B1 — I3 retried after Put back B1-1 founder sequence: applied, Preferences confirmed, mark refused, Put back, retried: the part stays available, no action repeated, no application date | FAIL | FAIL | FAIL | PASS |
| Insights R832-B1 — I3 retried after Put back B1-2 repeated retries and restarts change nothing | FAIL | FAIL | FAIL | PASS |
| Insights R832-B1 — I3 retried after Put back B1-3 the Preferences write is refused (returns false): nothing was done, so a later retry applies it once | PASS | PASS | PASS | PASS |
| Insights R832-B1 — I3 retried after Put back B1-4 the Preferences write lands but its answer is lost: the outcome is uncertain — no replay, no application claimed | FAIL | FAIL | FAIL | PASS |
| Insights R832-B1 — I3 retried after Put back B1-5 the app stops right after the attempt is recorded, before the change: no replay after the restart | N/A | N/A | N/A | PASS |
| Insights R832-B1 — I3 retried after Put back B1-6 the app stops after the change lands, before the mark: after a restart the mark is recorded with the original date, the change is not made twice | PASS | PASS | PASS | PASS |
| Insights R832-B1 — I3 retried after Put back B1-ctl I3 applied normally: left out once, marked that day | PASS | PASS | PASS | PASS |
| Insights R832-B1 — I3 retried after Put back B1-ctl2 the attempt record itself is refused: no change is made | FAIL | FAIL | FAIL | PASS |
| Insights R832-B2 — I4 retried after the kept Circle was removed B2-1 founder sequence: kept, Kept Circles confirmed, mark refused, the user removes it, retried: it stays removed, no application date | FAIL | FAIL | FAIL | PASS |
| Insights R832-B2 — I4 retried after the kept Circle was removed B2-2 repeated retries and restarts recreate nothing | FAIL | FAIL | FAIL | PASS |
| Insights R832-B2 — I4 retried after the kept Circle was removed B2-3 a Keep the user made independently is never attributed to I4 | FAIL | FAIL | FAIL | PASS |
| Insights R832-B2 — I4 retried after the kept Circle was removed B2-4 at the kept limit nothing is kept and nothing recorded; once a place is free, I4 keeps once | PASS | PASS | PASS | PASS |
| Insights R832-B2 — I4 retried after the kept Circle was removed B2-5 the Kept Circles write is refused (returns false): nothing was kept, so a later retry keeps it once | PASS | PASS | PASS | PASS |
| Insights R832-B2 — I4 retried after the kept Circle was removed B2-6 the Kept Circles write lands but its answer is lost: uncertain — never kept again, never claimed | PASS | PASS | PASS | PASS |
| Insights R832-B2 — I4 retried after the kept Circle was removed B2-7 the app stops after the Keep lands, before the mark: after a restart the mark is recorded with the original date; one kept Circle | FAIL | FAIL | FAIL | PASS |
| Insights R832-B2 — I4 retried after the kept Circle was removed B2-ctl I4 applied normally, also without Premium: kept once, marked that day | PASS | PASS | PASS | PASS |
| Insights The attempt record R1 it survives reassessment, a rebuild, another snapshot's change and restarts | N/A | N/A | N/A | PASS |
| Insights The attempt record R2 a damaged record makes the snapshot unreadable — kept as stored; a field this build doesn't know is kept | N/A | N/A | N/A | PASS |
| Insights The attempt record R3 Delete Circle history removes it with the snapshots; the user's choices stay | PASS | PASS | PASS | PASS |
| Insights Controls — I1 and I2 unchanged I1 applied: the Plan is started, marked that day | PASS | PASS | PASS | PASS |
| Insights Controls — I1 and I2 unchanged I2 applied: the cycle is gentler, marked that day | PASS | PASS | PASS | PASS |
| N01-C — founder temporal policy N1 Paused → Start pending → Resume confirmed → the prerequisite resolves: the Start is cancelled; a fresh Start on the active Plan is credited once | FAIL | FAIL | FAIL | PASS |
| N01-C — founder temporal policy N2 Active → Start pending → Pause confirmed → the prerequisite resolves: the Start is cancelled; a fresh Start on the paused Plan is never credited | FAIL | FAIL | FAIL | PASS |
| N01-C — founder temporal policy N3 the Pause is refused by the store: the Plan stayed active, so the pending Start goes ahead and is credited once | PASS | PASS | PASS | PASS |
| N01-C — founder temporal policy N4 the Resume is refused by the store: the Plan stayed paused, so the pending Start goes ahead without credit | FAIL | PASS | PASS | PASS |
| N01-C — founder temporal policy N5 the paused-Start record is refused: the Start is refused; the next tap starts without credit | FAIL | PASS | PASS | PASS |
| N01-C — founder temporal policy N6 repeated taps during a pending Start, and after its cancellation, start the Circle once | PASS | PASS | PASS | PASS |
| N01-C — founder temporal policy N7 a restart after the cancellation: nothing was started, no paused-Start record; a fresh Start is credited once | N/A | N/A | N/A | PASS |
| N01-C — founder temporal policy N8 Resume tapped while the paused Start's own record is being written: the Start is cancelled once the Resume is confirmed; the record left excludes nothing; a fresh Start is credited once | N/A | FAIL | FAIL | PASS |
| N01-C — founder temporal policy N-ctl Start → Pause → Close (a valid Start before the Pause) is credited once, also after restarts | PASS | PASS | PASS | PASS |
