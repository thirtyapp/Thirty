import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/thirty_app_bar.dart';
import '../application/kept_circles_provider.dart';
import 'kept_circle_page.dart';
import 'widgets/yours_parts.dart';

/// Yours (ADR-024 §2–§3), under You: the Circles the user kept — the only
/// reusable thing they own. Ownership only: each kept Circle opens its own
/// page, to use today, rename or remove. Nothing here is built, tuned,
/// suggested or collected, and nothing depends on Premium.
class YoursPage extends ConsumerWidget {
  const YoursPage({super.key});

  static const location = '/settings/yours';
  static const title = 'Yours';
  static const intro =
      'The Circles you kept. Each one is yours to use, rename or remove, with '
      'or without Premium.';
  static const empty =
      'Nothing kept yet. After you close a Circle THIRTY made for you, you can '
      'keep it, and it appears here.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kept = ref.watch(keptCirclesProvider).kept;
    return Scaffold(
      appBar: const ThirtyAppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.s,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          children: [
            YoursNote(kept.isEmpty ? empty : intro),
            if (kept.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.l),
              YoursSection(
                title: 'Circles you kept',
                child: YoursRows(
                  rows: [
                    for (final circle in kept)
                      YoursRow(
                        title: circle.name,
                        detail: keptCircleLine(circle),
                        onTap: () =>
                            context.push(KeptCirclePage.locationFor(circle.id)),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
