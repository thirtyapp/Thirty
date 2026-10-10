import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/premium/premium_access.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/thirty_app_bar.dart';
import '../../../core/widgets/thirty_button.dart';
import '../../../core/widgets/thirty_confirm_dialog.dart';
import '../../../core/widgets/thirty_text_action.dart';
import '../../home/application/activity_catalog.dart';
import '../../home/application/suggestion_preferences.dart';
import '../../home/domain/recommendation_engine.dart';
import '../../home/domain/recommendation_policy.dart';
import '../application/toolkit_provider.dart';
import '../domain/maintenance.dart';
import '../domain/path_engine.dart';
import '../domain/toolkit_model.dart';
import 'toolkit_page.dart';
import 'widgets/toolkit_parts.dart';

/// One routine: what it is, when it fits, what is in it, which version
/// THIRTY uses, and what the user can change. The ownership controls —
/// rename, turn off, delete, choose a version, when it's offered — are the
/// user's, whatever Premium's state.
class RoutineDetailPage extends ConsumerWidget {
  const RoutineDetailPage({required this.routineId, super.key});

  final String routineId;

  static const pathPattern = '/toolkit/routine/:id';
  static String locationFor(String id) => '/toolkit/routine/$id';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final toolkit = ref.watch(toolkitProvider);
    final routine = toolkit.routineById(routineId);
    if (routine == null) {
      return Scaffold(
        appBar: const ThirtyAppBar(title: Text('Routine')),
        body: const Padding(
          padding: EdgeInsets.all(AppSpacing.page),
          child: ToolkitNote('This routine is no longer in your Toolkit.'),
        ),
      );
    }
    final today = ref.watch(nowProvider);
    final history = ref.watch(toolkitHistoryProvider);
    final standing = routineStanding(routine, history, today);
    final preferences = ref.watch(suggestionPreferencesProvider);
    final entitled = ref.watch(premiumEntitlementProvider);
    final quiet = textTheme.bodyMedium?.copyWith(color: colors.textSecondary);
    final active = routine.active;
    final short = routine.shortVersion;
    final earlier = [
      for (final v in routine.versions.reversed)
        if (v.id != active.id && v.id != routine.shortVersionId) v,
    ];

