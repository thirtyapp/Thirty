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

  /// Throws a [StateError] when [url] or [publishableKey] is missing —
  /// blank or whitespace-only counts as missing. Fails fast, before
  /// `Supabase.initialize` or `runApp` ever run.
  void assertValid() {
    if (url.trim().isEmpty || publishableKey.trim().isEmpty) {
      throw StateError(
        'Supabase-configuratie ontbreekt. Start de app met '
        'flutter run --dart-define-from-file=config/supabase.local.json '
        '(zie config/supabase.example.json).',
      );
    }
  }
}
