# R8.3 / R8.3.1 founder decisions (record)

## 2026-11-06: architecture acceptance and implementation authorization

**Option B approved:** bounded integrity hardening. No database replacement, migration or rewrite.

| ID | Decision |
|---|---|
| **D1** | When Delete Circle history succeeds, the Insight attribution (`ElementLeftOut.byInsight`) is removed from retained preferences. The user's Leave-it-out preference, its element identity and its other metadata are kept. Preferences, kept Circles and Plan places are not reset. Coordinated with the deletion intent and the preference queue. |
| **D2** | A Pause before a valid, durably confirmed Start earns no Plan credit. Decision B's Start prerequisites are kept. No retrospective credit from the time of the Start tap. |
| **D3** | A retry of an Insight whose own action already landed repairs the applied mark from the exact provenance, dated with the original application date. It never repeats the action. A later manual change is authoritative. |
| **D4** | AUD-N3 is in scope: Delete uses the last confirmed durable Plans, never an unconfirmed optimistic change. |
| **D5** | Typed native getters with demonstrated start-up or initialization risk are fixed (the V1 retirement marker and the other start-up sites). Values are inspected before casting; unexpected stored values are never overwritten by a default. |

## 2026-11-07: R8.3 result reviewed; R8.3.1 authorized

**R83-F1: Option B.** Historical Plan credit depends on the eligibility of the Circle's original valid Start, combined with the durable Close and entitlement requirements. A later lifecycle change never makes an ineligible Start eligible.

| Action order | Result |
|---|---|
| Start → Close | credit |
| Start → Pause → Close | credit, original cycle, once |
| Start → Pause → Resume → Close | credit, once |
| Pause → Start → Close | no Plan credit |
| Pause → Start → Resume → Close | no Plan credit |
| Pause → Start → Close → Resume | no Plan credit, including a delayed fold |
| Pause → Start → Close → later Pause | no Plan credit |
| Start → Leave → Close | no credit |
| Start → Close requested → Leave while saving | credit, original cycle, once, after the Close is durable |
| Close never durable | no credit |
| Start alone | no credit |

A Circle without Plan credit keeps its valid History record. The Premium entitlement rules are unchanged.

## 2026-11-07: commit authorization

The R8.3 and R8.3.1 implementation results are accepted for the approved remediation scope. One auditable commit and a normal fast-forward push are authorized.

This is not independent audit approval and not commercial-release authorization. Phase E remains HOLD.

## L-1: DEFERRED, OPEN — PRE-RELEASE BLOCKER

L-1 is **not fixed, not waived and not authorized for implementation** in R8.3. This is a deliberate scope deferral, not acceptance of the behaviour.

**The behaviour:**
- A Suggestion Preferences record that THIRTY can't read as a whole (a newer schema, a malformed list field, or not JSON) survives Delete Circle history with any Insight attribution inside it. The Delete is reported as successful.
- Export does not include such a record.
- The record is not applied to recommendations, Plan stage 5 or Insights.
- Deleting or rewriting it automatically could destroy explicit, user-owned preferences, or a newer schema's fields.

**Release condition:** no commercial release until a safe Delete/Export disposition is implemented and verified.

**Evidence:**
- `../r8_3_1_founder_lifecycle_correction_2026-11-07/l1_assessment/L1_ASSESSMENT.md` (options 1–4);
- its probe and raw log.

The independent auditors are informed of L-1 and assess its impact on technical-baseline acceptance themselves. They are not asked to waive it.
