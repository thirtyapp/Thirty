# THIRTY R8.2: independent audit handoff (Astra and Claude)

- **For:** both independent reviewers of the post-R8.1 round, auditing separately.
- **Status:**
  - The founder accepted R8.2 at engineering implementation level on 2026-11-06.
  - This is **not** an independent audit pass and **not** a commercial release authorization.
  - THIRTY Phase E remains **HOLD**.
  - Neither audit has been started. Each starts only when the founder starts it.

## 1. Commit under audit

| Item | Value |
|---|---|
| Repository and branch | `thirtyapp/Thirty`, `step5-billing-integration` |
| R8.2 commit | The single commit that adds this file. Its full SHA is in the founder's commit and push report and in the local `R8_2_PUSH_RECORD.md`: a commit can't contain its own hash. |
| Parent (R8.1) | `e935112c408c16d99835280f4e1fafd722d47ed1` |
| Subject | `fix(thirty): close R8.2 cross-store integrity audit findings` |

**Inventory.** What is in the commit, and what was deliberately left out, is listed in `COMMIT_INVENTORY.md`.

## 2. Original post-R8.1 audit reports (committed unchanged)

| Report | Path | SHA-256 | Bytes |
|---|---|---|---|
| Astra (FAIL) | `docs/audits/THIRTY_INDEPENDENT_POST_R8_1_AUDIT.md` | `afb0dd9ad6e82774bb963e67c6749b44a9505c18954af037ac8a3c565c0c375a` | 104,664 |
| Claude (CONDITIONAL PASS) | `docs/audits/THIRTY_CLAUDE_POST_R8_1_AUDIT_REPORT.txt` | `96593e20a24cba993dc45973118d2ed021dcae25c465fa0078ac87b29e4c23a1` | 52,094 |

- **Unchanged.** Both are LF text, and the committed blobs are byte-identical to what was delivered. Neither was edited.
- **When the Claude report arrived.** It reached the work on 2026-11-06 at 09:08. That was after the R8.2 remediation and founder decisions A–C had been built from the founder directive's description of it. It was reconciled after that. The register keeps a record of when it was not available.

## 3–4. Finding mapping

The full record of every entry is `ISSUE_REGISTER.json`: reproduction, root cause, fix, files, tests and status. For the Claude entries it also holds the check against the original report (`originalReportCheck`).

| ID | Severity | Finding | Fix (short) | Tests |
|---|---|---|---|---|
| R81-A01 | HIGH | A pending failed Pause bypasses the durable-credit prerequisite | `recordGuided` separates credited on disk, pending, not owed, and owed but blocked; a blocked credit waits for the pending change to settle and is checked again | `r82_a01_pending_lifecycle_credit_test` |
| R81-A02 / NEW-2 | HIGH | Delete can finish with recreated Insight metadata | Deleted data leaves the rollback and decision snapshots at once (deletion generation); no assessment during a Delete; Delete waits for Plans and Insights queues | `r82_a02_new2_delete_isolation_test` |
| R81-A03 | MEDIUM | Stage publication checks the live offer, not the payload | `_publish` gates on the payload's own stage; an unsaveable stage Circle is never written and is taken back, narrowed by FD-B | `r82_a03_new1_stage_publication_test` |
| NEW-1 | MEDIUM (blocking) | A published stage Circle becomes unsaveable after legitimate Plan actions | Gate only when a write publishes a stage Circle; `confirmStartNoted` / `noteStart` settle that Circle's own served record | `r82_a03_new1_stage_publication_test`, `r82_claude_audit_new1_triggers_test` (CR-1) |
| R81-A04 | MEDIUM | I2 checks cycle A but applies gentler to pending cycle B | `apply()` waits for pending Plans and History writes; `keepGentler` takes the Insight's cycle id | `r82_a04_a08_new3_insight_actions_test` |
| R81-A05 | MEDIUM | Readable nested records lose unknown or damaged fields | Records keep their stored maps; malformed Booleans and dates make the record unreadable, kept as stored | `r82_a05_nested_fields_test` |
| R81-A06 | MEDIUM | Removing an overnight answer reopens a finished reflection | Durable day key `recommendation_reflection_finished` | `r82_a06_reflection_completion_test` |
| R81-A07 | MEDIUM | Pending History cache state can create a durable Insight | `JournalWrites` tracker; `readConfirmed()` is used by Insights, stage answers and application | `r82_a07_confirmed_history_test` |
| R81-A08 / Claude marker-retry | LOW | I1–I3 can't repair a failed applied marker | Replaced by FD-C, see §5 | `r82_a04_a08_new3_insight_actions_test`, `r82_decision_c_insight_provenance_test` |
| R81-A09 | MEDIUM | Wrong native preference types bypass unreadable-store recovery | `prefs.get` and a type check; Plans and Insights keep the value aside with its native type; Preferences refuse changes until Reset | `r82_a09_native_types_test` |
| NEW-3 | LOW | False notSaved when a later queued write already made the change durable | `confirmed()` waits and checks every changed value in the confirmed final state | `r82_a04_a08_new3_insight_actions_test` |
| E-1 | evidence tooling | The report accepts missing or incomplete declared parts | New runner: declared parts, exact identity, command and files, per-case coverage | `e1_runner_check/`, `claude_audit_reconciliation/e1_mutation/` |

