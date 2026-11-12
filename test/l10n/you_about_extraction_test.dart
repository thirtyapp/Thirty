import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/config/release_info.dart';
import 'package:thirty/core/l10n/thirty_locales.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/features/settings/presentation/widgets/you_about_card.dart';
import 'package:thirty/l10n/gen/app_localizations.dart';
import 'package:thirty/l10n/gen/app_localizations_en.dart';

/// G-02 / L-CNT-EN / Batch 1 (You → About): the About words come from
/// THIRTY's English catalogue — `youAboutSectionTitle`, `youAboutVersion`
/// (with the version from [ReleaseInfo.appVersion]) and the existing
/// `brandName` — and say exactly what they said before. The rendered page
/// itself is pinned against the baseline by `you_about_en_golden_test.dart`.
void main() {
  const arbPath = 'lib/l10n/arb/app_en.arb';
  Map<String, Object?> arb() =>
      jsonDecode(File(arbPath).readAsStringSync()) as Map<String, Object?>;

  group('the English catalogue', () {
    test('holds the About words with their exact English values', () {
      final c = arb();
      expect(c['youAboutSectionTitle'], 'About');
      expect(c['youAboutVersion'], 'Version {version}');
      expect(c['brandName'], 'THIRTY');
    });

    test('describes each key, and declares the version placeholder as a '
        'String used exactly once', () {
      final c = arb();
      for (final key in [
        'brandName',
        'youAboutSectionTitle',
        'youAboutVersion',
      ]) {
        final meta = c['@$key']! as Map<String, Object?>;
        expect(
          (meta['description']! as String).length,
          greaterThan(60),
          reason: '$key needs a description a translator can act on',
        );
      }
      expect((c['@youAboutSectionTitle']! as Map)['placeholders'], isNull);
      expect((c['@youAboutVersion']! as Map)['placeholders'], {
        'version': {'type': 'String'},
      });
      expect(
        RegExp(r'\{version\}').allMatches(c['youAboutVersion']! as String),
        hasLength(1),
      );
    });

    test('never holds the version itself, and THIRTY has one key '
        '(brandName, reused)', () {
      final raw = File(arbPath).readAsStringSync();
      expect(raw, isNot(contains(ReleaseInfo.appVersion)));
      expect(RegExp(r'\d+\.\d+\.\d+').hasMatch(raw), isFalse);
      final values = [
        for (final MapEntry(:key, :value) in arb().entries)
          if (!key.startsWith('@')) value,
      ];
      expect(values.where((v) => v == 'THIRTY'), hasLength(1));
    });
  });

  group('lookup', () {
    final en = lookupAppLocalizations(const Locale('en'));

    test('the generated English catalogue gives the baseline words', () {
      expect(en, isA<AppLocalizationsEn>());
      expect(en.youAboutSectionTitle, 'About');
      expect(en.brandName, 'THIRTY');
      expect(
        en.youAboutVersion(ReleaseInfo.appVersion),
        'Version ${ReleaseInfo.appVersion}',
      );
    });

    test('the version is inserted verbatim: no space, padding, trimming or '
        'number formatting', () {
      for (final v in ['1.7.0+14', '10.12.0+120', '2.0.0', '1.0.0-rc.1+3']) {
        expect(en.youAboutVersion(v), 'Version $v');
      }
      final shown = en.youAboutVersion(ReleaseInfo.appVersion);
      expect(shown.length, 'Version '.length + ReleaseInfo.appVersion.length);
      expect(shown, isNot(contains('  ')));
      expect(shown.trim(), shown);
    });

    test('every device language gets the same English words (G-5C)', () {
      for (final locale in const [
        Locale('fr'),
        Locale('fr', 'BE'),
        Locale('nl'),
        Locale('es', 'MX'),
        Locale('de'),
        Locale('it'),
        Locale('pt', 'BR'),
        Locale('ja'),
        Locale('ar'),
      ]) {
        final l = thirtyLocalizationsFor(locale);
        expect(l, isA<AppLocalizationsEn>(), reason: '$locale');
        expect(l.youAboutSectionTitle, 'About', reason: '$locale');
        expect(l.brandName, 'THIRTY', reason: '$locale');
        expect(
          l.youAboutVersion(ReleaseInfo.appVersion),
          'Version ${ReleaseInfo.appVersion}',
          reason: '$locale',
        );
      }
    });
  });

  testWidgets('the About card reads brandName and youAboutVersion, as one '
      'merged node with no action', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.platformDispatcher.localesTestValue = const [Locale('de', 'DE')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: thirtyLocalizationsDelegates,
        supportedLocales: thirtyReleaseLocales,
        localeListResolutionCallback: thirtyLocaleListResolution,
        home: const Scaffold(body: YouAboutCard()),
      ),
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(YouAboutCard)));
    expect(l10n, isA<AppLocalizationsEn>());
    expect(find.text(l10n.brandName), findsOneWidget);
    expect(
      find.text(l10n.youAboutVersion(ReleaseInfo.appVersion)),
      findsOneWidget,
    );
    final node = tester.getSemantics(
      find.text('Version ${ReleaseInfo.appVersion}'),
    );
    expect(node.label, 'THIRTY\nVersion ${ReleaseInfo.appVersion}');
    expect(node.getSemanticsData().actions, 0);
    semantics.dispose();
  });

  test('the generated code declares the keys with the String placeholder, '
      'and still supports English only', () {
    final generated = File(
      'lib/l10n/gen/app_localizations.dart',
    ).readAsStringSync();
    final english = File(
      'lib/l10n/gen/app_localizations_en.dart',
    ).readAsStringSync();
    expect(generated, contains('String get youAboutSectionTitle;'));
    expect(generated, contains('String youAboutVersion(String version);'));
    expect(english, contains("String get youAboutSectionTitle => 'About';"));
    expect(english, contains("return 'Version \$version';"));
    expect(AppLocalizations.supportedLocales, const [Locale('en')]);
  });
}
