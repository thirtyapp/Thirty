import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../application/recommendation_provider.dart';
import '../../domain/recommendation_engine.dart';

/// "Time you have" (V2 Phase B): a quiet three-way choice on the Daily
/// Context Question, already set to the last explicit choice (≈ 20 minutes
/// on first use) — so choosing a need stays the only tap most days.
///
/// It means room, not a target: a 5-minute activity is a fine answer to
/// "about 10".
class TimeWindowChoiceControl extends ConsumerWidget {
  const TimeWindowChoiceControl({super.key});

  /// What each segment shows, and what it means.
  static String label(TimeWindow window) => switch (window) {
    TimeWindow.about10 => '10 min',
    TimeWindow.about20 => '20 min',
    TimeWindow.upTo30 => '30 min',
  };

  static String meaning(TimeWindow window) => switch (window) {
    TimeWindow.about10 => 'About 10 minutes',
    TimeWindow.about20 => 'About 20 minutes',
    TimeWindow.upTo30 => 'Up to 30 minutes',
  };

  // Material 3 SegmentedButton chrome around a label without the selected
  // check: 12pt side padding and the 1pt border.
  static const _segmentChrome = 12.0 * 2 + 2;

  /// Quieter than the three needs it sits above: narrower, compact, and
  /// in small, muted type.
  static const _maxWidth = 264.0;

  static TextStyle? _labelStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall;

  static bool _segmentsFit(BuildContext context, double width) {
    final segmentWidth = width / TimeWindow.values.length;
    for (final window in TimeWindow.values) {
      final painter = TextPainter(
        text: TextSpan(text: label(window), style: _labelStyle(context)),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final fits = painter.width + _segmentChrome <= segmentWidth;
      painter.dispose();
      if (!fits) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final chosen = ref.watch(timeWindowChoiceProvider);
    void choose(TimeWindow window) =>
        ref.read(timeWindowChoiceProvider.notifier).choose(window);

    return Semantics(
      container: true,
      label: 'Time you have',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Text(
              'Time you have',
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth < _maxWidth
                  ? constraints.maxWidth
                  : _maxWidth;
              if (_segmentsFit(context, width)) {
                return Center(
                  child: SizedBox(
                    width: width,
                    child: SegmentedButton<TimeWindow>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        // A full 48pt touch target, however light it looks.
                        tapTargetSize: MaterialTapTargetSize.padded,
                        textStyle: _labelStyle(context),
                        foregroundColor: colors.textSecondary,
                        // Full-contrast text on the selection, in both
                        // themes (sage on dark sage was illegible).
                        selectedForegroundColor: colors.textPrimary,
                        selectedBackgroundColor: colors.secondary,
                        side: BorderSide(color: colors.divider),
                      ),
                      segments: [
                        for (final window in TimeWindow.values)
                          ButtonSegment(
                            value: window,
                            label: Text(
                              label(window),
                              semanticsLabel: meaning(window),
                            ),
                          ),
                      ],
                      selected: {chosen},
                      onSelectionChanged: (selection) =>
                          choose(selection.first),
                    ),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final window in TimeWindow.values)
                    _ChoiceRow(
                      label: meaning(window),
                      selected: window == chosen,
                      onTap: () => choose(window),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A full-width choice row for when large text no longer fits three
/// segments side by side.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: selected,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                // The check (not colour alone) carries the selection.
                if (selected) Icon(Icons.check, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
