import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/analytics/analytics_consent.dart';
import '../../../core/premium/entitlement_gateway.dart';
import '../../../core/premium/entitlement_status.dart';
import '../../../core/premium/premium_access.dart';
import '../../../core/providers/theme_mode_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/thirty_button.dart';
import '../../../core/widgets/thirty_card.dart';
import '../../reminder/application/reminder_provider.dart';

/// THIRTY's Settings surface — Step 5
/// (`docs/product/adr/ADR-017-v1-step5-revenuecat-billing.md`,
/// reconciled against the parent `THIRTY V1 PRODUCTIZATION + COMMERCIAL
/// REVIEW.md` §9/§32's actual V1 Settings minimum).
///
/// Exposes exactly the controls that authority both requires *and* this
/// app can truthfully back today:
///
/// - Premium status/upgrade, restore, manage subscription (frozen
///   architecture §14);
/// - theme (System/Light/Dark) — [themeModeProvider] already drives
///   `ThirtyApp`'s real `MaterialApp.router`; before this screen, the
///   only place a user could reach it was the internal `/showcase`
///   developer route, not a real product surface;
/// - analytics consent (`AnalyticsConsentNotifier` — off by default, the
///   sole gate `analyticsServiceProvider` now checks before transmitting
///   anything);
/// - the local reminder's on/off state, permission state and one time
///   (`ReminderNotifier` — parent §27/§28), reusing the same
///   `showTimePicker` flow as `ReminderInvitationCard`;
/// - the existing Circle-history data controls (export/delete).
///
/// Deliberately **not** included, because no authoritative value exists
/// anywhere in this repository to back it truthfully — fabricating
/// either would be worse than omitting them: a support contact and a
/// privacy-policy link.
///
/// `url_launcher` here is already present transitively via
/// `supabase_flutter`'s own dependency graph — not a new package added for
/// this screen (frozen architecture's dependency-exception, §3 of the
/// Step 5 report, is scoped to `purchases_flutter` only).
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isRestoring = false;
  String? _restoreMessage;

  Future<void> _restore() async {
    setState(() {
      _isRestoring = true;
      _restoreMessage = null;
    });
    final gateway = ref.read(entitlementGatewayProvider);
    final outcome = await gateway.restore();
    if (!mounted) return;
    setState(() {
      _isRestoring = false;
      _restoreMessage = switch (outcome) {
        RestoreOutcome.restored => 'Your Premium access has been restored.',
        RestoreOutcome.notFound => 'No previous purchase was found to restore.',
        RestoreOutcome.unavailable =>
          'Restore isn’t available right now. Please try again later.',
        RestoreOutcome.error =>
          'Something went wrong restoring your purchase. Please try again.',
      };
    });
  }

  Future<void> _openManagement(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final status = ref.watch(entitlementStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            Text('Premium', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s),
            ThirtyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusRow(status: status),
                  const SizedBox(height: AppSpacing.s),
                  if (status == EntitlementStatus.active)
                    FutureBuilder<String?>(
                      future: ref.read(entitlementGatewayProvider).managementUrl(),
                      builder: (context, snapshot) {
                        final url = snapshot.data;
                        if (url == null) {
                          return Text(
                            'Manage or cancel this subscription from the '
                            'Google Play Store app.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          );
                        }
                        return ThirtyButton(
                          label: 'Manage subscription',
                          variant: ThirtyButtonVariant.secondary,
                          onPressed: () => _openManagement(url),
                        );
                      },
                    )
                  else
                    ThirtyButton(
                      label: 'Upgrade to Premium',
                      onPressed: () => context.push('/premium'),
                    ),
                  const SizedBox(height: AppSpacing.s),
                  ThirtyButton(
                    label: 'Restore purchases',
                    variant: ThirtyButtonVariant.secondary,
                    isLoading: _isRestoring,
                    onPressed: _isRestoring ? null : _restore,
                  ),
                  if (_restoreMessage != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _restoreMessage!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            Text('Appearance', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s),
            ThirtyCard(child: _ThemeModeRow(themeMode: ref.watch(themeModeProvider))),
            const SizedBox(height: AppSpacing.m),
            Text('Analytics', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s),
            ThirtyCard(child: _AnalyticsConsentRow()),
            const SizedBox(height: AppSpacing.m),
            Text('Reminder', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s),
            ThirtyCard(child: _ReminderRow(state: ref.watch(reminderProvider))),
            const SizedBox(height: AppSpacing.m),
            Text('Your data', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s),
            ThirtyCard(
              // Since Batch B, `/history` is the Journal branch root of
              // the primary navigation shell — `go`, not `push`, is the
              // correct way to reach a shell branch from a route (like
              // Settings) that lives outside it; see
              // `../../home/presentation/home_page.dart`'s own doc comment
              // for why.
              onTap: () => context.go('/history'),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your Circle history — view, export or delete',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeRow extends ConsumerWidget {
  const _ThemeModeRow({required this.themeMode});

  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      container: true,
      label: 'Theme',
      child: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(value: ThemeMode.system, label: Text('System')),
          ButtonSegment(value: ThemeMode.light, label: Text('Light')),
          ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
        ],
        selected: {themeMode},
        onSelectionChanged: (selection) => ref
            .read(themeModeProvider.notifier)
            .setThemeMode(selection.first),
      ),
    );
  }
}

class _AnalyticsConsentRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final consent = ref.watch(analyticsConsentProvider);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Share anonymous usage data', style: textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Off by default. Helps us understand what to improve. '
                'Your Circle history is never included.',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: consent,
          onChanged: (value) =>
              ref.read(analyticsConsentProvider.notifier).setConsent(value),
        ),
      ],
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
    final initial = TimeOfDay(hour: widget.state.hour, minute: widget.state.minute);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    await ref
        .read(reminderProvider.notifier)
        .enable(hour: picked.hour, minute: picked.minute);
  }

  Future<void> _pickTimeAndUpdate() async {
    final initial = TimeOfDay(hour: widget.state.hour, minute: widget.state.minute);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    await ref
        .read(reminderProvider.notifier)
        .setTime(hour: picked.hour, minute: picked.minute);
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
        Row(
          children: [
            Expanded(
              child: Text('Daily reminder', style: textTheme.bodyMedium),
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
        if (state.enabled) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  !state.permissionGranted
                      ? 'Notifications are turned off for THIRTY in '
                            'system settings, so this won\'t fire yet.'
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

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.status});

  final EntitlementStatus status;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final (label, description) = switch (status) {
      EntitlementStatus.active => (
        'Premium is active',
        'Plans, Coach and Insights are available.',
      ),
      EntitlementStatus.inactive => (
        'Premium is not active',
        'Free remains complete. Your saved Plan positions and Insights '
            'stay on this device.',
      ),
      EntitlementStatus.initializing => (
        'Checking your Premium status…',
        null,
      ),
      EntitlementStatus.unavailable => (
        'Premium status is temporarily unavailable',
        'This does not affect your saved records. Please try again '
            'later.',
      ),
    };

    return Semantics(
      label: description == null ? label : '$label. $description',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.bodyLarge?.copyWith(
                color: status == EntitlementStatus.active
                    ? colors.primary
                    : null,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
