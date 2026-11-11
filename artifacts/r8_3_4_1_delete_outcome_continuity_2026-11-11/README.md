# THIRTY — R8.3.4.1 Delete outcome continuity (Astra R834-N01)

Founder directive, 11 November 2026. Branch `step5-billing-integration`.

- Start SHA: `dd9000cdd461c41d52a727f323b8e5c1003fefa0`, parent `285b5c70…`.
- At the start, HEAD, upstream and live origin all pointed at this SHA (`baseline/GIT_STATE_start.txt`).
- No staging, commit or push has happened. L-1 is still OPEN. Phase E is on HOLD.

See `CONTRACT_R8341.md` for the root cause, the correction, the outcome contract and the disclosed limitation.

## Inputs (`audit_inputs/`)

| Input | SHA-256 |
|---|---|
| Astra report `docs/audits/THIRTY_FINAL_R8_3_4_INDEPENDENT_ACCEPTANCE_VERIFICATION.md` (untracked, not copied) | `3f1cb4ca4d5688e58d8a15369c98a6e1cd637f56eb4e4d535b30c2cab626184a` |
| Astra ZIP `docs/audits/THIRTY_R834_INDEPENDENT_ACCEPTANCE_EVIDENCE.zip` (untracked, not copied) | `bc4acd9d65f1dd4d8d53787a10e01c7c61a53d545594e46a8353335bbfb50191` |
| Astra probe, original bytes (`r834_acceptance_boundary_test.ORIGINAL.dart.txt`) | `b60a8bbd0f918dffbbef941ac639feafbf23cfc9988e1f50ac2b1605552916ad` |
| Claude acceptance report, the final message of session fb8ede49 (`claude_r834_acceptance_report.txt`) | `8852bc3ffd4b1f73aec112c569d31ce9b6402d0a19459178ca349601d3f96fd7` |
| Claude R8.3.4 acceptance probe (that session's scratchpad `p834/test/zz_audit/audit_r834_final_test.dart`; run from there, not copied) | `f07e4e7ac39ed18cb2039e3738a91ed5ab26fa17da3bbb7578d4013b0d54d8ff` |

- All checksums inside the ZIP verify.
- The report inside the ZIP is byte-identical to the copy in `docs/audits/`.
- The Astra probe was saved here as `.dart`, then renamed to `.dart.txt` with identical bytes, so that the analyzer ignores it. This follows the convention of earlier rounds.
- `controls/run_controls.sh` ran while the file still had its old name; its path was updated afterwards.
- The probe compiled and ran unchanged. **No correction was needed.**

## RED before the fix (`repro_before_fix/`, exact dd9000cd export)

**Astra probe, unmodified: 5 pass / 4 fail.** The four failures are all behavioural, not preconditions: I3/I4 × uncertain_no_land and uncertain_landed each returned `done` where `notAvailable` was expected.

| Case | apply | Receipt | Target | Disk marker | After restart |
|---|---|---|---|---|---|
| I3/I4 uncertain_no_land | `done` | cleared | made | absent | `alreadyApplied` |
| I3/I4 uncertain_landed | `done` | cleared | made | `true` (cache absent) | History and snapshot erased; the Keep / left-out part remains |
| I3/I4 refused (control) | `done` | cleared | made | absent | `alreadyApplied` (correct) |

- The epoch was 0 → 0 in every case.
- GATE-C1, C2 and C3 pass.

**New permanent file on dd9000cd: 14 pass / 14 behavioural failures / 4 PRECONDITION.** The four preconditions are the later-confirmed-Delete tests. They need an application that has already stopped, which can't be set up on that tree.

## After the fix (`repro_after_fix/`)

- The Astra probe, unmodified: **9/9**.
- The new permanent file: **32/32**.

## Controls (`controls/`, `CONTROLS_perfile_both_trees.txt`)

Both trees were run: `red` is the exact dd9000cd export; `fixed` is that export plus the two production files.

| Suite | red | fixed |
|---|---|---|
| Earlier auditor controls (6 files) | 42 / 2 | 42 / 2 |
| R8.3.4 probe set (6 files) | 51 / 7 | 55 / 3 |
| Focused r81–r834, including the new file | — | 571 / 0 |

The earlier controls' two non-passes are identical on both trees: AUD-O3 (SUPERSEDED) and X4 (can't be set up). The remaining non-passes are the same as R8.3.4's own classification:
- Astra R833 original probe: the collision precondition can't be set up.
- GATE-A1: N/A, the precondition can't be set up.
- Claude P1: SUPERSEDED.

