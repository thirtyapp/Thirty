# THIRTY — R8.3.3 consolidated integrity closure result

**Founder acceptance, 10 November 2026.** The founder accepted the three behavioral dispositions and authorized one auditable commit:

- the founder decisions are in `FOUNDER_DECISIONS_R833.md`;
- the failure classification is in `EVIDENCE_REGISTER.md`;
- the commit gates are in `commit_verification/`.

This document is the implementation result as it was reviewed. The sections below are unchanged.

- **Date:** 10 November 2026. Founder authorization of the same day.
- **Scope:** R832-A01, R832-A02 and AUD-R832-1 only.
- **No staging, commit, push, deployment or release has been made.**
- **Phase E: HOLD.**

## 1. Starting Git state

The full record is in `baseline/GIT_STATE_start.txt`.

| Item | Value |
|---|---|
| Branch | `step5-billing-integration` (worktree `Thirty-step5-billing-integration`) |
| HEAD | `d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2` |
| HEAD's tracking branch and live `origin` | both the same commit |
| Parent | `9c910773d7bfd3961be75fe3c9a44db41a1b7b27` |
| Tree | `2f78849d4b85f97ddac4b3bc14ba6ff77f1e8e60` |
| `origin/main` | `a8b4088` (untouched) |

The working tree already held changes unrelated to this work. They were preserved and left untouched:

- two files with line-ending-only modifications:
  - `quiet_trail_hero_asset_view.dart`;
  - `r6_kept_voice_whole_circle_test.dart`;
- untracked items, among them `AGENTS.md`, `android/build/`, `artwork/`, two quiet-trail PNGs, the R8.3.2 handoff and push record, and the Astra report.

The source manifest at the start has 383 Git blobs, identical to the manifest at the end of the R832-G1 run.

## 2. Audit report integrity

The SHA-256 of each input is in `audit_inputs/AUDIT_INPUT_HASHES.txt`, re-verified at the end in `AUDIT_INPUT_HASHES_end.txt`.

**Astra.** The report is `docs/audits/THIRTY_INDEPENDENT_POST_R8_3_2_DELTA_AUDIT.md`, SHA-256 `381f3cfd…`, unchanged. A copy is in `audit_inputs/`.

- Verdict: **FAIL**, with two findings: A01 (HIGH) and A02 (MEDIUM).
- Its evidence ZIP and three probes were **not available** on this machine. The probes were reconstructed from the report's §10 source chains: A01, A02-A and A02-B.

**Claude.** The report exists only as the final message of the audit session.

- Session: `fbb08042`. Transcript SHA-256 `c98f8a3c…`.
- Extracted copies:
  - the report text, `claude_post_r8_3_2_report_extracted.md`;
  - the raw transcript line, `claude_report_transcript_line553.jsonl`.
- Verdict: **CONDITIONAL PASS**, with one finding: AUD-R832-1 (LOW).
- Its executed probe file, `audit_r832_delta_test.dart` (SHA-256 `9c191c91…`), was copied byte for byte and run unedited.

The earlier post-R8.3 reports are unchanged: Astra `89a61f9f…` and Claude `d1e5e700…`.

## 3. A01 failing-before reproduction

The before runs used an immutable `git archive` of `d4cf8c44`. All 383 of its blobs were verified equal to the commit (`repro_before_fix/EXPORT_BLOBS_vs_d4cf8c44.txt`). The before and after reports and raw logs are in `repro_before_fix/` and `repro_after_fix/`.

**A01 (Astra), reproduced exactly:**

1. I2 is applied, and its Applied mark is refused.
2. The user turns gentler off and pauses the Plan.
3. Seven days on, an I1 is generated.
4. I1 is applied, and its reconciliation of I2 is held.
5. Delete begins. Its intent and its first Plans pass land.
6. The held write is released.

**Result on R8.3.2:**

- The Delete reported success.
- `apply` returned `done`.
- The Plan was carried on again: `lifecycle: active`, against the user's Pause.
- `circle_plans_v2` held `appliedInsight` = the deleted I1 id, both on disk and in `confirmedState`.

**Variants:**

