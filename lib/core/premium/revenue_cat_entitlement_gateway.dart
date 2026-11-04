import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
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

  // Lookups overlap — a foreground-resume refresh can still be in flight
  // when a purchase or restore confirms, and answer last with the older
  // state. Each answer is ordered by when it was asked for (a pushed update
  // or a purchase/restore result by when it arrived), and only the newest
  // is published, so an older answer never overwrites a newer one.
  int _lastTicket = 0;
  int _publishedTicket = 0;
  EntitlementStatus _published = EntitlementStatus.unavailable;

  EntitlementStatus _publish(int ticket, EntitlementStatus status) {
    if (ticket < _publishedTicket) return _published;
    _publishedTicket = ticket;
    _published = status;
    _statusController.add(status);
    return status;
  }

  @override
  Stream<EntitlementStatus> get statusUpdates => _statusController.stream;

  @override
  Future<EntitlementStatus> initialize() async {
    final ticket = ++_lastTicket;
    try {
      if (!_configured) {
        await Purchases.configure(
          PurchasesConfiguration(_config.androidApiKey),
        );
        Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdate);
        _configured = true;
      }
      // `getCustomerInfo()` returns the RevenueCat SDK's own
      // previously-verified cached result when the network is unreachable
      // (frozen architecture §7) — this app never builds a parallel cache.
      final customerInfo = await Purchases.getCustomerInfo();
      return _publish(ticket, _statusFor(customerInfo));
    } catch (_) {
      // Configuration failure, no connectivity with no prior cache, or
      // any other SDK error — never a crash, never a false Premium grant.
      return _publish(ticket, EntitlementStatus.unavailable);
    }
  }

  void _onCustomerInfoUpdate(CustomerInfo customerInfo) {
    _publish(++_lastTicket, _statusFor(customerInfo));
  }

  /// Maps RevenueCat's verified [CustomerInfo] to THIRTY's four-value
  /// model — see `entitlement_status.dart`'s [EntitlementStatus] doc
  /// comment for exactly which provider states collapse into which value.
  /// The configured id absent from a successful response is the ordinary
  /// never-purchased customer, not a failure: RevenueCat only lists an
  /// entitlement once this customer has owned it, so it maps to
  /// [EntitlementStatus.inactive] and the offer stays purchasable. Only
  /// [EntitlementInfo.isActive] ever grants Premium — never an offering, a
  /// product or another entitlement being present.
  EntitlementStatus _statusFor(CustomerInfo customerInfo) {
    final entitlement = customerInfo.entitlements.all[_config.entitlementId];
    return entitlement != null && entitlement.isActive
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
      final status = _statusFor(result.customerInfo);
      _publish(++_lastTicket, status);
      return outcomeForPurchasedStatus(status);
    } on PlatformException catch (e) {
      return outcomeForPurchaseError(PurchasesErrorHelper.getErrorCode(e));
    } catch (_) {
      return PurchaseOutcome.error;
    }
  }

  /// A completed store purchase only counts as [PurchaseOutcome.purchased]
  /// once the entitlement it returned is active; otherwise it is still
  /// [PurchaseOutcome.confirming].
  @visibleForTesting
  static PurchaseOutcome outcomeForPurchasedStatus(EntitlementStatus status) =>
      status == EntitlementStatus.active
      ? PurchaseOutcome.purchased
      : PurchaseOutcome.confirming;

  /// Maps a RevenueCat purchase error: a closed sheet is an ordinary
  /// cancellation, a pending Google Play payment is [PurchaseOutcome.pending]
  /// (never an error), anything else is [PurchaseOutcome.error].
  @visibleForTesting
  static PurchaseOutcome outcomeForPurchaseError(PurchasesErrorCode code) =>
      switch (code) {
        PurchasesErrorCode.purchaseCancelledError =>
          PurchaseOutcome.userCancelled,
        PurchasesErrorCode.paymentPendingError => PurchaseOutcome.pending,
        _ => PurchaseOutcome.error,
      };

  @override
  Future<RestoreOutcome> restore() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      final status = _statusFor(customerInfo);
      _publish(++_lastTicket, status);
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