The only difference between the trees is the Astra R834 probe, 5/4 → 9/9. Each of these was 6/6 or 17/17 on both trees:
- the corrected Astra R833 probe;
- Claude's R8.3.4 acceptance probe.

## Full regression (`regression/`)

The runner and driver were copied unchanged from R8.3.4, except for OUT (`RUNNER_DIFF_vs_R834.txt`). Batches ran sequentially, with the memory guard on.

| Check | Result |
|---|---|
| Totals | **208 files, 3,055 passed, 0 failed, 0 skipped**, 24 raw logs |
| Run validators | EVIDENCE OK, CASES OK |
| `INVENTORY_RECONCILIATION.txt` | INVENTORY OK; vs R8.3.4: 3,023 → 3,055, and the only file whose count changed is `r8341_delete_outcome_continuity_test.dart` (0 → 32) |
| `RAW_LOG_VERIFICATION.txt` | RAW OK (R8.3.4 `verify_raw_logs.py`) |
| Year-long profiles | 13, each run exactly once |
| B8 | 6/6 (batch 19) |
| Source | Fingerprints and blob manifests identical at start and end |

## Other checks

- `flutter analyze`: no issues, exit 0 (`FLUTTER_ANALYZE.txt`).
- Audio: 180/180 match their HEAD blobs (`AUDIO_VERIFICATION.txt`).
- `SOURCE_MANIFEST_DELTA_vs_dd9000cd.txt`:
  - 2 production files modified: `circle_history_deletion.dart`, `insights_provider.dart`;
  - 1 test added: `test/features/r834/r8341_delete_outcome_continuity_test.dart`;
  - nothing else changed. 387 entries in total.
- R8.3.4 evidence:
  - `EVIDENCE_SHA256SUMS.txt` 117/117 OK;
  - `COMMIT_VERIFICATION_SHA256SUMS.txt` 14/14 OK;
  - tracked R8.3.4 evidence unchanged against HEAD;
  - the 3,023-test evidence is untouched.
- No dependency, billing, entitlement, localization, platform or asset path changed.

## Founder commit gate (11 November 2026)

- **§3, I1/I2 triage (`i1i2_triage/TRIAGE_RESULT.md`).** The path is reachable, but no MEDIUM/HIGH integrity violation was found. In the 8 disposable runs:
  - every Applied mark sits on the Insight's own change;
  - a confirmed Delete stops the action;
  - a landed Delete is finished at the next start, after which no key names either Insight and the Plan keeps its place;
  - nothing is replayed.
  - The results are byte-identical on dd9000cd and on the fixed tree. One LOW consistency difference from I3/I4 is disclosed.
- **§4, fix verification (`gate_probes/GATE_RESULT.md`).**
  - GATE-1 (uncertain→confirmed) and GATE-2 (Insights provider rebuild) pass on the fixed tree. GATE-2 fails on dd9000cd, because it is R834-N01 itself.
  - GATE-3 forces a rebuild of the deletion provider, which the app never does. In that case the overlap is missed; this is disclosed as unreachable.
  - The 32 permanent tests were checked in the raw log `regression/batch_16.jsonl`.
- **§5.** The working-tree source and tests were re-hashed before staging and are identical to the definitive run's end manifest and fingerprint.
- `FLUTTER_ANALYZE_final.txt` is the analyzer run on the final tree.