| Variant | On R8.3.2 |
|---|---|
| v2: I2 continuing over an I1 being reconciled | **Fail.** Gentler was turned on after the Delete, and the I2 id survived. |
| v8: interrupted Delete | **Fail.** The Plan was carried on. |
| v9: repeated Delete | **Fail.** The Plan was carried on. |
| v11: user-owned choices | **Fail.** The Plan was carried on. |
| x1: an I3 continuing across Delete | **Fail.** The part was left out after the Delete; no deleted id survived. |
| x2: an I4 continuing across Delete | **Fail.** A Circle was kept from a History day that had been deleted; no deleted id survived. |
| v10: a fresh Insight after Delete | **N/A** (PRECONDITION). The Plan was already active, because of the defect itself. |
| v3: reconciliation refused, or throwing | Pass (control). |
| v4: Delete before any of the Insight's own writes | Pass (control). |
| v5: the Insight's target write held across Delete | Pass (control). |
| v6: Delete after the target write, before the Applied mark | Pass (control). |
| v7: Delete refused before its intent is durable | Pass (control). |

## 4. A02 failing-before reproductions

Both variants run through production `assess()`, in one container with one cached `nowProvider` value. The setup is:

- an I4 generated on 2026-10-30 and retained;
- thirty days on, two newer useful Writing Circles;
- the older I4 applied, then a newer I4 generated for a different Circle (2026-11-27).

**A02-A, two successful Keeps.** Both kept Circles got `kept-1795939200000000-insight`. One rename renamed both. One removal removed both.

**A02-B, false proof.**

1. I4-A's Keep throws before landing, so only its receipt remains.
2. I4-B keeps 2026-11-27 under the same id.
3. On reassessment, I4-A was **marked Applied, dated 2026-11-29**, although no Circle from its own day (2026-10-29) was ever kept.

**Further failures on R8.3.2:**

- **A02-B2, a legacy stored collision.** It was taken as proof.
- **A02-C, a caller id already in use.** The id was accepted.
- **A02-D, two concurrent Keeps with one id.** Both landed.
- **A02-E, legacy duplicate ids.** One rename renamed both.
- **A02-I, Delete.** Only one id remained across the two Circles.

**Controls that pass on both trees:**

- A02-F, without Premium;
- A02-G, a Keep landing just before the process stops: proof with its original date;
- A02-H, a refused Keep and its retry.

## 5. AUD-R832-1 reproduction

Claude's own probes were run unedited.

| Probe | Pre-G1 (Claude's record) | R8.3.2 (Claude's run) | R8.3.3 |
|---|---|---|---|
| X1: the pending Resume is refused and rolled back; Resume again | started, 1 credit | started, 1 credit | **notStarted, 0 credits** |
| X2: the pending Resume is refused; Pause and Resume confirmed after it | started, 1 credit | started, 1 credit | **notStarted, 0 credits** |
| X2-ctl: the pending Resume lands; then Pause and Resume | started | cancelled | cancelled |

The evidence is in `auditor_controls/CLAUDE_R832_PROBES_evidence_on_fixed.txt`.

The R8.3.3 suite repeats these with assertions. On R8.3.2, X1 and X2 **fail**; X2-ctl, X-ctl, X3 and X4 pass. X3 is an uncertain Resume; X4 is a restart.

## 6. Proven root causes

**A01.**

- `InsightsNotifier.apply` is a multi-await operation that captured its inputs once.
- Delete's barrier, `HistoryWriteGate.epoch`, guarded only Today's writes and each store's queue. Nothing re-checked Delete after the reconciliation await.
- Plans `_set` captures `_deletions` when it queues a write. A write queued after Delete's first pass is therefore treated as post-Delete, and keeps its new `appliedInsight`.
- Delete's last pass did not run the Plans pass again.

**A02.**

- The I4 id was `kept-${nowProvider µs}-insight`, from a cached clock, so every I4 of one epoch shared it.
- `keepCircle(id:)` did not check whether the id was unique.
- `_appliedOn` matched the id alone, without the source Circle.
- `renameKept` and `deleteKept` act on every Circle with the id.

**AUD-R832-1.** `startConditions` added +1 when a lifecycle change was pending. `_startStillValid` compared only that count. Any later confirmed transition could satisfy it.

## 7. Exact production changes

The diff is `source_diffs/R833_production_vs_d4cf8c44.diff`: 5 files, +252/−45.

