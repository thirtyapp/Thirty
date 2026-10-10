import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../application/first_name_provider.dart';

/// Opens the first-name editor over the current page.
Future<void> showFirstNameEditor(BuildContext context) => showDialog<void>(
  context: context,
  // TalkBack names the backdrop by what it does.
  barrierLabel: 'Cancel',
  builder: (_) => const FirstNameEditor(),
);

/// The focused editor for the user's optional first name: one field,
/// prefilled with the current name, plus "Save" and "Cancel" — and a quiet
/// "Remove name" once a name exists. Removing it is a local preference
/// change, not data loss, so it is neither red nor confirmed.
///
/// "Save" is enabled only for a name that is non-blank and at most
/// [maxFirstNameLength] code points once trimmed: a blank field never saves
/// an empty name ("Remove name" is the one way to remove it), and a longer
/// one is explained, never truncated.
class FirstNameEditor extends ConsumerStatefulWidget {
  const FirstNameEditor({super.key});

  static const title = 'Your name';
  static const supporting =
      'Used only to make THIRTY feel a little more personal.';
  static const fieldLabel = 'First name';
  static const tooLongMessage = 'Use $maxFirstNameLength characters or fewer.';

  @override
  ConsumerState<FirstNameEditor> createState() => _FirstNameEditorState();
}

class _FirstNameEditorState extends ConsumerState<FirstNameEditor> {
  late final String? _existing = ref.read(firstNameProvider);
  late final _controller = TextEditingController(text: _existing);

  static const _largeTextScale = 1.3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _tooLong => !firstNameFits(_controller.text);

  bool get _canSave => trimmedFirstName(_controller.text) != null && !_tooLong;

  Future<void> _save() async {
    if (!_canSave) return;
    await ref.read(firstNameProvider.notifier).setFirstName(_controller.text);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    await ref.read(firstNameProvider.notifier).clear();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final largeText =
        MediaQuery.textScalerOf(context).scale(1) >= _largeTextScale;

    return AlertDialog(
      scrollable: true,
      insetPadding: largeText
          ? const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.l,
            )
          : null,
      actionsOverflowButtonSpacing: largeText ? AppSpacing.s : null,
      title: const Text(FirstNameEditor.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            FirstNameEditor.supporting,
            style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.m),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: FirstNameEditor.fieldLabel,
              errorText: _tooLong ? FirstNameEditor.tooLongMessage : null,
              errorMaxLines: 3,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(),
          ),
          if (_existing != null) ...[
            const SizedBox(height: AppSpacing.s),
            TextButton(
              onPressed: _remove,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 48),
                alignment: AlignmentDirectional.centerStart,
              ),
              child: const Text('Remove name'),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _canSave ? _save : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
