# THIRTY Playbook — Editorial Review

## Chapters 1–4, pre-v1.0 governance audit

*This is not a chapter. It is the editorial and governance review of [Chapter 1](01-the-circle-manifesto.md), [Chapter 2](02-circle-experience-system.md), [Chapter 3](03-circle-design-language.md), and [Chapter 4](04-product-decision-framework.md), performed before any further chapter is written. Its findings are corrections and consolidations to apply to the existing four chapters — it does not introduce new philosophy, and none of its recommendations should be read as Chapter 5.*

---

## 1. Internal Consistency

Two different kinds of repetition appear across Chapters 1–4, and they should be treated differently.

**Deliberate recurrence (keep).** Some principles are *supposed* to recur — they are the tests everything else is checked against, and each chapter applies them at its own altitude rather than duplicating them. "Does this strengthen the Circle" appears in Ch1 §11, Ch2 §11, Ch3 §14, and Ch4 §2/§3/§10/§11 — this is correct. A governing question that only appeared once would fail to govern. The same is true of "one primary action per screen" (Brand Book §11 → Ch1 §11 → Ch2 §7 → Ch3 §8 → Ch4 §4): each restatement is scoped to its own domain (a design principle, an interaction rule, a button spec, a decision filter) and, with one exception noted below, correctly cites the others rather than re-deriving them from scratch.

**Redundant explanation (fix).** The following are places where a principle is *independently re-explained*, rather than invoked and cited, and should be consolidated:

