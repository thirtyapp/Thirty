# R8.2 final Plan lifecycle policy correction: evidence

- **Asked for by:** the founder directive "R8.2 final Plan lifecycle policy correction", 2026-11-06.
- **State:** committed in the single R8.2 commit on `step5-billing-integration` (parent `e935112c`), after founder acceptance at implementation level (2026-11-06). Not an independent audit pass; not a release.
- **Starting state:** `start_state/GIT_STATE.txt` (HEAD `e935112c`, nothing staged, no stash). The pre-fix tree is byte-identical to the end fingerprint of the reconciliation regression (`../claude_audit_reconciliation/regression_final/`, 2,753/0). That run is the retained pre-fix R8.2 evidence, and it is untouched.

## 1. The policy as implemented

| Order of the user's actions | Result |
|---|---|
| Start → **Pause** → Close durable | **Credited.** Original Plan, cycle, stage and Circle. The Plan stays paused. |
| Start → **another Plan started** (pauses this one) → Close durable | **Credited** to the original Plan only. The other Plan stays active and doesn't move on. |
| Start → Pause → Carry on → Close | Credited, as before (the Plan is active again). |
| Start → **Leave** → Close | **Not credited.** The Close is still saved to History. The left cycle doesn't move on. |
| Start → Pause → Leave → Close | Not credited (Leave before Close). |
| Start → **Close requested** → Leave while the Close is still being saved | **Credited once the Close is durable**, to the cycle that was left. The Plan stays left. |
| …then "Go through it again" before the Close lands | Credited to the **left** cycle. The new cycle never moves on. |
| Close requested, its write fails and never becomes durable | **Not credited**, also after restarts. |
| Close requested before Leave, History write refused, recovered from the day keys after a restart | **Credited**: it is the same Close (same instant). |
| Close refused outright, Leave, Circle closed again after a restart | **Not credited**: that Close came after the Leave. |
| A Start alone | Never credited. |
| Premium lapses between Start and Close | Existing rule: credited if served and started under Premium. A Start after a verified expiry earns nothing. Unchanged. |
| **Pause before the Start** | **No credit**: the existing rule, confirmed by the founder on 2026-11-06 (§5). |

**How it works (no new credit system, no new write).**

1. **Today reports the user's actions.**
   - When the user starts a stage Circle or asks to close it, Today tells the Plans at that moment (`CirclePlansNotifier.noteStarted` / `noteCloseRequested`). This is in memory only.
   - After a restart Today reports again from what it restores, and History's record stands in.
2. **Pause and Leave stamp the served record in their own save.** This happens in `_lifecycle`, through `_withActionOrder`.
   - A Pause after the Start, or an automatic pause by another Plan's Start, records `lastServed.startedBeforePause`, the Start's instant.
   - A Leave after the Close was requested records `lastServed.closedBeforeLeave`, the Close's instant.
   - Nothing is credited at this point.
3. **Credit still happens only after a durable Close.**
   - Today calls `recordGuided` only after the Close is saved, or from the restart catch-up on the saved day keys. It now passes that Circle's own `startedAt` and `closedAt`.
   - `CirclePlansState.recordGuided` credits a paused Plan's current cycle only when the stamped Start is *that* Start. It credits a left cycle only when the stamped Close is *that* Close.
   - Entitlement (`creditsServed`), at-most-once (`lastAdvancedCircleId`, records), and the original cycle id are unchanged.
4. **"Go through it again" after such a Leave** keeps the stamped served record (`_newCycle`). That record names the left cycle, so the new cycle is never credited.
5. **Founder decision A's fold** (`_withEarnedCredits`) now also considers paused Plans, still under the same rules.
6. **Latent bug fixed.** The domain used to clear `activePlanId` whenever the credited Plan wasn't active. Crediting a paused Plan would therefore have deactivated the Plan the user was running. It now only clears it for the credited Plan itself (stage 5 ending it).

