# THIRTY — INDEPENDENT POST-R8.3.3 TARGETED DELTA AUDIT

**Verdict: PASS. The three contracts hold. Two new LOW residuals, neither breaks an integrity invariant.**

## 1. Verified commit, parent and tree

| Item | Value | How checked |
|---|---|---|
| Repository and branch | `thirtyapp/Thirty`, `step5-billing-integration` | `git ls-remote` returns `285b5c70…` for the branch |
| Commit | `285b5c701243e26efb543c68a2981d5e3471edbe` | `git log` |
| Sole parent | `d4cf8c44f8f9fd03652f79b10b55c1dd6588edd2` | `git log` |
| Tree | `7964a4a83d84fe0bb1bacf12f248b023c9ede671` | `git log` |

I audited `git -c core.autocrlf=false archive` exports of both commits, never the implementer's working directory.

## 2. Source and evidence integrity (all executed)

**Changed paths: 164, as reported.**
- 5 production files: `qa_scenario.dart`, `circle_history_deletion.dart`, `insights_provider.dart`, `kept_circles_provider.dart`, `circle_plans_provider.dart`.
- 2 added tests under `test/features/r833/`.
- 1 added Astra report.
- 156 evidence files.
- `COMMIT_PATHS.txt` equals `git diff --name-only`.

**No other changes:**
- No `pubspec.*`, platform, asset, localization, billing or entitlement path changed.
- All 180 tracked audio files are unchanged.

**Manifests and hashes:**
- All 385 manifest entries equal the committed blobs (385/385).
- The manifest covers exactly the committed `lib`, `test`, `pubspec.*` and `analysis_options` files.
- The start and end manifests and fingerprints are identical, so the regression ran on the committed bytes.
- `EVIDENCE_SHA256SUMS.txt`: every entry verifies.
- The Astra post-R8.3.2 report hash `381f3cfd…` is unchanged. My own post-R8.3.2 probe file in the evidence hashes to `9c191c91…`, the same as my original scratchpad file. The post-R8.3 Astra report (`89a61f9f…`) is unchanged. No other report in `docs/audits/` was touched.

## 3. Method and limitations

**Executed:**
- Flutter 3.44.8 on Windows: analyzer, full regression and targeted suites.
- The implementer's R8.3.3 suites on both trees.
- My own earlier probe files, unedited (post-R8.2, post-R8.3, post-R8.3.2).
- 15 new adversarial probes, P1–P15.
- Source review of every changed asynchronous boundary.

**Not executed:**
- Real Android process kill or storage faults (simulated restarts only).
- S25 or TalkBack.
- Billing.

**Not constructible:**
- My X4 (concurrent I1 + I2): its precondition still can't be built, because I1 needs a paused Plan and I2 an active one.
- My P7, P8 and P10 on R8.3.2: they use R8.3.3-only APIs.

None of these is counted as a pass.

## 4. A01 — Delete isolation: **PASS**

**How the barrier works:**
- The epoch is captured at `apply` entry (`insights_provider.dart:353`).
- `_stillCurrent` (`:98–101`) requires: still mounted, the same epoch, and no deletion under way or pending.
- It runs synchronously, immediately before every mutation:
  - receipt `:501`, receipt clearance `:525`, Applied marks `:561` and `:413`;
  - Plan changes `:579` and `:609`;
  - I3 `:659` and I4 `:719`.
- `confirmed()` (`circle_plans_provider.dart:562–566`) calls `_set` synchronously, so no await separates the check from the queued write.
- `leaveOutChange` chains onto `_writes` synchronously.
- `Delete` moves the epoch (`_begin`) and queues its first passes in the same synchronous step (`circle_history_deletion.dart:177–190`).
- `writeConfirmed` sets the SharedPreferences cache before the disk call, so `isPending` is already true while the intent write is in flight.

**Executed evidence:**
- R8.3.3 reproduction suite: 30/30.
- My probes:
  - P2: an `apply` begun during Delete is not applied, and the Plan stays paused.
  - P3: an I4 Keep queued before the boundary lands. The kept Circle stays (founder decision B4) and no Insight id remains.
  - P4: an I3 left-out part queued before the boundary stays left out, with its attribution removed.
  - P5: a target write whose answer is lost: reported not saved, the Plan stays paused, nothing deleted survives.
  - P6: a user Pause queued between Delete's two passes keeps its place.

