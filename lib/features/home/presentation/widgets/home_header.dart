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

  @override
  Widget build(BuildContext context) {
    return const ThirtyBrandLockup(
      wordmarkWidth: wordmarkWidth,
      headerLabel: 'THIRTY',
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
