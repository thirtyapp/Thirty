import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/premium/premium_access.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/thirty_app_bar.dart';
import '../../../core/widgets/thirty_button.dart';
import '../../home/application/activity_catalog.dart';
import '../../home/application/recommendation_provider.dart';
import '../../home/application/suggestion_preferences.dart';
import '../../home/domain/recommendation_engine.dart';
import '../../home/domain/recommendation_policy.dart';
import '../application/toolkit_provider.dart';
import '../domain/module_library.dart';
import '../domain/path_catalog.dart';
import '../domain/path_engine.dart';
import '../domain/toolkit_model.dart';
import 'toolkit_page.dart';
import 'widgets/toolkit_parts.dart';

/// One Path before it starts: what it builds, the pieces it works with, how
/// it goes, and — honestly — whether anything about it is based on the
/// user's own answers yet.
class PathStartPage extends ConsumerWidget {
  const PathStartPage({required this.template, super.key});

  final PathTemplateId template;

  static const pathPattern = '/toolkit/paths/:template';
  static String locationFor(PathTemplateId id) => '/toolkit/paths/${id.name}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final path = pathTemplate(template);
    final entitled = ref.watch(premiumEntitlementProvider);
    final toolkit = ref.watch(toolkitProvider);
    final preferences = ref.watch(suggestionPreferencesProvider);
    final seed = seedBuild(
      path,
      RecommendationMemory.of(
        ref.watch(nowProvider),
        ref.watch(toolkitHistoryProvider),
        RecommendationPolicy.initial,
        restsLifted: preferences.controls.restsLifted,
      ),
      controls: preferences.controls,
      allowSafetyPending: ref.watch(safetyPendingAllowedProvider),
    );
    final quiet = textTheme.bodyMedium?.copyWith(color: colors.textSecondary);
    final pieces = seed?.pool ?? path.pool;

    return Scaffold(
      appBar: const ThirtyAppBar(title: Text('A Path')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.s,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          children: [
            Semantics(
              header: true,
              child: Text(
                path.name,
                style: AppTypography.editorialDisplay(
                  colors,
                ).copyWith(fontSize: 30, height: 1.1),
              ),
            ),
            const SizedBox(height: 2),
            Text('${intentionLabel(path.need)} · seven Circles', style: quiet),
            const SizedBox(height: AppSpacing.l),
            ToolkitSection(
              title: 'What you’re building',
              child: Text(path.building, style: textTheme.bodyLarge),
            ),
            const SizedBox(height: AppSpacing.l),
            ToolkitSection(
              title: 'The pieces',
              child: ToolkitRows(
                rows: [
                  for (final module in pieces)
                    ToolkitRow(
                      title: moduleOf(module).name,
                      detail: moduleOf(module).purpose,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            ToolkitSection(
              title: 'How it goes',
              child: Text(
                'Your first Circles try the pieces short, then one in full, '
                'then two together, and a shorter form for busier days. '
                'After seven Circles you see what it built, and decide '
                'whether to keep it.\n\nThe Path is your Circle on days you '
                'choose ${intentionLabel(path.need)}. Other days, nothing '
                'changes, and missed days don’t matter. Answering after a '
                'Circle helps it fit you, but you never have to.',
                style: textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            if (seed != null)
              ToolkitNote(switch (seed.reason) {
                SeedReason.usefulModule =>
                  '${moduleOf(seed.useful!).name} comes first: you’ve found '
                      'it useful.',
                SeedReason.sparseStart =>
                  'A simple place to start — nothing here is based on your '
                      'answers yet.',
              }),
            const SizedBox(height: AppSpacing.l),
            ..._action(context, ref, entitled, toolkit, seed),
          ],
        ),
      ),
    );
  }

  List<Widget> _action(
    BuildContext context,
    WidgetRef ref,
    bool entitled,
    ToolkitState toolkit,
    PathSeed? seed,
  ) {
    if (seed == null) {
      return const [
        ToolkitNote(
          'This Path can’t build an honest routine right now: too few of its '
          'pieces are open. Some you’ve asked THIRTY not to suggest; some are '
          'resting after a recent “Not useful”, and a rest ends on its own. '
          'You’ll find both in What THIRTY remembers.',
        ),
      ];
    }
    if (!entitled) {
      return [
        const ToolkitNote('Paths are part of Premium.'),
        const SizedBox(height: AppSpacing.m),
        ThirtyButton(
          label: 'See Premium',
          onPressed: () => context.push('/premium'),
        ),
      ];
    }
    if (toolkit.path != null) {
      return const [
        ToolkitNote(
          'One Path at a time: finish or leave the one under way first.',
        ),
      ];
    }
    return [
      ThirtyButton(
        label: 'Start this Path',
        size: ThirtyButtonSize.hero,
        onPressed: () {
          final result = ref
              .read(toolkitProvider.notifier)
              .startBuild(template);
          if (result == PathStart.started) context.go(ToolkitPage.location);
        },
      ),
    ];
  }
}
