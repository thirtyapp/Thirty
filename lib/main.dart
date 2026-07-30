import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app/thirty_app.dart';
import 'core/config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const config = SupabaseConfig.fromEnvironment;
  config.assertValid();

  await Supabase.initialize(
    url: config.url,
    publishableKey: config.publishableKey,
  );

  runApp(const ProviderScope(child: ThirtyApp()));
}
