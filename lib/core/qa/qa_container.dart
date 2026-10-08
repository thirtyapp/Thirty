import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../analytics/analytics_service.dart';
import '../premium/entitlement_gateway.dart';
import '../providers/shared_preferences_provider.dart';
import '../providers/supabase_availability_provider.dart';
import '../reminder/reminder_gateway.dart';
import 'qa_entitlement_gateway.dart';
import 'qa_inert_services.dart';
import 'qa_scenario.dart';

/// QA-1 — the provider overrides for the harness's app container.
///
/// With no [session] these are exactly `main.dart`'s production overrides:
/// the genuine store, and every other provider — the RevenueCat-or-
/// unavailable `entitlementGatewayProvider` included — left at its
/// production default. With a [session], the whole container is
/// substituted in one place: the session's isolated store, its fixed
/// entitlement gateway, and no telemetry or real reminder scheduling.
List<Override> qaContainerOverrides({
  required SharedPreferences genuinePreferences,
  required bool supabaseAvailable,
  QaSession? session,
}) => [
  if (session == null) ...[
    sharedPreferencesProvider.overrideWithValue(genuinePreferences),
    supabaseAvailableProvider.overrideWithValue(supabaseAvailable),
  ] else ...[
    sharedPreferencesProvider.overrideWithValue(session.store),
    supabaseAvailableProvider.overrideWithValue(false),
    entitlementGatewayProvider.overrideWithValue(
      QaEntitlementGateway(session.entitlement.status),
    ),
    analyticsServiceProvider.overrideWithValue(
      const QaSilentAnalyticsService(),
    ),
    reminderGatewayProvider.overrideWithValue(const QaInertReminderGateway()),
  ],
];
