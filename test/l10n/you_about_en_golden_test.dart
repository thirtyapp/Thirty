import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/config/release_info.dart';
import 'package:thirty/core/l10n/thirty_locales.dart';
import 'package:thirty/core/premium/entitlement_gateway.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/reminder/reminder_gateway.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/features/premium/presentation/widgets/premium_restore_footer.dart';
import 'package:thirty/features/settings/presentation/settings_page.dart';
import 'package:thirty/features/settings/presentation/widgets/you_about_card.dart';
import 'package:thirty/features/settings/presentation/widgets/you_group_card.dart';

/// G-02 / L-CNT-EN / Batch 1 (You → About): the English output freeze.
///
/// Records, at the baseline `28827e73` and before any extraction, what You
/// renders for About — the section headings in order, every About string,
/// its resolved text style, the geometry of the heading, the card and
/// Restore, the render trees of the heading and the card, and the whole
/// page's semantics tree in traversal order — in light and dark, at 100 %
/// and 200 % text, for English and six other device languages. After the
/// extraction the same capture must be identical, byte for byte.
///
/// Each device language is compared with the English capture while
/// recording, and every capture with the golden afterwards.
///
/// Record (baseline only):
/// `flutter test test/l10n/you_about_en_golden_test.dart
///  --dart-define=WRITE_YOU_ABOUT_GOLDEN=true`
const _golden = 'test/l10n/you_about_en_golden_28827e73.json';
const _write = bool.fromEnvironment('WRITE_YOU_ABOUT_GOLDEN');

/// The device languages captured: English first, then six that THIRTY
/// does not ship (G-5C), which must all render the same English page.
const _deviceLocales = <Locale>[
  Locale('en', 'US'),
  Locale('fr', 'FR'),
  Locale('nl', 'NL'),
  Locale('es', 'ES'),
  Locale('de', 'DE'),
  Locale('it', 'IT'),
  Locale('ja', 'JP'),
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
  Future<MonthlyOffer?> monthlyOffer() async => null;
  @override
  Future<PurchaseOutcome> purchaseMonthly() async => PurchaseOutcome.error;
  @override
  Future<RestoreOutcome> restore() async => RestoreOutcome.notFound;
  @override
  Future<String?> managementUrl() async => null;
}

