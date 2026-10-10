# ADR-022 — V2 Phase D / Premium: Paths, personal Toolkit and maintenance

**Status:** Accepted — founder approval 2026-10-10

Product authority: [PRODUCT_V2_CONTRACT.md](../PRODUCT_V2_CONTRACT.md). This ADR records only how Phase D realises it. Review pack: `artifacts/v2_phase_d/` (CONTENT_REVIEW.md, SIMULATION_REVIEW.md, simulations/, device proofs).

## Decisions

1. **Modules are pieces of live Phase A activities, not new content** (`toolkit/domain/module_library.dart`).
   - There are 13 `SessionModule`s, each pointing at a live activity whose fit, setting, effort, safety note, ending and (for Guided) steps it reuses. A module adds only a purpose line, a role (opener / main / closer) and, where honest, a short form.
   - **Three treatments — internal words, never shown as levels or achievement:**
     - short: a truly shorter form, only where one is authored (the core of the piece);
     - full: the piece at its natural length, with the idea that makes it work;
     - combined: two pieces joined as one Circle — a routine.
   - A one-length piece (the two Guided stretches, the warm drink) has no short treatment.
   - No gated or retired activity (briskStepBurst, activeMovementSnack, focusedBreathingCount, restfulBreathingPause, energisingBreathReset) is a module. A guard test holds this.
   - A `Composition` (≤ 30 min) runs on Phase C's Guided runtime as one synthetic `ActivityDefinition` (`sessionFor`):
     - an Open piece becomes one step ("About *n* minutes");
     - a Guided piece contributes its own steps;
     - the ending is the last piece's.
   - One Circle, one part at a time, never a checklist.

2. **Six Path templates, two per need** (`path_catalog.dart`). Each has a three-piece pool, an exact job ("what you're building", its stated length checked against the routines it can build) and a default routine name.
   - More Energy: **A lift at home** (short bursts indoors → "My pick-me-up") and **Out the door** (one sustained brisk walk → "My brisk walk").
   - Clearer Head: **Clear the decks** (offload and put in order → "My reset") and **Away from the screen** (less input → "My screen break").
   - Gentler Pace: **A soft landing** (stillness at home → "My quiet pause") and **Easy time outdoors** (gentle movement outside → "My time outdoors").
   - Names are time-neutral (a guard test rejects morning/evening words) and never a mechanical "My <Path>". Template ids (`wakeUpIndoors`, `slowTimeOutside`) are stored identities and stay. Path and routine names are frozen by founder approval.
   - Jobs describe what the user wants and what the routine holds, never an outcome ("for when you want a little more energy", not "lifts your energy"); a guard test rejects outcome promises in job and offer copy.

