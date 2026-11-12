import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/application/recommendation_provider.dart';
import '../../features/reminder/application/reminder_provider.dart';
import '../analytics/analytics_event_type.dart';
import '../analytics/analytics_service.dart';
import '../l10n/thirty_locales.dart';
import '../premium/premium_access.dart';
import '../providers/clock_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../routing/app_router.dart';
import '../theme/design_tokens.dart';
import '../utils/date_key.dart';

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
    // Audit remediation R8 (Astra R7-A08, Claude F-1): a Circle still under
    // way from before midnight stays on show — Today's own restore keeps it
    // (`RecommendationState.carriesOverMidnightAt`), so the day is re-read
    // here whatever is on screen.
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

  /// Audit remediation R6b (A2-11): an app kept in the foreground across
  /// local midnight notices the new day at the user's first touch after it,
  /// not only on a resume — without swallowing what that touch was for.
  ///
  /// - **Nothing of the old day on show** (no Circle offered yet): the day
  ///   is re-read as the touch begins, so the choice it makes is today's.
  /// - **Otherwise** the touch first does what it was for on the screen
  ///   shown — Start the offered Circle, Keep it, answer its reflection,
  ///   change tab — and the new day opens right after ([_openNewDayIfDue]).
  /// - **Never** while a Circle is running: it keeps its own day until the
  ///   user closes it, and is recorded once, under that day. A Circle
  ///   closed after midnight keeps its reflection on show until that is
  ///   answered.
  bool get _newDay =>
      dateKey(ref.read(eventClockProvider)()) != dateKey(ref.read(nowProvider));

  void _onPointerDown(PointerDownEvent _) {
    if (_newDay && ref.read(recommendationProvider).recommendation == null) {
      ref.invalidate(nowProvider);
    }
  }

  void _onPointerUp(PointerUpEvent _) {
    // A microtask runs once this touch's own handlers have run.
    if (_newDay) scheduleMicrotask(_openNewDayIfDue);
  }

  void _openNewDayIfDue() {
    if (!mounted || !_newDay) return;
    final state = ref.read(recommendationProvider);
    if (state.status == RecommendationStatus.started) return;
    final closedAt = state.closedAt;
    if (state.status == RecommendationStatus.closed &&
        closedAt != null &&
        !state.isOnItsOwnDayAt(closedAt) &&
        !state.reflectionDone) {
      return;
    }
    ref.invalidate(nowProvider);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      child: MaterialApp.router(
        onGenerateTitle: (context) => context.l10n.brandName,
        // ADR-025 (L-INF): English only — every device language resolves to
        // English ([thirtyReleaseLocales]); the words are unchanged.
        localizationsDelegates: thirtyLocalizationsDelegates,
        supportedLocales: thirtyReleaseLocales,
        localeListResolutionCallback: thirtyLocaleListResolution,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        routerConfig: widget.router ?? appRouter,
        builder: widget.builder,
      ),
    );
  }
}
