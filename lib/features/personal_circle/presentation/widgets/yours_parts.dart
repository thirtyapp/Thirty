import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_card.dart';

/// Yours' quiet building blocks — the memory page's own: a small
/// spaced-capitals heading over one card of divided rows. No badges, no
/// gold, no progress bars.
class YoursSection extends StatelessWidget {
  const YoursSection({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        YoursEyebrow(title),
        const SizedBox(height: AppSpacing.s),
        // Its own node: a card's plain text would otherwise merge into the
        // page's list item and be read before its heading (S25 TalkBack).
        Semantics(container: true, child: child),
      ],
    );
  }
}

class YoursEyebrow extends StatelessWidget {
  const YoursEyebrow(this.text, {super.key});

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
class YoursRows extends StatelessWidget {
  const YoursRows({required this.rows, super.key});

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
class YoursRow extends StatelessWidget {
  const YoursRow({
    required this.title,
    required this.detail,
    this.onTap,
    super.key,
  });

  final String title;
  final String detail;
  final VoidCallback? onTap;

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
      label: [title, detail].join('. '),
      onTap: onTap,
      excludeSemantics: true,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

/// A quiet secondary line.
class YoursNote extends StatelessWidget {
  const YoursNote(this.text, {this.liveRegion = false, super.key});

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
