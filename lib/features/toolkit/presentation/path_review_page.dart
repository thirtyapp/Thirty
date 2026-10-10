import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/thirty_app_bar.dart';
import '../../../core/widgets/thirty_button.dart';
import '../../../core/widgets/thirty_card.dart';
import '../../../core/widgets/thirty_text_action.dart';
import '../../home/domain/recommendation_engine.dart';
import '../application/toolkit_provider.dart';
import '../domain/path_catalog.dart';
import '../domain/toolkit_model.dart';
import 'toolkit_page.dart';
import 'widgets/toolkit_parts.dart';

/// The end of a Path: only what happened — the pieces tried, the answers
/// given, what changed — and what it proposes. Nothing here is a score, an
/// outcome or a claim the answers don't support.
class PathReviewPage extends ConsumerStatefulWidget {
  const PathReviewPage({super.key});

  static const location = '/toolkit/review';

  @override
  ConsumerState<PathReviewPage> createState() => _PathReviewPageState();
}

class _PathReviewPageState extends ConsumerState<PathReviewPage> {
  TextEditingController? _name;

  @override
  void dispose() {
    _name?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final toolkit = ref.watch(toolkitProvider);
    final run = toolkit.path;
    final proposal = ref.watch(pathProposalProvider);
    if (run == null || proposal == null) {
      return Scaffold(
        appBar: const ThirtyAppBar(title: Text('Your Path')),
        body: const Padding(
          padding: EdgeInsets.all(AppSpacing.page),
          child: ToolkitNote('There’s no finished Path to look at.'),
        ),
      );
    }
    final routine = run.routineId == null
        ? null
        : toolkit.routineById(run.routineId!);
    final facts = proposal.facts;
    final quiet = textTheme.bodyMedium?.copyWith(color: colors.textSecondary);

    final heading = switch (run.kind) {
      PathKind.build => 'What your Path built',
      PathKind.tuneUp => 'Your routine, tuned',
      PathKind.shorter => 'A shorter version',
    };

    // Only what the answers support (PRODUCT_V2_CONTRACT — no fake
    // personal claims).
    final evidence =
        facts.answeredForResult >= 2 && facts.positiveForResult >= 2
        ? 'You found ${proposal.composition.combined ? 'these together' : 'this'} '
              'useful ${facts.positiveForResult} of the '
              '${facts.answeredForResult} times you said.'
        : facts.anyAnswers
        ? 'Shaped by what you told THIRTY along the way.'
        : 'Here’s what you built through this Path.';

    return Scaffold(
      appBar: const ThirtyAppBar(title: Text('Your Path')),
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
                heading,
                style: AppTypography.editorialDisplay(
                  colors,
                ).copyWith(fontSize: 30, height: 1.1),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(evidence, style: quiet),
            const SizedBox(height: AppSpacing.l),
            ThirtyCard(
              padding: const EdgeInsets.all(AppSpacing.featuredCard),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (run.kind == PathKind.build) ...[
                    Semantics(
                      container: true,
                      child: TextField(
                        controller: _name ??= TextEditingController(
                          text: pathTemplate(run.template!).routineName,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        maxLength: 40,
                        decoration: const InputDecoration(
                          labelText: 'Its name',
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                  ] else if (routine != null) ...[
                    Text(routine.name, style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.s),
                  ],
                  // What it is, read as one stop after its name field —
                  // never merged into the field (S25 TalkBack).
                  Semantics(
                    container: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final use in proposal.composition.uses)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
                            child: Text(
                              '${use.definition.name} · about ${use.minutes} min',
                              style: textTheme.bodyLarge,
                            ),
                          ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'About ${proposal.composition.minutes} minutes in all.',
                          style: quiet,
                        ),
                        if (proposal.shorter case final shorter?) ...[
                          const SizedBox(height: AppSpacing.s),
                          Text(
                            'And a shorter form — about ${shorter.minutes} minutes — '
                            'for days with less time.',
                            style: quiet,
                          ),
                        ],
                        if (run.kind == PathKind.tuneUp && routine != null) ...[
                          const SizedBox(height: AppSpacing.s),
                          Text(
                            'Until now: ${piecesLine(routine.active.composition)}. '
                            'Keeping this makes it version '
                            '${routine.versions.where((v) => v.origin != VersionOrigin.shorter).length + 1}'
                            '; the old one is kept.',
                            style: quiet,
                          ),
                        ],
                        if (run.kind == PathKind.shorter) ...[
                          const SizedBox(height: AppSpacing.s),
                          Text(
                            'THIRTY would use it on days with less time. Your '
                            'routine itself stays as it is.',
                            style: quiet,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            ToolkitSection(
              title: 'Along the way',
              child: ToolkitRows(
                rows: [
                  for (final circle in facts.answers)
                    ToolkitRow(
                      eyebrow: 'Circle ${circle.number}',
                      title: circle.composition.title,
                      detail:
                          'About ${circle.composition.minutes} minutes · '
                          '${_answerWords(circle.answer)}',
                    ),
                ],
              ),
            ),
            if (facts.changes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.m),
              for (final change in facts.changes) ToolkitNote(change),
            ],
            const SizedBox(height: AppSpacing.l),
            ThirtyButton(
              label: switch (run.kind) {
                PathKind.build => 'Keep this routine',
                PathKind.tuneUp => 'Use the new version',
                PathKind.shorter => 'Keep this shorter version',
              },
              size: ThirtyButtonSize.hero,
              onPressed: () {
                ref
                    .read(toolkitProvider.notifier)
                    .keepProposal(name: _name?.text);
                context.go(ToolkitPage.location);
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              child: ThirtyTextAction(
                label: run.kind == PathKind.build
                    ? 'Don’t keep it'
                    : 'Keep things as they are',
                onPressed: () {
                  ref.read(toolkitProvider.notifier).setAsideProposal();
                  context.go(ToolkitPage.location);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _answerWords(PastUsefulness? answer) => switch (answer) {
    PastUsefulness.veryUseful => 'you said very useful',
    PastUsefulness.somewhatUseful => 'you said somewhat useful',
    PastUsefulness.notUseful => 'you said not useful',
    null => 'not answered',
  };
}
