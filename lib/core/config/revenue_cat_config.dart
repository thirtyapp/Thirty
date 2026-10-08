/// THIRTY's RevenueCat billing configuration, read from compile-time
/// environment values (see `--dart-define-from-file`) — same pattern as
/// `supabase_config.dart`, deliberately kept free of any dependency on
/// `purchases_flutter` so this stays plain, fast unit-testable Dart.
///
/// **No real identifier is ever committed here or anywhere else in this
/// repository.** [androidApiKey] and [entitlementId] are supplied only at
/// build time by whoever owns the RevenueCat project and Google Play
/// listing — see `config/revenuecat.example.json` for the expected shape
/// and `docs/product/adr/ADR-017-v1-step5-revenuecat-billing.md` for the
/// exact external setup this depends on.
///
/// Unlike [SupabaseConfig.assertValid], missing RevenueCat configuration
/// deliberately never throws — frozen architecture §7/§24 requires Free to
/// stay completely independent of billing, so a missing or malformed key
/// must fail closed for Premium only, never crash startup. See
/// [isConfigured] and `entitlement_gateway.dart`'s `UnavailableEntitlementGateway`.
class RevenueCatConfig {
  const RevenueCatConfig({
    required this.androidApiKey,
    required this.entitlementId,
  });

  /// RevenueCat's public (client-safe) Android API key for this project.
  /// Never a secret/server key — RevenueCat's Android SDK key is designed
  /// to be embedded in a distributed app build.
  final String androidApiKey;

  /// The entitlement identifier configured in the RevenueCat dashboard for
  /// "THIRTY Premium" (frozen architecture §5: one entitlement covering
  /// Plans + Coach + Insights). Not a product or offering id.
  final String entitlementId;

  static const fromEnvironment = RevenueCatConfig(
    androidApiKey: String.fromEnvironment('REVENUECAT_ANDROID_API_KEY'),
    entitlementId: String.fromEnvironment('REVENUECAT_ENTITLEMENT_ID'),
  );

  /// Whether both values needed to safely initialize billing are present.
  /// Blank/whitespace-only counts as missing. When `false`, the billing
  /// adapter must never call into the RevenueCat SDK at all — see
  /// [isConfigured]'s only caller, `entitlementGatewayProvider`
  /// (`entitlement_gateway.dart`).
  bool get isConfigured =>
      androidApiKey.trim().isNotEmpty && entitlementId.trim().isNotEmpty;

  /// Why this configuration must not go into a distributed release build —
  /// empty when it may. Stricter than [isConfigured], which only decides
  /// whether to start the SDK at all: a release additionally needs real
  /// Google Play values, never the `config/revenuecat.example.json`
  /// placeholders or a non-Play (e.g. RevenueCat Test Store) key. Messages
  /// name the missing setting but never echo a value.
  ///
  /// Enforced before any release artifact exists:
  /// `android/app/build.gradle.kts` runs `tool/verify_release_config.dart`
  /// for every release build and fails the build on any problem.
  List<String> releaseProblems() {
    final key = androidApiKey.trim();
    final entitlement = entitlementId.trim();
    return [
      if (key.isEmpty)
        'REVENUECAT_ANDROID_API_KEY is missing.'
      else if (key == exampleAndroidApiKey)
        'REVENUECAT_ANDROID_API_KEY is still the example placeholder.'
      else if (!key.startsWith(googlePlayKeyPrefix))
        'REVENUECAT_ANDROID_API_KEY is not a RevenueCat Google Play public '
            'SDK key (expected the "$googlePlayKeyPrefix" prefix).',
      if (entitlement.isEmpty)
        'REVENUECAT_ENTITLEMENT_ID is missing.'
      else if (entitlement == exampleEntitlementId)
        'REVENUECAT_ENTITLEMENT_ID is still the example placeholder.',
    ];
  }

  /// RevenueCat's prefix for a Google Play app's public SDK key.
  static const googlePlayKeyPrefix = 'goog_';

  /// The placeholders in `config/revenuecat.example.json`.
  static const exampleAndroidApiKey = 'goog_your_public_android_sdk_key';
  static const exampleEntitlementId = 'your_dashboard_entitlement_identifier';
}
