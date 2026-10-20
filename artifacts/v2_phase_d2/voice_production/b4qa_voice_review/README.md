# Production voice pack — B4-QA defect correction (2026-10-18)

## Result: PASS — FROZEN

**What changed:** one shipping file, `voice_locke_v1/part_songOn_6017657f.m4a`.
- The founder approved its replacement by ear: on PC, then in the app on the S25.
- The other 171 production files are byte-identical (SHA-256, before and after).

## The defect

- **Found:** the founder heard it during the B4 S25 revisit check (Getting going, stage 1, part 1).
- **What it is:** the seed-30 take has an extra garbled syllable right after "really like": about 450 ms of voiced sound at speech level, around 3.8–4.4 s, then a pause, then "and let it play".
- **Why ASR missed it:** it folds the syllable into "and". Whole-clip ASR scores the take as exact.

## Triage (bounded)

9 candidates were examined: the confirmed clip, 5 shortlisted from the first ASR pass, and 4 flags from a second, piece-by-piece pass.

| Clip | Evidence | Verdict |
|---|---|---|
| Locke `songOn` | Founder ear; 450 ms of speech-level sound between "like" and "and" | **CONFIRMED DEFECT** |
| Heather `gentleStretch` | "slowly" is present in isolation; this is the founder-approved Oct 17 take | False positive |
| Heather `whatsNext` | "Decide" is clear in a wider window, as in Locke and Milo | False positive |
| Brittney `whatsNext` | "Decide" is clear (0.93); the take simply has no pauses | False positive |
| Locke `firstStep` | Two tiny bursts in the pause, peaking around −49 dBFS (about 33 dB under speech) | False positive (founder ear) |
| Milo `quickClearUp` | A released final "t" after "out" | False positive (founder ear) |
| Locke `whatsNext` | A pause after "and" ("and … go to it") | False positive (founder ear) |
| Milo `closeWhatsOpen`, `gentleStretch`, `lookAround` | Clean decay into silence, then onset; ASR artefacts at piece edges | False positive |
| Locke `quickClearUp`, Milo `readPages` | ASR merges and homophones; whole-clip ASR is exact | False positive |

**Scan limitation:** the second pass also scores the known `songOn` defect, and the earlier `sitOutside` one, as clean. Automated scans point at clips; they cannot clear them.

## Candidates (`locke_song_on/`)

**Generation:**
- Tool: `tools/generate_candidates.py`, a copy of the Oct 17 tool with only the target changed.
- Frozen voice ID, `eleven_multilingual_v2`, and the frozen settings (stability 0.5, similarity 0.75, style 0, speaker boost, speed 1.0), `mp3_44100_128`.
- The manifest script is sent verbatim. Seeds 31–33; 3 requests, 234 characters (`generation_log.json`).

**Mastering:**
- Tool: `tools/review_pack.py`.
- The frozen production rule at Locke's frozen median and voice gain (+4.47 dB). Nothing else was remastered.
- Chain check: re-mastering the shipping seed-30 raw reproduces the shipping file byte for byte.

| Take | Between "like" and "and" | Verdict |
|---|---|---|
| CURRENT s30 | About 450 ms of voiced sound at about −20 dBFS | Defect |
| c1 s31 | The same, about 400 ms at about −15 dBFS | Plainly defective |
| c2 s32 | Clean; but the title runs into the instruction (0.17 s) and the pace is fast (1.38) | Clean, but rushed |
| **c3 s33** | Silence at −78 to −87 dB (one 40 ms −58 dB breath) | **Founder pick** |

## Applied

**The copy:**
- `candidate3_seed33.m4a` was copied byte for byte over the shipping file.
- The replaced file is kept as `locke_song_on/REPLACED_shipping_seed30.m4a`.
- `production.FOUNDER_FINAL` records the source take.
- The global remaster lock in `master_production.py` is unchanged.

**Hash list:** `../PRODUCTION_SHA1.txt` changed one line (the previous version is `PRE_CORRECTION_PRODUCTION_SHA1.txt`) and verifies 172/172.

**Shipped-file QA (`applied_qa.json`):**
- File name and fingerprint: ok.
- Provenance: ok.
- ASR: exact.
- Lead-in 190 ms; tail 420 ms, ending in digital silence; true peak −3.75 dBTP.
- Waveform correlation with the approved take: 1.0.
- The "like → and" gap peaks at −57.8 dBFS, against −16.3 dBFS speech.

**App:**
- Code and manifest are unchanged; all 42 cues resolve in every voice folder (43 files each, including the preview).
- Voice and entitlement tests: 65/65.
- Android debug and QA Premium debug builds; the QA APK (`8d9274e6…`) bundles the new file.
- On the S25, sandboxed D3-A stage-1 Circle: founder **Approved**. The phone's real data was byte-identical afterwards.

**Listening files:** `listen/`.
