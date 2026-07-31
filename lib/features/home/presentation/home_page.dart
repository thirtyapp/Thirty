import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

/// THIRTY's product entry screen, shown on the root route. A minimal,
/// on-brand shell — later Fase 2 work (onboarding, the daily 30-minute
/// mechanism) lands here.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('THIRTY', style: textTheme.displayLarge),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'Your healthiest 30 minutes.',
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
