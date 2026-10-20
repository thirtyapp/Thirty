# Raw-source noise check — corrected methodology (2026-10-16)

## Why it changed

**What happened:**
- The first automatic gate rejected Brittney.
- The founder then heard her level-matched file as clean.

**Why the gate got it wrong:**
- The gate measured full-band, **unweighted** 20 ms RMS frames (p1/p5 floor and the loudness-to-floor ratio).
- That treats a 32 Hz sub-bass residual exactly like audible room tone or hiss.
- Detail and numbers are in `brittney/README.md` §3.

## The product rule (founder, 2026-10-16)

**Measurements are diagnostic evidence; founder listening is the final perceptual gate.**

**A source voice is rejected when any of these holds:**
- its noise is perceptible at the matched listening level;
- it has another audible source-quality defect;
- it has a concrete clipping or generation defect, for example Nicole's clipped onset.

**A measurable but inaudible residual is not, by itself, a rejection.**

## Method for the next candidate

1. **Generate** the five canonical clips with the frozen settings, unchanged.
2. **Hard defects**, by measurement and kept as before:
   - sample clipping;
   - speech energy at the file's first sample (clipped onset);
   - a cut-off ending;
   - true-peak overs.
3. **Noise evidence at the matched level.** Use `tools/perceptual_noise.py`, adding the candidate to `VOICES`:
   - one gain to a −22 LUFS take;
   - inter-word pauses analysed with a Welch PSD.
   - **Primary figure:** the A-weighted level of the quietest 10 % of pause windows.
   - **Classification:** the band split (< 100 Hz sub / 150 Hz–4 kHz room tone / > 4 kHz hiss), the DC offset, and the low-frequency peak frequency.
   - **The old unweighted p5 ratio:** keep it only as a secondary figure, and always read it together with the band split.
4. **Compare against founder-verified anchors only.** There is **no numeric threshold.**

   | Anchor | Quietest-pause level, A-weighted |
   |---|---|
   | Heard clean: Locke | −97.8 dB(A)FS |
   | Heard clean: Heather | −96.2 |
   | Heard clean: Milo | −90.1 |
   | Heard clean: Brittney (diagnostic file) | −82.9 |
   | Heard noise: Andre Leone | −68.9 |
   | Heard noise: Lunaria | −68.2 |

   - **Within or below the heard-clean range, or dominated by sub-bass:** report "measurement clean", then go to founder listening.
   - **At or above the heard-noise anchors in the audible bands:** report "measurement flag: likely audible", then go to founder listening.
   - **In between:** report the position plainly; founder listening decides.
5. **Always provide the gain-only, level-matched diagnostic file.** No limiter, no processing. This is the file the founder judges.
6. **Never** high-pass, EQ, denoise or regenerate to improve a number.

## Earlier rejections, re-read with this method

**This changes no founder decision.**

| Voice | Basis of rejection | Quietest pauses, A-weighted | Dominant band | Depended on the unweighted LF metric? |
|---|---|---|---|---|
| Andre Leone | **A: founder heard noise** (Guarded master, Oct 13) | −68.9 | 118 Hz, audible room tone | no |
| Lunaria | **A: founder heard noise** (Guarded master, Oct 13) | −68.2 | 129 Hz, audible room tone | no |
| Grace | B: measurement (hiss), plus −43 LUFS source level needing +21 dB | −59.5, the noisiest of all | broadband, strongest > 4 kHz | no: hiss weighs *more* under A-weighting |
| Anastasia | B: measurement only | −72.9 | 145 Hz, mid-band room tone | no |
| Nicole | B: measurement, **plus a concrete clipped onset** (`lead_first`) | −77.9 | broadband, > 150 Hz | no |

**Findings:**
- **No earlier rejection rested on the low-frequency artefact that misled the Brittney gate.** Brittney is the only voice whose floor is sub-bass dominated.
- **Grace** stays well clear: she is 9 dB noisier than the heard-noise anchors, in the audible band.
- **Nicole** also has an independent concrete defect, the clipped "F".
- **Anastasia (−72.9) and Nicole (−77.9) lie *between*** the heard-clean Brittney (−82.9) and the heard-noise Andre and Lunaria (−68 to −69).
  - Their rejection was by measurement, and the corrected method cannot settle it without listening.
  - Nicole's clipped onset is a concrete defect regardless.
  - This is reported only. Neither voice is reopened.

## Production freeze (founder, 2026-10-16)

This methodology is **frozen** for production QA of the 168 clips. The Brittney false-positive diagnosis (`brittney/README.md` §3, `brittney/perceptual_noise.json` and `.txt`) is preserved as part of the D2 evidence pack.

**Audio QA rules:**
- Measurements are diagnostic evidence, not an automatic perceptual verdict.
- A voice or clip is never rejected merely because an unweighted dBFS measurement detects energy.
- Classify any measured residual by kind:
  - perceptible broadband noise;
  - hiss;
  - audible room tone;
  - low-frequency or sub-bass residual;
  - codec residual;
  - DC or near-DC energy.
- Use perceptually meaningful analysis where it helps: weighting and spectral context.
- **Founder or device listening is the final perceptual quality gate.**
- No EQ, high-pass filtering or denoise merely to improve a number when there is no audible defect.

**Production mastering rules** (the validated restrained route; preserve each voice's founder-approved character):
- the same frozen `eleven_multilingual_v2` generation route and settings;
- the exact canonical scripts, each verified against its canonical fingerprint;
- natural clip-to-clip dynamics;
- voice-wide gain where appropriate;
- correction of genuine outliers only;
- no blanket per-clip exact-LUFS forcing;
- no denoise, no compression;
- no EQ unless a later concrete audible defect requires investigation;
- the limiter only where needed, with the corrected 5 ms delay;
- 10 ms trim-edge fades that do not damage initial consonants.

**Loudness:** comparable perceived loudness across all four voices. They are not made mathematically identical at the cost of naturalness.
