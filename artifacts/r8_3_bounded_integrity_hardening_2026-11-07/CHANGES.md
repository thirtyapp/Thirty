# R8.3 — code changes and root causes

**Scope.** Option B, bounded integrity hardening: no new storage technology, no migration, no key rename, no schema version bump, no new dependency. The exact diffs are in `source_diffs/lib.diff` and `source_diffs/test_support.diff`.

## Production: 15 files

Six are the core fixes. Nine are the small D5 type-safe reads.

| File | Change | Finding | Contract / invariant |
|---|---|---|---|
| `plans/domain/circle_plan.dart` | `ServedStageCircle.toJson` takes `source` minus every known key, then the known fields from the model: a cleared flag or absent stamp is written absent. `AppliedInsight.extra` keeps the unknown fields of a stored valid record | Astra R82-N03 / Claude AUD-N1, Astra R82-N04 | Codec rule, V |
| `plans/application/circle_plans_provider.dart` | `forgetStageEvidence` clears the `_startedAt`/`_closeRequestedAt` maps. Its write is computed at its own queue turn from the last confirmed Plans (`_durable`) without evidence, no longer from the optimistic `state` taken when Delete began. What is shown returns to that confirmed state when it lands or fails, unless the user changed something since | Claude AUD-N2, Claude AUD-N3 (D4) | VI, I |
| `home/application/suggestion_preferences.dart` | `PreferenceChange` outcome (`changed`/`unchanged`/`refused`/`notSaved`); `_change`; `idle()`; `leaveOutChange`. `forgetInsightProvenance()` and `forgetInsightProvenanceIn(prefs)` (D1). Domain: `SuggestionPreferences.withoutInsightProvenance`, `ElementLeftOut.withoutInsight`. Public `Future<bool>` methods unchanged | Astra R82-N02, Claude O-1 (D1) | Contract 1, I, II, VI |
| `insights/application/insights_provider.dart` | `apply` waits for the preferences too. Provenance first, for a current or stale snapshot: it marks from the original date and never acts. `_leaveOut` maps the outcome faithfully (`unchanged` gives `alreadyApplied`, no mark) | Astra R82-N01 (D3), Astra R82-N02 | Contract 2, II, III |
| `home/application/recommendation_provider.dart` | `_startOnceSaved` checks the local day again right before the started transition. If it has passed, nothing starts and `nowProvider` is invalidated, as for a tap after midnight | Astra R82-N05 | Boundary rule A, IV |
| `home/application/circle_history_deletion.dart` | The D1 step runs after the intent is durable and again in the last pass, with the preferences waited for. Start-up completion removes the attribution too | Claude O-1 (D1) | Boundary rule B, VI |
| `home/application/v1_premium_retirement.dart` | Marker read as stored; a foreign value is kept, and the retirement still runs | O-2 (D5) | V |
| `reminder/application/reminder_provider.dart` | `build` reads type-safely. `_persist` writes only what the user set | O-2 (D5) | V |
| `core/analytics/analytics_consent.dart` | Only `true` is consent | O-2 (D5) | V |
| `core/analytics/tester_identity_provider.dart` | A foreign id or cohort is never written over | O-2 (D5) | V |
| `home/application/first_breath_provider.dart` | Date read type-safely | O-2 (D5) | V |
| `premium/application/premium_offer_provider.dart`, `premium/presentation/widgets/premium_offer_invitation_card.dart`, `reminder/application/reminder_invitation_provider.dart`, `reminder/presentation/widgets/reminder_invitation_card.dart` | Flags read type-safely. A foreign value counts as shown and is never written over | O-2 (D5) | V |

**Not changed:**
- billing or entitlement code, RevenueCat, Supabase;
- audio, copy, localization;
- any existing test file. The one pre-existing `M` test file, `r6_kept_voice_whole_circle_test.dart`, has a line-ending difference only, and was left as found.

## Test infrastructure

- **`test/support/r8_fault_disk.dart`**
  - `ackLost(key, {times, thenStop})` and `HeldWrite.releaseAckLost()`: the value lands, then the call fails, or the process stops. Recorded in `ackLostLog`.
  - The single-writer guard `overlaps`.
  - `DiskFault` is unchanged, so every existing test that loops over `DiskFault.values` keeps its inventory.
- **`test/support/r83_invariants.dart` (new):** `DurableState`, the disk-only oracle:
  - round trip (V);
  - applied without provenance (II);
  - started off its day (IV);
  - deletion residue with ownership preservation (VI).
- **`test/features/r83/` (new, 7 files, 74 tests):**
  - codec law;
  - Insight attribution;
  - Start boundary;
  - Delete boundary;
  - start-up types;
  - cross-store (ack-lost credit, stage-5 boundaries);
  - the harness self-test.

## Evidence tooling

- **`regression/run_batches.py`:** the R8.2 runner plus raw-log validation (E-1 residual). Every change is in `RUNNER_DIFF_vs_R8_2.txt`.
- **`regression/drive_regression.sh`:** reads the batches from the plan, and writes Git-blob manifests at start and end.
- **`e1_raw_validation/check_raw_evidence.py`:** 17 damage scenarios, run on disposable copies of the R8.2 definitive evidence.
- **`verify_audio.py`.**
