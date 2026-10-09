import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/widgets/daily_intention_prompt.dart';

final _today = DateTime(2026, 8, 2);

Future<(Widget, ProviderContainer)> _wrap({
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final resolved = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(resolved),
      nowProvider.overrideWithValue(_today),
    ],
  );
  final widget = UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: DailyIntentionPrompt()),
    ),
  );
  return (widget, container);
}

void main() {
  // The real font: whether the time choice shows as three segments depends
  // on real glyph widths (the test font's square glyphs never fit).
  setUpAll(() async {
    final inter = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'));
    await inter.load();
  });

  test('every need meaning is the founder-approved wording', () {
    expect(
      intentionMeaning(Intention.moreEnergy),
      'I want to feel a little more awake and active.',
    );
    expect(
      intentionMeaning(Intention.clearerHead),
      'I want fewer things competing for my attention, and one thing to '
      'focus on.',
    );
    expect(
      intentionMeaning(Intention.gentlerPace),
      "I want something gentle that doesn't feel like another demand.",
    );
  });

  testWidgets('shows the Daily Context Question and exactly three options', (
    tester,
  ) async {
    final (widget, container) = await _wrap();
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);

    expect(find.text('What would help most today?'), findsOneWidget);
    expect(find.text('More Energy'), findsOneWidget);
    expect(find.text('Clearer Head'), findsOneWidget);
    expect(find.text('Gentler Pace'), findsOneWidget);
  });

  testWidgets('tapping an option chooses that intention', (tester) async {
    final (widget, container) = await _wrap();
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);

    await tester.tap(find.text('Clearer Head'));
    await tester.pump();

    final state = container.read(recommendationProvider);
    expect(state.recommendation, isNotNull);
    expect(state.recommendation!.intent, 'Clearer Head');
  });

  testWidgets(
    'each option is exposed as a semantic button with its label and meaning',
    (tester) async {
      final (widget, container) = await _wrap();
      addTearDown(container.dispose);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(widget);

      // The underlying ThirtyButton contributes its own `button: true`
      // Semantics node too (label-only, no meaning) — but this widget's
      // ExcludeSemantics wrapper drops that inner node from the real
      // semantics tree, so only this widget's own combined-label node
      // remains there. Reading the actual runtime semantics tree (not
      // walking Semantics widgets in the widget tree, which would still
      // see both) is what correctly reflects what an assistive technology
      // is exposed to.
      final semantics = tester
          .getSemantics(find.text('More Energy'))
          .getSemanticsData();

      expect(semantics.flagsCollection.isButton, isTrue);
      expect(
        semantics.label,
        'More Energy. ${intentionMeaning(Intention.moreEnergy)}',
      );

      handle.dispose();
    },
  );

  testWidgets(
    'a real assistive-technology tap action (SemanticsAction.tap), not '
    'just the button/label flags, actually chooses the intention '
    '(ADR-013 §9)',
    (tester) async {
      final (widget, container) = await _wrap();
      addTearDown(container.dispose);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(widget);

      // find.bySemanticsLabel resolves via the runtime SemanticsNode tree
      // itself (unlike find.text, which walks up from the render object
      // and can land on an unrelated ancestor node) — the precise way to
      // target the exact node an assistive technology would activate.
      final semantics = tester.getSemantics(
        find.bySemanticsLabel(
          'Clearer Head. ${intentionMeaning(Intention.clearerHead)}',
        ),
      );
      expect(
        semantics.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
        reason:
            'the node TalkBack would activate must itself carry a tap '
            'action — a label/button flag alone is not enough',
      );

      // ignore: deprecated_member_use
      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        semantics.id,
        SemanticsAction.tap,
      );
      await tester.pump();

      final state = container.read(recommendationProvider);
      expect(state.recommendation, isNotNull);
      expect(state.recommendation!.intent, 'Clearer Head');

      handle.dispose();
    },
  );

  testWidgets('shows only the question and the three choices — no explanatory '
      'paragraph — matching the restrained question/choice rhythm of the '
      'post-Circle feedback UI (emulator polish)', (tester) async {
    final (widget, container) = await _wrap();
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);

    expect(find.textContaining('THIRTY gives you one activity'), findsNothing);
    // Exactly the question, the time already chosen (V2 Phase B) and the
    // three needs — nothing else.
    expect(
      tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList(),
      [
        'What would help most today?',
        'Time you have',
        '10 min',
        '20 min',
        '30 min',
        'More Energy',
        'Clearer Head',
        'Gentler Pace',
      ],
    );
  });
}