- **Earlier IDs.** AUD-1 to AUD-6 (Claude) and N01–N10 (Astra) are R8 findings. Both post-R8.1 reports verify them as closed, and they stay in the committed R8.1 register.
- **Related entries.** Also registered:
  - CR-1, a coverage gap with no defect;
  - FD-B-1 (HIGH) and FD-B-2 (MEDIUM), both introduced and fixed during the founder-decision work, before any regression;
  - RL-4, accepted and unchanged.

## 5. Applied-marker repair reconciliation (R81-A08, the Claude observation, FD-C)

- **What the two reports describe.**
  - Astra A08: after the target change succeeded, a failed applied marker could never be repaired, because the status gate exited first.
  - Claude: the retry returns alreadyApplied without marking.
  - Both describe the same exit from different sides. See `originalReportCheck` on that entry.
- **Founder decision C (final).**
  - The I1 or I2 Plan change saves the Insight's id, cycle and day on the Plan (`PlanProgress.appliedInsight`), in the change's own save. The I3 leave-out saves it on the part (`ElementLeftOut.byInsight`).
  - A retry marks applied only when that provenance names this Insight; for I2 it must also name that exact cycle.
  - Otherwise it reports "not available", never "applied". A manual action carries no provenance and is never attributed.
  - No separate intent write exists that could fail on its own.
- **Limitation (LOW).** Provenance is one record per Plan. A later Insight on the same Plan replaces the earlier one's record, and an earlier mark that also failed is then reported not available, not repaired.

## 6. Founder decisions A–C (`founder_decisions/`)

- **A: historical Plan credit.** A Close durable before a later Pause, Leave, another Plan's Start or "Go through it again" keeps its credit. The credit is folded into that change's own save, on the original cycle and Circle, at most once.
- **B: failed save during Start.** A Circle starts only once its own first publication is on disk. A failed save refuses the Start; it never takes back a started Circle.
- **C: I1–I3 marker repair.** Repaired only from persisted provenance of the Insight's own change (§5).

## 7. Final Plan lifecycle policy (`lifecycle_policy/`)

| Order of actions | Result |
|---|---|
| Start → Pause, or another Plan started → Close durable | Credited to the original Plan, cycle, stage and Circle; the Plan stays paused |
| Start → Leave → Close | No credit; the Close is kept in History |
| Start → Close requested → Leave, Close still being saved | Credited once the Close is durable, to the cycle that was left |
| Close never durable | No credit, including after restarts |
| A Start alone | Never credited |
| Pause before a valid Start | No credit (confirmed by the founder, 2026-11-06) |
| Premium | The existing served-and-started-under-Premium rule, unchanged |

## 8. Failing-before → passing-after

| Work | Failing before | Passing after | Evidence |
|---|---|---|---|
| R8.2 findings | 103 tests on `e935112c`: **73 fail** | all pass | `repro_before_fix/` |
| Founder decisions A–C | 45 tests: **30 fail** | all pass | `founder_decisions/repro_before_fix/`, `cross_store_review/` |
| CR-1 (NEW-1 triggers) | 5/5 fail on R8.1 | 5/5 | `claude_audit_reconciliation/new_regression_test/` |
| Claude report, adapted reproductions | 6/6 fail on R8.1 | 6/6 | `claude_audit_reconciliation/adapted_repro/` |
| Lifecycle policy | 21 tests: **9 fail** | 21/21; targeted 1,487/0 | `lifecycle_policy/repro_before_fix/`, `passing_after/` |
| E-1 | R8.1 runner accepts damaged evidence | R8.2 runner rejects all six damaged copies | `e1_runner_check/` |

**Assertion changes to existing tests.** These are listed with their reasons in `CHANGES.md`, `founder_decisions/test_change_diffs/` and `lifecycle_policy/test_change_diffs/`.
- They follow decision B (refused Start) and the lifecycle policy (Pause before Close is credited).
- The other edits to existing tests add an `await settle()` between `start()` and the next action, because the Start now waits for its save.
- A pre-commit probe (`precommit_review/`, run on an export of the tested tree) shows that Close, Skip, Leave out and Pause tapped while a Start is still pending do nothing, and that one Close is saved once afterwards. So the settles don't hide a failure. That probe is not part of the suite.

## 9. The five unchanged original Claude reproducer failures

The auditor's three test files are preserved unchanged, with their hashes, in `claude_audit_reconciliation/original_auditor_repro/`.
- **Results:** R8.1 4 pass / 9 fail, as reported; R8.2 8 pass / 5 fail.
- **The five, one by one:** see `AUDIT_HANDOFF_R8_2.md` §2.
  - A2 ×2 and DIAG A2 assert the replaced R8.1 "stays on screen" behaviour.
  - A3 ×2 is a date-substring false positive: the Circle id equals the cycle's `startedOn`.

## 10–11. Definitive full regression (`lifecycle_policy/regression_rerun/`)

