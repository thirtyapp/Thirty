# Spoken guidance — production voice requirements

**The source of truth for the scripts and filenames is `../SPOKEN_GUIDANCE_MANIFEST.csv`**, regenerated 2026-10-12 after the final two copy fixes.
- **The pack:** 42 clips: `lead_first`, `lead_next`, `lead_last`, 38 element clips and `close`. **Recorded in each of THIRTY's two voices** — one female-presenting, one male-presenting (founder decision, 2026-10-12): **84 production clips** in all.
- **No production clip exists yet.** The voice gate is open until the founder approves both voices and every clip below exists in both and passes QA.
- **Premium only:** THIRTY's voice is a Premium service layer; the app plays it only while Premium is active. Accessibility (TalkBack) never depends on it (ADR-023 §6).

## 1. What the app expects

- **Files:** for each voice, exactly the 42 file names in the manifest's `file` column, in that voice's folder: `assets/audio/guidance/female/<file>` and `assets/audio/guidance/male/<file>`, e.g. `assets/audio/guidance/female/part_getItOut_a239320e.m4a`.
  - The 8-hex fingerprint is FNV-32 of the clip's script. If the script changes, the filename changes, and the old recording can no longer be found (never stale).
  - Do not rename files by hand.
- **All or nothing, per voice:** a voice switches on only when **all 42** of its clips are bundled (checked once at start-up). A partial set is silent.
- **Bundling:** add `- assets/audio/guidance/female/` and `- assets/audio/guidance/male/` to `pubspec.yaml` under `assets:`.
  - When the files are added, the test `without the bundled recordings the voice is silent — this build bundles none` (`composed_ui_test.dart`) must be inverted.
  - That test is the guard that no recording is committed before approval.
- **Format:** AAC-LC in an `.m4a` container (Android `MediaPlayer` from Flutter assets), mono, 44.1 kHz or 48 kHz, 96–128 kbit/s. All 42 use the same settings.
- **Playback:** a lead and its part play back to back with **no gap added by the app**, so every pause lives inside the files (§3).

## 2. Voice

- **It must sound:** warm, calm, natural, conversational, adult, clear and restrained — a person, not an announcer. The English must be internationally understandable.
- **It must not sound:** clinical, therapeutic, meditation-guru, sleepy, overly emotional, motivational, robotic, salesy or infantilising.
- **Within a voice:** the same speaker for all 42, with the same settings, recording chain (or generation model, voice and stability settings) and pronunciation.
- **Across the two voices:** the same model, generation settings, scripts and mastering, so they differ in voice character only.
- **Labels in the app:** "Female voice" / "Male voice" are placeholders. After selection, the chosen voice names become the primary labels, with a preview of each, and a short female/male descriptor only if it is useful. The choice is never asked during onboarding, is stored locally, and survives a lapse. The final names are not implemented before the founder selects the voices.
- **Pronunciation to check:**
  - "Minimise" (British spelling; neutral pronunciation);
  - "hoovering";
  - "briskly";
  - the em dash as a short natural pause;
  - curly apostrophes read as ordinary contractions ("you’d", "That’s").
- **Name and instruction:** each part clip is "<name>. <instruction>", e.g. "A brisk walk. Head out. Start easy…".
  - The name is read as a short heading, with a natural beat before the instruction, so the two don't sound duplicated.
  - Where an instruction repeats a word of its name ("A slow warm drink. Make a warm drink…"), the delivery must stay natural.
  - If a sentence sounds objectively awkward when spoken, report it as a content-freeze exception (brief §4). Do not edit it during recording.

## 3. Mastering

| Item | Requirement |
|---|---|
| Loudness | Integrated **−16 LUFS ±1 per clip**, and within ±1 LU across all 42. No audible jumps between the lead and the part, or between parts. |
| Peaks | True peak ≤ **−1.5 dBTP**. |
| Dynamics | Gentle levelling only. No heavy compression or limiting: the voice must not sound squashed. |
| Leading silence | 120–200 ms on every clip, so no clipped onsets. |
| Trailing silence | Leads (`lead_first`, `lead_next`, `lead_last`): **600–800 ms**, the "short natural pause" after "First." / "Next." / "And last." before the part begins. Parts and close: 300–500 ms. |
| Noise | Clean noise floor; no breaths cut mid-way, no clicks, no room tone jumps between clips. |
| Content | Voice only: **no music, no sound effects** (unless the founder explicitly approves). |

## 4. QA before approval

Before the founder approves, listen to every clip and to representative composed sequences:
- **Sequences:** First → part; Next → part; And last → part; the close.
- **Coverage:** short and long parts; writing (`getItOut`), walking (`briskWalk`, `easyWalk`), movement (`moveToMusic`, `standAndReach`) and quiet parts (`warmDrink`, `lookFar`, `sitAMinute`, `quietMusic`).

Check:
- no duplicated words between the lead and the part title;
- no clipped beginnings or ends;
- no overly long silence;
- natural transitions;
- consistent level (measure every file and record the LUFS and true peak per clip).

Then device QA on the S25 with the bundled pack:
- foreground, background, screen off and lock screen;
- Skip, Next and the dependent skip, each firing the cue once;
- no overlap, and no repeat after app-lifecycle changes;
- TalkBack in front: no voice.

## 5. Generation route (founder decision, 2026-10-12)

- **Audition only:** the vidIQ-generated audition (`../voice_audition/`) is for choosing a voice. It is never bundled, because the intermediary's commercial licence is unresolved.
- **Production route:** once the founder approves a voice, generate all 42 clips **directly under a paid ElevenLabs account/plan with commercial rights**.
  - Use the frozen manifest's exact scripts. Never rewrite a script during generation.
  - Use one model, one voice and one settings set for all 42.
- **Evidence to keep in `voice_production/PROVENANCE.md`** (no secrets, API keys or credentials in the repository):
  - account/plan;
  - generation date;
  - licence/terms reference;
  - voice name and ID;
  - model and settings (stability, similarity, style, speed);
  - the exact scripts (this manifest).
- **No runtime cost:** this is pre-generation only. Nothing in the app calls a voice service.
- **Before bundling:** master per §3, then prove that all 42 filenames and fingerprints match the manifest and that activation is all-or-nothing.
- **Alternative:** a voice actor recording the CSV script, mastered to the same table.

---

## Production (2026-10-16) — what superseded this brief

This brief predates the voice validation. **The production pack follows the founder's later decisions:**
- **Four voices, not two:** Locke, Heather, Milo and Brittney, with stable IDs `voice_*_v1`.
  - **Folders:** `assets/audio/guidance/voice_<name>_v1/<manifest file>`.
  - **Pack size:** 168 clips (42 × 4).
- **Mastering:** the founder-approved restrained route (`../voice_production_validation/replacements/NOISE_GATE_METHODOLOGY.md` § Production freeze).
  - One voice-wide gain to a **−22 LUFS** take: the level of the validation masters the founder approved.
  - Outlier-only correction within ±2 LU; no per-clip LUFS forcing.
  - The §3 table's −16 LUFS ±1 per-clip target is superseded.
  - Peaks (≤ −1.5 dBTP), lead-in (120–200 ms) and tails are still met (`../voice_production/post_master_qa.json`).
- **Commercial licence:** ElevenLabs Starter (paid), confirmed by the founder on 2026-10-16 (`../voice_production/PROVENANCE.md`).
- **Production evidence:** `../voice_production/README.md`.
