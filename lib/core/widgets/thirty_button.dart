import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// The two button styles THIRTY allows: one primary action, one secondary.
enum ThirtyButtonVariant { primary, secondary }

/// THIRTY's single button component, covering both variants and the
/// enabled, disabled and loading states.
class ThirtyButton extends StatelessWidget {
  const ThirtyButton({
    required this.label,
    required this.onPressed,
    this.variant = ThirtyButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    super.key,
  });

  final String label;

  /// Null makes the button appear and behave as disabled.
  final VoidCallback? onPressed;
  final ThirtyButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  bool get _isEnabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final isPrimary = variant == ThirtyButtonVariant.primary;

    final Color backgroundColor;
    final Color foregroundColor;
    final BorderSide borderSide;

    if (!_isEnabled) {
      backgroundColor = isPrimary ? colors.disabled : Colors.transparent;
      foregroundColor = colors.textSecondary;
      borderSide = isPrimary
          ? BorderSide.none
          : BorderSide(color: colors.disabled);
    } else if (isPrimary) {
      backgroundColor = colors.primary;
      foregroundColor = theme.colorScheme.onPrimary;
      borderSide = BorderSide.none;
    } else {
      backgroundColor = Colors.transparent;
      foregroundColor = colors.primary;
      borderSide = BorderSide(color: colors.primary);
    }

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: foregroundColor),
          const SizedBox(width: AppSpacing.s),
        ],
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(color: foregroundColor),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: _isEnabled,
      liveRegion: isLoading,
      label: isLoading ? '$label, bezig' : label,
      onTap: _isEnabled ? onPressed : null,
      child: ExcludeSemantics(
        child: SizedBox(
          height: 48,
          child: Material(
            color: backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.small,
              side: borderSide,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _isEnabled ? onPressed : null,
              // Quiet pressed feedback instead of the default expanding
              // splash — that spreading-circle motion reads as more
              // "default Flutter" than "THIRTY calm" for the product's one
              // primary action. NoSplash suppresses only the splash
              // animation; app_theme.dart's app-wide splashFactory is
              // untouched, so every other InkWell in the app keeps it.
              splashFactory: NoSplash.splashFactory,
              // Variant-aware, not foregroundColor-reused: a uniform
              // light overlay lightens primary's sage fill toward its
              // white label (reducing contrast) while the same tint
              // darkens secondary's near-white surface toward its sage
              // label (also reducing contrast) — the two variants sit on
              // opposite sides of the fill/label contrast, so the same
              // direction cannot serve both. Primary darkens (toward
              // colors.textPrimary, 8%) — pressed contrast ≈5.51:1,
              // stronger than resting. Secondary keeps its own tone at a
              // lower 3% (toward colors.primary, the same color it
              // already uses at rest) — pressed contrast ≈4.57:1. Both
              // clear WCAG AA 4.5:1; the original single-alpha, single-
              // color version did not (≈4.27:1 / ≈4.30:1). Only
              // `pressed` is resolved; returning null for every other
              // state leaves InkWell's own default hover/focus treatment
              // in place.
              overlayColor: WidgetStateProperty.resolveWith<Color?>((
                states,
              ) {
                if (!states.contains(WidgetState.pressed)) {
                  return null;
                }
                return switch (variant) {
                  ThirtyButtonVariant.primary => colors.textPrimary
                      .withValues(alpha: 0.08),
                  ThirtyButtonVariant.secondary => colors.primary
                      .withValues(alpha: 0.03),
                };
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Kept in the layout (but invisible) while loading so the
                    // button's size is driven by its normal content and
                    // doesn't shift when the spinner appears.
                    Visibility(
                      visible: !isLoading,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: content,
                    ),
                    if (isLoading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(foregroundColor),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
