import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/theme_mode_provider.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_confirm_dialog.dart';
import '../../../personal_circle/application/guidance_voice.dart';
import '../../../personal_circle/domain/spoken_cues.dart';
import '../../../reminder/application/reminder_provider.dart';
import 'theme_mode_choice.dart';
import 'you_group_card.dart';

/// You's "Preferences" group (Phase C1): the daily reminder, appearance
/// and spoken guidance (V2 Phase D2 — only in a build that bundles it) as
/// rows of one grouped card. Analytics consent is a privacy control and
/// lives in Data & privacy ([YouDataCard]; founder decision, B7). Each row's behaviour
/// is unchanged from before C1 — only the surface around them changed.
///
/// North Star convergence: each row gains a quiet decorative icon and a
/// title / detail hierarchy, and each switch row is announced as one
/// control (its label together with its on/off state).
class YouPreferencesCard extends ConsumerWidget {
  const YouPreferencesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return YouGroupCard(
      children: [
        YouRow(
          key: const ValueKey('you.reminder'),
          child: _ReminderRow(state: ref.watch(reminderProvider)),
        ),
        YouRow(
          key: const ValueKey('you.appearance'),
          icon: Icons.contrast,
          child: _AppearanceRow(themeMode: ref.watch(themeModeProvider)),
        ),
        // THIRTY's voice is Premium: on Free there is nothing to set. The
        // stored choices stay as they are for a return.
        if (ref.watch(spokenGuidanceOfferedProvider))
          const YouRow(
            key: ValueKey('you.spokenGuidance'),
            child: _SpokenGuidanceRow(),
          ),
      ],
    );
  }
}

class _AppearanceRow extends ConsumerWidget {
  const _AppearanceRow({required this.themeMode});

  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const YouRowTitle('Appearance'),
        const SizedBox(height: AppSpacing.xs),
        ThemeModeChoice(
          value: themeMode,
          onChanged: (mode) =>
              ref.read(themeModeProvider.notifier).setThemeMode(mode),
        ),
      ],
    );
  }
}

/// V2 Phase D2 (ADR-023 §6): spoken guidance on or off, which of THIRTY's
/// voices speaks when the build has more than one, and a preview of it in
/// its own production recordings. The Circle is complete without it.
class _SpokenGuidanceRow extends ConsumerWidget {
  const _SpokenGuidanceRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(spokenGuidanceEnabledProvider);
    final voices = [
      for (final voice in ThirtyVoice.values)
        if (ref.watch(bundledGuidanceVoicesProvider).contains(voice)) voice,
    ];
    final speaking = ref.watch(thirtyVoiceProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _spokenGuidanceSwitch(ref, enabled),
        if (enabled && voices.length > 1) ...[
          const SizedBox(height: AppSpacing.s),
          Semantics(
            container: true,
            label: SpokenGuidanceCopy.voice,
            child: Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.xs,
              children: [
                for (final voice in voices)
                  ChoiceChip(
                    label: Text(voice.label),
                    selected: voice == speaking,
                    onSelected: (_) =>
                        ref.read(thirtyVoiceChoiceProvider.notifier).set(voice),
                  ),
              ],
            ),
          ),
        ],
        if (enabled && speaking != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const ValueKey('you.spokenGuidance.preview'),
              icon: const Icon(Icons.play_arrow_outlined),
              label: Text(SpokenGuidanceCopy.preview(speaking.label)),
              // An explicit request to hear the voice: it plays even with
              // a screen reader on.
              onPressed: () => ref.read(guidanceAudioPlayerProvider).play([
                spokenPreviewFor(speaking).assetFor(speaking),
              ]),
            ),
          ),
      ],
    );
  }

  Widget _spokenGuidanceSwitch(WidgetRef ref, bool enabled) {
    return MergeSemantics(
      child: Row(
        children: [
          const Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                YouRowIcon(Icons.record_voice_over_outlined),
                SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      YouRowTitle(SpokenGuidanceCopy.title),
                      SizedBox(height: AppSpacing.xs),
                      YouRowDetail(SpokenGuidanceCopy.detail),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (value) =>
                ref.read(spokenGuidanceEnabledProvider.notifier).set(value),
          ),
        ],
      ),
    );
  }
}

class _ReminderRow extends ConsumerStatefulWidget {
  const _ReminderRow({required this.state});

  final ReminderState state;

  @override
  ConsumerState<_ReminderRow> createState() => _ReminderRowState();
}

class _ReminderRowState extends ConsumerState<_ReminderRow> {
  Future<void> _pickTimeAndEnable() async {
    final initial = TimeOfDay(
      hour: widget.state.hour,
      minute: widget.state.minute,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    await ref
        .read(reminderProvider.notifier)
        .enable(hour: picked.hour, minute: picked.minute);
  }

  Future<void> _pickTimeAndUpdate() async {
    final initial = TimeOfDay(
      hour: widget.state.hour,
      minute: widget.state.minute,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    await ref
        .read(reminderProvider.notifier)
        .setTime(hour: picked.hour, minute: picked.minute);
  }

  /// Shows THIRTY's one calm explanation for Android's exact-alarm
  /// special access *before* leaving the app for the system screen —
  /// never automatically, only from this explicit tap.
  Future<void> _requestExactAlarmAccess() async {
    final proceed = await showDialog<bool>(
      context: context,
      // TalkBack names the backdrop by what it does.
      barrierLabel: 'Not now',
      builder: (_) => const ThirtyConfirmDialog(
        title: 'Allow Alarms & reminders',
        body:
            'Android needs "Alarms & reminders" access so THIRTY can '
            'deliver your Circle reminder at the time you choose.',
        cancelLabel: 'Not now',
        confirmLabel: 'Continue',
      ),
    );
    if (proceed != true || !mounted) return;
    await ref.read(reminderProvider.notifier).requestExactAlarmAccess();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = widget.state;
    final timeLabel = TimeOfDay(
      hour: state.hour,
      minute: state.minute,
    ).format(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MergeSemantics(
          child: Row(
            children: [
              const Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    YouRowIcon(Icons.notifications_none_outlined),
                    SizedBox(width: AppSpacing.m),
                    Expanded(child: YouRowTitle('Daily reminder')),
                  ],
                ),
              ),
              Switch(
                value: state.enabled,
                onChanged: (value) async {
                  if (value) {
                    await _pickTimeAndEnable();
                  } else {
                    await ref.read(reminderProvider.notifier).disable();
                  }
                },
              ),
            ],
          ),
        ),
        if (state.enabled) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const SizedBox(width: YouRowIcon.size + AppSpacing.m),
              Expanded(
                child: Text(
                  !state.permissionGranted
                      ? 'Notifications are turned off for THIRTY in '
                            'system settings, so this won\'t fire yet.'
                      : !state.exactAlarmAccessGranted
                      ? 'Android access is needed to deliver this reminder '
                            'reliably.'
                      : state.timezoneUnavailable
                      ? 'Your reminder time is saved, but we couldn\'t '
                            'confirm your device\'s timezone just now, so '
                            'it isn\'t scheduled yet. This will resolve on '
                            'its own the next time you open THIRTY.'
                      : 'Reminds you at $timeLabel, if it fits that day.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              if (state.permissionGranted && !state.exactAlarmAccessGranted)
                TextButton(
                  onPressed: _requestExactAlarmAccess,
                  child: const Text('Allow access'),
                )
              else
                TextButton(
                  onPressed: _pickTimeAndUpdate,
                  child: const Text('Change time'),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
