import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/routing/app_router.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';

import '../features/l1/l1_fixture.dart';
import '../support/r8_harness.dart';

/// L-INF black-box golden (tests S-3 and S-13; also Free/Premium and the
/// calendar's TalkBack labels).
///
/// For each fixture store × entitlement × device language, the whole app
/// runs on the store: Today, Plans, Insights (with the calendar), History,
/// What THIRTY remembers and You; Copy as text in You; and the reminder's
/// time picker, opened and cancelled. Recorded: every text and every
/// TalkBack label on each screen, the exported text, and every stored value
/// afterwards — exactly, with its type.
///
/// The golden was recorded by this same file on the pre-L-INF tree
/// `b62984bc` (it uses nothing L-INF added). There every device language
/// gave the same record (checked when recording), so the golden holds one
/// record per fixture and entitlement, and every language here is compared
/// with it: the same words, the same TalkBack labels, the same export and
/// the same stored bytes as before, on every device language.
///
/// Record (on the baseline tree only):
/// `flutter test test/l10n/l_inf_black_box_golden_test.dart
///  --dart-define=WRITE_L_INF_GOLDEN=true`.
const _golden = 'test/l10n/l_inf_black_box_golden_b62984bc.json';
const _write = bool.fromEnvironment('WRITE_L_INF_GOLDEN');

const _locales = [
  Locale('en', 'US'),
  Locale('fr', 'BE'),
  Locale('nl', 'BE'),
  Locale('es', 'ES'),
  Locale('de', 'DE'),
  Locale('it', 'IT'),
  Locale('ja', 'JP'),
];

const _screens = [
  '/',
  '/plans',
  '/insights',
  '/history',
  '/memory',
  '/settings',
];

/// The fixture stores, derived from the L-1 fixture (real History, an
/// applied Insight, a started Plan and a kept Circle).
Map<String, Map<String, Object>> fixtures(L1Fixture f) {
  // The L-1 fixture keeps a Circle under a freshly allocated id (random
  // bits), so each seeding differs; one fixed id makes the stores the same
  // on every run and every tree.
  final allocated = RegExp(
    r'kept-\d+-[0-9a-f]{12}',
  ).firstMatch(f.store[keptCirclesKey]! as String)!.group(0)!;
  Object fixed(Object v) => switch (v) {
    final String s => s.replaceAll(
      allocated,
      'kept-1793347200000000-00000000f1ed',
    ),
    final List<String> l => [for (final s in l) fixed(s) as String],
    _ => v,
  };
  Map<String, Object> stable(Map<String, Object> s) => {
    for (final MapEntry(:key, :value) in s.entries) key: fixed(value),
  };
  final rich = stable(f.withPreferences(L1Fixture.readable));
  final journal =
      jsonDecode(rich[circleJournalKey]! as String) as Map<String, Object?>;
  final entries = (journal['entries']! as List).cast<Map<String, Object?>>();
  final kept =
      jsonDecode(rich[keptCirclesKey]! as String) as Map<String, Object?>;
  final keptList = (kept['kept']! as List).cast<Map<String, Object?>>();
  return {
    'rich': rich,
    'prefsNewerSchema': stable(f.withPreferences(L1Fixture.newerSchema)),
    'prefsNativeInt': stable(f.withPreferences(L1Fixture.nativeInt)),
    'prefsUnreadableItem': stable(f.withPreferences(L1Fixture.unreadableItem)),
    'journalForwardEntry': {
      ...rich,
      circleJournalKey: jsonEncode({
        ...journal,
        'entries': [
          ...entries,
          {
            ...entries.first,
            'schemaVersion': circleJournalSchemaVersion + 1,
            'circleId': '2026-10-29',
            'localDate': '2026-10-29',
            'fieldFromANewerBuild': {'kept': true},
          },
        ],
      }),
    },
    'journalUnreadable': {...rich, circleJournalKey: '{"schemaVersion": 2, '},
    'keptDamagedAndUnknown': {
      ...rich,
      keptCirclesKey: jsonEncode({
        ...kept,
        'kept': [
          {...keptList.first, 'wording': 'damaged'},
          {
            ...keptList.first,
            'id': 'kept-from-a-newer-build',
            'name': 'From a newer build',
            'parts': ['partFromANewerBuild:5'],
          },
        ],
      }),
    },
    'storesUnreadable': {
      ...rich,
      circlePlansKey: '{broken',
      insightsKey: '[]',
      keptCirclesUnreadableKey: 'kept before',
    },
    'firstRunEmpty': <String, Object>{},
  };
}

Map<String, Object?> typed(Object? v) => switch (v) {
  final String s => {'string': s},
  final bool b => {'bool': b},
  final int i => {'int': i},
  final double d => {
    'double': [
      for (final b in (ByteData(8)..setFloat64(0, d)).buffer.asUint8List()) b,
    ],
  },
  final List<String> l => {'stringList': l},
  _ => {'other': '$v'},
};

