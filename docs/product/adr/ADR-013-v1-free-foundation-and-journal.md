# ADR-013 — V1 Productization Batch 1 / Free Foundation + Prospective Local Journal

**Status:** Accepted

## Context

Concept validation passed. THIRTY moves from prototype to V1 productization
under a frozen product contract:

- **Free** is a complete, indefinite Daily Circle product.
- **Premium V1** (Circle Plans, a bounded contextual Circle Coach, and
  actionable Circle Insights — [`PREMIUM_STRATEGY.md`](../PREMIUM_STRATEGY.md))
  is out of scope for this batch entirely — no Plans, Coach, Insights,
  Premium Atmosphere, billing, or entitlement logic is implemented here.
- Premium's future Insights will need to interpret a user's own history.
  That requires a legitimate, versioned, local record of what actually
  happened on past Circles — which does not exist yet. Batch 2's
  per-`Intention` anti-repetition history (ADR-012) is not that record: it
  is short (`pool.length - 1` entries), unordered by date, carries no
  timestamps, and is silently truncated — using it as a historical record
  would fabricate one.

This batch (**Batch 1** of V1 productization) turns the validated
prototype Free Circle into a reliable V1 foundation, and lays the
narrowest possible prospective local record Premium's later systems will
need — without building any of those systems now.

## Decision

### 1. Frozen V1 launch catalogue (21 placements)

`activity_catalog.dart`'s `activityPools` grows from 7 activities (2/3/2
per direction) to the frozen V1 target: **exactly 7 reviewed placements per
`Intention`, 21 total**, each direction covering **at least 4 genuinely
different `ActivitySemanticFamily` values** (in practice, every placement
in this catalogue has a distinct family from every other placement in its
own direction — 7 of 7, not merely 4 of 7 — so no direction relies on
walking variants, or any other single family, to pad out its count).

- The 7 v0 identities (`thirtyMinuteWalk`, `moveToMusic`, `phoneFreeWalk`,
  `writeItDown`, `quietReading`, `easyWalk`, `quietMusicBreak`) are
  **reused unchanged** — same `ActivityId`, same pool membership, same
  `why`-copy. Reusing stable identities across a catalogue revision means
  no device's persisted `recommendationActivityIdKey`, per-intention
  history, or (once this batch ships) journal entry ever needs a migration
  just because the catalogue grew.
- 14 new identities were added (5 More Energy, 4 Clearer Head, 5 Gentler
  Pace), each with a full `ActivityDefinition` (`activity_catalog.dart`):
  title, one immediate first action, concise instructions, a truthful
  preparation/equipment constraint, explicit self-paced/stop language, a
  semantic family, and a `whyCopyFor` entry following v0's existing rule
  (truthful, practical, never a claim of hidden knowledge about the user).
- No cross-direction `ActivityId` sharing was introduced — every reviewed
  V1 placement is concrete and direction-specific enough on its own that
  sharing an identity would blur rather than clarify why it was
  recommended, matching v0's own reasoning for rejecting "Gentle mobility"
  as a shared candidate.
- `catalogVersion` (`activity_catalog.dart`, currently `1`) is a new,
  explicit content-version marker, carried on every `Recommendation` and
  every `CircleJournalEntry`, so a future catalogue revision can tell
  which version of the catalogue produced a given historical record.

### 2. Selection/diversity hardening

Batch 2's per-`Intention` history guard (ADR-012) is preserved exactly.
One narrow extension is added: `selectActivityId` now also accepts an
optional `lastShownFamily` (`ActivitySemanticFamily?`) and, **after** the
existing history filter, excludes any remaining candidate sharing that
family — but only when doing so still leaves at least one candidate,
otherwise this second filter is skipped entirely. `lastShownFamily` is the
family of the immediately prior Circle regardless of which `Intention` it
belonged to (`recommendationLastFamilyKey`, a single intention-independent
key), so choosing a different direction two days running no longer trivially
lands on the same kind of activity. Still two fixed, sequential, documented
exclusion filters — no scoring, no weights, no general recommendation
engine, and still a fully deterministic fallback at every stage.

