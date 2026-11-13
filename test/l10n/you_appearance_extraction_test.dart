import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/l10n/thirty_locales.dart';
import 'package:thirty/core/premium/entitlement_gateway.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/providers/theme_mode_provider.dart';
import 'package:thirty/core/reminder/reminder_gateway.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/features/settings/presentation/settings_page.dart';
import 'package:thirty/features/settings/presentation/widgets/theme_mode_choice.dart';
import 'package:thirty/features/settings/presentation/widgets/you_group_card.dart';
import 'package:thirty/l10n/gen/app_localizations.dart';
import 'package:thirty/l10n/gen/app_localizations_en.dart';

/// G-02 / L-CNT-EN / Batch 4 (You → Preferences: Appearance): the row title
/// and the three theme labels come from THIRTY's English catalogue, say
/// exactly what they said before, and keep their order, their responsive
/// segmented-or-stacked layout (measured on the words actually shown), the
/// literal `Theme` group label, single-choice semantics and the stored
/// theme values. The whole page stays pinned against the baseline by the
/// frozen `you_about_en_golden_test.dart`; the real-font layout checks stay
/// in `you_c1_real_font_test.dart`.
void main() {
  const arbPath = 'lib/l10n/arb/app_en.arb';
  const cardOwner =
      'lib/features/settings/presentation/widgets/you_preferences_card.dart';
  const choiceOwner =
      'lib/features/settings/presentation/widgets/theme_mode_choice.dart';
  Map<String, Object?> arb() =>
      jsonDecode(File(arbPath).readAsStringSync()) as Map<String, Object?>;

  /// The four authorized keys, in order, with their baseline English.
  const batch4 = <String, String>{
    'youAppearanceTitle': 'Appearance',
    'themeModeSystem': 'System',
    'themeModeLight': 'Light',
    'themeModeDark': 'Dark',
  };
  const labels = ['System', 'Light', 'Dark'];

  /// The accepted Batch 1–3 catalogue, in order.
  const accepted = <String, String>{
    'brandName': 'THIRTY',
    'youAboutSectionTitle': 'About',
    'youAboutVersion': 'Version {version}',
    'youPageTitle': 'You',
    'youPageSubtitle': 'Your space in THIRTY.',
    'youPersonalSectionTitle': 'Personal',
    'youPreferencesSectionTitle': 'Preferences',
    'youDataPrivacySectionTitle': 'Data & privacy',
    'youPersonalMemoryTitle': 'What THIRTY remembers',
    'youPersonalMemoryDetail': 'What you’ve told it, need by need',
    'youPersonalHistoryTitle': 'Your Circles',
    'youPersonalHistoryDetail': 'Every Circle, as it happened',
  };

  String valueOf(AppLocalizations l, String key) => switch (key) {
    'youAppearanceTitle' => l.youAppearanceTitle,
    'themeModeSystem' => l.themeModeSystem,
    'themeModeLight' => l.themeModeLight,
    'themeModeDark' => l.themeModeDark,
    _ => throw ArgumentError(key),
  };

  setUpAll(() async {
    await _loadFont('Inter', [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
    ]);
  });

  group('the English catalogue', () {
    test('holds the four words with their exact English values', () {
      final c = arb();
      for (final MapEntry(:key, :value) in batch4.entries) {
        expect(c[key], value, reason: key);
      }
    });

    test('is exactly sixteen messages: the accepted twelve unchanged and '
        'first, then the four in order', () {
      final c = arb();
      final keys = [
        for (final k in c.keys)
          if (!k.startsWith('@')) k,
      ];
      expect(keys, [...accepted.keys, ...batch4.keys]);
      expect(keys, hasLength(16));
      for (final MapEntry(:key, :value) in accepted.entries) {
        expect(c[key], value, reason: key);
      }
      expect(c['@@locale'], 'en');
    });

    String description(String key) =>
        ((arb()['@$key']! as Map<String, Object?>)['description']! as String);

    test('describes each key: where it sits, what it chooses, and how the '
        'three labels share or stack their row', () {
      for (final key in batch4.keys) {
        expect(
          description(key).length,
          greaterThan(100),
          reason: '$key needs a description a translator can act on',
        );
        expect(description(key), startsWith('You tab, '), reason: key);
      }
      expect(
        description('youAppearanceTitle'),
        startsWith('You tab, Preferences section: '),
      );
      for (final key in [
        'themeModeSystem',
        'themeModeLight',
        'themeModeDark',
      ]) {
        expect(description('youAppearanceTitle'), contains(key));
        expect(description(key), contains('youAppearanceTitle'), reason: key);
        expect(
          description(key),
          contains('themeModeSystem, themeModeLight, themeModeDark'),
          reason: '$key: the fixed order',
        );
        expect(description(key), contains('segmented control'), reason: key);
        expect(description(key), contains('stack'), reason: key);
        expect(
          description(key),
          contains('the group announced as Theme'),
          reason: key,
        );
      }
      expect(description('themeModeSystem'), contains("device's own"));
      expect(description('themeModeLight'), contains('light colours'));
      expect(description('themeModeDark'), contains('dark colours'));
    });

    test('declares no placeholder, and no value uses ICU syntax or an '
        'apostrophe', () {
      final c = arb();
      for (final MapEntry(:key, :value) in batch4.entries) {
        final meta = c['@$key']! as Map<String, Object?>;
        expect(meta.keys, ['description'], reason: key);
        expect(value, isNot(matches(RegExp(r"[{}'’]"))), reason: key);
      }
    });
  });

  group('the generated English catalogue', () {
    final en = lookupAppLocalizations(const Locale('en'));

    test('gives the baseline words', () {
      expect(en, isA<AppLocalizationsEn>());
      for (final MapEntry(:key, :value) in batch4.entries) {
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
      for (final MapEntry(:key, :value) in batch4.entries) {
        expect(generated, contains('String get $key;'), reason: key);
        expect(english, contains("String get $key => '$value';"), reason: key);
      }
      expect(AppLocalizations.supportedLocales, const [Locale('en')]);
      expect(thirtyReleaseLocales, const [Locale('en')]);
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
        for (final MapEntry(:key, :value) in batch4.entries) {
          expect(valueOf(l, key), value, reason: '$locale $key');
        }
      }
    });
  });

  group('the owning source', () {
    /// The source without its comments: doc comments quote the words to
    /// describe the design, and are not copy.
    String code(String path) => [
      for (final line in File(path).readAsStringSync().split('\n'))
        if (!line.trimLeft().startsWith('//')) line,
    ].join('\n');

    void noPinnedLookup(String code) {
      expect(code, contains('context.l10n'));
      expect(code, isNot(contains('lookupAppLocalizations')));
      expect(code, isNot(contains('AppLocalizationsEn')));
      expect(code, isNot(contains('AppLocalizations.of')));
      expect(code, isNot(contains("Locale('en')")));
      expect(code, isNot(contains('l10n/gen/')));
    }

    test('the Preferences card reads Appearance from the catalogue and '
        'keeps its other rows as they were', () {
      final card = code(cardOwner);
      expect(card, contains('class _AppearanceRow'));
      expect(card, isNot(contains("'Appearance'")));
      expect(
        RegExp(r'\bl10n\.youAppearanceTitle\b').allMatches(card),
        hasLength(1),
      );
      expect(card, contains('YouRowTitle(context.l10n.youAppearanceTitle)'));
      noPinnedLookup(card);
      // Out of scope, unchanged: the reminder row's own words.
      expect(card, contains("'Daily reminder'"));
      expect(card, contains("'Change time'"));
    });

    test('the theme choice reads its three labels from the catalogue, '
        'measures and shows that same list, and keeps the literal Theme '
        'group label', () {
      final choice = code(choiceOwner);
      for (final label in labels) {
        expect(choice, isNot(contains("'$label'")), reason: label);
      }
      for (final key in [
        'themeModeSystem',
        'themeModeLight',
        'themeModeDark',
      ]) {
        expect(
          RegExp('\\bl10n\\.$key\\b').allMatches(choice),
          hasLength(1),
          reason: key,
        );
      }
      // The fixed order.
      final system = choice.indexOf('(ThemeMode.system, l10n.themeModeSystem)');
      final light = choice.indexOf('(ThemeMode.light, l10n.themeModeLight)');
      final dark = choice.indexOf('(ThemeMode.dark, l10n.themeModeDark)');
      expect(system, isNonNegative);
      expect(light, greaterThan(system));
      expect(dark, greaterThan(light));
      // No English-only cache: no constant list of choices any more.
      expect(choice, isNot(contains('static const _choices')));
      // Resolved once per build, and that one list is what is measured
      // and what both layouts show.
      expect('_choices(context)'.allMatches(choice), hasLength(1));
      expect(
        choice,
        contains('_segmentsFit(context, constraints.maxWidth, choices)'),
      );
      expect('in choices)'.allMatches(choice), hasLength(3));
      // The measurement itself is unchanged.
      expect(
        choice,
        contains('static const _segmentChrome = 12.0 * 2 + 18 + 8 + 2;'),
      );
      expect(choice, contains('style: Theme.of(context).textTheme.labelLarge'));
      expect(choice, contains('textDirection: Directionality.of(context)'));
      expect(choice, contains('textScaler: MediaQuery.textScalerOf(context)'));
      expect(choice, contains('maxLines: 1'));
      expect(
        choice,
        contains(
          'final fits = painter.width + _segmentChrome <= segmentWidth;',
        ),
      );
      // Accessibility, not extracted (founder exclusion).
      expect(choice, contains("label: 'Theme',"));
      expect(choice, contains('container: true'));
      expect(choice, contains('inMutuallyExclusiveGroup: true'));
      expect(choice, contains('if (selected) Icon(Icons.check'));
      noPinnedLookup(choice);
    });
  });

  group('the rendered Appearance row', () {
    Finder inRow(Finder f) => find.descendant(
      of: find.byKey(const ValueKey('you.appearance')),
      matching: f,
    );

    testWidgets('the production UI obtains all four words from the '
        'catalogue: a marked catalogue changes exactly those four, and the '
        'Theme group label stays', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpYou(
        tester,
        width: 412,
        delegates: _with(const _MarkedDelegate(_Marked.new)),
      );
      expect(tester.takeException(), isNull);
      for (final key in batch4.keys) {
        expect(inRow(find.text('[fixture] $key')), findsOneWidget, reason: key);
      }
      for (final value in batch4.values) {
        expect(inRow(find.text(value)), findsNothing, reason: value);
      }
      expect(
        inRow(find.widgetWithText(YouRowTitle, '[fixture] youAppearanceTitle')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Theme'), findsOneWidget);
      // The rest of the card is not catalogue-backed in this batch.
      expect(find.text('Daily reminder'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('the fit is measured on the catalogue’s words: longer '
        'marked labels stack where the English fits, at 600pt', (tester) async {
      // The English labels fit at 600pt (the layout matrix below).
      await _pumpYou(
        tester,
        width: 600,
        delegates: _with(const _MarkedDelegate(_Marked.new)),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(SegmentedButton<ThemeMode>), findsNothing);
      for (final key in [
        'themeModeSystem',
        'themeModeLight',
        'themeModeDark',
      ]) {
        expect(_lines(tester, '[fixture] $key'), 1, reason: key);
      }
      expect(_truncated(tester), isEmpty);
    });

    testWidgets('the fit is measured on the catalogue’s words: shorter '
        'marked labels share one row where the English stacks, at 412pt', (
      tester,
    ) async {
      // The English labels stack at 412pt (the layout matrix below).
      await _pumpYou(
        tester,
        width: 412,
        delegates: _with(const _MarkedDelegate(_Short.new)),
      );
      expect(tester.takeException(), isNull);
      final segmented = tester.widget<SegmentedButton<ThemeMode>>(
        find.byType(SegmentedButton<ThemeMode>),
      );
      expect(
        [
          for (final s in segmented.segments)
            (s.value, (s.label! as Text).data),
        ],
        [
          (ThemeMode.system, '[s]'),
          (ThemeMode.light, '[l]'),
          (ThemeMode.dark, '[d]'),
        ],
      );
      expect(_truncated(tester), isEmpty);
    });

    // The English layout, unchanged from the baseline (Phase C1): the
    // segmented control only where every label fits on one line.
    final segmentedAt = {(600.0, 1.0)};
    for (final width in const [320.0, 360.0, 412.0, 600.0]) {
      for (final scale in const [1.0, 2.0]) {
        final segmented = segmentedAt.contains((width, scale));
        testWidgets('${width.toInt()}pt, ${scale}x: '
            '${segmented ? 'segmented' : 'stacked'}, the three labels in '
            'order on one line each, nothing cut short, one selected', (
          tester,
        ) async {
          final semantics = tester.ensureSemantics();
          await _pumpYou(tester, width: width, textScale: scale);
          expect(tester.takeException(), isNull);
          expect(_truncated(tester), isEmpty);
          expect(
            find.byType(SegmentedButton<ThemeMode>),
            segmented ? findsOneWidget : findsNothing,
          );
          for (final label in labels) {
            expect(inRow(find.text(label)), findsOneWidget, reason: label);
            expect(_lines(tester, label), 1, reason: label);
          }
          final at = [for (final l in labels) tester.getTopLeft(find.text(l))];
          for (var i = 1; i < at.length; i++) {
            if (segmented) {
              expect(at[i].dx, greaterThan(at[i - 1].dx), reason: labels[i]);
            } else {
              expect(at[i].dy, greaterThan(at[i - 1].dy), reason: labels[i]);
            }
          }
          if (segmented) {
            expect(
              tester
                  .widget<SegmentedButton<ThemeMode>>(
                    find.byType(SegmentedButton<ThemeMode>),
                  )
                  .selected,
              {ThemeMode.system},
            );
          } else {
            expect(inRow(find.byIcon(Icons.check)), findsOneWidget);
            _expectCheckOn(tester, 'System');
          }
          expect(
            tester.getSemantics(find.text('System')),
            isSemantics(isSelected: true, isInMutuallyExclusiveGroup: true),
          );
          for (final label in ['Light', 'Dark']) {
            expect(
              tester.getSemantics(find.text(label)),
              isSemantics(isSelected: false, isInMutuallyExclusiveGroup: true),
              reason: label,
            );
          }
          semantics.dispose();
        });
      }
    }

    for (final (themeName, theme) in [
      ('light', AppTheme.light),
      ('dark', AppTheme.dark),
    ]) {
      for (final scale in const [1.0, 2.0]) {
        testWidgets('$themeName, ${scale}x: Appearance as the row title, '
            'directly above the choice, with the same style and gap', (
          tester,
        ) async {
          await _pumpYou(tester, width: 412, textScale: scale, theme: theme);
          expect(tester.takeException(), isNull);
          final title = inRow(find.widgetWithText(YouRowTitle, 'Appearance'));
          expect(title, findsOneWidget);
          expect(find.text('Appearance'), findsOneWidget);
          final context = tester.element(find.text('Appearance'));
          final shown = tester.widget<Text>(find.text('Appearance'));
          expect(
            shown.style,
            Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).extension<AppColors>()!.textPrimary,
            ),
          );
          final choice = find.byType(ThemeModeChoice);
          expect(
            tester.getTopLeft(choice).dy - tester.getBottomLeft(title).dy,
            moreOrLessEquals(AppSpacing.xs),
          );
          expect(
            tester.getTopLeft(find.byKey(const ValueKey('you.appearance'))).dy,
            greaterThan(
              tester.getTopLeft(find.byKey(const ValueKey('you.reminder'))).dy,
            ),
          );
        });
      }
    }

    testWidgets('the Theme group: its literal label, then System, Light and '
        'Dark in that order for a screen reader, each a button with a tap '
        'action', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpYou(tester, width: 412);
      final group = tester.getSemantics(find.bySemanticsLabel('Theme'));
      expect(group.label, 'Theme');
      final order = <String>[];
      void visit(SemanticsNode node) {
        if (node.label.isNotEmpty) order.add(node.label);
        for (final child in node.debugListChildrenInOrder(
          DebugSemanticsDumpOrder.traversalOrder,
        )) {
          visit(child);
        }
      }

      visit(group);
      expect(order, ['Theme', ...labels]);
      for (final label in labels) {
        expect(
          tester.getSemantics(find.text(label)),
          isSemantics(
            label: label,
            isButton: true,
            hasTapAction: true,
            isInMutuallyExclusiveGroup: true,
          ),
          reason: label,
        );
      }
      semantics.dispose();
    });

    testWidgets('choosing Dark sets and stores `dark`, and the check moves '
        'with the selection — never colour alone', (tester) async {
      final semantics = tester.ensureSemantics();
      final (container, prefs) = await _pumpYou(tester, width: 412);
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(prefs.getString(themeModeKey), 'dark');
      expect(themeModeKey, 'theme_mode_v1');
      expect(inRow(find.byIcon(Icons.check)), findsOneWidget);
      _expectCheckOn(tester, 'Dark');
      expect(
        tester.getSemantics(find.text('Dark')),
        isSemantics(isSelected: true),
      );
      expect(
        tester.getSemantics(find.text('System')),
        isSemantics(isSelected: false),
      );
      semantics.dispose();
    });

    testWidgets('the screen-reader tap on Light sets and stores `light`', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final (container, prefs) = await _pumpYou(tester, width: 412);
      final node = tester.getSemantics(find.text('Light'));
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(prefs.getString(themeModeKey), 'light');
      _expectCheckOn(tester, 'Light');
      semantics.dispose();
    });

    testWidgets('on the segmented control (600pt) choosing System from Dark '
        'stores `system`', (tester) async {
      final (container, prefs) = await _pumpYou(
        tester,
        width: 600,
        stored: {themeModeKey: 'dark'},
      );
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();
      expect(container.read(themeModeProvider), ThemeMode.system);
      expect(prefs.getString(themeModeKey), 'system');
    });

    for (final locale in _deviceLocales) {
      testWidgets('device language $locale: the same English row', (
        tester,
      ) async {
        await _pumpYou(tester, width: 412, deviceLocale: locale);
        expect(
          AppLocalizations.of(tester.element(find.byType(ThemeModeChoice))),
          isA<AppLocalizationsEn>(),
        );
        for (final value in batch4.values) {
          expect(inRow(find.text(value)), findsOneWidget, reason: value);
        }
        expect(find.bySemanticsLabel('Theme'), findsOneWidget);
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

/// THIRTY's English catalogue with the four Batch 4 words replaced by
/// longer `[fixture] <key>` markers — not product copy.
class _Marked extends AppLocalizationsEn {
  @override
  String get youAppearanceTitle => '[fixture] youAppearanceTitle';
  @override
  String get themeModeSystem => '[fixture] themeModeSystem';
  @override
  String get themeModeLight => '[fixture] themeModeLight';
  @override
  String get themeModeDark => '[fixture] themeModeDark';
}

/// THIRTY's English catalogue with the three theme labels replaced by
/// shorter markers than the English — not product copy.
class _Short extends AppLocalizationsEn {
  @override
  String get themeModeSystem => '[s]';
  @override
  String get themeModeLight => '[l]';
  @override
  String get themeModeDark => '[d]';
}

class _MarkedDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _MarkedDelegate(this.create);
  final AppLocalizations Function() create;
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';
  @override
  Future<AppLocalizations> load(Locale locale) async => create();
  @override
  bool shouldReload(_MarkedDelegate old) => false;
}

List<LocalizationsDelegate<Object?>> _with(_MarkedDelegate marked) => [
  marked,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

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
  Future<MonthlyOffer?> monthlyOffer() async =>
      const MonthlyOffer(localizedPrice: '€4.99');
  @override
  Future<PurchaseOutcome> purchaseMonthly() async => PurchaseOutcome.error;
  @override
  Future<RestoreOutcome> restore() async => RestoreOutcome.notFound;
  @override
  Future<String?> managementUrl() async => null;
}

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(file).readAsBytesSync())),
    );
  }
  await loader.load();
}

/// You as the app hosts it (English-only resolution, `thirty_app.dart`),
/// with the app's real fonts, at [width] and [textScale].
Future<(ProviderContainer, SharedPreferences)> _pumpYou(
  WidgetTester tester, {
  required double width,
  double textScale = 1.0,
  ThemeData? theme,
  List<LocalizationsDelegate<Object?>> delegates = thirtyLocalizationsDelegates,
  Locale deviceLocale = const Locale('en', 'US'),
  Map<String, Object> stored = const {},
}) async {
  tester.view.physicalSize = Size(width, 3000);
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.localesTestValue = [deviceLocale];
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  SharedPreferences.setMockInitialValues(stored);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      entitlementGatewayProvider.overrideWithValue(_FakeEntitlementGateway()),
      sharedPreferencesProvider.overrideWithValue(prefs),
      reminderGatewayProvider.overrideWithValue(_FakeReminderGateway()),
    ],
  );
  addTearDown(container.dispose);
  await container.read(entitlementStatusProvider.notifier).initialize();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: theme ?? AppTheme.light,
        localizationsDelegates: delegates,
        supportedLocales: thirtyReleaseLocales,
        localeListResolutionCallback: thirtyLocaleListResolution,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: const SettingsPage(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (container, prefs);
}

/// Every paragraph on You that was cut short, by text.
List<String> _truncated(WidgetTester tester) => [
  for (final element in find.byType(RichText).evaluate())
    if ((element.renderObject! as RenderParagraph).didExceedMaxLines)
      (element.renderObject! as RenderParagraph).text.toPlainText(),
];

int _lines(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  return paragraph
      .getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: text.length),
      )
      .map((box) => box.top)
      .toSet()
      .length;
}

/// In the stacked layout, the one check sits in [label]'s own row and in
/// no other option's row.
void _expectCheckOn(WidgetTester tester, String label) {
  for (final option in ['System', 'Light', 'Dark']) {
    final row = find
        .ancestor(of: find.text(option), matching: find.byType(InkWell))
        .first;
    expect(
      find.descendant(of: row, matching: find.byIcon(Icons.check)),
      option == label ? findsOneWidget : findsNothing,
      reason: '$option (selected: $label)',
    );
  }
}
