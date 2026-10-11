import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/thirty_app_bar.dart';
import '../../../core/widgets/thirty_confirm_dialog.dart';
import '../../../core/widgets/thirty_text_action.dart';
import '../../home/application/activity_catalog.dart';
import '../../home/application/suggestion_preferences.dart';
import '../../toolkit/application/toolkit_provider.dart';
import '../../toolkit/domain/toolkit_model.dart';
import '../../toolkit/presentation/toolkit_page.dart';
import '../../toolkit/presentation/widgets/toolkit_parts.dart';
import '../domain/circle_elements.dart';
import '../domain/composed_session.dart';
import 'use_today_control.dart';

/// "Clearer Head · about 18 minutes · 4 parts".
String keptCircleLine(KeptCircle circle) =>
    '${intentionLabel(circle.need)} · about ${circle.minutes} minutes · '
    '${circle.plan.parts.length} parts';

/// One kept Circle (V2 Phase D2, ADR-023 §8): what is in it, using it today,
/// and the user's own controls — rename, remove. Everything here works
/// whatever Premium's state: a kept Circle is the user's.
class KeptCirclePage extends ConsumerWidget {
  const KeptCirclePage({required this.keptId, super.key});

  final String keptId;

  static const pathPattern = '/toolkit/kept/:id';
  static String locationFor(String id) => '/toolkit/kept/$id';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final circle = ref.watch(toolkitProvider).keptById(keptId);
    if (circle == null) {
      return Scaffold(
        appBar: const ThirtyAppBar(title: Text('Kept Circle')),
        body: const Padding(
          padding: EdgeInsets.all(AppSpacing.page),
          child: ToolkitNote('This Circle is no longer in your Toolkit.'),
        ),
      );
    }
    final preferences = ref.watch(suggestionPreferencesProvider);
    final blocked = [
      for (final part in circle.plan.parts)
        if (!isElementOfferable(part.definition) ||
            (part.definition.from != null &&
                preferences.isNotSuggested(part.definition.from!, circle.need)))
          part.definition.name,
    ];
    final quiet = textTheme.bodyMedium?.copyWith(color: colors.textSecondary);

    return Scaffold(
      appBar: const ThirtyAppBar(title: Text('Kept Circle')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.s,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          children: [
            Semantics(
              header: true,
              child: Text(
                circle.name,
                style: AppTypography.editorialDisplay(
                  colors,
                ).copyWith(fontSize: 30, height: 1.1),
              ),
            ),
            const SizedBox(height: 2),
            Text(keptCircleLine(circle), style: quiet),
            const SizedBox(height: AppSpacing.l),
            UseTodayControl(
              keptCircleId: circle.id,
              unavailableNote: blocked.isEmpty
                  ? null
                  : 'It includes ${blocked.join(' and ')}, which you asked '
                        'THIRTY not to suggest for '
                        '${intentionLabel(circle.need)}.',
            ),
            const SizedBox(height: AppSpacing.l),
            ToolkitSection(
              title: 'What’s in it',
              child: ToolkitRows(
                rows: [
                  for (final part in circle.plan.parts)
                    ToolkitRow(
                      title: part.definition.name,
                      detail:
                          '${ComposedCopy.partCue(part.minutes)} · '
                          '${part.definition.instruction}',
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            ToolkitSection(
              title: 'It’s yours',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ToolkitNote(
                    'THIRTY never offers a kept Circle unasked. It stays '
                    'yours, with or without Premium.',
                  ),
                  ThirtyTextAction(
                    label: 'Rename',
                    onPressed: () => _rename(context, ref, circle),
                  ),
                  ThirtyTextAction(
                    label: 'Remove',
                    onPressed: () => _remove(context, ref, circle),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    KeptCircle circle,
  ) async {
    final controller = TextEditingController(text: circle.name);
    final name = await showDialog<String>(
      context: context,
      barrierLabel: 'Cancel',
      builder: (context) => AlertDialog(
        semanticLabel: 'Rename',
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(counterText: ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null) return;
    ref.read(toolkitProvider.notifier).renameKept(circle.id, name);
  }

  static Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    KeptCircle circle,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierLabel: 'Keep it',
      builder: (_) => ThirtyConfirmDialog(
        title: 'Remove ${circle.name}?',
        body: 'It leaves your Toolkit. Days you used it stay in your history.',
        cancelLabel: 'Keep it',
        confirmLabel: 'Remove',
        destructive: true,
      ),
    );
    if (confirmed != true || !context.mounted) return;
    ref.read(toolkitProvider.notifier).deleteKept(circle.id);
    context.go(ToolkitPage.location);
  }
}
