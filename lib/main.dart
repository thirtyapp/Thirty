import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app/thirty_app.dart';
import 'core/config/supabase_config.dart';
import 'core/premium/premium_access.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'core/providers/supabase_availability_provider.dart';
import 'core/qa/qa_premium_gate.dart';
import 'core/qa/qa_premium_harness.dart';
import 'features/reminder/application/reminder_provider.dart';
import 'features/toolkit/application/v1_premium_retirement.dart';

/// ADR-013 §8 — optional analytics must never own the local product's own
/// startup availability. Missing configuration (`!config.isConfigured`)
/// and a reachability/network failure inside `Supabase.initialize` itself
/// (e.g. no connectivity at cold start) are both non-fatal for the same
/// reason: Supabase backs only the one narrow, consent-gated analytics path
/// (`analytics_service.dart`), never the Free product. Either way this
/// resolves to `false` and `runApp` still runs — never throws.
Future<bool> initializeSupabaseIfConfigured(SupabaseConfig config) async {
  if (!config.isConfigured) return false;
  try {
    await Supabase.initialize(
      url: config.url,
      publishableKey: config.publishableKey,
    );
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const config = SupabaseConfig.fromEnvironment;
  final supabaseAvailable = await initializeSupabaseIfConfigured(config);

  final sharedPreferences = await SharedPreferences.getInstance();
  // V2 Phase D: V1 Plans and Insights are retired before anything reads
  // the store (once; idempotent).
  await retireV1Premium(sharedPreferences);

  // QA-1: a debug build launched with THIRTY_QA_PREMIUM=true runs the
  // Premium QA harness instead. Compile-time false in profile and release.
  if (kQaPremiumHarnessEnabled) {
    runApp(
      QaPremiumHarnessApp(
        genuinePreferences: sharedPreferences,
        supabaseAvailable: supabaseAvailable,
      ),
    );
    return;
  }

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      supabaseAvailableProvider.overrideWithValue(supabaseAvailable),
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
