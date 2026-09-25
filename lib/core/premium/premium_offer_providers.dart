import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'entitlement_gateway.dart';
import 'entitlement_status.dart';

/// The current monthly offer, straight from the store via RevenueCat
/// ([EntitlementGateway.monthlyOffer]) — the single source for every
/// price THIRTY shows (You's Premium card and the Premium offer page).
/// `null` when no offer is available; the UI then shows no price at all,
/// never a hardcoded fallback.
///
/// Auto-disposed: fetched while a screen that shows a price is mounted,
/// and fetched afresh the next time one is, so a transient store failure
/// is not cached for the rest of the session.
final monthlyOfferProvider = FutureProvider.autoDispose<MonthlyOffer?>(
  (ref) => ref.watch(entitlementGatewayProvider).monthlyOffer(),
);

/// The store's subscription-management URL for an active subscriber, or
/// `null` when the store offers none. Fetched once per mount, not on every
/// rebuild.
final subscriptionManagementUrlProvider = FutureProvider.autoDispose<String?>(
  (ref) => ref.watch(entitlementGatewayProvider).managementUrl(),
);
