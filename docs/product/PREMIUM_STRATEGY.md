# THIRTY Premium Strategy

**Version:** v1.0
**Status:** Approved v1.0

## Purpose

This document defines the **commercial strategy** behind THIRTY's Premium tier: what Premium is *for*, in what priority order it should be built and sold, and the boundary test every future Premium idea must pass.

It makes the commercial value of Premium explicit. It does not change what has already been decided:

> **Premium deepens rather than gates.**

This principle is not open for renegotiation here — it is the settled outcome of Playbook [Chapter 1 §9](../playbook/01-the-circle-manifesto.md#9-premium-as-a-deeper-experience), [Chapter 2 §9](../playbook/02-circle-experience-system.md#9-premium-experience), [Chapter 3 §12](../playbook/03-circle-design-language.md#12-premium-design), [Chapter 4 §5](../playbook/04-product-decision-framework.md#5-the-premium-filter), and [ADR-007](adr/ADR-007-premium-never-blocks-the-core-loop.md). This document exists one level below that principle: it explains what "deepens" should commercially *mean* — why a subscriber pays, and what they are actually paying for — without touching the principle itself.

---

## A note on authority

This document does not sit above the Playbook, [VISION.md](../VISION.md), or [WORLD_SYSTEM.md](../worlds/WORLD_SYSTEM.md). It is checked against all three, not the reverse.

- **Relative to the Playbook.** Chapters 1–4 remain authoritative for *whether* a Premium idea is philosophically acceptable (the Premium Filter, Chapter 4 §5) — including what each named Premium concept (Circle Plans, Circle Sessions, Circle Coach, Circle Insights, Premium Atmosphere) already means. This document is authoritative for *why it is commercially worth building and paying for*, and for the relative priority between those concepts — a narrower, product-strategy question the Playbook deliberately does not answer at its own altitude. Nothing here may contradict Chapters 1–4, and nothing here redefines a term the Playbook already owns.
- **Relative to the free/Premium boundary.** [ADR-007](adr/ADR-007-premium-never-blocks-the-core-loop.md) is the decision of record for what remains unconditionally free. §1 below states that approved boundary for product reference; ADR-007 remains the authoritative record, and is updated alongside this document rather than duplicated by it.
- **Relative to World System.** [WORLD_SYSTEM.md §12](../worlds/WORLD_SYSTEM.md#12-free-and-premium) already governs Premium Atmosphere's relationship to a World (what it may deepen, what it must never own). This document's §7 restates none of that — it adds the commercial-priority context: *where* Premium Atmosphere sits relative to the other three Premium pillars, and why it is not the primary reason someone subscribes.
- **Relative to future pricing decisions.** This document deliberately sets no price, no packaging (monthly/annual), no trial length, and no paywall timing. Those remain future business decisions, to be checked against this document's priority order (§3) and boundary test (§10), not derived from them automatically.
- **Relative to future Coach safety decisions.** §5 defines Circle Coach's *product* boundaries — what it may and must not do, in principle. The technical safety framework, moderation approach, and AI provider are separate, future, and unresolved — see Non-Goals.
- **Relative to implementation ADRs.** Any future technical decision made while building Plans, Sessions, Coach, Insights, or Atmosphere is the right subject for a new ADR, checked against this document. This document is not itself an ADR — it is the strategy ADRs about Premium features should be checked against.

**Terminology.** *Circle Plan* and *Circle Session* are used throughout this document exactly as Playbook [Chapter 2 §9](../playbook/02-circle-experience-system.md#9-premium-experience) already defines them: a **Circle Plan** is the guided multi-day path; a **Circle Session** is a single guided or paced Circle experience, belonging to one moment or day, which may stand alone or serve as one step inside a Plan. An earlier draft of this document used "Circle Sessions" for the multi-day concept — that has been corrected throughout, so this document no longer diverges from Chapter 2 §9 anywhere.

Where this document is silent, the Playbook, VISION.md, and WORLD_SYSTEM.md govern.

## Table of contents

1. [Free Product Promise](#1-free-product-promise)
2. [Premium Product Promise](#2-premium-product-promise)
3. [Premium Priority Order](#3-premium-priority-order)
4. [Circle Plans](#4-circle-plans)
   - [Circle Sessions Within a Plan](#circle-sessions-within-a-plan)
5. [Circle Coach](#5-circle-coach)
6. [Circle Insights](#6-circle-insights)
7. [Premium Atmosphere](#7-premium-atmosphere)
8. [Personal Growth and Premium](#8-personal-growth-and-premium)
9. [Commercial Value Hierarchy](#9-commercial-value-hierarchy)
10. [Premium Boundary Test](#10-premium-boundary-test)
11. [Positioning Statement](#11-positioning-statement)

---

## Core Product Decision

Free helps someone complete one meaningful Circle today. Premium turns daily Circles into a personal path across multiple days.

That is the commercial shape "Premium deepens rather than gates" takes. It follows directly: Premium must provide meaningful **guidance, continuity, adaptation, and understanding** — the things that make a *path* different from a *day*. It must not be positioned primarily as:

- prettier Worlds;
- extra animation;
- decorative atmosphere;
- more statistics;
- a generic AI chat;
- access to THIRTY's core identity.

Every item on that list already fails the Playbook's own Premium Filter ([Chapter 4 §5](../playbook/04-product-decision-framework.md#5-the-premium-filter)) if offered *as the reason to subscribe* — none of them help the user choose, continue, adapt, or understand. They may still exist inside Premium (Atmosphere legitimately does, see §7) — they may simply never be the headline.

---

## 1. Free Product Promise

The free experience must feel **whole**, not deliberately incomplete. This section is the explicit, nameable list [ADR-007](adr/ADR-007-premium-never-blocks-the-core-loop.md) and [Onboarding Principles §3](onboarding-principles.md#3-premium-strategie) both anticipated as a still-open item — with this document's approval, recorded in ADR-007 alongside this pass, that question is resolved.

Free, unconditionally, for every user, forever:

- the core Circle ritual ([Playbook Ch.1](../playbook/01-the-circle-manifesto.md));
- The First Breath, in full ([Playbook Ch.2 §2–§3](../playbook/02-circle-experience-system.md));
- a meaningful daily recommendation, explainable in plain language ([ADR-002](adr/ADR-002-recommendations-must-be-explainable.md));
- starting and completing a Circle;
- the foundational World experience for every supported category ([WORLD_SYSTEM.md §12](../worlds/WORLD_SYSTEM.md#12-free-and-premium): "a complete World for every supported recommendation category");
- normal seasonal expression of that World ([WORLD_SYSTEM.md §9](../worlds/WORLD_SYSTEM.md#9-seasons): "seasonal variation belongs to every user... not a Premium gate");
- permanent Personal Growth ([WORLD_SYSTEM.md §11](../worlds/WORLD_SYSTEM.md#11-personal-growth));
- no streak pressure, no broken-chain iconography ([Playbook Ch.1 §7](../playbook/01-the-circle-manifesto.md#7-why-completion-matters-more-than-streaks));
- no guilt mechanics, no punished absence ([Playbook Ch.1 §8](../playbook/01-the-circle-manifesto.md#8-the-philosophy-of-starting-again));
- a complete and respectful daily experience, with nothing about it designed to feel like a trial.

The Circle, the daily ritual, and a World's basic identity must never become Premium-only. A future feature that would make any item on this list conditional on a subscription fails the Premium Filter before any other test is applied.

---

## 2. Premium Product Promise

**The central Premium promise: turning isolated daily actions into a guided personal path.**

Premium should help the user:

- choose what is appropriate today;
- work toward a meaningful multi-day outcome;
- adapt when time, energy, or circumstances change;
- understand what tends to work for them;
- resume gently after interruptions;
- reduce decision fatigue.

Premium's value comes primarily from **personal usefulness** — not content volume, and not visual decoration. A Premium feature that adds more content or more polish without making a decision easier, a path clearer, or the user better understood has not yet earned its place, however well it is built.

---

## 3. Premium Priority Order

1. **Circle Plans**
2. **Circle Coach**
3. **Circle Insights**
4. **Premium Atmosphere**

This is an order of **commercial and product importance, not necessarily a release schedule.** Technical sequencing, dependencies, and staffing may reasonably build these in a different order — this ranking states which one carries the subscription, not which one ships first.

Circle Plans, Circle Coach, and Circle Insights create practical value: they change what the user decides to do, or how well they understand their own pattern. Circle Sessions remain an important Premium capability — the guided unit a Plan is built from (§4) — but they are not a separate line in this priority order: their value is realised primarily as a component of Circle Plans, not as an independent product pillar. Premium Atmosphere strengthens emotional attachment and retention — it is a real, legitimate Premium benefit — but it is not, and must not become, the primary reason someone subscribes.

---

## 4. Circle Plans

**Circle Plans is the primary Premium product.**

A Plan is a **guided multi-day path toward a clearly stated outcome.** It is not merely:

- a timer;
- a playlist;
- a collection of unrelated activities;
- a static challenge;
- a disguised streak.

Illustrative outcome names — **not approved as a final catalogue**, since none of these currently exist in project documentation, and naming a shipped Plan is a separate future decision:

- More Energy
- Calmer Evenings
- Return to Movement
- Focus Week
- Gentle Sleep Rhythm
- Recovery After a Busy Period

**A strong Plan has:**

- a clear intended outcome;
- a sensible sequence of Circles building toward it;
- daily choices appropriate to the user's available time and energy that day;
- continuity between days — each day recognisably belongs to the one before it;
- gentle adaptation after a missed day, never punishment or lost progress ([Playbook Ch.1 §7–§8](../playbook/01-the-circle-manifesto.md#7-why-completion-matters-more-than-streaks));
- a clear beginning, development, and completion;
- a reason, statable in one sentence, why today's Circle belongs in the wider path.

**Formal distinction:**

> Free answers: *"What could help me today?"*
> A Premium Circle Plan answers: *"Where am I going, and what is the right next step?"*

### Circle Sessions Within a Plan

A Circle Session is a single guided or paced Circle experience — it belongs to one concrete moment or day, not to the multi-day arc. A Session:

- guides one individual Circle;
- may provide pacing, structure, prompts, or transitions;
- may be used independently, where existing product philosophy permits, without belonging to any Plan;
- may serve as one step inside a Circle Plan;
- does not itself imply a multi-day commitment;
- must not become a content playlist or passive media library.

**Formal relationship:**

> A Circle Plan creates the path.
> Circle Sessions guide individual steps within that path.

This is exactly how Playbook [Chapter 2 §9](../playbook/02-circle-experience-system.md#9-premium-experience) already defines Circle Sessions — this section does not introduce a new meaning, it restates the existing one at the priority-order altitude this document operates at.

---

## 5. Circle Coach

Circle Coach is a **contextual decision and guidance layer** — not a generic chatbot. Its value must come from context only THIRTY has, never from being a general-purpose conversational AI wearing THIRTY's name:

- the user's current intention;
- available time;
- stated energy;
- preferences;
- recent Circles;
- current Plan or Session;
- prior reflections;
- time of day;
- explicit constraints;
- activities the user does or does not want.

**The Coach should help with questions such as:**

- "What fits my energy today?"
- "I only have ten minutes; what can I do?"
- "I missed yesterday; how do I continue gently?"
- "Should I move, focus, or recover?"
- "Can today's Circle be made lighter?"

**The Coach should:** recommend, explain, adapt, and help the user resume.

**The Coach must not:**

- diagnose;
- present itself as therapy;
- replace professional medical or mental-health support — consistent with VISION.md's standing position that THIRTY is not a substitute for medical advice;
- pressure the user;
- fabricate certainty;
- turn every interaction into an upsell.

Every one of these boundaries is already implied by the Playbook's [AI Filter](../playbook/04-product-decision-framework.md#6-the-ai-filter) ("does it create understanding, or does it create dependency?", "does it respect the user's autonomy?", "can it be explained in plain language before it is shown?") — this section names the boundary explicitly for Coach specifically, it does not invent a new standard.

The exact technical implementation and safety framework — AI provider, moderation approach, escalation behaviour for concerning input — are separate future decisions, out of scope here (see Non-Goals).

---

## 6. Circle Insights

Circle Insights is an **actionable learning loop**, not a dashboard. It must not be limited to charts, totals, completion counts, raw history, activity rankings, or productivity scoring — all of that is measurement without a next step, which [Chapter 2 §9](../playbook/02-circle-experience-system.md#9-premium-experience) already rejects: *"insight is a mirror, not a report card."*

A useful Insight follows the same two-part pattern every time — an **observation**, paired with an **application**:

> **Observation:** *"You complete shorter outdoor Circles more consistently."*
> **Application:** *"We can keep your next recommendations lighter and outdoors."*

> **Observation:** *"Calm evening Circles are often followed by a more positive reflection."*
> **Application:** *"Would you like to continue that rhythm this week?"*

Insights must not promise conclusions the available data cannot support. They remain:

- observational;
- transparent;
- non-judgmental;
- cautious about causality — a pattern is a pattern, not proof;
- free from streak language;
- free from hidden performance scores.

This is [ADR-008, Learning Without Judgment](adr/ADR-008-learning-without-judgment.md), applied specifically to what a Premium Insight is allowed to say.

**Formal principle:**

> An Insight earns its place when it improves what happens next.

---

## 7. Premium Atmosphere

Premium Atmosphere remains a valid Premium benefit, in a **supporting role.**

It may include future enhancements such as:

- richer ambient World motion;
- subtler weather atmosphere;
- additional light behaviour;
- more nuanced environmental layers;
- deeper Session and Plan transitions;
- expanded sound or atmosphere, only if separately approved.

Every item above must still pass [WORLD_SYSTEM.md §12](../worlds/WORLD_SYSTEM.md#12-free-and-premium) and [Motion Language §12](../motion/MOTION_LANGUAGE.md#12-premium-motion), both already settled: Premium Atmosphere must not replace the free base World, own the World's identity, remove seasons from free users, own Personal Growth, create an intentionally empty free World, or — the addition this document makes explicit — become the primary Premium sales proposition.

**Formal principle:**

> Atmosphere rewards commitment. It does not create the reason to subscribe.

---

## 8. Personal Growth and Premium

Permanent Personal Growth remains available to all users, free and Premium alike — this is already settled by [WORLD_SYSTEM.md §11](../worlds/WORLD_SYSTEM.md#11-personal-growth) and restated here only to make its commercial consequence explicit.

Premium may deepen how growth is:

- interpreted (Circle Insights connecting a growth milestone to a pattern);
- connected to Plans (a Plan referencing progress already made);
- reflected upon;
- explained through Insights;
- enriched atmospherically (Premium Atmosphere rendering an earned milestone more richly).

Premium must never **own or reverse** the visible evidence of someone's accumulated Circles. No user may lose meaningful World growth because a subscription expires — a cancelled subscription returns a user to the free experience, not to a diminished one.

---

## 9. Commercial Value Hierarchy

1. Guidance
2. Personal relevance
3. Continuity and adaptation
4. Understanding
5. Emotional richness and atmosphere

Premium should be marketed **first around outcomes and guidance** — the top of this hierarchy. Visual richness is a supporting benefit, not the lead. Avoid promising guaranteed wellness outcomes at any point in this hierarchy: Premium can promise better guidance, not a guaranteed result — the same restraint [ADR-002](adr/ADR-002-recommendations-must-be-explainable.md) and the AI Filter already require of a single recommendation applies to the subscription's own claims about itself.

---

## 10. Premium Boundary Test

For every proposed Premium feature, ask:

- Does this help the user choose, continue, adapt, or understand?
- Is it meaningfully better because it knows the user's context?
- Does it support a path rather than add isolated content?
- Would someone understand why this is worth paying for?
- Does the free experience remain complete and respectful?
- Are we deepening the product rather than withholding its identity?
- Is this feature useful without relying on pressure, streaks, or guilt?
- Is this primarily practical value, or only decoration?
- Would the feature remain honest if the user cancels?

A Premium idea should not be approved only because it is attractive or technically impressive. This test operates at the same altitude as, and is checked alongside, the Playbook's own [Premium Filter](../playbook/04-product-decision-framework.md#5-the-premium-filter) — it does not replace it; it is that filter's commercial-strategy-specific expression.

---

## 11. Positioning Statement

> Free helps you make one meaningful choice today.
> Premium helps those choices become a path.

The "path" this statement promises is represented primarily by Circle Plans (§4) — Circle Sessions support the individual steps within it, but the claim that a choice "becomes a path" is a Circle Plan's claim to make, not a standalone Session's.

This is an internal positioning statement, not public marketing copy — it is written in THIRTY's existing internal voice (short, declarative, calm) for product and design decisions to be checked against. Turning it into external marketing language is a separate, future, deliberate decision, not an automatic next step.

---

## Non-Goals

This document does not decide:

- final subscription price;
- monthly versus annual packaging;
- trial length;
- paywall timing;
- App Store products;
- entitlement architecture;
- billing provider;
- launch catalogue size;
- exact Plan names;
- AI model or provider for Circle Coach;
- medical or Coach safety implementation;
- revenue forecasts;
- marketing campaigns.

These remain later decisions, to be made — and checked against this document — only when they become necessary, not assumed in advance.

## Unresolved Future Decisions

Carried forward from existing documentation:

1. The concrete, measurable trigger moment for first showing Premium ([Onboarding Principles §3](onboarding-principles.md#3-premium-strategie); [Product Discovery §6](product-discovery.md#6-open-vragen)).
2. AI model/provider and the safety/moderation framework for Circle Coach (§5).
3. Final Plan catalogue and naming (§4).
4. Pricing, packaging, trial length, and paywall timing (see Non-Goals).

Resolved during this pass, no longer open: the Circle Session/Circle Plan terminology (now matches Playbook Chapter 2 §9 throughout — see "A note on authority") and the explicit, nameable free list (§1, recorded in [ADR-007](adr/ADR-007-premium-never-blocks-the-core-loop.md)).

---

## Document Relationships

- **The [Playbook](../playbook/README.md)** governs philosophy — including whether a Premium idea is acceptable at all (Chapter 4 §5).
- **[VISION.md](../VISION.md)** governs why THIRTY exists and for whom; nothing here may contradict it.
- **[WORLD_SYSTEM.md](../worlds/WORLD_SYSTEM.md)** governs Premium Atmosphere's relationship to a World's identity, seasons, and growth.
- **[MOTION_LANGUAGE.md](../motion/MOTION_LANGUAGE.md)** governs Premium Motion specifically.
- **This document** governs commercial strategy — why Premium is worth building, in what priority, and the test future Premium ideas must pass.
- **Future implementation ADRs** will govern the technical realisation of Plans, Sessions, Coach, Insights, and Atmosphere, checked against this document.
- **Future pricing/business decisions** will govern price, packaging, and entitlement, checked against this document's priority order and boundary test.

None of those documents is modified by this one.

---

## Version History

### v1.0

- Initial approved version.
- Approved after terminology reconciliation and editorial review.
- Establishes THIRTY's official Premium product strategy.
- Records Circle Plans as the primary Premium product.
- Preserves Circle Sessions as individual guided Circle experiences.
- Records the approved free product boundary governed by ADR-007.
- Future strategic changes require an explicit product decision or ADR.

---

## Ownership

**Owner**

THIRTY Product Strategy

**Review Process**

PREMIUM_STRATEGY.md is a foundational product-strategy document.

Changes to its strategic priorities, free/Premium boundary interpretation, or canonical product definitions require an explicit product decision, approved product review, or ADR.

Implementation work must follow this strategy rather than redefine it.

[ADR-007](adr/ADR-007-premium-never-blocks-the-core-loop.md) remains authoritative for the approved free/Premium boundary; the Playbook remains authoritative for product philosophy; future pricing, packaging, entitlement, Coach safety, and implementation decisions require separate approval.

---

*This is v1.0 of the THIRTY Premium Strategy, in Approved status. It builds on the [THIRTY Playbook](../playbook/README.md), [VISION.md](../VISION.md), [WORLD_SYSTEM.md](../worlds/WORLD_SYSTEM.md), and [MOTION_LANGUAGE.md](../motion/MOTION_LANGUAGE.md), and contradicts none of them. Future strategic modifications require an explicit product decision or ADR, per [Playbook GOVERNANCE.md](../playbook/GOVERNANCE.md).*
