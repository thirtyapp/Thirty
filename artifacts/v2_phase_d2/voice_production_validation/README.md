# Production-voice validation — 4 voices × 5 clips (REVIEW ONLY, NOT BUNDLED)

> **Status, 2026-10-13:**
> - **Locke and Heather:** KEEP, with their approved masters.
> - **Andre Leone and Lunaria:** REPLACED, because the source background noise is intrinsic. Their files stay here as audit evidence only; see `noise_diagnostic/README.md`.
> - **Replacement candidates, 2026-10-14:** see `replacements/README.md`.
>   - **Milo:** passes the raw source gate; pending the founder.
>   - **Grace:** fails it, on persistent hiss.

**What this is:**
- **Not an audition:** the founder selected the four launch voices. This batch validates the production pipeline — generation, settings and mastering — on 5 canonical clips per voice, before the full pack of 168 clips is generated.
- **Not in the app:** nothing here is bundled, and `pubspec.yaml` is unchanged.

**Generated:** 2026-10-12, 19:22 CEST.

## Route

**Direct ElevenLabs API**, on the founder's own paid account. No vidIQ intermediary.
- **API key:** read from the Windows user environment at run time. It was never printed, logged or written to disk or to the repository. Its permissions do not include `user_read` or `models_read`, so the plan tier was not read directly.
- **Plan evidence:**
  - The API refused `pcm_44100` ("Pro tier and above") and `mp3_44100_192` ("Creator tier and above"). The account is therefore below Creator.
  - It generated with Heather, whose library entry has `free_users_allowed: false`. The account is therefore a paid plan — consistent with **Starter**.
  - **To confirm:** the commercial licence of that plan, on the account's billing page (ElevenLabs' published terms grant one on paid plans).
- **Runtime:** none. The output is fixed local audio.
- **Cost:** 20 requests, **1,648 characters**. Every voice's library rate is **1.0**, so there is no surcharge.

## The four voices (verified by exact ID, 2026-10-12)

| THIRTY label | ElevenLabs voice ID | Name in ElevenLabs (internal only) | Category | In account | Library rate | Notice period | Free users allowed | Live moderation | `eleven_multilingual_v2` |
|---|---|---|---|---|---|---|---|---|---|
| **Locke** — Calm & gentle | `oaLGpwm7fYWDEFmlRuQk` | Locke - Calm, Meditative and Gentle | professional (PVC, shared library) | added (`copied`) | 1.0 | 730 days | yes | off | high-quality base model ✔ |
| **Andre Leone** — Deep & grounded | `kXuFAM1KXqJVbauKJc2Z` | Andre Leone- Deep Healing Voice | professional | added | 1.0 | 730 days | yes | off | ✔ |
| **Lunaria** — Soft & serene | `Nyip1VgoS6bg9Vl30y8v` | Lunaria - Calm Meditations and Manifestations | professional | added | 1.0 | 730 days | yes | off | ✔ |
| **Heather** — Warm & textured | `plP9aw1rizYgjFfuvLQ7` | Heather - Warm, Raspy American Female | professional | added | 1.0 | 730 days | **no (paid plans only)** | off | ✔ |

- **Availability:** all four are available, and none is commercially restricted by its library settings.
- **Notice period:** 730 days means that if an owner withdraws a voice, the account keeps access for two years. Bundled files are fixed and unaffected.
- **Internal names:** they are for this record only. They never appear in the app.

## Generation settings (identical for all four voices)

| Setting | Value |
|---|---|
| Model | `eleven_multilingual_v2` — ElevenLabs' high-quality, non-low-latency model; a high-quality base model for all four voices |
| Stability | 0.5 |
| Similarity | 0.75 |
| Style | 0.0 |
| Speaker boost | on |
| Speed | 1.0 |
| Seed | 30 |
| Output format | `mp3_44100_128`: the best the plan allows. 192 kbit/s needs Creator; PCM needs Pro |
| Text | exactly the manifest script, one request per clip, without context stitching |

Per-clip request details are in `generation_log.json`. Scripts come verbatim from `../SPOKEN_GUIDANCE_MANIFEST.csv`:

