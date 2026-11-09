# R8.3.2: R832-G1 closure (founder authorization, 2026-11-09)

**Result: PASS.** R832-G1 (a lifecycle ABA during a pending Start) is fixed with the founder's preferred design: a per-Plan, in-memory generation counter of durably confirmed lifecycle and cycle transitions. The contract is in `CONTRACT_G1.md`.

**L-1: OPEN, NOT FIXED, NOT WAIVED, PRE-RELEASE BLOCKER.** It is untouched.

Phase E is on HOLD.

Earlier evidence is unchanged, and each earlier manifest was re-verified on 2026-11-09:
- `../r8_3_2_consolidated_integrity_closure_2026-11-07/` (the 2,914-pass run, audit inputs);
- `../r8_3_2_founder_scope_closure_2026-11-07/` (the 2,944-pass run);
- `../r8_3_2_final_gate_2026-11-08/` (the original G1 reproduction).

## Production change

One file changed: `lib/features/plans/application/circle_plans_provider.dart`. It adds 106 diff lines (`source_diffs/G1_vs_2944_tree.diff`). The full R8.3.2 production diff against 9c910773 is `source_diffs/lib_vs_HEAD.diff`.

The change adds no persistent field, store, migration or framework.

## Tests

The new permanent test file is `test/features/r832/r832_g1_lifecycle_generation_test.dart`, with 22 tests:
- **A1–A5:** the final gate's Check A;
- **G1–G7:** multiple transitions, both of two changes queued together, refused writes, an uncertain write (throws), an uncertain write (ack lost), and the controls for a tap on a pending Resume that lands and one that is refused;
- **R1–R8:** a Plans rebuild, a rebuild after ABA, Delete after ABA, Delete alone, a stale continuation, no change, and a restart (twice);
- **C1–C2:** Start → Pause → Close is credited once; Pause → Start → Close is never credited.

The tests check both the durable state and the in-memory state: status, paused-Start record, credits, History Starts and lifecycle, including after restarts.

| Run | Tree | Result |
|---|---|---|
| `repro_before_fix/G1_on_pre_fix` | unchanged working tree (= the 2,944 fingerprint) | 11 FAIL / 11 PASS (see that folder's README.txt for runs 1–3) |
| `gate/GATE_AND_G1_on_prefix` | pre-fix provider, final test bytes | **14 FAIL** (Check A1–A3, and G1 A1–A3, G1, G2, G4, G5, R1, R2, R3, R5) / 18 PASS |
| `gate/GATE_AND_G1_on_fixed` | the corrected tree | **32/32**: Check A 5/5, **Check B 5/5**, G1 22/22 |
| `gate/AUDITOR_ORIGINALS_on_fixed` | the corrected tree | 26/27. AUD-O3 is superseded by N01-C, as on the 2,944 tree. The file is unedited. |

## Final regression (`regression/`)

The runner was copied unchanged except for `OUT` (`RUNNER_DIFF_vs_R8_3_2_founder_scope.txt`). It runs batches sequentially with a memory guard.

| Check | Result |
|---|---|
| Totals | **2,966 passed, 0 failed, 0 skipped**, in 204 files |
| Report | EVIDENCE OK: the raw reporter logs are validated against every summary |
| Cases | CASES OK: 13/13 declared year-long profiles, each exactly once (19a–e, raw logs agree); B8 6/6 (batch 18) |
| Inventory | INVENTORY OK: 204 planned = 204 on disk. The only count change is the new file, 0 → 22 (2,944 → 2,966). |
| Source integrity | Fingerprints identical at start and end; Git-blob manifests identical. Against the 2,944 run, exactly two files differ: the provider and the new test file. |
| Analyzer | `FLUTTER_ANALYZE.txt`: no issues |
| Audio | `AUDIO_VERIFICATION.txt`: 172 + 8 = 180/180, AUDIO OK |
| Auditor reports | Astra `89a61f9f…` and Claude `d1e5e700…` are unchanged (`baseline/AUDITOR_REPORTS_sha256_now.txt`); `AUDIT_INPUT_HASHES` OK |

## Remaining limitations

- The G1 limitations are in `CONTRACT_G1.md`. All of them fail safe.
- **L-1** is OPEN (pre-release blocker). **RL-4** and the device-level tests are pending.
- `FaultDisk` simulations are not device faults.