- **Totals:** 193/193 test files, **2,774 passed, 0 failed, 0 skipped**.
- **Runner checks:** batches 1–17 and 18a–e each exit 0, and each completed successfully. EVIDENCE OK; CASES OK.
- **Year profiles:** 13/13 (p01–p11, p13, p14), each exactly once.
- **B8:** 6/6, cases A–E and "voice follows the entitlement".
- **Independent inventory check:** `INVENTORY_RECONCILIATION.txt`. No (file, test) pair ran twice. Against the 2,753 run, the only count change is the 21 lifecycle tests.
- **Other checks:** `flutter analyze` is clean. Audio is 172/172 production and 8/8 framing SHA-1, with exactly 180 bundled files. Fingerprints are identical at preflight, start and end (371 files).
- **Not evidence:** `lifecycle_policy/regression_final/` was interrupted, and is kept only as that record (`INTERRUPTED.txt`). The earlier complete runs are each labelled `SUPERSEDED.txt`.

## 12. Committed-source blob verification

The definitive manifest is `lifecycle_policy/regression_rerun/SOURCE_MANIFEST_git_blobs.txt`: one `<git blob id> <path>` per line, covering 371 files. Those are `analysis_options.yaml`, `pubspec.yaml`, `pubspec.lock` and every file under `lib/` and `test/`. Check the commit against it:

```sh
C=<R8.2 commit SHA>
M=artifacts/r8_2_consolidated_remediation_2026-11-05/lifecycle_policy/regression_rerun/SOURCE_MANIFEST_git_blobs.txt
diff <(git ls-tree -r $C -- analysis_options.yaml pubspec.yaml pubspec.lock lib test | awk '{print $3" "$4}' | LC_ALL=C sort -k2) \
     <(git show $C:$M | tr -d '\r' | LC_ALL=C sort -k2) && echo "committed source == tested source"
```

Also check:
- `git diff --stat e935112c <SHA> -- lib test pubspec.yaml pubspec.lock analysis_options.yaml`, against `CHANGES.md`;
- `sha256sum` of the two reports, against §2.

## 13. Known limitations and commercial-release blockers

These are accepted at implementation level only. None is a commercial-release approval.

- **No real Android process-kill verification.** Restarts are simulated in-process on what reached the simulated disk (`test/support/r8_harness.dart`); see `AUDIT_HANDOFF_R8_2.md` §5.
- **No S25 or TalkBack verification of R8.2. No real Android storage-failure testing.**
- **Memory-held action order.** The order of Start/Close relative to Pause/Leave is held in memory until the Pause or Leave is saved; after a restart it is reported again from what was restored.
- **RL-4.** Legacy offset-free timestamps are ambiguous in the repeated autumn hour. Its pre-commercial decision is still open for the founder.
- **No Start pending indicator, and the wording of one refusal** (`LIMITATIONS_R8_2.md` items 2–3).
- **Limited historical Insight attribution:** one provenance record per Plan (§5).
- **Existing unreadable Plan and Preferences restrictions.** An unreadable Plan can't be started over; unreadable Preferences refuse changes until Reset.
- **Lifecycle LOW points.**
  - Stage 5 credited on a paused Plan ends the Plan.
  - A stage 5 cycle that was left stays "left".
  - In the RL-4 hour, a History-based fallback or fold can withhold credit, never wrongly grant it.
- **Commercial.**
  - No commercial release is authorized, and Phase E is HOLD.
  - The delivery tracker (`docs/product/THIRTY_V2_DELIVERY_TRACKER.md`) keeps Phase E on HOLD, and it is the only implementation status.
  - Both independent audits of this commit must return first.
  - Release billing must fail without valid RevenueCat configuration; no bypass exists or may be added.

## Request to both auditors

Please independently **look for defects R8.2 introduced**, not only confirm that the listed findings appear fixed. Challenge in particular:

1. **Cross-store action ordering.** Today, Plans, Insights and History writes queued against each other, including the lifecycle stamps written inside the Pause or Leave save.
2. **Failed Plan credit and late recovery.** Restart catch-up, the decision A fold, and the A01 credit-resolution loop.
3. **Delete isolation.** Deletion generations, queued saves landing after a Delete, interrupted Delete.
4. **Historical stage-Circle durability.** The A03 and NEW-1 gate, withdrawal of an unstarted offer, decision B Start refusal.
5. **Insight attribution and retry.** FD-C provenance, NEW-3 `confirmed()`, the I2 cycle identity.
6. **Optimistic versus confirmed snapshots.** `_durable`, `confirmedState`, `readConfirmed()`, rollback after failures.
7. **Reflection completion around midnight.** The A06 marker, the carried-over Circle, the new-day opening.
8. **Malformed and future-schema data.** Nested fields, malformed lifecycle stamps, records kept aside.
9. **Native SharedPreferences behaviour.** Wrong native types, `writeConfirmed`, platform-write timing that the in-memory fault disk may not model.
10. **Memory-only action-order provenance.** What a real process death between tap and save does.
11. **Process restart and recovery limitations.** Where the in-process restart simulation could diverge from Android.