- **`insights_provider.dart` (A01, A02).**
  - The deletion epoch is captured at the start of `apply`.
  - `_stillCurrent(epoch)` is checked after every wait and just before each mutation: receipt, receipt clearance, displaced mark, Plan change, left-out part, Keep and the final mark.
  - A stopped operation returns `notAvailable`.
  - The I4 id comes from `newKeptId(tag: 'insight')`.
  - I4 proof requires the recorded `keptId` **and** `fromCircleId` = the source, with the attempt target checked as well.
- **`kept_circles_provider.dart` (A02).**
  - New: `keptIdRandomProvider`, `newKeptId`, `KeptCircles.addressedBy` and in-flight `_keepingIds`.
  - `keepCircle` refuses an id that is already in use.
  - `renameKept` and `deleteKept` change nothing when an id addresses more than one Circle.
- **`circle_plans_provider.dart` (AUD-R832-1).**
  - Each save is numbered: `_saves`.
  - `_shownMovedBy` and `_countedFrom` record which save moved each Plan and which save made each counted change.
  - `PlanStartConditions.pendingSave` is new.
  - `_startStillValid` requires the change counted since the tap to come from that save.
- **`circle_history_deletion.dart` (A01, defence only).** The last pass repeats `plans.forgetStageEvidence()`. It replaces the separate removal of the unreadable Plans copy, which the Plans pass already performs.
- **`lib/core/qa/qa_scenario.dart` (supporting).**
  - The QA store builder's own container seeds `keptIdRandomProvider` with `Random(0)`, so its documented determinism holds.
  - The need was found by diagnostic run 1; see `TEST_CHANGES.md`.

## 8. Passing-after results

| Suite | Result |
|---|---|
| `r833_reproduction_test.dart` | **30/30** (R8.3.2: 13 pass, 17 fail; one of the 17 is a PRECONDITION N/A) |
| `r833_identity_contract_test.dart` | **3/3** (R8.3.2: does not compile; N/A) |

The identity contract file covers three cases:

- forced collisions with a stuck clock and a stuck random source;
- a forced collision against I4-A's recorded id, which is never taken as proof;
- a retained-key id, which is refused.

## 9–11. Contracts

See **`CONTRACTS_R833.md`**, which covers:

- **§1, Delete isolation:** the epoch barrier, and the defensive pass, which is not itself the fix;
- **§2, I4 identity and ownership:** allocation, domain uniqueness, two-key proof, and handling of legacy duplicates;
- **§3, pending-Start write identity:** binding the Start to its exact save, and its UX consequence.

## 12. Prior regression controls

The runs are in `focused/` and `auditor_controls/`.

| Controls | Result |
|---|---|
| R8.1, R8.2, R8.3 and R8.3.2 focused adversarial suites | **482/482**, the same count Claude recorded |
| R8.3.2 reproductions | 42/42 |
| R8.3.2 founder scope | 30/30 |
| G1 | 22/22 |
| Final-gate checks | **10/10** |
| Original independent auditor controls | **26 PASS + 1 AUD-O3** |
| Claude's post-R8.3.2 probes | 6 completed, 1 failed |

**AUD-O3** is superseded by N01-C, not passed. Its original bytes are unchanged and it is recorded as superseded.

**Claude's post-R8.3.2 probes.** One test, X4, fails at its own precondition ("I2 current"): the setup cannot be built. Claude's report records exactly this.

These preserved outcomes cover:

- R8.2;
- R83-N01, N02 and N03;
- AUD-R83-1, 2 and 3;
- R832-B1 and B2;
- R832-G1 (A1–A5, G1–G7);
- N01-C and founder decisions D1–D5;
- the credit cases:
  - Start → Pause → Close is credited;
  - Pause → Start → Close is not;
  - Close-before-Leave is credited;
- safe Insight retry, with the original dates;
- Kept Circles ownership;
- Preferences retention through Delete.

## 13. Full Flutter regression and raw evidence

The definitive run is **run 2**, in `regression/`: 11:23–11:52, sequential, with the runner copied unchanged except `OUT` (`RUNNER_DIFF_vs_R832_G1.txt`).

