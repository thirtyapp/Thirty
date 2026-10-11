# ADR-023 — V2 Recurring Premium / Personal Guided Circle

**Status:** Proposed — Phase D2 implementation in progress (2026-10-11). Becomes Accepted only with the Phase D2 gates in [THIRTY_V2_DELIVERY_TRACKER.md](../THIRTY_V2_DELIVERY_TRACKER.md).

Product authority: [PRODUCT_V2_CONTRACT.md](../PRODUCT_V2_CONTRACT.md), as amended on 2026-10-11 ("Amendment — Recurring Premium (Phase D2)"). This ADR **supersedes the conflicting Premium portions of [ADR-022](ADR-022-v2-phase-d-paths-toolkit-and-maintenance.md)**: Premium's headline job, what Today does for a Premium user, the offer page, and the defects listed below. ADR-022 stays the historical record of Phase D as built and accepted on 2026-10-10. Free V2 stays governed by the contract and ADR-020/021.

## Context

The post-V2 audits at d89a035 (`docs/audits/`) judged Phase D's Premium a weak fit for monthly recurring revenue. It sells a durable routine at a service price: the rational pattern is to subscribe, build two or three routines, keep them (as designed), and cancel. The founder decided (2026-10-11):

- THIRTY must be able to support legitimate **monthly** recurring revenue. Lifetime or one-time Premium is not the target.
- The recurring job becomes the **Personal Guided Circle**: *"THIRTY turns the time I have today into a personal guided Circle built from what has worked for me, then guides me through it."*
- Build the strongest bounded version now. Validate the complete product with Google Play pre-release users after Phase E. No external validation round before implementation; product–market fit stays unproven and is labelled so.

## Decisions

*(Sections marked ◇ are filled in as each D2 step lands; the final text is the one accepted.)*

1. **Two jobs, one Circle a day.**
   - **Free:** chooses **one** good activity for today's need and time (Engine V2, unchanged in capability).
   - **Premium:** **creates and guides one coherent personal session** for today's need and time, made of a few small authored elements. The output is perishable: today's session is consumed today, and tomorrow THIRTY does the work again. That daily work is why a monthly charge can be legitimate.
   - Still one primary Circle per local day. The user still states only **need** and **time**: no questionnaire, mood log, planner or dashboard.

2. ◇ **Element model** — see §2 in the final text.
3. ◇ **Composer and quality gate.**
4. ◇ **Today precedence and fallback.**
5. ◇ **Guided composed runtime.**
6. ◇ **Spoken guidance.**
7. ◇ **Element controls and evidence boundaries.**
8. ◇ **Ownership: Use it today, kept Circles, lapse.**
9. ◇ **Paths, Toolkit and maintenance repositioned.**
10. ◇ **Truth fixes carried from the audits.**
11. ◇ **Offer and billing boundary.**
12. ◇ **QA, long-horizon simulations, content review.**

## Consequences

- Phase D's history, data and Path/Toolkit behaviour are preserved; nothing the user built is migrated away.
- Phase E stays on hold until Phase D2 passes.
