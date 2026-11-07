# THIRTY — independent delta audit handoff: R8.3 + R8.3.1

**For:** Claude and GPT-6 Astra, each working **independently**.

**What to audit:**
- **Target:** the commit that contains this file on `step5-billing-integration`. Its parent must be `e744f505d5fe2cf5ec4e56d79b2a61dbe09684c8` (R8.2). The exact SHA is recorded after the push and was reported to the founder.
- **Method:** audit only an immutable export of that commit (`git -c core.autocrlf=false archive <sha>`), never a working tree.

**Status:**
- Founder-accepted at implementation level.
- **Not** independently audited. **Not** release-authorized. Phase E: HOLD.
- **Known OPEN pre-release blocker: L-1** (§8). You assess its impact on technical-baseline acceptance yourselves. You are not asked to waive it.

**Do not assume correctness because the regression is green.** R8 → R8.1 → R8.2 each shipped same-class defects past a passing suite. The tests are evidence, not proof.

## 1. Inputs, preserved byte-identical

| File | SHA-256 |
|---|---|
| `docs/audits/THIRTY_INDEPENDENT_POST_R8_2_AUDIT.md` (Astra) | `a6f5984b0681bb375a407e450de277ce0a29912105d096943006096ca35e9e43` |
| `docs/audits/THIRTY_CLAUDE_INDEPENDENT_POST_R8_2_AUDIT.txt` (Claude) | `2fc8766eb1916758e6bf369261e168da622fb00abb4af12a1f64ac457932cc8f` |
| `artifacts/pre_r8_3_architecture_review_2026-11-06/ARCHITECTURE_REVIEW.md` | `bfb9acfab9419a546f05eb4894dc0bf116864f488749fe04e2cfae6740eb7581` |

The founder decisions (D1–D5, R83-F1 Option B, the L-1 deferral) are recorded in `FOUNDER_DECISIONS.md`.

## 2. What changed

**Production: 15 files under `lib/`.**

| Area | Files | Findings |
|---|---|---|
| Codec rule | `plans/domain/circle_plan.dart` (`ServedStageCircle.toJson`, `AppliedInsight.extra`) | Astra R82-N03 = Claude AUD-N1; Astra R82-N04 |
| Delete and Plans | `plans/application/circle_plans_provider.dart` (`forgetStageEvidence`) | Claude AUD-N2, AUD-N3 (D4) |
| Preference outcome | `home/application/suggestion_preferences.dart` (`PreferenceChange`, `idle`, `leaveOutChange`, `forgetInsightProvenance`) | Astra R82-N02; O-1 (D1) |
| Provenance-first apply | `insights/application/insights_provider.dart` | Astra R82-N01 (D3), R82-N02 |
| Start boundary | `home/application/recommendation_provider.dart` (`_startOnceSaved`) | Astra R82-N05; R83-F1 |
| Delete coordinator | `home/application/circle_history_deletion.dart` | O-1 (D1) |
| Start-up type safety | `v1_premium_retirement.dart`, `reminder_provider.dart`, `analytics_consent.dart`, `tester_identity_provider.dart`, `first_breath_provider.dart`, `premium_offer_provider.dart` + card, `reminder_invitation_provider.dart` + card | O-2 (D5) |
| Start eligibility (R8.3.1) | `circle_plan.dart` (`PlanProgress.startedWhilePaused`, `noteStartedWhilePaused`, `recordGuided`), `circle_plans_provider.dart` (`noteStartWhilePaused`, `startNeedsNoWrite`), `recommendation_provider.dart` | R83-F1 (founder Option B) |

**Tests:**
- `test/support/r8_fault_disk.dart`: the ack-lost fault and the same-key overlap detector. `DiskFault` itself is unchanged.
- New: `test/support/r83_invariants.dart` (the disk-only oracle) and 8 files in `test/features/r83/` (98 tests).
- No existing test file changed.

**Diffs:**
- `source_diffs/lib.diff` (R8.3 vs `e744f505`);
- `../r8_3_1_founder_lifecycle_correction_2026-11-07/source_diffs/r831_lib_vs_R8_3.diff`;
- `../r8_3_1_founder_lifecycle_correction_2026-11-07/source_diffs/full_lib_test_vs_HEAD.diff`.

## 3. What to verify

1. **The seven R8.2 findings are closed in the source:**
   - Astra R82-N01–N05;
   - Claude AUD-N1 (= N03), AUD-N2, AUD-N3.

   Failing-before evidence:
   - `repro_before_fix/` (30 of 74 on a clean `git archive` export of e744f505);
   - `auditor_controls/`: Astra's Appendix B, executed for the first time (7/7 fail on R8.2, 7/7 pass after); Claude's own adversarial file.
2. **R83-F1 and the lifecycle table** (`FOUNDER_DECISIONS.md`): `r831_start_eligibility_test.dart`, 24 tests (11 fail on both R8.2 and R8.3, and pass after).
   - **Paths to check:** the immediate Close, the decision-A fold, the restart catch-up, the next-day overwrite safety net after `lastServed` is replaced, Pause/Resume, and starting another Plan.
   - **Points to challenge:**
     - the fact is a single slot per Plan (`startedWhilePaused` = one circleId). Its justification is that only one day's Circle is ever still to be caught up;
     - the fact is judged from the Plan *as shown* (optimistic) at the valid Start.
