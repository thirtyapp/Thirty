import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/thirty_app_bar.dart';
import '../../../core/widgets/thirty_confirm_dialog.dart';
import '../../../core/widgets/thirty_text_action.dart';
import '../../home/application/activity_catalog.dart';
import '../../home/application/suggestion_preferences.dart';
import '../application/kept_circles_provider.dart';
import '../domain/composed_session.dart';
import '../domain/kept_circle.dart';
import 'use_today_control.dart';
import 'widgets/yours_parts.dart';
import 'yours_page.dart';

/// "Clearer Head · about 18 minutes · 4 parts".
String keptCircleLine(KeptCircle circle) =>
    '${intentionLabel(circle.need)} · about ${circle.minutes} minutes · '
    '${circle.plan.parts.length} parts';

/// What Yours says about a kept Circle THIRTY can't read or run (audit
/// remediation R4) — calm, true, and never a claim it runs.
abstract final class KeptCircleCopy {
  /// A kept Circle THIRTY can't read that has no name left to show.
  static const unnamed = 'A kept Circle';

  /// Its row in Yours.
  static const unreadableLine =
      'THIRTY can’t open it in this version. It’s still yours.';

  /// Its own page.
  static const unreadable =
      'THIRTY can’t open this Circle in this version of the app, so it can’t '
      'run today. Nothing in it has changed: it stays in Yours and in your '
      'export.';

  /// A whole stored record of kept Circles THIRTY can't open (R4.1): its
  /// row in Yours, its note, and removing it. Proposed copy.
  static const unreadableStore = 'Kept Circles THIRTY can’t open';
  static const unreadableStoreLine = 'They stay as stored, and in your export.';
  static const unreadableStoreNote =
      'THIRTY can’t open these kept Circles in this version of the app, so it '
      'can’t show or run them, or tell how many there are. Until they can be '
      'opened or you remove them, THIRTY won’t keep another Circle. Nothing '
      'in them has changed, and they’re in your export.';
  static const removeUnreadableStoreTitle = 'Remove stored Circles?';
  static const removeUnreadableStoreBody =
      'THIRTY can’t tell how many Circles are in this saved data. Removing '
      'it deletes all of them from this device. You can copy your history '
      'as text first.';

  /// A kept Circle with a part THIRTY no longer offers.
  static String notOffered(List<String> parts) =>
      'THIRTY no longer offers ${parts.join(' and ')}, so this Circle can’t '
      'run. It stays yours to read, rename or remove.';
}

/// One kept Circle (V2 Phase D2, ADR-023 §8; Yours, ADR-024 §3): what is in
/// it, using it today,
/// and the user's own controls — rename, remove. Everything here works
/// whatever Premium's state: a kept Circle is the user's.
class KeptCirclePage extends ConsumerWidget {
  const KeptCirclePage({required this.keptId, super.key});

  final String keptId;

