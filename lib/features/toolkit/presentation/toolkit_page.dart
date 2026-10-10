import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/premium/premium_access.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/thirty_button.dart';
import '../../../core/widgets/thirty_card.dart';
import '../../../core/widgets/thirty_confirm_dialog.dart';
import '../../../core/widgets/thirty_text_action.dart';
import '../../home/application/activity_catalog.dart';
import '../../home/domain/recommendation_engine.dart';
import '../../home/presentation/widgets/time_window_choice.dart';
import '../application/toolkit_provider.dart';
import '../domain/maintenance.dart';
import '../domain/path_catalog.dart';
import '../domain/path_engine.dart';
import '../domain/toolkit_model.dart';
import 'choose_path_page.dart';
import 'path_review_page.dart';
import 'path_start_page.dart';
import 'routine_detail_page.dart';
import 'widgets/toolkit_header_art.dart';
import 'widgets/toolkit_parts.dart';

/// The Toolkit (V2 Phase D, ADR-022): the one Premium destination. A
/// Path under way, the one thing worth changing (if any), and the user's
/// own routines — small, personal, owned.
///
/// It reads the same for everyone who has routines: they are the user's,
/// usable in Free, whatever Premium's state. What Premium adds — starting
/// Paths, tuning, shorter versions — is offered, never pressed.
class ToolkitPage extends ConsumerWidget {
  const ToolkitPage({super.key});

  static const location = '/toolkit';
  static const title = 'Toolkit';
  static const subtitle = 'Routines that are yours.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final toolkit = ref.watch(toolkitProvider);
    final entitled = ref.watch(premiumEntitlementProvider);
    final offer = ref.watch(primaryOfferProvider);
    final check = ref.watch(toolkitCheckProvider);
    final now = ref.watch(nowProvider);

