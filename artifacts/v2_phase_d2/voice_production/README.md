# D2 spoken guidance — production run (2026-10-16)

**Status:**
- **Done and measured:** 168 production clips generated, raw-QA'd, mastered, bundled and device-tested.
- **Still open:** founder listening of the final pack. D2 is **NOT COMPLETE**.

| Gate | Result |
|---|---|
| Commercial licence | **CONFIRMED** by the founder, 2026-10-16: ElevenLabs Starter, paid, "Commercial License for Speech and Music" (`PROVENANCE.md`) |
| Voices | Locke `voice_locke_v1`, Heather `voice_heather_v1`, Milo `voice_milo_v1`, Brittney `voice_brittney_v1` (founder lock; `../voice_production_validation/FINAL_VOICE_SET.md`) |
| Canonical scripts | 42 clips. `SPOKEN_GUIDANCE_MANIFEST.csv` regenerated from the code is **byte-identical** (SHA-1 `d91c55d9…`), and every file name's FNV-1a fingerprint is re-derived from its script |
| Generation | 168/168, 16,940 characters, 168 distinct request IDs, no refusal (`generation_log.json`, `RAW_SHA1.txt`) |
| Raw QA | All hard checks pass after two Locke retakes (§3). Onset-at-first-sample takes are listed for listening (§3) |
| Mastering | The frozen restrained route (§4). No denoise, EQ, high-pass or compression; the limiter engaged on **0** clips |
| Pack integrity | 4 × 42 = 168 files, exactly the manifest names, nothing stale or extra. SHA-1 in `PRODUCTION_SHA1.txt` (168/168 verify). All 168 are in the APK, stored uncompressed |
| Device QA (S25) | Pass on every objective check (`device_qa/S25_PRODUCTION_VOICE_QA.md`) |
| **Founder listening of the final pack** | **NOT DONE.** During the device session the founder reported "I wasn't listening closely". The perceptual items are therefore unverified: clipped onsets, transition artefacts, volume jumps, pacing, and loudness between voices |

## 1. Generation (`tools/generate_production.py`)

- **Settings:** exact voice IDs; `eleven_multilingual_v2`; stability 0.5, similarity 0.75, style 0, speaker boost on, speed 1.0, seed 30; `mp3_44100_128`. The manifest script is sent verbatim, one request per clip, with no context stitching. These are the same settings as every validation batch.
- **The key** is read from the user environment. It is never printed, logged or stored.
- **Seed 30 reproduces the approved validation performances:**
  - Locke, Heather and Brittney match their founder-approved validation raws: the same durations, waveform correlation 0.997–0.9996.
  - Milo has the same durations and the same performance (20 ms envelope correlation 0.988–0.997). Only his waveform fine structure differs, at correlation 0.40–0.94; his voice is not bit-reproducible.
  - So the five clips the founder heard are the shipping takes.

## 2. Raw QA (`tools/raw_qa.py` → `raw_qa.json`; `tools/onset_detail.py` → `onset_detail.json`)

The untouched MP3s, decoded to float only.

**Checks per clip:**
- provenance: the expected voice ID and the exact canonical script;
- not empty;
- onset and ending;
- sample clipping;
- inner stalls;
- pace against the voice's own median;
- **offline speech recognition** (faster-whisper small.en, local, no upload), compared with the script.

**Per voice:** the frozen perceptual noise method.

| | Locke | Heather | Milo | Brittney |
|---|---|---|---|---|
| Provenance, empty files, sample clipping, stalls | pass | pass | pass | pass |
| ASR against the script | 1 real defect (`sitOutside`, §3), plus an ASR artefact ("Tend to" → "10 to 1") | ASR artefact only | ASR artefact only ("three" → "3") | exact |
| Pace outliers | script-driven: `gentleStretch`, `standingStretch` and `songOn` are slow or fast in every voice | same | same | same |
| Quietest-10 % pause bed, matched level, A-weighted | −98.3 dB(A) (validation anchor −97.8) | −101.0 (anchor −96.2) | −91.1 (anchor −90.1) | −89.4 (anchor −82.9) |
| Speech already sounding at the file's first sample | 2 | 17 (2 of them the founder-approved validation takes) | 12 | 9 |

