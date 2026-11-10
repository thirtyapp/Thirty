# R8.3.3 — commit inventory and verification

The founder authorized one auditable commit and one normal fast-forward push on 10 November 2026; see `../FOUNDER_DECISIONS_R833.md`.

- **Parent:** `d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2`.
- **Branch:** `step5-billing-integration`.
- **Paths:** the exact list is `COMMIT_PATHS.txt`, written before the commit.
- **This file cannot contain the commit's own SHA.** The post-commit record is the separate, untracked `../R8_3_3_PUSH_RECORD.md`.

## Paths

| Group | Paths | Status |
|---|---:|---|
| Production source | 5 | M |
| New tests (`test/features/r833/`) | 2 | A |
| Original Astra post-R8.3.2 report (`docs/audits/`) | 1 | A |
| R8.3.3 evidence directory, this verification included | all files | A |

**Production source (M):**

- `lib/core/qa/qa_scenario.dart`
- `lib/features/home/application/circle_history_deletion.dart`
- `lib/features/insights/application/insights_provider.dart`
- `lib/features/personal_circle/application/kept_circles_provider.dart`
- `lib/features/plans/application/circle_plans_provider.dart`

**New tests (A):**

- `test/features/r833/r833_identity_contract_test.dart`
- `test/features/r833/r833_reproduction_test.dart`

**Excluded.** These are preserved in the working tree and are not committed:

- the line-ending-only modifications of `lib/core/world_rendering/quiet_trail_hero_asset_view.dart` and `test/features/personal_circle/r6_kept_voice_whole_circle_test.dart`;
- `AGENTS.md`, `android/build/`, `artwork/`, and the two untracked quiet-trail PNGs;
- the local R8.3.2 handoff and push record;
- every other untracked historical artifact.

No `git add -A` was used. Paths were staged from an explicit list, and the staged set was compared with that list: equal.

## Gates

### Gate I — no change after the definitive regression

Current `lib/`, `test/` and configuration Git blobs, and their byte fingerprints, are identical to `regression/SOURCE_MANIFEST_git_blobs_end.txt` and `regression/SOURCE_FINGERPRINT_end.sha256` (385 entries).

### Source and test blobs

The staged index blobs for `lib/`, `test/`, `analysis_options.yaml`, `pubspec.yaml` and `pubspec.lock` are identical to the definitive tested manifest (385 entries, 0 differences).

**Line endings.** `core.autocrlf=true` applies to source and test files, so their blobs are LF. Five production working files are CRLF on disk; Git's clean conversion makes them LF, exactly as `git hash-object` did for the tested manifest. `STAGED_EOL_VERIFICATION.txt` shows, for each of the 7 files:

- the staged blob has 0 CR bytes;
- the working file, with CRLF turned into LF, is byte-identical to that blob.

### Evidence files are byte-exact

Evidence and text files written on Windows with CRLF were staged with their exact bytes, using `git hash-object -w --no-filters` and `update-index`. Every recorded SHA-256 therefore verifies from the commit:

- the raw reporter logs, against their `rawSha256`;
- the audit inputs;
- the hash lists.

`verify_staged_bytes.py` checks that every staged non-source path equals its working file byte for byte: BYTES OK. `EVIDENCE_SHA256SUMS.txt` lists the SHA-256 of the committed blob bytes of every path.

### Auditor reports

These SHA-256 values were computed from the staged blobs:

| Report | SHA-256 |
|---|---|
| Astra post-R8.3.2 (`docs/audits/` and its `audit_inputs/` copy) | `381f3cfddf600cd6e79b532a81b3e78fbd507ac0717fec15937937aa6533cd32` |
| Claude report, extracted | `49cb739df2c61de14280e74921474749f1a694cf52a0b689ad6e7d9f0e1448bc` |
| Claude transcript line | `29b23a9bbda2fd57408ceb383ed7101c28a5cac4d0c196c90ec7cf64ff47ee66` |
| Claude probe file | `9c191c91deeff2c7975c5d5950ac38419f9b5aa207f3c1158eb1299b00c67d94` |

All equal the hashes recorded at the start in `audit_inputs/AUDIT_INPUT_HASHES.txt`. The earlier post-R8.3 reports are unchanged: Astra `89a61f9f…`, Claude `d1e5e700…`.

### Raw logs of run 2

`RAW_LOG_VERIFICATION_run2.txt`, produced by `verify_raw_logs.py`, checks the raw reporter logs directly, without trusting any summary:

- 23 logs, 206 files, 2,999 successes;
- 0 failed, 0 skipped;
- each log has a start event and exactly one final successful `done`;
- every test start finishes exactly once;
- no test name repeats;
- each log's SHA-256 equals its summary's `rawSha256`.

Its result is RAW OK.

### Gates A–H

The source checks are in `CONTRACTS_R833.md`. The test evidence is in `EVIDENCE_REGISTER.md`.

| Gate | What was checked |
|---|---|
| **A** | I4 uses `newKeptId(tag: 'insight')`: event clock + 48 random bits. `_now` (the cached `nowProvider`) now only supplies dates. `keepCircle(id:)` refuses an id already in use. |
| **B** | The production source is `Random.secure()`, falling back to `Random()`. The only `Random(0)` seed is in the temporary container of the QA store builder, which only the debug QA harness reaches (`kDebugMode && THIRTY_QA_PREMIUM`). |
| **C** | `renameKept` and `deleteKept` return without change when `addressedBy(id) > 1` (A02-E). |
| **D** | `_appliedOn` for I4 needs the attempt target, the exact `keptId` **and** `fromCircleId` (A02-B, A02-B2, ID-2). |
| **E** | `apply` captures the epoch and re-checks after its waits. Every mutation in the apply path sits directly behind a synchronous `_stillCurrent(epoch)` check: receipt, receipt clearance, marks, Plan change, left-out part, Keep, final mark. |
| **F** | A continuation either queued its change before the boundary, so Delete's own pass runs after it, or it stops. A01, v2, v8, v9, v11, x1 and x2 all pass. |
| **G** | `_startStillValid` needs `_countedFrom[plan] == accepted.pendingSave` as well as the G1 generation (X1, X2, X3). |
| **H** | Focused suites 482/482. Final gate 10/10. Auditor originals 26 PASS + AUD-O3 **SUPERSEDED**. Full regression 2,999/0/0. |
