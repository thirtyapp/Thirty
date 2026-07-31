# THIRTY Playbook — Governance

This document governs how the Playbook itself is maintained, versioned, and extended. It contains no product or brand philosophy — for that, see [Chapters 1–4](README.md#reading-order). It exists so the Playbook can remain a single source of truth for many years without drifting, being silently rewritten, or being expanded without discipline.

## Ownership

One named owner — the **Playbook Editor** (the founder, initially) — is the sole approver of any change to an already-Approved chapter. Anyone (designer, engineer, product manager, or an AI agent) may draft a new chapter, propose a correction, or flag an inconsistency; only the Playbook Editor can move a draft to Approved or authorize an amendment to existing content.

## Versioning strategy

The Playbook is versioned as a whole (all chapters + this governance model + the README), not as independent files.

- **Major (v2.0, v3.0, …):** a change to a load-bearing claim in an already-Approved chapter — for example, altering "the Circle is the product," "no streaks, ever," or "Premium never gates." A major version requires the full approval workflow below, because every later chapter and every ADR built on top of the changed claim must be re-checked against it.
- **Minor (v1.1, v1.2, …):** a new chapter that extends the Playbook into a domain it did not previously govern (for example, AI behavior, growth, or community), without altering any existing chapter's meaning.
- **Patch (v1.0.1, v1.0.2, …):** a correction that doesn't change meaning — a citation fix, a terminology reconciliation, a broken link repair.

## Approval workflow

1. A chapter or amendment is drafted (**Draft**).
2. It is reviewed against the existing Playbook for consistency, duplication, and terminology (**Reviewed**) — the same kind of pass performed in `editorial-review-v1.md`.
3. The Playbook Editor approves it (**Approved**) or sends it back to Draft with specific reasons.
4. Once Approved, a chapter is never silently edited. A later correction is applied as an explicit, dated patch (for wording/citation/terminology fixes) or a named amendment (for anything that touches meaning) — never a quiet diff with no trace that something changed.

## Event-triggered review

The Playbook is not reviewed on a calendar. A philosophy document reviewed on a fixed schedule invites revision for its own sake — exactly the trend-chasing the Playbook itself warns against (Chapter 4 §8). Review is triggered instead by:

- a new chapter being proposed;
- an ADR that appears to strain against something an existing chapter already says;
- a lightweight **annual integrity check** — not a rewrite session, a single standing question asked once a year: does the live product still match what the Playbook says it should feel like?

## Relationship between ADRs and the Playbook

An ADR is the right instrument for a decision made **within** the boundaries the Playbook already sets — a specific implementation choice, or a specific signal's priority inside the recommendation engine. ADRs are checked against the Playbook, not the reverse.

The Playbook itself must change, via the approval workflow above, only when a proposed decision would require **contradicting** a standing chapter. At that point an ADR is the wrong tool.

Where an ADR's principle is broad enough to generalize beyond its original, narrow scope, it may be **elevated**: the ADR is left `Accepted` (its original, scoped decision still stands and is not superseded), and both documents cross-reference each other — the elevating Playbook chapter names the ADR explicitly, and the ADR carries a one-line forward reference to the chapter that elevated it. This has already been done for ADR-001, ADR-002, ADR-003, ADR-004, ADR-005, ADR-007, and ADR-008, each pointing to the relevant filter in Chapter 4.

## Criteria for modifying an existing chapter

A change to an Approved chapter is in scope only if it is one of:

- a **citation or cross-reference fix** (pointing to the correct existing source);
- a **terminology reconciliation** (removing a conflict between two chapters' names for the same concept, without changing what either chapter means);
- a **deliberate, explicit amendment** to a load-bearing claim, carried out with the same care as freezing a new chapter (full approval workflow, major version bump).

A change is out of scope if it introduces new philosophy, new principles, new terminology, new sections, or a stylistic rewrite without a corresponding consistency problem to fix. "Improving the writing" is never sufficient justification on its own to touch an Approved chapter.

## Criteria for creating a new chapter

A new chapter is warranted only when a genuinely new domain needs governing — not because more detail could be added to an existing one. Candidate domains are already named in the Playbook itself (Chapter 1's closing note: AI behavior, growth, community). A new chapter must:

- state explicitly which existing chapters it builds on, and not restate their content;
- avoid re-deciding anything an existing chapter has already settled;
- pass the same "does this strengthen the Circle" test Chapter 4 applies to every other product decision — a new chapter is, in this sense, a feature being added to the company's own operating system, and is held to the same bar.

---

*This is the governance model for the THIRTY Playbook, current as of v1.0. It is itself subject to the amendment discipline it describes.*
