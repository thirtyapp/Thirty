# R83-F1 — a Circle closed while its Plan was paused is credited later

**Status:** OPEN. This needs a founder decision. Found while verifying founder decision D2; **not changed by R8.3**.

## What happens

Founder decision D2 (approved 2026-11-06) says a Pause before a valid, durably confirmed Start earns no Plan credit. At the Close itself, that holds on R8.2 and on R8.3. The credit arrives later, once the Plan is active again.

| Probe (`repro_before_fix/r83_probe_d2_later_credit_test.dart.txt`) | Credits at Close | Credits afterwards | R8.2 | R8.3 |
|---|---|---|---|---|
| P1: Start pending, Pause, Close, then Resume, then restart | 0 | **1** | same | same |
| P2: no pending write. Pause, Start, Close, then Resume, then restart | 0 | **1** | same | same |
| P3: Start pending, Pause, Close, then Resume, then Pause again (no restart) | 0 | **1** | same | same |
| P4: Pause, Start, Resume, then Close (the Plan is active at Close) | 1 | 1 | same | same |
| P5: Start pending, Pause, Close, then restart (the Plan stays paused) | 0 | 0 | same | same |

Raw logs:
- `repro_before_fix/probe_d2_on_r82.jsonl`;
- `passing_after/probe_d2_on_R8_3_tree.jsonl`.

P2 shows the behaviour is **pre-existing and not specific to a pending Start**.

## Why

`recordGuided` (`circle_plan.dart`) decides eligibility from the Plan's lifecycle at the moment it runs. Two later paths run it again once a Resume has made the Plan active:
- the restart catch-up of a closed Circle (Today `_mirrorInJournal`);
- the decision-A fold (`_withEarnedCredits`, run by the next lifecycle change).

The served record holds no fact saying "this Circle was closed while its Plan was paused, with no Start before the Pause". So the later run treats it as an active Plan's Circle.

## Why R8.3 did not fix it

Directive §10 says to stop for founder review when a correction affects historical credit semantics beyond the accepted contract. Here a fix needs both:

1. **A new persisted fact.** For example, a stamp on the served record, written by the Pause (or by the Close while paused), that `recordGuided` honours later. This adds a field to the Plans record.
2. **A policy answer for P4.** With Pause, then Start, then Resume, then Close, the Plan is active at Close, and today that Circle is credited. The literal D2 wording ("a Pause before a valid Start earns no credit") would refuse it. The lifecycle policy ("an active Plan's current cycle is credited") grants it.

## Options for the founder

| Option | P1–P3 | P4 | Change |
|---|---|---|---|
| **A.** No credit for a Circle *closed* while its Plan was paused without an earlier Start | none | credited (as now) | Pause/Close stamp a "closed while paused" fact; `recordGuided` refuses it later. Small; new optional field |
| **B.** No credit for a Circle *started* while its Plan was paused | none | **none** | Stamp at Start when the Plan is paused. Stricter; changes P4 |
| **C.** Keep the current behaviour and document it as accepted | credited later | credited | Documentation only |

The recommendation is **A**. It matches D2 at the moment that matters (the Close) and leaves P4, a Plan the user deliberately carried on before closing, as it is today.

The impact is a Plan stage credited that the rule says earns none. It does not grant Premium access, it loses no data, and the trigger is rare (Pause before Start, then Close, then carry on).
