/// THIRTY's Premium entitlement state — Step 5 billing integration
/// (`docs/product/adr/ADR-017-v1-step5-revenuecat-billing.md`).
///
/// This is the smallest state model that can truthfully distinguish the
/// cases frozen architecture §6 requires an app to tell apart. It
/// deliberately does *not* mirror every Google Play/RevenueCat lifecycle
/// name (grace period, account hold, cancelled-with-time-remaining, …) —
/// those are provider truth that collapses correctly into just two of the
/// four values here:
///
/// - a verified subscription in its **active paid period** — including a
///   cancelled-but-not-yet-expired subscription and a grace period, both
///   of which RevenueCat's own `EntitlementInfo.isActive` already reports
///   as active (frozen architecture §6: "cancellation is not automatically
///   immediate entitlement loss") — is [active];
/// - a verified subscription **outside its paid period** — account hold,
///   expiry, revocation, refund — is [inactive].
///
/// The app must never re-derive these from anything except
/// [EntitlementInfo.isActive] itself (`entitlement_gateway.dart`'s
/// `RevenueCatEntitlementGateway`) — never from network reachability, a
/// button-tap callback, or app activity (frozen architecture §6/§24).
enum EntitlementStatus {
  /// No verified state has been resolved yet — the app has not finished
  /// its first billing check this session (or, with no billing
  /// configuration at all, never will). Distinct from [inactive]: this is
  /// "don't know yet", not "confirmed not entitled". Free is fully usable
  /// in this state; only new Premium operation waits.
  initializing,

  /// A verified RevenueCat entitlement is active — covers a normal paid
  /// period, a grace period, and a cancelled-but-not-yet-expired period
  /// alike. Plans/Coach/Insights may operate.
  active,

  /// A verified RevenueCat entitlement exists but is not active — covers
  /// account hold, expiry, revocation and refund alike. Free remains
  /// available; new Premium operation is paused, never erased.
  inactive,

  /// No trustworthy verified state is available — missing/invalid billing
  /// configuration, the SDK failing to initialize, or a lookup that found
  /// no matching entitlement identifier in the provider's response at all
  /// (a configuration mismatch, not a real subscription state). Treated
  /// exactly like [inactive] for gating purposes (fail closed for
  /// Premium), but reported separately so Settings/paywall can show a
  /// truthful "temporarily unavailable" state instead of falsely implying
  /// the user was never subscribed.
  unavailable,
}

/// The result of one purchase attempt — `entitlement_gateway.dart`'s
/// `EntitlementGateway.purchaseMonthly()`.
enum PurchaseOutcome {
  /// The store confirmed the purchase and RevenueCat returned an updated,
  /// authoritative [EntitlementStatus] — never inferred from the button
  /// call succeeding alone (frozen architecture §11).
  purchased,

  /// The user closed/cancelled the platform purchase sheet — an ordinary,
  /// non-error outcome (frozen architecture §11).
  userCancelled,

  /// No monthly package is currently available to purchase (missing
  /// configuration, no configured offering, or the store returned no
  /// product) — never presented as a silent failure; the paywall must
  /// show a quiet unavailable state instead of a broken buy button.
  unavailable,

  /// The store/provider reported an error other than user cancellation.
  error,
}

/// The result of one restore attempt —
/// `entitlement_gateway.dart`'s `EntitlementGateway.restore()`.
enum RestoreOutcome {
  /// Restore completed and found an active entitlement.
  restored,

  /// Restore completed successfully but found no active entitlement for
  /// this store account — an ordinary, non-error outcome.
  notFound,

  /// No trustworthy provider response was available (missing
  /// configuration, SDK/network failure).
  unavailable,

  /// The provider reported an error.
  error,
}

/// The monthly offer's actual store-returned price and period —
/// `entitlement_gateway.dart`'s `EntitlementGateway.monthlyOffer()`.
///
/// [localizedPrice] is exactly what the store returns for the configured
/// monthly package (e.g. `StoreProduct.priceString`) — never a hardcoded
/// literal. The €3.99/month figure named in the frozen architecture is a
/// working hypothesis to verify the configured product against, not a
/// value this app is ever allowed to display in place of the real one.
class MonthlyOffer {
  const MonthlyOffer({required this.localizedPrice});

  final String localizedPrice;
}
