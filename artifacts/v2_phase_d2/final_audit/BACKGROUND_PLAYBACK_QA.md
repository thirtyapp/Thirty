# Background playback — S25 QA (final hardening, 2026-10-12)

**Device:** Galaxy S25 (SM-S931B), Android 16, One UI.
- **Builds:** debug, with the QA harness (`THIRTY_QA_PREMIUM=true`).
- **How it was driven:** Claude drove every step over adb. The founder unlocked the phone twice and did nothing else.
- **Test audio:** the voice was played with **temporary test tones**, 42 sine beeps named after the manifest files (lead 0.7 s, part 8 s, close 3.5 s). They were bundled only in throwaway builds, never committed, and deleted afterwards. They prove timing, focus and lifecycle — **not voice quality**.
- **Outside audio:** Chrome playing an MP3 (`USAGE_MEDIA`).
- **Volume:** media volume was set to 0 midway through, at the founder's request (the tones were unpleasant). Every check below reads system state (`dumpsys audio`, `dumpsys activity`, `dumpsys notification`, `dumpsys power`, logcat), not sound.
- **Log evidence:** `../bg_qa/logcat_thirty_audio.txt` — logcat filtered to THIRTY, its service and audio focus. The full device log was deleted because it held other apps' personal data.
- **Screenshots:** `../screenshots/fh_*.png`. Shade and lock-screen shots are cropped to the THIRTY and Chrome cards, for the same reason.

## Runs

### Run 1 — 10-minute Clearer Head Circle (D2-A), Chrome playing

Parts: Neck and shoulders 2 min, Get it out 6 min, A glass of water 2 min.

| Time | Step | Evidence | Result |
|---|---|---|---|
| 01:00:13.42 | Start Circle, in front | THIRTY focus request `req=3` (`USAGE_ASSISTANCE_NAVIGATION_GUIDANCE`); service `GuidanceService` `isForeground=true types=0x2` (mediaPlayback); notification "Circle running · Neck and shoulders", 2 actions; `PARTIAL_WAKE_LOCK thirty:circle_guidance` held | **PASS.** "First." plays at Start — a defect before this pass, now fixed. |
| 01:00:13.42–01:00:22.58 | The cue over Chrome's music | Chrome got `onAudioFocusChange(-3)` (LOSS_TRANSIENT_CAN_DUCK) at 13.420 and `(1)` (GAIN) at 22.580. Its player stayed `state:started` throughout | **PASS.** Ducked, not paused or taken over; music returns after the cue. |
| 01:00:45 | Screen off (`KEYCODE_SLEEP`); the S25 locks | `mWakefulness=Dozing`, `isKeyguardShowing=true` | — |
| **01:02:13.35** | The part ends with the screen off and locked | THIRTY focus `req=3` at 01:02:13.345, exactly 2 min after Start; process `isFrozen=false`, `curProcState=4` (foreground service) | **PASS.** The timed transition and its cue happen on time, with the screen off and the phone locked. |
| 01:03 | Wake: lock screen | Samsung's lock screen shows Chrome's media player only. The lock-screen shade shows "Circle running · Get it out" with Pause / Next | **PASS:** the notification holds the right part. **Note:** a non-media-session notification doesn't appear in the lock-screen "Now Bar" (see the architecture note). |
| 01:03:45.6 | Pause, tapped on the **locked** phone | The PAUSE intent reached `GuidanceService` (logcat `Received SERVICE intent … PAUSE`) without unlocking, **but the Circle did not pause** | **FAIL → fixed (defect A).** |
| 01:06:00 | Founder unlocks | Today: "Circle in progress. 5 of 10 minutes", "Get it out · Part 2 of 3 · next: A glass of water". The cue log holds just two cues (01:00:13, 01:02:13) | **PASS.** The UI matches reality, with no duplicate cue on return. |
| 01:06:13 → 01:06:35 | Pause, then Resume, in the app | The notification reads "Circle paused · Get it out", with the wake lock **released**; then "Circle running", with the wake lock re-acquired | **PASS.** |
| 01:06:40 | Home, then Settings in front | — | — |
| **01:08:36.44** | The part ends while Settings is in front | THIRTY focus `req=3` at 01:08:36.437 = 01:08:13 + the ≈ 23 s paused; `isFrozen=false`; the notification text is "A glass of water" | **PASS.** On time, with pause time correctly excluded, across an app switch. |
| **01:10:36.44** | Natural end, still out of sight | Close cue `req=3` at 01:10:36.437; focus abandoned 01:10:40.099; the wake lock released at 01:10:40.100; the service and notification gone | **PASS.** The ending is spoken once, then the service ends itself after it. |

