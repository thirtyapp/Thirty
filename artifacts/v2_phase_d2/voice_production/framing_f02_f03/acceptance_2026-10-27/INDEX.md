# F02 / F03 — acceptance listening (2026-10-27)

These files are built from the **installed app masters** (`assets/audio/guidance/<voice>/`), joined in PCM.
- No generation was done.
- No source, master or shipping file was changed: the 180 guidance assets had the same aggregate SHA-1 before and after.
- Tool: `../tools/acceptance_listening.py`. Measurements: `acceptance_listening.json`.

| # | File | What you hear |
|---|---|---|
| 01 | `01_brittney__existing_cue__then_F02_as_at_Start.m4a` | An existing Brittney cue ("Next." + Clear one corner), a 2 s pause, then Start as THIRTY plays it: F02 → "First." → Stand and reach |
| 02 | `02_brittney__existing_last_cue_and_ending__then_F03_as_at_Close.m4a` | "And last." + Choose one, a 2 s pause, the ending, 1.5 s, then F03 |
| 03 | `03_heather_F02__A_app_master__B_social_correction_matched__in_context_then_ABAB.m4a` | The same Heather cue, then **A** (the app master) → "First."; the same cue, then **B** (the founder-approved social version B, −4.03 dB to A's −22.3 LUFS) → "First."; then A B A B |
| — | `../listen/voice_locke_v1__ending_then_close.m4a` (existing) | Locke's F03 after his ending. His F03 is the quietest line against the clip before it (−1.6 LU) |

## Measured, for the ear to judge

**Brittney's pitch.** Against her **parts**, F02 is −2.67 st and F03 is −2.37 st. Against her own **short app lines** — the leads, the ending and the Preview, which are what F02 and F03 sit beside — they are −0.22 st and +0.07 st. Those short lines themselves span −3.65 to −0.31 st against her parts.

In sequence:
- F02 → "First.": +0.25 st, which is seamless.
- F02 → first part: −1.9 st.
- Ending → F03: −2.06 st. This is the most exposed join, file 02.

**Loudness against the neighbouring clip:**

| Voice | F02 vs first part | F03 vs ending |
|---|---|---|
| Locke | −0.2 LU | −1.6 LU |
| Heather | +2.0 LU | +1.2 LU |
| Milo | +1.7 LU | 0.0 LU |
| Brittney | +0.5 LU | +2.0 LU |

These are short clips, so integrated loudness is only approximate. Each line is within the frozen rule against its voice's median part.

**Edges.** The lead-in peak is −105 to −123 dBFS and every tail is digital silence. There is no noise floor outside the words.

## Listening guide (final verification, 2026-10-27)

Listen at a normal phone volume, on the phone's speaker and on earbuds if you can. The times below are computed from the clip lengths.

**1 · Brittney into F02** — file 01 (35.5 s)
- 0:00–0:15: an existing cue ("Next." and Clear one corner). This is her usual voice, the reference.
- **0:17.1: F02 "Your Circle for today."**, then "First." at 0:18.9 and Stand and reach from 0:20.4.
- Listen for: does F02 sound like the same person as 0:00–0:15? Does F02 flow into "First." as one line? (Measured: +0.25 st, seamless.)

**2 · Brittney ending into F03** — file 02 (21.5 s). **This is the most exposed join.**
- 0:00–0:10: "And last." and Choose one.
- 0:12.4: the ending.
- **0:18.75: F03 "Your next Circle opens tomorrow."**
- Listen for: the drop from the ending into F03 (−2.06 st). Does it sound like a natural, quieter last word, or like a different take? Does F03 feel too loud next to the ending (+2.0 LU)?

**3 · Heather F02, A vs B** — file 03 (54.2 s, matched level)
- 0:15.0: **A** (app master, what ships), then "First." at 0:17.0.
- 0:36.4: **B** (the founder-approved social correction), then "First." at 0:38.2.
- Back to back: A 0:42.4 · B 0:45.9 · A 0:48.9 · B 0:52.3.
- Listen for: whether A's start and flow are as good as B's. If B is clearly better, that is a master swap. It would need your explicit authorization and would use no credits.

**4 · Other high-risk transition: Locke ending into F03** — `../listen/voice_locke_v1__ending_then_close.m4a` (7.5 s)
- The ending from 0:00, then F03 at about 0:05.2.
- Listen for: F03 is his quietest line against the clip before it (−1.6 LU). Is it still clearly heard?

Nothing in this folder ships. No master will change unless you hear a defect and authorize the change.

## Founder decisions (2026-10-29)

- **1 · Brittney into F02: PASS.**
- **2 · Brittney ending into F03: PASS.**
- **3 · Heather F02: PASS.** Master A, the existing corrected app audio, is kept. No swap.
- No new recordings, and no master changes. `FRAMING_SHA1.txt` still verifies 8/8.
- **4 · Locke ending into F03:** no separate verdict was given in this round.
