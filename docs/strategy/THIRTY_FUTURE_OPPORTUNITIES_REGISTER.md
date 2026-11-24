# THIRTY — Future Opportunities & Deferred Commitments Register

| | |
|---|---|
| **Document ID** | THIRTY-FUT-REG-2026-11-24 |
| **Version** | 1.0 (2026-11-24) |
| **Owner** | KEYBRACE founder |
| **Status** | **Central index.** The founder approved its creation as part of the English-first documentation scope (2026-11-24). Its independent acceptance is pending. |
| **Source draft** | `THIRTY_FUTURE_OPPORTUNITIES_REGISTER_DRAFT_2026-11-24.md` (founder working file, outside the repository; sha256 `3f14fc26…`), 30 entries. Every draft ID is preserved here |
| **Baseline** | `thirtyapp/Thirty` @ `d8cd676518f5713e1c5417382a71eed892ff640b` |

> **First prove THIRTY. Then expand the system.** English-first does not delete the other languages or any evidence-gated growth idea.

## Purpose and what this register is not

This register keeps long-term ideas from being forgotten when the launch scope is narrowed. It is a searchable **index** of three kinds of item:
- deferred commitments;
- strategic directions;
- exploratory opportunities.

It is **not** any of the following:
- a product-contract amendment;
- a development backlog with authorized tasks;
- a release requirement or launch blocker;
- a feature entitlement;
- a launch schedule;
- an approved budget;
- a catalogue of guaranteed commercial products.

Being written here **never** approves, schedules or funds an idea. It never lets an idea bypass a release gate. It never pulls an idea into launch scope. It never removes a current contract obligation.

## Authority

