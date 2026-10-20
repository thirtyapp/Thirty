# Nicole — female candidate validation (2026-10-16; REVIEW ONLY, NOT BUNDLED)

**What this is:**
- **The candidate:** the founder supplied the exact ID after Anastasia was rejected on source quality.
- **What was generated:** only the five canonical validation clips. The 168-clip pack is **NOT AUTHORIZED**.
- **Untouched:** `pubspec.yaml` and all earlier voice evidence. The approved Locke/Heather hashes still match, and so do the Milo, Grace and Anastasia raw hashes.

| Gate | Result |
|---|---|
| Exact voice | ✔ available, no restriction |
| Raw source quality | **FAIL**: a steady broadband bed (hiss-leaning room tone), comparable to Anastasia's; plus a clipped start on `lead_first` |
| Character | not evaluated (the gate failed) |
| Master | **not created** |

## 1. Exact voice (read-only, `verification_raw.json`)

| | |
|---|---|
| Voice ID | `gc5LArFpEOmYx9nYmK9l` ✔ exact (the only library match) |
| ElevenLabs name (internal only) | Nicole - ASMR, Meditation, Hypnosis |
| Category | high_quality (shared library) |
| In account (My Voices) | no. The key lacks `voices_write`, so nothing was changed; TTS accepted the exact library ID |
| Library rate | 1.0 (no surcharge) |
| Free users allowed | **no (paid plans only)**, like Heather; the account is a paid plan |
| Notice period | 730 days |
| Live moderation | off |
| Commercial restriction in library settings | none (the plan licence on the billing page is still the same open item) |
| `eleven_multilingual_v2` | **verified** in the library's verified-language list. The account fine-tune field can't be read until she is added |
| Catalogue | American, female, middle-aged, "meditative", narrative/story: "gentle, intimate, and slightly sultry voice, whisper[s] its way into your senses" |

## 2. Generation — identical to the Milo, Grace and Anastasia batches

| Setting | Value |
|---|---|
| Model | `eleven_multilingual_v2` |
| Stability / Similarity / Style | 0.5 / 0.75 / 0.0 |
| Speaker boost | on |
| Speed | 1.0 |
| Seed | 30 |
| Output format | `mp3_44100_128` |
| Text | the manifest verbatim, one request per clip, no stitching |
| Cost | 5 requests, 412 characters |

Tools: `../tools/verify_nicole.py`, `generate_nicole.py`, `nicole_gate.py`, `nicole_bed.py`, `nicole_files.py`. These are the Anastasia tools with the ID swapped, plus Anastasia added as a rejected reference.

## 3. Raw source-quality gate — untouched MP3s, decoded to float only

| Voice (status) | Raw speech | Floor p5 | **Loudness-to-floor** (frozen) | Bed (p1) | **Bed under speech** | Bed steadiness (p10−p1) | Bed at −22 LUFS take level | Bed >4 kHz share |
|---|---|---|---|---|---|---|---|---|
| **Nicole** (candidate) | −23.2 LUFS | −75.8 | **52.6 dB** | −76.7 | **53.5 dB** | **1.8 dB** (constant) | **≈ −75.7 dBFS** | −6.1 |
| Locke (approved) | −27.0 | −91.3 | 64.3 | −91.5 | 64.5 | 0.4 | ≈ −86.5 | −7.0 |
| Heather (approved) | −20.5 | −74.4 | 53.9 | −88.3 | 67.8 | 27.3 (breath, no bed) | ≈ −89.3 | −3.1 |
| Milo (technical pass) | −20.2 | −82.3 | 62.2 | −83.8 | 63.6 | 2.6 | ≈ −85.6 | −5.4 |
| Anastasia (rejected) | −26.2 | −68.4 | 42.2 | −76.3 | 50.1 | 13.2 | ≈ −72.2 | −8.5 |
| Lunaria (rejected) | −28.2 | −67.1 | 38.9 | −68.9 | 40.7 | 3.3 | ≈ −62.9 | −18.4 |
| Andre Leone (rejected) | −30.2 | −64.3 | 34.1 | −66.6 | 36.4 | 3.7 | ≈ −58.0 | −27.4 |
| Grace (rejected) | −43.2 | −76.9 | 33.7 | −77.8 | 34.6 | 1.7 | ≈ −56.5 | −4.5 |

**For PASS:**
- **The frozen ratio:** 52.6 dB sits beside Heather's 53.9, and well clear of Andre, Lunaria and Grace (34–39).
- **Cleaner pauses than the breathy voices:** the 20 dB-rule pause noise is 46.1 dB under loudness, against Heather's 37.6.

