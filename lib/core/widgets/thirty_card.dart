import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// A calm, reusable surface container with consistent padding, radius and
/// a subtle border/shadow. Supports light and dark mode via the theme.
class ThirtyCard extends StatelessWidget {
  const ThirtyCard({required this.child, this.padding, this.onTap, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// Null makes the card a plain, non-interactive surface: no gesture
  /// detection and no ripple layer are added.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final shadow = theme.brightness == Brightness.light
        ? AppShadows.light
        : AppShadows.dark;

    final content = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.card),
      decoration: BoxDecoration(
        borderRadius: AppRadius.medium,
        border: Border.all(color: colors.border),
      ),
      child: child,
    );

    final surface = Material(
      color: colors.surface,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.medium,
        boxShadow: shadow,
      ),
      child: ClipRRect(borderRadius: AppRadius.medium, child: surface),
    );
  }
}