### Run 2 — a composed Circle under way (D2-C), build with fix A

| Step | Evidence | Result |
|---|---|---|
| Opening a Circle already 2 min in | No cue (last cue 01:10:36); notification "Circle running · Clear one corner" | **PASS.** Never a cue on a first look, but the session is open. |
| Home, then the notification's **Next** (01:12:23) | Notification "Get it out"; **one** cue `req=3` at 01:12:24.5 | **PASS.** Next moves exactly once and speaks once. |
| The notification's **Pause** (01:12:47) | "Circle paused", **Resume** button, wake lock count 0 | **PASS.** |
| The notification's **Resume** (01:13:09) | "Circle running", wake lock 1, no new cue | **PASS.** |
| Back to THIRTY (01:13:28) | "3 of 16 minutes" (the pause excluded); "Part 3 of 4 · Get it out"; no extra cue | **PASS.** |
| Skip on "Get it out" | Sheet: "“Choose one thing” builds on this part, so it’s skipped too. Nothing is recorded against either." → "Skip it for today" → "To finish"; close cue at 01:13:55.1; focus released 01:13:58.8; service gone | **PASS.** The dependent skip goes straight to the ending, spoken once, and the session ends. |
| Close → confirm → "Did you try it?" Yes → "Was it useful?" Very useful → "Keep it" | "Thanks — you’ll see this again now and then." / "Kept as My clear-head Circle. It’s in your Toolkit." | **PASS.** |

### Run 3 — Back at the first screen (defect B)

| Step | Evidence | Result |
|---|---|---|
| Back on Today with a voiced Circle running (build before fix B) | logcat: `ActivityRecord.finishIfPossible` from the app; the service ended with the engine | **FAIL → fixed (defect B).** |
| The same, with fix B | THIRTY goes to the launcher; `GuidanceService` still running; activity alive | **PASS.** |
| Back on an open Skip sheet (fix B) | The sheet closes; THIRTY stays in front | **PASS.** In-app Back is unchanged. |
| The timed cue after Back to the launcher | THIRTY focus `req=3` at **01:35:47.97**, at the part's time, with the launcher in front; `isFrozen=false`; the notification reads "Get it out" | **PASS.** |

## Defects found on the S25 and fixed

**A. The notification's controls reached nothing after the app's state was rebuilt.**
- **Cause:** the single platform channel's listener was cleared by the *previous* provider container when the QA harness swapped containers.
- **The same risk in production:** any time the conductor is recreated.
- **Fix:** a session clears only a listener it set itself (`PlatformGuidanceSession.listen`).
- **Test:** `guidance_session_test.dart`.
- **Re-verified on the S25:** Next, Pause and Resume from the notification shade, with THIRTY in the background (Run 2).

**B. Back on Today finished the activity, ending a voiced Circle's cues.**
- **Cause:** on Android 16, once Flutter has nothing to pop, it withdraws its back callback, and the platform's default `Activity.BackInvokedFinishCallback` finishes the activity (stack captured with a temporary log, since removed).
- **Fix:** `MainActivity` registers a back callback before Flutter's own that moves THIRTY to the background, as Android 12+ does for launcher apps. `popSystemNavigator` does the same on older versions.
- **Re-verified on the S25 (Run 3).**

## Architecture note — why a plain foreground service, not a media session

- **The hijack risk:** a `MediaSession` (Media3 `MediaSessionService`) would make THIRTY the target of headset and lock-screen media buttons after each cue. During "Move to music", "Put a song on" or "Listen to one thing", the user's own player would lose its play/pause buttons to THIRTY. The founder brief rules out that kind of hijacking.
- **What Android requires:** only that the `mediaPlayback` foreground service shows a notification. A media session is not needed.
- **The trade-off:**
  - the controls appear in the notification shade, including on the locked phone, not in Samsung's lock-screen media "Now Bar";
  - without the notification permission they are hidden, though the voice still continues;
  - THIRTY asks for no new permission.

