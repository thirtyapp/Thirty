# ADR-024 — V2 Circle Plans, Insights and the four-tab product

**Status:** Accepted — in the D2 closure commit (2026-10-21).

- **Founder approval of the design:** 2026-10-17 — the product contract, the content freeze and the launch copy.
- **Implementation:** B1–B9 complete (2026-10-17 to 2026-10-21, §14); founder approval of the B9 closure 2026-10-21.
- **Acceptance:** accepted only together with the D2 closure — done in the D2 closure commit (2026-10-21).

**Product authority:** [PRODUCT_V2_CONTRACT.md](../PRODUCT_V2_CONTRACT.md), Amendment 2 (2026-10-17).

**Design source:** *THIRTY — Final pre-implementation contract repair* (2026-10-17). This ADR records that design in full and does not reinterpret it.

**Supersedes:**
- the Paths, routines, Toolkit and maintenance portions of [ADR-022](ADR-022-v2-phase-d-paths-toolkit-and-maintenance.md);
- [ADR-023](ADR-023-v2-recurring-premium-personal-guided-circle.md) §4 items 1–2, the routine parts of §8, §9, the routine and Toolkit fixes of §10, §11's routine line, and §12's routine scenarios.

**Unchanged from ADR-023:** the Personal Guided Circle, the element library, the composer, the guided composed runtime, spoken guidance with background playback, and the entitlement gate.

## Context

D2 made monthly Premium's daily job real: the Personal Guided Circle, plus THIRTY's spoken guidance. A product and commercial reconciliation on 2026-10-17 found D2 still **too reduced** to carry a recurring subscription.

**Evidence (internal simulations, not user evidence):**
- Distinct main pieces plateau at 13–18 by Day 30.
- Materially distinct sessions plateau by about Month 6 for engaged users.
- Eight kept Circles covered 40 of 60 lapsed days in the lapse attack (`artifacts/v2_phase_d2/SIMULATION_REVIEW.md`).

**What was missing:** two kinds of continuing value that can't be stockpiled:
- **direction** over several Circles;
- **understanding** of the user's own record.

**A coherence defect in the build:**
- a Path step pre-empted the composed Circle and ran on the unvoiced Phase D runtime;
- routines and kept Circles were two near-identical owned objects on different runtimes.

**The founder's decision:** Circle Plans and Insights must remain real product capabilities. They are **not** restored as V1 code or content. The V1 history is evidence only.

## Decisions

### 1. Commercial frame

THIRTY is designed as a **recurring-revenue product for KEYBRACE**. Premium has four paid jobs, all continuing software work:

| Job | What THIRTY does |
|---|---|
| **Today** | Composes a new Personal Guided Circle. |
| **Direction** | Operates a Circle Plan across several matching Circles. |
| **Understanding** | Computes new evidence-aware Insights, each with an application the user may approve. |
| **Guidance** | Speaks the Circle in THIRTY's voice, including background playback. |

- The recurring model never depends on confiscating owned content.
- Eight kept Circles are eight fixed sessions. They can't compose, speak, operate a Plan or produce Insights.
- Willingness to pay, conversion, retention, price and cadence are **unproven**.

### 2. Information architecture: Today | Plans | Insights | You

This replaces Today | Toolkit | You. It is the founder-approved IA of 2026-09-09 (Scope Delta PD-10), now with a working engine behind every tab.

| Tab | Job | Free | Premium | Lapsed | Primary action |
|---|---|---|---|---|---|
| Today | Today's one Circle | One activity | Composed and voiced Circle; stage-steered on a match | Free Today and Use it today | Start Circle |
| Plans | Direction over several Circles | The three Plans, readable | Run, pause, revisit, leave, review | Saved place; readable reviews | Start / Carry on |
| Insights | My own record, and one useful change | Calendar, list, record detail | One current Insight; earlier Insights | Calendar; earlier Insights readable | Open a date / Apply |
| You | Personal control | Everything below | Plus spoken guidance and voice | Choices kept | — |

**You:**
- **Personal:** first name · What THIRTY remembers (with Reset suggestion preferences) · **Yours** (one row → the kept Circles)
- **Preferences:** reminder · appearance · spoken guidance (Premium) · voice (four names, "Hear <name>")
- **Premium:** status · manage · restore
- **Data & privacy:** analytics consent · export · Delete Circle history *(founder decision 2026-10-20, B7: Reset suggestion preferences lives in What THIRTY remembers, beside what it resets; analytics consent is a privacy control)*

**Rules:**
- A Free user opening Plans or Insights sees a calm, truthful preview, and may choose to open the offer. A tab never auto-opens the purchase page.
- "Yours" is one row, not a tab. It holds no maintenance, checks or "build" actions.