**Endings:**
- The raw "ending" flags (Heather ×7, Locke ×1) were short-tail measurements.
- In every one the last 10 ms is at −85 to −88 dBFS: the file ends in silence, not inside a sound.
- None is a cut ending.

**Heather's breath:**
- Her per-clip pause outliers (`gentleStretch` quietest pause −61 dB(A) at playback level, `nameWhatsOn` −63) are breath in short, list-like pauses: pause frames vary from −50 to −44 dBFS. They are not a steady bed.
- Her founder-approved validation take `briskWalk` already has breath at about −55 dBFS raw.
- Reported for listening; not rejected (frozen method).

## 3. Retakes (`tools/generate_retakes.py`, `retake_log.json`, `retake_qa.json`)

**The rule:**
- Only a **concrete** defect qualifies.
- The retake uses the same voice, model, settings and script; only the seed moves on (seed 30 is reproducible and would return the same take).
- The seed-30 originals stay in `raw/`.

| Voice / clip | Seed-30 defect | Seed-31 retake | Shipped |
|---|---|---|---|
| Locke `part_sitOutside` | **An inserted vocalisation** after "Sit outside." (ASR "and one", about 300 ms of voiced sound between "outside" and "Find") | ASR exact; a clean pause; onset 30 ms | **seed 31** |
| Locke `part_phoneFreeWalk` | "Screen" already sounding at the first sample | ASR exact; onset 20 ms, from silence | **seed 31** |
| Heather `part_activeJob`, Heather `part_oneTask`, Milo `part_standAndReach`, Brittney `part_oneTask` | the word at the first sample | **the same** at seed 31 | seed 30 |

**Finding:**
- For words like "One…", "Stand…", "Sit…" and "Shake…", the model starts the audio on the word whatever the seed. It is text- and voice-dependent, not a one-off glitch.
- More retakes would not remove it.
- Every such word was recognised correctly by ASR.
- The founder approved two takes with the same property in validation: Heather's "First." and "Get it out".
- **Whether any sounds clipped is a listening question.** All of them are in `listen/<voice>__onset_review.m4a`.

**Cost:** 6 retakes, 794 characters. About 21.4k characters went through the API since 2026-10-12, against the Starter allowance of 30k a month.

## 4. Mastering (`tools/master_production.py` → `mastering_report.json`)

**The rule:** the frozen restrained route (`../voice_production_validation/replacements/NOISE_GATE_METHODOLOGY.md` § Production freeze):
- trim to speech;
- 10 ms trim-edge fades;
- outlier-only correction into ±2 LU of the voice's median part;
- **one voice-wide gain** to a −22 LUFS 42-clip take (the founder-approved validation level);
- the delay-compensated limiter only where needed (self-check lag 0 samples);
- 150 ms lead-in; 700/400 ms tails;
- AAC-LC, mono, 44.1 kHz, 128 kbit/s.

**Two applications of the rule, decided in this run** (reported for founder review):
1. **Leads are included in the outlier check.**
   - Validation exempted the one-word leads. Here Heather's "Next." came out 9.4 LU under her parts, and Locke's 4.6 LU.
   - Only leads outside the ±2 LU window moved: Heather "First."/"Next.", Locke "First."/"Next.".
   - The 1–2 LU softer "First." the founder approved in validation is inside the window and untouched.
   - After mastering, every lead's speech level (10 ms-frame p90) is within 2.2 dB of its voice's parts.
2. **The head fade never runs past the speech onset.**
   - Where a take starts with less than 10 ms before its first sound, the head fade is shortened to that margin, with a 2 ms minimum (click-free). A 10 ms fade would have softened the initial consonant.
   - Short head fades: Locke 1, Heather 19, Milo 13, Brittney 12. The tail fade is always 10 ms.

