import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'b8_review_pack_test.dart'
    show
        CatalogueMessage,
        Pack,
        catalogueMessages,
        englishCatalogue,
        fnv64,
        surfaces;
import 'support/live_copy.dart';

/// G-02 Batch 1 review-coverage correction: copy that moves from Dart into
/// THIRTY's English catalogue stays in the founder's B8 review pack
/// (section I), and the pack's deterministic hash and manifest catch every
/// catalogue change. Fixture catalogues are marked "[fixture]"; none of it
/// is product copy.
void main() {
  /// The pack's section I.
  String sectionI(String body) =>
      body.substring(body.indexOf('## I. English catalogue (ARB)'));

  /// Everything before section I: the Dart-derived pack (A–H).
  String beforeI(String body) =>
      body.substring(0, body.indexOf('## I. English catalogue (ARB)'));

  final real = Pack();
  final realBody = real.build();

  group('the real catalogue', () {
    test('every user-facing English message is listed with its key, text, '
        'catalogue path, description and placeholders', () {
      final messages = catalogueMessages(englishCatalogue);
      final raw =
          jsonDecode(File(englishCatalogue).readAsStringSync())
              as Map<String, Object?>;
      expect(
        [for (final m in messages) m.key],
        [
          for (final k in raw.keys)
            if (!k.startsWith('@')) k,
        ],
        reason: 'every message key, and no metadata entry',
      );
      final section = sectionI(realBody);
      for (final CatalogueMessage(:key, :text, :description, :placeholders)
          in messages) {
        final entry = section.substring(section.indexOf('- **`$key`**: '));
        expect(entry, startsWith('- **`$key`**: $text\n'), reason: key);
        expect(entry, contains('  - Source: `$englishCatalogue`'));
        expect(description, isNotNull, reason: key);
        expect(entry, contains('  - Description: $description'));
        for (final name in placeholders.keys) {
          expect(entry, contains('`{$name}` ('), reason: '$key {$name}');
        }
      }
      // Metadata is never listed as copy.
      expect(section, isNot(contains('`@')));
      expect(section, isNot(contains('@@locale')));
    });

    test('Batch 1 is visible: brandName, youAboutSectionTitle and '
        'youAboutVersion, with its placeholder documented', () {
      final section = sectionI(realBody);
      expect(section, contains('- **`brandName`**: THIRTY\n'));
      expect(section, contains('- **`youAboutSectionTitle`**: About\n'));
      expect(section, contains('- **`youAboutVersion`**: Version {version}\n'));
      expect(section, contains('  - Placeholders: `{version}` (type: String)'));
    });

    test('Batch 2 is visible: the You page heading, subtitle and the '
        'Personal, Preferences and Data & privacy headings, each with its '
        'source and description, after Batch 1 and with no placeholder', () {
      const batch2 = <String, String>{
        'youPageTitle': 'You',
        'youPageSubtitle': 'Your space in THIRTY.',
        'youPersonalSectionTitle': 'Personal',
        'youPreferencesSectionTitle': 'Preferences',
        'youDataPrivacySectionTitle': 'Data & privacy',
      };
      final section = sectionI(realBody);
      final byKey = {for (final m in real.messages) m.key: m};
      var previous = section.indexOf('- **`youAboutVersion`**: ');
      expect(previous, isNonNegative, reason: 'Batch 1 still listed');
      for (final MapEntry(:key, :value) in batch2.entries) {
        final at = section.indexOf('- **`$key`**: $value\n');
        expect(at, greaterThan(previous), reason: '$key, in catalogue order');
        previous = at;
        final next = section.indexOf('\n- **`', at + 1);
        final entry = section.substring(at, next < 0 ? null : next);
        expect(entry, contains('  - Source: `$englishCatalogue`'));
        expect(
          entry,
          contains('  - Description: ${byKey[key]!.description}'),
          reason: key,
        );
        expect(byKey[key]!.description, startsWith('You tab: '));
        expect(byKey[key]!.placeholders, isEmpty, reason: key);
        expect(entry, isNot(contains('Placeholders:')), reason: key);
      }
      final manifest =
          jsonDecode(
                File(
                  'artifacts/v2_phase_d2/b8/MANIFEST.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      expect(
        manifest['catalogueKeys'],
        containsAllInOrder(['youAboutVersion', ...batch2.keys]),
      );
    });

    test('Batch 3 is visible: the You Memory and History rows, each with '
        'its source and description, after Batch 2 and with no '
        'placeholder; the same words elsewhere stay in the Dart-derived '
        'review', () {
      const batch3 = <String, String>{
        'youPersonalMemoryTitle': 'What THIRTY remembers',
        'youPersonalMemoryDetail': 'What you’ve told it, need by need',
        'youPersonalHistoryTitle': 'Your Circles',
        'youPersonalHistoryDetail': 'Every Circle, as it happened',
      };
      final section = sectionI(realBody);
      final byKey = {for (final m in real.messages) m.key: m};
      var previous = section.indexOf('- **`youDataPrivacySectionTitle`**: ');
      expect(previous, isNonNegative, reason: 'Batch 2 still listed');
      for (final MapEntry(:key, :value) in batch3.entries) {
        final at = section.indexOf('- **`$key`**: $value\n');
        expect(at, greaterThan(previous), reason: '$key, in catalogue order');
        previous = at;
        final next = section.indexOf('\n- **`', at + 1);
        final entry = section.substring(at, next < 0 ? null : next);
        expect(entry, contains('  - Source: `$englishCatalogue`'));
        expect(
          entry,
          contains('  - Description: ${byKey[key]!.description}'),
          reason: key,
        );
        expect(byKey[key]!.description, startsWith('You tab, Personal '));
        expect(byKey[key]!.placeholders, isEmpty, reason: key);
        expect(entry, isNot(contains('Placeholders:')), reason: key);
      }
      // Batch 3 ends the accepted twelve; only Batch 4's four, then Batch
      // 5's two, then Batch 6's two, then Batch 7's two, then Batch 8's
      // two, follow (next tests).
      expect(real.messages, hasLength(24));
      // The one catalogue message that adds to H's curly-apostrophe count.
      expect(
        [
          for (final m in real.messages)
            if (m.text.contains('’')) m.key,
        ],
        ['youPersonalMemoryDetail'],
      );
      final manifest =
          jsonDecode(
                File(
                  'artifacts/v2_phase_d2/b8/MANIFEST.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      expect(
        manifest['catalogueKeys'],
        containsAllInOrder(['youDataPrivacySectionTitle', ...batch3.keys]),
      );
      expect(manifest['catalogueMessagesListed'], 24);
      // Only the card's own Dart copy left the review; the same words in
      // other files are still listed where they live.
      final d = realBody.substring(
        realBody.indexOf('## D. You'),
        realBody.indexOf('## E. '),
      );
      final card = d.substring(
        d.indexOf(
          '**`features/settings/presentation/widgets/'
          'you_personal_card.dart`**',
        ),
      );
      final cardBlock = card.substring(0, card.indexOf('\n**`', 1));
      for (final value in batch3.values) {
        expect(cardBlock, isNot(contains('- $value\n')), reason: value);
      }
      // The name row's prompt left with Batch 5 (its test below); the
      // card's Yours copy is still listed.
      expect(cardBlock, isNot(contains('- Add your name\n')));
      expect(cardBlock, contains('- Circles you keep appear here\n'));
      final memoryPage = d.substring(
        d.indexOf('**`features/home/presentation/memory_page.dart`**'),
      );
      expect(memoryPage, contains('- What THIRTY remembers\n'));
      final c = realBody.substring(
        realBody.indexOf('## C. Insights'),
        realBody.indexOf('## D. You'),
      );
      expect(c, contains('- Your Circles\n'));
    });

    test('Batch 4 is visible: the You Appearance title and the three theme '
        'labels, each with its source and description, after Batch 3 and '
        'with no placeholder; the Theme group label stays in the '
        'Dart-derived review, in D and in G', () {
      const batch4 = <String, String>{
        'youAppearanceTitle': 'Appearance',
        'themeModeSystem': 'System',
        'themeModeLight': 'Light',
        'themeModeDark': 'Dark',
      };
      const accepted = [
        'brandName',
        'youAboutSectionTitle',
        'youAboutVersion',
        'youPageTitle',
        'youPageSubtitle',
        'youPersonalSectionTitle',
        'youPreferencesSectionTitle',
        'youDataPrivacySectionTitle',
        'youPersonalMemoryTitle',
        'youPersonalMemoryDetail',
        'youPersonalHistoryTitle',
        'youPersonalHistoryDetail',
      ];
      final section = sectionI(realBody);
      final byKey = {for (final m in real.messages) m.key: m};
      var previous = section.indexOf('- **`youPersonalHistoryDetail`**: ');
      expect(previous, isNonNegative, reason: 'Batch 3 still listed');
      for (final MapEntry(:key, :value) in batch4.entries) {
        final at = section.indexOf('- **`$key`**: $value\n');
        expect(at, greaterThan(previous), reason: '$key, in catalogue order');
        previous = at;
        final next = section.indexOf('\n- **`', at + 1);
        final entry = section.substring(at, next < 0 ? null : next);
        expect(entry, contains('  - Source: `$englishCatalogue`'));
        expect(
          entry,
          contains('  - Description: ${byKey[key]!.description}'),
          reason: key,
        );
        expect(byKey[key]!.text, value, reason: key);
        expect(byKey[key]!.description, startsWith('You tab, '));
        // Each names the other half of the row: the title its choices, each
        // choice its title.
        expect(
          byKey[key]!.description,
          contains(
            key == 'youAppearanceTitle'
                ? 'themeModeSystem'
                : 'youAppearanceTitle',
          ),
          reason: key,
        );
        expect(byKey[key]!.placeholders, isEmpty, reason: key);
        expect(entry, isNot(contains('Placeholders:')), reason: key);
      }
      for (final key in batch4.keys.skip(1)) {
        expect(byKey[key]!.description, contains('Theme'), reason: key);
      }
      // Only Batch 5's two, then Batch 6's two, then Batch 7's two, then
      // Batch 8's two, follow (next tests).
      const batch5 = ['youPersonalNameTitle', 'youPersonalNameAddPrompt'];
      const batch6 = ['firstNameEditorTitle', 'firstNameEditorSupporting'];
      const batch7 = [
        'firstNameEditorRemoveNameAction',
        'firstNameEditorSaveAction',
      ];
      const batch8 = [
        'firstNameEditorCancelAction',
        'firstNameEditorDismissBarrierLabel',
      ];
      expect(
        [for (final m in real.messages) m.key],
        [
          ...accepted,
          ...batch4.keys,
          ...batch5,
          ...batch6,
          ...batch7,
          ...batch8,
        ],
      );
      // Batch 4 adds no apostrophe of either kind, so H is unchanged.
      for (final value in batch4.values) {
        expect(value, isNot(contains('’')));
        expect(value, isNot(contains("'")));
      }
      final manifest =
          jsonDecode(
                File(
                  'artifacts/v2_phase_d2/b8/MANIFEST.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      expect(manifest['catalogueKeys'], [
        ...accepted,
        ...batch4.keys,
        ...batch5,
        ...batch6,
        ...batch7,
        ...batch8,
      ]);
      expect(manifest['catalogueMessagesListed'], 24);
      expect(manifest['founderFlags'], 4);
      // Only the four words left the Dart-derived review; the theme
      // selector's group label and the card's other copy stay listed.
      final d = realBody.substring(
        realBody.indexOf('## D. You'),
        realBody.indexOf('## E. '),
      );
      String block(String file) {
        final from = d.substring(d.indexOf('**`$file`**'));
        return from.substring(0, from.indexOf('\n**`', 1));
      }

      final choice = block(
        'features/settings/presentation/widgets/theme_mode_choice.dart',
      );
      expect(choice, contains('- Theme\n'));
      for (final value in ['System', 'Light', 'Dark']) {
        expect(choice, isNot(contains('- $value\n')), reason: value);
      }
      final card = block(
        'features/settings/presentation/widgets/you_preferences_card.dart',
      );
      expect(card, isNot(contains('- Appearance\n')));
      expect(card, contains('- Daily reminder\n'));
      expect(card, contains('- Change time\n'));
      final g = realBody.substring(
        realBody.indexOf('## G. '),
        realBody.indexOf('## H. '),
      );
      expect(g, contains('\n- Theme\n'));
    });

    test('Batch 5 is visible: the You name row title and its add-name '
        'prompt, each with its source and description, after Batch 4 and '
        'with no placeholder; the first-name editor keeps its own copy, '
        'separate from the row’s keys', () {
      const batch5 = <String, String>{
        'youPersonalNameTitle': 'Your name',
        'youPersonalNameAddPrompt': 'Add your name',
      };
      const accepted = [
        'brandName',
        'youAboutSectionTitle',
        'youAboutVersion',
        'youPageTitle',
        'youPageSubtitle',
        'youPersonalSectionTitle',
        'youPreferencesSectionTitle',
        'youDataPrivacySectionTitle',
        'youPersonalMemoryTitle',
        'youPersonalMemoryDetail',
        'youPersonalHistoryTitle',
        'youPersonalHistoryDetail',
        'youAppearanceTitle',
        'themeModeSystem',
        'themeModeLight',
        'themeModeDark',
      ];
      final section = sectionI(realBody);
      final byKey = {for (final m in real.messages) m.key: m};
      var previous = section.indexOf('- **`themeModeDark`**: ');
      expect(previous, isNonNegative, reason: 'Batch 4 still listed');
      for (final MapEntry(:key, :value) in batch5.entries) {
        final at = section.indexOf('- **`$key`**: $value\n');
        expect(at, greaterThan(previous), reason: '$key, in catalogue order');
        previous = at;
        final next = section.indexOf('\n- **`', at + 1);
        final entry = section.substring(at, next < 0 ? null : next);
        expect(entry, contains('  - Source: `$englishCatalogue`'));
        expect(
          entry,
          contains('  - Description: ${byKey[key]!.description}'),
          reason: key,
        );
        expect(byKey[key]!.text, value, reason: key);
        expect(
          byKey[key]!.description,
          startsWith('You tab, Personal section: '),
        );
        expect(byKey[key]!.description!.length, greaterThan(200));
        expect(byKey[key]!.placeholders, isEmpty, reason: key);
        expect(entry, isNot(contains('Placeholders:')), reason: key);
      }
      expect(
        byKey['youPersonalNameTitle']!.description,
        contains('youPersonalNameAddPrompt'),
      );
      expect(
        byKey['youPersonalNameAddPrompt']!.description,
        contains('youPersonalNameTitle'),
      );
      // Only Batch 6's two, then Batch 7's two, then Batch 8's two, the
      // first-name editor's own, follow (next tests).
      const batch6 = ['firstNameEditorTitle', 'firstNameEditorSupporting'];
      const batch7 = [
        'firstNameEditorRemoveNameAction',
        'firstNameEditorSaveAction',
      ];
      const batch8 = [
        'firstNameEditorCancelAction',
        'firstNameEditorDismissBarrierLabel',
      ];
      expect(real.messages, hasLength(24));
      expect(
        [for (final m in real.messages) m.key],
        [...accepted, ...batch5.keys, ...batch6, ...batch7, ...batch8],
      );
      // Batch 5 adds no apostrophe of either kind, so H is unchanged.
      for (final value in batch5.values) {
        expect(value, isNot(contains('’')));
        expect(value, isNot(contains("'")));
      }
      final manifest =
          jsonDecode(
                File(
                  'artifacts/v2_phase_d2/b8/MANIFEST.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      expect(manifest['catalogueKeys'], [
        ...accepted,
        ...batch5.keys,
        ...batch6,
        ...batch7,
        ...batch8,
      ]);
      expect(manifest['catalogueMessagesListed'], 24);
      expect(manifest['founderFlags'], 4);
      // Only the card's two words left the Dart-derived review: its Yours
      // copy stays listed. The first-name editor's own title and supporting
      // line left with Batch 6, and its Remove name with Batch 7 (next
      // tests); its remaining copy is still listed where it lives.
      final d = realBody.substring(
        realBody.indexOf('## D. You'),
        realBody.indexOf('## E. '),
      );
      String block(String file) {
        final from = d.substring(d.indexOf('**`$file`**'));
        return from.substring(0, from.indexOf('\n**`', 1));
      }

      final card = block(
        'features/settings/presentation/widgets/you_personal_card.dart',
      );
      expect(card, isNot(contains('- Your name')));
      expect(card, isNot(contains('- Add your name')));
      expect(card, contains('- Circles you keep appear here\n'));
      expect(card, contains('- 1 Circle you kept\n'));
      expect(card, contains(r'- $kept Circles you kept'));
      final editor = block(
        'features/settings/presentation/widgets/first_name_editor.dart',
      );
      expect(editor, contains('- First name\n'));
      expect(editor, isNot(contains('- Remove name\n')));
      expect(d, isNot(contains('- Add your name')));
    });

    test('Batch 6 is visible: the first-name editor’s title and supporting '
        'line, each with its source and description, after Batch 5 and '
        'with no placeholder; they leave the editor’s Dart-derived '
        'listing, and its other copy stays listed', () {
      const batch6 = <String, String>{
        'firstNameEditorTitle': 'Your name',
        'firstNameEditorSupporting':
            'Used only to make THIRTY feel a little more personal.',
      };
      // Only Batch 7's two, the editor's actions, then Batch 8's two, its
      // Cancel button and barrier label, follow (next tests).
      const batch7 = [
        'firstNameEditorRemoveNameAction',
        'firstNameEditorSaveAction',
      ];
      const batch8 = [
        'firstNameEditorCancelAction',
        'firstNameEditorDismissBarrierLabel',
      ];
      const accepted = [
        'brandName',
        'youAboutSectionTitle',
        'youAboutVersion',
        'youPageTitle',
        'youPageSubtitle',
        'youPersonalSectionTitle',
        'youPreferencesSectionTitle',
        'youDataPrivacySectionTitle',
        'youPersonalMemoryTitle',
        'youPersonalMemoryDetail',
        'youPersonalHistoryTitle',
        'youPersonalHistoryDetail',
        'youAppearanceTitle',
        'themeModeSystem',
        'themeModeLight',
        'themeModeDark',
        'youPersonalNameTitle',
        'youPersonalNameAddPrompt',
      ];
      final section = sectionI(realBody);
      final byKey = {for (final m in real.messages) m.key: m};
      var previous = section.indexOf('- **`youPersonalNameAddPrompt`**: ');
      expect(previous, isNonNegative, reason: 'Batch 5 still listed');
      for (final MapEntry(:key, :value) in batch6.entries) {
        final at = section.indexOf('- **`$key`**: $value\n');
        expect(at, greaterThan(previous), reason: '$key, in catalogue order');
        previous = at;
        final next = section.indexOf('\n- **`', at + 1);
        final entry = section.substring(at, next < 0 ? null : next);
        expect(entry, contains('  - Source: `$englishCatalogue`'));
        expect(
          entry,
          contains('  - Description: ${byKey[key]!.description}'),
          reason: key,
        );
        expect(byKey[key]!.text, value, reason: key);
        expect(byKey[key]!.description, startsWith('First-name editor '));
        expect(byKey[key]!.description!.length, greaterThan(200));
        expect(byKey[key]!.placeholders, isEmpty, reason: key);
        expect(entry, isNot(contains('Placeholders:')), reason: key);
      }
      // Each names the other half of the dialog's header; the title also
      // names the row's key it must not be confused with.
      expect(
        byKey['firstNameEditorTitle']!.description,
        contains('firstNameEditorSupporting'),
      );
      expect(
        byKey['firstNameEditorTitle']!.description,
        contains('youPersonalNameTitle'),
      );
      expect(
        byKey['firstNameEditorSupporting']!.description,
        contains('firstNameEditorTitle'),
      );
      expect(real.messages, hasLength(24));
      expect(
        [for (final m in real.messages) m.key],
        [...accepted, ...batch6.keys, ...batch7, ...batch8],
      );
      // Batch 6 adds no apostrophe of either kind, so H is unchanged.
      for (final value in batch6.values) {
        expect(value, isNot(contains('’')));
        expect(value, isNot(contains("'")));
      }
      final manifest =
          jsonDecode(
                File(
                  'artifacts/v2_phase_d2/b8/MANIFEST.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      expect(manifest['catalogueKeys'], [
        ...accepted,
        ...batch6.keys,
        ...batch7,
        ...batch8,
      ]);
      expect(manifest['catalogueMessagesListed'], 24);
      expect(manifest['founderFlags'], 4);
      // Only the editor's two words left the Dart-derived review; its field
      // label and its length message stay listed ("Remove name" left with
      // Batch 7, next test), and the first-use question's own copy is
      // unchanged.
      final d = realBody.substring(
        realBody.indexOf('## D. You'),
        realBody.indexOf('## E. '),
      );
      String block(String file) {
        final from = d.substring(d.indexOf('**`$file`**'));
        return from.substring(0, from.indexOf('\n**`', 1));
      }

      final editor = block(
        'features/settings/presentation/widgets/first_name_editor.dart',
      );
      for (final value in batch6.values) {
        expect(editor, isNot(contains('- $value\n')), reason: value);
        expect(d, isNot(contains('- $value\n')), reason: value);
      }
      expect(editor, isNot(contains('- Your name')));
      expect(editor, contains('- First name\n'));
      expect(
        editor,
        contains(r'- Use $maxFirstNameLength characters or fewer.'),
      );
      expect(editor, isNot(contains('- Remove name\n')));
      final question = block(
        'features/settings/presentation/first_name_question_page.dart',
      );
      expect(question, contains('- What should we call you?\n'));
      expect(
        question,
        contains(
          '- Your first name stays on this device and helps THIRTY feel a '
          'little more personal.\n',
        ),
      );
      expect(question, contains('- Skip for now\n'));
      final card = block(
        'features/settings/presentation/widgets/you_personal_card.dart',
      );
      expect(card, isNot(contains('- Your name')));
      expect(card, isNot(contains('- Add your name')));
      expect(card, contains('- Circles you keep appear here\n'));
    });

    test('Batch 7 is visible: the first-name editor’s Remove name and Save '
        'actions, each with its source and description, after Batch 6 and '
        'with no placeholder; they leave the Dart-derived review, the kept '
        'Circle’s own Save and Cancel stay listed, and the editor’s other '
        'copy stays listed', () {
      const batch7 = <String, String>{
        'firstNameEditorRemoveNameAction': 'Remove name',
        'firstNameEditorSaveAction': 'Save',
      };
      const batch8 = [
        'firstNameEditorCancelAction',
        'firstNameEditorDismissBarrierLabel',
      ];
      const accepted = [
        'brandName',
        'youAboutSectionTitle',
        'youAboutVersion',
        'youPageTitle',
        'youPageSubtitle',
        'youPersonalSectionTitle',
        'youPreferencesSectionTitle',
        'youDataPrivacySectionTitle',
        'youPersonalMemoryTitle',
        'youPersonalMemoryDetail',
        'youPersonalHistoryTitle',
        'youPersonalHistoryDetail',
        'youAppearanceTitle',
        'themeModeSystem',
        'themeModeLight',
        'themeModeDark',
        'youPersonalNameTitle',
        'youPersonalNameAddPrompt',
        'firstNameEditorTitle',
        'firstNameEditorSupporting',
      ];
      final section = sectionI(realBody);
      final byKey = {for (final m in real.messages) m.key: m};
      var previous = section.indexOf('- **`firstNameEditorSupporting`**: ');
      expect(previous, isNonNegative, reason: 'Batch 6 still listed');
      for (final MapEntry(:key, :value) in batch7.entries) {
        final at = section.indexOf('- **`$key`**: $value\n');
        expect(at, greaterThan(previous), reason: '$key, in catalogue order');
        previous = at;
        final next = section.indexOf('\n- **`', at + 1);
        final entry = section.substring(at, next < 0 ? null : next);
        expect(entry, contains('  - Source: `$englishCatalogue`'));
        expect(
          entry,
          contains('  - Description: ${byKey[key]!.description}'),
          reason: key,
        );
        expect(byKey[key]!.text, value, reason: key);
        expect(byKey[key]!.description, startsWith('First-name editor '));
        expect(byKey[key]!.description!.length, greaterThan(200));
        expect(byKey[key]!.placeholders, isEmpty, reason: key);
        expect(entry, isNot(contains('Placeholders:')), reason: key);
      }
      // Only Batch 8's two follow Save (next test).
      expect(
        section.indexOf('\n- **`', previous + 1),
        section.indexOf('\n- **`firstNameEditorCancelAction`**: '),
        reason: 'Batch 8 follows Batch 7',
      );
      // Each says what it is not: Remove name is neither a data deletion
      // nor the row's prompt; Save is neither onboarding's Continue nor a
      // status message.
      final remove = byKey['firstNameEditorRemoveNameAction']!.description!;
      expect(remove, contains('only when a first name already exists'));
      expect(remove, contains('does not delete Circle history'));
      expect(remove, contains('no destructive confirmation dialog'));
      expect(remove, contains('youPersonalNameAddPrompt'));
      final save = byKey['firstNameEditorSaveAction']!.description!;
      expect(save, contains('disabled when the entered value is blank'));
      expect(save, contains('separately labelled Continue'));
      expect(save, contains('not a status message'));
      expect(real.messages, hasLength(24));
      expect(
        [for (final m in real.messages) m.key],
        [...accepted, ...batch7.keys, ...batch8],
      );
      // Batch 7 adds no apostrophe of either kind, so H is unchanged.
      for (final value in batch7.values) {
        expect(value, isNot(contains('’')));
        expect(value, isNot(contains("'")));
      }
      final manifest =
          jsonDecode(
                File(
                  'artifacts/v2_phase_d2/b8/MANIFEST.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      expect(manifest['catalogueKeys'], [
        ...accepted,
        ...batch7.keys,
        ...batch8,
      ]);
      expect(manifest['catalogueMessagesListed'], 24);
      expect(manifest['founderFlags'], 4);
      final d = realBody.substring(
        realBody.indexOf('## D. You'),
        realBody.indexOf('## E. '),
      );
      String block(String file) {
        final from = d.substring(d.indexOf('**`$file`**'));
        return from.substring(0, from.indexOf('\n**`', 1));
      }

      // The editor's Remove name left the Dart-derived review; its field
      // label and length message stay listed.
      final editor = block(
        'features/settings/presentation/widgets/first_name_editor.dart',
      );
      expect(editor, isNot(contains('- Remove name')));
      expect(d, isNot(contains('- Remove name')));
      expect(editor, contains('- First name\n'));
      expect(
        editor,
        contains(r'- Use $maxFirstNameLength characters or fewer.'),
      );
      // D lists each text once, under the first file using it, with its
      // count in the section. The editor's Save was counted in the kept
      // Circle page's "Save (×2)"; only the kept Circle's own Save is left.
      // Since Batch 8 the editor's Cancel button and barrier are in the
      // catalogue too, so only the kept Circle's own two count in
      // "Cancel (×2)" (the Batch 8 test below).
      final kept = block(
        'features/personal_circle/presentation/kept_circle_page.dart',
      );
      expect(kept, contains('\n- Save\n'));
      expect(kept, isNot(contains('- Save *(×')));
      expect(kept, contains('\n- Cancel *(×2)*\n'));
      expect(
        d.split('\n').where((l) => l == '- Save' || l.startsWith('- Save *(')),
        hasLength(1),
      );
      // The first-use question's own copy, Continue included, is unchanged.
      final question = block(
        'features/settings/presentation/first_name_question_page.dart',
      );
      expect(question, contains('- What should we call you?\n'));
      expect(question, contains('- Continue *(×2)*\n'));
      expect(question, contains('- Skip for now\n'));
      // The name row's Batch 5 copy stays out of D.
      final card = block(
        'features/settings/presentation/widgets/you_personal_card.dart',
      );
      expect(card, isNot(contains('- Add your name')));
      expect(card, contains('- Circles you keep appear here\n'));
    });

    test('Batch 8 is visible: the first-name editor’s Cancel button and its '
        'barrier label, two keys with the same English, each with its source '
        'and description, after Batch 7 and with no placeholder; they leave '
        'the Dart-derived review, and only the kept Circle’s own two Cancel '
        'stay listed', () {
      const batch8 = <String, String>{
        'firstNameEditorCancelAction': 'Cancel',
        'firstNameEditorDismissBarrierLabel': 'Cancel',
      };
      const accepted = [
        'brandName',
        'youAboutSectionTitle',
        'youAboutVersion',
        'youPageTitle',
        'youPageSubtitle',
        'youPersonalSectionTitle',
        'youPreferencesSectionTitle',
        'youDataPrivacySectionTitle',
        'youPersonalMemoryTitle',
        'youPersonalMemoryDetail',
        'youPersonalHistoryTitle',
        'youPersonalHistoryDetail',
        'youAppearanceTitle',
        'themeModeSystem',
        'themeModeLight',
        'themeModeDark',
        'youPersonalNameTitle',
        'youPersonalNameAddPrompt',
        'firstNameEditorTitle',
        'firstNameEditorSupporting',
        'firstNameEditorRemoveNameAction',
        'firstNameEditorSaveAction',
      ];
      final section = sectionI(realBody);
      final byKey = {for (final m in real.messages) m.key: m};
      var previous = section.indexOf('- **`firstNameEditorSaveAction`**: ');
      expect(previous, isNonNegative, reason: 'Batch 7 still listed');
      for (final MapEntry(:key, :value) in batch8.entries) {
        final at = section.indexOf('- **`$key`**: $value\n');
        expect(at, greaterThan(previous), reason: '$key, in catalogue order');
        previous = at;
        final next = section.indexOf('\n- **`', at + 1);
        final entry = section.substring(at, next < 0 ? null : next);
        expect(entry, contains('  - Source: `$englishCatalogue`'));
        expect(
          entry,
          contains('  - Description: ${byKey[key]!.description}'),
          reason: key,
        );
        expect(byKey[key]!.text, value, reason: key);
        expect(byKey[key]!.description, startsWith('First-name editor '));
        expect(byKey[key]!.description!.length, greaterThan(200));
        expect(byKey[key]!.placeholders, isEmpty, reason: key);
        expect(entry, isNot(contains('Placeholders:')), reason: key);
      }
      // The barrier label is the catalogue's last entry.
      expect(
        section.indexOf('\n- **`', previous + 1),
        -1,
        reason: 'nothing follows Batch 8',
      );
      // Each names the other, and says which one it is: the visible button,
      // or the barrier's accessibility label that dismisses.
      final button = byKey['firstNameEditorCancelAction']!.description!;
      expect(button, contains('visible Cancel button'));
      expect(button, contains('placed before Save'));
      expect(button, contains('firstNameEditorDismissBarrierLabel'));
      expect(button, contains('must remain independently translatable'));
      final barrier = byKey['firstNameEditorDismissBarrierLabel']!.description!;
      expect(barrier, contains('modal dialog barrier'));
      expect(barrier, contains('not an additional visible button'));
      expect(barrier, contains('without saving any edits'));
      expect(barrier, contains('firstNameEditorCancelAction'));
      expect(real.messages, hasLength(24));
      expect(
        [for (final m in real.messages) m.key],
        [...accepted, ...batch8.keys],
      );
      // Batch 8 adds no apostrophe of either kind, so H is unchanged.
      for (final value in batch8.values) {
        expect(value, isNot(contains('’')));
        expect(value, isNot(contains("'")));
      }
      final manifest =
          jsonDecode(
                File(
                  'artifacts/v2_phase_d2/b8/MANIFEST.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      expect(manifest['catalogueKeys'], [...accepted, ...batch8.keys]);
      expect(manifest['catalogueMessagesListed'], 24);
      expect(manifest['founderFlags'], 4);
      final d = realBody.substring(
        realBody.indexOf('## D. You'),
        realBody.indexOf('## E. '),
      );
      String block(String file) {
        final from = d.substring(d.indexOf('**`$file`**'));
        return from.substring(0, from.indexOf('\n**`', 1));
      }

      // D lists each text once, under the first file using it, with its
      // count in the section. The editor's Cancel button and barrier label
      // were counted in the kept Circle page's "Cancel (×4)"; only the kept
      // Circle's own button and barrier are left, "Cancel (×2)", in the same
      // place. Nothing else lists Cancel in D.
      final kept = block(
        'features/personal_circle/presentation/kept_circle_page.dart',
      );
      expect(kept, contains('\n- Rename *(×4)*\n- Cancel *(×2)*\n- Save\n'));
      expect(kept, isNot(contains('- Cancel *(×4)*')));
      expect(
        d
            .split('\n')
            .where((l) => l == '- Cancel' || l.startsWith('- Cancel *(')),
        ['- Cancel *(×2)*'],
      );
      // The editor's block keeps its two remaining Dart-derived texts, and
      // no Cancel.
      final editor = block(
        'features/settings/presentation/widgets/first_name_editor.dart',
      );
      expect(
        editor,
        '**`features/settings/presentation/widgets/first_name_editor.dart`**'
        '\n\n- First name\n- Use \$maxFirstNameLength characters or fewer.\n',
      );
      // The first-use question's own copy is unchanged.
      final question = block(
        'features/settings/presentation/first_name_question_page.dart',
      );
      expect(question, contains('- What should we call you?\n'));
      expect(question, contains('- Continue *(×2)*\n'));
      expect(question, contains('- Skip for now\n'));
      // F and G still list Cancel once: the kept Circle's own text and
      // barrier label remain, and the catalogue's two identical values do
      // not add a line.
      String between(String from, String to) =>
          realBody.substring(realBody.indexOf(from), realBody.indexOf(to));
      for (final s in [
        between('## F. ', '## G. '),
        between('## G. ', '## H. '),
      ]) {
        expect(s.split('\n').where((l) => l == '- Cancel'), hasLength(1));
      }
    });

    test('the Dart-derived review is unchanged: every surface string is '
        'still listed, and the catalogue adds only section I', () {
      for (final s in real.strings) {
        if (!surfaces.any((x) => x.$3.any(s.file.startsWith))) continue;
        expect(realBody, contains(s.text), reason: '${s.file}: ${s.text}');
      }
      final dir = Directory.systemTemp.createTempSync('thirty_b8_cat_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final empty = File('${dir.path}/app_en.arb')
        ..writeAsStringSync(jsonEncode({'@@locale': 'en'}));
      final without = Pack(catalogue: empty.path).build();
      // By design H's mixed-apostrophes flag also counts catalogue messages
      // that use ’ (see "a lapse line or a straight apostrophe in the
      // catalogue reaches the cross-surface views" below). So only that one
      // number may differ, by exactly the catalogue's messages using ’;
      // everything else before I stays byte for byte.
      final curlyFlag = RegExp(
        r'^(- Apostrophes are mixed: .* while )(\d+)( use ’\.)$',
        multiLine: true,
      );
      RegExpMatch flagIn(String body) {
        final flags = curlyFlag.allMatches(beforeI(body)).toList();
        expect(flags, hasLength(1), reason: 'the flag, exactly once');
        return flags.single;
      }

      String normalized(String body) => beforeI(
        body,
      ).replaceFirstMapped(curlyFlag, (m) => '${m[1]}<count>${m[3]}');
      final curlyInCatalogue = real.messages
          .where((m) => m.text.contains('’'))
          .length;
      expect(
        int.parse(flagIn(realBody)[2]!),
        int.parse(flagIn(without)[2]!) + curlyInCatalogue,
      );
      expect(normalized(realBody), normalized(without));
      expect(sectionI(without), contains('NONE'));
    });

    test('the manifest names the catalogue and its keys, and counts the '
        'production Dart files actually scanned', () {
      final manifest =
          jsonDecode(
                File(
                  'artifacts/v2_phase_d2/b8/MANIFEST.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      expect(manifest['productionFilesScanned'], productionFiles().length);
      expect(
        productionFiles().where((f) => f.startsWith('lib/l10n/gen/')),
        isEmpty,
        reason: 'generated code is never counted or listed as copy',
      );
      expect(manifest['catalogueFilesInPack'], [englishCatalogue]);
      expect(manifest['catalogueKeys'], [for (final m in real.messages) m.key]);
      expect(manifest['catalogueMessagesListed'], real.messages.length);
      expect(manifest['contentHashFnv64'], fnv64(realBody));
    });
  });

  group('the hash catches every catalogue change', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('thirty_b8_cat_'));
    tearDown(() => dir.deleteSync(recursive: true));

    final base = <String, Object?>{
      '@@locale': 'en',
      'fixtureTitle': '[fixture] A title',
      '@fixtureTitle': {'description': '[fixture] a heading'},
      'fixtureCount': '[fixture] {count} items',
      '@fixtureCount': {
        'description': '[fixture] a count',
        'placeholders': {
          'count': {'type': 'int', 'format': 'compact'},
        },
      },
    };

    (String, Pack) packFor(Map<String, Object?> catalogue) {
      final f = File('${dir.path}/app_en.arb')
        ..writeAsStringSync(jsonEncode(catalogue));
      final pack = Pack(catalogue: f.path);
      return (pack.build(), pack);
    }

    test('a fixture catalogue is listed in full, placeholders included', () {
      final (body, pack) = packFor(base);
      expect(pack.messages.map((m) => m.key), ['fixtureTitle', 'fixtureCount']);
      final section = sectionI(body);
      expect(section, contains('- **`fixtureTitle`**: [fixture] A title'));
      expect(
        section,
        contains(
          '- **`fixtureCount`**: [fixture] {count} items\n'
          '  - Source: `${dir.path}',
        ),
      );
      expect(
        section,
        contains('  - Placeholders: `{count}` (format: compact, type: int)'),
      );
    });

    /// The base catalogue's pack, built in its own directory. The catalogue
    /// path is part of section I, so paths are compared as `<dir>`.
    String baseHash() {
      final dir = Directory.systemTemp.createTempSync('thirty_b8_cat_');
      try {
        final f = File('${dir.path}/app_en.arb')
          ..writeAsStringSync(jsonEncode(base));
        return Pack(catalogue: f.path).build().replaceAll(dir.path, '<dir>');
      } finally {
        dir.deleteSync(recursive: true);
      }
    }

    String hashOf(Map<String, Object?> catalogue) {
      final (body, _) = packFor(catalogue);
      return fnv64(body.replaceAll(dir.path, '<dir>'));
    }

    test('the same catalogue gives the same hash', () {
      expect(hashOf(base), fnv64(baseHash()));
    });

    for (final (name, changed) in <(String, Map<String, Object?>)>[
      (
        'a new message',
        {
          ...base,
          'fixtureNew': '[fixture] New words',
          '@fixtureNew': {'description': '[fixture] new'},
        },
      ),
      ('a removed message', {...base}..remove('fixtureTitle')),
      ('a changed English value', {...base, 'fixtureTitle': '[fixture] B'}),
      (
        'a changed description',
        {
          ...base,
          '@fixtureTitle': {'description': '[fixture] another heading'},
        },
      ),
      (
        'a changed placeholder',
        {
          ...base,
          '@fixtureCount': {
            'description': '[fixture] a count',
            'placeholders': {
              'count': {'type': 'num'},
            },
          },
        },
      ),
    ]) {
      test('$name changes the hash, so the pack must be regenerated and '
          'reviewed', () {
        expect(hashOf(changed), isNot(fnv64(baseHash())));
      });
    }

    test('a lapse line or a straight apostrophe in the catalogue reaches '
        'the cross-surface views (F and the apostrophe flag)', () {
      final (body, _) = packFor({
        ...base,
        'fixtureLapse': '[fixture] Saved at stage two',
        '@fixtureLapse': {'description': '[fixture] lapse'},
        'fixtureStraight': "[fixture] It's here",
        '@fixtureStraight': {'description': '[fixture] apostrophe'},
      });
      final f = body.substring(
        body.indexOf('## F. Lapse'),
        body.indexOf('## G. Accessibility'),
      );
      expect(f, contains('- [fixture] Saved at stage two'));
      final h = body.substring(
        body.indexOf('## H. Founder flags'),
        body.indexOf('## I. English catalogue'),
      );
      final (baseBody, _) = packFor(base);
      int straight(String body) => int.parse(
        RegExp(
          r'Apostrophes are mixed: (\d+) live strings',
        ).firstMatch(body)!.group(1)!,
      );
      expect(straight(h), straight(baseBody) + 1);
    });
  });
}
