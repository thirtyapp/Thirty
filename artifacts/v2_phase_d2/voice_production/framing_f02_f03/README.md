# F02 / F03 — spoken opening and closing lines (2026-10-26)

Founder approval: "THIRTY — PREMIUM VOICE INTEGRATION: F02 & F03". **Status: implemented and staged for founder review. Nothing is committed. No device QA has been done.**

| Line | Script | App clip | When |
|---|---|---|---|
| F02 | Your Circle for today. | `opening_d1293026.m4a` | At the user's own Start, before "First.", with the words shown as the heading |
| F03 | Your next Circle opens tomorrow. | `next_circle_3c38eb7b.m4a` | After the user's own Close, only when the Circle closed on its own day |

Both lines exist in each voice folder `assets/audio/guidance/voice_{locke,heather,milo,brittney}_v1/`. That makes 8 new files. The 172 shipping files are byte-identical: `PRODUCTION_SHA1.txt` verifies 172/172.

## No generation

All eight takes come from the social voice bank (Set 2, 2026-10-22). No credits were spent.
- Byte copies are in `source/`. The social bank was only read.
- Each take's generation-log entry was verified: voice ID, script, model, frozen settings, seed 30 and byte count.

## Production

`tools/framing_production.py` holds the method; its docstring is the specification.

The frozen production rule was applied with each voice's **frozen** median and voice-wide gain, exactly as the previews were. A chain check runs first: this master of each voice's preview raw reproduces the shipping preview byte-for-byte, for all 4 voices.

| Voice | F02 | F03 |
|---|---|---|
| Locke | rule only | rule only |
| Heather | **cut to speech** + **level −2.6 dB** | rule only |
| Milo | rule only | rule only |
| Brittney | **tempo ×1.106** (pitch-preserving) | **tempo ×1.106** |

### Heather F02

The source has two low-frequency events entirely outside the speech:
- the known onset thump, 0–40 ms at −37 to −43 dBFS raw, ahead of speech that starts at 50 ms;
- a second bump at 1.78–1.80 s, about 0.25 s after "today".

The app rule's −50 dBFS trim keeps both. The correction cuts the clip to its speech: 5 ms before the 300 Hz–4 kHz onset, and the rule's own 40 ms after its end. It does no filtering or denoising, and the speech is untouched.

Her F02 then measured +2.45 LU (integrated) and +2.70 dB (maximum momentary) above her median part. That is the "too loud" pattern from 17 Oct. It gets one static −2.6 dB, by the rule of the founder-approved `part_getItOut` and `part_oneTask` corrections.

Result: no non-speech event remains, and the master sits within 0.15 dB of her median part. A/B: `review/heather_F02__A_rule_only__B_cut_to_speech__C_social_chain_B.m4a` (C = the founder-approved social version B, at app level).

### Brittney

Her social takes are at speed 0.9; her app voice is at 1.0.

**Tempo.** The ratio comes from 36 same-script pairs that exist at both speeds (`tools/brittney_pace.py`): 0.9 takes speak 10.6% longer (median; IQR 8.4–12.3%). Three pitch-preserving methods were compared:

| Method | Pitch shift | Spectrum change vs own 0.9 take | Periodicity |
|---|---|---|---|
| ffmpeg `atempo` (chosen) | 0.00 st | 0.22 dB | none lost |
| Rubber Band, crisp | 0.00 st | 0.65 dB | none lost |
| Rubber Band, smooth | 0.00 st | 1.20 dB | phasiness (0.816 → 0.783) |

For scale, real 1.0 vs 0.9 takes differ by 2.80 dB.

**Pitch** (`tools/brittney_pitch.py`):
- Speed does not change her pitch: across 38 pairs, the median is +0.07 st.
- F02/F03 sit about 2.5 st below her instructional app parts, but within 0.6–0.9 st of her other short social lines at speed 1.0. That is delivery, not speed.
- It is still the largest gap of the four voices, so the founder should listen.

**A/B files:**
- `review/brittney_F02__A_speed090_as_generated__B_tempo_1106.m4a`
- `review/brittney_F03__…`
- the method on a line with a real 1.0 take: `review/brittney_method_check_A01__A_real_speed100__B_speed090_tempo_1106.m4a`

**If the founder's ear rejects the tempo version,** the exact retake is: F02 and F03, Brittney `pjcYQlDFKMbcOUp6F5GD`, `eleven_multilingual_v2`, stability 0.5, similarity 0.75, style 0, speaker boost on, **speed 1.0**, seed 30, `mp3_44100_128`. That is 54 characters, about 22 credits at the Set 2 rate (9 + 13). It needs the founder's authorization.

## QA, all 8 masters

- **ASR** (faster-whisper small.en): exact on all sources and masters (0 word edits).
- **Edges:** no clipped onset or ending; no sample clipping; no limiter engaged; true peak −4.4 to −8.9 dBTP.
- **Loudness:** I and maximum momentary are within −1.4 to +0.95 LU (I) and −3.0 to +0.1 dB (M max) of each voice's median shipping part.
- **Non-speech edges:** none in Locke, Heather or Milo masters. Brittney's masters have sub-40 Hz content at the edges, up to −42 dBFS. A-weighted it is −67 to −69 dBA, and the same residual runs through her speech. That is the founder-verified inaudible residual (16 Oct); it is reported, not corrected.

## Listening (as heard in THIRTY)

- `listen/<voice>__start.m4a`: "Your Circle for today." → "First." → a first part.
- `listen/<voice>__ending_then_close.m4a`: the ending, a pause, then "Your next Circle opens tomorrow."
- `listen/all_four__F02_opening.m4a` and `all_four__F03_next_circle.m4a`.

## Integrity

- `FRAMING_SHA1.txt` lists the 8 installed files.
- `framing_qa.json` holds every measurement.
- `masters/` holds the staged copies, identical to the installed ones.

## Acceptance remediation (2026-10-27)

**Status: still NOT ACCEPTED.** It awaits the founder's ear, the governance approval and S25 QA.

- **Native lifecycle:** `native_lifecycle/` compiles the real `GuidanceAudio.kt` and `GuidanceService.kt` on the JVM against simulated Android. It runs 12 scenarios with 69 checks (`run.sh <repo>`).
  - One gap was found and fixed: `stop()` did not report the voice idle. A session waiting for the ending therefore stayed up to its 30 s limit when the voice was turned off or lapsed. `result_prefix_stop_without_idle.txt` shows the failure before the fix.
- **Listening:** `acceptance_2026-10-27/` holds Brittney in context and Heather A/B at matched level. See its INDEX.
- **Governance:** `GOVERNANCE_DELTA_PROPOSED.md` holds the append-only amendments for the contract, ADR-023 and the tracker, not applied. The 172 baseline is untouched.

## Final regression closure (2026-10-29)

- **Founder ear:** Brittney F02 PASS, Brittney F03 PASS, Heather F02 PASS. The existing corrected Heather audio is kept. No new recordings. The masters are unchanged.
- **Status: still NOT ACCEPTED.** The governance approval (`GOVERNANCE_DELTA_PROPOSED.md` §6) and S25 QA are still open.
- **Native harness re-run:** `native_lifecycle/result_2026-10-29_final_regression.txt`, 69/69, identical to 2026-10-27.
