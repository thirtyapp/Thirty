# THIRTY Playbook
## Chapter 4 — Product Decision Framework

*This chapter builds on [Chapter 1 — The Circle Manifesto](01-the-circle-manifesto.md), [Chapter 2 — Circle Experience System](02-circle-experience-system.md), and [Chapter 3 — Circle Design Language](03-circle-design-language.md). It does not repeat their philosophy; it turns that philosophy into a framework for deciding what THIRTY becomes. Where this chapter is silent, Chapters 1–3 govern.*

*This chapter also does not replace [recommendation-philosophy.md](../product/recommendation-philosophy.md), [decision-framework.md](../product/decision-framework.md), or the eight product ADRs. Those documents remain the authoritative, detailed governance of one specific system: how THIRTY constructs a daily recommendation. This chapter operates one level above them — it is the governance of everything, including that system, at the altitude of "should this exist at all." Several existing ADRs are, by this chapter, formally elevated from a single recorded decision into a standing filter that applies to every future feature, not only to recommendations:*

- *ADR-001 (the 30-minute promise may never quietly drift) becomes the core of the [Circle Filter](#3-the-circle-filter)'s "does it help today's ritual" test.*
- *ADR-007 (Premium never blocks the core loop) becomes the [Premium Filter](#5-the-premium-filter) in full.*
- *ADR-002, ADR-003, ADR-004, ADR-005, and ADR-008 (explainability, success over perfection, optional data, intent before activity, learning without judgment) together become the substance of the [AI Filter](#6-the-ai-filter).*

*Nothing here contradicts those documents. Where this chapter generalizes a rule that an ADR wrote narrowly for recommendations, that generalization is named as such, not silently assumed.*

---

## 1. Introduction

A product is not defined by its feature list. It is defined by the shape of everything that was proposed, considered seriously, and declined. Any team can add a feature that looks reasonable in isolation — that is the easy direction, and it is available every single day, for years, without ever making one decision that looks wrong on its own. Nobody erodes a product's identity with one bad choice. It erodes through hundreds of individually defensible ones, each of which made sense given the meeting it was made in.

Focus is not a starting posture that a product has and then keeps by default. It is a discipline, practiced identically on the easy days and the tempting ones — and it is tested hardest not by obviously bad ideas, but by good ones that simply don't belong. A well-built engagement loop, a competitor's popular feature, a clever growth mechanic — these are not failures of judgment when someone proposes them. They are the normal output of talented people solving the problem they were asked to solve. The discipline is remembering to ask a different question before building it: not "would this work," but "should this be part of THIRTY."

This chapter exists to make that second question answerable the same way, by anyone, at any point in the company's life — not by relitigating the Manifesto every time, but by running each proposal through a small set of filters built from it.

## 2. The Golden Product Question

Every product decision in THIRTY begins with one question:

**"Does this strengthen the daily Circle?"**

This is the Brand Book's Golden Rule (§1) — *does this feel calmer, simpler, and more human than the alternative* — applied specifically to product decisions rather than to tone or visual choices. It comes first because everything else in this chapter is a way of answering it more precisely, not a replacement for it. A feature that passes every filter below but fails this question has still failed. A feature that struggles with a filter below but obviously strengthens the Circle deserves a second, more careful look before it's declined.

"Strengthens" has a specific meaning here, and it excludes a tempting substitute: it does not mean *makes people use THIRTY more*. A feature that increases opens, sessions, or time spent, without making the daily thirty minutes feel more worth doing, has not strengthened the Circle — it has only made the product larger. The Circle is strengthened when closing it means more to the user than it did before, not when there are more reasons to look at the app around it.

## 3. The Circle Filter

For every proposed feature, ask:

- **Does it reinforce the Circle?** Or does it introduce a second thing to pay attention to, competing with the one daily ritual for meaning? A feature that is excellent on its own terms but pulls focus away from the Circle has added a competitor to the product's own center.
- **Does it reduce cognitive load?** Or does it hand the user one more thing to configure, interpret, or remember? THIRTY's value is proportional to how little a user has to think in order to receive it.
- **Does it create calm?** Or does it, even subtly, increase urgency, comparison, or self-monitoring? A feature can be genuinely useful and still fail this question — usefulness has never been sufficient on its own in THIRTY (Chapter 1 §6).
- **Does it help today's ritual?** This generalizes ADR-001: THIRTY's core promise is one focused investment of about thirty minutes, today. A feature that quietly extends the product's real center of gravity beyond that — a longer program, a multi-day plan the user must track, a system that only pays off over weeks — needs an explicit, transparent reason to exist, the same way ADR-001 requires for recommendations specifically.
- **Does it deepen meaning?** Or does it add volume — more data, more options, more content — without making the existing ritual feel more understood or more worth doing? Depth and volume are frequently confused; this question exists to keep them separate.
- **Does it respect the user's attention?** Attention spent on THIRTY should feel like it was spent on the user's own behalf. A feature that asks for attention primarily to benefit a metric, a growth loop, or a business goal fails here, regardless of how it is framed to the user.
- **Does it fit our philosophy of beginning again?** Nothing may punish absence, track streaks, or make tomorrow's circle depend on what happened to yesterday's (Chapter 1 §7–§8). A feature that reintroduces a ledger — even a gentle-looking one — does not fit, no matter how it is visually softened.
- **Would removing it make the experience stronger?** This is the filter's most reliable tool, because it strips away the sunk cost of having already designed something. If a feature's disappearance would be a relief rather than a loss, it was never earning its place.

A feature does not need a perfect score on every question to proceed — some are more decisive than others depending on what's being proposed. But a feature that fails the last question, or fails "does it fit our philosophy of beginning again," should not proceed regardless of how well it answers the rest.

## 4. The Calm Filter

- **Less is better.** Every addition has a cost that isn't visible in the feature itself: the cost of everything around it becoming slightly less clear. That cost accumulates silently and is rarely subtracted back out later — which is why it must be weighed at the moment of addition, not after the fact.
- **Silence is valuable.** A moment where the product says or shows nothing is not a gap to be filled — it is frequently the correct, finished state (Chapter 2 §6, Chapter 3 §5). Treat the impulse to add something to a quiet moment with suspicion, not enthusiasm.
- **One action is stronger than many.** A single, clear thing to do carries more weight than several options presented at once, because choice itself has a cost the options rarely advertise. THIRTY is more persuasive offering one right thing than offering three good ones (Chapter 2 §7, Chapter 3 §8).
- **Avoid visual and cognitive competition.** Nothing should ask for the same attention the Circle is asking for. Two important things on a screen are not twice as valuable — they are usually a signal that one of them shouldn't be there (Chapter 3 §2).
- **Avoid urgency.** Urgency produces short-term action and long-term fatigue. THIRTY is built for a relationship measured in years, not for a single session's conversion — manufacturing urgency trades the second for the first.
- **Avoid noise.** Noise is anything present that doesn't change what the user understands or can do. It is the most common failure mode in mature products, because noise rarely arrives all at once — it accumulates one reasonable-seeming addition at a time (Chapter 3 §2).

These are not rules against specific features. They are a standing bias, applied every time a choice could go either way: when unsure, choose the version with less in it.

## 5. The Premium Filter

- **Does Premium deepen the ritual, or does it merely gate functionality?** This is ADR-007 (Chapter 1 §9) restated as a question to ask of every Premium idea, not only the ones proposed at launch. If a feature's Premium framing can be swapped for "unlock" without changing its meaning, it is gating, not deepening.
- **Would the free version still feel complete without this?** Completeness is not the same as generosity — the free Circle was never meant to feel like a trial. If removing a Premium feature from the mental picture of the free product would make that product feel unfinished, the feature was drawn from the core, not added beside it, and does not belong in Premium.
- **Does Premium increase understanding rather than complexity?** Circle Insights should make a user feel more known; Circle Coach should make guidance feel more personal; Circle Sessions should make the ritual feel more accompanied. None of them should require the user to learn a new system to receive that benefit.
- **Could this feature be explained as an addition, not a contrast?** If a Premium idea can only be pitched by first describing what free users are missing, it has already failed, regardless of build quality (Chapter 1 §9).
- **Does this deepen a relationship that already exists, or does it manufacture a new need in order to sell its resolution?** Premium should feel like more attention paid to something the user already valued for free — never like a problem introduced for the purpose of offering its solution.

## 6. The AI Filter

THIRTY's AI exists to make one decision easier — what to do with today's thirty minutes — not to become a second product living inside the first. Every proposed AI feature should be evaluated against what kind of relationship it creates with the user's own judgment:

- **Does it create understanding, or does it create dependency?** A good AI feature leaves the user better able to make sense of their own health over time. One that makes the user need the AI more, without understanding more themselves, has optimized for engagement rather than for the user.
- **Does it replace reflection, or does it invite it?** THIRTY's Reflection Principles (Chapter 2 §8) hold that reflection belongs to the user. An AI feature that pre-fills, summarizes, or scores that reflection on the user's behalf has quietly taken something away from them while appearing to help.
- **Does it speak too much?** THIRTY's AI is restrained by the same personality that governs every part of the product (Brand Book §7): present, not intrusive. An AI that comments on every action is not more helpful for being more talkative — it is simply louder.
- **Does it reduce thinking, or does it reduce the need for thinking?** These sound similar and are opposite outcomes. THIRTY should make a decision easier to make well; it should not make the decision disappear from the user's own sense of agency over their health.
- **Does it respect the user's autonomy?** The user chooses; the AI suggests. This ordering, already load-bearing for the recommendation engine (ADR-005: intent before activity), generalizes to every AI feature THIRTY ever builds — none of them may be structured so the AI's suggestion effectively becomes the decision, with the user's role reduced to acceptance.
- **Can it be explained in plain language before it is shown?** Carried forward directly from ADR-002: an AI feature whose reasoning cannot be stated simply to the user is not ready to ship, regardless of how well it performs.
- **Does it treat a skipped, ignored, or adjusted suggestion as information rather than as a verdict on the user?** Carried forward directly from ADR-008. Any AI feature that scores, ranks, or silently profiles a user's discipline, motivation, or consistency has crossed a line no future implementation is permitted to cross.

AI is not added to THIRTY because a capability becomes available. It is added because a specific, named user difficulty becomes easier to bear — and every AI feature should be able to name that difficulty in one sentence before a single line of it is designed.

## 7. The Notification Filter

Should this feature notify the user? The answer is arrived at through judgment, not a rule, because the same message can be a kindness at one time of day and a pressure at another. A few honest questions get closer to the right answer than any fixed policy could:

- **Why does this need to interrupt someone, right now, from outside the product?** If the honest answer is "so they come back," that is not yet a good enough reason.
- **Would silence be better?** Most days, for most users, it is. A notification has to earn the exception; the default is that today's Circle can wait for the user to arrive on their own.
- **Does this notification invite, or does it pressure?** An invitation can be declined without cost. A notification that implies the user is behind, missing something, or letting a number down has crossed from invitation into pressure, regardless of how gently it's worded.
- **Would the user thank us for receiving it?** Not tolerate — thank. If the honest answer is "they'd probably ignore it" or "they might find it naggy," that answer is the decision.

This is deliberately a set of questions rather than a schedule of allowed notification types, because a rulebook invites the search for a technically compliant exception. Judgment, applied consistently through these questions, does not.

## 8. The Marketing Filter

Should this feature exist because a competitor has it? This is one of the most common ways a calm product quietly stops being one — not through a single bad decision, but through a long series of reasonable-sounding responses to what everyone else appears to be doing.

- **Feature envy** — the sense that THIRTY looks incomplete next to a competitor's list of capabilities — is not evidence that a feature belongs in THIRTY. A shorter list, chosen on purpose, is not a weaker product; it is a different bet, and it is the bet THIRTY has already made (Chapter 1 §2).
- **Trend chasing** solves for looking current for a season and looks dated the moment the trend passes. THIRTY is built to solve for looking correct in ten years (§9), which is a different, slower, and more demanding target than looking current today.
- **Competitive pressure** is real and should inform awareness, not direction. Knowing what others build is useful context; letting it set THIRTY's roadmap outsources the company's judgment to whichever competitor moved most recently.

THIRTY is guided by its own philosophy, not by the market's current shape, because the market's current shape is, by definition, temporary. A feature earns its place by passing the Circle Filter — never by the fact that its absence is starting to feel conspicuous.

## 9. The Longevity Filter

- **Will this still make sense in ten years?** Not "will it still function" — will the reasoning behind it still hold once the technology, the design trends, and the competitive landscape around it have completely changed.
- **Does this follow timeless human behavior, or current digital fashion?** THIRTY is built on how people form a daily habit and recover from missing one — facts about people that were true a century ago and will be true in another one. A feature justified only by what today's interfaces tend to do has built on the wrong foundation.
- **Would Dieter Rams approve?** Would this feature exist if the standard was "as little design as possible," applied honestly rather than as a slogan?
- **Would Apple remove it?** Not "would Apple build it" — the harder and more useful question is whether a team optimizing relentlessly for simplicity would have cut this in review.
- **Would it still fit the Circle in 2035?** If the honest answer requires imagining a different product with a different center, the feature doesn't belong in this one, however well it might work today.

## 10. Feature Review Matrix

Every proposed feature can be checked against ten dimensions: Circle, Calm, Clarity, Meaning, Simplicity, Longevity, Accessibility, Premium Philosophy, Trust, Emotional Impact.

The matrix is used qualitatively, not numerically. THIRTY does not average these into a score, because a score implies a precision the judgment doesn't actually have — the same reasoning that keeps the recommendation engine from ever manufacturing false certainty (decision-framework.md §9) applies here. Instead, each dimension is rated simply as **Strengthens**, **Neutral**, or **Weakens**:

- A feature that **Weakens** any dimension needs that weakening explicitly discussed and consciously accepted before proceeding — never waved through because the average still looks fine.
- A feature that is **Neutral** everywhere and **Strengthens** nothing has not yet justified its own existence, regardless of how well it's built.
- A feature must **Strengthen** the Circle dimension specifically to proceed. No combination of gains elsewhere in the matrix substitutes for this one.

The matrix's purpose is not to produce a verdict on its own — it is to make the tradeoffs of a decision visible in one place, so that "this weakens Trust but strengthens Meaning" is a sentence the team actually says out loud, rather than a tradeoff quietly absorbed into a launch.

## 11. Product Review Checklist

Before implementing any feature, every designer, developer, and product manager should be able to answer these:

- Does this strengthen the Circle?
- Does this remove friction, or does it add friction somewhere the user won't notice until they hit it?
- Is there a simpler solution that achieves the same purpose?
- Can something be removed instead of adding this?
- Would a first-time user understand this without an explanation?
- Would this still feel elegant after a hundred uses, or does its charm depend on novelty?
- Does this create guilt, in any form, at any point in the flow?
- Does this create hope — specifically, does it leave the door open for tomorrow regardless of how today went?
- If this shipped and nobody noticed it, would that be a failure, or would it mean the feature did its job quietly?

A feature that cannot be answered honestly and well on all of these is not ready, no matter how complete it is technically.

## 12. Things THIRTY Will Probably Never Build

This list exists to make refusal easy to recognize in the moment, not to criticize the products that build these things well for their own goals. Each of the following is a legitimate tool for growing engagement — and each conflicts with what THIRTY has decided to be.

- **Aggressive gamification** — points, levels, and mechanics borrowed from games — asks users to care about the system's abstractions instead of their own thirty minutes. THIRTY's reward is the completed Circle itself, not a layer built on top of it (Chapter 2 §10).
- **Leaderboards** turn a personal ritual into a comparison with strangers. THIRTY measures a user only against their own closed circles (Chapter 1 §7); a leaderboard has no honest place inside that.
- **Fear-of-missing-out mechanics** manufacture urgency out of absence — the exact feeling THIRTY's daily practice of starting again exists to remove (Chapter 1 §8).
- **Manipulative streak systems** attach a penalty to every good day by making it retroactively erasable. This is the most explicit refusal in the whole Playbook, stated first in Chapter 1 §7 and repeated here because it is the single mechanic most tempting to reach for when growth numbers look soft.
- **Artificial urgency** — countdowns, limited-time framing, disappearing offers — produces short-term action at the cost of the long-term trust THIRTY depends on (§7 above; VISION.md, "trust over growth tricks").
- **Reward loops** engineered around variable, unpredictable payoffs are a known mechanism for compulsive engagement. THIRTY's payoff — a completed circle — is deliberately the same, honest size every day; it is not intermittent, and it is not designed to be craved.
- **Excessive badges** turn completion into collection. THIRTY's Circle already is the marker of completion; a badge on top of it doesn't add meaning, it dilutes the one marker that already carried it.
- **Dark patterns** — confirmshaming, hidden cancellation flows, consent obtained through confusion — are incompatible with a Brand Promise that requires every interaction to leave the user calmer, not merely more converted (Brand Book §5).
- **Advertising disguised as wellbeing content** — sponsored recommendations framed as personal guidance — would compromise ADR-002's requirement that a recommendation's reasoning be explainable in plain language. An explanation that has to omit "because we were paid to suggest this" is not an honest explanation.

None of these are refused because they don't work. They are refused because they work by asking something of the user that THIRTY has already promised never to ask.

## 13. Closing Statement

Every product decision THIRTY ever makes is, underneath its specific details, the same decision: whether this choice protects the daily Circle, or slowly trades it for something else — more engagement, more data, more revenue, more features — that was never what THIRTY was for. The company will exist for a long time only if the Circle stays worth closing every single day, for reasons the user could explain simply if asked. Protecting that is not one department's job. It is the standard every decision answers to, for as long as THIRTY exists.

---

*This is Chapter 4 of the THIRTY Playbook, built on Chapters 1–3. It governs product decisions at the level of "should this exist"; [recommendation-philosophy.md](../product/recommendation-philosophy.md), [decision-framework.md](../product/decision-framework.md), and the product ADRs remain authoritative for how the recommendation engine specifically resolves conflicts between signals. Future chapters may extend this framework into new domains; none may contradict what is written here or in Chapters 1–3 without a deliberate, explicit decision to supersede it, in the same spirit as an ADR.*
