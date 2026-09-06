# ADR-017 — V1 Step 5 / RevenueCat Billing Integration

**Status:** Accepted (billing code, onboarding, Settings, analytics
consent, local reminder with correct device-local-timezone scheduling) /
**BLOCKED** (live billing proof; live reminder delivery proof — both
require a real device this session does not have; see Consequences) /
**REQUIRED BEFORE FEATURE-COMPLETE** (privacy policy and support contact
content — not yet supplied by the founder/operator)

## Context

Batches 2A–2C (ADR-014/015/016) built the working Plans → Coach → Insights
service behind `premiumEntitlementProvider`, a pre-billing seam that
always resolved to `false` in production
(`lib/core/premium/premium_access.dart`). The controlling frozen document
[`RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md`](../RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md)
§36 step 5 ("Existing supporting UI/billing integration") requires
connecting that service to one real monthly RevenueCat subscription, with
Settings/restore/management, while preserving the frozen contract's
same-day identity and entitlement-loss data guarantees exactly.

Two things were confirmed by direct repository inspection before writing
any code, not assumed:

- **No RevenueCat/Google Play external configuration is visible from this
  repository** — no API keys, no entitlement/offering identifiers, no
  signing config beyond `applicationId: com.thirty.app.thirty`. This is
  not proof that no such configuration exists in the owner's actual
  RevenueCat/Play accounts — only that this repository cannot verify it,
  and this implementation must not invent it.
- **Onboarding, Settings and reminder/notification features do not exist
  in code at all** (`lib/features/` contained only `coach`, `home`,
  `insights`, `plans` before this batch), and no detailed reminder-policy
  or Settings-layout specification exists beyond one-line mentions in the
  frozen document. Building a general onboarding flow, notification
  cadence or Settings information architecture now would mean inventing
  product policy this ADR has no authority to invent.

## Decision

**Scope actually implemented — billing-minimum only, per explicit
founder direction during this batch:**

1. **RevenueCat as the single billing authority.** Added the official
   `purchases_flutter` SDK (v10.11.0, current at implementation time) —
   the one explicit dependency exception this batch is authorized for
   (`CLAUDE.md` §5 otherwise forbids new dependencies). `url_launcher` is
   declared directly in `pubspec.yaml` for `SettingsPage`'s management
   link, but adds no new package to the resolved dependency tree — it was
   already present transitively via `supabase_flutter`.

