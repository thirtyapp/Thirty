import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/thirty_button.dart';
import '../../home/application/recommendation_provider.dart';

/// The words of [UseTodayControl], in one place.
abstract final class UseTodayCopy {
  static const action = 'Use it today';
  static const isToday = 'It’s your Circle for today.';
  static const started =
      'Today’s Circle has already begun — one a day. You can use it '
      'tomorrow.';
  static const closed =
      'Your Circle for today is closed. You can use it tomorrow.';
  static const unavailable = 'It can’t be used today.';
}

/// "Use it today" (V2 Phase D2, ADR-023 §8): makes one of the user's kept
/// Circles ([keptCircleId]) today's Circle. Free — what the user owns is
/// theirs to use — and bounded: only before today's Circle starts, still one
/// Circle a day, from the kept Circle's own page (never a list on Today).
class UseTodayControl extends ConsumerWidget {
  const UseTodayControl({
    required this.keptCircleId,
    this.unavailableNote,
    super.key,
  });

  final String keptCircleId;

  /// Why it can't be used, when the page already knows (a part the user
  /// asked THIRTY not to suggest): shown instead of the button.
  final String? unavailableNote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(recommendationProvider);
    final today = state.recommendation;
    final isToday =
        today != null && today.composed?.keptCircleId == keptCircleId;
    String? note;
    if (isToday) {
      note = UseTodayCopy.isToday;
    } else if (state.status == RecommendationStatus.started) {
      note = UseTodayCopy.started;
    } else if (state.status == RecommendationStatus.closed) {
      note = UseTodayCopy.closed;
    } else if (unavailableNote != null) {
      note = unavailableNote;
    }
    if (note != null) {
      return Semantics(
        container: true,
        child: Text(
          note,
          style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
      );
    }
    return ThirtyButton(
      label: UseTodayCopy.action,
      trailingIcon: Icons.arrow_forward_rounded,
      onPressed: () {
        final result = ref
            .read(recommendationProvider.notifier)
            .useOwnedToday(keptCircleId: keptCircleId);
        if (result == UseTodayResult.used) {
          context.go('/');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(UseTodayCopy.unavailable)),
          );
        }
      },
    );
  }
}
