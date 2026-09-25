import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// The two button styles THIRTY allows: one primary action, one secondary.
enum ThirtyButtonVariant { primary, secondary }

/// Button heights. [regular] (48pt) is every button's default; [hero]
/// (56pt) is opt-in and reserved for a screen's one main CTA — in Phase B,
/// only Home's lifecycle CTA.
enum ThirtyButtonSize { regular, hero }

/// THIRTY's single button component, covering both variants and the
/// enabled, disabled and loading states.
class ThirtyButton extends StatelessWidget {
  const ThirtyButton({
    required this.label,
    required this.onPressed,
    this.variant = ThirtyButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.size = ThirtyButtonSize.regular,
    super.key,
  });

  final String label;

  /// Null makes the button appear and behave as disabled.
  final VoidCallback? onPressed;
  final ThirtyButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  /// A forward cue after the label (e.g. an arrow). Decorative: the label
  /// alone carries the button's semantics.
  final IconData? trailingIcon;
  final ThirtyButtonSize size;

  static const _trailingIconSize = 20.0;

  /// Large accessibility text wraps a label onto a second line before it
  /// is ever ellipsized.
  static const _maxLabelLines = 2;

  /// Room for the trailing icon plus its gap to the label; reserved on
  /// both sides so the label stays centered.
  static const _trailingSlotWidth = _trailingIconSize + AppSpacing.s;

  /// From this text scale up, the label gets the tighter side inset.
  static const _largeTextScale = 1.3;

  /// The label's side inset: 24pt, tightened to 16pt at large
  /// accessibility text so a label has the width to fit in two lines.
  static double _horizontalInset(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1) >= _largeTextScale
      ? AppSpacing.m
      : AppSpacing.l;

  /// Whether [label] fits a plain (icon-less) button of [buttonWidth]
  /// without being ellipsized — i.e. in at most two lines, measured with
  /// exactly the style, inset and text scale this button renders with.
  /// Lets a caller choose a layout (e.g. side-by-side vs stacked) that
  /// never truncates.
  static bool labelFits(
    BuildContext context,
    String label, {
    required double buttonWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: Theme.of(context).textTheme.labelLarge,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: _maxLabelLines,
    )..layout(maxWidth: buttonWidth - _horizontalInset(context) * 2);
    final fits = !painter.didExceedMaxLines;
    painter.dispose();
    return fits;
  }

  bool get _isEnabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final horizontalInset = _horizontalInset(context);
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

    final labelRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: foregroundColor),
          const SizedBox(width: AppSpacing.s),
        ],
        // `Flexible` (not a plain `Text`) — Batch C found this Row
        // overflowing on a small-width button (e.g. two side by side in
        // `circle_history_page.dart`) combined with a longer label or a
        // large accessibility text scale: a non-flex child in a `Row` is
        // measured at its unconstrained preferred width regardless of
        // available space. `Flexible` lets it shrink instead — normal-width
        // buttons render identically, since this only engages when the
        // label genuinely does not fit. Since the large-text foundation
        // pass it first wraps to a second line (the button grows past its
        // minimum height), and only a label that needs more than two lines
        // ellipsizes.
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: foregroundColor,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: _maxLabelLines,
          ),
        ),
      ],
    );

    // With a trailing icon, the icon is pinned to the trailing edge and an
    // equal, empty slot is reserved on the leading edge, so the label stays
    // optically centered on the button (and on whatever axis the button is
    // centered on). Both slots are laid out, never overlaid: at large text
    // the label ellipsizes inside its own space instead of colliding with
    // the icon.
    final content = trailingIcon == null
        ? labelRow
        : Row(
            children: [
              const SizedBox(width: _trailingSlotWidth),
              // heightFactor: 1 — size to the label, never stretch to the
              // parent's height (the button's height is a minimum now, so
              // a bounded parent would otherwise make it that tall).
              Expanded(child: Center(heightFactor: 1, child: labelRow)),
              SizedBox(
                width: _trailingSlotWidth,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  heightFactor: 1,
                  child: Icon(
                    trailingIcon,
                    size: _trailingIconSize,
                    color: foregroundColor,
                  ),
                ),
              ),
            ],
          );

    // A minimum, not a fixed, height: at ordinary text sizes every button
    // is exactly 48pt (56pt hero) because its one-line content is shorter;
    // at large accessibility text a label that needs a second line grows
    // the button instead of being cut off.
    final button = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: switch (size) {
          ThirtyButtonSize.regular => 48,
          ThirtyButtonSize.hero => 56,
        },
      ),
      child: Material(
        color: backgroundColor,
        // Fully rounded (founder decision D2, Phase A3) at either
        // height.
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.pill,
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
            // The vertical inset only matters once a label wraps: it keeps
            // two lines clear of the pill's rounded ends. A one-line label
            // stays well inside the minimum height either way. At large
            // accessibility text the side inset tightens from 24 to 16 so
            // a label has the width to fit in two lines; at ordinary sizes
            // it is unchanged.
            padding: EdgeInsets.symmetric(
              horizontal: horizontalInset,
              vertical: AppSpacing.s,
            ),
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
    );

    return Semantics(
      button: true,
      enabled: _isEnabled,
      liveRegion: isLoading,
      label: isLoading ? '$label, bezig' : label,
      onTap: _isEnabled ? onPressed : null,
      child: ExcludeSemantics(
        // A trailing-icon button's Row fills its width (to pin the icon),
        // so IntrinsicWidth keeps the button sized like every other one:
        // its content's width, or wider only when its parent asks for it.
        child: trailingIcon == null ? button : IntrinsicWidth(child: button),
      ),
    );
  }
}
