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

    expect(
      find.textContaining('€3.99 / month, billed automatically'),
      findsOneWidget,
    );
    expect(find.text('Subscribe'), findsOneWidget);
  });

  testWidgets('shows a quiet unavailable state and no purchase button when '
      'no monthly package is configured', (tester) async {
    final gateway = _FakeEntitlementGateway()..offer = null;
    final (widget, container) = await _wrap(gateway: gateway);
    addTearDown(container.dispose);

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Premium is temporarily unavailable'),
      findsOneWidget,
    );
    expect(find.text('Subscribe'), findsNothing);
  });

  testWidgets('already-entitled users see confirmation, not a purchase '
      'button', (tester) async {
    final gateway = _FakeEntitlementGateway(
      initialStatus: EntitlementStatus.active,
    );
    final (widget, container) = await _wrap(gateway: gateway);
    addTearDown(container.dispose);

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(find.text('You already have Premium.'), findsOneWidget);
    expect(find.text('Subscribe'), findsNothing);
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

    await tester.tap(find.text('Subscribe'));
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

    await tester.tap(find.text('Subscribe'));
    await tester.pumpAndSettle();

    expect(find.textContaining('wrong'), findsNothing);
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

    await tester.tap(find.text('Subscribe'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Something went wrong'),
      findsOneWidget,
    );
    expect(container.read(premiumEntitlementProvider), isFalse);
  });

  testWidgets('mentions Free remains available and that history is '
      'device-local, not cloud-synced', (tester) async {
    final (widget, container) = await _wrap(gateway: _FakeEntitlementGateway());
    addTearDown(container.dispose);

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(find.textContaining('Free remains complete'), findsOneWidget);
    expect(find.textContaining('not backed up to the cloud'), findsOneWidget);
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
