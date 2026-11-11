# D-1: classification of the regenerated B8 content review pack

**Founder approval:** D-1 and D-2, 11 November 2026.

## How the pack was generated

- **Generator:** the existing, unmodified one: `flutter test test/features/b8/b8_review_pack_test.dart --dart-define=EXPORT_B8_PACK=true`.
- **Where it ran:** an isolated clean clone at `d9369795`, with only the final L-1 files copied in, so that `gitHead` is real.
- **Generator and extractor untouched:** `b8_review_pack_test.dart`, `support/live_copy.dart` and `b8_live_copy_guard_test.dart` all hash to the same blobs as at HEAD (855e9d06…, 4cf8d05a…, e04043e7…).
- **The diff:** `B8_PACK_DIFF_vs_d9369795.diff`.

## Every changed line

| Change | Classification |
|---|---|
| Header: generation time and `HEAD 58b179c9…` → `HEAD d9369795…` | Mechanical: new run, real HEAD |
| `Close *(×6)*` → `*(×7)*` | L-1: the qualified Delete notice's `barrierLabel: 'Close'` (journal_data_controls.dart) |
| Delete confirmation, original text removed then re-added | Not a change: the text is byte-identical, and diff alignment moved it |
| New: the Delete confirmation with "Some saved suggestion preferences can’t be read, so THIRTY can’t check them for links to this history; they’ll be kept unchanged." | L-1, the §5.3 conditional qualifier |
| New: "Some saved preferences couldn’t be checked" and its body | L-1, approved founder copy |
| New: the memory notice | L-1 |
| New: "Reset unreadable suggestion preferences?" and its body, now "…show or **restore**." | L-1, approved founder copy with the D-2 word |
| New: "Couldn’t copy your data. Please try again." | L-1 |
| "Copy as text" listed under memory_page.dart (D. You ×2; G. Accessibility), and its later duplicate lines under you_data_card.dart and journal_data_controls.dart dropped | L-1: the memory notice's Copy button. The pack lists each string once per surface, at its first occurrence (`seen` in the generator), so the string moves earlier. It is not removed. |
| Founder flag "Apostrophes are mixed …": "92 use ’" → "98" | L-1: exactly the 6 new strings that contain ’ (deletedTitle, deletedBody, memoryNotice, resetBody, copyFailed, and the qualified confirmation) |
| MANIFEST: `generatedAtUtc`, `gitHead`, `contentHashFnv64` | Mechanical |
| MANIFEST: `copyStringsExtracted` 666 → 675 | L-1: +9 = 6 new strings + 1 qualified confirmation + 1 `Close` + 1 `Copy as text` |
| MANIFEST: `founderFlags` 4 | Unchanged |

**Result:** no Today, Plans, Insights, Premium, lapse or other existing copy changed, no founder flag was added, and nothing was removed. **Every substantive difference is approved L-1 copy.**
