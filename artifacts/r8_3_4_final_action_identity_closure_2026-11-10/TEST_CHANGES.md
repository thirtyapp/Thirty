# R8.3.4 — test changes

No existing test was weakened, skipped or removed, and no existing contract assertion was relaxed.

## Added (permanent)

### `test/features/r834/r834_reproduction_test.dart` (24 tests)

The file uses only APIs present at R8.3.3, so the same bytes ran on both trees.

| Group | Tests | Before the fix (R8.3.3) | After the fix |
|---|---|---|---|
| R833-A02 | A02-1, A02-2 (with restart), A02-3 (two receipts naming one id) | **3 fail** at decisive assertions | pass |
| R833-A02 controls | A02-4 own proof, A02-5 manual Keep, A02-6 retained record, A02-7 Delete | 4 pass | pass |
| R833-A01 / AUD-R833-1 | I3-REFUSED, I4-REFUSED, I3-CLEAR-REFUSED, I4-CLEAR-REFUSED | **4 fail** at decisive assertions | pass |
| R833-A01 controls | ACCEPTED, RETRIED, UNCERTAIN (×I3/I4); CLEAR-ACCEPTED (×I3/I4) | 8 pass | pass |
| R833-A03 | A03-1 (three Keeps while the first write is held) | **1 fail** at its decisive assertion | pass |
| R833-A03 controls | A03-2 held id; A03-3 ×2 (throws, returnsFalse); A03-4 limit and same day | 4 pass | pass |
| **Total** | | **8 fail / 16 pass, 0 PRECONDITION** | **24 / 24** |

The raw logs are:

- before: `repro_before_fix/r834_on_r833.jsonl`;
- after: `repro_after_fix/r834_on_fixed.jsonl`.

## Adapted (one test, disclosed)

### `test/features/r833/r833_identity_contract_test.dart`, ID-2

**Before.** The test forced I4-B to be given the id that I4-A's unresolved attempt had recorded, asserting `kept.single['id'] == recorded` (reason: `collision not forced`). It then asserted that A is never proven.

**Why it changed.** R8.3.4 makes that collision unconstructible by design (CONTRACTS_R834 §1.2, item 3): B is never given an id an attempt recorded.

**After.** That one assertion is replaced by its stronger opposite:

```dart
expect(kept.single['id'], isNot(recorded), reason: 'an id an unresolved attempt recorded was given again');
```

- The test name now says "is never given the id A recorded" instead of "is given the very id A recorded".
- A three-line comment explains the change.
- The two decisive assertions are byte-unchanged: A is never Applied, and A is stale after the restart.
- The diff is +9/−2: `source_diffs/r833_identity_contract_test.diff`.

**Results.**

- On R8.3.3 the adapted test **fails**: B was given A's id.
- After the fix it passes.
- Logs: `repro_before_fix/r833_identity_contract_ADAPTED_on_r833.jsonl` and `repro_after_fix/r833_identity_contract_ADAPTED_on_fixed.jsonl`.
- The pre-adaptation focused run, which shows the original ID-2 failing on the fixed tree for exactly this reason, is kept as `focused/focused_on_fixed_PRE_ID2_ADAPTATION.jsonl`.

The test was patched from its HEAD blob with exactly these two edits (`patch_id2.py` in the session scratchpad). An earlier `dart format` pass that reflowed the whole file was discarded and is not in the tree.

## Auditor probes: preserved, not added to `test/`

### Astra's six probes

- The original bytes are `astra_probe_correction/r833_independent_adversarial_test_ORIGINAL.dart.txt`, SHA-256 `7a0b7ae8…`, identical to the file in the ZIP.
- They ran unedited on both trees.
- **One justified correction** was made to the same-source probe, in `astra_probe_correction/…_CORRECTED.dart.txt`; `CORRECTION.diff` shows it.
  - Its forced-collision line `expect(kept.single['id'], oldReceipt['keptId'], reason: 'forced collision precondition')` asserts the very collision that the fix removes.
  - That line becomes a recorded `collided` value, plus `expect(kept, hasLength(1))`.
  - Its decisive assertions (`appliedOn` null, `attempt` not null) are unchanged.
- Results for the corrected copy:
  - On R8.3.3: `collided=true`, and the decisive assertion fails (A is falsely Applied).
  - On the fixed tree: `collided=false`, and it passes.

### Claude's P1–P15

- The file is `audit_inputs/claude_probe/audit_r833_delta_test.dart.txt`, SHA-256 `f727ef8d…`. It ran unedited.
- **P1 is SUPERSEDED, not passing, after the fix.** Its one contract assertion `expect(snap?['appliedOn'], isNull)` (comment: "nothing left out, no false Applied") encoded R8.3.3's stranding as integrity.
- Under the founder's refused-Delete contract (directive §4), the I3 must complete. P1's own evidence after the fix shows a **genuine** application:
  - `apply: done`;
  - the part left out, with this Insight's id;
  - the attempt cleared;
  - retry `alreadyApplied`.
- There is no false Applied. The file is not edited.
- P2–P15 pass unedited.
