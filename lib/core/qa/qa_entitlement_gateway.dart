import '../premium/entitlement_gateway.dart';
import '../premium/entitlement_status.dart';

/// QA-1 — the entitlement states the harness can simulate. A lapsed
/// subscriber is [inactive] plus prior Premium history (the
/// `lapsedRetainedSnapshots` scenario), never a state of its own:
/// [EntitlementStatus] is unchanged.
enum QaEntitlement {
  active,
  inactive,
  unavailable;

  EntitlementStatus get status => switch (this) {
    QaEntitlement.active => EntitlementStatus.active,
    QaEntitlement.inactive => EntitlementStatus.inactive,
    QaEntitlement.unavailable => EntitlementStatus.unavailable,
  };

  String get label => name.toUpperCase();
}

/// QA-1 — a fixed-state [EntitlementGateway] for the debug-only harness.
///
/// It reports exactly [status] through the same abstraction
/// `EntitlementNotifier` consumes from the RevenueCat gateway, so every
/// Premium boundary downstream (`premiumEntitlementProvider`) behaves as it
/// would for a real subscriber in that state. It sells nothing: there is no
/// offer, a purchase or restore is [PurchaseOutcome.unavailable] /
/// [RestoreOutcome.unavailable], and there is no management link — the QA
/// harness never imitates a store transaction.
class QaEntitlementGateway implements EntitlementGateway {
  const QaEntitlementGateway(this.status);

  final EntitlementStatus status;

  @override
  Stream<EntitlementStatus> get statusUpdates => const Stream.empty();

  @override
  Future<EntitlementStatus> initialize() async => status;

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
