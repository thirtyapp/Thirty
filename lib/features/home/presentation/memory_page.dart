import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/date_key.dart';
import '../../../core/widgets/thirty_app_bar.dart';
import '../../../core/widgets/thirty_button.dart';
import '../../../core/widgets/thirty_card.dart';
import '../../../core/widgets/thirty_confirm_dialog.dart';
import '../../../core/widgets/thirty_text_action.dart';
import '../application/activity_catalog.dart';
import '../application/circle_journal.dart';
import '../application/recommendation_provider.dart';
import '../application/suggestion_preferences.dart';
import '../domain/memory_overview.dart';
import '../domain/recommendation_engine.dart';
import 'widgets/circle_journal_entry_card.dart';
import 'widgets/time_window_choice.dart';

/// "What THIRTY remembers" (V2 Phase C, ADR-021) — the Free memory page:
/// what the user has told THIRTY after their Circles, need by need, and
/// what THIRTY does with it. Plain sentences tied to their own answers and
/// choices; no scores, counts, charts or inferences. Each item opens its
/// detail, where it can be corrected.
///
/// History says what happened; this page says what THIRTY currently uses.
class MemoryPage extends ConsumerStatefulWidget {
  const MemoryPage({this.need, super.key});

  /// The need to open on, when the way in is about one — "nothing fits
  /// More Energy" opens on More Energy, where those choices are.
  final Intention? need;

  /// The route to this page, opening on [need] when given.
  static String location([Intention? need]) =>
      need == null ? '/memory' : '/memory?need=${need.name}';

  static const title = 'What THIRTY remembers';
  static const intro =
      'Only what you’ve told THIRTY after a Circle, need by need. It’s what '
      'THIRTY goes by when it chooses.';

  @override
  ConsumerState<MemoryPage> createState() => _MemoryPageState();
}

class _MemoryPageState extends ConsumerState<MemoryPage> {
  Intention? _need;

  /// The need asked for, else today's, else the latest Circle's, else
  /// More Energy.
  Intention _initialNeed(List<CircleJournalEntry> entries) =>
      widget.need ??
      ref.read(recommendationProvider).recommendation?.intention ??
      (entries.isEmpty ? Intention.moreEnergy : entries.last.direction);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final entries = ref.watch(circleJournalRepositoryProvider).readAll();
    final preferences = ref.watch(suggestionPreferencesProvider);
    final need = _need ??= _initialNeed(entries);
    final memory = needMemoryOf(
      today: ref.watch(nowProvider),
      need: need,
      history: pastCirclesFrom(entries),
      controls: preferences.controls,
      allowSafetyPending: ref.watch(safetyPendingAllowedProvider),
    );

