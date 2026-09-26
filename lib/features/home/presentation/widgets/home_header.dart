import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/branding/thirty_wordmark_view.dart';
import '../../../../core/theme/design_tokens.dart';

/// Home's brand lockup (Phase D1): the THIRTY wordmark with the tagline
/// beneath it, top-left in Home's header.
///
/// A logotype, so it keeps one fixed size at every text scale (WCAG 1.4.4
/// exempts text that is part of a logo) — that is what lets Home's header
/// keep a fixed height. The wordmark is announced as the header "THIRTY";
/// the tagline is read as ordinary text after it.
class HomeBrandLockup extends StatelessWidget {
  const HomeBrandLockup({super.key});

  static const wordmarkWidth = 96.0;
  static const tagline = 'A brighter you in small steps';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return MediaQuery.withNoTextScaling(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            label: 'THIRTY',
            child: const SizedBox(
              width: wordmarkWidth,
              child: ThirtyWordmarkView(),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A BRIGHTER YOU\nIN SMALL STEPS',
            semanticsLabel: tagline,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 9.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.2,
              color: colors.textSecondary,
            ),
          ),
        ],
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
