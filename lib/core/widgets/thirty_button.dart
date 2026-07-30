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
              borderRadius: AppRadius.medium,
              side: borderSide,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _isEnabled ? onPressed : null,
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
