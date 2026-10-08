import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/reminder/reminder_gateway.dart';
import '../../../core/utils/daypart_greeting.dart';
import '../../home/application/home_invitation_slot.dart';
import '../../home/application/recommendation_provider.dart';
import '../../settings/application/first_name_provider.dart';

/// THIRTY's one local reminder — Step 5 local closure
/// (`docs/product/adr/ADR-017-v1-step5-revenuecat-billing.md`), the
/// already-frozen contract from `THIRTY V1 PRODUCTIZATION + COMMERCIAL
/// REVIEW.md` §27/§28: Free, explicitly opt-in, local, at most one per
/// day. §48 (2026-09-09, "Reminder Return-Ritual Amendment") narrows §27
/// without replacing it: consent stays opt-in, but once enabled the
/// reminder must remain eligible every local calendar day until disabled
/// or permission is lost — reliably, not merely "if the app happens to
/// be reopened" — with next-day eligibility restored automatically even
/// when the app is never launched on that later day.
///
/// [enabled] is the user's own on/off choice; [permissionGranted],
/// [exactAlarmAccessGranted] and [timezoneUnavailable] are separate, live
/// platform truths — Settings shows all of them, exactly as the parent
/// authority requires ("Settings shows the actual permission/schedule
/// state with on/off and one local time"). A user can want reminders
/// (`enabled == true`) while the OS notification permission is denied,
/// while Android's exact-alarm special access hasn't been granted, or
/// while the device's timezone momentarily can't be resolved; nothing
/// here nags them about it more than once, and none of these states is
/// ever silently hidden behind a false "it's working" claim.
class ReminderState {
  const ReminderState({
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.permissionGranted,
    this.exactAlarmAccessGranted = false,
    this.timezoneUnavailable = false,
  });

  final bool enabled;
  final int hour;
  final int minute;
  final bool permissionGranted;

  /// Whether Android's exact-alarm special access (`SCHEDULE_EXACT_ALARM`)
  /// is currently granted. `false` until the first live check resolves
  /// (`ReminderNotifier.initialize`) — see [permissionGranted]'s own
  /// identical bootstrapping. Without this, THIRTY fails closed: no
  /// reminder is scheduled, and it is never silently scheduled inexact
  /// instead (the reproduced Samsung SM-S931B failure this replaces).
  final bool exactAlarmAccessGranted;

  /// `true` only right after a schedule attempt could not resolve the
  /// device's actual local timezone (`ScheduleOutcome.timezoneUnavailable`
  /// — see `local_notifications_reminder_gateway.dart`). Never persisted
  /// — it is live platform truth, re-resolved on every reschedule
  /// attempt, exactly like [permissionGranted].
  final bool timezoneUnavailable;

  ReminderState copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    bool? permissionGranted,
    bool? exactAlarmAccessGranted,
    bool? timezoneUnavailable,
  }) {
    return ReminderState(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      exactAlarmAccessGranted:
          exactAlarmAccessGranted ?? this.exactAlarmAccessGranted,
      timezoneUnavailable: timezoneUnavailable ?? this.timezoneUnavailable,
    );
  }
}

const reminderEnabledKey = 'reminder_enabled_v1';
const reminderHourKey = 'reminder_hour_v1';
const reminderMinuteKey = 'reminder_minute_v1';

/// A sensible pre-filled time shown before the user has ever chosen their
/// own — only meaningful once [ReminderState.enabled] becomes `true`.
const _defaultHour = 20;
const _defaultMinute = 0;

class ReminderNotifier extends Notifier<ReminderState> {
  @override
  ReminderState build() {
    final prefs = ref.watch(sharedPreferencesProvider);

    // React to today's Circle actually starting/closing by re-anchoring
    // the schedule (parent §27: "closing/starting today suppresses an
    // unnecessary later 'start' reminder"). `ref.listen` inside `build()`
    // is the supported Riverpod pattern for reacting to another
    // provider's changes without coupling this notifier's own rebuilds
    // to it — mirrors `entitlementStatusProvider`'s own use of a
    // dedicated `initialize()` rather than a `ref.watch`-driven rebuild.
    ref.listen<RecommendationState>(recommendationProvider, (previous, next) {
      if (previous?.status != next.status) {
        unawaited(_rescheduleIfNeeded());
      }
    });

    // The notification's greeting carries the first name, and a scheduled
    // notification's content is fixed when it is scheduled — so adding,
    // changing or removing the name re-establishes the daily reminder
    // with the same time and settings. With the reminder off this only
    // cancels (a no-op); it never requests a permission.
    ref.listen<String?>(firstNameProvider, (previous, next) {
      if (previous != next) unawaited(_rescheduleIfNeeded());
    });

    return ReminderState(
      enabled: prefs.getBool(reminderEnabledKey) ?? false,
      hour: prefs.getInt(reminderHourKey) ?? _defaultHour,
      minute: prefs.getInt(reminderMinuteKey) ?? _defaultMinute,
      permissionGranted: false,
    );
  }

