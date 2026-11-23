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
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/features/personal_circle/presentation/yours_page.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';
import 'package:thirty/features/settings/presentation/widgets/first_name_editor.dart';
import 'package:thirty/features/settings/presentation/widgets/you_group_card.dart';
import 'package:thirty/features/settings/presentation/widgets/you_personal_card.dart';
import 'package:thirty/l10n/gen/app_localizations.dart';
import 'package:thirty/l10n/gen/app_localizations_en.dart';

/// G-02 / L-CNT-EN / Batch 5 (You → Personal: the first-name row): the
/// row's title and its add-name prompt come from THIRTY's English
/// catalogue, say exactly what they said before, and keep the row's one
/// button, its single composed spoken label (`'$rowTitle, $detail'`), its
/// saved-name fallback and the first-name editor it opens. The person's
/// saved first name is user data: it is shown as stored and never comes
/// from the catalogue. The first-name editor keeps its own, separate copy
/// (since Batch 6, its own keys: `firstNameEditorTitle` and
/// `firstNameEditorSupporting`, never the row's).
/// The whole page stays pinned against the baseline by the frozen
/// `you_about_en_golden_test.dart` (whole-page semantics tree).
void main() {
  const arbPath = 'lib/l10n/arb/app_en.arb';
  const owner =
      'lib/features/settings/presentation/widgets/you_personal_card.dart';
  const editorOwner =
      'lib/features/settings/presentation/widgets/first_name_editor.dart';
  const questionOwner =
      'lib/features/settings/presentation/first_name_question_page.dart';
  Map<String, Object?> arb() =>
      jsonDecode(File(arbPath).readAsStringSync()) as Map<String, Object?>;

  /// The two authorized keys, in order, with their baseline English.
  const batch5 = <String, String>{
    'youPersonalNameTitle': 'Your name',
    'youPersonalNameAddPrompt': 'Add your name',
  };
  const title = 'Your name';
  const prompt = 'Add your name';

  /// The accepted Batch 1–4 catalogue, in order, with its values.
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
    'youAppearanceTitle': 'Appearance',
    'themeModeSystem': 'System',
    'themeModeLight': 'Light',
    'themeModeDark': 'Dark',
  };

  /// The other Personal rows' composed spoken labels, unchanged.
  const memoryLabel =
      'What THIRTY remembers, What you’ve told it, need by need';
  const historyLabel = 'Your Circles, Every Circle, as it happened';
  const yoursLabel = '${YoursPage.title}, Circles you keep appear here';

  String valueOf(AppLocalizations l, String key) => switch (key) {
    'youPersonalNameTitle' => l.youPersonalNameTitle,
    'youPersonalNameAddPrompt' => l.youPersonalNameAddPrompt,
    _ => throw ArgumentError(key),
  };

  const nameRow = ValueKey('you.name');
  Finder inRow(Finder f) =>
      find.descendant(of: find.byKey(nameRow), matching: f);

  group('the English catalogue', () {
    test('holds the two words with their exact English values', () {
      final c = arb();
      for (final MapEntry(:key, :value) in batch5.entries) {
        expect(c[key], value, reason: key);
      }
    });

    test('starts with exactly eighteen messages: the accepted sixteen '
        'unchanged and first, then the two in row order; only Batch 6 '
        'follows', () {
      final c = arb();
      final keys = [
        for (final k in c.keys)
          if (!k.startsWith('@')) k,
      ];
      expect(keys.take(16).toList(), accepted.keys.toList());
      expect(keys.skip(16).take(2).toList(), batch5.keys.toList());
      // Only Batch 6's two authorized keys, the first-name editor's own,
      // follow (you_first_name_editor_extraction_test.dart).
      expect(keys.skip(18).toList(), [
        'firstNameEditorTitle',
        'firstNameEditorSupporting',
      ]);
      expect(keys, hasLength(20));
      for (final MapEntry(:key, :value) in accepted.entries) {
        expect(c[key], value, reason: key);
      }
      expect(c['@@locale'], 'en');
    });

    String description(String key) =>
        ((arb()['@$key']! as Map<String, Object?>)['description']! as String);

    test('describes each key: where it sits, what it shows, how a screen '
        'reader reads it, and that neither is the person’s name', () {
      for (final key in batch5.keys) {
        expect(
          description(key).length,
          greaterThan(200),
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
        expect(description(key), contains('first name'), reason: key);
      }
      final t = description('youPersonalNameTitle');
      expect(t, contains('first-name row'));
      expect(t, contains('youPersonalNameAddPrompt'));
      expect(t, contains('saved first name'));
      expect(t, contains('first-name editor'));
      expect(t, contains('only the row on You'));
      expect(t, contains('never the name itself'));
      final p = description('youPersonalNameAddPrompt');
      expect(p, contains('under youPersonalNameTitle'));
      expect(p, contains('no first name has been saved'));
      expect(p, contains('replaced by'));
      expect(p, contains("not the person's stored first name"));
      expect(p, contains('never saved'));
    });

    test('declares no placeholder, and no value uses ICU syntax or an '
        'apostrophe', () {
      final c = arb();
      for (final MapEntry(:key, :value) in batch5.entries) {
        final meta = c['@$key']! as Map<String, Object?>;
        expect(meta.keys, ['description'], reason: key);
        expect(value, isNot(matches(RegExp(r"[{}'’]"))), reason: key);
      }
    });

    test('is still the only catalogue: no other language file exists', () {
      expect(
        [
          for (final f in Directory('lib/l10n/arb').listSync())
            f.uri.pathSegments.last,
        ],
        ['app_en.arb'],
      );
    });
  });

  group('the generated English catalogue', () {
    final en = lookupAppLocalizations(const Locale('en'));

    test('gives the baseline words, the same as the ARB', () {
      expect(en, isA<AppLocalizationsEn>());
      final c = arb();
      for (final MapEntry(:key, :value) in batch5.entries) {
        expect(valueOf(en, key), value, reason: key);
        expect(valueOf(en, key), c[key], reason: '$key matches the ARB');
      }
    });

    test('declares plain String getters, and still supports English only', () {
      final generated = File(
        'lib/l10n/gen/app_localizations.dart',
      ).readAsStringSync();
      final english = File(
        'lib/l10n/gen/app_localizations_en.dart',
      ).readAsStringSync();
      for (final MapEntry(:key, :value) in batch5.entries) {
        expect(generated, contains('String get $key;'), reason: key);
        expect(english, contains("String get $key => '$value';"), reason: key);
      }
      expect(AppLocalizations.supportedLocales, const [Locale('en')]);
      expect(thirtyReleaseLocales, const [Locale('en')]);
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
        for (final MapEntry(:key, :value) in batch5.entries) {
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

    test('no longer holds the two English literals or their constants '
        '(comments may still quote them)', () {
      expect(code, contains('class YouPersonalCard'));
      // The comment filter is what separates the two: the doc comment
      // still names the row, the executable source does not.
      expect(source, contains('"Add your name"'));
      for (final value in batch5.values) {
        expect(code, isNot(contains("'$value'")), reason: value);
        expect(code, isNot(contains('"$value"')), reason: value);
      }
      expect(code, isNot(contains('static const rowTitle')));
      expect(code, isNot(contains('static const addPrompt')));
      expect(code, isNot(contains('YouPersonalCard.rowTitle')));
      expect(code, isNot(contains('YouPersonalCard.addPrompt')));
      // No English fallback constant of any kind: the only static constant
      // left is the Yours title, which is not in this batch.
      expect(RegExp(r'static const \w+').allMatches(code).map((m) => m[0]), [
        'static const yoursTitle',
      ]);
    });

    test('reads both words from the catalogue of the widget’s context, '
        'with no English-pinned lookup', () {
      expect(
        RegExp(r'final l10n = context\.l10n;').allMatches(code),
        hasLength(1),
      );
      for (final key in batch5.keys) {
        expect(
          RegExp('\\bl10n\\.$key\\b').allMatches(code),
          hasLength(1),
          reason: key,
        );
      }
      expect(code, contains('final rowTitle = l10n.youPersonalNameTitle;'));
      expect(
        code,
        contains('final addPrompt = l10n.youPersonalNameAddPrompt;'),
      );
      expect(code, isNot(contains('lookupAppLocalizations')));
      expect(code, isNot(contains('AppLocalizationsEn')));
      expect(code, isNot(contains("Locale('en')")));
      expect(code, isNot(contains('thirtyLocalizationsFor')));
    });

    test('keeps the saved-name fallback, the composed label, the provider, '
        'the editor and the other Personal rows', () {
      expect(code, contains('final name = ref.watch(firstNameProvider);'));
      expect(code, contains('final detail = name ?? addPrompt;'));
      expect(code, contains("label: '\$rowTitle, \$detail',"));
      expect(code, contains('void open() => showFirstNameEditor(context);'));
      expect(code, contains("key: const ValueKey('you.name'),"));
      expect(code, contains('ExcludeSemantics('));
      expect(code, contains('YouRowTitle(rowTitle)'));
      expect(code, contains('YouRowDetail(name)'));
      expect(code, contains('Icons.edit_outlined'));
      expect(code, contains('minHeight: 48'));
      for (final key in [
        'youPersonalMemoryTitle',
        'youPersonalMemoryDetail',
        'youPersonalHistoryTitle',
        'youPersonalHistoryDetail',
      ]) {
        expect(
          RegExp('\\bl10n\\.$key\\b').allMatches(code),
          hasLength(1),
          reason: key,
        );
      }
      expect(code, contains('static const yoursTitle = YoursPage.title;'));
      expect(code, contains('title: yoursTitle,'));
      expect(code, contains('detail: yoursDetail(kept),'));
      expect(code, contains("0 => 'Circles you keep appear here',"));
      expect(code, contains("1 => '1 Circle you kept',"));
      expect(code, contains(r"_ => '$kept Circles you kept',"));
      expect(code, contains("label: '\$title, \$detail',"));
    });

    test('the first-name editor reads its own two keys (Batch 6), never the '
        'row’s; it keeps the rest of its copy, its storage and its '
        'validation', () {
      final editor = File(editorOwner).readAsStringSync();
      // The old Dart-owned title and supporting line are gone.
      expect(editor, isNot(contains('static const title')));
      expect(editor, isNot(contains('static const supporting')));
      expect(editor, isNot(contains('FirstNameEditor.title')));
      expect(editor, isNot(contains('FirstNameEditor.supporting')));
      expect(editor, isNot(contains("'Your name'")));
      expect(
        editor,
        isNot(
          contains("'Used only to make THIRTY feel a little more personal.'"),
        ),
      );
      // Its own keys, read once each from the widget's context.
      expect(
        RegExp(r'final l10n = context\.l10n;').allMatches(editor),
        hasLength(1),
      );
      expect(editor, contains('title: Text(l10n.firstNameEditorTitle),'));
      expect(
        RegExp(r'\bl10n\.firstNameEditorSupporting,').allMatches(editor),
        hasLength(1),
      );
      // Never the row's keys, even though the English title is the same.
      expect(editor, isNot(contains('youPersonalName')));
      // The rest of the editor is unchanged and out of this batch.
      expect(editor, contains("static const fieldLabel = 'First name';"));
      expect(
        editor,
        contains(
          "static const tooLongMessage = "
          "'Use \$maxFirstNameLength characters or fewer.';",
        ),
      );
      expect(editor, contains('labelText: FirstNameEditor.fieldLabel,'));
      expect(
        editor,
        contains(
          'errorText: _tooLong ? FirstNameEditor.tooLongMessage : null,',
        ),
      );
      expect(editor, contains("child: const Text('Remove name'),"));
      expect(editor, contains("child: const Text('Cancel'),"));
      expect(editor, contains("child: const Text('Save'),"));
      expect(editor, contains("barrierLabel: 'Cancel',"));
      expect(editor, contains('builder: (_) => const FirstNameEditor(),'));
      // Storage and validation contracts.
      expect(
        editor,
        contains('late final String? _existing = ref.read(firstNameProvider);'),
      );
      expect(
        editor,
        contains('bool get _tooLong => !firstNameFits(_controller.text);'),
      );
      expect(
        editor,
        contains(
          'bool get _canSave => '
          'trimmedFirstName(_controller.text) != null && !_tooLong;',
        ),
      );
      expect(
        editor,
        contains(
          'await ref.read(firstNameProvider.notifier)'
          '.setFirstName(_controller.text);',
        ),
      );
      expect(
        editor,
        contains('await ref.read(firstNameProvider.notifier).clear();'),
      );
    });

    test('the row keeps its own two keys, and the first-use question keeps '
        'its own copy: neither the row’s keys nor the editor’s', () {
      for (final key in batch5.keys) {
        expect(
          RegExp('\\bl10n\\.$key\\b').allMatches(code),
          hasLength(1),
          reason: key,
        );
      }
      expect(code, isNot(contains('firstNameEditor')));
      final question = File(questionOwner).readAsStringSync();
      expect(question, isNot(contains('youPersonalName')));
      expect(question, isNot(contains('firstNameEditorTitle')));
      expect(question, isNot(contains('firstNameEditorSupporting')));
      expect(question, isNot(contains('l10n')));
      expect(question, contains('labelText: FirstNameEditor.fieldLabel,'));
    });
  });

  group('the rendered name row', () {
    for (final (themeName, theme) in [
      ('light', AppTheme.light),
      ('dark', AppTheme.dark),
    ]) {
      for (final scale in const [1.0, 2.0]) {
        testWidgets('$themeName, ${scale}x, no saved name: "$title" over '
            '"$prompt", one button read as "$title, $prompt"', (tester) async {
          final semantics = tester.ensureSemantics();
          await _pumpCard(tester, theme: theme, textScale: scale);
          expect(tester.takeException(), isNull);

          expect(find.text(title), findsOneWidget);
          expect(find.text(prompt), findsOneWidget);
          expect(inRow(find.text(title)), findsOneWidget);
          expect(inRow(find.text(prompt)), findsOneWidget);
          double top(Finder f) => tester.getTopLeft(f).dy;
          expect(top(find.text(prompt)), greaterThan(top(find.text(title))));
          expect(
            find.ancestor(
              of: find.text(title),
              matching: find.byType(YouRowTitle),
            ),
            findsOneWidget,
          );
          // The prompt keeps its accent colour and small body style.
          final context = tester.element(find.byType(YouPersonalCard));
          final colors = Theme.of(context).extension<AppColors>()!;
          final promptText = tester.widget<Text>(find.text(prompt));
          expect(promptText.style?.color, colors.primary);
          expect(
            promptText.style?.fontSize,
            Theme.of(context).textTheme.bodySmall?.fontSize,
          );
          expect(inRow(find.byIcon(Icons.edit_outlined)), findsOneWidget);
          expect(
            tester.getSize(find.byKey(nameRow)).height,
            greaterThanOrEqualTo(48),
          );

          final node = tester.getSemantics(find.byKey(nameRow));
          expect(
            node,
            matchesSemantics(
              label: '$title, $prompt',
              isButton: true,
              hasTapAction: true,
            ),
          );
          // One label, one comma between title and detail, no children: the
          // visible words sit under ExcludeSemantics.
          expect(', '.allMatches(node.label), hasLength(1));
          expect(node.childrenCount, 0);
          expect(find.semantics.byLabel(prompt), findsNothing);
          expect(find.semantics.byLabel(title), findsNothing);
          expect(find.bySemanticsLabel(RegExp('your name')), findsOneWidget);

          // Row order is unchanged: name, memory, Yours, history.
          final rows = [
            find.byKey(nameRow),
            find.byKey(const ValueKey('you.memory')),
            find.byKey(const ValueKey('you.yours')),
            find.byKey(const ValueKey('you.history')),
          ];
          for (var i = 1; i < rows.length; i++) {
            expect(top(rows[i]), greaterThan(top(rows[i - 1])), reason: '$i');
          }
          semantics.dispose();
        });
      }
    }

    testWidgets('a saved first name replaces the prompt: "$title" over the '
        'name, read as "$title, Alex"; the stored value is untouched', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final (container, prefs) = await _pumpCard(
        tester,
        prefsValues: {firstNameKey: 'Alex'},
      );
      expect(inRow(find.text(title)), findsOneWidget);
      expect(inRow(find.text('Alex')), findsOneWidget);
      expect(find.text(prompt), findsNothing);
      expect(
        find.ancestor(
          of: find.text('Alex'),
          matching: find.byType(YouRowDetail),
        ),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.byKey(nameRow)),
        matchesSemantics(
          label: '$title, Alex',
          isButton: true,
          hasTapAction: true,
        ),
      );
      expect(prefs.getString(firstNameKey), 'Alex');
      expect(container.read(firstNameProvider), 'Alex');
      semantics.dispose();
    });

    testWidgets('tapping the row opens the first-name editor with its own '
        'unchanged copy', (tester) async {
      await _pumpCard(tester);
      await tester.tap(find.byKey(nameRow));
      await tester.pumpAndSettle();
      final dialog = find.byType(FirstNameEditor);
      expect(dialog, findsOneWidget);
      Finder inDialog(String text) =>
          find.descendant(of: dialog, matching: find.text(text));
      // The baseline English, written out here, independent of production.
      expect(inDialog('Your name'), findsOneWidget);
      expect(
        inDialog('Used only to make THIRTY feel a little more personal.'),
        findsOneWidget,
      );
      expect(inDialog('First name'), findsOneWidget);
      expect(inDialog('Save'), findsOneWidget);
      expect(inDialog('Cancel'), findsOneWidget);
      expect(inDialog('Remove name'), findsNothing);
    });

    testWidgets('the screen-reader tap opens the editor, and a saved name '
        'comes back as stored', (tester) async {
      final semantics = tester.ensureSemantics();
      final (container, prefs) = await _pumpCard(tester);
      final node = tester.getSemantics(find.byKey(nameRow));
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect(find.byType(FirstNameEditor), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Sam');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.byType(FirstNameEditor), findsNothing);
      expect(prefs.getString(firstNameKey), 'Sam');
      expect(container.read(firstNameProvider), 'Sam');
      expect(inRow(find.text('Sam')), findsOneWidget);
      expect(find.text(prompt), findsNothing);
      expect(tester.getSemantics(find.byKey(nameRow)).label, '$title, Sam');
      semantics.dispose();
    });

    for (final locale in _deviceLocales) {
      testWidgets('device language $locale: the same English row', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await _pumpCard(tester, deviceLocale: locale);
        expect(
          AppLocalizations.of(tester.element(find.byType(YouPersonalCard))),
          isA<AppLocalizationsEn>(),
        );
        expect(inRow(find.text(title)), findsOneWidget);
        expect(inRow(find.text(prompt)), findsOneWidget);
        expect(
          tester.getSemantics(find.byKey(nameRow)).label,
          '$title, $prompt',
        );
        semantics.dispose();
      });
    }
  });

  group('a marked catalogue', () {
    testWidgets('no saved name: the production row shows and speaks the two '
        'marked words; the other rows and the editor are untouched', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpCard(tester, delegates: _markedDelegates);
      for (final key in batch5.keys) {
        expect(inRow(find.text('[fixture] $key')), findsOneWidget, reason: key);
      }
      expect(find.text(title), findsNothing);
      expect(find.text(prompt), findsNothing);
      expect(
        tester.getSemantics(find.byKey(nameRow)),
        matchesSemantics(
          label:
              '[fixture] youPersonalNameTitle, '
              '[fixture] youPersonalNameAddPrompt',
          isButton: true,
          hasTapAction: true,
        ),
      );
      // The other Personal rows do not read the name row's keys.
      for (final (row, label) in [
        ('you.memory', memoryLabel),
        ('you.yours', yoursLabel),
        ('you.history', historyLabel),
      ]) {
        final rowLabel = tester.getSemantics(find.byKey(ValueKey(row))).label;
        expect(rowLabel, label, reason: row);
        expect(rowLabel, isNot(contains('[fixture]')), reason: row);
      }
      // The editor keeps its own title: it is not the row's key.
      await tester.tap(find.byKey(nameRow));
      await tester.pumpAndSettle();
      final dialog = find.byType(FirstNameEditor);
      expect(
        find.descendant(of: dialog, matching: find.text('Your name')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.textContaining('[fixture]')),
        findsNothing,
      );
      semantics.dispose();
    });

    testWidgets('a saved name: only the title is the catalogue’s; the name '
        'is the person’s own, as stored', (tester) async {
      final semantics = tester.ensureSemantics();
      final (_, prefs) = await _pumpCard(
        tester,
        delegates: _markedDelegates,
        prefsValues: {firstNameKey: 'Alex'},
      );
      expect(
        inRow(find.text('[fixture] youPersonalNameTitle')),
        findsOneWidget,
      );
      expect(inRow(find.text('Alex')), findsOneWidget);
      expect(find.text('[fixture] youPersonalNameAddPrompt'), findsNothing);
      expect(
        tester.getSemantics(find.byKey(nameRow)).label,
        '[fixture] youPersonalNameTitle, Alex',
      );
      expect(prefs.getString(firstNameKey), 'Alex');
      semantics.dispose();
    });
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

/// THIRTY's English catalogue with the two Batch 5 words replaced by
/// `[fixture] <key>` markers — not product copy.
class _Marked extends AppLocalizationsEn {
  @override
  String get youPersonalNameTitle => '[fixture] youPersonalNameTitle';
  @override
  String get youPersonalNameAddPrompt => '[fixture] youPersonalNameAddPrompt';
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

const _markedDelegates = <LocalizationsDelegate<Object?>>[
  _MarkedDelegate(),
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// The Personal card as You hosts it (English-only resolution,
/// `thirty_app.dart`), with its real destinations stubbed by route
/// markers. One pump per test.
Future<(ProviderContainer, SharedPreferences)> _pumpCard(
  WidgetTester tester, {
  List<LocalizationsDelegate<Object?>> delegates = thirtyLocalizationsDelegates,
  Map<String, Object> prefsValues = const {},
  ThemeData? theme,
  double textScale = 1.0,
  Locale deviceLocale = const Locale('en', 'US'),
}) async {
  tester.view.physicalSize = const Size(412, 2400);
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.localesTestValue = [deviceLocale];
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
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
    UncontrolledProviderScope(
      container: container,
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
  return (container, prefs);
}
