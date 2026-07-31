# THIRTY Playbook

**Version:** v1.0
**Status:** Approved

## Purpose

The Playbook is THIRTY's philosophical, experiential, visual-grammar, and product-governance foundation — the reasoning every future screen, feature, and decision is checked against. It exists so that a founder, a designer, a developer, or an AI agent, working on THIRTY at any point in the company's life, arrives at the same decision the same way.

## Reading order

1. [Chapter 1 — The Circle Manifesto](01-the-circle-manifesto.md) — why THIRTY exists, and what the Circle means.
2. [Chapter 2 — Circle Experience System](02-circle-experience-system.md) — how THIRTY should feel, moment to moment.
3. [Chapter 3 — Circle Design Language](03-circle-design-language.md) — the visual grammar that expresses Chapters 1–2.
4. [Chapter 4 — Product Decision Framework](04-product-decision-framework.md) — how to decide whether a future feature should exist at all.
5. [GOVERNANCE.md](GOVERNANCE.md) — how the Playbook itself is maintained, versioned, and extended.
6. [editorial-review-v1.md](editorial-review-v1.md) — the consistency and governance audit performed before freezing v1.0.

Each chapter states which earlier chapters it builds on and does not repeat their content — read them in order the first time.

## Scope

The Playbook governs *why* THIRTY looks, feels, and behaves the way it does, and *whether* a proposed feature belongs in THIRTY at all. It does not contain concrete token values (colors, spacing, type scales), specific UI copy, or the mechanics of the recommendation engine — those live in the documents below, which the Playbook references rather than replaces.

## Relationship with existing documentation

| Document | Responsibility relative to the Playbook |
|---|---|
| **[Brand Book](../BRAND_BOOK.md)** | The origin of the Golden Rule, Core Values, tone of voice, and the first, shorter statements of the Circle Philosophy, Emotional Journey, and Design Principles. The Playbook elaborates these in depth; the Brand Book remains the shorter entry point and is not replaced. |
| **Design System** *(the theme token files in `lib/core/theme/`; a dedicated `DESIGN_SYSTEM.md` is referenced by Brand Book §13 but not yet written)* | Defines what a color, spacing, radius, or type value **is**. Chapter 3 explains **why** those values take the shape they do, and never redefines them. |
| **[Product ADRs](../product/adr/)** | Each records one dated, scoped, reversible-if-superseded decision. Several have been generalized by Chapter 4 into standing filters that apply beyond their original scope — each of those ADRs carries a forward reference to the chapter that elevated it. |
| **[Product Documentation](../product/README.md)** (`recommendation-philosophy.md`, `decision-framework.md`, `product-discovery.md`, `onboarding-principles.md`) | Governs one specific system in mechanical detail: how a daily recommendation is constructed. Chapter 4 operates one level above it — the governance of everything, at the altitude of "should this exist at all" — and does not replace its detailed conflict-resolution rules. |
| **[CLAUDE.md](../../CLAUDE.md)** | Governs how the team works: tech stack, architecture, workflow, Definition of Done. Delegates brand and product philosophy outward — previously to the Brand Book alone, now to the Playbook for the deeper layer. |

## Version history

- **v1.0** — Approved. Chapters 1–4 frozen following the editorial review in `editorial-review-v1.md`.