    final sections = <Widget>[
      if (toolkit.path case final run?) _PathCard(run: run, entitled: entitled),
      if (offer != null && toolkit.path == null)
        _OfferCard(offer: offer, entitled: entitled, checkDue: check != null)
      else if (check != null && check.state != CheckState.action)
        _CheckCard(check: check),
      if (toolkit.routines.isNotEmpty)
        _Routines(
          routines: toolkit.routines,
          entitled: entitled,
          premiumShownAbove: toolkit.path != null,
        )
      else if (toolkit.path == null)
        entitled ? const _FirstPath() : const _WhatPremiumBuilds(),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            const SizedBox(height: AppSpacing.l),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: AppTypography.editorialDisplay(
                        colors,
                      ).copyWith(fontSize: 34, height: 1.05),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            ToolkitHeaderArt(art: toolkitHeaderArt, now: now),
            const SizedBox(height: AppSpacing.l),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Each section its own node, so TalkBack reads them in
                  // order rather than gathering loose text first.
                  for (final (index, section) in sections.indexed) ...[
                    if (index > 0) const SizedBox(height: AppSpacing.section),
                    Semantics(container: true, child: section),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The time a step needs, in the Daily Context Question's own words:
/// "about 10 minutes", "about 20 minutes", "up to 30 minutes".
String windowWordsFor(int minutes) {
  final window = TimeWindow.values.firstWhere(
    (w) => w.maxMinutes >= minutes,
    orElse: () => TimeWindow.upTo30,
  );
  return TimeWindowChoiceControl.meaning(window).toLowerCase();
}

/// The Path under way: where it is, what comes next, and how it reaches
/// Today. With Premium lapsed it is saved, exactly where it was.
class _PathCard extends ConsumerWidget {
  const _PathCard({required this.run, required this.entitled});

  final PathRun run;
  final bool entitled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final toolkit = ref.watch(toolkitProvider);
    final step = ref.watch(nextPathStepProvider);
    final resting = ref.watch(pathRestingProvider);
    // A piece the next step can't do without is resting: the Path waits
    // for it, and says so, rather than bring it back early.
    final waitingOn = step == null
        ? null
        : [
            for (final use in step.composition.uses)
              if (resting.contains(use.module)) use.definition.name,
          ].firstOrNull;
    final routine = run.routineId == null
        ? null
        : toolkit.routineById(run.routineId!);
    final name = switch (run.kind) {
      PathKind.build => pathTemplate(run.template!).name,
      PathKind.tuneUp => 'Tuning ${routine?.name ?? 'a routine'}',
      PathKind.shorter => 'Shortening ${routine?.name ?? 'a routine'}',
    };
    final need = intentionLabel(run.need);
    final position = run.finished
        ? 'All ${run.length} Circles'
        : 'Circle ${run.nextNumber} of ${run.length}';
    final quiet = textTheme.bodyMedium?.copyWith(color: colors.textSecondary);

    return ToolkitSection(
      title: 'Your Path',
      child: ThirtyCard(
        padding: const EdgeInsets.all(AppSpacing.featuredCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              container: true,
              label: '$name. $need. $position.',
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.editorialDisplay(
                        colors,
                      ).copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 2),
                    Text('$need · $position', style: quiet),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            // Each block its own stop, in the order it is seen: the
            // card's own text would otherwise gather into the card and be
            // read before its title (S25 TalkBack).
            if (run.finished) ...[
              Semantics(
                container: true,
                child: Text(
                  'This Path has had all its Circles. See what it built, and '
                  'decide whether to keep it.',
                  style: textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              Semantics(
                container: true,
                child: ThirtyButton(
                  label: 'See what it built',
                  onPressed: () => context.push(PathReviewPage.location),
                ),
              ),
            ] else if (step != null) ...[
              Semantics(
                container: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      // The length keeps together, so a wrap never leaves
                      // a dangling separator.
                      'Next: ${step.composition.title} — about'
                      ' ${step.composition.minutes} minutes',
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(step.explanation, style: quiet),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              Semantics(
                container: true,
                child: Text(
                  waitingOn != null
                      ? '$waitingOn is resting after your “Not useful”, so '
                            'this Path waits until its rest is over. Other '
                            'days, nothing changes.'
                      : entitled
                      ? 'Choose $need on Today, with '
                            '${windowWordsFor((step.shorter ?? step.composition).minutes)} '
                            'or more, and this is your Circle. Other days, '
                            'nothing changes.'
                      : 'Saved where you left it. It continues when Premium '
                            'is active again.',
                  style: textTheme.bodyMedium,
                ),
              ),
              if (!entitled) ...[
                const SizedBox(height: AppSpacing.m),
                Semantics(
                  container: true,
                  child: ThirtyButton(
                    label: 'See Premium',
                    variant: ThirtyButtonVariant.secondary,
                    onPressed: () => context.push('/premium'),
                  ),
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.s),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ThirtyTextAction(
                label: run.finished ? 'Leave it for now' : 'Leave this Path',
                onPressed: () => _confirmLeave(context, ref, run),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _confirmLeave(
    BuildContext context,
    WidgetRef ref,
    PathRun run,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierLabel: 'Keep going',
      builder: (_) => ThirtyConfirmDialog(
        title: run.finished ? 'Leave what it built?' : 'Leave this Path?',
        body: run.finished
            ? 'Nothing is added to your Toolkit. Its Circles stay in your '
                  'history.'
            : 'Its Circles stay in your history. You can start a Path again '
                  'whenever you like.',
        cancelLabel: 'Keep going',
        confirmLabel: 'Leave',
      ),
    );
    if (confirmed != true) return;
    final notifier = ref.read(toolkitProvider.notifier);
    run.finished ? notifier.setAsideProposal() : notifier.leavePath();
  }
}

/// The one maintenance offer: what THIRTY saw, and what it offers.
class _OfferCard extends ConsumerWidget {
  const _OfferCard({
    required this.offer,
    required this.entitled,
    required this.checkDue,
  });

  final MaintenanceOffer offer;
  final bool entitled;

  /// The Toolkit check came round with this offer as its result.
  final bool checkDue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final notifier = ref.read(toolkitProvider.notifier);

    void accept() {
      if (checkDue) notifier.seeCheck();
      switch (offer.kind) {
        case OfferKind.gap:
          context.push(PathStartPage.locationFor(offer.template!));
        case OfferKind.timeMisfit:
          notifier.startShorter(offer.routine!.id, offer.targetMinutes!);
        case OfferKind.fading:
          notifier.startTuneUp(offer.routine!.id);
      }
    }

    return ToolkitSection(
      title: checkDue ? 'Toolkit check' : 'Worth a look',
      child: ThirtyCard(
        padding: const EdgeInsets.all(AppSpacing.featuredCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(offer.evidence, style: textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              offer.proposal,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            if (entitled)
              ThirtyButton(label: 'Try it', onPressed: accept)
            else ...[
              Text(
                'Tuning routines is Premium. Your routines stay yours either '
                'way.',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              ThirtyButton(
                label: 'See Premium',
                variant: ThirtyButtonVariant.secondary,
                onPressed: () => context.push('/premium'),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Align(
              child: ThirtyTextAction(
                label: 'Not now',
                onPressed: () {
                  if (checkDue) notifier.seeCheck();
                  notifier.declineOffer(offer.key);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Toolkit check, every four weeks or so: nothing to change, or still
/// learning — said plainly, and nothing invented.
class _CheckCard extends ConsumerWidget {
  const _CheckCard({required this.check});

  final ToolkitCheck check;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ToolkitSection(
      title: 'Toolkit check',
      child: ThirtyCard(
        padding: const EdgeInsets.all(AppSpacing.featuredCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(check.message, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ThirtyTextAction(
                label: 'OK',
                onPressed: ref.read(toolkitProvider.notifier).seeCheck,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The user's routines — the heart of the Toolkit.
class _Routines extends StatelessWidget {
  const _Routines({
    required this.routines,
    required this.entitled,
    this.premiumShownAbove = false,
  });

  final List<Routine> routines;
  final bool entitled;

  /// A saved Path above already links to Premium: one link is enough.
  final bool premiumShownAbove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToolkitSection(
          title: 'Your routines',
          child: ToolkitRows(
            rows: [
              for (final routine in routines)
                ToolkitRow(
                  title: routine.name,
                  detail: routine.enabled
                      ? routineLine(routine)
                      : 'Off · ${routineLine(routine)}',
                  muted: !routine.enabled,
                  onTap: () =>
                      context.push(RoutineDetailPage.locationFor(routine.id)),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        if (entitled)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ThirtyTextAction(
              label: 'Build another routine',
              onPressed: () => context.push(ChoosePathPage.location),
            ),
          )
        else ...[
          const ToolkitNote(
            'Routines you built stay yours — THIRTY still offers them on '
            'Today. Building and tuning routines is Premium.',
          ),
          if (!premiumShownAbove) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ThirtyTextAction(
                label: 'See Premium',
                onPressed: () => context.push('/premium'),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// Free, with nothing built: what Premium builds — without making Free
/// look unfinished.
class _WhatPremiumBuilds extends StatelessWidget {
  const _WhatPremiumBuilds();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    return ThirtyCard(
      padding: const EdgeInsets.all(AppSpacing.featuredCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'A few routines of your own',
              style: AppTypography.editorialDisplay(
                colors,
              ).copyWith(fontSize: 22),
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'With Premium, a Path tries a few pieces with you over seven '
            'Circles — short, then in full, then together — and ends with a '
            'routine you keep. When your days change, THIRTY offers to tune '
            'it.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Routines you build stay yours, with or without Premium. Free '
            'stays complete: THIRTY still chooses one thing for today.',
            style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.m),
          ThirtyButton(
            label: 'See Premium',
            variant: ThirtyButtonVariant.secondary,
            onPressed: () => context.push('/premium'),
          ),
        ],
      ),
    );
  }
}

/// Premium, with nothing built yet: one sensible first Path, and the way to
/// the others.
class _FirstPath extends ConsumerWidget {
  const _FirstPath();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final suggestion = ref.watch(suggestedPathProvider);
    final template = pathTemplate(suggestion.template);
    return ToolkitSection(
      title: 'Your first Path',
      child: ThirtyCard(
        padding: const EdgeInsets.all(AppSpacing.featuredCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              template.name,
              style: AppTypography.editorialDisplay(
                colors,
              ).copyWith(fontSize: 22),
            ),
            const SizedBox(height: 2),
            Text(
              '${intentionLabel(template.need)} · seven Circles',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(template.building, style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              suggestion.reason,
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.m),
            ThirtyButton(
              label: 'Look at this Path',
              onPressed: () =>
                  context.push(PathStartPage.locationFor(template.id)),
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              child: ThirtyTextAction(
                label: 'See all six Paths',
                onPressed: () => context.push(ChoosePathPage.location),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The first Path THIRTY suggests, and why — only what the evidence says.
typedef PathSuggestion = ({PathTemplateId template, String reason});

/// The need chosen most often over the last four weeks (at least three
/// times), and that need's Path whose routine fits the time usually chosen
/// for it. Otherwise the first Path, with nothing claimed.
final suggestedPathProvider = Provider<PathSuggestion>((ref) {
  final history = ref.watch(toolkitHistoryProvider);
  final today = ref.watch(nowProvider);
  final counts = <Intention, int>{};
  final windows = <Intention, List<TimeWindow>>{};
  for (final c in history) {
    final age = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(c.date.year, c.date.month, c.date.day)).inDays;
    if (age < 1 || age > 28) continue;
    counts[c.need] = (counts[c.need] ?? 0) + 1;
    if (c.window case final w?) (windows[c.need] ??= []).add(w);
  }
  final ranked = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.index.compareTo(b.key.index);
    });
  if (ranked.isEmpty || ranked.first.value < 3) {
    return (
      template: pathCatalog.first.id,
      reason: 'A simple place to start. You can choose another Path.',
    );
  }
  final need = ranked.first.key;
  final usual = windows[need] ?? const <TimeWindow>[];
  final usualMax = usual.isEmpty
      ? TimeWindow.upTo30.maxMinutes
      : usual.map((w) => w.maxMinutes).reduce((a, b) => a < b ? a : b);
  final options = pathsFor(need);
  final fitting = options.firstWhere(
    (t) => _shortestJoined(t) <= usualMax,
    orElse: () => options.first,
  );
  return (
    template: fitting.id,
    reason: 'You’ve often chosen ${intentionLabel(need)} lately.',
  );
});

int _shortestJoined(PathTemplate template) {
  var shortest = 1 << 20;
  final pool = template.pool;
  for (var i = 0; i < pool.length; i++) {
    for (var j = i + 1; j < pool.length; j++) {
      final together = fullTogether(pool[i], pool[j]);
      if (together == null) continue;
      final minutes = (shortFormOf(together) ?? together).minutes;
      if (minutes < shortest) shortest = minutes;
    }
  }
  return shortest;
}