**Against — why this is FAIL:**
- **Heather's comparable figure is not a bed.** Her p5 is breath; her real floor is −88 dBFS. Nicole's p5 *is* her floor: a **constant bed**.
  - It is flat to within 1.8 dB, with the same steadiness signature as Grace.
  - It sits at **−76.7 dBFS raw**, the same absolute level as Grace (−77.8) and Anastasia (−76.3).
  - Every post-speech tail settles flat on it (for example −75.3, −75.7, −75.0, −73.7, −72.0, −72.9).
  - Pauses bottom out on it: the pause median sits only 4.6 dB above the pause minimum.
- **Nicole's ratio is better only because her speech is louder,** not because her source is cleaner.
- **At listening level:**
  - her bed is about −75.7 dBFS;
  - that is **10–14 dB noisier than every clean voice** (Locke −86.5, Milo −85.6, Heather −89.3);
  - and within **3.5 dB of Anastasia (−72.2)**, who was rejected on this gate.
- **It is not "materially closer" to the clean voices** on the real bed: 53.5 dB under speech, against 63.6–67.8 for the clean voices and 50.1 for Anastasia.
- **Spectrum:** broadband with a strong high-frequency component (>4 kHz share −6.1 dB), so a hiss-leaning room tone.
- **In the app** each clip has digital-silence lead-ins and tails, so this bed would switch on and off at every clip boundary.

**Clipped start (generation artefact): `lead_first`.**
- Speech energy begins at the very first sample: −40 dBFS from 0 ms, with a non-zero first sample. Milo's file starts at −89 dBFS and Anastasia's at −55.
- The "F" of "First." is cut off at the file start, and the 10 ms edge fade could not restore it.

**Other checks:**
- **Clipped endings:** none (0.20–0.36 s of tail; the last 10 ms are −84 dBFS or lower).
- **Sample clipping:** none. The highest true peak is −4.2 dBTP.

**Verdict:**
- **SOURCE QUALITY: FAIL.** It has persistent broadband room tone and hiss at a level comparable to rejected Anastasia, and well above every clean voice.
- **Plus one clipped start.**
- **Not rescued:** no master, and no denoise, expander, EQ, compression or limiting was tried.

**To confirm by ear:** play `nicole_DIAGNOSTIC_level_matched_gain_only.m4a`.
- **What it is:** one linear gain of +1.01 dB to −22.01 LUFS, with no limiter, so it plays at the level of `../../locke/locke_listen_mastered.m4a`, `../../heather/heather_listen_mastered.m4a` and `../milo/milo_listen_mastered.m4a`.
- **Listen in the pauses,** and where the bed stops at the digital-silence gaps.
- **This file is not a master.**

## 4. Character — not evaluated (the gate failed)

The only measured proxy is pace: **1.54 words/s**. That is the slowest of all eight voices; Grace speaks at 1.88, the clean voices at 2.41–2.60. Her four spoken clips last **51.9 s**, against 31–33 s for the clean voices. That fits her "ASMR / Hypnosis / whisper" catalogue description, which is a direct match to the brief's rejection criteria (sleepy, ASMR-like, hypnotic). It is moot, because the gate failed.

## 5. Files

| File | What it is |
|---|---|
| `raw/*.mp3` | The five untouched API outputs |
| `nicole_listen_as_generated.m4a` | The untouched take (−23.02 LUFS) |
| `nicole_DIAGNOSTIC_level_matched_gain_only.m4a` | **Gate confirmation only:** a gain-only copy at the approved level |
| `verification_raw.json`, `generation_log.json`, `generation_settings.json` | The exact-ID check, settings and request IDs |
| `raw_source_gate.json`, `floor_character.json`, `source_quality.json` | Gate measurements for all 8 voices, the bed analysis and the result |
| `RAW_SHA1.txt` | Raw hashes |

## Status

- **The 168 production clips:** NOT AUTHORIZED.
- **Nicole:** fails the raw source gate.
- **The female slot:** open; the founder decides next. No other voice was searched for or generated.
- **D2:** NOT COMPLETE.
- **Phase E:** HOLD.

**Founder decision (2026-10-16):** Nicole is REJECTED, for persistent room tone and hiss plus the clipped onset. She is not to be repaired, denoised or regenerated.

**Founder voice-set lock (2026-10-16):** Nicole is REJECTED for source issues, including a clipped onset. Voice selection is CLOSED. She is not to be reopened automatically.
