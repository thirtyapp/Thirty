# Phase D2 — audit evidence pack (final hardening, 2026-10-12)

**Status of D2: NOT COMPLETE.**
- **The open gate:** the production voice. No production clip exists, and the founder has not yet approved a voice; a review-only audition exists.
- **Not yet the immutable target:** this pack documents the hardened build. It is **not** the immutable audit target until every D2 gate closes and a single closure commit is made.

The review packs stay in `artifacts/` and are untracked, as in every earlier phase; the code, tests and governance documents are in git. Everything below was produced from the code or measured on the device. Negative findings are kept.

| Evidence | Where |
|---|---|
| Final content pack — the last two fixes, a machine drift proof, and the full shipping copy generated from code | `../CONTENT_REVIEW.md` |
| Element coverage (generated) | `../ELEMENT_COVERAGE.md` |
| Long-horizon simulations — 14 profiles, day 1 to month 12, including `p14_more_energy_dominant`, plus the lapse attack | `../SIMULATION_REVIEW.md`, `../simulations/` |
| Spoken-guidance manifest — the recording source of truth, 42 clips | `../SPOKEN_GUIDANCE_MANIFEST.csv` |
| Voice production and mastering requirements | `VOICE_PRODUCTION_REQUIREMENTS.md` |
| Voice audition — review only, 3 voices × 5 clips, not bundled | `../voice_audition/README.md` |
| **Production voice QA** | **None possible: no production clips exist.** Plumbing was verified with temporary test tones (`BACKGROUND_PLAYBACK_QA.md`). |
| Background playback, screen off / lock / app switch / Back / notification controls / ducking | `BACKGROUND_PLAYBACK_QA.md`, raw log `../bg_qa/logcat_session.txt` |
| Device QA, all D2 passes | `../DEVICE_QA.md` (final-hardening section at the end), `../screenshots/` |
| TalkBack evidence | `../DEVICE_QA.md` (2026-10-11 live pass; final-hardening TalkBack section), `../talkback/` |
| Tests and analyze, this pass | `TEST_RESULTS.md` |
| Saved-Circle / lapse attack | `KNOWN_COMMERCIAL_HYPOTHESES.md` H2; `../simulations/saved_circle_lapse_attack.json`; test `test/features/personal_circle/saved_circle_lapse_attack_test.dart` |
| More Energy (p14) | `KNOWN_COMMERCIAL_HYPOTHESES.md` H3; `../SIMULATION_REVIEW.md` |
| Commercial hypotheses, real-user and acquisition unknowns | `KNOWN_COMMERCIAL_HYPOTHESES.md` |
| Release-audit notes (older source wording) | `RELEASE_AUDIT_NOTES.md` |
| Governance | `docs/product/adr/ADR-023-…md` (Proposed), `docs/product/THIRTY_V2_DELIVERY_TRACKER.md` (D2 IN PROGRESS), `docs/product/PRODUCT_V2_CONTRACT.md` amendment |

---

## Production voice pass (2026-10-16) — D2 still NOT COMPLETE

| Evidence | Where |
|---|---|
| The final four voices, their stable IDs, the rejected voices | `../voice_production_validation/FINAL_VOICE_SET.md` |
| Commercial licence: ElevenLabs Starter, paid, "Commercial License for Speech and Music" (founder, 2026-10-16) | `../voice_production/PROVENANCE.md` |
| Generation settings and request IDs; raw hashes | `../voice_production/generation_log.json`, `RAW_SHA1.txt` |
| Canonical 42-script manifest; drift proof | `../SPOKEN_GUIDANCE_MANIFEST.csv`, regenerated from the code byte-identical (`TEST_RESULTS.md`) |
| Raw QA (incl. offline ASR), onset detail, retakes | `../voice_production/README.md` §2–3, `raw_qa.json`, `onset_detail.json`, `retake_log.json` |
| Mastering rules and per-clip report | `../voice_production/README.md` §4, `mastering_report.json`; `../voice_production_validation/replacements/NOISE_GATE_METHODOLOGY.md` |
| Perceptual-noise methodology and the Brittney false-positive history | `../voice_production_validation/replacements/NOISE_GATE_METHODOLOGY.md`, `../voice_production_validation/replacements/brittney/README.md` §3 |
| 168-clip completeness and production fingerprints | `../voice_production/PRODUCTION_SHA1.txt`; test "bundles the four production voices, each complete" |
| Post-master QA of the shipping files | `../voice_production/post_master_qa.json` |
| **S25 device QA with the production audio**: all four voices, preview, 10/20/30-min windows, timed cues in the background and locked, Pause/Resume/Next/Skip, the dependent skip, Close, ducking, voice off, TalkBack (Premium and Free), Free and lapsed kept Circle, Premium again | `../voice_production/device_qa/S25_PRODUCTION_VOICE_QA.md` |
| Tests, analyze, the 14 simulations, the lapse attack | `TEST_RESULTS.md` (production voice pass) |
| **Open:** founder listening of the final pack | `../voice_production/listen/`; not yet done (`../voice_production/README.md`) |
