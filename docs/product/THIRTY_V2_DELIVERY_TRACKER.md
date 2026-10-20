# THIRTY V2 DELIVERY TRACKER

Status only. What is being built is defined in [PRODUCT_V2_CONTRACT.md](PRODUCT_V2_CONTRACT.md).

## Current state

| | |
|---|---|
| **PRODUCT V2 CONTRACT** | FROZEN (2026-10-08); Amendment 1 (2026-10-11); **Amendment 2 — architecture and content freeze APPROVED (2026-10-17)** |
| **TARGET IA** | Today \| Plans \| Insights \| You — built as the final four-tab shell since B7 (2026-10-20) |
| **PUBLIC LAUNCH** | PAUSED |
| **CURRENT IMPLEMENTATION PHASE** | PHASE D2 — PASS — COMPLETE (2026-10-21; batches B0–B9 closed in the single D2 closure commit). Awaiting the two independent post-D2 audits of that commit. Phase E on hold. |
| **D2** | PASS — COMPLETE (2026-10-21; closure commit; ADR-023 Accepted, ADR-024 Accepted). Post-D2 audits pending on the closure commit. |
| **PRODUCTION AUDIO** | PASS — FROZEN: 4 voices (Locke, Heather, Milo, Brittney) × 43 files = 172. One file corrected 2026-10-18 after B4 QA (Locke `part_songOn`); the other 171 are byte-identical |
| **PHASE E** | HOLD |
| **POST-D2 AUDITS** | Mandatory: two independent audits (Claude; GPT-6 Astra) of one immutable pushed SHA — the D2 closure commit, whose full SHA is recorded in the B9-B report and the audit hand-off (a commit can't name itself). A material blocker from either restarts both on a new SHA. Audit #1: NOT STARTED. Audit #2: NOT STARTED. |
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

**STATUS: PASS — COMPLETE** (2026-10-10; see [ADR-021](adr/ADR-021-v2-phase-c-circle-experience-and-memory.md))

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

**STATUS: PASS — COMPLETE** (2026-10-10; see [ADR-022](adr/ADR-022-v2-phase-d-paths-toolkit-and-maintenance.md)) — the historical V2 Premium architecture. Its Premium headline is superseded by Phase D2 (ADR-023). Its Paths, routines, Toolkit and maintenance are **retired before public release** by [ADR-024](adr/ADR-024-v2-circle-plans-insights-and-four-tab-product.md) (2026-10-17). Their removal was D2 batch B1 (implemented and verified 2026-10-17).

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
- **Carried from Phase C (ADR-021, Consequences):** an explicit per-need "Don't suggest" MUST be respected by the new Path / Toolkit architecture — no Path stage, routine, Toolkit candidate or tune-up may offer an activity for a need the user asked THIRTY not to suggest it for. No temporary V1 Plan compatibility work.
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

## Phase D2 — Recurring Premium redesign (Personal Guided Circle)

**STATUS: PASS — COMPLETE** (2026-10-21; started 2026-10-11; see [ADR-023](adr/ADR-023-v2-recurring-premium-personal-guided-circle.md), [ADR-024](adr/ADR-024-v2-circle-plans-insights-and-four-tab-product.md), and contract Amendments 1 (2026-10-11) and 2 (2026-10-17))

- **Purpose:** give monthly Premium legitimate recurring jobs.
  - **Today:** a newly composed Personal Guided Circle.
  - **Direction:** an operating Circle Plan.
  - **Understanding:** new evidence-aware Insights with user-approved applications.
  - **Guidance:** THIRTY's spoken guidance with background playback.
  - *Amended 2026-10-17:* Phase D's Paths, routines and Toolkit are retired before public release (ADR-024); kept Circles are the only owned object.
- **B0 — governance freeze: COMPLETE (2026-10-17).**
  - Contract Amendment 2, ADR-024 (Proposed), ADR-023 drift corrections, the ADR-022 supersession note and this entry.
  - Uncommitted, for founder review.
- **B1 — pre-release removal: IMPLEMENTED AND VERIFIED (2026-10-17).**
  - Paths, routines, tune-ups, shorter versions, maintenance, the Phase D module library and the Toolkit tab removed; kept Circles managed in Yours, under You; an idempotent migration keeps kept Circles and drops only the retired fields.
  - Interim shell Today | You (not the final IA). Retired routes go to Yours (kept-Circle ownership) or Today.
  - Gates: tests 1,571/0; analyze clean; Android debug build; emulator and S25 smoke (sandboxed QA scenario D2-E; the S25's real data gained only the migration marker).
  - Uncommitted, for founder review.
- **B2 — composer seam / StageBrief: IMPLEMENTED AND VERIFIED (2026-10-17).**
  - One optional StageBrief input to the existing composer: it only narrows which gate-passing Circles may be chosen. Without one, the composer is unchanged from B1 (957 recorded days, identical).
  - The twelve fixed briefs, stage 5's four cases, and set aside / wait as a pure probe. Pure domain only: no Plan state, persistence, UI or route, and nothing in the live app uses a brief.
  - Gates: tests 1,650/0, including the 45-cell feasibility matrix at its frozen counts, set aside / wait, stage 5, Not useful and the More Energy attack; analyze clean; Android debug build. S25 not required (inactive seam).
  - Uncommitted, for founder review.
- **B3 — Plan domain + runtime: IMPLEMENTED AND VERIFIED (2026-10-17).**
  - The three launch Plans on the B2 briefs; per-Plan place, cycles and stage records (`circle_plans_v2`); one active Plan; start, pause, carry on, leave, go through again, revisit; Premium enforced at the service boundary.
  - Today: an applicable stage first, then the Personal Guided Circle, then Free; wait, set aside (the next stage tried the same day), "Not this one today" inside the stage first, "Use it today" wins, guided once on start + close, lapse stops steering and progression.
  - Journal schema 2: a stage Circle's provenance travels with its offer; version-1 journals read unchanged. The export carries the Plans; Delete history removes stage evidence and keeps each Plan's place.
  - No Plans tab, Plan UI or Insights; the shell is still the interim Today | You. The two new QA scenarios (D3-A, D3-B) and the marker's Plan line exist only in the QA harness.
  - Gates: tests 1,699/0; analyze clean; debug and QA Premium debug builds. S25 PASS: matching need, different need, Use it today, lapse/resume, set aside and ordinary Today (sandboxed QA; real data unchanged).
  - Closure addendum (2026-10-17): Delete history now also removes why and when a cycle ended (unless the user left) and the last guided Circle id, so no review can outlive its deleted evidence. Tests 1,706/0; analyze clean; both debug builds. The S25 run predates this fix, which no S25 check exercises.
  - Governance (founder decision, 2026-10-17): Stage-5 eligibility is current-cycle only. The contract's and ADR-024's *Repeat cycle* wording now says so: all history still shapes the composer's ranking, and cross-cycle comparison is for reviews and later Insights. The implementation was unchanged.
  - Final-code S25 check of Delete history: PASS (installed APK sha256 1bc64bce…, the post-fix build behind the gates; sandboxed D3-A):
    - stage 3 reached with 2 guided stages and an answer;
    - the real Delete Circle history control: history empty, 1 kept Circle, stage 3 kept, 0 guided;
    - More Energy then served stage 3, with no "found useful" claim;
    - the phone's real data was byte-identical afterwards.
  - Uncommitted, for founder review.
- **Implementation (ADR-024 §14), continued** — B0–B9 are all closed in the D2 closure commit (2026-10-21). The "uncommitted, for founder review" notes below record each batch's state when it was verified:
  - **B4** — Plans tab: IMPLEMENTED AND VERIFIED — PASS (2026-10-18; uncommitted, for founder review).
    - Built: Plans landing (Your Plan first, then the others), Plan detail (status, the five-stage arc, revisit, pause, carry on, leave, switch), the review ("What you told THIRTY", cases A–D, compared with last time, Keep, repeat), Today's stage context line, the after-end entry on Today, the offer's Plans line, and a QA review scenario (D4-A).
    - Interim shell Today | Plans | You; the frozen shell is Today | Plans | Insights | You.
    - Gates: tests 1,738/0 (re-run 2026-10-18); analyze clean; debug and QA Premium debug builds; emulator visual QA; S25 A–I PASS, including 1.6× text.
    - Final S25 checks (2026-10-18; installed APK sha256 1dd81ef3…, the build behind the gates; sandboxed D3-A):
      - Revisit served: stage 1 was asked for again at place 2, and the next More Energy choice served stage 1 while the place stayed at 2. The Circle was started and closed: stage 1 now reads "Guided 18 Oct", no revisit is left to ask for, and stage 2 is "Next" again. No double move.
      - The next day's forward Circle was not walked on the phone, because changing the phone's date would have fired its real alarms. The live test "served on the next matching day; the place stays" covers it, with day + 1 serving the forward stage.
      - TalkBack walk (founder): PASS. The order and labels were truthful, with no "completed" wording and no traps. Minor: focus stops once on the Today tab before the last stage row, which sits under the floating nav bar; it then scrolls and reads the row.
      - Accessibility services restored exactly (CCleaner only); the phone's settings were restored; its real data was byte-identical.
    - Found during the run, outside B4: Locke's "Put a song on" clip has an extra syllable after "really like". This is a D2 voice-pack finding, corrected in a bounded pass the same day (see Production voice pack below).
    - B5 not started.
  - **B5** — Insights domain: IMPLEMENTED AND VERIFIED (2026-10-18; uncommitted, for founder review).
    - **Built** (`lib/features/insights/`):
      - a pure, deterministic evaluator of the six frozen families (I1–I6), each with its own gate and the pattern-gate floor;
      - snapshots holding the shown text, structured facts, evidence ids, wording version, and applied / "Not now" / "Keep it" dates; at most 52; readable after a lapse;
      - pull-based assessment: Plan reviews at once; otherwise at most one new Insight per 7 days, in priority I3 > I2 > I4 > I1 > I6; "Not now" hides that evidence set for 28 days, and materially new relevant evidence may qualify again; nothing is pushed;
      - readiness states for B6 (no History, too short, nothing qualifies, cadence waiting, Insight available) with the Week-1 counts.
    - **Applications:** explicit, through their own domains, and safe to repeat.
      - I1/I6: start, carry on with, or go through the Plan again.
      - I2: "Keep this Plan's Circles gentler for now".
      - I3: the existing Leave it out.
      - I4: Keep, never replacing at the limit of 8.
      - I5: a reference to the B3 cycle that B4 shows — no second review engine.
      - Generating and applying are Premium, checked at the service.
    - **I2 on the composer:**
      - The cycle's `gentlerSince` setting composes stage Circles from low-effort parts, one size below today's time (never below ≈10). All 45 stage × time cells stay feasible.
      - The setting ends with the cycle and can be turned off.
      - Offers composed under it carry `gentler` provenance and never count as evidence.
      - Ordinary composition is unchanged.
    - **Journal:** `replacedFromPlanStage` records the stage of a Circle "Not this one today" replaced, so I2 can count stage offers.
    - **Delete history and export:** Delete history removes every snapshot; leave-outs, kept Circles and the Plan's place and settings stay. Export carries the snapshots.
    - **Gates:**
      - analyze clean; tests 1,886/0 (148 new);
      - B2 feasibility 45/45; composer equivalence 957/957;
      - debug and QA Premium debug builds.
      - S25 not required: no Insights UI is live, and no production-visible behaviour changed.
    - **12-month structural simulation** (seven profiles): no pattern before two weeks; I3 from month 1 for a skipper; I4 from month 3 for an answerer; I6 only after month 3; cross-cycle reviews by month 6; the cap holds; nothing new while lapsed.
      - Limit: a single-need user who never answers mostly sees I1 every 28 days, plus Plan reviews.
      - Record: `artifacts/v2_phase_d2/b5_insights/`.
    - **Still interim:** no Insights tab, page or calendar. The shell is still Today | Plans | You.
    - **Contract closure (2026-10-18):**
      - "Not now" now hides that evidence set, not the subject. The fingerprint is the subject plus the family's relevant Circle ids, sorted. Materially new relevant evidence may qualify again under the cadence, gate and priority.
      - I3 "Keep it" is a plain dismissal: no preference, answer or ranking evidence.
      - I2 has no Plan-level cooldown; it follows the same evidence-set rule, and the setting still ends with its cycle.
      - Plan reviews can't be dismissed with "Not now".
      - Gates: analyze clean; tests 1,897/0; both debug builds.
      - Recorded for the founder: the rule lets I1 and I2 return about weekly while new evidence keeps arriving (`artifacts/v2_phase_d2/b5_insights/README.md`).
    - **Anti-repetition closure (founder decision 2026-10-18, from the B5 simulation):**
      - The same claim — family and subject (I1–I4, I6) — is shown at most once in any 28 days from when it was shown, whatever the user did; priority applies among eligible claims.
      - "Not now" also hides that evidence set; I5 stays immediate and separate; no novelty quota.
      - The rule is derived from the snapshots, and the cap keeps ordinary snapshots under 28 days old.
      - Contract and ADR-024 cadence lines updated.
      - 12 months: at most 12 showings of one I1 or I2 claim a year (was 39 and 32); I6 surfaces for a user who starts every Plan; 31–42 silent weeks of 52.
  - **B6** — Insights surface + calendar: IMPLEMENTED AND VERIFIED — PASS (2026-10-18; uncommitted, for founder review).
    - **Built:**
      - the production `/insights` page (the B1 redirect removed). It is a top-level route with no tab: the shell stays Today | Plans | You until B7.
      - the V1 calendar, restored and shared. It opens `/history/:date` and `/history`. Dates read "Circle closed in THIRTY" or "Circle recorded, not closed"; no-record dates are not TalkBack stops; the month header counts the recorded dates.
      - Free, Premium early-life and lapsed states, using the frozen ADR §12 lines.
      - the current Insight, with its evidence, its application and "Not now" (never "Keep it");
      - Earlier: dated, compact rows, four shown and the rest on request;
      - I5 references opening the canonical B4 review, with `?cycle=` for earlier cycles, shown as a record.
      - the I2 note plus "Use usual pacing" on Plan detail, never gated.
    - **Rules:**
      - The UI reads B5 service state only; it reimplements no eligibility.
      - No charts, scores, streaks or analytics. No new families, audio or composer logic.
      - Offer copy is untouched (left for B7).
    - **QA:** scenarios E6-0 and E6-A…E6-H, which open on Insights.
    - **Gates:**
      - analyze clean; tests 1,969/0;
      - debug `d90c7ed2…` and QA Premium debug `027dca36…` builds;
      - emulator visual QA (Pixel 7, light and dark, 1.6× text);
      - S25 A–I PASS on sandboxed data: calendar, early week, Not now, I2 apply and turn off, I4 Keep, Nothing to change, I5 current and earlier cycle, lapsed, Delete, 1.6× text.
      - The S25's real data was byte-identical afterwards, and its settings were restored.
    - **J (TalkBack), final closure (2026-10-18):**
      - The founder's live walk passed on the S25 (installed QA APK `027dca36…`, matching the final B6 source; sandboxed E6-C; screen recording kept).
      - Order heard: "Insights · Your own record, and one useful change.", then Now, then the card as one stop (kind, observation, evidence), then "Leave it out next time", "Not now", "Your Circles", "October 2026. Circles recorded on 11 dates.", previous and next month.
      - Dates read "…, Circle closed in THIRTY" and "Friday, October 16, 2026, Circle recorded, not closed", then "See as a list".
      - No focus trap, no completion, streak or missed-day wording, and no meaningless duplicate stops. Targets are at least 48 dp.
      - Afterwards: TalkBack off; accessibility services restored exactly (CCleaner only); QA off; settings restored (30 s timeout, stay-awake off, text 1.0); the phone's real THIRTY data byte-identical to the fresh pre-walk backup.
      - No code changed for the closure.
    - **Fixed during QA:**
      - earlier I5 rows are dated by the cycle's end;
      - status labels no longer break mid-phrase;
      - the calendar keeps room for the unclosed dot at large text sizes.
    - **QA-only quirk:** QA opens Insights as the root, so Back leaves the app. B7's tab replaces this path.
  - **B7** — four-tab shell + integration gates: IMPLEMENTED AND VERIFIED — PASS (2026-10-20; uncommitted, for founder review).
    - **Shell:** Today | Plans | Insights | You (Insights its own branch at `/insights`; the Phase D1 Insights icon). No badge or lock on a tab; no tab opens the offer. TalkBack: "<name>, Tab n of 4", with the selected state. Each branch keeps its own state (Insights month, a pushed Plan); re-tapping a tab returns it to its root. Back at a tab root leaves the app without bouncing through tabs; History, Memory and the offer are pushed over the shell and return to the tab that opened them; opened by their own location (no page beneath), Back leads to their parent surface (`ThirtyAppBar.parentLocation`). Insights assesses whenever it comes on screen, since the tab outlives each visit.
    - **You (final placement, founder decision 2026-10-20):** Personal (name, What THIRTY remembers — with Reset suggestion preferences inside it — Yours, Your Circles) · Premium card · Preferences (reminder, appearance, spoken guidance + four voices only with Premium) · Data & privacy (Share anonymous usage data, Copy as text, Delete Circle history) · About · Restore. Analytics consent moved from Preferences to Data & privacy as presentation only: same control, value and default. No duplicate controls; nothing retired. Contract and ADR-024 §2 aligned.
    - **Offer copy (draft for founder review):** the approved headline "A Circle made for your day"; the promise "One guided Circle for today, made from the time you have — and, over the weeks, a direction for your Circles and what they show."; points Made for you · Guided for you · Plans to follow · Insights · Shaped by your answers ("Yours to keep" removed — owning is no Premium benefit); Free line names what stays free; the lapse line adds "A Plan keeps its place. The Insights you've seen stay readable, and your History and everything you kept stay yours." You's card: "A guided Circle made for your day, Plans that give several Circles a direction, and Insights from your own Circles." Price stays the store's localized monthly price; no trial, annual or urgency.
    - **Entitlement, at the service boundary:** a matrix over initializing, unavailable, inactive, active, grace and cancelled-but-paid (billing reports both as active) and true expiry — composition, voice, Plan start/carry on/repeat/revisit/gentler, Insight assessment and application are refused by their services without Premium; gentler off, pause, leave, Keep, History and snapshots never need it. **Fixed:** "Leave it out next time" was offered and recorded on a Free day's kept Circle; Leave it out is Premium (contract), so the service now records it only with Premium and the skip sheet offers only today's skip on Free.
    - **Copy truth fixed:** the Delete confirmation now says Insights and Plan reviews go and each Plan's place is kept (contract, Delete / Export).
    - **Gates:** analyze clean; tests 2,041/0 (new: four-tab shell and routes 25, entitlement matrix 40, You hierarchy 2, offer copy guards); B2 45/45 and 957/957 inside the suite; audio 172 files unchanged; debug `1b4aa4bc…` and QA Premium debug `829b647e…` builds; emulator visual QA (Pixel 7: Today, Plans, Plan detail, Insights Free/Premium, You Free/Premium, offer, lapsed Plans/Insights, 1.6×).
    - **S25 (sandboxed QA, APK `829b647e…`):** four tabs; Free walk; Premium walk (stage-steered Today, Insight applied, voice settings); cross-links Plan → Today, Insight → Plan → Back, calendar → record → Back, You → Yours, offer → Back; lapse (Free Today, saved place, earlier Insight readable, kept Circle in Yours); direct `/insights` and root Back; 1.6× text — PASS. TalkBack (founder walk): tab names, positions and selection heard; Plans, Insights and You opened by double-tap with one root item read on Plans and Insights. Real data byte-identical afterwards; settings and accessibility restored.
    - **Noted, not changed:** the Insights glyph has no filled variant, so its selection is the sage colour and bold label (as in the approved D1 shell); You's card shows Become Premium when the store has no price (the offer page then explains it); the QA marker's full-screen accessibility node can take TalkBack focus (QA builds only).
  - **B8** — simulations, review packs, content guards: IMPLEMENTED AND VERIFIED — PASS (2026-10-20; uncommitted, for founder review). Record: `artifacts/v2_phase_d2/b8/` (README, CONTENT_REVIEW_PACK + MANIFEST, REVIEW_MATRIX, simulations).
    - **Whole-product 12-month simulations** through the production providers (structure only — no market, retention or health evidence):
      - **Non-responder:** every Premium day composed (311/311), 21 Plan cycles, Stage 5 always case A, honest "no answer" reviews, I1/I5/I6 only, no "found useful" claim.
      - **Mixed answerer:** Stage 5 A/B/C from this cycle's eligible stages only; 16 of 18 reviews compare cycles where answered; I4 with denominators; missing answers never negative.
      - **More Energy ≈10:** 365/365 composed, no stall, safety intact; 6 mains, 19 materially distinct and 52 exact sessions; first exact repeat on day 23, never on consecutive days. WEAK — a real-user risk, not a blocker (ADR-024 §10, unchanged).
      - **Lapse and return:** nothing owned lost; new composition, voice, Plan operation and new Insights stop and resume; a kept Circle could stand in on 111 of 120 lapsed days.
      - **Insights:** 24–42 of 53 weeks silent; no cadence, same-claim or cap violation.
    - **Plan and Delete attacks:**
      - Stage 5 checked exhaustively: 625 combinations × 3 Plans against §7, every made Stage 5 composed at all three times (1,827/1,827).
      - 40 adversarial cycles per Plan, with all-rejected, all-set-aside and mixed phases: no stall, loop or duplicate progress.
      - Delete history mid-history at stage 3, before stage 5, after an end, and after a Leave: the place and settings stay; evidence, reviews and snapshots go and are never rebuilt.
    - **Content guards over the live product:** every production string literal, against retired product, false completion, streak/guilt, health claims, hidden inference, Premium drift and AI. Every exception is allowlisted with a reason, and the allowlist itself is checked for staleness. No live violation.
    - **Review pack:** generated from production source (619 strings, content hash in MANIFEST); a test fails if live copy drifts from it. Founder flags:
      - More Energy is thin at ≈10 and at up to 30;
      - "Your routine" still labels old routine records (development devices only);
      - apostrophes are mixed.
    - **Fixed:** past the 52-snapshot cap, dropped Plan reviews were generated again as new (440 shown for 75 cycles in the More Energy run; B5's own active Plan user 72 for 48). Now each review is shown once (`assessInsights`); below the cap, behaviour is unchanged.
    - **Commercial attack:** structurally plausible, not validated. Free solves the daily job; Premium's four continuing jobs remain after lapse and without answers; answer-rate dependency MEDIUM; Month 12 adds no new mechanism over Month 6. Largest structural weakness: for a rare answerer on one need, the daily difference narrows to fresh composition, voice and direction, while kept Circles can cover most days.
    - **Gates:**
      - analyze clean; tests 2,071/0; B2 45/45 and 957/957;
      - debug `c06ba373…` and QA Premium debug `208ffe0e…` builds;
      - S25 bounded smoke of the fix (E6-H Plan reviews, re-assessed twice): PASS.
      - The S25's real THIRTY data was byte-identical. The native reminder schedule rolled forward to the next day's 17:32, as it does daily.
  - **B9** — S25 QA, founder review, closure:
    - **B9-A** — final device QA + D2 closure candidate: PASS (2026-10-20; founder approval 2026-10-21). Record: `artifacts/v2_phase_d2/b9/`.
      - **S25 rounds** (sandboxed QA, APK `208ffe0e…`, built from the final source): Free, active Premium, lapse/resubscribe, ownership, delete/export, 1.6× — PASS.
        - Covered: the voice and background playback (foreground `GuidanceService`, playback seen); Plan progression by one; Insight applied; no second Insight after Not now; the kept Circle voiceless and skip-only on a lapsed day; the truthful Delete warning; the Plan place and kept Circle surviving Delete.
      - **TalkBack** (founder): shell, Today, Plans and Insights PASS; You carried from the B7 closure walk (code unchanged).
        - Device finding: the S25's Samsung speech engine garbles one label ("Tuesday, October 20, 2026, Circle recorded, not closed"). It is clean on Google's engine on the same phone, and every other label tested is clean. THIRTY sends one correct utterance.
        - A day-first date format was tried and did not help, so it was reverted byte-for-byte. A device-engine finding, not a defect.
      - **Founder content closure sheet:** no new decision required.
        - More Energy thin: WEAK, not a D2 blocker, real-user risk.
        - "Your routine": unreachable on a clean install; legacy compatibility only.
        - Apostrophes: non-blocking editorial inconsistency.
      - **Docs:** the B8 I5 rule is recorded in the contract and ADR-024 §11. No other material drift.
      - **Public-release safety review:** REQUIRED before public release — not a D2 implementation blocker; the gated exertion and breathing content stays disabled.
      - **Production audio:** 172/172 match `PRODUCTION_SHA1.txt`.
      - The S25's real data was byte-identical to the fresh B9 baseline; the phone was restored.
      - **Acceptance review and S25 evidence top-up (2026-10-20, founder decision):**
        - **Founder content decisions:** the Delete warning is approved (its last sentence verified against storage, below); the B8 Plan-review rule is approved; More Energy WEAK is an accepted, non-blocking risk; mixed apostrophes and the legacy "Your routine" label stay unchanged.
        - **Delete, verified against storage and recovery:** Android backup is off (`android:allowBackup="false"`), nothing syncs history off the device, and anonymous usage data is off by default and never read back. One gap fixed: a Plans or Insights record set aside as unreadable (`circle_plans_v2_unreadable`, `insights_v2_unreadable`) now goes with Delete too (a regression test is added). An unreadable kept-Circles record stays, like the kept Circles.
        - **New QA-only scenarios:** D4-B ("Slowing down" through once with no answers: review case A) and D4-C ("Making room" with every stage Not useful: case D), each with a scenario test.
        - **S25 (sandboxed, QA APK `93b13a22…`, built from the final source):**
          - Review case A: "You didn’t answer after these Circles, so THIRTY can’t say which stages suited you." Every stage reads "No answer". PASS.
          - Go through it again: a new cycle at "Stage 1 of 5 · Slow hands", nothing guided yet. PASS.
          - Review case D: "You said none of these stages was useful, so THIRTY hasn’t made a last Circle from them." Four stages read "You said not useful", stage 5 isn't marked guided, and only "Choose another Plan" and "That’s enough for now" are offered. PASS.
          - I3 applied: "“Open a window” is left out. You can put it back in What THIRTY remembers." Memory lists it with "Put it back: Open a window". PASS.
          - Four-tab shell in dark mode: already proven in the B9-A rounds, which ran on the S25's system dark theme (Today on a stage day, Plans, Insights, You). Not repeated.
        - **Gates:** analyze clean; tests 2,074/0; review-pack manifest unchanged (619 strings); debug `373166b0…` and QA `93b13a22…` builds.
        - The S25's real THIRTY data was byte-identical afterwards. The reminder is still scheduled for the next 17:32, and settings are restored.
        - **Docs:** stale status lines corrected (ADR-024 Implementation, ADR-023 "What Accepted still needs", the Phase D line about B1). The three "Proposed" mentions flip only in the closure commit.
    - **B9-B** — the single closure commit, push and audit hand-off: PASS (2026-10-21, founder-authorized). The governance edits (ADR-023 and ADR-024 Accepted, D2 PASS — COMPLETE, the ADR index), one commit from the reviewed manifests (`artifacts/v2_phase_d2/b9/closure_stage_*.txt`, exclusions in `closure_exclude.txt`), a clean-checkout verification, and the push. The full SHA is recorded in the B9-B report and the audit hand-off. Independent Audit #1 and #2: NOT STARTED. Phase E: HOLD.
- **Scope:**
  - Governance: ADR-023, ADR-024, both contract amendments, and this entry. Phase D's history is untouched.
  - An element model and a safe release element library, with a coverage report.
  - A pure, local, deterministic composer with a documented quality gate and time-use policy, falling back to Free when no honest composition exists.
  - Premium Today integration, and a guided composed runtime on Phase C's shell.
  - Element controls: skip this step, and leave this out next time, reversible in Memory, with documented evidence boundaries.
  - Ownership: "Use it today" (Free), kept Circles, and the lapse boundary.
  - Paths, Toolkit and maintenance repositioned as supporting infrastructure *(done as built; now superseded — retired before public release by ADR-024, batch B1)*.
  - Truth fixes: the hidden routine rest from Path-trial answers, the Toolkit check's "working well" claim, and the time-misfit wording *(done; moot once B1 removes routines)*.
  - Premium offer copy for the recurring job. Billing stays a subscription; price is untouched.
  - Long-horizon internal simulations (day 1 to month 12), a content pack, and device QA.
  - *(Added 2026-10-17, ADR-024.)*
    - Three launch Circle Plans with fifteen StageBriefs.
    - The Plan runtime: guided / wait / set aside, revisit, pause, leave, review, repeat, lapse.
    - Six Insight families with snapshots.
    - The restored Free calendar inside Insights.
    - Today | Plans | Insights | You, and Yours under You.
    - Removal of Paths and routines, with the migration of kept Circles.
- **Acceptance (all required):**
  - Recurring Premium contract frozen.
  - Element model and safe release library complete.
  - Composer, Premium Today and composed runtime complete.
  - Explicit element control complete.
  - Free unchanged in capability, and owned Circles stay Free *(amended 2026-10-17: kept Circles are the only owned object)*.
  - Hidden-rest and truth-copy defects fixed.
  - No gated or retired content leaks.
  - Long-horizon simulations pass structurally.
  - Full suite and analyze clean.
  - Real-device QA and TalkBack pass.
  - Founder content review passes.
  - Founder approval of the production voice recordings — **DONE (2026-10-17): 4 voices, 172 production files (42 cues + 1 Preview each), PASS — FROZEN.**
    - **Correction (2026-10-18), Production voice pack:**
      - The founder heard a defect during B4 QA: Locke `part_songOn_6017657f.m4a` had an extra garbled syllable after "really like", about 450 ms of voiced sound at speech level.
      - Bounded triage covered 9 candidates (5 shortlisted plus 4 automated-scan flags). Locke `songOn` was the only confirmed defect; the rest were false positives, three of them cleared by the founder's ear.
      - The automated scan cannot clear a clip: it also scores the known defect as clean.
      - Replaced with the founder's pick, c3 (seed 33), out of 3 takes on the frozen voice, model and settings, mastered by the frozen rule at Locke's frozen gain. c1 had the same defect.
      - Founder approved the take by ear on PC and in the app on the S25.
      - Same file name (the script is unchanged); the manifest and app code are unchanged. 171 of 172 files are byte-identical (SHA-256); `PRODUCTION_SHA1.txt` verifies 172/172.
      - 234 characters. Record: `artifacts/v2_phase_d2/voice_production/b4qa_voice_review/`.
      - Production audio: PASS — FROZEN.
  - Android background playback for a voiced Circle works on the S25, including screen off and locked (founder decision E, 2026-10-12) — **DONE**.
  - *(Added 2026-10-17, ADR-024.)*
    - **Batches:** B1–B9 complete.
    - **Paths and routines:** none remain in the release build; kept Circles migrated intact; journal records readable.
    - **Feasibility:** the StageBrief matrix holds as a permanent test (45/45 cells pass).
    - **Plans:** three Plans run to their frozen semantics, including all four stage-5 cases.
    - **Insights:** six families gated as frozen; the calendar restored with its accessibility tests.
    - **Shell and gates:** the four-tab shell; Premium checks at the service boundary, with direct-route tests.
    - **Simulations:** a non-responder, a mixed answerer, More Energy at ≈10, lapse, and a 12-month Insight cadence run.
  - Documentation matches the implementation.
- **Device proof:** S25.
  - **Free unchanged;** Premium 10/20/30-minute guided sessions; skip and leave-out; next-day effect; Use it today; lapse and resubscribe; dark mode, 130 % text and TalkBack.
  - *(Amended 2026-10-17: Path and Toolkit removed from the list.)*
  - **Plans:**
    - start;
    - a stage-steered, voiced stage Circle;
    - wait (different need);
    - set aside (after a leave-out);
    - pause and carry on;
    - revisit;
    - the review in cases A and D;
    - repeat;
    - lapse with a saved place.
  - **Insights:**
    - the Day-1 state;
    - the calendar with TalkBack (all three date states);
    - record detail;
    - applying an Insight;
    - readability after a lapse.
  - **You:** Yours.
  - **Shell:** the four-tab shell at 130 % and in dark mode.
  - **Today card on a stage day:** Start Circle stays visible, and the Circle is never shrunk beyond the existing near-fit rule.
- **Known risk, not a blocker:** More Energy at ≈10 is relatively thin (19 sessions, 6 main pieces product-wide). The Plans don't stall (ADR-024 §9–§10).
- **Commercial question:** do a personal guided Circle every day, a Plan with a direction, and truthful Insights feel worth a monthly subscription? Unproven until pre-release users try the complete product.
- **Dependencies:** Phase D.

## Phase E — Measurement & release

**STATUS: NOT STARTED — ON HOLD until Phase D2 passes, its single closure SHA is pushed, both independent post-D2 audits of that SHA are positive, and the founder approves**

- **Purpose:** a measurable, compliant launch.
- **Scope:**
  - MEASUREMENT-1 resumed for the V2 funnel, including the consent-copy decision and a production Supabase project.
  - Privacy policy and support contact.
  - Play Data Safety.
  - **Google Play foreground-service declaration (from D2):** the Android release runs `GuidanceService`, a `mediaPlayback` foreground service, while a voiced Circle runs. The guidance service may start only for an explicitly started Circle that is eligible for THIRTY spoken guidance, when Premium is active, spoken guidance is enabled, a complete production voice is bundled, and accessibility rules permit THIRTY voice output. The Play Console foreground-service declaration for `FOREGROUND_SERVICE_MEDIA_PLAYBACK` must be filed with its description and the required demonstration evidence (a video of a voiced Circle continuing with the screen off and in another app, and its ongoing notification). Merged-manifest evidence: `artifacts/v2_phase_d2/final_audit/FGS_MANIFEST_VERIFICATION.md`.
  - **Voice usage measurement (from D2):** aggregate, consent-gated events `voice_previewed`, `voice_selected`, `voice_changed`, `guided_circle_started` and `guided_circle_completed`, keyed by stable neutral voice IDs (`voice_locke_v1`, `voice_heather_v1`, `voice_milo_v1`, `voice_brittney_v1`). They carry no Circle, need, activity, Memory or History content, no user text, no names and no health inference. They must be reflected in privacy and Data Safety. A voice is retired only on usage evidence, with a safe preference migration. Requirement: [`PHASE_E_VOICE_USAGE_MEASUREMENT.md`](PHASE_E_VOICE_USAGE_MEASUREMENT.md).
  - **Plan and Insight measurement** (from D2, frozen 2026-10-17; ADR-024 §14):
    - aggregate, consent-gated events `plan_started`, `stage_guided`, `plan_review_seen`, `insight_shown` and `insight_applied`;
    - they carry no Circle content, no need/activity/Memory text, no user text and no health inference;
    - they must be reflected in privacy and Data Safety;
    - not implemented before Phase E.
  - **Safety review before public release** (release gate): a bounded safety review of the live breathing and exertion content, and of any still-gated activity proposed for release. Nothing is reactivated before it.
  - Live RevenueCat billing, with cadence chosen from the commercial hypotheses.
  - Store listing.
  - Slogan decision.
  - Release notes.
- **Acceptance:** the release gate below.
- **Device proof:** release build on the S25, plus a live purchase and restore.
- **Commercial question:** D7, D30, feedback response rate, conversion and pause behaviour.
- **Dependencies:** Phase D2.

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
- **2026-10-09** — Phase C implementation candidate ready for founder review: one Circle shell with Open, Guided and (architecture-only, internal QA) Paced runtimes; wall-clock lifecycle with pause; a calm natural end; inline reflection with acknowledgement; "What THIRTY remembers" per need; explicit "Don't suggest" / "Suggest again" preferences that survive Delete and have their own reset; "Remove this answer"; History refinements; QA fixtures C-A–C-R; S25 device proof. No pacing pattern is reviewed — the safety gate is unchanged. Not committed; not accepted.
- **2026-10-10** — Phase C quality closure: live S25 TalkBack pass complete (Open, Guided, reflection, Memory, nothing-fits). Fixes from it: Open moment read as one stop; every backdrop named (guarded by a test across `lib/`); confirmations announced by their question; focus follows only the user's own action; natural-end announcement after Close's focus; "Review what THIRTY remembers" now opens memory on the need that has nothing left (ADR-021 §9, §14). S25 visual smoke at 100% and 130% text: closed copy, Guided end, Memory, nothing-fits. Full suite 1825 passed; analyze clean. Still uncommitted; founder acceptance pending.
- **2026-10-10** — **Phase C PASS — COMPLETE.** Founder approved Phase C with one final copy correction: the closed Circle reads "Your Circle for today." / "Your next Circle opens tomorrow." (no orphaned word on the S25 at 100% or 130%, dark mode). Final live TalkBack acceptance on the S25: Open, Guided, feedback/reflection, Memory and nothing-fits. No-candidate Memory deep link fixed: "Review what THIRTY remembers" opens memory on the need with nothing left (`/memory?need=…`). Every dialog/sheet backdrop labelled. Phase D migration invariant recorded (ADR-021): explicit per-need "Don't suggest" must be respected by the new Path / Toolkit architecture. Full suite 1825 passed, 0 failed, 0 skipped; analyze clean. Phase D not started.
- **2026-10-10** — Phase D implementation candidate ready for founder review (ADR-022): a 13-piece module library built on live Phase A activities (levels as depth and combination); six Path templates, two per need; a pure Path engine (seeded from Free history, 7 Path Circles, adapts to answers, waits rather than cuts); a personal Toolkit whose routines are ordinary Engine V2 candidates with no Premium bonus and run on Phase C's Guided runtime; maintenance offers (time misfit, fading, gap, user refresh), one at a time with a 21-day cooldown, and a four-week check that says "nothing to change" when true; lapse keeps routines usable and owned and saves a Path exactly; "Don't suggest" enforced in seeds, steps, routines, tune-ups and shorter versions. V1 Plans, Coach and Insights retired (state removed, no routine fabricated, old records keep a plain context line); navigation Today | Toolkit | You; offer-page copy only (price and billing untouched). QA scenarios D-*; twelve eight-week simulations with human review and policy tuning; content review pack. S25 device proof: 46 screenshots (dark, light, 130 %) and a live TalkBack walk in five rounds (Path step, maintenance offer, review, lapsed Toolkit, fixed review); its fixes are recorded in ADR-022 §13. Not committed; not accepted. Phase E not started.
- **2026-10-10** — Phase D founder quality correction (ADR-022): a shorter version is always the same routine (every piece, each full or in its authored short form) or there is none; the gap needs explicit weak answers to Free's own picks ("Somewhat useful" counts as served; too few answers claim nothing); an active "Not useful" rest is respected in Path seeding, adaptation, tune-ups, shorter versions and gap builds, and ends on its own; time-neutral names (A lift at home / My pick-me-up, My brisk walk, My screen break, A soft landing / My quiet pause, Easy time outdoors / My time outdoors); step lines no longer put piece names mid-sentence; internal "levels" renamed short / full / combined; content review pack complete and checked against shipped copy. Simulations re-run (plus 5b served-well, 10b active rest); S25 re-proof of the changed flows (dark, 130 %) and final live TalkBack on the maintenance offer and the lapsed Toolkit. **Closed-test question:** after building a routine, do users feel THIRTY offers it often enough to feel useful and owned? (no ranking bonus, no preference control added). Still uncommitted; founder approval pending; Phase E not started.
- **2026-10-10** — Phase D final quality closure (ADR-022): two Path jobs no longer promise an outcome (A lift at home: "A short movement routine for when you want a little more energy — all at home, about 15 to 25 minutes."; Out the door: "A routine built around a brisk walk for when you want a little more energy — about 25 to 30 minutes."), with a guard test; Path and routine names frozen. Evidence-scope invariant: a routine with a piece resting for the chosen need is not today's routine while the rest lasts (eligible again on expiry or Suggest again); a routine's own "Not useful" never rests its pieces; no cross-need suppression. Full suite 1567 passed, 0 failed, 0 skipped; analyze clean. S25 smoke: both start pages, routine-with-resting-piece not chosen (Memory shows the rest), chosen again once lifted. Routine frequency remains a closed-test question. Still uncommitted; founder sign-off pending; Phase E not started.
- **2026-10-10** — **Phase D PASS — COMPLETE.** Founder approved the Premium V2 design and content (six Paths and six routine names frozen; outcome-free job lines). Final S25 acceptance: corrected start pages, a routine with a resting piece not chosen and chosen again once the rest is lifted, Week-7 shorter version (My reset 30 → Write it down + Clear one surface, both short, 20 min), gap vs served-well, lapse (routines kept and offered in Free, the Path saved and resumed exactly), 100 % and 130 %, dark. Live TalkBack acceptance on the maintenance offer and the lapsed Toolkit. 14 eight-week simulations pass with human review. Full suite 1567 passed, 0 failed, 0 skipped; analyze clean. ADR-022 accepted. Closed-test question carried to Phase E: after building a routine, do users feel THIRTY offers it often enough to feel useful and owned? Phase E not started.
- **2026-10-11** — **Phase D2 started (Recurring Premium redesign).** The founder decided that THIRTY must support legitimate monthly recurring revenue, with no lifetime purchase, after the post-V2 audits judged Phase D's Premium a weak recurring fit (build and cancel). The new Premium job is the Personal Guided Circle (contract amendment 2026-10-11, ADR-023). The founder chose to implement before external validation; product–market fit is unproven. Phase D stays PASS as the historical architecture. Phase E is on hold until D2 passes.
- **2026-10-11** — Phase D2 implementation candidate (ADR-023), not yet accepted:
  - **Elements and composer:** a 38-element release library (21 pieces of live activities, 17 new cues; no breathing, exertion, safety-pending or retired content), plus a pure deterministic composer with a documented quality gate and time-use policy.
  - **Premium Today:** Path step → the user's proven routine → Personal Guided Circle → Free's activity, said plainly. The guided composed runtime moves each part on by itself and restores exactly.
  - **Controls:** Skip (never an answer) and "Leave it out next time" (reversible in Memory).
  - **Ownership:** "Use it today" (Free) and "Keep this Circle". On lapse, composition stops and everything owned stays.
  - **Repositioning:** Paths and Toolkit are supporting infrastructure; the offer leads with the recurring job (price untouched).
  - **Truth fixes:** hidden routine rest, the stable check's claim, and the time-misfit, fading and gap wording.
  - **Composer correction:** long-horizon internal simulations exposed degeneration (answers credited arrivals and closes; sum-based evidence compounded; no exploration). After it: 13 profiles × 365 days pass structurally, with 0 fallbacks, no identical session within 15 days, and no main piece on more than 22 % of days. These are not user validation.
  - **QA:** scenarios D2-A–E.
  - **Spoken guidance:** architecture only; no voice ships (blocking quality decision).
  - **Open:** founder content review, the spoken-guidance decision, S25 device QA and live TalkBack.
  - **Tests:** full suite green and analyze clean. Commits 9acd03b, add2157, c694189, b62f493 (not pushed).
- **2026-10-11** — Phase D2 S25 device QA (`artifacts/v2_phase_d2/DEVICE_QA.md`):
  - **Rounds 1–9 pass:** Free unchanged; first Premium Today at ≈ 10, ≈ 20 and up to 30; a part moving on by itself; Skip; finish and Close; reflection; Keep; kept Circle page; Memory put-back; lapse with "Use it today"; resubscribe; 130 %; light mode; live TalkBack on the running card and the Skip sheet.
  - **Six defects found on the device and fixed:**
    - the composed card pushed Start Circle off the first screen (it now shows the substance line at full width);
    - Memory showed composite answers as activity answers;
    - Toolkit order and the Path-suggestion wording;
    - a long part instruction pushed Close under the tab bar (seven instructions tightened; new S25 guard for every element);
    - the Skip sheet overflowed at 130 %;
    - orphaned words.
  - **Tests:** full suite green (1658, plus 13 long-horizon simulations); analyze clean.
  - **Still open before D2 can pass:** founder content review (`CONTENT_REVIEW.md`) and the spoken-guidance decision.

- **2026-10-11** — **Phase D2 founder correction pass** (founder reviewed `CONTENT_REVIEW.md` and `SIMULATION_REVIEW.md`; element count is no longer a blocker; D2 not yet approved):
  - **Semantic dependencies:** a part that builds on another ("Choose one thing" after "Get it out") is composed only directly after it, and skipping that part skips it too. All 38 elements were audited.
  - **Copy:** 20 element instructions corrected:
    - the phone stays the audible guide;
    - nothing asks the user to close what could lose unsaved work;
    - no needless intensity;
    - no assumed daylight;
    - comfort wording added from the source activities.
  - **Premium offer truth:** no evidence claims on a subscriber's first day; "Free stays complete" replaced with consumer wording.
  - **Spoken guidance:** founder decision recorded (bundled pre-generated recordings).
    - Architecture, the 42-clip manifest (`SPOKEN_GUIDANCE_MANIFEST.csv`), the Android player, the You setting and tests are complete.
    - **No recordings exist; the voice is silent.**
  - **Attacks:**
    - `p14_more_energy_dominant`: no degeneration, but visibly narrow (9 mains, 31 materially distinct sessions a year);
    - saved-Circle / lapse: 40 of 60 lapsed days served by kept Circles the user chose. **Substitution is a commercial hypothesis for the post-D2 audit.**
  - **S25:**
    - Skip-with-dependants, voice plumbing (with temporary test tones, never committed), voice under TalkBack, the voice switch, and offer copy all pass.
    - Two device defects were fixed: the voice never became available, and Flutter's `accessibleNavigation` was true with TalkBack off.
    - **Open:** once the user switches away, Android freezes THIRTY and cues stop. A foreground service is a founder decision within the voice gate.
  - **Tests:** 1672 regular plus 14 long-horizon simulations pass; analyze clean.
  - **Still open before D2 can pass:**
    - founder approval of the corrected content;
    - founder approval of the production voice recordings, together with the background-playback decision.
- **2026-10-12** — **Phase D2 final hardening** (audit-candidate pass; D2 still NOT COMPLETE):
  - **Content:**
    - **The last two copy fixes:**
      - "Phone face down" now ends "…unless a part asks you to use it".
      - "Look far away" no longer assumes a window or the outdoors. Its wording is tighter than the brief's, because the S25 geometry test failed on the longer sentence.
    - **Content frozen:** `CONTENT_REVIEW.md` §0 carries a machine diff proving nothing else drifted.
  - **Background playback (founder decision E):**
    - **The service:** while a voiced Circle runs, a `mediaPlayback` foreground service with a partial wake lock, and a notification ("Circle running" / "Circle paused", the part, Pause/Resume and Next). There is no media session, so headset buttons are never taken from the user's music.
    - **The conductor:** a new application-level `GuidanceConductor` owns the cues from the Circle's stored facts and the clock, independent of the UI.
    - **S25-verified:**
      - timed cues with the screen off and locked, across an app switch, and after Back to the launcher;
      - ducking of Chrome's music, which keeps playing;
      - the notification's Next, Pause and Resume;
      - the ending, then the service stopping itself;
      - no duplicate cue on return.
    - **Fixed along the way:**
      - "First." never played at Start;
      - the notification's controls could reach nothing after the app's state was rebuilt;
      - Back on Today finished the activity on Android 16, ending the Circle's cues.
  - **Voice:**
    - **Manifest:** regenerated as the recording source of truth; 2 of 42 fingerprints changed.
    - **Audition:** review-only, 3 voices × 5 clips via the vidIQ voiceover tool (42 add-on credits), not bundled.
    - **Requirements:** production and mastering requirements written.
    - **No production clip exists.**
  - **Audit pack:** `artifacts/v2_phase_d2/final_audit/`, with the commercial hypotheses (kept-Circle substitution: 40 of 60 lapsed days; More Energy is the thinnest need) and release-audit notes.
  - **Still open before D2 can pass:** founder approval of a production voice and its licence, and the 42 clips produced, bundled and S25-QA'd.
- **2026-10-12** — **Phase D2 voice and release-quality closure pass** (D2 still NOT COMPLETE; the founder decided the following):
  - **Content:** "Look far away" is **approved and frozen** as shipping: "Let your eyes settle on the furthest thing you can comfortably see — through a window, or across the room."
  - **Voice route:**
    - The vidIQ-generated Sarah / River / Eric files are **audition only** and will never be bundled.
    - The production pack is to be generated under a **paid ElevenLabs plan with commercial rights** once a voice is chosen.
    - Evidence to keep: account/plan, generation date, licence/terms reference, voice, exact scripts. No credentials in the repository.
  - **Foreground-service manifest:** **PASS**, no change needed (`artifacts/v2_phase_d2/final_audit/FGS_MANIFEST_VERIFICATION.md`). Checked in the packaged manifest of a fresh profile APK:
    - `GuidanceService` is `exported=false`, `foregroundServiceType=mediaPlayback` only, `stopWithTask=true`;
    - `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_MEDIA_PLAYBACK` are declared;
    - there is no other foreground-service type or permission.
    - **Why profile:** the release merge itself is blocked by the billing gate without `config/revenuecat.local.json`, by design. It is element-identical to the profile merge, and must be re-checked on the real release APK in Phase E.
    - **Phase E requirement added:** the Play Console foreground-service declaration.
  - **TalkBack reliability (S25):** **7 timed transitions tested, 7 announced, 0 missed** (`final_audit/CLOSURE_DEVICE_QA.md` §2).
    - **Conditions covered:** TalkBack OFF→ON at 6 s to 6.5 min before a change; Pause/Resume; Home and return 5 s before a change; and the original D2-C path into "Choose one thing", twice.
    - **Natural ends:** 4 of 4 spoken.
    - **When TalkBack is busy, a change is queued, not dropped:** spoken in full, 11–18 s late.
    - **The earlier observation does not reproduce:** no code change.
  - **System Back regression (3-button navigation, voiced Circle):** **PASS** on every check (`CLOSURE_DEVICE_QA.md` §3):
    - the Circle continues with the service and wake lock held;
    - the timed cue fires on time out of sight;
    - the UI is correct on return;
    - no duplicate cue;
    - no journal close;
    - the service, notification and wake lock end with the Circle.
  - **Still open before D2 can pass:** the founder's voice choice; the 42 production clips via the licensed route; production voice QA on the S25; the full final gate.
- **2026-10-12** — **Phase D2 guided-voice entitlement correction** (founder decision; D2 still NOT COMPLETE; ADR-023 still Proposed):
  - **The boundary:** THIRTY spoken guidance is a Premium service layer. Accessibility output, including TalkBack, is entitlement-independent and remains available to all users. Owned Circles remain fully owned and visually usable after Premium lapse. Cancellation removes new composition and THIRTY spoken guidance, not owned content.
  - **Code:**
    - `guidanceVoiceProvider` plays only while Premium is active, the switch is on and a voice is bundled. The background service follows the voice, so it never starts on Free.
    - A kept Circle on Free runs complete, on screen and through TalkBack, without the voice.
    - A lapse mid-Circle stops the voice and the service at once, and the Circle runs on. A resubscription speaks again from the next part, never repeating one under way. **Fixed along the way:** a returning voice used to speak a part already under way.
    - **Two voices:** `ThirtyVoice.female` and `ThirtyVoice.male`, each bundled all-or-nothing in `assets/audio/guidance/<voice>/`. The choice is a local preference that survives a lapse; it shows in You → Spoken guidance, on Premium only.
  - **Copy:** the offer's services are now "Made for you" and "Guided for you". The voice is named only in a build that bundles it, and the cancellation line then adds "— its parts and timing on screen, without THIRTY's voice." Accessibility is not claimed as a benefit.
  - **Deferred:** a Free voice preview is optional Phase E / paywall work, not built.
  - **Tests:** `guidance_entitlement_test.dart` (new) covers the Free/Premium voice, the visual runtime, an identical TalkBack tree and announcements on Free, a lapse and resubscription mid-Circle, the stored choice, You, and reopened sessions. The You, offer, composed and review-pack tests were updated.
  - **Lapse attack re-run:** 40 of 60 lapsed days served by kept Circles and 20 by Free Today. THIRTY voice plays while lapsed: **0**; background sessions while lapsed: **0**; all 60 Premium days spoken.
  - **Manifest:** the 42 scripts and fingerprints are unchanged; the `file` column is now the per-voice file name. The production pack is 84 clips (42 × 2).
  - **Still open before D2 can pass:**
    - the direct ElevenLabs audition (2 female-presenting and 2 male-presenting candidates; it needs the founder's paid-plan API key);
    - founder approval of both voices;
    - the 84 clips;
    - production voice QA on the S25;
    - the full final gate;
    - the closure commit and push.
- **2026-10-13** — **Phase D2 voice noise diagnostic** (D2 still NOT COMPLETE; nothing committed):
  - **Founder choice:** the Guarded master is preferred for Andre Leone and Lunaria; the approved Locke and Heather masters stand. The founder hears background noise in Guarded Andre and Lunaria.
  - **Root cause:** generated by ElevenLabs. It is the steady room tone of these two voices, about 35 dB (Andre) and 40 dB (Lunaria) under their speech, against 54–65 dB for Locke and Heather.
    - **What the gain does:** the Guarded gain makes the noise louder without changing the ratio.
    - **Not the cause:** the limiter and the MP3 → AAC transcode, which is lossy-to-lossy but measured 24–31 dB under the noise.
    - **Seed:** a seed-31 regeneration (one clip per voice) has the same noise.
  - **Controlled noise reduction:**
    - a spectral denoiser was rejected: it dulls speech and smears breaths;
    - a pause-only expander is clean, but only −3.5 dB.
  - **Not ready for the 168 clips:** a founder decision is needed for Andre and Lunaria. Evidence: `artifacts/v2_phase_d2/voice_production_validation/noise_diagnostic/README.md`.
  - **Phase E requirement added:** voice usage measurement (`PHASE_E_VOICE_USAGE_MEASUREMENT.md`).
- **2026-10-13** — **Phase D2 voice source quality decision** (founder; D2 still NOT COMPLETE; Phase E HOLD; the 168 clips NOT AUTHORIZED):
  - **Locke and Heather:** KEEP.
  - **Andre Leone and Lunaria:** REPLACE. Their background noise is intrinsic to the ElevenLabs source voices.
    - **Rejected as repairs:** permanent denoising, Voice Isolator, expansion and a different production model. Premium spoken guidance starts from clean source voices.
    - **Evidence:** kept for the audit trail; neither voice is a production candidate any more.
  - **Replacement validation rule** (one candidate each, exact IDs from the founder; nothing is searched or generated before then):
    1. Generate only the five canonical validation clips, with the same `eleven_multilingual_v2` production settings.
    2. Inspect the untouched output before mastering: measure the pause and background noise, and listen to it.
    3. Reject at once on persistent room tone or hiss audibly comparable to Andre or Lunaria.
    4. Only then evaluate character and mastering.
    - **Character directions** (not user-facing descriptors): Andre's replacement is deep, grounded, calm and warm; Lunaria's is soft, serene, warm and light.
  - **Pipeline refinements kept for the final production run of all four voices:** the limiter's 5 ms delay correction and 10 ms trim-edge fades. Locke and Heather are not rebuilt yet.
- **2026-10-14** — **Phase D2 replacement voice validation** (D2 still NOT COMPLETE; Phase E HOLD; the 168 clips NOT AUTHORIZED; nothing committed):
  - **Candidates** (founder-supplied exact IDs): Milo `GUDYcgRAONiI1nXDcNQQ` for Andre Leone, and Grace `mZTVERjx1WQkdAWt1Lcm` for Lunaria. Both were verified as available, in the account, at rate 1.0, with no library restriction.
    - **Milo's model gap:** his clone is **not** fine-tuned for `eleven_multilingual_v2`; the API generated on it anyway, and the settings were not changed.
  - **Generation:** five canonical clips each, with the frozen v2 settings, seed 30, `mp3_44100_128`. Ten requests, 824 characters.
  - **Raw source gate** (pooled loudness-to-floor; Locke 64.3 dB, Heather 53.9, Andre 34.1, Lunaria 38.9):
    - **Milo:** 62.2 dB, no steady bed. **PASS.**
    - **Grace:** 33.7 dB, a steady broadband hiss under every pause. Her output is also about 20 dB quieter than the other voices. **FAIL.**
  - **Milo's restrained master:**
    - **Applied:** one −1.99 dB voice-wide gain, the 10 ms trim-edge fades, and the delay-compensated limiter.
    - **Not needed:** no outlier corrections; the limiter never engaged.
    - **Level:** −22.15 LUFS.
  - **Grace:** no master was made. There is a gain-only, level-matched diagnostic file for confirming the gate by ear.
  - **Awaiting the founder:**
    1. a listen to Milo, and a decision on his model fine-tune gap;
    2. a decision on Grace.
  - **Evidence:** `artifacts/v2_phase_d2/voice_production_validation/replacements/README.md`.
- **2026-10-16** — **Phase D2 final four voices locked** (founder; D2 still NOT COMPLETE; Phase E HOLD; nothing committed):
  - **Launch voice set, all FOUNDER APPROVED:**

    | Voice | ElevenLabs ID | Stable product ID |
    |---|---|---|
    | Locke | `oaLGpwm7fYWDEFmlRuQk` | `voice_locke_v1` |
    | Heather | `plP9aw1rizYgjFfuvLQ7` | `voice_heather_v1` |
    | Milo | `GUDYcgRAONiI1nXDcNQQ` | `voice_milo_v1` |
    | Brittney | `pjcYQlDFKMbcOUp6F5GD` | `voice_brittney_v1` |

    - **Milo:** the missing `eleven_multilingual_v2` fine-tune metadata is not a blocker; the founder approved the actual generated output.
    - **Brittney:** her automatic raw-noise FAIL was a false positive, caused by unweighted measurement of mainly ~32 Hz sub-bass energy. The founder heard no perceptible noise. The perceptual analysis and the founder's listening supersede it.
  - **Voice selection is CLOSED.** No further search; rejected voices are reopened only if a concrete later production defect forces a replacement.
  - **Rejected:**
    - Andre Leone and Lunaria: founder-confirmed audible source noise.
    - Grace: source hiss and insufficient source level.
    - Anastasia: not selected.
    - Nicole: source issues, including a clipped onset.
  - **Audio QA methodology frozen:**
    - measurements are diagnostic evidence, not a perceptual verdict;
    - noise is classified by kind (broadband, hiss, room tone, sub-bass, codec residual, DC);
    - founder or device listening is the final perceptual gate;
    - no EQ, high-pass or denoise just to improve a number.
  - **Production mastering rules:** the validated restrained route, as frozen in `replacements/NOISE_GATE_METHODOLOGY.md` § Production freeze.
  - **The 168 production clips** (42 × 4 voices) are blocked **only** by the founder's confirmation that the paid ElevenLabs plan grants commercial-use rights for the generated content.
  - **Evidence:**
    - `artifacts/v2_phase_d2/voice_production_validation/FINAL_VOICE_SET.md`;
    - approved-output hashes in `replacements/APPROVED_MILO_BRITTNEY_SHA1.txt` and `APPROVED_LOCKE_HEATHER_SHA1.txt`.
- **2026-10-16** — **Phase D2 production voice pass** (licence confirmed; D2 still NOT COMPLETE; Phase E HOLD; nothing committed):
  - **Licence gate CLOSED:** ElevenLabs Starter, paid, "Commercial License for Speech and Music" (founder-verified). Recorded without billing details in `artifacts/v2_phase_d2/voice_production/PROVENANCE.md`.
  - **Generated:** 168/168 clips (42 × 4) with the frozen settings, seed 30; 16,940 characters.
    - Seed 30 reproduced the founder-approved validation performances: Locke, Heather and Brittney near sample-identical; Milo the same performance, but not bit-identical.
  - **Raw QA:** provenance, onset and ending, clipping, stalls, pace, offline ASR against every script, and the frozen perceptual noise method.
    - **Two Locke clips retaken** with seed 31, same settings: `sitOutside` had an inserted vocalisation; `phoneFreeWalk` started inside "Screen".
    - **Takes that start on their first sound** (mostly "One…", "S…" words) are text-driven: seed 31 reproduced them. They are kept and listed for listening.
  - **Mastering:** the frozen restrained route. One voice gain to a −22 LUFS take; ±2 LU outlier-only correction; no limiting was needed; no denoise, EQ or compression.
    - **Leads count in the outlier check:** Heather's "Next." was 9.4 LU low.
    - **The head fade never covers a speech onset:** 2–10 ms.
    - **Heather's raw levels span 15 LU**, so 24 of her 42 clips are outlier-corrected.
  - **Integrated:** `ThirtyVoice` is locke, heather, milo and brittney, with stable IDs `voice_*_v1`; the female/male slots are removed.
    - **Activation** is all-or-nothing per voice (`completeGuidanceVoices`).
    - **Bundling:** four asset folders in `pubspec.yaml`, 24 MB.
    - **You (Premium):** four name chips and "Hear <name>", which plays the voice's own shipping clips.
    - **Descriptors** are not shown, pending the founder.
  - **Gates:**
    - analyze clean;
    - full suite 1,723/0;
    - 14 long-horizon simulations pass;
    - focused voice, entitlement and lapse-attack tests 63/0;
    - S25 device QA with production audio passes on every objective check.
  - **Open before D2 closure:**
    - **founder listening of the final pack** (`voice_production/listen/`): the founder did not listen closely during the device session, so the perceptual items are unverified;
    - founder decisions on the descriptors, and on the two mastering applications (lead correction, onset-safe head fade).
  - **Evidence:** `artifacts/v2_phase_d2/voice_production/README.md`, `.../device_qa/S25_PRODUCTION_VOICE_QA.md`, `artifacts/v2_phase_d2/final_audit/`.
- **2026-10-17** — **Production audio PASS — FROZEN** (founder; D2 still NOT COMPLETE; nothing committed):
  - **Corrections:** the founder's perceptual QA found four clips to correct (Brittney `part_sitAMinute`; Heather `getItOut` and `oneTask` too loud; Heather `gentleStretch`).
    - The corrections were applied as byte copies; the other 164 clips are unchanged.
    - The founder heard them in the app on the S25: "all ok".
  - **Previews:** each voice gained a Preview, played by "Hear <name>": "Hi, I’m <Name>. I’ll tell you when each part of your Circle begins, so you can put the screen down." (heard on the S25: "All ok").
  - **The pack:** 4 voices × 43 files = **172 production files**. `completeGuidanceVoices` requires the Preview, and `master_production.py` refuses to run (pack frozen).
  - **Gates:** tests 1,737/0; analyze clean.
  - **Open:** voice descriptors — secondary; names only is the current state.
- **2026-10-17** — **Product and commercial reconciliation; architecture and content freeze APPROVED** (founder; B0 executed; D2 still NOT COMPLETE; Phase E HOLD; nothing committed):
  - **Finding:** D2 alone was judged too reduced for a recurring subscription. Every daily output could be stockpiled as kept Circles, and nothing gave direction or understanding over time.
  - **Founder decision:**
    - Circle Plans and Insights must remain real capabilities, not restored V1 code;
    - Today | Plans | Insights | You;
    - Paths, routines, tune-ups, shorter versions and the Toolkit tab are removed before public release;
    - kept Circles are the only reusable owned object, managed in Yours under You;
    - THIRTY is designed as a recurring-revenue product for KEYBRACE, with four paid jobs (Today, Direction, Understanding, Guidance) and no confiscation. Nothing about demand is proven.
  - **Frozen design (ADR-024):**
    - three Plans — Getting going, Making room, Slowing down — × five StageBriefs;
    - shared rules C1–C8;
    - the Plan semantics: guided, wait, set aside, revisit, pause, leave, review, repeat, lapse;
    - the two Not-useful rules: composed or stage Circle → ranking evidence only, no rest; single-activity Circle → the Engine V2 14-day rest;
    - the four stage-5 cases, including the honest non-responder path and the case-D ending;
    - six Insight families with gates (I4 uses an exposure baseline with a 25-point guard);
    - maturity states; the restored Free calendar; the Free/Premium/lapse table; the launch copy.
  - **Feasibility:**
    - a validated port of the production quality gate (it reproduces `ELEMENT_COVERAGE.md` exactly);
    - 45/45 stage × time cells pass;
    - More Energy never stalls but is thin at ≈10 — a known risk, not a blocker;
    - a safety review is required before public release; nothing is reactivated.
  - **B0 (documentation only):**
    - `PRODUCT_V2_CONTRACT.md` Amendment 2, and the affected sections amended;
    - ADR-024 created (Proposed);
    - ADR-023 corrected (four voices / 172 files, audio frozen; routine and Path parts marked as superseded) — still Proposed;
    - ADR-022 supersession note;
    - this tracker.
    - No app code, test, audio, manifest or asset changed.
  - **Next:** B1 — pre-release removal. Not started.
- **2026-10-17** — **B1 pre-release removal implemented and verified** (D2 still NOT COMPLETE; ADR-023 and ADR-024 still Proposed; Phase E HOLD; nothing committed):
  - Removed before public release: Paths and their starts and progression, routines (creation, candidates, evidence), tune-ups, shorter versions, maintenance, the Phase D module library and the Toolkit tab.
  - Kept: kept Circles (never gated, up to 8, rename, remove, Use it today, Premium voice under the guidance rules, surviving lapse and Delete history, in the export), history, Memory, the Personal Guided Circle, the composer, the voices and the safety gates.
  - Yours under You ("Yours · N Circles you kept"). Interim shell Today | You — not the final IA.
  - Migration: one idempotent pass on `toolkit_v1` keeps kept Circles and removes only the retired Path and routine fields. Historical routine and Path entries stay readable in history.
  - Gates: tests 1,571/0; analyze clean; Android debug build; emulator and S25 smoke (sandboxed QA scenario D2-E; the S25's real data gained only the migration marker).
  - **Next:** B2 — composer seam / StageBrief. Not started.
- **2026-10-17** — **B2 composer seam / StageBrief implemented and verified** (D2 still NOT COMPLETE; ADR-023 and ADR-024 still Proposed; Phase E HOLD; nothing committed):
  - `composeCircle` takes an optional StageBrief. It filters gate-passing Circles before the unchanged ranking and composes at ≈20 size for E1 and E2 on an up-to-30 day. Without a brief, all 957 recorded B1 days are identical (`composer_baseline_equivalence_test`).
  - `stage_brief.dart`: the twelve fixed briefs; `composeStage` (composed, wait, or set aside — the set-aside probe ignores only Leave it out, Don't suggest and the user's rests, never safety, time, yesterday's main piece or today's constraint); and stage 5 cases A–D.
  - Feasibility, on the production composer: 45 / 45 cells PASS at the frozen counts. The set-aside, wait, stage-5 and More Energy attack expectations of ADR-024 hold.
  - No Plan state, persistence, UI, route or Insight. No user-visible change.
  - **Next:** B3 — Plan domain and runtime. Not started.
- **2026-10-17** — **B3 Plan domain + runtime implemented and verified** (D2 still NOT COMPLETE; ADR-023 and ADR-024 still Proposed; Phase E HOLD; nothing committed):
  - `lib/features/plans/`: the catalogue (getting_going, making_room, slowing_down) on the B2 briefs, the Plan state and its pure actions, `planToday`, and the Notifier, which checks Premium itself.
  - Today precedence: Plan stage → Personal Guided Circle → Free. Without an applicable Plan, Today is unchanged: the 957-line B1 baseline is identical.
  - S25, sandboxed QA, D3-A and D3-B:
    - stage 2 served; Start alone left the Plan at stage 2, and Close moved it to stage 3 once;
    - Gentler Pace: the ordinary Circle, the Plan untouched;
    - Use it today: the kept Circle ran and the Plan didn't move;
    - INACTIVE: Free's activity, the place kept; ACTIVE again: stage 2 steers again;
    - at ≈10 with "Some fresh air" left out: Fresh air set aside and stage 5 served the same day;
    - ordinary Today unchanged.
    - The S25's real THIRTY data was byte-identical afterwards.
  - Open for B4/B7: the Today stage line (C8), Plan copy in the Delete dialog, and the Plans surface.
  - **Next:** B4 — Plans tab. Not started.
- **2026-10-21** — **Phase D2 PASS — COMPLETE** (founder approval of B9-A and authorization of B9-B):
  - **Built in D2:** the Personal Guided Circle and THIRTY's spoken guidance (four voices, 172 files, PASS — FROZEN); the pre-release removal of Paths, routines and the Toolkit; three Circle Plans; six Insight families with the restored calendar; and the four-tab shell Today | Plans | Insights | You.
  - **Governance:** ADR-023 and ADR-024 Accepted in the single D2 closure commit.
  - **Gates:** analyze clean; tests 2,074/0; S25 device QA and TalkBack (B4, B6, B7, B9-A with its evidence top-up); founder content closure (`artifacts/v2_phase_d2/b9/`).
  - **Known, non-blocking:** More Energy is thin (WEAK; a real-user risk); the public-release safety review is still required, and the gated content stays disabled; mixed apostrophes; the legacy "Your routine" label on development data only; the Samsung speech engine garbles one calendar label.
  - **Next:** the two independent post-D2 audits of the pushed closure commit (not started). Phase E stays on hold.
