# R8.3.2: remaining risks and limitations

## Release blocker

**L-1: OPEN, NOT FIXED, NOT WAIVED, PRE-RELEASE BLOCKER.** Not modified in R8.3.2.

When the Suggestion Preferences record can't be read as a whole (a newer schema, a malformed list field, or not JSON):
- Delete Circle history reports success, but any Insight attribution (`byInsight`) inside the record stays on disk.
- Export leaves the record out.

What this affects today:
- The record isn't applied to recommendations, Plan stage 5 or Insights.
- It does make ordinary preference changes refuse until Reset.
- The privacy consequence is real but narrow. Evidence derived from History (which Insight caused a choice) survives a Delete that the user was told succeeded. The user can neither see it nor export it.
- No current build writes such a record. It comes only from a downgrade, a restore or outside damage.

Claude's H2 is part of L-1: a future build that reads the record could bring the ids back.

No commercial release is authorized until a safe Delete/Export disposition is implemented and verified. The options are in `r8_3_1_.../l1_assessment/L1_ASSESSMENT.md`.

## Open, awaiting a scope decision

**R832-B1 and R832-B2.** After I3's Put back or I4's kept-Circle removal, a retry of an Insight whose mark was refused repeats its action. This violates D3. See `open_findings/R832_B1_B2_SCOPE_DECISION.md`.

## Decision point

**N01-C linearization.** If a Plan change is tapped while a paused Start's own record is being written, it is ordered after that Start. So the Start is never credited. The conservative alternative, waiting for the change and crediting it if it is a Resume, needs a founder decision. See `CONTRACTS_R8_3_2.md` §A.4.

## Bounded, by design

- **Single paused-Start slot (Astra §5).** A newer paused Start of a later Circle replaces the record.
  - At domain level, `recordGuided` would still credit an older Circle if its Close were replayed after that.
  - No production caller does this. The older day is resolved by `_recordBeforeOverwrite` before the next day's Circle is published; the fold reads only `lastServed`; catch-up reads only the day keys.
  - It is executed on the production path in S1. Any future, wider journal replay must keep the exclusion identity.
- **Instant identity.**
  - An abandoned preparation and a later valid Start are told apart by their instants.
  - Besides that, the abandoned record is superseded before any new Start of the same Circle (Contract A rule 3).
  - If `recordGuided` is ever given no start instant, it fails closed: no credit.
  - RL-4 (offset-free historical timestamps) is unchanged. The instants written by R8.3.2 are UTC.
- **A stricter fast path.** A Start goes the waiting way whenever any Plans change is still pending, not only when that Plan's own change is pending.
  - That is a few milliseconds of an unindicated wait, which is the existing "no starting indicator" limitation.
  - If Plan changes keep arriving, the Start is refused after 8 rounds, as for every other R8.2 wait.
- **Downgrade.** An R8.3.1 build reads the new record object as an unreadable Plan. It keeps the Plan as stored and runs nothing (fail-closed). R8.3.1 is not released.

## Unchanged from R8.3

These keep their R8.3 status:
- L-2 (one provenance record per Plan). This is now safe after an overwrite (R83-N03); it is not safe after the I3/I4 erasures (R832-B1/B2).
- L-3, L-6.
- RL-4.
- The analytics unknown-cohort string (LOW, analytics-only, not changed).
- Device-level recovery is unproven. The fault harness simulates SharedPreferences inside one Dart process. No real process kill, storage fault, S25 or TalkBack run was done.

## Commercial gates

Phase E is on HOLD. These gates are untouched:
- L-1;
- the device recovery and storage tests;
- S25 and TalkBack;
- RL-4;
- analytics, privacy and retention;
- backup, migration and a real Premium restore;
- the billing and release-APK security review;
- localization and audio QA;
- the final commercial audit.
