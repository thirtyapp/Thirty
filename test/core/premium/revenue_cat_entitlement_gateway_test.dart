import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart'
    show PurchasesErrorCode;

import 'package:thirty/core/config/revenue_cat_config.dart';
import 'package:thirty/core/premium/entitlement_gateway.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/premium/revenue_cat_entitlement_gateway.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_button.dart';
import 'package:thirty/features/premium/presentation/premium_offer_page.dart';

/// The real [RevenueCatEntitlementGateway], driven through the real
/// `purchases_flutter` Dart layer (its own `CustomerInfo`/`Offerings`/
/// `PurchaseResult` parsing). Only the native side of the
/// `purchases_flutter` method channel is stubbed, with the payload shapes
/// RevenueCat returns — no Google Play or RevenueCat backend is reached, so
/// none of this is store evidence (audit remediation R1: A2-01, J18).
const _entitlementId = 'premium';

const _channel = MethodChannel('purchases_flutter');

Map<String, Object?> _customerInfo([
  Map<String, Map<String, Object?>> entitlements = const {},
]) => {
  'entitlements': {
    'all': entitlements,
    'active': {
      for (final MapEntry(:key, :value) in entitlements.entries)
        if (value['isActive'] == true) key: value,
    },
    'verification': 'NOT_REQUESTED',
  },
  'allPurchaseDates': <String, Object?>{},
  'activeSubscriptions': <Object?>[
    for (final value in entitlements.values)
      if (value['isActive'] == true) value['productIdentifier'],
  ],
  'allPurchasedProductIdentifiers': <Object?>[
    for (final value in entitlements.values) value['productIdentifier'],
  ],
  'nonSubscriptionTransactions': <Object?>[],
  'firstSeen': '2026-10-21T10:00:00Z',
  'originalAppUserId': r'$RCAnonymousID:r1',
  'allExpirationDates': <String, Object?>{},
  'requestDate': '2026-10-21T10:00:00Z',
};

Map<String, Object?> _entitlement(String id, {required bool isActive}) => {
  'identifier': id,
  'isActive': isActive,
  'willRenew': isActive,
  'latestPurchaseDate': '2026-08-01T10:00:00Z',
  'originalPurchaseDate': '2026-08-01T10:00:00Z',
  'productIdentifier': 'thirty_monthly',
  'isSandbox': true,
  'expirationDate': isActive ? '2026-11-21T10:00:00Z' : '2026-09-01T10:00:00Z',
};

/// What a customer who never bought anything gets back: RevenueCat lists
/// an entitlement only once it has been owned.
final _neverPurchased = _customerInfo();
final _expired = _customerInfo({
  _entitlementId: _entitlement(_entitlementId, isActive: false),
});
final _active = _customerInfo({
  _entitlementId: _entitlement(_entitlementId, isActive: true),
});

Map<String, Object?> _offerings({bool monthly = true}) {
  final package = {
    'identifier': r'$rc_monthly',
    'packageType': 'MONTHLY',
    'product': {
      'identifier': 'thirty_monthly',
      'description': 'THIRTY Premium',
      'title': 'THIRTY Premium',
      'price': 3.99,
      'priceString': '€3.99',
      'currencyCode': 'EUR',
      'productCategory': 'SUBSCRIPTION',
      'subscriptionPeriod': 'P1M',
    },
    'presentedOfferingContext': {'offeringIdentifier': 'default'},
  };
  final offering = {
    'identifier': 'default',
    'serverDescription': 'Default',
    'metadata': <String, Object?>{},
    'availablePackages': monthly ? [package] : <Object?>[],
    'monthly': monthly ? package : null,
  };
  return {
    'all': {'default': offering},
    'current': offering,
  };
}

Map<String, Object?> _purchaseResult(Map<String, Object?> customerInfo) => {
  'customerInfo': customerInfo,
  'transaction': {
    'transactionIdentifier': 'GPA.r1',
    'productIdentifier': 'thirty_monthly',
    'purchaseDate': '2026-10-21T10:05:00Z',
  },
};

PlatformException _sdkError(PurchasesErrorCode code) =>
    PlatformException(code: '${code.index}', message: code.name);

