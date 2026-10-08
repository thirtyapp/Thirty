import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/reminder/application/reminder_provider.dart';
import '../analytics/analytics_event_type.dart';
import '../analytics/analytics_service.dart';
import '../premium/premium_access.dart';
import '../providers/clock_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../routing/app_router.dart';
import '../theme/design_tokens.dart';

/// THIRTY's root widget: wires up theming and routing. Product screens are
/// deliberately out of scope here — see the design system showcase route.
class ThirtyApp extends ConsumerStatefulWidget {
  const ThirtyApp({super.key, this.builder, this.router});

  /// Passed to [MaterialApp.router]'s `builder` — `null` in production; only
  /// the debug-only QA-1 harness (`../qa/qa_premium_harness.dart`) uses it,
  /// to draw its marker over every screen.
  final TransitionBuilder? builder;

  /// The router to use — `null` in production, meaning the shared
  /// [appRouter]; only the debug-only QA-1 harness passes a fresh one per
  /// QA session.
  final GoRouter? router;

  @override
  ConsumerState<ThirtyApp> createState() => _ThirtyAppState();
}

/// A [WidgetsBindingObserver] purely for Batch 1's daily-reset legibility
/// fix (Phase D) and its app-open instrumentation (Phase E) — nothing else
/// about the app's structure changes here.
///
/// [nowProvider] is deliberately cached once per container lifetime
/// (`clock_provider.dart`'s own doc comment), so an app instance kept alive
/// across local midnight — the overwhelmingly common real path being
/// "backgrounded overnight, reopened the next morning without being fully
/// killed" — would otherwise keep showing yesterday's Circle lifecycle
/// until something else happened to rebuild it. Invalidating [nowProvider]
/// on every foreground resume closes that gap using the app's existing,
/// natural resume signal — no new timer or scheduling architecture.
class _ThirtyAppState extends ConsumerState<ThirtyApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _trackAppOpened();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    ref.invalidate(nowProvider);
    _trackAppOpened();
    // Step 5: re-resolve verified entitlement state on every foreground
    // resume (frozen architecture §17's "app restart, lifecycle refresh")
    // — a cancellation, expiry or recovery that happened while THIRTY was
    // backgrounded must be reflected without requiring a cold restart.
    // Fire-and-forget for the same reason as `main.dart`'s initial call:
    // this must never block resume, and failures already resolve to
    // `EntitlementStatus.unavailable` rather than throwing.
    unawaited(ref.read(entitlementStatusProvider.notifier).initialize());
    // Step 5 local closure: re-anchor the reminder schedule to the
    // device's current local time/timezone and re-check the live OS
    // permission on every resume — see `ReminderNotifier.initialize`'s
    // own doc comment and `LocalNotificationsReminderGateway`'s "known
    // limitation" note on why this specific resume hook matters for DST.
    unawaited(ref.read(reminderProvider.notifier).initialize());
  }

  /// "First observed app use" (never "install" — this app cannot observe
  /// an actual install) is derived later as the earliest `app_opened` row
  /// per tester; every later distinct calendar day this fires on is what
  /// lets a second-distinct-day return be derived too (Phase E).
  void _trackAppOpened() {
    ref.read(analyticsServiceProvider).track(AnalyticsEventType.appOpened);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'THIRTY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: widget.router ?? appRouter,
      builder: widget.builder,
    );
  }
}
