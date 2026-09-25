import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_card.dart';

/// One grouped surface for You's plain rows (Phase C1): a single
/// [ThirtyCard] with hairline dividers between rows, instead of one card
/// per control. Rows are inset by [AppSpacing.featuredCard], the same as
/// the Premium card's content, so every text edge on You lines up.
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

/// A row inside a [YouGroupCard]: the shared vertical rhythm.
class YouRow extends StatelessWidget {
  const YouRow({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
      child: child,
    );
  }
}

/// A tappable text row inside a [YouGroupCard] (e.g. "Copy as text",
/// "Delete all"). [destructive] renders the label in the AA `errorText`
/// role, the same as every other destructive action since Phase A5. A
/// `null` [onTap] disables it.
class YouActionRow extends StatelessWidget {
  const YouActionRow({
    required this.label,
    required this.onTap,
    this.destructive = false,
    super.key,
  });

  final String label;
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
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(color: color),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
