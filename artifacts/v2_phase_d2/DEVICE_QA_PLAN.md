# THIRTY Phase D2 — S25 device QA plan

Debug build with the QA harness. Every round starts from a QA scenario (the harness's "Apply" is a fresh app start), so nothing depends on timing or on an earlier round. Claude pre-positions each screen over adb and takes the screenshots. The founder is asked for at most three simple actions per round, with no timers.

| Round | Scenario | What is checked | Founder actions |
|---|---|---|---|
| 1 | `free_useful` (Free) | Today unchanged: one activity, its reason, the how-to with "Not this one today", Start/Close, the reflection, Memory, History | none (Claude drives; screenshots) |
| 2 | `d2_first_premium` | Choose Clearer Head ≈ 10 → "YOUR CIRCLE", parts line, basis line; "See the parts" sheet; Start; the first part moving on by itself after its minute | none |
| 3 | `d2_first_premium` | ≈ 20 and up to 30 (More Energy, Gentler Pace): fit, time use, coherence | none |
| 4 | `d2_running` | Part 2 on show; Skip sheet (three choices); "Skip it for today" → part 3; Next to "To finish"; Close leads | none |
| 5 | `d2_month` | "Built from things you've found useful…"; Memory → "Left out of your Circles" → Put it back; Toolkit → "Circles you kept" → its page | none |
| 6 | `d2_lapsed` | Today is Free's (no composition); Toolkit keeps the routine and the kept Circle; "Use it today" on each → Today | none |
| 7 | `d2_back` | Composition returns (Clearer Head) | none |
| 8 | dark mode, 130 % text | Rounds 2, 4 and 5 screens again: nothing truncated or overflowing; the Circle not shrunk beyond the ≤ 4 % near-fit trim | none |
| 9 | TalkBack on (Claude toggles it) | **Founder:** swipe through the running composed card (part text read as one; Skip, Pause, Next named); open Skip and swipe its three choices; on the closed day, swipe to "Keep it" | ≤ 3 swipes per screen |

Pass criteria: no visual defect a founder would call mediocre; every string matches `CONTENT_REVIEW.md`; TalkBack reads each stop once and in order; no "achievement" or pressure wording; Free looks exactly as in Phase C/D.
