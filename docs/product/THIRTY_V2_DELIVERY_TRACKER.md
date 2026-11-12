# THIRTY V2 DELIVERY TRACKER

Status only. What is being built is defined in [PRODUCT_V2_CONTRACT.md](PRODUCT_V2_CONTRACT.md).

## Current state

| | |
|---|---|
| **PRODUCT V2 CONTRACT** | FROZEN (2026-10-08); Amendment 1 (2026-10-11); **Amendment 2 — architecture and content freeze APPROVED (2026-10-17)** |
| **TARGET IA** | Today \| Plans \| Insights \| You — built as the final four-tab shell since B7 (2026-10-20) |
| **PUBLIC LAUNCH** | PAUSED |
| **CURRENT ACCEPTED BASELINE (2026-11-11)** | `c83543d5f40294c76532a4710b748d893320d245` on `step5-billing-integration` (L-1 Option B; parent `d9369795`). **R8 engineering baseline FROZEN at `d9369795a92aa24505c475fa1417d03132300c4a`** (founder). **L-1: ENGINEERING ACCEPTED**, with a documented independent-runtime limitation (founder, 2026-11-11). Phase E HOLD; commercial release NOT AUTHORIZED; deployment NONE. Rounds R8.1 → L-1: log 2026-11-11 |
| **PRE-RELEASE PRODUCT GAP REGISTER** | APPROVED by the founder (2026-11-11) as planning authority only: [THIRTY_PRE_RELEASE_PRODUCT_GAP_REGISTER.md](THIRTY_PRE_RELEASE_PRODUCT_GAP_REGISTER.md). It lists the remaining product and release gaps: onboarding, six languages, multilingual voice, content depth, Free/Premium viability, UX, and release gates. Planning only: it amends no contract and authorizes no development, and its founder decisions stay OPEN until decided. Status stays here |
| **SIX-LANGUAGE LAUNCH** | Amendment 3 (2026-11-12). ADR-025/026/027 Proposed. Not implemented. First engineering slice: L-INF (infrastructure only), authorized by the founder on 2026-11-12; implemented in a separate local commit, not pushed, awaiting independent acceptance verification. The effective app language stays English (ADR-026 gate G-5C). |
| **CURRENT IMPLEMENTATION PHASE** | PHASE D2 — PASS — COMPLETE (2026-10-21; batches B0–B9 closed in the single D2 closure commit `8bfd42c`). The two independent post-D2 audits of that commit **returned on 2026-10-21** (see POST-D2 AUDITS). The joint audit remediation follows batch by batch on founder approval: R1–R4.1 implemented and verified, R5 and R6 accepted at implementation and test level (2026-11-03; not audit closure), R7 final regression PASS on the exact commit tree (2026-11-04); all of this since `8bfd42c` is in one R7 remediation commit on `step5-billing-integration`, whose SHA is recorded outside the commit (see JOINT AUDIT REMEDIATION). F02/F03 framing lines accepted 2026-11-01. Phase E on hold. *Update 2026-11-11: R8 and R8.1 → R8.3.4.1 and L-1 followed on the same branch; the current baseline is the CURRENT ACCEPTED BASELINE row (log 2026-11-11).* |
| **D2** | PASS — COMPLETE (2026-10-21; closure commit `8bfd42c`; ADR-023 Accepted, ADR-024 Accepted). The post-D2 audits of that commit returned on 2026-10-21: Audit #1 CONDITIONAL, Audit #2 FAIL (see POST-D2 AUDITS). |
| **PRODUCTION AUDIO** | PASS — FROZEN: 4 voices (Locke, Heather, Milo, Brittney) × 43 files = 172. One file corrected 2026-10-18 after B4 QA (Locke `part_songOn`); the other 171 are byte-identical. Three Heather files corrected 2026-11-02 (seed 32, FOUNDER LISTENING PASS: `close`, `part_closeWhatsOpen`, `part_activeJob`); the other 169 are byte-identical to the 2026-10-18 state (`heather_seed32_integration_2026-11-02/`). Six more Heather files corrected 2026-11-02 in the final quality round (FOUNDER LISTENING PASS: `part_shakeOut` s34, `part_noteOneThing` s31 with the 2026-10-17 −1.8 dB static trim, `part_briskWalk`, `part_lookAround`, `part_roundTheBlock`, `part_sitOutside` s32); the other 166 are byte-identical; S25 PASS at real levels (`heather_final_integration_2026-11-02/`). Heather audio-quality correction round **CLOSED** |
| **FRAMING AUDIO (F02/F03)** | ACCEPTED (founder, 2026-11-01; core functionality): 8 files (2 lines × 4 voices) beside the frozen 172, not part of it; 180 bundled. S25 PASS (2026-11-01). Not device-validated: midnight, a full process restart, the exact visual F02 → "First." handover, direct audio-focus measurement and a real RevenueCat lapse (automated or QA coverage only). Committed in the R7 remediation commit (2026-11-04) |
| **OPEN AUDIO FINDING** | 2026-11-01: on the S25 the founder hears background noise in Heather's **ending** (`voice_heather_v1/close_3b06cf13.m4a`, part of the frozen 172). Under bounded, non-destructive investigation (`artifacts/v2_phase_d2/voice_production/heather_ending_qa_2026-11-01/`): one cleaned candidate awaits the founder's A/B listening; the production file is unchanged. **2026-11-02: RESOLVED.** Replaced by the founder-approved seed-32 take; S25 ending → F03 PASS. **New, open:** on the S25 the founder hears background noise at the end of Heather's `part_shakeOut` (unchanged original; seed 32 and seed 31 did not clean it). Not authorized for replacement; no candidate. **2026-11-02 (later): RESOLVED.** Replaced by the founder-approved seed-34 take; S25 PASS (end noise gone). No founder-heard audio finding remains open |
| **PHASE E** | HOLD |
| **POST-D2 AUDITS** | Mandatory: two independent audits (Claude; GPT-6 Astra) of one immutable pushed SHA — the D2 closure commit, whose full SHA is recorded in the B9-B report and the audit hand-off (a commit can't name itself). A material blocker from either restarts both on a new SHA. **Both RETURNED on 2026-10-21, on `8bfd42c`; the reports are preserved as delivered in `docs/audits/`.** Audit #1 (Claude): **CONDITIONAL**; Phase E recommendation PROCEED, subject to its conditions, Audit #2's outcome and founder approval (`INDEPENDENT_AUDIT_1_D2_2026-10-21.md`). Audit #2 (GPT-6 Astra): **FAIL**; Phase E **HOLD**. Its BLOCKER, A2-01: a never-purchased RevenueCat customer read as billing unavailable, so the paywall showed no purchase control (`INDEPENDENT_AUDIT_2_D2_2026-10-21.md`). A2-01 is a material blocker: after the remediation, both audits restart on the new SHA. `8bfd42c` stays the immutable historical audit target. |
| **JOINT AUDIT REMEDIATION** | R1 billing entry (A2-01), R2 paid day, R3 persistence and Delete, R4/R4.1 kept-Circle ownership: implemented and verified, uncommitted (log 2026-10-21/22). **R5 (I4 Keep, A2-05): implemented; founder-accepted at implementation and test level (2026-11-03). This is not audit closure.** **R6 (R6, R6b, R6c, R6 final): ACCEPTED at implementation and test level (2026-11-03). This is not audit closure; no independent audit has reviewed it** (log 2026-11-03). **R7 (verification, 2026-11-04): final regression PASS on the exact commit tree — 159/159 files, 2,353 passed, 0 failed, 0 skipped; analyze clean; audio 172/172 + 8/8. One auditable commit on `step5-billing-integration` (parent `8bfd42c`); SHA and push verification recorded outside the commit** (log 2026-11-04; `artifacts/r7_final_regression_2026-11-04/`). The repeat (targeted) independent audit: NOT STARTED — no audit has passed |
| **PRE-RELEASE REVIEW — PREMIUM SECURITY & LOCAL DEVICE MIGRATION** | REGISTERED 2026-11-01 — mandatory before public release; NOT STARTED. Scope in the log (2026-11-01). No accounts, cloud infrastructure or new migration functionality without founder approval |
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

*(2026-11-01: the audits of `8bfd42c` returned with Audit #2 FAIL; under the audit rule both restart on the remediated SHA. See Current state.)*

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
- The **Premium security & local device migration** review completed (registered 2026-11-01; scope in the log).
  - *Amendment 2026-11-03 (audit remediation R6b): **Audit #2 A2-07 is an explicit, mandatory gate inside this review.*** Public release is blocked until all of the following are true.
    - **Decision:** the founder decides the intended behaviour for Android cloud backup and device-to-device transfer of THIRTY's local stores (journal, kept Circles, Plans, Insights, preferences): excluded, or deliberately carried.
    - **Configuration:** the manifest and `dataExtractionRules` / `fullBackupContent` implement that decision. `allowBackup="false"` alone is not assumed to cover device-to-device transfer.
    - **Verification:** a backup/restore and a device-transfer test are run on the **signed release artifact**, on at least the S25 and one other manufacturer or emulator image.
    - **Copy:** the user-facing copy states only the verified behaviour.
  - **Owner:** founder (decision and test devices), with engineering (configuration, tests and evidence).
  - **Depends on:** this review's device-migration decisions, a buildable signed release (RevenueCat release configuration and keystore), and Premium restore via RevenueCat.
  - **Not a substitute:** "Copy as text" is a one-way clipboard export; it is not device migration.
  - **Allowed meanwhile:** internal engineering and closed tests may proceed before this gate.

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
- **2026-10-21** — **Post-D2 audits returned** on `8bfd42c`. The reports are preserved as delivered: `docs/audits/INDEPENDENT_AUDIT_1_D2_2026-10-21.md` and `docs/audits/INDEPENDENT_AUDIT_2_D2_2026-10-21.md`.
  - **Audit #1 (Claude): CONDITIONAL.** Phase E recommendation PROCEED, subject to its conditions, Audit #2's outcome and founder approval. No CRITICAL or BLOCKER findings; two MAJOR technical defects.
  - **Audit #2 (GPT-6 Astra): FAIL; Phase E HOLD.** BLOCKER A2-01: a never-purchased RevenueCat customer read as billing unavailable, so the paywall showed no purchase control. Reproduced independently with the real adapter.
  - **Consequence:** under the audit rule, a material blocker restarts both audits on a new SHA. `8bfd42c` stays the immutable historical audit target.
  - **Joint audit remediation plan:** R1 billing → R2 paid day → R3 persistence and Delete → R4 kept compatibility → R5 I4 Keep → R6 copy, docs and config → R7 verification. Each batch starts only on founder approval.
- **2026-10-21/22** — **Remediation R1–R4.1 implemented and verified.** Uncommitted; Phase E HOLD.
  - **R1 billing entry:** an absent entitlement maps to inactive (A2-01). The adapter publishes only the newest-asked answer. Tests: `test/core/premium/revenue_cat_entitlement_gateway_test.dart`. No real Play purchase was made.
  - **R2 paid day:**
    - "Make today's Circle" turns today's Free decision into today's Circle.
    - Plan credit follows its provenance, with no credit for a Circle started after a verified expiry (design A).
    - Tests: `r2_make_today_circle_test.dart`, `r2_plan_credit_provenance_test.dart`.
    - S25 device QA, including TalkBack: PASS (2026-10-22). Real data was restored byte-identical.
  - **R3 persistence and Delete:**
    - Today's keys are published as one write-ahead record.
    - A Delete Circle history that was cut short is finished at start-up.
    - The journal and Plan credit catch up from durable state.
    - Tests: `r3_persistence_delete_test.dart`, `r3_delete_feedback_test.dart`. Full suite 2,196/0, analyze clean, debug APK.
  - **R4/R4.1 kept-Circle ownership:**
    - Kept Circles are read with their saved lengths and words. Records THIRTY can't read are kept verbatim.
    - The founder signed off the R4.1 copy (2026-10-22).
    - Tests: `r4_kept_ownership_test.dart`. Full suite 2,233/0, analyze clean, build exit 0.
  - **Not started:** R5–R7 and the repeat audits.
- **2026-10-26** — **F02/F03 integrated** (founder approval "PREMIUM VOICE INTEGRATION: F02 & F03").
  - No generation; the 172 files are byte-identical.
  - Tests 2,260/0, analyze clean, debug APK. No device QA.
- **2026-10-27** — **F02/F03 acceptance remediation.**
  - Native lifecycle proven on the real Kotlin under a simulated platform (12 scenarios, 69 checks). One gap fixed: `stop()` now reports idle.
  - The closed screen's "tomorrow" follows the real local day, and so does the Close confirmation's "until tomorrow".
  - F02 is on show for each voice's own recording length; its words are kept out of the semantics tree.
  - Listening pack in `framing_f02_f03/acceptance_2026-10-27/`.
  - **Final verification:**
    - Full suite: 2,272 pass, 1 fail. The only failure was the B8 review-pack guard, cleared by regenerating the pack for the one new string.
    - A clean full rerun was stopped by the system for low memory at 1,629/0.
    - Analyze clean. Debug APK built with all 180 files byte-identical.
    - 172/172 SHA-1 OK. Native harness 69/69.
  - **Not accepted yet.**
- **2026-10-29** — **F02/F03 final regression closure.**
  - Founder ear: Brittney F02/F03 PASS, Heather F02 PASS. No new audio.
  - The Close confirmation title is now "Close this Circle?" (`CircleHero.closeConfirmTitle`). B8 review pack regenerated. Its only change is that string, plus the apostrophe tally note going from 10 to 9.
  - Full suite, `flutter test --concurrency=1`: **2,273 pass, 0 fail, 0 skipped, exit 0** (14 min 11 s, about 8 GB free, no other test run alongside).
  - `flutter analyze`: no issues, exit 0. `flutter build apk --debug`: exit 0.
  - The APK holds 180 guidance files: 172/172 match `PRODUCTION_SHA1.txt` and 8/8 match `FRAMING_SHA1.txt`.
  - Native harness re-run: 69/69 PASS, output identical to 2026-10-27 (`native_lifecycle/result_2026-10-29_final_regression.txt`). `GuidanceAudio.kt` and `GuidanceService.kt` are unchanged since that run.
  - **Not accepted yet.** The harness runs the real Kotlin against stubs on a desktop JVM; it is not device evidence.
- **2026-11-01** — **F02/F03 S25 acceptance; founder acceptance; governance applied.** Uncommitted.
  - **S25 run:** SM-S931B, QA APK `9ff2e3c4…` installed in place, Google TalkBack 17.1.
    - PASS on the founder's ear and device evidence: F02 → "First." in all four voices; Close during the ending, after the ending and mid-part; voice off and QA lapse during speech; locked-screen cue; return after Close; TalkBack; "Close this Circle?".
    - Afterwards the original APK was reinstalled in place, real data was byte-identical to the backup, and the 17:32 reminder was re-armed.
  - **Founder decision: F02/F03 CORE FUNCTIONALITY — ACCEPTED.**
    - Not validated on the device, and never reported as device PASS: midnight (automated only); a full process restart with QA data (automated only); the exact visual F02 → "First." handover; direct audio-focus measurement (the probe was defective); a real RevenueCat lapse (QA lapse only).
  - **Governance:** the F02/F03 delta §§1–8 is applied append-only: the contract ("Voices" and "Four voices"), ADR-023 (header and §6), and pointers in ADR-021 and ADR-011. The 172-file baseline is unchanged.
  - **Separate finding:** Heather's ending (`close_3b06cf13.m4a`, frozen 172) has audible background noise on the device. It is under bounded, non-destructive investigation; the file is unchanged.
  - **Pre-release review registered: PREMIUM SECURITY & LOCAL DEVICE MIGRATION.** Mandatory before public release; separate from F02/F03; nothing implemented. Scope:
    - APK copying, tampering and unauthorized Premium entitlement;
    - RevenueCat / Google Play purchase restoration after changing phones;
    - multi-device and anonymous user-ID behaviour;
    - local history, kept Circles, Plans, settings and reminders during device migration;
    - Android backup behaviour and the local-only privacy promise;
    - elimination of QA Premium overrides from production release builds.
    - No accounts, cloud infrastructure or new migration functionality without founder approval.
  - R5 and R6 not started. Phase E HOLD.
- **2026-11-02** — Heather audio correction: three founder-approved seed-32 takes integrated by the 2026-10-17/18 route. Uncommitted.
  - **Replaced:** `voice_heather_v1/close_3b06cf13.m4a`, `part_closeWhatsOpen_a811d003.m4a` and `part_activeJob_5b1bb959.m4a`.
    - Each is byte-copied from the review master, which the frozen rule reproduces from its raw take.
    - No new loudness change.
  - **Integrity:** `PRODUCTION_SHA1.txt` changed 3 lines and verifies 172/172. F02/F03 8/8 unchanged. The originals are kept beside the record, and the baseline is 8bfd42c.
  - **Records:** `production.FOUNDER_FINAL` has 3 entries. Record folder: `artifacts/v2_phase_d2/voice_production/heather_seed32_integration_2026-11-02/`.
  - **Gates:** analyze clean; relevant tests 371/0; debug and QA debug APKs bundle 172/172 + 8/8.
  - **S25:** ending → F03 PASS (founder ear); real data restored byte-identical.
  - **New open finding:** Heather `part_shakeOut` has audible background noise at its end on the device (unchanged original).
  - **Social F04 Heather (separately, 2026-11-02):** t5 applied to the social manifest; CLOSED.
  - R5/R6 not started. Phase E HOLD.
- **2026-11-02** — Heather final audio-quality round: six founder-approved takes integrated by the 2026-10-17/18 route. Heather audio-quality correction round **CLOSED**. Uncommitted.
  - **Replaced:** `voice_heather_v1/part_shakeOut` (seed 34), `part_noteOneThing` (seed 31), `part_briskWalk`, `part_lookAround`, `part_roundTheBlock` and `part_sitOutside` (seed 32). File names unchanged.
    - The founder chose from a level-matched package. For roundTheBlock, seed 32 was preferred despite its shorter pause, overriding the automated recommendation.
  - **Loudness gate:** measured at real levels against Heather's shipping pack. No take breaks the frozen standard or becomes a new loudest part.
    - Only `part_noteOneThing` meets the getItOut threshold (2026-10-17 formula −1.8 dB), so it carries that one static trim; words, timing and pitch are unchanged.
  - **Integrity:** `PRODUCTION_SHA1.txt` changed 6 lines and verifies 172/172. F02/F03 8/8. The three earlier seed-32 files and all other voices (incl. the getItOut/oneTask trims) are byte-identical. Originals are kept beside the record; baseline 8bfd42c.
  - **Records:** `production.FOUNDER_FINAL` +6 entries. Record folder: `artifacts/v2_phase_d2/voice_production/heather_final_integration_2026-11-02/`.
  - **Gates:** analyze clean; relevant tests 371/0; debug and QA debug APKs bundle 172/172 + 8/8.
  - **S25:** five in-app Circles at real production levels, each new clip between unchanged neighbours: all six PASS (founder ear), including the shakeOut end noise gone. Real data restored byte-identical.
  - No generation, no credits. F04/social bank untouched. R5/R6 not started. Phase E HOLD.
- **2026-11-03** — **R5 accepted at implementation level (founder): I4 Keep after a lapse (Audit #2 A2-05 / Audit #1 m2).** This is not audit closure; no independent audit has reviewed it. Uncommitted.
  - **Fix:**
    - `InsightsNotifier.apply` exempts only `KeepCircleFromHistory`, under the unchanged validity (current, in History, not kept) and eight-Circle checks.
    - The Insights page offers that one card without Premium; "Not now" stays Premium.
  - **Tests:** `test/features/insights/r5_i4_keep_after_lapse_test.dart` (13: Premium; inactive, unavailable and initializing; stale; Not now; I1 and I3 still Premium; unknown id; eight kept; after Delete; a mid-session lapse; restart), plus one widget test in `insights_page_test.dart`.
  - **B8:** the simulation's lapse loop skips I4 Keeps (they are not exercised there, so its trajectory is unchanged). The exception is covered by the R5 file.
  - **Mutations:** 5/5 caught.
- **2026-11-03** — **R6 (copy, docs, config) implemented in part; awaiting founder review.** Uncommitted; Phase E HOLD.
  - **D-B, kept-Circle voice (founder decision):**
    - R4 already voiced a kept part only when its saved words equal the recorded script (no mismatched clip was ever played). R6 makes this whole-Circle: `ComposedSession.voiced`.
    - A kept Circle with any differing part has no opening, cues, ending, closing line or background session, and every running part shows a note.
    - Supersedes R4.1's per-part note. New line: `ComposedCopy.notSpokenCircle`, **proposed copy, awaiting founder approval**.
    - Tests: `r6_kept_voice_whole_circle_test.dart` (8). R4 and R4.1 tests updated to the new rule.
  - **TalkBack "bezig":** `ThirtyButtonCopy.busy` gives "<label>, loading" (**proposed copy**). Tests: `test/core/widgets/r6_button_busy_label_test.dart` (5); the existing button tests updated.
  - **Docs:** dated amendment notes in the contract (Free / Premium / after lapse), ADR-024 §11/§13 and ADR-023 §6. No sentence rewritten.
  - **m4 (Audit #1):** dated status notes on the stale contract line and three `final_audit` files.
  - **m5 (Audit #1):** `.gitattributes` keeps `artifacts/**/*SHA1.txt` LF.
  - **B8 content review pack:** regenerated (one line changed).
  - **Gates:** full suite 2,300/0; analyze clean; R6 mutations 5/5 caught. No device QA.
  - **Not done in R6, awaiting founder decisions:**
    - A2-06 analytics disclosure copy;
    - A2-07 Android device-transfer exclusions (belongs to the device-migration review);
    - A2-08, A2-09, A2-10, A2-11;
    - Audit #1 m1, m3, m6.
- **2026-11-03** — **R6b implemented; awaiting founder copy approvals.** Uncommitted; Phase E HOLD.
  - **A2-08:** I1's date range now spans the whole denominator window (`insight_engine.dart`).
  - **A2-09:** a journal record whose local date isn't a real `YYYY-MM-DD` date is unreadable at the read boundary (`isCanonicalDateKey`, `circle_journal.dart`). It is dropped like any record with an invalid required field, never normalised.
  - **A2-11:** the first touch after local midnight re-reads the day without a resume (`thirty_app.dart`). A Circle that is running keeps its own day until Close, and is recorded once.
  - **A2-10:** the variety metric is now structurally distinct (actual roles via `partRole`) at all three evidence sites. `ELEMENT_COVERAGE.md` and `b8/simulations/` were regenerated; only the metric and the A2-08 date lines changed. Dated notes were added to the B8 README, `SIMULATION_REVIEW.md` and ADR-024 §8. The frozen §8 counts are unchanged.
  - **A2-07:** recorded as an explicit gate under the Premium security & local device migration review (release gate).
  - **Tests:** `test/features/insights/r6b_insight_dates_test.dart` (10), `test/core/app/r6b_day_rollover_test.dart` (2), each failing before its fix. Full suite 2,312/0; analyze clean. Mutations: A2-08 1/1, A2-09 1/1, A2-11 2/3 (the uncaught one removes a same-day short-circuit with no observable effect).
  - **Correction to earlier reports:** the app sends six analytics event types, not three: `app_opened`, `recommendation_shown` (need, activity id), `circle_started`, `circle_closed`, `circle_attempt_reported` and `circle_usefulness_reported` (answer).
  - **Awaiting the founder:** A2-06 disclosure copy; R6 strings (kept-Circle note, busy label); m1, m3, m6 copy.
- **2026-11-03** — **R6 final corrections applied (founder copy direction); awaiting founder acceptance.** Uncommitted; Phase E HOLD.
  - **Copy applied:**
    - kept-Circle note: "Spoken guidance isn’t available for this saved Circle. You can still follow each part.";
    - busy label "{label}, in progress" (purchase: "Become Premium, in progress");
    - I4 labels "Outside or fresh air" / "Tidying or an active task";
    - Stage 5 mixed line "Some stages didn’t feel useful, and THIRTY set the others aside. It hasn’t made a last Circle from them." (worded for what set aside means: THIRTY sets a stage aside for parts left out, resting or not to be suggested);
    - A2-06 "Share usage data", plus a detail naming the six events, their fields and the random ID, and what turning it off does;
    - Delete dialog: "If you shared usage data, what was already sent isn’t deleted."
  - **A2-09 data safety:** every journal save now writes records it can't read back verbatim (`_unreadableStored`), and export carries them as `entriesUnreadable`; Delete still removes all. **Still open:** a journal whose whole stored wrapper is unreadable is replaced by the next save (pre-existing).
  - **A2-11:** reworked so the first touch never swallows its action. No Circle offered → the day is re-read as the touch begins; otherwise the touch acts first and the new day opens after; never while running, nor while a Circle closed after midnight awaits its reflection.
  - **Tests:** `r6_purchase_busy_label_test`, `r6_stage5_end_line_test` (5), `r6b_journal_unreadable_preserved_test` (4), `r6b_day_rollover_test` (5). Mutations: A2-11 4/4, A2-09 write-back 1/1. B8 pack regenerated.
  - **Audio:** production 172/172 and framing 8/8 SHA-1 OK. m6 is not applied (complete four-line table awaiting the founder).
  - **A2-06 remains a blocker for measurement and public release:** no retention policy, no user-requested deletion and no privacy policy exist yet.
- **2026-11-03** — **R6c journal data safety implemented; awaiting founder acceptance.** Uncommitted; Phase E HOLD.
  - **Root cause:** every journal save rewrites the whole stored journal from what it read. A stored journal THIRTY couldn't read as a whole (not JSON, not an object, no entries list, an unknown version) read as empty, and the next save wrote over it. A journal written by a newer THIRTY was read as empty and overwritten the same way.
  - **Fix (`circle_journal.dart`):**
    - **Before every save:** a journal THIRTY can't read is appended, byte for byte, to `circle_journal_preserved_v1` (`circleJournalPreservedKey`), and only once the disk confirms that write. An earlier copy is never replaced, and a copy is kept once.
    - **A newer schema** is never written over.
    - **Failure:** a refusal or a failed copy throws `JournalWriteRefused` and writes nothing. The in-memory cache is restored, so the next save tries again.
    - **Export:** shows `journalStored` and `journalPreserved`.
    - **Delete:** Delete Circle history (`clearAll` and the R3 deletion) removes the copies too.
  - **Tests:** `r6c_journal_store_safety_test.dart` (11; 9 failed before the fix). Mutations 4/4 caught.
  - **Stage 5:** the all-set-aside line now names resting parts ("…or that are resting for now."). ADR-024 amendment note added; B8 pack regenerated.
  - **Open for the founder:**
    - starting yesterday's not-yet-started Circle after midnight (it keeps yesterday's date);
    - m6 (four lines, not applied);
    - A2-06 retention, deletion and privacy policy;
    - A2-07.
- **2026-11-03** — **R6 final closure batch implemented; awaiting founder acceptance.** Uncommitted; Phase E HOLD.
  - **Midnight (founder rule):** `RecommendationNotifier.start` never starts an offer whose day has passed. Start opens the new day instead and nothing starts; today's Circle is then started deliberately. The rule also holds for a screen reader's activation. A Circle started before midnight still continues and closes under its own day, recorded once.
  - **m6:** the four founder-approved Free lines are applied (`activity_catalog.dart`). Activities, ids and status are unchanged, and no recording is affected.
  - **Journal save outcome:**
    - each save's outcome reaches the screen (`journalSaveStatusProvider`);
    - a failed save is shown once per Circle (`JournalSaveFailureNotice` in the app shell, `ThirtyNoticeDialog`): "This Circle couldn’t be saved to History." / "Your existing saved data wasn’t overwritten.";
    - History says "Some earlier History couldn’t be opened. THIRTY preserved a copy before continuing." when a copy was kept;
    - for a journal it can't open and hasn't copied (damaged, or from a newer THIRTY), History shows the **proposed** "Some earlier History couldn’t be opened. THIRTY is leaving it as it was stored." (awaiting founder approval) instead of "Nothing recorded yet";
    - a journal write that returns false is treated as a failure.
  - **Tests:** `r6_free_copy_test.dart` (5), `r6_journal_save_failure_test.dart` (9), plus midnight tests rewritten for the rule (10 in `test/core/app`). Mutations 2/2 caught. B8 pack regenerated.
- **2026-11-03** — **R6 FINAL VERIFIED: accepted at implementation and test level.** This is **not** an independent audit. Uncommitted; Phase E HOLD.
  - **Last copy:** "Your History couldn’t be opened. THIRTY has left the stored data unchanged." (History THIRTY can't open, no copy yet).
  - **Full suite:** run in memory-bounded sequential batches (`artifacts/r6_final_verification_2026-11-03/`). **159/159 test files, 2,353 passed, 0 failed, 0 skipped**; `COVERAGE_MANIFEST.json` shows none not run, none unexpected, none incomplete. The host stopped one background batch for low memory; that file was rerun in five foreground parts, 13 of 13 profiles. `flutter analyze` clean. Audio 172/172 + 8/8 SHA-1 OK.
  - **Still open, not solved by R6 (public-release blockers):**
    - A2-06: analytics retention schedule, server-side deletion, privacy policy, verification of Supabase data handling;
    - A2-07: Android backup and device migration, Premium restore and transfer checks;
    - the Premium security review (tampering, subscription recovery, no QA overrides in production);
    - the six-language launch and final commercial audits.
  - **R7 entry (awaiting founder authorization):**
    1. founder authorizes R7;
    2. agree the auditable commit's scope (code, tests, docs, the `artifacts/` evidence and media; personal data cropped);
    3. full regression on the final tree (same batch method if memory requires);
    4. one commit on `step5-billing-integration`, then push (never main, no force), local SHA == remote;
    5. hand that SHA to the targeted independent audit (billing A2-01, R2–R6).
- **2026-11-04** — **R7 final regression, auditable commit and controlled push (founder authorization, 2026-11-03).** Phase E HOLD; no commercial release.
  - **Commit scope:** one remediation commit on `step5-billing-integration`, parent `8bfd42c`. It holds 97 modified and 73 added paths, with no deletions, plus `artifacts/r7_final_regression_2026-11-04/` and this entry:
    - R1–R6 code and tests (159 test files);
    - the 9 founder-approved Heather replacements and the 8 F02/F03 framing clips, with their SHA-1 manifests and integration records;
    - the contract and ADR amendment notes;
    - the regenerated B8 pack;
    - the two post-D2 audit reports, unchanged;
    - the R6 and R7 verification summaries.
  - **Deliberately not committed (kept locally, unchanged):**
    - the six-language and Founder Dashboard planning folder `artifacts/launch_six_language_2026-11-03/` (drafts, including the unapplied Amendment 3, and discontinued KEYBRACE material);
    - raw and intermediate audio, auditions and listening files;
    - device screenshots and recordings;
    - earlier-phase local artifacts;
    - raw test logs (`*.jsonl`);
    - `android/build/`, `AGENTS.md`, and two unreferenced Quiet Trail morning PNGs.
  - **Verification:** the inclusion manifest was written into a separate index and checked out into a fresh detached worktree, and only that tree was tested:
    - **159/159 files; 2,353 passed, 0 failed, 0 skipped.** No empty or non-zero runs. Per-file counts are identical to R6.
    - All 13 year profiles ran, each exactly once (`CASE_COVERAGE.json`).
    - `flutter analyze` clean.
    - Audio 172/172 + 8/8 SHA-1 OK.
    - The secrets and privacy scan of every staged text file is clean.
  - **No device QA in R7.**
  - **Handoff:** `artifacts/r7_final_regression_2026-11-04/AUDIT_HANDOFF.md`. Audit the pushed SHA, not a working tree.
  - **Still OPEN:** A2-06, A2-07, the pre-commercial security review, the six-language launch, and the Founder Dashboard.
- **2026-11-04** — **R8 post-independent-audit remediation implemented; awaiting founder acceptance.** Uncommitted, on top of `8ece26f6`, which stays the audited baseline (Astra FAIL, Claude CONDITIONAL PASS). Phase E HOLD.
  - **Findings:**
    - Astra R7-A01…A04 (HIGH) and A05…A08 (MEDIUM): taken from the founder directive; the Astra report itself wasn't available locally.
    - Claude F-1…F-6, plus recommendations.
    - All are deduplicated into 15 register entries: `artifacts/r8_post_audit_remediation_2026-11-04/ISSUE_REGISTER.json`.
  - **Shared fix:** `writeConfirmed` (`lib/core/storage/confirmed_write.dart`).
    - A throw or a `false` from the store is a failure, and memory is put back to what is on disk.
    - It is used by Today's day keys, History, kept Circles, Plans, Insights and Delete.
    - Failures are shown in the app shell.
  - **Behaviour:**
    - Delete records its intent on disk before removing anything (one retry); otherwise nothing is deleted and the user is told.
    - A Keep and an I4 apply are confirmed before they are shown.
    - A malformed kept collection, damaged saved words and damaged Insight dates are kept as stored and never overwritten or substituted.
    - Unreadable History can be copied and deleted.
    - Yesterday's running Circle survives a resume or restart after midnight, within a proposed 6-hour limit.
    - A no-touch choice uses the real time.
    - "Restored" is shown only when billing verifies Premium active.
  - **Tests:**
    - 94 new R8 tests; 73 fail on the R7 tree, and the other 21 are guards.
    - Full suite in memory-bounded batches: **167/167 files, 2,448 passed, 0 failed, 0 skipped**; all 13 year profiles ran, each once.
    - The source fingerprint was unchanged across the run. `flutter analyze` clean.
    - Audio 172/172 + 8/8 SHA-1 OK.
  - **Awaiting the founder:**
    - proposed copy: "This change couldn’t be saved."; "Your history wasn’t deleted." / "Nothing was changed. You can try again.";
    - `midnightCarryOverLimit` = 6 h (TUNABLE);
    - the R3 Delete timing change (memory is cleared once the intent is confirmed);
    - the Astra report, for a cross-check.
  - **Still open:** A2-06, A2-07, pre-commercial security, the six-language launch, the Founder Dashboard and the final audits. Independent re-audit of a new SHA is NOT STARTED.
- **2026-11-04 (later)** — **R8 pre-commit gate: founder decisions D1–D3 applied; corrections P2, overwrite protection and Delete ordering made.** Uncommitted; awaiting founder acceptance. Phase E HOLD.
  - **D1:**
    - "This change couldn’t be saved." / "Please try again.";
    - "Your history wasn’t deleted." / "Nothing was changed. You can try again.".
  - **D2:** a six-hour carry-over of real elapsed time, frozen in the contract amendment.
  - **D3:** the Delete intent is confirmed before anything else, frozen in the contract amendment.
  - **P2:** a failed recovery-record cleanup is pending retry, not "not saved".
  - **Overwrite protection:** an earlier day's unrecorded Start or Close is never overwritten by the next day's choice; under a persistent History failure, today's choice isn't durable and the user is told.
  - **Delete ordering:** a Delete that never began stops no write.
  - **Astra report:** read in full; cross-checked.
  - **Full suite:** **169/169 files, 2,484 passed, 0 failed, 0 skipped**; 13/13 year profiles. Source fingerprint unchanged; analyze clean; audio 172/172 + 8/8.
  - **Evidence:** `artifacts/r8_post_audit_remediation_2026-11-04/` (README, ISSUE_REGISTER with 20 entries, COMMIT_INVENTORY).
- **2026-11-04 (later)** — **R8 ACCEPTED by the founder at implementation and reported-test level; committed as one R8 commit on top of `8ece26f6` and pushed to `origin/step5-billing-integration`.** This is NOT independent audit closure. Phase E HOLD; no commercial release authorized.
  - **Approved:** D1 copy (typographic apostrophes); D2 six-hour carry-over; D3 durable Delete intent before the write barrier; P2 recovery-record cleanup is pending retry; the fail-closed rule for a persistent History failure (do not remove for convenience).
  - **Commit identity:** a commit cannot hold its own SHA. Its parent is `8ece26f6dbd41f573e854b8fc82f44a6942282e3`; the full SHA is in the local push record `artifacts/r8_post_audit_remediation_2026-11-04/R8_PUSH_RECORD.md` and the founder report.
  - **Re-audit handoff:** `artifacts/r8_post_audit_remediation_2026-11-04/AUDIT_HANDOFF.md`. Both auditors must inspect the exact new commit. Re-audit NOT STARTED.
  - **Still OPEN:** A2-06, A2-07, commercial subscription and APK security checks, six-language localization (zero unapproved hardcoded user-facing text, complete multilingual audio, native-language QA), the final commercial release audit. The KEYBRACE Founder Dashboard is a separate project; KEYBRACE OS is discontinued.
- **2026-11-11** — **Tracker reconciliation: R8.1 → R8.3.4.1 and L-1 (recorded after the fact; no historical entry changed), and the pre-release product gap register (approved by the founder 2026-11-11 as planning authority only).** Phase E HOLD; commercial release NOT AUTHORIZED; deployment NONE.
  - **Rounds since the R8 commit `58b179c9`**, each one commit on `step5-billing-integration` with the previous round as its sole parent. Test totals as reported in each round's evidence folder:

    | Round | Commit | Date | Tests | Evidence |
    |---|---|---|---|---|
    | R8.1 | `e935112c` | 2026-11-05 | 2,599/0 | `artifacts/r8_1_consolidated_remediation_2026-11-05/` (includes RL-4) |
    | R8.2 | `e744f505` | 2026-11-06 | 2,774/0 | `artifacts/r8_2_consolidated_remediation_2026-11-05/` |
    | R8.3 + R8.3.1 | `9c910773` | 2026-11-07 | 2,872/0 | `artifacts/r8_3_bounded_integrity_hardening_2026-11-07/`, `artifacts/r8_3_1_founder_lifecycle_correction_2026-11-07/` |
    | R8.3.2 + G1 | `d4cf8c44` | 2026-11-09 | 2,966/0/0 | `artifacts/r8_3_2_*` |
    | R8.3.3 | `285b5c70` | 2026-11-10 | 2,999/0/0 | `artifacts/r8_3_3_consolidated_integrity_closure_2026-11-10/` |
    | R8.3.4 | `dd9000cd` | 2026-11-10 | 3,023/0/0 | `artifacts/r8_3_4_final_action_identity_closure_2026-11-10/` |
    | R8.3.4.1 | `d9369795` | 2026-11-11 | 3,055/0/0 | `artifacts/r8_3_4_1_delete_outcome_continuity_2026-11-11/` |
    | **L-1 Option B** | `c83543d5` | 2026-11-11 | 3,143/0/0 | `artifacts/l1_option_b_2026-11-11/` |

  - **Independent audit reports** of these rounds are in `docs/audits/` (post-R8, post-R8.1, post-R8.2, R8.3 and R8.3.2 deltas) and in each round's audit inputs.
  - **Founder status (2026-11-11):**
    - **R8 engineering baseline FROZEN at `d9369795`.**
    - **L-1 ENGINEERING ACCEPTED** at `c83543d5`, with its documented limitation: independent Flutter runtime verification, simulated storage only (`artifacts/l1_option_b_2026-11-11/LIMITATIONS_L1.md`).
    - Engineering closure waives no platform, device, accessibility, backup or privacy gate.
  - **Corrections to earlier entries:**
    - **Analytics events.** The app sends **six** consent-gated analytics event types (R6b correction, 2026-11-03), not three.
    - **A2-06 in-app copy.** The in-app disclosure ("Share usage data") was applied in R6 final. A2-06 stays open only for the server side: the retention schedule, server-side deletion, the privacy policy and Supabase data handling.
  - **Still OPEN (unchanged):** A2-06 (server side), A2-07, the Premium security & local device migration review, the RL-4 pre-commercial decision, live billing, the safety review, MEASUREMENT-1, privacy/support/Data Safety, store readiness, the final release audit.
  - **Approved (2026-11-11), as planning authority only: [THIRTY_PRE_RELEASE_PRODUCT_GAP_REGISTER.md](THIRTY_PRE_RELEASE_PRODUCT_GAP_REGISTER.md).**
    - **Content:** the canonical planning register for the remaining product gaps:
      - G-01 onboarding;
      - G-02 six launch languages (founder direction; the 2026-11-03 amendment draft is still unapplied);
      - G-03 multilingual Premium voice;
      - G-04 Free/Premium viability;
      - G-05 UX;
      - G-06 release gates;
      - CD-1 content-depth acceptance;
      - G-07 safety proportionality;
      - G-08 long-term ecosystem (strategy only; canonical home `docs/strategy/THIRTY_PRODUCT_FAMILY_STRATEGY.md`).
    - **Testing sequence:** the founder's full-product-first order. Google Play pre-release testing happens only on the complete six-language product; earlier signed builds are bounded pilots, never a pre-release.
    - **Authority:** it is the canonical planning register only. It changes no contract (contract changes need separate, explicit approval), it authorizes no product development, and its implementation and commercial founder decisions remain OPEN.
- **2026-11-12** — **Amendment 3 recorded (founder decision): six launch languages** (en, fr, nl, es-ES, de, it) with full Free/Premium parity, per-locale gates, zero unapproved hard-coded user-facing text, English fallback only for unsupported device languages, and a founder-approved native-quality voice experience in every launch language for T2/T3 (counts and personas: D-V-1…5). ADR-025/026/027 *Proposed*, none accepted. Nothing implemented. Phase E HOLD; commercial release NOT AUTHORIZED; deployment NONE. Evidence: `THIRTY_G02_SIX_LANGUAGE_DECISION_GATE_2026-11-12/` (outside the tree).
  - **Also decided the same day (G-02 package rev 2):** D-L-1b dependencies `flutter_localizations` (SDK) + `intl: ^0.20.2`; D-L-1c ADR-025 accepted within its stated scope; D-L-5 Part A of ADR-026 approved as principles, Part B (persisted `sourceLocale` = D-L-5c, journal schema 3, export envelope, D-RL4) on HOLD; D-ON-3 (a language preference alone never counts as existing-user evidence); D-V-3 (no mismatched spoken language, no substitute voice); Q-1 (T2 requires approved native-quality spoken guidance in every launch language). Still OPEN: D-V-1, D-V-2, D-V-4, D-V-5, D-L-6…D-L-9, G-01 implementation, SAF-1 clearances.
