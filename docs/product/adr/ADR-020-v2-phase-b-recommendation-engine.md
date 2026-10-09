# ADR-020 — V2 Phase B / Recommendation Engine V2

**Status:** Accepted — founder approved, Phase B complete (2026-10-09)

Product authority: [PRODUCT_V2_CONTRACT.md](../PRODUCT_V2_CONTRACT.md). This ADR records only how Phase B realises it.

## Decisions

1. **A pure decision layer.**
   - `recommend(context, history, {policy})` in `lib/features/home/domain/recommendation_engine.dart` is pure Dart: no clock, storage, randomness or Flutter. The same inputs always give the same `RecommendationDecision` (activity, offered minutes, reason code, trace).
   - Gathering (the provider reads the Circle journal), deciding (the engine), persisting (provider + journal) and presenting (Today card) are separate.

2. **Inputs.**
   - Today: local date, need, `TimeWindow` (≈ 10 / ≈ 20 / up to 30), an optional `ReplacementRequest`, and whether safety-pending content may be offered.
   - Activity: the Phase A catalogue plus two new attributes, `ActivitySetting` (indoor / outdoor / either) and `ActivityEffort` (low / moderate), set explicitly for every activity; used only by "Not this one today".
   - History: `PastCircle`s mapped from the journal — date, need, final activity, catalogue version, explicit usefulness, replaced-from. Attempt answers ("Not today") and Close are never usefulness evidence.

3. **Derived memory, never stored.** `RecommendationMemory` recomputes evidence strength (Very +2, Somewhat +1, Not useful −2; halved after the half-life; nothing beyond the window), rests, recency, family use and exploration state from the journal on every decision. Delete Circle history therefore removes all learning by construction; no profile or cache exists.

4. **Historical-learning eligibility.** Every answer passes `historicalEvidenceEligible(activity, catalogVersion)` (ADR-019 §4). V1 answers for LEARNING_RESET activities (A brisk walk, A quick standing stretch) and the retired breath reset never count. V1 Circles still count for recency, which is factual.

5. **Selection.** Every tunable value lives in one place, `RecommendationPolicy.initial` (`recommendation_policy.dart`).
   - **Hard limits, never relaxed:** safety status, retired content, fit NONE, a length that cannot fit the window, today's replacement constraint.
   - **Multi-direction fit:** primary fits before secondary ones; a secondary fit the user found useful (here or for another need) joins the primaries.
   - **Time fit:** the window is room, not a target; an offer using less than half of it carries a soft penalty.
   - **Recency and variety (soft penalties, never exclusions):** offered in the last few days, declined recently, same family as yesterday, the last Circle of this need, a family used often this week, a rest just ended, "Not useful" for another need or for its family.
   - **Ranking bands:** useful-here-and-ready → primary fits and useful secondary fits → other secondary fits. Within a band: fewer soft penalties, primary first, positive evidence, the curated starter order while a need is new, then the tie-break.
   - **Exploration:** once a need has ≥ 3 answers and ≥ 4 Circles since something new, an untried fit is offered — never on a ≈ 10 day, never as a replacement, always labelled.

6. **Explicit negative feedback outranks variety** (frozen, founder correction 2026-10-09). Protective rules are relaxed only when nothing else is left, in this order:
   1. normal rules;
   2. the weekly cap (family frequency is already a soft penalty);
   3. yesterday's activity — an otherwise valid one that isn't resting may repeat;
   4. only when no valid fit that isn't resting remains, a temporary "Not useful" rest gives way — deterministically, the rest closest to expiry first, then the weakest negative evidence. The rest itself stays intact.

   Any relaxed pick carries the internal reason `fallback` and shows no personal reason. **Consecutive repetition is a fallback, never normal positive-evidence behaviour:** a useful activity stays bound by recency and variety, and the simulations assert that ordinary histories never repeat an activity on consecutive days.

7. **Tie-break.** `stableTieBreak` is a 32-bit FNV-1a hash of `YYYY-MM-DD|need|activity` — platform-independent, pinned by a test, never `dayIndex % n`.

8. **Offered duration.** Open activities may run anywhere from their minimum to their typical length within the window; Guided and Paced only at their authored length. Nothing is padded or cut short. The ring, the card and the how-to use today's offered minutes.

9. **One decision a day.** `chooseIntention` decides once and persists the offer (time window, offered minutes, reason code, replacement) in the per-day keys and the journal. Rebuilds and restarts restore it; the engine runs again only for "Not this one today". Persistence writes are serialised so a quick replacement can never be overwritten by the original offer.

10. **Not this one today.** Offered from the activity's how-to (the space above Start Circle is fully used on the S25). Before Start, the card's activity row says so in one quiet line beneath the name — "How to do it · Not this one?", or just "Not this one?" where the full line would need a second (narrower phones, enlarged text); "How to do it" once swapped or on a Plan day; nothing once started. It is fitted into the row's own height and is always one line, so at normal text the card is never taller. Once per day, before Start, never for a V1 Plan stage. Reasons: "Can't go outside" (only for outdoor activities; outdoor excluded), "Too much for today" (low effort, shorter and gentler preferred; labelled "lighter" only when truly shorter), "Not feeling this one" (another family). The journal records the final activity, the replaced one and the reason; the declined activity is treated as recently offered for a few days (soft, decaying context). It is never a usefulness answer.

11. **Reasons.** At most one visible line, shown in place of the activity's own reason (which stays in the how-to): "You found this useful before." only when positive evidence decided the pick and includes a "Very useful"; "Something new to try for this."; and the three replacement lines. `starter`, `bestFit`, `fallback` and `planStage` stay internal.

12. **Journal fields.** Additive, nullable, schema 1: `timeWindow`, `offeredMinutes`, `reasonCode`, `replacedFromActivityId`, `replacementReason`. Exported as part of every entry. The retired V1 keys (`recommendation_history_*`, `recommendation_last_family`) are no longer written and are removed on the next choice and by Delete.

13. **Time default.** `timeWindowChoiceProvider` starts from the most recent explicit window in the journal, else ≈ 20 — derived, so it resets with Delete.

14. **Safety gate in QA.** `safetyPendingAllowedProvider` carries the Phase A gate; the QA harness pins it off, so QA walkthroughs show exactly what a release build would.

## Consequences

- V1 Plans (Phase D) still supply their stage activity without the engine or a replacement.
- The memory page (Phase C) can present the same derived memory; it adds no new storage.
- Policy values are hypotheses: change them in one file and re-read the 40-day traces (`recommendation_simulation_test.dart`, `--dart-define=TRACE=true`).
