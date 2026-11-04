# Heather final integration (2026-11-02)

## Result: APPLIED — PASS. Heather audio-quality correction round CLOSED. Uncommitted.

The founder listened to `heather_final_round_2026-11-02/FINAL_HEATHER_LISTEN_levelmatched.m4a` and approved the final variant in every section, so all six have FOUNDER LISTENING PASS. For roundTheBlock, the founder explicitly prefers seed 32 despite its shorter pause, which overrides the automated "keep the original".

**Route:** the 2026-10-17/18 single-clip route.
- **No generation and no credits.**
- **Mastering:** the frozen master rule. One file (noteOneThing) carries the established 2026-10-17 static trim; see the loudness gate.

| Clip | Shipping file (name unchanged) | Old SHA-1 (baseline 8bfd42c) | New SHA-1 | Take (request) | Extra gain |
|---|---|---|---|---|---|
| Shake it out | `voice_heather_v1/part_shakeOut_d58bb0f4.m4a` | `cead8c1dbcc488b4add8603ae6fefdac8d0ee389` | `8896408ce290d31c68be331c467383323c834489` | seed 34 (`8wT1CCk0FKe5bGj9om9T`) | 0 |
| Note one thing | `voice_heather_v1/part_noteOneThing_721bafd4.m4a` | `ee1f04b66984cbd50d796b0b2aecaad8d81b4c46` | `60e24b1fd9fbf320fac546a517532005513f420a` | seed 31 (`2N1tb5SHbbXeuvoepb3D`) | **−1.8 dB** |
| A brisk walk | `voice_heather_v1/part_briskWalk_e3125526.m4a` | `8302849906e7aa00283e0e9c387edd7e9daf758f` | `e311e08647b9b182d7bd1f2d4a99e20eb7d21032` | seed 32 (`Xdfb6HmGyVdHShGHlEtv`) | 0 |
| Look around | `voice_heather_v1/part_lookAround_53849d95.m4a` | `3e8416d16913262b14f55724ec30ce0f8cd85ccb` | `b55f8599e31e28c88009e24a97c9c5366974a459` | seed 32 (`9dc4emFC1vGOuDi0ywtT`) | 0 |
| Round the block | `voice_heather_v1/part_roundTheBlock_b1fa45f9.m4a` | `e7489c58f77354ab15892db87c6482b8ae8c0f46` | `6bac184329a542ce9ff5f5bca89e373ed2322336` | seed 32 (`aTJNbDScQCgZ9Bro5OPD`) | 0 |
| Sit outside | `voice_heather_v1/part_sitOutside_ba8e7ce2.m4a` | `aebf984799dc946fefbc097dde74de8d54c5e385` | `19ad090de7d613876d3b4e2ae34f8b22f4ea9198` | seed 32 (`e1YDujuBQ3r44FNDrMff`) | 0 |

**Raw sources:**
- shakeOut: `heather_final_round_2026-11-02/part_shakeOut/raw/seed34.mp3`
- noteOneThing: `preexpiry_review_2026-11-01/part_noteOneThing/raw/seed31.mp3`
- the four seed-32 clips: `heather_seed32_bank_2026-11-02/raw/<clip>_seed32.mp3`

## Loudness quality gate (`tools/loudness_gate.py`, `loudness_gate.json`)

The founder chose from level-matched files, so each take was measured as it ships. The reference is Heather's pack as it ships now (median part I −22.0, M_max −17.8, S_max −21.55).

**Trim criteria, fixed before measuring** (a static gain by the 2026-10-17 route only):
- **T1:** the take breaks the frozen standard (limiter or true peak).
- **T2:** it would be louder than every Heather part now shipping.
- **T3:** its 2026-10-17 correction is at least the −1.8 dB that the founder confirmed by ear for getItOut.

| Clip | Ships at I / M_max / S_max | vs its original (I) | Oct-17 formula | T1 / T2 / T3 | Action |
|---|---|---|---|---|---|
| shakeOut s34 | −20.2 / −17.6 / −20.9 | +3.8 | −0.9 | no / no / no | none |
| noteOneThing s31 | −20.0 / −16.5 / −19.6 | −0.3 | **−1.75 → −1.8** | no / no / **yes** | **−1.8 dB → ships −21.8 / −18.4 / −21.4** |
| briskWalk s32 | −20.3 / −16.3 / −20.1 | +1.8 | −1.55 | no / no / no | none |
| lookAround s32 | −20.2 / −17.2 / −19.7 | +3.6 | −1.4 | no / no / no | none |
| roundTheBlock s32 | −20.2 / −17.3 / −19.4 | +4.4 | −1.5 | no / no / no | none |
| sitOutside s32 | −21.6 / −18.6 / −21.3 | +2.5 | 0.0 | no / no / no | none |

**What the numbers show:**
- **Inside the standard:** no take breaks the frozen standard, and none becomes a new loudest Heather part.
- **Louder than before:** several originals were quiet outliers, so their replacements play 1.8–4.4 LU louder. That still sits within the range Heather's other parts already use.
- **noteOneThing:** its formula correction (−1.75) rounds to the −1.8 dB the founder confirmed for getItOut, so it takes that trim.
  - Its original shipped even louder, so the trim takes it from the old loudest Heather part to near her median.
  - Words, timing and pitch are unchanged (correlation 1.0 with the source at the logged gain).
  - The untrimmed as-ruled master stays at `preexpiry_review_2026-11-01/part_noteOneThing/masters/seed31_as_shipped.m4a`.