`_restoreRecommendation` (`recommendation_provider.dart`) now also
validates that a persisted `(intention, activityId)` pair is still
*compatible* — `activityId` must actually belong to `intention`'s pool —
before trusting it, not just that both parse to known enum values. An
incompatible pair (which cannot occur going forward, but could arise from
a downgrade or a manually edited store) fails safe to "no recommendation,"
exactly like a missing or corrupt value already did.

Today's resolved activity stays frozen for the reasons already structural
to `RecommendationNotifier`: `chooseIntention` is a hard no-op once
`state.recommendation != null`, and nothing about foregrounding,
`ThemeMode`, or a future Premium entitlement change ever calls it — only an
explicit user tap on the Daily Context Question does.

### 3. Daily state / persistence

The existing per-day `SharedPreferences` keys
(`recommendationDayKey`/`…IntentionKey`/`…ActivityIdKey`/`…StatusKey`/
`…StartedAtKey`/`…ClosedAtKey`) are kept as the live "today" record — they
were already one coherent, notifier-owned write group with a fail-safe
restore path that already tolerates a partial/interrupted write (any
invalid sub-combination restores to "notStarted"/"no recommendation" rather
than a half-formed state). Two new keys
(`recommendationAttemptResponseKey`/`…UsefulnessResponseKey`) join that
same group, cleared alongside the rest on a fresh day.

