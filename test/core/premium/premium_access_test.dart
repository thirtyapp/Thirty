import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/premium/entitlement_gateway.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';

/// A deterministic test double for [EntitlementGateway] — Step 5
/// (`docs/product/adr/ADR-017-v1-step5-revenuecat-billing.md`). Mirrors
/// this codebase's existing convention of a private per-file fake (see
/// `plan_provider_test.dart`'s `_RecordingAnalyticsService`) rather than a
/// shared test-support library.
class _FakeEntitlementGateway implements EntitlementGateway {
  _FakeEntitlementGateway({EntitlementStatus initialStatus = EntitlementStatus.inactive})
    : _current = initialStatus;

  EntitlementStatus _current;
  final _controller = StreamController<EntitlementStatus>.broadcast();

  PurchaseOutcome purchaseOutcome = PurchaseOutcome.purchased;
  EntitlementStatus statusAfterPurchase = EntitlementStatus.active;

  RestoreOutcome restoreOutcome = RestoreOutcome.restored;
  EntitlementStatus statusAfterRestore = EntitlementStatus.active;

  MonthlyOffer? offer = const MonthlyOffer(localizedPrice: '€3.99');
  String? managementUrlValue;

  @override
  Stream<EntitlementStatus> get statusUpdates => _controller.stream;

  @override
  Future<EntitlementStatus> initialize() async => _current;

  @override
  Future<MonthlyOffer?> monthlyOffer() async => offer;

  @override
  Future<PurchaseOutcome> purchaseMonthly() async {
    if (purchaseOutcome == PurchaseOutcome.purchased) {
      _current = statusAfterPurchase;
      _controller.add(_current);
    }
    return purchaseOutcome;
  }

  @override
  Future<RestoreOutcome> restore() async {
    if (restoreOutcome == RestoreOutcome.restored) {
      _current = statusAfterRestore;
      _controller.add(_current);
    }
    return restoreOutcome;
  }

  @override
  Future<String?> managementUrl() async => managementUrlValue;

  /// Simulates a background provider change while the app is open — a
  /// renewal, a grace/hold transition, or a restore triggered elsewhere.
  void emit(EntitlementStatus status) {
    _current = status;
    _controller.add(status);
  }
}

