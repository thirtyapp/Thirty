import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_mode_provider.dart';
import '../routing/app_router.dart';
import '../theme/design_tokens.dart';

/// THIRTY's root widget: wires up theming and routing. Product screens are
/// deliberately out of scope here — see the design system showcase route.
class ThirtyApp extends ConsumerWidget {
  const ThirtyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
