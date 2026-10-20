# THIRTY D2 — final launch voice set (founder lock, 2026-10-16)

**Voice selection is CLOSED.** Do not search for more voices. A rejected voice is reopened only if a concrete later production defect forces a replacement.

## Launch set — all FOUNDER APPROVED

| # | Display name | Stable product ID | ElevenLabs voice ID | Approved validation output | Evidence |
|---|---|---|---|---|---|
| 1 | Locke | `voice_locke_v1` | `oaLGpwm7fYWDEFmlRuQk` | `locke/locke_listen_mastered.m4a` | `README.md`, `APPROVED_LOCKE_HEATHER_SHA1.txt` |
| 2 | Heather | `voice_heather_v1` | `plP9aw1rizYgjFfuvLQ7` | `heather/heather_listen_mastered.m4a` | `README.md`, `APPROVED_LOCKE_HEATHER_SHA1.txt` |
| 3 | Milo | `voice_milo_v1` | `GUDYcgRAONiI1nXDcNQQ` | `replacements/milo/milo_listen_mastered.m4a` | `replacements/README.md`, `replacements/APPROVED_MILO_BRITTNEY_SHA1.txt` |
| 4 | Brittney | `voice_brittney_v1` | `pjcYQlDFKMbcOUp6F5GD` | `replacements/brittney/brittney_listen_mastered.m4a` | `replacements/brittney/README.md`, `replacements/APPROVED_MILO_BRITTNEY_SHA1.txt` |

**Voice notes:**
- **Milo:** the missing `eleven_multilingual_v2` fine-tune metadata is **not a blocker**. The founder approved the actual generated THIRTY output.
- **Brittney:** her automatic raw-noise FAIL was a **false positive**, caused by unweighted measurement of mainly ~32 Hz sub-bass energy. The founder heard no perceptible noise. The perceptual analysis (`replacements/brittney/perceptual_noise.json`) and the founder's listening supersede the old rejection.
- **Library notice period:** Brittney's library record has a notice period of 180 days and live moderation on; the other three have 730 days. Bundled files are unaffected by a later withdrawal.

**Identity rules:**
- **Stable IDs** are neutral, separate from display labels, and never encode gender. The rules for when an ID changes are in `docs/product/PHASE_E_VOICE_USAGE_MEASUREMENT.md`.
- **Display names:** Locke, Heather, Milo, Brittney.
- **Descriptors:** finalised from the approved production output.
- **Never in product copy:** ElevenLabs catalogue language such as meditation, meditative, hypnosis, healing, manifestations or ASMR. The ElevenLabs names are internal only.

## Rejected / superseded (not to be reopened automatically)

| Voice | Decision |
|---|---|
| Andre Leone | REJECTED: founder-confirmed audible source noise |
| Lunaria | REJECTED: founder-confirmed audible source noise |
| Grace | REJECTED: source hiss and insufficient source level |
| Anastasia | REJECTED: not selected |
| Nicole | REJECTED: source issues, including a clipped onset |

Their evidence is preserved unchanged in `andre_leone/`, `lunaria/`, `noise_diagnostic/` and `replacements/{grace,anastasia,nicole}/`.

## Production rules

- **Audio QA methodology:** frozen in `replacements/NOISE_GATE_METHODOLOGY.md`. Measurements are diagnostic; founder or device listening is the final perceptual gate.
- **Mastering:** also frozen there, under § Production freeze:
  - **Generation:** the frozen `eleven_multilingual_v2` route, with stability 0.5, similarity 0.75, style 0, speaker boost on, speed 1.0, seed 30 and `mp3_44100_128`.
  - **Scripts:** the canonical scripts, each verified against its fingerprint.
  - **Processing:** voice-wide gain, outlier-only correction, and the limiter only where needed (corrected 5 ms delay). 10 ms trim-edge fades that keep initial consonants.
  - **Not used:** denoise, compression, EQ, and blanket per-clip LUFS forcing.

## Gate before production

**The 168 final clips (42 canonical clips × 4 voices) are BLOCKED** until the founder confirms that the current paid ElevenLabs subscription grants commercial-use rights for content generated under that plan.

**After that confirmation, in order:**
1. generate the 168 clips;
2. verify every script against its canonical fingerprint;
3. verify all four packs are complete;
4. make sure no partial pack can activate;
5. integrate the four voices;
6. keep the selected voice through a Premium lapse;
7. add or verify Preview using the real production audio;
8. run the full S25 voice QA;
9. run the full D2 regression and final gate;
10. then close: ADR-023 ACCEPTED, D2 PASS, the closure commit and push, local SHA equal to remote SHA with ahead/behind 0/0, and the SHA locked for both audits.

## Status

| | |
|---|---|
| Locke / Heather / Milo / Brittney | APPROVED |
| Voice selection | CLOSED |
| The 168 production clips | blocked **only** by commercial-licence confirmation |
| D2 | NOT COMPLETE |
| Phase E | HOLD |