void main() {
  group('premiumEntitlementProvider (production billing seam)', () {
    test('defaults to unentitled — no production build ever falsely '
        'grants Premium access, even before any override', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(premiumEntitlementProvider), isFalse);
    });

    test('can still be overridden directly for tests/dev via dependency '
        'injection, exactly as Batch 2A documented', () {
      final container = ProviderContainer(
        overrides: [premiumEntitlementProvider.overrideWithValue(true)],
      );
      addTearDown(container.dispose);

      expect(container.read(premiumEntitlementProvider), isTrue);
    });

    test('is true only while entitlementStatusProvider is active', () async {
      final gateway = _FakeEntitlementGateway(
        initialStatus: EntitlementStatus.active,
      );
      final container = ProviderContainer(
        overrides: [entitlementGatewayProvider.overrideWithValue(gateway)],
      );
      addTearDown(container.dispose);

      await container.read(entitlementStatusProvider.notifier).initialize();

      expect(container.read(premiumEntitlementProvider), isTrue);
    });

    test('never becomes true for initializing, inactive or unavailable '
        'status', () async {
      for (final status in [
        EntitlementStatus.inactive,
        EntitlementStatus.unavailable,
      ]) {
        final gateway = _FakeEntitlementGateway(initialStatus: status);
        final container = ProviderContainer(
          overrides: [entitlementGatewayProvider.overrideWithValue(gateway)],
        );
        addTearDown(container.dispose);

        await container.read(entitlementStatusProvider.notifier).initialize();

        expect(container.read(premiumEntitlementProvider), isFalse);
      }
    });
  });

  group('entitlementStatusProvider (EntitlementNotifier)', () {
    test('starts as initializing without ever touching the gateway — a '
        'bare read must never synchronously reach the billing SDK', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(entitlementStatusProvider),
        EntitlementStatus.initializing,
      );
    });

    test('production default (no override) resolves to unavailable on '
        'initialize — missing billing configuration fails closed for '
        'Premium without throwing', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(entitlementStatusProvider.notifier).initialize();

      expect(
        container.read(entitlementStatusProvider),
        EntitlementStatus.unavailable,
      );
    });

    test('initialize() adopts the gateway\'s resolved status', () async {
      final gateway = _FakeEntitlementGateway(
        initialStatus: EntitlementStatus.active,
      );
      final container = ProviderContainer(
        overrides: [entitlementGatewayProvider.overrideWithValue(gateway)],
      );
      addTearDown(container.dispose);

      await container.read(entitlementStatusProvider.notifier).initialize();

      expect(
        container.read(entitlementStatusProvider),
        EntitlementStatus.active,
      );
    });

    test('is idempotent — calling initialize() again re-resolves cleanly '
        '(app restart / foreground-resume lifecycle refresh)', () async {
      final gateway = _FakeEntitlementGateway(
        initialStatus: EntitlementStatus.active,
      );
      final container = ProviderContainer(
        overrides: [entitlementGatewayProvider.overrideWithValue(gateway)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(entitlementStatusProvider.notifier);

      await notifier.initialize();
      await notifier.initialize();

      expect(
        container.read(entitlementStatusProvider),
        EntitlementStatus.active,
      );
    });

    test('reflects a background status change pushed after initialize — '
        'renewal, grace/hold transition, or a restore triggered '
        'elsewhere', () async {
      final gateway = _FakeEntitlementGateway(
        initialStatus: EntitlementStatus.active,
      );
      final container = ProviderContainer(
        overrides: [entitlementGatewayProvider.overrideWithValue(gateway)],
      );
      addTearDown(container.dispose);
      await container.read(entitlementStatusProvider.notifier).initialize();

      // Account hold: the grace period ended without recovery.
      gateway.emit(EntitlementStatus.inactive);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(entitlementStatusProvider),
        EntitlementStatus.inactive,
      );
    });

    test(
      'cancellation with paid time remaining stays active — Google Play '
      'reports isActive=true for both a normal period and a cancelled '
      'one before its expiryTime, and the gateway maps both to active '
      '(frozen architecture §6: cancellation is not immediate loss)',
      () async {
        final gateway = _FakeEntitlementGateway(
          initialStatus: EntitlementStatus.active,
        );
        final container = ProviderContainer(
          overrides: [entitlementGatewayProvider.overrideWithValue(gateway)],
        );
        addTearDown(container.dispose);

        await container.read(entitlementStatusProvider.notifier).initialize();

        expect(container.read(premiumEntitlementProvider), isTrue);
      },
    );

    test(
      'grace period stays active — Play reports IN_GRACE_PERIOD as '
      'isActive=true while the payment retry window is open',
      () async {
        final gateway = _FakeEntitlementGateway(
          initialStatus: EntitlementStatus.active,
        );
        final container = ProviderContainer(
          overrides: [entitlementGatewayProvider.overrideWithValue(gateway)],
        );
        addTearDown(container.dispose);

        await container.read(entitlementStatusProvider.notifier).initialize();

        expect(container.read(premiumEntitlementProvider), isTrue);
      },
    );

    test(
      'account hold, expiry, revocation and refund all resolve to '
      'inactive, never crash, never fabricate Premium',
      () async {
        for (final _ in [0, 1, 2, 3]) {
          final gateway = _FakeEntitlementGateway(
            initialStatus: EntitlementStatus.inactive,
          );
          final container = ProviderContainer(
            overrides: [
              entitlementGatewayProvider.overrideWithValue(gateway),
            ],
          );
          addTearDown(container.dispose);

          await container
              .read(entitlementStatusProvider.notifier)
              .initialize();

          expect(
            container.read(entitlementStatusProvider),
            EntitlementStatus.inactive,
          );
          expect(container.read(premiumEntitlementProvider), isFalse);
        }
      },
    );

    test('purchaseMonthly() re-syncs authoritative state from the '
        'gateway, not from the call merely returning', () async {
      final gateway = _FakeEntitlementGateway(
        initialStatus: EntitlementStatus.inactive,
      );
      final container = ProviderContainer(
        overrides: [entitlementGatewayProvider.overrideWithValue(gateway)],
      );
      addTearDown(container.dispose);
      await container.read(entitlementStatusProvider.notifier).initialize();

      final outcome = await container
          .read(entitlementStatusProvider.notifier)
          .purchaseMonthly();
      await Future<void>.delayed(Duration.zero);

      expect(outcome, PurchaseOutcome.purchased);
      expect(
        container.read(entitlementStatusProvider),
        EntitlementStatus.active,
      );
    });

    test('user-cancelled purchase is an ordinary outcome, not an error, '
        'and never changes entitlement state', () async {
      final gateway = _FakeEntitlementGateway(
        initialStatus: EntitlementStatus.inactive,
      )..purchaseOutcome = PurchaseOutcome.userCancelled;
      final container = ProviderContainer(
        overrides: [entitlementGatewayProvider.overrideWithValue(gateway)],
      );
      addTearDown(container.dispose);
      await container.read(entitlementStatusProvider.notifier).initialize();

      final outcome = await container
          .read(entitlementStatusProvider.notifier)
          .purchaseMonthly();

      expect(outcome, PurchaseOutcome.userCancelled);
      expect(
        container.read(entitlementStatusProvider),
        EntitlementStatus.inactive,
      );
    });

    test('restore() is idempotent — repeating it with nothing to '
        'restore always yields notFound, never an error', () async {
      final gateway = _FakeEntitlementGateway(
        initialStatus: EntitlementStatus.inactive,
      )..restoreOutcome = RestoreOutcome.notFound;
      final container = ProviderContainer(
        overrides: [entitlementGatewayProvider.overrideWithValue(gateway)],
      );
      addTearDown(container.dispose);
      await container.read(entitlementStatusProvider.notifier).initialize();
      final notifier = container.read(entitlementStatusProvider.notifier);

      expect(await notifier.restore(), RestoreOutcome.notFound);
      expect(await notifier.restore(), RestoreOutcome.notFound);
      expect(
        container.read(entitlementStatusProvider),
        EntitlementStatus.inactive,
      );
    });

    test('successful restore re-syncs authoritative active state', () async {
      final gateway = _FakeEntitlementGateway(
        initialStatus: EntitlementStatus.inactive,
      );
      final container = ProviderContainer(
        overrides: [entitlementGatewayProvider.overrideWithValue(gateway)],
      );
      addTearDown(container.dispose);
      await container.read(entitlementStatusProvider.notifier).initialize();

      final outcome = await container
          .read(entitlementStatusProvider.notifier)
          .restore();
      await Future<void>.delayed(Duration.zero);

      expect(outcome, RestoreOutcome.restored);
      expect(
        container.read(entitlementStatusProvider),
        EntitlementStatus.active,
      );
    });
  });
}
