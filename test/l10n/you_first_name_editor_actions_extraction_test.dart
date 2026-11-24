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

/// G-02 / L-CNT-EN / Batch 7 (the first-name editor's actions): the
/// editor's "Remove name" and "Save" button labels come from THIRTY's
/// English catalogue under their own keys, `firstNameEditorRemoveNameAction`
/// and `firstNameEditorSaveAction`, and say exactly what they said before.
/// The buttons themselves are unchanged: Remove name is still shown only
/// for a saved name, is still quiet and unconfirmed, and still clears only
/// the name; Save is still enabled only for a valid name and still stores
/// it trimmed under the same key. The field label, the length message, the
/// first-use question and the Personal name row are out of this batch and
/// unchanged. The person's first name is user data: never in the catalogue,
/// never translated.
///
/// G-02 / L-CNT-EN / Batch 8 (the first-name editor's Cancel semantics),
/// in the same file: the visible "Cancel" button and the dialog barrier's
/// spoken "Cancel" are two copy owners with two keys,
/// `firstNameEditorCancelAction` and `firstNameEditorDismissBarrierLabel`.
/// Their English is the same, so a marked catalogue gives each its own
/// `[fixture]` words: the button shows and is read as its own, the barrier
/// is read as its own, and neither can borrow, swap or hard-code the other.
/// Both still close the editor without saving; the kept Circle page's own
/// Cancel is a third owner and keeps its English literal.
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
  const batch7 = <String, String>{
    'firstNameEditorRemoveNameAction': 'Remove name',
    'firstNameEditorSaveAction': 'Save',
  };

  /// Batch 8's two keys, in order, with their baseline English (the same
  /// words, two owners), written out here independently of production.
  const batch8 = <String, String>{
    'firstNameEditorCancelAction': 'Cancel',
    'firstNameEditorDismissBarrierLabel': 'Cancel',
  };
  const removeName = 'Remove name';
  const save = 'Save';
  const cancel = 'Cancel';
  const title = 'Your name';
  const supporting = 'Used only to make THIRTY feel a little more personal.';

  /// The accepted Batch 1–6 catalogue, in order, with its values.
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
    'firstNameEditorTitle': title,
    'firstNameEditorSupporting': supporting,
  };

  /// FNV-1a/64 of the accepted twenty messages *with* their metadata (key,
  /// English value and `@key` map, in order), as accepted at da19082d: any
  /// change to a key, a value, a description or a placeholder of Batches
  /// 1–6 changes it.
  const acceptedFingerprint = '25be0f3d13827e2e';

  /// FNV-1a/64 of the accepted twenty-two (Batches 1–7) with their metadata,
  /// computed the same way, as accepted at b1dea377. The hash's top bit is
  /// set, so the project's `fnv64` (a 64-bit Dart int) prints it signed:
  /// this is the unsigned value 0x99657005976253cc.
  const accepted22Fingerprint = '-669a8ffa689dac34';

  String valueOf(AppLocalizations l, String key) => switch (key) {
    'firstNameEditorRemoveNameAction' => l.firstNameEditorRemoveNameAction,
    'firstNameEditorSaveAction' => l.firstNameEditorSaveAction,
    'firstNameEditorCancelAction' => l.firstNameEditorCancelAction,
    'firstNameEditorDismissBarrierLabel' =>
      l.firstNameEditorDismissBarrierLabel,
    _ => throw ArgumentError(key),
  };

  group('the English catalogue', () {
    test('holds the two labels with their exact English values', () {
      final c = arb();
      for (final MapEntry(:key, :value) in batch7.entries) {
        expect(c[key], value, reason: key);
      }
    });

    test('Batch 8: holds the Cancel button and the barrier label, both '
        '"Cancel", under two keys', () {
      final c = arb();
      for (final MapEntry(:key, :value) in batch8.entries) {
        expect(c[key], value, reason: key);
        expect(c[key], cancel, reason: key);
      }
      // Two owners, two keys: no generic or shared Cancel key exists.
      expect(
        [
          for (final k in c.keys)
            if (!k.startsWith('@') && k.toLowerCase().contains('cancel')) k,
        ],
        ['firstNameEditorCancelAction'],
      );
      expect([
        for (final k in c.keys)
          if (!k.startsWith('@') && c[k] == cancel) k,
      ], batch8.keys.toList());
    });

    test('is exactly twenty-four messages: the accepted twenty unchanged and '
        'first, then Remove name, then Save, then Batch 8’s Cancel button, '
        'then its barrier label', () {
      final c = arb();
      final keys = [
        for (final k in c.keys)
          if (!k.startsWith('@')) k,
      ];
      expect(keys.take(20).toList(), accepted.keys.toList());
      expect(keys.skip(20).take(2).toList(), batch7.keys.toList());
      expect(keys.skip(22).toList(), batch8.keys.toList());
      expect(keys, hasLength(24));
      for (final MapEntry(:key, :value) in accepted.entries) {
        expect(c[key], value, reason: key);
      }
      expect(c['@@locale'], 'en');
      // The raw file still ends with Batch 6, then Batch 7's two, then
      // Batch 8's two, in that order.
      final raw = File(arbPath).readAsStringSync();
      expect(
        raw.indexOf('"firstNameEditorSupporting"'),
        lessThan(raw.indexOf('"firstNameEditorRemoveNameAction"')),
      );
      expect(
        raw.indexOf('"firstNameEditorRemoveNameAction"'),
        lessThan(raw.indexOf('"firstNameEditorSaveAction"')),
      );
      expect(
        raw.indexOf('"firstNameEditorSaveAction"'),
        lessThan(raw.indexOf('"firstNameEditorCancelAction"')),
      );
      expect(
        raw.indexOf('"firstNameEditorCancelAction"'),
        lessThan(raw.indexOf('"firstNameEditorDismissBarrierLabel"')),
      );
    });

    test('keeps the accepted twenty’s descriptions and placeholders byte '
        'for byte', () {
      final c = arb();
      final accepted20 = [
        for (final key in accepted.keys) [key, c[key], c['@$key']],
      ];
      expect(fnv64(jsonEncode(accepted20)), acceptedFingerprint);
    });

    test('Batch 8 keeps the accepted twenty-two (Batch 7 included) byte for '
        'byte: keys, values, descriptions and placeholders', () {
      final c = arb();
      final accepted22 = [
        for (final key in [...accepted.keys, ...batch7.keys])
          [key, c[key], c['@$key']],
      ];
      expect(fnv64(jsonEncode(accepted22)), accepted22Fingerprint);
    });

    String description(String key) =>
        ((arb()['@$key']! as Map<String, Object?>)['description']! as String);

    test('describes Remove name: the dialog, when it shows, what it clears '
        'and what it does not, and what it must not be confused with', () {
      final r = description('firstNameEditorRemoveNameAction');
      expect(r.length, greaterThan(200));
      expect(
        r,
        startsWith(
          'First-name editor (the dialog that opens from the Your name row '
          'on You): ',
        ),
      );
      expect(r, contains('only when a first name already exists'));
      expect(r, contains('clears that optional first name stored on the'));
      expect(
        r,
        contains(
          'does not delete Circle history, kept Circles or any other '
          'preference',
        ),
      );
      expect(r, contains('quiet, non-destructive-looking preference action'));
      expect(r, contains('no destructive confirmation dialog'));
      expect(r, contains('broader data-deletion actions elsewhere in THIRTY'));
      expect(r, contains('youPersonalNameAddPrompt'));
      expect(r, contains('Personal name-row prompt'));
      expect(r, contains('A short button label'));
    });

    test('describes Save: what it saves, where, when it is disabled, that it '
        'is not onboarding’s Continue, and that it is a button label', () {
      final s = description('firstNameEditorSaveAction');
      expect(s.length, greaterThan(200));
      expect(
        s,
        startsWith(
          'First-name editor (the dialog that opens from the Your name row '
          'on You): ',
        ),
      );
      expect(s, contains('saves the edited optional first name'));
      expect(s, contains('inside the first-name editor dialog'));
      expect(
        s,
        contains('disabled when the entered value is blank (or only spaces) '),
      );
      expect(s, contains('otherwise invalid'));
      expect(s, contains('existing name-storage behaviour'));
      expect(s, contains('not the first-use onboarding action'));
      expect(s, contains('separately labelled Continue'));
      expect(s, contains('short button label, not a status message'));
      expect(s, contains('understandable whether the button is enabled or'));
    });

    test('Batch 8 describes the Cancel button: its dialog, its place before '
        'Save, that it saves nothing and removes nothing, that it stays '
        'available, and that the barrier is a separate key', () {
      final c = description('firstNameEditorCancelAction');
      expect(c.length, greaterThan(200));
      expect(
        c,
        startsWith(
          'First-name editor (the dialog that opens from the Your name row '
          'on You): ',
        ),
      );
      expect(c, contains('visible Cancel button'));
      expect(c, contains('belongs only to this dialog'));
      expect(c, contains('placed before Save in the dialog actions'));
      expect(c, contains('closes the dialog without saving any edits'));
      expect(c, contains('does not remove or change the first name'));
      expect(c, contains('stays available when Save is disabled'));
      expect(c, contains('A short action label'));
      expect(c, contains('announces it as a button'));
      expect(c, contains('It is not the accessibility label of the dialog'));
      expect(c, contains('firstNameEditorDismissBarrierLabel'));
      expect(c, contains('must remain independently translatable'));
    });

    test('Batch 8 describes the barrier label: the modal barrier outside the '
        'content, an accessibility label and no visible button, a dismissal '
        'that saves and clears nothing, read after the dialog, and separate '
        'from the visible Cancel', () {
      final b = description('firstNameEditorDismissBarrierLabel');
      expect(b.length, greaterThan(200));
      expect(
        b,
        startsWith(
          'First-name editor (the dialog that opens from the Your name row '
          'on You): ',
        ),
      );
      expect(b, contains('accessibility label of the modal dialog barrier'));
      expect(b, contains('outside the visible content of the dialog'));
      expect(b, contains('not an additional visible button'));
      expect(b, contains('the action of dismissing the modal dialog'));
      expect(b, contains('closes the editor without saving any edits'));
      expect(
        b,
        contains('must not suggest deleting, removing or clearing the stored'),
      );
      expect(b, contains('separate dismissal target'));
      expect(b, contains('after the content and actions of the dialog'));
      expect(b, contains('separate from the visible Cancel button'));
      expect(b, contains('firstNameEditorCancelAction'));
      expect(b, contains('describe the dismiss function of the barrier'));
    });

    test('declares no placeholder, and no value uses ICU syntax or an '
        'apostrophe; no description quotes a stored name', () {
      final c = arb();
      for (final MapEntry(:key, :value) in {...batch7, ...batch8}.entries) {
        final meta = c['@$key']! as Map<String, Object?>;
        expect(meta.keys, ['description'], reason: key);
        expect(value, isNot(matches(RegExp(r"[{}'’]"))), reason: key);
        expect(
          (meta['description']! as String),
          isNot(matches(RegExp(r"[{}]"))),
          reason: key,
        );
      }
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

    test('gives the baseline labels, the same as the ARB', () {
      expect(en, isA<AppLocalizationsEn>());
      final c = arb();
      for (final MapEntry(:key, :value) in {...batch7, ...batch8}.entries) {
        expect(valueOf(en, key), value, reason: key);
        expect(valueOf(en, key), c[key], reason: '$key matches the ARB');
      }
    });

    test('declares plain String getters, and generates English only', () {
      final generated = File(
        'lib/l10n/gen/app_localizations.dart',
      ).readAsStringSync();
      final english = File(
        'lib/l10n/gen/app_localizations_en.dart',
      ).readAsStringSync();
      for (final MapEntry(:key, :value) in {...batch7, ...batch8}.entries) {
        expect(generated, contains('String get $key;'), reason: key);
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

    test('every device language gets the same English labels (G-5C)', () {
      for (final locale in _deviceLocales) {
        final l = thirtyLocalizationsFor(locale);
        expect(l, isA<AppLocalizationsEn>(), reason: '$locale');
        for (final MapEntry(:key, :value) in {...batch7, ...batch8}.entries) {
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

    test('the editor reads each label from the catalogue of the widget’s '
        'context, once, with no English fallback or English-pinned '
        'lookup', () {
      expect(
        RegExp(r'final l10n = context\.l10n;').allMatches(editor),
        hasLength(1),
      );
      for (final key in [...batch7.keys, ...batch8.keys]) {
        expect(
          RegExp('\\bl10n\\.$key\\b').allMatches(editor),
          hasLength(1),
          reason: key,
        );
      }
      expect(
        editor,
        contains('child: Text(l10n.firstNameEditorRemoveNameAction),'),
      );
      expect(editor, contains('child: Text(l10n.firstNameEditorSaveAction),'));
      // Batch 8: the button reads its own key through the widget's l10n; the
      // barrier reads its own key from the caller's context, the only
      // context showFirstNameEditor has.
      expect(
        editor,
        contains('child: Text(l10n.firstNameEditorCancelAction),'),
      );
      expect(
        editor,
        contains(
          '  barrierLabel: context.l10n.firstNameEditorDismissBarrierLabel,\n',
        ),
      );
      expect(RegExp(r'\bcontext\.l10n\b').allMatches(editor), hasLength(2));
      for (final value in [...batch7.values, ...batch8.values]) {
        expect(editor, isNot(contains("'$value'")), reason: value);
        expect(editor, isNot(contains('"$value"')), reason: value);
      }
      expect(editor, isNot(contains('lookupAppLocalizations')));
      expect(editor, isNot(contains('AppLocalizationsEn')));
      expect(editor, isNot(contains("Locale('en')")));
      expect(editor, isNot(contains('thirtyLocalizationsFor')));
      expect(editor, isNot(contains('Localizations.override')));
      expect(editor, isNot(contains('youPersonalName')));
      // No new English constant: the same three statics as Batch 6.
      expect(RegExp(r'static const \w+').allMatches(editor).map((m) => m[0]), [
        'static const fieldLabel',
        'static const tooLongMessage',
        'static const _largeTextScale',
      ]);
    });

    test('Remove name keeps its condition, its quiet full-height button and '
        'its callback; only its label changed', () {
      expect(
        editor,
        contains(
          '          if (_existing != null) ...[\n'
          '            const SizedBox(height: AppSpacing.s),\n'
          '            TextButton(\n'
          '              onPressed: _remove,\n'
          '              style: TextButton.styleFrom(\n'
          '                padding: EdgeInsets.zero,\n'
          '                minimumSize: const Size(0, 48),\n'
          '                alignment: AlignmentDirectional.centerStart,\n'
          '              ),\n'
          '              child: Text(l10n.firstNameEditorRemoveNameAction),\n'
          '            ),\n'
          '          ],\n',
        ),
      );
      expect(
        editor,
        contains(
          '  Future<void> _remove() async {\n'
          '    await ref.read(firstNameProvider.notifier).clear();\n'
          '    if (mounted) Navigator.of(context).pop();\n'
          '  }\n',
        ),
      );
      expect(editor, isNot(contains('showDialog<bool>')));
      expect(editor, isNot(contains('colorScheme.error')));
      expect(editor, isNot(contains('foregroundColor')));
    });

    test('Save keeps its enablement and its callback, and Cancel then Save '
        'stay the dialog’s two actions; only their labels changed (Save in '
        'Batch 7, Cancel in Batch 8), and Cancel still only closes', () {
      expect(
        editor,
        contains(
          '      actions: [\n'
          '        TextButton(\n'
          '          onPressed: () => Navigator.of(context).pop(),\n'
          '          child: Text(l10n.firstNameEditorCancelAction),\n'
          '        ),\n'
          '        TextButton(\n'
          '          onPressed: _canSave ? _save : null,\n'
          '          child: Text(l10n.firstNameEditorSaveAction),\n'
          '        ),\n'
          '      ],\n',
        ),
      );
      expect(
        editor,
        contains(
          '  bool get _canSave => '
          'trimmedFirstName(_controller.text) != null && !_tooLong;\n',
        ),
      );
      expect(
        editor,
        contains(
          '  Future<void> _save() async {\n'
          '    if (!_canSave) return;\n'
          '    await ref.read(firstNameProvider.notifier).setFirstName('
          '_controller.text);\n'
          '    if (mounted) Navigator.of(context).pop();\n'
          '  }\n',
        ),
      );
      expect(editor, contains('onSubmitted: (_) => _save(),'));
    });

    test('Batch 8: the dialog route is unchanged; only its barrier label’s '
        'source changed, read from the caller’s context, with the same '
        'default dismissal', () {
      expect(
        editor,
        contains(
          'Future<void> showFirstNameEditor(BuildContext context) => '
          'showDialog<void>(\n'
          '  context: context,\n'
          '  barrierLabel: context.l10n.firstNameEditorDismissBarrierLabel,\n'
          '  builder: (_) => const FirstNameEditor(),\n'
          ');\n',
        ),
      );
      // The comment that explains the label is still there (code() drops
      // comments, so read the raw file).
      expect(
        File(editorOwner).readAsStringSync(),
        contains(
          '  // TalkBack names the backdrop by what it does.\n'
          '  barrierLabel: context.l10n.firstNameEditorDismissBarrierLabel,\n',
        ),
      );
      // Default barrier behaviour: dismissible, default colour, default
      // route settings; nothing forced to English.
      for (final absent in [
        'barrierDismissible',
        'barrierColor',
        'useRootNavigator',
        'routeSettings',
        'useSafeArea',
        'traversalEdgeBehavior',
      ]) {
        expect(editor, isNot(contains(absent)), reason: absent);
      }
      expect(RegExp(r'showDialog\b').allMatches(editor), hasLength(1));
    });

    test('the header, the field label and the length message are unchanged '
        'and out of this batch; no Cancel literal is left', () {
      for (final line in [
        'Future<void> showFirstNameEditor(BuildContext context) => '
            'showDialog<void>(',
        '  barrierLabel: context.l10n.firstNameEditorDismissBarrierLabel,',
        'builder: (_) => const FirstNameEditor(),',
        "static const fieldLabel = 'First name';",
        "static const tooLongMessage = 'Use \$maxFirstNameLength characters "
            "or fewer.';",
        'title: Text(l10n.firstNameEditorTitle),',
        'l10n.firstNameEditorSupporting,',
        'labelText: FirstNameEditor.fieldLabel,',
        'errorText: _tooLong ? FirstNameEditor.tooLongMessage : null,',
        'late final String? _existing = ref.read(firstNameProvider);',
        'late final _controller = TextEditingController(text: _existing);',
        'bool get _tooLong => !firstNameFits(_controller.text);',
        'autofocus: true,',
        'textCapitalization: TextCapitalization.words,',
        'textInputAction: TextInputAction.done,',
      ]) {
        expect(editor, contains(line), reason: line);
      }
      expect(RegExp("'Cancel'").allMatches(editor), isEmpty);
      expect(RegExp('"Cancel"').allMatches(editor), isEmpty);
      expect(editor, isNot(contains('l10n.cancel')));
    });

    test('nothing else reads the two keys: not the row, not the first-use '
        'question, and not the kept Circle page’s own Save', () {
      final readers = <String>[
        for (final f in Directory('lib').listSync(recursive: true))
          if (f is File &&
              f.path.endsWith('.dart') &&
              !f.path.replaceAll(r'\', '/').startsWith('lib/l10n/gen/') &&
              batch7.keys.any(f.readAsStringSync().contains))
            f.path.replaceAll(r'\', '/'),
      ];
      expect(readers, [editorOwner]);
      final row = code(rowOwner);
      expect(row, isNot(contains('firstNameEditor')));
      expect(row, contains('void open() => showFirstNameEditor(context);'));
      final question = code(questionOwner);
      expect(question, isNot(contains('l10n')));
      expect(question, isNot(contains('firstNameEditor')));
      expect(question, contains("label: 'Continue',"));
      expect(question, contains('onPressed: _canContinue ? _continue : null,'));
      expect(
        code('lib/features/personal_circle/presentation/kept_circle_page.dart'),
        contains("child: const Text('Save'),"),
      );
    });

    test('Batch 8: only the editor reads the two Cancel keys, each exactly '
        'once in all of lib; the row, the first-use question and the kept '
        'Circle page read neither, and the kept Circle keeps its own '
        'English Cancel', () {
      for (final key in batch8.keys) {
        final readers = <String, int>{
          for (final f in Directory('lib').listSync(recursive: true))
            if (f is File &&
                f.path.endsWith('.dart') &&
                !f.path.replaceAll(r'\', '/').startsWith('lib/l10n/gen/') &&
                f.readAsStringSync().contains(key))
              f.path.replaceAll(r'\', '/'): RegExp(
                '\\b$key\\b',
              ).allMatches(f.readAsStringSync()).length,
        };
        expect(readers, {editorOwner: 1}, reason: key);
      }
      const keptOwner =
          'lib/features/personal_circle/presentation/kept_circle_page.dart';
      for (final other in [rowOwner, questionOwner, keptOwner]) {
        final source = code(other);
        expect(source, isNot(contains('firstNameEditor')), reason: other);
        for (final key in batch8.keys) {
          expect(source, isNot(contains(key)), reason: '$other $key');
        }
      }
      // The kept Circle page is a third Cancel owner: its button and its
      // barrier keep their English literals, out of this batch.
      final kept = code(keptOwner);
      expect(kept, contains("barrierLabel: 'Cancel',"));
      expect(kept, contains("child: const Text('Cancel'),"));
      expect(RegExp("'Cancel'").allMatches(kept), hasLength(2));
    });
  });

  group('the rendered editor, in English', () {
    for (final (themeName, theme) in [
      ('light', AppTheme.light),
      ('dark', AppTheme.dark),
    ]) {
      for (final width in const [320.0, 412.0]) {
        for (final scale in const [1.0, 2.0]) {
          for (final saved in const [false, true]) {
            testWidgets('$themeName, ${width.toInt()}dp, ${scale}x, '
                '${saved ? 'a saved name' : 'no saved name'}: the same '
                'actions, labels, states and layout; nothing cut off', (
              tester,
            ) async {
              await _pumpEditor(
                tester,
                theme: theme,
                width: width,
                textScale: scale,
                prefsValues: {if (saved) firstNameKey: 'Alex'},
              );
              expect(tester.takeException(), isNull);
              final dialog = find.byType(AlertDialog);
              Finder inDialog(String text) =>
                  find.descendant(of: dialog, matching: find.text(text));

              expect(inDialog(title), findsOneWidget);
              expect(inDialog(supporting), findsOneWidget);
              expect(inDialog('First name'), findsOneWidget);
              expect(inDialog('Cancel'), findsOneWidget);
              expect(inDialog(save), findsOneWidget);
              expect(
                inDialog(removeName),
                saved ? findsOneWidget : findsNothing,
              );

              // Save is the second action, after Cancel; disabled for an empty
              // field, enabled for the saved name.
              final alert = tester.widget<AlertDialog>(dialog);
              final actions = alert.actions!.cast<TextButton>();
              expect(actions, hasLength(2));
              expect((actions.first.child! as Text).data, 'Cancel');
              expect((actions.last.child! as Text).data, save);
              expect(actions.first.onPressed, isNotNull);
              expect(
                actions.last.onPressed,
                saved ? isNotNull : isNull,
                reason: 'Save is enabled only for a valid name',
              );

              final context = tester.element(find.byType(FirstNameEditor));
              final colors = Theme.of(context).colorScheme;
              Color? colorOf(String text) => tester
                  .renderObject<RenderParagraph>(inDialog(text))
                  .text
                  .style
                  ?.color;
              if (saved) {
                // Under the field, quiet (the same colour as Cancel, never the
                // error colour), at least 48dp tall, aligned to the start.
                final remove = _button(tester, removeName);
                expect(remove.onPressed, isNotNull);
                final style = remove.style!;
                expect(style.padding?.resolve({}), EdgeInsets.zero);
                expect(style.minimumSize?.resolve({}), const Size(0, 48));
                expect(style.alignment, AlignmentDirectional.centerStart);
                expect(style.foregroundColor, isNull);
                expect(colorOf(removeName), colorOf('Cancel'));
                expect(colorOf(removeName), isNot(colors.error));
                final rect = tester.getRect(
                  find.ancestor(
                    of: inDialog(removeName),
                    matching: find.byType(TextButton),
                  ),
                );
                expect(rect.height, greaterThanOrEqualTo(48));
                expect(
                  rect.top,
                  greaterThan(tester.getRect(find.byType(TextField)).bottom),
                );
                expect(
                  rect.bottom,
                  lessThanOrEqualTo(tester.getTopLeft(inDialog('Cancel')).dy),
                );
              }

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
              for (final label in [save, if (saved) removeName, 'Cancel']) {
                final r = tester.getRect(inDialog(label));
                expect(r.left, greaterThanOrEqualTo(0), reason: label);
                expect(r.right, lessThanOrEqualTo(screen.width), reason: label);
              }
            });
          }
        }
      }
    }

    for (final locale in _deviceLocales) {
      testWidgets('device language $locale: the same English actions', (
        tester,
      ) async {
        await _pumpEditor(
          tester,
          deviceLocale: locale,
          prefsValues: {firstNameKey: 'Alex'},
        );
        expect(
          AppLocalizations.of(tester.element(find.byType(FirstNameEditor))),
          isA<AppLocalizationsEn>(),
        );
        expect(find.text(removeName), findsOneWidget);
        expect(find.text(save), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });
    }
  });

  group('the actions’ behaviour and storage are unchanged', () {
    const otherPrefs = <String, Object>{
      'theme_mode_v1': 'dark',
      'first_name_prompt_seen_v1': true,
      '[fixture] other preference': 7,
    };

    Map<String, Object?> others(SharedPreferences prefs) => {
      for (final key in otherPrefs.keys) key: prefs.get(key),
    };

    testWidgets('no saved name: no Remove name; Save shown but disabled, '
        'Cancel enabled; header and field unchanged', (tester) async {
      await _pumpEditor(tester);
      expect(find.text(removeName), findsNothing);
      expect(find.text(save), findsOneWidget);
      expect(_button(tester, save).onPressed, isNull);
      expect(_button(tester, 'Cancel').onPressed, isNotNull);
      expect(find.text(title), findsOneWidget);
      expect(find.text(supporting), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration!.labelText,
        'First name',
      );
      expect(_controller(tester).text, isEmpty);
    });

    testWidgets('blank, whitespace-only and too-long names leave Save '
        'disabled, with the same length message; a valid one enables it', (
      tester,
    ) async {
      await _pumpEditor(tester);
      for (final (text, enabled) in [
        ('', false),
        ('   ', false),
        ('a' * (maxFirstNameLength + 1), false),
        ('  ${'b' * maxFirstNameLength}  ', true),
        ('Sam', true),
      ]) {
        await tester.enterText(find.byType(TextField), text);
        await tester.pump();
        expect(
          _button(tester, save).onPressed,
          enabled ? isNotNull : isNull,
          reason: '"$text"',
        );
      }
      await tester.enterText(
        find.byType(TextField),
        'a' * (maxFirstNameLength + 1),
      );
      await tester.pump();
      expect(find.text('Use 40 characters or fewer.'), findsOneWidget);
      expect(maxFirstNameLength, 40);
    });

    testWidgets('Save stores the trimmed name under the same key, closes, and '
        'touches nothing else', (tester) async {
      final (container, prefs) = await _pumpEditor(
        tester,
        prefsValues: otherPrefs,
      );
      final before = others(prefs);
      await tester.enterText(find.byType(TextField), '  Sam  ');
      await tester.pump();
      await tester.tap(find.text(save));
      await tester.pumpAndSettle();
      expect(find.byType(FirstNameEditor), findsNothing);
      expect(prefs.getString('user_first_name_v1'), 'Sam');
      expect(container.read(firstNameProvider), 'Sam');
      expect(others(prefs), before);
      expect(prefs.getKeys(), {...otherPrefs.keys, firstNameKey});
    });

    testWidgets('a disabled Save does nothing when tapped', (tester) async {
      final (_, prefs) = await _pumpEditor(tester);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      await tester.tap(find.text(save), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(FirstNameEditor), findsOneWidget);
      expect(prefs.containsKey(firstNameKey), isFalse);
    });

    testWidgets('the keyboard’s Done still saves a valid name, and still '
        'does nothing for an invalid one', (tester) async {
      final (container, prefs) = await _pumpEditor(tester);
      await tester.enterText(
        find.byType(TextField),
        'a' * (maxFirstNameLength + 1),
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byType(FirstNameEditor), findsOneWidget);
      expect(prefs.containsKey(firstNameKey), isFalse);
      await tester.enterText(find.byType(TextField), 'Robin ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byType(FirstNameEditor), findsNothing);
      expect(prefs.getString(firstNameKey), 'Robin');
      expect(container.read(firstNameProvider), 'Robin');
    });

    testWidgets('a saved name: prefilled exactly as stored; Remove name '
        'clears only the name, at once, with no confirmation', (tester) async {
      final (container, prefs) = await _pumpEditor(
        tester,
        prefsValues: {...otherPrefs, firstNameKey: 'Zoë-Anne'},
      );
      final before = others(prefs);
      expect(_controller(tester).text, 'Zoë-Anne');
      expect(_button(tester, save).onPressed, isNotNull);
      await tester.tap(find.text(removeName));
      await tester.pump();
      // No confirmation step: the editor is closing and no other dialog
      // opened.
      await tester.pumpAndSettle();
      expect(find.byType(FirstNameEditor), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      expect(prefs.containsKey(firstNameKey), isFalse);
      expect(container.read(firstNameProvider), isNull);
      expect(others(prefs), before);
    });

    testWidgets('Cancel closes without saving the edit or changing anything', (
      tester,
    ) async {
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

    testWidgets('Batch 8: Cancel stays enabled, and still only closes, while '
        'Save is disabled (blank, spaces, too long)', (tester) async {
      for (final text in ['', '   ', 'a' * (maxFirstNameLength + 1)]) {
        final (container, prefs) = await _pumpEditor(
          tester,
          prefsValues: {...otherPrefs, firstNameKey: 'Alex'},
        );
        await tester.enterText(find.byType(TextField), text);
        await tester.pump();
        expect(_button(tester, save).onPressed, isNull, reason: '"$text"');
        expect(_button(tester, cancel).onPressed, isNotNull, reason: '"$text"');
        await tester.tap(find.text(cancel));
        await tester.pumpAndSettle();
        expect(find.byType(FirstNameEditor), findsNothing, reason: '"$text"');
        expect(prefs.getString(firstNameKey), 'Alex', reason: '"$text"');
        expect(container.read(firstNameProvider), 'Alex');
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('Batch 8: tapping the barrier, outside the dialog, closes '
        'without saving the edit or changing anything, and never clears the '
        'name', (tester) async {
      final (container, prefs) = await _pumpEditor(
        tester,
        prefsValues: {...otherPrefs, firstNameKey: 'Alex'},
      );
      final before = others(prefs);
      await tester.enterText(find.byType(TextField), 'Bob');
      await tester.pump();
      // The dialog's surface, its Material, does not cover the tapped point.
      final surface = tester.getRect(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(surface.contains(const Offset(4, 4)), isFalse);
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(find.byType(FirstNameEditor), findsNothing);
      expect(prefs.getString(firstNameKey), 'Alex');
      expect(container.read(firstNameProvider), 'Alex');
      expect(others(prefs), before);
    });
  });

  group('accessibility is unchanged', () {
    for (final scale in const [1.0, 2.0]) {
      testWidgets('${scale}x, a saved name: Remove name, Cancel and Save are '
          'enabled buttons with tap actions, read in the same order; the '
          'barrier is a separate "Cancel", read last', (tester) async {
        final semantics = tester.ensureSemantics();
        await _pumpEditor(
          tester,
          textScale: scale,
          prefsValues: {firstNameKey: 'Alex'},
        );
        final labels = _labelsInTraversalOrder(
          tester.getSemantics(find.text(title)),
        );
        expect(labels, [
          'Alert',
          title,
          supporting,
          'First name',
          removeName,
          'Cancel',
          save,
          'Cancel',
        ]);
        expect(labels.where((l) => l == removeName), hasLength(1));
        expect(labels.where((l) => l == save), hasLength(1));
        for (final action in [removeName, 'Cancel', save]) {
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
              hasEnabledState: true,
              isEnabled: true,
              isFocusable: true,
              hasTapAction: true,
              hasFocusAction: true,
            ),
            reason: action,
          );
        }
        // Batch 8: the barrier is its own node, outside the dialog, read as
        // "Cancel" once, with tap and dismiss and no button role; the
        // visible Cancel is the only "Cancel" text.
        expect(labels.where((l) => l == cancel), hasLength(2));
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text(cancel),
          ),
          findsOneWidget,
        );
        _expectBarrier(tester, cancel);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        semantics.dispose();
      });
    }

    testWidgets('no saved name: Save is a disabled button with no tap action, '
        'there is no Remove name, and the barrier is read as "Cancel" and '
        'dismisses', (tester) async {
      final semantics = tester.ensureSemantics();
      final (_, prefs) = await _pumpEditor(tester);
      final labels = _labelsInTraversalOrder(
        tester.getSemantics(find.text(title)),
      );
      expect(labels, [
        'Alert',
        title,
        supporting,
        'First name',
        'Cancel',
        save,
        'Cancel',
      ]);
      expect(
        tester.getSemantics(
          find.ancestor(of: find.text(save), matching: find.byType(TextButton)),
        ),
        isSemantics(
          label: save,
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
      final node = _expectBarrier(tester, 'Cancel');
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect(find.byType(FirstNameEditor), findsNothing);
      expect(prefs.containsKey(firstNameKey), isFalse);
      semantics.dispose();
    });
  });

  group('a marked catalogue', () {
    testWidgets('no saved name: the disabled Save shows and is read as its own '
        'key’s words; there is no Remove name in any form', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpEditor(tester, delegates: _markedDelegates);
      final dialog = find.byType(AlertDialog);
      Finder inDialog(String text) =>
          find.descendant(of: dialog, matching: find.text(text));
      expect(inDialog(_saveFixture), findsOneWidget);
      expect(inDialog(save), findsNothing);
      expect(inDialog(_removeFixture), findsNothing);
      expect(inDialog(removeName), findsNothing);
      final actions = tester
          .widget<AlertDialog>(dialog)
          .actions!
          .cast<TextButton>();
      expect((actions.last.child! as Text).data, _saveFixture);
      expect(actions.last.onPressed, isNull);
      expect(
        tester.getSemantics(
          find.ancestor(
            of: inDialog(_saveFixture),
            matching: find.byType(TextButton),
          ),
        ),
        isSemantics(label: _saveFixture, isButton: true, isEnabled: false),
      );
      expect(_labelsInTraversalOrder(tester.getSemantics(find.text(title))), [
        'Alert',
        title,
        supporting,
        'First name',
        _cancelFixture,
        _saveFixture,
        _barrierFixture,
      ]);
      semantics.dispose();
    });

    testWidgets('a saved name: each action shows and is read as its own '
        'key’s words, on its own button; since Batch 8 Cancel and the '
        'barrier are read as their own two keys’ words too', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpEditor(
        tester,
        delegates: _markedDelegates,
        prefsValues: {firstNameKey: 'Alex'},
      );
      final dialog = find.byType(AlertDialog);
      Finder inDialog(String text) =>
          find.descendant(of: dialog, matching: find.text(text));
      expect(inDialog(_removeFixture), findsOneWidget);
      expect(inDialog(_saveFixture), findsOneWidget);
      expect(inDialog(removeName), findsNothing);
      expect(inDialog(save), findsNothing);
      expect(inDialog(_cancelFixture), findsOneWidget);
      expect(find.text(cancel), findsNothing);
      // Save is the dialog's last action; Remove name is the quiet button in
      // its content, under the field.
      final alert = tester.widget<AlertDialog>(dialog);
      expect(
        (alert.actions!.cast<TextButton>().last.child! as Text).data,
        _saveFixture,
      );
      final contentButton = tester.widget<TextButton>(
        find.descendant(
          of: find.byWidget(alert.content!),
          matching: find.byType(TextButton),
        ),
      );
      expect((contentButton.child! as Text).data, _removeFixture);
      expect(contentButton.style?.minimumSize?.resolve({}), const Size(0, 48));
      expect(_labelsInTraversalOrder(tester.getSemantics(find.text(title))), [
        'Alert',
        title,
        supporting,
        'First name',
        _removeFixture,
        _cancelFixture,
        _saveFixture,
        _barrierFixture,
      ]);
      for (final label in [_removeFixture, _cancelFixture, _saveFixture]) {
        expect(
          tester.getSemantics(
            find.ancestor(
              of: inDialog(label),
              matching: find.byType(TextButton),
            ),
          ),
          isSemantics(
            label: label,
            isButton: true,
            isEnabled: true,
            hasTapAction: true,
          ),
          reason: label,
        );
      }
      semantics.dispose();
    });

    testWidgets('the marked Remove name still removes the name, and only the '
        'name', (tester) async {
      final (container, prefs) = await _pumpEditor(
        tester,
        delegates: _markedDelegates,
        prefsValues: {firstNameKey: 'Alex', 'theme_mode_v1': 'dark'},
      );
      await tester.tap(find.text(_removeFixture));
      await tester.pumpAndSettle();
      expect(find.byType(FirstNameEditor), findsNothing);
      expect(prefs.containsKey(firstNameKey), isFalse);
      expect(container.read(firstNameProvider), isNull);
      expect(prefs.getString('theme_mode_v1'), 'dark');
    });

    testWidgets('the marked Save still saves the person’s own name, as typed '
        'and never translated', (tester) async {
      final (container, prefs) = await _pumpEditor(
        tester,
        delegates: _markedDelegates,
        prefsValues: {firstNameKey: 'Alex'},
      );
      await tester.enterText(find.byType(TextField), ' Zoë ');
      await tester.pump();
      await tester.tap(find.text(_saveFixture));
      await tester.pumpAndSettle();
      expect(find.byType(FirstNameEditor), findsNothing);
      expect(prefs.getString(firstNameKey), 'Zoë');
      expect(container.read(firstNameProvider), 'Zoë');
    });

    testWidgets('Batch 8: the visible Cancel is the first action, shows and '
        'is read as its own key’s words, is enabled, and is never the '
        'barrier’s words', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpEditor(
        tester,
        delegates: _markedDelegates,
        prefsValues: {firstNameKey: 'Alex'},
      );
      final dialog = find.byType(AlertDialog);
      final actions = tester
          .widget<AlertDialog>(dialog)
          .actions!
          .cast<TextButton>();
      expect(actions, hasLength(2));
      expect((actions.first.child! as Text).data, _cancelFixture);
      expect(actions.first.onPressed, isNotNull);
      expect(
        find.descendant(of: dialog, matching: find.text(_cancelFixture)),
        findsOneWidget,
      );
      // The barrier's words are never shown as text, anywhere.
      expect(find.text(_barrierFixture), findsNothing);
      expect(find.text(cancel), findsNothing);
      expect(
        tester.getSemantics(
          find.ancestor(
            of: find.text(_cancelFixture),
            matching: find.byType(TextButton),
          ),
        ),
        isSemantics(
          label: _cancelFixture,
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      final labels = _labelsInTraversalOrder(
        tester.getSemantics(find.text(title)),
      );
      expect(labels.where((l) => l == _cancelFixture), hasLength(1));
      expect(labels.where((l) => l == _barrierFixture), hasLength(1));
      expect(labels, isNot(contains(cancel)));
      semantics.dispose();
    });

    testWidgets('Batch 8: the barrier is read as its own key’s words, on its '
        'own node outside the dialog, read last, with tap and dismiss, and '
        'never the button’s words', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpEditor(tester, delegates: _markedDelegates);
      final node = _expectBarrier(tester, _barrierFixture);
      expect(node.label, _barrierFixture);
      expect(node.label, isNot(_cancelFixture));
      // The button's words are not on any node outside the dialog.
      expect(
        find
            .bySemanticsLabel(_cancelFixture)
            .evaluate()
            .where(
              (e) => find
                  .ancestor(
                    of: find.byWidget(e.widget),
                    matching: find.byType(AlertDialog),
                  )
                  .evaluate()
                  .isEmpty,
            ),
        isEmpty,
      );
      semantics.dispose();
    });

    testWidgets('Batch 8: the marked Cancel still closes without saving the '
        'edit, and without clearing the name', (tester) async {
      final (container, prefs) = await _pumpEditor(
        tester,
        delegates: _markedDelegates,
        prefsValues: {firstNameKey: 'Alex', 'theme_mode_v1': 'dark'},
      );
      await tester.enterText(find.byType(TextField), 'Bob');
      await tester.pump();
      await tester.tap(find.text(_cancelFixture));
      await tester.pumpAndSettle();
      expect(find.byType(FirstNameEditor), findsNothing);
      expect(prefs.getString(firstNameKey), 'Alex');
      expect(container.read(firstNameProvider), 'Alex');
      expect(prefs.getString('theme_mode_v1'), 'dark');
    });

    for (final action in [SemanticsAction.dismiss, SemanticsAction.tap]) {
      testWidgets('Batch 8: activating the marked barrier (${action.name}) '
          'closes without saving the edit, and without clearing the name', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        final (container, prefs) = await _pumpEditor(
          tester,
          delegates: _markedDelegates,
          prefsValues: {firstNameKey: 'Alex', 'theme_mode_v1': 'dark'},
        );
        await tester.enterText(find.byType(TextField), 'Bob');
        await tester.pump();
        final node = _expectBarrier(tester, _barrierFixture);
        node.owner!.performAction(node.id, action);
        await tester.pumpAndSettle();
        expect(find.byType(FirstNameEditor), findsNothing);
        expect(prefs.getString(firstNameKey), 'Alex');
        expect(container.read(firstNameProvider), 'Alex');
        expect(prefs.getString('theme_mode_v1'), 'dark');
        semantics.dispose();
      });
    }

    testWidgets('Batch 8: at 2.0x with no saved name, the two Cancel owners '
        'keep their own words and places; touch targets still pass', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpEditor(tester, delegates: _markedDelegates, textScale: 2.0);
      expect(tester.takeException(), isNull);
      expect(_labelsInTraversalOrder(tester.getSemantics(find.text(title))), [
        'Alert',
        title,
        supporting,
        'First name',
        _cancelFixture,
        _saveFixture,
        _barrierFixture,
      ]);
      expect(_button(tester, _cancelFixture).onPressed, isNotNull);
      expect(_button(tester, _saveFixture).onPressed, isNull);
      _expectBarrier(tester, _barrierFixture);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });

    testWidgets('opened from the Personal name row: the editor shows the '
        'marked actions; the row itself shows neither', (tester) async {
      await _pumpCard(tester, delegates: _markedDelegates);
      const nameRow = ValueKey('you.name');
      expect(find.textContaining('[fixture]'), findsNothing);
      await tester.tap(find.byKey(nameRow));
      await tester.pumpAndSettle();
      expect(find.text(_saveFixture), findsOneWidget);
      expect(find.text(_removeFixture), findsNothing);
      expect(find.text(save), findsNothing);
      // Batch 8: opened from the row, the editor's Cancel is still its own.
      expect(find.text(_cancelFixture), findsOneWidget);
      expect(find.text(cancel), findsNothing);
    });

    testWidgets('Batch 8: opened from the Personal name row, the barrier is '
        'read as its own key’s words, from the row’s own context', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpCard(tester, delegates: _markedDelegates);
      await tester.tap(find.byKey(const ValueKey('you.name')));
      await tester.pumpAndSettle();
      // Under the router the barrier is read first, before the dialog, in
      // English too and before Batch 8 (evidence: card_traversal_*.txt);
      // only its words changed owner.
      final node = _expectBarrier(tester, _barrierFixture, last: false);
      final labels = _labelsInTraversalOrder(node);
      expect(labels.where((l) => l == _barrierFixture), hasLength(1));
      expect(labels.where((l) => l == _cancelFixture), hasLength(1));
      expect(labels, isNot(contains(cancel)));
      semantics.dispose();
    });

    testWidgets('the first-use question reads neither key: its Continue and '
        'its other copy are unchanged', (tester) async {
      await _pumpQuestion(tester, delegates: _markedDelegates);
      expect(find.byType(FirstNameQuestionPage), findsOneWidget);
      expect(find.textContaining('[fixture]'), findsNothing);
      expect(find.text(FirstNameQuestionPage.question), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('First name'), findsOneWidget);
      expect(find.text(save), findsNothing);
      expect(find.text(removeName), findsNothing);
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

const _removeFixture = '[fixture] remove action';
const _saveFixture = '[fixture] save action';
const _cancelFixture = '[fixture] cancel button';
const _barrierFixture = '[fixture] dismiss barrier';

/// THIRTY's English catalogue with the editor's two action labels (Batch 7)
/// and its Cancel button and barrier label (Batch 8) replaced by distinct
/// `[fixture]` markers — not product copy. A button or barrier reading
/// another's key, or keeping an English literal, shows or speaks the wrong
/// words.
class _Marked extends AppLocalizationsEn {
  @override
  String get firstNameEditorRemoveNameAction => _removeFixture;
  @override
  String get firstNameEditorSaveAction => _saveFixture;
  @override
  String get firstNameEditorCancelAction => _cancelFixture;
  @override
  String get firstNameEditorDismissBarrierLabel => _barrierFixture;
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

/// The dialog barrier's own semantics node, found by [label]: exactly one
/// node with that label whose widget is outside the AlertDialog and inside
/// the route's ModalBarrier. It is not a button, covers the screen, offers
/// tap and dismiss, and is read [last] (under a plain host page) or first
/// (under a router, as You hosts it: the recorded b1dea377 order).
SemanticsNode _expectBarrier(
  WidgetTester tester,
  String label, {
  bool last = true,
}) {
  final outside = find
      .bySemanticsLabel(label)
      .evaluate()
      .where(
        (e) => find
            .ancestor(
              of: find.byWidget(e.widget),
              matching: find.byType(AlertDialog),
            )
            .evaluate()
            .isEmpty,
      )
      .toList();
  expect(outside, hasLength(1), reason: 'one "$label" outside the dialog');
  final widget = find.byWidget(outside.single.widget);
  // The route wraps its ModalBarrier in the Semantics that sorts it last,
  // so the labelled node's widget is the barrier's wrapper (or inside it).
  // (Under a router, the page route's own, unlabelled barrier can also be
  // in range, so this asks for at least one.)
  expect(
    find
            .ancestor(of: widget, matching: find.byType(ModalBarrier))
            .evaluate()
            .length +
        find
            .descendant(of: widget, matching: find.byType(ModalBarrier))
            .evaluate()
            .length,
    greaterThanOrEqualTo(1),
    reason: '"$label" is the modal barrier’s',
  );
  final node = tester.getSemantics(widget);
  expect(
    node,
    isSemantics(
      label: label,
      isButton: false,
      hasTapAction: true,
      hasDismissAction: true,
    ),
  );
  final data = node.getSemanticsData();
  expect(data.hasAction(SemanticsAction.tap), isTrue);
  expect(data.hasAction(SemanticsAction.dismiss), isTrue);
  final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
  expect(node.rect.size, screen, reason: 'the barrier covers the screen');
  final labels = _labelsInTraversalOrder(node);
  expect(
    last ? labels.last : labels.first,
    label,
    reason: last ? 'the barrier is read last' : 'the barrier is read first',
  );
  expect(labels.where((l) => l == label).length, lessThanOrEqualTo(2));
  // The barrier's node is not inside the dialog's semantics subtree.
  final dialogNode = tester.getSemantics(find.byType(FirstNameEditor));
  var parent = node.parent;
  while (parent != null) {
    expect(parent, isNot(same(dialogNode)), reason: 'outside the dialog');
    parent = parent.parent;
  }
  return node;
}

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
