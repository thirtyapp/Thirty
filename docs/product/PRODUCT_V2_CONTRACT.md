# THIRTY PRODUCT V2 CONTRACT

## Status

**FROZEN FOR IMPLEMENTATION** — founder-approved 2026-10-08.

- The **product architecture** in this document is frozen. Changing it requires an explicit founder decision.
- Values marked **TUNABLE** are implementation hypotheses. They may change on device or simulation evidence without reopening this contract.
- **Commercial terms** (price, trial, billing cadence) are **not** frozen. See [Commercial hypotheses](#commercial-hypotheses--not-frozen).
- Delivery status lives in [THIRTY_V2_DELIVERY_TRACKER.md](THIRTY_V2_DELIVERY_TRACKER.md), not here.

Where any older THIRTY document conflicts with this contract, **this contract is authoritative** (see [Authority](#authority)).

---

## Product job

> **"Help me decide what could help me feel better today."**

## Product progression

| When | What the user should feel |
|---|---|
| **Day 1** | THIRTY chooses something sensible. |
| **Day 7** | THIRTY remembered. |
| **Day 30** | THIRTY understands what tends to suit me. |
| **Premium** | THIRTY helps me build and maintain a small personal toolkit of routines that work for me. |

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

## Premium V2 contract

Premium sells a **process**, not access to the user's data or routines:

**Paths → routines → Personal Toolkit → maintenance.**

- **Paths** are bounded, adaptive, progressive and seeded from the user's own evidence. Each ends by producing a routine.
- **Toolkit:** a small set of user-owned routines.
- **Maintenance:** evidence-triggered offers to tune, version or build, and an honest "nothing needs changing".
- Routines remain usable in Free after Premium ends.

## Free / Premium boundary

| FREE owns | PREMIUM owns | USER always owns |
|---|---|---|
| Recommendation intelligence | Building routines (Paths) | History |
| Feedback learning | Progressing Paths | Explicit feedback |
| Time fit | Tune-ups | Memory controls / corrections |
| Reasons | Versions (shorter / longer / variant) | Routines already created, and their versions |
| Circle guidance (all modes) | Toolkit maintenance | Export and delete control |
| Memory page | Actionable cross-context review | |
| Use of already-created routines | | |

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
- Path, step and routine context;
- routine definitions;
- the user's explicit memory corrections.

**Derived** (computed, never cached as a profile): evidence scores, rests, recency, family carry-over, reason eligibility, memory-page observations and maintenance triggers.

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
- does **not** automatically delete user-created routines or explicit memory corrections and preferences, which have their own clear delete/reset controls.

The confirmation copy must state this truthfully. No residue from deleted journal evidence may keep influencing recommendations.

**Export** includes the journal (including the new V2 fields), routines and explicit corrections.

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

## Path contract

- Bounded, deliberate, progressive and adaptive.
- Built from existing session modules plus the user's explicit evidence, and seeded from Free history.
- Counted in completed Circles, **not** calendar days. Missed days pause a Path; they never create failure.
- Each step uses the last explicit answer to advance, hold and vary, switch, or repeat lighter, and states its reason.
- Paths are designed to **end**. Each ends with a review and produces something lasting, typically a **user-owned routine**.
- If an active Path's need matches today's chosen need, today's Circle is the Path step, sized to the time window. *Not this one today* falls back to the normal engine; the Path waits.
- **Path length is TUNABLE.** The starting hypothesis is 7 Circles.
- Paths must not be fixed reorderings of Free activities, endless loops, a content treadmill, fake personalisation, or a requirement to open THIRTY daily.

## Personal Toolkit contract

- A small set of **user-owned routines**. Each routine has session modules, a natural duration, need fit, a level or treatment, and variants.
- Local, exportable, deletable, renamable and disableable by the user.
- Routines are recommendation candidates in Free for the needs and times they fit.
- **Routines remain usable after Premium ends.** Premium never holds data or routines hostage.

## Maintenance contract

```
BUILD → USE → OBSERVE (explicit feedback) → DETECT (change / gap / misfit) → OFFER → TUNE / VERSION / BUILD → USE AGAIN
```

- Triggers are deterministic and based only on explicit evidence. Core triggers:
  - **fading usefulness** of a previously positive routine;
  - **time misfit** between recent time windows and a routine's length;
  - **toolkit gap** — a need chosen often without a fitting routine;
  - a **user-requested refresh**.
- Thresholds are **TUNABLE**. Below the minimum evidence, THIRTY makes no claim and says it is still learning.
- **Every maintenance action is offered, never silently applied.**
- New Paths are **not** the primary retention engine.

## Stable-user contract

- When nothing needs changing, THIRTY **says so**.
- It never manufactures work, degrades routines or invents content cadence to justify billing.

---

## Coach

**RETIRED as a separate pillar.** Its legitimate jobs live in the recommendation engine, Circle guidance, the feedback acknowledgement, Path progression and toolkit maintenance.

## Insights

**RETIRED as a separate pillar and tab.** Count-based insights are retired.

Useful insight jobs move:
- in **Free**, into the memory page and recommendation reasons;
- in **Premium**, into Path and toolkit review and maintenance offers.

An insight must **reveal** something non-trivial **and change** a useful future decision.

## Worlds

**Protected.** Worlds may support emotional context, mode identity, session atmosphere, the completion moment, Path continuity, and later Premium atmosphere. **No** gamification, collectibles, streak rewards, virtual pets or unlock grind. The existing art and the B1.1 identity are protected.

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
- Five-stage Plans, the stage-4 repeat, and repeat cycles.
- Coach as a Premium pillar.
- Insights as a Premium pillar or tab; click-count insights.
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
- Premium as toolkit process;
- routines survive cancellation;
- maintenance by offer, and stable-user honesty;
- Coach and Insights retired;
- Worlds protected;
- the exclusions;
- the safety gate.

### Tunable implementation hypotheses
- Fit placements, minutes and effort/setting attributes.
- Every engine parameter.
- Time buckets (≈ 10 / ≈ 20 / up to 30).
- Path length (7 Circles) and the number of levels.
- The module set.
- Maintenance thresholds and toolkit-check cadence.
- All copy.
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

Recurring Premium is approved as a **product direction**; its exact billing model is a hypothesis. Existing RevenueCat infrastructure remains, and no new monetisation structure is coded before Phase E.

---

## Implementation sequence

| Phase | Name | Outcome |
|---|---|---|
| **A** | Activities that feel designed | Activity model V2, content to standard, natural duration, safety gating, learning-compatibility classification, how-to surfaced in the existing Circle |
| **B** | Engine V2 and memory | Feedback-driven deterministic engine, time input, replacement, reasons, Delete/Export updates; a 40-day deterministic simulation |
| **C** | Circle experience and memory | Open / Guided / Paced, completion moment, inline feedback, memory page, humane history. Closed-test readiness for Free V2 |
| **D** | Premium V2 | Paths, routines, toolkit, maintenance; V1 Plans/Coach/Insights retired and migrated |
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