2. **Production configuration boundary — no identifiers invented or
   committed.** `lib/core/config/revenue_cat_config.dart` mirrors
   `supabase_config.dart`'s existing `String.fromEnvironment` pattern:
   `REVENUECAT_ANDROID_API_KEY` and `REVENUECAT_ENTITLEMENT_ID` are read
   from `--dart-define-from-file` only. `config/revenuecat.example.json`
   documents the expected shape (placeholder values, exactly like
   `config/supabase.example.json`'s own `"your-project-ref"`);
   `config/revenuecat.local.json` (real values) is gitignored and was
   never created by this batch. Unlike `SupabaseConfig.assertValid()`,
   missing RevenueCat configuration never throws — `isConfigured` is
   `false`, and the app fails closed for Premium while Free stays
   completely unaffected.

3. **Entitlement state model** (`entitlement_status.dart`): four values —
   `initializing`, `active`, `inactive`, `unavailable`. `active` covers a
   normal paid period, a grace period, and a cancelled-but-unexpired
   period alike, because RevenueCat's own `EntitlementInfo.isActive`
   already reports all three as active — this app never re-derives that
   distinction itself. `unavailable` is distinct from `inactive`: it means
   no trustworthy verified state exists (missing config, SDK failure, or
   a configured entitlement id absent from the provider's response),
   never "confirmed not subscribed".

4. **`EntitlementGateway`** (`entitlement_gateway.dart`): the one seam
   between app code and RevenueCat, deliberately not a generalized
   multi-provider abstraction. `entitlementGatewayProvider` resolves to
   `RevenueCatEntitlementGateway` only when `RevenueCatConfig.isConfigured`
   is `true`; otherwise to the inert `UnavailableEntitlementGateway`,
   which never touches a platform channel. Under `flutter test`, the
   dart-defines are always unset, so this is always the safe branch
   unless a test explicitly overrides the provider with a fake — exactly
   the existing `sharedPreferencesProvider`/`eventClockProvider`
   convention.

5. **`RevenueCatEntitlementGateway`** (`revenue_cat_entitlement_gateway.dart`):
   wraps `Purchases.configure`, `getCustomerInfo`, `getOfferings`,
   `purchase`, `restorePurchases`. Maps `CustomerInfo` to
   `EntitlementStatus` by looking up the *configured* entitlement id in
   `entitlements.all` — a missing key maps to `unavailable` (a
   configuration mismatch), never to `inactive`. Every method catches its
   own failures and never throws. `getCustomerInfo()` is RevenueCat's own
   verified-cache-aware call, so this app builds no parallel offline
   cache (frozen architecture §7).

6. **`premiumEntitlementProvider` kept its exact pre-billing shape** — a
   plain `Provider<bool>`, now `== EntitlementStatus.active` — so every
   existing call site (`plan_provider.dart`'s `resolveSessionFor`,
   `home_page.dart`'s AppBar visibility) and every existing test's
   `premiumEntitlementProvider.overrideWithValue(...)` needed zero
   changes. `EntitlementNotifier` (`premium_access.dart`) does the actual
   work: `build()` never touches the gateway (so a bare
   `ProviderContainer()` reads `initializing` synchronously, with no risk
   of an uncaught platform-channel error under `flutter test`);
   `initialize()` is called explicitly from `main.dart` (fire-and-forget,
   non-blocking — Free never waits on billing) and again on every
   foreground resume from `thirty_app.dart`'s existing
   `didChangeAppLifecycleState` observer (frozen architecture §17: "app
   restart, lifecycle refresh"). `purchaseMonthly()`/`restore()`
   explicitly re-resolve state with their own `gateway.initialize()` call
   once the store confirms an outcome, rather than relying on
   `statusUpdates` stream timing — frozen architecture §11: "purchase
   success means authoritative entitlement confirmation, not merely that
   a button call returned."

7. **Purchase flow** (`premium_offer_page.dart`, route `/premium`):
   states Plans + Coach + Insights, the real `Offering.current.monthly`
   package's `storeProduct.priceString` (never a hardcoded €3.99),
   automatic monthly renewal, that Free remains available, restore, and
   that Circle history is device-local. No offering available →
   `PurchaseOutcome.unavailable` and no purchase button rendered — never
   a broken "Subscribe" the user can tap into an error.

8. **Restore + management** (`settings_page.dart`, route `/settings`):
   Premium status row (one of the four `EntitlementStatus` values, each
   with a truthful description); "Upgrade to Premium" when not active;
   "Manage subscription" using RevenueCat's own `CustomerInfo.managementURL`
   when active and present, falling back to plain "manage this
   subscription from the Google Play Store app" guidance when RevenueCat
   returns none — never a hardcoded Play Store URL. Restore is available
   from both Settings and the offer page, idempotent by construction
   (`RestoreOutcome.notFound` is an ordinary, non-error outcome). Settings
   also links to the pre-existing `CircleHistoryPage` for
   export/delete — reused, not duplicated.

9. **Quiet offer placement** (`premium_offer_provider.dart`,
   `premium_offer_invitation_card.dart`): the frozen document's §26 is
   concrete, unambiguous authority — "a single nonmodal invitation after
   the second closed Circle on distinct dates" — so it was implemented.
   A plain inline `ThirtyCard` on the home screen, never a dialog; marks
   itself shown exactly once (persisted, independent of entitlement
   state, so losing/regaining Premium never re-triggers it) the first
   time it actually renders. **Corrected in the Reconciliation below:**
   it must also never render while a reflection question is pending.

10. **Onboarding, Settings and reminders — see Reconciliation below.**
    The original version of this ADR marked all three
    `BLOCKED BY MISSING IMPLEMENTATION AUTHORITY`, reasoning that neither
    existed in code nor in any authority document. That premise was
    corrected: the parent `THIRTY V1 PRODUCTIZATION + COMMERCIAL
    REVIEW.md` (§9, §27, §28, §32) — explicitly preserved, unaffected
    parent-document sections per the frozen correction's own §35 —
    already specifies both in concrete, implementable detail. This ADR
    is not silently rewritten; the correction is recorded below with
    what changed and why.

### Purchase lifecycle verification matrix

| State | Provider truth | App entitlement | Free | Premium | Current Circle | User data | Verification |
|---|---|---|---|---|---|---|---|
| Initial purchase | `purchase()` returns confirmed `CustomerInfo` | `active` (re-resolved via explicit `gateway.initialize()`, not the call returning) | unaffected | starts operating | unaffected — never rerolled | unaffected | DETERMINISTIC ADAPTER TEST (`premium_offer_page_test.dart`) |
| Renewal | `isActive` stays `true`, `latestPurchaseDate` advances | stays `active` | unaffected | continues | unaffected | unaffected | DOCUMENTATION-CONTRACT VERIFIED (RevenueCat/Play docs) |
| Cancel, paid time remaining | `isActive=true`, `unsubscribeDetectedAt` set, `willRenew=false` | stays `active` | unaffected | continues until expiry | unaffected | unaffected | DETERMINISTIC ADAPTER TEST |
| Grace period | `isActive=true`, `billingIssueDetectedAt` set | stays `active` | unaffected | continues | unaffected | unaffected | DETERMINISTIC ADAPTER TEST + DOCUMENTATION-CONTRACT VERIFIED |
| Account hold | `isActive=false` | `inactive` | unaffected | new operation pauses | unaffected — preserved, not erased | preserved | DETERMINISTIC ADAPTER TEST |
| Expiry | `isActive=false` | `inactive` | unaffected | new operation pauses | unaffected | preserved | DETERMINISTIC ADAPTER TEST |
| Recovery | `isActive` returns to `true` | returns to `active` | unaffected | resumes | unaffected | preserved, untouched during interruption | DETERMINISTIC ADAPTER TEST |
| Refund / revocation | `isActive=false` | `inactive` | unaffected | new operation pauses | unaffected | preserved | DETERMINISTIC ADAPTER TEST |
| Restore, found | `restorePurchases()` returns active `CustomerInfo` | `active` | unaffected | resumes | unaffected | never reconstructs journal/Plan history | DETERMINISTIC ADAPTER TEST (`premium_access_test.dart`) |
| Restore, not found | `restorePurchases()` returns inactive `CustomerInfo` | unchanged | unaffected | unaffected | unaffected | unaffected | DETERMINISTIC ADAPTER TEST |
| Duplicate restore | repeated call, same result | unchanged, no duplicate state | unaffected | unaffected | unaffected | unaffected | DETERMINISTIC ADAPTER TEST |
| Offline, cached active | SDK's own verified cache returns active | `active` | unaffected | continues | unaffected | unaffected | DOCUMENTATION-CONTRACT VERIFIED (RevenueCat cache semantics — this app builds no parallel cache) |
| Provider unavailable, no trusted state | SDK throws / no config | `unavailable` | fully usable | new operation paused, truthful "temporarily unavailable" shown | unaffected | preserved | DETERMINISTIC ADAPTER TEST |
| Reinstall (no cloud history) | fresh install, `restorePurchases()` may find entitlement | `active` if found | unaffected | resumes if restored | new Circle identity (no cross-device journal exists to reroll) | journal/Plan history NOT recovered — disclosed in copy | DOCUMENTATION-CONTRACT VERIFIED |
| Entitlement becomes active mid-day | purchase completes after today's Free Circle resolved | `active` | today's Circle stands | new Plan Sessions begin next eligible Circle | today's `ActivityId` never changes | unaffected | DETERMINISTIC ADAPTER TEST (existing `resolveSessionFor` "once per local day" guard, ADR-014) |
| Entitlement becomes inactive mid-day | expiry/refund after today's Premium Circle resolved | `inactive` | today's Circle stands | new operation pauses after | today's `ActivityId`/Plan identity never changes | Plan cursor, journal, snapshots preserved | DETERMINISTIC ADAPTER TEST |

No row above is LIVE TESTED or PROVIDER-SANDBOX TESTED — see Consequences.

## Consequences

- **LIVE BILLING PROOF: BLOCKED.** No RevenueCat project/Google Play
  subscription product could be verified to exist from this repository,
  and this session has no RevenueCat dashboard, Google Play Console, or
  physical/emulated Android device with a Play-authenticated test account
  to perform a real sandbox purchase. §20's real test transaction
  requirement is therefore not satisfiable in this session regardless of
  external account state. **Owner action required:** create (or confirm)
  a RevenueCat project with an Android app, one entitlement, one offering
  containing a `Monthly`-type package, and a matching Google Play
  Console monthly subscription/base plan at the €3.99 working hypothesis;
  supply `REVENUECAT_ANDROID_API_KEY`/`REVENUECAT_ENTITLEMENT_ID` via
  `config/revenuecat.local.json`; build and run on a licensed test-track
  device to perform the real purchase this ADR cannot.
- **LIVE REMINDER DELIVERY PROOF: BLOCKED**, same root cause as billing —
  this session has no physical/emulated Android device. What IS verified
  deterministically, without a device: the `timezone` package's own DST
  correctness for the component `TZDateTime` constructor (real IANA
  tzdata, real spring-forward/fall-back transitions), and
  `LocalNotificationsReminderGateway`'s timezone-resolution branching
  (mocking the `flutter_timezone`/`flutter_local_notifications` platform
  channels directly — a supported `flutter_test` technique, not a
  device). REAL DEVICE TEST REQUIRED for: actual OS notification
  delivery and its exact rendered content, the Android 13+ permission
  dialog's real behavior, boot-receiver survival across an actual reboot,
  and a real timezone/DST transition experienced on a physical device
  clock (the deterministic tests prove the mechanism is correct; they
  cannot prove Android's alarm subsystem honors it identically on every
  OEM skin).
- **Production safety:** no code path outside test overrides can ever set
  `premiumEntitlementProvider`/`entitlementStatusProvider` to
  active/`true` without a verified RevenueCat entitlement. Malformed or
  missing billing configuration fails closed for Premium and never
  affects Free — verified by `revenue_cat_config_test.dart` and
  `entitlement_gateway_test.dart`. Analytics consent defaults `false` and
  gates every transmission centrally — verified by
  `analytics_consent_test.dart`. A timezone resolution failure fails
  closed for the reminder only (never schedules against a wrong zone)
  and never affects Free — verified by
  `local_notifications_reminder_gateway_test.dart`.
- **Test suite:** 569/569 passing (460 batch-2C baseline + 56 Step 5 + 12
  first reconciliation + 32 local closure + 8 final local timezone
  reconciliation), `flutter analyze` clean. Regression coverage for
  Batches 1/2A/2B/2C is unaffected — `premiumEntitlementProvider` kept
  its exact overridable shape, so no existing test needed to change
  beyond the two `ListView` viewport-scroll fixes Settings' growth
  required.
- **Privacy/data boundary:** no purchase token, receipt, or RevenueCat
  identifier is sent to Supabase/general analytics; the reminder's
  enabled/hour/minute/permission state stays local-only (SharedPreferences),
  never transmitted anywhere. Consent-gated analytics still carries no new
  payload fields from this batch (frozen architecture §23 — funnel events
  deferred to the measurement batch, not required for Step 5 acceptance).

## Reconciliation (targeted authority correction, same batch)

This ADR originally classified onboarding, Settings-beyond-billing and
reminders as `BLOCKED BY MISSING IMPLEMENTATION AUTHORITY`, on the premise
that no authority existed for them beyond one-line mentions. That premise
was incorrect: `THIRTY V1 PRODUCTIZATION + COMMERCIAL REVIEW.md` §9, §27,
§28 and §32 are explicitly preserved, unaffected parent sections (frozen
correction §35) and specify all three concretely. Corrected disposition:

- **Onboarding — implemented.** `daily_intention_prompt.dart` now shows
  one first-use explanation ("Choose a direction. THIRTY gives you one
  activity to do offline, in about thirty minutes. Tomorrow brings a new
  Circle.") directly above the three always-reachable direction choices —
  integrated into the existing entry flow per §28, not a separate screen.
  Shown exactly once: persisted (`onboardingIntroShownKey`) the moment a
  direction is actually chosen, and never shown at all for an install
  that already has prior journal history (an upgraded pre-onboarding
  user is never told this is their first use).
- **Prompt-priority defect found and fixed.** Auditing 9cb3a6e against
  §28's prompt-priority rule found a real stacking violation:
  `PremiumOfferInvitationCard` could render simultaneously with
  `ActionReportPrompt`'s reflection question, since both were independent
  conditions on the same screen. Fixed by extracting
  `reflectionPendingProvider` (`action_report_prompt.dart`) and gating
  `showPremiumOfferInvitationProvider` on it — the Premium invitation now
  never appears while a reflection question is pending, exactly matching
  "reflection comes first... Premium invitation waits until neither is
  being presented."
- **Settings — theme added; analytics consent added in the local-closure
  pass below; privacy/support are REQUIRED BEFORE FEATURE-COMPLETE, not
  optional.** Added a real System/Light/Dark theme control
  (`themeModeProvider` already drove `ThirtyApp`'s actual rendering; the
  only existing UI for it was the internal `/showcase` developer route,
  not a product surface — this batch is the first real product exposure
  of an already-working mechanism, not a fabricated feature).
  Privacy-policy/support-contact links remain explicitly **not** added —
  no such artifact (file, URL, or documented address) exists anywhere in
  this repository, and none is invented here. Corrected status (an
  earlier draft of this ADR understated this as merely "blocked on
  operational content," implying it was optional polish): §32's
  feature-complete definition explicitly requires "privacy/support" as an
  exit criterion — **PRIVACY POLICY: REQUIRED BEFORE FEATURE-COMPLETE —
  CONTENT/URL NOT YET SUPPLIED; SUPPORT CONTACT: REQUIRED BEFORE
  FEATURE-COMPLETE — CONTACT NOT YET SUPPLIED.** Only the
  founder/operator can supply the actual values; no Settings UI row was
  added for either, since a row pointing at nothing would itself be
  untruthful — one can be added the moment a real URL/contact exists.
- **Local reminder — implemented in the local-closure pass below**, once
  the founder explicitly approved the two-package dependency request
  originally recorded here.

## Local closure (analytics consent + local reminder, same batch)

Founder approval was subsequently granted for exactly two additional
dependencies (`flutter_local_notifications`, `timezone`) for the
already-frozen local reminder only, and a further contract correction was
made: analytics consent is **not** a mere content/operational gap — the
parent authority (§28) requires an explicit local opt-in gate, which is a
real code change, not a missing external value. Both are now implemented.

**Analytics consent** (`analytics_consent.dart`): `analyticsConsentProvider`
defaults to `false` and is the sole gate `analyticsServiceProvider`
(`analytics_service.dart`'s new `ConsentGatedAnalyticsService` wrapper)
checks before ever calling `SupabaseAnalyticsService.track` — every
existing and future call site goes through this one provider, so none
can accidentally bypass it. No queued/backfilled pre-consent events exist
to flush once enabled; disabling never touches journal/Plan/Coach/Insight
state. A Settings toggle ("Share anonymous usage data") exposes it,
independent of reminder permission and of Premium entitlement state — no
code path connects any of the three.

**Local reminder** (`lib/core/reminder/`, `lib/features/reminder/`):
`flutter_local_notifications` (22.3.0) + `timezone` (0.11.1) +
`flutter_timezone` (5.1.0) added — the
resolved dependency-request below, approved by the founder. `ReminderGateway`
mirrors `EntitlementGateway`'s exact seam pattern (one interface, a real
implementation, fakes in tests); `ReminderNotifier` persists
enabled/hour/minute via `SharedPreferences`, tracks live OS permission
state separately (`ReminderState.permissionGranted`), and reacts to
`recommendationProvider`'s status changes via `ref.listen` inside
`build()` to re-anchor the schedule whenever today's Circle actually
starts or closes (§27: "closing/starting today suppresses an unnecessary
later 'start' reminder"). A single canonical notification id is always
cancelled before rescheduling, so no duplicate can ever exist. The quiet
one-time invitation (`ReminderInvitationCard`) appears after the first
closed Circle, gated on `reflectionPendingProvider` per the prompt-priority
order below; `SettingsPage` exposes on/off, the chosen time, and a
truthful permission-state message with no repeated permission-request
loop.

**Superseded — the original UTC-anchored tradeoff did not satisfy the
frozen contract.** An earlier version of this batch scheduled against
`tz.UTC` rather than a named IANA zone, accepting up to a one-hour drift
around DST until the app was next opened. That was assessed as violating
the frozen requirement for a *correct* local wall-clock reminder time,
not merely an imperfect one — a self-correcting wrong answer is still a
wrong answer in the interim. **Corrected:** the founder approved exactly
one further dependency, `flutter_timezone` (5.1.0), whose sole job is
resolving the device's actual IANA identifier (its own README is what
first identified this as the missing piece — `timezone` cannot do this
itself). `LocalNotificationsReminderGateway.scheduleDaily` now resolves
`FlutterTimezone.getLocalTimezone()` fresh on every call, and schedules
using `tz.TZDateTime`'s **component constructor** — `TZDateTime(location,
year, month, day, hour, minute)`, not `.from(instant, location)` — which
treats the given fields as wall-clock time *in* that location and is
correctly DST-aware by construction (verified directly:
`local_notifications_reminder_gateway_test.dart` proves the same
`hour: 8` renders as physically different UTC offsets/instants either
side of a real spring-forward and fall-back transition in
`America/New_York`, and that the same wall-clock hour resolves to
different absolute instants across two named zones). Resolving fresh
(never caching a location) is also what makes a genuine device timezone
change self-correct on the very next reschedule, no different from any
other state change.

**If timezone resolution fails, nothing is silently scheduled wrong.**
`scheduleDaily` returns `ScheduleOutcome.timezoneUnavailable` and skips
straight past the notification-plugin call entirely — it never falls
back to `tz.UTC` or any assumed zone. `ReminderState.timezoneUnavailable`
carries this into `SettingsPage`, which shows a truthful "your reminder
time is saved, but we couldn't confirm your device's timezone" message
rather than either claiming success or alarming the user; Free and the
saved reminder preference are both completely unaffected.

**Prompt-priority order, completed:** `reflectionPendingProvider` →
`showReminderInvitationProvider` → `showPremiumOfferInvitationProvider`,
each gating the next, so at most one of reflection/reminder-invitation/
Premium-invitation ever renders at once — verified directly in
`premium_offer_provider_test.dart`.

**REMINDER DEPENDENCY REQUEST — approved, implemented as specified**

> **PACKAGE:** `flutter_local_notifications` (plus its `timezone`
> dependency, pulled in transitively for `zonedSchedule`).
>
> **WHY REQUIRED:** §27 requires real inexact local notification
> scheduling, Android 13+ runtime permission request, cancel/reschedule
> on toggle/time change, and reboot/timezone/DST-safe rescheduling. Flutter's
> SDK has no built-in notification API; achieving this without a plugin
> means writing and maintaining native Android code (a `BroadcastReceiver`
> for `AlarmManager`, a boot receiver, `NotificationManagerCompat` calls,
> and manual permission-request platform channels) — strictly more code,
> more platform-specific risk, and no test coverage this repository's
> existing Dart-only test suite could exercise.
>
> **WHY THIS IS THE SIMPLEST ROUTE:** it is the de facto standard, actively
> maintained Flutter package for exactly this need, already handles the
> Android 13+ permission flow, inexact/exact alarm selection, and
> boot-safe rescheduling internally, and needs no server component —
> consistent with "no general backend" (frozen architecture §22).
>
> **PLATFORM IMPACT:** Android manifest additions for a boot-completed
> receiver and the `POST_NOTIFICATIONS`/`SCHEDULE_EXACT_ALARM`-adjacent
> (inexact-only, so no exact-alarm special access) permissions; no iOS
> work needed (Android-only V1). No Gradle/minSdk changes expected beyond
> what Flutter's own default already satisfies.
>
> **ALTERNATIVES REJECTED:** hand-written native platform-channel code
> (larger, riskier, explicitly discouraged by this batch's own governing
> instructions as "an unnecessary custom framework"); `Timer`-only
> in-Dart scheduling (silently stops working once the app process is
> killed — cannot satisfy "local reminder" at all); a remote/push-based
> reminder (explicitly rejected by both frozen architecture and the
> parent document — "no remote push... in V1").

**Second dependency request — `flutter_timezone`, approved and
implemented:** package `flutter_timezone` (5.1.0); required because
`timezone`'s own README states it cannot resolve the device's local IANA
identifier itself; simplest route because it is the package
`flutter_local_notifications`' own documentation names for exactly this
gap, needs no server component, and required no Android manifest changes
beyond what was already in place; alternatives rejected for the same
reasons as before (hand-written platform-channel code is a larger,
riskier custom framework; a fixed-offset workaround would be a
known-wrong answer, not a documented tradeoff).

All three packages were explicitly approved by the founder for exactly
this purpose (not Firebase Messaging, remote push, backend scheduling, or
any unrelated dependency) and added — **LOCAL REMINDER V1: implemented**,
with
live delivery/permission-flow proof deferred to real-device testing (see
Consequences).

## Related documents

- [RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md](../RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md) §5–§9, §14, §22, §26, §36 step 5 — the controlling contract this ADR implements.
- `THIRTY V1 PRODUCTIZATION + COMMERCIAL REVIEW.md` §9, §17, §27, §28, §32 — the parent-document sections explicitly preserved unaffected by the frozen correction (§35), and the actual authority basis for onboarding/reminder/Settings in the Reconciliation above.
- [ADR-014](ADR-014-v1-batch-2a-circle-plans.md) §16 — the original `premiumEntitlementProvider` seam this ADR replaces the implementation of, without changing its shape.
- [ADR-015](ADR-015-v1-batch-2b-circle-coach.md), [ADR-016](ADR-016-v1-batch-2c-circle-insights.md) — the Coach/Insights surfaces gated by the same single entitlement.
