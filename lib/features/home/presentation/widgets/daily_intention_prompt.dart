import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_card.dart';
import '../../application/activity_catalog.dart';
import '../../application/circle_journal.dart';
import '../../application/recommendation_provider.dart';

/// SharedPreferences key recording that THIRTY's one first-use explanation
/// has already been shown — Step 5 onboarding reconciliation (`THIRTY V1
/// PRODUCTIZATION + COMMERCIAL REVIEW.md` §28). Set the moment the user
/// actually chooses their first direction, never merely on render — an
/// app closed before a first choice should still explain itself next
/// time (frozen "no long opening every time the app returns" is about
/// the First Breath ritual, not this one-time explanatory line).
const onboardingIntroShownKey = 'onboarding_intro_shown_v1';

/// Whether [DailyIntentionPrompt] should render its one-time first-use
/// explanation above the daily question.
///
/// `false` once already shown. Also `false` for an install that already
/// has any journal history — an existing user upgrading from a
/// pre-onboarding build has already learned the mechanic and must never
/// see a "first use" explanation addressed to a new user (and this also
/// marks the flag so the check is a single read thereafter).
final showOnboardingIntroProvider = Provider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  if (prefs.getBool(onboardingIntroShownKey) ?? false) return false;

  final hasPriorHistory = ref
      .watch(circleJournalRepositoryProvider)
      .readAll()
      .isNotEmpty;
  return !hasPriorHistory;
});

/// THIRTY's Daily Context Question — Recommendation MVP v0
/// (`docs/product/recommendation-mvp-v0.md`): "What would help most
/// today?", shown instead of the Circle Hero whenever today's recommendation
/// doesn't exist yet (`home_page.dart` decides between the two on
/// `recommendationProvider`'s [RecommendationState.recommendation]).
///
/// Exactly the three [Intention] values, in the same fixed order every day —
/// no inference, no additional questions. Tapping one calls
/// [RecommendationNotifier.chooseIntention], which fixes today's
/// recommendation; this widget has nothing left to do afterward; `HomePage`
/// swaps it out for `CircleHero` (circle_hero.dart) on the next build.
class DailyIntentionPrompt extends ConsumerWidget {
  const DailyIntentionPrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final showIntro = ref.watch(showOnboardingIntroProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.page),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showIntro) ...[
            Text(
              'Choose a direction. THIRTY gives you one activity to do '
              'offline, in about thirty minutes. Tomorrow brings a new '
              'Circle.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.m),
          ],
          Text(
            'What would help most today?',
            style: textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.section),
          for (final intention in Intention.values) ...[
            _IntentionOption(intention: intention, colors: colors),
            if (intention != Intention.values.last)
              const SizedBox(height: AppSpacing.m),
          ],
        ],
      ),
    );
  }
}

class _IntentionOption extends ConsumerWidget {
  const _IntentionOption({required this.intention, required this.colors});

  final Intention intention;
  final AppColors colors;

  /// Chooses [intention] and — the first time this is ever called —
  /// permanently marks the first-use explanation as shown
  /// ([onboardingIntroShownKey]), so it never appears again once the user
  /// has actually completed their first choice.
  void _choose(WidgetRef ref) {
    final prefs = ref.read(sharedPreferencesProvider);
    if (!(prefs.getBool(onboardingIntroShownKey) ?? false)) {
      unawaited(prefs.setBool(onboardingIntroShownKey, true));
    }
    ref.read(recommendationProvider.notifier).chooseIntention(intention);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final label = intentionLabel(intention);
    final meaning = intentionMeaning(intention);

    // ADR-013 §9 — a bare `button: true` + `label` semantics node carries
    // no actual action for an assistive technology to invoke: TalkBack
    // would announce this as a button but a double-tap would do nothing,
    // since ExcludeSemantics removes ThirtyCard's own gesture-derived
    // semantics from the tree entirely. `onTap` here is what gives this
    // node a real SemanticsAction.tap an assistive technology can invoke —
    // see daily_intention_prompt_test.dart's explicit
    // `performAction(..., SemanticsAction.tap)` regression test.
    return Semantics(
      button: true,
      label: '$label. $meaning',
      onTap: () => _choose(ref),
      child: ExcludeSemantics(
        child: ThirtyCard(
          onTap: () => _choose(ref),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                meaning,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
