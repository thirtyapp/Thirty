# Replacement voice validation — Milo and Grace (2026-10-14; REVIEW ONLY, NOT BUNDLED)

**What this is:**
- **The candidates:** the founder supplied two exact voice IDs to replace the rejected Andre Leone and Lunaria.
- **What was generated:** only the five canonical validation clips per voice.
- **What was not:** no production clips. The 168-clip pack is **NOT AUTHORIZED**.
- **Untouched:** `pubspec.yaml`. Locke and Heather were not rebuilt; their approved hashes still match `../APPROVED_LOCKE_HEATHER_SHA1.txt`. The Andre and Lunaria evidence is kept as it was.

| | Milo | Grace |
|---|---|---|
| Replaces (for validation) | Andre Leone | Lunaria |
| Raw source-quality gate | **PASS** | **FAIL**: persistent hiss |
| Character gate | founder's ear (measured pace is normal) | not evaluated (the gate failed) |
| Master | restrained, one voice-wide gain | **not created** |

## 1. Exact voice IDs (read-only check, 2026-10-14)

| | Milo | Grace |
|---|---|---|
| Voice ID | `GUDYcgRAONiI1nXDcNQQ` ✔ exact | `mZTVERjx1WQkdAWt1Lcm` ✔ exact |
| ElevenLabs name (internal only) | Milo - Calm, Soothing and Meditative | Grace - warm, velvety meditation voice |
| Category | professional (PVC, shared library) | professional (PVC, shared library) |
| In account | yes (`copied`) | yes (`copied`) |
| Library rate | 1.0 (no surcharge) | 1.0 (no surcharge) |
| Free users allowed | yes | **no (paid plans only)**, like Heather |
| Notice period | 730 days | 730 days |
| Live moderation | off | off |
| Commercial restriction in library settings | none | none |
| `eleven_multilingual_v2` fine-tuned (high-quality base model) | **NO** ⚠ | yes ✔ |
| Catalogue labels | American, male, middle-aged, "relaxed", narrative/story | American, female, **young**, "calm", conversational |

- **Milo — model compatibility:**
  - His professional clone is fine-tuned for `eleven_turbo_v2_5`, `eleven_flash_v2_5`, `eleven_turbo_v2`, `eleven_flash_v2` and `eleven_v4*`, but **not** for the frozen production model `eleven_multilingual_v2`. All four earlier voices were.
  - The API generated all five clips on `eleven_multilingual_v2` without error.
  - **What may follow:** these clips may not be his full-fidelity, fine-tuned rendering, and may sound different from his library preview.
  - **Settings were not changed** to work around this, per the brief.
  - **This is a founder decision** whatever the listening result.
- **Commercial use:** both are available on the founder's paid plan, with no library-level restriction. The plan's commercial licence still has to be confirmed on the billing page; the key cannot read the subscription. This is the same open item as before.

Evidence: `verification_raw.json`.

## 2. Generation — identical to the 2026-10-12 batch

| Setting | Value |
|---|---|
| Route | direct ElevenLabs API, founder's paid account. The key is read from the user environment and never printed or stored |
| Model | `eleven_multilingual_v2` |
| Stability / Similarity / Style | 0.5 / 0.75 / 0.0 |
| Speaker boost | on |
| Speed | 1.0 |
| Seed | 30 (fixed, the same as the earlier batch) |
| Output format | `mp3_44100_128` (the best this plan allows) |
| Text | the manifest script verbatim; one request per clip; no context stitching |
| Cost | 10 requests, **824 characters** (412 per voice) |

Per-clip request IDs are in `generation_log.json` and in `<voice>/generation_settings.json`. Raw hashes are in `<voice>/RAW_SHA1.txt`.

## 3. Raw source-quality gate — BEFORE any gain, limiting or transcode

- **Material:** the untouched MP3s, decoded to float only.
- **Comparison set:** all six voices measured by the same code (`tools/raw_source_gate.py`, `tools/pause_floor.py`, `tools/grace_pauses.py`).
- **Method:** the pooled floor is the 2026-10-13 diagnostic method. It reproduces the earlier figures within about 1 dB: Locke 64.3 against 64.7, Heather 53.9 against 53.5, Andre 34.1 against 34.8, Lunaria 38.9 against 40.1.

| Voice (status) | Raw speech loudness | Pooled floor (p5) | **Loudness-to-floor** | Pause noise under loudness¹ | Pause steadiness (s.d.)² | Noise >4 kHz share³ | Last 150 ms of file⁴ |
|---|---|---|---|---|---|---|---|
| **Milo** (candidate) | −20.2 LUFS | −82.3 dBFS | **62.2 dB** | 60.0 dB | 7.4 dB (no steady bed) | −7.5 dB | −58.3 dB |
| **Grace** (candidate) | **−43.2 LUFS** | −76.9 dBFS | **33.7 dB** | **31.5 dB** | **2.0 dB (steady)** | **−7.6 dB (hiss)** | **−35.2 dB** |
| Locke (approved) | −27.0 | −91.3 | 64.3 | 52.8 | 8.7 | −22.5 | −49.3 |
| Heather (approved) | −20.5 | −74.4 | 53.9 | 37.6 | 3.6 | −12.0 | −40.6 |
| Andre Leone (rejected) | −30.2 | −64.3 | 34.1 | 30.0 | 2.6 | −32.6 (rumble) | −33.1 |
| Lunaria (rejected) | −28.2 | −67.1 | 38.9 | 37.2 | 1.8 | −19.6 | −41.4 |

