# Guided-voice entitlement correction — S25 QA (2026-10-12)

**Device:** Galaxy S25 (SM-S931B), Android 16, with 3-button navigation.

**Build:**
- **Throwaway debug build with the QA harness:** 42 temporary sine tones bundled in **both** voice folders (`assets/audio/guidance/female/` and `male/`), so that both voices count as bundled.
- **Never committed:** `pubspec.yaml` was restored and the tones removed right after the build.
- **Afterwards:** a clean build was reinstalled.

**Setup:**
- Media volume was 0 during the tones, then restored to 3.
- The screen was kept on while plugged in for the run, then restored.
- The founder touched nothing.

**Evidence:**
- `../talkback/entitlement_focus_log.txt`: audio-focus lines for TalkBack (uid 10151) and THIRTY (uid 10254) only.
- `../talkback/entitlement_free_kept_caption.png`: TalkBack's caption.
- `../screenshots/entitlement_you_*.png`.
- The raw log and the recording were deleted.

| # | Flow | Evidence | Result |
|---|---|---|---|
| 1 | **Free (D2-D lapsed):** the kept Circle's page | "My clear-head Circle", Clearer Head · about 25 minutes · 4 parts, with all 4 parts and their instructions (the frozen "Look far away" wording), and Use it today | **PASS.** Ownership intact. |
| 2 | **Free:** Use it today, then Start Circle (15:43:15) | Today: "My clear-head Circle, about 25 minutes · A Circle you kept." The running UI shows Part 1 of 4 with Skip / Pause / Next / Close Circle. **No THIRTY audio-focus line at all, no `GuidanceService`, no notification, no guidance wake lock.** | **PASS.** Before the correction, Start played "First." and opened the service. |
| 3 | **Free + TalkBack:** timed part change (15:45:15) | TalkBack spoke 15:45:15.2–15:45:27.0: "Part 2 of 4. Easy walk. Step outside without picking a route. Walk slower than usual, and stop for anything that catches your eye. About 15 minutes." THIRTY made no focus call | **PASS.** Accessibility is unchanged on Free. |
| 4 | **Free:** Pause, Resume, Next (TalkBack off) | "Paused · Part 2 of 4", then running again; Next → "Part 3 of 4 · next: Look far away". Still 0 THIRTY focus requests, no service | **PASS.** The visual runtime is complete. |
| 5 | **Free:** You | No spoken-guidance row | **PASS.** |
| 6 | **Premium again (D2-E, Active):** You | "Spoken guidance" (on), plus "Voice": **Female voice** (default, selected) / **Male voice**. Selecting Male voice marks it chosen | **PASS.** |
| 7 | **Premium:** the same kept Circle, Use it today, then Start (15:49:21) | THIRTY focus request 15:49:21.263 (`USAGE_ASSISTANCE_NAVIGATION_GUIDANCE`); `GuidanceService` `isForeground=true types=0x2`; notification "Circle running · Neck and shoulders" | **PASS.** The voice and service return with Premium, for a kept Circle too. |
| 8 | Leaving the voiced Circle (QA reset to real data) | Wake lock released 15:50:15.246; no service, no notification | **PASS.** Nothing is orphaned. |

**Covered by tests, not on the device:** these need the entitlement to change under a running Circle, which the QA harness can't do without replacing the session's store. All are in `guidance_entitlement_test.dart`:
- a lapse mid-Circle (the voice and service stop, and the Circle runs on);
- a resubscription mid-Circle (the voice speaks from the next part, never one under way);
- the stored voice choice surviving a lapse.

The lapse attack re-run is also a test: `saved_circle_lapse_attack_test.dart`.
