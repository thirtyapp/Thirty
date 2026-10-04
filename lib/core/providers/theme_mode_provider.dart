import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared_preferences_provider.dart';

/// The SharedPreferences key holding the chosen [ThemeMode] by name
/// (`system` / `light` / `dark`).
const themeModeKey = 'theme_mode_v1';

/// Holds THIRTY's current [ThemeMode], defaulting to the system setting.
///
/// The choice made on You persists locally, so it survives a cold start.
/// No stored value — or one this build doesn't recognise — means
/// [ThemeMode.system].
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // `get`, not `getString`: a corrupt non-String value must fall back,
    // never throw during app start.
    final stored = ref.read(sharedPreferencesProvider).get(themeModeKey);
    return (stored is String ? ThemeMode.values.asNameMap()[stored] : null) ??
        ThemeMode.system;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    unawaited(
      ref.read(sharedPreferencesProvider).setString(themeModeKey, mode.name),
    );
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