| Question | Authority |
|---|---|
| What THIRTY is and what ships | [PRODUCT_V2_CONTRACT.md](../product/PRODUCT_V2_CONTRACT.md), including [Amendment 4](../product/PRODUCT_V2_CONTRACT.md#status) (English-first) and Amendment 3 (language principles) |
| Why English-first | [THIRTY_ENGLISH_FIRST_RELEASE_SCOPE_AMENDMENT_2026-11-24.md](../product/THIRTY_ENGLISH_FIRST_RELEASE_SCOPE_AMENDMENT_2026-11-24.md) |
| Remaining launch gaps and gates | [THIRTY_PRE_RELEASE_PRODUCT_GAP_REGISTER.md](../product/THIRTY_PRE_RELEASE_PRODUCT_GAP_REGISTER.md) |
| Delivery status | [THIRTY_V2_DELIVERY_TRACKER.md](../product/THIRTY_V2_DELIVERY_TRACKER.md) |
| Localization and language-safe persistence | [ADR-025](../product/adr/ADR-025-localization-architecture.md), [ADR-026](../product/adr/ADR-026-language-safe-persistence.md) |
| Product family, flagship growth, commercial architecture | [THIRTY_PRODUCT_FAMILY_STRATEGY.md](THIRTY_PRODUCT_FAMILY_STRATEGY.md) (founder-approved long-term direction, v1.1) |
| Physical ritual products and merchandise | [THIRTY_FUTURE_RITUAL_PRODUCTS_AND_MERCHANDISE.md](THIRTY_FUTURE_RITUAL_PRODUCTS_AND_MERCHANDISE.md) (future exploration, non-binding). It remains the authority for the physical-product concept inventory |

**Founder working records outside the repository** (historical inputs, cited as plain text; their approvals may be superseded by V2):
- `THIRTY_PRODUCT_DIRECTION_AND_SCOPE_DELTA_2026-09-08.md`, the "September Scope Delta": PD-01…PD-12;
- `THIRTY_PRE_RELEASE_VISION_AND_DELIVERY_TRACKER.md`.

## Status vocabulary

| Status | Meaning |
|---|---|
| **CURRENT CONTRACT** | Already required by V2. Never deferred by this register |
| **DEFERRED DELIVERY** | Explicitly preserved, but rescheduled after the initial release |
| **FOUNDER-APPROVED FUTURE DIRECTION** | Strategic intent accepted. No implementation commitment |
| **CANDIDATE** | Needs evaluation and evidence before a separate product decision |
| **EXPLORATION ONLY** | A concept that is noted, not ratified |
| **RETIRED CURRENT PRODUCT ELEMENT** | Removed from the current contract |
| **EXCLUDED / PROHIBITED** | May not be (re)introduced without a separate explicit decision, usually a contract amendment |

Unknown facts are marked `OPEN`, `UNVERIFIED` or `SOURCE TO VERIFY`. No owner, cost, date or priority is invented. Unless stated otherwise, the owner of every entry's decision is the founder.

---

## A. Languages and audio (7)

**Shared basis for LANG-01…05:**
- **Source:** [Amendment 3](../product/PRODUCT_V2_CONTRACT.md#status) (founder decision 2026-11-12; direction first given 2026-11-03) made these languages launch languages. [Amendment 4](../product/PRODUCT_V2_CONTRACT.md#status) (2026-11-24) defers them.
- **Status:** **DEFERRED DELIVERY.** Deferred, not cancelled.
- **Why not at launch:** Amendment 4 makes the initial T2 and T3 English-only.
- **Dependencies and safeguards** (Amendment 4, "Before any further language is activated or shipped"):
  - complete approved locale copy;
  - full Free/Premium parity;
  - native review;
  - accessibility and layout;
  - date, time and ICU behaviour;
  - truthful offers;
  - approved native-quality Premium voices (LANG-06);
  - script and screen that match, with no cross-language substitution;
  - licensing and manifests;
  - legacy English records shown as saved;
  - G-5C / ADR-026 Part B / D-L-5c (LANG-07);
  - D-L-8;
  - a separate rollout authorization.
- **Next review trigger:** post-launch language planning, on evidence of product, demand, quality and economics.
- **Founder decision required:** choosing the language, approving its `L-UPD` release brief and gates, and authorizing its rollout. Plus D-L-3 (glossary) and D-L-4 (native reviewers) for that language.
- **No delivery order, release date, country list, translation vendor, voice count, budget or price is set.**

### LANG-01 — French (`fr`)
The shared basis applies. Its layout risk (text expansion) is tracked under gap register G-05.

### LANG-02 — Dutch (`nl`)
The shared basis applies. Its layout risk (text expansion) is tracked under G-05.

### LANG-03 — European Spanish (`es-ES`)
The shared basis applies.
- **Content:** es-ES content, held in the single `es` resource (ADR-025 §2).
- **Also pending:** D-L-6, Spanish outside Spain. Native-quality es-ES voices were effectively 0/4 at the 2026-11-03 check (gap register G-03).

### LANG-04 — German (`de`)
The shared basis applies. Its layout risk (text expansion) is tracked under G-05.

### LANG-05 — Italian (`it`)
The shared basis applies. The Italian "Plans" term is an open glossary point (D-L-3).

### LANG-06 — Native-quality Premium guidance and voices for each activated language
- **Source:**
  - Amendment 3, "Premium voice";
  - Q-1 and D-V-3 (2026-11-12);
  - [gap register G-03](../product/THIRTY_PRE_RELEASE_PRODUCT_GAP_REGISTER.md);
  - ADR-025 §7, which sets per-(persona, locale) completeness and allows no clip from another locale.
- **ADR-027:** multilingual audio, **not drafted**.
- **Status:** **DEFERRED DELIVERY.**
  - The rule itself is current and binding: no language ships without approved native-quality guidance.
  - The English pack (172 + 8 = 180 files) is **CURRENT CONTRACT** and stays on the T2 critical path.
- **Why not at launch:** there is no further language at launch.
- **Dependencies and safeguards:**
  - native listening approval, because a "multilingual" provider label is not native quality;
  - licensing confirmed at generation time;
  - script and label match;
  - manifest integrity;
  - no mixed-language session.

  Unvoiced Premium is **not** an equivalent alternative. Any relaxation needs a contract amendment.
- **Next review trigger:** each language's `L-UPD` brief.
- **Founder decision required:**
  - D-V-1, the voice option (A, B or C; B was recommended, **not approved**);
  - D-V-2, the persona model;
  - D-V-4, the budget;
  - D-V-5, licences.

### LANG-07 — Language selection, source locale and legacy-record continuity
- **Source:**
  - ADR-025 §4, language selection;
  - ADR-026: Part A approved; Part B on HOLD; gate G-5C;
  - D-L-5c, D-L-8 and D-L-9;
  - D-ON-3: a language preference is never existing-user evidence.
- **Status:** **DEFERRED DELIVERY — IMPLEMENTATION HOLD.**
- **Why not at launch:** the release set is `{en}`. No language control exists, and G-5C forbids any non-English release set against a real store.
- **Dependencies and safeguards:**
  - no change to saved legacy English;
  - export and privacy approval for any persisted language field (D-RL4 and an export-format decision);
  - language choice is Free and never Premium.
- **Next review trigger:** before the first further language.
- **Founder decision required:** D-L-5c, D-L-8 and D-L-9.

---

## B. Flagship THIRTY — growth beyond the current V2 contract (9)

### CORE-01 — More authored Circle Plans and deeper coherent paths
- **Source:**
  - Product Family Strategy PF-06 ("Flagship may expand beyond its initial activity/Plan inventory: Approved future direction") and Phase B ("more Plans");
  - September Scope Delta PD-03.
- **Status:** **FOUNDER-APPROVED FUTURE DIRECTION.** A specific new catalogue is a **CANDIDATE**.
- **Current contract, not deferred:** the [three launch Plans](../product/PRODUCT_V2_CONTRACT.md#circle-plan-contract-amended-2026-10-17), with five StageBriefs each.
- **Why not at launch:** the frozen V2 contract sets exactly three launch Plans.
- **Dependencies and safeguards:** no content treadmill; translation and voice upkeep for every language.
- **Next review trigger:** repeated real user need after launch.
- **Founder decision required:** catalogue and scope approval, plus a contract amendment for any change to the Plan set.

### CORE-02 — Richer contextual Circle Coach, or an eventual distinct destination
- **Source:**
  - [Contract, Coach](../product/PRODUCT_V2_CONTRACT.md#coach): "RETIRED as a separate pillar … No generic coach or chat";
  - Product Family Strategy Phase B ("a richer Coach");
  - September Scope Delta PD-02 (a V1-era direction, superseded for V2 by the contract).
- **Status:** **CANDIDATE.** The V2 contract **retires Coach as a separate current pillar** (RETIRED CURRENT PRODUCT ELEMENT). Its legitimate jobs live today in:
  - the recommendation engine;
  - Circle guidance;
  - the feedback acknowledgement;
  - Plan stage lines and resumption.
- **Not approved:**
  - the old V1 Coach as a current Premium entitlement;
  - a standalone Coach tab;
  - a generic AI chatbot (**EXCLUDED**);
  - runtime generative AI (**EXCLUDED**, contract Explicit exclusions).
- **Why not at launch:** retired in V2. A richer Coach is post-launch exploration only.
- **Dependencies and safeguards:** a demonstrated, bounded decision or guidance job; safety review; economic value; local-first and deterministic behaviour.
- **Next review trigger:** post-launch evidence of an unmet guidance job.
- **Founder decision required:** a separate product **and** safety decision, plus an **explicit V2 contract amendment** before any restoration.

### CORE-03 — Expanded evidence-aware, actionable Insights
- **Source:** Product Family Strategy PF-06 and Phase B ("richer Insights"); September Scope Delta PD-03.
- **Status:** **FOUNDER-APPROVED FUTURE DIRECTION.** The details are a **CANDIDATE**.
- **Current contract, not deferred:** the [six Insight families](../product/PRODUCT_V2_CONTRACT.md#insights-contract-amended-2026-10-17), I1–I6.
- **Why not at launch:** the six families are frozen for launch.
- **Dependencies and safeguards:**
  - evidence and denominators;
  - truthful co-occurrence wording, never causal;
  - privacy and safety;
  - no vanity dashboard, scores or inferred health states.
- **Next review trigger:** post-launch Insight usefulness evidence.
- **Founder decision required:** scope approval, plus a contract amendment for any new family.

### CORE-04 — Premium Atmosphere
Restrained extra motion, light, environmental depth and suitable sound.
- **Source:**
  - [Contract, Worlds](../product/PRODUCT_V2_CONTRACT.md#worlds) ("later Premium atmosphere");
  - Product Family Strategy Phase B;
  - `docs/worlds/WORLD_SYSTEM.md` §12;
  - historical `PREMIUM_STRATEGY.md` §7.
- **Status:** **CANDIDATE**, post-launch.
- **Current contract, not deferred:** baseline Worlds, dayparts, seasons and permanent Growth remain Free and shared.
- **Why not at launch:** no Atmosphere deliverable is in the V2 launch contract.
- **Dependencies and safeguards:**
  - visual, performance, accessibility (reduced motion) and cost review;
  - no paid ownership of Worlds, seasons or progress;
  - no gamification.
- **Next review trigger:** post-launch Premium value review.
- **Founder decision required:** a separate approval.

### CORE-05 — Additional authored guided Sessions or advanced guidance
- **Source:** the historical Premium concepts "Circle Sessions" (Playbook Ch. 4; `PREMIUM_STRATEGY.md`, superseded for V2).
- **Status:** **EXPLORATION ONLY.** It is not a current or automatic Premium feature.
- **Current contract, not deferred:** today's bundled Premium spoken guidance.
- **Why not at launch:** no distinct job is established.
- **Dependencies and safeguards:** the content, safety and voice workload, multiplied by languages; the commercial boundary.
- **Next review trigger:** OPEN.
- **Founder decision required:** a product decision and contract amendment.

### CORE-06 — Further activity and content expansion after launch
- **Source:**
  - Product Family Strategy PF-06 and Phase B ("more activities");
  - the contract's optional activity additions (Catalogue status: Daylight minutes, Screen-break reset, Reach out to someone).
- **Status:** **FOUNDER-APPROVED FUTURE DIRECTION.**
- **Not deferred by this register:** the **CD-1** launch content-depth decision and any SAF-1 clearance. Both are current T2 prerequisites, made before the English copy freeze.
- **Why not at launch:** the depth beyond the CD-1 decision follows launch evidence (gap register CNT-2, P2).
- **Dependencies and safeguards:** content QA; the safety gate; translation and voice upkeep; economics.
- **Next review trigger:** observed depth or retention gaps after T2/T3.
- **Founder decision required:** content approval.

### CORE-07 — Watch Companion
A watch acting as a remote for the same Circle Start and Close.
- **Source:** September Scope Delta §7 and PD-05 ("Candidate Premium expansion"). Founder working record outside the repository.
- **Status:** **CANDIDATE.**
- **Why not at launch:** not V2 scope. A feasibility brief is needed.
- **Dependencies and safeguards:**
  - the phone stays a complete Free experience without a watch;
  - a watch closure is an app interaction, not proof of activity;
  - **no** heart-rate, sleep, steps, GPS, Health Connect or wearable-health ingestion (EXCLUDED without a separate product, safety and privacy decision; ADR-004);
  - no mandatory account or cloud backend;
  - platform, API, shared state, entitlement and maintenance cost.
- **Next review trigger:** post-launch, on a feasibility brief.
- **Founder decision required:** platform and scope approval.

### CORE-08 — Optional instructional guide variants
- **Source reconciliation:**
  - September Scope Delta PD-07 proposed character variants inside Worlds. It was **SUPERSEDED on 7 October 2026 by PD-12**: World artwork stays people-free.
  - PD-12 and Product Family Strategy §K2 ("Optional guide preference") record that two things are possible **future** capabilities: instructional human guidance (in a separate guidance layer, never in World art) and an optional guide preference (Man · Woman · No preference).
- **Status:** **EXPLORATION ONLY.** The in-World variant idea of PD-07 is retired.
- **Why not at launch:** no current scope. PD-12 explicitly creates no onboarding, gender-identity, cloud-profile or release-timing change.
- **Dependencies and safeguards:**
  - the World System No-People rule;
  - local opt-in, with "No preference" always available;
  - never a question about the user's own sex or gender;
  - no gender inference;
  - accessibility;
  - brand approval.
- **Next review trigger:** OPEN (most relevant to future specialist products).
- **Founder decision required:** product and brand approval.

### CORE-09 — Richer World-inspired visual content, consistent with Free ownership
- **Source:**
  - Product Family Strategy §C ("richer Worlds and Atmosphere");
  - September Scope Delta PD-06;
  - `docs/worlds/WORLD_SYSTEM.md`.
- **Status:** **CANDIDATE** for incremental future scope.
- **Current contract, not deferred:** the current pre-release World quality and beauty work, with Worlds protected (contract "Worlds").
- **Why not at launch:** beyond the launch asset scope.
- **Dependencies and safeguards:** the World System, Motion Language and Design System; no paid ownership of seasons or progress; no collectibles.
- **Next review trigger:** post-launch.
- **Founder decision required:** a bounded asset brief.

---

## C. Product family (5)

All five follow the **standalone product gate** (Product Family Strategy §P) and its sequencing (§Q):
- prove the flagship first;
- **build at most one specialist first** (PF-12);
- no premature multi-app platform rewrite (PF-11).

Names are working names, not approved store names. **No specialist implementation, shared architecture, account system or billing rewrite is authorized.**

Validation needs real flagship evidence: usage, retention, subscription economics, operating costs and demand.

### FAM-01 — THIRTY Fit (working name)
- **Source:** Product Family Strategy PF-03 and §F; September Scope Delta PD-11.
- **Status:** **CANDIDATE** specialist app.
- **Why not at launch:** the flagship is unproven.
- **Safeguards:** THIRTY DNA (PF-10, §E); the calm-fitness constraint (§K2); no leaderboards or grind culture.
- **Next review trigger:** the flagship launch plus evidence.
- **Founder decision required:** the standalone gate and a product brief.

### FAM-02 — THIRTY Meditation (working name)
- **Source:** Product Family Strategy PF-04 and §G.
- **Status:** **CANDIDATE** specialist app.
- **Why not at launch:** as FAM-01.
- **Safeguards:** non-therapy positioning and guidance safety. The 0.85× English pacing test is **not** approved for it (gap register G-08).
- **Next review trigger:** as FAM-01.
- **Founder decision required:** the standalone gate and a product brief.

### FAM-03 — THIRTY Yoga (working name)
- **Source:** Product Family Strategy PF-05 and §H.
- **Status:** **CANDIDATE** specialist app.
- **Why not at launch:** as FAM-01.
- **Safeguards:** a distinct mobility and flow job; instructional-guidance safety (CORE-08).
- **Next review trigger:** as FAM-01.
- **Founder decision required:** the standalone gate and a product brief.

### FAM-04 — THIRTY Pass (cross-product membership or bundle)
- **Source:** Product Family Strategy PF-08 ("Commercial candidate only") and §M; gap register G-08.
- **Status:** **CANDIDATE.** Unpriced, not designed, not approved.
- **Not a change to:** the current RevenueCat entitlement, subscription identity or billing architecture.
- **Why not at launch:** it needs at least one viable specialist.
- **Dependencies and safeguards:** store rules, shared billing and entitlement, pricing and a business case.
- **Next review trigger:** after a specialist is proven.
- **Founder decision required:** a commercial decision plus an ADR.

### FAM-05 — Reusable shared THIRTY core, or optional cross-app identity and sync
- **Source:** Product Family Strategy PF-07 ("Architectural direction, not a current task"), §L and §O; PF-11.
- **Status:** **CANDIDATE** (architectural).
- **Why not at launch:** there is no concrete second product.
- **Dependencies and safeguards:**
  - demonstrated reuse;
  - local-first data protection;
  - no mandatory account or cloud profile (contract Explicit exclusions);
  - an explicit ADR.
- **Next review trigger:** a concrete second product.
- **Founder decision required:** an ADR plus scope approval.

---

## D. Commercial ecosystem (5)

**Shared boundaries** (Future Ritual Products & Merchandise §§7.1, 10, 11; Product Family Strategy PF-09). Nothing below is approved:
- new SKUs;
- suppliers or manufacturers;
- inventory;
- fulfilment;
- a production budget;
- commerce inside a Circle;
- any digital Premium entitlement from a physical purchase;
- artificial scarcity or "complete the set" pressure;
- undeclared safety or health claims.

The detailed document remains the authority for the physical-product concept inventory.

### ECO-01 — World-inspired ritual products, distinct from generic logo merchandise
- **Source:** Product Family Strategy PF-09 ("Future commercial direction") and §N; Future Ritual Products & Merchandise §1 and §6.
- **Status:** **FOUNDER-APPROVED FUTURE DIRECTION** (long-term). The individual products are **CANDIDATE** or **EXPLORATION ONLY**.
- **Why not at launch:** it is not a launch requirement.
- **Dependencies and safeguards:**
  - evidence of interest;
  - product and physical safety;
  - sourcing and margins;
  - a legal merchant entity (KEYBRACE);
  - artwork IP rights;
  - founder workload.
- **Next review trigger:** after flagship launch evidence (Future Ritual Products & Merchandise §9 validation sequence).
- **Founder decision required:** a separate product, safety, sourcing and margin approval.

### ECO-02 — World-inspired adult coloring / mandala ritual book
- **Source:** Future Ritual Products & Merchandise §§4–5. Its §11 records it as "an explicit future opportunity".
- **Status:** **EXPLORATION ONLY.** It sits in a non-binding exploration document; no product, name or date is approved.
- **Why not at launch:** not a launch requirement.
- **Dependencies and safeguards:** a product brief; original quality artwork and IP; safety and claims review; unit economics; never scarcity-driven series pressure.
- **Next review trigger:** Future Ritual Products & Merchandise §9.
- **Founder decision required:** a separate product approval.

### ECO-03 — Ritual objects and bundles
Items: the Garden Window `tend` caddy or utility basket, storage basket, textiles and throws, mats, notebooks, and cohesive ritual bundles.
- **Source:** Future Ritual Products & Merchandise §2, §3 and §6.2; Signature Objects (`docs/design/THIRTY_SIGNATURE_OBJECTS.md`, non-binding).
- **Status:** **EXPLORATION ONLY.** The caddy is recorded there as "a promising commercial hypothesis".
- **Why not at launch:** not a launch requirement.
- **Dependencies and safeguards:**
  - product-specific prototypes;
  - audience interest;
  - fulfilment cost;
  - World-fit rules (for example, Still Lake excludes mats, cushions and towels);
  - a notebook carries no streak tracking.
- **Next review trigger:** Future Ritual Products & Merchandise §9.
- **Founder decision required:** a separate product approval.

### ECO-04 — World collections, gifting, seasonal editions and optional physical-to-digital links
- **Source:** Future Ritual Products & Merchandise §5.1 (gift; series), §6–§7 (QR or link to a matching ritual; small bundles) and §7.1 (hard boundaries).
- **Status:** **EXPLORATION ONLY.**
- **Why not at launch:** not a launch requirement.
- **Dependencies and safeguards:**
  - no fabricated scarcity;
  - no commerce inside a Circle;
  - a physical link never unlocks Premium or changes the Free experience;
  - explicit founder approval.
- **Next review trigger:** after ECO-01 validation.
- **Founder decision required:** a separate approval.

### ECO-05 — Specialist partnerships or distribution extensions
- **Source:** Product Family Strategy §M ("relevant future partnerships or programs") and §R.
- **Status:** **EXPLORATION ONLY.**
- **Why not at launch:** not a launch requirement.
- **Dependencies and safeguards:** brand fit; user value; legal and commercial safety; health-claim restraint; cost.
- **Next review trigger:** OPEN.
- **Founder decision required:** a separate approval.

---

## E. Earlier ideation — retained for discovery, not ratified (4)

These names come from the source draft's "earlier product brainstorming". **Their original source has not been established.** No record of them was found in the repository at the baseline, nor in the founder working records named above.

All four are therefore **EXPLORATION ONLY — EARLIER IDEATION — SOURCE TO VERIFY — NOT AUTHORIZED.** None is a founder-approved feature or a V2 capability. Each needs a source-led founder review before it could become a CANDIDATE.

**Common fields for IDEA-01…04:**
- **Status:** EXPLORATION ONLY — EARLIER IDEATION — SOURCE TO VERIFY — NOT AUTHORIZED.
- **Why not at launch:** unratified. The original source is unknown, and the idea is not in the V2 contract.
- **Next review trigger:** a source-led founder product review.
- **Founder decision required:** to establish the source and the user job, then to accept, archive or promote the idea to CANDIDATE. Where the idea touches an exclusion, an explicit contract amendment is also needed.

### IDEA-01 — Circle Moments
- **Source:** SOURCE TO VERIFY.
- **Status:** EXPLORATION ONLY — SOURCE TO VERIFY — NOT AUTHORIZED. The common fields above apply.
- **Gate:** define the actual user job.
- **Restriction:** any feed or engagement-pressure form is **EXCLUDED** (contract Explicit exclusions: "A feed, social features or community").

### IDEA-02 — Circle Together, or optional shared social rituals
- **Source:** SOURCE TO VERIFY.
- **Status:** EXPLORATION ONLY — SOURCE TO VERIFY — NOT AUTHORIZED. The common fields above apply.
- **Gate:** privacy, consent, non-comparison and product fit.
- **Restriction:** social features and community are **EXCLUDED** by the current contract. Any form of this idea needs an **explicit contract amendment**, not ordinary backlog work.

### IDEA-03 — Home-screen widgets, and watch complications beyond CORE-07
- **Source:** SOURCE TO VERIFY.
- **Status:** EXPLORATION ONLY — SOURCE TO VERIFY — NOT AUTHORIZED. The common fields above apply.
- **Gate:** incremental value, accessibility and platform cost.
- **Restriction:** no streak or pressure surface.

### IDEA-04 — Optional social sharing, community, referral or partner touchpoints
- **Source:** SOURCE TO VERIFY.
- **Status:** EXPLORATION ONLY — SOURCE TO VERIFY — NOT AUTHORIZED. The common fields above apply.
- **Gate:** user evidence and non-judgmental design; no growth hacking or forced social participation.
- **Restriction:** community and social features are **EXCLUDED** by the current contract, and would need an explicit contract amendment.

---

## F. Retired and excluded items (reference only; not opportunities)

These items carry no register ID, because they are not future opportunities.

- **RETIRED CURRENT PRODUCT ELEMENT** (contract "Superseded V1 assumptions"; Amendment 2):
  - Coach as a separate Premium pillar;
  - V1 click-count Insights;
  - Paths, routines, tune-ups, shorter routine versions, Toolkit maintenance and the Toolkit tab;
  - V1's five-stage Plans of fixed activities.
- **EXCLUDED / PROHIBITED** (contract Explicit exclusions and frozen rules):
  - runtime generative AI and a generic AI chatbot or coach;
  - ML personalisation and a cloud personal profile;
  - an account requirement;
  - streaks, badges, points, scores, leaderboards and guilt mechanics;
  - a feed, social features or community;
  - a browsable catalogue, a virtual pet or an unlock grind;
  - "AI" product positioning;
  - paywalling owned History or kept Circles;
  - a content treadmill;
  - runtime machine translation or generated speech.

  Without an explicit product, safety and privacy decision, these are also excluded: wearable health-data ingestion, physiological health scoring and inferred gender.

Writing an idea in this register never removes one of these prohibitions.

## G. Review cadence and intake rules

**Every idea added to this register must have:**
1. a stable ID (never reused);
2. its source, or `SOURCE TO VERIFY`;
3. its actual decision status, from the vocabulary above;
4. why it is deferred or not in scope;
5. its next decision gate;
6. its safety, privacy, architecture and commercial constraints;
7. a link to its detailed specification, where one exists.

**Separate founder authorization** is always required before implementation.

**Never silently delete an entry.** A rejected or superseded idea is archived here with its original ID, the date and an explicit reason.

**Cadence:**
- **At each release-planning review:** review LANG-01…07 and this register beside the gap register before declaring a scope freeze. An open future idea **never** becomes a launch blocker by staying open.
- **At each founder product review:** assign IDs to new ideas and re-check statuses.
- **After the English launch:**
  - review real activation, retention, conversion, paid renewals, support load and operating economics before prioritizing anything in B–E;
  - for a language update, prepare a per-locale release brief that confirms ADR-026 Part B, migration, voice, accessibility and commercial claims first;
  - for a specialist app, prove the flagship and build at most one specialist first.

## H. ID reconciliation with the source draft

| Section | Draft IDs | Register IDs | Count |
|---|---|---|---|
| Languages | LANG-01…07 | LANG-01…07 | 7 |
| Flagship | CORE-01…09 | CORE-01…09 | 9 |
| Product family | FAM-01…05 | FAM-01…05 | 5 |
| Commercial ecosystem | ECO-01…05 | ECO-01…05 | 5 |
| Earlier ideation | IDEA-01…04 | IDEA-01…04 | 4 |
| **Total** | **30** | **30** | **30** |

No ID was merged, renamed, dropped or added.

**Status corrections against the draft.** Each change makes a status match its source; none promotes an idea.
- **LANG-01…07:** the draft's "DEFERRED-LANGUAGE DIRECTION … Amendment 3 still active" became **DEFERRED DELIVERY**, now that Amendment 4 is recorded.
- **CORE-08:** "INVESTIGATION ONLY" became **EXPLORATION ONLY**. The entry now records that PD-07 is superseded by PD-12.
- **ECO-02:** "EXPLICIT FUTURE OPPORTUNITY" became **EXPLORATION ONLY**, because its source is non-binding.
- **ECO-03 and ECO-04:** "FUTURE POSSIBILITIES" became **EXPLORATION ONLY**.
- **IDEA-01…04:** "EARLIER IDEATION ONLY" became **EXPLORATION ONLY — SOURCE TO VERIFY — NOT AUTHORIZED**, and the conflict of IDEA-02 and IDEA-04 with the contract's exclusions is now named.

## I. Change log

- **1.0, 2026-11-24.** First version, from the founder draft (Draft 0.1, 2026-11-24).
  - All 30 IDs are preserved.
  - Sources were verified against the repository at `d8cd6765` and against the September Scope Delta (founder working record).
  - Created with Amendment 4 under the founder-approved eight-document documentation scope.
  - No code, release or entitlement change.