| Clip | Script |
|---|---|
| `lead_first` | "First." |
| `part_getItOut` | "Get it out. Write down everything on your mind, without sorting. When you run dry, ask what else is nagging at you." |
| `part_briskWalk` | "A brisk walk. Head out. Start easy, then walk briskly — at a pace you can still talk at. Turn back about halfway." |
| `part_warmDrink` | "A slow warm drink. Make a warm drink you’d enjoy. Hold the cup in both hands, and drink it slowly, with your phone face down." |
| `close` | "That’s your Circle. Take a moment before you move on." |

## Mastering (one rule for every clip of every voice)

1. **Trim** to speech: a −50 dBFS envelope, keeping a 40 ms margin.
2. **Linear gain** so that each clip's integrated loudness is **−22 LUFS**.
3. **True-peak safety only:** a 4×-oversampled look-ahead peak limiter at −2 dBFS (5 ms attack, 60 ms release). No compression, no EQ, no other processing.
4. **Silence:** 150 ms lead-in; tail 700 ms after a lead ("First." → part), 400 ms after a part or the close.
5. **Encoding:** AAC-LC `.m4a`, mono, 44.1 kHz, 128 kbit/s. File names are fingerprinted exactly as the app expects (`part_getItOut_a239320e.m4a`).

**Why −22 LUFS, not the −16 first proposed:**
- These voices have a very high crest factor: their peaks are 14–24 dB above their loudness.
- **At −16:** Lunaria and Andre Leone would need 7–9 dB of limiting — audibly squashed.
- **With no limiting at all:** the common target could be no higher than −25 LUFS, which is too quiet.
- **At −22:** 7 of the 20 clips touch the limiter, by at most 3.6 dB on isolated peaks, and 13 are untouched.
- **Rejected before this:** one gain per voice left the voices 6.4 LU apart, because ElevenLabs generates each request at its own level (up to 10 LU apart within one voice). Per-clip normalisation is the rule that makes "one coherent session" true.

## Measured results (encoded files; EBU R128 via ffmpeg)

| Voice | Listening file as generated | Gain range applied | Limiter (max) | Mastered listening file | True peak (mastered, worst clip) |
|---|---|---|---|---|---|
| Locke | −26.95 LUFS, TP −7.99 | +2.8 … +5.7 dB | none | **−21.96 LUFS** | −2.69 dBTP |
| Andre Leone | −29.64 LUFS, TP −6.04 | +4.8 … +10.5 dB | 0.8 dB (2 clips) | **−22.15 LUFS** | −1.64 dBTP |
| Lunaria | −27.86 LUFS, TP −5.34 | +0.1 … +7.3 dB | 3.6 dB (4 clips) | **−21.99 LUFS** | −1.96 dBTP |
| Heather | −18.74 LUFS, TP −1.53 | −5.4 … +5.6 dB | none | **−21.95 LUFS** | −3.15 dBTP |

- **Spread of the mastered listening files:** 0.20 LU.
- **Every part and close clip:** −22 ± 0.5 LUFS, at or below −1.5 dBTP. No clipping.
- **The "First." clips** read −23 to −24 LUFS. This is a measurement effect of a one-word clip in padded silence; their gain was set on the speech itself by the same rule.
- **Per-clip details:** `loudness_report.json`.

## Not judged by Claude

Claude cannot listen.
- **Measured:** loudness, peaks, durations and silences.
- **Not judged:** character, naturalness, pronunciation, clipped phonemes, or whether a voice drifts toward sleepy, guru-like, therapeutic, mystical, ASMR or theatrical.
- **Watch for:** several raw clips begin speech within 40 ms of the file start (`trimmed_head_s: 0`). Listen for a clipped first sound.

## Files to listen to

For each voice:
- `<voice>/<voice>_listen_mastered.m4a` — the five clips mastered and in sequence ("First." runs straight into "Get it out", as in THIRTY). **Compare the voices with this one.**
- `<voice>/<voice>_listen_as_generated.m4a` — the same, as ElevenLabs returned it (unmastered).
- `<voice>/*.m4a` — the five mastered clips, with production file names.
- `<voice>/raw/*.mp3` — the API output, untouched.

## Final launch voice set (founder, 2026-10-16)

**Locke, Heather, Milo and Brittney are FOUNDER APPROVED; voice selection is CLOSED.** Andre Leone and Lunaria were replaced. See `FINAL_VOICE_SET.md`.
