import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/analytics/analytics_consent.dart';
import 'package:thirty/core/premium/entitlement_gateway.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/providers/theme_mode_provider.dart';
import 'package:thirty/core/reminder/reminder_gateway.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/features/reminder/application/reminder_provider.dart';
import 'package:thirty/features/settings/presentation/settings_page.dart';
import 'package:thirty/features/settings/presentation/widgets/you_premium_card.dart';
import 'package:thirty/core/widgets/thirty_card.dart';

class _FakeReminderGateway implements ReminderGateway {
  bool permissionGranted = true;
  bool exactAlarmAccessGranted = true;
  ScheduleOutcome scheduleOutcome = ScheduleOutcome.scheduled;
  int scheduleCallCount = 0;
  int cancelCallCount = 0;
  int requestExactAlarmAccessCallCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<bool> hasPermission() async => permissionGranted;

  @override
  Future<bool> hasExactAlarmAccess() async => exactAlarmAccessGranted;

  @override
  Future<void> requestExactAlarmAccess() async {
    requestExactAlarmAccessCallCount++;
  }

  @override
  Future<ScheduleOutcome> scheduleDaily({
    required DateTime firstOccurrenceLocal,
    required int hour,
    required int minute,
  }) async {
    if (!exactAlarmAccessGranted) return ScheduleOutcome.exactAlarmAccessDenied;
    scheduleCallCount++;
    return scheduleOutcome;
  }

  @override
  Future<void> cancel() async {
    cancelCallCount++;
  }
}

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
  _FakeReminderGateway? reminderGateway,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final resolvedPrefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      entitlementGatewayProvider.overrideWithValue(gateway),
      sharedPreferencesProvider.overrideWithValue(resolvedPrefs),
      reminderGatewayProvider.overrideWithValue(
        reminderGateway ?? _FakeReminderGateway(),
      ),
    ],
  );
  await container.read(entitlementStatusProvider.notifier).initialize();
  final widget = UncontrolledProviderScope(
    container: container,
    child: MaterialApp(theme: AppTheme.light, home: const SettingsPage()),
  );
  return (widget, container);
}

