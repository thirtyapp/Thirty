import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/features/insights/application/insight_provider.dart';
import 'package:thirty/features/insights/presentation/insights_page.dart';

/// The Insights tab stays alive in the shell's indexed stack, so "when the
/// user opens the relevant surface" (Batch 2C's weekly assessment) has to
/// cover more than the page's first build: coming back to the tab, coming
/// back to the app (which renews `nowProvider`), and Premium being verified
/// after the first visit — while the existing cadence and entitlement
/// guards still keep every other call a no-op.

final _day0 = DateTime(2026, 9, 1, 9);

class _Entitled extends Notifier<bool> {
  _Entitled(this.initial);

  final bool initial;

  @override
  bool build() => initial;

  void set(bool value) => state = value;
}

class _Harness {
  _Harness(this.container, this.visible, this.entitled);

  final ProviderContainer container;
  final ValueNotifier<bool> visible;
  final NotifierProvider<_Entitled, bool> entitled;

  /// Moves the device clock, as the app's own resume handler does: a new
  /// `nowProvider` value.
  DateTime clock = _day0;

  DateTime? get lastAssessedAt =>
      container.read(insightProvider).lastAssessedAt;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  bool entitled = true,
  bool visible = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final entitledProvider = NotifierProvider<_Entitled, bool>(
    () => _Entitled(entitled),
  );
  late final _Harness harness;
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWith((ref) => harness.clock),
      premiumEntitlementProvider.overrideWith(
        (ref) => ref.watch(entitledProvider),
      ),
    ],
  );
  addTearDown(container.dispose);
  final visibility = ValueNotifier(visible);
  addTearDown(visibility.dispose);
  harness = _Harness(container, visibility, entitledProvider);

  // The indexed stack's own mechanism: an inactive branch is built with
  // its TickerMode disabled.
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: ValueListenableBuilder<bool>(
          valueListenable: visibility,
          builder: (context, isVisible, child) =>
              TickerMode(enabled: isVisible, child: child!),
          child: const InsightsPage(),
        ),
      ),
    ),
  );
  await tester.pump();
  return harness;
}

Future<void> _setVisible(WidgetTester tester, _Harness h, bool visible) async {
  h.visible.value = visible;
  await tester.pump();
  await tester.pump();
}

Future<void> _resumeAt(WidgetTester tester, _Harness h, DateTime at) async {
  h.clock = at;
  h.container.invalidate(nowProvider);
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('opening the tab assesses once when due', (tester) async {
    final h = await _pump(tester);
    expect(h.lastAssessedAt, _day0);
  });

  testWidgets('a hidden tab never assesses; becoming the visible tab does', (
    tester,
  ) async {
    final h = await _pump(tester, visible: false);
    expect(h.lastAssessedAt, isNull);

    await _setVisible(tester, h, true);
    expect(h.lastAssessedAt, _day0);
  });

  testWidgets('coming back to the tab after the cadence has elapsed '
      'reassesses — no app restart needed', (tester) async {
    final h = await _pump(tester);
    expect(h.lastAssessedAt, _day0);

    await _setVisible(tester, h, false);
    final week = _day0.add(const Duration(days: insightCadenceDays));
    // Back from the background on another tab: the clock moves, but a
    // hidden Insights tab is not "opened".
    await _resumeAt(tester, h, week);
    expect(h.lastAssessedAt, _day0);

    await _setVisible(tester, h, true);
    expect(h.lastAssessedAt, week);
  });

  testWidgets('coming back to the app while on the tab reassesses once the '
      'cadence has elapsed', (tester) async {
    final h = await _pump(tester);
    final week = _day0.add(const Duration(days: insightCadenceDays));

    await _resumeAt(tester, h, week);
    expect(h.lastAssessedAt, week);
  });

  testWidgets('Premium verified after the first visit is not missed', (
    tester,
  ) async {
    // Entitlement still resolving on the first visit reads as unentitled.
    final h = await _pump(tester, entitled: false);
    expect(h.lastAssessedAt, isNull);

    h.container.read(h.entitled.notifier).set(true);
    await tester.pump();
    await tester.pump();
    expect(h.lastAssessedAt, _day0);
  });

  testWidgets('without Premium, nothing ever assesses', (tester) async {
    final h = await _pump(tester, entitled: false);
    await _setVisible(tester, h, false);
    await _setVisible(tester, h, true);
    await _resumeAt(tester, h, _day0.add(const Duration(days: 30)));
    expect(h.lastAssessedAt, isNull);
  });

  testWidgets('no repeated recomputation: tab switches and same-week '
      'resumes leave the last assessment untouched', (tester) async {
    final h = await _pump(tester);
    expect(h.lastAssessedAt, _day0);

    for (var i = 1; i <= 3; i++) {
      await _setVisible(tester, h, false);
      await _setVisible(tester, h, true);
      await _resumeAt(tester, h, _day0.add(Duration(days: i)));
    }
    // Any evaluation would have advanced it.
    expect(h.lastAssessedAt, _day0);
  });
}
