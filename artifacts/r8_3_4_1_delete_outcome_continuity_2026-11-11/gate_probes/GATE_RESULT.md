# R8.3.4.1 founder gate §4 — verification of the completed R834-N01 fix

## Method

The permanent tests and production files are unchanged, so the definitive regression evidence still applies.

`build_gate.py` copies the permanent `r8341_delete_outcome_continuity_test.dart` and appends three disposable probes per family, saved as `gate_block.dart.txt`. The composed file is saved as `r8341_gate_probes_test.dart.txt` and was run in the fixed tree and in the exact dd9000cd tree.

## Probes

| Probe | Fixed tree | dd9000cd |
|---|---|---|
| GATE-1: uncertain intent, then confirmed, both answered before the held receipt resumes | **PASS** (I3, I4). `notAvailable`; epoch 0 → 1; snapshot, receipt and target are all absent; after restart no key names the Insight | PASS: the confirmed epoch already stops it |
| GATE-2: Insights provider rebuilt (`invalidate`) while the receipt is held, then an uncertain intent | **PASS** (I3, I4). `notAvailable`; receipt kept; nothing made; after restart stale, retry `notAvailable` | **FAIL** (I3, I4). `done` with the target made: this is R834-N01 |
| GATE-3: deletion provider forcibly rebuilt after two refused Deletes, then an uncertain intent overlaps (characterization, no expectation) | `done`, target made | `done`, target made |

## Disclosed limitation: GATE-3, not reachable in the app

The counters live on the `CircleHistoryDeletion` instance.
- A new instance restarts numbering at 0.
- An application that captured `answered = 2` from the old instance therefore cannot see the new instance's uncertain intent number 1.

In the app this instance is never rebuilt:
- `circleHistoryDeletionProvider` is a plain keep-alive Riverpod 3 `Provider` whose instance uses only `_ref.read`, never watch or listen.
- No file under `lib/` invalidates or refreshes it.
- The app uses one `ProviderContainer` (`main.dart`), and a restart ends every in-flight operation.

`HistoryWriteGate`'s epoch, which R8.3.3 already relies on, has the same lifetime property.

In GATE-3 the application's own writes are all confirmed and its Applied mark is true. No uncertain write becomes a false confirmation; the missed item is only the R834-N01 conservative cancel. Should the founder want to rule out this dependency, the counters can be made process-wide, or `apply` can treat an instance change as uncertain. Either is a production change and would need a new full regression. It was not done here.

## Covered by the definitive regression (raw log `regression/batch_16.jsonl`)

The raw log's SHA-256 matches its summary. All 32 permanent tests pass with no skips, each with its own `R8341-EVIDENCE` line. Together with GATE-1 and GATE-2 they cover:
- an uncertain intent that finishes before the receipt resumes, both not-landed and landed;
- successive intents: uncertain→refused, landed→refused, refused→uncertain, refused→refused, and uncertain→confirmed (GATE-1);
- a refused Delete that never began;
- restart, and an Insights provider rebuild;
- I3/I4 receipt creation, target and clearance;
- no false Applied mark and no replay.
