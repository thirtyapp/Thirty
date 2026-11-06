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
- **R8.2 (R81-A03):** it was taken off the screen as soon as it was certain it couldn't be saved, even if it was already started or closed, and the user was told. It is never written to the day keys.
- **Founder decision B (acceptance review, 2026-11-05):** a Circle now starts only once its own save is confirmed, so only an offer not yet started is ever taken back. A refused Start leaves the Circle unstarted, tells the user, and can be tapped again.
- **Corrected description of the R8.1 limitation.** The original Claude post-R8.1 report asked for it, and said it "must not be closed silently". It was added 2026-11-06, after the report arrived.
  - On R8.1, *one* transient failure of the Plans write at choice time was enough.
  - The stage Circle stayed on screen. The user could still Start, run and Close the whole Circle, and answer its reflection.
  - None of it was saved: not the Start, the Close or the answers. History did not even keep the Circle as shown.
  - Separately, on healthy storage, any Plan action that replaced the Plan's last served record made an already-saved stage Circle unsaveable from then on. That was Claude NEW-1. It is closed.
  - The R8.1 wording ("stays visible … never saved") understated all of this.
  - Reproduced again on R8.1 and shown closed on the current tree: `claude_audit_reconciliation/`.

## Other R8.1 limitations (unchanged)

- **Unreadable Plan.** It can't be started over, and Start shows no explanatory copy.
- **Unreadable Suggestion Preferences.** Changes are refused until Reset. Since R8.2 this also covers a value of the wrong native type.
- **Notification-shade carry-over, analytics at interaction.** As previously accepted.
- **No device QA.** No S25 run, no TalkBack run, and no real Android storage-failure run has been done.

## Founder decisions (acceptance review, 2026-11-05)

Points 1–3 of the list kept below are decided. They are implemented in `founder_decisions/`.

- **Point 1 → decision A (yes).** A Close durably recorded before a later Pause, Leave or another Plan started keeps its credit. That credit is saved with the change.
- **Point 2 → decision B (not acceptable).** Start waits for the Circle's save. It is refused if that save fails, and a started Circle is never taken back.
- **Point 3 → decision C (not sufficient).** A mark is repaired only from the Insight's own provenance, saved with its change.

The original list follows, unchanged, as the record of what was put to the founder.

## Remaining after the founder decisions

1. **Decided 2026-11-06 (R8.2 final Plan lifecycle policy; `lifecycle_policy/`).** This was "not extended by decision A". It is now implemented as follows:
   - a Pause, or another Plan started, *after* the Start keeps the credit once the Close is durable;
   - a Leave *before* the Close earns nothing, and the Close is still kept in History;
   - a Close requested before the Leave keeps its credit once it is durable.
   - **Pause before the Start:** no credit. Confirmed by the founder (regression authorization, 2026-11-06).

   What remains open for the founder:
   - The LOW points in `lifecycle_policy/README.md` §5: stage 5 on a paused Plan ends it; a stage 5 left cycle stays "left"; the RL-4 repeated hour can withhold a fold; the action order is held in memory until the Pause or Leave saves it.
2. **LOW: no "starting" indicator.** While a Start waits for its save, the Start button stays as it is, and further taps do nothing. On a healthy device that lasts milliseconds. If the wait ends in a refusal, the user is told by an existing, founder-approved notice. No new copy or UI was added.
3. **LOW: wording of one refusal.** When a refused Start is also the first failure of the offer's own save, the user sees History's existing notice: "This Circle couldn't be saved to History. Your existing saved data wasn't overwritten." It doesn't say "Please try again". Each further refusal shows "This change couldn't be saved. Please try again." Exactly one notice is shown per refusal.
4. **LOW: provenance is one record per Plan.** A later Insight acting on the same Plan replaces the earlier one's provenance. If the earlier Insight's mark was also refused, its retry reports it not available rather than claiming it. That is truthful, but the mark is then not repaired.
5. **LOW, unchanged since R8.1: a Start after a verified expiry.** It is noted on the Plan's served record at the tap. If that Start is then refused because the offer couldn't be saved, the note stays. It says the Circle was started after expiry although it never started. Its only effect is to withhold a credit that couldn't exist anyway, and the next Start rewrites it from billing's answer then.
6. **Unchanged.** RL-4, the unreadable Plan, unreadable Suggestion Preferences, the notification-shade carry-over, and no device QA (above).
7. **The Claude post-R8.1 report: reconciled (2026-11-06).** It was supplied at 09:08 on 2026-11-06, after founder decisions A–C were implemented, which were therefore built without it. It is preserved unedited at `docs/audits/THIRTY_CLAUDE_POST_R8_1_AUDIT_REPORT.txt`, SHA-256 `96593e20…4c23a1`.
   - Every finding in it maps to a register entry.
   - None is open on the current tree.
   - One coverage gap was closed with a new test file: the report's own NEW-1 trigger scenarios. See `claude_audit_reconciliation/README.md`.
   - Still open for the founder, as the report says: RL-4's pre-commercial decision, and all commercial gates.

## Points for founder review, as put in R8.2 (decided above)

1. **Credit after the Plan is durably paused or left.** If a stage Circle's Close was saved but its credit was not, and the user then pauses or leaves the Plan (and that change lands), the credit is not recorded. This is the existing domain rule that a paused or left Plan is not moved on. R8.2 keeps it and treats the credit as legitimately unnecessary. Only a change still pending, or one that fails, blocks or restores the credit. The test is `r82_a01…`, "the Pause lands". If the founder wants a Close made while the Plan was active to be credited regardless, that is a product-rule change.
2. **Withdrawal of a started stage Circle.** The R81-A03 fix also takes back a stage Circle the user had already started when its Plan save failed. Today's choice reopens, and the user has already been told the save failed. This happens only when storage fails in the seconds between the choice and its Plan save. The alternative would be to let the session run and refuse every save.
3. **I1 "carry on" marker repair.** A resumed Plan carries no date, so for an I1 whose step was "carry on", the repair checks only that the Plan is active. For "start" and "go through again", the repair requires a cycle begun on or after the day the Insight was shown.
4. **History copy of a native-type value.** A History value of the wrong native type is kept in the existing preserved-copies list as its JSON text, which records the type: `42`, not `"42"`. Plans and Insights keep such a value aside with its native type.
5. **Claude post-R8.1 report.** It was not in the workspace. NEW-1, NEW-2, NEW-3, E-1 and the marker-retry observation are implemented from the descriptions in the founder directive. Please supply the original so it can be preserved and the entries checked against it.
