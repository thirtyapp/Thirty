# THIRTY Playbook
## Chapter 3 — Circle Design Language

*This chapter builds on [Chapter 1 — The Circle Manifesto](01-the-circle-manifesto.md) and [Chapter 2 — Circle Experience System](02-circle-experience-system.md). It does not repeat their philosophy; it gives that philosophy a visual grammar. Where this chapter is silent, Chapter 1 and Chapter 2 govern.*

*This chapter also does not replace Brand Book §11–§19, or the color, type, spacing, radius, and shadow tokens already implemented in THIRTY's theme. It explains the reasoning those decisions already embody, and names the specific places where they should grow to fully express the Circle. Existing values are referenced, never reprinted or redefined here — the token files remain the single source of truth for what a value *is*; this chapter is the source of truth for *why*.*

---

## 1. Introduction

Visual style is a set of choices — a palette, a typeface, a corner radius. Visual language is the reasoning that makes those choices feel inevitable rather than arbitrary. A style can be copied in an afternoon. A language has to be understood, because it keeps producing the right answer even in situations its original author never considered.

THIRTY needs a language, not a style, for a specific reason: the Circle is not one screen's decoration, it is the product (Chapter 1 §3). Every visual decision — a spacing value, a shadow, a typeface weight — either reinforces that one object or quietly competes with it. There is no neutral visual choice in THIRTY. A screen that is beautiful on its own terms but doesn't make the Circle feel more present has still made the wrong choice.

This chapter exists so that a decision made in a component nobody has designed yet — a settings row, an error state, a future platform — can still be checked against the same visual reasoning used everywhere else. The goal is not uniformity for its own sake. It is that THIRTY should be recognizable by its restraint before it is recognizable by any specific color or shape.

## 2. Visual Philosophy

**Calm before excitement.** A visual choice that makes a screen more exciting at the cost of making it feel less settled has optimized for the wrong emotion. Excitement asks for attention now; calm earns trust over time. THIRTY is built for the second kind of relationship (Chapter 1 §6).

**Simplicity over decoration.** Every visual element should be traceable to a purpose — communicating state, guiding attention, or creating necessary separation. An element that exists only because a screen "felt empty" has solved the wrong problem; an empty screen is frequently correct (§5).

**Whitespace creates focus.** Attention is finite, and a crowded screen spends it on deciding where to look before the user has looked at anything real. Space is what removes that first, invisible cost.

**Hierarchy through restraint, not through volume.** The common way to make something stand out is to make it bigger, louder, or brighter. THIRTY's way is to make almost everything else quieter, so the one thing that matters doesn't have to compete for the role.

**Premium through consistency, not through richness.** Luxury design, historically, often signals value through ornament — texture, gilding, visual density. THIRTY signals value the way a well-made, quiet object does: nothing rattles, nothing is inconsistent from one use to the next, and every detail was clearly considered even though most of them are invisible. Consistency is what makes a product feel expensive without ever feeling decorated.

**Beauty through reduction.** The measure of a good screen in THIRTY is not what was added to make it appealing, it's what could be safely removed without losing meaning. What survives that removal is what was actually necessary — and necessity, rendered with care, is what THIRTY considers beautiful.

## 3. The Circle

**Purpose.** The Circle is the single object THIRTY exists to fill and close, once a day. Every other visual element on a screen involving the Circle exists in a supporting role to it — never beside it as an equal, never above it in visual weight.

**Visual hierarchy.** On any screen where the Circle appears, it is the first thing the eye should find and the last thing it should leave. Nothing on that screen may be sized, colored, or positioned in a way that competes with it for that first glance.

**Proportions and presence.** The Circle should always feel generously sized relative to what surrounds it — not because bigger reads as more important by default, but because a ritual object deserves room, the way a person doesn't rush a meaningful gesture into a corner. A Circle rendered small enough to be mistaken for a UI control has lost the thing that made it a Circle rather than a progress bar.

**Open.** An open Circle should read as potential, not as absence. It has weight and presence on the screen even with nothing in it yet — an empty Circle is a beginning being held, not a gap waiting to be filled in by something else.

**Filling.** A filling Circle should feel like it is accumulating something the user did, not counting down something the user is losing. The direction of feeling matters as much as the direction of the arc: every state that reads to the eye as *gain* is correct; anything that could be read as *depletion* — even accidentally, through color or motion — is a violation of this chapter regardless of how it was intended.

