# R8.3.4 — evidence register

Every result below comes from the raw `flutter test --reporter json` streams in this folder. Summaries were recounted from them, never taken on trust.

## Trees

| Name | What it is | Verification |
|---|---|---|
| **red** | `git -c core.autocrlf=false archive 285b5c70`, plus probes only | 385/385 blobs equal the commit (`repro_before_fix/EXPORT_BLOBS_vs_285b5c70.txt`); `pubspec.lock` unchanged after `pub get --offline` |
| **fixed** | red, plus the 3 R8.3.4 production files and the 2 test files (LF) | each file's `git hash-object` equals the working tree's |
| **working tree** | the repository, where the definitive full regression ran | start and end fingerprints and blob manifests identical |

## Failing-before (red = R8.3.3)

| Run | Result | Classification |
|---|---|---|
| Astra 6 probes, unedited | 2 pass / 4 fail | All 4 fail at their contract assertions, after every precondition passed: intent I3, intent I4, same-source, in-flight. The 2 passes are the accepted-Delete controls. |
| Astra same-source, corrected copy | fails at its decisive assertion (`collided=true`) | R833-A02 reproduced |
| Claude P1–P15, unedited | 15 pass | P1's evidence line shows AUD-R833-1: `apply notAvailable`; attempt stranded; stale before and after restart. P1's own assertion covers integrity only. |
| `r834_reproduction` | 8 fail / 16 pass, **0 PRECONDITION** | A02-1, A02-2, A02-3, I3/I4-REFUSED, I3/I4-CLEAR-REFUSED, A03-1 |
| `r833_identity_contract` (ID-2 adapted) | 2 pass / 1 fail | The adapted ID-2 fails because B was given A's id. |
| Prior auditor controls (6 files, 44 tests) | 42 pass / 2 not-pass | AUD-O3 is SUPERSEDED (N01-C). X4 cannot be constructed (I1 needs a paused Plan, I2 an active one). Both are unchanged from the R8.3.3 record. |

## After the fix

| Run | Result |
|---|---|
| Astra 6 probes, unedited | 5 pass / 1 fails at its **precondition** (`forced collision precondition`): the collision is now unconstructible, so this is not counted as a pass |
| Astra 6 probes with the corrected same-source copy | **6 / 6** (`collided=false`) |
| Claude P1–P15, unedited | 14 pass; **P1 SUPERSEDED**: its `appliedOn isNull` assertion meets a genuine application (part left out with its own id, attempt cleared, retry `alreadyApplied`) |
| `r834_reproduction` | **24 / 24** |
| `r833_identity_contract` | **3 / 3** |
| Focused r81, r82, r83, r832, r833 (before the ID-2 adaptation) and r834 | 538 / 539. The one failure is the original ID-2, failing only on its forced-collision step. r81–r832 alone: **482 / 482**, as at R8.3.3. |
| Prior auditor controls | 42 / 2: byte-for-byte the same outcome as on red |

## Definitive full regression (working tree)

| Item | Result |
|---|---|
| Files | **207** (206 at R8.3.3, plus r834) |
| Tests | **3,023 passed, 0 failed, 0 skipped**, exit 0 |
| Runner checks | EVIDENCE OK, CASES OK, INVENTORY OK, RAW OK (24 logs) |
| Per-file count change against the R8.3.3 run | only `r834_reproduction_test.dart`, 0 → 24 |
| Year-long profiles | **13**, each exactly once (p01–p11, p13, p14; no p12 is declared) |
| B8 | `b8_product_simulation_test` **6 / 6** |
| Fingerprints and blob manifests | identical at start and end |
| Memory guard | no stop |
| Duration | 19:01:59 to 19:29:58 |

## Other gates

| Gate | Result |
|---|---|
| `flutter analyze` (whole project) | No issues, exit 0 |
| Audio | 180 tracked = 180 in the working tree, 0 differing |
| R8.3.3 evidence register | 163 / 163 against HEAD blobs; its 66 regression files are byte-identical; the 2,999 run is unchanged |
| Source manifest against 285b5c70 | 385 → 386: 3 lib changed; 1 test changed (ID-2); 1 test added |
| Billing, entitlements, dependencies, platforms, localization, assets | unchanged |
