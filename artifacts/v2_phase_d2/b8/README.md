# THIRTY — D2 B8: simulations, review packs, content guards

> **REVIEW ARTIFACT.** Evidence produced from the current working tree (HEAD `27e840a`, with the B0–B8 work intentionally uncommitted). It is not canonical authority: the product contract, ADR-023, ADR-024 and the code are.
>
> **Structure only.** These are deterministic synthetic histories. They show whether the product stays coherent, honest and within its rules over time. They establish **nothing** about willingness to pay, retention, conversion, health benefit, real usefulness or revenue.

## Contents

| File | What it is | How it is made |
|---|---|---|
| `CONTENT_REVIEW_PACK.md` | Every live user-facing string, by surface (Today, Plans, Insights, You, offer, lapse, accessibility), plus concrete founder flags | `flutter test test/features/b8/b8_review_pack_test.dart --dart-define=EXPORT_B8_PACK=true` |
| `MANIFEST.json` | When and from what the pack was made: HEAD, files, string count, content hash | Same command; the test fails whenever live copy no longer matches it |
| `REVIEW_MATRIX.md` | One table: where each piece of content appears, Free/Premium, lifetime stage, lapse, its evidence and the user's action | Written by hand against the code, for spotting contradictions |
| `simulations/` | The simulation traces and summaries quoted below | `flutter test test/features/b8/` writes them to `build/b8_simulations/`; copied here |

**Tests:**
- `test/features/b8/b8_product_simulation_test.dart`: the whole product for 12 months, profiles A–D, through the production providers.
- `b8_plan_attack_test.dart`: Stage 5 exhaustively, and 40 adversarial cycles per Plan.
- `b8_delete_longitudinal_test.dart`: Delete Circle history in the middle of long histories.
- `b8_live_copy_guard_test.dart`: the content guards.
- `b8_review_pack_test.dart`: the pack and its integrity check.

## One defect found and fixed

**Old Plan reviews came back as new.** Once a user had more than 52 Insight snapshots, the cap dropped the oldest. The next time Insights was opened, every dropped Plan review was generated again as if it were new.

