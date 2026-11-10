# THIRTY — R8.3.4 final action identity closure result

- **Date:** 10 November 2026, under the founder directive of the same day.
- **Scope:** three findings only:
  - R833-A02;
  - R833-A01 together with AUD-R833-1;
  - R833-A03.
- **No staging, commit, push, deployment or release has been made. Phase E: HOLD. L-1: OPEN.**

The other documents in this folder:

| File | What it holds |
|---|---|
| `CONTRACTS_R834.md` | the contracts and the non-transferability argument |
| `TEST_CHANGES.md` | the added test, the one adapted test, and how the auditor probes were handled |
| `EVIDENCE_REGISTER.md` | every result and its classification |
| `source_diffs/` | the exact diffs |
| `audit_inputs/` | report and probe hashes |

## 1. Starting Git state

The full record is in `baseline/GIT_STATE_start.txt`.

| Item | Value |
|---|---|
| Branch | `step5-billing-integration` |
| HEAD, `@{u}`, and live origin | all `285b5c701243e26efb543c68a2981d5e3471edbe` |
| Parent | `d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2` |
| Tree | `7964a4a8` |
| `main` | `a8b4088` |

Items already in the working tree were preserved untouched:

- two files with line-ending-only modifications:
  - `quiet_trail_hero_asset_view.dart`;
  - `r6_kept_voice_whole_circle_test.dart`;
- the untracked items, including both post-R8.3.3 audit inputs in `docs/audits/`.

## 2. Audit inputs

The hashes are in `audit_inputs/AUDIT_INPUT_HASHES.txt`.

**Astra.**

- Report: `7ca4387d…`.
- ZIP: `30a107be…`. All 21 of its SHA256SUMS entries are OK, and the report inside it is identical to the copy in `docs/audits/`.
- Probe file: `7a0b7ae8…`. It was preserved unedited, and a copy is in `astra_probe_correction/`.

**Claude.** The report is the final message of session `fb8ede49`, extracted to `audit_inputs/` (`a55f6d6e…`). Its probe file is `f727ef8d…`, copied byte for byte.

## 3–4. Probes and failing-before reproductions

All six Astra probes compiled unedited and ran against the exact R8.3.3 export:

- the **four adversarial probes failed at their contract assertions**, after every precondition had passed;
- the two accepted-Delete controls passed.

Claude's P1 evidence reproduces AUD-R833-1:

- `apply notAvailable`;
- the attempt stays on disk;
- the Insight is stale before and after a restart;
- the retry returns `notAvailable`.

The permanent file `r834_reproduction_test.dart`, run on R8.3.3, gives **8 behavioral failures, 16 passing controls and 0 precondition failures**. See EVIDENCE_REGISTER.

## 5. Root causes

| Finding | Root cause |
|---|---|
| **R833-A02** | Allocation ignored the ids recorded in unresolved Insight receipts, so a later Keep could be given one. Proof matched on id plus source only, so that later Keep proved the earlier attempt. |
| **R833-A01 / AUD-R833-1** | One root cause. `_stillCurrent` read `isPending` from the SharedPreferences cache, which holds the intent before the platform confirms it. The receipt-bearing steps stopped on a Delete that could still be refused. That covers the post-receipt I3 and I4 steps, and also `_clearAttempt`; the R8.3.4 tests found the `_clearAttempt` path (CLEAR-REFUSED). |
| **R833-A03** | The reservation was removed at the start of the commit callback, before the write awaited. |

## 6. Production changes

Three files changed, `+167/−36`.

**`circle_history_deletion.dart`**

- Adds `DeletionIntentOutcome {confirmed, refused, uncertain}`.
- Adds `intentBeingRecorded`, set while the intent's two writes are under way.
- A confirmed outcome is told only after `gate._begin()`.

**`insights_provider.dart`**

- Adds `_intentAnswer()`.
- The I3 and I4 post-receipt steps and `_clearAttempt` loop on it, then run the unchanged synchronous `_stillCurrent` check.
- With no intent in flight, nothing is awaited.
- I4 allocates with `avoiding: _attemptKeptIds()`.
- I4 proof additionally requires that exactly one receipt names the id.

**`kept_circles_provider.dart`**

- `_keeping` becomes a map from id to day, held until the Keep settles.
- Refusal is shared by the call and the commit (`_keepRefused`). It counts the Keeps under way that are not yet in state.
- `newKeptId` takes `avoiding`.

## 7–9. Contracts

These are in `CONTRACTS_R834.md`: §1 I4 identity, §2 refused Delete, §3 reservations.

## 10–12. Results

Details are in EVIDENCE_REGISTER.

| Check | Result |
|---|---|
| Astra probes | 6/6, with one justified, disclosed correction |
| Claude probes | P2–P15 pass; P1 is SUPERSEDED |
| `r834` | 24/24 |
| r81–r832 focused | 482/482 |
| Prior auditor controls | unchanged, 42/2 |
| **Full regression** | **207 files, 3,023/0/0**; EVIDENCE, CASES, INVENTORY and RAW all OK; 13 profiles; B8 6/6; fingerprints identical |
| Analyzer | clean |
| Audio | 180 OK |
| R8.3.3 evidence | 163/163 unchanged |

## 13. Remaining limitations

These are disclosed, not fixed.

- **Unreleased R8.3.3 records.** A record such a build wrote with a forced id collision, after the other I4's receipt was cleared, can't be told apart on read. No repair is made.
- **A tap during intent recording.** An I3/I4 tapped while a Delete intent is being recorded is still refused at entry with `notAvailable`. No receipt is written; this is availability only.
- **An uncertain intent outcome.** The attempt is kept and the Insight stays stale. This is the fail-safe choice; the next start finishes any deletion that did land.
- **Legacy duplicate kept ids.** The consequences are unchanged: rename and remove are no-ops, and both records count toward the limit (Claude AUD-R833-2, outside this scope).
- **Device evidence.** Real process kill, device storage, S25, TalkBack and billing were not executed.

## 14. L-1

**OPEN — PRE-RELEASE BLOCKER — NOT FIXED — NOT WAIVED.** It is untouched.
