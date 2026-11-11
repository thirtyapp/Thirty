# R8.3.4.1 founder gate §3 — bounded I1/I2 triage

**Result: no MEDIUM/HIGH integrity violation established. The commit gate proceeds.** The path is reachable. Its outcome is a LOW consistency difference from I3/I4. It is not a contract violation.

## Method (disposable only)

`build_triage.py` copies the repository's `test/features/r833/r833_reproduction_test.dart`, which itself stays unmodified. It inserts `triage_block.dart.txt` before the end of that file's `R832-A01` group, reusing Astra's R83-N03 fixtures:

- `i1OverUnmarkedI2`: I2 was applied durably and its Applied mark refused. The user turned Gentler off and paused the Plan. Seven days later I1 is shown.
- `i2OverUnmarkedI1`: I1 was applied durably and its mark refused. I2 is still current.

The composed file is saved here as `r8341_i1i2_triage_test.dart.txt`. It was run only in the two disposable exact-SHA trees.

Each run does the following:

1. Hold the later Insight's reconciliation, which writes the displaced Insight's Applied mark to Insights.
2. Begin a Delete. Answer its intent as refused, uncertain-not-landed, uncertain-landed (acknowledgement lost; the cache shows no marker while the disk holds `true`), or confirmed.
3. Release the reconciliation only after the outcome has been announced.
4. Inspect memory, the confirmed bytes, a restart, and a retry after restart.

## Results (`triage_on_fixed.txt`, `triage_on_dd9000cd.txt`)

| Case | apply | Before restart | After restart |
|---|---|---|---|
| I1/I2 refused | done | Plan changed. Attribution and Applied marks are the later Insight's own; the earlier one is marked on its own date. | Same. Retry: `alreadyApplied`. |
| I1/I2 uncertain, not landed | done | Same as refused. The marker is not on disk, so no deletion happened. | Same. Retry: `alreadyApplied`. |
| I1/I2 uncertain, landed | done | Plan changed (I1: paused → active; I2: Gentler on), with own attribution and marks. Marker `true` on disk. | The deletion was finished at start. Journal and Insights are gone and `appliedInsight` is removed. **No key names either Insight.** The Plan keeps its place. Retry: `notAvailable`, so no replay. |
| I1/I2 confirmed | notAvailable | Epoch 0 → 1. Plan unchanged (I1 case: still paused; I2 case: no Gentler). | Clean. No key names either Insight. |

All 8 runs pass the built-in invariants:
- an Applied mark appears only with the Insight's own change on disk;
- after a confirmed or landed Delete, no attribution or id survives;
- a confirmed Delete changes nothing;
- there is no replay.

The TRIAGE evidence lines are **byte-identical on dd9000cd and on the fixed tree**. The behaviour predates R8.3.4.1, which does not change it.

## Assessment against the founder's questions

| Question | Finding |
|---|---|
| False Insight application? | **No.** Every Applied mark matches a Plan change that carries that Insight's own provenance. |
| Deleted attribution reintroduced? | **No.** Confirmed: nothing is written after the boundary. Landed: recovery's `forgetStageEvidence()` keeps only `planId`, lifecycle and cycles, and Insights are removed, so no key names either id. |
| Incorrect mutation of a user-owned Plan? | **No integrity violation.** The change is the user's own tapped I1/I2 action. A Delete keeps each Plan's place by contract. For uncertain-landed, the end state equals "applied, then deleted", which is also what a fresh tap right after the same uncertain Delete gives (accepted D3 behaviour). Only a confirmed boundary must stop it, and it does. |
| Invalid Applied marker? | **No.** |
| Conservative uncertain-write handling violated? | **No.** No target write is uncertain here and nothing is replayed. |

## Residual (LOW, disclosed, not remediated)

After R8.3.4.1, an I3/I4 that overlaps an uncertain Delete cancels; an I1/I2 in the same position proceeds. R8.3.4 CONTRACTS §2.5 kept I1/I2 unchanged by design, so this is a consistency difference, not a breach. The founder may decide later whether I1/I2 should adopt the same conservative cancel. That would require the same `answered` check before `_direct`/`_gentler`, and it was not done here.
