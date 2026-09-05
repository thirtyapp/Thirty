import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/analytics_event_type.dart';
import '../analytics/analytics_service.dart';
import '../providers/clock_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../routing/app_router.dart';
import '../theme/design_tokens.dart';

/// THIRTY's root widget: wires up theming and routing. Product screens are
/// deliberately out of scope here — see the design system showcase route.
class ThirtyApp extends ConsumerStatefulWidget {
  const ThirtyApp({super.key});

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
      routerConfig: appRouter,
    );
  }
}
