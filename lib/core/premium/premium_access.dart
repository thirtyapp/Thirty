import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'entitlement_gateway.dart';
import 'entitlement_status.dart';

/// The Premium entitlement access seam — originally Batch 2A
/// (`docs/product/adr/ADR-014-v1-batch-2a-circle-plans.md` §16), replaced
/// with a real billing-backed implementation in Step 5
/// (`docs/product/adr/ADR-017-v1-step5-revenuecat-billing.md`).
///
/// [premiumEntitlementProvider] keeps exactly the shape Batch 2A
/// documented it would: a plain `Provider<bool>`, resolved through
/// dependency injection, overridable in tests exactly like
/// `sharedPreferencesProvider`
/// (`ProviderScope(overrides: [premiumEntitlementProvider.overrideWithValue(true)])`
/// still works unchanged). Nothing that reads it needed to change — it is
/// now simply derived from [entitlementStatusProvider]'s verified
/// [EntitlementStatus.active] state instead of a hardcoded `false`.
///
/// **Production default is unentitled**, and now additionally fails
/// closed on any malformed/missing billing configuration or provider
/// failure (`entitlement_gateway.dart`'s `UnavailableEntitlementGateway`)
/// — no code path in this app ever derives Premium from analytics, a
/// locally editable preference, onboarding state, a purchase-button
/// callback alone, or a failed/successful HTTP request alone (frozen
/// architecture §5).
final premiumEntitlementProvider = Provider<bool>((ref) {
  return ref.watch(entitlementStatusProvider) == EntitlementStatus.active;
});

/// Manages THIRTY's one verified Premium entitlement for this session.
///
/// [build] never touches the billing provider itself — it only returns
/// [EntitlementStatus.initializing] and wires up a listener for
/// `EntitlementGateway.statusUpdates`. All actual RevenueCat/platform-
/// channel work happens inside [initialize], [purchaseMonthly] and
/// [restore], called explicitly from `main.dart` (app startup) or user
/// action — never as a `build()`-time side effect, so a bare
/// `ProviderContainer()` (as `premium_access_test.dart` uses) can read
/// this provider synchronously without ever reaching the SDK.
class EntitlementNotifier extends Notifier<EntitlementStatus> {
  StreamSubscription<EntitlementStatus>? _subscription;

  @override
  EntitlementStatus build() {
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
    });
    return EntitlementStatus.initializing;
  }

  /// Resolves the current verified entitlement state and starts listening
  /// for background changes (renewal, grace/hold transitions, a restore
  /// triggered elsewhere) for the rest of this session. Idempotent — safe
  /// to call again on app resume/lifecycle refresh (frozen architecture
  /// §17: "app restart, lifecycle refresh").
  Future<void> initialize() async {
    final gateway = ref.read(entitlementGatewayProvider);
    await _subscription?.cancel();
    _subscription = gateway.statusUpdates.listen((status) => state = status);
    state = await gateway.initialize();
  }

  /// Purchases the current monthly package. Deliberately re-resolves
  /// [state] with its own explicit `gateway.initialize()` call once the
  /// store confirms the purchase, rather than relying on
  /// [EntitlementGateway.statusUpdates] eventually delivering the same
  /// change — frozen architecture §11: "purchase success means
  /// authoritative entitlement confirmation, not merely that a button
  /// call returned." By the time this method returns, [state] already
  /// reflects that confirmation; a caller never needs to guess when a
  /// background stream event will land.
  Future<PurchaseOutcome> purchaseMonthly() async {
    final gateway = ref.read(entitlementGatewayProvider);
    final outcome = await gateway.purchaseMonthly();
    if (outcome == PurchaseOutcome.purchased) {
      state = await gateway.initialize();
    }
    return outcome;
  }

  /// Restores previously purchased entitlements. Idempotent — a repeated
  /// call with nothing to restore always yields [RestoreOutcome.notFound],
  /// never an error, and never reconstructs local journal/Plan history
  /// (frozen architecture §10 — restore recovers billing entitlement
  /// only). Re-resolves [state] explicitly on success, for the same
  /// reason [purchaseMonthly] does.
  Future<RestoreOutcome> restore() async {
    final gateway = ref.read(entitlementGatewayProvider);
    final outcome = await gateway.restore();
    if (outcome == RestoreOutcome.restored) {
      state = await gateway.initialize();
    }
    return outcome;
  }
}

final entitlementStatusProvider =
    NotifierProvider<EntitlementNotifier, EntitlementStatus>(
      EntitlementNotifier.new,
    );
