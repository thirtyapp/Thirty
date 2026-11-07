# L-1: an unreadable Suggestion Preferences record and Delete

**Verdict: a verified, unresolved deviation from the Delete/Export contract. Classified as a RELEASE BLOCKER pending a founder decision.** Not changed in R8.3.1: it is outside the authorised scope, and no correction has been approved.

## What was tested

`r831_probe_l1_test.dart.txt` was run on the R8.3.1 tree, from a scratch copy, so it is not part of the regression suite. It covers three kinds of record that THIRTY can't read as a whole, each holding an Insight id in a left-out part:

- one with a newer schema version;
- one whose list field isn't a list;
- one that isn't JSON.

The raw log is `../passing_after/probes_L1_and_D2_on_R8_3_1.jsonl`; the printed results are in `L1_PROBE_OUTPUT.txt`.

| Question | Answer (every case) |
|---|---|
| Can History-derived attribution remain in such a record? | **Yes.** The bytes, the attribution included, are unchanged after a Delete that reports success (the marker is removed) |
| Is it applied? | **No.** The preferences read as empty, so nothing left out is applied. Recommendations, stage 5 and Insights are not influenced |
| Can Delete remove it safely? | **No, not in general.** The record's format is by definition unknown to this build. Editing it, even removing one key, would guess at a newer schema's meaning and could destroy explicit preferences or future fields. Writing it over is forbidden (R8.1 RL-3) |
| Does the current behaviour satisfy the contract? | **Partly.** It satisfies "No residue from deleted journal evidence may keep influencing recommendations, Plan stage 5 or Insights". It does **not** satisfy founder decision D1 ("Delete must not report success while relevant history-derived attribution remains durable"). Nor does it satisfy the Export clause ("Export includes … explicit corrections and preferences"), because Export doesn't carry the record |
| Is there a recovery or export path? | **Only Reset** (What THIRTY remembers), the user's own destructive erasure. There is no export, unlike unreadable kept Circles, which Export carries as stored |

## How it can arise

None of THIRTY's own writes produces such a record. Every write is schema version 1, with list fields.

It arises only from:
- a record written by a newer THIRTY, then opened by this one (a downgrade or restore);
- damage to the store from outside the app.

There is no newer schema today. So the state can't be produced by any build that exists, but it is reachable by restoring or damaging data.

## Minimal options for the founder (none implemented)

1. **Truthful Delete.** When the preferences record is unreadable, Delete finishes everything else and then tells the user that their suggestion preferences couldn't be checked and that Reset clears them. The Delete wouldn't be announced as fully done. This needs new copy.
2. **Export as stored.** Export carries an unreadable preferences record exactly as stored, as it already does for kept Circles. This closes the Export clause, but not D1.
3. **Both 1 and 2** (recommended): the smallest change that satisfies both clauses without touching the user's data.
4. **Accept.** Disclose it as a limitation that holds until any preferences schema change ships; that change would then have to define downgrade behaviour.
