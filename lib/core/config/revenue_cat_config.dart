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
}
