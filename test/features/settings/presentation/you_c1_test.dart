import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/premium/entitlement_gateway.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/providers/theme_mode_provider.dart';
import 'package:thirty/core/reminder/reminder_gateway.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/settings/presentation/settings_page.dart';

/// Phase C1 — You: approved commercial hierarchy and billing-state matrix.

class _FakeReminderGateway implements ReminderGateway {
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<bool> hasExactAlarmAccess() async => true;
  @override
  Future<void> requestExactAlarmAccess() async {}
  @override
  Future<ScheduleOutcome> scheduleDaily({
    required DateTime firstOccurrenceLocal,
    required int hour,
    required int minute,
  }) async => ScheduleOutcome.scheduled;
  @override
  Future<void> cancel() async {}
}

class _FakeEntitlementGateway implements EntitlementGateway {
  _FakeEntitlementGateway({
    this.status = EntitlementStatus.inactive,
    this.offer,
    this.managementUrlValue,
  });

  EntitlementStatus status;
  Future<MonthlyOffer?>? offer;
  String? managementUrlValue;
  RestoreOutcome restoreOutcome = RestoreOutcome.notFound;
  EntitlementStatus? statusAfterRestore;
  int offerCalls = 0;
  int managementUrlCalls = 0;
  int restoreCalls = 0;

  @override
  Stream<EntitlementStatus> get statusUpdates => const Stream.empty();

  @override
  Future<EntitlementStatus> initialize() async => status;

  @override
  Future<MonthlyOffer?> monthlyOffer() {
    offerCalls++;
    return offer ?? Future.value(null);
  }

  @override
  Future<PurchaseOutcome> purchaseMonthly() async => PurchaseOutcome.error;

  @override
  Future<RestoreOutcome> restore() async {
    restoreCalls++;
    if (statusAfterRestore != null) status = statusAfterRestore!;
    return restoreOutcome;
  }

  @override
  Future<String?> managementUrl() async {
    managementUrlCalls++;
    return managementUrlValue;
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  _FakeEntitlementGateway gateway, {
  bool initialize = true,
  bool withJournal = false,
}) async {
  tester.view.physicalSize = const Size(412, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  if (withJournal) {
    await CircleJournalRepository(prefs).recordShown(
      circleId: '2026-08-01',
      localDate: '2026-08-01',
      direction: Intention.moreEnergy,
      activityId: ActivityId.thirtyMinuteWalk,
      shownAt: DateTime(2026, 8, 1, 9),
    );
  }
  final container = ProviderContainer(
    overrides: [
      entitlementGatewayProvider.overrideWithValue(gateway),
      sharedPreferencesProvider.overrideWithValue(prefs),
      reminderGatewayProvider.overrideWithValue(_FakeReminderGateway()),
    ],
  );
  addTearDown(container.dispose);
  if (initialize) {
    await container.read(entitlementStatusProvider.notifier).initialize();
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.light, home: const SettingsPage()),
    ),
  );
  await tester.pump();
  await tester.pump();
  return container;
}

double _top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