In every case, durable bytes and confirmed state hold no deleted Insight id. The user's Plan choices, Kept Circles and left-out parts survive (v11). The final Plans pass is defence in depth only: the tests assert `lifecycle == paused`, which a final pass alone could not restore.

## 5. A02 — Kept identity: **PASS**

**What is enforced:**
- Uniqueness is enforced in the Kept Circles domain, not left to randomness.
- `keepCircle` refuses an id held by a kept Circle, a retained (unreadable) record, or a Keep under way, both at the call and inside the serialized commit (`kept_circles_provider.dart:347–376`).
- I4 Applied proof needs three things: the attempt target, the exact `keptId`, and `fromCircleId` equal to the source Circle (`insights_provider.dart:459–471`).
- Rename and Remove refuse an id that addresses more than one Circle (`:395`, `:423`).

**Executed evidence:**
- A02-A…I and ID-1…3 pass.
- My probes:
  - P8: a forced collision in the commit window stores no duplicate.
  - P9: an uncertain I4 followed by a manual Keep of the same day is never taken as proof, and nothing is kept twice.
  - P10: a forced collision with a stored `-insight` id gets a `-1` suffix; the legacy record is untouched.
- Export serializes every record as stored; duplicates are not merged (`journal_data_controls.dart:106–108`).

**Risk from the preservation policy:** no data is destroyed. The residual risk is AUD-R833-2 (§11).

## 6. AUD-R832-1 — Exact Start save: **PASS**

| Probe | R8.3.2 | R8.3.3 |
|---|---|---|
| X1 (refused Resume, then a new Resume) | started, 1 credit | notStarted, 0 credits |
| X2 (refused Resume, then Pause and Resume) | started, 1 credit | notStarted, 0 credits |
| X2-ctl (Resume lands, then Pause and Resume) | cancelled | cancelled |

My original probe file ran unedited on R8.3.3. Its output is byte-identical to the implementer's record.

**New probes:**

| Probe | Scenario | Outcome |
|---|---|---|
| P11 | Refused intermediate save; the exact save s3 lands | started, credited once |
| P12 | Refused Resume, nothing else | cancelled |
| P13 | Uncertain Resume (landed, answer lost) | cancelled |
| P14 | Delete during the pending Start | cancelled |
| P15 | The exact save lands | started, credited once |

None of these left a stray session, a credit or a `startedWhilePaused` record.

**Source reasoning:**
- `_countedFrom` is set only by a save that landed or is uncertain.
- An uncertain save fails the `_durable` place check.
- `_saves` is monotonic, and a rebuild changes `_epoch`.

So no other save can stand in for a refused or uncertain one. The founder's Start/Pause/Close credit policy is unchanged.

## 7. Prior-finding regression matrix

| Finding | Evidence | Status |
|---|---|---|
| R8.2 fixes, AUD-N1/N2/N3 | My R8.2 adversarial probes 8/8 + full suite | Holds |
| R83-N01/N02/N03, AUD-R83-1/2/3 | My R8.3 delta probes 11/11 + suite | Holds |
| R832-B1/B2, G1, N01-C, D1–D5 | Full suite (G1 22/22, founder-scope suites); X3/X3-ctl | Holds |
| Credit rules (Start→Pause→Close credited once; Pause→Start→Close not; abandoned Start not; Close-before-Leave credited) | Suite + P11/P15 | Holds |
| Reversed Insight never repeated; deleted attribution never restored | Suite + P2–P6, P9 | Holds |
| **AUD-O3 (original)** | Still "fails" (expects started, gets cancelled) | **SUPERSEDED by N01-C, not passing** |

## 8. Independently executed adversarial tests

| Run | R8.3.3 | R8.3.2 |
|---|---|---|
| `r833_reproduction` | 30/30 | 13 pass / 17 fail |
| `r833_identity_contract` | 3/3 | does not compile |
| My P1–P15 | 15/15 | 11 pass / 1 fail of 12 that could run (P1 fails: see AUD-R833-1) |

On R8.3.2, the 17 reproduction failures are 16 genuine assertion failures plus A01-v10, which fails its precondition. This matches the implementer's accounting exactly.

## 9. Full regression evidence

**My own run (executed on the pristine export):**
- `flutter analyze`: no issues.
- `flutter test`: 206 files, **2,999 passed, 0 failed, 0 skipped**, exit 0.
- Per-file counts are **identical** to the implementer's run 2.

**Implementer's raw logs (recounted by me):**
- 23 logs, every one done=success.
- 206 files, 2,999 passed, 0 skipped.
- The 13 year-long profiles each ran exactly once (19a–e).
- B8 is `b8_product_simulation_test`, 6/6.
- The only count changes against the G1 run are the two r833 files (+33).

