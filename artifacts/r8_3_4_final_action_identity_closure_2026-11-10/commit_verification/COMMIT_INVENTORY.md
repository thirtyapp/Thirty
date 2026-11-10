# R8.3.4 — commit inventory and staging procedure

The founder conditionally authorized exactly one auditable commit and one normal fast-forward push, on 10 November 2026, after every verification gate passes.

- **Parent:** `285b5c701243e26efb543c68a2981d5e3471edbe`.
- **Branch:** `step5-billing-integration`.
- **The exact path list** is `COMMIT_PATHS.txt`, written before staging.
- **This file cannot contain the commit's own SHA.** The post-commit record is the separate, untracked `../R8_3_4_PUSH_RECORD.md`.

## Paths

| Group | Paths | Status |
|---|---:|---|
| Production source | 3 | M |
| Existing test (ID-2 adaptation) | 1 | M |
| New test (`test/features/r834/`) | 1 | A |
| R8.3.4 evidence: the reviewed bundle | 118 (117 registered in `EVIDENCE_SHA256SUMS.txt`, plus that register) | A |
| R8.3.4 evidence: `commit_verification/` (this folder) | listed in `COMMIT_PATHS.txt` | A |

**Production source (M):**

- `lib/features/home/application/circle_history_deletion.dart`
- `lib/features/insights/application/insights_provider.dart`
- `lib/features/personal_circle/application/kept_circles_provider.dart`

**Modified test (M):** `test/features/r833/r833_identity_contract_test.dart`

**New test (A):** `test/features/r834/r834_reproduction_test.dart`

**The original auditor inputs are in the bundle.** These were copied byte for byte from their sources, with SHA-256 values in `../audit_inputs/AUDIT_INPUT_HASHES.txt`:

- Astra's six-probe file: `../astra_probe_correction/…_ORIGINAL.dart.txt`, equal to the bytes in the ZIP;
- Astra's corrected copy, with its diff;
- Claude's extracted report;
- Claude's probe file and its two raw outputs.

Astra's report and ZIP in `docs/audits/` are **not** committed (founder §6). Their hashes are recorded.

**Excluded.** These stay in the working tree and are not committed:

- the line-ending-only modifications of `lib/core/world_rendering/quiet_trail_hero_asset_view.dart` and `test/features/personal_circle/r6_kept_voice_whole_circle_test.dart`;
- `AGENTS.md`, `android/build/`, `artwork/`, and the two quiet-trail PNGs;
- the untracked `docs/audits/` inputs;
- the older local handoff and push records;
- every other untracked artifact.

## Procedure

1. **Sources and tests.** Stage with `git add -- <explicit path>`. With `core.autocrlf=true`, Git's clean conversion gives LF blobs, exactly as `git hash-object` did for the tested manifest. Never `git add -A`.
2. **Evidence.** Stage every evidence file byte-exact with `git hash-object -w --no-filters <path>` and `git update-index --add --cacheinfo 100644,<blob>,<path>`. Recorded SHA-256 values then verify from the commit itself.
3. **Verify after staging** (`STAGED_VERIFICATION.txt`):
   - the staged paths equal `COMMIT_PATHS.txt`;
   - the source and test blobs equal the definitive tested manifest;
   - the line endings of the staged source;
   - the evidence bytes equal their working files;
   - the audit-input hashes, computed from the staged blobs;
   - `EVIDENCE_SHA256SUMS.txt`, from the staged blobs;
   - the raw logs of the definitive run, from the staged blobs.
4. **Register this folder** (`COMMIT_VERIFICATION_SHA256SUMS.txt`, all of this folder except itself). Stage it byte-exact, and compare the staged set with `COMMIT_PATHS.txt` once more.
5. **Commit and push.** Make one commit on the parent, then one normal fast-forward push. Verify HEAD, upstream and live origin afterwards.