**Closed.** A closed Circle should feel whole rather than emphatic. It is the visual resolution of the day, not a trophy. Nothing about how it looks should ask to be admired — it should simply, quietly, be finished (Chapter 2 §3).

**Where the Design System should evolve.** THIRTY's implemented Circle today has one presentation: one context, one size, one stroke weight, colored by borrowing the interface's general primary and border colors. That was the right first step, and none of it is wrong — but as the Circle now appears in more places (a hero moment on Home, a smaller reference in history, a mention inside Coach), it deserves its own deliberate scale, not an ad-hoc resize of a single value, and its own named color role, not a borrowed one. The Circle is the product; it should be the one element in the system that is never implicitly derived from something else's tokens. This is a natural next step for the Design System, not a correction of a mistake.

## 4. Typography

Typography in THIRTY exists to be read effortlessly and then disappear from notice — it is not a place for the product's personality to perform. A calm product does not need a distinctive typographic voice; it needs one that gets out of the way of what's actually being said.

- **Large titles create breathing room**, not emphasis for its own sake. Size at the top of a screen tells the eye "start here, and there isn't much more to find" — it should always be telling the truth about how little there is to read.
- **Body text supports; it does not compete.** Its role is to be legible at a comfortable, unhurried pace. If reading it ever feels like effort, the type is the problem, not the reader.
- **Labels disappear when unnecessary.** A label that restates what's already obvious from context or position is noise wearing the shape of information. Labels earn their place only where genuine ambiguity would exist without them.
- **One reading path per screen.** A user should never have to decide where to start reading. If a screen has two equally weighted places the eye could land, its typographic hierarchy hasn't been finished.
- **Minimalism in text is a form of respect.** Every sentence a user has to read is a small amount of their attention spent. THIRTY should feel confident enough to say less, trusting that less, said clearly, is more persuasive than more, said carefully.

Emotionally, typography in THIRTY is meant to feel like being spoken to by someone unhurried and sure of themselves — never like being addressed by a system trying to hold attention through size or emphasis.

**Where the Design System should evolve.** The existing type scale was built, correctly, as a small, disciplined set of styles for titles, body copy, and labels. It does not yet have a dedicated style for the one kind of text the Circle Philosophy already singles out as different: the numbers — minutes, progress — that the Brand Book identifies as often the most important information on a screen. A number inside or beside the Circle is not a label and not a heading; it deserves its own considered treatment (weight, spacing, figure alignment) rather than borrowing the nearest heading style by default.

## 5. Whitespace

Whitespace in THIRTY is not the residue left after content is placed — it is placed first, deliberately, the way silence is composed into music rather than left over from it.

- **Spacing** creates the rhythm of a screen: which elements belong to the same thought, and which are separate ones. Consistent spacing is what lets a user feel structure without consciously noticing there is one.
- **Balance** means no single region of a screen should feel dense while another feels sparse for no reason relating to importance. Visual weight should track meaning, not just fit.
- **Silence**, rendered visually, is simply the space around the one thing that matters. A screen with one clear focal point and generous space around it is the visual equivalent of Chapter 2's audio silence — the absence is the message, not an oversight.
- **Breathing room** around the Circle in particular should never be treated as available space to fill with something else "while we have the room." Having room is not an invitation to use it.
- **Focus** is the actual product of whitespace. Every additional element placed on a screen taxes the attention available for the one element that was supposed to matter.

Empty space should be preferred over additional UI whenever the alternative is explaining something that a well-designed default should have made unnecessary to explain in the first place.

## 6. Color Philosophy

Color in THIRTY carries meaning before it carries mood. Its first job is to tell the user what state something is in; only after that job is satisfied does it get to also make the screen feel considered.

- **Meaning.** A color should be traceable to a reason. If a color's presence can't be explained by what it communicates, it shouldn't be there.
- **Calm.** The dominant colors in any THIRTY screen should recede, not perform. A screen that is calm in its base tones can afford one moment of real color to mean something specific — a screen that is loud everywhere has nowhere left to put emphasis.
- **Contrast** exists to direct attention on purpose, not by accident. Where contrast is high, it should be high because that is where the user's eye is meant to land.
- **Focus.** Color is one of the strongest tools THIRTY has for saying "look here" — which is exactly why it must be spent rarely. A product that colors everything has nothing left that reads as important.
- **Premium restraint.** A wide, expressive palette signals that a product wants to be noticed. A narrow, consistent one signals that a product already trusts what it's built. THIRTY's restraint in color is a statement of confidence, not a limitation.
- **Accessibility** is not a constraint layered on top of this philosophy — it is this philosophy applied honestly. A color relationship that only works for some users was never actually calm; it was only calm for the people it happened to work for.

