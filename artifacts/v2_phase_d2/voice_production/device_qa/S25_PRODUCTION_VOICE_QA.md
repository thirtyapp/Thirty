# Production voice QA on the S25 — 2026-10-16

**Device:** Galaxy S25 (SM-S931B), Android 16, One UI, 3-button navigation.

**Build:**
- **A debug build with the QA harness** (`THIRTY_QA_PREMIUM=true`), bundling **the real 168 production clips**. This is the first device QA with production audio rather than test tones.
- **For this session only:** one temporary debug line named the assets handed to the player, so the right voice and script could be read from logcat (`QA-VOICE play …`).
- **Afterwards:** the line was removed, `flutter analyze` and the focused tests re-ran clean, and a clean build was reinstalled.

**How it was driven:**
- Claude drove every step over adb.
- The founder unlocked the phone twice (at the start, and after the locked-phone run).
- Media volume stayed at 9/15.

**Evidence:**
- **Log:** `logcat_voice_qa_filtered.txt`, filtered to THIRTY, Chrome's focus changes and TalkBack's focus. The full device log was deleted (other apps' data).
- **Screenshots:** `you_voices.png` and `r1_running.png`. The shade screenshot was deleted (personal notifications).

**Device state restored:**
- the accessibility services setting is back to its original value;
- screen stay-on is back to 0;
- no file was left on the phone, and no app permission was changed. A Samsung Music storage prompt was **declined**; the music came from Chrome over `adb reverse`;
- the harness is reset to real data.

## Runs

| # | Run | Evidence (logcat / dumpsys) | Result |
|---|---|---|---|
| P | **Preview, all four voices** (You → chip → "Hear <name>") | 14:58:30–14:59:23: `voice_locke_v1`, `voice_heather_v1`, `voice_milo_v1` and `voice_brittney_v1` each played `lead_first` + `part_phoneFaceDown`, following the selected chip | **PASS.** Real production audio, the selected voice |
| 1 | **Locke, 10 min, Clearer Head** (Neck and shoulders → Get it out → A glass of water) | Start 15:00:18: "First." + part, with the service started. **Timed Next at 15:02:18.465**, exactly 2:00 later, with THIRTY in the background (Home) | **PASS** |
| 1 | The notification's **Next** (shade) | 15:04:08.300: "And last." + `part_glassOfWater`, **once** | **PASS** |
| 1 | **Ducking:** Chrome playing (`USAGE_MEDIA`) and the natural close cue | Close at **15:06:08.465** (2:00 after the last part). Chrome: `onAudioFocusChange(-3)` (LOSS_TRANSIENT_CAN_DUCK) at 15:06:08.478, `(1)` at 15:06:12.373. Chrome's player stayed `started` throughout | **PASS.** Ducked, not paused |
| 1 | **End of Circle** | The wake lock `thirty:circle_guidance`, acquired 15:00:18, was released at 15:06:12.374, right after the close; no service | **PASS** |
| 1 | *(void attempt)* | The first ducking try: Chrome had not really started (0:00, no focus). Repeated as above | — |
| 2 | **Heather, 16 min (20-min window), More Energy** (Open a window → Move to music → Standing stretch → A glass of water) | Start 15:08:01; **Pause** 15:08:25 ("Paused · Part 1 of 4"); **Resume** 15:08:32, with no cue; **Next** 15:08:36 → "Next." + `moveToMusic`; Next 15:08:59 → "Next." + `standingStretch`; **Skip** "Skip it for today" 15:09:29 → "And last." + `glassOfWater` | **PASS.** Each cue once; Pause and Resume add no cue |
| 2 | **Close mid-Circle** | Confirm at 15:10:00; wake lock released 15:10:00.184; no service, no notification | **PASS** |
| 3 | **Milo, 26 min (30-min window), Clearer Head** (Set screens aside → One task → Get it out → Look far away) | 15:11:12 First; 15:11:30 and 15:11:53 Next (writing part); "Keep going" on the Skip sheet → no cue; 15:12:31 "And last." + `lookFar` (gentle part) | **PASS** |
| 4 | **Brittney, D2-C (a Circle already running), dependency** | Opening it mid-Circle: **no cue**. Next 15:13:44 → "Next." + `getItOut`. Skip sheet: "“Choose one thing” builds on this part, so it's skipped too." → straight to "To finish": **close once** at 15:14:13; the service ended after the speech (15:14:18) | **PASS** |
| 5 | **Voice setting OFF** (You switch), then Start and Next | No play call, no THIRTY focus, no service, no wake lock | **PASS** |
| 6 | **TalkBack ON, Premium, THIRTY in front** (TalkBack's own permission dialog dismissed with Back; nothing granted) | Timed change at 15:24:55.848: player called with `defer=true`; **no THIRTY focus request**. TalkBack (uid 10151) spoke 15:24:55.937–15:25:04.883 | **PASS.** Never two voices |
| 6 | *(void attempt)* | 15:18:55: TalkBack's permission dialog was on top, so THIRTY was out of sight and correctly spoke itself (`defer=false`). Not counted as an in-front test | — |
| 7 | **Free (D2-D, INACTIVE):** You | No spoken-guidance row | **PASS** |
| 7 | **Free, kept Circle** ("My clear-head Circle", Use it today → Start → Next) | No play call, no THIRTY focus, no service | **PASS** |
| 7 | **Free + TalkBack**: kept Circle, timed change at 15:29:11 | THIRTY silent (no play, no focus); TalkBack held speech focus 15:29:01–15:29:23; the screen showed Part 2 of 4 | **PASS** |
| 8 | **Premium again (D2-E, ACTIVE)**: the same kept Circle in Brittney | 15:32:21.910 "First." + `lookAround`; `GuidanceService` `isForeground=true types=0x2` | **PASS.** The voice returns with Premium |
| 8 | *(void attempt)* | D2-E first applied as INACTIVE: the selector still held D2-D's state. Free behaviour seen (no voice), as expected | — |
| 9 | **Screen off and locked** (`KEYCODE_SLEEP`; `mWakefulness=Dozing`, `isKeyguardShowing=true`) | Timed change at **15:33:21.912**, exactly 1:00 after Start: Brittney "Next." + `easyWalk`, with THIRTY focus requested; the process was `curProcState=4`, `isFrozen=false`. A second timed change, still locked, at **15:48:21.912** (15:00 later): "Next." + `gentleStretch` | **PASS** |
| 9 | **Return to the app** after the founder unlocked | Today showed "16 of 26 minutes", Part 3 of 4, Gentle stretch; **no cue on return** | **PASS** |

## Not verified on the device

**Perceptual (founder listening):**
- During this session the founder answered **"I wasn't listening closely"**.
- So these are **not verified by ear**:
  - no clipped onset;
  - no audible transition artefact;
  - no unnatural volume jump;
  - natural lead → instruction pacing;
  - comparable perceived loudness between voices;
  - the correct voice by ear.
- **What was verified objectively:** the correct voice and script by asset name and fingerprint, plus no stale and no duplicate cue.
- **Listening files:** `../listen/`.

**Resubscription restoring the *stored* choice:**
- The harness builds a new isolated store on every Apply, so a choice can't carry across a lapse on the device.
- **Covered by tests** in `guidance_entitlement_test.dart`:
  - "the user's voice and on/off choices survive a lapse";
  - "a lapse during a voiced Circle … a resubscription brings the voice back from the next part".
- **Seen on the device:** the Free → Premium return of the voice itself (run 8).

**Release build:** not built. As before, it needs `config/revenuecat.local.json`, by design.
