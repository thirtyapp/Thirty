# THIRTY World System

**Version:** v1.0.2
**Status:** Approved v1.0.2

## Purpose

This document defines how THIRTY creates, varies and evolves the illustrated worlds that appear inside the Circle, in recommendation cards, during Circle Sessions and at completion.

---

## Design Principles

This section is a quick reference for designers and developers. It restates, in compact form, the standing rules that govern every World — the reasoning for each is developed in the sections that follow, not repeated here.

- The World is a place, not an illustration.
- The World always serves the Circle.
- Every recommendation belongs to one World.
- The same World accompanies the user throughout one daily journey.
- Worlds evolve slowly.
- Nature follows time.
- The World remembers your return.
- Premium deepens a World. It never replaces one.

---

## A note on authority

The World System does not sit above the [THIRTY Playbook](../playbook/README.md). It is a new domain the Playbook did not yet govern — the kind of extension [Chapter 1 §14](../playbook/01-the-circle-manifesto.md#14-the-future-vision) anticipates and [GOVERNANCE.md](../playbook/GOVERNANCE.md#criteria-for-creating-a-new-chapter) sets the bar for: it must build on what the Playbook already says, restate none of it, and never contradict it.

Everything below extends, and is checked against, decisions already made elsewhere:

- **The Circle is the product**, not decoration ([Chapter 1 §3](../playbook/01-the-circle-manifesto.md#3-the-meaning-of-the-circle)). A World exists to serve the Circle; it is never a competing focal point.
- **No streaks, no ledgers, no punished absence** ([Chapter 1 §7–8](../playbook/01-the-circle-manifesto.md#7-why-completion-matters-more-than-streaks), [Chapter 2 §10](../playbook/02-circle-experience-system.md#10-experience-rules)). World growth must obey the same rule.
- **Premium deepens, it never gates** ([Chapter 1 §9](../playbook/01-the-circle-manifesto.md#9-premium-as-a-deeper-experience), [Chapter 2 §9](../playbook/02-circle-experience-system.md#9-premium-experience), [Chapter 4 §5](../playbook/04-product-decision-framework.md#5-the-premium-filter)). A World's Premium Atmosphere must pass the same test every other Premium concept already passes.
- **Illustration is minimal, geometric, and used sparingly** ([Brand Book §18](../BRAND_BOOK.md#18-illustration-style)); **motion must mean something before it may exist** ([Chapter 2 §4](../playbook/02-circle-experience-system.md#4-motion-principles)); **color is meaning before mood, and a narrow palette is a form of confidence** ([Chapter 3 §6](../playbook/03-circle-design-language.md#6-color-philosophy), [DESIGN_SYSTEM.md](../DESIGN_SYSTEM.md)).
- **Real people, shown without performance or comparison** ([Brand Book §17, Photography Style](../BRAND_BOOK.md#17-photography-style)) is the existing rule for photography; this document states the equivalent rule for illustration explicitly, for the first time, in §2 below.

Where this document is silent, the Playbook governs. Where a future decision would require contradicting a claim made here or in the Playbook, that is a deliberate amendment, made with the same care as any other — not a quiet drift.

---

## Core Philosophy

The World System is built on five standing statements. Every section below is a working-out of one or more of them, never a departure from them.

> **"The Circle shows possibility. The Card shows intention."**

> **"The brand welcomes you. The world keeps you."**

> **"Nature follows time. The world remembers you."**

> **"The world never judges the user. It only remembers them."**

> **"World progression belongs to every user. Premium enriches the world, but never owns it."**

The World System must reinforce:

- The Circle is the product.
- The user should be able to imagine themselves inside the world.
- THIRTY shows moments and places, not idealized people.
- The world evolves without streaks, pressure, shame or loss.
- Premium deepens the experience but never gates its emotional core.

---

## 1. Why Worlds Exist

THIRTY does not use illustration merely as decoration. Brand Book §18 already limits illustration to being "used sparingly... not as decoration on every screen" — a World is the specific, deliberate exception that earns its place, because it does real work the interface cannot do with layout or copy alone.

A World:

- emotionally introduces the recommendation, before a single word of it is read;
- gives each recommendation category a recognisable visual identity of its own;
- creates continuity across Home, Session and Completion, so the day's ritual feels like one place, not a sequence of unrelated screens;
- helps the user feel the activity before reading it;
- allows the product to evolve with season, time and personal history, without ever touching the Circle's shape, size or meaning.

The test for whether a World is doing its job is a feeling, not a checklist:

> The user should think: **"I would like to be there."**
> Not: **"That is a nice icon."**

An illustration that reads as clever, decorative, or impressive has failed this test regardless of its craft. A World that makes the user briefly want to be somewhere else, somewhere quiet, has succeeded.

---

## Emotional Intent

Every World is designed around an emotional objective before any visual decision is made. The composition, palette and light described in later sections exist to serve that objective — they are not chosen first and explained afterward.

| Category | Emotion |
|---|---|
| Walking | Invitation |
| Meditation | Stillness |
| Reading | Comfort |
| Stretching | Space |
| Journaling | Reflection |
| Creativity | Curiosity |

Categories beyond Walking are illustrative of this reasoning pattern, not a commitment to build them — §16 and §18 govern which categories and Worlds actually ship.

Emotion is the primary design driver. Illustration exists to reinforce emotion; it does not exist to decorate the interface.

---

## 2. No People

**THIRTY Worlds do not show identifiable people.**

Do not use:

- recognisable men or women;
- age-coded bodies;
- idealised fitness bodies;
- faces;
- avatars;
- human silhouettes as the main subject.

**Reason.** The user should imagine themselves inside the scene, not compare themselves with an illustrated person. A depicted body — however abstract — invites a silent comparison (age, fitness, gender presentation) that a place never does. This formalises, for illustration, the same instinct already stated for photography in Brand Book §17: THIRTY favours "moment and feeling... over showing intense effort," and never a "competitive, fitness-influencer aesthetic." It is also a direct expression of the Experience Principle "belonging without comparison" ([Chapter 1 §10](../playbook/01-the-circle-manifesto.md#10-the-emotional-principles)): the user's only meaningful comparison is with their own closed circles, never with a body — real or illustrated — that isn't theirs.

The environment carries the story. A tree, a path, a window, a chair — these can hold an emotional promise without ever inviting the user to measure themselves against anything.

---

## 3. World Structure

A World is a composition of independent dimensions, not one fixed image. Each dimension can vary on its own, and together they describe the exact scene the user sees at a given moment:

```
World
├── Category
├── Place
├── Season
├── Daypart
├── Weather Mood
├── Personal Growth
└── Premium Atmosphere
```

**Category.** The recommendation family, such as walking, meditation, reading or stretching. This is the axis that determines *which* World applies.

**Place.** The stable world identity, such as *Quiet Trail* or *Still Lake* — the one thing about a World that never changes, regardless of season, time, weather, or the user's history with it.

**Season.** Spring, summer, autumn or winter. Affects the World's detail, never its identity (see §9).

**Daypart.** Morning, afternoon or evening. Affects light and atmosphere (see §10).

**Weather Mood.** Examples include clear, cloudy, misty or lightly rainy. A restrained, secondary atmospheric layer (see §10).

**Personal Growth.** Permanent additions earned through completed Circles over time — never through streaks (see §11).

**Premium Atmosphere.** Optional richer motion, light, sound and detail layered on the same World (see §12).

These dimensions must remain independently composable. A World is the product of all seven at once, not a separate asset drawn for every combination — this is what allows THIRTY to feel infinitely varied while remaining, underneath, a small and disciplined system.

**Category vs. Place.** A recommendation Category is not itself a World — it is the axis that determines which Place options are available. A single Category may eventually contain multiple Worlds:

```
Walking
├── Quiet Trail
├── Forest Path
└── Coastal Walk
```

The Place is the long-term visual identity a user comes to recognise. The Category simply determines which Places are available for that recommendation family.

**Design rule:** *One recommendation category may contain multiple Worlds.*

---

## World Lifecycle

A rendered World is composed by applying each dimension from this section in a fixed conceptual order:

```
Recommendation
      ↓
World selected
      ↓
Season applied
      ↓
Daypart applied
      ↓
Weather Mood applied
      ↓
Personal Growth applied
      ↓
Premium Atmosphere applied
      ↓
Rendered World
```

These layers remain conceptually independent — each can vary without requiring the others to change, and none of them alters the World's stable identity. This section describes the order in which a World is composed, not an implementation pipeline; how it is actually rendered is a decision for a future implementation task (§17).

---

## 4. Naming Rules

World names describe a place or a feeling. They must never encode:

- season;
- time of day;
- weather;
- progress state;
- subscription tier.

**Good examples:** Quiet Trail · Forest Path · Open Meadow · Still Lake · Reading Nook · Garden Window

**Avoid:** Morning Trail · Autumn Path · Premium Forest · Completed Meadow

**Formal rule:**

> "World names describe place or feeling, never temporary context."

A name that encodes a variable dimension (§3) locks the World's identity to one instance of it — the opposite of what §3 requires. *Quiet Trail* remains *Quiet Trail* in every season, at every hour, whether the user is new to it or has returned a hundred times.

---

## 5. Visual Levels

One World has four main expressions. Each has its own purpose; none repeats another's job.

### A. Circle Hero World

**Purpose:** Emotion and possibility.

- rich, atmospheric version;
- fills the Circle;
- multiple depth layers;
- soft colour fields;
- light, mist and spatial depth;
- feels like a window rather than an icon.

### B. Activity Card Companion

**Purpose:** Concrete context.

- simplified line-art interpretation;
- the same world, not the same image reduced;
- thin lines;
- minimal tint;
- decorative and quiet;
- reminds the user of the Circle without repeating it.

**Formal rule:**

> "The Card should remind you of the Circle, not repeat it."

### C. Circle Session World

**Purpose:** Continuity during the activity.

- same place as Home;
- may contain subtle, meaningful movement;
- never becomes game-like;
- session progress may be reflected through light, atmosphere or viewpoint.

### D. Completion World

**Purpose:** Quiet acknowledgement.

- same place;
- subtly changed after completion;
- warmer light, clearer mist, or another restrained change;
- no celebration effects;
- supports the Circle Closed ritual ([Chapter 1 §12](../playbook/01-the-circle-manifesto.md#12-the-experience-principles), [Brand Book §10](../BRAND_BOOK.md#10-the-thirty-moment)) rather than competing with its deliberate restraint.

---

## 6. Illustration Language

**The Circle Hero World should feel:**

- atmospheric;
- editorial;
- organic;
- timeless;
- softly textured;
- natural rather than geometric.

**Use:**

- asymmetric forms;
- layered depth;
- soft light;
- restrained colour;
- subtle imperfections;
- curved paths;
- varied foliage;
- atmospheric perspective.

**Avoid:**

- icon-like geometry;
- perfect circular tree crowns;
- thick outlines;
- generic vector clip-art;
- stock illustrations;
- emoji;
- cartoon styling;
- 3D;
- isometric art;
- saturated colours;
- Material-style illustrations.

A landscape should feel like one coherent scene, not a collection of separate vector objects. This is the same discipline Brand Book §18 already names — "simple shapes, a narrow palette... no busy, detailed or cartoonish style" — applied at the fuller detail a Circle Hero World requires.

---

## 7. Depth and Composition

Every Circle Hero World should contain several spatial layers:

- sky or atmospheric background;
- distant layer;
- middle layer;
- focal element;
- foreground.

For Walking, an example composition:

- soft sky;
- distant hills;
- middle-ground tree;
- winding path;
- foreground vegetation.

The eye should be guided calmly through the scene, the same way [Chapter 3 §4](../playbook/03-circle-design-language.md#4-typography) requires one reading path per screen for text — a World needs one visual path for the eye. Avoid compositions where every object sits on the same visual plane; flatness reads as an icon, depth reads as a place.

---

## 8. Colour and Light

Worlds use the THIRTY palette as their base — see [DESIGN_SYSTEM.md](../DESIGN_SYSTEM.md) for the exact tokens.

**Primary references:**

- Circle Sage
- Mist Sage
- Warm Stone
- Cream
- approved text and neutral roles where needed

Use a narrow colour range. Do not introduce unrelated brand colours merely to make a World more expressive — this is the same restraint [Chapter 3 §6](../playbook/03-circle-design-language.md#6-color-philosophy) already requires of every other screen: *"A wide, expressive palette signals that a product wants to be noticed. A narrow, consistent one signals that a product already trusts what it's built."*

**Preferred light:**

- diffuse morning light;
- golden-hour warmth;
- soft overcast light;
- light mist;
- quiet evening light.

**Avoid:**

- harsh midday contrast;
- dramatic cinematic lighting;
- neon colour;
- aggressive shadows.

---

## 9. Seasons

Every core World may have seasonal expressions. **The composition and place identity remain stable** — season is detail layered onto a fixed scene, never a redesign of it.

Season affects:

- foliage;
- ground detail;
- atmospheric colour;
- light;
- mist;
- small environmental details.

**Example — Quiet Trail:**

**Spring:** young leaves · fresh green · small blossom · morning moisture

**Summer:** fuller foliage · warmer light · deeper shadows · more flowers

**Autumn:** muted ochre · fallen leaves · lower sun · moss and warm stone

**Winter:** bare branches · pale grass · frost or mist · snow only when contextually appropriate

Seasonal variation belongs to every user. It is part of THIRTY's identity, not a Premium gate — see §12.

---

## 10. Daypart and Weather Mood

A World should adapt to when the user opens THIRTY.

**Daypart** can affect:

- light angle;
- sky tone;
- shadow length;
- warmth;
- visibility of the sun, moon or stars.

**Weather Mood** can affect:

- cloud cover;
- mist;
- ground tone;
- water reflection;
- subtle rain atmosphere.

Do not make the adaptation literal or noisy. The World should feel contextually appropriate without becoming a weather app — the goal is an atmosphere the user senses, not a data readout they parse.

---

## 11. Personal Growth

The World may evolve permanently through completed Circles. This must never use streak logic.

- Do not reward consecutive-day perfection.
- Do not remove growth when the user is absent.
- Do not show broken chains or failure states.

Use cumulative Circle milestones instead. Examples:

- flowers appear;
- a tree becomes fuller;
- a bench appears;
- a small stream develops;
- the landscape gains subtle detail.

These changes should be:

- slow;
- permanent;
- surprising;
- non-competitive;
- never announced through confetti or achievement pop-ups.

The user may simply notice that something has changed.

**Formal rule:**

> "The world grows through return, not perfection."

This is the direct extension of [Chapter 1 §7–8](../playbook/01-the-circle-manifesto.md#7-why-completion-matters-more-than-streaks) and [Chapter 4 §12](../playbook/04-product-decision-framework.md#12-things-thirty-will-probably-never-build) ("Manipulative streak systems... the single mechanic most tempting to reach for") into the World System specifically: a World that visibly regressed after an absence, or that displayed a broken-chain motif, would reintroduce exactly the ledger the Playbook already forbids — only rendered as scenery instead of as a counter.

Exact milestone numbers are not frozen in this v1.0 document. Treat exact thresholds as future product configuration (see §18).

---

## 12. Free and Premium

**Free users receive:**

- a complete World for every supported recommendation category;
- seasonal variation;
- daypart adaptation;
- permanent Personal Growth;
- the full visual identity of THIRTY.

**Premium may deepen the same World through:**

- subtle motion;
- richer atmospheric effects;
- smoother transitions;
- additional lighting variations;
- more detailed environmental layers;
- optional ambient sound;
- extra nuance within the same season or weather mood.

**Premium must not own:**

- the World itself;
- seasonal adaptation;
- the core progression;
- the emotional reward of growth.

**Formal rule:**

> "Free Worlds grow. Premium Worlds breathe."

This also preserves the existing Playbook principle, unaltered:

> Premium deepens. Premium never gates.

Every item above is a direct application of the [Premium Filter](../playbook/04-product-decision-framework.md#5-the-premium-filter): would the free World still feel complete without Premium? Yes — a free user experiences the same Place, the same seasons, and the same permanent growth as a Premium user. What Premium adds is texture on top of a whole thing, never the pieces that make it whole.

---

## 13. First Breath Relationship

The World System connects to The First Breath — THIRTY's existing Home reveal ritual — as follows.

**Canonical sequence** *(reconciled 2026-08-06 — see Version History, v1.0.2. This supersedes the symbol-led sequence this section stated from 2026-08-04, following [THIRTY_SYMBOL.md v2.0](../brand/THIRTY_SYMBOL.md#status-update--first-breath-is-now-wordmark-led-v20)'s explicit direction change: First Breath is now wordmark-led, not symbol-led. The step order itself — brand mark, then Circle opening, then World — is unchanged; only what appears at steps 2–4 changed.)*:

1. The closed Circle is present.
2. The stable THIRTY wordmark appears inside it.
3. The wordmark remains briefly and completely still.
4. The wordmark fades out completely.
5. The Circle opens.
6. The selected World appears.
7. Home content follows through the existing reveal hierarchy.

The wordmark receives no heartbeat or scale animation — a deliberate departure from the symbol-led sequence's single restrained pulse, reasoned in full in [THIRTY_WORDMARK.md §4](../brand/THIRTY_WORDMARK.md#4-motion-relationship): a horizontal wordmark depends on stable letterforms for clarity, and stillness communicates presence without risking the moment feeling performative.

**The THIRTY wordmark itself remains stable. It must not be seasonally redrawn.**

Seasonal variation belongs entirely to the World revealed at step 6:

- background atmosphere;
- light;
- subtle environmental detail.

It never belongs to the wordmark at steps 2–4. The wordmark carries no seasonal, daypart, weather, World, or Premium variation of any kind — see [THIRTY_WORDMARK.md](../brand/THIRTY_WORDMARK.md) for the full wordmark direction, including its relationship to the Circle and its motion requirements. [THIRTY_SYMBOL.md](../brand/THIRTY_SYMBOL.md) remains the record of the superseded standalone-symbol direction, retained for a possible future, separate brand context — it no longer governs First Breath.

**Formal rule:**

> "The brand introduces the ritual, then steps aside."

**No haptic during The First Breath.** Haptics remain reserved for exactly the two moments [Chapter 2 §5](../playbook/02-circle-experience-system.md#5-haptic-principles) already names:

- Start Circle;
- Circle Closed.

---

## 14. Continuity Through the Experience

The selected World should remain consistent throughout one daily Circle journey:

```
Home → Activity Card → Circle Session → Circle Closed → optional Reflection context
```

Do not replace the World between stages. The World may subtly evolve (§9–§11), but it remains recognisably the same place. This creates continuity and reduces the feeling of moving through unrelated app screens — the visual counterpart of [Chapter 2 §1](../playbook/02-circle-experience-system.md#1-introduction)'s standing test: not "does this screen work," but what a person carries with them after they've stopped looking at it.

---

## 15. Walking World v1

The first fully defined reference World.

**Category:** Walking
**Intent:** More Energy
**Working place name:** Quiet Trail *(the name must remain time- and season-neutral, per §4)*

**Emotional promise:**

> "An open place that quietly invites you forward."

**Circle Hero composition:**

- soft sky;
- distant rolling hills;
- one organic tree;
- winding path;
- light atmospheric depth;
- two or three varied birds;
- restrained vegetation;
- no person.

**Activity Card companion:**

- same tree;
- same path;
- same horizon;
- simplified into elegant line art;
- much less detail;
- one restrained accent colour.

**Session expression:**

- same World;
- minimal meaningful motion;
- optional progress reflected through atmosphere later.

**Completion expression:**

- same World;
- slightly warmer or clearer;
- never celebratory.

---

## World DNA

Every World should eventually have a compact identity profile — a single reference summarising its defining facts, useful to designers, developers and future content reviews alike:

- **Name**
- **Emotion**
- **Primary Activity**
- **Primary Colours**
- **Dominant Shape**
- **Hero Focus**
- **Card Focus**
- **Primary Light**
- **Movement**
- **Growth Elements**

**Example — Quiet Trail**

| Field | Value |
|---|---|
| Name | Quiet Trail |
| Emotion | Invitation |
| Primary Activity | Walking |
| Primary Colours | Circle Sage, Mist Sage, Warm Stone, Cream |
| Dominant Shape | Winding path through rolling hills |
| Hero Focus | One organic tree on a distant hill, path winding toward it |
| Card Focus | Same tree, same path, same horizon, simplified to line art |
| Primary Light | Diffuse morning light, soft sunrise atmosphere |
| Movement | Minimal — a few birds, subtle atmospheric drift; never game-like |
| Growth Elements | Flowers appearing along the path, the tree becoming fuller, a bench appearing over time |

This is the only World DNA profile defined in v1.0 — no additional Worlds are introduced here (see §16).

---

## 16. Future Reference Worlds

Brief placeholders only — not full specifications. Walking (§15) is the only fully defined reference World in v1.0.

**Meditation:** Still Lake

**Reading:** Reading Nook

**Stretching:** Open Room or Open Meadow — final naming unresolved.

---

## 17. Architectural Implications

This section is conceptual, not code-specific — folder structures, class names, and Flutter APIs belong in a future implementation task or ADR, not here.

Future implementation should separate:

- Category;
- Place;
- Season;
- Daypart;
- Weather Mood;
- Personal Growth;
- Premium Atmosphere.

The Home screen must not hardcode Walking visuals. Illustration selection must derive from the current recommendation and World configuration, not from a fixed reference to one category's illustration — the same principle already established for the recommendation-to-illustration lookup, extended here to cover every additional dimension in §3.

---

## Future Expansion

The World System is intentionally designed to scale beyond what is defined in this v1.0 draft. Possible future extensions may include:

- additional Places per Category;
- richer seasonal variants;
- regional flora;
- accessibility variants;
- richer atmospheric variation;
- new recommendation categories.

None of these are defined here. This section states only that the architecture described in §3 intentionally leaves room for this kind of growth, so that adding to it later is an extension of the system, not a redesign of it.

---

## 18. Non-Goals for v1.0

This document does not yet define:

- exact milestone numbers;
- exact location or weather data sources;
- GPS use;
- final illustration assets;
- final animation durations;
- audio catalogue;
- all recommendation categories;
- implementation architecture;
- production rendering technology;
- exact Premium pricing or entitlements.

These are not resolved silently. Each is listed here as an explicit future decision, to be made — and checked against this document and the Playbook — when it becomes necessary, not assumed in advance.

---

## 19. Review Checklist

Before a new World ships, it should be able to answer these honestly:

- Does it belong to the recommendation?
- Can users imagine themselves there?
- Does it avoid idealised people?
- Does the Circle version create emotion?
- Does the Card version provide context?
- Are both recognisably the same place?
- Does it work across seasons?
- Is the name time-neutral?
- Can it evolve without streaks?
- Is the free version complete?
- Does Premium only deepen it?
- Does it remain calm and unmistakably THIRTY?

---

## Document Relationships

- **The [Playbook](../playbook/README.md)** governs philosophy — why THIRTY looks, feels, and behaves the way it does, and whether a proposed feature belongs in THIRTY at all.
- **[DESIGN_SYSTEM.md](../DESIGN_SYSTEM.md)** governs exact UI tokens — what a color, spacing, radius, or type value *is*.
- **This document, the World System,** governs illustrated environments, variation and progression — what a World *is*, how it varies, and how it may grow.
- **A future Motion Language** will govern precise movement.
- **A future implementation ADR** may govern technical architecture.

None of those documents is modified by this one. Where a future decision in any of them would require contradicting a claim made here, that contradiction is resolved deliberately and explicitly — never by quietly overriding one document with another.

---

## Version History

### v1.0.2 — 2026-08-06

- Reconciles §13's First Breath sequence with [THIRTY_SYMBOL.md v2.0](../brand/THIRTY_SYMBOL.md#status-update--first-breath-is-now-wordmark-led-v20)'s explicit direction change: First Breath is now wordmark-led, not symbol-led. A standalone THIRTY symbol is no longer required for First Breath.
- Restates steps 2–4 of the canonical sequence around the THIRTY wordmark (appears, remains still, fades out) rather than the symbol (appears, heartbeat, fades out). The step order itself — brand mark, then Circle opening, then World — is unchanged from v1.0.1.
- States explicitly that the wordmark receives no heartbeat or scale animation, and cites [THIRTY_WORDMARK.md §4](../brand/THIRTY_WORDMARK.md#4-motion-relationship) for the reasoning.
- Adds a cross-reference to the new [THIRTY_WORDMARK.md](../brand/THIRTY_WORDMARK.md) specification (Draft v0.1), now the authority for what appears at steps 2–4.
- Retains the cross-reference to [THIRTY_SYMBOL.md](../brand/THIRTY_SYMBOL.md), now recorded as the superseded-for-First-Breath, dormant standalone-symbol direction rather than the active one.
- No other section changed; no load-bearing claim outside §13 altered.

### v1.0.1 — 2026-08-04

- Reconciles §13's First Breath sequence with the approved Home implementation: the Circle now opens before the selected World appears (previously stated in the opposite order, an inconsistency surfaced during First Breath v2 discovery).
- Restates the sequence as the canonical seven-step form: closed Circle, symbol appearance, heartbeat, symbol fade-out, Circle opening, World appearance, Home content reveal.
- Clarifies that seasonal/daypart/weather/World/Premium variation belongs only to the World step, never to the symbol.
- Adds a cross-reference to the new [THIRTY_SYMBOL.md](../brand/THIRTY_SYMBOL.md) specification (Draft).
- No other section changed; no load-bearing claim outside §13 altered.

### v1.0

- Initial approved version.
- Approved after editorial review.
- Establishes the official THIRTY World System.
- Future modifications require an explicit design decision or ADR.

---

## Ownership

**Owner**

THIRTY Product Design

**Review Process**

WORLD_SYSTEM.md is a foundational design document.

Changes must only be made through an explicit design decision, documented ADR, or approved product review.

Implementation work must follow this document rather than redefine it.

---

*This is v1.0.2 of the THIRTY World System, in Approved status. It builds on the [THIRTY Playbook](../playbook/README.md), [BRAND_BOOK.md](../BRAND_BOOK.md), and [DESIGN_SYSTEM.md](../DESIGN_SYSTEM.md), and contradicts none of them. It governs illustrated environments, variation and progression; it does not replace the Playbook's authority over product philosophy, nor the Design System's authority over token values. §13's First Breath sequence is wordmark-led as of v1.0.2 — see [THIRTY_WORDMARK.md](../brand/THIRTY_WORDMARK.md).*
