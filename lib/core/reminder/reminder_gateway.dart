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
///
/// [ScheduleOutcome.timezoneUnavailable] exists specifically so a failure
/// to resolve the device's actual local timezone is never silently
/// swallowed into "scheduled" — the frozen contract requires the user's
/// chosen wall-clock time to be preserved correctly across timezone/DST
/// changes, so scheduling against a wrong/default zone would be a
/// truthfulness defect, not an acceptable fallback.
enum ScheduleOutcome {
  /// Scheduled against the device's actual resolved local timezone, using
  /// exact-while-idle timing.
  scheduled,

  /// The device's local timezone could not be resolved — nothing was
  /// scheduled. The caller must surface this truthfully (never claim the
  /// reminder is active) and must never fall back to a wrong timezone.
  timezoneUnavailable,

  /// Android's exact-alarm special access (`SCHEDULE_EXACT_ALARM`) is not
  /// currently granted — nothing was scheduled. A reproduced physical
  /// failure (a correctly `inexactAllowWhileIdle`-scheduled 18:05 reminder
  /// twice actually delivered ~03:48 the next local day) is why THIRTY
  /// never falls back to an inexact schedule here: the caller must
  /// surface this truthfully as "Android access needed", exactly like
  /// [timezoneUnavailable].
  exactAlarmAccessDenied,

  /// Some other scheduling failure occurred.
  failed,
}

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

  /// Whether Android's exact-alarm special access (`SCHEDULE_EXACT_ALARM`)
  /// is currently granted, without prompting the user. On a platform
  /// without this concept, resolves the same conservative default
  /// [hasPermission] itself already uses there.
  Future<bool> hasExactAlarmAccess();

  /// Sends the user to the platform's exact-alarm special-access screen.
  /// Must only ever be called after the user has explicitly elected to
  /// enable reminders, and only after THIRTY's own calm explanation has
  /// been shown — never at cold launch and never merely because Settings
  /// was opened (same discipline as [requestPermission]). Does not itself
  /// resolve whether access was actually granted — the caller must
  /// re-check [hasExactAlarmAccess] once the user returns to the app.
  Future<void> requestExactAlarmAccess();

  /// (Re)establishes THIRTY's one daily reminder, cancelling any
  /// previous schedule first (a single canonical notification id is
  /// reused throughout this gateway, so this is inherently
  /// non-duplicating). [firstOccurrenceLocal] is the next wall-clock
  /// moment (in the device's current local time) the reminder should
  /// fire; the underlying OS schedule then repeats daily at
  /// [hour]:[minute] — in the device's actual resolved local timezone,
  /// preserving that wall-clock time correctly across DST — from that
  /// point on — including when [firstOccurrenceLocal] deliberately skips a
  /// still-upcoming [hour]:[minute] today, and without the app being
  /// opened again. [title] and [body] are the notification's whole visible
  /// content — composed by the caller, never by the gateway.
  Future<ScheduleOutcome> scheduleDaily({
    required DateTime firstOccurrenceLocal,
    required int hour,
    required int minute,
    required String title,
    required String body,
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
