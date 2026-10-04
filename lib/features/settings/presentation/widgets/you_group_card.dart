import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_card.dart';

/// A section heading on You ("Preferences", "Data & privacy", "About"),
/// announced as a header.
class YouSectionHeading extends StatelessWidget {
  const YouSectionHeading(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

/// One grouped surface for You's plain rows (Phase C1): a single
/// [ThirtyCard] with hairline dividers between rows, instead of one card
/// per control. Rows are inset by [AppSpacing.featuredCard], the same as
/// the Premium card's content, so every content edge on You lines up.
class YouGroupCard extends StatelessWidget {
  const YouGroupCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ThirtyCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.featuredCard,
        vertical: AppSpacing.s,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A row inside a [YouGroupCard]: the shared vertical rhythm, with an
/// optional decorative leading [icon] beside the row's content.
class YouRow extends StatelessWidget {
  const YouRow({required this.child, this.icon, super.key});

  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
      child: icon == null
          ? child
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                YouRowIcon(icon!),
                const SizedBox(width: AppSpacing.m),
                Expanded(child: child),
              ],
            ),
    );
  }
}

/// A row's leading icon: decorative (the row's own text carries the
/// meaning), quiet, and centred on the first line of the row's title —
/// at any text size, so a title that wraps at large text keeps its icon
/// beside its first line rather than drifting to the middle of the block.
/// Place it in a top-aligned row; [lineStyle] is the title's text style
/// (the [YouRowTitle] style by default).
class YouRowIcon extends StatelessWidget {
  const YouRowIcon(this.icon, {this.color, this.lineStyle, super.key});

  static const size = 22.0;

  final IconData icon;
  final Color? color;
  final TextStyle? lineStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final style = lineStyle ?? theme.textTheme.bodyLarge!;
    final lineHeight =
        MediaQuery.textScalerOf(context).scale(style.fontSize!) *
        (style.height ?? 1);
    return ExcludeSemantics(
      child: Padding(
        padding: EdgeInsets.only(
          top: lineHeight > size ? (lineHeight - size) / 2 : 0,
        ),
        child: Icon(icon, size: size, color: color ?? colors.textSecondary),
      ),
    );
  }
}

/// A row title on You: the primary text of a Preferences / data / About row.
class YouRowTitle extends StatelessWidget {
  const YouRowTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    return Text(
      text,
      style: theme.textTheme.bodyLarge?.copyWith(color: colors.textPrimary),
    );
  }
}

/// A row's supporting line on You, under its [YouRowTitle].
class YouRowDetail extends StatelessWidget {
  const YouRowDetail(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
    );
  }
}

/// A tappable text row inside a [YouGroupCard] (e.g. "Copy as text",
/// "Delete Circle history"), with a decorative leading [icon].
/// [destructive] renders the label and icon in the AA `errorText` role,
/// the same as every other destructive action since Phase A5 — and the
/// label itself names the destruction, so it never rests on colour alone.
/// A `null` [onTap] disables it.
class YouActionRow extends StatelessWidget {
  const YouActionRow({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final enabled = onTap != null;
    final color = !enabled
        ? colors.textSecondary
        : destructive
        ? colors.errorText
        : colors.primary;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  YouRowIcon(
                    icon,
                    color: color,
                    lineStyle: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