/// The native side of the channel. Each field is what the next call of
/// that method answers; an [Exception] value is thrown as the native
/// error. With [holdLookups], every `getCustomerInfo` waits on its own
/// completer in [heldLookups], so a test decides the completion order.
class _NativeBilling {
  Object setup = 'ok';
  Object customerInfo = _neverPurchased;
  Object offerings = _offerings();
  Object purchase = _purchaseResult(_active);
  Object restore = _neverPurchased;
  bool holdLookups = false;
  final heldLookups = <Completer<Object?>>[];
  final calls = <String>[];

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) {
          calls.add(call.method);
          if (call.method == 'getCustomerInfo' && holdLookups) {
            final lookup = Completer<Object?>();
            heldLookups.add(lookup);
            return lookup.future;
          }
          final answer = switch (call.method) {
            'setupPurchases' => setup,
            'getCustomerInfo' => customerInfo,
            'getOfferings' => offerings,
            'purchasePackage' => purchase,
            'restorePurchases' => restore,
            _ => null,
          };
          if (answer is Exception) throw answer;
          return Future.value(answer == 'ok' ? null : answer);
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null),
    );
  }

  /// RevenueCat pushing a background change (renewal, expiry, a purchase
  /// completing later) — `Purchases-CustomerInfoUpdated`.
  Future<void> push(Map<String, Object?> customerInfo) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          _channel.name,
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('Purchases-CustomerInfoUpdated', customerInfo),
          ),
          (_) {},
        );
  }
}

RevenueCatEntitlementGateway _gateway() => RevenueCatEntitlementGateway(
  const RevenueCatConfig(
    androidApiKey: 'goog_r1',
    entitlementId: _entitlementId,
  ),
);

