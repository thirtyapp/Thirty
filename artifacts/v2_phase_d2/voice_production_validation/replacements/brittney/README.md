# Brittney — female replacement validation (2026-10-16; NOT YET BUNDLED)

**Status: FOUNDER APPROVED for production (2026-10-16).**
- **Basis:** the founder listened to the restrained master (`brittney_listen_mastered.m4a`, §5) and approved her.
- **Superseded:** the automatic raw-noise FAIL was a false positive, caused by unweighted measurement of mainly ~32 Hz sub-bass energy (§3). The founder heard no perceptible noise.
- **Approved output hashes:** `../APPROVED_MILO_BRITTNEY_SHA1.txt`.

*The earlier status lines, kept for the record:* source quality FOUNDER LISTENING PASS; measurement flag "low-frequency residual under investigation" (now resolved, §3); final mastered-listening approval PENDING (now given).

**What this is:**
- **The candidate:** the founder supplied the exact ID for the remaining female slot.
- **What was generated:** only the five canonical validation clips. The 168-clip pack is **NOT AUTHORIZED**.
- **Untouched:** `pubspec.yaml` and all earlier voice evidence. The approved Locke/Heather hashes, the Milo/Grace/Anastasia/Nicole raw hashes, and Milo's master outputs all still match.

**History:**
1. The first automatic gate (unweighted 20 ms frame floor) reported FAIL.
2. The founder listened to `brittney_DIAGNOSTIC_level_matched_gain_only.m4a` and heard it as extremely clean, with no perceptible background noise. **That overrules the automatic FAIL.**
3. §3 explains the false positive.

## 1. Exact voice (read-only, `verification_raw.json`)

| | |
|---|---|
| Voice ID | `pjcYQlDFKMbcOUp6F5GD` ✔ exact (the only library match) |
| ElevenLabs name (internal only, never product copy) | Brittney - Relaxing, Calm and Meditative |
| Category | high_quality (shared library) |
| In account (My Voices) | no. The key lacks `voices_write`; TTS accepted the exact library ID |
| Library rate | 1.0 (no surcharge) |
| Free users allowed | yes (no paid-plan requirement) |
| Commercial restriction in library settings | none (the plan licence on the billing page is still the same open item) |
| Notice period | **180 days**, against 730 for every earlier voice. Bundled files are unaffected by a withdrawal |
| Live moderation | **on** (earlier voices: off). It moderates generated text |
| `eleven_multilingual_v2` | verified in the library list (en and 10 other languages). The account fine-tune field can't be read until she is added |

## 2. Generation — identical to every earlier batch

| Setting | Value |
|---|---|
| Model | `eleven_multilingual_v2` |
| Stability / Similarity / Style | 0.5 / 0.75 / 0.0 |
| Speaker boost | on |
| Speed | 1.0 |
| Seed | 30 |
| Output format | `mp3_44100_128` |
| Text | the manifest verbatim, one request per clip |
| Cost | 5 requests, 412 characters |

## 3. Why the first gate gave a false positive (`perceptual_noise.json` / `.txt`)

**Method of the re-analysis (`../tools/perceptual_noise.py`):**
- every voice is scaled by one gain to the matched −22 LUFS listening level;
- the inter-word pauses are analysed with a 2048-point Welch PSD (21.5 Hz bins), plus an 8192-point pass for the low-frequency peak;
- reported are the unweighted level, the **A-weighted level**, band-limited levels and the DC offset;
- the **quietest 10 % of pause windows** form the perceptual bed: the noise that is left when nothing else is sounding.

| Voice (founder status) | Quietest pauses, **A-weighted** | Same, unweighted | of which < 100 Hz | of which > 150 Hz | > 4 kHz | LF peak |
|---|---|---|---|---|---|---|
| Locke (approved) | −97.8 dB(A)FS | −86.2 | −86.6 | −96.9 | −99.4 | 11 Hz |
| Heather (approved) | −96.2 | −91.2 | −94.4 | −94.2 | −96.4 | 5 Hz |
| Milo (approved) | −90.1 | −84.7 | −89.0 | −87.4 | −91.5 | 86 Hz |
| **Brittney (heard clean)** | **−82.9** | **−53.6** | **−53.6** | **−79.0** | −88.3 | **32 Hz** |
| Nicole (rejected) | −77.9 | −72.7 | −76.1 | −75.4 | −81.7 | 11 Hz |
| Anastasia (rejected by measurement) | −72.9 | −70.2 | −79.6 | −71.0 | −80.3 | 145 Hz |
| Andre Leone (heard noise) | −68.9 | −56.2 | −59.2 | −62.1 | −86.5 | 118 Hz |
| Lunaria (heard noise) | −68.2 | −63.0 | −81.6 | −64.6 | −82.6 | 129 Hz |
| Grace (rejected) | −59.5 | −55.0 | −59.2 | −57.5 | −61.4 | 48 Hz |

(All levels are dBFS at the matched −22 LUFS listening level.)

**The cause:**

1. **Brittney's residual is sub-bass, not room tone or hiss.**
   - Essentially all of her unweighted pause energy is below 100 Hz (−53.6 dBFS out of −53.6).
   - It peaks at **32 Hz**, and about 80 % of the 0–150 Hz energy lies below 40 Hz.
   - Above 150 Hz her bed is −79 dBFS; above 4 kHz it is −88.
   - **It is not DC:** the DC offset is −79.7 dBFS, which is negligible.
