# D2 final voice corrections — founder review (2026-10-17)

## FOUNDER PERCEPTUAL QA: PASS (S25, real app, 2026-10-17 09:45–09:48)

**Verdict:** the founder listened on the S25 in the real app runtime and answered "all ok" for all four.

**How it was played:**
- A temporary debug-only QA Circle: Set screens aside → One task → Get it out → Gentle stretch → Sit for a minute.
- **Heather:** her preview as reference, then "Next." + One task, Get it out and Gentle stretch.
- **Brittney:** her preview as reference, then "And last." + Sit for a minute, then her close.
- **Playback:** each cue played once and held audio focus for its full length (`S25_founder_listening_logcat.txt`).

**Cleanup:** the temporary scenario and log line were reverted. `lib/` is byte-identical to before (155/155), and a clean build was reinstalled with the harness reset to real data.

**Open founder item:** the "Hear <name>" preview must no longer be an activity clip. It needs a dedicated preview line per voice.

## APPLIED (founder picks, 2026-10-17)

The founder chose by ear: Brittney **c3**, Heather Get it out **−1.8 dB**, Heather One task **−2.7 dB**, and Heather Gentle stretch **c3**. Do not substitute these on measurements.

**Copied, not remastered:**
- The four approved review files were copied byte-for-byte over their shipping files in `assets/audio/guidance/`.
- The exact performances the founder heard now ship.

**Integrity:**
- **Count:** 168 files, 42 per voice.
- **Hash list:** `../PRODUCTION_SHA1.txt` was rebuilt in its original order and verifies 168/168.
- **Changed:** 4 lines differ from `PRE_CORRECTION_PRODUCTION_SHA1.txt`. The other 164 files are byte-identical.

| Shipping file | New SHA-1 | Source |
|---|---|---|
| `voice_brittney_v1/part_sitAMinute_c80c3b07.m4a` | `10ad54ce…` | `brittney_sit_a_minute/candidate3_seed33.m4a` |
| `voice_heather_v1/part_getItOut_a239320e.m4a` | `c64cf98c…` | `heather_get_it_out/CORRECTED_-1.8dB.m4a` |
| `voice_heather_v1/part_oneTask_80701d4c.m4a` | `9b9603b7…` | `heather_one_task/CORRECTED_-2.7dB.m4a` |
| `voice_heather_v1/part_gentleStretch_052b8910.m4a` | `70c33a4e…` | `heather_gentle_stretch/candidate3_seed33.m4a` |

**QA of the files as shipped (`applied_qa.json`):**
- **Script:** ASR matches the canonical script exactly (0 word edits on all 4).
- **Naming and provenance:** the manifest file name and fingerprint are correct, and the logged voice ID and script are correct.
- **Levels:** 150 ms lead-in; 430–460 ms tails, ending in digital silence.
- **Identity:** waveform correlation with the source take at the logged gain is ≥ 0.9997, so each file IS the approved performance.

**Brittney's initial "S":**
- In c3 the "S" frication lasts **140 ms** before voicing: the longest of the four seeds (seed 30: 130 ms, 31: 135, 32: 90). No phoneme is missing.
- The take starts on an "S" already under way, at −9.9 dB from its peak.
- The shipping file's "S" profile is identical to the raw.
- The 2 ms head fade removes −27 dB of the first 100 ms' energy, and the 150 ms lead-in keeps the "S" clear of the AAC encoder start. No new fade or gain was applied.

**Pack-wide post-master QA:**
- `../post_master_qa.json` was re-run; the previous version is kept as `PRE_CORRECTION_post_master_qa.json`.
- Lead-in and true peak are in spec on all 168. The tail exceptions are the same three Heather parts as before (longer, not shorter).
- **Heather's pause bed:** −101.4 → −102.2 dB(A). Her gentleStretch breath is gone.
- **Brittney's pause bed:** −89.8 → −88.2 dB(A). It is still quieter than her founder-verified anchor of −82.9. This is a measurement note, not a flag.

**Locked:**
- `../tools/production.py` `FOUNDER_FINAL` records the four.
- `../tools/master_production.py` now refuses to run, because a rerun would re-derive voice gains from the new takes and remaster all 168.
- `../mastering_report.json` describes the 2026-10-16 master. For these four files, the authority is `review_report.json` and `applied_qa.json`.

---

**Original review (before the picks):** nothing in `assets/audio/guidance/` had been replaced.

