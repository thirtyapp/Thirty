import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/premium/entitlement_gateway.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/features/premium/presentation/premium_offer_page.dart';
import 'package:thirty/core/widgets/thirty_card.dart';

class _FakeEntitlementGateway implements EntitlementGateway {
  _FakeEntitlementGateway({this.initialStatus = EntitlementStatus.inactive});

  EntitlementStatus initialStatus;
  MonthlyOffer? offer = const MonthlyOffer(localizedPrice: '€3.99');
  PurchaseOutcome purchaseOutcome = PurchaseOutcome.purchased;
  EntitlementStatus statusAfterPurchase = EntitlementStatus.active;

  @override
  Stream<EntitlementStatus> get statusUpdates => const Stream.empty();

  @override
  Future<EntitlementStatus> initialize() async => initialStatus;

  @override
  Future<MonthlyOffer?> monthlyOffer() async => offer;

  @override
  Future<PurchaseOutcome> purchaseMonthly() async {
    if (purchaseOutcome == PurchaseOutcome.purchased) {
      initialStatus = statusAfterPurchase;
    }
    return purchaseOutcome;
  }

  @override
  Future<RestoreOutcome> restore() async => RestoreOutcome.notFound;

  @override
  Future<String?> managementUrl() async => null;
}

Future<(Widget, ProviderContainer)> _wrap({
  required _FakeEntitlementGateway gateway,
}) async {
  final container = ProviderContainer(
    overrides: [entitlementGatewayProvider.overrideWithValue(gateway)],
  );
  await container.read(entitlementStatusProvider.notifier).initialize();
  final widget = UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light,
      home: const PremiumOfferPage(),
    ),
  );
  return (widget, container);
}

void main() {
  testWidgets('describes Plans, Coach and Insights and nothing else — no '
      'Atmosphere, AI, trial, annual or scarcity language', (tester) async {
    final (widget, container) = await _wrap(gateway: _FakeEntitlementGateway());
    addTearDown(container.dispose);

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(find.textContaining('Circle Plans'), findsOneWidget);
    expect(find.textContaining('Circle Coach'), findsOneWidget);
    expect(find.textContaining('Circle Insights'), findsOneWidget);
    expect(find.textContaining('Atmosphere'), findsNothing);
    expect(find.textContaining('trial', findRichText: true), findsNothing);
    expect(find.textContaining('annual', findRichText: true), findsNothing);
    expect(find.textContaining('AI'), findsNothing);
  });

  testWidgets('shows the real localized store price and period, never a '
      'hardcoded figure', (tester) async {
    final gateway = _FakeEntitlementGateway()
      ..offer = const MonthlyOffer(localizedPrice: '€3.99');
    final (widget, container) = await _wrap(gateway: gateway);
    addTearDown(container.dispose);

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(find.text('€3.99 / month'), findsOneWidget);
    expect(
      find.text('Billed monthly. Renews automatically until you cancel.'),
      findsOneWidget,
    );
    expect(find.text('Become Premium'), findsOneWidget);
  });

  testWidgets('shows a quiet unavailable state and no purchase button when '
      'no monthly package is configured', (tester) async {
    final gateway = _FakeEntitlementGateway()..offer = null;
    final (widget, container) = await _wrap(gateway: gateway);
    addTearDown(container.dispose);

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(find.text('Pricing isn’t available right now.'), findsOneWidget);
    expect(find.text('Become Premium'), findsNothing);
  });

  testWidgets('already-entitled users see their active status, not a '
      'purchase button (Phase C2 copy)', (tester) async {
    final gateway = _FakeEntitlementGateway(
      initialStatus: EntitlementStatus.active,
    );
    final (widget, container) = await _wrap(gateway: gateway);
    addTearDown(container.dispose);

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(find.text('Premium is active'), findsOneWidget);
    expect(find.text('Become Premium'), findsNothing);
    expect(find.textContaining('/ month'), findsNothing);
  });

  testWidgets('a successful purchase reports confirmation and updates '
      'entitlement state authoritatively', (tester) async {
    final gateway = _FakeEntitlementGateway()
      ..purchaseOutcome = PurchaseOutcome.purchased
      ..statusAfterPurchase = EntitlementStatus.active;
    final (widget, container) = await _wrap(gateway: gateway);
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Become Premium'));
    await tester.tap(find.text('Become Premium'));
    await tester.pumpAndSettle();

    expect(find.text('You now have Premium.'), findsOneWidget);
    expect(container.read(premiumEntitlementProvider), isTrue);
  });

  testWidgets('a user-cancelled purchase is treated as an ordinary outcome '
      '— no error message, no crash', (tester) async {
    final gateway = _FakeEntitlementGateway()
      ..purchaseOutcome = PurchaseOutcome.userCancelled;
    final (widget, container) = await _wrap(gateway: gateway);
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Become Premium'));
    await tester.tap(find.text('Become Premium'));
    await tester.pumpAndSettle();

    expect(find.textContaining('wrong'), findsNothing);
    expect(container.read(premiumEntitlementProvider), isFalse);
  });

  testWidgets('a pending Google Play payment is explained, never shown as '
      'success or as an error', (tester) async {
    final gateway = _FakeEntitlementGateway()
      ..purchaseOutcome = PurchaseOutcome.pending;
    final (widget, container) = await _wrap(gateway: gateway);
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Become Premium'));
    await tester.tap(find.text('Become Premium'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Your payment is pending with Google Play. Premium unlocks when it '
        'completes.',
      ),
      findsOneWidget,
    );
    expect(find.text('You now have Premium.'), findsNothing);
    expect(find.textContaining('wrong'), findsNothing);
    expect(container.read(premiumEntitlementProvider), isFalse);
  });

  testWidgets('a purchase whose entitlement is not yet active is shown as '
      'confirming, never as success', (tester) async {
    final gateway = _FakeEntitlementGateway()
      ..purchaseOutcome = PurchaseOutcome.purchased
      ..statusAfterPurchase = EntitlementStatus.inactive;
    final (widget, container) = await _wrap(gateway: gateway);
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Become Premium'));
    await tester.tap(find.text('Become Premium'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Your purchase is being confirmed. Premium unlocks as soon as '
        'Google Play confirms it.',
      ),
      findsOneWidget,
    );
    expect(find.text('You now have Premium.'), findsNothing);
    expect(container.read(premiumEntitlementProvider), isFalse);
  });

  testWidgets('a provider error is reported without implying success', (
    tester,
  ) async {
    final gateway = _FakeEntitlementGateway()
      ..purchaseOutcome = PurchaseOutcome.error;
    final (widget, container) = await _wrap(gateway: gateway);
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Become Premium'));
    await tester.tap(find.text('Become Premium'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Something went wrong'),
      findsOneWidget,
    );
    expect(container.read(premiumEntitlementProvider), isFalse);
  });

  testWidgets('says Free stays complete and that history stays on this '
      'device (Phase C2 copy)', (tester) async {
    final (widget, container) = await _wrap(gateway: _FakeEntitlementGateway());
    addTearDown(container.dispose);

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(find.text('Free stays complete.'), findsOneWidget);
    expect(
      find.textContaining('Your Circle history stays on this device'),
      findsOneWidget,
    );
  });

  testWidgets('Phase A2 — the Premium offer card uses featuredCard padding', (
    tester,
  ) async {
    final (widget, container) = await _wrap(gateway: _FakeEntitlementGateway());
    addTearDown(container.dispose);

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(
      tester.widget<ThirtyCard>(find.byType(ThirtyCard)).padding,
      const EdgeInsets.all(AppSpacing.featuredCard),
    );
  });
}
