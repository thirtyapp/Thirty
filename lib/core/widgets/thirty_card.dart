import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// A calm, reusable surface container with consistent padding, radius and
/// a soft layered shadow. Supports light and dark mode via the theme.
///
/// Borderless in both modes, per the soft, layered surface language (Brand
/// Book §12/§15). In light mode the white surface and [AppShadows.light]
/// carry the separation; in dark mode the one-step tonal lift of
/// [AppColors.surface] over the page does, matching the floating nav
/// (`docs/DESIGN_SYSTEM.md` §4.4).
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
      child: child,
    );

    final surface = Material(
      color: colors.surface,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );

    return Container(
      decoration: BoxDecoration(borderRadius: AppRadius.xl, boxShadow: shadow),
      child: ClipRRect(borderRadius: AppRadius.xl, child: surface),
    );
  }
}