**Stored format.**
- Two optional fields on `lastServed`, both UTC ISO 8601 instants.
- A present but malformed value makes the served record unreadable: it is kept as stored and credits nothing (the R81-A05 rule).
- Older records read as before.

**Files changed** (`source_diffs/`):
- `lib/features/plans/domain/circle_plan.dart`
- `lib/features/plans/application/circle_plans_provider.dart`
- `lib/features/home/application/recommendation_provider.dart` (27 lines added, none removed)

No entitlement, monetization, RevenueCat, Supabase, audio or localization code changed.

## 2. Failing-before → passing-after

`test/features/r82/r82_lifecycle_policy_test.dart` (new, 21 tests):

| | Pre-fix R8.2 tree | After |
|---|---|---|
| Total | 21 tests: **9 fail**, 12 pass | **21 pass** |
| Failing before (behaviour corrected) | Pause → Close; another Plan → Close; lapse before Close; failed Close → recovery ×2; Close → Leave with day keys held; Close → Leave with History held; Close → Leave + Go through again; failed Close → Leave → recovery | pass |
| Controls (must not change) | Pause → Carry on → Close; Start after expiry; Close never durable ×2; Leave → Close; Pause → Leave → Close; held Close refused ×4; a Close after the Leave; Pause before Start | pass |

The logs are in `repro_before_fix/` (with `BASELINE.txt`) and `passing_after/`.

## 3. Changes to existing tests (assertions changed by the policy)

All three asserted the rule the founder reversed (a Plan paused before the Close earns nothing). Scenarios unchanged; expectations follow the decision. Exact diffs are in `test_change_diffs/`.

| File | Test | Was | Now |
|---|---|---|---|
| `r82_decision_a_historical_credit_test.dart` | "not extended" → Pause BEFORE the Close | no credit | credited once; Plan stays paused; also after 2 restarts |
| same | Pause while the Close's History write is pending | no credit | not folded into the Pause; credited once the Close lands |
| `plans/r2_plan_credit_provenance_test.dart` | a Plan paused after its stage Circle was served… | cursor 1, no record | cursor 2, one record, Plan still paused |

The sibling R2 test "a Plan left after its stage Circle was served is not moved at Close" is unchanged and passes. That is Leave before Close.

## 4. The original Claude auditor reproductions

- **Unchanged files:** preserved at `../claude_audit_reconciliation/original_auditor_repro/`, with SHA-256 equal to the auditor's originals.
- **Run again on the post-fix tree:** 8 pass / 5 fail (`auditor_repro_post_fix/`). These are the same five as before the fix.
- **The five, one by one:** see `../AUDIT_HANDOFF_R8_2.md` §2.
- **Adapted forms:** 6/6 pass.

## 5. Remaining limitations of this policy (LOW)

1. **Pause before Start.** The policy doesn't cover a stage Circle served while the Plan was active, then the Plan paused, then the Circle started. The existing rule stands: no credit. Tested in "not covered by the policy". **Confirmed by the founder (regression authorization, 2026-11-06): a Pause before a valid Start does not earn credit.**
2. **Stage 5 on a paused Plan.** Its credit completes the cycle, so the Plan becomes *ended*, not paused. This matches decision A, where a stage 5 Close durable before a Pause also ends the Plan. It is not a reactivation.
3. **Stage 5 Close requested before Leave.** The left cycle receives the record but keeps its end as *left*. It is not converted to "reached the end".
4. **The repeated autumn hour (RL-4).** Two paths read History's times, which are stored without an offset:
   - the fallback stamp, used only when Today hasn't reported the action;
   - decision A's fold.
   In the repeated hour these may fail to match, and the credit is then withheld, never wrongly granted. Today's own credit uses the exact UTC day-key instants and isn't affected.
5. **The action order is held in memory.** It lasts until the Pause or Leave saves it. After a restart, Today reports it again from what it restores, before any Plan action can be taken.