  /// Resolves the current OS permission truth and, for an already-enabled
  /// reminder, re-anchors its schedule to the device's current local
  /// time/timezone. Called once from `main.dart` at startup and again on
  /// every foreground resume (`thirty_app.dart`) — never a `build()`-time
  /// side effect, matching `EntitlementNotifier`'s own discipline.
  ///
  /// The live permission check itself now lives inside
  /// [_rescheduleIfNeeded] (see its own doc comment) — this method's job
  /// is only to run the one-time plugin setup first.
  Future<void> initialize() async {
    final gateway = ref.read(reminderGatewayProvider);
    await gateway.initialize();
    await _rescheduleIfNeeded();
  }

  /// The user has just elected to enable reminders at [hour]:[minute].
  /// Requests the OS permission — never before this explicit action
  /// (parent §27: "do not request system permission at cold launch").
  /// Denial still records [enabled] as the user's own choice (truthfully
  /// reflected as non-functional via [ReminderState.permissionGranted]
  /// in Settings) rather than silently discarding it.
  Future<void> enable({required int hour, required int minute}) async {
    final gateway = ref.read(reminderGatewayProvider);
    final granted = await gateway.requestPermission();
    state = state.copyWith(
      enabled: true,
      hour: hour,
      minute: minute,
      permissionGranted: granted,
    );
    // Enabling reminders ends the reminder invitation for the rest of this
    // app session — disabling again later in the session never brings it
    // back (session state only; `reminder_invitation_shown_v1` keeps its
    // "was meaningfully visible" meaning).
    ref.read(homeInvitationSlotProvider.notifier).closeReminderForSession();
    await _persist();
    await _rescheduleIfNeeded();
  }

  /// Turns the reminder off and cancels any pending scheduled work.
  Future<void> disable() async {
    if (!state.enabled) return;
    state = state.copyWith(enabled: false);
    await _persist();
    await ref.read(reminderGatewayProvider).cancel();
  }

  /// Changes the reminder time without otherwise touching [enabled] or
  /// [permissionGranted]. Re-anchoring (never duplicating — a single
  /// canonical notification id is always cancelled before rescheduling)
  /// happens only if the reminder is actually active.
  Future<void> setTime({required int hour, required int minute}) async {
    state = state.copyWith(hour: hour, minute: minute);
    await _persist();
    await _rescheduleIfNeeded();
  }

  /// Re-checks the live OS permission state (e.g. the user may have
  /// changed it from system settings while THIRTY was backgrounded) and
  /// reconciles the schedule accordingly. [_rescheduleIfNeeded] now does
  /// this check itself, so this is a thin, stable public name for it.
  Future<void> refreshPermission() async {
    await _rescheduleIfNeeded();
  }

  /// Sends the user to Android's exact-alarm special-access screen. The
  /// caller (Settings) must have already shown THIRTY's own calm
  /// explanation *before* calling this — this method itself performs no
  /// UI and must only ever run from that explicit user action, never at
  /// cold launch and never merely because Settings was opened.
  ///
  /// The system screen does not hand back a result THIRTY can await, so
  /// this also re-checks live access immediately afterward (covering an
  /// OS that resolves synchronously); `ThirtyApp`'s own foreground-resume
  /// hook (`ReminderNotifier.initialize`) is what reliably catches the
  /// far more common case of the user returning to THIRTY after leaving
  /// it to decide in system Settings.
  Future<void> requestExactAlarmAccess() async {
    final gateway = ref.read(reminderGatewayProvider);
    await gateway.requestExactAlarmAccess();
    await _rescheduleIfNeeded();
  }

