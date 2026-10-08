import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/branding/thirty_brand_lockup.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/thirty_button.dart';
import '../application/first_name_provider.dart';
import 'widgets/first_name_editor.dart';
import 'widgets/first_use_world_window.dart';

/// The one first-use question — "What should we call you?" — asked once,
/// before THIRTY is first used (`/welcome/name`, `app_router.dart`'s
/// redirect), and never again once resolved.
///
/// "Continue" saves a valid name and "Skip for now" saves nothing; both mark
/// the question resolved ([firstNamePromptSeenProvider]) and open Today.
/// The name stays optional and can be added, changed or removed later in
/// You. One quiet question beneath a [FirstUseWorldWindow] — a window into
/// THIRTY's world, never an active Circle; the premium welcome experience
/// is its own later piece of work.
class FirstNameQuestionPage extends ConsumerStatefulWidget {
  const FirstNameQuestionPage({super.key});

  static const question = 'What should we call you?';
  static const supporting =
      'Your first name stays on this device and helps THIRTY feel a little '
      'more personal.';

  @override
  ConsumerState<FirstNameQuestionPage> createState() =>
      _FirstNameQuestionPageState();
}

class _FirstNameQuestionPageState extends ConsumerState<FirstNameQuestionPage> {
  final _controller = TextEditingController();
  bool _finishing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _tooLong => !firstNameFits(_controller.text);

  bool get _canContinue =>
      !_finishing && trimmedFirstName(_controller.text) != null && !_tooLong;

  Future<void> _continue() async {
    if (!_canContinue) return;
    setState(() => _finishing = true);
    final result = await ref
        .read(firstNameProvider.notifier)
        .setFirstName(_controller.text);
    if (result != FirstNameSaveResult.saved) {
      if (mounted) setState(() => _finishing = false);
      return;
    }
    await _finish();
  }

  Future<void> _skip() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await _finish();
  }

  Future<void> _finish() async {
    await ref.read(firstNamePromptSeenProvider.notifier).markSeen();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final now = ref.watch(nowProvider);
    final screen = MediaQuery.sizeOf(context);
    final insets = MediaQuery.paddingOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    // Large text: the window's gaps give back a step each, so the question
    // and both actions keep their first screen.
    final largeText = textScale >= 1.5;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          children: [
            // Home's own lockup and sizes (`home_header.dart`): the wordmark
            // with the tagline beneath it, read as one identity block.
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.m),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Semantics(
                  label: 'THIRTY',
                  child: const ThirtyBrandLockup(
                    wordmarkWidth: 96,
                    taglineFontSize: 8,
                  ),
                ),
              ),
            ),
            SizedBox(height: largeText ? AppSpacing.m : AppSpacing.l),
            Center(
              child: FirstUseWorldWindow(
                now: now,
                diameter: FirstUseWorldWindow.diameterFor(
                  width: screen.width - AppSpacing.page * 2,
                  height: screen.height - insets.vertical,
                  textScale: textScale,
                ),
              ),
            ),
            SizedBox(height: largeText ? AppSpacing.l : AppSpacing.xl),
            Semantics(
              header: true,
              child: Text(
                FirstNameQuestionPage.question,
                textAlign: TextAlign.center,
                style: AppTypography.editorialDisplay(
                  colors,
                ).copyWith(fontSize: 34, height: 1.15),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              FirstNameQuestionPage.supporting,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.l),
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
              onSubmitted: (_) => _continue(),
            ),
            const SizedBox(height: AppSpacing.xl),
            ThirtyButton(
              label: 'Continue',
              onPressed: _canContinue ? _continue : null,
            ),
            const SizedBox(height: AppSpacing.s),
            Center(
              child: TextButton(
                onPressed: _finishing ? null : _skip,
                style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                child: const Text('Skip for now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