## 10. Six-invariant assessment (changed paths only)

1. **Durable confirmation:** holds.
2. **Exact attribution:** holds (two-key I4 proof, `pendingSave` binding).
3. **Idempotence:** holds. Receipts block repeats (P9).
4. **Temporal validity:** holds. The epoch barrier; the Start is cancelled on any substituted save.
5. **Serialization fidelity:** holds. Legacy duplicates and retained records are kept as stored.
6. **Delete completeness:** holds for readable current-schema data. L-1 is separate and still open.

This applies to the changed paths, not to the whole app.

## 11. New findings

**AUD-R833-1 (LOW). A regression versus R8.3.2 that affects availability only.**
- **Interleaving:**
  1. An I3 or I4 attempt receipt is being written.
  2. Delete begins; its intent write is pending, with the cache already set.
  3. The receipt lands, and `_stillCurrent` is false (`isPending`, `circle_history_deletion.dart:111–113`).
  4. `apply` returns `notAvailable` (`insights_provider.dart:652–659` and `:712–719`), and `_clearAttempt` is skipped (`:525`).
  5. The intent write is then refused twice, so the Delete raises `HistoryDeletionNotStarted`.
- **Result (P1, executed):**
  - the receipt stays on disk;
  - the Insight is stale before and after restart, and a retry returns `notAvailable`;
  - nothing was left out, and nothing is falsely marked Applied.
- **On R8.3.2** the same probe applied the I3 normally.
- **Contract conflict:** this contradicts CONTRACTS_R833 §1.8 and v7 ("a Delete refused before its intent is durable… the waiting application completes normally").
- **User impact:** an Insight is suppressed until a later Delete; the user can still make the change by hand.

**AUD-R833-2 (LOW). Affects legacy records only; a user-experience honesty issue.**
- `renameKept` and `deleteKept` on an ambiguous id complete with no error (P7, executed).
- After Remove, `kept_circle_page.dart:254–259` then goes to Yours as if the Circle had been removed.
- Neither duplicate can ever be removed, and both use slots out of the 8-Circle limit.
- The detail page shows only the first duplicate (`keptById`).
- No data is destroyed. Only unreleased `d4cf8c44` builds can have written such records. This fits the founder's "no auto-repair" decision, but the silent success was not disclosed.

**Informational, no defect:**
- **O-1:** between a Keep's commit step and the store confirming it, its id is neither reserved nor in state (P8). The domain check still prevents duplicates. Only a forced collision is affected, and that Keep is refused.
- **O-2:** the 48-bit id uses `<<`. That is safe on the 64-bit Dart VM but would truncate on web, which is not a target.

## 12. L-1 and accepted limitations

**L-1: OPEN — PRE-RELEASE BLOCKER — NOT FIXED — NOT WAIVED.** Wholly unreadable Preferences records survive Delete and are left out of Export. R8.3.3 does not touch this.

Still open:
- RL-4;
- real Android process-kill and storage recovery;
- S25 and TalkBack;
- real Premium restore and billing;
- migration and backup validation;
- privacy, analytics and retention;
- localization and audio QA;
- the final release security review;
- the legacy-duplicate repair policy, if real affected records are ever found.

## 13. Verdict

**PASS** for the R8.3.3 delta, with the two LOW residuals AUD-R833-1 and AUD-R833-2 recorded for founder disposition.

## 14. Engineering baseline

**Yes.** `285b5c701243e26efb543c68a2981d5e3471edbe` can serve as the technical engineering baseline. Neither residual violates durable confirmation, attribution, idempotence, temporal validity, serialization fidelity or Delete completeness.

## 15. Baseline versus commercial release

Accepting this as the engineering baseline **is not** a commercial-release authorization. Commercial release remains **unauthorized**: L-1 and the gates in §12 block it. **Phase E remains HOLD.**

---

My probe files are in the scratchpad, at `C:\Users\thoma\AppData\Local\Temp\claude\b7fd4c17e92f619e\fb8ede49-7c3e-4112-b879-89d56ac06d0e\scratchpad\probe\test\zz_audit\audit_r833_delta_test.dart`. Raw outputs are in `C:\Users\thoma\AppData\Local\Temp\claude\b7fd4c17e92f619e\fb8ede49-7c3e-4112-b879-89d56ac06d0e\scratchpad\out\`. No repository changes were made.