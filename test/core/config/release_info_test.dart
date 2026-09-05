import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/config/release_info.dart';

void main() {
  group('ReleaseInfo', () {
    test(
      'appVersion stays in sync with pubspec.yaml\'s own version — '
      'ReleaseInfo.appVersion is hand-maintained (no package_info_plus '
      'dependency), so nothing else catches the two drifting apart',
      () {
        final pubspec = File('pubspec.yaml').readAsStringSync();
        final match = RegExp(
          r'^version:\s*(\S+)',
          multiLine: true,
        ).firstMatch(pubspec);

        expect(match, isNotNull, reason: 'pubspec.yaml must declare a version');
        expect(ReleaseInfo.appVersion, match!.group(1));
      },
    );
  });
}
