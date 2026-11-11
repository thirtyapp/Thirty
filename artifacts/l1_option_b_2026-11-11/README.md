# THIRTY: L-1 Option B (unreadable Suggestion Preferences)

- **Founder authorization:** 11 November 2026, Option B with four conditions. D-1 and D-2 were approved the same day, after the Gate 4 HOLD.
- **Parent:** the frozen R8 baseline `d9369795a92aa24505c475fa1417d03132300c4a`. Its sole parent is `dd9000cd…` and its tree is `11a2b7ef…`.
- **Status:** L-1 stays **OPEN** until independent acceptance and the founder's decision. Phase E is on HOLD, and no commercial release is authorized.

**Read first:**
- `CONTRACT_L1_OPTION_B.md`: the implemented contract.
- `LIMITATIONS_L1.md`
- `LOCALIZATION_INVENTORY_L1.md`
- `INDEPENDENT_AUDIT_HANDOFF_L1.md`

## History of this package, in order

| Step | Where | Result |
|---|---|---|
| Read-only discovery (frozen tree) | `discovery/` | L-1A, L-1B and L-1C characterised. The probes and raw logs are kept as `.dart.txt` and `.txt`. |
| Gate 0 baseline | `baseline/` | Refs, the founder's working-tree status, and the HEAD manifests (source, all tracked paths, audio) |
| Gate 1 failing-before (frozen tree + L-1 tests) | `repro_before_fix/` | 88 tests: **33 passed, 55 failed**. The controls pass and every L-1 expectation fails. |
| First implementation, focused | `after_fix/` | L-1 88/88; focused R8 controls 973/973 (60 files) |
| **First full regression: NOT A PASS** | `regression/` | **3,141 passed, 2 failed**. The 2 failures are the B8 live-copy guard ("recover") and the B8 review pack. |
| Gate 4 HOLD | `gate4_hold/HOLD_RECORD.md` | Stopped before staging; founder decisions D-1 and D-2 requested |
| Founder D-1 and D-2 approved; resumption | `resumption/` | D-2 one-word copy change; D-1 pack regenerated (`B8_PACK_DIFF_CLASSIFICATION.md`); B8 guard 11/11; pack 1/1; L-1 88/88; focused 973/973 with the same test identities |
| Full regression after D-1 and D-2: **passed, but superseded** | `regression_final/` | **210 files, 3,143 passed, 0 failed, 0 skipped.** 24 raw logs. EVIDENCE, CASES, INVENTORY and RAW all OK. 13 profiles, each once. B8 simulation 6/6. Both earlier B8 failures now pass (`REQUIRED_RESULTS_FROM_RAW_LOGS.txt`). Fingerprints and blob manifests identical at start and end. |
| Line-ending normalization of two L-1 test files (before staging) | `resumption/LF_NORMALIZATION_RECORD.md` | Only CRLF → LF changed, so the raw tested bytes now equal the committed blobs. L-1 88/88 rerun. |
| **Definitive full regression: AUTHORITATIVE** | `regression_definitive/` | Run on the exact bytes that are committed. The results are in its own logs and `REQUIRED_RESULTS_FROM_RAW_LOGS.txt`, summarized in the founder report and the push record. |
| Gate 5 integrity | `final_integrity/`, `FLUTTER_ANALYZE_final.txt` | Analyzer clean. Exactly 8 of the 2,677 tracked paths changed, all authorized. Audio 180/180 unchanged. `pubspec` and platform files unchanged. |

## Changed paths (all authorized)

**Production and documentation (6):**
- `lib/features/home/application/suggestion_preferences.dart`
- `lib/features/home/application/circle_journal.dart`
- `lib/features/home/presentation/widgets/journal_data_controls.dart`
- `lib/features/settings/presentation/widgets/you_data_card.dart`
- `lib/features/home/presentation/memory_page.dart`
- `docs/product/PRODUCT_V2_CONTRACT.md`

**B8 review pack (D-1, 2):**
- `artifacts/v2_phase_d2/b8/CONTENT_REVIEW_PACK.md`
- `artifacts/v2_phase_d2/b8/MANIFEST.json`

**New tests (3):**
- `test/features/l1/l1_delete_recovery_test.dart` (17)
- `test/features/l1/l1_option_b_ui_test.dart` (71)
- `test/features/l1/l1_fixture.dart` (support)

**Evidence:** this folder.

**Not changed:**
- `circle_history_deletion.dart`
- the B8 tests, extractor, regexes and allowlist
- dependencies, platform files, audio, billing and entitlement code

## Environment

- Every test ran in a `git archive` export of `d9369795` with the change applied: the "tested tree".
- The commit was built in a separate clean clone at `d9369795`, never in the founder's working tree, and only from the verified tested bytes.
- Paths inside the raw logs point to that scratch export.
- All storage-fault results come from the committed `FaultDisk` simulation, not from a device.

`EVIDENCE_SHA256SUMS.txt` covers every file in this folder except itself.