The genuinely new state this batch introduces — the Circle journal (§5) —
**is** given one coherent, single-key, versioned JSON persistence boundary
(`circle_journal.dart`'s `circleJournalKey`) rather than one preference key
per field, specifically because it is designed to survive across many days
and needs atomic-enough replace semantics the existing per-day keys don't
need (they are overwritten wholesale every day anyway). This is the
"technical reason to alter the storage representation" the frozen batch
requirements anticipated — applied only where it was actually needed, not
across the whole file.

`Recommendation` gained three additive fields — `intention`, `circleId`,
`catalogVersion` — so both the journal and the diversity guard can use the
stable raw identity instead of re-deriving it from display copy.
`RecommendationState` gained `attemptResponse`/`usefulnessResponse` (§4).
Neither change altered `CircleHero`'s (in-progress visual work, §10) own
consumption of `Recommendation.intent`/`.activity`/`.why`/`.category` or
`RecommendationState.status` — both remain untouched by this batch.

### 4. Optional action-report foundation

Once today's Circle is closed, `ActionReportPrompt`
(`presentation/widgets/action_report_prompt.dart`) — a widget independent
of `circle_hero.dart` (§10) — offers: *"Did you try this activity?"* (Yes /
A little / Not today), then, only after an affirmative answer, an optional
*"Was it useful?"* (Very useful / Somewhat useful / Not useful).

- `RecommendationNotifier.reportAttempt`/`reportUsefulness` are no-ops
  outside `RecommendationStatus.closed` (and `reportUsefulness` is
  additionally a no-op without an affirmative attempt already recorded) —
  never required to Close, never required to receive tomorrow's Circle.
- `null` always means **no answer / UNKNOWN**, never a negative or a
  failure. `CircleAttemptResponse.notToday` is an explicit, reported
  non-action — distinct from `null`.
- Answering is idempotent and revisable — calling `reportAttempt` again
  overwrites the earlier answer; changing to a non-affirmative answer
  clears any previously recorded usefulness response, since usefulness may
  only ever follow an affirmative attempt.
- Neither response causes any automatic repeat, personalization, or
  progression — `chooseIntention`'s ordinary no-op guard is unaffected by
  either response.
- Two new analytics events, `circleAttemptReported`/
  `circleUsefulnessReported` (wire names `circle_attempt_reported`/
  `circle_usefulness_reported`), fire only on a genuine recorded response,
  carrying only the response enum name as metadata — no free text, no
  health claim, no verified-completion claim. The paired migration
  (`supabase/migrations/20260906010000_add_action_report_events.sql`) only
  widens the existing `analytics_events.event_type` CHECK constraint.

None of this changes ADR-010's standing rule: Close is a factual app
interaction only. The action report is the *only* place a user's own
account of what happened is recorded, and even that is exclusively
self-reported, never verified.

### 5. Prospective local Circle journal

`circle_journal.dart` introduces `CircleJournalRepository` — a bounded,
versioned, local-only record, kept under one `SharedPreferences` key as a
single JSON object: `{"schemaVersion": 1, "entries": [...]}`.

- **One entry per local date**, upserted as that date's Circle progresses:
  `recordShown`/`recordStarted`/`recordClosed`/`recordAttempt`/
  `recordUsefulness`. Each entry carries `schemaVersion`, `circleId`,
  `localDate`, `direction`, `activityId`, `catalogVersion`, `shownAt`, and
  optional `startedAt`/`closedAt`/`attemptResponse`/`usefulnessResponse`.
- `circleId` and `localDate` are currently always equal — Free is bounded
  to one Circle per local day, so the date already is a stable identity —
  kept as two separate fields so a future change to what makes a Circle's
  identity stable would only need a change to how `circleId` is computed,
  not a schema change.
- **Self-healing upserts:** every `record*` method synthesizes a missing
  entry from whatever context it already has (direction/activityId, plus a
  fallback `shownAt`) rather than silently no-op'ing — this is what makes
  "process interruption during writes" safe: a fire-and-forget write from
  an earlier step that never lands (app killed, or simply hasn't resolved
  yet) does not silently lose that day's later events.
- **Retention cap:** at most `circleJournalMaxRecords` (366) entries are
  kept, oldest local date dropped first — the frozen recurring Premium
  architecture's own two figures
  (`RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md` §9): a
  **365-day rolling retention window**, and a separately stated **hard cap
  of 366 Circle records**. Both are taken literally, not reconciled into a
  single number — the retention window is still 365 days; 366 is the
  enforced entry-count bound. (An earlier version of this ADR and the
  shipped Batch 1 code used 365 for both, before that document was
  incorporated — see "Contract reconciliation" below.)
- **Fail-safe reads:** a missing value, non-JSON string, unrecognized or
  future `schemaVersion`, or malformed `entries` list all read back as an
  empty journal rather than throwing. A single corrupt entry inside an
  otherwise valid wrapper is dropped individually. An entry whose
  `activityId` no longer belongs to its recorded `direction`'s pool is also
  dropped — the same compatibility rule §2 applies to live state applies to
  historical records too.
- **Never fabricated:** the journal is populated only from this point
  forward, by the notifier's own real transitions — never backfilled from
  Batch 2's anti-repetition history or from Supabase analytics events.

The schema is additive-friendly by construction (a plain JSON object per
entry) so a future Plan/stage/cycle/pacing/revisit field can be added
without a breaking migration — no such field is added now.

### 6. User data access / controls

`CircleHistoryPage` (`presentation/circle_history_page.dart`), reachable
from `HomePage`'s AppBar in every state, is a plain, read-only list of
journal entries. Each entry explicitly separates **shown / started /
closed / reported attempt / reported usefulness** — including a standing
reminder that Close is a factual interaction only. Two controls are
offered:

- **Delete all** — `CircleJournalRepository.clearAll()`, behind an explicit
  confirmation dialog (irreversible, nothing to restore it from).
- **Copy as text** — `CircleJournalRepository.exportAsJson()` copied to the
  system clipboard via `package:flutter/services.dart`'s `Clipboard`, not a
  file-sharing package. This is a deliberate scope decision: AGENTS.md §5
  freezes the dependency set at what's already in `pubspec.yaml`, and a
  clipboard copy delivers a genuine, functioning local export with zero new
  dependencies. A share-sheet or file-based export remains a reasonable
  future enhancement if that dependency freeze is later lifted — it is not
  something this batch was blocked on.

No activity replay, browsing, rankings, streaks, progress scores,
Insights, charts/dashboard, or search — all explicitly out of scope, and
all would risk pre-empting Premium Insights' own future design.

### 7. Local-only data boundary (Android backup)

`android:allowBackup` was previously unset, which defaults to `true` —
Android's Auto Backup could have silently included the app's
`SharedPreferences` (recommendation state, and now the Circle journal) in
a user's Google account cloud backup, and Android 12's separate
device-to-device transfer flow would also have carried it — a de facto
cloud restore mechanism, contradicting "device-local only" and "no
account/cloud-sync system is authorized." `android/app/src/main/
AndroidManifest.xml` now sets `android:allowBackup="false"`, which disables
both mechanisms outright; no XML backup-rules/data-extraction-rules file is
needed since there is nothing selective to allow through. This is
unrelated to, and does not affect, a future in-app-purchase *entitlement*
restore (a Play Store concept, never a personal-history restore) — no such
system exists yet regardless.

### 8. Analytics — startup independence

`main.dart`'s `Supabase.initialize` call is now wrapped in a `try`/`catch`.
Previously, a reachability failure at cold start (no network, a
misbehaving endpoint) would throw before `runApp` ever ran, meaning
optional instrumentation could prevent the entire local, offline-first
product from opening at all. `SupabaseAnalyticsService._send`
(`analytics_service.dart`) already tolerated `Supabase.instance` never
having initialized successfully — this closes the one path that could
still turn an analytics outage into a startup outage.
`SupabaseConfig.assertValid()`'s existing fail-fast behavior for a missing
URL/key (a developer misconfiguration, not a runtime availability issue)
is unchanged.

### 9. Accessibility — direction card activation

`daily_intention_prompt.dart`'s `_IntentionOption` previously wrapped
`ThirtyCard` in `ExcludeSemantics` beneath an outer `Semantics(button:
true, label: ...)` node **with no `onTap`** — a real, if narrow, source-
supported defect: an assistive technology could read the label and the
button role, but activating it (a double-tap in TalkBack, or the
equivalent `SemanticsAction.tap`) invoked nothing, since the wrapped
gesture handling was entirely excluded from the semantics tree. `onTap` is
now set directly on that outer `Semantics` node, verified by a test that
performs the actual `SemanticsAction.tap` (not merely asserting the
`button`/`label` properties, which the pre-existing test already did and
which alone did not catch this).

## Consequences

- Free's core mechanic (one `Intention` → one deterministic `ActivityId`)
  is unchanged; no reroll, no browser, no personalization engine.
- The Circle journal is genuinely new local state, but it changes no
  existing behavior — it is written alongside the existing per-day
  lifecycle, never instead of it, and nothing reads it back into product
  logic yet (only `CircleHistoryPage` reads it, for display).
- `docs/product/recommendation-mvp-v0.md` is updated narrowly (catalogue
  size, the cross-direction family rule, the new local-storage section) —
  its other sections are unaffected.
- `Recommendation`/`RecommendationState`'s additive fields, and the two new
  analytics events, are exactly the surface future Premium work (Plans,
  Coach, Insights) will build on — none of that behavior exists yet.
- Circle/geometry visual work in progress (`thirty_progress_circle.dart`,
  `circle_hero.dart`, `crafted_circle_geometry.dart` and their tests) was
  deliberately left untouched by this batch; only `home_page.dart` (a
  clean, non-WIP file) was extended to host `ActionReportPrompt` and the
  history entry point, so this batch's functional surface stays fully
  separable from that unrelated, ongoing visual pass.

## Contract reconciliation (post-Batch-1)

`RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md` — the
controlling frozen Premium document — became available to this repository
after Batch 1 shipped and this ADR was first written. It confirms Batch 1's
scope directly (§37: "execute the existing Batch 1 — Free Circle: useful
action and reliable daily state — with the narrow prospective-journal
prerequisite... Preserve the current Circle WIP") and identifies one
numeric discrepancy: its §9 "Local history contract" states the journal's
hard cap as **366** Circle records, not the 365 Batch 1 shipped
(`circleJournalRetentionDays`, since renamed `circleJournalMaxRecords`).
The retention *window* remains 365 days in both — only the enforced
record-count cap changed, corrected in a narrow follow-up commit. No other
discrepancy between this document and the shipped Batch 1 implementation
was found.

## Related documents

- [RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md](../RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md) — the controlling frozen Premium document; authoritative above this ADR for Premium product scope
- [PREMIUM_STRATEGY.md](../PREMIUM_STRATEGY.md)
- [ADR-007 — Premium Never Blocks the Core Loop](ADR-007-premium-never-blocks-the-core-loop.md)
- [ADR-010 — Circle Closed Is Not Verified Activity Completion](ADR-010-circle-closed-not-completion.md)
- [ADR-011 — Batch 1 / Post-Fix Retention Cohort](ADR-011-batch-1-post-fix-retention-cohort.md)
- [ADR-012 — Batch 2 / Recommendation Diversity](ADR-012-batch-2-recommendation-diversity.md)
- [`recommendation-mvp-v0.md`](../recommendation-mvp-v0.md)
- [`supabase/README.md`](../../../supabase/README.md)
