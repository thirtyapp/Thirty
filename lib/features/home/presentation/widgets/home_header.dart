import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/branding/thirty_brand_lockup.dart';
import '../../../../core/theme/design_tokens.dart';

/// Home's brand lockup (Phase D1): the shared [ThirtyBrandLockup] at
/// 96pt, top-left in Home's header, announced as the header "THIRTY" with
/// the tagline read after it. Fixed size at every text scale, which is
/// what lets Home's header keep a fixed height.
class HomeBrandLockup extends StatelessWidget {
  const HomeBrandLockup({super.key});

  static const wordmarkWidth = 96.0;
  static const tagline = ThirtyBrandLockup.tagline;

  /// Small enough that the tagline stays within the wordmark's width, so
  /// the Circle's top curve can rise beside the lockup (Design vision).
  static const taglineFontSize = 8.0;

  /// The lockup's fixed box: the wordmark's width, which the tagline never
  /// exceeds, and room for the wordmark plus the two-line tagline. Fixed so
  /// Home can place the Circle's top curve beside it.
  static const width = wordmarkWidth;
  static const height = 50.0;

  @override
  Widget build(BuildContext context) {
    // Scale down, never overflow: the box is a hard bound the Circle's
    // placement relies on, whatever the platform font does to the tagline.
    return const SizedBox(
      width: width,
      height: height,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topLeft,
        child: ThirtyBrandLockup(
          wordmarkWidth: wordmarkWidth,
          headerLabel: 'THIRTY',
          taglineFontSize: taglineFontSize,
        ),
      ),
    );
  }
}

/// Home's header row (Phase D1): the brand lockup on the left gutter, the
/// profile button on the right. It sits at the top of Home's scroll view
/// and scrolls away with the Circle — never pinned over it — so the Circle
/// can rise beside the lockup (Design vision) and is never covered.
class HomeHeader extends StatelessWidget {
  const HomeHeader({required this.showLockup, super.key});

  /// Tall enough for the fixed-size lockup and the 48pt profile button.
  static const height = 72.0;

  /// The lockup is always laid out, only faded, so the header's height and
  /// the Circle's position never change when it appears.
  final bool showLockup;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        child: Row(
          children: [
            AnimatedOpacity(
              opacity: showLockup ? 1 : 0,
              duration: reducedMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              child: const HomeBrandLockup(),
            ),
            const Spacer(),
            // Phase D1 — a round shortcut to You, visible in every state.
            const HomeProfileButton(),
          ],
        ),
      ),
    );
  }
}

/// The round profile button in Home's header (Phase D1): a shortcut to
/// the You tab — the same destination as the bottom nav's "You", never an
/// account or profile of its own.
class HomeProfileButton extends StatelessWidget {
  const HomeProfileButton({super.key});

  static const size = 48.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    return Semantics(
      button: true,
      label: 'Open You',
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: theme.brightness == Brightness.light
              ? AppShadows.light
              : AppShadows.dark,
        ),
        child: Material(
          color: colors.surface,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.go('/settings'),
            child: SizedBox.square(
              dimension: size,
              child: Icon(Icons.person_outline, color: colors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
