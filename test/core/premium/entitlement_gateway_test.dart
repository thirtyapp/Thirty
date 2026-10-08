import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart'
    show PurchasesErrorCode;

import 'package:thirty/core/premium/entitlement_gateway.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/revenue_cat_entitlement_gateway.dart';

void main() {
  group('UnavailableEntitlementGateway', () {
    const gateway = UnavailableEntitlementGateway();

    test('initialize() resolves to unavailable, never throws', () async {
      expect(await gateway.initialize(), EntitlementStatus.unavailable);
    });

    test('monthlyOffer() is null — never a placeholder price', () async {
      expect(await gateway.monthlyOffer(), isNull);
    });

    test(
      'purchaseMonthly() is unavailable, never fabricates a purchase',
      () async {
        expect(await gateway.purchaseMonthly(), PurchaseOutcome.unavailable);
      },
    );

    test(
      'restore() is unavailable, never fabricates recovered access',
      () async {
        expect(await gateway.restore(), RestoreOutcome.unavailable);
      },
    );

    test('managementUrl() is null — no hardcoded fallback URL', () async {
      expect(await gateway.managementUrl(), isNull);
    });

    test('statusUpdates never emits anything', () async {
      final events = <EntitlementStatus>[];
      final sub = gateway.statusUpdates.listen(events.add);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(events, isEmpty);
    });
  });

  group('RevenueCatEntitlementGateway purchase outcome mapping', () {
    test('a pending Google Play payment is pending, not an error', () {
      expect(
        RevenueCatEntitlementGateway.outcomeForPurchaseError(
          PurchasesErrorCode.paymentPendingError,
        ),
        PurchaseOutcome.pending,
      );
    });

    test('a closed purchase sheet stays an ordinary cancellation', () {
      expect(
        RevenueCatEntitlementGateway.outcomeForPurchaseError(
          PurchasesErrorCode.purchaseCancelledError,
        ),
        PurchaseOutcome.userCancelled,
      );
    });

    test('every other purchase error stays an error', () {
      for (final code in PurchasesErrorCode.values) {
        if (code == PurchasesErrorCode.paymentPendingError ||
            code == PurchasesErrorCode.purchaseCancelledError) {
          continue;
        }
        expect(
          RevenueCatEntitlementGateway.outcomeForPurchaseError(code),
          PurchaseOutcome.error,
          reason: code.name,
        );
      }
    });

    test('a completed purchase is only "purchased" once its entitlement is '
        'active; otherwise it is still confirming', () {
      expect(
        RevenueCatEntitlementGateway.outcomeForPurchasedStatus(
          EntitlementStatus.active,
        ),
        PurchaseOutcome.purchased,
      );
      for (final status in [
        EntitlementStatus.inactive,
        EntitlementStatus.unavailable,
        EntitlementStatus.initializing,
      ]) {
        expect(
          RevenueCatEntitlementGateway.outcomeForPurchasedStatus(status),
          PurchaseOutcome.confirming,
          reason: status.name,
        );
      }
    });
  });

  group('entitlementGatewayProvider', () {
    test('resolves to UnavailableEntitlementGateway when unconfigured — '
        'true under flutter test, since REVENUECAT_* dart-defines are '
        'never set there, and this must never reach purchases_flutter '
        'platform channels', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(entitlementGatewayProvider),
        isA<UnavailableEntitlementGateway>(),
      );
    });
  });
}
