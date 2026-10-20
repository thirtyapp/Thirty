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
/// exactly what it does. [buildingOn] names the later parts that build on
/// this one and are skipped with it. [offerLeaveOut] is false without
/// Premium: Leave it out is a composer control, so a Free day's kept Circle
/// offers only today's skip.
Future<SkipChoice?> showSkipPartSheet(
  BuildContext context, {
  List<String> buildingOn = const [],
  bool offerLeaveOut = true,
}) {
  final colors = Theme.of(context).extension<AppColors>()!;
  return showModalBottomSheet<SkipChoice>(
    context: context,
    useRootNavigator: true,
    // TalkBack names the backdrop by what it does.
    barrierLabel: ComposedCopy.keepGoing,
    // Enlarged text needs more than the default sheet height; the content
    // then scrolls instead of overflowing (S25 finding at 130 %, D2).
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) =>
        SkipPartSheet(buildingOn: buildingOn, offerLeaveOut: offerLeaveOut),
  );
}

class SkipPartSheet extends StatelessWidget {
  const SkipPartSheet({
    super.key,
    this.buildingOn = const [],
    this.offerLeaveOut = true,
  });

  final List<String> buildingOn;
  final bool offerLeaveOut;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final detail = textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    return SingleChildScrollView(
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
              child: Text(
                ComposedCopy.skipTodayDetailFor(buildingOn),
                style: detail,
              ),
            ),
          ),
          if (offerLeaveOut) ...[
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
          ],
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
