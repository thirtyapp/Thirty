import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/config/revenue_cat_config.dart';
import 'package:thirty/core/premium/entitlement_gateway.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';

/// RELEASE-HARDENING-1 — a release build cannot be produced with billing
/// unconfigured, Android hands the router no external locations, and an
/// unconfigured build never grants Premium.
void main() {
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();

  test('every release Gradle build runs the billing release check, before '
      'release signing is resolved', () {
    expect(gradle, contains('if (isReleaseTaskRequested) {'));
    expect(gradle, contains('"tool/verify_release_config.dart"'));
    expect(gradle, contains('throw GradleException('));
    final check = gradle.indexOf(
      RegExp(r'\n\s*verifyReleaseBillingConfig\(\)'),
    );
    expect(check, isNonNegative);
    expect(check, lessThan(gradle.indexOf('\nandroid {')));
  });

  test('there is no bypass: the check always runs to its verdict, and no '
      'flag, environment value or committed key can skip it', () {
    final start = gradle.indexOf('fun verifyReleaseBillingConfig() {');
    final end = gradle.indexOf('logger.lifecycle(report)', start);
    expect(start, isNonNegative);
    expect(end, greaterThan(start));
    final check = gradle.substring(start, end);
    expect(check, isNot(contains('return')));
    expect(check, isNot(contains('getenv')));
    // The only environment read in the build is the signing password
    // lookup (resolveSecret), which supplies a secret, never a skip.
    expect('System.getenv('.allMatches(gradle), hasLength(1));
    expect(gradle, contains('val fromEnv = System.getenv(envVarName)'));
    expect(gradle, isNot(contains(RegExp('ALLOW|SKIP', caseSensitive: false))));
    expect(gradle, isNot(contains('goog_')));
  });

  test('debug and profile builds never run the release check', () {
    expect(
      gradle,
      contains(
        'val isReleaseTaskRequested = gradle.startParameter.taskNames.any {\n'
            .replaceAll('\n', gradle.contains('\r\n') ? '\r\n' : '\n'),
      ),
    );
    expect(gradle, contains('it.contains("Release", ignoreCase = true)'));
  });

  test('the release check script judges with '
      'RevenueCatConfig.releaseProblems', () {
    final script = File('tool/verify_release_config.dart').readAsStringSync();
    expect(script, contains('config.releaseProblems()'));
    expect(script, contains('exitCode = 1'));
  });

  test('Flutter deep linking is off: no external location reaches the '
      'router', () {
    expect(
      RegExp(
        r'android:name="flutter_deeplinking_enabled"\s*'
        r'android:value="false"',
      ).hasMatch(manifest),
      isTrue,
    );
  });

  test('unconfigured billing (as in this build) resolves to the '
      'unavailable gateway and never grants Premium', () async {
    expect(RevenueCatConfig.fromEnvironment.isConfigured, isFalse);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(entitlementGatewayProvider),
      isA<UnavailableEntitlementGateway>(),
    );
    await container.read(entitlementStatusProvider.notifier).initialize();
    expect(
      container.read(entitlementStatusProvider),
      EntitlementStatus.unavailable,
    );
    expect(container.read(premiumEntitlementProvider), isFalse);
  });
}
