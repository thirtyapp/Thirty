import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/thirty_button.dart';
import '../domain/composed_session.dart';

/// What the user chose in [showSkipPartSheet].
enum SkipChoice {
  /// Skip the part on show for today only.
  today,

  /// Skip it, and leave it out of future Circles (reversible in Memory).
  leaveOut,
}

/// "Skip this step" (V2 Phase D2, ADR-023 §7): asks whether to skip the part
/// on show just for today, or to leave it out of future Circles too — or
/// `null` if the user keeps going. Neither answer is "Not useful": each says
/// exactly what it does.
Future<SkipChoice?> showSkipPartSheet(BuildContext context) {
  final colors = Theme.of(context).extension<AppColors>()!;
  return showModalBottomSheet<SkipChoice>(
    context: context,
    useRootNavigator: true,
    // TalkBack names the backdrop by what it does.
    barrierLabel: ComposedCopy.keepGoing,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const SkipPartSheet(),
  );
}

class SkipPartSheet extends StatelessWidget {
  const SkipPartSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final detail = textTheme.bodySmall?.copyWith(color: colors.textSecondary);
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
              ComposedCopy.skipTitle,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          ThirtyButton(
            label: ComposedCopy.skipToday,
            variant: ThirtyButtonVariant.secondary,
            onPressed: () => Navigator.of(context).pop(SkipChoice.today),
          ),
          Semantics(
            container: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.m,
              ),
              child: Text(ComposedCopy.skipTodayDetail, style: detail),
            ),
          ),
          ThirtyButton(
            label: ComposedCopy.leaveOut,
            variant: ThirtyButtonVariant.secondary,
            onPressed: () => Navigator.of(context).pop(SkipChoice.leaveOut),
          ),
          Semantics(
            container: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.m,
              ),
              child: Text(ComposedCopy.leaveOutDetail, style: detail),
            ),
          ),
          ThirtyButton(
            label: ComposedCopy.keepGoing,
            variant: ThirtyButtonVariant.secondary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
