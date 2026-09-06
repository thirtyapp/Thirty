# ADR-017 — V1 Step 5 / RevenueCat Billing Integration

**Status:** Accepted (code) / **BLOCKED** (live billing proof — see
Consequences)

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
   the second closed Circle on distinct dates" — so it was implemented,
   unlike onboarding/reminders (see below). A plain inline `ThirtyCard` on
   the home screen, never a dialog; marks itself shown exactly once
   (persisted, independent of entitlement state, so losing/regaining
   Premium never re-triggers it) the first time it actually renders.

10. **Onboarding and reminders: explicitly out of scope, by design, not
    oversight.** Neither exists in code, and no detailed policy for
    either exists in any authority document beyond high-level bullets
    ("one optional local reminder" with no permission flow, cadence or
    copy specified). Building either now would mean this ADR inventing
    product policy it has no authority to invent. **Gate status: BLOCKED
    BY MISSING IMPLEMENTATION AUTHORITY** for both — not attempted.

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
- **Onboarding and reminders remain unbuilt.** Their absence is a
  documented, deliberate scope boundary, not an oversight — resuming them
  requires a founder decision on notification cadence/copy and Settings
  information architecture, which is out of this ADR's authority.
- **Production safety:** no code path outside test overrides can ever set
  `premiumEntitlementProvider`/`entitlementStatusProvider` to
  active/`true` without a verified RevenueCat entitlement. Malformed or
  missing billing configuration fails closed for Premium and never
  affects Free — verified by `revenue_cat_config_test.dart` and
  `entitlement_gateway_test.dart`.
- **Test suite:** 516/516 passing (460 baseline + 56 new), `flutter
  analyze` clean. Regression coverage for Batches 1/2A/2B/2C is
  unaffected — `premiumEntitlementProvider` kept its exact overridable
  shape, so no existing test needed to change.
- **Privacy/data boundary:** no purchase token, receipt, or RevenueCat
  identifier is sent to Supabase/general analytics; none of this batch's
  new code touches the analytics service at all (frozen architecture
  §23 — funnel events deferred to the measurement batch, not required
  for Step 5 acceptance).

## Related documents

- [RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md](../RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md) §5–§9, §14, §22, §26, §36 step 5 — the controlling contract this ADR implements.
- [ADR-014](ADR-014-v1-batch-2a-circle-plans.md) §16 — the original `premiumEntitlementProvider` seam this ADR replaces the implementation of, without changing its shape.
- [ADR-015](ADR-015-v1-batch-2b-circle-coach.md), [ADR-016](ADR-016-v1-batch-2c-circle-insights.md) — the Coach/Insights surfaces gated by the same single entitlement.