3. **D1–D5:**
   - **D1:** no Preferences mutation before the intent is durable; removal of the attribution in both passes and at start-up completion.
   - **D2:** a Pause while the Start is pending earns no credit.
   - **D3:** the original date, and no repeated action.
   - **D4:** the Delete write is computed from `_durable` at its queue turn.
   - **D5:** the 9 start-up sites; no default is written over an unexpected stored value.
4. **The six invariants:**
   - I: durable confirmation and distinct outcomes;
   - II: provenance;
   - III: idempotence;
   - IV: revalidation after an await;
   - V: the codec, including the new field and its damaged-value rule;
   - VI: Delete completeness.

   The oracle: `test/support/r83_invariants.dart`.
5. **Cross-store ordering and provenance:** a manual change queued ahead of an Insight; a target saved but its mark refused; an ack-lost write; the stage-5 boundaries (`r83_cross_store_test.dart`).
6. **Delete isolation and successful-Delete semantics:**
   - a refused intent;
   - pending Plans or Preferences writes;
   - a refused attribution removal (the Delete must fail);
   - the app stopping after the intent;
   - same-day re-serving after Delete.
7. **Start-up and native type safety:** `r83_startup_types_test.dart`, including 4 `ThirtyApp` cold starts.
8. **Serialization round trips:** `r83_codec_law_test.dart`. Note: `InsightSnapshot.toJson` keeps the same overlay pattern, with no clearing path today (not changed).
9. **Evidence tooling (E-1 residual):** `e1_raw_validation/`. Before: the R8.2 runner accepts all 10 raw-log damages. After: the R8.3 runner rejects all 10.

## 4. Regression evidence

**Definitive final run:** `../r8_3_1_founder_lifecycle_correction_2026-11-07/regression/`.

- **Totals:** 201/201 files, **2,872 passed, 0 failed, 0 skipped**.
- **Batches:** 23 raw logs (batches 1–18 and 19a–e), every one exit 0, each with exactly one terminal `done` of success, last.
- **Coverage:** 13/13 year profiles, each once; B8 6/6; EVIDENCE OK and CASES OK (raw-validated); INVENTORY OK.
- **Integrity:** fingerprints and Git-blob manifests identical from preflight to end (380 files).
- **Re-verified independently** before the commit (`../r8_3_1_founder_lifecycle_correction_2026-11-07/commit_verification/`).

**Earlier runs:**
- **Pre-R8.3.1 (valid, not final):** `regression/` in this folder, 200 files, 2,848/0.
- **Superseded and not included:** R8.3 run 1. It was incomplete because a driver CRLF bug meant parts 19a–d never ran.

**Verification order for an auditor:**
1. Read the raw `.jsonl` terminal events and per-test outcomes yourselves, before trusting any summary.
2. Compare `SOURCE_MANIFEST_git_blobs_end.txt` with `git ls-tree -r <sha> lib test` and the 3 configuration files.

## 5. Real versus simulated

Every "restart" is `R8Harness.restart()`, a new SharedPreferences over the simulated disk's confirmed bytes, inside one Dart process. The ack-lost fault is likewise a simulation.

None of this is evidence of real Android process-kill, power-loss or storage-fault safety. No device, S25 or TalkBack run was done for R8.3.

## 6. Accepted limitations (`LIMITATIONS_R8_3.md`)

- **L-2:** one provenance record per Plan.
- **L-3:** QA and dev-preview typed getters left as they are.
- **L-5:** simulation only.
- **L-6:** the overlap guard records but isn't enforced globally.
- A Resume during the ~ms eligibility write counts the Start as paused (conservative).
- **RL-4:** offset-free historical timestamps, a pre-commercial decision.

## 7. Known residual auditor results

On both R8.2 and R8.3/R8.3.1, the R8.1 Claude originals fail 5 tests (A2 ×2, DIAG A2, A3 ×2). The R8.2 reconciliation already classified these as an obsolete expectation and a defective substring assertion. The adapted versions pass 6/6.

## 8. L-1: OPEN — PRE-RELEASE BLOCKER

**What happens.** A Suggestion Preferences record that THIRTY can't read as a whole survives Delete Circle history with any Insight attribution inside it, and the Delete reports success. Export does not include such a record.

**Why it was deferred, not fixed.** The record is never applied, so it influences no recommendation or Insight. Removing or rewriting it automatically could destroy explicit user preferences or a newer schema's fields.

**Founder disposition (2026-11-07):** deferred. Not fixed, not waived. No commercial release until a safe Delete/Export disposition is implemented and verified.

**Evidence:** `../r8_3_1_founder_lifecycle_correction_2026-11-07/l1_assessment/`.

## 9. Not in scope; unchanged

Billing, RevenueCat, entitlement rules, Kept Circles ownership, localization, artwork, audio (180 files, SHA-1 verified) and dependencies.