### Run 4 — TalkBack (rule: in front with a screen reader, the voice never speaks; out of sight, it does)

TalkBack was switched on through settings (Samsung TalkBack, appended to the existing CCleaner accessibility entry), and its own phone-permission dialog was dismissed with Back. Nobody touched the screen afterwards. Speech is evidenced by TalkBack's audio-focus requests (`USAGE_ASSISTANCE_ACCESSIBILITY`).

| Time | Situation | Evidence | Result |
|---|---|---|---|
| 01:22:07.7 | First attempt: TalkBack's permission dialog was **over** THIRTY when the part changed | THIRTY played its cue (`req=3`). THIRTY wasn't in front, so this is the out-of-sight branch | Correct per the rule; **not** the in-front test, so repeated. |
| 01:41:47.97 | THIRTY in front, TalkBack on; "Get it out" → "Choose one thing" | THIRTY: `abandonAudioFocus` only, no request — **the voice deferred**. **No TalkBack speech was logged** at this change | Voice rule **PASS**. TalkBack announcement **not evidenced** (open observation, below). |
| 01:42:47.97 / 01:42:48.98 | Same, natural end | THIRTY: no request (deferred). TalkBack spoke 01:42:48.98–01:42:57.7 (the natural-end announcement) | **PASS.** |
| 01:47:00.45 / 01:47:00.51 | Fresh 10-minute Circle, THIRTY in front, TalkBack on; "Neck and shoulders" → "Get it out" | THIRTY: no request (deferred). TalkBack spoke 01:47:00.51–01:47:12.38, the length of the part's live-region label | **PASS.** The live announcement speaks; the voice stays silent. |

**Still verified:** the rule holds on the S25 when TalkBack is off but another accessibility service (CCleaner) is on. The voice played in Runs 1–3 with CCleaner enabled; touch exploration is the deciding signal.

**Observation (resolved by the closure pass, 2026-10-12):** at one of the two timed part changes (01:41:47), TalkBack logged no speech. Correction: TalkBack had then been idle for 5 min (its restart readout ended 01:36:53), not just restarted.
- **Closure retest:** `CLOSURE_DEVICE_QA.md` §2 — 7 timed transitions tested, 7 announced, 0 missed, including this exact path twice (D2-C opened under way, TalkBack restarted then idle, the change into "Choose one thing"). A change while TalkBack is busy is queued and spoken in full, not dropped.
- **Outcome:** not reproducible; no code change (an explicit announcement would duplicate the live region TalkBack demonstrably speaks).

### Run 5 — the voice switch, lapse, resubscribe, lock-screen controls with fix A

| Step | Evidence | Result |
|---|---|---|
| You → Spoken guidance off, during a running voiced Circle | Service, notification and wake lock all gone at once | **PASS.** |
| …back on | The session reopens (THIRTY in front) | **PASS.** |
| Switching QA scenario (container disposed) | Service gone | **PASS.** |
| D2-D lapsed → Toolkit → "My clear-head Circle" → Use it today → Start | Today: "My clear-head Circle, about 25 minutes · A Circle you kept."; on Start, "First." plays and the session opens | **PASS.** **Note:** a kept Circle keeps spoken guidance on Free (ownership), which feeds the substitution hypothesis. |
| D2-E back on Premium | "Your Circle, about 15 minutes · Built from things you’ve found useful, to fit your 20 minutes." | **PASS.** |
| Lock-screen Pause and Resume **with fix A** (01:58:15) | `isKeyguardShowing=true`; "Circle paused" with the wake lock released; "Circle running" with it re-acquired | **PASS.** The notification's controls work on the locked phone. |

## Phone restored

- **Settings:** media volume back to 6, stay-awake off, TalkBack off with the original accessibility services.
- **Cleanup:** the Chrome test audio was paused, the adb reverse removed, and the local server and log capture stopped.
- **Build:** the plain debug QA build is installed, with no tones, so the voice is silent.
- **Left as found:** the phone is locked.
