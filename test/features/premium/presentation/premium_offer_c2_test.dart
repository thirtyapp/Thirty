import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/premium/entitlement_gateway.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_button.dart';
import 'package:thirty/features/premium/presentation/premium_offer_page.dart';

/// Phase C2 — the Premium offer page: hierarchy, exits and every
/// billing / purchase state.

class _FakeEntitlementGateway implements EntitlementGateway {
  _FakeEntitlementGateway({
    this.status = EntitlementStatus.inactive,
    Future<MonthlyOffer?>? offer,
  }) : offer =
           offer ??
           Future.value(const MonthlyOffer(localizedPrice: r'$9.99'));

  EntitlementStatus status;
  Future<MonthlyOffer?> offer;
  Future<PurchaseOutcome> Function()? onPurchase;
  EntitlementStatus? statusAfterPurchase;
  final _updates = StreamController<EntitlementStatus>.broadcast();

  void emit(EntitlementStatus next) {
    status = next;
    _updates.add(next);
  }

  @override
  Stream<EntitlementStatus> get statusUpdates => _updates.stream;
  @override
  Future<EntitlementStatus> initialize() async => status;
  @override
  Future<MonthlyOffer?> monthlyOffer() => offer;
  @override
  Future<PurchaseOutcome> purchaseMonthly() async {
    final outcome = await (onPurchase?.call() ??
        Future.value(PurchaseOutcome.purchased));
    if (outcome == PurchaseOutcome.purchased && statusAfterPurchase != null) {
      status = statusAfterPurchase!;
    }
    return outcome;
  }

  @override
  Future<RestoreOutcome> restore() async => RestoreOutcome.notFound;
  @override
  Future<String?> managementUrl() async =>
      'https://play.google.com/store/account/subscriptions';
}

/// Pumps the offer page pushed on top of a plain root route, so the exits
/// have somewhere to go back to.
Future<ProviderContainer> _pump(
  WidgetTester tester,
  _FakeEntitlementGateway gateway, {
  bool initialize = true,
}) async {
  tester.view.physicalSize = const Size(412, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [entitlementGatewayProvider.overrideWithValue(gateway)],
  );
  addTearDown(container.dispose);
  if (initialize) {
    await container.read(entitlementStatusProvider.notifier).initialize();
  }
  final navigatorKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        theme: AppTheme.light,
        home: const Scaffold(body: Text('root')),
      ),
    ),
  );
  navigatorKey.currentState!.push(
    MaterialPageRoute<void>(builder: (_) => const PremiumOfferPage()),
  );
  await tester.pumpAndSettle();
  return container;
}

double _top(WidgetTester tester, Finder finder) =>
    tester.getTopLeft(finder).dy;

Finder get _cta => find.widgetWithText(ThirtyButton, 'Become Premium');