- **Neighbours:** heard in context on the S25, all six PASS, including noteOneThing at its trimmed level and the three loudest risers next to the Oct-17-trimmed getItOut and the leads.

## Checks before any write (`tools/apply.py`, `apply_log.json`)

1. Each shipping file equaled its `PRODUCTION_SHA1.txt` line **and** the committed baseline blob (8bfd42c).
2. **Provenance:** the credit-ledger entry has the voice `plP9aw1rizYgjFfuvLQ7`, `eleven_multilingual_v2`, the frozen settings and the seed. The canonical script is verbatim and the raw SHA-1 matches.
3. **Reproducible masters:**
   - The approved master is reproduced byte-for-byte by the frozen rule from its raw and equals the final-round QA master SHA-1.
   - The trimmed noteOneThing master was reproduced twice byte-identically, with the same outlier correction and no limiter.
4. **Gate:** the verdict lists exactly the planned trim.

## Applied

- **The copies:** each file was byte-copied over its shipping file. Each original is kept here as `REPLACED_shipping_<file>`, byte-identical to its old SHA-1, and the trimmed master is kept as `TRIMMED_part_noteOneThing_seed31_-1.8dB.m4a`.
- **Hash list:** `PRODUCTION_SHA1.txt` changed exactly 6 lines (52, 56, 57, 73, 80, 82), LF kept, and verifies 172/172. The previous list is kept as `PRE_CORRECTION_PRODUCTION_SHA1.txt`. The frozen baseline remains the committed 8bfd42c list.
- **`tools/production.py` `FOUNDER_FINAL`:** 6 entries (source raw and extra gain). The chain check (frozen rule on each entry) reproduces every shipping file byte-for-byte.

**What did not change** (`integrity_before.sha1` vs `integrity_after.sha1`, 180 files):
- **Only the six files differ.**
- **Byte-identical:**
  - the three seed-32 files integrated earlier today;
  - F02/F03 (8/8);
  - every other voice, including the getItOut −1.8 and oneTask −2.7 trims.
- **Social:** the F04 correction and the social bank were not touched.

## Shipped-file QA (`tools/applied_qa.py`, `applied_qa.json`)

| | shakeOut | noteOneThing | briskWalk | lookAround | roundTheBlock | sitOutside |
|---|---|---|---|---|---|---|
| ASR vs script | exact | exact | exact | exact | exact | exact |
| Name / fingerprint | ok | ok | ok | ok | ok | ok |
| Chain reproduces file | yes | yes | yes | yes | yes | yes |
| Correlation with approved take | 1.0 | 1.0 | 0.9999 | 1.0 | 0.9999 | 1.0 |
| Lead-in / tail (ms) | 150 / 450 | 150 / 460 | 190 / 470 | 190 / 440 | 200 / 450 | 150 / 440 |
| True peak (dBTP) | −4.76 | −7.88 | −4.87 | −4.76 | −5.69 | −4.06 |
| Pause bed old → new (dB(A)) | −66.3 → −106.0 | −69.8 → −105.4 | −71.0 → −108.1 | −70.8 → −96.0 | −70.9 → −89.2 | −70.3 → −106.0 |
| Duration old → new (s) | 6.66 → 6.83 | 6.36 → 6.62 | 10.64 → 11.16 | 6.98 → 6.27 | 8.30 → 6.45 | 9.27 → 9.20 |

**Clip durations:** the app reads no per-clip durations for parts. The only per-voice timing (`openingOnShow`) belongs to F02, which is unchanged.

## Gates

| Gate | Result |
|---|---|
| `flutter analyze` | no issues (`analyze.log`) |
| Relevant tests (`--concurrency=1`) | **371/0** (`tests_relevant.log`). Covered: `personal_circle/`, `b7_entitlement_matrix`, You B7/C1, `b8/` |
| Debug APK | sha256 `79884dd4…`. 180 guidance files: 172/172 + 8/8; the 6 new hashes are present and the old ones absent (`build_debug.log`) |
| QA debug APK (`THIRTY_QA_PREMIUM=true`) | sha256 `adf6dc9e…`; same asset check (`build_qa.log`) |

**Full suite not re-run:** no Dart or Kotlin code changed, only asset bytes and records. A temporary composer probe test (to pick device scenarios) was run and deleted, so `test/` is unchanged.

## Samsung S25 (`Documents/THIRTY_QA_backups/heather_final_s25_2026-11-02/run/RESULTS.md`)

**Procedure:** the established data-preserving procedure.
1. A fresh backup.
2. An in-place install of the QA APK.
3. In-memory QA scenarios.
4. Prefs checks after install and after launch.
5. `restore.sh`.

**Rounds:** five in-app Circles in Heather's voice, at real production levels, each replacement between unchanged neighbours.

| Round | New clip(s) | Founder verdict |
|---|---|---|
| R1 | Look around, Sit outside (with getItOut as level reference) | **Both PASS** |
| R2 | Note one thing (trimmed) | **PASS** |
| R3 | Round the block | **PASS** |
| R4 | A brisk walk | **PASS** |
| R5 | Shake it out (end noise) | **PASS** |

**Real data:** prefs byte-identical after restore; original APK `93b13a22…` back; settings identical; reminder re-armed for 17:32.

## Remaining audio notes

- **Founder-heard defects:** none left open. The ending and shakeOut findings are both resolved.
- **Measured, never heard on the device:** `part_nameWhatsOn` (−63.7 dB(A)), `part_comfortableSpot` (−68.7) and `part_neckAndShoulders` (−69.1) remain in the measured noise band. None of them played in today's device rounds and the founder has never reported them. Not in scope; no candidate.