### 3. Kept Circles: the only reusable owned object; Paths and routines removed

| Item | Final status |
|---|---|
| New Path starts | None. The entry points and the Path engine are removed. |
| Path in progress | Ended by the pre-release migration. Its Circles stay in History as recorded; no routine is created. |
| New routine creation | None. |
| Existing routines | Removed by an explicit pre-release migration. They exist only on development and test devices; no public installs exist. Journal records that name a routine stay readable, because each record stores its own title and parts. |
| Tune-ups | Retired. |
| Shorter routine versions | Retired. Daily time fit is the composer's job. |
| Toolkit tab, maintenance, Toolkit check | Retired. |
| **Kept Circles** | The only reusable owned object (below). |
| **Yours** | One row under You › Personal, leading to the kept Circles. |

**Kept Circles:**
- **Keeping:** "Keep this Circle" after Close, Keep in a Plan review, or Keep from Insight 4. Keep is never gated.
- **Limit:** at most 8. At the limit: "You have 8 kept Circles. Remove one in Yours to keep another."
- **The object:** fixed parts at their authored lengths. It is never tuned, versioned or shortened.
- **Using it:** "Use it today", before today's Circle starts. It is still one Circle a day, runs at its own length as the user's choice, and is never offered unasked.
- **Ownership:** rename and remove.
- **Voice:** voiced on Premium; on screen and paced, with full TalkBack, on Free.
- **Persistence:** exported; survives a lapse and Delete Circle history.
- **Migration:** existing kept Circles migrate in place under their current storage key.

### 4. Circle Plans: the three launch Plans (founder-approved launch copy)

#### Getting going — More Energy

- **Purpose:** "A few Circles that try different ways of getting moving, at home and outside, and end with a mix of what suited you."
- **Card:** "From a stretch at home to time outside, in five Circles."

| # | Role | Stage | Today line |
|---|---|---|---|
| 1 | Begin | Loosen up | "Start small: a stretch at home." |
| 2 | Develop | On your feet | "One part that keeps you on your feet for a while." |
| 3 | Apply | Two together | "Two kinds of moving, one after the other." |
| 4 | Apply in a new setting | Fresh air | "Take it outside: a walk, or air at an open door." |
| 5 | Consolidate | Your mix | stage-5 line (§7) |

#### Making room — Clearer Head

- **Purpose:** "A few Circles that make a little room — on paper, around you and in what comes in — and end with a mix of what suited you."
- **Card:** "Paper, then a space, then one thing — in five Circles."

| # | Role | Stage | Today line |
|---|---|---|---|
| 1 | Begin | Out of your head | "Everything on your mind onto paper. No sorting yet." |
| 2 | Develop | Room around you | "Clear one space around you." |
| 3 | Apply | Down to one | "Narrow it down to one thing." |
| 4 | Protect | Less coming in | "Screens down, and just one thing coming in." |
| 5 | Consolidate | Your way | stage-5 line (§7) |

#### Slowing down — Gentler Pace

- **Purpose:** "A few unhurried Circles — something in your hands, an easy stretch, something quiet, a slower place — that end with a mix of what suited you."
- **Card:** "Hands, body, quiet, then a slower place — in five Circles."

| # | Role | Stage | Today line |
|---|---|---|---|
| 1 | Begin | Slow hands | "Something warm, or one small thing to look after." |
| 2 | Develop | Ease the body | "An easy stretch, only as far as is comfortable." |
| 3 | Apply | Something quiet | "One quiet thing to listen to or read." |
| 4 | Apply in a new setting | Somewhere slower | "Somewhere slower: outside, or by an open door." |
| 5 | Consolidate | Your pace | stage-5 line (§7) |

**Stage-5 lines:**
- "A mix of this Plan's earlier stages."
- "Built around <stage>, which you said was useful."
- "The stages you said were useful, together."