2. **At 32 Hz hearing is very insensitive.** A-weighting discounts it by about 39 dB, which is why the same bed reads −82.9 dB(A).
   - That is **14 dB quieter than Andre and Lunaria**, whose noise the founder heard.
   - Phone speakers barely reproduce 32 Hz at all.
   - Their noise is different: it sits at 118–129 Hz, in the audible range (Andre's unweighted −56 is also mostly audible, at > 150 Hz −62).
3. **The first gate weighted every hertz equally.** It used full-band, unweighted 20 ms RMS frames, with the p1/p5 floor and the loudness-to-floor ratio.
   - A 32 Hz component therefore counted the same as audible noise.
   - The 20 ms frames give 50 Hz bins. The earlier "40–80 Hz" label was really the 50 Hz bin collecting 0–75 Hz energy through window leakage.
   - The "fluctuating tails" were the same artefact: the 31 ms period of a 32 Hz wave is longer than the frame, so frame RMS wobbles.
4. **Her low raw level amplified the error.** At −31.9 LUFS she needs +9.7 dB of gain, which lifts the inaudible sub-bass to a large unweighted number.
5. **Where the 32 Hz content comes from** cannot be established from the output alone. It could be a generation or codec low-frequency residual or the voice's training audio. Either way it is not audible at the matched level by the founder's test.

**What the measurement still says:** her A-weighted bed (−82.9) is 7–15 dB above Locke, Heather and Milo. That is a measured difference, not an audible one by the founder's listening test.

**Kept as evidence:** `raw_source_gate.json`, `floor_character.json` and `onset_and_rumble.txt` are kept unchanged as the record of the superseded automatic gate. Their "FAIL" is overruled.

## 4. Other source checks (unchanged, all clean)

- **Clipped starts: NO.** Every file begins on residual and speech rises after 10–40 ms.
- **Clipped endings: NO.** Each has 0.28–0.34 s of tail.
- **Sample clipping:** none. The raw true peak is −13.0 dBTP at most.
- **Generation artefacts:** none measured. Claude cannot listen.

## 5. Restrained master (`../tools/master_brittney.py`, `mastering_report.json`)

**The rule** is the same as Milo's:
- trim to speech (−50 dBFS, 40 ms margin);
- a 10 ms raised-cosine fade at each trim edge;
- outlier correction only, into a ±2 LU window around the median part;
- **ONE voice-wide gain** to a −22 LUFS take;
- a delay-compensated 4× limiter at −2 dBFS, only where needed (the self-check gives 0 samples of lag);
- 150 ms lead-in and 700/400 ms tails;
- AAC-LC at 128 kbit/s.

**Not used:** denoise, **high-pass**, EQ, compression or expander. There was no demonstrated audible benefit, so the 32 Hz residual was left as it is.

**Result:**
- **Gain:** one gain of **+9.56 dB** for all five clips.
- **Outlier corrections:** none (the parts span 2.0 LU).
- **Limiter:** never engaged; the worst pre-limit true peak was −3.48 dBTP.

| Clip | Raw (trimmed) | Final | True peak | Speech onset after trim edge | Energy removed by head fade |
|---|---|---|---|---|---|
| lead_first | −31.98 | −24.03 | −9.07 | 40 ms | −35.9 dB of the first 100 ms |
| part_getItOut | −32.23 | −22.89 | −4.54 | 40 ms | −49.2 dB |
| part_briskWalk | −32.13 | −22.76 | −3.49 | 20 ms | −50.0 dB |
| part_warmDrink | −30.69 | −21.24 | −4.22 | 40 ms | −39.6 dB |
| close | −32.68 | −23.31 | −4.99 | 45 ms | −35.7 dB |
| **Listening take** | −31.72 (as generated) | **−22.16 LUFS** | −3.58 | | |

- **Initial consonants:** in every clip, speech starts 20–45 ms after the trim edge. The 10 ms fade only shapes the residual before speech (−58 to −73 dBFS raw) and removes at most 0.03 % of the first 100 ms of energy. No consonant is touched. Still, listen to the "G" of "Get it out" and the "A" of "A brisk walk".
- **The spread is kept:** the natural 2.4 LU spread between clips is preserved.
- **Comparison level:** the take sits within 0.2 LU of Locke (−21.96), Heather (−21.95) and Milo (−22.15).

## 6. Listening files

| File | What it is |
|---|---|
| `brittney_listen_mastered.m4a` | **The restrained master**, for the founder's final listening approval |
| `brittney_listen_as_generated.m4a` | The untouched take (−31.72 LUFS) |
| `brittney_DIAGNOSTIC_level_matched_gain_only.m4a` | The gain-only file the founder judged clean |
| `mastered_clips/*.m4a` | The five mastered clips, with production file names |
| `raw/*.mp3` | The five untouched API outputs |
| References | `../../locke/locke_listen_mastered.m4a`, `../../heather/heather_listen_mastered.m4a`, `../milo/milo_listen_mastered.m4a` |

## Status

- **The 168 production clips:** blocked only by confirmation of the commercial licence.
- **Brittney:** FOUNDER APPROVED (2026-10-16).
- **D2:** NOT COMPLETE.
- **Phase E:** HOLD.