Color should communicate state — progress, completion, an error that needs attention — far more often than it decorates. When a designer reaches for a new color, the right first question is not "does this look good here," it's "what would the user misunderstand if this were left neutral instead."

## 7. Cards

A card is a visual claim that says "these things belong together, and they are separate from what surrounds them." That claim should be true every time it's made, not applied automatically because a layout needed a container.

Cards are appropriate when information genuinely needs a boundary — grouping several related facts, separating one entry among many similar ones, or containing something a user might act on independently of the rest of the screen. Cards are not appropriate as a default wrapper for anything that could just as clearly sit directly on the page. A screen where everything lives in a card has cards that mean nothing, because the boundary no longer signals anything the surrounding space didn't already make clear.

Information should exist without a card whenever it is the primary subject of its screen — the Circle, a single headline stat, a primary message. Wrapping the one thing a screen exists to show inside a container built for grouping secondary things undersells it. The most important object on a screen should feel like it belongs to the whole page, not like it's been filed inside a box on top of it.

## 8. Buttons

- **Primary action** — the one thing the screen is asking the user to do. There should be exactly one candidate for this role per screen (Chapter 2 §7); if two actions seem equally primary, the screen has not finished being designed.
- **Secondary action** — available, but visually quieter, for anything worth offering without competing with the primary action for the first glance.
- **Destructive action** — rare, and never disguised as an ordinary choice. Its visual weight should reflect the seriousness of what happens if the user proceeds without reading carefully.
- **Disabled state** — used only when an action is genuinely unavailable, never as a way to discourage a choice the product would rather the user not make. A disabled button that could be enabled with information the user isn't being given is a design failure hiding behind a state.

THIRTY almost always has exactly one primary action because a ritual asks one thing of a person at a time. A screen with several equally weighted actions is asking the user to make a decision about what to decide — an extra, invisible task the product should have already resolved on their behalf.

## 9. Icons

Icons are used when a shape can be recognized faster than a word can be read — never as decoration for a screen that felt visually sparse without one. An icon that requires a label to be understood has failed at the one thing an icon is for; in that case, the label was doing the actual work, and the icon should be removed rather than kept alongside it as ornamentation.

Text is enough, and preferable, whenever the concept being represented doesn't already have a widely understood visual shorthand — inventing a new icon for an idea nobody will recognize on sight only adds a symbol the user has to learn. Icons explain; they do not decorate. If removing an icon from a screen changes nothing about what the user understands, it was never doing the job an icon is meant to do.

## 10. Navigation

Navigation in THIRTY should be felt as little as possible — the measure of good navigation is how rarely a user has to think about where they are or how to get somewhere else.

- **Bottom navigation**, where used, should stay small in the number of choices it offers. Every additional top-level destination is a small tax on the certainty of "where am I," paid on every single screen.
- **Navigation depth** should be shallow. A ritual that requires several layers of navigation to reach has already added more friction than thirty minutes of attention can absorb.
- **Progressive disclosure** — showing the next relevant choice only once it's relevant — keeps a simple product feeling simple even as it grows more capable underneath. Complexity is allowed to exist; it is not allowed to be visible before it's needed.
- **Keeping people oriented** matters more than surfacing more options. A user should always be able to answer "where am I, and how do I get back" without pausing to think about it.
- **Reducing decision fatigue** is the underlying goal behind all of the above. Every navigational choice removed on the user's behalf is attention preserved for the thirty minutes that actually matter.

## 11. Empty States

An empty state in THIRTY is never a dead end and never a quiet accusation. It communicates one of a small number of honest situations, and it communicates all of them the same hopeful way:

