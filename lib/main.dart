import 'package:flutter/material.dart';

import 'core/showcase/design_system_showcase_page.dart';
import 'core/theme/design_tokens.dart';

void main() {
  runApp(const ThirtyApp());
}

class ThirtyApp extends StatefulWidget {
  const ThirtyApp({super.key});

  @override
  State<ThirtyApp> createState() => _ThirtyAppState();
}

class _ThirtyAppState extends State<ThirtyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'THIRTY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: DesignSystemShowcasePage(
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}
