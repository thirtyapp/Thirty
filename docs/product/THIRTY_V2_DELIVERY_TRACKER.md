# THIRTY V2 DELIVERY TRACKER

Status only. What is being built is defined in [PRODUCT_V2_CONTRACT.md](PRODUCT_V2_CONTRACT.md).

## Current state

| | |
|---|---|
| **PRODUCT V2 CONTRACT** | FROZEN (2026-10-08) |
| **PUBLIC LAUNCH** | PAUSED |
| **CURRENT IMPLEMENTATION PHASE** | PHASE C — NOT STARTED (Phase B complete) |
| **MEASUREMENT-1** | PAUSED, resumes in Phase E |

---

## Phase A — Activities that feel designed

**STATUS: PASS — COMPLETE** (2026-10-09; see [ADR-019](adr/ADR-019-v2-phase-a-activity-model.md))

- **Purpose:** give every activity real substance and an honest length before adding any intelligence.
- **Scope:**
  - Activity model metadata: PRIMARY / SECONDARY / NONE fit per need, minimum and typical minutes, mode, effort, setting, steps, and lighter treatment.
  - V1 → V2 **learning-compatibility classification** for every activity (LEARNING_COMPATIBLE or LEARNING_RESET). Retired activities contribute no learning.
  - Content rewrite to the V2 standard. Claude drafts; the founder approves.
  - Natural duration up to about 30 minutes. The ring follows the activity's length.
  - Retire the current concept of `energisingBreathReset` from the live catalogue. Its history stays.
  - Safety gating: breathing and relevant exertion content is excluded from external builds until reviewed.
  - How-to surfaced through progressive disclosure, using the **existing Circle as the interim host**. Guided steps may appear as a list here.
  - Humane record and history copy. Fix "Ready to close today's Circle?" appearing before start.
  - The old selector may remain until Phase B.
- **Acceptance:**
  - Founder device verdict: "this activity feels credibly designed and lasts the right amount of time."
  - Every activity meets its mode's content standard or is explicitly gated.
  - Catalogue invariants are tested.
  - Full test suite and analyze are clean.
- **Device proof:** S25 — representative Open and Guided activities end to end at their real lengths, in light and dark themes and with reduced motion.
- **Commercial question:** is the content worth following?
- **Dependencies:** none (founder decisions 1–4 are resolved).

## Phase B — Engine V2 and memory

**STATUS: PASS — COMPLETE** (2026-10-09; see [ADR-020](adr/ADR-020-v2-phase-b-recommendation-engine.md))

- **Purpose:** choices that change with explicit feedback, with a reason shown when evidence supports one.
- **Scope:**
  - Deterministic engine with multi-direction fit, time fit, feedback, recency, variety, exploration, sparse-data honesty and reason codes.
  - Time input: ≈ 10 / ≈ 20 / up to 30, preselected to the last choice, defaulting to ≈ 20.
  - "Not this one today".
  - New journal fields.
  - Acknowledgement at Close.
  - Delete removes learning; export gains the new fields.
  - Retire the V1 history keys.
- **Acceptance:**
  - Scenario fixtures pass.
  - A **deterministic 40-local-day simulation** proves all of the following:
    - feedback changes selection;
    - a single *Not useful* has a bounded effect;
    - positive evidence matters;
    - multi-direction fit, time fit, recency and variety all work;
    - no inferred permanent bans;
    - sparse-data honesty;
    - Delete removes learning;
    - learning-compatibility is respected.
  - Same inputs always give the same pick.
- **Device proof:** scripted multi-day run on the emulator plus an S25 spot check.
- **Commercial question:** can THIRTY decide better than the user?
- **Dependencies:** Phase A.

## Phase C — Circle experience and memory

**STATUS: NOT STARTED**

- **Purpose:** an experience inside the Circle that the founder judges worth having.
- **Scope:**
  - **Open / Guided Steps / Paced** modes. Paced only with reviewed content.
  - Completion moment and inline feedback.
  - Background and resume behaviour.
  - Reduced motion and screen-reader support.
  - The memory page with corrections.
  - Humane history.
- **Acceptance:**
  - Founder uses all three modes on the S25, including backgrounding, early exit, reduced motion and TalkBack.
  - **Technically correct but visually mediocre counts as a FAIL.**
- **Device proof:** S25 founder session, with visual review.
- **Commercial question:** do people actually do the activity?
- **Dependencies:** Phase B.
- **Milestone:** after acceptance, **Free V2 is ready for a closed test**.

## Phase D — Premium V2

**STATUS: NOT STARTED**

- **Purpose:** a Premium that builds the user's routines and keeps them working.
- **Scope:**
  - Module library with levels.
  - Paths, with their length still tunable.
  - Path review leading to a routine.
  - Toolkit, with its routines as candidates in Free.
  - Maintenance triggers (fading, time misfit, gap, user refresh) and an honest periodic check.
  - Lapse behaviour.
  - Retire V1 Plans, Coach and Insights, migrating their state.
  - New QA scenarios.
  - Offer-page copy. Price is not touched.
