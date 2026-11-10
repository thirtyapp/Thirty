# R8.3.3 — founder decisions (10 November 2026)

The founder reviewed the R8.3.3 closure result (`README.md`) and accepted its three proposed behavioral dispositions. The founder also conditionally authorized exactly one auditable commit and one normal fast-forward push, subject to the commit gates in `commit_verification/`.

**This is not independent engineering-baseline acceptance, and not a commercial-release authorization.**

## A. Legacy duplicate kept ids — preserve, do not auto-repair (APPROVED)

The founder's rationale: the only build known to be able to create these duplicates (`d4cf8c44`) was never released commercially.

**Required behavior, all implemented in R8.3.3:**

- Legacy duplicates are kept exactly as stored. They are never re-identified, merged or deleted automatically.
- Rename and Remove leave every record unchanged when an id is ambiguous (`addressedBy(id) > 1`, test A02-E).
- New records are unique at the storage layer: `newKeptId`, plus the refusal in `keepCircle(id:)` (A02-C, A02-D, ID-1, ID-3).
- An I4 receipt is proven only by the exact kept id **and** the source Circle (A02-B, A02-B2, ID-2).
- Unreadable and future-schema kept records stay protected and are unchanged. A retained record's key counts as taken (ID-3).

**Not authorized:** any migration of legacy duplicate ids.

**Limitation recorded for pre-release review.** Internal or QA builds of `d4cf8c44`, including the founder's own devices, could hold affected records if I4 was applied twice on one cached day. Such records show the shared id twice, and Rename or Remove on them does nothing.

No evidence was found that released or real user-owned records are affected. If such evidence appears, a separate policy decision is required.

## B. I3/I4 versus Delete — Delete takes priority (APPROVED)

When Delete begins before a pending I3 or I4 application has queued its target change, that stale application never executes. It returns `notAvailable` (A01-x1, A01-x2).

**Guarantees:**

1. No historical Insight action continues from a pre-Delete snapshot after the deletion boundary. The barrier is the Insight deletion generation, checked immediately before every mutation (`CONTRACTS_R833.md` §1).
2. No deleted attribution is restored. Delete's final Plans pass is only a defence in depth.
3. No abandoned attempt receipt survives a successful Delete. The receipt write is either queued before the boundary, and removed by Delete's Insights pass, or never queued.
4. A target change queued before the boundary lands before Delete's own pass in that store. It is then kept under the established user-owned rules: a left-out part loses its attribution, and a kept Circle stays.
5. A fresh explicit action after Delete completes works normally (A01-v10).
6. Delete still reports success only once its durable operations are confirmed.

## C. A pending Start and its exact Plan write — cancel on refusal or uncertainty (APPROVED)

1. A pending Start is bound to the exact prerequisite save it was tapped on (`PlanStartConditions.pendingSave`).
2. A confirmed write of that same save may authorize the Start, if every other condition still holds (X-ctl, G6).
3. If that save is refused or uncertain, the Start is cancelled. A separately confirmed later save never substitutes for it (X1, X2, X3).
4. A cancelled Start leaves nothing behind: no session, no historical credit, no eligibility marker.
5. A later fresh Start follows the Plan lifecycle as confirmed at that time.
6. The N01-C and G1 ABA behaviors are preserved: G1 22/22, founder-scope N1–N8.

The conservative extra tap is explicitly accepted.

## Unchanged

- **L-1: OPEN — PRE-RELEASE BLOCKER — NOT FIXED — NOT WAIVED.**
- RL-4, the real-device recovery limits and the accessibility (S25/TalkBack) limits are as disclosed.
- No Premium, billing or R8.4 work.
- **Phase E: HOLD.**