- **No data yet** reads as "nothing has happened here yet," not as a void needing to be justified.
- **First use** reads as an invitation — the calm opening described in Chapter 2 §2, not a form to complete before access is granted.
- **Waiting** reads as something in motion that the user doesn't need to watch, not as a delay to be anxious about.
- **Future content** reads as something coming, described plainly, without manufacturing anticipation the product then has to satisfy.
- **Missed days** are rendered exactly like any other empty space — quiet, neutral, without a broken visual motif, without color signaling failure. Chapter 1 §7 and §8 forbid the streak and the ledger; the empty state for a missed day is where that rule is most tempting to break visually, and where it must hold most firmly.

Nothing in an empty state should shame the user for arriving at it. Every empty state should carry, in tone and in visual treatment, the same quiet hope that governs the opening of a new Circle each day.

## 12. Premium Design

Premium should look like a deeper version of something the user already trusts, never like an advertisement placed inside a product they came to for calm (Chapter 1 §9).

- **Never loud.** No premium surface should visually announce itself more forcefully than the core experience around it.
- **Never gold.** THIRTY does not borrow the visual vocabulary of luxury or status — no metallic accents, no crowns, no badges implying the user has been elevated to a tier. That vocabulary belongs to a different kind of product, one built on status rather than calm.
- **Never intrusive.** Premium is never presented as an interruption of the free ritual — not as a modal blocking the day's Circle, not as a banner competing with it for space.
- **An invitation, not an advertisement.** The visual difference between free and Premium should read as "more depth is available here if you want it," not as "something has been withheld from you until now." The distinction is subtle to describe and unmistakable to feel — a user should never be able to point to a Premium surface and say it looked like a sales pitch.

## 13. Accessibility

Accessibility is not a compliance layer added after the calm design is finished — it is the same philosophy, tested honestly. A design that only feels calm for users with typical vision, hearing, or motor ability was never actually calm; it was only calm for the people it happened to already suit.

- **Contrast** must hold up on its own merits, not only in the ideal case. A palette this restrained has no room to also be one that fails to be read clearly by everyone.
- **Touch targets** should be generous enough that precision is never the price of using the product calmly. A target that requires careful aim reintroduces the exact friction whitespace and simplicity are meant to remove.
- **Motion sensitivity** must be respected by offering the calm, still alternative to any animation — for a product built on restraint, this should be the easiest accessibility commitment to keep, not the hardest.
- **Screen readers** should encounter the same clear, single reading path a sighted user experiences — the Circle's state, in particular, must always be describable in words as clearly as it's communicated visually.
- **Dynamic type** must be allowed to grow without breaking the one reading path per screen (§4) — a design that only works at one text size was never actually a system, only a single fixed picture of one.
- **Left- and right-handed use** should be considered in where primary actions are reachable, so ease of use isn't quietly assumed to belong to only one half of the population.

## 14. Visual Decision Framework

Before a visual decision ships, it should survive these questions honestly:

- Does this reduce mental effort, or does it add something to notice and interpret?
- Would removing this improve the experience, or only make the screen look less finished to the person who built it?
- Does this reinforce the Circle, or does it quietly compete with it for attention?
- Would this still feel modern in ten years, or does it depend on a trend that is already fading?
- Is this decoration, or is it communication? If it's decoration, can it be justified anyway — and if not, does it survive?
- Does this help today's ritual specifically, or does it serve a broader ambition the ritual doesn't need right now?
- Would a designer who values restraint over impression remove something here?
- Does this still feel calm on a screen used at the end of a hard day, not just in a clean design file?

## 15. Closing Statement

The first time someone opens THIRTY, they should not feel like they've entered an app. They should feel like they've been handed something already finished — quiet, considered, with nothing to configure and nothing demanding to be understood before it can be used. The Circle should be the first thing they see and the only thing they need to. Nothing about the moment should feel like a beginning full of decisions; it should feel like a beginning full of room.

---

*This is Chapter 3 of the THIRTY Playbook, built on [Chapter 1 — The Circle Manifesto](01-the-circle-manifesto.md) and [Chapter 2 — Circle Experience System](02-circle-experience-system.md). The color, typography, spacing, radius, and shadow values already implemented in THIRTY's Design System remain authoritative for what those tokens are; this chapter is authoritative for why they take the shape they do, and where that system should grow next to fully express the Circle. Future chapters may extend this visual language into new domains; none may contradict what is written here or in Chapters 1–2 without a deliberate, explicit decision to supersede it, in the same spirit as an ADR.*
