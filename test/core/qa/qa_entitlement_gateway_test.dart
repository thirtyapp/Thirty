import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/premium/entitlement_gateway.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/qa/qa_entitlement_gateway.dart';

/// QA-1 — each simulated entitlement reaches Premium through the same
/// [EntitlementNotifier] the RevenueCat gateway feeds, and the QA gateway
/// never imitates a store transaction.
void main() {
  Future<ProviderContainer> containerFor(QaEntitlement entitlement) async {
    final container = ProviderContainer(
      overrides: [
        entitlementGatewayProvider.overrideWithValue(
          QaEntitlementGateway(entitlement.status),
        ),
      ],
    );
    await container.read(entitlementStatusProvider.notifier).initialize();
    return container;
  }

  for (final (entitlement, status, entitled) in [
    (QaEntitlement.active, EntitlementStatus.active, true),
    (QaEntitlement.inactive, EntitlementStatus.inactive, false),
    (QaEntitlement.unavailable, EntitlementStatus.unavailable, false),
  ]) {
    test('${entitlement.name} resolves to $status; Premium is '
        '${entitled ? 'on' : 'off'}', () async {
      final container = await containerFor(entitlement);
      addTearDown(container.dispose);

      expect(container.read(entitlementStatusProvider), status);
      expect(container.read(premiumEntitlementProvider), entitled);
    });
  }

  test('only the three existing statuses are simulated — no new '
      'EntitlementStatus exists for a lapsed subscriber', () {
    expect(QaEntitlement.values.map((e) => e.status).toSet(), {
      EntitlementStatus.active,
      EntitlementStatus.inactive,
      EntitlementStatus.unavailable,
    });
    expect(EntitlementStatus.values, hasLength(4));
  });

  test('the QA gateway sells nothing: no offer, purchase and restore '
      'unavailable, no management link, entitlement unchanged', () async {
    final container = await containerFor(QaEntitlement.inactive);
    addTearDown(container.dispose);
    final notifier = container.read(entitlementStatusProvider.notifier);
    const gateway = QaEntitlementGateway(EntitlementStatus.inactive);

    expect(await gateway.monthlyOffer(), isNull);
    expect(await gateway.managementUrl(), isNull);
    expect(await notifier.purchaseMonthly(), PurchaseOutcome.unavailable);
    expect(await notifier.restore(), RestoreOutcome.unavailable);
    expect(
      container.read(entitlementStatusProvider),
      EntitlementStatus.inactive,
    );
  });
}
