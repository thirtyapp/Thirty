import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../home/application/recommendation_provider.dart';
import '../application/kept_circles_provider.dart';
import '../domain/kept_circle.dart';

/// The words of [KeepCircleCard], in one place.
abstract final class KeepCircleCopy {
  static const offer = 'Keep this Circle to use again on a day you choose.';
  static const action = 'Keep it';
  static String kept(String name) => 'Kept as $name. It’s in Yours, under You.';
  static const full =
      'You have $maxKeptCircles kept Circles. Remove one in Yours to keep '
      'another.';
}

/// "Keep this Circle" (V2 Phase D2, ADR-023 §8): once today's Personal
/// Guided Circle is closed, one quiet row below the Circle lets the user
/// keep it as their own — usable on any later day ("Use it today"), with
/// or without Premium. Never on a kept Circle being used again, never
/// before Close, never more than [maxKeptCircles].
class KeepCircleCard extends ConsumerWidget {
  const KeepCircleCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recommendationProvider);
    final recommendation = state.recommendation;
    final composed = recommendation?.composed;
    if (recommendation == null ||
        composed == null ||
        composed.isKept ||
        state.status != RecommendationStatus.closed) {
      return const SizedBox.shrink();
    }
    final owned = ref.watch(keptCirclesProvider).kept;
    final kept = owned
        .where((k) => k.fromCircleId == recommendation.circleId)
        .firstOrNull;
    final full = kept == null && owned.length >= maxKeptCircles;

    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final text = kept != null
        ? KeepCircleCopy.kept(kept.name)
        : full
        ? KeepCircleCopy.full
        : KeepCircleCopy.offer;
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
                      kept != null
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 22,
                      color: colors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Semantics(
                    liveRegion: kept != null,
                    child: Text(text, style: textTheme.bodyLarge),
                  ),
                ),
                if (kept == null && !full) ...[
                  const SizedBox(width: AppSpacing.s),
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: () => ref
                        .read(keptCirclesProvider.notifier)
                        .keepCircle(
                          plan: composed.plan,
                          need: recommendation.intention,
                          circleId: recommendation.circleId,
                        ),
                    child: const Text(KeepCircleCopy.action),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
