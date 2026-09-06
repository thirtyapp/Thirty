import 'dart:async';

import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/revenue_cat_config.dart';
import 'entitlement_gateway.dart';
import 'entitlement_status.dart';

/// The real managed-billing adapter — RevenueCat is the frozen
/// architecture's single named billing authority (§22). Constructed only
/// by `entitlementGatewayProvider` (`entitlement_gateway.dart`), and only
/// when [RevenueCatConfig.isConfigured] is `true`; never constructed
/// directly by app or test code.
///
/// Every public method swallows the platform-channel/SDK failure modes it
/// can encounter and reports them as the closest [EntitlementStatus] /
/// [PurchaseOutcome] / [RestoreOutcome] value instead of throwing —
/// frozen architecture §24: initialization failure, network outage, a
/// missing offering, a delayed response and a malformed configuration
/// must all fail closed for Premium without ever blocking Free or
/// crashing the app.
class RevenueCatEntitlementGateway implements EntitlementGateway {
  RevenueCatEntitlementGateway(this._config);

  final RevenueCatConfig _config;
  final _statusController = StreamController<EntitlementStatus>.broadcast();
  bool _configured = false;

  @override
  Stream<EntitlementStatus> get statusUpdates => _statusController.stream;

  @override
  Future<EntitlementStatus> initialize() async {
    try {
      if (!_configured) {
        await Purchases.configure(PurchasesConfiguration(_config.androidApiKey));
        Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdate);
        _configured = true;
      }
      // `getCustomerInfo()` returns the RevenueCat SDK's own
      // previously-verified cached result when the network is unreachable
      // (frozen architecture §7) — this app never builds a parallel cache.
      final customerInfo = await Purchases.getCustomerInfo();
      final status = _statusFor(customerInfo);
      _statusController.add(status);
      return status;
    } catch (_) {
      // Configuration failure, no connectivity with no prior cache, or
      // any other SDK error — never a crash, never a false Premium grant.
      const status = EntitlementStatus.unavailable;
      _statusController.add(status);
      return status;
    }
  }

  void _onCustomerInfoUpdate(CustomerInfo customerInfo) {
    _statusController.add(_statusFor(customerInfo));
  }

  /// Maps RevenueCat's verified [CustomerInfo] to THIRTY's four-value
  /// model — see `entitlement_status.dart`'s [EntitlementStatus] doc
  /// comment for exactly which provider states collapse into which value.
  /// A missing entitlement identifier (the configured id not present in
  /// the provider's response at all) is a configuration mismatch, not a
  /// real "never subscribed" state, so it maps to [EntitlementStatus.unavailable]
  /// rather than [EntitlementStatus.inactive].
  EntitlementStatus _statusFor(CustomerInfo customerInfo) {
    final entitlement = customerInfo.entitlements.all[_config.entitlementId];
    if (entitlement == null) return EntitlementStatus.unavailable;
    return entitlement.isActive
        ? EntitlementStatus.active
        : EntitlementStatus.inactive;
  }

  @override
  Future<MonthlyOffer?> monthlyOffer() async {
    try {
      final offerings = await Purchases.getOfferings();
      final monthly = offerings.current?.monthly;
      if (monthly == null) return null;
      return MonthlyOffer(localizedPrice: monthly.storeProduct.priceString);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PurchaseOutcome> purchaseMonthly() async {
    try {
      final offerings = await Purchases.getOfferings();
      final monthly = offerings.current?.monthly;
      if (monthly == null) return PurchaseOutcome.unavailable;

      final result = await Purchases.purchase(PurchaseParams.package(monthly));
      // Authoritative confirmation comes from the CustomerInfo RevenueCat
      // returns with the purchase result, not from the call merely
      // returning (frozen architecture §11).
      _statusController.add(_statusFor(result.customerInfo));
      return PurchaseOutcome.purchased;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      return code == PurchasesErrorCode.purchaseCancelledError
          ? PurchaseOutcome.userCancelled
          : PurchaseOutcome.error;
    } catch (_) {
      return PurchaseOutcome.error;
    }
  }

  @override
  Future<RestoreOutcome> restore() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      final status = _statusFor(customerInfo);
      _statusController.add(status);
      return status == EntitlementStatus.active
          ? RestoreOutcome.restored
          : RestoreOutcome.notFound;
    } on PlatformException catch (_) {
      return RestoreOutcome.error;
    } catch (_) {
      return RestoreOutcome.unavailable;
    }
  }

  @override
  Future<String?> managementUrl() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.managementURL;
    } catch (_) {
      return null;
    }
  }
}
