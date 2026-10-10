import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/thirty_app_bar.dart';
import '../../home/application/activity_catalog.dart';
import '../domain/path_catalog.dart';
import 'path_start_page.dart';
import 'widgets/toolkit_parts.dart';

/// The six Paths, two per need — each named for the routine it builds.
/// Not a catalogue to browse: six short answers to "what am I building?".
class ChoosePathPage extends StatelessWidget {
  const ChoosePathPage({super.key});

  static const location = '/toolkit/paths';
  static const title = 'Choose a Path';

  @override
  Widget build(BuildContext context) {
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
            const ToolkitNote(
              'Each Path builds one routine over seven Circles. Pick what '
              'you want to build.',
            ),
            for (final need in Intention.values) ...[
              const SizedBox(height: AppSpacing.l),
              ToolkitSection(
                title: intentionLabel(need),
                child: ToolkitRows(
                  rows: [
                    for (final template in pathsFor(need))
                      ToolkitRow(
                        title: template.name,
                        detail: template.building,
                        onTap: () => context.push(
                          PathStartPage.locationFor(template.id),
                        ),
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