**Notes on the columns:**
1. **Pause noise:** the median level of inter-word pauses (runs of 120 ms or more, 20 dB or more under speech), relative to clip loudness. This column over-reads voices with short, breathy pauses (Heather), so the pooled ratio stays the primary figure.
2. **Steadiness:** the s.d. of the 20 ms frames inside each pause. A low value means a constant bed: room tone or hiss, not natural decay.
3. **>4 kHz share:** the share of pause energy above 4 kHz. A high value means hiss.
4. **Last 150 ms of file:** the ambience after speech, relative to loudness.

### Milo — PASS

- **Floor:** 62.2 dB under speech, between Locke (64.3) and Heather (53.9), and about 25 dB cleaner than Andre or Lunaria.
- **Pauses:** they fall to about −81 dBFS. There is no steady bed: their s.d. of 7.4 dB is like Locke's 8.7, not Andre's or Lunaria's 2–3 dB.
- **File tails:** his post-speech tails are the cleanest of all six voices, at −58 dB.
- **Defects:** no clipping (sample peak −2.0 dBFS or lower) and no tonal hum. The noise spectrum is broad and very low.
- **To listen for — clipped onsets:**
  - every Milo clip starts speech within 40 ms of the file start, so the trim keeps the file start;
  - `part_getItOut` has energy at −55 dBFS in its first 10 ms;
  - **listen to the "G" of "Get it out"**, in the as-generated file and in the mastered file.
- **Endings:** not clipped; each has 130–240 ms of quiet tail.

### Grace — FAIL (persistent hiss in the raw source)

- **The output is very quiet:** about 20 dB below every other voice (−43 LUFS, true peak −25 dBTP), in all five clips.
- **The noise is constant:** a steady broadband bed under every pause of every clip, at about −75 to −77 dBFS.
- **Ratio:** only **33.7 dB** under her speech, the same as rejected Andre (34.1) and worse than rejected Lunaria (38.9).
- **It is hiss:** its >4 kHz share (−7.6 dB) is the highest of all six voices. Andre's noise was rumble; Grace's is air and hiss.
- **No way around it:** reaching the level of the approved voices needs **+21.3 dB of gain**, which puts the hiss at about −54 dBFS in the pauses. That is louder than the Guarded Andre floor (−57.9) that the founder already heard as noise.
- **Why the as-generated file sounds clean:** it is so quiet that the hiss is inaudible at normal volume.
  - **To confirm by ear:** use `grace/grace_DIAGNOSTIC_level_matched_gain_only.m4a`. It is one linear gain, with no limiter and nothing else, so it plays at Locke's and Heather's level.
  - **This file is not a master.**

**Pace (a measured proxy, not a character verdict):** Grace speaks at 1.88 words/s. Locke speaks at 2.57, Heather 2.41 and Milo 2.60. Her four spoken clips last 44 s, against 31–33 s for the approved voices. That is consistent with her catalogue "slow, unhurried cadence" and is a meditation-pacing risk. It is moot, because the gate failed.

## 4. Character

**Claude cannot listen**, so character is the founder's judgement.

- **Milo — measured only:**
  - **Pace:** 2.60 words/s, the same as Locke, so not slowed or sleepy by pace.
  - **Catalogue:** describes him as "soothing, relaxed… for meditation, bedtime stories".
  - **Listen for:** sleepy, guru-like, overly soft, therapeutic, ASMR-like or paternal.
  - **And:** whether the non-fine-tuned model rendering sounds less natural than his library preview.
- **Grace:** not evaluated, because the raw source gate failed. Her catalogue age label is "young", against the brief's target of "adult".

## 5. Mastering — Milo only (`tools/master_replacements.py`)

**The rule:**
- trim to speech (−50 dBFS, 40 ms margin);
- **a 10 ms raised-cosine fade at each trim edge;**
- outlier correction only, into a ±2 LU window around the median part;
- **ONE voice-wide gain** to a −22 LUFS take, the level of the approved masters;
- peak safety only: a 4× look-ahead limiter at −2 dBFS, **delay-compensated** (`latency=1`; the self-check gives 0 samples of lag);
- 150 ms lead-in and 700/400 ms tails;
- AAC-LC at 128 kbit/s.

**Not used:** denoise, spectral processing, expanders, compression or EQ.

**Result:**
- **Gain:** one gain of **−1.99 dB** for all five clips.
- **Outlier corrections:** none. The parts span 2.0 LU and sit inside the window.
- **Limiter:** never engaged. The worst pre-limit true peak was −4.0 dBTP.

