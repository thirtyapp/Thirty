import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/l10n/thirty_locales.dart';
import 'package:thirty/core/premium/entitlement_gateway.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/reminder/reminder_gateway.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/features/settings/presentation/settings_page.dart';
import 'package:thirty/l10n/gen/app_localizations.dart';
import 'package:thirty/l10n/gen/app_localizations_en.dart';

/// G-02 / L-CNT-EN / Batch 2 (You page chrome): the page heading, its
/// subtitle and the Personal, Preferences and Data & privacy headings come
/// from THIRTY's English catalogue and say exactly what they said before.
/// The rendered page itself stays pinned against the baseline by the
/// frozen `you_about_en_golden_test.dart` (whole-page semantics tree).
void main() {
  const arbPath = 'lib/l10n/arb/app_en.arb';
  const owner = 'lib/features/settings/presentation/settings_page.dart';
  Map<String, Object?> arb() =>
      jsonDecode(File(arbPath).readAsStringSync()) as Map<String, Object?>;

  /// The five authorized keys, in page order, with their baseline English.
  const batch2 = <String, String>{
    'youPageTitle': 'You',
    'youPageSubtitle': 'Your space in THIRTY.',
    'youPersonalSectionTitle': 'Personal',
    'youPreferencesSectionTitle': 'Preferences',
    'youDataPrivacySectionTitle': 'Data & privacy',
  };

  String valueOf(AppLocalizations l, String key) => switch (key) {
    'youPageTitle' => l.youPageTitle,
    'youPageSubtitle' => l.youPageSubtitle,
    'youPersonalSectionTitle' => l.youPersonalSectionTitle,
    'youPreferencesSectionTitle' => l.youPreferencesSectionTitle,
    'youDataPrivacySectionTitle' => l.youDataPrivacySectionTitle,
    _ => throw ArgumentError(key),
  };

  group('the English catalogue', () {
    test('holds the five words with their exact English values', () {
      final c = arb();
      for (final MapEntry(:key, :value) in batch2.entries) {
        expect(c[key], value, reason: key);
      }
    });

    test('keeps Batch 1 unchanged, and adds the five after it', () {
      final keys = [
        for (final k in arb().keys)
          if (!k.startsWith('@')) k,
      ];
      expect(keys, [
        'brandName',
        'youAboutSectionTitle',
        'youAboutVersion',
        ...batch2.keys,
      ]);
      final c = arb();
      expect(c['brandName'], 'THIRTY');
      expect(c['youAboutSectionTitle'], 'About');
      expect(c['youAboutVersion'], 'Version {version}');
    });

    test('describes each key where it sits on You and what it is', () {
      final c = arb();
      String description(String key) =>
          (c['@$key']! as Map<String, Object?>)['description']! as String;
      for (final key in batch2.keys) {
        expect(
          description(key).length,
          greaterThan(100),
          reason: '$key needs a description a translator can act on',
        );
        expect(description(key), startsWith('You tab: '), reason: key);
      }
      expect(description('youPageTitle'), contains("the page's main heading"));
      expect(description('youPageTitle'), contains('announced as a heading'));
      expect(description('youPageSubtitle'), contains('subtitle'));
      expect(
        description('youPageSubtitle'),
        contains(
          'THIRTY is the product name (see brandName) and is never '
          'translated',
        ),
      );
      for (final (key, section) in [
        ('youPersonalSectionTitle', 'Personal'),
        ('youPreferencesSectionTitle', 'Preferences'),
        ('youDataPrivacySectionTitle', 'Data & privacy'),
      ]) {
        expect(
          description(key),
          contains('the heading of the $section section'),
          reason: key,
        );
        expect(description(key), contains('announced as a heading'));
      }
    });

    test('declares no placeholder, and no value uses ICU syntax', () {
      final c = arb();
      for (final MapEntry(:key, :value) in batch2.entries) {
        final meta = c['@$key']! as Map<String, Object?>;
        expect(meta.keys, ['description'], reason: key);
        expect(value, isNot(matches(RegExp(r"[{}']"))), reason: key);
      }
    });
  });

  group('the generated English catalogue', () {
    final en = lookupAppLocalizations(const Locale('en'));

    test('gives the baseline words', () {
      expect(en, isA<AppLocalizationsEn>());
      for (final MapEntry(:key, :value) in batch2.entries) {
        expect(valueOf(en, key), value, reason: key);
      }
    });

    test('declares plain String getters, and still supports English only', () {
      final generated = File(
        'lib/l10n/gen/app_localizations.dart',
      ).readAsStringSync();
      final english = File(
        'lib/l10n/gen/app_localizations_en.dart',
      ).readAsStringSync();
      for (final MapEntry(:key, :value) in batch2.entries) {
        expect(generated, contains('String get $key;'), reason: key);
        expect(english, contains("String get $key => '$value';"), reason: key);
      }
      expect(AppLocalizations.supportedLocales, const [Locale('en')]);
    });

    test('every device language gets the same English words (G-5C)', () {
      for (final locale in const [
        Locale('en', 'US'),
        Locale('fr', 'FR'),
        Locale('nl', 'NL'),
        Locale('es', 'ES'),
        Locale('de', 'DE'),
        Locale('it', 'IT'),
        Locale('ja', 'JP'),
      ]) {
        final l = thirtyLocalizationsFor(locale);
        expect(l, isA<AppLocalizationsEn>(), reason: '$locale');
        for (final MapEntry(:key, :value) in batch2.entries) {
          expect(valueOf(l, key), value, reason: '$locale $key');
        }
      }
    });
  });

  group('the owning source', () {
    final source = File(owner).readAsStringSync();

    /// The source without its comments: doc comments quote the words to
    /// describe the page, and are not copy.
    final code = [
      for (final line in source.split('\n'))
        if (!line.trimLeft().startsWith('//')) line,
    ].join('\n');

    test('no longer holds any of the five English literals', () {
      expect(code, contains('class SettingsPage'));
      for (final value in batch2.values) {
        expect(code, isNot(contains("'$value'")), reason: value);
        expect(code, isNot(contains('"$value"')), reason: value);
      }
      expect(code, isNot(contains('static const title')));
      expect(code, isNot(contains('static const subtitle')));
    });

    test('reads each word from the catalogue, through context.l10n', () {
      for (final key in batch2.keys) {
        expect(
          RegExp('context\\.l10n\\.$key\\b').allMatches(source),
          hasLength(1),
          reason: key,
        );
      }
      // Batch 1 untouched.
      expect(source, contains('context.l10n.youAboutSectionTitle'));
    });
  });

  group('the rendered page', () {
    testWidgets('the production UI obtains all five words from the '
        'catalogue: a marked catalogue changes exactly those five', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpYou(
        tester,
        deviceLocale: const Locale('en', 'US'),
        delegates: const [
          _MarkedDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      );
      for (final MapEntry(:key, :value) in batch2.entries) {
        expect(find.text('[fixture] $key'), findsOneWidget, reason: key);
        expect(find.text(value), findsNothing, reason: value);
      }
      for (final key in batch2.keys.where((k) => k != 'youPageSubtitle')) {
        expect(
          tester.getSemantics(find.text('[fixture] $key')),
          isSemantics(isHeader: true),
          reason: key,
        );
      }
      // The page's header node is built from the catalogue's words.
      expect(
        tester.getSemantics(find.text('[fixture] youPageTitle')).label,
        '[fixture] youPageTitle\n[fixture] youPageSubtitle',
      );
      // Everything else on the page still reads the real catalogue.
      expect(find.text('About'), findsOneWidget);
      semantics.dispose();
    });

    for (final locale in const [
      Locale('en', 'US'),
      Locale('fr', 'FR'),
      Locale('nl', 'NL'),
      Locale('es', 'ES'),
      Locale('de', 'DE'),
      Locale('it', 'IT'),
      Locale('ja', 'JP'),
    ]) {
      testWidgets('device language $locale: the same English words, in the '
          'same order, with the same heading semantics', (tester) async {
        final semantics = tester.ensureSemantics();
        await _pumpYou(
          tester,
          deviceLocale: locale,
          delegates: thirtyLocalizationsDelegates,
        );
        final l10n = AppLocalizations.of(
          tester.element(find.byType(SettingsPage)),
        );
        expect(l10n, isA<AppLocalizationsEn>());
        double top(String text) => tester.getTopLeft(find.text(text)).dy;
        final order = [...batch2.values, 'About'];
        for (final text in order) {
          expect(find.text(text), findsOneWidget, reason: text);
        }
        for (var i = 1; i < order.length; i++) {
          expect(
            top(order[i]),
            greaterThan(top(order[i - 1])),
            reason: '${order[i]} below ${order[i - 1]}',
          );
        }
        // The heading and its subtitle are one header node, as at the
        // baseline (frozen in you_about_en_golden_28827e73.json).
        final header = tester.getSemantics(find.text('You'));
        expect(header, isSemantics(isHeader: true));
        expect(header.label, 'You\nYour space in THIRTY.');
        expect(
          tester.getSemantics(find.text('Your space in THIRTY.')).id,
          header.id,
        );
        for (final heading in [
          'Personal',
          'Preferences',
          'Data & privacy',
          'About',
        ]) {
          final node = tester.getSemantics(find.text(heading));
          expect(node, isSemantics(isHeader: true), reason: heading);
          expect(node.label, heading, reason: heading);
        }
        semantics.dispose();
      });
    }
  });
}

