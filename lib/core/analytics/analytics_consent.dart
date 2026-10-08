import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/shared_preferences_provider.dart';

/// SharedPreferences key for THIRTY's local analytics-consent choice —
/// Step 5 local closure (`docs/product/adr/ADR-017-v1-step5-revenuecat-billing.md`).
///
/// The parent authority (`THIRTY V1 PRODUCTIZATION + COMMERCIAL
/// REVIEW.md` §28) requires: "analytics off until the user chooses the
/// proposed opt-in setting... Do not bundle analytics consent with
/// reminders or purchases." [analyticsConsentProvider] is the sole
/// source of truth `analyticsServiceProvider`
/// (`analytics_service.dart`'s `ConsentGatedAnalyticsService`) reads
/// before ever attempting to transmit an event — no other call site
/// needs to check this itself.
const analyticsConsentKey = 'analytics_consent_v1';

/// Whether THIRTY may transmit analytics events right now. **Defaults to
/// `false`** — no event is ever sent before the user explicitly opts in,
/// and enabling only ever affects events tracked from that point forward
/// (this app keeps no queue of dropped pre-consent events to later
/// flush, so there is nothing to backfill).
class AnalyticsConsentNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(analyticsConsentKey) ?? false;
  }

  /// Sets the user's explicit analytics choice. Independent of reminder
  /// permission and of Premium entitlement state — neither this app nor
  /// any of its billing/reminder code paths ever calls this on the
  /// user's behalf.
  void setConsent(bool value) {
    if (state == value) return;
    state = value;
    unawaited(
      ref.read(sharedPreferencesProvider).setBool(analyticsConsentKey, value),
    );
  }
}

final analyticsConsentProvider =
    NotifierProvider<AnalyticsConsentNotifier, bool>(
      AnalyticsConsentNotifier.new,
    );
