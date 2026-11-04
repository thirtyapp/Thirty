import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/premium/entitlement_gateway.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';

/// A store whose restore reports an active entitlement, then — re-resolved
/// at once, as the notifier does — answers [afterRestore].
class _Gateway implements EntitlementGateway {
  _Gateway(this.afterRestore);

  final EntitlementStatus afterRestore;
  var _current = EntitlementStatus.inactive;

  @override
  Stream<EntitlementStatus> get statusUpdates => const Stream.empty();

  @override
  Future<EntitlementStatus> initialize() async => _current;

  @override
  Future<MonthlyOffer?> monthlyOffer() async => null;

  @override
  Future<PurchaseOutcome> purchaseMonthly() async => PurchaseOutcome.error;

  @override
  Future<RestoreOutcome> restore() async {
    _current = afterRestore;
    return RestoreOutcome.restored;
  }

  @override
  Future<String?> managementUrl() async => null;
}

/// Audit remediation R8 (audit recommendation, restore wording): "Your
/// Premium access has been restored." is said only when Premium is then
/// verified active. When billing's own answer right after the restore is
/// inactive or unavailable, the outcome is unavailable — "Restore isn't
/// available right now" — never a success the entitlement doesn't show.
/// RevenueCat stays the only authority; nothing here grants Premium.
void main() {
  for (final (after, expected) in [
    (EntitlementStatus.active, RestoreOutcome.restored),
    (EntitlementStatus.inactive, RestoreOutcome.unavailable),
    (EntitlementStatus.unavailable, RestoreOutcome.unavailable),
  ]) {
    test('restore reported, billing then ${after.name}: ${expected.name}, '
        'and Premium is exactly what billing says', () async {
      final c = ProviderContainer(
        overrides: [
          entitlementGatewayProvider.overrideWithValue(_Gateway(after)),
        ],
      );
      addTearDown(c.dispose);
      await c.read(entitlementStatusProvider.notifier).initialize();
      final outcome = await c
          .read(entitlementStatusProvider.notifier)
          .restore();
      expect(outcome, expected);
      expect(c.read(entitlementStatusProvider), after);
      expect(
        c.read(premiumEntitlementProvider),
        after == EntitlementStatus.active,
      );
    });
  }
}