  static const pathPattern = '${YoursPage.location}/kept/:id';
  static String locationFor(String id) => '${YoursPage.location}/kept/$id';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final collection = ref.watch(keptCirclesProvider);
    final circle = collection.keptById(keptId);
    if (circle == null) {
      if (collection.retainedByKey(keptId) case final record?) {
        return _RetainedKeptView(record: record);
      }
      if (collection.unreadableAt(keptId) case final store?) {
        return _UnreadableStoreView(store: store);
      }
      return Scaffold(
        appBar: const ThirtyAppBar(title: Text('Kept Circle')),
        body: const Padding(
          padding: EdgeInsets.all(AppSpacing.page),
          child: YoursNote('This Circle is no longer in Yours.'),
        ),
      );
    }
    final preferences = ref.watch(suggestionPreferencesProvider);
    // Audit remediation R4: a part THIRTY no longer offers is said as such —
    // never as something the user asked for.
    final notOffered = [
      for (final part in keptPartsNotOffered(
        circle,
        ref.watch(partOfferableProvider),
      ))
        circle.wordingAt(circle.plan.parts.indexOf(part)).name,
    ];
    final blocked = [
      for (final (position, part) in circle.plan.parts.indexed)
        if (part.definition.from != null &&
            preferences.isNotSuggested(part.definition.from!, circle.need))
          circle.wordingAt(position).name,
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
              unavailableNote: notOffered.isNotEmpty
                  ? KeptCircleCopy.notOffered(notOffered)
                  : blocked.isEmpty
                  ? null
                  : 'It includes ${blocked.join(' and ')}, which you asked '
                        'THIRTY not to suggest for '
                        '${intentionLabel(circle.need)}.',
            ),
            const SizedBox(height: AppSpacing.l),
            YoursSection(
              title: 'What’s in it',
              child: YoursRows(
                rows: [
                  // As kept: its own lengths and words (audit remediation R4).
                  for (final (position, part) in circle.plan.parts.indexed)
                    YoursRow(
                      title: circle.wordingAt(position).name,
                      detail: [
                        '${ComposedCopy.partCue(part.minutes)} · '
                            '${circle.wordingAt(position).instruction}',
                        // R4.1: said only when a safety correction shows.
                        if (circle.correctedForSafetyAt(position))
                          ComposedCopy.correctedForSafety,
                      ].join('\n'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            YoursSection(
              title: 'It’s yours',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const YoursNote(
                    'THIRTY never offers a kept Circle unasked. It stays '
                    'yours, with or without Premium.',
                  ),
                  ThirtyTextAction(
                    label: 'Rename',
                    onPressed: () =>
                        _rename(context, ref, circle.id, circle.name),
                  ),
                  ThirtyTextAction(
                    label: 'Remove',
                    onPressed: () =>
                        _remove(context, ref, circle.id, circle.name),
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
    String id,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
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
    ref.read(keptCirclesProvider.notifier).renameKept(id, name);
  }

  static Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierLabel: 'Keep it',
      builder: (_) => ThirtyConfirmDialog(
        title: 'Remove $name?',
        body: 'It leaves Yours. Days you used it stay in your history.',
        cancelLabel: 'Keep it',
        confirmLabel: 'Remove',
        destructive: true,
      ),
    );
    if (confirmed != true || !context.mounted) return;
    ref.read(keptCirclesProvider.notifier).deleteKept(id);
    context.go(YoursPage.location);
  }
}

/// A kept Circle THIRTY can't read (audit remediation R4): shown, never
/// hidden; never run; the user's to rename — where its record still allows —
/// and to remove. It stays in the export as stored.
class _RetainedKeptView extends StatelessWidget {
  const _RetainedKeptView({required this.record});

  final RetainedKept record;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final name = record.name ?? KeptCircleCopy.unnamed;
    return Scaffold(
      appBar: const ThirtyAppBar(title: Text('Kept Circle')),
      body: SafeArea(
        child: Consumer(
          builder: (context, ref, _) => ListView(
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
                  name,
                  style: AppTypography.editorialDisplay(
                    colors,
                  ).copyWith(fontSize: 30, height: 1.1),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              const YoursNote(KeptCircleCopy.unreadable),
              const SizedBox(height: AppSpacing.l),
              YoursSection(
                title: 'It’s yours',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (record.canRename)
                      ThirtyTextAction(
                        label: 'Rename',
                        onPressed: () => KeptCirclePage._rename(
                          context,
                          ref,
                          record.key,
                          record.name ?? '',
                        ),
                      ),
                    ThirtyTextAction(
                      label: 'Remove',
                      onPressed: () => KeptCirclePage._remove(
                        context,
                        ref,
                        record.key,
                        name,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A whole stored record of kept Circles THIRTY can't open (audit
/// remediation R4.1): shown, never hidden; nothing in it is shown as a
/// Circle or run; removed only on the user's own request, after a warning.
class _UnreadableStoreView extends StatelessWidget {
  const _UnreadableStoreView({required this.store});

  final UnreadableKeptStore store;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      appBar: const ThirtyAppBar(title: Text('Kept Circle')),
      body: SafeArea(
        child: Consumer(
          builder: (context, ref, _) => ListView(
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
                  KeptCircleCopy.unreadableStore,
                  style: AppTypography.editorialDisplay(
                    colors,
                  ).copyWith(fontSize: 30, height: 1.1),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              const YoursNote(KeptCircleCopy.unreadableStoreNote),
              const SizedBox(height: AppSpacing.l),
              YoursSection(
                title: 'They’re yours',
                child: ThirtyTextAction(
                  label: 'Remove',
                  onPressed: () => _remove(context, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierLabel: 'Keep them',
      builder: (_) => const ThirtyConfirmDialog(
        title: KeptCircleCopy.removeUnreadableStoreTitle,
        body: KeptCircleCopy.removeUnreadableStoreBody,
        cancelLabel: 'Keep them',
        confirmLabel: 'Remove',
        destructive: true,
      ),
    );
    if (confirmed != true || !context.mounted) return;
    ref.read(keptCirclesProvider.notifier).removeUnreadable(store.address);
    context.go(YoursPage.location);
  }
}