**Plan-page copy** (<Need> is the Plan's need):
- **Ready:** "Five Circles on days you choose <Need>. It waits on other days."
- **Active:** "Stage 2 of 5 · <Stage>. Next time you choose <Need>, your Circle follows this stage."
- **Waiting (other need):** "Waiting for your next <Need> day."
- **Waiting (couldn't fit):** "Today's Circle couldn't follow this stage honestly, so it waits."
- **Set aside:** "Set aside this time: it's built around <part>, which you've asked THIRTY to leave out." (For a rest: "…which is resting after you said it wasn't useful on <date>." For Don't suggest: "…which you asked THIRTY not to suggest.")
- **Paused:** "Paused at stage 3. It stays here until you carry on."
- **Lapsed:** "Saved at stage 3. It carries on with Premium."
- **Finished:** "This Plan has reached its end: 4 stages guided, 1 set aside."
- **Free:** "Plans run with Premium. Each one is five Circles with a direction, on the days you choose its need."
- **Leave (confirm):** "Leave this Plan? Its Circles stay in your history. You can start it again from stage 1."

**Review:**
- **Heading:** "What you told THIRTY"
- **Options:** Keep one of these Circles · Go through it again · Choose another Plan · That's enough for now

**On the Today card:** a stage day shows "<PLAN> · STAGE n OF 5 · <minutes>", and the stage's Today line replaces the composition basis line. The card is no taller.

**Copy rules:** no outcome promise, no therapy language, no streak or achievement framing. No "about half an hour", and no instruction to leave the phone behind, because the phone is the guide.

### 5. StageBriefs: the shared rules (C1–C8)

A StageBrief is a pure condition, applied on top of the existing composer (`ComposerContext`). It holds a main-piece condition and/or a whole-Circle condition, plus an optional *serves up to ≈20* mark.

- **C1 — Composition.**
  - Every hard limit and the quality gate stay unchanged: safety, need fit, Leave it out, Don't suggest, rests, the window, today's constraint, never yesterday's main piece, and the gate.
  - A brief only adds conditions; ranking inside it is unchanged.
- **C2 — Time fit.**
  - A stage composes for today's time choice.
  - A brief marked *serves up to ≈20* (E1, E2) composes at ≈20 size on an up-to-30 day.
  - Nothing is padded, stretched or repeated. More time is never a reason to wait.
- **C3 — Set aside or wait.** If no Circle that fits the brief passes the gate today, THIRTY tests again with the user's own controls ignored — Leave it out, Don't suggest, and rests from the user's own Not-useful answers. Safety, time, yesterday's main piece and today's constraint stay in force.
  - If a Circle would pass → **set aside** (§6).
  - Otherwise → **wait**, and today is the ordinary Personal Guided Circle.
- **C4 — Not this one today.** One replacement a day:
  1. recompose inside the brief under the constraint;
  2. else recompose without the brief under the constraint (the stage waits and isn't guided today);
  3. else Free's one activity.
- **C5 — Feedback.**
  - The stage Circle's answer is recorded against the stage.
  - It counts like any composed Circle's answer: −2/+1/+2 at half weight for the main and second piece, this need only.
  - It never rests an activity and never blocks progress.
- **C6 — Never inferred:** that the stage was done; how long; any change in energy, focus, mood or calm; that a stage "worked".
- **C7 — A review may state** only: the stage title, the date guided, its parts, the answer or "no answer", skipped parts, or "set aside" and why.
- **C8 — Distinct from ordinary composition.** A brief fixes the stage's facet; stage 5 fixes a combination; the stage line replaces the basis line.

**No content gate is ever relaxed.** All 38 elements are live and safe; no gated or retired activity is in the library.

### 6. Plan runtime semantics (frozen; never merged with one another)

- **Start:**
  - explicit, and Premium;
  - one active Plan at a time; starting another pauses the current one at its place;
  - each Plan keeps its own place, cycles and reviews.
- **Today match:** on a Premium day whose need is the active Plan's need, the current stage — or a pending revisit — steers composition.
  - Precedence: Plan stage → Personal Guided Circle → Free's activity.
  - The user's own "Use it today" choice wins, and the stage isn't advanced.
- **Different need:** ordinary composition. The Plan waits — no debt, no nudge.
- **GUIDED:** a stage Circle was **started and later closed in THIRTY**.
  - It does not mean the activity was done in the real world.
  - The place advances once, idempotently per Circle ID.
  - Copy says "guided", never "done" or "completed".
- **WAIT:** the stage stays at its place because of a temporary composition constraint that is not one of the user's lasting exclusions — time, yesterday's main piece, today's Not-this-one constraint, or safety.
- **SET ASIDE:**
  - **Condition:** on a matching day the stage (or a pending revisit) is due, no Circle that fits its brief passes, and one would pass with the user's own controls ignored.
  - **Scope:** this cycle only.
  - **Place:** moves past the stage, which is recorded **set aside** — never guided or completed. A set-aside revisit is cleared, and the place doesn't move.
  - **That day:** the next stage is tried; if none composes, the ordinary Personal Guided Circle. The user always gets a Circle.
  - **Review:** names the stage and the reason.
  - **Later cycle:** checked again from scratch.
  - **Reversal:** the user may reverse the control in Memory (Put it back / Suggest again / allow) and then "Try this stage", using that stage's one revisit. THIRTY never overrides the exclusion.
  - **Edge case:** if stages 1–4 are all set aside, the Plan ends at its review: "Every stage of this Plan uses parts you've left out or asked THIRTY not to suggest."
- **Revisit:** "This stage again next time" — at most once per stage per cycle. A pending revisit is served on the next matching day **without moving the place**.
- **NOT USEFUL ON A COMPOSED OR STAGE CIRCLE:**
  - negative ranking evidence only;
  - **no activity rest**;
  - the place still moves on;
  - the stage is excluded from stage 5 this cycle;
  - it's shown in the review.
- **NOT USEFUL ON A SINGLE-ACTIVITY CIRCLE** (Free Today, or a Premium day that fell back to Free's activity):
  - the existing Engine V2 rule: a 14-day rest of that activity for that need (`restDays`), liftable with Suggest again;
  - while it lasts, the composer excludes elements from that activity;
  - this can set a stage aside.
  - (Verified in `recommendation_engine.dart`: `composite`, `_aboutActivity`, `_daysSinceNotUseful`.)
- **Pause:**
  - steering stops at once;
  - the place, any pending revisit, cycle records and set-asides are kept exactly;
  - matching days are ordinary Personal Guided Circles;
  - nothing is marked missed, and no prompt is sent;
  - "Carry on" resumes on the next matching day at the same stage.
- **Leave:** ends the cycle. Its records stay in History. A review is produced if at least 3 stages were guided. A new start begins at stage 1.
- **Return:** a paused Plan resumes; a Plan that was left starts a new cycle.
- **End:** stage 5 guided or set aside, or case D (§7) → the review (Insight 5).
- **Repeat cycle:**
  - the same authored stages, composed afresh from the evidence and recency so far;
  - stage 5 draws only on eligible stages from this cycle (§7), never directly on earlier cycles; the composer's ordinary ranking still uses all past evidence *(founder decision 2026-10-17)*;
  - set-aside stages are tried again;
  - the review compares cycles;
  - no new authored content is needed.
- **Lapse:** the place, cycles and reviews are preserved and readable. Steering, progression and new reviews stop. Resubscribing resumes at the place.

### 7. Stage 5: the four feedback cases

Each earlier stage of the cycle is classified as positive (Very or Somewhat useful), negative (Not useful), unanswered, or set aside. **Negative and set-aside stages are never used. Nothing is fabricated.**

**A — no answers**
- **Circle:** satisfies at least two earlier briefs at once; falls back to at least one.
- **Line:** "A mix of this Plan's earlier stages."
- **Review:** "You didn't answer after these Circles, so THIRTY can't say which stages suited you." Then each stage with its date.
- **Never:** "THIRTY learned", favourites, or improvement.

**B — one positive stage**
- **Circle:** a mix led by that stage, plus another earlier stage that wasn't rejected; else that stage alone, as a deliberate return.
- **Line:** "Built around <stage>, which you said was useful."
- **Review:** "You said <stage> was useful." Plus "You didn't answer after the others." or "You said <stage> wasn't." as applicable.

**C — several positive stages**
- **Circle:** the two most positive stages together (Very before Somewhat; ties on the composer's date-seeded hash); else the next pair; else the single most positive stage.
  - Some pairs can never be composed together, for example E1 + E2 and G1 + G3.
- **Line:** "The stages you said were useful, together."
- **Review:** "You said these stages were useful: <list>."

**D — only Not-useful answers**
- **If some stages are unanswered:** case A over the unanswered stages only.
- **If every earlier stage was explicitly rejected:** no last Circle is made. The Plan ends at the review: "You said none of these stages was useful, so THIRTY hasn't made a last Circle from them." Options: Choose another Plan · That's enough for now.

**Review options in cases A–C:** Keep one of these Circles · Go through it again · Choose another Plan · That's enough for now.

### 8. The fifteen StageBriefs

The Today lines are in §4. Counts are gate-passing shapes / distinct main pieces / materially distinct sessions at ≈10 · ≈20 · up to 30. Shared rules C1–C8 apply to every stage.

**Getting going (More Energy)**
- **E1 `getting_going.1` — Loosen up**
  - **Must be:** the main piece is Standing stretch or Gentle stretch.
  - **Time:** serves up to ≈20.
  - **Set aside when:** both stretches are blocked by the user's controls.
  - **Not feeling it:** the brief has no other kind of main piece, so C4 step 2 applies.
  - **Counts:** 29/2/6 · 89/2/8 · 89/2/8 at ≈20 size.
- **E2 `getting_going.2` — On your feet**
  - **Must be:** the main piece is Move to music, One active job, Quick clear-up or Clear one corner, with **no second piece that also moves you** (movement, music or tidying).
  - **Time:** serves up to ≈20.
  - **Too much for today:** low-effort parts, so Clear one corner.
  - **Counts:** 138/4/11 · 155/4/12 · 155/4/12 at ≈20 size.
- **E3 `getting_going.3` — Two together**
  - **Must be:** a second piece of a moving kind different from the main piece's kind. The main can be any More Energy main, walks included.
  - **Counts:** 31/5/9 · 409/9/25 · 173/7/15.
- **E4 `getting_going.4` — Fresh air**
  - **Must be:** a walking main piece (A brisk walk, Round the block, Screen-free walk), or "Some fresh air" as the second piece.
  - **At ≈10:** only the open-door form exists (an indoor main, then "Some fresh air"), because no walk fits 10 minutes with another part.
  - **Can't go outside:** "Some fresh air" stays eligible; its library setting is indoor.
  - **Set aside when:** at ≈10, "Some fresh air" is left out.
  - **Counts:** 24/4/4 · 202/9/21 · 66/4/11.
- **E5 `getting_going.5` — Your mix**
  - **Must be:** as §7.
  - **Case A counts:** 27/4/7 · 238/9/24 · 31/3/7.

**Making room (Clearer Head)**
- **H1 `making_room.1` — Out of your head**
  - **Must be:** Get it out as the main or second piece. Choose one thing and Write the first step are **excluded** (narrowing is H3's job).
  - **Set aside when:** Get it out is blocked. There is no "Name what's on" substitute.
  - **Counts:** 206/8/14 · 1,719/15/59 · 656/11/40.
- **H2 `making_room.2` — Room around you**
  - **Must be:** Clear one corner, Quick clear-up or Tend to one thing as the main or second piece.
  - **Counts:** 357/4/26 · 3,583/11/114 · 1,911/8/72.
- **H3 `making_room.3` — Down to one**
  - **Must be:** Choose one thing is present (directly after Get it out, optionally followed by Write the first step), **or** the main piece is One task, no switching.
  - **At ≈10:** the writing chain only.
  - **Set aside at ≈10 when:** Get it out or Choose one thing is blocked.
  - **Counts:** 49/6/8 · 1,315/14/66 · 2,053/9/58.
- **H4 `making_room.4` — Less coming in**
  - **Must be:** an arrival of Phone face down or Set screens aside, followed by Listen to one thing, Read a few pages, Quiet music or Sit outside; **or** a Screen-free walk as the main piece.
  - **Counts:** 47/4/11 · 1,462/5/101 · 1,338/5/91.
- **H5 `making_room.5` — Your way**
  - **Must be:** as §7.
  - **Case A counts:** 28/4/7 · 1,360/10/69 · 1,229/8/56.

**Slowing down (Gentler Pace)**
- **G1 `slowing_down.1` — Slow hands**
  - **Must be:** the main piece is A slow warm drink or Tend to one thing.
  - **At ≈10:** Tend to one thing only. It can wait one matching day if yesterday's main piece was Tend to one thing.
  - **Counts:** 57/1/6 · 348/2/47 · 166/2/28.
- **G2 `slowing_down.2` — Ease the body**
  - **Must be:** Gentle stretch as the main or second piece, or Neck and shoulders as the arrival or second piece.
  - **Set aside when:** that activity is resting.
  - **Counts:** 104/7/14 · 887/11/112 · 648/10/89.
- **G3 `slowing_down.3` — Something quiet**
  - **Must be:** the main piece is Quiet music, Listen to one thing or Read a few pages.
  - **Counts:** 106/3/15 · 1,184/3/74 · 625/3/59.
- **G4 `slowing_down.4` — Somewhere slower**
  - **Must be:** the main piece is Easy walk, Sit outside or Round the block, or "Some fresh air" as the second piece.
  - **Counts:** 50/5/11 · 659/10/88 · 518/7/64.
- **G5 `slowing_down.5` — Your pace**
  - **Must be:** as §7.
  - **Case A counts:** 72/6/13 · 847/10/106 · 535/8/79.

**What a review may state, for every stage:** "<Stage> · <date> · <parts> · You said <answer> / No answer / Set aside: <reason>".

### 9. Feasibility result

**Method:**
- A port of the production quality gate (`gatePassingShapes`, `coherentParts`) over the 38-element release library.
- **Validated** against `ELEMENT_COVERAGE.md`: it reproduces the shape, distinct-main and materially-distinct counts exactly for every need × time.

**Result:** **45 / 45 stage × time cells PASS · 0 WAIT · 0 FAIL** in the clean model (full live, safe library; no user controls).

**Cells that become empty only under the user's own controls** — set aside, never a stall:
- E4 at ≈10;
- H3 at ≈10;
- G1 at ≈10;
- G2;
- E1.

**The only waits from other causes:** G1 at ≈10 (one matching day, after yesterday's main), and one day after a C4 fallback.

**B2 must port this matrix, the stage-5 cases and the More Energy attack to permanent Dart tests.**

### 10. More Energy: known risk

| Scenario | Result |
|---|---|
| More Energy every day at ≈10 | A cycle takes 5 consecutive days with no waits. Every stage has at least 2 main pieces at ≈10, so yesterday's main never empties a stage. |
| Standing stretch left out | E1 keeps 8 / 71 / 71 shapes. |
| Not useful on a composed or stage Circle | No exclusion; baseline counts; ranking only. |
| Single-activity Not useful on the stretch activity (rest) | E1 8 / 71 / 71 · E2 97 / 113 / 113 · E3 25 / 275 / 129 · E4 14 / 141 / 46. |
| Single-activity Not useful on Move to music (rest) | E1 20 / 43 / 43 · E2 74 / 93 / 93 · E3 16 / 121 / 61 · E4 15 / 141 / 61. |
| Too much for today | Every stage keeps low-effort forms (lowest: E3 at ≈10, 9 shapes). |
| Can't go outside | E4 keeps 24 / 144 / 19. |
| Safety gates | Enforced throughout. Nothing reactivated. |

- **Stall risk: PASS.**
- **Thinness: MEDIUM.** At ≈10, a More-Energy-dominant user meets the whole product's 19 sessions and 6 main pieces, and stage forms repeat from about cycle 3.
- **Status:** **not a D2 architecture blocker.** A known commercial and content risk.
- **Before public release:** the bounded safety review required by the release gate must be resolved — for the live breathing and exertion content, and for any still-gated activity proposed for release. The only lever that widens More Energy is optionally assessing `briskStepBurst` and `activeMovementSnack` in that review. Nothing is reactivated by this ADR.

### 11. Insights: six families

**Common rules:**
- Insights speak only of facts: choices, parts, skips, ratings, leave-outs, Plan state, dates and counts.
- Wording describes co-occurrence, never cause. Every denominator is shown.
- Every Insight carries an application, or an explicit "Nothing to change".
- **Cadence:**
  - a Plan review appears at once;
  - otherwise at most one new Insight per 7 days, assessed when the Insights tab is opened;
  - the same claim — the same family and subject (I1–I4, I6) — is shown at most once in any 28 days, counted from when it was shown, whatever the user did and whatever new evidence arrived *(founder decision 2026-10-18, from the B5 simulation)*;
  - priority: I3 > I2 > I4 > I1 > I6, among eligible claims only;
  - "Not now" also hides that evidence set for 28 days;
  - the Plan review (I5) is outside these rules;
  - no novelty quota — silence is valid;
  - nothing is pushed.
- **Snapshots:** the shown text, evidence dates, wording version, and applied/dismissed status; at most 52; readable after a lapse; deleted by Delete Circle history. Each Plan review is shown once: the cap never brings back a review it dropped *(B8 correction, 2026-10-20)*.
- **Free / Premium:** generating and applying Insights is Premium. The facts are always visible to everyone in History.
- **Forbidden everywhere:** mood, diagnosis, stress, mental-health state, recovery, physical ability, causal benefit, and "you did it" from a Close.

**I1 `insight.plan_for_need` — the Plan for your need**
- **Gate:**
  - within the last 28 days, one need was chosen on at least 5 Circles, on at least 3 dates, spanning at least 14 days;
  - it is the unique most-chosen need;
  - its Plan isn't active.
- **Example:** "You chose Clearer Head on 9 of your last 14 Circles, between 2 and 27 October."
- **Application:** Start / Carry on with / Go through that Plan again.
- **If already applied:** withdrawn.
- **When stale:** a dated snapshot, not actionable.
- **Forbidden:** any reason for the choice.

**I2 `insight.plan_pacing` — gentler Plan Circles**
- **Gate:**
  - within the active Plan's last 5 or more stage offers, inside 28 days, "Too much for today" was chosen at least 3 times on at least 3 dates;
  - Circles composed under this setting never count (system-applied).
- **Example:** "On 3 of your last 5 Getting going days, you chose 'Too much for today'."
- **Application:** "Keep this Plan's Circles gentler for now" → low-effort parts, composed one size below today's time (never below ≈10). It can be turned off and ends with the cycle.
- **If already applied:** never offered.
- **Forbidden:** "tired", "low energy", "recovering".

**I3 `insight.skipped_part` — a part you skip**
- **Gate:**
  - the user directly skipped part P (not as a dependent skip);
  - in at least 3 of the last 4 composed Circles that held P, on at least 3 dates, within 28 days;
  - P isn't already left out.
- **Example:** "You skipped 'Open a window' in 3 of the 4 Circles it was part of, most recently on 14 October."
- **Application:** Leave it out next time (reversible: Put it back). Or "Keep it".
- **When stale:** withdrawn after 2 unskipped appearances in a row.
- **Forbidden:** "you don't like it".

**I4 `insight.useful_in_common` — what your useful Circles shared**
- **Gate:**
  - **useful set:** within 90 days, for one need, at least 4 composed Circles rated Very or Somewhat useful, on at least 3 dates spanning at least 14 days;
  - **comparison set:** at least 3 other composed Circles for that need in the same window (unanswered or Not useful);
  - **the kind:** one kind (writing, tidying, music, walking, listening, reading, stretching…) was the main or second piece, unskipped, in at least ⌈2/3⌉ of the useful set and in at least 3 of them;
  - **base-rate guard:** the kind's share in the useful set exceeds its share in the comparison set by at least 25 percentage points.
- **Example:** "Writing was part of 5 of the 6 Clearer Head Circles you called useful, and 2 of the 9 other Clearer Head Circles in that time."
- **Rationale for the comparison set:**
  - It is an **exposure baseline** (how often the kind appears generally), not a set of failures. Unanswered ≠ Not useful, and the wording never says "the ones that weren't useful".
  - A negative-only comparison would make the Insight effectively unreachable, and would favour users who complain.
  - The composer already raises positively rated parts' exposure, so the guard is conservative.
  - Small samples are a description, not significance. That is acceptable because the only applications are Keep or "Nothing to change".
- **Application:** Keep the most recent of those Circles (if it isn't kept and there's room), or "Nothing to change — THIRTY already gives parts you've rated useful more weight."
- **Forbidden:** "helps your focus", "works for you".

**I5 `insight.plan_review` — the Plan review**
- **Trigger:** stage 5 guided or set aside; case D; or Leave after at least 3 guided stages.
- **Gate:** none. It's a bounded set with every stage shown. From cycle 2 there is a cross-cycle line per stage.
- **Wording:** §7.
- **Application:** Keep one of these Circles (works on Free) · Go through it again · Choose another Plan · That's enough for now.
- **When stale:** never. It's a dated record.
- **Forbidden:** "progress", "completed", "calmer", scores or rankings. "Most useful" is allowed only for a unique top positive answer.

**I6 `insight.whats_changed` — what's changed**
- **Gate:**
  - two windows — Recent (the last 28 days) and Earlier (days 57–84 ago), each meeting the pattern gate;
  - the unique most-chosen need differs between them;
  - each top need is at least 40 % of its window;
  - possible from about Month 3.
- **Example:** "From 1 to 28 July you chose Gentler Pace most (9 of 16). In the last four weeks it's been More Energy (11 of 18)."
- **Application:** the Plan for the recent need, or "Nothing to change — <Plan> is already your Plan."
- **When stale:** withdrawn.
- **Forbidden:** explanations from season, weather, life events or mood.

**Users who never answer** still get I1, I2, I3 and I6, and full Plan progress.

### 12. Insights maturity states and the calendar

The Insights tab never manufactures an Insight to fill the screen.

| State | Free | Premium |
|---|---|---|
| Day 1 | Calendar: "Your Circles will appear here, date by date." Plus: "With Premium, THIRTY looks at your own Circles and answers, and suggests one useful change when there's enough to go on." No sample Insight. | "THIRTY says nothing about patterns until your Circles span two weeks. Your calendar fills in as you go." The active Plan's place, if any. |
| Week 1 | Calendar | "So far: 6 Circles, 4 answers. THIRTY looks for patterns once your Circles span two weeks." The Plan's place. A genuine Plan review if a cycle ended. |
| Week 3+ | Calendar | I1, I2, I3 possible; I4 once enough answers exist. |
| Month 2+ | Calendar | I4 over 90 days; cross-cycle reviews; I6 from about Month 3. |

**Calendar** (restores the founder's decision of 2026-10-02, PD-04, and the V1 widget's three-state contract with its accessibility and state tests):
- **Closed:** a calm ring — "Closed in THIRTY", an app interaction only.
- **Recorded, not closed:** a small neutral dot.
- **No record:** plain and neutral.
- **Selected date:** a recorded date opens `/history/:date`.
- **List:** "See as a list" opens `/history`. On narrow screens, recorded dates are listed as rows at least 48 pt tall.
- **Spoken labels:** "<date>, Circle closed" / "Circle recorded, not closed" / "no Circle recorded".
- **Never:** streak chains, consecutive-day emphasis, red or missed dates, percentages, failure states, a Plan mark, or any implied activity or duration.
- **History stays Free and shared,** and is read from the same journal.

### 13. Free / Premium / after lapse

Identical to the contract's section [Free / Premium / after lapse](../PRODUCT_V2_CONTRACT.md#free--premium--after-lapse-amended-2026-10-17).

- **Free:** Today and Engine V2, feedback and learning, Not this one today, Memory, History list, calendar and record detail, export and delete, reminder, Worlds, accessibility and TalkBack, Keep, use/rename/remove of kept Circles on screen, and a truthful Plan preview.
- **Premium:** Personal Guided Circle composition, spoken guidance and background playback, running Plans (stage-steered composition, progression and revisits, reviews, repeat cycles), new Insights and their applications, Leave it out, and voiced kept Circles while the entitlement is active.
- **After lapse, preserved and readable:** kept Circles, History and calendar, Memory, leave-outs (with Put it back), saved Plan places and cycles, existing reviews, existing Insight snapshots, applied settings, the voice choice, export and delete.
- **After lapse, stops:** new composition, THIRTY's voice, Plan steering and progression, new reviews, new Insights, new applications.
- **No hostage mechanics.**

### 14. Audio, measurement and implementation

**Audio:**
- Production guidance is four voices (Locke, Heather, Milo, Brittney), each with 42 cues and one Preview: **172 files, PASS — FROZEN.**
- **No new Plan or Insight audio is required.** Stage Circles use the existing cues; stage context is on screen.
- *Optional, not authorized:* about 15 stage-opening lines and 3 Plan-end lines (about 3,600 characters across four voices). Decide after the closed test.

**Phase E measurement:** consent-gated aggregate events `plan_started`, `stage_guided`, `plan_review_seen`, `insight_shown` and `insight_applied`.
- They carry no Circle content, no need/activity/Memory text and no health inference, and must be reflected in privacy and Data Safety.
- Not implemented in D2.

**Implementation batches** (B0 is this governance freeze; B1–B9 followed in order, all complete by 2026-10-21):
- **B1 — Pre-release removal:**
  - Paths, routines, tune-ups, shorter versions, maintenance, the module library, routine candidates in the engine, and routine controls in Memory;
  - the Toolkit tab becomes Yours;
  - kept Circles migrate in place; journal records stay readable;
  - the export schema is updated.
- **B2 — Composer seam:** `StageBrief` (conditions, *serves up to*, gentle pacing, the C3 check), with the §9 matrix, the §7 cases and the §10 attack as Dart tests.
- **B3 — Plan domain and runtime:**
  - catalogue, state and engine;
  - Today precedence and the card line;
  - C4, Use it today, lapse;
  - new V2 plan IDs and a journal schema bump;
  - export and delete.
- **B4 — Plans tab.**
- **B5 — Insights domain:** six families, gates, snapshots, cadence, applications.
- **B6 — Insights tab:** the restored calendar and its tests; list and record-detail links; maturity states.
- **B7 — Shell and gates:** the four-tab shell, the You hierarchy, offer copy, entitlement checks at the service boundary, and direct-route tests.
- **B8 — Simulations and review packs:** Plan profiles (a non-responder, a mixed answerer, More Energy at ≈10, lapse), a 12-month Insight cadence run, regenerated packs and content guards.
- **B9 — Device QA and closure:**
  - S25 device QA and TalkBack;
  - founder content review;
  - the full D2 gate;
  - one closure commit;
  - push for the two independent audits.

**New device proof (S25):**
- Plans: start, a stage-steered and voiced stage Circle, wait (different need), set aside (after a leave-out), pause/carry on, revisit, the review in cases A and D, repeat, and lapse with a saved place;
- Insights: Day-1 state, the calendar with TalkBack (all three date states), record detail, applying an Insight (Leave it out), and lapse readability;
- You › Yours and Use it today;
- the four-tab shell at 130 % text and in dark mode;
- the Today card on a stage day — Start Circle stays visible, and the Circle is never shrunk beyond the existing near-fit rule.

## Consequences

- **Nothing owned is lost.** Kept Circles and every journal record survive. The only removals are Phase D objects that exist on test devices.
- **Net code size may shrink:** B1 removes more than B2–B7 add.
- **Plans and Insights only become personal with explicit answers.** The answer rate is unknown, and every case degrades honestly.
- **More Energy stays thin at ≈10** until the safety review widens its library honestly.
- **Accepted only with D2 closure:** this ADR becomes Accepted only in the single D2 closure commit.
- **After closure:** two independent audits of the same pushed SHA are mandatory. A material blocker from either restarts both on a new SHA. Phase E stays on hold until then.
