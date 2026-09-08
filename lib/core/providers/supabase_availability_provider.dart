import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether `Supabase.initialize` actually completed successfully at
/// startup (`main.dart`'s `initializeSupabaseIfConfigured`). Defaults to
/// `false`, so any code built outside the real app bootstrap — tests, or a
/// bare `ProviderContainer()` — never assumes an initialized client exists.
/// `SupabaseAnalyticsService` (`analytics_service.dart`) reads this before
/// touching `Supabase.instance` at all, rather than only discovering it's
/// unavailable by catching the failure after the fact.
final supabaseAvailableProvider = Provider<bool>((ref) => false);
