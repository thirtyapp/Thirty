import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/analytics/analytics_event_type.dart';
import 'package:thirty/core/analytics/analytics_service.dart';
import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/premium/entitlement_gateway.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/reminder/reminder_gateway.dart';
import 'package:thirty/core/routing/app_router.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';
import 'package:thirty/features/settings/presentation/settings_page.dart';
import 'package:thirty/features/settings/presentation/widgets/first_name_editor.dart';
import 'package:thirty/features/settings/presentation/widgets/you_personal_card.dart';

/// First-name personalization on You: the "Personal" row, its editor, and
/// the privacy contract (local only, never exported or tracked, untouched
/// by "Delete Circle history").

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

class _RecordingAnalyticsService implements AnalyticsService {
  final List<(AnalyticsEventType, Map<String, Object?>?)> events = [];

  @override
  void track(AnalyticsEventType type, {Map<String, Object?>? metadata}) {
    events.add((type, metadata));
  }
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

Future<(ProviderContainer, SharedPreferences)> _pump(
  WidgetTester tester, {
  Map<String, Object> prefsValues = const {},
  Size size = const Size(412, 915),
  double textScale = 1.0,
  ThemeData? theme,
  bool withJournal = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  if (withJournal) {
    await CircleJournalRepository(prefs).recordShown(
      circleId: '2026-10-01',
      localDate: '2026-10-01',
      direction: Intention.moreEnergy,
      activityId: ActivityId.thirtyMinuteWalk,
      shownAt: DateTime(2026, 10, 1, 9),
    );
  }
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

Finder get _row => find.byKey(const ValueKey('you.name'));

Future<void> _openEditor(WidgetTester tester) async {
  await tester.tap(_row);
  await tester.pumpAndSettle();
}

Finder get _field => find.descendant(
  of: find.byType(FirstNameEditor),
  matching: find.byType(TextField),
);

TextButton _button(WidgetTester tester, String label) =>
    tester.widget<TextButton>(find.widgetWithText(TextButton, label));

List<String> _truncated(WidgetTester tester) => [
  for (final element in find.byType(RichText).evaluate())
    if ((element.renderObject! as RenderParagraph).didExceedMaxLines)
      (element.renderObject! as RenderParagraph).text.toPlainText(),
];

void main() {
  setUpAll(() async {
    await _loadFont('Inter', [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
    ]);
    await _loadFont('Newsreader', ['assets/fonts/Newsreader[opsz,wght].ttf']);
  });

  group('Personal row', () {
    testWidgets('"Personal" sits after the header and before THIRTY Premium', (
      tester,
    ) async {
      await _pump(tester);
      double top(Finder f) => tester.getTopLeft(f).dy;
      expect(top(find.text('Personal')), greaterThan(top(find.text('You'))));
      expect(
        top(find.text('Personal')),
        greaterThan(top(find.text(SettingsPage.subtitle))),
      );
      expect(top(_row), greaterThan(top(find.text('Personal'))));
      expect(top(find.text('THIRTY Premium')), greaterThan(top(_row)));
    });

    testWidgets('no name: "Your name" / "Add your name"', (tester) async {
      await _pump(tester);
      expect(find.text('Your name'), findsOneWidget);
      expect(find.text('Add your name'), findsOneWidget);
    });

    testWidgets('a stored name shows the actual value', (tester) async {
      await _pump(tester, prefsValues: {firstNameKey: 'Thomas'});
      expect(find.text('Your name'), findsOneWidget);
      expect(find.text('Thomas'), findsOneWidget);
      expect(find.text('Add your name'), findsNothing);
    });

    testWidgets('no avatar, no account icon, at least 48dp tall', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.byType(CircleAvatar), findsNothing);
      expect(find.byIcon(Icons.person), findsNothing);
      expect(find.byIcon(Icons.account_circle), findsNothing);
      expect(find.byIcon(Icons.account_circle_outlined), findsNothing);
      expect(tester.getSize(_row).height, greaterThanOrEqualTo(48));
    });
  });

  group('Editor', () {
    testWidgets('tapping the row opens the editor: title, supporting copy, '
        'labelled empty field, Save disabled, no Remove', (tester) async {
      await _pump(tester);
      await _openEditor(tester);

      expect(find.byType(FirstNameEditor), findsOneWidget);
      expect(find.text('Your name'), findsNWidgets(2));
      expect(
        find.text('Used only to make THIRTY feel a little more personal.'),
        findsOneWidget,
      );
      expect(find.text('First name'), findsOneWidget);
      expect(tester.widget<TextField>(_field).controller!.text, isEmpty);
      expect(tester.widget<TextField>(_field).autofocus, isTrue);
      expect(_button(tester, 'Save').onPressed, isNull);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Remove name'), findsNothing);
    });

    testWidgets('prefilled with the existing name, with Remove name', (
      tester,
    ) async {
      await _pump(tester, prefsValues: {firstNameKey: 'Thomas'});
      await _openEditor(tester);
      expect(tester.widget<TextField>(_field).controller!.text, 'Thomas');
      expect(find.text('Remove name'), findsOneWidget);
    });

    testWidgets('Save stores the name and updates You immediately', (
      tester,
    ) async {
      final (container, prefs) = await _pump(tester);
      await _openEditor(tester);
      await tester.enterText(_field, 'Thomas');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(FirstNameEditor), findsNothing);
      expect(find.text('Thomas'), findsOneWidget);
      expect(find.text('Add your name'), findsNothing);
      expect(container.read(firstNameProvider), 'Thomas');
      expect(prefs.getString(firstNameKey), 'Thomas');
    });

    testWidgets('the keyboard Done action saves too', (tester) async {
      final (_, prefs) = await _pump(tester);
      await _openEditor(tester);
      expect(
        tester.widget<TextField>(_field).textInputAction,
        TextInputAction.done,
      );
      await tester.enterText(_field, 'Anna');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byType(FirstNameEditor), findsNothing);
      expect(prefs.getString(firstNameKey), 'Anna');
    });

    testWidgets('Remove name clears it and returns the row to "Add your '
        'name" — no confirmation, nothing else touched', (tester) async {
      final (container, prefs) = await _pump(
        tester,
        prefsValues: {firstNameKey: 'Thomas', 'theme_mode_v1': 'dark'},
      );
      await _openEditor(tester);
      await tester.tap(find.text('Remove name'));
      await tester.pumpAndSettle();

      expect(find.byType(FirstNameEditor), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Add your name'), findsOneWidget);
      expect(container.read(firstNameProvider), isNull);
      expect(prefs.containsKey(firstNameKey), isFalse);
      expect(prefs.getString('theme_mode_v1'), 'dark');
    });

    testWidgets('Remove name is quiet, not destructive red', (tester) async {
      await _pump(tester, prefsValues: {firstNameKey: 'Thomas'});
      await _openEditor(tester);
      final style = _button(tester, 'Remove name').style;
      final color = style?.foregroundColor?.resolve({});
      expect(color, isNot(AppColors.light.errorText));
    });

    testWidgets('Cancel changes nothing, even after typing', (tester) async {
      final (container, prefs) = await _pump(
        tester,
        prefsValues: {firstNameKey: 'Thomas'},
      );
      await _openEditor(tester);
      await tester.enterText(_field, 'Someone else');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(FirstNameEditor), findsNothing);
      expect(find.text('Thomas'), findsOneWidget);
      expect(container.read(firstNameProvider), 'Thomas');
      expect(prefs.getString(firstNameKey), 'Thomas');
    });

    testWidgets('whitespace: a blank field cannot be saved; surrounding '
        'spaces are trimmed', (tester) async {
      final (_, prefs) = await _pump(
        tester,
        prefsValues: {firstNameKey: 'Thomas'},
      );
      await _openEditor(tester);
      await tester.enterText(_field, '    ');
      await tester.pump();
      expect(_button(tester, 'Save').onPressed, isNull);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(prefs.getString(firstNameKey), 'Thomas');

      await tester.enterText(_field, '  Anna  ');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(prefs.getString(firstNameKey), 'Anna');
      expect(find.text('Anna'), findsOneWidget);
    });

    testWidgets('over 40 code points: explained, Save disabled, nothing '
        'saved or truncated', (tester) async {
      final (_, prefs) = await _pump(tester);
      await _openEditor(tester);
      await tester.enterText(_field, 'a' * 41);
      await tester.pump();

      expect(find.text('Use 40 characters or fewer.'), findsOneWidget);
      expect(_button(tester, 'Save').onPressed, isNull);
      expect(tester.widget<TextField>(_field).controller!.text, 'a' * 41);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(prefs.containsKey(firstNameKey), isFalse);

      await tester.enterText(_field, 'a' * 40);
      await tester.pump();
      expect(find.text('Use 40 characters or fewer.'), findsNothing);
      expect(_button(tester, 'Save').onPressed, isNotNull);
    });
  });

  group('Accessibility', () {
    testWidgets('"Personal" is a header; the row is one button announcing '
        'its value', (tester) async {
      await _pump(tester);
      expect(
        tester.getSemantics(find.text('Personal')),
        isSemantics(isHeader: true),
      );
      expect(
        tester.getSemantics(_row),
        isSemantics(
          label: 'Your name, Add your name',
          isButton: true,
          hasTapAction: true,
        ),
      );
      expect(find.bySemanticsLabel('Your name, Add your name'), findsOneWidget);
      expect(find.bySemanticsLabel('Add your name'), findsNothing);
    });

    testWidgets('with a name: "Your name, Thomas"', (tester) async {
      await _pump(tester, prefsValues: {firstNameKey: 'Thomas'});
      expect(
        tester.getSemantics(_row),
        isSemantics(label: 'Your name, Thomas', isButton: true),
      );
    });

    testWidgets('the field has an explicit label; Save, Cancel and Remove '
        'name are buttons', (tester) async {
      await _pump(tester, prefsValues: {firstNameKey: 'Thomas'});
      await _openEditor(tester);
      // The decoration's label names the editable node itself.
      expect(
        tester.getSemantics(find.bySemanticsLabel('First name')),
        isSemantics(label: 'First name', isTextField: true),
      );
      expect(find.bySemanticsLabel('First name'), findsOneWidget);
      for (final label in ['Save', 'Cancel', 'Remove name']) {
        expect(
          tester.getSemantics(find.widgetWithText(TextButton, label)),
          isSemantics(isButton: true),
          reason: label,
        );
      }
    });
  });

  group('Responsive', () {
    for (final (label, size, scale) in [
      ('Pixel 7 at 200%', const Size(412, 915), 2.0),
      ('360×740', const Size(360, 740), 1.0),
      ('360×740 at 200%', const Size(360, 740), 2.0),
    ]) {
      for (final (themeName, theme) in [
        ('light', AppTheme.light),
        ('dark', AppTheme.dark),
      ]) {
        testWidgets('$label, $themeName: the row and the editor fit, with the '
            'keyboard up', (tester) async {
          await _pump(
            tester,
            prefsValues: {firstNameKey: 'Thomas'},
            size: size,
            textScale: scale,
            theme: theme,
          );
          expect(tester.takeException(), isNull);
          expect(_truncated(tester), isEmpty);
          expect(find.text('Thomas'), findsOneWidget);

          await _openEditor(tester);
          // A typical phone software keyboard (about 320dp tall).
          tester.view.viewInsets = const FakeViewPadding(bottom: 320);
          addTearDown(tester.view.resetViewInsets);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(_truncated(tester), isEmpty);
          for (final action in ['Save', 'Cancel', 'Remove name']) {
            await tester.ensureVisible(find.text(action));
            await tester.pumpAndSettle();
            expect(find.text(action).hitTestable(), findsOneWidget);
          }
        });
      }
    }
  });

  group('Privacy', () {
    testWidgets('the Circle export ("Copy as text") never includes the name', (
      tester,
    ) async {
      final (_, prefs) = await _pump(
        tester,
        prefsValues: {firstNameKey: 'Thomas'},
        withJournal: true,
        size: const Size(412, 3000),
      );
      final exported = CircleJournalRepository(prefs).exportAsJson();
      expect(exported, isNot(contains('Thomas')));

      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.tap(find.text('Copy as text'));
      await tester.pumpAndSettle();
      expect(copied, hasLength(1));
      expect(copied.single, contains('entries'));
      expect(copied.single, isNot(contains('Thomas')));
    });

    testWidgets('no analytics event carries the name — through app start, '
        'opening You and saving a name', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({
        firstNameKey: 'Thomas',
        firstNamePromptSeenKey: true,
        'analytics_consent_v1': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final analytics = _RecordingAnalyticsService();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          analyticsServiceProvider.overrideWithValue(analytics),
          entitlementGatewayProvider.overrideWithValue(
            _FakeEntitlementGateway(),
          ),
          reminderGatewayProvider.overrideWithValue(_FakeReminderGateway()),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(() => appRouter.go('/'));
      await container.read(entitlementStatusProvider.notifier).initialize();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ThirtyApp(),
        ),
      );
      await tester.pumpAndSettle();
      appRouter.go('/settings');
      await tester.pumpAndSettle();
      await _openEditor(tester);
      await tester.enterText(_field, 'Thomasina');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(analytics.events, isNotEmpty, reason: 'app start is tracked');
      for (final (type, metadata) in analytics.events) {
        final payload = jsonEncode({'type': type.wireName, 'meta': metadata});
        expect(payload, isNot(contains('Thomas')), reason: type.wireName);
      }
    });

    testWidgets('"Delete Circle history" keeps the name', (tester) async {
      final (container, prefs) = await _pump(
        tester,
        prefsValues: {firstNameKey: 'Thomas'},
        withJournal: true,
        size: const Size(412, 3000),
      );
      await tester.tap(find.text('Delete Circle history'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete permanently'));
      await tester.pumpAndSettle();

      expect(prefs.getString(circleJournalKey), isNull);
      expect(prefs.getString(firstNameKey), 'Thomas');
      expect(container.read(firstNameProvider), 'Thomas');
      expect(find.text('Thomas'), findsOneWidget);
    });
  });

  test('YouPersonalCard copy', () {
    expect(YouPersonalCard.rowTitle, 'Your name');
    expect(YouPersonalCard.addPrompt, 'Add your name');
  });
}