void main() {
  group('Hierarchy', () {
    testWidgets('value → price → disclosure → CTA → Not now → Free → '
        'restore footer → cancel line', (tester) async {
      await _pump(tester, _FakeEntitlementGateway());

      final order = [
        find.text('Plans, Coach and Insights'),
        find.textContaining('Circle Plans'),
        find.textContaining('Circle Coach'),
        find.textContaining('Circle Insights'),
        find.text(r'$9.99 / month'),
        find.text('Billed monthly. Renews automatically until you cancel.'),
        _cta,
        find.text('Not now'),
        find.text('Free stays complete.'),
        find.text('Restore purchases'),
        find.textContaining('You can cancel anytime in Google Play.'),
      ];
      for (var i = 1; i < order.length; i++) {
        expect(
          _top(tester, order[i]),
          greaterThan(_top(tester, order[i - 1])),
          reason: '${order[i]} below ${order[i - 1]}',
        );
      }
    });

    testWidgets('Become Premium is the full-width 56pt hero CTA', (
      tester,
    ) async {
      await _pump(tester, _FakeEntitlementGateway());

      final cta = tester.getRect(_cta);
      expect(cta.height, 56);
      expect(cta.width, 412 - AppSpacing.page * 2);
    });

    testWidgets('each value point is one sentence for assistive tech; the '
        'mark is decorative', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, _FakeEntitlementGateway());
      expect(
        find.bySemanticsLabel(
          'Circle Plans: three guided Plans that remember your place',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Circle Coach: contextual pacing and gentle resumption',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Circle Insights: what your own choices tell you'),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });

  group('Exits', () {
    testWidgets('Not now goes back without purchasing', (tester) async {
      var purchases = 0;
      final gateway = _FakeEntitlementGateway()
        ..onPurchase = () async {
          purchases++;
          return PurchaseOutcome.purchased;
        };
      await _pump(tester, gateway);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(find.byType(PremiumOfferPage), findsNothing);
      expect(find.text('root'), findsOneWidget);
      expect(purchases, 0);
    });

    testWidgets('active: Premium is active, Manage, Done — no price, no CTA', (
      tester,
    ) async {
      final gateway = _FakeEntitlementGateway(status: EntitlementStatus.active);
      await _pump(tester, gateway);

      expect(find.text('Premium is active'), findsOneWidget);
      expect(find.text('Manage subscription'), findsOneWidget);
      expect(_cta, findsNothing);
      expect(find.textContaining('/ month'), findsNothing);
      expect(find.text('Not now'), findsNothing);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(PremiumOfferPage), findsNothing);
    });
  });

  group('Billing-state matrix', () {
    testWidgets('checking: no purchase, no restore', (tester) async {
      await _pump(tester, _FakeEntitlementGateway(), initialize: false);
      expect(find.text('Checking your Premium status…'), findsOneWidget);
      expect(_cta, findsNothing);
      expect(find.text('Restore purchases'), findsNothing);
    });

    testWidgets('unavailable: truthful status, no purchase, restore shown', (
      tester,
    ) async {
      await _pump(
        tester,
        _FakeEntitlementGateway(status: EntitlementStatus.unavailable),
      );
      expect(
        find.text('Premium status is temporarily unavailable'),
        findsOneWidget,
      );
      expect(_cta, findsNothing);
      expect(find.text('Restore purchases'), findsOneWidget);
    });

    testWidgets('price loading: "Checking the current price…", CTA disabled, '
        'no price text', (tester) async {
      final pending = Completer<MonthlyOffer?>();
      await _pump(tester, _FakeEntitlementGateway(offer: pending.future));

      expect(find.text('Checking the current price…'), findsOneWidget);
      expect(find.textContaining('/ month'), findsNothing);
      expect(tester.widget<ThirtyButton>(_cta).onPressed, isNull);

      pending.complete(const MonthlyOffer(localizedPrice: '£4.49'));
      await tester.pumpAndSettle();
      expect(find.text('£4.49 / month'), findsOneWidget);
      expect(tester.widget<ThirtyButton>(_cta).onPressed, isNotNull);
    });

    testWidgets('no offer: no price, no CTA, the exit stays', (tester) async {
      await _pump(tester, _FakeEntitlementGateway(offer: Future.value(null)));
      expect(find.text('Pricing isn’t available right now.'), findsOneWidget);
      expect(_cta, findsNothing);
      expect(find.text('Not now'), findsOneWidget);
    });

    testWidgets('the price is the store\'s own string, never a hardcoded one', (
      tester,
    ) async {
      await _pump(tester, _FakeEntitlementGateway());
      expect(find.text(r'$9.99 / month'), findsOneWidget);
      expect(find.textContaining('€'), findsNothing);
      expect(find.textContaining('4.99'), findsNothing);
    });

    testWidgets('purchasing: CTA loading; Not now and Restore disabled', (
      tester,
    ) async {
      final purchase = Completer<PurchaseOutcome>();
      final gateway = _FakeEntitlementGateway()
        ..onPurchase = () => purchase.future;
      await _pump(tester, gateway);

      await tester.tap(_cta);
      await tester.pump();
      expect(tester.widget<ThirtyButton>(_cta).isLoading, isTrue);
      expect(
        tester.widget<TextButton>(find.widgetWithText(TextButton, 'Not now'))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Restore purchases'),
            )
            .onPressed,
        isNull,
      );

      purchase.complete(PurchaseOutcome.userCancelled);
      await tester.pumpAndSettle();
      expect(tester.widget<ThirtyButton>(_cta).isLoading, isFalse);
    });

    testWidgets('confirmed purchase: switches to the active state and says '
        'so once', (tester) async {
      final gateway = _FakeEntitlementGateway()
        ..statusAfterPurchase = EntitlementStatus.active;
      await _pump(tester, gateway);

      await tester.tap(_cta);
      await tester.pumpAndSettle();
      expect(find.text('You now have Premium.'), findsOneWidget);
      expect(find.text('Premium is active'), findsOneWidget);
      expect(_cta, findsNothing);
    });

    testWidgets('pending: explained, still free — then unlocks when Google '
        'Play completes it', (tester) async {
      final gateway = _FakeEntitlementGateway()
        ..onPurchase = () async => PurchaseOutcome.pending;
      await _pump(tester, gateway);

      await tester.tap(_cta);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Your payment is pending with Google Play. Premium unlocks when it '
          'completes.',
        ),
        findsOneWidget,
      );
      expect(find.text('Premium is active'), findsNothing);

      gateway.emit(EntitlementStatus.active);
      await tester.pumpAndSettle();
      expect(find.text('Premium is active'), findsOneWidget);
      expect(_cta, findsNothing);
    });
  });
}
