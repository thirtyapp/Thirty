import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/recommendation_provider.dart';
import 'widgets/circle_hero.dart';
import 'widgets/daily_intention_prompt.dart';

/// THIRTY's product entry screen.
///
/// Shows the Daily Context Question ([DailyIntentionPrompt]) whenever
/// today's recommendation doesn't exist yet
/// (`RecommendationState.recommendation == null` — Recommendation MVP v0,
/// `docs/product/recommendation-mvp-v0.md`), and the Circle Hero — the first
/// true emotional experience of the product (Playbook Ch.1 §3 — "The Circle
/// is not the app icon... it is the thing THIRTY is") — once it does.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasRecommendation =
        ref.watch(recommendationProvider).recommendation != null;

    return Scaffold(
      body: SafeArea(
        child: hasRecommendation
            ? const CircleHero()
            : const DailyIntentionPrompt(),
      ),
    );
  }
}
