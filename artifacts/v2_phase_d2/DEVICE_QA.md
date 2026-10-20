# THIRTY Phase D2 — S25 device QA (2026-10-11)

Galaxy S25 (SM-S931B), 3-button navigation, debug build with the QA harness. Claude drove every round over adb from QA scenarios; the founder unlocked the phone and did one TalkBack round. Screenshots: `screenshots/`. The TalkBack recording and its caption strips are in `talkback/`.

## Results

| Round | Scenario | Result |
|---|---|---|
| 1 Free unchanged | `free_useful` | **PASS.** One activity with its reason; how-to with "Not this one today"; "Too much for today" → "Something lighter instead"; Start / Close confirm / reflection ("Thanks — you'll see this again now and then."); Memory. No Keep row on a Free day. |
| 2 First Premium Today, ≈ 10 | `d2_first_premium` | **PASS after fix 1.** "YOUR CIRCLE · 10 MIN", "Here's your Circle for today.", parts sheet, Start; the first part moved on by itself after its 2 minutes ("Get it out · Part 2 of 3 · next: A glass of water"); Skip sheet → "Skip it for today" → part 3; Next → "To finish" + ending, Close leads; reflection; "Keep it" → "Kept as My clear-head Circle. It's in your Toolkit." |
| 3 ≈ 20 / up to 30 | `d2_first_premium` | **PASS after fix 2.** More Energy ≈ 20: 16 min, "Built from things you've found useful…" (true: the history holds a "Very useful" Move to music). Gentler Pace up to 30: 29 min. |
| 4 Running | `d2_running` | **PASS.** Part 2 on show, Skip / Pause / Next. |
| 5 A month of Circles | `d2_month` | **PASS after fixes 3–4.** Toolkit "Circles you kept" → its page (parts with times, Use it today, Rename, Remove); Memory "Left out of your Circles" with "Put it back". |
| 6 Lapsed | `d2_lapsed` | **PASS.** Today is Free's one activity (no fallback line — not a Premium day); the routine kept; an honest fading check pointing to Premium; the kept Circle → "Use it today" → Today shows it ("A Circle you kept.", no "Not this one?"). |
| 7 Back on Premium | `d2_back` | **PASS.** Composition returns ("Built from things you've found useful…"). |
| 8 130 % text, light mode | several | **PASS after fixes 5–6.** Nothing truncated at 130 %; the page scrolls as designed. In light mode, Close Circle is fully visible after Today → Start. |
| 9 TalkBack | `d2_running` | **PASS.** See the reading order below. |

**TalkBack reading order.**

Running card:
1. "Clear one corner"
2. "Part 2 of 4 · next: Get it out"
3. The card as one stop ("One corner of a desk… About 8 minutes.")
4. "Skip, button"
5. "Pause, button"
6. "Next, button"
7. "Close Circle"

Skip sheet:
1. Backdrop "Keep going" (every backdrop is named)
2. "Dismiss"
3. "Skip this part?"
4. "Skip it for today, button", then its explanation
5. "Leave it out next time", then its explanation
6. "Keep going, button" — focus then returns to the part text

The debug-only QA marker also takes a stop; it is absent from release builds.

## Defects found on the device and fixed (commits 7ba6157, f77a4ea)

1. **Composed Today card pushed Start Circle off the first screen.**
   - Cause: the parts line wrapped to three lines beside the decorative art.
   - Fix: the composed card uses its full width.
2. **A four-part Circle still needed three lines.**
   - Fix: Today now names the session's substance — its main and second piece (e.g. "Easy walk · Read a few pages"), guarded to two lines. Every part stays in "See the parts", and History shows the full line.
3. **Memory showed a composed Circle's "Not useful" as the user's word about One active household task.**
   - This was a pre-existing display bug for routines too; the engine was always right.
   - Fix: Memory counts only answers about an activity on its own.
4. **Toolkit order and wording.**
   - Owned things now come before the optional first Path.
   - The Path suggestion now states the observed count instead of "often … lately".
5. **Light mode, Today → Start: a four-line part instruction pushed Close Circle under the tab bar.**
   - Fix: seven instructions were tightened to three lines.
   - A new S25 geometry guard runs every element as the part on show, after the Today card, with the longest next-part name.
6. **The Skip sheet overflowed at 130 %.**
   - Fix: it is now scroll-controlled; guarded at 200 % on a 320 pt screen.
7. **Polish:** no orphaned "minutes." or "one." (non-breaking spaces).

## Not covered on the device

- **Gesture navigation:** covered by the S25 geometry tests only.
- **A full 10/20/30-minute session run to its natural end in real time:** the parts and the auto-advance were proven; the natural end is tested in the widget tests.
- **Spoken guidance:** no voice ships (ADR-023 §6).

---

# Correction pass — S25 regression (2026-10-11, evening)

Same S25 (3-button navigation), debug QA build. Claude drove every step over adb; the founder only reconnected the phone. Screenshots: `screenshots/cp_*.png`.

Spoken guidance was checked with **temporary test tones**: 42 sine beeps named after the manifest, bundled only in a throwaway build, never committed, and deleted afterwards. **They are plumbing, not the voice.** No real recording exists.

