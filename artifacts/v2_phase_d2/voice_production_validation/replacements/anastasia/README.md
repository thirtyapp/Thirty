# Anastasia — female replacement validation (2026-10-16; REVIEW ONLY, NOT BUNDLED)

**What this is:**
- **The candidate:** the founder supplied one exact voice ID for the female slot of the rejected Grace / Lunaria. Nicole was superseded before validation and was not generated.
- **What was generated:** only the five canonical validation clips.
- **The 168-clip pack is NOT AUTHORIZED.**
- **Untouched:** `pubspec.yaml`, Locke, Heather, Milo, Grace, Andre and Lunaria evidence. The approved Locke/Heather hashes still match `../../APPROVED_LOCKE_HEATHER_SHA1.txt`, and the Milo and Grace raw hashes still match their `RAW_SHA1.txt`.

| Gate | Result |
|---|---|
| Exact voice | ✔ available, no restriction |
| Raw source quality | **FAIL**: a persistent low broadband bed (room tone), about 50 dB under speech |
| Character | not evaluated (the gate failed) |
| Master | **not created** |

## 1. Exact voice (read-only check, `verification_raw.json`)

| | |
|---|---|
| Voice ID | `ckKmfA55w4oOeREP60LL` ✔ exact (the only library match) |
| ElevenLabs name (internal only, never product copy) | Anastasia - Soft Soothing Meditation |
| Category | professional (PVC, shared library) |
| In account (My Voices) | **no**. See below |
| Library rate | 1.0 (no surcharge; no fiat rate) |
| Free users allowed | yes (no paid-plan requirement) |
| Notice period | 730 days |
| Live moderation | off |
| Commercial restriction in library settings | none |
| `eleven_multilingual_v2` | **verified** in the library's verified-language list (en-US). Milo's list lacked it, Grace's had it, and in both cases the list matched the account-level fine-tune field |
| Catalogue labels | American, female, **young**, "gentle", narrative/story |

**Account state:**
- **Not added:** the voice is not in My Voices. Adding it needs the `voices_write` permission, which the API key lacks, so nothing in the account was changed.
- **Generation still worked:** text-to-speech accepted the exact library ID directly.
- **Fine-tune field unreadable:** because the voice is not in the account, `high_quality_base_model_ids` cannot be read. The model status above comes from the library record.
- **Commercial licence:** the plan's licence still has to be confirmed on the billing page. This is the same open item as before.

## 2. Generation — identical to the 2026-10-12 and 2026-10-14 batches

| Setting | Value |
|---|---|
| Route | direct ElevenLabs API, founder's paid account. The key is read from the user environment and never printed or stored |
| Model | `eleven_multilingual_v2` |
| Stability / Similarity / Style | 0.5 / 0.75 / 0.0 |
| Speaker boost | on |
| Speed | 1.0 |
| Seed | 30 (fixed, the same as every earlier batch) |
| Output format | `mp3_44100_128` |
| Text | the manifest script verbatim, one request per clip, no context stitching |
| Cost | 5 requests, **412 characters** |

Request IDs are in `generation_log.json` and `generation_settings.json`. Raw hashes are in `RAW_SHA1.txt`. Tools: `../tools/generate_anastasia.py`, `verify_anastasia.py`, `anastasia_gate.py`, `anastasia_bed.py`, `anastasia_files.py`.

## 3. Raw source-quality gate — untouched MP3s, decoded to float only

**Method:** the same code as the 2026-10-14 gate (`raw_source_gate.analyse`, `pause_floor`, the 20 dB pause rule). All seven voices were re-measured together, and the reference figures reproduce the 10-14 report exactly.

| Voice (status) | Raw speech | Pooled floor (p5) | **Loudness-to-floor** (frozen metric) | Deepest bed (p1) | **Bed under speech** | Bed at the −22 LUFS take level | Pause s.d. | Noise >4 kHz |
|---|---|---|---|---|---|---|---|---|
| **Anastasia** (candidate) | −26.2 LUFS | −68.4 | **42.2 dB** | −76.3 | **50.1 dB** | **≈ −72 dBFS** | 5.3 | −13.4 |
| Locke (approved) | −27.0 | −91.3 | 64.3 | −91.5 | 64.5 | ≈ −86.5 | 8.7 | −22.5 |
| Heather (approved) | −20.5 | −74.4 | 53.9 | −88.3 | 67.8 | ≈ −89.3 | 3.6 | −12.0 |
| Milo (technical pass) | −20.2 | −82.3 | 62.2 | −83.8 | 63.6 | ≈ −85.6 | 7.4 | −7.5 |
| Andre Leone (rejected) | −30.2 | −64.3 | 34.1 | −66.6 | 36.4 | ≈ −58.0 (Guarded: −57.9) | 2.6 | −32.6 |
| Lunaria (rejected) | −28.2 | −67.1 | 38.9 | −68.9 | 40.7 | ≈ −62.9 | 1.8 | −19.6 |
| Grace (rejected) | −43.2 | −76.9 | 33.7 | −77.8 | 34.6 | ≈ −56.5 | 2.0 | −7.6 |

