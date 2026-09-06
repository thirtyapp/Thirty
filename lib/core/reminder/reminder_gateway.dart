import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_notifications_reminder_gateway.dart';

/// THIRTY's one seam onto local notification scheduling — Step 5 local
/// closure (`docs/product/adr/ADR-017-v1-step5-revenuecat-billing.md`).
/// `flutter_local_notifications` is the one approved package for this;
/// this interface exists only so [reminderGatewayProvider] can be
/// overridden with a deterministic fake in tests — exactly the
/// `entitlementGatewayProvider`/`sharedPreferencesProvider` convention
/// already used throughout this codebase — never as a hypothetical
/// multi-provider abstraction.
///
/// Every method must never throw — a scheduling/permission failure fails
/// closed (no reminder fires) without ever affecting the rest of the app,
/// exactly like [EntitlementGateway]'s own contract.
abstract class ReminderGateway {
  /// One-time plugin/timezone-database setup. Safe to call more than
  /// once (idempotent).
  Future<void> initialize();

  /// Requests the platform notification permission (Android 13+), and
  /// returns whether it is granted afterward. Must only ever be called
  /// after the user has explicitly elected to enable reminders — never
  /// at cold launch (frozen architecture / parent §27).
  Future<bool> requestPermission();

  /// Whether the notification permission is currently granted, without
  /// prompting the user.
  Future<bool> hasPermission();

  /// (Re)establishes THIRTY's one daily reminder, cancelling any
  /// previous schedule first (a single canonical notification id is
  /// reused throughout this gateway, so this is inherently
  /// non-duplicating). [firstOccurrenceLocal] is the next wall-clock
  /// moment (in the device's current local time) the reminder should
  /// fire; the underlying OS schedule then repeats daily at
  /// [hour]:[minute] from that point on.
  Future<void> scheduleDaily({
    required DateTime firstOccurrenceLocal,
    required int hour,
    required int minute,
  });

  /// Cancels THIRTY's scheduled reminder, if any. A no-op if none is
  /// currently scheduled.
  Future<void> cancel();
}

/// Production default. Tests must override this provider with a fake
/// rather than relying on this resolving safely — unlike the billing
/// seam, there is no external "unconfigured" state to fall back to here
/// (no API key involved), so nothing about this provider itself prevents
/// a test from reaching the real plugin if it calls gateway methods
/// without overriding first. `ReminderNotifier.build()` (`reminder_provider.dart`)
/// never does so — only explicit `initialize()`/action calls do, called
/// only from `main.dart` or real user interaction.
final reminderGatewayProvider = Provider<ReminderGateway>(
  (ref) => LocalNotificationsReminderGateway(),
);
