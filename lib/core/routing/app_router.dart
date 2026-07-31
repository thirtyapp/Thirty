import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_page.dart';
import '../providers/theme_mode_provider.dart';
import '../showcase/design_system_showcase_page.dart';

/// THIRTY's single, shared router configuration. Created once at module
/// load and reused for the app's lifetime — never rebuilt from a widget's
/// build method.
///
/// `/showcase` is an internal developer route for reviewing the design
/// system; it is reachable only by navigating to it directly, not linked
/// from any product screen.
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(
      path: '/showcase',
      builder: (context, state) {
        return Consumer(
          builder: (context, ref, _) {
            return DesignSystemShowcasePage(
              themeMode: ref.watch(themeModeProvider),
              onThemeModeChanged: (mode) =>
                  ref.read(themeModeProvider.notifier).setThemeMode(mode),
            );
          },
        );
      },
    ),
  ],
);
