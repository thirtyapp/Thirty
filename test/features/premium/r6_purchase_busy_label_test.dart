import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/premium/entitlement_gateway.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_button.dart';
import 'package:thirty/features/premium/presentation/premium_offer_page.dart';

/// A store whose purchase stays in flight until the test completes it.
class _SlowGateway implements EntitlementGateway {
  final purchase = Completer<PurchaseOutcome>();
  var status = EntitlementStatus.inactive;

  @override
  Stream<EntitlementStatus> get statusUpdates => const Stream.empty();

  @override
  Future<EntitlementStatus> initialize() async => status;

  @override
  Future<MonthlyOffer?> monthlyOffer() async =>
      const MonthlyOffer(localizedPrice: '€3.99');

  @override
  Future<PurchaseOutcome> purchaseMonthly() => purchase.future;

  @override
  Future<RestoreOutcome> restore() async => RestoreOutcome.notFound;

  @override
  Future<String?> managementUrl() async => null;
}

/// Audit remediation R6 (founder-approved copy, 2026-11-03): while a
/// purchase is in flight TalkBack hears "Become Premium, in progress" — the
/// button disabled, nothing else about the purchase changed.
void main() {
  testWidgets('the purchase button while the store works: "Become Premium, '
      'in progress", disabled; afterwards its own label again', (tester) async {
    // As the paywall's own tests: tall enough that the button is built.
    tester.view.physicalSize = const Size(412, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final gateway = _SlowGateway();
    final container = ProviderContainer(
      overrides: [entitlementGatewayProvider.overrideWithValue(gateway)],
    );
    addTearDown(container.dispose);
    await container.read(entitlementStatusProvider.notifier).initialize();
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PremiumOfferPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Become Premium'));
    await tester.pumpAndSettle();
    final button = find.ancestor(
      of: find.text('Become Premium'),
      matching: find.byType(ThirtyButton),
    );
    expect(tester.getSemantics(button).label, 'Become Premium');

    await tester.tap(find.text('Become Premium'));
    await tester.pump();
    final busy = tester.getSemantics(button);
    expect(busy.label, 'Become Premium, in progress');
    expect(busy.flagsCollection.isEnabled, Tristate.isFalse);

    gateway.purchase.complete(PurchaseOutcome.userCancelled);
    await tester.pumpAndSettle();
    expect(tester.getSemantics(button).label, 'Become Premium');
    handle.dispose();
  });
}