void main() {
  group('Hierarchy', () {
    testWidgets('Premium card → billing footer → Preferences → Your data, '
        'with Delete all as the final row', (tester) async {
      await _pump(
        tester,
        _FakeEntitlementGateway(
          offer: Future.value(const MonthlyOffer(localizedPrice: r'$9.99')),
        ),
      );

      final order = [
        'THIRTY Premium',
        'Become Premium',
        'Restore purchases',
        'Preferences',
        'Daily reminder',
        'Appearance',
        'Share anonymous usage data',
        'Your data',
        'Copy as text',
        'Delete all',
      ];
      for (var i = 1; i < order.length; i++) {
        expect(
          _top(tester, order[i]),
          greaterThan(_top(tester, order[i - 1])),
          reason: '${order[i]} below ${order[i - 1]}',
        );
      }

      // Nothing on the page sits below "Delete all".
      final deleteTop = _top(tester, 'Delete all');
      for (final paragraph in find.byType(RichText).evaluate()) {
        final box = paragraph.renderObject! as RenderBox;
        expect(
          box.localToGlobal(Offset.zero).dy,
          lessThanOrEqualTo(deleteTop),
        );
      }
    });

    Color colorOf(WidgetTester tester, String text) =>
        tester.widget<Text>(find.text(text)).style!.color!;
    final colors = AppTheme.light.extension<AppColors>()!;

    testWidgets('Delete all uses the errorText role; Copy as text does not', (
      tester,
    ) async {
      await _pump(tester, _FakeEntitlementGateway(), withJournal: true);
      expect(colorOf(tester, 'Delete all'), colors.errorText);
      expect(colorOf(tester, 'Copy as text'), colors.primary);
    });

    testWidgets('both data actions are disabled with no history', (
      tester,
    ) async {
      await _pump(tester, _FakeEntitlementGateway());
      expect(colorOf(tester, 'Delete all'), colors.textSecondary);
      expect(colorOf(tester, 'Copy as text'), colors.textSecondary);
      expect(
        tester.getSemantics(find.text('Delete all')).flagsCollection.isEnabled,
        isNot(Tristate.isTrue),
      );
    });
  });

  group('Billing-state matrix', () {
    testWidgets('initializing: checking only — no acquisition CTA, no '
        'restore', (tester) async {
      final gateway = _FakeEntitlementGateway();
      await _pump(tester, gateway, initialize: false);

      expect(find.text('Checking your Premium status…'), findsOneWidget);
      expect(find.text('Become Premium'), findsNothing);
      expect(find.text('Restore purchases'), findsNothing);
      expect(gateway.offerCalls, 0);
    });

    testWidgets('inactive + offer: the store\'s own localized price, never '
        'a hardcoded one', (tester) async {
      await _pump(
        tester,
        _FakeEntitlementGateway(
          offer: Future.value(const MonthlyOffer(localizedPrice: r'$9.99')),
        ),
      );

      expect(find.text(r'$9.99 / month'), findsOneWidget);
      expect(find.text('Become Premium'), findsOneWidget);
      expect(find.text('Restore purchases'), findsOneWidget);
      expect(find.textContaining('€'), findsNothing);
      expect(find.textContaining('4.99'), findsNothing);
    });

    testWidgets('inactive + offer still loading: no price text yet, CTA '
        'present', (tester) async {
      final pending = Completer<MonthlyOffer?>();
      await _pump(tester, _FakeEntitlementGateway(offer: pending.future));

      expect(find.textContaining('/ month'), findsNothing);
      expect(find.textContaining('Pricing'), findsNothing);
      expect(find.text('Become Premium'), findsOneWidget);

      pending.complete(const MonthlyOffer(localizedPrice: '£4.49'));
      await tester.pump();
      await tester.pump();
      expect(find.text('£4.49 / month'), findsOneWidget);
    });

    testWidgets('inactive + no offer: a plain note, no price', (tester) async {
      await _pump(tester, _FakeEntitlementGateway());

      expect(find.text('Pricing isn’t available right now.'), findsOneWidget);
      expect(find.textContaining('/ month'), findsNothing);
      expect(find.text('Become Premium'), findsOneWidget);
    });

    testWidgets('active: status and manage, no acquisition, no price, and '
        'the offer is never fetched', (tester) async {
      final gateway = _FakeEntitlementGateway(
        status: EntitlementStatus.active,
        managementUrlValue: 'https://play.google.com/store/account',
      );
      await _pump(tester, gateway);

      expect(find.text('Premium is active'), findsOneWidget);
      expect(find.text('Manage subscription'), findsOneWidget);
      expect(find.text('Become Premium'), findsNothing);
      expect(find.textContaining('/ month'), findsNothing);
      expect(find.text('Restore purchases'), findsOneWidget);
      expect(gateway.offerCalls, 0);
    });

    testWidgets('unavailable: truthful status, no acquisition CTA, restore '
        'still offered', (tester) async {
      await _pump(
        tester,
        _FakeEntitlementGateway(status: EntitlementStatus.unavailable),
      );

      expect(
        find.text('Premium status is temporarily unavailable'),
        findsOneWidget,
      );
      expect(find.text('Become Premium'), findsNothing);
      expect(find.text('Restore purchases'), findsOneWidget);
    });
  });

  group('Billing footer', () {
    testWidgets('restore goes through EntitlementNotifier: a restored '
        'purchase flips the Premium card to active', (tester) async {
      final gateway = _FakeEntitlementGateway()
        ..restoreOutcome = RestoreOutcome.restored
        ..statusAfterRestore = EntitlementStatus.active;
      final container = await _pump(tester, gateway);
      expect(find.text('Become Premium'), findsOneWidget);

      await tester.tap(find.text('Restore purchases'));
      await tester.pumpAndSettle();

      expect(gateway.restoreCalls, 1);
      expect(
        container.read(entitlementStatusProvider),
        EntitlementStatus.active,
      );
      expect(find.text('Premium is active'), findsOneWidget);
      expect(find.text('Become Premium'), findsNothing);
      expect(
        find.text('Your Premium access has been restored.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Restores Premium access only. Your Circle history stays on this '
          'device.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the manage URL is fetched once, not on every rebuild', (
      tester,
    ) async {
      final gateway = _FakeEntitlementGateway(
        status: EntitlementStatus.active,
        managementUrlValue: 'https://play.google.com/store/account',
      );
      final container = await _pump(tester, gateway);

      for (final mode in [ThemeMode.dark, ThemeMode.light, ThemeMode.system]) {
        container.read(themeModeProvider.notifier).setThemeMode(mode);
        await tester.pumpAndSettle();
      }
      expect(gateway.managementUrlCalls, 1);
    });
  });
}