- **Evidence:** the More Energy ≈10 profile ends 75 cycles a year. It was shown 440 Plan reviews, the same January review up to 8 times between August and January. B5's own "active Plan user" showed 72 reviews for 48 cycles.
- **Effect:** the dropped reviews returned under Earlier, out of order, pushing real history out of the cap. This broke the frozen rules: each review stays bound to its cycle, and the cap must not create repeats.
- **Fix** (`lib/features/insights/domain/insight_engine.dart`, `assessInsights`): a review is shown by the first assessment after its cycle ends. Once the cap is in force (never fewer than 52 snapshots afterwards), a review that isn't kept although a later snapshot exists was dropped by the cap, and is not generated again.
- **Scope:** no new state; below the cap, behaviour is unchanged.
- **After the fix:** every profile shows exactly one review per ended cycle (75 for 75; B5's 48 for 48). Every other B5 profile's 12-month numbers are byte-identical.

## A. Non-responder (311 days used of 365, no usefulness answer ever)

| | |
|---|---|
| Premium days composed | 311 of 311; 0 fallbacks to Free's activity; 0 stalls |
| Plan (Making room, repeated) | 131 stage days; 21 cycles ended and reviewed |
| Stage 5 | 28 times, every one case A ("A mix of this Plan's earlier stages") |
| Reviews | Every one says "You didn't answer after these Circles, so THIRTY can't say which stages suited you"; every stage line reads "No answer"; no cross-cycle comparison (it needs answers both times) |
| Claims | 0 "built from things you found useful"; no Insight text mentions "useful" |
| Insights | I1 ×10, I6 ×5, I5 ×21; I2/I3 0 (the user never chose Too much or skipped); I4 0 |
| Silent weeks | 38 of 53 |
| After Month 6 | Stage days and Insights continue to the end of the year |

**Without answers, the user still gets:**
- the daily composition, sized to time and need, with variety;
- Plan steering, progression and repeat cycles;
- an honest Stage 5 (case A);
- honest reviews;
- I1, I5 and I6, from choices and Plan facts.

**What is missing without answers:** answer-led personalisation. There is no "found useful" basis, no I4, no case B/C and no cross-cycle comparison.

## B. Mixed answerer (321 days)

The user answers on about 60% of days: Very, Somewhat or Not useful by the main piece's kind. Occasionally they choose Too much for today or Not feeling it, skip a part (once leaving it out), switch Plans and revisit a stage.

| | |
|---|---|
| Composed | 321 of 321; 0 stalls; 0 duplicate progress |
| Answers visible | 241 Circles "built from things you found useful" |
| Stage 5 | A ×1, B ×4, C ×14 — drawn only from this cycle's eligible stages (checked every time against `earlierStages`) |
| Reviews | 18; 16 compare with the cycle before, only where the user answered both times ("Fresh air — Not useful last time, very useful this time") |
| Insights | I1 ×12, I2 ×1, I4 ×10 (denominators shown: "3 of the 4 Clearer Head Circles you called useful, and 0 of the 6 other…"), I5 ×18, I6 ×6 |
| Silent weeks | 24 of 53 |
| Missing answers | Never counted as negative: an unanswered stage stays eligible for Stage 5 and reads "No answer" |

**Mechanisms covered by targeted tests, not this run:**
- A composite "Not useful" counts at half weight with no rest (`stage_brief_test` "Not useful (§6)", `circle_plan_today_test` 20–21).
- A single-activity "Not useful" rests that activity for 14 days.

## C. More Energy every day at ≈10 (365 days, Getting going repeated)

| | |
|---|---|
| Composed | 365 of 365; 0 stalls; 0 fallbacks; every part live and safe; never over 10 minutes |
| Plan | 365 stage days; 75 cycles; Stage 5 A ×14, B ×61 |
| Distinct sessions | 52 exact sessions; **19 materially distinct** (main + second piece); **6 main pieces** |
| Repetition | First exact repeat on day 23; median gap between repeats 23 days; shortest 8 days; never the same session two days running |
| Stage feasibility | All 45 stage × time cells still pass (`stage_brief_test`); Stage 5 composes for every eligible combination at every time (below) |

**Classification: WEAK** (thin, structurally usable).

This is the same finding as ADR-024 §10: 19 materially distinct sessions and 6 mains. The pack also shows More Energy at up-to-30 has 19 materially distinct sessions and 7 mains. That is new information, but no new risk class.

- **Not a D2 blocker:** no stall, the safety gate holds, and no content was widened.
- **Not a pre-release safety blocker.**
- **Real-user validation risk:** yes. A user who mostly chooses More Energy will meet repeats within about 3 weeks.

## D. Lapse and return (Premium 150 days, true expiry 120 days, then Premium again)

The user keeps a Circle after every positive answer (up to 8), leaves one part out, runs Making room and applies Insights.

| | |
|---|---|
| During the lapse | No new composition, no stage Circle, no Plan movement (place, cycles and records unchanged every day), no new Insight, every Insight application refused, voice not offered (the choice kept) |
| Preserved | Kept Circles (8), History, leave-outs, the Plan's place and cycles, earlier reviews, Insight snapshots, voice choice — checked every lapsed day |
| Owned substitution | On **111 of 120** lapsed days a kept Circle matched the day's need and time, and was used |
| Back on Premium | Composition resumes; the Plan steers again from its saved place; Insights generate again; nothing is generated retroactively for the lapse |
| Hostage mechanics | None |

**What lapse takes away:** new personal composition, THIRTY's voice, operating a Plan, and new Insights with their actions. All four are continuing work that a kept Circle can't do.

## E. Twelve-month Insights (all profiles)

| Profile | I1 | I2 | I3 | I4 | I5 | I6 | Silent weeks |
|---|---|---|---|---|---|---|---|
| A non-responder | 10 | 0 | 0 | 0 | 21 | 5 | 38/53 |
| B mixed | 12 | 1 | 0 | 10 | 18 | 6 | 24/53 |
| C More Energy ≈10 | 10 | 0 | 0 | 1 | 75 | 0 | 42/53 |
| D lapse | 9 | 0 | 0 | 5 | 19 | 0 | 39/53 |

- **Violations across all four:**
  - 7-day cadence: none;
  - 28-day same-claim rule: none;
  - snapshot cap: none, after the fix.
- **B5's own 12-month simulation:** re-run unchanged, except its active Plan user, where the fix applies.
  - I3 surfaces for its frequent skipper (9).
  - I2 for its active Plan user (12).
- **Month comparisons:**
  - Month 1 → 6: more families appear (I6, more I4) and cross-cycle comparisons begin.
  - Month 6 → 12: the same mechanisms over more history. Nothing claims growing sophistication.

## Plan longitudinal attack, Stage 5, Delete history

**Stage 5, exhaustively:**
- For each Plan, all 625 combinations of the four earlier stages (set aside, no answer, Very, Somewhat, Not useful) were checked against an independent statement of §7.
- 16 combinations make no last Circle: every stage set aside or Not useful, and only then.
- 65 are case A, 216 case B and 328 case C.
- Results are deterministic.
- Every made Stage 5 composes at ≈10, ≈20 and up to 30 in a clean library: 1,827 of 1,827.

**40 adversarial cycles per Plan:**
- The cycles mixed random answers, leave-outs that set stages aside, revisits and pauses, with phases of all-rejected, all-set-aside, and mixed set-aside plus unanswered.
- Endings per Plan: 30 reached the end, 5 all rejected, 5 all set aside.
- No stall, no loop, no duplicate progress (closing the same Circle twice never moves the place twice).
- The place only moves by one per guided Circle, or past stages set aside that day.
- Revisits never move the place.
- Every cycle id is distinct.

**Delete Circle history mid-history:**
- **At stage 3 after a month of history:**
  - The place, cycle, start date and Plan state stay; so do kept Circles and leave-outs.
  - The journal, snapshots and stage records go.
  - Stage 3 is served next.
  - No Insight appears until new evidence spans two weeks.
  - Stages 1–2 become unanswered.
- **Just before stage 5 with every stage "Very useful":** stage 5 becomes case A, with no "found useful" claim.
- **An ended cycle:** the review and its Insight go, and are never rebuilt. The end reads `historyDeleted`, with no date.
- **A left Plan:** the Leave and its date survive; the review does not.
- **The gentler setting:** it survives.

## Commercial attack (structural, not market evidence)

| Question | Answer, from the runs above |
|---|---|
| 1. Can Free fully solve the daily core job? | Yes: one good activity for the day's need and time, learning from answers, History, Memory, kept Circles on screen |
| 2. Is Premium more than "more content"? | Yes: it composes from the same live library. Its value is the work done each day (composition, voice, Plan operation, Insights), not extra content |
| 3. Can 8 kept Circles replace the subscription? | **Partly.** As daily sessions they matched 111 of 120 lapsed days. They can't compose for a new need or time, follow a Plan, produce an Insight or speak |
| 4. Does a Plan still serve after cycle 1? | Yes: each repeat cycle composes afresh; 16 of 18 mixed-answerer reviews compare with the previous cycle |
| 5. Do Insights grow without becoming a dashboard? | Yes, slowly: about one ordinary Insight every 2–4 weeks, later families from about Month 3, no charts. Many weeks are silent by design |
| 6. Does a non-responder still get recurring value? | Yes, structurally: daily composition, Plan operation, honest Stage 5 and reviews, I1/I5/I6. Not the answer-led parts |
| 7. Answer-rate dependency | **MEDIUM**: the four jobs run without answers; personal depth (found useful, I4, Stage 5 B/C, comparisons) needs them |
| 8. Month 6 vs Month 1 | Materially different: more Insight families, cross-cycle comparisons, composition weighted by more evidence |
| 9. Month 12 vs Month 6 | Not materially different: the same mechanisms over more history. The product doesn't pretend otherwise |
| 10. Does value rely on confiscating ownership? | No: nothing owned changes on lapse |
| 11. Does value rely on endless new content? | No. The fixed library's thin spots (More Energy) are recorded, not hidden |
| 12. Does value rely on fake weekly Insights? | No: 24–42 of 53 weeks have no new Insight |
| 13. €5–7 a month | **Structurally plausible** — continuing jobs exist — **not validated**. No price, conversion or retention evidence exists |
| 14. Still unvalidated by real users | Willingness to pay; answer rate; whether composed variety feels different enough from Free; kept-Circle substitution in practice; Plan uptake; whether Insights feel useful; the voice's value; retention |

**Largest remaining structural weakness:** for a user who rarely answers and mostly chooses one need, Premium's day-to-day difference narrows to fresh composition, the voice and the Plan's direction. Eight kept Circles can cover most days as fixed sessions, so the recurring value rests on variety, guidance and direction, never on ownership. More Energy's thin library makes this sharpest. Only real users can show whether that is enough.
