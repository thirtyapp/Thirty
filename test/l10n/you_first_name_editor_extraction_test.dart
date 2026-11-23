import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:thirty/features/settings/presentation/first_name_question_page.dart';
import 'package:thirty/features/settings/presentation/widgets/first_name_editor.dart';
import 'package:thirty/features/settings/presentation/widgets/you_personal_card.dart';
import 'package:thirty/l10n/gen/app_localizations.dart';
import 'package:thirty/l10n/gen/app_localizations_en.dart';

import '../features/b8/b8_review_pack_test.dart' show fnv64;

/// G-02 / L-CNT-EN / Batch 6 (the first-name editor's header): the dialog's
/// title and its supporting line come from THIRTY's English catalogue under
/// their own keys, `firstNameEditorTitle` and `firstNameEditorSupporting`,
/// and say exactly what they said before. The Personal name row keeps its
/// own Batch 5 key, `youPersonalNameTitle`, which has the same English
/// words but a different owner. The editor's field label, length message,
/// buttons, barrier label, storage and validation are unchanged and out of
/// this batch; so is the first-use question. The person's first name is user
/// data: it is never in the catalogue, never translated, and shown and
/// stored exactly as entered (trimmed).
void main() {
  const arbPath = 'lib/l10n/arb/app_en.arb';
  const editorOwner =
      'lib/features/settings/presentation/widgets/first_name_editor.dart';
  const rowOwner =
      'lib/features/settings/presentation/widgets/you_personal_card.dart';
  const questionOwner =
      'lib/features/settings/presentation/first_name_question_page.dart';
  Map<String, Object?> arb() =>
      jsonDecode(File(arbPath).readAsStringSync()) as Map<String, Object?>;

  /// The two authorized keys, in order, with their baseline English,
  /// written out here independently of production.
  const batch6 = <String, String>{
    'firstNameEditorTitle': 'Your name',
    'firstNameEditorSupporting':
        'Used only to make THIRTY feel a little more personal.',
  };
  const title = 'Your name';
  const supporting = 'Used only to make THIRTY feel a little more personal.';

  /// The accepted Batch 1–5 catalogue, in order, with its values.
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
    'youPersonalNameTitle': 'Your name',
    'youPersonalNameAddPrompt': 'Add your name',
  };

  /// FNV-1a/64 of the accepted eighteen messages *with* their metadata
  /// (key, English value and `@key` map, in order), as accepted at
  /// 57c234ce: any change to a key, a value, a description or a
  /// placeholder of Batches 1–5 changes it.
  const acceptedFingerprint = '22e382603b9ff20e';

  String valueOf(AppLocalizations l, String key) => switch (key) {
    'firstNameEditorTitle' => l.firstNameEditorTitle,
    'firstNameEditorSupporting' => l.firstNameEditorSupporting,
    _ => throw ArgumentError(key),
  };

  group('the English catalogue', () {
    test('holds the two words with their exact English values', () {
      final c = arb();
      for (final MapEntry(:key, :value) in batch6.entries) {
        expect(c[key], value, reason: key);
      }
    });

    test('is exactly twenty messages: the accepted eighteen unchanged and '
        'first, then the two in dialog order', () {
      final c = arb();
      final keys = [
        for (final k in c.keys)
          if (!k.startsWith('@')) k,
      ];
      expect(keys.take(18).toList(), accepted.keys.toList());
      expect(keys.skip(18).toList(), batch6.keys.toList());
      expect(keys, hasLength(20));
      for (final MapEntry(:key, :value) in accepted.entries) {
        expect(c[key], value, reason: key);
      }
      expect(c['@@locale'], 'en');
    });

    test('keeps the accepted eighteen’s descriptions and placeholders byte '
        'for byte', () {
      final c = arb();
      final accepted18 = [
        for (final key in accepted.keys) [key, c[key], c['@$key']],
      ];
      expect(fnv64(jsonEncode(accepted18)), acceptedFingerprint);
    });

    String description(String key) =>
        ((arb()['@$key']! as Map<String, Object?>)['description']! as String);

    test('describes each key: the dialog that owns it, where it sits, what '
        'it is for, and what it is not', () {
      for (final key in batch6.keys) {
        expect(
          description(key).length,
          greaterThan(200),
          reason: '$key needs a description a translator can act on',
        );
        expect(
          description(key),
          startsWith('First-name editor (the dialog that opens from the '),
          reason: key,
        );
      }
      final t = description('firstNameEditorTitle');
      expect(t, contains("the dialog's title"));
      expect(t, contains('first-name field'));
      expect(t, contains('firstNameEditorSupporting'));
      expect(t, contains('never the name itself'));
      expect(t, contains('never contains what the person types'));
      expect(t, contains('youPersonalNameTitle'));
      expect(t, contains('a different key with its own owner'));
      final s = description('firstNameEditorSupporting');
      expect(s, contains("immediately below the dialog's title"));
      expect(s, contains('firstNameEditorTitle'));
      expect(s, contains('calmly and without technical words'));
      expect(s, contains('must not suggest an account, an online profile'));
      expect(s, contains('stored on a server'));
      expect(s, contains('it is not a validation or error message'));
      expect(s, contains('THIRTY is the product name'));
    });

    test('declares no placeholder, and no value uses ICU syntax or an '
        'apostrophe; the name itself is never in the catalogue', () {
      final c = arb();
      for (final MapEntry(:key, :value) in batch6.entries) {
        final meta = c['@$key']! as Map<String, Object?>;
        expect(meta.keys, ['description'], reason: key);
        expect(value, isNot(matches(RegExp(r"[{}'’]"))), reason: key);
      }
      // THIRTY stays the product name, as written.
      expect(c['firstNameEditorSupporting'], contains('THIRTY'));
    });

    test('is still the only catalogue: no other language file exists, and '
        'English is still the only runtime locale', () {
      expect(
        [
          for (final f in Directory('lib/l10n/arb').listSync())
            f.uri.pathSegments.last,
        ],
        ['app_en.arb'],
      );
      expect(AppLocalizations.supportedLocales, const [Locale('en')]);
      expect(thirtyReleaseLocales, const [Locale('en')]);
    });
  });

  group('the generated English catalogue', () {
    final en = lookupAppLocalizations(const Locale('en'));

    test('gives the baseline words, the same as the ARB', () {
      expect(en, isA<AppLocalizationsEn>());
      final c = arb();
      for (final MapEntry(:key, :value) in batch6.entries) {
        expect(valueOf(en, key), value, reason: key);
        expect(valueOf(en, key), c[key], reason: '$key matches the ARB');
      }
      // The row's title has the same English words under its own key.
      expect(en.youPersonalNameTitle, title);
    });

    test('declares plain String getters, and generates English only', () {
      final generated = File(
        'lib/l10n/gen/app_localizations.dart',
      ).readAsStringSync();
      final english = File(
        'lib/l10n/gen/app_localizations_en.dart',
      ).readAsStringSync();
      for (final MapEntry(:key, :value) in batch6.entries) {
        expect(generated, contains('String get $key;'), reason: key);
        // The formatter may wrap a long getter after `=>`.
        expect(
          english,
          matches(RegExp("String get $key =>\\s+'${RegExp.escape(value)}';")),
          reason: key,
        );
      }
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
        for (final MapEntry(:key, :value) in batch6.entries) {
          expect(valueOf(l, key), value, reason: '$locale $key');
        }
        expect(
          thirtyLocaleListResolution([locale], thirtyReleaseLocales),
          const Locale('en'),
          reason: '$locale',
        );
      }
    });
  });

  group('the owning source', () {
    /// A source file without its comments: doc comments quote words to
    /// describe the widget, and are not copy.
    String code(String path) => [
      for (final line in File(path).readAsStringSync().split('\n'))
        if (!line.trimLeft().startsWith('//')) line,
    ].join('\n');

    final editor = code(editorOwner);

    test('the editor no longer holds the two English literals or their '
        'constants (comments may still quote them)', () {
      expect(editor, contains('class FirstNameEditor'));
      for (final value in batch6.values) {
        expect(editor, isNot(contains("'$value'")), reason: value);
        expect(editor, isNot(contains('"$value"')), reason: value);
      }
      expect(editor, isNot(contains("'Your name")));
      expect(editor, isNot(contains("'Used only")));
      expect(editor, isNot(contains('static const title')));
      expect(editor, isNot(contains('static const supporting')));
      expect(editor, isNot(contains('FirstNameEditor.title')));
      expect(editor, isNot(contains('FirstNameEditor.supporting')));
      // No English fallback constant of any kind: the only static constants
      // left are the field's label and length message (out of this batch)
      // and the private large-text threshold.
      expect(RegExp(r'static const \w+').allMatches(editor).map((m) => m[0]), [
        'static const fieldLabel',
        'static const tooLongMessage',
        'static const _largeTextScale',
      ]);
    });

    test('the editor reads its own two keys from the catalogue of the '
        'widget’s context, once each, with no English-pinned lookup', () {
      expect(
        RegExp(r'final l10n = context\.l10n;').allMatches(editor),
        hasLength(1),
      );
      expect(
        RegExp(r'\bl10n\.firstNameEditorTitle\b').allMatches(editor),
        hasLength(1),
      );
      expect(
        RegExp(r'\bl10n\.firstNameEditorSupporting\b').allMatches(editor),
        hasLength(1),
      );
      expect(editor, contains('title: Text(l10n.firstNameEditorTitle),'));
      expect(
        editor,
        contains(
          'Text(\n'
          '            l10n.firstNameEditorSupporting,\n'
          '            style: textTheme.bodyMedium?.copyWith('
          'color: colors.textSecondary),\n'
          '          ),',
        ),
      );
      // Only those two catalogue reads, and never the row's keys.
      expect(
        RegExp(r'\bl10n\.(\w+)').allMatches(editor).map((m) => m[1]).toSet(),
        {'firstNameEditorTitle', 'firstNameEditorSupporting'},
      );
      expect(editor, isNot(contains('youPersonalName')));
      expect(editor, isNot(contains('lookupAppLocalizations')));
      expect(editor, isNot(contains('AppLocalizationsEn')));
      expect(editor, isNot(contains("Locale('en')")));
      expect(editor, isNot(contains('thirtyLocalizationsFor')));
      expect(editor, isNot(contains('Localizations.override')));
      expect(
        editor,
        contains("import '../../../../core/l10n/thirty_locales.dart';"),
      );
    });

    test('the editor keeps its dialog, field, length message, three '
        'actions, barrier label, storage and validation', () {
      for (final line in [
        'Future<void> showFirstNameEditor(BuildContext context) => '
            'showDialog<void>(',
        "barrierLabel: 'Cancel',",
        'builder: (_) => const FirstNameEditor(),',
        'const FirstNameEditor({super.key});',
        "static const fieldLabel = 'First name';",
        "static const tooLongMessage = 'Use \$maxFirstNameLength characters "
            "or fewer.';",
        'static const _largeTextScale = 1.3;',
        'late final String? _existing = ref.read(firstNameProvider);',
        'late final _controller = TextEditingController(text: _existing);',
        'bool get _tooLong => !firstNameFits(_controller.text);',
        'bool get _canSave => trimmedFirstName(_controller.text) != null && '
            '!_tooLong;',
        'await ref.read(firstNameProvider.notifier).setFirstName('
            '_controller.text);',
        'await ref.read(firstNameProvider.notifier).clear();',
        'scrollable: true,',
        'actionsOverflowButtonSpacing: largeText ? AppSpacing.s : null,',
        'MediaQuery.textScalerOf(context).scale(1) >= _largeTextScale;',
        'autofocus: true,',
        'textCapitalization: TextCapitalization.words,',
        'textInputAction: TextInputAction.done,',
        'labelText: FirstNameEditor.fieldLabel,',
        'errorText: _tooLong ? FirstNameEditor.tooLongMessage : null,',
        'errorMaxLines: 3,',
        'onSubmitted: (_) => _save(),',
        'if (_existing != null) ...[',
        'minimumSize: const Size(0, 48),',
        "child: const Text('Remove name'),",
        "child: const Text('Cancel'),",
        'onPressed: _canSave ? _save : null,',
        "child: const Text('Save'),",
      ]) {
        expect(editor, contains(line), reason: line);
      }
      // Button order: Cancel, then Save.
      expect(
        editor.indexOf("const Text('Cancel')"),
        lessThan(editor.indexOf("const Text('Save')")),
      );
    });

    test('the row keeps its own two keys and never reads the editor’s; the '
        'first-use question reads neither', () {
      final row = code(rowOwner);
      expect(row, contains('final rowTitle = l10n.youPersonalNameTitle;'));
      expect(row, contains('final addPrompt = l10n.youPersonalNameAddPrompt;'));
      expect(row, isNot(contains('firstNameEditor')));
      expect(row, contains('void open() => showFirstNameEditor(context);'));
      final question = code(questionOwner);
      expect(question, isNot(contains('firstNameEditorTitle')));
      expect(question, isNot(contains('firstNameEditorSupporting')));
      expect(question, isNot(contains('youPersonalName')));
      expect(question, isNot(contains('l10n')));
      expect(
        question,
        contains("static const question = 'What should we call you?';"),
      );
      expect(question, contains('labelText: FirstNameEditor.fieldLabel,'));
      expect(
        question,
        contains(
          'errorText: _tooLong ? FirstNameEditor.tooLongMessage : null,',
        ),
      );
    });
  });

  group('the rendered editor, in English', () {
    for (final (themeName, theme) in [
      ('light', AppTheme.light),
      ('dark', AppTheme.dark),
    ]) {
      for (final width in const [360.0, 412.0]) {
        for (final scale in const [1.0, 2.0]) {
          testWidgets('$themeName, ${width.toInt()}dp, ${scale}x: "$title" '
              'over the supporting line over the field; unchanged styles, '
              'actions and layout, nothing cut off', (tester) async {
            await _pumpEditor(
              tester,
              theme: theme,
              width: width,
              textScale: scale,
            );
            expect(tester.takeException(), isNull);
            final dialog = find.byType(AlertDialog);
            expect(dialog, findsOneWidget);
            Finder inDialog(String text) =>
                find.descendant(of: dialog, matching: find.text(text));

            expect(inDialog(title), findsOneWidget);
            expect(inDialog(supporting), findsOneWidget);
            expect(inDialog('First name'), findsOneWidget);
            expect(inDialog('Cancel'), findsOneWidget);
            expect(inDialog('Save'), findsOneWidget);
            expect(inDialog('Remove name'), findsNothing);

            // The title is the AlertDialog's title, the supporting line the
            // first child of its content.
            final alert = tester.widget<AlertDialog>(dialog);
            expect((alert.title! as Text).data, title);
            final column = alert.content! as Column;
            expect((column.children.first as Text).data, supporting);
            expect(alert.scrollable, isTrue);
            final large = scale >= 1.3;
            expect(
              alert.insetPadding,
              large
                  ? const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                      vertical: AppSpacing.l,
                    )
                  : null,
            );
            expect(
              alert.actionsOverflowButtonSpacing,
              large ? AppSpacing.s : null,
            );

            double top(Finder f) => tester.getTopLeft(f).dy;
            expect(
              top(inDialog(supporting)),
              greaterThan(top(inDialog(title))),
            );
            expect(
              top(find.byType(TextField)),
              greaterThan(top(inDialog(supporting))),
            );

            // Styles: the title inherits the dialog's title style; the
            // supporting line is bodyMedium in the secondary text colour.
            final context = tester.element(find.byType(FirstNameEditor));
            final colors = Theme.of(context).extension<AppColors>()!;
            final textTheme = Theme.of(context).textTheme;
            expect(tester.widget<Text>(inDialog(title)).style, isNull);
            final supportingStyle = tester
                .widget<Text>(inDialog(supporting))
                .style!;
            expect(supportingStyle.color, colors.textSecondary);
            expect(supportingStyle.fontSize, textTheme.bodyMedium?.fontSize);
            expect(
              supportingStyle.fontWeight,
              textTheme.bodyMedium?.fontWeight,
            );
            expect(supportingStyle.height, textTheme.bodyMedium?.height);

            // Empty field: Save disabled, Cancel enabled.
            expect(_button(tester, 'Save').onPressed, isNull);
            expect(_button(tester, 'Cancel').onPressed, isNotNull);

            // Nothing in the dialog is cut off or overflows its lines.
            for (final paragraph in tester.renderObjectList<RenderParagraph>(
              find.descendant(of: dialog, matching: find.byType(RichText)),
            )) {
              expect(
                paragraph.didExceedMaxLines,
                isFalse,
                reason: paragraph.text.toPlainText(),
              );
            }
            final screen =
                tester.view.physicalSize / tester.view.devicePixelRatio;
            final box = tester.getRect(
              find
                  .descendant(of: dialog, matching: find.byType(Material))
                  .first,
            );
            expect(box.left, greaterThanOrEqualTo(0));
            expect(box.right, lessThanOrEqualTo(screen.width));
          });
        }
      }
    }

    testWidgets('with a saved name: prefilled exactly as stored, and "Remove '
        'name" appears under the field', (tester) async {
      await _pumpEditor(tester, prefsValues: {firstNameKey: 'Alex'});
      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(of: dialog, matching: find.text(title)),
        findsOneWidget,
      );
      expect(_controller(tester).text, 'Alex');
      expect(
        find.descendant(of: dialog, matching: find.text('Remove name')),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.text('Remove name')).dy,
        greaterThan(tester.getTopLeft(find.byType(TextField)).dy),
      );
      expect(_button(tester, 'Save').onPressed, isNotNull);
    });

    for (final locale in _deviceLocales) {
      testWidgets('device language $locale: the same English header', (
        tester,
      ) async {
        await _pumpEditor(tester, deviceLocale: locale);
        expect(
          AppLocalizations.of(tester.element(find.byType(FirstNameEditor))),
          isA<AppLocalizationsEn>(),
        );
        expect(find.text(title), findsOneWidget);
        expect(find.text(supporting), findsOneWidget);
      });
    }
  });

  group('the editor’s behaviour and storage are unchanged', () {
    const otherPrefs = <String, Object>{
      'theme_mode_v1': 'dark',
      'first_name_prompt_seen_v1': true,
      '[fixture] other preference': 7,
    };

    Map<String, Object?> others(SharedPreferences prefs) => {
      for (final key in otherPrefs.keys) key: prefs.get(key),
    };

    testWidgets('blank, whitespace-only and too-long names cannot be saved; '
        'the longest allowed one can', (tester) async {
      await _pumpEditor(tester);
      expect(_button(tester, 'Save').onPressed, isNull);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(_button(tester, 'Save').onPressed, isNull);
      expect(find.text(FirstNameEditor.tooLongMessage), findsNothing);
      await tester.enterText(
        find.byType(TextField),
        'a' * (maxFirstNameLength + 1),
      );
      await tester.pump();
      expect(_button(tester, 'Save').onPressed, isNull);
      expect(find.text('Use 40 characters or fewer.'), findsOneWidget);
      expect(FirstNameEditor.tooLongMessage, 'Use 40 characters or fewer.');
      await tester.enterText(find.byType(TextField), 'a' * maxFirstNameLength);
      await tester.pump();
      expect(_button(tester, 'Save').onPressed, isNotNull);
      expect(find.text('Use 40 characters or fewer.'), findsNothing);
    });

    testWidgets('Save stores the trimmed name under the same key and touches '
        'nothing else', (tester) async {
      final (container, prefs) = await _pumpEditor(
        tester,
        prefsValues: otherPrefs,
      );
      final before = others(prefs);
      await tester.enterText(find.byType(TextField), '  Sam  ');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.byType(FirstNameEditor), findsNothing);
      expect(firstNameKey, 'user_first_name_v1');
      expect(prefs.getString('user_first_name_v1'), 'Sam');
      expect(container.read(firstNameProvider), 'Sam');
      expect(others(prefs), before);
      expect(prefs.getKeys(), {...otherPrefs.keys, firstNameKey});
    });

    testWidgets('the keyboard’s Done saves, the same as Save', (tester) async {
      final (container, prefs) = await _pumpEditor(tester);
      await tester.enterText(find.byType(TextField), 'Robin');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byType(FirstNameEditor), findsNothing);
      expect(prefs.getString(firstNameKey), 'Robin');
      expect(container.read(firstNameProvider), 'Robin');
    });

    testWidgets('Done on a blank field neither saves nor closes', (
      tester,
    ) async {
      final (_, prefs) = await _pumpEditor(tester);
      await tester.enterText(find.byType(TextField), '  ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byType(FirstNameEditor), findsOneWidget);
      expect(prefs.containsKey(firstNameKey), isFalse);
    });

    testWidgets('Cancel closes without changing the stored name or anything '
        'else', (tester) async {
      final (container, prefs) = await _pumpEditor(
        tester,
        prefsValues: {...otherPrefs, firstNameKey: 'Alex'},
      );
      final before = others(prefs);
      await tester.enterText(find.byType(TextField), 'Bob');
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(FirstNameEditor), findsNothing);
      expect(prefs.getString(firstNameKey), 'Alex');
      expect(container.read(firstNameProvider), 'Alex');
      expect(others(prefs), before);
    });

    testWidgets('Remove name removes the name, and only the name', (
      tester,
    ) async {
      final (container, prefs) = await _pumpEditor(
        tester,
        prefsValues: {...otherPrefs, firstNameKey: 'Alex'},
      );
      final before = others(prefs);
      await tester.tap(find.text('Remove name'));
      await tester.pumpAndSettle();
      expect(find.byType(FirstNameEditor), findsNothing);
      expect(prefs.containsKey(firstNameKey), isFalse);
      expect(container.read(firstNameProvider), isNull);
      expect(others(prefs), before);
    });
  });

  group('accessibility is unchanged', () {
    for (final scale in const [1.0, 2.0]) {
      testWidgets('${scale}x: the same dialog semantics (a route-scoping '
          'alert dialog, its title a plain text node); the reading order is '
          'title, supporting line, field, Remove name, Cancel, Save, then '
          'the barrier; nothing is read twice', (tester) async {
        final semantics = tester.ensureSemantics();
        await _pumpEditor(
          tester,
          textScale: scale,
          prefsValues: {firstNameKey: 'Alex'},
        );
        // As at 57c234ce: Material names the alert dialog's route (its own
        // localized "Alert"), so the title itself does not name the route.
        final titleNode = tester.getSemantics(find.text(title));
        expect(
          titleNode,
          matchesSemantics(label: title, textDirection: TextDirection.ltr),
        );
        expect(
          tester.getSemantics(find.text(supporting)),
          matchesSemantics(label: supporting, textDirection: TextDirection.ltr),
        );
        var dialogNode = titleNode.parent;
        while (dialogNode != null && dialogNode.label != 'Alert') {
          dialogNode = dialogNode.parent;
        }
        expect(dialogNode, isNotNull, reason: 'the dialog route node');
        expect(
          dialogNode,
          isSemantics(label: 'Alert', scopesRoute: true, namesRoute: true),
        );

        final labels = _labelsInTraversalOrder(titleNode);
        int at(String label) {
          final i = labels.indexOf(label);
          expect(i, isNonNegative, reason: '"$label" in $labels');
          return i;
        }

        expect(at('Alert'), lessThan(at(title)));
        expect(at(title), lessThan(at(supporting)));
        expect(at(supporting), lessThan(at('First name')));
        expect(at('First name'), lessThan(at('Remove name')));
        expect(at('Remove name'), lessThan(at('Cancel')));
        expect(at('Cancel'), lessThan(at('Save')));
        // The barrier, read as "Cancel" (by what it does), comes last.
        expect(labels.lastIndexOf('Cancel'), labels.length - 1);
        // The header is read once each; the page under the dialog is not
        // read at all.
        expect(labels.where((l) => l == title), hasLength(1));
        expect(labels.where((l) => l == supporting), hasLength(1));
        expect(labels.where((l) => l.contains('[host]')), isEmpty);
        // "Cancel" twice: the button and the barrier.
        expect(labels.where((l) => l == 'Cancel'), hasLength(2));
        expect(labels, [
          'Alert',
          title,
          supporting,
          'First name',
          'Remove name',
          'Cancel',
          'Save',
          'Cancel',
        ]);

        // The field is labelled "First name" and holds the name as typed.
        expect(
          tester.getSemantics(find.byType(EditableText)),
          isSemantics(label: 'First name', value: 'Alex', isTextField: true),
        );
        for (final action in ['Cancel', 'Save', 'Remove name']) {
          expect(
            tester.getSemantics(
              find.ancestor(
                of: find.text(action),
                matching: find.byType(TextButton),
              ),
            ),
            isSemantics(
              label: action,
              isButton: true,
              isEnabled: true,
              hasTapAction: true,
            ),
            reason: action,
          );
        }
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        semantics.dispose();
      });
    }

    testWidgets('an empty field: Save is a disabled button; the barrier is '
        'read as "Cancel" and dismisses', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpEditor(tester);
      expect(
        tester.getSemantics(
          find.ancestor(
            of: find.text('Save'),
            matching: find.byType(TextButton),
          ),
        ),
        isSemantics(label: 'Save', isButton: true, isEnabled: false),
      );
      final barrier = find
          .bySemanticsLabel('Cancel')
          .evaluate()
          .where(
            (e) => find
                .ancestor(
                  of: find.byWidget(e.widget),
                  matching: find.byType(AlertDialog),
                )
                .evaluate()
                .isEmpty,
          );
      expect(barrier, hasLength(1));
      final node = tester.getSemantics(find.byWidget(barrier.single.widget));
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect(find.byType(FirstNameEditor), findsNothing);
      semantics.dispose();
    });
  });

  group('a marked catalogue', () {
    testWidgets('the row reads its own title; the editor it opens reads its '
        'own title and supporting line, never the row’s', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpCard(tester, delegates: _markedDelegates);
      const nameRow = ValueKey('you.name');
      expect(
        find.descendant(
          of: find.byKey(nameRow),
          matching: find.text(_rowTitleFixture),
        ),
        findsOneWidget,
      );
      expect(find.text(_editorTitleFixture), findsNothing);
      await tester.tap(find.byKey(nameRow));
      await tester.pumpAndSettle();
      final dialog = find.byType(AlertDialog);
      Finder inDialog(String text) =>
          find.descendant(of: dialog, matching: find.text(text));
      expect(inDialog(_editorTitleFixture), findsOneWidget);
      expect(inDialog(_editorSupportingFixture), findsOneWidget);
      expect(inDialog(_rowTitleFixture), findsNothing);
      expect(inDialog(title), findsNothing);
      expect(inDialog(supporting), findsNothing);
      expect(
        (tester.widget<AlertDialog>(dialog).title! as Text).data,
        _editorTitleFixture,
      );
      expect(
        tester.getSemantics(inDialog(_editorTitleFixture)),
        matchesSemantics(
          label: _editorTitleFixture,
          textDirection: TextDirection.ltr,
        ),
      );
      // The rest of the editor is still its own English.
      expect(inDialog('First name'), findsOneWidget);
      expect(inDialog('Cancel'), findsOneWidget);
      expect(inDialog('Save'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('the same through showFirstNameEditor on its own, with a '
        'saved name: the name is the person’s own, never translated', (
      tester,
    ) async {
      final (container, prefs) = await _pumpEditor(
        tester,
        delegates: _markedDelegates,
        prefsValues: {firstNameKey: 'Alex'},
      );
      expect(find.text(_editorTitleFixture), findsOneWidget);
      expect(find.text(_editorSupportingFixture), findsOneWidget);
      expect(find.text(_rowTitleFixture), findsNothing);
      expect(find.textContaining('[fixture]'), findsNWidgets(2));
      expect(_controller(tester).text, 'Alex');
      expect(find.text('Remove name'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Zoë');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(prefs.getString(firstNameKey), 'Zoë');
      expect(container.read(firstNameProvider), 'Zoë');
    });

    testWidgets('the first-use question reads neither the editor’s keys nor '
        'the row’s: its own copy is unchanged', (tester) async {
      await _pumpQuestion(tester, delegates: _markedDelegates);
      expect(find.byType(FirstNameQuestionPage), findsOneWidget);
      expect(find.textContaining('[fixture]'), findsNothing);
      expect(find.text(FirstNameQuestionPage.question), findsOneWidget);
      expect(find.text(FirstNameQuestionPage.supporting), findsOneWidget);
      expect(find.text('First name'), findsOneWidget);
      expect(find.text(title), findsNothing);
      expect(find.text(supporting), findsNothing);
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

const _rowTitleFixture = '[fixture] row title';
const _editorTitleFixture = '[fixture] editor title';
const _editorSupportingFixture = '[fixture] editor supporting';

/// THIRTY's English catalogue with the editor's two words and the row's
/// title replaced by distinct `[fixture]` markers — not product copy. In
/// English the row's title and the editor's title are the same words; here
/// they differ, so a widget reading the wrong key shows the wrong marker.
class _Marked extends AppLocalizationsEn {
  @override
  String get firstNameEditorTitle => _editorTitleFixture;
  @override
  String get firstNameEditorSupporting => _editorSupportingFixture;
  @override
  String get youPersonalNameTitle => _rowTitleFixture;
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

TextButton _button(WidgetTester tester, String label) => tester.widget(
  find.ancestor(of: find.text(label), matching: find.byType(TextButton)),
);

TextEditingController _controller(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!;

/// Every non-empty label under the root of [node]'s tree, in screen-reader
/// traversal order.
List<String> _labelsInTraversalOrder(SemanticsNode node) {
  var root = node;
  while (root.parent != null) {
    root = root.parent!;
  }
  final labels = <String>[];
  void visit(SemanticsNode n) {
    if (n.label.isNotEmpty) labels.add(n.label);
    for (final child in n.debugListChildrenInOrder(
      DebugSemanticsDumpOrder.traversalOrder,
    )) {
      visit(child);
    }
  }

  visit(root);
  return labels;
}

Future<(ProviderContainer, SharedPreferences)> _container(
  Map<String, Object> prefsValues,
) async {
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return (container, prefs);
}

void _view(
  WidgetTester tester, {
  required double width,
  double height = 915,
  Locale deviceLocale = const Locale('en', 'US'),
}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.localesTestValue = [deviceLocale];
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
}

/// The real first-name editor, opened through the real
/// [showFirstNameEditor] from a host page under THIRTY's English-only
/// resolution (`thirty_app.dart`). One pump per test.
Future<(ProviderContainer, SharedPreferences)> _pumpEditor(
  WidgetTester tester, {
  List<LocalizationsDelegate<Object?>> delegates = thirtyLocalizationsDelegates,
  Map<String, Object> prefsValues = const {},
  ThemeData? theme,
  double width = 412,
  double textScale = 1.0,
  Locale deviceLocale = const Locale('en', 'US'),
}) async {
  _view(tester, width: width, deviceLocale: deviceLocale);
  final (container, prefs) = await _container(prefsValues);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: theme ?? AppTheme.light,
        localizationsDelegates: delegates,
        supportedLocales: thirtyReleaseLocales,
        localeListResolutionCallback: thirtyLocaleListResolution,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showFirstNameEditor(context),
                child: const Text('[host] open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  // A fixture delegate loads asynchronously: settle before the first tap.
  await tester.pumpAndSettle();
  await tester.tap(find.text('[host] open'));
  await tester.pumpAndSettle();
  expect(find.byType(FirstNameEditor), findsOneWidget);
  return (container, prefs);
}

/// The Personal card as You hosts it, with its real destinations stubbed
/// by route markers. One pump per test.
Future<void> _pumpCard(
  WidgetTester tester, {
  required List<LocalizationsDelegate<Object?>> delegates,
}) async {
  _view(tester, width: 412, height: 2400);
  final (container, _) = await _container(const {});
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
        theme: AppTheme.light,
        localizationsDelegates: delegates,
        supportedLocales: thirtyReleaseLocales,
        localeListResolutionCallback: thirtyLocaleListResolution,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The first-use question on its own, under [delegates]. One pump per test.
Future<void> _pumpQuestion(
  WidgetTester tester, {
  required List<LocalizationsDelegate<Object?>> delegates,
}) async {
  _view(tester, width: 412);
  final (container, _) = await _container(const {});
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: delegates,
        supportedLocales: thirtyReleaseLocales,
        localeListResolutionCallback: thirtyLocaleListResolution,
        home: const FirstNameQuestionPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
