import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// RELEASE-DEVICE-FIX-1 (P2) — THIRTY's Android identity: the app is named
/// "THIRTY" (BRAND_BOOK.md §23); the launcher shows the founder-approved
/// B1.1 brand mark (watercolour artwork + canonical wordmark); and small
/// system surfaces use the one-colour Circle micro mark.
void main() {
  const res = 'android/app/src/main/res';
  String read(String path) => File(path).readAsStringSync();

  test('the Android display name is THIRTY, exactly', () {
    final labels = RegExp(r'<application[^>]*android:label="([^"]*)"')
        .allMatches(read('android/app/src/main/AndroidManifest.xml'))
        .map((match) => match.group(1))
        .toList();
    expect(labels, ['THIRTY']);
  });

  test('the adaptive icon layers the brand mark over its cream ground, '
      'with the micro mark as the themed (monochrome) layer', () {
    final adaptive = read('$res/mipmap-anydpi-v26/ic_launcher.xml');
    expect(adaptive, contains('@color/ic_launcher_background'));
    expect(adaptive, contains('@drawable/ic_launcher_foreground'));
    expect(adaptive, contains('@drawable/ic_launcher_monochrome'));

    final foreground = read('$res/drawable/ic_launcher_foreground.xml');
    expect(foreground, contains('@drawable/ic_launcher_artwork'));
    expect(foreground, contains('@drawable/ic_launcher_wordmark'));
    expect(
      File('$res/drawable-nodpi/ic_launcher_artwork.png').existsSync(),
      isTrue,
    );
  });

  test('the launcher wordmark is the canonical wordmark path, verbatim, in '
      'Circle Sage', () {
    final canonical = RegExp(
      r'\sd="([^"]+)"',
    ).firstMatch(read('assets/brand/thirty_wordmark.svg'))!.group(1);
    final wordmark = read('$res/drawable/ic_launcher_wordmark.xml');
    expect(wordmark, contains('android:pathData="$canonical"'));
    expect(wordmark, contains('android:fillColor="#FF7C8B6D"'));
  });

  test('legacy launcher PNGs exist at every density and are no longer the '
      'Flutter template icon', () {
    const sizes = {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };
    for (final entry in sizes.entries) {
      final bytes = File(
        '$res/mipmap-${entry.key}/ic_launcher.png',
      ).readAsBytesSync();
      // PNG IHDR: width and height are big-endian at bytes 16..23.
      int u32(int at) =>
          (bytes[at] << 24) |
          (bytes[at + 1] << 16) |
          (bytes[at + 2] << 8) |
          bytes[at + 3];
      expect(u32(16), entry.value, reason: entry.key);
      expect(u32(20), entry.value, reason: entry.key);
      // The Flutter template icons are palette PNGs (colour type 3); the
      // THIRTY tiles are RGBA (colour type 6) with transparent corners.
      expect(bytes[25], 6, reason: entry.key);
    }
  });

  test('the micro mark is a one-colour Circle: white for the notification '
      'small icon, a single tint colour for the themed icon', () {
    final stat = read('$res/drawable/ic_stat_thirty.xml');
    expect(stat, contains('android:strokeColor="#FFFFFFFF"'));
    expect(stat, contains('android:fillColor="#00000000"'));
    expect(stat, isNot(contains('pathData="m 199')));

    final mono = read('$res/drawable/ic_launcher_monochrome.xml');
    expect(
      RegExp(r'android:(?:stroke|fill)Color="(#[0-9A-F]{8})"')
          .allMatches(mono)
          .map((m) => m.group(1))
          .toSet()
          .difference({'#00000000'}),
      {'#FF000000'},
    );
  });

  test('reminders use the micro mark as their small icon, and release '
      'resource shrinking keeps it', () {
    final gateway = read(
      'lib/core/reminder/local_notifications_reminder_gateway.dart',
    );
    expect(
      gateway,
      contains("AndroidInitializationSettings('@drawable/ic_stat_thirty')"),
    );
    expect(gateway, isNot(contains('@mipmap/ic_launcher')));
    expect(
      read('$res/raw/keep.xml'),
      contains('tools:keep="@drawable/ic_stat_thirty"'),
    );
  });
}
