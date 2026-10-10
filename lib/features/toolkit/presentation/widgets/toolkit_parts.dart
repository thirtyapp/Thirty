import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_card.dart';
import '../../../home/application/activity_catalog.dart';
import '../../domain/module_library.dart';
import '../../domain/toolkit_model.dart';

/// The Toolkit's quiet building blocks — the memory page's own: a small
/// spaced-capitals heading over one card of divided rows. No badges, no
/// gold, no progress bars.
class ToolkitSection extends StatelessWidget {
  const ToolkitSection({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToolkitEyebrow(title),
        const SizedBox(height: AppSpacing.s),
        // Its own node: a card's plain text would otherwise merge into the
        // page's list item and be read before its heading (S25 TalkBack).
        Semantics(container: true, child: child),
      ],
    );
  }
}

class ToolkitEyebrow extends StatelessWidget {
  const ToolkitEyebrow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        semanticsLabel: text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.textSecondary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

/// One card holding [rows], divided.
class ToolkitRows extends StatelessWidget {
  const ToolkitRows({required this.rows, super.key});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return ThirtyCard(
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
    );
  }
}

/// A row: a title, one line of detail, and — when it opens something — a
/// chevron. One TalkBack stop, read as "title. detail".
class ToolkitRow extends StatelessWidget {
  const ToolkitRow({
    required this.title,
    required this.detail,
    this.eyebrow,
    this.onTap,
    this.muted = false,
    super.key,
  });

  final String title;
  final String detail;

  /// A small line above [title] ("Circle 4"), so a long title keeps the
  /// full width of its own line.
  final String? eyebrow;
  final VoidCallback? onTap;

  /// A turned-off routine: still shown, quieter.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (eyebrow case final eyebrow?) ...[
                    Text(
                      eyebrow.toUpperCase(),
                      semanticsLabel: eyebrow,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(
                      color: muted ? colors.textSecondary : colors.textPrimary,
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
            if (onTap != null) ...[
              const SizedBox(width: AppSpacing.s),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: colors.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
    // Each row its own stop, never merged with its neighbours.
    return Semantics(
      container: true,
      button: onTap != null,
      label: [?eyebrow, title, detail].join('. '),
      onTap: onTap,
      excludeSemantics: true,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

/// A quiet secondary line.
class ToolkitNote extends StatelessWidget {
  const ToolkitNote(this.text, {this.liveRegion = false, super.key});

  final String text;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final note = Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
    );
    // Its own stop, where it stands — never gathered into what surrounds it.
    return Semantics(container: true, liveRegion: liveRegion, child: note);
  }
}

/// "Standing stretch, then Move to music".
String piecesLine(Composition composition) {
  final names = [for (final use in composition.uses) use.definition.name];
  return [
    names.first,
    for (final name in names.skip(1))
      '${name[0].toLowerCase()}${name.substring(1)}',
  ].join(', then ');
}

/// "More Energy · about 15 minutes".
String routineLine(Routine routine) =>
    '${intentionLabel(routine.need)} · about ${routine.active.minutes} '
    'minutes';