| Principle | Where it appears | Canonical source | What the others should do |
|---|---|---|---|
| Circle Lifecycle state names | Ch2 §3 defines *Open, Filling, Nearly Closed, Closed, Archived, Unopened*. Ch3 §3 independently uses *Empty state, Active state, Completed state* for what is the same underlying progression. | **Chapter 2 §3** — it is the dedicated lifecycle chapter. | Chapter 3 §3 should adopt Chapter 2's exact state names instead of a parallel set of synonyms. This is the most concrete inconsistency found in this review — see §2 below. |
| "Silence is valuable" | Fully explained in Ch2 §6 (audio) and Ch3 §5 (visual/whitespace) — these are legitimately two different domains and both should stay. Restated with no citation in Ch2 §10 (rule 3) and Ch4 §4. | **Chapter 2 §6** (audio) and **Chapter 3 §5** (visual) jointly — there is no single canonical source because silence has two distinct expressions. | Ch2 §10 rule 3 and Ch4 §4's "Silence is valuable" bullet should cite both, the way Ch4's neighboring "one action" bullet already cites Ch2 §7 and Ch3 §8. |
| Premium deepens, never gates | Independently explained in Ch1 §9 (naming/vocabulary), Ch2 §9 (the four concepts' felt experience), Ch3 §12 (visual treatment), Ch4 §5 (evaluation filter). | **Chapter 1 §9** — it is where the rule and its vocabulary (Circle Sessions/Insights/Coach) originate. | Each later chapter adds a genuinely different, non-redundant layer (experience, visual, evaluation) and should stay — but Ch3 §12 and Ch4 §5 open by re-deriving the "why" instead of citing Ch1 §9 the way Ch2 §9 already does. This is a citation gap, not a content duplication: the content earns its place, the missing pointer doesn't. |
| Experience Rules / Design Principles / Never-Build lists as freestanding claims | Ch1 §11 (6 items), Ch2 §10 (20 items), Ch4 §12 (9 items) are compressed, aphorism-style lists. Most items restate a principle explained fully elsewhere in the same or an earlier chapter, without a pointer back to where. | The full explanation, wherever it lives (see table above and the Canonical Principles list in §7). | These lists are valuable as quick-reference indexes and should be kept — but should read explicitly as indexes, not as sources. A light pass adding inline section pointers (some items already have them, e.g. Ch2 §10 rule... none currently do; Ch4 §4 items are inconsistent — two of six bullets cite, four don't) would remove the appearance of new claims where none are intended. |

No outright **conflicting** principles were found — nothing in Chapters 1–4 tells a future team to do the opposite of what an earlier chapter says. The issues above are consolidation and citation gaps, not contradictions.

## 2. Terminology Audit

A glossary does not yet exist. It should — see Editorial Recommendations (§8). Below is the audit that glossary should be built from.

| Term | Used consistently? | Canonical definition to adopt |
|---|---|---|
| **Circle** | Yes. Defined once, used identically everywhere: the daily unit of attention and the product itself, not the logo (Ch1 §3). | "The Circle: THIRTY's daily unit of attention — the product itself, not the app icon (Ch1 §3)." |
| **Circle states** (Open / Filling / Nearly Closed / Closed / Archived / Unopened) | **No** — see §1 above. Ch3 §3 uses a different, overlapping vocabulary (Empty / Active / Completed). | Adopt Chapter 2 §3's six state names as the only names used anywhere in the Playbook or the product. |
| **Ritual** | Yes. Defined once (Ch1 §4: something returned to on purpose, as opposed to a task), used consistently as the frame for the whole daily experience. | "A ritual is returned to because the returning has meaning, unlike a task, which is completed and removed (Ch1 §4)." |
| **Calm** | Yes. Rooted in Brand Book's Golden Rule and Brand Promise, elevated in Ch1 §6 and Ch1 §10, applied consistently as the dominant emotional target in every later chapter. | "Calm: the default emotional state THIRTY produces — measured by whether the user is less activated after an interaction than before (Ch1 §6, §10; Brand Book §5)." |
| **Completion** | Used in two related but distinct senses that are never explicitly distinguished: (1) the moment a single Circle closes (Ch2 §2, "Circle Completed"), and (2) the cumulative record of closed circles over time, deliberately never scored or chained (Ch1 §7). Not contradictory, but worth separating explicitly so a future implementation doesn't quietly build a "completion score" that violates the anti-streak rule. | Define both senses explicitly: "Completion (moment): a single Circle closing. Completion (record): the count of closed circles, each independent, never a streak or score (Ch1 §7)." |
| **Renewal** | **Used once, in passing, undefined** (Ch4 §12: "the exact feeling THIRTY's daily renewal exists to remove"). It was one of the seven meanings the Circle was originally said to represent, but Chapters 1–4 use synonyms instead — "starting again" (Ch1 §8, its actual section title), "beginning again," "a new circle." The word "renewal" itself is not established terminology. | Decide deliberately: either adopt "Renewal" as the formal name of Ch1 §8's concept (it currently has no single-word name, only the section title "The Philosophy of Starting Again"), or remove the stray usage in Ch4 §12 and treat "starting again" as the only sanctioned term. Leaving it as an undefined, single, incidental use is the one option that shouldn't stand. |
| **Reflection** | Yes. Defined once and precisely (Ch2 §8: invited, never required, never judges), referenced correctly elsewhere (Ch4 §6 cites Ch2 §8 directly). | "Reflection: an invitation the user may decline without consequence, never a form, streak, or judgment (Ch2 §8)." |
| **Premium** | Yes, and unusually well-disciplined across chapters — see §1 above. Every mention traces back to Ch1 §9 and ADR-007 in substance, even where the citation itself is missing. | "Premium: deepens a part of the ritual that already exists; never gates the core, never frames itself by contrast with what's missing (Ch1 §9)." |
| **Depth** | **No — collides across three unrelated meanings.** (1) Visual z-axis/elevation: "depth through layer, not noise" (Ch1 §11). (2) Personalization/understanding, specifically re: Premium: "depth is not the same as more" (Ch1 §9), "does it deepen meaning" (Ch4 §3). (3) Navigation hierarchy: "depth should be shallow" (Ch3 §10). | These are three real, useful, but distinct concepts wearing one word. Recommend renaming the navigation sense to **"Navigation Depth"** or **"Hierarchy Depth"** in Chapter 3 §10, reserving the unqualified word "Depth" for the Premium/meaning sense, which is the philosophically load-bearing one. The visual-elevation sense can stay disambiguated by context ("depth through layer") since it's a single, contained bullet. |
| **Trust** | Present but thin relative to its importance. Named as an Emotional Principle (Ch1 §10, two sentences), invoked as a Marketing Filter citation (Ch4 §8, correctly pointing to VISION.md), a Feature Review Matrix dimension (Ch4 §10), and a justification in the Never-Build list (Ch4 §12) — but never given a dedicated explanation the way Calm gets an entire section (Ch1 §6). | No new content needed, but Trust is a strong candidate to be more visibly defined — see Missing Foundations (§4). Canonical mechanic, already stated once and worth treating as the formal definition: "Trust compounds slowly through consistency and breaks instantly through one manipulative moment (Ch1 §10)." |
| **Meaning** | Used constantly as a load-bearing word — "reinforces the Circle for meaning," "does it deepen meaning," a Feature Review Matrix dimension — but **never explicitly defined anywhere**. | See Missing Foundations (§4). No canonical definition currently exists to adopt; one should be written. |
| **Attention** | Yes, consistent: a finite, protectable resource (Ch3 §2, Ch4 §3 "respect the user's attention"). No conflicting usage found. | "Attention: the finite resource every design and product decision either protects or taxes (Ch3 §2; Ch4 §3)." |
| **Restraint** | Yes, consistently used as a virtue and a design method (Ch2 §4, Ch2 rule 11, Ch3 throughout), never contradicted, but never formally named as a standalone principle with its own definition — always adjectival. | "Restraint: doing the least that still communicates clearly — evidenced most at the moments that matter most, not least (Ch2 §4, rule 11)." Worth formalizing given how often it's invoked. |

## 3. Cross References

Where a reader currently has to guess origin, or where a link would genuinely help navigation:

- **Ch4 §5 (Premium Filter) and Ch3 §12 (Premium Design)** state "Premium deepens, never gates" without citing Chapter 1 §9, unlike Ch2 §9 which does. Add the citation in both places.
- **Ch1 §10 (Emotional Principles), "Trust" bullet** does not cite Brand Book §6 (Core Values), even though every other bullet in that list ties back to a named source (Brand Promise, ADR-008). Add the citation.
- **Ch4 §4 (Calm Filter)** cites sources inconsistently within a single list — "one action stronger than many" cites Ch2 §7 and Ch3 §8; "silence is valuable," "avoid visual competition," "avoid noise" cite nothing. Bring the whole list to the same standard.
- **Ch2 §10 (Experience Rules) and Ch1 §11 (Design Principles)** contain no inline citations at all, unlike Ch3 and Ch4's equivalent lists, which cite occasionally. Recommend a uniform light pass across all four "rules/principles" lists in the Playbook (Ch1 §11, Ch2 §10, Ch3 §14, Ch4 §10/§12) so each item either states its own reasoning in full or points to where it's stated in full — not a mix of both within the same list.
- **Ch3 §3's "Empty / Active / Completed state"** should link to and reuse Chapter 2 §3's state names directly (see §1, §2 above) rather than merely citing Chapter 2 once for the Completed state, as it currently does.
- No additional *new* links are recommended beyond fixing the above. The four chapters already cross-reference each other well — the gaps found are omissions in an otherwise consistent pattern, not a missing pattern.

## 4. Missing Foundations

Two concepts are invoked constantly across all four chapters but never given a dedicated explanation the way Calm (Ch1 §6), Streaks (Ch1 §7), or Starting Again (Ch1 §8) are. Both should be elevated — not invented, since both already exist implicitly and consistently, only unstated as their own principle:

- **Meaning.** Used as a load-bearing word throughout ("strengthens the Circle for meaning," "deepen meaning," a named dimension in the Feature Review Matrix) without ever being defined. Recommend a short, explicit treatment — most naturally as an addition to Chapter 1 (where Calm, Trust, and the other Emotional Principles already live) — stating what "meaning" refers to in THIRTY specifically (most likely: the user's own sense that their thirty minutes mattered, as distinct from data collected about it, engagement produced by it, or attention captured through it).
- **Trust.** Exists in Ch1 §10 as two sentences and is cited everywhere else, but carries more structural weight in the Playbook than its current treatment reflects — it is the justification behind the entire Never-Build list (Ch4 §12) and the Marketing Filter (Ch4 §8). Recommend expanding its existing two sentences into a short, fuller treatment in the same place, rather than a new section — the mechanic ("compounds slowly, breaks instantly") is already correct and simply needs room.

One concept is invoked once, thinly, and is a genuine candidate rather than a confirmed gap:

- **Autonomy.** Appears once, unexplained, in the AI Filter ("does it respect the user's autonomy?" — Ch4 §6). It is clearly the same idea underlying Reflection's "invited, never required" (Ch2 §8) and Interaction's "the user decides" framing (Ch2 §7), but the Playbook never names that connection. Recommend either folding an explicit definition into Chapter 2 §8 (where it's most concretely expressed) or leaving it as a candidate for a future AI-specific chapter, since Ch1's closing note already flags "AI behavior" as a planned future domain.

Two concepts from the brief's example list are **already adequately covered** and need no action:

- **Quiet Confidence** — already a named Emotional Principle with its own definition (Ch1 §10).
- **Long-term thinking** — already has dedicated treatment in two places (Ch1 §14, Ch3 §9/Ch4 §9's "ten year" tests).

One concept is genuinely thin and worth a decision, not urgent:

- **Ownership.** Appears exactly once, as a single word inside a state's emotional meaning ("momentum, ownership" — Ch2 §3, Filling state). It is never explained. It's unclear whether this deserves its own principle (the user owns their pace, their data, their decision to skip a day) or whether it was simply a well-chosen word in that one sentence. Recommend leaving as-is unless a future chapter needs to build on it explicitly — flagging it here so it isn't mistaken for an established principle if a future author quotes it as one.

## 5. Governance Review

The Playbook has none of the governance the rest of the product's documentation already has (the ADR system's Status/Superseded discipline, the docs/product/README's "who's authoritative" table). It needs an equivalent, sized for a document meant to hold for twenty years rather than for one recommendation-engine decision.

- **Versioning.** Treat the Playbook as a whole, versioned document, not four independent files. A new chapter that extends coverage into an ungoverned domain (AI behavior, growth, community) is a **minor** version bump (v1.1, v1.2…). A correction to an existing chapter that doesn't change its meaning — a citation fix, a terminology reconciliation like the ones in this review — is a **patch**. A change to a load-bearing claim in an already-approved chapter ("the Circle is the product," "no streaks, ever," "Premium never gates") is a **major** version bump, because every later chapter and every ADR built on top of it would need to be re-checked against the new claim.
- **Review cadence.** Not calendar-based. A philosophy document reviewed on a schedule invites revision for its own sake, which is exactly the trend-chasing Chapter 4 §8 warns against. Instead, review is triggered by events: a new chapter proposal, an ADR that appears to strain against something written here, or a lightweight **annual integrity check** — not a rewrite session, a single question asked once a year: does the live product still match what these four chapters say it should feel like?
- **Ownership.** One named owner (a "Playbook Editor" — the founder, initially) is the sole approver of any change to an already-approved chapter. Anyone — designer, engineer, PM, or an AI agent — may draft a new chapter or propose a correction; only the owner can move it from Draft to Approved. This mirrors, and sits one level above, however Brand Book and CLAUDE.md changes are currently approved.
- **Approval process.** Adopt the ADR discipline that already exists in `docs/product/adr/`: a chapter is never silently edited once Approved. A correction is recorded as an explicit, dated amendment appended to the chapter (or, for terminology/citation fixes like the ones in this review, applied directly with a changelog note) — never a quiet diff with no trace that something changed.
- **Adding future chapters.** A new chapter is warranted only when a genuinely new domain needs governing — Chapter 1's own closing note already names the likely candidates (AI behavior, growth, community). A new chapter must: state which existing chapters it builds on (as Ch2–4 already do), avoid restating settled philosophy, and — since a new chapter is itself a kind of feature being added to the company — pass the same "does this strengthen the Circle" test Chapter 4 applies to everything else.
- **ADR vs. Playbook change.** An ADR is the right instrument for a decision made *within* the boundaries the Playbook already sets — a specific implementation choice, a specific signal's priority in the recommendation engine. The Playbook itself must change, via the amendment process above, only when a proposed decision would require contradicting a standing chapter — at that point an ADR is the wrong tool, because ADRs are checked against the Playbook, not the reverse.

## 6. Relationship with Existing Documentation

| Document | Responsibility | Must never duplicate |
|---|---|---|
| **CLAUDE.md** | How the team works: tech stack, architecture principle, workflow, Definition of Done. | Brand or product philosophy — it already correctly delegates this to Brand Book and now should delegate the deeper layer to the Playbook. |
| **VISION.md** | Why THIRTY exists, for whom, and the four founding product principles (focus, personal, trust, achievable) that outrank everything else. | Tone, visual identity, or decision filters — those are Brand Book's and the Playbook's jobs respectively. Already correctly cited by Ch4 §8. |
| **BRAND_BOOK.md** | The Golden Rule, Core Values, tone of voice, and the original, shorter statements of Circle Philosophy, Emotional Journey, and Design Principles that the Playbook now elaborates in depth. | The *deep* version of anything it originated. Sections §8–§11 and §16 in particular now largely overlap with the fuller treatment in Playbook Ch1–3 — see Editorial Recommendations (§8) for what to do about this. |
| **Design System** *(currently the theme token files; a dedicated `DESIGN_SYSTEM.md` is referenced by Brand Book §13 but doesn't yet exist)* | What a color, spacing, radius, or type value **is**. | Why it's shaped that way — that's Playbook Chapter 3's job, already respected in both directions (Ch3 references tokens without redefining them). When `DESIGN_SYSTEM.md` is eventually written, it should open with a pointer to Chapter 3 the same way Chapter 3 points to it. |
| **THIRTY Playbook (Ch1–4)** | The philosophical, experiential, visual-grammar, and product-governance foundation — the constitution everything else is checked against. | Concrete token values, specific UI copy, or recommendation-engine mechanics — those stay in the Design System and `docs/product/` respectively. |
| **`docs/product/` (recommendation-philosophy.md, decision-framework.md, product-discovery.md, onboarding-principles.md)** | The detailed, mechanical governance of one specific system: how a daily recommendation gets constructed, and the onboarding/discovery decisions specific to first use. | Broad product philosophy — Chapter 4's preface already draws this line explicitly and correctly. |
| **ADRs** | One dated, scoped, reversible-if-superseded decision each. | Broad philosophy. Seven of the eight existing ADRs have now been generalized into standing Playbook filters (Ch4's preface names them explicitly) — see §8 for the one concrete gap this creates. |

## 7. Canonical Principles

The following twenty statements are, as of this review, the immutable foundation of THIRTY. Each cites its origin chapter; none should be restated elsewhere without a citation back to this list or to its origin.

1. The Circle is the product, not the logo. — *Ch1 §3*
2. THIRTY is a ritual, returned to on purpose — not a task, completed and removed. — *Ch1 §4*
3. Calm outranks motivation, permanently, with no case-by-case exception. — *Ch1 §6*
4. There are no streaks. THIRTY counts completion — closed circles, each independent — never a chain that breaks. — *Ch1 §7*
5. A missed day changes nothing about tomorrow's circle. — *Ch1 §8*
6. Premium deepens the ritual; it never gates the core, and never frames itself by contrast with what's missing. — *Ch1 §9; ADR-007*
7. Every interaction should leave the user calmer than it found them — the standard every feature is measured against before it ships. — *Ch1 §15; Brand Book §5*
8. One primary action per screen, always. — *Brand Book §11; Ch1 §11; Ch2 §7; Ch3 §8*
9. Silence is a design material — in sound and in space — not an absence waiting to be filled. — *Ch2 §6; Ch3 §5*
10. Motion must mean something before it may exist. — *Ch2 §4*
11. Haptic feedback is spent on exactly two moments: starting and completing a circle. — *Ch2 §5*
12. Reflection is invited, never required, and never carries judgment. — *Ch2 §8*
13. Nothing THIRTY does may punish absence — an unopened day is empty, not broken. — *Ch1 §7; Ch2 §3; Ch3 §11*
14. The Circle is visually sacred — never generic decoration, never a borrowed motif. — *Ch1 §11; Brand Book §11.3*
15. Beauty in THIRTY is measured by what could be removed, not by what was added. — *Ch3 §2*
16. Data about the user is used to understand them, never to score, rank, or diagnose them. — *Ch2 rule 18; ADR-008; Ch4 §6*
17. A recommendation or AI feature that cannot be explained in plain language before it ships is not ready. — *ADR-002; Ch4 §6*
18. THIRTY is guided by its own philosophy, not by competitors or trends. — *Ch4 §8*
19. Every lasting decision must survive the question: will this still make sense in ten years? — *Ch3 §14; Ch4 §9*
20. Every product decision is checked first against "does this strengthen the daily Circle" before anything else. — *Ch4 §2*

## 8. Editorial Recommendations

Ranked by leverage — clarity, maintainability, governance, or consistency gained per unit of effort:

1. **Reconcile Circle-state terminology.** Update Chapter 3 §3 to use Chapter 2 §3's exact state names (Open, Filling, Nearly Closed, Closed, Archived, Unopened) instead of the parallel Empty/Active/Completed vocabulary. Single highest-value fix in this review — it's the one place two chapters actually disagree on a name for the same thing.
2. **Publish a Playbook Glossary** as a standing document (the table in §2 above, formalized), so every future chapter is required to use existing terms rather than inventing adjacent synonyms — which is exactly how the Circle-state and "renewal" issues arose.
3. **Resolve the "Depth" collision** by renaming Chapter 3 §10's navigation usage (recommend "Navigation Depth" or "Hierarchy Depth"), freeing the unqualified word for its more central, Premium/meaning-related sense.
4. **Decide the fate of "renewal."** Either adopt it formally as the name for Chapter 1 §8's concept or remove its one stray, undefined use in Chapter 4 §12.
5. **Add the missing backward citations** identified in §3 above (Ch1 §10 Trust bullet → Brand Book §6; Ch3 §12 and Ch4 §5 → Ch1 §9; the inconsistently-cited bullets in Ch4 §4).
6. **Add "Elevated by Playbook Chapter 4" back-references** to ADR-001, 002, 003, 004, 005, 007, and 008, so a reader arriving at an ADR first can find the generalized principle. Consider whether the ADR status vocabulary (currently only `Proposed` / `Accepted` / `Superseded by ADR-00X`) needs a way to express "elevated to Playbook governance" — a smaller, additive change to `docs/product/README.md`'s ADR rules rather than a new status value, most likely a one-line convention rather than a new formal state.
7. **Trim Brand Book §8 (Circle Philosophy), §9 (Emotional Journey), §10 (THIRTY Moment), §11 (Design Principles), and §16 (Motion)** into short summaries pointing to Playbook Chapters 1–3, mirroring the pattern CLAUDE.md's own "Product Principles" section already uses toward Brand Book. This is the largest recommendation in this review and the only one that touches a document outside the Playbook itself — flagged here, not executed, since it's a product/brand decision about an already-approved document, not a Playbook consistency fix.
8. **Write this review's governance section (§5) into the Playbook itself** — a short, persistent home for versioning/ownership/amendment rules, rather than leaving them recorded only in a one-time review document.

None of these are style edits. All eight are either fixing something that will actively confuse a future author (1, 3, 4), preventing that confusion from recurring (2), closing traceability gaps (5, 6), or establishing governance that doesn't yet exist anywhere (7, 8).

## 9. Readiness Assessment

**YES.** Chapters 1–4 are stable enough to freeze as **THIRTY Playbook v1.0**.

Justification: this review found no conflicting principles anywhere in the four chapters — every finding was a consolidation, citation, or terminology gap, not a place where one chapter tells a future team to do the opposite of another. The four chapters already form a coherent stack (manifesto → experience → visual grammar → decision governance), each correctly scoped to its own altitude, and the cross-referencing discipline is already strong in the majority of cases audited. The gaps found are the kind of polish a mature, well-run editorial process catches before a freeze — not evidence the philosophy itself is unsettled.

Remaining actions before officially freezing v1.0, in order:

1. Fix the Chapter 2 / Chapter 3 Circle-state naming mismatch (§1, §2, §8.1).
2. Resolve the "Depth" term collision and the "renewal" terminology decision (§8.3, §8.4).
3. Add the identified missing citations (§8.5).
4. Publish the Playbook Glossary as a standing document (§8.2).
5. Add the "Elevated by" back-references to the seven affected ADRs (§8.6).
6. Write a short, permanent governance note into the Playbook folder (§8.8; the substance already exists in §5 of this review).

Item 7 from the Editorial Recommendations (trimming Brand Book) is **not** a precondition for freezing v1.0 — it changes a different, already-approved document and should be a deliberate, separate decision, not a side effect of freezing the Playbook.

---

*This review is the editorial and governance record for THIRTY Playbook v1.0. It does not alter Chapters 1–4 on its own — each recommendation above is a proposed action, to be applied deliberately and, per the governance model in §5, with the same care as any other change to an already-approved chapter.*
