# Existing tests changed in the final founder scope pass, and why

No assertion was removed or loosened. Each change follows one of two rules from the founder's decisions of 2026-11-07, and each is annotated in the test file.

**Rule 1: an Insight receipt comes first (B1/B2).** I3 and I4 now record their attempt before their action. A fault that a test intended for the **applied mark** therefore moves onto the write that carries the mark, using `FaultDisk.failWhere` with a match on `"appliedOn"`. The scenario is unchanged: the change is saved and the mark is refused. For I1 and I2 the mark is still the first Insights write, so their behaviour is identical.

**Rule 2: no unprotected mutation.**
- "A failed receipt write must not permit an unprotected target mutation."
- "If the outcome is uncertain … do not replay."

Where a test asserted that I3 or I4 makes its change with every Insights write refused, or replays after a write that threw, the expectation now asserts the decided behaviour.

**N01-C rule.** A lifecycle change during an unresolved Start cancels it.

| File | Change | Rule |
|---|---|---|
| `test/features/r83/r831_start_eligibility_test.dart` (Start tapped while its offer is saved, then the Plan is paused) | After the offer lands, the status is `notStarted` (cancelled). The user taps Start again: started, Close, Resume, restarts. Credit is still **0**. | N01-C |
| `test/features/r83/r83_start_boundary_test.dart` (founder decision D2) | The same: cancelled, then a fresh Start on the paused Plan. All later assertions are unchanged: no `startedBeforePause`, the Circle ran, 0 credits, still paused after a restart. | N01-C |
| `test/features/r82/r82_a04_a08_new3_insight_actions_test.dart` (`markRefused` helper) | `hold(insightsKey)` on the first write becomes `failWhere(appliedOn, fault, times: 1)`. | 1 |
| `test/features/r82/r82_decision_c_insight_provenance_test.dart` ("residual: the Insights store refuses every write") | I1 and I2 are unchanged. The I3 case is replaced by a stricter one: with every Insights write refused, **nothing is left out** (`notSaved`). Once the store takes it, the retry applies once and is marked. | 2 |
| `test/features/r81/r81_n04_n05_expiry_and_insight_application_test.dart` | "Its own store throws", I3 only: after the restart there is no replay, no change and no mark, because the outcome is uncertain. `returnsFalse` and I1/I2 are unchanged. "Mark refused": the fault moves to the mark write. | 2, 1 |
| `test/features/personal_circle/r8_kept_ownership_persistence_test.dart` (Insight 4's Keep) | "The Circle's save throws": no Keep again and never applied, because the outcome is uncertain. `returnsFalse` is unchanged. "I4's own record refused": the fault moves to the mark write. | 2, 1 |
| `test/features/home/r8b_precommit_persistence_test.dart` (I4's own record throws) | The fault moves to the mark write (`throws`). | 1 |
| `test/features/r832/r832_reproduction_test.dart` B5 | Before: started, never credited (the conservative linearization). After: cancelled, then a fresh Start on the active Plan is credited once. | N01-C |

## Harness

`test/support/r8_fault_disk.dart` gains `failWhere(key, matches, {fault, times})`. It fails only the writes of `key` whose text matches; other writes land. It is test-only, and `healAll` clears it.

## Auditor originals (not edited; preserved verbatim)

Claude's R8.2 probe **AUD-O3** ("Start tapped while its offer save is pending, then Plan Pause, then Close: credited?") asserts `started` as an intermediate step. Under N01-C that Start is cancelled, so the probe now stops at that assertion. Its question, whether such a Circle is credited, is answered **no**: here, by N2 and by the updated R8.3/R8.3.1 tests. The other 26 auditor tests pass unmodified.
