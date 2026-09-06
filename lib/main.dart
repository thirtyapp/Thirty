import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app/thirty_app.dart';
import 'core/config/supabase_config.dart';
import 'core/premium/premium_access.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'features/reminder/application/reminder_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const config = SupabaseConfig.fromEnvironment;
  config.assertValid();

  // ADR-013 §8 — optional analytics must never own the local product's own
  // startup availability. `config.assertValid()` above still fails fast on
  // a genuine developer misconfiguration (a missing URL/key), but a
  // reachability/network failure inside `Supabase.initialize` itself (e.g.
  // no connectivity at cold start) must not prevent `runApp` from ever
  // running. `AnalyticsService.track` (`analytics_service.dart`) already
  // tolerates `Supabase.instance` never having been successfully
  // initialized — its own `_send` swallows exactly this failure mode.
  try {
    await Supabase.initialize(
      url: config.url,
      publishableKey: config.publishableKey,
    );
  } catch (_) {
    // Deliberately swallowed — see comment above.
  }

  final sharedPreferences = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
    ],
  );

  // Fire-and-forget: Free must stay immediately usable regardless of
  // billing/network state (frozen architecture §7), so entitlement
  // resolution never blocks the first frame. `EntitlementNotifier`
  // resolves to `unavailable` on any configuration/SDK failure rather
  // than throwing, so this is never an unhandled error either.
  unawaited(container.read(entitlementStatusProvider.notifier).initialize());
  // Same fire-and-forget discipline: a reminder-scheduling failure must
  // never block the first frame or affect the rest of the app (parent
  // §27's own failure behavior — see `ReminderGateway`'s doc comment).
  unawaited(container.read(reminderProvider.notifier).initialize());

  runApp(
    UncontrolledProviderScope(container: container, child: const ThirtyApp()),
  );
}
