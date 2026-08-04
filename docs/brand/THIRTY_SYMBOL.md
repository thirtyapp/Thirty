# THIRTY Symbol

**Version:** v0.2
**Status:** Draft v0.2 — not yet Approved. No image, icon, or code asset may be produced from this document until it reaches Approved status.

## Purpose

This document defines the design specification for the THIRTY symbol: the stable brand mark named in [World System §13, First Breath Relationship](../worlds/WORLD_SYSTEM.md#13-first-breath-relationship) and [Motion Language §4, Motion Hierarchy](../motion/MOTION_LANGUAGE.md#4-motion-hierarchy), but never previously specified anywhere in the repository.

It decides principles, not pixels — what the symbol must be, what it must never become, and what it must support. Final geometry, typography, and numeric motion values are explicitly deferred (§14, Non-Goals).

---

## A note on authority

This document does not sit above the [THIRTY Playbook](../playbook/README.md), [BRAND_BOOK.md](../BRAND_BOOK.md), [WORLD_SYSTEM.md](../worlds/WORLD_SYSTEM.md), [MOTION_LANGUAGE.md](../motion/MOTION_LANGUAGE.md), or [DESIGN_SYSTEM.md](../DESIGN_SYSTEM.md). It fills a gap those documents left open rather than governed: none of them defines what the THIRTY symbol actually is.

It builds on, and must never contradict:

- **The Circle is the product, not the logo** — [Playbook Ch.1 §3](../playbook/01-the-circle-manifesto.md#3-the-meaning-of-the-circle): *"The Circle is not the app icon. The app icon may depict a circle, but the Circle is the product... logos can be redesigned; the Circle cannot."* That sentence already implies a symbol is a legitimate, separate concept from the Circle — it was simply never specified. §1 below states the relationship explicitly.
- **Circle Sage is THIRTY's brand-identity color** — [DESIGN_SYSTEM.md, "Brand Identity vs. Implementation Tokens"](../DESIGN_SYSTEM.md#brand-identity-vs-implementation-tokens): the value to use "for brand assets, marketing, illustration, product communication, and any static or non-interactive expression of THIRTY's visual identity." The symbol is exactly that kind of expression. §5 below inherits Circle Sage (`#7C8B6D`), not [Brand Book §13](../BRAND_BOOK.md#13-color-philosophy)'s earlier turquoise table, which DESIGN_SYSTEM.md v1.1 has since superseded for brand-identity purposes — a pre-existing divergence between those two documents that this document does not attempt to resolve; it simply defers to the more recent, more specific one, as DESIGN_SYSTEM.md itself instructs.
- **First Breath is Ritual Motion, Primary Motion, Ceremonial timing, and silent** — [Motion Language §3.A, §4, §6, §10](../motion/MOTION_LANGUAGE.md). §6 below inherits these constraints rather than restating their reasoning.
- **The First Breath, in full, is unconditionally free** — [PREMIUM_STRATEGY.md §1](../product/PREMIUM_STRATEGY.md#1-free-product-promise); [ADR-007](../product/adr/ADR-007-premium-never-blocks-the-core-loop.md). §9 below restates this as it applies specifically to the symbol.
- **The canonical First Breath sequence** — [World System §13](../worlds/WORLD_SYSTEM.md#13-first-breath-relationship), reconciled alongside this document (see that section's Version History, v1.0.1).

Where this document is silent, the Playbook, Brand Book, World System, Motion Language, and Design System govern. Where a future decision would require contradicting a claim made here, that is a deliberate amendment, made with the same care as any other — not a quiet drift.

## Table of contents

1. [Purpose](#1-purpose)
2. [Symbol Versus Wordmark](#2-symbol-versus-wordmark)
3. [Form Principles](#3-form-principles)
4. [Relationship to the Circle](#4-relationship-to-the-circle)
5. [Colour](#5-colour)
6. [Motion Compatibility](#6-motion-compatibility)
7. [Asset Requirements](#7-asset-requirements)
8. [Platform Relationships](#8-platform-relationships)
9. [Premium Boundary](#9-premium-boundary)
10. [Multiple-World Independence](#10-multiple-world-independence)
11. [Accessibility](#11-accessibility)
12. [Reduced Motion](#12-reduced-motion)
13. [Review Checklist](#13-review-checklist)
14. [Non-Goals](#14-non-goals)
15. [Document Authority](#15-document-authority)

---

## 1. Purpose

The THIRTY symbol is the stable brand mark that appears during The First Breath and may later inform other brand contexts (§8). Four claims define it:

- **The Circle is the product** ([Playbook Ch.1 §3](../playbook/01-the-circle-manifesto.md#3-the-meaning-of-the-circle)) — the daily unit of attention, the shape progress takes. The symbol is not this.
- **The symbol is not the Circle, and must never attempt to replace it.** It is the maker's mark, not the ritual object. Where the Circle means "today," the symbol means "THIRTY made this."
- **The symbol represents THIRTY as a brand** — the same role a maker's mark plays on an otherwise unbranded, well-made object: present, but not the object itself.
- **The symbol must remain stable while Worlds, seasons, daypart, weather, and Personal Growth change around it.** It is the one constant Home shows across every context — everything else in the Circle Hero is permitted to vary; the symbol is not.
- **The symbol may appear inside the Circle, but must never visually compete with it** (§4). It is a brief guest inside the Circle's space at steps 2–4 of the canonical sequence, not a permanent occupant or a second focal point.

**Formal rule**, restated from the authority this document builds on:

> The Circle is not the logo. The Circle is the product.

## 2. Symbol Versus Wordmark

**Decision: a standalone symbol. No wordmark, no combined mark, for First Breath.**

The word "THIRTY" is not assumed to appear anywhere in the First Breath ritual, and this document does not assume it should.

Reasoning, against the criteria this decision must be based on:

- **Mobile Circle size.** The illustration inset today already sits well inside the ring's stroke (`circle_hero.dart`'s existing `illustrationSize = circleSize − strokeWidth×2`), and §4 requires the symbol to sit with materially more breathing room than that. At that size, a wordmark either becomes illegible or forces the Circle to grow beyond what "the brand introduces the ritual, then steps aside" ([World System §13](../worlds/WORLD_SYSTEM.md#13-first-breath-relationship)) allows.
- **Calm ritual use, short display duration.** The symbol phase is one Ceremonial beat inside a ritual already measured in a few seconds total ([Motion Language §6](../motion/MOTION_LANGUAGE.md#6-timing)). A viewer has time to register a shape, not read a word.
- **Independence from language.** THIRTY has no stated localization decision. A wordmark hard-codes English into the most repeated, silent, wordless moment in the product ([Motion Language §13](../motion/MOTION_LANGUAGE.md#13-silence), "Stillness is part of the experience"). A symbol needs no translation and asks nothing of a reader.
- **Recognisability at small size.** A simple mark reads faster at small scale than a word does — the same reasoning [Playbook Ch.3 §9](../playbook/03-circle-design-language.md#9-icons) already applies to icons generally ("used when a shape can be recognized faster than a word can be read").
- **Accessibility.** A symbol marked decorative (§11) costs nothing whether or not a word is baked into it. A wordmark rendered as an image would additionally need special handling to avoid becoming an unlabeled image of text, which a pure symbol never risks.
- **Future app-icon use.** Platform app icons are conventionally symbol-first — a wordmark rarely survives being cropped into a rounded-square icon. §8 already treats the app icon as a separate future deliverable; a symbol-first choice here keeps that door open without deciding it now.

A wordmark may still have its own, separate use elsewhere (app store listing, website, social avatar) — that is a §8 decision, not this one, and is not made here.

## 3. Form Principles

**What the symbol must communicate.** Of the candidate qualities worth evaluating, three are load-bearing:

- **Calm** — the symbol must itself pass [the Golden Rule](../BRAND_BOOK.md#1-the-golden-rule): does it feel rustiger, eenvoudiger en menselijker than the alternative of no symbol at all?
- **Intention** — it should read as a considered mark, not an ornament. Every stroke should be explainable.
- **Continuity** — as the one constant across every World, season, and daypart (§10), it should read as something that persists, not something that arrives with spectacle.

Completion, renewal, and openness are the Circle's meanings, not the symbol's ([Playbook Ch.1 §3](../playbook/01-the-circle-manifesto.md#3-the-meaning-of-the-circle)) — assigning them to the symbol would blur the exact distinction §1 exists to draw. Balance and human imperfection are secondary qualities worth keeping in mind stylistically, not requirements the symbol must prove on its own. Recognisability is handled as a constraint below, not a quality to "communicate."

**What the form must be:**

- simple enough to read clearly at mobile size;
- distinctive enough not to look generic;
- stable under a subtle scale heartbeat — no part of the form should read as "broken" mid-pulse;
- visually centred;
- usable in monochrome (§5);
- free of unnecessary detail;
- free of literal wellness clichés;
- free of decorative World imagery — Worlds are not the symbol's job ([World System, Design Principles](../worlds/WORLD_SYSTEM.md#design-principles): "The World is a place, not an illustration"; the same discipline applies here: the symbol is a mark, not an illustration).

**What it must not become, and why:**

| Rejected form | Reason |
|---|---|
| A second progress ring | Directly violates [Playbook Ch.1 §3](../playbook/01-the-circle-manifesto.md#3-the-meaning-of-the-circle) by making the symbol a small copy of the very object it is supposed to introduce and then step aside from — visually competing with, or pre-empting, the Circle's own reveal at step 5. |
| A literal completed Circle | Same failure as above, more literally — it would announce the day's outcome before the day has even opened. |
| A play button | Implies "start," which is Start Circle's meaning — a distinct, later moment that also carries a haptic ([Motion Language §10](../motion/MOTION_LANGUAGE.md#10-haptics)). Reusing that gesture here blurs two different moments into one. |
| A check mark | Implies completion, which is Circle Closed's territory ([Brand Book §10, The THIRTY Moment](../BRAND_BOOK.md#10-the-thirty-moment)). First Breath is a beginning, not a completion. |
| A heart, leaf, or sunrise icon; a meditation silhouette; a miniature landscape | Literal wellness clichés — exactly what [Brand Book §18](../BRAND_BOOK.md#18-illustration-style) and the Illustration Language already warn against for World illustration. These would make THIRTY indistinguishable from any other health app rather than the calm, timeless mark [DESIGN_SYSTEM.md §2.1](../DESIGN_SYSTEM.md#brand-identity-vs-implementation-tokens) describes for Circle Sage. A landscape specifically is also literally the World's job ([World System §3](../worlds/WORLD_SYSTEM.md#3-world-structure), [§6](../worlds/WORLD_SYSTEM.md#6-illustration-language)) — putting one inside the symbol would duplicate a World before any World has been revealed. |
| An infinity symbol | The closest of this list to being on-theme (continuity), and rejected for exactly that reason: the Circle already owns "no beginning, no end" ([Playbook Ch.1 §3](../playbook/01-the-circle-manifesto.md#3-the-meaning-of-the-circle)). A second, different closed-loop shape would create two competing "endless" motifs on the same screen. |
| A generic app-icon glyph | Fails distinctiveness outright — indistinguishable from stock. This is the exact failure state already found among this repository's own unmodified platform placeholder icons. |

## 4. Relationship to the Circle

The symbol sits inside the closed Circle, clearly subordinate to it:

- it must not touch the Circle's stroke;
- it must have generous breathing room — visibly more inset than the World illustration is today, since the illustration is designed to fill the Circle's interior and the symbol must not read as attempting the same job;
- it must remain legible without a background plate behind it;
- it must not mimic Circle progress in any way — no arc, no partial fill, no sweep;
- it must not create a second concentric ring;
- it must stay centred within the Circle while the Circle itself remains visually stable (the closed Circle does not move during the symbol's phase — see [World System §13](../worlds/WORLD_SYSTEM.md#13-first-breath-relationship)'s canonical sequence, steps 1–4);
- the Circle does not reshape itself around the symbol — the relationship is one of a small mark resting inside a large, calm, unchanged space, never the reverse.

Proportional relationship, without pixel measurements: the symbol should occupy a materially smaller fraction of the Circle's interior than the World illustration is designed to. Where the illustration is inset only enough to clear the ring's stroke, the symbol should read as a small, quiet mark with room to spare around it on every side — closer to a signature than to a filling.

## 5. Colour

**Colour-token verification.** Circle Sage is already a canonical, named brand color in [DESIGN_SYSTEM.md §2.1](../DESIGN_SYSTEM.md#brand-identity-vs-implementation-tokens) ("Circle Sage — brand color"), documented at the brand-identity layer specifically *because* it must stay stable for exactly this kind of non-interactive, static brand use — separate from `AppColors.primary`, the Flutter implementation token, which is permitted to diverge from it minimally for accessibility reasons (§4.2 of that document). This document does not define, own, or duplicate the colour value — it inherits "Circle Sage" as the canonical name and cites DESIGN_SYSTEM.md §2.1 as the sole authority for it. The hex value below is retained only as a descriptive reference, consistent with how DESIGN_SYSTEM.md itself writes the name alongside its hex throughout. No new token is introduced by this document, and none is needed: no canonical Design System token besides Circle Sage was found to apply, and none was created here.

**The symbol must support:**

- a primary monochrome treatment, using the canonical Circle Sage brand color (`#7C8B6D`, per [DESIGN_SYSTEM.md §2.1](../DESIGN_SYSTEM.md#brand-identity-vs-implementation-tokens)) — not the `primary` implementation token, and not [Brand Book §13](../BRAND_BOOK.md#13-color-philosophy)'s earlier turquoise value, which DESIGN_SYSTEM.md v1.1 has since superseded for brand-identity use;
- legible use against THIRTY's warm neutral background — Cream in light mode, the derived dark near-black background in dark mode ([DESIGN_SYSTEM.md §2.4](../DESIGN_SYSTEM.md), §3);
- use inside the closed Circle, per §4;
- a light and a dark application only where the Design System requires one — not as two independently designed marks.

**The symbol must not:**

- change colour by World;
- change colour by season, daypart, or weather;
- change colour by Premium status (§9);
- use gradients as part of its identity;
- require multiple colours to remain recognisable;
- contain baked-in shadow, glow, or atmosphere of any kind.

Future atmosphere may exist around the symbol (light, softness, a subtle glow behind it) — but that atmosphere is not part of the symbol asset itself, exactly as [World System §13](../worlds/WORLD_SYSTEM.md#13-first-breath-relationship) already reserves seasonal atmosphere for the World, never the symbol.

## 6. Motion Compatibility

The symbol must remain visually stable through every phase of its First Breath appearance: arrival, one restrained heartbeat, return to rest, and fade-out.

**The symbol itself must not:**

- deform;
- rotate;
- bounce;
- overshoot;
- wobble;
- morph;
- fragment;
- redraw itself;
- repeat its heartbeat;
- react to Premium or World state.

These exclusions are not new rules — they restate [Motion Language §7](../motion/MOTION_LANGUAGE.md#7-easing)'s existing prohibition on bounce, spring, elastic, and overshoot easing, applied specifically to the one shape that must hold this discipline most strictly, since it is the first thing First Breath shows.

**The heartbeat must feel like presence, not excitement** — a single, restrained pulse, resolving fully back to rest before any fade-out begins. This document sets no numeric scale, opacity, or duration value; those belong to a later motion implementation and tuning pass (§14), checked against [Motion Language §6](../motion/MOTION_LANGUAGE.md#6-timing)'s Ceremonial timing category and this document's qualitative requirement.

## 7. Asset Requirements

The future approved asset must satisfy:

- a vector master as the preferred source format;
- a high-resolution raster fallback only where a specific, justified technical constraint requires one;
- a transparent background;
- tight but safe intrinsic bounds — no baked-in outer padding beyond what the shape itself needs to render cleanly;
- no shadow;
- no glow;
- no background shape or plate;
- no text, since the approved First Breath mark is a standalone symbol, not a wordmark (§2) — this requirement is reopened only if a future, separate decision changes that;
- monochrome compatibility (§5);
- clean rendering at small mobile sizes, verified at the actual scale it will render inside the Circle (§4), not only at a large design-review size.

This document does not select a Flutter package, decide SVG integration architecture, or specify a rendering pipeline — those are implementation decisions for a later technical task, checked against this document rather than assumed here.

## 8. Platform Relationships

The approved THIRTY symbol may later inform:

- the app icon;
- the splash experience;
- onboarding;
- the website;
- a social avatar;
- First Breath.

These uses may require separate crops or compositions — a symbol correct for a small mark resting inside a large, calm Circle (§4) is not automatically correct for a rounded-square app icon that has no Circle around it at all. The exact First Breath asset should not be assumed to copy directly into every platform context without a specific check for each one.

The app icon remains a separate future deliverable. No existing Flutter scaffold icon (iOS `AppIcon.appiconset`, `LaunchImage.imageset`; macOS `AppIcon.appiconset`; web `favicon.png`/`icons/`; Windows `app_icon.ico`) is modified by this document or by any task that produced it.

## 9. Premium Boundary

- The THIRTY symbol is available to every user, free and Premium alike.
- The complete First Breath brand ritual — symbol appearance, heartbeat, fade-out — is free, per [PREMIUM_STRATEGY.md §1](../product/PREMIUM_STRATEGY.md#1-free-product-promise) ("The First Breath, in full") and [ADR-007](../product/adr/ADR-007-premium-never-blocks-the-core-loop.md).
- Premium does not receive a different symbol.
- Premium does not receive a stronger heartbeat.
- Premium does not receive a longer or more complete ritual.
- Cancellation never changes the brand mark — a returning free user sees exactly the same symbol they always did, per [PREMIUM_STRATEGY.md §8](../product/PREMIUM_STRATEGY.md#8-personal-growth-and-premium)'s standing rule that a cancelled subscription returns a user to the free experience, not a diminished one.

Future Premium Atmosphere ([PREMIUM_STRATEGY.md §7](../product/PREMIUM_STRATEGY.md#7-premium-atmosphere)) may enrich the selected World only after the shared brand ritual has completed — never the symbol phase itself, and never in a way that makes the ritual different for a paying user. This follows §7's own formal principle: *"Atmosphere rewards commitment. It does not create the reason to subscribe."*

## 10. Multiple-World Independence

The symbol and its ritual know nothing about:

- Quiet Trail;
- `ActivityCategory`;
- World;
- Place;
- season;
- daypart;
- weather;
- Personal Growth;
- Premium Atmosphere.

The reusable conceptual sequence, per [World System §13](../worlds/WORLD_SYSTEM.md#13-first-breath-relationship):

> Brand ritual → Circle opening → selected World reveal

Every future Circle Hero World reuses the same brand ritual unchanged. Nothing about the symbol's form, colour, or motion is parameterised by which World, season, or Premium state follows it.

## 11. Accessibility

**Decision: the symbol is decorative during First Breath.**

The Circle already exposes the only meaningful semantics for this moment, via `ThirtyProgressCircle`'s existing `Semantics` node: "Today's Circle" / "Ready to begin." Announcing "THIRTY" mid-ritual adds narration noise, not useful information — a screen-reader user already knows which app they opened before First Breath ever plays (the platform itself announces the app on launch), so a second, mid-ritual name announcement is redundant rather than informative.

This matches the precedent [circle_hero.dart](../../lib/features/home/presentation/widgets/circle_hero.dart) already sets for the World illustration layer, which is wrapped in `ExcludeSemantics` for the same reason. The symbol should follow the same pattern when implemented, preserving a single meaningful Circle semantics owner rather than adding a second, competing one.

Heartbeat, opacity, and scale changes on the symbol must not be exposed to accessibility services — there is no meaning inside that motion for a screen reader to preserve, since the symbol itself is decorative.

## 12. Reduced Motion

**Reduced-motion support is mandatory in the First Breath v2 implementation sprint.**

THIRTY has no reduced-motion handling anywhere in the app today (confirmed by a repository-wide search: no matches for reduced-motion or `disableAnimations` handling in `lib/`). That absence is not a reason to defer this requirement — it is the reason to hold it firmly here. First Breath v2 introduces new, intentional motion (the symbol's arrival, heartbeat, and fade-out); shipping that new motion without a reduced-motion path would knowingly *expand* an existing accessibility gap rather than merely inherit one. A gap that already exists elsewhere in the app is a separate, pre-existing problem to track and close on its own schedule (see the standing requirement in [Motion Language §11](../motion/MOTION_LANGUAGE.md#11-accessibility)); it is not license to add a new ritual moment that repeats it.

**Reduced-motion ritual, at design level:**

1. The closed Circle is present.
2. The stable THIRTY symbol appears without heartbeat scale animation.
3. The symbol remains briefly stable.
4. The symbol disappears through either a very brief calm crossfade or an immediate transition.
5. The Circle moves directly or near-directly to its open, settled state.
6. The selected World and Home content become available without the normal long stagger.
7. Start Circle interaction is not unnecessarily delayed.

**This reduced-motion path preserves:**

- the same daily ritual meaning — the symbol still marks the day's opening; nothing is silently removed, only shortened;
- the same local-calendar, once-per-day persistence;
- the same selected World;
- the same accessibility semantics (§11) — still decorative, still a single Circle semantics owner;
- the same free/Premium boundary (§9) — reduced motion is a platform/user setting, never a Premium differentiator in either direction.

**This document does not prescribe:**

- exact durations;
- Flutter APIs;
- `MediaQuery` implementation details;
- animation-controller architecture.

Those are implementation decisions for the later technical pass (§14, §15), checked against this specification rather than decided here.

**Reduced motion reduces movement and waiting — never meaning or access.** Every step above still happens; only how long each one takes, and how much it visibly animates, is reduced.

## 13. Review Checklist

Before any First Breath symbol asset ships, it should be able to answer these honestly:

- Does the symbol remain distinct from the Circle?
- Is it recognisable at mobile size?
- Does it feel calm rather than energetic?
- Does one heartbeat feel restrained?
- Does it return cleanly to rest?
- Is it visually subordinate to the Circle?
- Does it remain stable across every World?
- Does it work in monochrome?
- Does it avoid generic wellness symbolism?
- Does it remain identical for free and Premium users?
- Does reduced motion preserve the ritual without unnecessary animation?

A symbol that cannot be answered well on all of these is not ready, regardless of how well it is drawn.

## 14. Non-Goals

This document does not decide:

- final logo geometry;
- final wordmark typography;
- exact dimensions;
- exact heartbeat timing;
- exact scale percentage;
- Flutter widget architecture;
- an SVG or image-rendering package;
- app-icon composition;
- splash implementation;
- animation code;
- Premium Atmosphere's own specification;
- public launch branding.

These require later, separate design and implementation passes, checked against this document rather than assumed by it.

## 15. Document Authority

- **The [Playbook](../playbook/README.md)** governs product philosophy, including whether the symbol's existence and behaviour are acceptable at all.
- **[BRAND_BOOK.md](../BRAND_BOOK.md)** governs brand expression more broadly — tone, personality, and the app-icon guidance in §23, which this document's §8 defers to rather than repeats.
- **This document, THIRTY_SYMBOL.md,** governs the approved symbol direction, once it reaches Approved status — form, colour, and asset requirements.
- **[MOTION_LANGUAGE.md](../motion/MOTION_LANGUAGE.md)** governs the symbol's animation — this document states what the motion must respect (§6, §12); Motion Language governs how motion in general is reasoned about.
- **[WORLD_SYSTEM.md](../worlds/WORLD_SYSTEM.md)** governs the sequence relationship between the symbol, the Circle, and the World (§13).
- **[PREMIUM_STRATEGY.md](../product/PREMIUM_STRATEGY.md)** and **[ADR-007](../product/adr/ADR-007-premium-never-blocks-the-core-loop.md)** govern the free/Premium boundary this document's §9 restates.
- **A later technical task or ADR** governs implementation — Flutter widget structure, asset pipeline, and rendering, checked against this document rather than deciding it here.

This document remains in **Draft** status. It is not marked Approved during the task that authored it, and no asset should be generated from it until an explicit approval step promotes it, in the same spirit as the Playbook's own approval workflow ([GOVERNANCE.md](../playbook/GOVERNANCE.md#approval-workflow)).

**This Draft is a direction, not a design.** It approves *what the symbol must be and must never become* (§1–§12) — it does not itself contain, imply, or approve any final geometry, typography, or artwork. The distinct stages that follow it are:

1. **Approve the symbol-direction document** — this document (THIRTY_SYMBOL.md) moves from Draft to Approved, unchanged in kind from what it is now: principles, not pixels.
2. **Create several visual symbol concepts** — a future, separate design pass explores multiple candidate forms against §3's principles and rejection list. None of those concepts exists yet, and none is implied by this document.
3. **Select and refine one concept** — a deliberate narrowing from several candidates to one, checked against the full specification (§3–§7).
4. **Approve the master vector asset** — the specific, final file (§7) is reviewed and approved on its own, separately from the direction that shaped it.
5. **Implement First Breath v2** — a Flutter implementation task builds both the normal-motion and reduced-motion (§12) paths from the approved asset and this specification, checked against them rather than redefining either.

Each stage requires its own explicit approval; none is skipped by completing an earlier one, and this document's own approval (stage 1) does not fast-forward to stage 4.

---

## Version History

### v0.2 — 2026-08-04

- Refinement pass, ahead of editorial review. Still Draft; not yet Approved.
- §12 Reduced Motion rewritten: reduced-motion support is now stated as mandatory for the First Breath v2 implementation sprint, with an explicit seven-step reduced-motion ritual and an explicit list of what it preserves and does not prescribe.
- §5 Colour tightened: explicitly verifies Circle Sage as the existing canonical DESIGN_SYSTEM.md §2.1 brand-identity token rather than a value this document owns or duplicates.
- §15 Document Authority extended with the explicit five-stage approval pipeline from direction to implementation.
- Ownership/Review Process rewritten to the concise, named form (Owner: THIRTY Brand Design) with explicit review responsibilities per pipeline stage.
- Replaced one fragile, hand-computed markdown anchor with a stable citation.
- No change to §1–§4, §6–§11, §13, §14, or the standalone-symbol decision (§2).

### v0.1 — 2026-08-04

- Initial draft.
- Authored as one of the two prerequisites for THIRTY First Breath v2, alongside the [World System §13 sequence reconciliation](../worlds/WORLD_SYSTEM.md#13-first-breath-relationship) (v1.0.1).
- Not yet reviewed or approved. No asset has been generated from this version.

---

## Ownership

**Owner**

THIRTY Brand Design

**Review Process**

- Symbol-direction changes require explicit Brand Design approval.
- Final geometry requires visual concept review (approval pipeline stage 2–3 above).
- The production asset requires explicit approval, separate from the direction that shaped it (stage 4 above).
- Implementation must follow the approved asset and this specification, not redefine either (stage 5 above).
- Neither Flutter code nor an AI-generated draft may redefine the symbol.

Once Approved, this document is never silently edited — only through an explicit, dated patch or amendment, in the same spirit as the Playbook's own approval workflow.

No image, icon, or code asset may be generated from this document while it remains in Draft status.

---

*This is v0.2 of the THIRTY Symbol specification, in Draft status. It builds on the [THIRTY Playbook](../playbook/README.md), [BRAND_BOOK.md](../BRAND_BOOK.md), [WORLD_SYSTEM.md](../worlds/WORLD_SYSTEM.md), [MOTION_LANGUAGE.md](../motion/MOTION_LANGUAGE.md), and [DESIGN_SYSTEM.md](../DESIGN_SYSTEM.md), and contradicts none of them. It requires review and explicit approval before any asset may be produced from it.*
