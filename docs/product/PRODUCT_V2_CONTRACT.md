# THIRTY PRODUCT V2 CONTRACT

## Status

**FROZEN FOR IMPLEMENTATION** — founder-approved 2026-10-08.

- The **product architecture** in this document is frozen. Changing it requires an explicit founder decision.
- Values marked **TUNABLE** are implementation hypotheses. They may change on device or simulation evidence without reopening this contract.
- **Commercial terms** (price, trial, billing cadence) are **not** frozen. See [Commercial hypotheses](#commercial-hypotheses--not-frozen).
- Delivery status lives in [THIRTY_V2_DELIVERY_TRACKER.md](THIRTY_V2_DELIVERY_TRACKER.md), not here.

Where any older THIRTY document conflicts with this contract, **this contract is authoritative** (see [Authority](#authority)).

> **Amendment 2 — Circle Plans, Insights and the four-tab product (founder decision 2026-10-17).** The founder approved the final pre-implementation product contract and launch copy. Where this amendment, or a section marked *(amended 2026-10-17)*, conflicts with anything else in this document — including Amendment 1 below — **Amendment 2 wins**. It is realised by [ADR-024](adr/ADR-024-v2-circle-plans-insights-and-four-tab-product.md) (Accepted, 2026-10-21), which supersedes the Paths/Toolkit/maintenance portions of ADR-022 and ADR-023 §8–§9. The authoritative design source is *THIRTY — Final pre-implementation contract repair* (2026-10-17), recorded in ADR-024.
>
> - **Navigation:** Today | Plans | Insights | You.
> - **Commercial frame:** THIRTY is designed as a **recurring-revenue product for KEYBRACE**. Premium's continuing value is four distinct paid jobs, all continuing software work:
>   - **Today** — a newly composed Personal Guided Circle;
>   - **Direction** — an operating Circle Plan across several matching Circles;
>   - **Understanding** — new evidence-aware Insights and user-approved applications;
>   - **Guidance** — THIRTY's spoken guidance, including background playback.
>
>   The recurring model never depends on confiscating user-owned content: after a lapse, owned and readable data stays owned and readable, and only the continuing services stop. Willingness to pay, conversion and retention are **not proven**.
> - **Restored:** [Circle Plans](#circle-plan-contract-amended-2026-10-17) (three launch Plans built from StageBriefs that steer the composer) and [Insights](#insights-contract-amended-2026-10-17) (six evidence-aware, actionable families). Neither is a restoration of V1 code or V1 content.
> - **Retired before public release:** Paths, routines, tune-ups, shorter routine versions, Toolkit maintenance and the Toolkit tab. **Kept Circles are the only reusable owned object**, managed in **Yours** under You.
> - **History and the calendar** are Free and shared. The calendar sits visually inside Insights; the records stay user-owned.
> - **Voices:** four Premium production voices — Locke, Heather, Milo and Brittney — with 43 production files each (42 guidance cues and one Preview): **172 production audio files**, PASS and FROZEN. No new Plan or Insight audio is required.
> - **Implementation:** pending (ADR-024 batches B1–B9). Until it ships, the built app still shows the Phase D/D2 Toolkit; that is implementation status, not product direction.

> **Amendment 1 — Recurring Premium (Phase D2), founder decision 2026-10-11.** The Premium job changes; everything about Free stays as written. Where this amendment conflicts with the Premium sections below ([Product progression](#product-progression) "Premium" row, [Premium V2 contract](#premium-v2-contract), the Premium column of the [boundary](#free--premium-boundary), and "Premium as toolkit process" among the frozen rules), **this amendment wins**. Realised by [ADR-023](adr/ADR-023-v2-recurring-premium-personal-guided-circle.md), which supersedes the conflicting Premium portions of ADR-022. The text below this note is kept as it was frozen on 2026-10-08.
>
> - **Premium job:** "THIRTY turns the time I have today into a personal guided Circle built from what has worked for me, then guides me through it." Free chooses one good activity; Premium creates and guides one coherent personal session for today. Today's session is perishable, and tomorrow THIRTY does the work again.
> - **Today is the Premium value surface.** The user still states only need and time. Premium never composes merely because the user pays: when no honest, high-quality composition exists, Today falls back to Free's choice.
> - **Paths, routines, Toolkit and maintenance** — *superseded by Amendment 2:* retired before public release. (As built in Phase D2 they were supporting infrastructure, never the headline reason to subscribe.)
> - **Free keeps:** everything in the [Free V2 contract](#free-v2-contract), plus use of everything the user owns — **kept Circles** (amended 2026-10-17; routines are retired) — including a bounded **"Use it today"** before today's Circle starts.
> - **Premium monthly owns:** the new Personal Guided Circle each day, its guided multi-part session, THIRTY's own spoken guidance (with background playback and a choice of THIRTY's four voices), and ongoing personal variation from explicit evidence. *Amended 2026-10-17:* plus running Circle Plans and new Insights; Paths, tune-ups and shorter versions are retired. The complete current boundary is [Free / Premium / after lapse](#free--premium--after-lapse-amended-2026-10-17).
> - **Lapse:** the user keeps every kept Circle (with its instructions, structure and visual pacing), its name, History, Memory, export and delete, ordinary Free Today, "Use it today", and every accessibility support. THIRTY stops composing a new Personal Guided Circle, and its spoken guidance stops, until the user resubscribes. **Owned Circles remain fully owned and visually usable after Premium lapse. Cancellation removes new composition and THIRTY spoken guidance, not owned content.** (Founder decision 2026-10-12; routines removed from this list 2026-10-17 because they are retired. Plans and Insights after a lapse: see [Free / Premium / after lapse](#free--premium--after-lapse-amended-2026-10-17).)
> - **Spoken guidance** (founder decision 2026-10-11): bundled, pre-generated, high-quality recordings, played offline and looked up deterministically. No runtime generative AI, no voice API or other recurring cost, and no device text-to-speech as the intended experience. The user can turn it off; the visual runtime and accessibility are complete without it.
>   - **THIRTY spoken guidance is a Premium service layer. Accessibility output, including TalkBack, is entitlement-independent and remains available to all users** (founder decision 2026-10-12).
>   - **Four voices** (founder decision 2026-10-16; supersedes the two-voice decision of 2026-10-12): Locke, Heather, Milo and Brittney, all Premium, named without gender. Each has 43 production files — the 42 guidance cues and one Preview — so **172 production audio files** ship. The user's choice is a local preference that survives a lapse.
>   - **Founder approval:** all four voices and the complete pack are founder-approved (2026-10-17), generated under a paid ElevenLabs plan with commercial rights. Production audio is **PASS — FROZEN**.
>   - **Out of sight (Android):** a voiced Circle keeps speaking with another app open, or with the screen off and locked, through a media-playback foreground service that exists only while that Circle runs (founder decision 2026-10-12; ADR-023 §6). The guidance service may start only for an explicitly started Circle that is eligible for THIRTY spoken guidance, when Premium is active, spoken guidance is enabled, a complete production voice is bundled, and accessibility rules permit THIRTY voice output.
> - **Billing:** recurring subscription; monthly is the economic target. No lifetime purchase. Price stays a Phase E commercial hypothesis.
> - **Unchanged and still binding:** the safety gate, one Circle per day, no streaks, scores, levels, collectibles or content treadmill, no runtime AI or cloud personalisation, local-first deterministic and explainable behaviour, editable Memory, and hard "Don't suggest".

---

## Product job

> **"Help me decide what could help me feel better today."**

## Product progression

| When | What the user should feel |
|---|---|
| **Day 1** | THIRTY chooses something sensible. |
| **Day 7** | THIRTY remembered. |
| **Day 30** | THIRTY understands what tends to suit me. |
| **Premium** *(amended 2026-10-17)* | THIRTY makes and guides a Circle for my day, gives a few Circles a direction, and tells me — truthfully — what my own use shows, with one change I can approve. |

## Core loop

```
TODAY NEED + TIME + LOCAL EXPLICIT EVIDENCE + ACTIVITY FIT + RECENCY / VARIETY
→ ONE RECOMMENDATION
→ ACTIVITY-SHAPED CIRCLE
→ EXPLICIT FEEDBACK
→ LOCAL MEMORY
→ BETTER FUTURE DECISION
```

---

## Free V2 contract

- One primary Circle per local day.
- The user states today's **need** — More Energy, Clearer Head or Gentler Pace — and a **time window**.
- THIRTY offers **one** activity, chosen locally and deterministically. It weighs multi-direction fit, time fit, the user's explicit evidence, recency, variety and today's constraint.
- **Not this one today:** one bounded replacement per day (see [below](#not-this-one-today)).
- The Circle runs in one of three modes (Open / Guided Steps / Paced), at the activity's natural length of up to about 30 minutes, with the guidance it needs.
- **Close** brings a calm completion moment with **inline feedback**, and the effect of that feedback is acknowledged.
- Feedback **changes later recommendations** — bounded, decaying, never an inferred permanent ban.
- Truthful recommendation reasons appear only when evidence supports them.
- A visible, editable **memory page**.
- Humane, truthful history. User-owned local data, export, Delete, reminders and Worlds.
- Free recommendation intelligence is **never** weakened to create Premium scarcity.

## Premium V2 contract *(amended 2026-10-17)*

Premium sells **continuing software work**, never access to the user's data or owned Circles. It has four paid jobs:

| Job | What THIRTY does each time |
|---|---|
| **Today** | Composes a new Personal Guided Circle for today's need and time ([Amendment 1](#status); [ADR-023](adr/ADR-023-v2-recurring-premium-personal-guided-circle.md)). |
| **Direction** | Operates a [Circle Plan](#circle-plan-contract-amended-2026-10-17): on each matching day its current stage steers that Circle, and the Plan progresses, waits, sets a stage aside or ends in a review. |
| **Understanding** | Computes new [Insights](#insights-contract-amended-2026-10-17) from the user's own record, each with an application the user may approve. |
| **Guidance** | Speaks the Circle in THIRTY's voice, including with the screen off (background playback). |

*Superseded:* the 2026-10-08 process "Paths → routines → Personal Toolkit → maintenance" (Phase D, [ADR-022](adr/ADR-022-v2-phase-d-paths-toolkit-and-maintenance.md)). It was built and is retired before public release.

## Free / Premium / after lapse *(amended 2026-10-17)*

This table supersedes the 2026-10-08 boundary table and the Premium column of Amendment 1.

### FREE
- Today: Engine V2's one activity, its normal recommendation, feedback and learning, reasons, time fit, and Not this one today.
- Circle guidance in all three modes.
- Memory and all its controls.
- History: the list, the calendar and record detail.
- Export and delete; reminders; Worlds.
- Accessibility, TalkBack included.
- **Keep** (never gated).
- Use, rename and remove owned kept Circles, on screen and paced.
- A truthful, readable preview of the three Plans.

### PREMIUM
- Personal Guided Circle composition.
- THIRTY's spoken guidance and its background playback.
- Running Plans: stage-steered composition, stage progression and revisits, set-aside handling, Plan reviews and repeat cycles.
- New Insights and their applications.
- Leave it out (a composer control).
- Voiced kept Circles while the entitlement is active.

### AFTER LAPSE
**Preserved and readable:**
- kept Circles;
- History and the calendar;
- Memory;
- leave-outs, with Put it back;
- saved Plan places and cycles;
- existing Plan reviews;
- existing Insight snapshots;
- applied settings;
- the voice choice;
- export and delete.

**Stops until resubscribing:**
- new Personal Guided Circle composition;
- THIRTY's production voice and its background service;
- Plan steering and progression;
- new Plan reviews;
- new Insights;
- new Insight applications.

**No hostage mechanics.** Ordinary Free Today, "Use it today" and every accessibility support stay.

---

## Activity model

**FROZEN**
- **Multi-direction fit.** Each activity has **PRIMARY / SECONDARY / NONE** fit for each of the three needs. There is no three-pool architecture.
- **Natural duration**, up to about 30 minutes. Each activity has a **minimum** and a **typical** duration. Activities are never padded to fill time.
- **Mode:** Open, Guided Steps or Paced.

**TUNABLE**
- Individual fit placements.
- Exact minutes.
- Effort and setting attributes.

## Catalogue status

- The current 21 activities are the **starting catalogue**.
- **`energisingBreathReset` (Standing breath reset): its current concept is retired from the V2 live catalogue** (founder decision 1). The long/brisk breathing concept is not carried forward. It is not to be saved by shortening its wording.
- The Phase 1B candidate additions — Daylight minutes, Screen-break reset, Reach out to someone — are **OPTIONAL**. They become required only if Phase A or Phase B coverage review shows an uncovered recommendation case.
- There is no fixed target catalogue size.

## Content contract

Every activity must read as a designed experience. The V1 pattern of title + formulaic "why" + 30-minute timer is superseded.

| Mode | Minimum content |
|---|---|
| **Open** | Meaningful title; human reason; natural duration; first action; preparation if needed; optional in-session suggestions; ending line; lighter or shorter treatment where useful. |
| **Guided Steps** | Everything in Open, plus 3–6 named steps, each with an instruction and timing or repetitions, a lighter step set, and safety wording where required. |
| **Paced** | Safe, reviewed pacing parameters; setup; duration; stop and safety guidance; a reduced-motion equivalent. |

**Authoring workflow (founder decision 2):** Claude drafts content to this standard. The founder reviews and approves the user-facing experience. Claude never self-certifies health or safety content.

## Safety gate

*Founder decision 1.*

- Breathing content, and exertion content where relevant (for example stairs or slopes, and bodyweight movement), **cannot ship in any external or public build** until a separate, bounded safety/content review clears it.
- It may be developed internally behind that gate.
- No medical claims anywhere.
- *(Added 2026-10-17.)* **Before public release**, the bounded safety review required by the release gate must be resolved for the live breathing and exertion content, and for any still-gated activity proposed for release. Until then nothing is reactivated, and no Plan, StageBrief or Insight may weaken or route around a gate.

---

## Recommendation Engine contract

**FROZEN RULES**
- Local, deterministic, explainable, bounded and testable. The same inputs always produce the same pick.
- No runtime generative AI, no ML, no cloud personalisation, no black-box scoring.
- Need is not a hard silo. Fit **NONE** is excluded; **PRIMARY** and **SECONDARY** are both candidates, with primary preferred unless evidence or constraints justify secondary.
- Time fit: an activity whose minimum exceeds today's window is excluded, unless a lighter treatment fits.
- **Explicit feedback matters:**
  - *Not useful* makes an activity temporarily less likely, or rests it, in comparable context.
  - Positive answers make it more likely where appropriate.
  - No answer is UNKNOWN and carries zero weight.
- Feedback effects are bounded, decaying and reversible. **No inferred permanent bans.**
- One positive answer must not create a favourite loop: recency and variety always apply.
- Recency: never the same activity on consecutive days. Repetition is capped.
- Variety: no visible rotation. Ties are broken deterministically (date-seeded), never with `dayIndex % n`.
- Exploration is deterministic, labelled honestly, and never used on a short-window day.
- One bounded replacement per day. Its reason becomes a hard constraint for today and soft, decaying context afterwards. It is never counted as *Not useful*.
- **Sparse-data honesty:** no evidence-based reason is shown below the evidence threshold. A curated starter order serves new users.
- Every pick carries a reason code derived from its decisive evidence. At most one reason is shown. Wording stays truthful ("you've found this useful before"), never "this works for you".
- **Explicit user control** (for example *Don't suggest* on the memory page) may persist until the user reverses it. This is not an inferred ban.

**TUNABLE PARAMETERS**
- Decay rate.
- Rest length (starting hypothesis about 14 days).
- Evidence tiers and thresholds.
- Family carry-over strength.
- Recency caps.
- Exploration frequency.
- Evidence window (starting hypothesis 90 days).
- Reason thresholds.
- All copy.

## Time windows

*Founder decision 3.*

- **FROZEN:** an explicit time input exists, is visible each day, is preselected to the user's last explicit choice, and defaults to about 20 minutes on first use.
- **TUNABLE:** the buckets. The starting hypothesis is **≈ 10 / ≈ 20 / up to 30 minutes**.

---

## Memory contract

**Stored** (local only):
- local date, need, offered activity, offered duration and time window;
- shown, started and closed timestamps, and minutes at close;
- explicit attempt and usefulness answers;
- the replaced activity and the replacement reason;
- the recommendation reason code;
- the composed Circle's parts and any skipped parts;
- Plan, stage and cycle context *(amended 2026-10-17; replaces "Path, step and routine context")*;
- kept Circles *(replaces "routine definitions")*;
- Plan state: the place, any pending revisit, cycle records, set-asides, reviews and the user's Plan settings;
- Insight snapshots: the shown text, evidence dates, wording version and whether it was applied or dismissed — at most 52;
- the user's explicit memory corrections and preferences (including Leave it out).

**Derived** (computed, never cached as a profile): evidence scores, rests, recency, family carry-over, reason eligibility, memory-page observations, Plan stage eligibility and Insight eligibility. *(Amended 2026-10-17: "maintenance triggers" retired with the Toolkit.)* An Insight snapshot is a dated record of what was shown, not a profile.

**Never stored or inferred:**
- medical or mental-health states, diagnoses, mood or stress;
- personality or fitness level;
- health improvement;
- a hidden psychological profile;
- actual activity completion.

**Circle Close remains a factual app interaction. It does not prove the activity happened.** All learning must derive from user-visible, user-owned local evidence.

## Historical-learning compatibility

**History visibility ≠ recommendation-learning eligibility.**

- All valid historical (V1) records remain **visible, exportable and truthful**.
- Old attempt and usefulness evidence may influence Engine V2 **only** if the historical activity version is semantically compatible with the current V2 version. **The same activity ID is not sufficient.**
- In Phase A, every migrated activity is classified for the V1 → V2 transition:
  - **LEARNING_COMPATIBLE.** The experience is materially the same: clearer wording, title cleanup, a modest duration correction, newly exposed guidance, or small presentation changes. Its old explicit evidence **may** count.
  - **LEARNING_RESET.** The experience changed materially: a fundamental duration change, materially different instructions, a new structured experience, changed safety treatment, or a changed concept. Its old entries stay in History and Export, but their evidence **does not** influence V2 scoring.
- Removed or retired activities keep their history and contribute **no** learning. `energisingBreathReset` must not seed V2 learning.
- The same rule applies to any later activity revision that materially changes the experience.

## Delete / Export contract

**Delete Circle history** (founder decision 4):
- deletes the journal and history, and therefore **all learning derived from it**;
- also deletes Insight snapshots, Plan reviews and the stage evidence of Plan cycles, which are derived from the journal *(amended 2026-10-17)*;
- does **not** automatically delete kept Circles, the Plan place and settings, or explicit memory corrections and preferences, which have their own clear remove/reset controls *(amended 2026-10-17: kept Circles replace "user-created routines")*.

The confirmation copy must state this truthfully. No residue from deleted journal evidence may keep influencing recommendations, Plan stage 5 or Insights.

**Export** includes the journal (including the V2 fields), kept Circles, Plan state and reviews, Insight snapshots, and explicit corrections and preferences *(amended 2026-10-17; replaces "routines")*.

---

## Circle V2 contract

A Circle is **the activity-specific experience chosen for today**, not a generic timer. It uses a small set of reusable modes, never one bespoke screen per activity.

- **Open.** A strong first action; optional how-to one tap away; a quiet session timed to the activity's length; a gentle end cue; continuing past the cue is fine.
- **Guided Steps.** 3–6 bounded steps, one clear instruction at a time; an optional lighter variant; pause where needed; resumes correctly after backgrounding.
- **Paced.** A bounded short duration with controlled visual pacing; a reduced-motion text alternative; safety-appropriate background behaviour (it pauses). Only reviewed content.
- **Completion (all modes).**
  - Early exit is always allowed, with neutral wording.
  - A calm completion moment, which the World may support.
  - Inline feedback, with its effect acknowledged.
  - No confetti, badges, scores or streaks.
  - The record stays truthful.

## Memory page contract

- Free, visible and editable.
- Plain-language factual observations: what has helped, what is resting, what has not been tried, usual time.
- Lets the user correct or remove items (*Suggest again*, *Don't suggest*, remove an answer).
- Must **not** look like a psychological profile, a medical interpretation, an analytics dashboard or developer telemetry. No charts, scores or profile theatre.

## Not this one today

- Once per day, the user states one constraint or reason; candidate reasons are "Can't go outside", "Too much for today" and "Not feeling this one" (wording not frozen).
- THIRTY re-selects **one** replacement under that constraint.
- No list of alternatives, no browsing, no swap loop.

---

## Circle Plan contract *(amended 2026-10-17)*

**Job:** "Where am I going over several Circles, and what is the right next step?"

A Plan is **not** a streak, a calendar challenge, a renamed Path, a saved routine, a playlist, five static activities, or fake progress. It is counted in Circles on days the user chooses its need, never in calendar days. There are no compulsory days and no missed-day debt.

### Launch Plans (exactly three; founder-approved launch copy)

| Plan | Need | Stages (role) |
|---|---|---|
| **Getting going** | More Energy | 1 Loosen up (begin) · 2 On your feet (develop) · 3 Two together (apply) · 4 Fresh air (apply in a new setting) · 5 Your mix (consolidate) |
| **Making room** | Clearer Head | 1 Out of your head (begin) · 2 Room around you (develop) · 3 Down to one (apply) · 4 Less coming in (protect) · 5 Your way (consolidate) |
| **Slowing down** | Gentler Pace | 1 Slow hands (begin) · 2 Ease the body (develop) · 3 Something quiet (apply) · 4 Somewhere slower (apply in a new setting) · 5 Your pace (consolidate) |

Purposes, Today lines, the fifteen StageBriefs and all Plan-page copy are frozen in [ADR-024](adr/ADR-024-v2-circle-plans-insights-and-four-tab-product.md). Adding a Plan requires a distinct need and arc, and a founder decision. New Plans are never promised on a cadence or tied to renewal.

### StageBriefs

Each stage is a **StageBrief**: a condition on the main piece and/or the whole Circle, applied on top of the existing composer. Shared rules C1–C8 (full text in ADR-024):

- **C1 — Composition.** The existing composer, with every hard limit and the quality gate unchanged. A brief only adds conditions; ranking inside it is unchanged.
- **C2 — Time fit.** A stage composes for today's time choice; a brief marked *serves up to ≈20* composes at ≈20 size on an up-to-30 day. Nothing is padded, stretched or repeated. More time is never a reason to wait.
- **C3 — Set aside or wait.** When no Circle that fits the brief passes the gate today: if one *would* pass with the user's own controls ignored, the stage is **set aside**; otherwise it **waits** (below).
- **C4 — Not this one today.** One replacement a day: first recompose inside the brief under the constraint; then without the brief (the stage waits); then Free's one activity.
- **C5 — Feedback.** A stage Circle's answer is recorded against the stage. It counts like any composed Circle's answer (below), never rests an activity, and never blocks progress.
- **C6 — Never inferred:** that a stage was done; for how long; any change in energy, focus, mood or calm; that a stage "worked".
- **C7 — A review may state** only the stage title, the date it was guided, its parts, the answer or "no answer", skipped parts, or "set aside" and why.
- **C8 — Distinct from ordinary composition.** A brief fixes the stage's facet; stage 5 fixes a combination. On a stage day the stage line replaces the basis line on the Today card.

Only content that is live and safe today is used. A brief never relaxes a safety gate, and no gated or retired content may enter one.

### Runtime semantics (frozen; never merged with one another)

- **Start:** the user explicitly starts a Plan (Premium). **One Plan is active at a time;** starting another pauses the current one at its place. Each Plan keeps its own place, cycle history and reviews.
- **Today match:** on a Premium day whose chosen need is the active Plan's need, the current stage — or a pending revisit — steers today's Personal Guided Circle (C1–C3). The user's own "Use it today" choice takes precedence, and the stage is not advanced.
- **Different need:** ordinary composition. The Plan waits — no debt, no nudge, no badge.
- **GUIDED:** a stage Circle was **started and later closed in THIRTY**. It does **not** mean the activity was done in the real world. The Plan's place moves on once, idempotently, per Circle. Copy says "guided", never "done" or "completed".
- **WAIT:** the stage stays at its place because of a temporary composition constraint that is *not* one of the user's lasting exclusions — time, yesterday's main piece, today's Not-this-one constraint, or safety. That day is an ordinary Personal Guided Circle.
- **SET ASIDE:** the stage can't currently pass *because of the user's own controls* (Leave it out, Don't suggest, or a rest from the user's own Not-useful answer), although it would otherwise pass.
  - The Plan moves past it **for this cycle only**, and the stage is recorded as **set aside** — never guided or completed.
  - The next stage is tried the same day; if none composes, the day is an ordinary Personal Guided Circle.
  - The review names the stage and the reason.
  - THIRTY never overrides the exclusion. The user may reverse it in Memory and then ask to try the stage once ("Try this stage").
  - A later cycle checks again from scratch.
  - A Plan can never stall indefinitely on content the user deliberately excluded.
- **Revisit:** "This stage again next time" — at most once per stage per cycle. A pending revisit is served on the next matching day **without moving the Plan's place**, which is kept separately.
- **NOT USEFUL ON A COMPOSED OR STAGE CIRCLE:** negative ranking evidence only (−2 at half weight for that Circle's main and second piece, this need only). **No activity rest.** The Plan still moves on; that stage is excluded from stage 5 this cycle; the review shows it.
- **NOT USEFUL ON A SINGLE-ACTIVITY CIRCLE** (Free Today, or a Premium day that fell back to Free's activity): the existing Engine V2 rule — a 14-day rest of that activity for that need, liftable with Suggest again. The composer then excludes that activity's elements while the rest lasts, which can set a stage aside.
- **Pause:**
  - stage steering stops at once;
  - the place, any pending revisit, the cycle's records and set-asides are kept exactly;
  - matching days are ordinary Personal Guided Circles;
  - nothing is marked missed, and no prompt is sent;
  - "Carry on" resumes on the next matching day at the same stage.
- **Leave:** ends the cycle. Its Circles stay in History. A review is produced if at least 3 stages were guided. Starting again begins at stage 1.
- **Return:** a paused Plan resumes at its place; a Plan that was left starts a new cycle.
- **End:** when stage 5 is guided or set aside — or at case D below — the Plan review (Insight 5) offers:
  - Keep one of these Circles (works on Free);
  - Go through it again;
  - Choose another Plan;
  - That's enough for now.

  A finished cycle reads "This Plan has reached its end: 4 stages guided, 1 set aside", never "completed".
- **Repeat cycle:** the same authored stages, composed afresh from the evidence and recency so far. Stage 5 draws only on eligible stages from this cycle (see Stage 5 below), never directly on earlier cycles; a new cycle evaluates every stage afresh, so set-aside stages are tried again; the composer's ordinary ranking still uses all past evidence; and the review compares cycles. *(Founder decision 2026-10-17: Stage-5 eligibility is current-cycle only.)* No new authored content is required.
- **Lapse:** the place, cycles and reviews are saved and readable. Steering, progression and new reviews stop. Resubscribing resumes at the saved place.

### Stage 5 — the four feedback cases (frozen)

Stage 5 classifies each earlier stage of this cycle as positive (Very or Somewhat useful), negative (Not useful), unanswered, or set aside. **Negative and set-aside stages are never used.**

- **A — no answers.** The Circle must satisfy at least two earlier briefs at once (falling back to at least one). Line: "A mix of this Plan's earlier stages." It never implies that THIRTY learned anything, that these are favourites, or that anything improved.
- **B — one positive stage.** A mix led by that stage together with another earlier stage the user didn't reject; failing that, that stage alone as a deliberate return. Line: "Built around <stage>, which you said was useful."
- **C — several positive stages.** The two most positive together (Very before Somewhat; ties on the date-seeded hash); failing that, the next pair; failing that, the single most positive stage. Line: "The stages you said were useful, together."
- **D — only Not-useful answers.** If some stages are unanswered, case A over those only. If **every** earlier stage was explicitly rejected, **no** last Circle is made, and the Plan ends at its review: "You said none of these stages was useful, so THIRTY hasn't made a last Circle from them."

No personalisation is fabricated, and no rejected stage is ever forced into stage 5.

### Feasibility and known risk

- **Feasibility:** in the clean model — the full live, safe library with no user controls — **all 45 stage × time cells pass** (15 StageBriefs × ≈10 / ≈20 / up to 30). The Plans do not stall.
- **Known commercial and content risk:** **More Energy at ≈10 is relatively thin.** A user who mostly chooses More Energy at ≈10 meets 19 materially distinct sessions and 6 main pieces in the whole product, and stage forms repeat from about the third cycle. This is **not** a D2 architecture blocker. It is recorded as a known risk.
- Widening More Energy honestly depends on the separate safety review (see [Safety gate](#safety-gate)), never on weakening a gate.

## Kept Circles and Yours *(amended 2026-10-17)*

**Kept Circles are the only reusable owned object.** Paths, routines, tune-ups and shorter routine versions are retired before public release; there is no second owned type.

- **Keeping:** "Keep this Circle" after Close; Keep in a Plan review; and Keep from Insight 4. Keep is **never gated**.
- **Limits:** at most 8.
- **The object:** fixed parts at their authored lengths. A kept Circle never changes — it is never tuned, versioned or shortened.
- **Using it:** "Use it today", before today's Circle starts. It is still one Circle a day, runs at its own length as the user's choice, and is never offered unasked.
- **Ownership controls:** rename and remove.
- **Voice:** voiced while Premium is active; on screen and paced, with full TalkBack support, on Free.
- **Persistence:** exported; survives a lapse and Delete Circle history.
- **Yours:** one row under You › Personal, leading to the list of kept Circles. It has no maintenance offers, checks or "build" actions, and it is **not** a tab.
- **Retirement of legacy objects:** the Toolkit tab and Toolkit maintenance are retired. Routines and Paths that exist on development or test devices are removed by an explicit pre-release migration (ADR-024). Their journal records stay readable. No public installs exist.

## Maintenance contract — *retired 2026-10-17*

The Phase D maintenance loop (fading, time misfit, toolkit gap, user refresh, Toolkit check) is retired with routines.

- Daily time fit is the composer's job.
- Evidence-aware, user-approved adjustments are now [Insights](#insights-contract-amended-2026-10-17).
- The principle carries over: **every adjustment is offered, never silently applied.**

## Stable-user contract

- When nothing needs changing, THIRTY **says so** — including an Insight's explicit "Nothing to change".
- It never manufactures work, degrades owned Circles or invents content cadence to justify billing.

---

## Coach

**RETIRED as a separate pillar** (unchanged). Its legitimate jobs live in the recommendation engine, Circle guidance, the feedback acknowledgement, Plan stage lines and Plan resumption *(amended 2026-10-17; formerly "Path progression and toolkit maintenance")*. No generic coach or chat.

## Insights contract *(amended 2026-10-17)*

*The 2026-10-08 retirement of Insights as a pillar and tab is superseded.* V1's count-based Insights remain retired.

**Job:** "What does my actual use show, and is there one useful change I can approve?"

**Every real Insight has:**
- an **observation** about facts only — what the user chose, what appeared in their Circles, what they skipped, rated or left out, Plan place and state, dates and counts;
- its **evidence**, with every denominator shown;
- **truthful co-occurrence wording**, never causal;
- an **application** the user may approve, or an explicit **"Nothing to change"**.

There are no decorative counting-only cards, no scores, no charts as an end in themselves, and no dashboard.

**Never inferred:** mood, diagnosis, stress, mental-health state, recovery, physical ability, causal benefit, or that an activity was performed because Close was tapped.

**Six families (frozen; gates, wording and applications in ADR-024):**

| # | Family | Application |
|---|---|---|
| I1 | The Plan for your need | Start / carry on with / go through that Plan again |
| I2 | Gentler Plan Circles | "Keep this Plan's Circles gentler for now" |
| I3 | A part you skip | Leave it out next time |
| I4 | What your useful Circles shared | Keep that Circle, or "Nothing to change" |
| I5 | The Plan review | Keep one of these Circles · go again · another Plan · stop |
| I6 | What's changed | The Plan for the recent need, or "Nothing to change" |

- **Pattern gate:** at least 5 relevant records on at least 3 dates spanning at least 14 days, within the family's window. Usefulness claims need explicit answers, with the denominator shown.
- **Cadence:** a Plan review appears at once. Otherwise at most one new Insight per 7 days, assessed when the Insights tab is opened. Nothing is pushed.
  - *(Founder decision 2026-10-18, from the B5 simulation.)* The same claim — the same family and subject (I1–I4, I6) — is shown at most once in any 28 days, counted from when it was shown, whatever the user did and whatever new evidence arrived. Priority applies only among eligible claims.
  - "Not now" also hides that evidence set for 28 days.
  - The Plan review (I5) stays immediate and separate.
  - There is no novelty quota: silence is valid.
- **Snapshots:** at most 52; readable after a lapse; deleted by Delete Circle history. Each Plan review is shown once: the cap never brings back a review it dropped *(B8 correction, 2026-10-20)*.
- **Free/Premium:** generating Insights and applying them is Premium. The underlying facts are always visible to everyone in History.

### Maturity states

The Insights tab never manufactures an Insight to fill the screen.

- **Day 1:** an empty calendar. A plain statement that THIRTY says nothing about patterns until the user's Circles span two weeks.
- **Week 1:** the calendar, the active Plan's place, and a status line (counts of Circles and answers — not an Insight).
- **Week 3 onward:** pattern families become possible.
- **Month 2 onward:** longer-window and cross-cycle Insights. I6 is possible from about Month 3.
- A **genuine** Plan review may appear as soon as a cycle ends.

## History and calendar contract *(amended 2026-10-17)*

History is **Free and shared**, and never Premium-gated. The calendar sits visually inside Insights and reads the same journal (no second store).

- **Closed:** a calm ring around the date. It means "Closed in THIRTY" — an app interaction only.
- **Recorded, not closed:** a small neutral dot. Never the ring, never the primary colour.
- **No record:** plain and not interactive. Empty dates are neutral.
- **Selected date:** tapping a recorded date opens that date's read-only record detail (`/history/:date`).
- **List alternative:** "See as a list" opens the full History list. On a narrow screen, the month's recorded dates are listed as rows at least 48 pt tall.
- **Spoken labels:** "<date>, Circle closed" / "Circle recorded, not closed" / "no Circle recorded". Targets are at least 48 pt and follow the user's text size.
- **Never:** a streak chain, emphasis on consecutive days, red or missed dates, a completion percentage, a failure state, a Plan mark, or any implied real-world activity or verified duration.

This restores the founder's calendar decision of 2026-10-02 (Scope Delta PD-04).

## Navigation contract *(amended 2026-10-17)*

**Today | Plans | Insights | You.** It supersedes Today | Toolkit | You (Phase D).

| Tab | Job | Free | Premium | Lapsed |
|---|---|---|---|---|
| **Today** | Today's one Circle | One activity | Composed and voiced Circle; stage-steered on a match | Free Today and "Use it today" |
| **Plans** | Direction over several Circles | The three Plans, readable | Run, pause, revisit, leave, review | Saved place; readable reviews |
| **Insights** | My own record, and one useful change | Calendar, list, record detail | One current Insight; earlier Insights | Calendar; earlier Insights readable |
| **You** | Personal control | Everything listed below | Plus spoken guidance and voice | Choices kept |

**You:**
- **Personal:** first name · What THIRTY remembers (with Reset suggestion preferences) · **Yours** (one row)
- **Preferences:** reminder · appearance · spoken guidance (Premium) · voice (four names, with "Hear <name>")
- **Premium:** status · manage · restore
- **Data & privacy:** analytics consent · export · Delete Circle history *(founder decision 2026-10-20, B7: Reset suggestion preferences lives in What THIRTY remembers, beside what it resets; analytics consent is a privacy control)*

A Free user opening Plans or Insights sees a calm, truthful preview and may choose to open the offer. A tab never auto-opens the purchase page.

## Worlds

**Protected.** Worlds may support emotional context, mode identity, session atmosphere, the completion moment, Plan continuity *(amended 2026-10-17; formerly "Path continuity")*, and later Premium atmosphere. **No** gamification, collectibles, streak rewards, virtual pets or unlock grind. The existing art and the B1.1 identity are protected.

## Explicit exclusions

- Runtime generative AI.
- ML personalisation.
- A cloud personal profile.
- An account requirement.
- Streaks, badges or points.
- A feed, social features or community.
- A browsable catalogue.
- A virtual pet or unlock grind.
- "AI" product positioning.

## Protected infrastructure

Evolve; do not rebuild unless a V2 dependency requires a small adaptation:
- app shell and routing (extend only);
- first-name flow;
- reminders (native scheduler);
- Android B1.1 identity;
- entitlement plumbing and RevenueCat integration;
- opt-in Supabase analytics architecture;
- release hardening and the billing guard;
- local-first persistence;
- Delete semantics and the export mechanism;
- World artwork and the scene system;
- accessibility principles;
- the QA harness architecture;
- the journal foundation.

## Superseded V1 assumptions

- Every Circle lasts a fixed 30:00.
- Three isolated activity pools of seven.
- Day-index rotation as recommendation.
- Usefulness feedback not affecting selection.
- Activity guidance mostly hidden.
- The Circle as a generic timer.
- V1's five-stage Plans of fixed 30-minute activities, and the authored stage-4 repeat. *(Clarified 2026-10-17: V2 Circle Plans — StageBriefs over the composer, with evidence-led repeat cycles — are a different design and are current.)*
- Coach as a Premium pillar.
- Click-count Insights, and V1's Insights tied to V1 Plan state. *(Clarified 2026-10-17: evidence-aware, actionable V2 Insights and their tab are current.)*
- *(Added 2026-10-17.)* Paths, routines, tune-ups, shorter routine versions, Toolkit maintenance and the Toolkit tab (Phase D) — retired before public release.
- The current V1 Premium being subscription-worthy.
- Learning and intelligence placed in Premium.
- "AI Health Companion" positioning.

---

## Frozen vs tunable vs commercial hypotheses

### Frozen product rules

Everything above marked FROZEN, and every contract section not explicitly marked tunable. That includes:
- the job and progression;
- one Circle per day;
- needs plus an explicit time input;
- multi-direction fit;
- the engine principles;
- feedback that matters, with no inferred permanent bans;
- one-replacement recourse;
- natural duration up to about 30 minutes;
- the three modes and their content standards;
- Close ≠ completion;
- the memory page;
- historical-learning compatibility;
- Delete and export scope;
- *(amended 2026-10-17)* Premium as four continuing paid jobs (Today, Direction, Understanding, Guidance), never confiscation;
- *(amended 2026-10-17)* kept Circles as the only reusable owned object, surviving cancellation;
- *(amended 2026-10-17)* every adjustment offered, never silently applied, and stable-user honesty;
- *(amended 2026-10-17)* Today | Plans | Insights | You; three launch Plans with five StageBriefs each; the six Insight families; the Plan semantics (guided, wait, set aside, the two Not-useful rules) and the Stage-5 cases;
- Coach retired;
- Worlds protected;
- the exclusions;
- the safety gate.

### Tunable implementation hypotheses
- Fit placements, minutes and effort/setting attributes.
- Every engine parameter.
- Time buckets (≈ 10 / ≈ 20 / up to 30).
- *(amended 2026-10-17)* Composer values; the element-kind sets inside StageBriefs where a feasibility test proves no stage worsens; Insight thresholds and cadence; the kept-Circle limit (8).
- All copy beyond the founder-approved launch copy recorded in ADR-024.
- The optional activity additions.

### Commercial hypotheses — NOT frozen
- Price.
- Trial.
- Monthly vs annual cadence; monthly-with-natural-pauses plus annual is the working hypothesis.
- Pause economics.
- Conversion.
- Retention (D1/D7/D30, Month-2 paid).
- Willingness to pay.
- LTV.
- Launch strategy. The working plan is a closed test of V2, then a public launch with Free + Premium V2.

*(Added 2026-10-17.)* THIRTY is designed as a **recurring-revenue product for KEYBRACE**. Its four paid jobs (Today, Direction, Understanding, Guidance) are structural design decisions, not evidence of demand. Willingness to pay, conversion, retention, price and cadence remain unproven, and are left to real-user validation.

Recurring Premium is approved as a **product direction**; its exact billing model is a hypothesis. Existing RevenueCat infrastructure remains, and no new monetisation structure is coded before Phase E.

---

## Implementation sequence

| Phase | Name | Outcome |
|---|---|---|
| **A** | Activities that feel designed | Activity model V2, content to standard, natural duration, safety gating, learning-compatibility classification, how-to surfaced in the existing Circle |
| **B** | Engine V2 and memory | Feedback-driven deterministic engine, time input, replacement, reasons, Delete/Export updates; a 40-day deterministic simulation |
| **C** | Circle experience and memory | Open / Guided / Paced, completion moment, inline feedback, memory page, humane history. Closed-test readiness for Free V2 |
| **D** | Premium V2 | Paths, routines, toolkit, maintenance; V1 Plans/Coach/Insights retired and migrated *(historical; Phase D's Premium was superseded by D2 and its Paths/routines/Toolkit retired by Amendment 2)* |
| **D2** | Recurring Premium | Personal Guided Circle and spoken guidance (ADR-023); Circle Plans, Insights, the four-tab IA and the Path/routine removal (ADR-024) |
| **E** | Measurement and release | MEASUREMENT-1 on the V2 funnel; privacy, support, Data Safety, live billing, store, slogan |

Order: Free core value → Premium value → measurement and release. Status and acceptance details live in [THIRTY_V2_DELIVERY_TRACKER.md](THIRTY_V2_DELIVERY_TRACKER.md).

## Public launch rule

- **No public V1 launch.** The V1 Premium is not acceptable as the paid product.
- Public launch stays **paused** until the V2 release gate in the delivery tracker is satisfied.

## Authority

1. **This contract** — *what* we build.
2. [BRAND_BOOK.md](../BRAND_BOOK.md), [DESIGN_SYSTEM.md](../DESIGN_SYSTEM.md), [WORLD_SYSTEM.md](../worlds/WORLD_SYSTEM.md) — *how* approved behaviour looks and feels, except where still awaiting their scheduled V2 update; where they conflict with this contract, this contract wins.
3. **V2 ADRs** (`adr/`, from ADR-019 onward) — *how* individual implementation decisions are realised.
4. [THIRTY_V2_DELIVERY_TRACKER.md](THIRTY_V2_DELIVERY_TRACKER.md) — *status* only.
5. **Historical / superseded documents** — context only, including V1 strategy, freezes, ADR-001/012–016 where noted, and the V1 roadmap.
