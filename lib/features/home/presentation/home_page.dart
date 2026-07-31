import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../application/recommendation_provider.dart';
import 'widgets/recommendation_card.dart';

/// THIRTY's product entry screen, shown on the root route. Shows the
/// day's single recommendation — the first vertical slice of the app.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final recommendationState = ref.watch(recommendationProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'THIRTY',
                style: textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Your healthiest 30 minutes.',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.section),
              RecommendationCard(
                recommendation: recommendationState.recommendation,
                status: recommendationState.status,
                onStart: () =>
                    ref.read(recommendationProvider.notifier).start(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
