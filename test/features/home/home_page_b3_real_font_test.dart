import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/home_page.dart';
import 'package:thirty/features/reminder/application/reminder_invitation_provider.dart';

/// Phase B3 QA floor with the app's real fonts (Inter, Newsreader) loaded,
/// so 200% text is measured the way a device renders it. flutter_test's
/// default font draws every glyph as a full square, which roughly doubles
/// the width of short fixed labels (e.g. the Premium card's "Learn more")
/// and reports overflows no real device shows.

final _today = DateTime(2026, 8, 2);

const _chosen = <String, Object>{
  recommendationDayKey: '2026-08-02',
  recommendationIntentionKey: 'moreEnergy',
  recommendationActivityIdKey: 'thirtyMinuteWalk',
};

final _started = <String, Object>{
  ..._chosen,
  recommendationStatusKey: 'started',
  recommendationStartedAtKey: _today.toIso8601String(),
};

final _closedPendingReflection = <String, Object>{
  ..._started,
  recommendationStatusKey: 'closed',
  recommendationClosedAtKey: _today.toIso8601String(),
};

final _closedReflected = <String, Object>{
  ..._closedPendingReflection,
  recommendationAttemptResponseKey: CircleAttemptResponse.notToday.name,
};

Future<void> _closedCircleOn(
  SharedPreferences prefs,
  String localDate,
  DateTime at,
) async {
  final journal = CircleJournalRepository(prefs);
  await journal.recordShown(
    circleId: localDate,
    localDate: localDate,
    direction: Intention.moreEnergy,
    activityId: ActivityId.thirtyMinuteWalk,
    shownAt: at,
  );
  await journal.recordClosed(
    circleId: localDate,
    localDate: localDate,
    direction: Intention.moreEnergy,
    activityId: ActivityId.thirtyMinuteWalk,
    closedAt: at.add(const Duration(minutes: 30)),
  );
}

Future<void> _oneClosedDay(SharedPreferences prefs) =>
    _closedCircleOn(prefs, '2026-08-01', DateTime(2026, 8, 1, 9));

Future<void> _twoClosedDays(SharedPreferences prefs) async {
  await _closedCircleOn(prefs, '2026-07-31', DateTime(2026, 7, 31, 9));
  await _closedCircleOn(prefs, '2026-08-01', DateTime(2026, 8, 1, 9));
}

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    final bytes = File(file).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    await _loadFont('Inter', [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
    ]);
    await _loadFont('Newsreader', ['assets/fonts/Newsreader[opsz,wght].ttf']);
  });

  for (final size in const [Size(320, 568), Size(360, 640)]) {
    final sizeName = '${size.width.toInt()}x${size.height.toInt()}';
    for (final (name, prefs, seed) in [
      ('Ready', const <String, Object>{}, null),
      ('assigned', _chosen, null),
      ('started', _started, null),
      ('closed + reflection', _closedPendingReflection, null),
      ('assigned + reminder', _chosen, _oneClosedDay),
      ('started + reminder', _started, _oneClosedDay),
      (
        'closed + Premium',
        {..._closedReflected, reminderInvitationShownKey: true},
        _twoClosedDays,
      ),
    ]) {
      for (final (themeName, theme) in [
        ('light', AppTheme.light),
        ('dark', AppTheme.dark),
      ]) {
        testWidgets('real fonts, $sizeName, 200% text, $name, $themeName: no '
            'overflow; the whole page is reachable', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          SharedPreferences.setMockInitialValues(prefs);
          final sharedPrefs = await SharedPreferences.getInstance();
          if (seed != null) await seed(sharedPrefs);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(sharedPrefs),
                nowProvider.overrideWithValue(_today),
                premiumEntitlementProvider.overrideWithValue(false),
              ],
              child: MaterialApp(
                theme: theme,
                home: Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      disableAnimations: true,
                      textScaler: const TextScaler.linear(2.0),
                    ),
                    child: const HomePage(),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);

          final scrollable = find.descendant(
            of: find.byType(HomePage),
            matching: find.byType(Scrollable),
          );
          expect(scrollable, findsOneWidget);
          await tester.drag(scrollable, const Offset(0, -10000));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