| Check | Result |
|---|---|
| Files | **206** |
| Passed | **2,999** = 2,966 + 33 |
| Failed | **0** |
| Skipped | **0** |
| Batches and parts | 23 batch and part logs, every one `done=True`, exit 0 |
| Validators | EVIDENCE OK; CASES OK |
| Inventory reconciliation | INVENTORY OK. The two r833 files are the only count changes against the G1 run. |
| My own raw-log recount (`INDEPENDENT_RAW_RECOUNT.txt`) | 206 file rows, success 2,999 |
| Year-long profiles | **13 of 13** declared, each run exactly once |
| B8 | **6/6** |
| Start and end source fingerprints | identical |
| Start and end blob manifests | identical |

**Run 1 is not counted.** It is in `regression_run1_DIAGNOSTIC_INCOMPLETE/`. That run:

- found the `qa_scenario_test` determinism failure;
- was then stopped by Claude Code for low system memory, during B8.

The earlier 2,966-pass evidence (`artifacts/r8_3_2_g1_closure_2026-11-09/`) is unchanged.

## 14. Source, analyzer and audio integrity

- **Source manifest** (`SOURCE_MANIFEST_DELTA_vs_d4cf8c44.txt`): 383 → 385 entries. Changed: exactly the 5 production files above. Added: the 2 r833 tests. Nothing else.
- **`flutter analyze`:** "No issues found!", exit 0 (`FLUTTER_ANALYZE.txt`).
- **Audio:** 180/180 Git blobs unchanged (`AUDIO_VERIFICATION.txt`).
- **No other changes** to billing, entitlement, Premium, dependencies (`pubspec.*`), platform folders, assets or localization.

## 15. Remaining limitations and L-1

- **L-1: OPEN — NOT FIXED — NOT WAIVED — PRE-RELEASE BLOCKER.**
  - Wholly unreadable Preferences survive a Delete reported as successful, and Export omits them.
  - R8.3.3 does not touch this. A01 concerned readable current-schema data and is a different defect.
- **Founder decision needed: a repair policy for legacy duplicate kept ids.**
  - Only a build of `d4cf8c44` can have written them: two I4 applications on one cached day. That build was never released.
  - R8.3.3 keeps such records as stored. Neither can be renamed or removed by id, because one action never changes two Circles.
  - A repair would change stored ownership identifiers, so it was not implemented.
- **Disclosed behavior change:** an I3 or I4 that the user tapped just before Delete, and whose change had not yet been queued when Delete began, is now cancelled (`notAvailable`).
- **Disclosed UX change:** a pending Start is cancelled, and the user taps Start again, whenever the save the user saw is refused or uncertain — even when another save produces the same place.
- **Inherited limits, unchanged:**
  - in-memory generations and save numbers;
  - simulated restarts only — no real Android process kill, power loss or storage-fault proof;
  - RL-4, ambiguous historical timestamps;
  - conservative availability of an unresolved receipt, and its "No longer current" wording;
  - the D5 cohort item;
  - S25 and TalkBack;
  - real billing and restore validation.
- **No other HIGH Delete or user-data defect was found.** I3 and I4 crossing a Delete share A01's root cause, are fixed by the same barrier, and left no deleted id behind.

## 16. Working-tree inventory at the end (`WORKING_TREE_INVENTORY_end.txt`)

New since the start:

- ` M` the 5 production files in §7;
- `??` `test/features/r833/`, two files.

This evidence folder existed before the start inventory was recorded. Everything else is exactly as at baseline, including the two line-ending-only files and the unrelated untracked items. The prior evidence folders and the Astra report are unchanged.

## 17. Verdict and next gate

**IMPLEMENTATION PASS — awaiting founder review.**

- All three findings are reproduced on the immutable R8.3.2 tree, their root causes are corrected, and their failing-before scenarios pass after.
- Every prior control is preserved. The full regression is 2,999/0/0.

**Recommended next acceptance gate:**

1. The founder decides two things:
   - the repair policy for legacy duplicate ids;
   - confirmation of the two disclosed behavior changes.
2. With those settled, an authorized commit and push of R8.3.3 together with this evidence.
3. Independent targeted delta audits of R8.3.3, by Claude and Astra.

**L-1 still blocks release. Phase E stays HOLD.**
