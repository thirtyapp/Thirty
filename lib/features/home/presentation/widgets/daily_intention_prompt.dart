import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';
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
/// today?", revealed beneath the still-mounted closed Circle once the user
/// taps `Begin today's Circle` (`circle_ready_prompt.dart` — Golden Home
/// continuity correction). Tapping one calls
/// [RecommendationNotifier.chooseIntention], which fixes today's
/// recommendation; this widget has nothing left to do afterward — `HomePage`
/// swaps the whole Ready composition out for `CircleHero`
/// (circle_hero.dart) on the next build, which then plays The First Breath.
///
/// Exactly the three [Intention] values, in the same fixed order every day —
/// no inference, no additional questions. Presented as compact, discrete
/// choices — the same visual language as THIRTY's post-Circle feedback
/// questions (`action_report_prompt.dart`'s "Did you try this activity?"):
/// a calm, centered question followed by a stack of secondary
/// [ThirtyButton]s — deliberately not the larger, descriptive
/// [ThirtyCard] treatment this widget used before the correction, which
/// read as an activity catalogue rather than three quick directions. Each
/// option's fuller meaning (`intentionMeaning`) still reaches assistive
/// technology through its [Semantics] label below; it is no longer shown as
/// its own visible line, since a compact choice — not a description — is
/// the point.
///
/// Deliberately has no [SingleChildScrollView] or outer padding of its
/// own: `circle_ready_prompt.dart` is this widget's only mount point, and
/// it already provides both, as one shared scrollable/padded shell together
/// with the Circle above this question — the same shell, not a second one,
/// is what keeps the Circle from ever needing to reflow when this content
/// appears.
class DailyIntentionPrompt extends ConsumerWidget {
  const DailyIntentionPrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final showIntro = ref.watch(showOnboardingIntroProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
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
          style: textTheme.titleSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s),
        for (final intention in Intention.values) ...[
          _IntentionOption(intention: intention),
          if (intention != Intention.values.last)
            const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _IntentionOption extends ConsumerWidget {
  const _IntentionOption({required this.intention});

  final Intention intention;

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
    final label = intentionLabel(intention);
    final meaning = intentionMeaning(intention);

    // ADR-013 §9 — a bare `button: true` + `label` semantics node carries
    // no actual action for an assistive technology to invoke: TalkBack
    // would announce this as a button but a double-tap would do nothing,
    // since ExcludeSemantics removes ThirtyButton's own gesture-derived
    // semantics from the tree entirely. `onTap` here is what gives this
    // node a real SemanticsAction.tap an assistive technology can invoke —
    // see daily_intention_prompt_test.dart's explicit
    // `performAction(..., SemanticsAction.tap)` regression test. The
    // combined "label. meaning" text is kept as this node's semantics
    // label even though only [label] is shown visually below — an
    // assistive-technology user still gets the fuller context a sighted
    // user reads from the surrounding daily question and the label alone.
    return Semantics(
      button: true,
      label: '$label. $meaning',
      onTap: () => _choose(ref),
      child: ExcludeSemantics(
        child: ThirtyButton(
          label: label,
          variant: ThirtyButtonVariant.secondary,
          onPressed: () => _choose(ref),
        ),
      ),
    );
  }
}
