# THIRTY — R7 handoff for the targeted independent audit (2026-11-04)

**Audit the commit that contains this file, on `origin/step5-billing-integration`. Do not audit any uncommitted working tree.** A commit cannot name its own SHA. The full SHA is recorded outside the commit: in the founder's R7 report and in the local `R7_PUSH_RECORD.md`. Before you start, check that `git rev-parse HEAD` equals that SHA and that its parent is `8bfd42c16693b8f5040ebcf4761db0e9c439981c` (the D2 closure, the immutable target of both earlier audits).

**Status.** R1–R6 were accepted by the founder at implementation and test level only. No independent reviewer has examined this commit. Do not treat any audit as passed until reviewers have actually reviewed this SHA. The tracker rule applies: a material blocker restarts the audits on a new SHA. Phase E is on **HOLD**. No commercial release is authorized.

## Scope of this commit

This is one remediation commit on top of `8bfd42c`: 170 source/evidence paths (97 modified, 73 added, 0 deleted), plus this folder and the R7 tracker entry.

| Area | Content |
|---|---|
| App code | `lib/` (39 modified, 4 added) and Android `GuidanceAudio.kt` / `MainActivity.kt`. The Kotlin change is the F02/F03 `afterCurrent` queue: a stop now signals idle. |
| Tests | 26 modified, 19 added; 159 test files in total |
| Audio | 9 founder-approved Heather replacements, within the 172: seed-32 ×3, final round ×6. Also the 8 F02/F03 framing clips (2 lines × 4 voices). 180 files are bundled. |
| Audio records | `PRODUCTION_SHA1.txt` (172); `framing_f02_f03/FRAMING_SHA1.txt` (8). Integration and QA records are in `voice_production/heather_seed32_integration_2026-11-02/`, `heather_final_integration_2026-11-02/` and `framing_f02_f03/`. |
| Product docs | Amendment notes in `PRODUCT_V2_CONTRACT.md` and in ADR-011/021/023/024. The delivery tracker log covers R1–R7. |
| Evidence | Regenerated B8 review pack and simulations; `final_audit` status notes; `.gitattributes` LF rule for the hash manifests (m5) |
| Audit inputs | `docs/audits/INDEPENDENT_AUDIT_1_D2_2026-10-21.md` and `..._2_...`, committed unchanged (sha256 `311c40d0…`, `8bf52ac4…`) |
| Verification | `artifacts/r6_final_verification_2026-11-03/` (summaries) and this folder |

## Findings → remediation → tests

| Finding | Severity | Batch | What changed | Main tests |
|---|---|---|---|---|
| A2-01: a never-purchased customer gets no purchase CTA | BLOCKER | R1 | An absent entitlement maps to `inactive`; a failed lookup stays `unavailable` (fails closed). Overlapping refreshes publish only the newest-asked answer (J18). | `test/core/premium/revenue_cat_entitlement_gateway_test.dart` |
| A2-02 / F1: a paid user gets a Free day; Plan progression lost | MAJOR | R2 | "Make today’s Circle" upgrade; served-stage provenance; no credit when started after a *verified* expiry (Design A) | `r2_make_today_circle_test`, `r2_plan_credit_provenance_test` |
| A2-04: mixed-day state; Delete resurrection | MAJOR | R3 | Write-ahead today record; same-day guard; HistoryWriteGate and two-pass deletion with a pending marker; start-up completion | `r3_persistence_delete_test`, `r3_delete_feedback_test` |
| A2-03 / F2: catalogue changes alter or remove owned Circles | MAJOR | R4, R4.1 | Kept parts read with their saved lengths and words; unreadable records and stores retained verbatim, counted, removable only by the user | `r4_kept_ownership_test`, `r41_kept_store_test` |
| A2-05 / m2: I4 Keep gated by subscription | MAJOR | R5 | `KeepCircleFromHistory` is exempt from the Premium gate; other I4 actions stay gated; the eight-slot limit is unchanged | `r5_i4_keep_after_lapse_test` |
| D-B: saved words vs. the current recording | — | R6 | The whole Circle runs unvoiced, with a note, when any part's saved words differ | `r6_kept_voice_whole_circle_test` |
| A2-06: consent copy understates the data | MAJOR | R6 | `UsageDataCopy` names the six events, their fields and the random ID, and what turning sharing off does. The Delete dialog line was added. **Copy only: retention, deletion and privacy policy remain OPEN.** | settings/You tests |
| A2-07: backup and device migration | MAJOR | R6b | Documented as a release gate only. **OPEN.** | — |
| A2-08: I1 range vs. denominator | MINOR | R6b | The range spans the denominator window | `r6b_insight_dates_test` |
| A2-09: malformed dates; unreadable journal | MINOR | R6b, R6c | Canonical date check. Unreadable entries are written back verbatim. An unreadable wrapper is preserved before any save, and newer schemas are refused. Save failures are shown. | `r6b_journal_unreadable_preserved_test`, `r6c_journal_store_safety_test`, `r6_journal_save_failure_test` |
| A2-10: diversity metric | MINOR | R6b | `partRole`-based structural distinctness; coverage and B8 regenerated | B8 tests |
| A2-11: day boundary in a continuous session | MINOR | R6b, R6 final | The touch-driven day re-read never swallows an action. A stale unstarted offer can't start after midnight. A Circle started before midnight finishes under its own day, recorded once. | `r6b_day_rollover_test`, `test/core/app` |
| m1 / m3 / m6: Stage 5 line, I4 labels, four Free lines | MINOR | R6 | Founder copy applied | `r6_stage5_end_line_test`, `r6_free_copy_test` |
| m4: docs vs. implementation | MINOR | R6 | Amendment and status notes | — |
| m5: CRLF hash manifests | MINOR | R6 | `.gitattributes` `artifacts/**/*SHA1.txt text eol=lf` | `sha1sum -c` on a fresh checkout |
| A11y: busy state | — | R6 | "{label}, in progress", disabled, as a live region (purchase: "Become Premium, in progress") | `r6_button_busy_label_test`, `r6_purchase_busy_label_test` |

