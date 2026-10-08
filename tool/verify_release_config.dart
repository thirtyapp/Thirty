// Release-build gate for THIRTY's billing configuration
// (RELEASE-HARDENING-1). Run by `android/app/build.gradle.kts` for every
// release build, with the build's dart-define values passed in the
// environment; exits non-zero — failing the build — unless
// `RevenueCatConfig.releaseProblems` is empty. Prints setting names only,
// never values.
//
// Manual use, with the same values a release would be built with:
//   REVENUECAT_ANDROID_API_KEY=… REVENUECAT_ENTITLEMENT_ID=… \
//     dart tool/verify_release_config.dart
import 'dart:io';

import 'package:thirty/core/config/revenue_cat_config.dart';

void main() {
  final environment = Platform.environment;
  final config = RevenueCatConfig(
    androidApiKey: environment['REVENUECAT_ANDROID_API_KEY'] ?? '',
    entitlementId: environment['REVENUECAT_ENTITLEMENT_ID'] ?? '',
  );

  final problems = config.releaseProblems();
  if (problems.isEmpty) {
    stdout.writeln('THIRTY release billing configuration: OK');
    return;
  }
  stderr.writeln('THIRTY release billing configuration is not release-ready:');
  for (final problem in problems) {
    stderr.writeln('  - $problem');
  }
  exitCode = 1;
}