| Check | Result |
|---|---|
| Skip on "Get it out" with "Choose one thing" after it | **PASS.** The sheet reads "“Choose one thing” builds on this part, so it’s skipped too. Nothing is recorded against either." "Skip it for today" goes straight to "To finish". |
| Voice: a part begins (Next) | **PASS after fixes A and B.** THIRTY requests transient duckable focus (`USAGE_ASSISTANCE_NAVIGATION_GUIDANCE`, `req=3`). Two MediaPlayers play in sequence (lead, then part), and focus is released about 2.5 s later. |
| Voice: last part, then the close | **PASS.** The "And last" lead plays; the close plays at "To finish" (also after a skip). |
| Voice with TalkBack on, THIRTY in front | **PASS.** At the part change THIRTY plays nothing (no focus request, no player); TalkBack's own speech takes focus and announces the change. TalkBack was switched on and off via settings, with no founder swipes. |
| Voice switched off (You → Spoken guidance) | **PASS.** The next part change and the close are silent. |
| You → Spoken guidance | **PASS.** Shown, on by default, in the build with recordings. Absent in the build without them. |
| User leaves THIRTY mid-Circle (Home) | **FINDING C, open.** Android froze THIRTY (`isFrozen=true`), so no cue at the part change. On return the screen shows the right part and no stale cue plays. |
| Premium offer, lapsed | **PASS.** "From your first day…", "Shaped by your answers: tell THIRTY what was useful and later Circles can bring it back…", "With Free, THIRTY still gives you one good thing for today…". |
| You Premium card | **PASS.** "A guided Circle made for your day, from the time you have — and shaped by your answers over time." |

**Found on the device and fixed:**

- **A. The voice never became available.**
  - The bundled-recordings check is asynchronous, and the Circle only *read* the voice provider, so it never settled.
  - Fix: whether the recordings are bundled is now read once at start-up and passed in, like the stored preferences. A widget test runs the real voice → player chain.
  - Re-verified on the S25 with a fresh build: the cue plays, and the setting shows only in the build with recordings.
- **B. Flutter's `accessibleNavigation` was true with TalkBack off** (CCleaner's accessibility service was enabled), so the voice deferred to a screen reader that wasn't there.
  - Fix: the Android player decides from touch exploration (TalkBack) itself.

**Open (not fixed — a founder decision, part of the voice gate):**

- **C. Cues while THIRTY is not in front.**
  - Keeping cues on time after the user switches away needs a media-playback foreground service, which brings a persistent notification.
  - Screen off with THIRTY on top was not tested: the S25 has a lock screen, and waking it needs the founder.

**Not re-run:** a full live TalkBack swipe-through. The Skip sheet's structure is unchanged (one new detail string in the same semantics container), and the voice-versus-TalkBack rule was verified without swipes.

**Phone restored:** TalkBack off with the original accessibility services, stay-awake off, and the plain debug QA build installed (no recordings).

---

# Final hardening — S25 (2026-10-12, night)

**Setup:** same S25, now on Android 16. Debug QA builds. Claude drove every step over adb; the founder unlocked the phone twice and did nothing else. The full record is in `final_audit/BACKGROUND_PLAYBACK_QA.md`.

**Spoken guidance was again exercised with temporary test tones:** never committed, and deleted afterwards. **No production voice exists, so no voice quality was assessed.**

| Area | Checks | Result |
|---|---|---|
| Free regression (`free_useful`) | Today ("Here’s one thing for today", "You found this useful before."); "Not this one today" → "Can’t go outside" → "An indoor one instead."; Start (no voice session for a Free activity); Close confirm; reflection; Memory ("Move to music. You said somewhat useful · 12 October"); History | **PASS** |
| Premium compositions (D2-A) | ≈ 10 → 10 min Clearer Head, 3 parts; ≈ 20 → 16 min More Energy, "Built from things you’ve found useful"; up to 30 → 29 min Gentler Pace | **PASS** |
| Running (D2-C) | Skip; dependent skip (sheet names "Choose one thing", goes to "To finish"); Pause / Resume / Next, in the app and from the notification; Close confirm; reflection; Keep it ("Kept as My clear-head Circle") | **PASS** |
| Ownership and lapse (D2-D, D2-E) | Lapsed Toolkit → kept Circle → Use it today → "A Circle you kept." → Start (voiced); back on Premium → composition returns | **PASS** |
| Audio and lifecycle | Voice in front; screen off and locked; another app in front; Back to the launcher; notification controls on the locked phone; ducking of Chrome's music; return to the app; the voice switch; the natural end ending the service | **PASS**, after fixes A and B |
| TalkBack | The voice never spoke in front with TalkBack on (3 changes). TalkBack spoke the natural end and one timed part change; at one other timed change no TalkBack speech was logged | Rule **PASS**; observation **resolved**: closure retest 7 of 7 announced, 0 missed (`final_audit/CLOSURE_DEVICE_QA.md`) |

**Fixed on the device in this pass:**
- **A.** The notification's controls reached nothing after the app's state was rebuilt.
- **B.** Back on Today finished the activity on Android 16, ending a voiced Circle's cues.
- Before the device run, a widget test also exposed that "First." never played at Start.

**Not covered:**
- production voice playback quality (no clips exist);
- gesture navigation (3-button only on this S25);
- a live founder TalkBack swipe-through (the controls are unchanged since the founder's 2026-10-11 pass);
- headset media buttons (no headset connected; no media session exists to take them).
