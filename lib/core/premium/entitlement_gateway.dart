import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/revenue_cat_config.dart';
import 'entitlement_status.dart';
import 'revenue_cat_entitlement_gateway.dart';

/// THIRTY's one seam onto managed billing — Step 5
/// (`docs/product/adr/ADR-017-v1-step5-revenuecat-billing.md`).
///
/// RevenueCat is the frozen architecture's single named billing authority
/// (§22); this is deliberately *not* a generalized multi-provider billing
/// framework — it exists only so `entitlementGatewayProvider` can be
/// overridden with a deterministic fake in tests, exactly the way
/// `sharedPreferencesProvider`/`eventClockProvider` already are in this
/// codebase. A second implementation is not expected.
abstract class EntitlementGateway {
  /// Fires whenever the provider's verified entitlement state changes —
  /// after a purchase, a renewal, a restore, or any background
  /// reconciliation the SDK performs while the app is open. The initial
  /// resolved state is also delivered here, in addition to being returned
  /// by [initialize].
  Stream<EntitlementStatus> get statusUpdates;

  /// Performs first-time setup and resolves the current verified
  /// entitlement state. Must never throw — any failure resolves to
  /// [EntitlementStatus.unavailable]. Safe to call more than once
  /// (idempotent) for an app-restart/lifecycle refresh.
  Future<EntitlementStatus> initialize();

  /// The current monthly offer's actual store-returned price, or `null`
  /// when no monthly package is available to purchase (frozen
  /// architecture §4: the app must show the real localized price, never a
  /// hardcoded one — a `null` result means the offer must not be shown as
  /// purchasable at all, not that a placeholder price should appear).
  Future<MonthlyOffer?> monthlyOffer();

  /// Purchases the current monthly package. Never infers success from the
  /// platform call returning alone — see [PurchaseOutcome.purchased]'s own
  /// doc comment.
  Future<PurchaseOutcome> purchaseMonthly();

  /// Restores previously purchased entitlements for the current store
  /// account. Idempotent — calling this repeatedly with no purchase to
  /// restore always yields [RestoreOutcome.notFound], never an error.
  Future<RestoreOutcome> restore();

  /// The provider's own subscription-management URL for an active
  /// entitlement (Google Play's subscription-center deep link once a
  /// purchase exists), or `null` when there is none to offer — never a
  /// hardcoded fallback URL (frozen architecture §14).
  Future<String?> managementUrl();
}

/// The safe default when [RevenueCatConfig.isConfigured] is `false` —
/// missing/placeholder billing configuration must fail closed for Premium
/// while leaving Free completely unaffected (frozen architecture §7/§24).
/// Never touches the RevenueCat SDK or any platform channel, so it is also
/// exactly what a bare `ProviderContainer()` in tests resolves to unless a
/// test explicitly overrides [entitlementGatewayProvider].
class UnavailableEntitlementGateway implements EntitlementGateway {
  const UnavailableEntitlementGateway();

  @override
  Stream<EntitlementStatus> get statusUpdates => const Stream.empty();

  @override
  Future<EntitlementStatus> initialize() async => EntitlementStatus.unavailable;

  @override
  Future<MonthlyOffer?> monthlyOffer() async => null;

  @override
  Future<PurchaseOutcome> purchaseMonthly() async =>
      PurchaseOutcome.unavailable;

  @override
  Future<RestoreOutcome> restore() async => RestoreOutcome.unavailable;

  @override
  Future<String?> managementUrl() async => null;
}

/// Production default: the real RevenueCat gateway when — and only when —
/// [RevenueCatConfig.isConfigured] is `true`, otherwise the inert
/// [UnavailableEntitlementGateway]. Tests never reach either branch
/// because `REVENUECAT_ANDROID_API_KEY`/`REVENUECAT_ENTITLEMENT_ID` are
/// never set under `flutter test`, so [RevenueCatConfig.isConfigured] is
/// always `false` there — override this provider directly with a fake
/// instead of relying on that, exactly as `premium_access_test.dart` and
/// this feature's own tests do.
final entitlementGatewayProvider = Provider<EntitlementGateway>((ref) {
  const config = RevenueCatConfig.fromEnvironment;
  if (!config.isConfigured) return const UnavailableEntitlementGateway();
  return RevenueCatEntitlementGateway(config);
});
