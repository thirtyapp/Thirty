# Andre Leone / Lunaria — mastering review (2026-10-12)

**What this is:**
- **Requested by:** the founder's listening result.
  - Locke and Heather: current masters **approved**.
  - Andre Leone and Lunaria: current masters **rejected**. The as-generated versions sounded better, and Andre's master "sounds like two volume levels".
- **No generation:** nothing was regenerated and no ElevenLabs credits were used. Everything here is built from the existing raw clips in `../<voice>/raw/`.
- **Nothing replaced:** the earlier masters stay where they were, as evidence.

## Listen to these (same 5 canonical clips, same order, "First." straight into its part)

| File | What it is |
|---|---|
| `andre_as_generated.m4a` | **A** — exactly as ElevenLabs returned it |
| `andre_voice_wide.m4a` | **B** — one gain for every clip; every within-voice level relationship kept |
| `andre_guarded.m4a` | **C** — only the outliers nudged, then one gain |
| `lunaria_as_generated.m4a` | **A** |
| `lunaria_voice_wide.m4a` | **B** |
| `lunaria_guarded.m4a` | **C** |

- **Loudness:** B and C sit at the same overall loudness (≈ −23.2 LUFS), so they differ in shape, not level. That is about 1.2 LU under the approved Locke and Heather (−22.0): a small offset that can be changed voice-wide if wanted.
- **A is much quieter** (Andre −29.6 LUFS, Lunaria −27.9), because it is raw. Compare it by character, not volume, or turn the phone up for it.
- **Per-clip files with production names:** `*_voice_wide_clips/` and `*_guarded_clips/`.

## What was done (no compression, no EQ in any variant)

- **A, as generated:** the raw clips, concatenated.
- **B, voice-wide:**
  - production silence handling: trim, then 150 ms before, 700 ms after a lead, 400 ms after a part or the close;
  - then one gain for the whole voice.
- **C, guarded:**
  - production silence handling, as in B;
  - a clip more than **2 LU** from the voice's median part level moves just to the edge of that ±2 LU window; every clip inside the window is left exactly as generated;
  - then one gain.
- **Peak safety in B and C:** the same 4× look-ahead limiter at −2 dBFS, engaged only where a clip's peaks would otherwise exceed it.

### Andre Leone (median part level, raw: −30.70 LUFS)

| Clip | Raw | Current master (rejected): gain / limiter | B: gain / limiter → level | C: correction + gain / limiter → level |
|---|---|---|---|---|
| lead_first | −26.90 | +4.90 / 0 | +6.50 / 0 → −21.8 | −1.80 +5.62 / 0 → −22.7 |
| part_getItOut | −26.75 | +4.75 / 0.7 | +6.50 / **2.5** → −20.6 | −1.95 +5.48 / 1.4 → −21.5 |
| part_briskWalk | −31.51 | **+9.51** / 0.8 | +6.50 / 0 → −25.1 | 0 +7.42 / 0 → −24.2 |
| part_warmDrink | −32.51 | **+10.51** / 0 | +6.50 / 0 → −26.2 | 0 +7.42 / 0 → −25.3 |
| close | −29.88 | +7.88 / 0 | +6.50 / 0 → −23.8 | 0 +7.42 / 0 → −22.8 |

**Clip-to-clip spread:**
- as generated: 5.8 LU;
- B: 5.6 LU, the natural shape;
- C: 3.8 LU;
- rejected master: 0.2 LU, forced.

### Lunaria (median part level, raw: −28.11 LUFS)

| Clip | Raw | Current master (rejected): gain / limiter | B: gain / limiter → level | C: correction + gain / limiter → level |
|---|---|---|---|---|
| lead_first | −22.07 | +0.07 / 0 | +4.76 / 0 → **−18.4** | **−4.04** +0.89 / 0 → −22.2 |
| part_getItOut | −28.30 | +6.30 / **2.9** | +4.76 / 1.4 → −23.6 | 0 +4.93 / 1.6 → −23.5 |
| part_briskWalk | −27.91 | +5.91 / 1.0 | +4.76 / 0 → −23.1 | 0 +4.93 / 0 → −23.0 |
| part_warmDrink | −29.27 | +7.27 / **3.6** | +4.76 / 1.1 → −24.8 | 0 +4.93 / 1.2 → −24.6 |
| close | −27.46 | +5.46 / 0.5 | +4.76 / 0 → −22.8 | 0 +4.93 / 0 → −22.7 |

- **The only outlier is "First.":** generated 6 LU louder than Lunaria's parts. In B it stays 5 LU proud of them; C brings it within 2 LU.

**Trade-off in B and C:** the limiter still engages on Andre's "Get it out" (2.5 dB in B, 1.4 dB in C) and on Lunaria's two most dynamic parts (1.1–1.6 dB). Without any limiting, the clean ceiling would be about −25 LUFS for Andre and about −24 for Lunaria — 2–3 LU under Locke and Heather.

Locke and Heather are unchanged. Their approved masters are fingerprinted in `../APPROVED_LOCKE_HEATHER_SHA1.txt`; the mastering is byte-deterministic (verified across two runs).