/// The Switch inside one of You's keyed Preferences rows.
Finder _switchIn(String rowKey) => find.descendant(
  of: find.byKey(ValueKey(rowKey)),
  matching: find.byType(Switch),
);

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

  testWidgets('shows the THIRTY Premium card with a "Become Premium" entry '
      'when inactive (Phase C1 copy)', (tester) async {
    final gateway = _FakeEntitlementGateway(
      initialStatus: EntitlementStatus.inactive,
    );
    final (widget, container) = await _wrap(gateway: gateway);
    addTearDown(container.dispose);

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(find.text('THIRTY Premium'), findsOneWidget);
    expect(find.text('Become Premium'), findsOneWidget);
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
    // Restore is You's last section (North Star order) — scroll to it.
    await tester.scrollUntilVisible(find.text('Restore purchases'), 200);
    await tester.ensureVisible(find.text('Restore purchases'));
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
    // Restore is You's last section (North Star order) — scroll to it.
    await tester.scrollUntilVisible(find.text('Restore purchases'), 200);
    await tester.ensureVisible(find.text('Restore purchases'));
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
    // Restore is You's last section (North Star order) — scroll to it.
    await tester.scrollUntilVisible(find.text('Restore purchases'), 200);
    await tester.ensureVisible(find.text('Restore purchases'));
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

  testWidgets(
    'exposes inline export/delete data controls under "Data & '
    'privacy" — founder IA correction: these live directly on "You" now, '
    'not behind a link to the retired primary Journal tab',
    (tester) async {
      final gateway = _FakeEntitlementGateway();
      final (widget, container) = await _wrap(gateway: gateway);
      addTearDown(container.dispose);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      // The Settings list has grown past the default test viewport + cache
      // extent since Appearance/Analytics were added — scroll to bring this
      // card into the mounted range before asserting on it.
      await tester.scrollUntilVisible(find.text('Delete Circle history'), 200);

      expect(find.text('Data & privacy'), findsOneWidget);
      expect(find.text('Copy as text'), findsOneWidget);
      expect(find.text('Delete Circle history'), findsOneWidget);
      expect(find.text('Your data'), findsNothing);
      expect(find.text('Delete all'), findsNothing);
    },
  );

  testWidgets(
    'exposes the real System/Light/Dark theme control, reflecting and '
    'updating the actual themeModeProvider the app renders with',
    (tester) async {
      final gateway = _FakeEntitlementGateway();
      final (widget, container) = await _wrap(gateway: gateway);
      addTearDown(container.dispose);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(container.read(themeModeProvider), ThemeMode.system);

      await tester.ensureVisible(find.text('Dark'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(container.read(themeModeProvider), ThemeMode.dark);
    },
  );

  testWidgets(
    'exposes an analytics consent toggle, defaulting to off and updating '
    'the real analyticsConsentProvider the app reads before transmitting '
    'anything',
    (tester) async {
      final gateway = _FakeEntitlementGateway();
      final (widget, container) = await _wrap(gateway: gateway);
      addTearDown(container.dispose);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(container.read(analyticsConsentProvider), isFalse);
      expect(find.text('Share anonymous usage data'), findsOneWidget);

      await tester.ensureVisible(_switchIn('you.analytics'));
      await tester.pumpAndSettle();
      await tester.tap(_switchIn('you.analytics'));
      await tester.pumpAndSettle();

      expect(container.read(analyticsConsentProvider), isTrue);
    },
  );

  testWidgets(
    'reminder off by default; enabling it opens the time picker and '
    'requests permission only at that point',
    (tester) async {
      final reminderGateway = _FakeReminderGateway();
      final (widget, container) = await _wrap(
        gateway: _FakeEntitlementGateway(),
        reminderGateway: reminderGateway,
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Daily reminder'), 200);
      // The whole row (switch and its action), not just its title, below
      // the You header band.
      await tester.ensureVisible(find.byKey(const ValueKey('you.reminder')));
      await tester.pumpAndSettle();

      expect(container.read(reminderProvider).enabled, isFalse);

      await tester.tap(_switchIn('you.reminder'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(container.read(reminderProvider).enabled, isTrue);
      expect(reminderGateway.scheduleCallCount, greaterThan(0));
    },
  );

  testWidgets(
    'shows a truthful message when permission is denied, without a '
    'repeated permission-request loop',
    (tester) async {
      final reminderGateway = _FakeReminderGateway()..permissionGranted = false;
      final (widget, container) = await _wrap(
        gateway: _FakeEntitlementGateway(),
        reminderGateway: reminderGateway,
        prefs: {reminderEnabledKey: true},
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Daily reminder'), 200);
      // The whole row (switch and its action), not just its title, below
      // the You header band.
      await tester.ensureVisible(find.byKey(const ValueKey('you.reminder')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Notifications are turned off for THIRTY'),
        findsOneWidget,
      );
    },
  );

  testWidgets('disabling the reminder cancels pending work', (tester) async {
    final reminderGateway = _FakeReminderGateway();
    final (widget, container) = await _wrap(
      gateway: _FakeEntitlementGateway(),
      reminderGateway: reminderGateway,
      prefs: {reminderEnabledKey: true},
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Daily reminder'), 200);
    // The whole row (switch and its action), not just its title, below
    // the You header band.
    await tester.ensureVisible(find.byKey(const ValueKey('you.reminder')));
    await tester.pumpAndSettle();

    await tester.tap(_switchIn('you.reminder'));
    await tester.pumpAndSettle();

    expect(container.read(reminderProvider).enabled, isFalse);
    expect(reminderGateway.cancelCallCount, greaterThan(0));
  });

  testWidgets(
    'shows a truthful "Android access needed" message with an "Allow '
    'access" action when notification permission is granted but '
    'exact-alarm access is not — never silently scheduled inexact',
    (tester) async {
      final reminderGateway = _FakeReminderGateway()
        ..exactAlarmAccessGranted = false;
      final (widget, container) = await _wrap(
        gateway: _FakeEntitlementGateway(),
        reminderGateway: reminderGateway,
        prefs: {reminderEnabledKey: true},
      );
      addTearDown(container.dispose);
      // Resolves the live notification-permission truth (default `true`
      // on the fake) from the `build()`-time hardcoded `false` — exactly
      // like the timezone-unavailable test below.
      await container.read(reminderProvider.notifier).initialize();

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Daily reminder'), 200);
      // The whole row (switch and its action), not just its title, below
      // the You header band.
      await tester.ensureVisible(find.byKey(const ValueKey('you.reminder')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Android access is needed'),
        findsOneWidget,
      );
      expect(find.text('Allow access'), findsOneWidget);
      expect(find.text('Change time'), findsNothing);
      expect(reminderGateway.scheduleCallCount, 0);

      // Tapping shows THIRTY's own calm explanation first — never leaves
      // the app before that.
      await tester.tap(find.text('Allow access'));
      await tester.pumpAndSettle();
      expect(find.text('Allow Alarms & reminders'), findsOneWidget);
      expect(reminderGateway.requestExactAlarmAccessCallCount, 0);

      // Confirming from that dialog is what actually invokes the platform
      // request — and, once access is granted, re-checking live makes the
      // reminder become active.
      reminderGateway.exactAlarmAccessGranted = true;
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(reminderGateway.requestExactAlarmAccessCallCount, 1);
      expect(container.read(reminderProvider).exactAlarmAccessGranted, isTrue);
      expect(reminderGateway.scheduleCallCount, greaterThan(0));
      expect(find.textContaining('Reminds you at'), findsOneWidget);
    },
  );

  testWidgets(
    'shows a truthful message when the device timezone cannot be '
    'resolved, without ever claiming the reminder is scheduled',
    (tester) async {
      final reminderGateway = _FakeReminderGateway()
        ..scheduleOutcome = ScheduleOutcome.timezoneUnavailable;
      final (widget, container) = await _wrap(
        gateway: _FakeEntitlementGateway(),
        reminderGateway: reminderGateway,
        prefs: {reminderEnabledKey: true},
      );
      addTearDown(container.dispose);
      await container.read(reminderProvider.notifier).initialize();

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Daily reminder'), 200);
      // The whole row (switch and its action), not just its title, below
      // the You header band.
      await tester.ensureVisible(find.byKey(const ValueKey('you.reminder')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('we couldn\'t confirm your device\'s timezone'),
        findsOneWidget,
      );
      expect(find.textContaining('Reminds you at'), findsNothing);
    },
  );

  testWidgets('Phase C1 — Premium card and grouped rows share one content '
      'inset (the 8pt mismatch A2 recorded is gone)', (tester) async {
    // North Star: the Premium card's text sits beside its mark, and each
    // row's beside its icon — so the shared edge is the card content's:
    // the Premium body line and the rows' leading icons.
    final (widget, container) = await _wrap(gateway: _FakeEntitlementGateway());
    addTearDown(container.dispose);

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final cards = tester
        .widgetList<ThirtyCard>(find.byType(ThirtyCard, skipOffstage: false))
        .toList();
    expect(cards.first.padding, const EdgeInsets.all(AppSpacing.featuredCard));
    for (final group in cards.skip(1)) {
      expect(
        (group.padding! as EdgeInsets).left,
        AppSpacing.featuredCard,
      );
    }
    expect(
      tester.getTopLeft(find.text(YouPremiumCard.body)).dx,
      tester.getTopLeft(find.byIcon(Icons.notifications_none_outlined)).dx,
    );
  });
}
