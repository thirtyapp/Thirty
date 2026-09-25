import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

/// The System / Light / Dark choice (Phase C1): a [SegmentedButton] when
/// all three labels fit their segment on one line, and a stack of three
/// single-choice rows when they don't — the segmented control split
/// "System" mid-word at 360pt even at 100% text, and into single letters
/// at 200%. Same choices, same order, same semantics either way.
class ThemeModeChoice extends StatelessWidget {
  const ThemeModeChoice({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  static const _choices = [
    (ThemeMode.system, 'System'),
    (ThemeMode.light, 'Light'),
    (ThemeMode.dark, 'Dark'),
  ];

  // Material 3 SegmentedButton geometry around each label: 12pt side
  // padding, an 18pt selected check plus its 8pt gap, and the 1pt border.
  static const _segmentChrome = 12.0 * 2 + 18 + 8 + 2;

  static bool _segmentsFit(BuildContext context, double width) {
    final segmentWidth = width / _choices.length;
    for (final (_, label) in _choices) {
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
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
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Theme',
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (_segmentsFit(context, constraints.maxWidth)) {
            return SegmentedButton<ThemeMode>(
              segments: [
                for (final (mode, label) in _choices)
                  ButtonSegment(value: mode, label: Text(label)),
              ],
              selected: {value},
              onSelectionChanged: (selection) => onChanged(selection.first),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (mode, label) in _choices)
                _ChoiceRow(
                  label: label,
                  selected: mode == value,
                  onTap: () => onChanged(mode),
                ),
            ],
          );
        },
      ),
    );
  }
}

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
