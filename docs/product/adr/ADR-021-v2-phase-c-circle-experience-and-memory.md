# ADR-021 — V2 Phase C / Circle experience and explicit memory

**Status:** Accepted — founder approval 2026-10-10 (implemented 2026-10-09)

Product authority: [PRODUCT_V2_CONTRACT.md](../PRODUCT_V2_CONTRACT.md). This ADR records only how Phase C realises it.

## Decisions

1. **One Circle shell, three bodies.**
   - The Home Circle stays one screen: the World and its ring, a heading pair, one card in the Today card's shell (`HomeCardShell`), and one action.
   - Before Start: the greeting and the Today card (Phase A/B, unchanged).
   - While running: a session heading and `CircleSessionCard` with the mode's body (`sessionBodyFor`): **Open**, **Guided** (an activity with steps) or **Paced** (an activity with a reviewed `PacePattern`).
   - After Close: a calm close ("Your Circle for today." / "Your next Circle opens tomorrow.") and the inline reflection.
   - The shared shell keeps Phase A's near-fit contract: the running session card is shorter than the Phase A running card. Every live activity keeps the full Close clearance on the S25, and the Circle is never trimmed on a fresh launch into a running Circle.

2. **Runtime as timestamps and small state** (`domain/circle_session.dart`).
   - Active time is `activeElapsed(startedAt, now, pausedAt, pausedTotal)`: wall clock less pauses, never frame ticks.
   - Persisted per day: `recommendation_paused_at`, `recommendation_paused_ms` and `recommendation_guided_position`.
   - A resume from the background (which rebuilds today's Circle from storage) and a process restart restore exactly. Nothing is snapshotted per tick, and the recommendation is never re-rolled.

3. **Open.**
   - The card moves through the activity's own content as time passes:
     - the first action, for a fifth of the Circle (at least 2 minutes, at most half);
     - then each "while you're there" idea in turn;
     - from the natural end, the authored ending line.
   - The heading is the activity and its time: "4 of 15 minutes", never a countdown.
   - Time keeps running in the background. Open has no Pause.

4. **Guided.**
   - One step at a time: the step name is the serif heading ("Step 2 of 5 · *activity*" beneath it), and the card holds its instruction and cue.
   - Back and Next move through the steps and then to a "To finish" page with the ending line.
   - Position is orientation only. No step, position or "done" is ever journalled.
   - The authored cues stay human words; no per-step timer is inferred from prose.
   - Pause is a fixed-width icon toggle (the heading says "Paused" in words). It stops the Circle's time; background time while paused never counts.
   - Without a manual pause, time continues in the background: the user may still be doing the step away from the screen.

5. **Paced** — architecture only.
   - `PacePattern` / `paceMomentFor` give a deterministic phase from active time; `PacedSessionBody` shows the phase and time left, with a growing/settling mark.
   - Under reduced motion: words, numbers and a still ring only.
   - `PauseWhenHidden` pauses whenever the app leaves the foreground, and it stays paused until the user resumes.
   - **No catalogue activity has a pattern** (`ActivityDefinition.pace` is null everywhere, tested), so no activity paces. **No safety review has been done.** Breathing and exertion stay gated; the breath reset stays retired.
   - The runtime is proven on a synthetic, neutral pattern ("Pace one / Pace two"), not breathing guidance, on `/dev/paced-qa`. That route is registered only in debug builds (tested). Its ring is named "Paced test session", never "Today's Circle".

6. **The natural end.** Time only — never "completed".
   - The ring reaches full; the heading reads "That's your *n* minutes"; the card shows the ending line. A soft warm light falls over the same World (WORLD_SYSTEM §5D), fading in over 1.6 s.
   - Close becomes the filled action. Nothing closes automatically, and Close records the real time.
   - Seen live, it plays once and TalkBack hears one announcement. Found on arrival (background return, restart), it is simply there: no replay, no announcement. Under reduced motion it appears at once, with the announcement.
   - An early Close never warms the World. The closed ring keeps the time the Circle actually ran.
   - **Guided at the natural end.** Time never fabricates step progress. Wherever the user stood (step 2 of 5 included), the step, its position and Back/Next/Pause give way to the same end: "That's your *n* minutes", the ending line and the filled Close. When the app is hidden, the hero resets its end and close-lead state, so a return finds the end as it stands (§6, found on arrival) rather than a half-played beat.

7. **One filled action at a time.**
   - Start Circle before Start.
   - While running, the session's own action leads (Guided: Next) and Close stays outlined.
   - Close becomes filled at the natural end or on Guided's "To finish" page.

8. **Close and reflection.**
   - Close keeps its neutral confirmation, and spends the one soft Circle Closed haptic (MOTION_LANGUAGE §10).
   - The journal gains an additive, nullable `minutesAtClose` field: active minutes. It is a fact about the Circle, never the activity.
   - The reflection is inline, in the Circle: "Did you try it?", then "Was it useful?" only after "Yes" or "A little". Answers are optional, and Close alone is never evidence.
   - After an answer comes its acknowledgement (ADR-020) and a quiet "What THIRTY remembers" link. The footer prompt is retired, and the reminder/Premium invitations still wait for the reflection.

9. **Memory page** — `/memory`, "What THIRTY remembers": reached from You → Personal, from a closed Circle's acknowledgement, and from the no-candidate note.
   - It opens on the need asked for (`/memory?need=…`; the no-candidate note asks for its own need, so "nothing fits More Energy" lands on More Energy's "Not suggested" list), else today's need, else the latest Circle's, else More Energy.
   - One need at a time.
   - `needMemoryOf` derives it from the same journal facts and controls the engine uses, today's answers included:
     - **Useful before**: latest counting answer positive.
     - **Resting for now**: an unlifted "Not useful" within the rest, with its end date.
     - **Not useful before**: latest answer negative, rest over or lifted.
     - **Not suggested, as you asked.**
   - A usual time appears only from ≥ 3 explicit choices with a clear leader (≥ 60 %, no tie). TUNABLE.
   - Unanswered, started or closed Circles appear nowhere. What hasn't come up is one quiet line, without a count.
   - No scores, counts, charts or inferences.

10. **Explicit suggestion preferences** (`suggestion_preferences_v1`) — local, versioned, user-owned, separate from the journal.
    - `notSuggested` (activity + need + since) and `restsLifted` (activity + need + at), mapped to the engine's pure `SuggestionControls`.
    - **Don't suggest** is per activity *and* need, and is a hard engine filter that fallback, exploration and recency never relax.
    - If it leaves nothing that fits the chosen need and time, the engine returns no pick. It never overrides the user, and never offers a longer activity outside the window (a Phase C fix to Phase B's empty-window fallback). The daily question then says so and links to memory.
    - **Suggest again** on a not-suggested activity removes the choice; it is eligible under normal rules again. On a rest, it lifts the rest from answers given before that moment. The answer and its bounded evidence stay, and a later "Not useful" rests it again.
    - V1 Plan stages (Phase D) are not filtered by these controls.

11. **Remove this answer.**
    - From a History record or the memory detail.
    - Removes usefulness, or the attempt together with its usefulness. The record stays.
    - Today's Circle updates at once; memory and future picks recompute from the journal.

12. **Delete vs Reset.**
    - Delete Circle history removes the journal and everything derived from it, and keeps the suggestion preferences. Its confirmation says so.
    - "Reset suggestion preferences" (shown only when there are some) removes only the preferences.
    - Export adds `suggestionPreferences` beside the entries when any exist; nothing derived is exported.

13. **History.** A record also shows the offered length and any replacement in plain words, and offers "Remove" beside each given answer. No reason codes or scores.

14. **Screen reader (TalkBack, verified live on the S25).**
    - Open's moment is one stop: "First. *action*" / "While you're there. *idea*" / "To finish. *ending*". It is never a bare eyebrow, and it is not a live region: it changes with time, unasked.
    - Every dialog and sheet names its backdrop for what it does ("Close", "Keep Circle open", "Keep it", "Not now", "Cancel"); a guard test holds this for every call site in `lib/`.
    - A confirmation is announced by its question (`AlertDialog.semanticLabel`), not "Alert".
    - Focus follows only the user's own action: an answer moves TalkBack to the next question or the acknowledgement, never on first arrival; Pause/Resume keeps focus on the toggle; when Close takes the lead mid-session it takes focus.
    - The natural-end announcement waits 900 ms (`CircleHero.naturalEndAnnouncementDelay`), so it is heard after Close's own focus announcement rather than cut off by it.

15. **QA.** Debug-only fixtures C-A … C-R seed today's Circle (offered / running / paused / ended / closed and answered) and suggestion preferences directly, as the notifier persists them. C-H opens the Paced bench.

## Consequences

- **Phase D migration invariant:** an explicit per-need "Don't suggest" MUST be respected by the new Path / Toolkit architecture — no Path stage, routine, Toolkit candidate or tune-up may offer an activity for a need the user asked THIRTY not to suggest it for. No temporary V1 Plan compatibility work is added for this; V1 Plans are retired in Phase D.
- Phase D can give its Paths the same session runtime.
- A reviewed pacing pattern, once it exists, is added to its activity's `pace`. The Paced body and its lifecycle are ready; the safety gate still decides exposure.
