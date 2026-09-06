import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/premium/entitlement_gateway.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/settings/presentation/settings_page.dart';

class _FakeEntitlementGateway implements EntitlementGateway {
  _FakeEntitlementGateway({this.initialStatus = EntitlementStatus.inactive});

  EntitlementStatus initialStatus;
  RestoreOutcome restoreOutcome = RestoreOutcome.notFound;
  String? managementUrlValue;

  @override
  Stream<EntitlementStatus> get statusUpdates => const Stream.empty();

  @override
  Future<EntitlementStatus> initialize() async => initialStatus;

  @override
  Future<MonthlyOffer?> monthlyOffer() async => null;

  @override
  Future<PurchaseOutcome> purchaseMonthly() async => PurchaseOutcome.error;

  @override
  Future<RestoreOutcome> restore() async => restoreOutcome;

  @override
  Future<String?> managementUrl() async => managementUrlValue;
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
    child: MaterialApp(theme: AppTheme.light, home: const SettingsPage()),
  );
  return (widget, container);
}

void main() {
  testWidgets('shows "Premium is active" and a manage-subscription button '
      'when a real managementURL is available', (tester) async {
    final gateway = _FakeEntitlementGateway(
      initialStatus: EntitlementStatus.active,
    )..managementUrlValue = 'https://play.google.com/store/account/subscriptions';
    final (widget, container) = await _wrap(gateway: gateway);
    addTearDown(container.dispose);

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(find.text('Premium is active'), findsOneWidget);
    expect(find.text('Manage subscription'), findsOneWidget);
    expect(find.text('Upgrade to Premium'), findsNothing);
  });

  testWidgets('falls back to plain Play Store guidance when active but no '
      'managementURL is available', (tester) async {
    final gateway = _FakeEntitlementGateway(
      initialStatus: EntitlementStatus.active,
    );
    final (widget, container) = await _wrap(gateway: gateway);
    addTearDown(container.dispose);

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Manage or cancel this subscription from the'),
      findsOneWidget,
    );
    expect(find.text('Manage subscription'), findsNothing);
  });

  testWidgets('shows "Premium is not active" and an Upgrade entry when '
      'inactive', (tester) async {
    final gateway = _FakeEntitlementGateway(
      initialStatus: EntitlementStatus.inactive,
    );
    final (widget, container) = await _wrap(gateway: gateway);
    addTearDown(container.dispose);

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(find.text('Premium is not active'), findsOneWidget);
    expect(find.text('Upgrade to Premium'), findsOneWidget);
    expect(find.text('Manage subscription'), findsNothing);
  });

  testWidgets('shows a truthful "temporarily unavailable" state without '
      'implying the user was never subscribed', (tester) async {
    final gateway = _FakeEntitlementGateway(
      initialStatus: EntitlementStatus.unavailable,
    );
    final (widget, container) = await _wrap(gateway: gateway);
    addTearDown(container.dispose);

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(
      find.text('Premium status is temporarily unavailable'),
      findsOneWidget,
    );
  });

  testWidgets('restore purchases: success reports the restored message', (
    tester,
  ) async {
    final gateway = _FakeEntitlementGateway(
      initialStatus: EntitlementStatus.inactive,
    )..restoreOutcome = RestoreOutcome.restored;
    final (widget, container) = await _wrap(gateway: gateway);
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restore purchases'));
    await tester.pumpAndSettle();

    expect(
      find.text('Your Premium access has been restored.'),
      findsOneWidget,
    );
  });

  testWidgets('restore purchases: no purchase found is reported plainly, '
      'not as an error', (tester) async {
    final gateway = _FakeEntitlementGateway(
      initialStatus: EntitlementStatus.inactive,
    )..restoreOutcome = RestoreOutcome.notFound;
    final (widget, container) = await _wrap(gateway: gateway);
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restore purchases'));
    await tester.pumpAndSettle();

    expect(
      find.text('No previous purchase was found to restore.'),
      findsOneWidget,
    );
  });

  testWidgets('restore purchases is idempotent — repeated taps never '
      'duplicate or crash', (tester) async {
    final gateway = _FakeEntitlementGateway(
      initialStatus: EntitlementStatus.inactive,
    )..restoreOutcome = RestoreOutcome.notFound;
    final (widget, container) = await _wrap(gateway: gateway);
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restore purchases'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore purchases'));
    await tester.pumpAndSettle();

    expect(
      find.text('No previous purchase was found to restore.'),
      findsOneWidget,
    );
  });

  testWidgets('links to Your Circle history for existing data controls', (
    tester,
  ) async {
    final gateway = _FakeEntitlementGateway();
    final (widget, container) = await _wrap(gateway: gateway);
    addTearDown(container.dispose);

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(
      find.text('Your Circle history — view, export or delete'),
      findsOneWidget,
    );
  });
}