The tracker log (2026-10-21 → 2026-11-04) holds the details, the mutation checks and the founder decisions for each batch.

## Test results (R7, on this commit's source tree)

- **159/159 files; 2,353 passed, 0 failed, 0 skipped.** `flutter analyze` clean. See `README.md`, `COVERAGE_MANIFEST.json` and `CASE_COVERAGE.json`.
- All 13 year-long profiles ran, each exactly once; the B8 year simulations ran whole.
- **Audio:** 172/172 and 8/8 SHA-1 OK.

## Guarantees the reviewers should challenge

- **Premium:** RevenueCat is the only entitlement authority. `inactive` and `unavailable` never grant Premium; `unavailable` fails closed. Lapsed: I4 Keep works; other Premium Insight and Plan actions are gated; no Premium regeneration; eight kept slots.
- **Local data:** Delete semantics (R3); R4/R4.1 records preserved; an unreadable or newer-schema journal is never overwritten; save failures are visible and announced; owned History intact.
- **Daily Circle:** one Circle per day; no start of a stale offer after midnight; a Circle started before midnight closes once under its own day; no swallowed taps.
- **Audio:** compatible kept Circles stay voiced. Incompatible ones are wholly silent, with a note. No misleading clip plays. Frozen masters are changed only by the 9 recorded founder-approved Heather replacements.

## Known limitations of this evidence

- R7 repeated no device QA. Device evidence for R2, the F02/F03 S25 pass and the Heather S25 passes is in the tracker log.
- **Not device-validated:** midnight, a full process restart, a real RevenueCat lapse, direct audio-focus measurement.
- No real Play purchase has been made; billing is verified through the real adapter with the platform channel mocked.
- Analytics: the tester ID persists after consent is withdrawn; no remote delete exists.

## Release gates still OPEN (not addressed by this commit)

- **A2-06:** analytics retention, server-side deletion, privacy policy, verification of Supabase data handling.
- **A2-07:** Android backup and device migration; History and kept-Circle migration; RevenueCat restore; real-device transfer tests.
- **Pre-commercial security:** APK tampering; entitlement bypass attempts; anonymous subscription recovery; removing the production QA override; real-device release validation.
- **Multilingual launch:** all six languages; zero unapproved hard-coded text; Free/Premium parity; four voices per language; Circle terminology; native QA; final audits. These are planning documents only; none is in this commit.
- **Founder Dashboard:** standalone; separate approval. KEYBRACE OS is discontinued.

Reviewers report findings to the founder. Nothing is implemented automatically from a future audit.
