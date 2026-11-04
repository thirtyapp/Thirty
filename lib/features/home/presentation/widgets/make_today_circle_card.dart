import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/premium/premium_access.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../application/recommendation_provider.dart';

/// The words of [MakeTodayCircleCard], in one place.
abstract final class MakeTodayCircleCopy {
  static const offer =
      'Premium is active. THIRTY can make today’s Circle for this need and '
      'time, in place of this suggestion.';
  static const action = 'Make today’s Circle';
  static const made = 'Today’s Circle is ready.';
  static const noFit =
      'No Circle fits this need and time today, so this one stays.';
}

/// "Make today's Circle" (audit remediation R2, founder decision D1): when
/// Premium is verified after today's ordinary Free offer was decided, one
/// quiet row below the Circle lets the user turn that offer — unstarted —
/// into the Circle THIRTY makes ([RecommendationNotifier.upgradeToday]).
/// Never a swap without the tap; never once today's Circle has started, or
/// for a kept, replaced or already composed one.
class MakeTodayCircleCard extends ConsumerStatefulWidget {
  const MakeTodayCircleCard({super.key});

  @override
  ConsumerState<MakeTodayCircleCard> createState() =>
      _MakeTodayCircleCardState();
}

class _MakeTodayCircleCardState extends ConsumerState<MakeTodayCircleCard> {
  /// Set once a tap found nothing to make: today's offer stays, said once.
  bool _noFit = false;

  void _make() {
    final result = ref.read(recommendationProvider.notifier).upgradeToday();
    switch (result) {
      case UpgradeTodayResult.upgraded:
        SemanticsService.sendAnnouncement(
          View.of(context),
          MakeTodayCircleCopy.made,
          Directionality.of(context),
        );
      case UpgradeTodayResult.noComposition:
        setState(() => _noFit = true);
      case UpgradeTodayResult.notAvailable:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recommendationProvider);
    final recommendation = state.recommendation;
    if (recommendation == null ||
        !recommendation.isFreeDecision ||
        state.status != RecommendationStatus.notStarted ||
        !ref.watch(premiumEntitlementProvider)) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page - AppSpacing.s,
        0,
        AppSpacing.page - AppSpacing.s,
        AppSpacing.page,
      ),
      child: Semantics(
        container: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.surfaceMuted,
                    ),
                    child: Icon(
                      Icons.auto_awesome_outlined,
                      size: 22,
                      color: colors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                // The action sits under its sentence: its label is longer
                // than "Keep it", and beside the text it overflows at large
                // text sizes.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        liveRegion: _noFit,
                        child: Text(
                          _noFit
                              ? MakeTodayCircleCopy.noFit
                              : MakeTodayCircleCopy.offer,
                          style: textTheme.bodyLarge,
                        ),
                      ),
                      if (!_noFit)
                        TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s,
                            ),
                          ),
                          onPressed: _make,
                          child: const Text(MakeTodayCircleCopy.action),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