/// THIRTY's English catalogue with the five Batch 2 words replaced by
/// `[fixture] <key>` markers — not product copy.
class _Marked extends AppLocalizationsEn {
  @override
  String get youPageTitle => '[fixture] youPageTitle';
  @override
  String get youPageSubtitle => '[fixture] youPageSubtitle';
  @override
  String get youPersonalSectionTitle => '[fixture] youPersonalSectionTitle';
  @override
  String get youPreferencesSectionTitle =>
      '[fixture] youPreferencesSectionTitle';
  @override
  String get youDataPrivacySectionTitle =>
      '[fixture] youDataPrivacySectionTitle';
}

class _MarkedDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _MarkedDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';
  @override
  Future<AppLocalizations> load(Locale locale) async => _Marked();
  @override
  bool shouldReload(_MarkedDelegate old) => false;
}

class _FakeReminderGateway implements ReminderGateway {
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<bool> hasExactAlarmAccess() async => true;
  @override
  Future<void> requestExactAlarmAccess() async {}
  @override
  Future<ScheduleOutcome> scheduleDaily({
    required DateTime firstOccurrenceLocal,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async => ScheduleOutcome.scheduled;
  @override
  Future<void> cancel() async {}
}

class _FakeEntitlementGateway implements EntitlementGateway {
  @override
  Stream<EntitlementStatus> get statusUpdates => const Stream.empty();
  @override
  Future<EntitlementStatus> initialize() async => EntitlementStatus.inactive;
  @override
  Future<MonthlyOffer?> monthlyOffer() async => null;
  @override
  Future<PurchaseOutcome> purchaseMonthly() async => PurchaseOutcome.error;
  @override
  Future<RestoreOutcome> restore() async => RestoreOutcome.notFound;
  @override
  Future<String?> managementUrl() async => null;
}

/// You as the app hosts it (English-only resolution, `thirty_app.dart`),
/// in a tall view so every section is built.
Future<void> _pumpYou(
  WidgetTester tester, {
  required Locale deviceLocale,
  required List<LocalizationsDelegate<Object?>> delegates,
}) async {
  tester.view.physicalSize = const Size(412, 6000);
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.localesTestValue = [deviceLocale];
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      entitlementGatewayProvider.overrideWithValue(_FakeEntitlementGateway()),
      sharedPreferencesProvider.overrideWithValue(prefs),
      reminderGatewayProvider.overrideWithValue(_FakeReminderGateway()),
      nowProvider.overrideWithValue(DateTime(2026, 10, 4, 14)),
    ],
  );
  addTearDown(container.dispose);
  await container.read(entitlementStatusProvider.notifier).initialize();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: delegates,
        supportedLocales: thirtyReleaseLocales,
        localeListResolutionCallback: thirtyLocaleListResolution,
        home: const SettingsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
