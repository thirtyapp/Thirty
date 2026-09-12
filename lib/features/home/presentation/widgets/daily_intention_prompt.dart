import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';
import '../../application/activity_catalog.dart';
import '../../application/recommendation_provider.dart';

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
/// **Emulator polish:** this question used to be preceded by a one-time
/// first-use explanatory paragraph ("Choose a direction. THIRTY gives you
/// one activity to do offline..." — Step 5 onboarding reconciliation). The
/// founder asked for this state to use the same restrained question/choice
/// rhythm as the post-Circle feedback UI, which never precedes its own
/// questions with explanatory copy — so that paragraph (and the
/// SharedPreferences flag/provider that gated it) is removed outright
/// rather than left unused; the state this widget renders is now always
/// exactly the question and the three choices, on every use.
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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

  void _choose(WidgetRef ref) {
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
