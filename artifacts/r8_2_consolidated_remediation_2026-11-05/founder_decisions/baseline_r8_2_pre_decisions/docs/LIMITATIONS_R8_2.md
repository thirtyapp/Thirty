# R8.2: accepted limitations and points for founder review

The R8.1 limitation record stays as committed:
`artifacts/r8_1_consolidated_remediation_2026-11-05/LIMITATION_RL4_OFFSET_FREE_TIMESTAMPS.md`.
This file only restates boundaries. No accepted limitation is widened.

## RL-4: offset-free historical timestamps (ACCEPTED, unchanged)

- **Unchanged.** R8.2 changes no export or timestamp format. History, Kept Circles and Suggestion Preferences still store local times without an offset.
- **The six-hour carry-over is exact only for new values.** Since R8.1, day-key Start, Close and pause are written as UTC instants, and the carry-over measures those exactly. Day-key values written offset-free before R8.1 remain ambiguous in the repeated autumn hour. The R8.1 record's phrase "six-hour rule unaffected" applies only to the newly written UTC values. Nothing is guessed for the older ones.
- **Not display-only.** The time of a lifted rest (`restsLifted.at`) is compared with "Not useful" answers. Within the repeated hour that comparison can be off by an hour. It never loses or invents data.
- **Native-type values (R8.2).** A value of the wrong native type under a user store is now handled as unreadable (R81-A09). No timestamp is reinterpreted.

## Superseded R8.1 limitation

- **R8.1:** "A stage Circle composed while its Plan change was pending, whose save then failed, stays on screen and is never saved."
- **R8.2 (R81-A03):** it is now taken off the screen as soon as it is certain it can't be saved, even if it was already started or closed, and the user is told. It is never written to the day keys.

## Other R8.1 limitations (unchanged)

- **Unreadable Plan.** It can't be started over, and Start shows no explanatory copy.
- **Unreadable Suggestion Preferences.** Changes are refused until Reset. Since R8.2 this also covers a value of the wrong native type.
- **Notification-shade carry-over, analytics at interaction.** As previously accepted.
- **No device QA.** No S25 run, no TalkBack run, and no real Android storage-failure run has been done.

## Points for founder review (not decided by this remediation)

1. **Credit after the Plan is durably paused or left.** If a stage Circle's Close was saved but its credit was not, and the user then pauses or leaves the Plan (and that change lands), the credit is not recorded. This is the existing domain rule that a paused or left Plan is not moved on. R8.2 keeps it and treats the credit as legitimately unnecessary. Only a change still pending, or one that fails, blocks or restores the credit. The test is `r82_a01…`, "the Pause lands". If the founder wants a Close made while the Plan was active to be credited regardless, that is a product-rule change.
2. **Withdrawal of a started stage Circle.** The R81-A03 fix also takes back a stage Circle the user had already started when its Plan save failed. Today's choice reopens, and the user has already been told the save failed. This happens only when storage fails in the seconds between the choice and its Plan save. The alternative would be to let the session run and refuse every save.
3. **I1 "carry on" marker repair.** A resumed Plan carries no date, so for an I1 whose step was "carry on", the repair checks only that the Plan is active. For "start" and "go through again", the repair requires a cycle begun on or after the day the Insight was shown.
4. **History copy of a native-type value.** A History value of the wrong native type is kept in the existing preserved-copies list as its JSON text, which records the type: `42`, not `"42"`. Plans and Insights keep such a value aside with its native type.
5. **Claude post-R8.1 report.** It was not in the workspace. NEW-1, NEW-2, NEW-3, E-1 and the marker-retry observation are implemented from the descriptions in the founder directive. Please supply the original so it can be preserved and the entries checked against it.
