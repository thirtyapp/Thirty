import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_text_action.dart';
import '../../application/circle_journal.dart';
import '../../application/recommendation_provider.dart';
import 'feedback_acknowledgement.dart';
import 'today_card.dart';

/// The closed Circle's reflection (V2 Phase C, ADR-021), inline under the
/// Circle in place of the Today card: "Did you try it?", then — only after
/// "Yes" or "A little" — "Was it useful?", then what that answer changes.
///
/// Optional throughout: no answer is a fine answer, and nothing here says
/// the activity was done. Close is only an app interaction; the user's own
/// answer is the only account of what happened.
class CircleReflectionCard extends ConsumerStatefulWidget {
  const CircleReflectionCard({super.key});

  static const attemptQuestion = 'Did you try it?';
  static const usefulnessQuestion = 'Was it useful?';
  static const memoryLink = 'What THIRTY remembers';

  @override
  ConsumerState<CircleReflectionCard> createState() =>
      _CircleReflectionCardState();
}

enum _Stage { attempt, usefulness, answered }

class _CircleReflectionCardState extends ConsumerState<CircleReflectionCard> {
  /// Where the card stood when it first appeared. Only a step the user's
  /// own answer brings on takes TalkBack's focus — never the first look.
  _Stage? _arrivedAt;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recommendationProvider);
    final recommendation = state.recommendation;
    if (recommendation == null) return const SizedBox.shrink();
    final notifier = ref.read(recommendationProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;

    final attempt = state.attemptResponse;
    final affirmative =
        attempt == CircleAttemptResponse.yes ||
        attempt == CircleAttemptResponse.aLittle;
    final acknowledgement = feedbackAcknowledgement(state);
    final stage = attempt == null
        ? _Stage.attempt
        : affirmative && state.usefulnessResponse == null
        ? _Stage.usefulness
        : _Stage.answered;
    _arrivedAt ??= stage;
    // The tile just answered is gone: TalkBack is taken to what replaced it,
    // so it reads the next question, or the acknowledgement, once.
    final takeFocus = stage != _arrivedAt;

    final title = Text(
      recommendation.activity,
      style: textTheme.bodyLarge?.copyWith(
        color: colors.primary,
        fontWeight: FontWeight.w600,
      ),
    );

    final Widget first;
    final Widget second;
    if (stage == _Stage.attempt) {
      first = _Question(
        title: title,
        question: CircleReflectionCard.attemptQuestion,
      );
      second = _AnswerTiles(
        answers: [
          ('Yes', () => notifier.reportAttempt(CircleAttemptResponse.yes)),
          (
            'A little',
            () => notifier.reportAttempt(CircleAttemptResponse.aLittle),
          ),
          (
            'Not today',
            () => notifier.reportAttempt(CircleAttemptResponse.notToday),
          ),
        ],
      );
    } else if (stage == _Stage.usefulness) {
      first = _Question(
        key: const ValueKey(_Stage.usefulness),
        title: title,
        question: CircleReflectionCard.usefulnessQuestion,
        takeFocus: takeFocus,
      );
      second = _AnswerTiles(
        answers: [
          (
            'Very useful',
            () =>
                notifier.reportUsefulness(CircleUsefulnessResponse.veryUseful),
          ),
          (
            'Somewhat useful',
            () => notifier.reportUsefulness(
              CircleUsefulnessResponse.somewhatUseful,
            ),
          ),
          (
            'Not useful',
            () => notifier.reportUsefulness(CircleUsefulnessResponse.notUseful),
          ),
        ],
      );
    } else {
      first = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          title,
          const SizedBox(height: AppSpacing.xs),
          _FocusOnArrival(
            key: const ValueKey(_Stage.answered),
            enabled: takeFocus,
            child: Text(
              acknowledgement ?? '',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      );
      second = ThirtyTextAction(
        label: CircleReflectionCard.memoryLink,
        onPressed: () => context.push('/memory'),
      );
    }

    return HomeCardShell(first: first, second: second);
  }
}

class _Question extends StatelessWidget {
  const _Question({
    required this.title,
    required this.question,
    this.takeFocus = false,
    super.key,
  });

  final Widget title;
  final String question;
  final bool takeFocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        title,
        const SizedBox(height: AppSpacing.xs),
        _FocusOnArrival(
          enabled: takeFocus,
          child: Semantics(
            header: true,
            child: Text(
              question,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
      ],
    );
  }
}

/// Takes input focus once, as it appears, when [enabled] — which TalkBack
/// follows, reading [child] once. Nothing is drawn for it.
class _FocusOnArrival extends StatefulWidget {
  const _FocusOnArrival({
    required this.enabled,
    required this.child,
    super.key,
  });

  final bool enabled;
  final Widget child;

  @override
  State<_FocusOnArrival> createState() => _FocusOnArrivalState();
}

class _FocusOnArrivalState extends State<_FocusOnArrival> {
  final _node = FocusNode(skipTraversal: true);

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _node.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Focus(focusNode: _node, child: widget.child);
}

/// Three answers side by side while their labels fit (two lines at most),
/// otherwise stacked at full width — never truncated.
class _AnswerTiles extends StatelessWidget {
  const _AnswerTiles({required this.answers});

  final List<(String, VoidCallback)> answers;

  static const _gap = AppSpacing.s;
  static const _inset = AppSpacing.s;

  TextStyle? _style(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium;

  bool _fitSideBySide(BuildContext context, double width) {
    final tileWidth = (width - _gap * (answers.length - 1)) / answers.length;
    for (final (label, _) in answers) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: _style(context)),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        textAlign: TextAlign.center,
        maxLines: 2,
      )..layout(maxWidth: tileWidth - _inset * 2);
      final fits = !painter.didExceedMaxLines;
      painter.dispose();
      if (!fits) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = _fitSideBySide(context, constraints.maxWidth);
        final tiles = [
          for (final (label, onTap) in answers)
            _AnswerTile(label: label, onTap: onTap),
        ];
        if (sideBySide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, tile) in tiles.indexed) ...[
                  if (index > 0) const SizedBox(width: _gap),
                  Expanded(child: tile),
                ],
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (index, tile) in tiles.indexed) ...[
              if (index > 0) const SizedBox(height: AppSpacing.xs),
              tile,
            ],
          ],
        );
      },
    );
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.medium,
          side: BorderSide(color: colors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _AnswerTiles._inset,
                vertical: AppSpacing.s,
              ),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
