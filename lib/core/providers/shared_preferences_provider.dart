import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The resolved [SharedPreferences] instance.
///
/// Obtaining it is asynchronous, so it cannot be created lazily by this
/// provider itself. `main()` awaits [SharedPreferences.getInstance] once,
/// before `runApp`, and overrides this provider with the resolved value.
/// Tests do the same after calling [SharedPreferences.setMockInitialValues].
/// Reading this provider before it has been overridden is a programming
/// error.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden with a resolved '
    'SharedPreferences instance before the app starts.',
  );
});
