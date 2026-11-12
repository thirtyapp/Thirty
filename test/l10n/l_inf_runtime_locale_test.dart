import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/l10n/thirty_locales.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/routing/app_router.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';
import 'package:thirty/l10n/gen/app_localizations.dart';

/// L-INF (ADR-025; tests S-3, S-7, S-14): THIRTY runs in English on every
/// device, whatever its language — it starts normally, nothing is refused —
/// and the localization infrastructure changes no word Flutter or THIRTY
/// shows.
const deviceLocales = <Locale>[
  Locale('en', 'US'),
  Locale('fr', 'BE'),
  Locale('nl', 'BE'),
  Locale('es', 'ES'),
  Locale('de', 'DE'),
  Locale('it', 'IT'),
  Locale('ja', 'JP'), // unsupported
  Locale('pt', 'BR'), // unsupported
];

const six = <Locale>[
  Locale('en'),
  Locale('fr'),
  Locale('nl'),
  Locale('es'),
  Locale('de'),
  Locale('it'),
];

void main() {
  group('S-14: English only (ADR-026 gate G-5C)', () {
    test('the release-locale set is exactly English', () {
      expect(thirtyReleaseLocales, const [Locale('en')]);
      expect(AppLocalizations.supportedLocales, const [Locale('en')]);
    });

    test('nothing can widen it: no release-locale define and no stored '
        'language preference exist in the app', () {
      final sources = [
        for (final f in Directory('lib').listSync(recursive: true))
          if (f is File && f.path.endsWith('.dart')) f.readAsStringSync(),
      ].join('\n');
      expect(sources, isNot(contains('THIRTY_RELEASE_LOCALES')));
      expect(sources, isNot(contains('app_locale')));
      expect(sources, isNot(contains('sourceLocale')));
    });

    for (final locale in deviceLocales) {
      test('device $locale → English', () {
        expect(resolveThirtyLocale([locale]), const Locale('en'));
        expect(
          thirtyLocaleListResolution([locale], thirtyReleaseLocales),
          const Locale('en'),
        );
        final words = thirtyLocalizationsFor(locale);
        expect(words.localeName, 'en');
        expect(words.brandName, 'THIRTY');
      });
    }

    test('no device locales at all → English', () {
      expect(resolveThirtyLocale(null), const Locale('en'));
      expect(resolveThirtyLocale(const []), const Locale('en'));
    });
  });

  group('S-7: resolution rules for later release sets (pure function)', () {
    Locale r(List<Locale> device, {Locale? override}) =>
        resolveThirtyLocale(device, override: override, releaseLocales: six);

    test('each launch language resolves to itself', () {
      for (final l in six) {
        expect(r([l]), l);
      }
    });
    test('regional variants resolve to their language', () {
      expect(r(const [Locale('fr', 'BE')]), const Locale('fr'));
      expect(r(const [Locale('fr', 'CH')]), const Locale('fr'));
      expect(r(const [Locale('nl', 'BE')]), const Locale('nl'));
      expect(r(const [Locale('de', 'AT')]), const Locale('de'));
      expect(r(const [Locale('it', 'CH')]), const Locale('it'));
      expect(r(const [Locale('es', 'MX')]), const Locale('es'));
      expect(r(const [Locale('en', 'GB')]), const Locale('en'));
    });
    test('an unsupported device language resolves to English', () {
      expect(r(const [Locale('pt', 'BR')]), const Locale('en'));
      expect(r(const [Locale('ja')]), const Locale('en'));
    });
    test('the first supported language in the device order wins', () {
      expect(
        r(const [Locale('pt', 'BR'), Locale('de', 'DE')]),
        const Locale('de'),
      );
      expect(r(const [Locale('it'), Locale('fr')]), const Locale('it'));
    });
    test('a subset release set offers only its languages', () {
      expect(
        resolveThirtyLocale(
          const [Locale('nl')],
          releaseLocales: const [Locale('en'), Locale('fr')],
        ),
        const Locale('en'),
      );
    });
    test('an override in the set wins; one outside it is ignored', () {
      expect(
        r(const [Locale('de')], override: const Locale('fr')),
        const Locale('fr'),
      );
      expect(
        r(const [Locale('de')], override: const Locale('pt')),
        const Locale('de'),
      );
    });
  });

  group('S-3: the SDK English localizations equal the previous defaults', () {
    Future<
      (MaterialLocalizations, CupertinoLocalizations, WidgetsLocalizations)
    >
    resolved(WidgetTester tester, Locale device) async {
      tester.platformDispatcher.localesTestValue = [device];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      late (MaterialLocalizations, CupertinoLocalizations, WidgetsLocalizations)
      out;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: thirtyLocalizationsDelegates,
          supportedLocales: thirtyReleaseLocales,
          localeListResolutionCallback: thirtyLocaleListResolution,
          home: Builder(
            builder: (c) {
              out = (
                MaterialLocalizations.of(c),
                CupertinoLocalizations.of(c),
                WidgetsLocalizations.of(c),
              );
              return const SizedBox();
            },
          ),
        ),
      );
      return out;
    }

    for (final device in deviceLocales) {
      testWidgets('device $device: every Material word and format THIRTY can '
          'show is unchanged', (tester) async {
        final (g, gc, gw) = await resolved(tester, device);
        const d = DefaultMaterialLocalizations();
        const dc = DefaultCupertinoLocalizations();
        const dw = DefaultWidgetsLocalizations();
        final diffs = <String>[];
        void same(String n, Object? a, Object? b) {
          if ('$a' != '$b') diffs.add('$n: "$a" → "$b"');
        }

        // The calendar's TalkBack date labels: every day of four years.
        for (
          var day = DateTime(2024);
          day.isBefore(DateTime(2028));
          day = day.add(const Duration(days: 1))
        ) {
          same(
            'formatFullDate $day',
            d.formatFullDate(day),
            g.formatFullDate(day),
          );
        }
        // The reminder's time display and the time picker.
        for (var h = 0; h < 24; h++) {
          for (final m in [0, 1, 5, 30, 59]) {
            final t = TimeOfDay(hour: h, minute: m);
            same(
              'formatTimeOfDay $t',
              d.formatTimeOfDay(t),
              g.formatTimeOfDay(t),
            );
            same(
              'formatTimeOfDay24 $t',
              d.formatTimeOfDay(t, alwaysUse24HourFormat: true),
              g.formatTimeOfDay(t, alwaysUse24HourFormat: true),
            );
            same('formatHour $t', d.formatHour(t), g.formatHour(t));
            same('formatMinute $t', d.formatMinute(t), g.formatMinute(t));
          }
        }
        for (final (n, a, b) in [
          ('timeOfDayFormat', d.timeOfDayFormat(), g.timeOfDayFormat()),
          (
            'timeOfDayFormat24',
            d.timeOfDayFormat(alwaysUse24HourFormat: true),
            g.timeOfDayFormat(alwaysUse24HourFormat: true),
          ),
          ('ok', d.okButtonLabel, g.okButtonLabel),
          ('cancel', d.cancelButtonLabel, g.cancelButtonLabel),
          ('close', d.closeButtonLabel, g.closeButtonLabel),
          ('back', d.backButtonTooltip, g.backButtonTooltip),
          ('closeTooltip', d.closeButtonTooltip, g.closeButtonTooltip),
          ('dialHelp', d.timePickerDialHelpText, g.timePickerDialHelpText),
          ('inputHelp', d.timePickerInputHelpText, g.timePickerInputHelpText),
          ('hourLabel', d.timePickerHourLabel, g.timePickerHourLabel),
          ('minuteLabel', d.timePickerMinuteLabel, g.timePickerMinuteLabel),
          (
            'hourModeAnnouncement',
            d.timePickerHourModeAnnouncement,
            g.timePickerHourModeAnnouncement,
          ),
          (
            'minuteModeAnnouncement',
            d.timePickerMinuteModeAnnouncement,
            g.timePickerMinuteModeAnnouncement,
          ),
          ('dialMode', d.dialModeButtonLabel, g.dialModeButtonLabel),
          ('inputMode', d.inputTimeModeButtonLabel, g.inputTimeModeButtonLabel),
          ('invalidTime', d.invalidTimeLabel, g.invalidTimeLabel),
          ('am', d.anteMeridiemAbbreviation, g.anteMeridiemAbbreviation),
          ('pm', d.postMeridiemAbbreviation, g.postMeridiemAbbreviation),
          (
            'modalBarrier',
            d.modalBarrierDismissLabel,
            g.modalBarrierDismissLabel,
          ),
          ('dialog', d.dialogLabel, g.dialogLabel),
          ('alertDialog', d.alertDialogLabel, g.alertDialogLabel),
          ('scrim', d.scrimLabel, g.scrimLabel),
          ('bottomSheet', d.bottomSheetLabel, g.bottomSheetLabel),
          ('showMenu', d.showMenuTooltip, g.showMenuTooltip),
          ('moreButton', d.moreButtonTooltip, g.moreButtonTooltip),
          ('copy', d.copyButtonLabel, g.copyButtonLabel),
          ('cut', d.cutButtonLabel, g.cutButtonLabel),
          ('paste', d.pasteButtonLabel, g.pasteButtonLabel),
          ('selectAll', d.selectAllButtonLabel, g.selectAllButtonLabel),
          (
            'refresh',
            d.refreshIndicatorSemanticLabel,
            g.refreshIndicatorSemanticLabel,
          ),
          (
            'tab',
            d.tabLabel(tabIndex: 2, tabCount: 4),
            g.tabLabel(tabIndex: 2, tabCount: 4),
          ),
          ('decimal', d.formatDecimal(1234567), g.formatDecimal(1234567)),
          ('firstDayOfWeek', d.firstDayOfWeekIndex, g.firstDayOfWeekIndex),
          ('scriptCategory', d.scriptCategory, g.scriptCategory),
          ('textDirection', dw.textDirection, gw.textDirection),
          ('reorderUp', dw.reorderItemUp, gw.reorderItemUp),
          ('cupertinoCopy', dc.copyButtonLabel, gc.copyButtonLabel),
          ('cupertinoPaste', dc.pasteButtonLabel, gc.pasteButtonLabel),
          ('cupertinoAlert', dc.alertDialogLabel, gc.alertDialogLabel),
        ]) {
          same(n, a, b);
        }
        expect(diffs, isEmpty);
      });
    }

    for (final device in [
      const Locale('en', 'US'),
      const Locale('fr', 'BE'),
      const Locale('ja', 'JP'),
    ]) {
      testWidgets('device $device: the reminder time picker reads exactly as '
          'before (texts and TalkBack labels)', (tester) async {
        tester.platformDispatcher.localesTestValue = [device];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        final handle = tester.ensureSemantics();

        Future<List<String>> picker({required bool thirty}) async {
          TimeOfDay? picked;
          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: thirty
                  ? thirtyLocalizationsDelegates
                  : null,
              supportedLocales: thirty
                  ? thirtyReleaseLocales
                  : const [Locale('en', 'US')],
              localeListResolutionCallback: thirty
                  ? thirtyLocaleListResolution
                  : null,
              home: Builder(
                builder: (c) => TextButton(
                  onPressed: () async => picked = await showTimePicker(
                    context: c,
                    initialTime: const TimeOfDay(hour: 8, minute: 30),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          );
          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();
          // One more frame, so the semantics tree has caught up.
          await tester.pump(const Duration(milliseconds: 100));
          final seen = [
            for (final t in tester.widgetList<RichText>(find.byType(RichText)))
              'text: ${t.text.toPlainText()}',
            ...semanticsLabels(tester),
          ];
          await tester.tap(find.text('OK'));
          await tester.pumpAndSettle();
          seen.add('picked: $picked');
          await tester.pumpWidget(const SizedBox());
          return seen;
        }

        final before = await picker(thirty: false);
        final after = await picker(thirty: true);
        expect(after, before);
        expect(
          before,
          containsAll([
            'text: Select time',
            'text: AM',
            'text: PM',
            'text: Cancel',
            'text: OK',
            'semantics: Select hours 8',
            'semantics: Select minutes 30',
          ]),
        );
        expect(before.any((s) => s.contains('8:30 AM')), isTrue);
        expect(before.last, 'picked: ${const TimeOfDay(hour: 8, minute: 30)}');
        handle.dispose();
      });
    }
  });

  group('S-3/S-14: the app starts normally in English on any device', () {
    for (final locale in deviceLocales) {
      testWidgets('device $locale', (tester) async {
        tester.platformDispatcher.localesTestValue = [locale];
        tester.platformDispatcher.localeTestValue = locale;
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        addTearDown(tester.platformDispatcher.clearLocaleTestValue);
        SharedPreferences.setMockInitialValues({firstNamePromptSeenKey: true});
        final prefs = await SharedPreferences.getInstance();
        appRouter.go('/');
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: const ThirtyApp(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final context = tester.element(find.byType(Scaffold).first);
        expect(Localizations.localeOf(context), const Locale('en'));
        expect(context.l10n.brandName, 'THIRTY');
        expect(tester.widget<Title>(find.byType(Title)).title, 'THIRTY');
        expect(find.text("Begin today's Circle"), findsOneWidget);
      });
    }
  });
}

/// Every label, value, hint and tooltip in the semantics tree, in order.
List<String> semanticsLabels(WidgetTester tester) {
  final out = <String>[];
  void visit(SemanticsNode node) {
    final d = node.getSemanticsData();
    final parts = [
      d.label,
      d.value,
      d.hint,
      d.tooltip,
    ].where((s) => s.isNotEmpty);
    if (parts.isNotEmpty) out.add('semantics: ${parts.join(' | ')}');
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  for (final view in tester.binding.renderViews) {
    final root = view.owner?.semanticsOwner?.rootSemanticsNode;
    if (root != null) visit(root);
  }
  return out;
}