/// You, as the app hosts it: THIRTY's delegates and English-only locale
/// resolution (`thirty_app.dart`), a tall view so every section is built.
Future<void> _pumpYou(
  WidgetTester tester, {
  required ThemeData theme,
  required double textScale,
  required Locale deviceLocale,
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
        theme: theme,
        localizationsDelegates: thirtyLocalizationsDelegates,
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
}

/// Debug hash codes and semantics ids are per-run identities, not output.
String _normalize(String dump) => dump
    .replaceAll(RegExp(r'#[0-9a-f]{5}\b'), '#•')
    .replaceAll(RegExp(r'SemanticsNode#\d+'), 'SemanticsNode#•');

Map<String, Object?> _style(TextStyle? s) => {
  'color': s?.color?.toARGB32().toRadixString(16),
  'fontFamily': s?.fontFamily,
  'fontSize': s?.fontSize,
  'fontWeight': s?.fontWeight?.toString(),
  'height': s?.height,
  'letterSpacing': s?.letterSpacing,
};

List<double> _rect(Rect r) => [r.left, r.top, r.right, r.bottom];

/// Every paragraph inside [of], in paint order, with how it is drawn.
List<Map<String, Object?>> _paragraphs(WidgetTester tester, Finder of) => [
  for (final e
      in find.descendant(of: of, matching: find.byType(RichText)).evaluate())
    if (e.widget case final RichText rich)
      {
        'text': rich.text.toPlainText(),
        'style': _style(rich.text.style),
        'textScaler': rich.textScaler.toString(),
        'maxLines': rich.maxLines,
        'overflow': rich.overflow.name,
        'softWrap': rich.softWrap,
        'textAlign': rich.textAlign.name,
        'rect': _rect(tester.getRect(find.byWidget(rich))),
      },
];

/// The running version is [ReleaseInfo.appVersion]'s, checked live by
/// each test; the golden stores it as `{appVersion}` so a version bump is
/// not an About change. (The test font draws every glyph one em wide, so a
/// bump of the same length leaves the geometry unchanged; a longer or
/// shorter version moves the version line's right edge and needs a
/// reviewed re-record.)
Map<String, Object?> _capture(WidgetTester tester) =>
    jsonDecode(
          jsonEncode(
            _captureRaw(tester),
          ).replaceAll(ReleaseInfo.appVersion, '{appVersion}'),
        )
        as Map<String, Object?>;

Map<String, Object?> _captureRaw(WidgetTester tester) {
  final headingFinder = find.byType(YouSectionHeading);
  final headings = [
    for (final e in headingFinder.evaluate())
      (
        (e.widget as YouSectionHeading).title,
        tester.getTopLeft(find.byWidget(e.widget)).dy,
      ),
  ]..sort((a, b) => a.$2.compareTo(b.$2));
  final aboutHeading = find.widgetWithText(YouSectionHeading, 'About');
  final card = find.byType(YouAboutCard);
  final restore = find.byType(PremiumRestoreFooter);
  final root = tester
      .renderObject(find.byType(SettingsPage))
      .owner!
      .semanticsOwner!
      .rootSemanticsNode!;
  final versionNode = tester.getSemantics(
    find.descendant(of: card, matching: find.byType(MergeSemantics)),
  );
  final headingNode = tester.getSemantics(aboutHeading);
  return {
    'sectionHeadings': [for (final (t, _) in headings) t],
    'aboutHeading': _paragraphs(tester, aboutHeading),
    'aboutCard': _paragraphs(tester, card),
    'geometry': {
      'aboutHeading': _rect(tester.getRect(aboutHeading)),
      'aboutCard': _rect(tester.getRect(card)),
      'restoreFooter': _rect(tester.getRect(restore)),
    },
    'aboutHeadingSemantics': {
      'label': headingNode.label,
      'isHeader': headingNode.getSemanticsData().flagsCollection.isHeader,
      'actions': headingNode.getSemanticsData().actions,
      'node': _normalize(headingNode.toStringDeep()),
    },
    'aboutCardSemantics': {
      'label': versionNode.label,
      'value': versionNode.value,
      'hint': versionNode.hint,
      'actions': versionNode.getSemanticsData().actions,
      'node': _normalize(versionNode.toStringDeep()),
    },
    'aboutHeadingRenderTree': _normalize(
      tester.renderObject(aboutHeading).toStringDeep(),
    ),
    'aboutCardRenderTree': _normalize(tester.renderObject(card).toStringDeep()),
    'pageSemanticsTree': _normalize(
      root.toStringDeep(childOrder: DebugSemanticsDumpOrder.traversalOrder),
    ),
  };
}

void main() {
  final golden = <String, Object?>{};

  for (final (themeName, theme) in [
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    for (final textScale in [1.0, 2.0]) {
      for (final locale in _deviceLocales) {
        final key = '$themeName/${textScale}x';
        testWidgets(
          'You → About is unchanged: $key, device ${locale.toLanguageTag()}',
          (tester) async {
            final semantics = tester.ensureSemantics();
            await _pumpYou(
              tester,
              theme: theme,
              textScale: textScale,
              deviceLocale: locale,
            );
            expect(
              find.text('Version ${ReleaseInfo.appVersion}'),
              findsOneWidget,
            );
            final captured = _capture(tester);
            semantics.dispose();

            // Recording takes the English device; every other device
            // language must already render exactly the same page.
            if (_write && locale == _deviceLocales.first) {
              golden[key] = captured;
              return;
            }
            final recorded = _write
                ? golden[key]
                : (jsonDecode(File(_golden).readAsStringSync())
                      as Map<String, Object?>)[key];
            expect(recorded, isNotNull, reason: 'no golden for $key');
            expect(
              const JsonEncoder.withIndent('  ').convert(captured),
              const JsonEncoder.withIndent('  ').convert(recorded),
            );
          },
        );
      }
    }
  }

  test('the golden covers every combination and the baseline words', () {
    if (_write) {
      File(
        _golden,
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(golden));
    }
    final recorded =
        jsonDecode(File(_golden).readAsStringSync()) as Map<String, Object?>;
    expect(recorded.keys, [
      'light/1.0x',
      'light/2.0x',
      'dark/1.0x',
      'dark/2.0x',
    ]);
    for (final capture in recorded.values.cast<Map<String, Object?>>()) {
      expect(capture['sectionHeadings'], [
        'Personal',
        'Preferences',
        'Data & privacy',
        'About',
      ]);
      expect(
        [
          for (final p in capture['aboutHeading']! as List<Object?>)
            (p! as Map<String, Object?>)['text'],
        ],
        ['About'],
      );
      expect(
        [
          for (final p in capture['aboutCard']! as List<Object?>)
            (p! as Map<String, Object?>)['text'],
        ],
        [
          // The row's icon is drawn as a glyph.
          String.fromCharCode(Icons.info_outline.codePoint),
          'THIRTY',
          'Version {appVersion}',
        ],
      );
    }
  });
}