ProviderContainer _container(RevenueCatEntitlementGateway gateway) {
  final container = ProviderContainer(
    overrides: [entitlementGatewayProvider.overrideWithValue(gateway)],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RevenueCatEntitlementGateway status mapping (A2-01)', () {
    test('a never-purchased customer — no entitlement listed at all — is '
        'inactive, not unavailable, and never Premium', () async {
      final native = _NativeBilling()..customerInfo = _neverPurchased;
      native.install();
      final container = _container(_gateway());

      await container.read(entitlementStatusProvider.notifier).initialize();

      expect(
        native.calls,
        containsAllInOrder(['setupPurchases', 'getCustomerInfo']),
      );
      expect(
        container.read(entitlementStatusProvider),
        EntitlementStatus.inactive,
      );
      expect(container.read(premiumEntitlementProvider), isFalse);
    });

    test('a previously expired subscription is inactive', () async {
      _NativeBilling()
        ..customerInfo = _expired
        ..install();

      expect(await _gateway().initialize(), EntitlementStatus.inactive);
    });

    test('a currently active subscription is active', () async {
      _NativeBilling()
        ..customerInfo = _active
        ..install();
      final container = _container(_gateway());

      await container.read(entitlementStatusProvider.notifier).initialize();

      expect(
        container.read(entitlementStatusProvider),
        EntitlementStatus.active,
      );
      expect(container.read(premiumEntitlementProvider), isTrue);
    });

    test('a failed customer lookup stays unavailable — fails closed, never '
        'inactive and never Premium', () async {
      _NativeBilling()
        ..customerInfo = _sdkError(PurchasesErrorCode.networkError)
        ..install();
      final container = _container(_gateway());

      await container.read(entitlementStatusProvider.notifier).initialize();

      expect(
        container.read(entitlementStatusProvider),
        EntitlementStatus.unavailable,
      );
      expect(container.read(premiumEntitlementProvider), isFalse);
    });

    test('a failed SDK setup stays unavailable', () async {
      _NativeBilling()
        ..setup = _sdkError(PurchasesErrorCode.configurationError)
        ..customerInfo = _active
        ..install();

      expect(await _gateway().initialize(), EntitlementStatus.unavailable);
    });

    test('a valid offering never implies ownership: the configured '
        'entitlement absent — even beside another, active one — is '
        'inactive while the offer itself is available', () async {
      _NativeBilling()
        ..customerInfo = _customerInfo({
          'other': _entitlement('other', isActive: true),
        })
        ..offerings = _offerings()
        ..install();
      final gateway = _gateway();

      expect(await gateway.initialize(), EntitlementStatus.inactive);
      expect((await gateway.monthlyOffer())?.localizedPrice, '€3.99');
    });

    test('no current monthly package: no offer, and a purchase attempt is '
        'unavailable, not an error', () async {
      final native = _NativeBilling()
        ..offerings = _offerings(monthly: false)
        ..install();
      final gateway = _gateway();

      expect(await gateway.initialize(), EntitlementStatus.inactive);
      expect(await gateway.monthlyOffer(), isNull);
      expect(await gateway.purchaseMonthly(), PurchaseOutcome.unavailable);
      expect(native.calls, isNot(contains('purchasePackage')));
    });

    test('a failed offerings lookup is no offer', () async {
      _NativeBilling()
        ..offerings = _sdkError(PurchasesErrorCode.networkError)
        ..install();

      expect(await _gateway().monthlyOffer(), isNull);
    });
  });

  group('RevenueCatEntitlementGateway purchase and restore (A2-01)', () {
    test('a never-purchased customer buys: the active entitlement RevenueCat '
        'returns makes it purchased, and Premium follows', () async {
      final native = _NativeBilling()
        ..customerInfo = _neverPurchased
        ..purchase = _purchaseResult(_active);
      native.install();
      final container = _container(_gateway());
      final notifier = container.read(entitlementStatusProvider.notifier);
      await notifier.initialize();

      // RevenueCat now answers lookups with the purchase.
      native.customerInfo = _active;
      expect(await notifier.purchaseMonthly(), PurchaseOutcome.purchased);
      expect(container.read(premiumEntitlementProvider), isTrue);
    });

    test('a completed purchase whose result lists no active entitlement is '
        'confirming, never purchased', () async {
      _NativeBilling()
        ..purchase = _purchaseResult(_neverPurchased)
        ..install();

      expect(await _gateway().purchaseMonthly(), PurchaseOutcome.confirming);
    });

    test('a closed purchase sheet, a pending payment and a store error map '
        'to their outcomes', () async {
      for (final (error, outcome) in [
        (
          PurchasesErrorCode.purchaseCancelledError,
          PurchaseOutcome.userCancelled,
        ),
        (PurchasesErrorCode.paymentPendingError, PurchaseOutcome.pending),
        (PurchasesErrorCode.storeProblemError, PurchaseOutcome.error),
      ]) {
        _NativeBilling()
          ..purchase = _sdkError(error)
          ..install();
        expect(await _gateway().purchaseMonthly(), outcome, reason: error.name);
      }
    });

    test('restore: nothing owned is notFound, an owned entitlement is '
        'restored, a provider error is an error', () async {
      for (final (answer, outcome) in [
        (_neverPurchased, RestoreOutcome.notFound),
        (_expired, RestoreOutcome.notFound),
        (_active, RestoreOutcome.restored),
        (_sdkError(PurchasesErrorCode.networkError), RestoreOutcome.error),
      ]) {
        _NativeBilling()
          ..restore = answer
          ..install();
        expect(await _gateway().restore(), outcome, reason: '$outcome');
      }
    });
  });

  group('PremiumOfferPage through the real adapter (A2-01)', () {
    Future<ProviderContainer> pumpOffer(
      WidgetTester tester,
      _NativeBilling native,
    ) async {
      tester.view.physicalSize = const Size(412, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      native.install();
      final container = _container(_gateway());
      await container.read(entitlementStatusProvider.notifier).initialize();
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
      return container;
    }

    const unavailableNote = 'Premium status is temporarily unavailable';
    const purchase = 'Become Premium';

    testWidgets('a never-purchased customer sees the store price and the '
        'one purchase button', (tester) async {
      await pumpOffer(tester, _NativeBilling()..customerInfo = _neverPurchased);

      expect(find.text('€3.99 / month'), findsOneWidget);
      expect(find.text(purchase), findsOneWidget);
      expect(
        tester
            .widget<ThirtyButton>(find.widgetWithText(ThirtyButton, purchase))
            .onPressed,
        isNotNull,
      );
      expect(find.text(unavailableNote), findsNothing);
    });

    testWidgets('a never-purchased customer with no current offering sees '
        'pricing unavailable and no purchase button — never a broken one', (
      tester,
    ) async {
      await pumpOffer(
        tester,
        _NativeBilling()
          ..customerInfo = _neverPurchased
          ..offerings = _offerings(monthly: false),
      );

      expect(find.text('Pricing isn’t available right now.'), findsOneWidget);
      expect(find.text(purchase), findsNothing);
      expect(find.text(unavailableNote), findsNothing);
    });

    testWidgets('an expired subscriber sees the purchase button', (
      tester,
    ) async {
      await pumpOffer(tester, _NativeBilling()..customerInfo = _expired);

      expect(find.text('€3.99 / month'), findsOneWidget);
      expect(find.text(purchase), findsOneWidget);
    });

    testWidgets('an active subscriber sees their status, never a price or a '
        'purchase button', (tester) async {
      await pumpOffer(tester, _NativeBilling()..customerInfo = _active);

      expect(find.text('Premium is active'), findsOneWidget);
      expect(find.text(purchase), findsNothing);
      expect(find.text('€3.99 / month'), findsNothing);
    });

    testWidgets('a failed customer lookup shows the truthful unavailable '
        'note and no purchase button', (tester) async {
      await pumpOffer(
        tester,
        _NativeBilling()
          ..customerInfo = _sdkError(PurchasesErrorCode.networkError),
      );

      expect(find.text(unavailableNote), findsOneWidget);
      expect(find.text(purchase), findsNothing);
    });

    testWidgets('a never-purchased customer can buy from the offer: '
        'RevenueCat confirms, the page says so and shows Premium active', (
      tester,
    ) async {
      final native = _NativeBilling()..customerInfo = _neverPurchased;
      final container = await pumpOffer(tester, native);

      native
        ..purchase = _purchaseResult(_active)
        ..customerInfo = _active;
      await tester.tap(find.text(purchase));
      await tester.pumpAndSettle();

      expect(native.calls, contains('purchasePackage'));
      expect(find.text('You now have Premium.'), findsOneWidget);
      expect(find.text('Premium is active'), findsOneWidget);
      expect(container.read(premiumEntitlementProvider), isTrue);
    });
  });

  group('overlapping entitlement refreshes (J18)', () {
    test(
      'a resume refresh still in flight when a purchase is confirmed '
      'never overwrites the confirmed Premium with its older answer',
      () async {
        final native = _NativeBilling()..customerInfo = _neverPurchased;
        native.install();
        final container = _container(_gateway());
        final notifier = container.read(entitlementStatusProvider.notifier);
        await notifier.initialize();
        expect(
          container.read(entitlementStatusProvider),
          EntitlementStatus.inactive,
        );

        native.holdLookups = true;
        // Returning from the Play purchase sheet resumes the app, whose
        // lifecycle refresh asks RevenueCat before the purchase lands.
        unawaited(notifier.initialize());
        await _settle();
        final purchased = notifier.purchaseMonthly();
        await _settle();
        expect(native.heldLookups, hasLength(2));

        // The purchase confirmation's own lookup answers first…
        native.heldLookups[1].complete(_active);
        expect(await purchased, PurchaseOutcome.purchased);
        // …then the resume refresh's, with the pre-purchase state.
        native.heldLookups[0].complete(_neverPurchased);
        await _settle();

        expect(
          container.read(entitlementStatusProvider),
          EntitlementStatus.active,
        );
        expect(container.read(premiumEntitlementProvider), isTrue);
      },
    );

    test('an older lookup failing late never downgrades a newer verified '
        'answer to unavailable', () async {
      final native = _NativeBilling()..holdLookups = true;
      native.install();
      final container = _container(_gateway());
      final notifier = container.read(entitlementStatusProvider.notifier);

      unawaited(notifier.initialize());
      await _settle();
      unawaited(notifier.initialize());
      await _settle();
      native.heldLookups[1].complete(_active);
      await _settle();
      native.heldLookups[0].completeError(
        _sdkError(PurchasesErrorCode.networkError),
      );
      await _settle();

      expect(
        container.read(entitlementStatusProvider),
        EntitlementStatus.active,
      );
    });

    test('the newest lookup still wins when it is also the last to answer '
        '— a genuine expiry is never held back', () async {
      final native = _NativeBilling()..holdLookups = true;
      native.install();
      final container = _container(_gateway());
      final notifier = container.read(entitlementStatusProvider.notifier);

      unawaited(notifier.initialize());
      await _settle();
      unawaited(notifier.initialize());
      await _settle();
      native.heldLookups[0].complete(_active);
      await _settle();
      native.heldLookups[1].complete(_expired);
      await _settle();

      expect(
        container.read(entitlementStatusProvider),
        EntitlementStatus.inactive,
      );
    });

    test('a newer failed lookup still reports unavailable — failure after '
        'a verified answer is never hidden', () async {
      final native = _NativeBilling()..customerInfo = _active;
      native.install();
      final container = _container(_gateway());
      final notifier = container.read(entitlementStatusProvider.notifier);
      await notifier.initialize();

      native.customerInfo = _sdkError(PurchasesErrorCode.networkError);
      await notifier.initialize();

      expect(
        container.read(entitlementStatusProvider),
        EntitlementStatus.unavailable,
      );
    });

    // Last in this file: the SDK replays its last pushed CustomerInfo to
    // every listener added afterwards, for the rest of the isolate.
    test('a lookup started before RevenueCat pushes a change never '
        'overwrites that newer push', () async {
      final native = _NativeBilling()..customerInfo = _neverPurchased;
      native.install();
      final container = _container(_gateway());
      final notifier = container.read(entitlementStatusProvider.notifier);
      await notifier.initialize();

      native.holdLookups = true;
      unawaited(notifier.initialize());
      await _settle();
      // A pending Google Play payment completes while that lookup waits.
      await native.push(_active);
      await _settle();
      expect(
        container.read(entitlementStatusProvider),
        EntitlementStatus.active,
      );
      native.heldLookups.single.complete(_neverPurchased);
      await _settle();

      expect(
        container.read(entitlementStatusProvider),
        EntitlementStatus.active,
      );
    });
  });
}
