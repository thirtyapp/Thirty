import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/l10n/thirty_locales.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/personal_circle/presentation/yours_page.dart';
import 'package:thirty/features/settings/presentation/widgets/you_personal_card.dart';
import 'package:thirty/l10n/gen/app_localizations.dart';
import 'package:thirty/l10n/gen/app_localizations_en.dart';

/// G-02 / L-CNT-EN / Batch 3 (You → Personal: the Memory and History rows):
/// the two rows' titles and supporting lines come from THIRTY's English
/// catalogue, say exactly what they said before, and keep their order,
/// destinations, button semantics and composed spoken labels. The whole
/// page stays pinned against the baseline by the frozen
/// `you_about_en_golden_test.dart` (whole-page semantics tree).
void main() {
  const arbPath = 'lib/l10n/arb/app_en.arb';
  const owner =
      'lib/features/settings/presentation/widgets/you_personal_card.dart';
  Map<String, Object?> arb() =>
      jsonDecode(File(arbPath).readAsStringSync()) as Map<String, Object?>;

  /// The four authorized keys, in row order, with their baseline English.
  const batch3 = <String, String>{
    'youPersonalMemoryTitle': 'What THIRTY remembers',
    'youPersonalMemoryDetail': 'What you’ve told it, need by need',
    'youPersonalHistoryTitle': 'Your Circles',
    'youPersonalHistoryDetail': 'Every Circle, as it happened',
  };

  /// The frozen Batch 1 + Batch 2 catalogue, in order.
  const earlier = <String, String>{
    'brandName': 'THIRTY',
    'youAboutSectionTitle': 'About',
    'youAboutVersion': 'Version {version}',
    'youPageTitle': 'You',
    'youPageSubtitle': 'Your space in THIRTY.',
    'youPersonalSectionTitle': 'Personal',
    'youPreferencesSectionTitle': 'Preferences',
    'youDataPrivacySectionTitle': 'Data & privacy',
  };

  /// The composed spoken labels of the two rows (`'$title, $detail'`).
  const memoryLabel =
      'What THIRTY remembers, What you’ve told it, need by need';
  const historyLabel = 'Your Circles, Every Circle, as it happened';

  String valueOf(AppLocalizations l, String key) => switch (key) {
    'youPersonalMemoryTitle' => l.youPersonalMemoryTitle,
    'youPersonalMemoryDetail' => l.youPersonalMemoryDetail,
    'youPersonalHistoryTitle' => l.youPersonalHistoryTitle,
    'youPersonalHistoryDetail' => l.youPersonalHistoryDetail,
    _ => throw ArgumentError(key),
  };

  group('the English catalogue', () {
    test('holds the four words with their exact English values', () {
      final c = arb();
      for (final MapEntry(:key, :value) in batch3.entries) {
        expect(c[key], value, reason: key);
      }
    });

    test('keeps the typographic apostrophe in “you’ve”', () {
      final detail = arb()['youPersonalMemoryDetail']! as String;
      expect(detail.codeUnits, contains(0x2019));
      expect(detail, isNot(contains("'")));
      expect(
        File(arbPath).readAsStringSync(),
        contains(
          '"youPersonalMemoryDetail": "What you’ve told it, '
          'need by need"',
        ),
      );
    });

    test('starts with exactly twelve messages: Batch 1 and 2 unchanged and '
        'first, then the four in row order; only Batch 4 follows', () {
      final c = arb();
      final keys = [
        for (final k in c.keys)
          if (!k.startsWith('@')) k,
      ];
      // The accepted twelve, exactly and first; only Batch 4's four
      // authorized keys may follow (you_appearance_extraction_test.dart).
      expect(keys.take(12).toList(), [...earlier.keys, ...batch3.keys]);
      expect(keys.take(12).toList(), hasLength(12));
      expect(keys.skip(12).toList(), [
        'youAppearanceTitle',
        'themeModeSystem',
        'themeModeLight',
        'themeModeDark',
      ]);
      expect(keys, hasLength(16));
      for (final MapEntry(:key, :value) in earlier.entries) {
        expect(c[key], value, reason: key);
      }
      expect(c['@@locale'], 'en');
    });

    String description(String key) =>
        ((arb()['@$key']! as Map<String, Object?>)['description']! as String);

    test('describes each key: where it sits, what it opens, and how a '
        'screen reader reads it', () {
      for (final key in batch3.keys) {
        expect(
          description(key).length,
          greaterThan(150),
          reason: '$key needs a description a translator can act on',
        );
        expect(
          description(key),
          startsWith('You tab, Personal section: '),
          reason: key,
        );
        expect(
          description(key),
          contains('one label'),
          reason: '$key: read as part of the row’s single spoken label',
        );
      }
      // The titles: the row only, not the same words elsewhere.
      expect(
        description('youPersonalMemoryTitle'),
        contains('What THIRTY remembers page'),
      );
      expect(
        description('youPersonalMemoryTitle'),
        contains('only the row on You'),
      );
      expect(
        description('youPersonalMemoryTitle'),
        contains('THIRTY is the product name (see brandName)'),
      );
      expect(
        description('youPersonalHistoryTitle'),
        contains('Circle history'),
      );
      expect(
        description('youPersonalHistoryTitle'),
        contains('not the Yours row'),
      );
      expect(
        description('youPersonalHistoryTitle'),
        contains('only the row on You'),
      );
      // The supporting lines: part of the row's label, not a hint.
      for (final (detail, title) in [
        ('youPersonalMemoryDetail', 'youPersonalMemoryTitle'),
        ('youPersonalHistoryDetail', 'youPersonalHistoryTitle'),
      ]) {
        expect(description(detail), contains('under $title'));
        expect(
          description(detail),
          contains('not a separate instruction or hint'),
          reason: detail,
        );
        expect(description(title), contains('($detail)'), reason: title);
      }
      expect(
        description('youPersonalMemoryDetail'),
        contains('typographic apostrophe'),
      );
    });

    test('declares no placeholder, and no value uses ICU syntax', () {
      final c = arb();
      for (final MapEntry(:key, :value) in batch3.entries) {
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
      for (final MapEntry(:key, :value) in batch3.entries) {
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
      for (final MapEntry(:key, :value) in batch3.entries) {
        expect(generated, contains('String get $key;'), reason: key);
        expect(english, contains("String get $key => '$value';"), reason: key);
      }
      expect(AppLocalizations.supportedLocales, const [Locale('en')]);
      expect(
        [
          for (final f in Directory('lib/l10n/arb').listSync())
            f.uri.pathSegments.last,
        ],
        ['app_en.arb'],
      );
      expect(
        [
          for (final f in Directory('lib/l10n/gen').listSync())
            f.uri.pathSegments.last,
        ]..sort(),
        ['app_localizations.dart', 'app_localizations_en.dart'],
      );
    });

    test('every device language gets the same English words (G-5C)', () {
      for (final locale in _deviceLocales) {
        final l = thirtyLocalizationsFor(locale);
        expect(l, isA<AppLocalizationsEn>(), reason: '$locale');
        for (final MapEntry(:key, :value) in batch3.entries) {
          expect(valueOf(l, key), value, reason: '$locale $key');
        }
      }
    });
  });

  group('the owning source', () {
    final source = File(owner).readAsStringSync();

    /// The source without its comments: doc comments quote the words to
    /// describe the card, and are not copy.
    final code = [
      for (final line in source.split('\n'))
        if (!line.trimLeft().startsWith('//')) line,
    ].join('\n');

    test('no longer holds the four English literals or their constants', () {
      expect(code, contains('class YouPersonalCard'));
      for (final value in batch3.values) {
        expect(code, isNot(contains(value)), reason: value);
      }
      for (final name in [
        'memoryTitle',
        'memoryDetail',
        'historyTitle',
        'historyDetail',
      ]) {
        expect(code, isNot(contains('static const $name')), reason: name);
        expect(code, isNot(contains(' $name')), reason: name);
      }
    });

    test('reads each word from the catalogue of the widget’s context, '
        'with no English-pinned lookup', () {
      for (final key in batch3.keys) {
        expect(
          RegExp('\\bl10n\\.$key\\b').allMatches(code),
          hasLength(1),
          reason: key,
        );
      }
      expect(code, contains('context.l10n'));
      expect(code, isNot(contains('lookupAppLocalizations')));
      expect(code, isNot(contains('AppLocalizationsEn')));
      expect(code, isNot(contains("Locale('en')")));
      // Out of scope, unchanged: the name row and Yours.
      expect(code, contains("static const rowTitle = 'Your name';"));
      expect(code, contains("static const addPrompt = 'Add your name';"));
      expect(code, contains('static const yoursTitle = YoursPage.title;'));
    });
  });

  group('the rendered rows', () {
    testWidgets('the production UI obtains all four words from the '
        'catalogue: a marked catalogue changes exactly those four, and the '
        'two composed spoken labels with them', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpCard(
        tester,
        delegates: const [
          _MarkedDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      );
      for (final MapEntry(:key, :value) in batch3.entries) {
        expect(find.text('[fixture] $key'), findsOneWidget, reason: key);
        expect(find.text(value), findsNothing, reason: value);
      }
      expect(
        tester.getSemantics(find.byKey(const ValueKey('you.memory'))),
        matchesSemantics(
          label:
              '[fixture] youPersonalMemoryTitle, '
              '[fixture] youPersonalMemoryDetail',
          isButton: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.byKey(const ValueKey('you.history'))),
        matchesSemantics(
          label:
              '[fixture] youPersonalHistoryTitle, '
              '[fixture] youPersonalHistoryDetail',
          isButton: true,
          hasTapAction: true,
        ),
      );
      // The other Personal rows are untouched by the catalogue.
      expect(find.text('Your name'), findsOneWidget);
      expect(find.text('Add your name'), findsOneWidget);
      expect(find.text(YoursPage.title), findsOneWidget);
      expect(find.text('Circles you keep appear here'), findsOneWidget);
      semantics.dispose();
    });

    for (final (themeName, theme) in [
      ('light', AppTheme.light),
      ('dark', AppTheme.dark),
    ]) {
      for (final scale in const [1.0, 2.0]) {
        testWidgets('$themeName, ${scale}x: the same words, order, spoken '
            'labels and button semantics', (tester) async {
          final semantics = tester.ensureSemantics();
          await _pumpCard(
            tester,
            delegates: thirtyLocalizationsDelegates,
            theme: theme,
            textScale: scale,
          );
          expect(tester.takeException(), isNull);
          for (final value in batch3.values) {
            expect(find.text(value), findsOneWidget, reason: value);
          }
          double top(Finder f) => tester.getTopLeft(f).dy;
          final rows = [
            find.byKey(const ValueKey('you.name')),
            find.byKey(const ValueKey('you.memory')),
            find.byKey(const ValueKey('you.yours')),
            find.byKey(const ValueKey('you.history')),
          ];
          for (var i = 1; i < rows.length; i++) {
            expect(top(rows[i]), greaterThan(top(rows[i - 1])), reason: '$i');
          }
          // Title above its line, both inside their own row.
          for (final (row, title, detail) in [
            (
              'you.memory',
              batch3['youPersonalMemoryTitle']!,
              batch3['youPersonalMemoryDetail']!,
            ),
            (
              'you.history',
              batch3['youPersonalHistoryTitle']!,
              batch3['youPersonalHistoryDetail']!,
            ),
          ]) {
            final inRow = find.byKey(ValueKey(row));
            expect(
              find.descendant(of: inRow, matching: find.text(title)),
              findsOneWidget,
            );
            expect(
              find.descendant(of: inRow, matching: find.text(detail)),
              findsOneWidget,
            );
            expect(top(find.text(detail)), greaterThan(top(find.text(title))));
            expect(tester.getSize(inRow).height, greaterThanOrEqualTo(48));
          }
          expect(
            tester.getSemantics(find.byKey(const ValueKey('you.memory'))),
            matchesSemantics(
              label: memoryLabel,
              isButton: true,
              hasTapAction: true,
            ),
          );
          expect(
            tester.getSemantics(find.byKey(const ValueKey('you.history'))),
            matchesSemantics(
              label: historyLabel,
              isButton: true,
              hasTapAction: true,
            ),
          );
          // The visible words sit under ExcludeSemantics: no node of their
          // own, only the row's composed label.
          for (final value in batch3.values) {
            expect(find.semantics.byLabel(value), findsNothing, reason: value);
          }
          semantics.dispose();
        });
      }
    }

    for (final locale in _deviceLocales) {
      testWidgets('device language $locale: the same English rows', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await _pumpCard(
          tester,
          delegates: thirtyLocalizationsDelegates,
          deviceLocale: locale,
        );
        expect(
          AppLocalizations.of(tester.element(find.byType(YouPersonalCard))),
          isA<AppLocalizationsEn>(),
        );
        for (final value in batch3.values) {
          expect(find.text(value), findsOneWidget, reason: value);
        }
        expect(
          tester.getSemantics(find.byKey(const ValueKey('you.memory'))).label,
          memoryLabel,
        );
        expect(
          tester.getSemantics(find.byKey(const ValueKey('you.history'))).label,
          historyLabel,
        );
        semantics.dispose();
      });
    }

    for (final (row, title, route) in [
      ('you.memory', 'What THIRTY remembers', '/memory'),
      ('you.history', 'Your Circles', '/history'),
    ]) {
      testWidgets('tapping $row opens $route', (tester) async {
        await _pumpCard(tester, delegates: thirtyLocalizationsDelegates);
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
        expect(find.text('[route] $route'), findsOneWidget);
      });

      testWidgets('the screen-reader tap on $row opens $route', (tester) async {
        final semantics = tester.ensureSemantics();
        await _pumpCard(tester, delegates: thirtyLocalizationsDelegates);
        final node = tester.getSemantics(find.byKey(ValueKey(row)));
        node.owner!.performAction(node.id, SemanticsAction.tap);
        await tester.pumpAndSettle();
        expect(find.text('[route] $route'), findsOneWidget);
        semantics.dispose();
      });
    }
  });
}

const _deviceLocales = [
  Locale('en', 'US'),
  Locale('fr', 'FR'),
  Locale('nl', 'NL'),
  Locale('es', 'ES'),
  Locale('de', 'DE'),
  Locale('it', 'IT'),
  Locale('ja', 'JP'),
];

/// THIRTY's English catalogue with the four Batch 3 words replaced by
/// `[fixture] <key>` markers — not product copy.
class _Marked extends AppLocalizationsEn {
  @override
  String get youPersonalMemoryTitle => '[fixture] youPersonalMemoryTitle';
  @override
  String get youPersonalMemoryDetail => '[fixture] youPersonalMemoryDetail';
  @override
  String get youPersonalHistoryTitle => '[fixture] youPersonalHistoryTitle';
  @override
  String get youPersonalHistoryDetail => '[fixture] youPersonalHistoryDetail';
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

/// The Personal card as You hosts it (English-only resolution,
/// `thirty_app.dart`), with its real destinations stubbed by route
/// markers.
Future<void> _pumpCard(
  WidgetTester tester, {
  required List<LocalizationsDelegate<Object?>> delegates,
  ThemeData? theme,
  double textScale = 1.0,
  Locale deviceLocale = const Locale('en', 'US'),
}) async {
  tester.view.physicalSize = const Size(412, 2400);
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.localesTestValue = [deviceLocale];
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  Widget marker(String route) => Scaffold(body: Text('[route] $route'));
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(
          body: SingleChildScrollView(child: YouPersonalCard()),
        ),
      ),
      GoRoute(path: '/memory', builder: (_, _) => marker('/memory')),
      GoRoute(path: '/history', builder: (_, _) => marker('/history')),
      GoRoute(
        path: YoursPage.location,
        builder: (_, _) => marker(YoursPage.location),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp.router(
        theme: theme ?? AppTheme.light,
        localizationsDelegates: delegates,
        supportedLocales: thirtyReleaseLocales,
        localeListResolutionCallback: thirtyLocaleListResolution,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
