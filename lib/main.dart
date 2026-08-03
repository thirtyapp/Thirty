import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app/thirty_app.dart';
import 'core/config/supabase_config.dart';
import 'core/providers/shared_preferences_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const config = SupabaseConfig.fromEnvironment;
  config.assertValid();

  await Supabase.initialize(
    url: config.url,
    publishableKey: config.publishableKey,
  );

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const ThirtyApp(),
    ),
  );
}
