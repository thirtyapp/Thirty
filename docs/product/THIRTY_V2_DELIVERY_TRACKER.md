# THIRTY V2 DELIVERY TRACKER

Status only. What is being built is defined in [PRODUCT_V2_CONTRACT.md](PRODUCT_V2_CONTRACT.md).

## Current state

| | |
|---|---|
| **PRODUCT V2 CONTRACT** | FROZEN (2026-10-08) |
| **PUBLIC LAUNCH** | PAUSED |
| **CURRENT IMPLEMENTATION PHASE** | PHASE D2 — IN PROGRESS (Recurring Premium redesign; Phase E on hold) |
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

**STATUS: PASS — COMPLETE** (2026-10-10; see [ADR-022](adr/ADR-022-v2-phase-d-paths-toolkit-and-maintenance.md)) — the historical V2 Premium architecture. Its Premium headline is superseded by Phase D2 (ADR-023); its Paths, Toolkit and maintenance remain, as supporting infrastructure.

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

**STATUS: IN PROGRESS** (started 2026-10-11; see [ADR-023](adr/ADR-023-v2-recurring-premium-personal-guided-circle.md) and the contract amendment of 2026-10-11)

- **Purpose:** give monthly Premium a legitimate recurring job. Every day, THIRTY turns the user's need and time into one personal guided Circle built from what has worked for them, then guides them through it. Phase D's Paths and Toolkit stay, as supporting infrastructure.
- **Scope:**
  - Governance: ADR-023, the contract amendment, and this entry. Phase D's history is untouched.
  - An element model and a safe release element library, with a coverage report.
  - A pure, local, deterministic composer with a documented quality gate and time-use policy, falling back to Free when no honest composition exists.
  - Premium Today integration, and a guided composed runtime on Phase C's shell.
  - Element controls: skip this step, and leave this out next time, reversible in Memory, with documented evidence boundaries.
  - Ownership: "Use it today" (Free), kept Circles, and the lapse boundary.
  - Paths, Toolkit and maintenance repositioned as supporting infrastructure.
  - Truth fixes: the hidden routine rest from Path-trial answers, the Toolkit check's "working well" claim, and the time-misfit wording.
  - Premium offer copy for the recurring job. Billing stays a subscription; price is untouched.
  - Long-horizon internal simulations (day 1 to month 12), a content pack, and device QA.
- **Acceptance (all required):**
  - Recurring Premium contract frozen.
  - Element model and safe release library complete.
  - Composer, Premium Today and composed runtime complete.
  - Explicit element control complete.
  - Free unchanged in capability, and owned routines and Circles stay Free.
  - Hidden-rest and truth-copy defects fixed.
  - No gated or retired content leaks.
  - Long-horizon simulations pass structurally.
  - Full suite and analyze clean.
  - Real-device QA and TalkBack pass.
  - Founder content review passes.
  - Founder approval of the production voice recordings (spoken guidance: bundled, pre-generated; founder decision 2026-10-11), with all 42 clips bundled and QA'd.
  - Android background playback for a voiced Circle works on the S25, including screen off and locked (founder decision E, 2026-10-12).
  - Documentation matches the implementation.
- **Device proof:** S25. Free unchanged; Premium 10/20/30-minute guided sessions; skip and leave-out; next-day effect; Use it today; Path; Toolkit; lapse and resubscribe; dark mode, 130 % text and TalkBack.
- **Commercial question:** does a personal guided Circle every day feel worth a monthly subscription? Unproven until pre-release users try the complete product.
- **Dependencies:** Phase D.

## Phase E — Measurement & release

**STATUS: NOT STARTED — ON HOLD until Phase D2 passes**

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