/// Every label, value, hint and tooltip in the semantics tree, in order.
List<String> semantics(WidgetTester tester) {
  final out = <String>[];
  void visit(SemanticsNode node) {
    final d = node.getSemanticsData();
    final parts = [
      d.label,
      d.value,
      d.hint,
      d.tooltip,
    ].where((s) => s.isNotEmpty);
    if (parts.isNotEmpty) out.add(parts.join(' | '));
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

Future<Map<String, Object?>> screen(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  return {
    'text': [
      for (final t in tester.widgetList<RichText>(find.byType(RichText)))
        t.text.toPlainText(),
    ],
    'semantics': semantics(tester),
  };
}

void main() {
  late L1Fixture f;
  setUpAll(() async => f = await L1Fixture.seed());

  final recorded = <String, Object?>{};
  final golden = _write
      ? const <String, Object?>{}
      : jsonDecode(File(_golden).readAsStringSync()) as Map<String, Object?>;
  if (_write) {
    // One record per fixture and entitlement: on the baseline tree every
    // device language gave the same record — checked here before writing.
    tearDownAll(() {
      final collapsed = <String, Object?>{};
      for (final MapEntry(:key, :value) in recorded.entries) {
        final group = key.substring(0, key.lastIndexOf('/'));
        final previous = collapsed[group];
        if (previous != null && jsonEncode(previous) != jsonEncode(value)) {
          throw StateError('$key differs from another language on this tree');
        }
        collapsed[group] = value;
      }
      File(_golden).writeAsStringSync('${jsonEncode(collapsed)}\n');
    });
  }

  const names = [
    'rich',
    'prefsNewerSchema',
    'prefsNativeInt',
    'prefsUnreadableItem',
    'journalForwardEntry',
    'journalUnreadable',
    'keptDamagedAndUnknown',
    'storesUnreadable',
    'firstRunEmpty',
  ];
  for (final name in names) {
    for (final status in [
      EntitlementStatus.active,
      if (name == 'rich' || name == 'firstRunEmpty') EntitlementStatus.inactive,
    ]) {
      for (final locale in _locales) {
        final group = '$name/${status.name}';
        final id = '$group/$locale';
        testWidgets(id, (tester) async {
          tester.platformDispatcher.localesTestValue = [locale];
          tester.platformDispatcher.localeTestValue = locale;
          addTearDown(tester.platformDispatcher.clearLocalesTestValue);
          addTearDown(tester.platformDispatcher.clearLocaleTestValue);
          tester.view.physicalSize = const Size(412, 2400);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final handle = tester.ensureSemantics();
          final clipboard = FakeClipboard()..install(tester);

          final input = {firstNamePromptSeenKey: true, ...fixtures(f)[name]!};
          final h = R8Harness(L1Fixture.morning);
          await h.boot(input);
          final c = h.open(status: status);
          appRouter.go('/');
          await tester.pumpWidget(
            UncontrolledProviderScope(container: c, child: const ThirtyApp()),
          );
          await tester.pumpAndSettle();

          final screens = <String, Object?>{};
          for (final route in _screens) {
            appRouter.go(route);
            await tester.pumpAndSettle();
            screens[route] = await screen(tester);
          }

          // Copy as text, from You.
          final copy = find.text('Copy as text');
          String? exported;
          if (copy.evaluate().isNotEmpty) {
            await tester.ensureVisible(copy.first);
            await tester.pumpAndSettle();
            await tester.tap(copy.first);
            await tester.pumpAndSettle();
            exported = clipboard.copied.isEmpty ? null : clipboard.copied.last;
          }

          // The reminder's time picker, opened and cancelled.
          final reminder = find.descendant(
            of: find.ancestor(
              of: find.text('Daily reminder'),
              matching: find.byType(MergeSemantics),
            ),
            matching: find.byType(Switch),
          );
          if (reminder.evaluate().isNotEmpty) {
            await tester.ensureVisible(reminder.first);
            await tester.pumpAndSettle();
            await tester.tap(reminder.first);
            await tester.pumpAndSettle();
            screens['timePicker'] = await screen(tester);
            await tester.tap(find.text('Cancel'));
            await tester.pumpAndSettle();
          }

          await tester.pumpWidget(const SizedBox());
          // Let queued writes land (fake time: pump, never wait on real
          // timers inside a widget test).
          for (var i = 0; i < 20; i++) {
            await tester.pump(const Duration(milliseconds: 50));
          }
          final stored = await h.disk.stored();
          handle.dispose();

          final record = <String, Object?>{
            'screens': screens,
            'export': exported,
            'stored': {
              for (final k in stored.keys.toList()..sort()) k: typed(stored[k]),
            },
          };
          // A plain JSON round trip, as the golden file holds it.
          final normalized = jsonDecode(jsonEncode(record));
          if (_write) {
            recorded[id] = normalized;
            return;
          }
          final expected = golden[group] as Map<String, Object?>?;
          expect(expected, isNotNull, reason: 'no golden for $group');
          final actual = normalized as Map<String, Object?>;
          expect(actual['stored'], expected!['stored'], reason: 'stored bytes');
          expect(actual['export'], expected['export'], reason: 'Copy as text');
          final actualScreens = actual['screens']! as Map<String, Object?>;
          final expectedScreens = expected['screens']! as Map<String, Object?>;
          expect(actualScreens.keys, expectedScreens.keys);
          for (final s in expectedScreens.keys) {
            expect(actualScreens[s], expectedScreens[s], reason: 'screen $s');
          }
        }, timeout: const Timeout(Duration(minutes: 3)));
      }
    }
  }
}
