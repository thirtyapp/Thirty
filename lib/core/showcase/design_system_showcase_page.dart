import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../widgets/thirty_button.dart';
import '../widgets/thirty_card.dart';
import '../widgets/thirty_progress_circle.dart';

/// Internal page to visually verify THIRTY's design tokens and components.
/// This is a review tool, not a product screen.
class DesignSystemShowcasePage extends StatelessWidget {
  const DesignSystemShowcasePage({
    required this.themeMode,
    required this.onThemeModeChanged,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('THIRTY — Design System')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            _ThemeModeSwitcher(
              themeMode: themeMode,
              onChanged: onThemeModeChanged,
            ),
            const SizedBox(height: AppSpacing.section),
            const _Section(title: 'Colors', child: _ColorsShowcase()),
            const SizedBox(height: AppSpacing.section),
            const _Section(title: 'Typography', child: _TypographyShowcase()),
            const SizedBox(height: AppSpacing.section),
            const _Section(title: 'Spacing', child: _SpacingShowcase()),
            const SizedBox(height: AppSpacing.section),
            const _Section(title: 'Radius', child: _RadiusShowcase()),
            const SizedBox(height: AppSpacing.section),
            _Section(
              title: 'Shadows',
              child: _ShadowsShowcase(colors: colors),
            ),
            const SizedBox(height: AppSpacing.section),
            const _Section(title: 'Buttons', child: _ButtonsShowcase()),
            const SizedBox(height: AppSpacing.section),
            const _Section(title: 'Cards', child: _CardsShowcase()),
            const SizedBox(height: AppSpacing.section),
            const _Section(
              title: 'Progress Circle',
              child: _ProgressCircleShowcase(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeSwitcher extends StatelessWidget {
  const _ThemeModeSwitcher({required this.themeMode, required this.onChanged});

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(value: ThemeMode.system, label: Text('System')),
        ButtonSegment(value: ThemeMode.light, label: Text('Light')),
        ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
      ],
      selected: {themeMode},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.m),
        child,
      ],
    );
  }
}

class _ColorsShowcase extends StatelessWidget {
  const _ColorsShowcase();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final entries = <String, Color>{
      'primary': colors.primary,
      'secondary': colors.secondary,
      'background': colors.background,
      'surface': colors.surface,
      'textPrimary': colors.textPrimary,
      'textSecondary': colors.textSecondary,
      'border': colors.border,
      'disabled': colors.disabled,
      'success': colors.success,
      'warning': colors.warning,
      'error': colors.error,
    };

    return Wrap(
      spacing: AppSpacing.m,
      runSpacing: AppSpacing.m,
      children: entries.entries.map((entry) {
        return SizedBox(
          width: 96,
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: entry.value,
                  borderRadius: AppRadius.small,
                  border: Border.all(color: colors.border),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                entry.key,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TypographyShowcase extends StatelessWidget {
  const _TypographyShowcase();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final styles = <String, TextStyle?>{
      'displayLarge — 30': textTheme.displayLarge,
      'headlineSmall — Vandaag': textTheme.headlineSmall,
      'titleMedium — Ochtendwandeling': textTheme.titleMedium,
      'bodyLarge — Jouw 30 minuten van vandaag.': textTheme.bodyLarge,
      'bodyMedium — Morgen is een nieuwe cirkel.': textTheme.bodyMedium,
      'labelLarge — Start': textTheme.labelLarge,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: styles.entries.map((entry) {
        final label = entry.key.split(' — ').first;
        final sample = entry.key.split(' — ').last;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sample, style: entry.value),
              Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).extension<AppColors>()!.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SpacingShowcase extends StatelessWidget {
  const _SpacingShowcase();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final entries = <String, double>{
      'xs': AppSpacing.xs,
      's': AppSpacing.s,
      'm': AppSpacing.m,
      'l': AppSpacing.l,
      'xl': AppSpacing.xl,
      'xxl': AppSpacing.xxl,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Container(width: entry.value, height: 12, color: colors.primary),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RadiusShowcase extends StatelessWidget {
  const _RadiusShowcase();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final entries = <String, BorderRadius>{
      'small': AppRadius.small,
      'medium': AppRadius.medium,
      'large': AppRadius.large,
      'pill': AppRadius.pill,
    };

    return Wrap(
      spacing: AppSpacing.m,
      runSpacing: AppSpacing.m,
      children: entries.entries.map((entry) {
        return Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: entry.value,
                border: Border.all(color: colors.border),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(entry.key, style: Theme.of(context).textTheme.bodyMedium),
          ],
        );
      }).toList(),
    );
  }
}

class _ShadowsShowcase extends StatelessWidget {
  const _ShadowsShowcase({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.l,
      runSpacing: AppSpacing.m,
      children: [
        _shadowSample(context, label: 'light', shadow: AppShadows.light),
        _shadowSample(context, label: 'dark', shadow: AppShadows.dark),
      ],
    );
  }

  Widget _shadowSample(
    BuildContext context, {
    required String label,
    required List<BoxShadow> shadow,
  }) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 64,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppRadius.medium,
            boxShadow: shadow,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _ButtonsShowcase extends StatelessWidget {
  const _ButtonsShowcase();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.m,
      runSpacing: AppSpacing.m,
      children: [
        ThirtyButton(label: 'Primary', onPressed: () {}),
        const ThirtyButton(label: 'Primary disabled', onPressed: null),
        const ThirtyButton(
          label: 'Primary loading',
          onPressed: null,
          isLoading: true,
        ),
        ThirtyButton(
          label: 'Primary with icon',
          onPressed: () {},
          icon: Icons.play_arrow_rounded,
        ),
        ThirtyButton(
          label: 'Secondary',
          onPressed: () {},
          variant: ThirtyButtonVariant.secondary,
        ),
        const ThirtyButton(
          label: 'Secondary disabled',
          onPressed: null,
          variant: ThirtyButtonVariant.secondary,
        ),
      ],
    );
  }
}

class _CardsShowcase extends StatelessWidget {
  const _CardsShowcase();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        ThirtyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rustige kaart', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Een kaart zonder actie, puur ter presentatie.',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        ThirtyCard(
          onTap: () {},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tikbare kaart', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Deze kaart reageert op een tik.',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressCircleShowcase extends StatelessWidget {
  const _ProgressCircleShowcase();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final values = [0.0, 0.3, 0.75, 1.0];

    return Wrap(
      spacing: AppSpacing.l,
      runSpacing: AppSpacing.l,
      children: values.map((value) {
        return ThirtyProgressCircle(
          progress: value,
          size: 96,
          strokeWidth: 10,
          semanticLabel: 'Dagelijkse voortgang',
          child: Text(
            '${(value * 30).round()} min',
            style: textTheme.bodyMedium,
          ),
        );
      }).toList(),
    );
  }
}
