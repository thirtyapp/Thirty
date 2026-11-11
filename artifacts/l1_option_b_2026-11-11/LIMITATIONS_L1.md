# L-1 Option B: known limitations and residual risks

This file covers only issues that bear on this implementation. Other R8 findings are not reopened.

L-1 stays OPEN until the founder accepts it, after independent verification. Phase E stays on HOLD, and no commercial release is authorized.

## By design (founder-approved)

1. **Attribution THIRTY can't read stays durable.** A record THIRTY can't read as a whole keeps any Insight attribution inside it after Delete Circle history.
   - This is the approved exception, and it is disclosed rather than verified.
   - The record is never applied: the provider is empty, and recommendations, Plan stage 5 and Insights are unaffected (`test/features/l1/l1_delete_recovery_test.dart`).
   - Only the user's Reset removes it.
2. **Reset removes the whole record.** That includes unknown fields and any choices a newer THIRTY could have read. The warning says so (founder copy).

## Copy needing founder confirmation

See `LOCALIZATION_INVENTORY_L1.md`. Three strings are not verbatim founder copy:
- the memory notice, which was adapted so that it never claims a Delete took place;
- the one-sentence qualifier added to the Delete confirmation;
- the copy-failure SnackBar.

## Not changed (outside this mandate)

3. **Preference changes over an unreadable record.**
   - While such a record is stored, a new preference change such as "Don't suggest" is still refused. The user sees the existing generic notice, "This change couldn’t be saved. / Please try again."
   - Retrying doesn't help until the record is reset.
   - The memory page now explains the situation and offers Copy and Reset, but the generic notice itself is unchanged.
4. **No dialog when a pending Delete is finished elsewhere.**
   - A pending Delete can be finished at start-up, or before a new Circle (`resolvePending`). Neither path shows the qualified-completion dialog.
   - Instead, the persistent memory-page notice carries the disclosure, as the mandate (§6) designed.
5. **Double-tapping Reset.**
   - Tapping Reset twice before its warning opens can open two warnings. This is the existing dialog pattern, unchanged.
   - Each warning needs its own confirmation. The removal is idempotent and nothing is removed before a confirmation (tested).

## Platform and verification limits

6. **What the export is faithful to.**
   - The export reproduces the value as the `SharedPreferences` API returns it to THIRTY, losslessly.
   - It does not claim to reproduce the platform plugin's on-disk bytes, which Dart can't see.
   - "Copied" means the platform clipboard call returned without error. THIRTY can't read the clipboard back.
   - Inferred, not tested: a platform that rejects a very large clipboard payload by throwing gets the failure message.
7. **Simulated storage only.** Storage faults, acknowledgement loss and interruption were run on the committed `FaultDisk` harness, which is a simulation inside one Dart process.
   - No Android process kill, real storage failure, S25 or TalkBack validation of the new notice, Copy or Reset is claimed.
   - Large text (200%) and button semantics were checked in widget tests only.
   - The device-level gates stay open.
8. **Localization.** The new copy is English only, in line with the boundary in mandate §9. It is recorded in the inventory.