- **Acceptance — device/QA proof that:**
  1. Free history exists.
  2. A Path starts seeded from that history.
  3. The Path adapts after feedback.
  4. The Path produces a routine.
  5. The routine is usable in Free recommendation.
  6. A later evidence change creates a legitimate tune-up offer.
  7. The tune-up modifies the routine.
  8. A lapse or cancellation keeps the routine.
  9. Premium-only operations stop appropriately.
  10. A meaningful Month-2 QA scenario exists.
- **Commercial question:** will people pay, and keep paying?
- **Dependencies:** Phases B and C.

## Phase E — Measurement & release

**STATUS: NOT STARTED**

- **Purpose:** a measurable, compliant launch.
- **Scope:**
  - MEASUREMENT-1 resumed for the V2 funnel, including the consent-copy decision and a production Supabase project.
  - Privacy policy and support contact.
  - Play Data Safety.
  - Live RevenueCat billing, with cadence chosen from the commercial hypotheses.
  - Store listing.
  - Slogan decision.
  - Release notes.
- **Acceptance:** the release gate below.
- **Device proof:** release build on the S25, plus a live purchase and restore.
- **Commercial question:** D7, D30, feedback response rate, conversion and pause behaviour.
- **Dependencies:** Phase D.

---

## Release gate

Public launch requires **all** of the following:

- Phases A–E accepted on device.
- The safety review completed for every live breathing and exertion activity.
- The founder can defend each review gate below. These are review gates, not automated scores.

| Area | Gate |
|---|---|
| First session | ≥ 7 |
| Free | ≥ 7 |
| Personal relevance (design) | ≥ 7 |
| Perceived intelligence (design) | ≥ 7 |
| Content depth | ≥ 7 |
| Day-7 design potential | ≥ 7 |
| Day-30 design potential | ≥ 7 |
| Premium value | ≥ 7 |
| Premium differentiation | ≥ 7 |
| Month-2 design potential | ≥ 7 |
| Visual / emotional | ≥ 8 |
| Trust | ≥ 8 |
| Monetisation | Credible architecture (economics unproven) |
| Overall product | 8 target |

- Closed-test evidence reviewed, including feedback response rate and early retention.
- Privacy, support, Data Safety, truthful consent, production telemetry and live billing proven.
- No "AI" positioning in store copy.

## Log

- **2026-10-08** — V2 contract frozen. Founder decisions recorded:
  1. Breathing/exertion: option B.
  2. Content authoring: option A.
  3. Time windows: ≈ 10 / ≈ 20 / up to 30 (tunable).
  4. Delete scope: option A.

  Migration correction (history visibility ≠ learning eligibility) adopted.
- **2026-10-08** — Phase A implementation candidate ready for founder review: content, durations, learning classifications and the interim Circle. Not committed; not accepted.
- **2026-10-09** — Founder-review correction pass and S25 proof: three titles polished (A brisk walk, A quick standing stretch, Listen to one thing); brisk-walk guidance made distinct from Easy walk; two S25 display fixes (Today card text never truncated; how-to sheet clears the navigation bar). Still uncommitted; founder approval pending.
- **2026-10-09** — **Phase A PASS — COMPLETE.** Founder approved the Phase A product direction. Final decisions applied: Start Circle layout correction (near-fit spacing, then a ≤ 4% Circle trim for two-line titles on 3-button navigation only); A brisk walk is LEARNING_RESET; A quick standing stretch is 5 minutes; Clearer Head meaning reads "fewer things competing". Final S25 acceptance passed: 3-button and gesture navigation, light and dark, normal and 130% text.
- **2026-10-09** — Final quality note: a running Circle's **Close Circle is now fully visible** on the S25 with 3-button navigation for every live activity (was up to 13pt under the tab bar for three-line first actions). The near-fit rhythm continues into the running state — running gaps, then card padding, then the space above the first action, then clearance — and the Circle never changes size between Ready, running and closed. Phase A remains PASS — COMPLETE.
- **2026-10-09** — Phase B implementation candidate ready for founder review: Recommendation Engine V2 (pure, deterministic, journal-derived), time input, "Not this one today", reasons, feedback acknowledgement, journal fields, V1 history keys retired, six 40-day simulations and S25 proof. Not committed; not accepted.
- **2026-10-09** — Phase B founder quality correction: "Not useful" now outranks variety (fallback order weekly cap → yesterday's activity → a rest, closest to expiry and weakest first, ADR-020 §6), proven by pathological simulations 7a–7c; "Not this one today" made discoverable by a quiet cue on the card's activity row (ADR-020 §10). Still uncommitted; founder review pending.
- **2026-10-09** — **Phase B PASS — COMPLETE.** Founder approved the Phase B product behaviour. Recommendation Engine V2 is the Free daily selector. Frozen: explicit "Not useful" outranks variety — normal rules → weekly cap → yesterday's activity → only then a temporary rest, closest to expiry and weakest evidence first, labelled `fallback` with no personal reason; consecutive repetition is a fallback only (ADR-020 §6). Recourse: before Start the activity row reads "How to do it · Not this one?" ("Not this one?" where the full line would wrap; "How to do it" once swapped), opening the how-to with "Not this one today" and the three reasons — one replacement a day. Final audit and human trace review of all simulations (sparse, positive, negative, mixed, migration, delete, broad-negative) passed. S25 acceptance: 3-button and gesture navigation, light and dark, normal and 130% text; no Phase A geometry regression. Full suite 1733 passed, 0 failed, 0 skipped; analyze clean.
