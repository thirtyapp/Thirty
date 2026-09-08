/// THIRTY's Supabase connection configuration, read from compile-time
/// environment values (see `--dart-define-from-file`). Deliberately has no
/// dependency on `supabase_flutter` so its validation logic stays plain,
/// fast unit-testable Dart.
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.publishableKey});

  final String url;
  final String publishableKey;

  static const fromEnvironment = SupabaseConfig(
    url: String.fromEnvironment('SUPABASE_URL'),
    publishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );

  /// Whether both values needed to safely initialize Supabase are present.
  /// Blank/whitespace-only counts as missing. Supabase backs only the one
  /// narrow, optional, consent-gated analytics path (see
  /// `analytics_service.dart`) — never the Free product itself — so a
  /// missing value here must skip `Supabase.initialize` and leave telemetry
  /// unavailable, never prevent `runApp` from running (`main.dart`).
  bool get isConfigured =>
      url.trim().isNotEmpty && publishableKey.trim().isNotEmpty;
}
