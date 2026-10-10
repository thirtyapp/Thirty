import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/first_breath_provider.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/widgets/activity_guide_sheet.dart';
import 'package:thirty/features/home/presentation/widgets/circle_hero.dart';

/// V2 Phase A — the interim Circle: the activity's own length on the Today
/// card, the reason before Start and the first action once running, and
/// the full how-to one tap away.

final _today = DateTime(2026, 8, 2, 9);

Future<Widget> _hero({
  required Intention intention,
  required ActivityId activity,
  String? status,
}) async {
  SharedPreferences.setMockInitialValues({
    firstBreathLastPlayedDateKey: '2026-08-02',
    recommendationDayKey: '2026-08-02',
    recommendationIntentionKey: intention.name,
    recommendationActivityIdKey: activity.name,
    recommendationStatusKey: ?status,
    if (status != null) recommendationStartedAtKey: _today.toIso8601String(),
  });
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_today),
      eventClockProvider.overrideWithValue(() => _today),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: CircleHero()),
    ),
  );
}

Widget _sheet(ActivityId activity, Intention intention) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: ActivityGuideSheet(activityId: activity, intention: intention),
  ),
);

void main() {
  testWidgets('before Start: the card shows the activity\'s natural length '
      'and why it might fit — never a fixed half hour', (tester) async {
    await tester.pumpWidget(
      await _hero(
        intention: Intention.clearerHead,
        activity: ActivityId.writeItDown,
      ),
    );
    await tester.pump();

    expect(find.text('TODAY  ·  15\u00A0MIN'), findsOneWidget);
    expect(
      find.text(
        activityReasonFor(Intention.clearerHead, ActivityId.writeItDown),
      ),
      findsOneWidget,
    );
    expect(
      find.text(activityDefinition(ActivityId.writeItDown).firstAction),
      findsNothing,
    );
    expect(find.textContaining('30 min'), findsNothing);
  });

  testWidgets('once started: the first action replaces the reason, so what '
      'to do now is front and centre', (tester) async {
    await tester.pumpWidget(
      await _hero(
        intention: Intention.clearerHead,
        activity: ActivityId.writeItDown,
        status: 'started',
      ),
    );
    await tester.pump();

    expect(
      find.text(activityDefinition(ActivityId.writeItDown).firstAction),
      findsOneWidget,
    );
    expect(
      find.text(
        activityReasonFor(Intention.clearerHead, ActivityId.writeItDown),
      ),
      findsNothing,
    );
  });

  testWidgets('A quick standing stretch: started, it runs one step at a '
      'time (V2 Phase C), and the ring runs to 5 minutes', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      await _hero(
        intention: Intention.moreEnergy,
        activity: ActivityId.energisingStretchFlow,
        status: 'started',
      ),
    );
    await tester.pump();

    expect(find.text('Reach up'), findsOneWidget);
    expect(find.text('Step 1 of 5 · A quick standing stretch'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r"Today's Circle")), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel(RegExp(r"Today's Circle"))),
      matchesSemantics(
        label: "Today's Circle",
        value: 'Circle in progress. 0 of 5 minutes.',
      ),
    );
    semantics.dispose();
  });

  testWidgets('tapping the activity opens its full how-to', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      await _hero(
        intention: Intention.gentlerPace,
        activity: ActivityId.gentleStretchPause,
      ),
    );
    await tester.pump();

    final row = find.bySemanticsLabel('Gentle stretch pause');
    expect(row, findsOneWidget);
    expect(
      tester.getSemantics(row),
      matchesSemantics(
        label: 'Gentle stretch pause',
        // Before Start, while it can still be swapped (V2 Phase B).
        hint: 'How to do it, or not this one today',
        isButton: true,
        hasTapAction: true,
      ),
    );

    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.byType(ActivityGuideSheet), findsOneWidget);
    expect(find.text('Neck'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a Guided activity lists every named step with its cue, its '
      'lighter version and how to finish', (tester) async {
    await tester.pumpWidget(
      _sheet(ActivityId.energisingStretchFlow, Intention.moreEnergy),
    );
    final activity = activityDefinition(ActivityId.energisingStretchFlow);

    expect(find.text(activity.title), findsOneWidget);
    expect(find.text('About 5 minutes'), findsOneWidget);
    expect(find.textContaining('works too'), findsNothing);
    for (final step in activity.steps) {
      await tester.scrollUntilVisible(find.text(step.cue), 100);
      expect(find.text(step.name), findsOneWidget);
      expect(find.text(step.instruction), findsOneWidget);
    }
    await tester.scrollUntilVisible(find.text(activity.ending), 100);
    expect(find.text(activity.lighter!), findsOneWidget);
    expect(find.text(activity.safetyNote!), findsOneWidget);
    expect(find.textContaining('Internal draft'), findsNothing);
  });

  testWidgets('an Open activity shows its first action and its "while '
      'you\'re there" ideas', (tester) async {
    await tester.pumpWidget(_sheet(ActivityId.easyWalk, Intention.gentlerPace));
    final activity = activityDefinition(ActivityId.easyWalk);

    expect(find.text(activity.firstAction), findsOneWidget);
    for (final idea in activity.whileYoureThere) {
      await tester.scrollUntilVisible(find.text(idea), 100);
      expect(find.text(idea), findsOneWidget);
    }
  });

  testWidgets('content awaiting the safety review is marked as an internal '
      'draft whenever it is shown', (tester) async {
    await tester.pumpWidget(
      _sheet(ActivityId.restfulBreathingPause, Intention.gentlerPace),
    );

    expect(find.textContaining('Internal draft'), findsOneWidget);
  });

  testWidgets('at full scroll, the last line clears the system navigation '
      'bar (S25 device finding)', (tester) async {
    const navigationBar = 48.0;
    tester.view.physicalSize = const Size(411, 891);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: navigationBar);
    tester.view.viewPadding = const FakeViewPadding(bottom: navigationBar);
    addTearDown(tester.view.reset);

    // Opened the real way: a modal sheet, aligned to the screen's bottom.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showActivityGuide(
                context,
                activityId: ActivityId.energisingStretchFlow,
                intention: Intention.moreEnergy,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    // Fully expanded, as on the device.
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    final ending = activityDefinition(ActivityId.energisingStretchFlow).ending;
    await tester.scrollUntilVisible(find.text(ending), 100);
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).last)
        .position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();

    expect(
      tester.getRect(find.text(ending)).bottom,
      lessThanOrEqualTo(891 - navigationBar),
    );
  });
}
