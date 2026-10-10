import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';
import '../../application/activity_catalog.dart';
import '../../domain/recommendation_engine.dart';

/// "Not this one today" (V2 Phase B): asks what is in the way, in a few
/// words, and returns it — or `null` if the user changes their mind. One
/// answer gives one replacement; there is no list and no browsing.
///
/// "Can't go outside" is only offered when [current] is an outdoor activity.
Future<ReplacementReason?> showNotThisOneSheet(
  BuildContext context, {
  required ActivityId current,
}) {
  final colors = Theme.of(context).extension<AppColors>()!;
  return showModalBottomSheet<ReplacementReason>(
    context: context,
    useRootNavigator: true,
    // TalkBack names the backdrop by what it does.
    barrierLabel: 'Close',
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => NotThisOneSheet(current: current),
  );
}

/// The reasons [showNotThisOneSheet] offers for [current].
List<ReplacementReason> replacementReasonsFor(ActivityId current) => [
  if (activityDefinition(current).setting == ActivitySetting.outdoor)
    ReplacementReason.cantGoOutside,
  ReplacementReason.tooMuch,
  ReplacementReason.notFeeling,
];

/// What each reason says.
String replacementReasonLabel(ReplacementReason reason) => switch (reason) {
  ReplacementReason.cantGoOutside => 'Can’t go outside',
  ReplacementReason.tooMuch => 'Too much for today',
  ReplacementReason.notFeeling => 'Not feeling this one',
};

class NotThisOneSheet extends StatelessWidget {
  const NotThisOneSheet({required this.current, super.key});

  final ActivityId current;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.xl + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'What’s in the way today?',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'THIRTY will offer one other thing.',
            style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.m),
          for (final reason in replacementReasonsFor(current)) ...[
            ThirtyButton(
              label: replacementReasonLabel(reason),
              variant: ThirtyButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(reason),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}