    return Scaffold(
      appBar: const ThirtyAppBar(title: Text(MemoryPage.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.s,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          children: [
            Text(
              MemoryPage.intro,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            _NeedChoice(
              need: need,
              onChanged: (next) => setState(() => _need = next),
            ),
            const SizedBox(height: AppSpacing.l),
            ..._needSections(context, memory),
            // Its own control, shown only while there is something to reset.
            if (!preferences.isEmpty) ...[
              const SizedBox(height: AppSpacing.section),
              const _ResetPreferences(),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _needSections(BuildContext context, NeedMemory memory) {
    final need = memory.need;
    final label = intentionLabel(need);
    final usual = memory.usualTime;
    final sections = <Widget>[
      if (memory.usefulBefore.isNotEmpty)
        _Section(
          title: 'Useful before',
          rows: [
            for (final item in memory.usefulBefore)
              _MemoryRow(
                activity: item.activity,
                detail:
                    'You said ${_answerWords(item.answer)} · '
                    '${_date(item.answeredOn)}',
                onTap: () => _openDetail(context, item.activity, need),
              ),
          ],
        ),
      if (memory.resting.isNotEmpty)
        _Section(
          title: 'Resting for now',
          rows: [
            for (final item in memory.resting)
              _MemoryRow(
                activity: item.activity,
                detail:
                    'You said not useful · resting until '
                    '${_date(item.restsUntil!)}',
                onTap: () => _openDetail(context, item.activity, need),
              ),
          ],
        ),
      if (memory.notUsefulBefore.isNotEmpty)
        _Section(
          title: 'Not useful before',
          rows: [
            for (final item in memory.notUsefulBefore)
              _MemoryRow(
                activity: item.activity,
                detail: 'You said not useful · ${_date(item.answeredOn)}',
                onTap: () => _openDetail(context, item.activity, need),
              ),
          ],
        ),
      if (memory.notSuggested.isNotEmpty)
        _Section(
          title: 'Not suggested, as you asked',
          rows: [
            for (final activity in memory.notSuggested)
              _MemoryRow(
                activity: activity,
                detail: 'You asked THIRTY not to suggest it for $label',
                onTap: () => _openDetail(context, activity, need),
              ),
          ],
        ),
    ];
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final quiet = textTheme.bodyMedium?.copyWith(color: colors.textSecondary);
    return [
      if (sections.isEmpty)
        Text(
          'Nothing yet for $label. After a Circle, tell THIRTY whether it '
          'helped — your answers show here.',
          style: quiet,
        )
      else
        for (final (index, section) in sections.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.l),
          section,
        ],
      if (usual != null) ...[
        const SizedBox(height: AppSpacing.l),
        Text(
          'You usually choose '
          '${TimeWindowChoiceControl.meaning(usual).toLowerCase()} for '
          '$label.',
          style: quiet,
        ),
      ],
      // What hasn't been tried, without a tally to work through: THIRTY
      // brings something new now and then.
      if (memory.notOfferedYet > 0) ...[
        const SizedBox(height: AppSpacing.m),
        Text(
          'Some activities that fit $label haven’t come up yet — THIRTY '
          'brings something new now and then.',
          style: quiet,
        ),
      ],
    ];
  }

  void _openDetail(BuildContext context, ActivityId activity, Intention need) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      // TalkBack names the backdrop by what it does.
      barrierLabel: 'Close',
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).extension<AppColors>()!.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MemoryDetailSheet(activity: activity, need: need),
    );
  }
}

String _answerWords(PastUsefulness answer) => switch (answer) {
  PastUsefulness.veryUseful => 'very useful',
  PastUsefulness.somewhatUseful => 'somewhat useful',
  PastUsefulness.notUseful => 'not useful',
};

String _date(DateTime day) => humanJournalDate(dateKey(day), withWeekday: false)
    .replaceFirst(RegExp(r' \d{4}$'), '')
    // "7 October" stays on one line at large text.
    .replaceAll(' ', '\u00A0');

/// More Energy / Clearer Head / Gentler Pace — one view at a time, so an
/// answer about one need is never read as being about another.
class _NeedChoice extends StatelessWidget {
  const _NeedChoice({required this.need, required this.onChanged});

  final Intention need;
  final ValueChanged<Intention> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final style = Theme.of(context).textTheme.bodySmall;
    return LayoutBuilder(
      builder: (context, constraints) {
        final segment = constraints.maxWidth / Intention.values.length;
        final fits = Intention.values.every((option) {
          final painter = TextPainter(
            text: TextSpan(text: intentionLabel(option), style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout();
          final ok = painter.width + 26 <= segment;
          painter.dispose();
          return ok;
        });
        if (!fits) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final option in Intention.values)
                Semantics(
                  button: true,
                  inMutuallyExclusiveGroup: true,
                  selected: option == need,
                  label: intentionLabel(option),
                  onTap: () => onChanged(option),
                  child: ExcludeSemantics(
                    child: InkWell(
                      onTap: () => onChanged(option),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                intentionLabel(option),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            if (option == need)
                              Icon(Icons.check, color: colors.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }
        return SegmentedButton<Intention>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.padded,
            textStyle: style,
            foregroundColor: colors.textSecondary,
            selectedForegroundColor: colors.textPrimary,
            selectedBackgroundColor: colors.secondary,
            side: BorderSide(color: colors.divider),
          ),
          segments: [
            for (final option in Intention.values)
              ButtonSegment(value: option, label: Text(intentionLabel(option))),
          ],
          selected: {need},
          onSelectionChanged: (selection) => onChanged(selection.first),
        );
      },
    );
  }
}

/// A quiet section: a small heading, then its items in one card.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            title.toUpperCase(),
            semanticsLabel: title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        ThirtyCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.featuredCard,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, row) in rows.indexed) ...[
                if (index > 0) Divider(height: 1, color: colors.divider),
                row,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One remembered activity: its name and the user's own words about it.
/// Tapping opens what can be done about it.
class _MemoryRow extends StatelessWidget {
  const _MemoryRow({
    required this.activity,
    required this.detail,
    required this.onTap,
  });

  final ActivityId activity;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final title = activityLabel(activity);
    return Semantics(
      button: true,
      label: '$title. $detail',
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One remembered activity, for one need: what the user told THIRTY, what
/// THIRTY does with it, and the corrections that apply — "Suggest again",
/// "Don't suggest", and removing an answer.
class MemoryDetailSheet extends ConsumerWidget {
  const MemoryDetailSheet({
    required this.activity,
    required this.need,
    super.key,
  });

  final ActivityId activity;
  final Intention need;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final entries = ref.watch(circleJournalRepositoryProvider).readAll();
    final preferences = ref.watch(suggestionPreferencesProvider);
    final memory = needMemoryOf(
      today: ref.watch(nowProvider),
      need: need,
      history: pastCirclesFrom(entries),
      controls: preferences.controls,
      allowSafetyPending: ref.watch(safetyPendingAllowedProvider),
    );
    final label = intentionLabel(need);
    final title = activityLabel(activity);
    final notSuggested = memory.notSuggested.contains(activity);
    final resting = memory.resting
        .where((r) => r.activity == activity)
        .firstOrNull;
    final remembered = [
      ...memory.usefulBefore,
      ...memory.notUsefulBefore,
    ].where((r) => r.activity == activity).firstOrNull;

    final status = notSuggested
        ? 'You asked THIRTY not to suggest it for $label. It stays that way '
              'until you change it.'
        : resting != null
        ? 'You said it wasn’t useful for $label. It’s resting until '
              '${_date(resting.restsUntil!)}, then may come up again.'
        : remembered?.answer == PastUsefulness.notUseful
        ? 'You said it wasn’t useful for $label. THIRTY offers it less '
              'often for now.'
        : remembered != null
        ? 'You said it was ${_answerWords(remembered.answer)} for $label. '
              'THIRTY offers it again now and then.'
        : 'THIRTY has nothing from you about it for $label.';

    final answers = [
      for (final entry in entries.reversed)
        if (entry.direction == need &&
            entry.activityId == activity &&
            entry.usefulnessResponse != null)
          entry,
    ];

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    void done(String message) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }

    final prefs = ref.read(suggestionPreferencesProvider.notifier);
    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.xl + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: AppTypography.editorialDisplay(
              colors,
            ).copyWith(fontSize: 26, height: 1.2),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'For $label',
          style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.m),
        Text(status, style: textTheme.bodyLarge),
        if (answers.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.l),
          Semantics(
            header: true,
            child: Text(
              'WHAT YOU SAID',
              semanticsLabel: 'What you said',
              style: textTheme.labelSmall?.copyWith(
                color: colors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final entry in answers)
            _AnswerLine(
              entry: entry,
              onRemove: () => _confirmRemove(context, ref, entry),
            ),
        ],
        const SizedBox(height: AppSpacing.l),
        if (notSuggested)
          ThirtyButton(
            label: 'Suggest again',
            variant: ThirtyButtonVariant.secondary,
            onPressed: () async {
              await prefs.allowAgain(activity, need);
              done('THIRTY may suggest $title for $label again.');
            },
          )
        else ...[
          if (resting != null) ...[
            ThirtyButton(
              label: 'Suggest again',
              variant: ThirtyButtonVariant.secondary,
              onPressed: () async {
                await prefs.liftRest(activity, need);
                done('$title can come up for $label again.');
              },
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          ThirtyTextAction(
            label: 'Don’t suggest it for $label',
            onPressed: () async {
              await prefs.dontSuggest(activity, need);
              done('THIRTY won’t suggest $title for $label.');
            },
          ),
        ],
      ],
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    CircleJournalEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierLabel: 'Keep it',
      builder: (_) => ThirtyConfirmDialog(
        title: 'Remove this answer?',
        body:
            'Your Circle on ${humanJournalDate(entry.localDate, withWeekday: false)} '
            'stays in your history. THIRTY stops using this answer.',
        cancelLabel: 'Keep it',
        confirmLabel: 'Remove answer',
        destructive: true,
      ),
    );
    if (confirmed != true) return;
    ref
        .read(recommendationProvider.notifier)
        .removeAnswer(entry.circleId, includingAttempt: false);
  }
}

class _AnswerLine extends StatelessWidget {
  const _AnswerLine({required this.entry, required this.onRemove});

  final CircleJournalEntry entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final answer = switch (entry.usefulnessResponse!) {
      CircleUsefulnessResponse.veryUseful => 'Very useful',
      CircleUsefulnessResponse.somewhatUseful => 'Somewhat useful',
      CircleUsefulnessResponse.notUseful => 'Not useful',
    };
    final date = humanJournalDate(entry.localDate, withWeekday: false);
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$date  ',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                TextSpan(text: answer, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ),
        Semantics(
          label: 'Remove the answer from $date',
          button: true,
          excludeSemantics: true,
          onTap: onRemove,
          child: ThirtyTextAction(label: 'Remove', onPressed: onRemove),
        ),
      ],
    );
  }
}

/// "Reset suggestion preferences": clears every "Don't suggest" and lifted
/// rest. Circle history and its answers stay.
class _ResetPreferences extends ConsumerWidget {
  const _ResetPreferences();

  static const label = 'Reset suggestion preferences';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    Future<void> reset() async {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierLabel: 'Keep them',
        builder: (_) => const ThirtyConfirmDialog(
          title: 'Reset suggestion preferences?',
          body:
              'THIRTY will forget which activities you asked it not to '
              'suggest, and any rests you lifted. Your Circle history and '
              'your answers stay.',
          cancelLabel: 'Keep them',
          confirmLabel: 'Reset',
          destructive: true,
        ),
      );
      if (confirmed != true) return;
      await ref.read(suggestionPreferencesProvider.notifier).reset();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, color: colors.divider),
        Semantics(
          button: true,
          label: label,
          onTap: reset,
          excludeSemantics: true,
          child: InkWell(
            onTap: reset,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: colors.errorText),
                ),
              ),
            ),
          ),
        ),
        Text(
          'Your Circle history and your answers are not affected.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}
