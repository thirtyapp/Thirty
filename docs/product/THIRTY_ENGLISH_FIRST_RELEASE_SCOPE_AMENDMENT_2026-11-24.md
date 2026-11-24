# THIRTY — English-first release scope: decision record

## 1. Document identity

| | |
|---|---|
| **Document ID** | THIRTY-REL-EN-2026-11-24 |
| **Type** | Permanent decision record: rationale, scope and traceability |
| **Operative rule** | [PRODUCT_V2_CONTRACT.md — Amendment 4](PRODUCT_V2_CONTRACT.md#status). This record is **not** a second specification and creates no rule of its own. Where it and the contract differ, the contract wins. |
| **Owner** | KEYBRACE founder |
| **Source draft** | `THIRTY_ENGLISH_FIRST_RELEASE_SCOPE_AMENDMENT_DRAFT_2026-11-24.md` (founder working file, outside the repository; sha256 `51207644…`), corrected as in §20 |
| **Scope authority** | the independent `THIRTY_ENGLISH_FIRST_GOVERNANCE_SCOPE_AUDIT_2026-11-24.md` (outside the repository; sha256 `b2cb23f8…`). It set the eight-document scope of this change |

## 2. Founder decision

On **2026-11-24** the founder approved two things:
- an **English-first release strategy**: the first complete Google Play pre-release (T2) and the first public commercial release (T3) are English;
- the exact eight-document scope that records it.

> **Decision principle.** Launch a complete, safe, commercially viable THIRTY in English first. Deliver French, Dutch, European Spanish, German and Italian through separately validated updates. **Deferred does not mean cancelled.**

**Status, kept distinct:**

| Step | State |
|---|---|
| Founder decision (strategic direction and documentation scope) | **APPROVED, 2026-11-24** |
| Local documentation implementation (this record, Amendment 4 and the related updates) | made in one local commit on top of the baseline below |
| Independent acceptance of that documentation commit | **PENDING** |
| GitHub publication (push) of that commit | **NOT AUTHORIZED** at the time of writing; it needs its own founder authorization |
| Application release (T2, T3) | **NOT AUTHORIZED.** No release gate is cleared by this decision |

## 3. Immutable Git baseline

| | |
|---|---|
| Repository | `thirtyapp/Thirty` |
| Branch | `step5-billing-integration` |
| Baseline commit | `d8cd676518f5713e1c5417382a71eed892ff640b` |
| Tree | `f308b8516db850f8e28d1d72cbbc3c3fe317f29e` |
| Sole parent | `b1dea377c88b69991af714073eaaef936f885a22` |
| State | G-02 English Batch 8, independently accepted and pushed. The English ARB catalogue holds 24 messages; English copy extraction is **not** complete |

## 4. Authority hierarchy

1. [PRODUCT_V2_CONTRACT.md](PRODUCT_V2_CONTRACT.md) defines what THIRTY is. **Amendment 4** holds the operative English-first rule. **Amendment 3** (2026-11-12) stays in force except where Amendment 4 names it.
2. The ADRs:
   - [ADR-025](adr/ADR-025-localization-architecture.md) (accepted localization architecture) carries a dated note: its six-language T2/T3 rollout set is superseded;
   - [ADR-026](adr/ADR-026-language-safe-persistence.md) (Part A approved; Part B HOLD; gate G-5C) is unchanged;
   - ADR-027 is not drafted.
3. [THIRTY_PRE_RELEASE_PRODUCT_GAP_REGISTER.md](THIRTY_PRE_RELEASE_PRODUCT_GAP_REGISTER.md) is the planning authority (gaps, gates, roadmap, founder decisions).
4. [THIRTY_V2_DELIVERY_TRACKER.md](THIRTY_V2_DELIVERY_TRACKER.md) holds status only.
5. [THIRTY_FUTURE_OPPORTUNITIES_REGISTER.md](../strategy/THIRTY_FUTURE_OPPORTUNITIES_REGISTER.md) is an index of deferred and future ideas. It authorizes nothing.
6. This record holds rationale and traceability only.

## 5. Why English first

- **Amendment 3 made all six languages a T2 and T3 condition.** Every language needed:
  - full copy, native review and native-quality Premium voices;
  - per-locale gates;
  - safe language identity for persisted records.

  Under that rule the first release waited on the slowest of six languages.
- **Most of that work has not started**, and parts of it are blocked by open decisions (ADR-026 Part B / D-L-5c, D-L-8, D-V-1…5). At the baseline, even English extraction is still incomplete: 24 ARB messages.
- **The release-critical risks are language-independent:**
  - onboarding;
  - content depth and safety clearance;
  - real billing, measurement, privacy, security and device validation.

  They need to be proven on one complete product first.
- **Doing English first keeps the quality bar.** THIRTY ships one language at full quality rather than six under schedule pressure. Each further language then gets its own native review, voices and evidence-based priority.
- **This changes the order of delivery, nothing else.** The approved product's completeness, safety, quality and commercial obligations are not reduced.

## 6. Scope of Amendment 4

Amendment 4 decides:
- the initial release language: English (`en`);
- the meaning of T0–T3 for that release;
- the deferral of five languages;
- the conditions for activating any further language;
- the status of December 2026.

It is recorded in the contract, not here.

## 7. What Amendment 4 supersedes in Amendment 3

These six points only:
1. the number of languages required at the initial T2 pre-release;
2. the number of languages required at the initial T3 public release;
3. the first-release scheduling of non-English Premium voice production;
4. the first-release scheduling of non-English store listings;
5. the first-release per-locale gating of the five deferred languages;
6. the derived language switching and non-English rollout sequencing.

## 8. What stays binding from Amendment 3

These apply to English now and to every language when it is activated:
- **English** is the canonical source of approved content.
- **"Complete"** means a language's whole user-facing experience passes functional, native linguistic, accessibility, audio and data-safety checks. Machine translation never qualifies a language.
- **Per-locale gates and parity:** full Free and Premium functionality with truthful feature and subscription copy. **Choosing a language is Free.**
- **Premium voice rules:**
  - a guided Circle speaks exactly one language;
  - no clip says words that differ from the screen;
  - no recording is replaced by another language's;
  - the frozen English pack is unchanged.
- **Zero unapproved hard-coded user-facing text** at release, enforced by guards.
- **Fallback:** an unsupported device language resolves to English. Within a supported language, a missing or unreviewed message fails the release build.
- **Identity and records:** identities are locale-independent, and stored records are immutable and shown as saved. There is no journal-schema or export-format change without its own decision.
- **"Circle"** stays under evaluation, per language (D-L-3).
- **Local-first:** no account, no cloud profile, no runtime machine translation or generated speech.

## 9. Test tiers (existing taxonomy; no new tier)

| Tier | Meaning |
|---|---|
| **T0: engineering testing** | Automated tests, developer builds, emulator, QA and device smoke tests. Never, on its own, evidence of release readiness |
| **T1: controlled pilots** | Bounded signed tests of a specific feature or condition. A billing, onboarding or other pilot is never a substitute for the complete product's T2 |
| **T2: full-product Google Play pre-release** | A complete approved **English** release candidate, carrying the full Free and Premium contract, through Google Play's appropriate closed-testing process |
| **T3: first public commercial release** | The English product, only after T2 evidence, every remaining commercial and release gate, a successful final independent audit and explicit founder authorization |

**Future language updates (`L-UPD`)** are a separately governed post-launch rollout stream, **not a test tier**. Each language has its own release brief, gates, implementation approval and final acceptance.

*(Correction of the draft: the draft's "T4 — post-launch language expansions" is withdrawn. The T0–T3 taxonomy is not changed.)*

## 10. T2 obligations: the complete English product

Every applicable T2 gate stays mandatory:
- the complete approved Free and Premium contract;
- genuine onboarding (G-01);
- the CD-1 content-depth decision and the SAF-1 / G-07 safety clearances made before the English copy freeze;
- complete English user-facing copy (G-02 English);
- the approved English Premium guidance: 180 bundled files, the frozen 172 plus 8 framing files (G-03 English);
- real billing and restore in Play (BIL-1);
- consent-gated measurement (MEA-1);
- privacy, support and Data Safety (PRV-1/2);
- the SEC-1 T2 subset;
- signed-device validation (DEV-1, including the outstanding S-12 S25 smoke);
- release signing (SIG-1);
- accessibility.

## 11. T3 obligations: the English commercial release

These are in addition to T2:
- the subscription lifecycle (BIL-2);
- Android backup and device transfer (A2-07: decision, configuration, verification);
- SEC-1 in full;
- the D-RL4 timestamp decision;
- the **English** store listing and slogan (STO-1, D-S English wording);
- the full device matrix;
- the formal SAF-1 record;
- the final independent release audit (AUD-1) on the English release candidate;
- explicit founder authorization.

The full before/after matrix is in the gap register §4a.

## 12. The five deferred languages

| Language | Code | Register |
|---|---|---|
| French | `fr` | LANG-01 |
| Dutch | `nl` | LANG-02 |
| European Spanish | `es-ES` | LANG-03 |
| German | `de` | LANG-04 |
| Italian | `it` | LANG-05 |

They are **deferred, not cancelled**. Nothing below is set:
- a delivery order;
- a guaranteed release date;
- a target country list;
- a translation vendor;
- a fixed voice count;
- a budget;
- a launch price.

A future update may ship one language at a time. Its sequencing depends on separately approved evidence: product, user demand, quality readiness, translation and voice upkeep, and economics.

## 13. Native-quality voice parity

Each activated language needs **approved native-quality Premium spoken guidance** before it ships.
- An absent voice pack never makes a language commercially complete.
- Unvoiced Premium is **not** an equivalent alternative.
- A truthful unvoiced state is allowed only in a clearly scoped T1 pilot, as Amendment 3 says.
- D-V-3 stays binding: no mismatched spoken language and no substitute voice.
- Any material relaxation of per-language Premium parity would need a later, explicit contract amendment.

*(Correction of the draft: the draft's parenthesis "or a separately authorized honest product-language restriction" is withdrawn. It could have been read as an automatic waiver of native-quality guidance.)*

## 14. Safe persistence and legacy data

- English-only is the active safe persistence configuration.
- **Gate G-5C** stays active: no build with a non-English release set may run against a real store or be distributed until D-L-5c is decided and, if approved, built.
- ADR-026 Part B / D-L-5c stays on **HOLD**.
- D-L-8, the running-Circle language, stays **OPEN** and must be decided before the first non-English build.
- Existing English History, kept Circles and Insight snapshots are never rewritten, translated or relabelled as if they had been created in another language.

## 15. English-only runtime constraint

Only English is enabled at runtime.
- A device set to any other language starts and works normally in English.
- No language selector is introduced by this decision.
- Whenever further languages are authorized, the language choice is Free.

## 16. Future rollout decisions

When a language is selected for rollout, a bounded per-language scope and acceptance criteria are created. They cover:
- the UI, content, notifications and accessibility;
- Premium and commercial truth;
- native audio;
- stored historical content;
- locale identity;
- migration and export integrity;
- tests and device evidence.

The language then needs its own founder rollout authorization. The open decisions D-L-3, D-L-4, D-L-6, D-L-8, D-L-9, D-V-1, D-V-2, D-V-4, D-V-5 and the locale-specific part of D-S belong to that work.

## 17. Remaining launch blockers

This decision clears **none**. At the baseline:
- **Open or on hold:** G-01 onboarding; English copy extraction (24 ARB messages only; G-02 Batch 9 not authorized); CD-1; SAF-1 and G-07 clearances; BIL-1 and BIL-2; MEA-1; PRV-1/2; SEC-1; DEV-1 and S-12 (NOT RUN); SIG-1 enrolment; A2-07; D-RL4 (HOLD); STO-1; AUD-1.
- **Unchanged holds and gates:** ADR-026 Part B / D-L-5c (HOLD), G-5C (active) and D-L-8 (OPEN).
- **Phase E:** HOLD. Public launch: PAUSED / NOT AUTHORIZED.

## 18. No fixed release-date promise

**December 2026 is a planning target**, not:
- a guaranteed public-release date;
- an approved store publication date;
- a waiver of missing gates;
- evidence of readiness.

If the gates cannot be met in December, quality is kept and publication is delayed. THIRTY will not knowingly launch an incomplete or unsafe product.

## 19. Future opportunities

The deferred languages and the other future ideas are indexed in [THIRTY_FUTURE_OPPORTUNITIES_REGISTER.md](../strategy/THIRTY_FUTURE_OPPORTUNITIES_REGISTER.md). Those ideas include richer Circle Coach, more Plans and Insights, Atmosphere, Watch, the product family, ritual products and earlier ideation. The register is an index, not a backlog or a launch requirement.

## 20. Governance, acceptance and implementation

- **Documents changed** (eight paths, documentation only):
  - modified: PRODUCT_V2_CONTRACT.md, THIRTY_PRE_RELEASE_PRODUCT_GAP_REGISTER.md, THIRTY_V2_DELIVERY_TRACKER.md, ADR-025, CLAUDE.md and docs/product/README.md;
  - added: this record and the Future Opportunities Register.
- **Not changed:** no code, test, asset, ARB, configuration, ADR-026 or strategy document.
- **Corrections to the source draft:**
  - The invented `T4` tier is replaced by the `L-UPD` stream.
  - The optional wording that could waive native-quality guidance is removed.
  - The draft's "PROPOSED / not yet integrated" status is replaced by §2's status table.
- **Acceptance:** this documentation change needs **independent acceptance** before it is treated as accepted, and a separate founder authorization to be pushed.
- **Implementation:** any code or content work, such as further English extraction, needs its own bounded founder authorization. So does any language update. This record authorizes none of it.
