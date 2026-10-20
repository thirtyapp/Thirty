# D2 closure pass — S25 device QA (2026-10-12)

**Device:** Galaxy S25 (SM-S931B), Android 16, One UI, with 3-button navigation (`navigation_mode=0`, the founder's normal setting).

**How it was driven:**
- Claude drove every step over adb, and the founder touched nothing.
- **QA data:** the QA harness, with D2-A and D2-C. It was reset to real data afterwards, and the founder's real journal was never used.
- **TalkBack:** switched on and off through `enabled_accessibility_services`, keeping the existing CCleaner entry. Its phone-permission dialog was dismissed with Back each time.
- **Screen:** kept on while plugged in (`stay_on_while_plugged_in=3`) for the in-front tests, then restored to `0`.

**Builds:**
- **Circle 1:** the debug build of `d6e8dcb`, with no clips, so the voice is silent.
- **Circles 2–4:** a **throwaway** build with 42 temporary sine tones in place of the clips, so that the voice, `GuidanceService` and its wake lock run. The tones were bundled only for that build and never committed. `pubspec.yaml` was restored and the tones removed right after the build.
- **Afterwards:** a clean build was reinstalled (0 guidance assets in the APK).
- **Media volume:** 0 during the tones, then restored to 3.

**Speech evidence:**
- **When TalkBack spoke:** its audio-focus requests and abandons (`USAGE_ASSISTANCE_ACCESSIBILITY`, uid 10151). THIRTY's own cue is uid 10254, `USAGE_ASSISTANCE_NAVIGATION_GUIDANCE`. The log is filtered to those lines only: `../talkback/closure_tb_focus_log.txt`.
- **What TalkBack said:** its "Display speech output" captions, read from screen recordings around each change.
- **Personal data:** the raw logcat and recordings held the founder's personal notifications (TalkBack read incoming messages aloud during the run). They were deleted. Only crops showing THIRTY's own captions were kept.

## 2. TalkBack reliability — timed part changes, THIRTY in front

| # | Circle | Condition before the change | Change (log) | TalkBack | Caption evidence |
|---|---|---|---|---|---|
| 1 | 1 (D2-A, 10 min) | TalkBack OFF→ON, then idle for 1 min 45 s; Home → back 30 s, 3 min before the change | 10:32:19 Neck and shoulders → Get it out | **Spoken.** 10:32:19.5–10:32:31.4 | focus log |
| 2 | 1 | TalkBack OFF; **Pause** (20.7 s) and **Resume**; TalkBack ON 34 s before the change; dialog dismissed 29 s before | 10:38:40 → A glass of water (the last part) | **Spoken.** 10:38:40.5–10:38:49.4 | focus log |
| 3 | 2 (D2-A, voiced) | TalkBack OFF→ON **6 s before** the change; its dialog dismissed 3 s before, while still reading | 10:44:57.92 → Get it out. THIRTY deferred its cue (abandon only) | **Spoken, queued ~11 s late, in full.** One focus hold, 10:44:51.5–10:45:23.3: "TalkBack activé" → dialog → "THIRTY" → banner → **"Part 2 of 3. Get it out. …"** | `closure_overlap_captions.png` |
| 4 | 3 (**D2-C**, opened 2 min in, voiced) | TalkBack OFF→ON at 10:53:54, then **idle 6.5 min** (incoming-notification speech only) | 11:00:36.13 → Get it out (THIRTY deferred) | **Spoken.** From 11:00:36.19: "Part 3 of 4. Get it out. …" | `closure_d2c_part3_caption.png` |
| 5 | 3 (**D2-C**) — **the original miss reproduced exactly** | Same TalkBack session, idle 4.5 min | 11:06:36.13 Get it out → **Choose one thing** (the last part; THIRTY deferred) | **Spoken.** 11:06:36.22–11:06:45.1: "Part 4 of 4. Choose one thing. …" | `closure_d2c_lastpart_captions.png` |
| 6 | 4 (D2-A, voiced) | TalkBack OFF→ON just after Start, then idle 1 min 50 s | 11:10:36.00 → Get it out (THIRTY deferred) | **Spoken.** 11:10:36.04–11:10:47.9 | `closure_c4_idle_captions.png` |
| 7 | 4 | **Home** with TalkBack on (11:16:00), back in front **5 s before** the change (11:16:31.7) | 11:16:36.00 → A glass of water (THIRTY deferred) | **Spoken, queued ~18 s late, in full.** One focus hold, 11:16:00.6–11:17:06.1: home-screen widget → "THIRTY" → banner → **"Part 3 of 3. A glass of water. …"** | Seen frame by frame; the crop was lost to a save error before cleanup. Focus log kept. |

**Natural ends with TalkBack on, in front:** 4 of 4 spoken (10:40:40, 10:52:58, 11:07:36, 11:18:36). Each time THIRTY's close cue deferred: abandon only, no request.

**Result:** **7 timed transitions tested, 7 announced, 0 missed.** In front with TalkBack on, the voice never spoke: there was no THIRTY focus request at any change.

**Finding.**
- **What happens when TalkBack is busy:** when a part changes while TalkBack is already speaking (its restart readout, or the screen it reads on return), the part is **queued, not dropped**. It is spoken in full after the current speech, 11–18 s late, inside the same audio-focus hold.
- **Why the old "miss" may have looked like one:** in that case no new focus request appears at the change. A focus-log-only reading would wrongly call it a miss. That is why this pass reads the captions.

**The original observation (01:41:47, the earlier pass).**
- **What the original log shows:** TalkBack had finished speaking at 01:36:53 and was idle for 5 min. At the change it made no focus request at all, so it was not the queueing case above.
- **Retest:** its exact path was re-run twice in transitions 4 and 5: D2-C opened under way, TalkBack restarted then idle for minutes, and the change into "Choose one thing". Both were announced.
- **What stays unexplained:** the cause of that single event. The Flutter bridge (3.44.8, `AccessibilityBridge.java`) sends `TYPE_WINDOW_CONTENT_CHANGED` with `CONTENT_CHANGE_TYPE_SUBTREE` on every label change of a live region, and THIRTY's part label always changes. It **does not reproduce.**
- **No fix applied:** no code change, per the brief. An explicit announcement would add duplicate speech to the live region, which TalkBack demonstrably speaks.

## 3. System Back regression (3-button navigation, TalkBack off, voiced Circle 2)

| Check | Evidence | Result |
|---|---|---|
| Back from a running voiced Circle does not end it | Back at 10:47:22.9. THIRTY's task was kept and its activity moved to the back, **not finished**: same pid 2456, `Hist #0` still in the task. On return: "Circle in progress. 8 of 10 minutes" | **PASS** |
| The app goes to the intended background state | Launcher in front; `GuidanceService` `isForeground=true types=0x2`; `thirty:circle_guidance` wake lock held; process not frozen | **PASS** |
| Cue timing continues | The part change at 10:50:57.92 = Start (10:42:58) + 8:00 exactly: one THIRTY focus request (`USAGE_ASSISTANCE_NAVIGATION_GUIDANCE`), abandoned 10:51:01.97; notification "Circle running · A glass of water" | **PASS** |
| Returning restores the correct UI | Return 10:51:18: "A glass of water · Part 3 of 3 · the last part", with Skip / Pause / Next / Close Circle | **PASS** |
| No duplicate cue | No THIRTY focus request between 10:51:01.97 and the natural end at 10:52:57.92 | **PASS** |
| No accidental journal close | The Circle was still running on return. It ended only at its natural end | **PASS** |
| No orphan foreground service | At the natural end the wake lock was released at 10:52:57.925, and the service and its notification were gone (`dumpsys activity services`: nothing; 0 THIRTY notifications). The same holds after Circle 4 (wake lock released at 11:18:36.000) | **PASS** |

## 1. Foreground-service manifest

See `FGS_MANIFEST_VERIFICATION.md`. The result was PASS, and no change was needed. The Play Console declaration is recorded in the tracker as a Phase E requirement.