3. **The Path engine is pure and deterministic** (`path_engine.dart`).
   - **Seed:**
     - pieces found useful for the need first;
     - Don't-suggest removed;
     - a piece **resting** after a recent "Not useful" (Phase B's rest, not lifted) left out while it rests; negative evidence after the rest goes last;
     - fewer than two left → the Path does not start, and its page says why;
     - no evidence → the template order, said plainly.
   - **A build is 7 Path Circles, not days:**
     - Circles 1–2: short tries.
     - Circle 3: the better piece in full, or the third piece.
     - Circles 4–5: two together. The partner swaps after a "Not useful".
     - Circle 6: a shorter form, or else another pairing.
     - Circle 7: the routine as it stands.
   - Each step carries one plain reason line. A claim appears only when the user said it.
   - Missed days, other needs and "Not this one today" consume nothing. There are no streaks.
   - **Time:** a step runs at its own length, or its truly shorter form ("A shorter form, to fit today's time."), or the Path waits. Nothing is cut.
   - **Active rests** (`moduleResting`, founder correction): a Path never switches into a resting piece (Circle 3's third try, a partner from Circle 4, a pairing to compare); a step that can't do without one waits, and the Toolkit says so. A rest is never a ban: when it ends the piece is eligible again under normal evidence. Don't-suggest stays the harder, lasting control.
   - **Tune-up and Shorter are 3-Circle Paths over an existing routine:**
     - A tune-up swaps one piece. A piece the user asked not to suggest, or one resting, is swapped first; a resting piece is never the fix; with two such pieces no tune-up is offered.
     - **A shorter version is the same routine** (founder quality principle, `shorterVersionsOf`): every piece, in the same order, each full or in its authored short form — never a piece dropped, a timer cut or a step skipped, never made with a resting piece. A routine whose pieces can't be made shorter that way has no shorter version: on a shorter day it just doesn't fit, and Free decides. A single-piece routine may be shortened only by its own authored short form.
   - Step lines never repeat piece names mid-sentence; the card shows them right above ("You've found this useful before, so it comes first.").

4. **A routine is the user's** (`toolkit_model.dart`, `toolkit_provider.dart`, store `toolkit_v1`).
   - A routine has a name, a need, versions with origin (path / tuneUp / shorter) and an optional short version.
   - Versioning: a shorter version shares its base version's number; a tune-up becomes version max + 1, is made active and clears the old short version; every earlier version is kept and can be used again.
   - The user can rename it, turn it off, delete it, switch versions, and set routine-level Don't suggest.
   - The review proposes; the user keeps it (and names it) or doesn't keep it.
   - An unreadable store is set aside, never silently reset.

5. **Routines compete as ordinary Engine V2 candidates, with no Premium bonus** (`recommendation_engine.dart`).
   - A `RoutineCandidate` goes through the same gather/compare as an activity.
   - Its fit is primary for its own need, and secondary only if every piece fits.
   - Its answers are routine evidence. A routine Circle counts toward its pieces' recency.
   - Exploration never calls a routine "new".
   - **Evidence scopes stay distinct** (final closure):
     - a piece of the routine that is **resting** for this need (an unlifted "Not useful" within Phase B's rest) keeps the routine out of today's choice while it rests — Memory says the piece is resting, so Today never brings it back inside a routine. It is temporary: the routine is eligible again when the rest ends or "Suggest again" lifts it. Free then picks normally; no empty state is invented;
     - "Not useful" about the **routine** rests and down-ranks the routine only. It never rests its pieces: a user can dislike the combination without disliking each part;
     - rests are per need: a piece resting for another need doesn't touch this one;
     - per-need Don't-suggest stays the harder, lasting control.
   - A Path step takes Today only when Premium is active, the need matches, every piece is allowed and the step fits the time. Otherwise Free decides.

6. **Maintenance is always an offer, one at a time** (`maintenance.dart`, policy in `toolkit_policy.dart`).
   - **Priority:** time misfit > fading > gap. There is no offer while a Path is under way.
   - **Cooldown:** a declined offer stays away for 21 days.
   - **Time misfit:** ≥ 4 of the last 6 need-days in 28 are under the routine's length, no short version covers them, and a truthful shorter version (all pieces) is buildable with no piece resting.
   - **Fading:** ≥ 3 rated uses, and any one of:
     - the last 3 score ≤ 0;
     - the last 2 score ≤ −1;
     - a "Not useful" after ≥ 2 positive answers.
   - Fading counts only real uses: a build's own Path Circles never count.
   - **Gap** (founder correction — Premium must not manufacture need):
     - a need chosen ≥ 5 days in 28;
     - at least 3 explicit answers to Free's own picks for it (routine and Path answers don't count); unanswered Circles never make a gap;
     - Free not serving it well: the mean of those answers (Very 1, Somewhat 0.7, Not useful 0) below 0.5 — five "Somewhat useful" (0.7) are served;
     - no routine the user built for it, that THIRTY may offer, fits the usual time;
     - a Path for it that can still be seeded (Don't-suggest and rests respected);
     - fewer than 6 routines.
   - **User refresh:** Tune or Shorter from the routine page at any time.
   - **Toolkit check:** every 28 days. It says "Your routines are working well — nothing to change." when that is true, or "Still learning how these fit." without enough answers.
   - All values are TUNABLE and collected in `ToolkitPolicy`. Before → after tuning is recorded in SIMULATION_REVIEW.md.

7. **Don't suggest is a hard invariant everywhere** (the ADR-021 carry-over).
   - Per-need activity Don't-suggest removes a module from seeds, Path steps (checked again on the day), tune-up pools and shorter versions.
   - A routine containing a not-suggested piece is not offered for that need. Its page says so and offers the tune that replaces the piece.
   - Routine-level Don't-suggest (`routinesNotSuggested`) is a separate, user-owned control.

8. **Lapse.** Only starting a build, tune-up or shorter version needs Premium.
   - Routines stay owned, usable as Free candidates, and editable.
   - A Path under way is saved exactly and resumes at its next Circle when Premium is active again. In Free, its steps never take Today.
   - Recording a Circle of a Path already started, keeping or setting aside a finished proposal, and every ownership control stay ungated.

9. **V1 Premium is retired truthfully.**
   - `lib/features/plans`, `coach` and `insights` are removed.
   - `retireV1Premium` (idempotent, marker written last) deletes `plans_state_v1`, `insight_snapshots_v1` and the plan-day keys.
   - No routine is fabricated from V1 plan history. Old journal records keep a plain V1 Plan context line.
   - `/plans`, `/plans/:id` and `/insights` redirect to `/toolkit`.

10. **IA.**
    - Navigation is Today | Toolkit | You.
    - Toolkit (`/toolkit`) shows, in order:
      - the Path under way (or finished, or saved while lapsed);
      - the one offer or the check;
      - the routines;
      - "What Premium builds" for Free.
    - Further pages: choose a Path, Path start, review, and routine detail.
    - The offer page's copy is "Routines of your own"; price, products, trial, billing and restore are untouched.

11. **Journal.**
    - It gains an additive `session` record: title, modules, routine/version, Path run/kind/circle, reason, and the replaced-from fields.
    - Export includes the `toolkit` state.
    - Delete Circle history keeps routines, any Path under way and preferences, and says so. Every claim derived from history goes.

12. **QA.**
    - Debug-only scenarios D-* seed each founder proof:
      - first Path, under way, adapted, review, saved;
      - daily pick, week-7 misfit, fading;
      - tune-up under way and review;
      - stable check, lapsed, month two, gap.
    - D-N2 "Served well": the gap scenario's days, every Free pick "Somewhat useful" — no offer.
    - D-H2 / D-H3: a routine whose piece is resting is not today's pick; with the rest lifted, it is again.
    - Twelve eight-week simulations (plus 5b served-well and 10b active rest) run the production providers.

13. **S25 device pass** (100 %, 130 %, light and dark, live TalkBack). It changed:
    - **The label line on Today.** It reads "PATH · 5 OF 7 · 15 MIN"; TalkBack says "Path · Circle 5 of 7, about 15 minutes". With larger text it splits into two lines, with no dangling "·".
    - **The running Circle.** A Path step goes by its Path's name ("Step 1 of 2 · A lift at home").
    - **Step lines.** They stay within 60 characters (a guard test), so Start Circle stays on the first screen within Phase A's ≤ 4 % near-fit trim.
    - **Answer over time.** The line based on the user's answer outranks the time line.
    - **The Toolkit check.** It waits while a Path is under way, and never says "working well" with a "Not useful" in the period.
    - **Reading order.** Every Toolkit section, note and row, and the review's name field, is its own TalkBack stop, read in the order shown.
    - **Buttons.** `ThirtyButton` is always its own semantics node, so a button never merges into the text around it.

## Consequences

- **Closed-test question — routine frequency.** With no Premium bonus, a routine is offered about weekly when many ordinary activities are also well supported; the best truthful daily candidate wins. No preference control or ranking change is added. The closed test asks: "After building a routine, do users feel THIRTY offers it often enough to feel useful and owned?"
- Path lengths (7/3) and every maintenance threshold remain hypotheses, to be read against Phase E measurement.
- Phase E is not started.
