# RL-4 — offset-free historical timestamps (accepted R8.1 limitation)

**Status: ACCEPTED by the founder (2026-11-05) as a non-blocking technical limitation for this audit baseline. Not fixed. No export format changed in R8.1.**

## Affected stores

These values are written with `DateTime.toIso8601String()` of a local time, which carries no UTC offset:

| Store (key) | Fields | Writer |
|---|---|---|
| Circle journal (`circle_journal_v1`) | `shownAt`, `startedAt`, `closedAt` on each entry. Answer and replacement times go through these fields. | `lib/features/home/application/circle_journal.dart` (`CircleJournalEntry.toJson`) |
| Kept Circles (`toolkit_v1`) | `createdAt` | `lib/features/personal_circle/domain/kept_circle.dart` |
| Suggestion preferences (`suggestion_preferences_v1`) | `since` ("Don't suggest", left-out part), `at` (lifted rest) | `lib/features/home/application/suggestion_preferences.dart` |
| History export (Copy as text) | The journal and preferences above, as stored | the same `toJson` methods |
| QA scenario seeding (debug/QA builds only) | Day-key Start/Close/pause | `lib/core/qa/qa_scenario.dart` |

**Not affected:**
- **Plans and Insights:** they store calendar dates (`YYYY-MM-DD`), not instants.
- **The day keys behind the six-hour carry-over:** R8.1 (N09/AUD-5) writes their Start, Close and pause as UTC instants.

**Outside R8.1 (A2-06, not expanded here):** the analytics `occurred_at` sent to Supabase is also offset-free.

## Known daylight-saving ambiguity

When the clocks go back (Europe/Brussels: 25 October 2026, 03:00 CEST → 02:00 CET), the local hour from 02:00 to 03:00 happens twice. Two different instants in that hour serialize to the same text, for example `2026-10-25T02:30:00.000`.

On reading, Dart interprets such a value as one of the two instants. Which one depends on the platform. The other instant's true time is lost. No offset was ever stored, and THIRTY never guesses one.

## User-visible impact

- **History:** a time shown for a Circle recorded in that repeated hour can be off by one hour.
- **Ordering:** two such records can sort ambiguously by time. Dates and day attribution are unaffected, because each record also carries its own `localDate` / Circle id.
- **Recommendations and Insights:** they read the journal by date and by explicit answers, so an hour's error changes nothing they decide.
- **Kept Circles:** the creation time is display and ordering only.
- **Suggestion preferences:**
  - A lifted rest's `at` is compared with "Not useful" answers. One that falls inside the repeated hour could be off by an hour against an answer from the same hour.
  - In practice this is an edge of an edge, and it never loses or invents data.

## Why the approved six-hour carry-over is unaffected

The six-hour rule (`midnightCarryOverLimit`, founder decision D2) reads only the day keys' Start and Close:
- Since R8.1 those are stored as UTC instants and read back as local time.
- Both 02:30 occurrences are therefore distinct and measured in real elapsed time.
- Tests: `test/features/r81/r81_n08_n09_aud2_time_test.dart`, both occurrences on 25 Oct 2026.

Older offset-free day-key values still read exactly as before, as legacy local time.

## Future pre-commercial disposition (required)

Before the commercial release audit, a founder decision is needed on one of:
1. storing journal, Kept and preferences instants as UTC (or with their offset), plus a versioned export change and a reader for both forms; or
2. explicitly accepting display-only ambiguity for the repeated hour.

This belongs with the A2-06/A2-07 data, export and migration work. It is not to be changed silently.
