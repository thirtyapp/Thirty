import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../premium/application/premium_offer_provider.dart';
import '../../../reminder/application/reminder_invitation_provider.dart';

/// Home's "LATER TODAY" section label (Phase D1, Design vision): heads the
/// follow-ups that come after today's Circle — the reminder or Premium
/// invitation (their V1 priority order is unchanged; V2 Phase C moved the
/// reflection into the Circle). Shown only while one of them is actually
/// showing, so it never labels an empty section. A semantic header, read as
/// "Later today".
class LaterTodayLabel extends ConsumerWidget {
  const LaterTodayLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anyShowing =
        ref.watch(showReminderInvitationProvider) ||
        ref.watch(showPremiumOfferInvitationProvider);
    if (!anyShowing) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.s,
        AppSpacing.page,
        AppSpacing.m,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Semantics(
          header: true,
          child: Text(
            'LATER TODAY',
            semanticsLabel: 'Later today',
            style: textTheme.labelSmall?.copyWith(
              color: colors.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
