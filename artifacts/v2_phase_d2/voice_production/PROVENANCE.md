# Spoken guidance — production provenance

## 1. Commercial licence (founder-verified, 2026-10-16)

| | |
|---|---|
| Verification date | 2026-10-16 |
| Verified by | the founder, directly in the ElevenLabs billing UI |
| Provider | ElevenLabs |
| Plan | **Starter** |
| Paid plan | **YES**, active |
| Commercial licence | **YES** |
| UI wording | "Commercial License for Speech and Music" |

- **What this covers:** the final THIRTY production speech is generated under this paid commercial-use plan. No Creator or Pro upgrade is required (founder).
- **Approved source route:** ElevenLabs `mp3_44100_128` (128 kbit/s, 44.1 kHz).
- **Not stored here:** no payment details, billing identifiers, API keys, account identifiers or screenshots. The founder's verification is recorded as fact.
- **The commercial-licence gate is CLOSED** (founder, 2026-10-16). It was the last administrative pre-production gate (`../voice_production_validation/FINAL_VOICE_SET.md`).

## 2. Voices (founder lock, 2026-10-16)

| Stable product ID | Display name | ElevenLabs voice ID |
|---|---|---|
| `voice_locke_v1` | Locke | `oaLGpwm7fYWDEFmlRuQk` |
| `voice_heather_v1` | Heather | `plP9aw1rizYgjFfuvLQ7` |
| `voice_milo_v1` | Milo | `GUDYcgRAONiI1nXDcNQQ` |
| `voice_brittney_v1` | Brittney | `pjcYQlDFKMbcOUp6F5GD` |

## 3. Founder-approved final corrections (2026-10-17)

- **What changed:** after listening to the final pack, the founder approved four replacements by ear. Exactly those four shipping files changed. The other 164 are byte-identical to the pre-correction pack (`final_corrections_review/PRE_CORRECTION_PRODUCTION_SHA1.txt`).

| Clip | Shipping file now | Source |
|---|---|---|
| Brittney `part_sitAMinute` | candidate c3 | seed 33: same voice, model, settings and script |
| Heather `part_gentleStretch` | candidate c3 | seed 33: same voice, model, settings and script |
| Heather `part_getItOut` | the seed-30 take | one static gain of −1.8 dB |
| Heather `part_oneTask` | the seed-30 take | one static gain of −2.7 dB |

- **Generation:** the review generated 6 takes (seeds 31–33 for the two regenerated clips), 675 characters. Request IDs are in `final_corrections_review/generation_log.json`.
- **Locked:** `tools/production.py` `FOUNDER_FINAL`. `master_production.py` now refuses to run.

**Founder listening:** "all ok" on the S25, in the real app (2026-10-17).

## 4. Voice previews (founder, 2026-10-17)

**What changed:** "Hear <name>" no longer plays a Circle's activity. Each voice has its own preview line, chosen by the founder:

> "Hi, I’m <Name>. I’ll tell you when each part of your Circle begins, so you can put the screen down."

**Generation and mastering:**
- **Generation:** one request per voice, with the same voice ID, model and settings at seed 30. 4 requests, 396 characters; request IDs are in `previews/generation_log.json`.
- **Mastering:** the frozen rule, with each voice's frozen median and voice gain (`tools/preview_production.py`). No limiter was engaged.

**QA (`previews/preview_qa.json`):**
- **ASR:** exact for every voice. For Brittney, ASR spells the name "Brittany", a homophone; the founder confirmed it by ear.
- **Onsets and endings:** onsets 40–70 ms after silence; no clipped endings.
- **Noise:** each pause bed is inside its voice's own spread.

**Founder listening:** "All ok" on the S25, in the real app (`previews/S25_founder_listening_logcat.txt`).

**Pack:** 172 files = 4 × (42 manifest clips + 1 preview). `PRODUCTION_SHA1.txt` verifies 172/172; the previews are its last 4 lines.