**What the founder heard:**
- Brittney `part_sitAMinute` sounds like a different person.
- Heather `part_getItOut` and `part_oneTask` are too loud.
- Heather `part_gentleStretch` must be regenerated.

**Chain check:** re-running the production master on each of the four shipping raws reproduces the shipping `.m4a` byte-for-byte. Every file here therefore differs from shipping only in the stated way.

## Brittney — `brittney_sit_a_minute/`

- **Script (frozen):** "Sit for a minute. Sit still for a minute or two before you move on. There’s nothing to do."
- **Takes:** voice `pjcYQlDFKMbcOUp6F5GD`, `eleven_multilingual_v2`, frozen settings. Seeds 31, 32 and 33; the current take is seed 30.
- **Mastering:** the frozen production rule, using Brittney's frozen voice gain (+8.78 dB). No extra processing.

**Listen:** `COMPARE__firstStep_then_current_c1_c2_c3.m4a`. It plays Brittney's normal "First step" clip, then CURRENT; the clip again, then candidate 1; then candidate 2; then candidate 3.

| | CURRENT (s30) | c1 (s31) | c2 (s32) | c3 (s33) |
|---|---|---|---|---|
| ASR vs script | exact | exact | exact | exact |
| Onset | 10 ms, clean | "S" at first sample | **10 ms, clean** | "S" at first sample |
| Ending, clipping, stalls | ok | ok | ok | ok |
| Pause bed, dB(A) (voice spread −91.8 … −79.2) | −91.1 | −80.8 | −81.8 | −84.9 |
| Timbre: spectrum distance from her other 41 takes | **4.44 dB (97th pct, outlier)** | 3.10 (79th) | 2.56 (53rd) | 2.51 (53rd) |
| Pitch vs her median (214 Hz) | −0.3 st | **−2.5 st** | −0.4 st | **−2.2 st** |

## Heather — `heather_gentle_stretch/`

- **Script (frozen):** "Gentle stretch. Slowly: neck, shoulders, open the chest, a seated twist, then fold forward and come up slowly. Only what’s comfortable."
- **Takes:** voice `plP9aw1rizYgjFfuvLQ7`, seeds 31–33. Mastered by the frozen rule, with Heather's voice gain (−2.89 dB).

**Listen:** `COMPARE__warmDrink_then_current_c1_c2_c3.m4a`. It plays Heather's normal "Warm drink" clip before each take.

| | CURRENT (s30) | c1 (s31) | c2 (s32) | c3 (s33) |
|---|---|---|---|---|
| ASR vs script | exact | exact | exact | exact |
| Onset | at first sample | at first sample (5 ms fade) | **20 ms, clean** | **"G" at full level at sample 0** (−10 dBFS first 10 ms) |
| Pause bed, dB(A) (voice spread −108 … −61) | **−61.2 (breath; her worst)** | −101.5 | −98.4 | −101.2 |
| Duration / pace vs her median | 16.7 s / 0.55 | 13.8 s / 0.68 | 14.0 s / 0.67 | 15.7 s / 0.59 |
| Pitch vs her median (143 Hz) | −0.4 st | −0.6 st | −1.2 st | +0.3 st |
| Short-term max vs her part median | ±0 | +0.9 LU | +1.5 LU | +1.8 LU |

## Heather — level corrections (the takes are kept)

- **Rule:** the production chain from the same raw, with ONE extra static gain. The gain is the mean excess of integrated, max-momentary and max-short-term loudness over Heather's part median (I −22.1, M −17.8, S −21.7). No compression, EQ or denoise.

| | Current I / M max / S max | Excess | Correction | Corrected I / M / S |
|---|---|---|---|---|
| `heather_get_it_out/` | −20.4 / −15.8 / −19.9 | +1.7 / +2.0 / +1.8 | **−1.8 dB** | −22.2 / −17.6 / −21.7 |
| `heather_one_task/` | −19.9 / −14.9 / −18.8 | +2.2 / +2.9 / +2.9 | **−2.7 dB** | −22.6 / −17.6 / −21.5 |

**In context:** `heather_level_in_context__CORRECTED.m4a` is Heather's manifest run: quickClearUp, daylight, **getItOut**, clearCorner, **oneTask**, listenOne, readPages. `…__CURRENT.m4a` is the same run with the shipping files, for A/B.

**Numbers:** `review_report.json`.
**Tools:** `tools/` (`generate_candidates.py`, `review_pack.py`, `loudness_profile.py`).
**Generation:** 6 requests, 675 characters (`generation_log.json`).