    return Scaffold(
      appBar: const ThirtyAppBar(title: Text('Routine')),
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
                routine.name,
                style: AppTypography.editorialDisplay(
                  colors,
                ).copyWith(fontSize: 30, height: 1.1),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              routine.enabled
                  ? routineLine(routine)
                  : 'Off — THIRTY won’t offer it until you turn it on.',
              style: quiet,
            ),
            const SizedBox(height: AppSpacing.s),
            ToolkitNote(_standingWords(standing)),
            const SizedBox(height: AppSpacing.l),
            ToolkitSection(
              title: 'What’s in it',
              child: ToolkitRows(
                rows: [
                  for (final use in active.composition.uses)
                    ToolkitRow(
                      title: use.definition.name,
                      detail:
                          'About ${use.minutes} minutes · '
                          '${use.definition.purpose}',
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            ToolkitSection(
              title: 'The version THIRTY uses now',
              child: ToolkitRows(
                rows: [
                  ToolkitRow(
                    title: 'Version ${active.number}',
                    detail:
                        'About ${active.minutes} minutes · since '
                        '${_date(active.createdAt)}',
                  ),
                  if (short != null)
                    ToolkitRow(
                      title: 'Shorter version',
                      detail:
                          '${piecesLine(short.composition)} · about '
                          '${short.minutes} minutes, for days with less time',
                    ),
                ],
              ),
            ),
            if (earlier.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.l),
              ToolkitSection(
                title: 'Earlier versions',
                child: ToolkitRows(
                  rows: [
                    for (final version in earlier)
                      ToolkitRow(
                        title: 'Version ${version.number}',
                        detail:
                            '${piecesLine(version.composition)} · about '
                            '${version.minutes} minutes',
                        onTap: () => _useAgain(context, ref, routine, version),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.l),
            ToolkitSection(
              title: 'When THIRTY offers it',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final need in Intention.values)
                    if (routine.fitFor(need) != NeedFit.none)
                      _OfferedFor(
                        routine: routine,
                        need: need,
                        preferences: preferences,
                      ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            ToolkitSection(
              title: 'Change it',
              child: _ChangeIt(routine: routine, entitled: entitled),
            ),
            const SizedBox(height: AppSpacing.l),
            ToolkitSection(
              title: 'It’s yours',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ThirtyTextAction(
                    label: 'Rename',
                    onPressed: () => _rename(context, ref, routine),
                  ),
                  ThirtyTextAction(
                    label: routine.enabled ? 'Turn it off' : 'Turn it on',
                    onPressed: () => ref
                        .read(toolkitProvider.notifier)
                        .setEnabled(routine.id, enabled: !routine.enabled),
                  ),
                  ThirtyTextAction(
                    label: 'Delete',
                    onPressed: () => _delete(context, ref, routine),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Only what its answers since it last changed support.
  static String _standingWords(RoutineStanding standing) {
    final rated = standing.rated;
    if (standing.fading) {
      return 'It hasn’t suited you as well lately.';
    }
    if (rated.length < 3) return 'Still learning how this one fits.';
    final recent = rated.length > 5 ? rated.sublist(rated.length - 5) : rated;
    final useful = recent
        .where(
          (u) =>
              u == PastUsefulness.veryUseful ||
              u == PastUsefulness.somewhatUseful,
        )
        .length;
    return 'You found it useful $useful of the last ${recent.length} times '
        'you said.';
  }

  static String _date(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  static Future<void> _useAgain(
    BuildContext context,
    WidgetRef ref,
    Routine routine,
    RoutineVersion version,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierLabel: 'Keep the current one',
      builder: (_) => ThirtyConfirmDialog(
        title: 'Use version ${version.number} again?',
        body:
            '${piecesLine(version.composition)}, about ${version.minutes} '
            'minutes. The current version is kept, so you can switch back.',
        cancelLabel: 'Keep the current one',
        confirmLabel: 'Use it',
      ),
    );
    if (confirmed != true) return;
    ref.read(toolkitProvider.notifier).useVersion(routine.id, version.id);
  }

  static Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    Routine routine,
  ) async {
    final controller = TextEditingController(text: routine.name);
    final name = await showDialog<String>(
      context: context,
      barrierLabel: 'Cancel',
      builder: (context) => AlertDialog(
        semanticLabel: 'Rename',
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(counterText: ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null) return;
    ref.read(toolkitProvider.notifier).rename(routine.id, name);
  }

  static Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Routine routine,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierLabel: 'Keep it',
      builder: (_) => ThirtyConfirmDialog(
        title: 'Delete ${routine.name}?',
        body:
            'It and its versions leave your Toolkit, and THIRTY won’t offer '
            'it again. Circles you did with it stay in your history.',
        cancelLabel: 'Keep it',
        confirmLabel: 'Delete',
        destructive: true,
      ),
    );
    if (confirmed != true || !context.mounted) return;
    ref.read(toolkitProvider.notifier).deleteRoutine(routine.id);
    context.go(ToolkitPage.location);
  }
}

/// Whether THIRTY offers the routine for [need] — the same "Don't suggest"
/// as on the memory page, for a routine.
class _OfferedFor extends ConsumerWidget {
  const _OfferedFor({
    required this.routine,
    required this.need,
    required this.preferences,
  });

  final Routine routine;
  final Intention need;
  final SuggestionPreferences preferences;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = intentionLabel(need);
    final blockedBy = [
      for (final use in routine.active.composition.uses)
        if (preferences.isNotSuggested(use.definition.source, need))
          use.definition.name,
    ];
    if (blockedBy.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
        child: ToolkitNote(
          'Not offered for $label: it includes '
          '${blockedBy.join(' and ').toLowerCaseFirst}, which you asked '
          'THIRTY not to suggest for $label.'
          '${need == routine.need && blockedBy.length == 1 ? ' Tuning it '
                    'replaces that piece.' : ''}',
        ),
      );
    }
    final offered = !preferences.isRoutineNotSuggested(routine.id, need);
    final notifier = ref.read(suggestionPreferencesProvider.notifier);
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('Offered for $label'),
      value: offered,
      onChanged: (on) => on
          ? notifier.allowRoutineAgain(routine.id, need: need)
          : notifier.dontSuggestRoutine(routine.id, need),
    );
  }
}

extension on String {
  String get toLowerCaseFirst =>
      isEmpty ? this : '${this[0].toLowerCase()}${substring(1)}';
}

/// The Premium changes: a shorter version, or a tune-up — offered, and
/// started only when the user asks.
class _ChangeIt extends ConsumerWidget {
  const _ChangeIt({required this.routine, required this.entitled});

  final Routine routine;
  final bool entitled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolkit = ref.watch(toolkitProvider);
    if (!entitled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ToolkitNote(
            'A shorter version, or tuning it, is Premium. Your routine stays '
            'yours, and THIRTY keeps offering it either way.',
          ),
          const SizedBox(height: AppSpacing.s),
          ThirtyButton(
            label: 'See Premium',
            variant: ThirtyButtonVariant.secondary,
            onPressed: () => context.push('/premium'),
          ),
        ],
      );
    }
    if (toolkit.path != null) {
      return const ToolkitNote(
        'One Path at a time: this can wait until the one under way has '
        'finished.',
      );
    }
    final target = _shorterTarget(ref);
    final notifier = ref.read(toolkitProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToolkitNote(
          '${target == null ? 'It takes' : 'Each takes'} three Circles and '
          'ends with your choice. Nothing changes unless you keep it.',
        ),
        const SizedBox(height: AppSpacing.s),
        if (target != null) ...[
          ThirtyButton(
            label: 'Make a shorter version',
            variant: ThirtyButtonVariant.secondary,
            onPressed: () {
              if (notifier.startShorter(routine.id, target) ==
                  PathStart.started) {
                context.go(ToolkitPage.location);
              }
            },
          ),
          const SizedBox(height: AppSpacing.s),
        ],
        ThirtyButton(
          label: 'Tune this routine',
          variant: ThirtyButtonVariant.secondary,
          onPressed: () {
            if (notifier.startTuneUp(routine.id) == PathStart.started) {
              context.go(ToolkitPage.location);
            }
          },
        ),
      ],
    );
  }

  /// The time a shorter version would fit — the next window down that a
  /// real shorter form fits — or `null`.
  int? _shorterTarget(WidgetRef ref) {
    final active = routine.active;
    final memory = RecommendationMemory.of(
      ref.read(nowProvider),
      ref.read(toolkitHistoryProvider),
      RecommendationPolicy.initial,
    );
    // Never made shorter with a piece resting after a "Not useful".
    if (active.composition.uses.any(
      (use) => moduleResting(use.module, routine.need, memory),
    )) {
      return null;
    }
    for (final window in TimeWindow.values.reversed) {
      if (window.maxMinutes >= active.minutes) continue;
      if (routine.shortVersion case final s?
          when s.minutes <= window.maxMinutes) {
        continue;
      }
      if (shorterVersionOf(active.composition, window.maxMinutes) != null) {
        return window.maxMinutes;
      }
    }
    return null;
  }
}