| Clip | Raw (trimmed) | Final | True peak |
|---|---|---|---|
| lead_first | −18.10 | −22.03 | −4.08 |
| part_getItOut | −19.78 | −21.84 | −4.27 |
| part_briskWalk | −21.37 | −23.64 | −4.48 |
| part_warmDrink | −20.16 | −22.38 | −6.14 |
| close | −19.33 | −21.19 | −5.22 |
| **Listening take** | −20.17 (as generated) | **−22.15 LUFS** | −4.08 |

- **The spread is kept on purpose:** the natural 2.4 LU spread between clips is preserved, not flattened.
- **Comparison level:** the take sits within 0.2 LU of the approved Locke and Heather masters (−21.96 and −21.95).

## 6. Listening files

| Voice | File | What it is |
|---|---|---|
| Milo | `milo/milo_listen_mastered.m4a` | **The restrained master**: compare it with `../locke/locke_listen_mastered.m4a` and `../heather/heather_listen_mastered.m4a` at one fixed volume |
| Milo | `milo/milo_listen_as_generated.m4a` | Untouched ElevenLabs take (container only) |
| Milo | `milo/mastered_clips/*.m4a` | The five mastered clips, with production file names |
| Milo | `milo/raw/*.mp3` | The five untouched API outputs |
| Grace | `grace/grace_DIAGNOSTIC_level_matched_gain_only.m4a` | **Gate confirmation only:** gain-only at the approved level. Listen in the pauses |
| Grace | `grace/grace_listen_as_generated.m4a` | Untouched take: very quiet, so the hiss is masked |
| Grace | `grace/raw/*.mp3` | The five untouched API outputs |

Each voice folder also has `generation_settings.json`, `source_quality.json` and `RAW_SHA1.txt`.

## Status

- **The 168 production clips:** NOT AUTHORIZED.
- **Milo:** pending the founder's listening and approval, plus a decision on the `eleven_multilingual_v2` fine-tune gap.
- **Grace:** fails the raw source gate. A founder decision is needed, and no substitute was generated or searched for.
- **D2:** NOT COMPLETE.
- **Phase E:** HOLD.

## Founder decision — 2026-10-16

- **Milo: APPROVED.** The founder listened to the real THIRTY validation output and approved it. The missing `eleven_multilingual_v2` fine-tune metadata is **not a blocker**: the frozen-model output generated successfully and passed the raw source gate.
- **Female voice #2: OPEN.** We wait for the founder's next exact voice ID; no search is made.
- **Rejected:**
  - Andre Leone: source noise.
  - Lunaria: source noise.
  - Grace: source hiss and insufficient source level.
  - Anastasia: persistent room tone (`anastasia/`).
  - Nicole: persistent room tone and hiss, plus a clipped onset (`nicole/`). It is not to be repaired, denoised or regenerated.
- **Final-intent set:** Locke, Heather and Milo APPROVED; female #2 OPEN.
- **The 168 production clips:** NOT AUTHORIZED.
- **D2:** NOT COMPLETE.
- **Phase E:** HOLD.

## Founder correction — 2026-10-16 (Brittney, and the noise method)

- **Brittney:** FOUNDER SOURCE-QUALITY PASS, which overrules the automatic gate's false positive (a sub-bass residual around 32 Hz). The restrained master is in `brittney/`. **Final mastered listening approval is PENDING.**
- **The noise method is corrected:** see `NOISE_GATE_METHODOLOGY.md`. Measurements are diagnostic, and founder listening is the final perceptual gate.
- **Rejected:**
  - Andre Leone and Lunaria: the founder heard noise.
  - Grace: source hiss and insufficient source level.
  - Anastasia: by measurement; not reopened.
  - Nicole: source issues, including a clipped onset.
- **The 168 production clips:** NOT AUTHORIZED.
- **D2:** NOT COMPLETE.
- **Phase E:** HOLD.

## Founder decision — 2026-10-16: final four voices locked

- **Brittney: APPROVED.** The founder listened to the restrained mastered validation (`brittney/brittney_listen_mastered.m4a`) and approved her for production. Her automatic raw-noise FAIL was a false positive (~32 Hz sub-bass measured unweighted).
- **Launch set, all FOUNDER APPROVED:** Locke, Heather, Milo and Brittney. See `../FINAL_VOICE_SET.md`.
- **Voice selection: CLOSED.** No further search. Rejected voices are reopened only if a concrete later production defect forces a replacement.
- **Rejected:**
  - Andre Leone and Lunaria: founder-confirmed audible source noise.
  - Grace: source hiss and insufficient source level.
  - Anastasia: not selected.
  - Nicole: source issues, including a clipped onset.
- **Approved-output hashes:** `APPROVED_MILO_BRITTNEY_SHA1.txt`, alongside `../APPROVED_LOCKE_HEATHER_SHA1.txt`.
- **QA methodology and production mastering rules:** frozen in `NOISE_GATE_METHODOLOGY.md` § Production freeze.
- **The 168 production clips:** blocked **only** by the founder's commercial-licence confirmation.
- **D2:** NOT COMPLETE.
- **Phase E:** HOLD.