| | Locke | Heather | Milo | Brittney |
|---|---|---|---|---|
| Voice gain | +4.47 dB (validation used per-clip gains of +2.8 … +5.7) | −2.89 | −2.38 (validation −1.99) | +8.78 (validation +9.56) |
| Clips corrected as outliers | 2 (leads) | **24 of 42** (§ below) | 2 | 3 |
| Limiter engaged | 0 | 0 | 0 | 0 |
| Whole take | −22.10 LUFS | −22.04 | −22.09 | −22.07 |
| Part range after mastering | −23.6 … −20.9 | −24.8 … −20.2 | −24.6 … −20.2 | −24.1 … −20.4 |
| Worst true peak | −2.90 dBTP | −3.80 | −4.01 | −2.87 |

**Heather:**
- Her raw part levels span **15.3 LU** (−31.1 to −15.8). The other voices span 2.7–6.0 LU.
- That is generation inconsistency, not natural dynamics, so the "genuine outliers" rule corrects 24 clips and leaves her parts at a 4.6 LU spread, like the other voices.
- Her quietest take, `part_standAndReach`, needs +9.6 dB of correction. Listen for a softer, breathier delivery than her other clips.

## 5. Post-master QA of the shipping files (`tools/post_master_qa.py` → `post_master_qa.json`)

- **Lead-in:** 120–200 ms on all 168.
- **Tails:** within spec on all except three Heather parts, which run longer, not shorter: 0.58–0.70 s after a soft breath end. Harmless.
- **True peak:** ≤ −1.5 dBTP on all 168.
- **Perceptual bed at playback level:** at or below each voice's founder-verified anchor (Locke −98.4, Heather −101.4, Milo −91.2, Brittney −89.8 dB(A)).
- **Loudness between voices:** median part loudness −22.2 to −22.5 LUFS across the four.

## 6. App integration (code; see the tracker)

**The four named voices** replace the female/male placeholder slots:
- `ThirtyVoice` is `locke`, `heather`, `milo`, `brittney`.
- The neutral stable IDs (`voice_*_v1`) are the stored choice, the asset folder and the analytics ID. No gender appears anywhere in product logic.

**Activation:**
- **All or nothing per voice:** `completeGuidanceVoices`. A clip recorded for an older script has another file name, so it never counts.
- **Bundling:** the four folders are in `pubspec.yaml`.

**Settings and preview:**
- **You (Premium only):** the four name chips, plus **"Hear <name>"**.
- **The preview** plays the voice's own shipping clips, "First." plus "Phone face down…", with nothing synthesised for it. It plays even with a screen reader on, because it is an explicit request.

**Descriptors:**
- **Not shown.** Claude cannot hear the voices, and catalogue wording is barred.
- Locke's "Calm & gentle" and Heather's "Warm & textured" (founder, Oct 12) and any Milo/Brittney descriptor await the founder's choice from the production audio.

## 7. Listening files (`listen/`)

| File | Purpose |
|---|---|
| `<voice>__all_42_in_manifest_order.m4a` | **Every shipping clip** (6–8 min per voice): the requirement "listen to every clip" |
| `<voice>__onset_review.m4a` | Every clip whose take starts on its first sound (short head fade) |
| `<voice>__first_then_part`, `next_then_writing`, `next_then_walking`, `next_then_movement`, `next_then_gentle`, `last_then_part_then_close` | Sequences as heard in THIRTY |
| `all_four__next_then_walking.m4a` | The same cue in all four voices, at playback level: loudness between voices |

**To check by ear:**
1. Clipped first sounds, from the onset files.
2. Heather `standAndReach` (softer take?), `gentleStretch` and `nameWhatsOn` (breath in pauses).
3. Heather and Locke "Next.", corrected up.
4. Comparable loudness in `all_four__…`.
