import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_text_action.dart';
import '../../application/activity_catalog.dart';

/// Opens the full how-to for today's activity — the progressive-disclosure
/// layer behind the Today card (V2 Phase A). The Circle itself only shows
/// the activity, its length and what to do first; everything else lives
/// here, one tap away.
///
/// [offeredMinutes] is today's real length of the activity; [onNotThisOne],
/// when given, offers today's one "Not this one today" (V2 Phase B).
Future<void> showActivityGuide(
  BuildContext context, {
  required ActivityId activityId,
  required Intention intention,
  int? offeredMinutes,
  VoidCallback? onNotThisOne,
}) {
  final colors = Theme.of(context).extension<AppColors>()!;
  return showModalBottomSheet<void>(
    context: context,
    // Above the app shell, so the floating nav bar never covers the sheet.
    useRootNavigator: true,
    // TalkBack names the backdrop by what it does.
    barrierLabel: 'Close',
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ActivityGuideSheet(
      activityId: activityId,
      intention: intention,
      offeredMinutes: offeredMinutes,
      onNotThisOne: onNotThisOne,
    ),
  );
}

/// The how-to content for one activity, ordered the way you would use it:
/// what it is, what to do first, what to have ready, how it goes, and how
/// it ends.
class ActivityGuideSheet extends StatelessWidget {
  const ActivityGuideSheet({
    super.key,
    required this.activityId,
    required this.intention,
    this.offeredMinutes,
    this.onNotThisOne,
  });

  final ActivityId activityId;
  final Intention intention;

  /// Today's length; the activity's usual length when `null`.
  final int? offeredMinutes;

  /// "Not this one today": closes this sheet and asks why. `null` once used,
  /// once started, or for a Plan stage.
  final VoidCallback? onNotThisOne;

  @override
  Widget build(BuildContext context) {
    final activity = activityDefinition(activityId);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final titleStyle = AppTypography.editorialDisplay(
      colors,
    ).copyWith(fontSize: 26, height: 1.2);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, controller) => ListView(
        controller: controller,
        // The sheet runs beneath the system navigation bar (useSafeArea
        // guards only the top and sides), so its last line must scroll
        // clear of it — on the S25's button bar it otherwise stayed
        // underneath at full scroll.
        padding: EdgeInsets.fromLTRB(
          AppSpacing.page,
          0,
          AppSpacing.page,
          AppSpacing.xl + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          if (activity.status == ActivityStatus.safetyReviewPending)
            const _DraftNotice(),
          Semantics(
            header: true,
            child: Text(activity.title, style: titleStyle),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _lengthLabel(activity, offeredMinutes),
            style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            activityReasonFor(intention, activityId),
            style: textTheme.bodyLarge,
          ),
          // Quiet, and only here: the card's room above Start Circle is
          // spoken for, and this is where the activity is being weighed up.
          if (onNotThisOne case final notThisOne?)
            ThirtyTextAction(
              label: 'Not this one today',
              onPressed: () {
                Navigator.of(context).pop();
                notThisOne();
              },
            ),
          _Section(
            label: 'First',
            child: Text(
              activity.firstAction,
              style: textTheme.bodyLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (activity.preparation case final preparation?)
            _Section(
              label: 'You’ll need',
              child: Text(preparation, style: textTheme.bodyMedium),
            ),
          if (activity.steps.isNotEmpty)
            _Section(
              label: 'Steps',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (index, step) in activity.steps.indexed)
                    _StepRow(number: index + 1, step: step),
                ],
              ),
            ),
          if (activity.whileYoureThere.isNotEmpty)
            _Section(
              label: 'While you’re there',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final idea in activity.whileYoureThere)
                    _Bullet(text: idea),
                ],
              ),
            ),
          if (activity.lighter case final lighter?)
            _Section(
              label: 'Short on time',
              child: Text(lighter, style: textTheme.bodyMedium),
            ),
          if (activity.safetyNote case final safetyNote?)
            _Section(
              label: 'Go gently',
              child: Text(safetyNote, style: textTheme.bodyMedium),
            ),
          _Section(
            label: 'To finish',
            child: Text(activity.ending, style: textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  static String _lengthLabel(ActivityDefinition activity, int? offered) {
    final minutes = offered ?? activity.typicalMinutes;
    return activity.minMinutes < minutes
        ? 'About $minutes minutes · ${activity.minMinutes} works too'
        : 'About $minutes minutes';
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              label.toUpperCase(),
              semanticsLabel: label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          child,
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.step});

  final int number;
  final GuidedStep step;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.secondary,
              ),
              child: Text(
                '$number',
                semanticsLabel: 'Step $number:',
                style: textTheme.labelMedium?.copyWith(color: colors.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.name,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(step.instruction, style: textTheme.bodyMedium),
                  const SizedBox(height: 2),
                  Text(
                    step.cue,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, right: AppSpacing.m),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Shown only on internal builds, where drafts awaiting the safety/content
/// review can be inspected. Release builds never offer such an activity.
class _DraftNotice extends StatelessWidget {
  const _DraftNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      padding: const EdgeInsets.all(AppSpacing.s),
      decoration: BoxDecoration(
        borderRadius: AppRadius.small,
        border: Border.all(color: colors.warning),
      ),
      child: Text(
        'Internal draft — awaiting safety review. Not shown in released '
        'builds.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
