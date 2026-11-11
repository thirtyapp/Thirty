import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/home/presentation/memory_page.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';

import '../../support/r8_harness.dart';

/// L-1 Option B (founder decision, 2026-11-11) — the shared fixture of the
/// L-1 tests, taken from the L-1 read-only discovery: real History, a real
/// I3 Insight applied through the production path (so its id and the
/// `byInsight` it leaves are THIRTY's own), a started Plan and a kept
/// Circle; and the Suggestion Preferences record in each shape THIRTY can
/// or can't read.
///
/// Every observation in the L-1 tests is black-box — the store, the screen
/// and the clipboard — so the same tests ran on the frozen tree before the
/// change.
class L1Fixture {
  L1Fixture._(this.store, this.insightId, this.variants);

  /// The whole durable store, with the readable (v1) preferences record.
  final Map<String, Object> store;

  /// The applied I3 Insight's id.
  final String insightId;

  /// The preferences record by case name.
  final Map<String, Object> variants;

  static final morning = DateTime(2026, 10, 30, 9);

  static const readable = 'A_v1_readable';
  static const newerSchema = 'B_newer_schema_v2';
  static const malformed = 'C_malformed_json';
  static const listShape = 'D_list_field_not_a_list';
  static const stringList = 'E1_native_string_list';
  static const nativeInt = 'E2_native_int';
  static const unreadableItem = 'F_v1_with_one_unreadable_item';

  /// The cases whose whole record THIRTY can't read.
  static const unreadableCases = [
    newerSchema,
    malformed,
    listShape,
    stringList,
    nativeInt,
  ];

  static const allCases = [
    readable,
    newerSchema,
    malformed,
    listShape,
    stringList,
    nativeInt,
    unreadableItem,
  ];

  /// The store with [name]'s preferences record.
  Map<String, Object> withPreferences(String name) => {
    ...store,
    suggestionPreferencesKey: variants[name]!,
  };

  static Future<L1Fixture> seed() async {
    final h = R8Harness(morning);
    CirclePart part(ElementId e) => CirclePart(e, elementOf(e).minutes);
    final window = [
      part(ElementId.openWindow),
      part(ElementId.standingStretch),
      part(ElementId.sitAMinute),
    ];
    final reading = [part(ElementId.phoneFaceDown), part(ElementId.readPages)];
    CircleJournalEntry entry(
      int ago,
      Intention need, {
      List<CirclePart> parts = const [],
      Set<ElementId> skipped = const {},
    }) {
      final date = morning.subtract(Duration(days: ago));
      return CircleJournalEntry(
        schemaVersion: circleJournalSchemaVersion,
        circleId: dateKey(date),
        localDate: dateKey(date),
        direction: need,
        activityId: ActivityId.values.first,
        catalogVersion: catalogVersion,
        shownAt: date,
        startedAt: date,
        closedAt: date,
        session: parts.isEmpty
            ? null
            : CircleSessionRecord(
                title: 'Circle',
                parts: CirclePlan(parts).toWire(),
                skipped: [for (final e in skipped) e.name],
              ),
      );
    }

    final manualNotSuggested = {
      'activityId': ActivityId.values.first.name,
      'need': Intention.moreEnergy.name,
      'since': '2026-10-01T09:00:00.000',
    };
    final manualLeftOut = {
      'elementId': ElementId.readPages.name,
      'since': '2026-10-02T09:00:00.000',
      'futureItemField': 'kept',
    };
    await h.boot({
      circleJournalKey: jsonEncode({
        'schemaVersion': circleJournalSchemaVersion,
        'entries': [
          for (final ago in [2, 4, 6, 8, 10, 12, 15])
            entry(ago, Intention.clearerHead, parts: reading).toJson(),
          for (final (k, ago) in [1, 5, 9, 11].indexed)
            entry(
              ago,
              Intention.moreEnergy,
              parts: window,
              skipped: k == 1 ? const {} : {ElementId.openWindow},
            ).toJson(),
        ],
      }),
      suggestionPreferencesKey: jsonEncode({
        'schemaVersion': suggestionPreferencesSchemaVersion,
        'notSuggested': [manualNotSuggested],
        'elementsLeftOut': [manualLeftOut],
        'futureTopField': 1,
      }),
    });
    final c = h.open();
    final shown = c.read(insightsProvider.notifier).assess().added.single;
    expect(shown.family, InsightFamily.skippedPart);
    await R8Harness.settle();
    expect(
      await c.read(insightsProvider.notifier).apply(shown.id),
      InsightActionResult.done,
    );
    await R8Harness.settle();
    expect(
      c.read(circlePlansProvider.notifier).start('getting_going'),
      PlanActionResult.done,
    );
    await R8Harness.settle();
    expect(
      await c
          .read(keptCirclesProvider.notifier)
          .keepCircle(
            plan: CirclePlan(window),
            need: Intention.moreEnergy,
            circleId: entry(1, Intention.moreEnergy).circleId,
          ),
      isNotNull,
    );
    await R8Harness.settle();
    final store = await h.disk.stored();
    c.dispose();

    final id = shown.id;
    final v1Raw = store[suggestionPreferencesKey]! as String;
    expect(v1Raw, contains(id));
    final v1 = jsonDecode(v1Raw) as Map<String, Object?>;
    final leftOut = (v1['elementsLeftOut']! as List)
        .cast<Map<String, Object?>>();
    final withId = leftOut.firstWhere((e) => e['byInsight'] == id);
    return L1Fixture._(store, id, {
      readable: v1Raw,
      // A newer THIRTY's record, laid out its own way: tabs, newlines,
      // non-ASCII text and a trailing space — kept exactly.
      newerSchema:
          '${const JsonEncoder.withIndent('\t').convert({
            ...v1,
            'schemaVersion': suggestionPreferencesSchemaVersion + 1,
            'futureV2Field': {'meaning': 'unknown to this build', 'note': 'é 😀'},
          })}\n ',
      malformed: v1Raw.substring(0, v1Raw.length - 3),
      listShape: jsonEncode({
        ...v1,
        'elementsLeftOut': {'0': withId, '1': manualLeftOut},
      }),
      stringList: <String>[jsonEncode(withId), jsonEncode(manualNotSuggested)],
      nativeInt: 42,
      unreadableItem: jsonEncode({
        ...v1,
        'elementsLeftOut': [
          ...leftOut,
          {
            'elementId': 'partFromANewerBuild',
            'since': '2026-10-03T09:00:00.000',
            'byInsight': id,
          },
        ],
      }),
    });
  }
}

