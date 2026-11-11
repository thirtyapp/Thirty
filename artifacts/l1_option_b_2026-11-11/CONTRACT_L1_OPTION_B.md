# L-1 Option B: the implemented contract

**Founder decision:** 11 November 2026.
- Approved: Option B, together with its four mandatory conditions.
- Rejected: Option A (fail closed) and Option C (rewrite unknown schemas).
- Deferred: Option D (an erase choice inside Delete).

**Starting point:** the frozen R8 baseline `d9369795a92aa24505c475fa1417d03132300c4a`. Its sole parent is `dd9000cd…` and its tree is `11a2b7ef…`.

## Root cause (from the L-1 read-only discovery)

Every L-1 symptom traces back to one behaviour. `SuggestionPreferences.tryRead` returns `null` for a record THIRTY can't read as a whole, and `SuggestionPreferencesNotifier.build` then shows `SuggestionPreferences.empty`. The fact that such a record was stored was visible only as a private flag, `_storedUnreadable`.

That single gap produced three problems:
- **L-1A, Delete.** The Delete was reported as done, with no qualification.
- **L-1B, Export.** The record was left out of the export, and Copy was disabled when it was the only thing stored.
- **L-1C, Reset.** Reset was hidden.

## The correction: one fact made visible

**`suggestion_preferences.dart`**
- `UnreadableSuggestionPreferences` holds the stored value exactly as the `SharedPreferences` API gives it.
- `unreadableSuggestionPreferencesProvider` makes it reactive:
  - It is built from the stored record, so the state is correct after every start.
  - It becomes `null` only inside `_change`'s existing confirmed-write block, after the store has confirmed a write over the record. In practice that write is Reset, which uses `erase: true`.
  - A Reset that is refused, uncertain, or lands but loses its acknowledgement goes through `writeConfirmed`, which puts the record back. The provider keeps the record in all three cases.
- `toExport()` is the lossless, typed export form described below.

**Unchanged:** the Delete engine (`circle_history_deletion.dart`), `_change`'s refusal over an unreadable record, `forgetInsightProvenance`, `forgetInsightProvenanceIn`, the marker, start-up completion, and every R8 ordering or confirmation rule.

| Founder condition | Where it is met | Behaviour |
|---|---|---|
| 1. Qualified Delete completion | `journal_data_controls.dart` `confirmAndClear` | The confirmation adds one sentence when the record is unreadable (`deleteConfirmBodyWithUnreadablePreferences`). The readable wording, `deleteConfirmBody`, is byte-identical to before. After `delete()` completes normally, and only then, a notice shows the approved title and body if the record is still stored. The not-started and unfinished paths are unchanged and never show this notice. |
| 2. Persistent transparency | `memory_page.dart` `_UnreadablePreferences` | The notice is derived from the stored record by the provider. It is shown after any restart, including after start-up completion. It never says that a Delete happened, and it disappears only once a Reset is confirmed. No new persistent flag is stored. |
| 3. Lossless opaque Export | `circle_journal.dart` `exportAsJson(suggestionPreferencesStored:)`; `journal_data_controls.dart` `copyAsText` / `canCopyAsText` / `exportToClipboard` | One additive key. History, You and the memory page share one implementation, reading everything at tap time. Copy is enabled when the unreadable record is the only data. A failed export or clipboard call shows "Couldn’t copy your data. Please try again." and never "Copied…". |
| 4. Explicit Reset | `memory_page.dart` | Reset is shown when there are readable preferences **or** an unreadable record. The unreadable record has its own warning (the approved title and body), and Copy as text sits beside the notice. Cancelling writes nothing. The existing `reset()` (`erase: true`, confirmed write) is unchanged. |

## Export form: `suggestionPreferencesStored`

This key appears only for a record THIRTY can't read as a whole. In that case `suggestionPreferences` is absent, so no empty record is ever exported in its place.

| Stored type | Export |
|---|---|
| String | `{"type": "string", "value": "<exactly as stored>"}`. This covers whitespace, non-ASCII and empty text. JSON escaping carries an unpaired surrogate as `\udXXX`, and it round-trips exactly. |
| bool | `{"type": "bool", "value": true \| false}` |
| int | `{"type": "int", "value": "<decimal>"}`, as text so that no reader loses digits (tested at 2^53+1 and −2^63) |
| double | `{"type": "double", "ieee754Hex": "<16 hex digits, binary64, big-endian>"}` (tested for −0.0, NaN, ±∞, the smallest subnormal and 0.1) |
| List of strings | `{"type": "stringList", "value": [...]}`, with order, duplicates and blanks kept (tested, including an empty list) |
| anything else | `UnsupportedError`. The whole copy fails and says so, so the record is never silently omitted. The `SharedPreferences` API exposes no other type. |

The export reproduces the value as the `SharedPreferences` API returns it to THIRTY. How the platform plugin lays that value out on disk is not visible to Dart, and is not claimed. THIRTY itself adds no alteration.

## Contract amendment

`docs/product/PRODUCT_V2_CONTRACT.md` has one new block under Delete / Export, dated 2026-11-11 and named L-1 Option B. No earlier decision was removed or reworded.
