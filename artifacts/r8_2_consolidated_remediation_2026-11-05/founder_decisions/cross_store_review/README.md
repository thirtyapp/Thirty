# Cross-store review of the founder-decision changes

Each new mechanism was checked against the other stores: Today's day keys, History, Plans, Insights, Suggestion Preferences, Delete Circle history and billing.

## Defects found and fixed before the full regression

| ID | Found by | What | Fix | Evidence |
|---|---|---|---|---|
| FD-B-1 | The existing R2 test "a second Start, a direct credit and a restart after a start past expiry: nothing credited" failed on the first draft of decision B. | The Start waited, and its Plan record of "started after a verified expiry" was written only when the queued Start ran. A credit asked for meanwhile was judged on billing's earlier answer and granted. | The record is noted at the tap, as in R8.1. Only the started state waits. | The R2 test passes with its assertion unchanged. |
| FD-B-2 | Review of `_offersOnDisk` across the rebuild that Delete Circle history causes. | After a Delete, the same offer chosen again, with its save refused, could be taken as already saved, so Start would run unsaved. | Every later rebuild forgets any confirmation the day keys no longer hold. It only ever forgets. | `delete_then_rechoose_WITHOUT_build_rule.jsonl`: the test fails with the rule removed from a scratch copy of the current tree; nothing else differs. `delete_then_rechoose_WITH_build_rule.jsonl`: it passes on the real tree. |

## Interactions checked, with no defect found

| Interaction | Outcome |
|---|---|
| **A × Delete Circle history** | `forgetStageEvidence` drops `lastServed`, so nothing is folded in afterwards. A fold-in before the Plans pass of a Delete moves the place on, and the Delete then removes the stage records but keeps the place, exactly as for any credited Circle. A save queued before the Delete never restores deleted evidence: the R81-A02 generation rule. |
| **A × Premium** | The same rule as `recordGuided`. It is tested both ways: lapsed after a Start under Premium (credited), and started after a verified expiry (not credited). |
| **A × Insight I1** | A Carry on or Start made by an Insight goes through the same lifecycle path, so it folds in the other Plan's earned credit too. |
| **A × a refused save** | The Pause and its folded-in credit are taken back together. `recordGuided` then resolves the credit again on what the disk holds. It no longer fails at once while the folded save is pending. |
| **B × the Plans queue** | `startNeedsNoWrite` takes the fast path only when the served record on disk equals the one shown. A pending Plan action that leaves that record alone doesn't hold up Start. |
| **B × Replace and Use it today** | Both are refused while a tapped Start waits, so a Start is never silently dropped. |
| **B × Today's write gate (Delete)** | A Start whose write is overtaken by a Delete is dropped quietly. It isn't reported as a refusal. |
| **C × NEW-3** | The provenance is part of the change's own save, so `confirmed()`'s leaf-level check covers it. |
| **C × Delete Circle history** | `forgetStageEvidence` drops `appliedInsight` along with the Insights it would attribute. |
| **C × a damaged record** | It attributes nothing and is written back as stored. This is tested. |

All of the above is covered by `test/features/r82/r82_decision_{a,b,c}_*` and the unchanged R8.1/R8.2 suites, in the full regression.