**Findings:**
- **The frozen metric puts her in the rejected cluster.** Her 42.2 dB is 3.3 dB from Lunaria (38.9), but 11.7 dB from Heather (53.9) and 20 dB from Milo and Locke.
- **The most favourable reading still isn't clear of it.** The p5 floor is inflated by her breathy pauses, as it is for Heather, so the true bottom is the p1 bed.
  - Her bed sits 50.1 dB under speech.
  - The rejected voices sit at 35–41 dB and the approved ones at 64–68 dB; the midpoint is about 51.
  - Even on this reading she is **not materially closer to Locke, Heather and Milo**. She sits at the middle, slightly on the rejected side.
- **The bed is persistent:** her post-speech tails settle flat at about −73 dBFS for 100 ms or more (for example −73.6, −73.2, −72.9, −73.5, −72.6). Every pause bottoms out at a median of −75.3 dBFS. The spectrum of the deepest frames is broadband (bands from 20 Hz to 22 kHz within 4 dB): room tone, not breath.
- **It is not hiss-dominated:** the >4 kHz share is −13.4 dB, against −7.6 dB for Grace. **Not rumble** either.
- **The bed is less steady than the rejected voices':** pauses carry breath and decay above it (pause s.d. 5.3 dB against 1.8–2.6 dB). The bed is underneath, not the whole pause.
- **At listening level:**
  - the gain needed is +4.15 dB, which puts the bed at about −72 dBFS;
  - that is 9–16 dB quieter than the rejected voices, which the founder heard as noise (−57 to −63);
  - but it is **14–17 dB noisier than every approved voice** (−86 to −89).
- **Other checks:**
  - **Clipping:** none. The highest true peak is −5.9 dBTP.
  - **Endings:** not clipped. There are 0.15–0.34 s of tail, and the last 10 ms sit at −83 dBFS or lower.
  - **Onset to check by ear:** `lead_first` starts 30 ms into the file, at −54 dBFS in its first 10 ms. Listen for a clipped "F" in "First."
  - **Generation artefacts:** none measurable. Claude cannot listen.

**Verdict:**
- **SOURCE QUALITY: FAIL.** The raw source is not materially closer to the approved set; on the frozen metric it is closer to the rejected set.
- **Its bed is persistent room tone.** It is lower than Andre's, Lunaria's or Grace's, but it is a constant bed that the approved voices do not have.
- **Not rescued:** no denoise, expander, isolator, EQ, compression or limiting was tried.

**To confirm by ear:** play `anastasia_DIAGNOSTIC_level_matched_gain_only.m4a` and listen in the pauses and the gaps. It is one linear gain of +4.15 dB to −22.03 LUFS, with no limiter and nothing else, so it plays at the same level as `../../locke/locke_listen_mastered.m4a`, `../../heather/heather_listen_mastered.m4a` and `../milo/milo_listen_mastered.m4a`. **This file is not a master.**

## 4. Character — not evaluated (the gate failed)

The only measured proxy is pace: **2.29 words/s**. That is slower than Locke (2.57), Heather (2.41) and Milo (2.60), but faster than Lunaria (2.12) and Grace (1.88). It does not read as sleepy by pace alone. The catalogue age label is "young", against the brief's target of "adult".

## 5. Files

| File | What it is |
|---|---|
| `raw/*.mp3` | The five untouched API outputs |
| `anastasia_listen_as_generated.m4a` | The untouched take (−26.17 LUFS; AAC container only) |
| `anastasia_DIAGNOSTIC_level_matched_gain_only.m4a` | **Gate confirmation only:** a gain-only copy at the approved level |
| `verification_raw.json` | The exact-ID check |
| `generation_log.json`, `generation_settings.json` | Settings and request IDs |
| `raw_source_gate.json` | Per-clip and per-voice gate measurements for all 7 voices |
| `floor_character.json` | Bed analysis: percentiles, pause minima, deepest-frame spectrum, tail traces |
| `source_quality.json` | All of the above, plus the result |
| `RAW_SHA1.txt` | Raw hashes |

## Status

- **The 168 production clips:** NOT AUTHORIZED.
- **Anastasia:** fails the raw source gate. A founder decision is needed; no substitute was searched for or generated.
- **D2:** NOT COMPLETE.
- **Phase E:** HOLD.

**Founder decision (2026-10-16):** Anastasia is REJECTED for persistent room tone.

**Founder voice-set lock (2026-10-16):** Anastasia is REJECTED and not selected. Voice selection is CLOSED. She is not to be reopened automatically.