  Future<void> _persist() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(reminderEnabledKey, state.enabled);
    await prefs.setInt(reminderHourKey, state.hour);
    await prefs.setInt(reminderMinuteKey, state.minute);
  }

  /// The one place that decides whether THIRTY's reminder should currently
  /// be scheduled, and for when.
  ///
  /// **Cancels the previously-armed alarm first, unconditionally, before
  /// anything else** — never "check → compute → eventually cancel/
  /// reschedule". This method is invoked `unawaited` from a synchronous
  /// `ref.listen` callback ([build]'s own listener on [recommendationProvider],
  /// most importantly the Close transition), so the calling code never
  /// waits for it to finish; if the OS kills this process partway through,
  /// the safest possible partial outcome is "today's alarm is already
  /// gone, tomorrow's was never armed" — never "today's stale alarm
  /// survives because cancellation was still waiting behind a permission
  /// check". The same fail-closed bias already governs
  /// [ScheduleOutcome.timezoneUnavailable] elsewhere in this gateway;
  /// re-arming the next occurrence below remains best-effort.
  ///
  /// Re-checks the *live* OS permission via [ReminderGateway.hasPermission]
  /// itself, rather than trusting [ReminderState.permissionGranted] —
  /// that field starts at a hardcoded `false` in [build] and is normally
  /// only corrected once [initialize]'s own async permission check
  /// resolves. Reading it here instead of that field closes a real race:
  /// the `ref.listen` in [build] is wired up synchronously the moment this
  /// notifier is first read, before [initialize]'s awaits have completed,
  /// so a `recommendationProvider` status change landing in that narrow
  /// window would previously see the stale default `false` and wrongly
  /// [ReminderGateway.cancel] an already-armed reminder it had no real
  /// reason to touch — cancelling first, above, is harmless either way,
  /// since a correct re-arm always follows immediately when one is due.
  Future<void> _rescheduleIfNeeded() async {
    final gateway = ref.read(reminderGatewayProvider);

    await gateway.cancel();

    if (!state.enabled) {
      state = state.copyWith(timezoneUnavailable: false);
      return;
    }

    final granted = await gateway.hasPermission();
    state = state.copyWith(permissionGranted: granted);
    if (!granted) {
      state = state.copyWith(timezoneUnavailable: false);
      return;
    }

    // Same fail-closed shape as the notification-permission check above:
    // without live exact-alarm access, nothing is scheduled — never a
    // silent fallback to inexact scheduling (the reproduced Samsung
    // SM-S931B failure this whole gate exists to prevent).
    final exactGranted = await gateway.hasExactAlarmAccess();
    state = state.copyWith(exactAlarmAccessGranted: exactGranted);
    if (!exactGranted) {
      state = state.copyWith(timezoneUnavailable: false);
      return;
    }

    final now = ref.read(eventClockProvider)();
    final todayResolved =
        ref.read(recommendationProvider).status != RecommendationStatus.notStarted;
    final firstOccurrence = _nextOccurrence(
      now,
      state.hour,
      state.minute,
      suppressToday: todayResolved,
    );
    final outcome = await gateway.scheduleDaily(
      firstOccurrenceLocal: firstOccurrence,
      hour: state.hour,
      minute: state.minute,
      title: reminderNotificationTitle(
        hour: state.hour,
        minute: state.minute,
        firstName: ref.read(firstNameProvider),
      ),
      body: reminderNotificationBody,
    );
    state = state.copyWith(
      timezoneUnavailable: outcome == ScheduleOutcome.timezoneUnavailable,
      // Reconciles the rare race where access is revoked between the live
      // check above and this call — the gateway independently refused to
      // schedule (`local_notifications_reminder_gateway.dart`'s own
      // fail-closed check), so state must reflect that truthfully too.
      exactAlarmAccessGranted: outcome != ScheduleOutcome.exactAlarmAccessDenied,
    );
  }
}

/// The next local wall-clock moment [hour]:[minute] should fire, given
/// [now] — today, unless [suppressToday] (today's Circle already
/// started/closed) or [hour]:[minute] has already passed today, in which
/// case tomorrow. Exposed at top level (not a private method) so
/// `reminder_provider_test.dart` can verify this pure calculation
/// directly, independent of provider/gateway wiring.
/// The daily reminder's title: THIRTY's daypart greeting for the time the
/// reminder fires ([hour]:[minute] — never the moment it was scheduled),
/// with the first name when there is one: "Good evening, Thomas." or
/// "Good evening.". The name is the only personal detail a notification
/// ever shows.
String reminderNotificationTitle({
  required int hour,
  required int minute,
  String? firstName,
}) => daypartGreeting(DateTime(2000, 1, 1, hour, minute), firstName: firstName);

/// The daily reminder's body — the same every day, with nothing from the
/// user's history in it.
const reminderNotificationBody = "Your Circle is here when you're ready.";

DateTime nextReminderOccurrence(
  DateTime now,
  int hour,
  int minute, {
  required bool suppressToday,
}) {
  var candidate = DateTime(now.year, now.month, now.day, hour, minute);
  if (suppressToday || !candidate.isAfter(now)) {
    candidate = candidate.add(const Duration(days: 1));
  }
  return candidate;
}

DateTime _nextOccurrence(
  DateTime now,
  int hour,
  int minute, {
  required bool suppressToday,
}) => nextReminderOccurrence(now, hour, minute, suppressToday: suppressToday);

final reminderProvider = NotifierProvider<ReminderNotifier, ReminderState>(
  ReminderNotifier.new,
);
