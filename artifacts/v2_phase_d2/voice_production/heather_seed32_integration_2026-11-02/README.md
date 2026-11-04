# Heather seed-32 integration (2026-11-02)

## Result: APPLIED — PASS. Uncommitted.

The founder authorized integrating three Heather seed-32 takes. Each had FOUNDER LISTENING PASS, and the founder had accepted the ending → F03 preview. The 2026-10-17/18 single-clip route was used:
- **No generation, remastering or new loudness change.**
- **No credits.**

| Clip | Shipping file (name unchanged) | Old SHA-1 (baseline 8bfd42c) | New SHA-1 | Source take |
|---|---|---|---|---|
| Ending | `voice_heather_v1/close_3b06cf13.m4a` | `c295a7f4c7679c2def0775650884bf991b8cec18` | `64fd416e98cbb2caf669660ce8f80993761c9151` | `preexpiry_review_2026-11-01/close/raw/seed32.mp3` (request `4ZAKwlIqG0aIFKPwN82D`) |
| Set screens aside | `voice_heather_v1/part_closeWhatsOpen_a811d003.m4a` | `ee9d5e868bf833fbdf053d8e3a0784d8b3d66e6a` | `7c1a508d34eaa44ac2892ba32b3fbd2d2a11778f` | `…/part_closeWhatsOpen/raw/seed32.mp3` (`DxA4DONNMEf9YMVWNgUF`) |
| One active job | `voice_heather_v1/part_activeJob_5b1bb959.m4a` | `53b65e05c2200dd7e9f83245e1786d794584a5e6` | `239c8f0dcbcce940a40913c5b61e9db251433dc0` | `…/part_activeJob/raw/seed32.mp3` (`BQKjWOc3zjpzUxizuZ0q`) |

## Checks before any write (`tools/apply.py`, `apply_log.json`)

1. Each shipping file equaled its `PRODUCTION_SHA1.txt` line **and** the committed baseline blob (8bfd42c).
2. **Provenance:** the 2026-11-01 ledger shows the voice `plP9aw1rizYgjFfuvLQ7`, `eleven_multilingual_v2`, the frozen settings, seed 32, the canonical script verbatim and the raw SHA-1.
3. **Masters:** the approved review master is reproduced byte-for-byte by the frozen rule from its raw take (Heather median −19.5, voice gain −2.89, no extra gain). It equals the bank's QA'd candidate master.

## Applied

**The copies:**
- Each master was byte-copied over the shipping file.
- Each original is kept here as `REPLACED_shipping_seed30_<file>`, byte-identical to its old SHA-1.

**Hash list:**
- `PRODUCTION_SHA1.txt`: 3 lines changed (55, 66, 84), LF kept; it verifies 172/172.
- The previous list is kept as `PRE_CORRECTION_PRODUCTION_SHA1.txt`.
- The frozen baseline remains the committed 8bfd42c list.

**Founder record:** `tools/production.py`, `FOUNDER_FINAL` has 3 entries (source take, extra gain 0.0). The remaster lock is unchanged.

**What did not change:**
- **Byte-identical against the session snapshot:** F02/F03 (`FRAMING_SHA1.txt` 8/8), and all other 169 production files, including the getItOut −1.8 and oneTask −2.7 trims.
- **The only changed files** are the 3 assets, `PRODUCTION_SHA1.txt` and `production.py`.

**Governance (append-only):**
- Tracker: PRODUCTION AUDIO and OPEN AUDIO FINDING rows extended, plus a log entry.
- ADR-023: a correction line under "Production voices".

## Shipped-file QA (`tools/applied_qa.py`, `applied_qa.json`)

| | Ending | Set screens aside | One active job |
|---|---|---|---|
| ASR vs script | exact | exact | exact |
| File name / fingerprint | ok | ok | ok |
| Correlation with approved take | 0.9999 | 0.9999 | 0.9999 |
| Lead-in / tail | 190 / 440 ms | 150 / 450 ms | 150 / 440 ms |
| Ends in digital silence | yes | yes | yes |
| True peak | −4.07 dBTP | −3.96 | −3.77 |
| Integrated LUFS, old → new | −24.3 → −20.6 | −22.8 → −21.9 | −21.1 → −20.9 |
| Duration (mvhd), old → new | 4.33 → 4.43 s | 10.30 → 10.14 s | 12.06 → 10.90 s |
| Pause bed, old → new (dB(A)) | −67.9 → −87.8 | −66.9 → −95.3 | −67.1 → −101.3 |
| Identity: spectrum percentile / pitch | 61st / −0.88 st (old: 100th / −1.81) | 76th / −0.39 | 3rd / −0.06 |

**Loudness:** the ending's new level is inside the frozen ±2 LU window around Heather's median (−22.2), with its peaks at the median. The 2026-10-17 trim formula asks for only −0.6 dB, so no standard is violated and no trim was made.

**Durations:** the app reads no per-clip durations for these files.
- F03 follows via `afterCurrent` (played after the ending finishes).
- The only per-voice timing (`openingOnShow`) belongs to F02, which is unchanged.

## Gates

| Gate | Result |
|---|---|
| `flutter analyze` | no issues |
| Relevant tests (`--concurrency=1`): `personal_circle/` (incl. framing mvhd and ending-file tests, guidance session/entitlement, composed UI, D2 review pack), `b7_entitlement_matrix`, You B7/C1, `b8/` (simulations, review pack, live-copy guard) | **371/0** (`tests_relevant.log`) |
| Debug APK | sha256 `53fc7bac…`; 180 guidance files: 172/172 + 8/8; the new hashes are present and the old ones absent |
| QA debug APK (`THIRTY_QA_PREMIUM=true`) | sha256 `13322dfb…`; same asset check |

**The full suite was not re-run,** because no Dart or Kotlin code changed; only asset bytes and records did.

## Samsung S25 (`Documents/THIRTY_QA_backups/heather32_s25_2026-11-02/run/RESULTS.md`)

**Procedure:** the established safe procedure.
1. A fresh backup of real data.
2. In-place install with the same cert and versionCode.
3. An in-memory QA Circle.
4. A prefs check after install and after launch.
5. `restore.sh` afterwards.

**Founder ear:**
- **Ending → F03: PASS** (R2; R1 was replayed at the founder's request).
- Noted separately: noise at the end of `part_shakeOut` (see below).

**Real data:** restored byte-identical; settings identical; the reminder re-armed.

## Remaining audio concerns

1. **`part_shakeOut` (Heather, unchanged original):**
   - The founder hears background noise at its end on the S25.
   - Its bed measures −66.3 dB(A), in the heard-noise band.
   - Seeds 31 and 32 did not clean it (−70.9 / −70.0).
   - Not authorized; no candidate exists.
2. **Others in the same band** (not reported by the founder on device): `part_nameWhatsOn`, `part_comfortableSpot`, `part_neckAndShoulders`, `part_noteOneThing` (its Nov 1 seed 31 at −103.7 is a clean, unapproved candidate).
3. **Level:** the new ending is 3.7 LU louder than the old outlier; F03 now follows 2.6 LU quieter. The founder accepted this in the preview and on the S25.
