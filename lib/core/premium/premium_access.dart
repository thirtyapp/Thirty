import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Premium entitlement access seam — Batch 2A
/// (`docs/product/adr/ADR-014-v1-batch-2a-circle-plans.md` §16).
///
/// Batch 2A does not implement RevenueCat or any real subscription
/// entitlement (`RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md`
/// §16). This is the smallest explicit seam a future billing integration
/// needs: one boolean read, resolved through dependency injection rather
/// than a persisted or manually editable "isPremium" field, an analytics
/// flag, or a fake local purchase record.
///
/// **Production default is unentitled.** No code path in this app ever
/// overrides this provider with `true` — a real build never falsely
/// presents a paid entitlement as granted. Circle Plans
/// (`../../features/plans/`) check this provider both to gate their entry
/// point (`../../features/home/presentation/home_page.dart`'s AppBar) and,
/// independently, inside the actual daily resolution
/// (`../../features/plans/application/plan_provider.dart`'s
/// `resolveSessionFor`) — so even a forced direct navigation to `/plans`
/// can never produce a Plan-resolved Circle without entitlement.
///
/// Tests and any future manual/dev verification override this exactly the
/// way `sharedPreferencesProvider` is already overridden in tests:
/// `ProviderScope(overrides: [premiumEntitlementProvider.overrideWithValue(true)])`.
/// When real billing (RevenueCat) is integrated, this provider's
/// implementation is replaced with one that reads verified subscription
/// state — nothing that reads [premiumEntitlementProvider] needs to change.
final premiumEntitlementProvider = Provider<bool>((ref) => false);
