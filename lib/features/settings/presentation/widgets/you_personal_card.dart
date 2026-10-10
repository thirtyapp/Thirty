import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../application/first_name_provider.dart';
import 'first_name_editor.dart';
import 'you_group_card.dart';

/// You's "Personal" group: "Your name", showing the stored first name or
/// "Add your name", which opens [FirstNameEditor]; and "What THIRTY
/// remembers" (V2 Phase C), the memory page. No avatar and no account: the
/// name and the memory live on this device only ([firstNameProvider]).
class YouPersonalCard extends ConsumerWidget {
  const YouPersonalCard({super.key});

  static const rowTitle = 'Your name';
  static const addPrompt = 'Add your name';
  static const memoryTitle = 'What THIRTY remembers';
  static const memoryDetail = 'What you’ve told it, need by need';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final name = ref.watch(firstNameProvider);
    final detail = name ?? addPrompt;
    void open() => showFirstNameEditor(context);

    return YouGroupCard(
      children: [
        Semantics(
          key: const ValueKey('you.name'),
          button: true,
          label: '$rowTitle, $detail',
          onTap: open,
          child: ExcludeSemantics(
            child: InkWell(
              onTap: open,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const YouRowIcon(Icons.edit_outlined),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const YouRowTitle(rowTitle),
                            const SizedBox(height: 2),
                            if (name == null)
                              Text(
                                addPrompt,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.primary,
                                ),
                              )
                            else
                              YouRowDetail(name),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Semantics(
          key: const ValueKey('you.memory'),
          button: true,
          label: '$memoryTitle, $memoryDetail',
          onTap: () => context.push('/memory'),
          child: ExcludeSemantics(
            child: InkWell(
              onTap: () => context.push('/memory'),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      YouRowIcon(Icons.auto_stories_outlined),
                      SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            YouRowTitle(memoryTitle),
                            SizedBox(height: 2),
                            YouRowDetail(memoryDetail),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
