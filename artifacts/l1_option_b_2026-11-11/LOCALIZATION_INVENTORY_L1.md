# L-1 Option B: new user-facing English copy (localization inventory)

These strings join the inventory for the approved six-language work. Machine translation is not authorized, and this round adds no ARB or localization framework.

Each string is a complete sentence or paragraph; none is assembled from fragments. All of them live in `lib/features/home/presentation/widgets/journal_data_controls.dart`.

| ID (constant) | Where shown | Source |
|---|---|---|
| `UnreadablePreferencesCopy.deletedTitle`: "Some saved preferences couldn’t be checked" | The notice after a successful Delete | Founder copy direction, verbatim |
| `UnreadablePreferencesCopy.deletedBody` (two paragraphs) | Same notice | Founder copy direction, verbatim |
| `UnreadablePreferencesCopy.memoryNotice`: "Some saved suggestion preferences couldn’t be read. They’re kept unchanged and may include links to earlier history that THIRTY can’t check. You can copy your data before choosing to reset them." | What THIRTY remembers | Adapted from the founder's suggested text, see the note below. Shown in the HOLD report and in the B8 pack diff that the founder reviewed for D-1 (11 November 2026). Still listed for the founder's final copy review. |
| `UnreadablePreferencesCopy.resetTitle`: "Reset unreadable suggestion preferences?" | Reset warning | Founder copy direction, verbatim |
| `UnreadablePreferencesCopy.resetBody` (two paragraphs) | Reset warning | Founder copy direction, with "show or **restore**" in place of "show or recover" (founder decision D-2, 11 November 2026, so the existing B8 live-copy guard passes unchanged) |
| `UnreadablePreferencesCopy.copyFailed`: "Couldn’t copy your data. Please try again." | SnackBar when Copy as text fails | New. Mandate §7.2/§7.3 requires an error and never "Copied". Shown in the HOLD report and in the B8 pack diff that the founder reviewed for D-1 (11 November 2026). Still listed for the founder's final copy review. |
| `deleteConfirmBodyWithUnreadablePreferences`: the existing confirmation plus "Some saved suggestion preferences can’t be read, so THIRTY can’t check them for links to this history; they’ll be kept unchanged." | Delete confirmation, unreadable record only | New. Mandate §5.3 asks for the smallest conditional qualification. Shown in the HOLD report and in the B8 pack diff that the founder reviewed for D-1 (11 November 2026). Still listed for the founder's final copy review. |
| `deleteConfirmBody` | Delete confirmation | Unchanged text, moved from the widget into a constant |

**Reused, not new:** "Copy as text" (button), "Reset suggestion preferences" (control), "Close", "Keep them", "Reset".

**Note on the memory notice.** The suggested text said the record "may include links to previously deleted history". Mandate §6 forbids claiming that a Delete occurred just because an unreadable record exists, and the record may predate any Delete. The text therefore says "links to earlier history that THIRTY can’t check", which keeps the warning without making that claim.