/// The IEEE-754 bits of [v], as 16 hexadecimal digits.
String doubleBits(double v) {
  final data = ByteData(8)..setFloat64(0, v);
  return [
    for (var i = 0; i < 8; i++)
      data.getUint8(i).toRadixString(16).padLeft(2, '0'),
  ].join();
}

double doubleFromBits(String hex) {
  final data = ByteData(8);
  for (var i = 0; i < 8; i++) {
    data.setUint8(i, int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16));
  }
  return data.getFloat64(0);
}

/// Reads back an exported `suggestionPreferencesStored` value: what the
/// store's API gave THIRTY. Fails on anything not in the export's form.
Object decodeStoredPreferences(Object? exported) {
  final env = (exported! as Map).cast<String, Object?>();
  return switch (env['type']) {
    'string' => env['value']! as String,
    'bool' => env['value']! as bool,
    'int' => int.parse(env['value']! as String),
    'double' => doubleFromBits(env['ieee754Hex']! as String),
    'stringList' => (env['value']! as List).cast<String>().toList(),
    final other => throw StateError('unknown exported type $other'),
  };
}

/// Whether [a] and [b] are the same stored value — the same type, and for a
/// double the same bits.
bool sameStoredValue(Object? a, Object? b) => switch ((a, b)) {
  (final double x, final double y) => doubleBits(x) == doubleBits(y),
  (final List x, final List y) =>
    x.length == y.length &&
        [for (var i = 0; i < x.length; i++) x[i] == y[i]].every((e) => e),
  _ => a.runtimeType == b.runtimeType && a == b,
};

/// The clipboard, for "Copy as text": what was copied, or a failure.
class FakeClipboard {
  final copied = <String>[];
  bool fail = false;

  void install(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          if (fail) {
            throw PlatformException(code: 'clipboard', message: 'refused');
          }
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
  }

  Map<String, Object?> get last =>
      jsonDecode(copied.last) as Map<String, Object?>;
}

/// Shows [home] — the memory page as itself, anything else on a scrolling
/// page — over [c].
Future<void> pumpL1(
  WidgetTester tester,
  ProviderContainer c,
  Widget home, {
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: home is MemoryPage
            ? home
            : Scaffold(body: SingleChildScrollView(child: home)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// L-1 Option B's words, as the user reads them (founder-approved copy
/// direction, 2026-11-11). Literal here, so these tests read the screen
/// rather than the app's own constants.
abstract final class L1Words {
  static const deletedNoticeTitle =
      'Some saved preferences couldn’t be checked';
  static const deletedNoticeBody =
      'Your Circle history was deleted, but THIRTY couldn’t read some saved '
      'suggestion preferences to check whether they contain links to that '
      'history.\n\n'
      'Your preferences have been kept unchanged. You can export them or '
      'remove them using Reset suggestion preferences.';
  static const confirmQualifier =
      'Some saved suggestion preferences can’t be read';
  static const memoryNotice =
      'Some saved suggestion preferences couldn’t be read. They’re kept '
      'unchanged and may include links to earlier history that THIRTY '
      'can’t check. You can copy your data before choosing to reset them.';
  static const resetUnreadableTitle =
      'Reset unreadable suggestion preferences?';
  static const resetUnreadableBody =
      'THIRTY can’t read all your saved suggestion preferences. Reset will '
      'permanently remove that saved record, including choices THIRTY can’t '
      'currently show or restore.\n\n'
      'You can copy your saved data first from Your data. Your Circle history '
      'and answers won’t be deleted by this reset.';
  static const resetLabel = 'Reset suggestion preferences';
  static const resetReadableTitle = 'Reset suggestion preferences?';
  static const copied = 'Copied your Circle history as text.';
  static const copyFailed = 'Couldn’t copy your data. Please try again.';
  static const notStartedTitle = 'Your history wasn’t deleted.';
  static const unfinishedTitle = 'Couldn’t finish deleting your history.';
}
