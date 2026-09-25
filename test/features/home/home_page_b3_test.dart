import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_progress_circle.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/first_breath_provider.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/home_page.dart';
import 'package:thirty/features/home/presentation/widgets/action_report_prompt.dart';
import 'package:thirty/features/home/presentation/widgets/circle_hero.dart';
import 'package:thirty/features/premium/application/premium_offer_provider.dart';
import 'package:thirty/features/premium/presentation/widgets/premium_offer_invitation_card.dart';
import 'package:thirty/features/reminder/application/reminder_invitation_provider.dart';
import 'package:thirty/features/reminder/presentation/widgets/reminder_invitation_card.dart';

/// Phase B3 — Home's single-scroll composition: the hero and every card
/// below it are one document inside CircleHero's own scroll view. Cards
/// extend the page; they never shrink the hero or move the Circle.

final _today = DateTime(2026, 8, 2);

const _pixel7 = Size(412, 915);

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

/// Closed today, reflection still pending (no attempt answer yet).
final _closedPendingReflection = <String, Object>{
  ..._started,
  recommendationStatusKey: 'closed',
  recommendationClosedAtKey: _today.toIso8601String(),
};

/// Closed today with the reflection answered ("Not today"), so nothing is
/// pending and the invitations may take their turn.
final _closedReflected = <String, Object>{
  ..._closedPendingReflection,
  recommendationAttemptResponseKey: CircleAttemptResponse.notToday.name,
};

/// A past Circle closed on [localDate], written through the real journal.
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

/// Journal history that makes the reminder invitation eligible (one past
/// closed Circle).
Future<void> _oneClosedDay(SharedPreferences prefs) =>
    _closedCircleOn(prefs, '2026-08-01', DateTime(2026, 8, 1, 9));

/// Journal history that makes the Premium invitation eligible (two
/// distinct closed days), once the reminder invitation has been shown.
Future<void> _twoClosedDays(SharedPreferences prefs) async {
  await _closedCircleOn(prefs, '2026-07-31', DateTime(2026, 7, 31, 9));
  await _closedCircleOn(prefs, '2026-08-01', DateTime(2026, 8, 1, 9));
}

Future<(Widget, SharedPreferences)> _wrap({
  Map<String, Object> storedPrefs = const {},
  Future<void> Function(SharedPreferences prefs)? seedJournal,
  bool disableAnimations = true,
  double textScale = 1.0,
  ThemeData? theme,
}) async {
  SharedPreferences.setMockInitialValues(storedPrefs);
  final prefs = await SharedPreferences.getInstance();
  if (seedJournal != null) await seedJournal(prefs);
  final widget = ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_today),
      premiumEntitlementProvider.overrideWithValue(false),
    ],
    child: MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
            textScaler: TextScaler.linear(textScale),
          ),
          child: const HomePage(),
        ),
      ),
    ),
  );
  return (widget, prefs);
}

void _setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Finder get _homeScrollables => find.descendant(
  of: find.byType(HomePage),
  matching: find.byType(Scrollable),
);

Rect _circleRect(WidgetTester tester) =>
    tester.getRect(find.byType(ThirtyProgressCircle));

bool _visibleCards(WidgetTester tester, Type card) =>
    find
        .descendant(of: find.byType(card), matching: find.byType(Padding))
        .evaluate()
        .isNotEmpty;

void main() {
  group('One scroll owner', () {
    testWidgets('exactly one Scrollable in Home, in every state', (
      tester,
    ) async {
      for (final prefs in [
        const <String, Object>{},
        _chosen,
        _started,
        _closedPendingReflection,
      ]) {
        final (widget, _) = await _wrap(storedPrefs: prefs);
        await tester.pumpWidget(widget);
        await tester.pump();
        expect(_homeScrollables, findsOneWidget, reason: '$prefs');
      }
    });

    testWidgets('the below-hero cards live inside the hero\'s own scroll', (
      tester,
    ) async {
      final (widget, _) = await _wrap(storedPrefs: _closedPendingReflection);
      await tester.pumpWidget(widget);
      await tester.pump();

      for (final card in [
        ActionReportPrompt,
        ReminderInvitationCard,
        PremiumOfferInvitationCard,
      ]) {
        expect(
          find.descendant(
            of: find.byType(CircleHero),
            matching: find.byType(card),
          ),
          findsOneWidget,
          reason: '$card',
        );
      }
    });
  });

  group('Circle geometry (Pixel 7 logical size, 412x915)', () {
    testWidgets('identical across Ready, assigned, started, closed + '
        'reflection, reminder invitation and Premium invitation', (
      tester,
    ) async {
      _setSurface(tester, _pixel7);
      final rects = <String, Rect>{};

      Future<void> capture(
        String name, {
        Map<String, Object> prefs = const {},
        Future<void> Function(SharedPreferences)? seed,
      }) async {
        final (widget, _) = await _wrap(storedPrefs: prefs, seedJournal: seed);
        await tester.pumpWidget(widget);
        await tester.pump();
        rects[name] = _circleRect(tester);
      }

      await capture('ready');
      await capture('assigned', prefs: _chosen);
      await capture('started', prefs: _started);
      await capture('closed+reflection', prefs: _closedPendingReflection);
      await capture('assigned+reminder', prefs: _chosen, seed: _oneClosedDay);
      expect(find.text('Choose a time'), findsOneWidget);
      await capture(
        'closed+premium',
        prefs: {..._closedReflected, reminderInvitationShownKey: true},
        seed: _twoClosedDays,
      );
      expect(
        find.text('THIRTY Premium adds guided Plans, Coach and Insights.'),
        findsOneWidget,
      );

      for (final entry in rects.entries) {
        expect(entry.value, rects['ready'], reason: entry.key);
      }
    });

    testWidgets('a card below the hero neither moves nor resizes the Circle '
        'nor compresses the hero on first layout', (tester) async {
      _setSurface(tester, _pixel7);

      final (plain, _) = await _wrap(storedPrefs: _chosen);
      await tester.pumpWidget(plain);
      final circleWithout = _circleRect(tester);
      final ctaWithout = tester.getRect(find.text('Start Circle'));

      final (withCard, _) = await _wrap(
        storedPrefs: _chosen,
        seedJournal: _oneClosedDay,
      );
      await tester.pumpWidget(withCard);
      expect(find.text('Choose a time'), findsOneWidget);
      expect(_circleRect(tester), circleWithout);
      // Before B3 the hero was an Expanded above the cards, so a card took
      // height from the hero; now the whole hero, down to its CTA, keeps
      // exactly the same layout and the card simply follows it.
      expect(tester.getRect(find.text('Start Circle')), ctaWithout);
      expect(
        tester.getRect(find.text('Choose a time')).top,
        greaterThan(ctaWithout.bottom),
      );
    });
  });

  group('Cards are reached through the single page scroll', () {
    for (final (name, prefs, seed, cardText) in [
      (
        'reflection',
        _closedPendingReflection,
        null,
        'Did you try this activity?',
      ),
      ('reminder invitation', _chosen, _oneClosedDay, 'Not now'),
      (
        'Premium invitation',
        {..._closedReflected, reminderInvitationShownKey: true},
        _twoClosedDays,
        'THIRTY Premium adds guided Plans, Coach and Insights.',
      ),
    ]) {
      testWidgets('$name: below the fold at 320x568, scrolled into view by '
          'the page scroll', (tester) async {
        _setSurface(tester, const Size(320, 568));
        final (widget, _) = await _wrap(storedPrefs: prefs, seedJournal: seed);
        await tester.pumpWidget(widget);
        await tester.pump();

        final card = find.text(cardText);
        expect(card, findsOneWidget);
        final viewport = tester.getRect(_homeScrollables);
        expect(tester.getRect(card).top, greaterThan(viewport.bottom));

        await tester.scrollUntilVisible(
          card,
          200,
          scrollable: _homeScrollables,
        );
        final cardRect = tester.getRect(card);
        expect(viewport.top <= cardRect.top, isTrue);
        expect(cardRect.bottom <= viewport.bottom, isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Invitation "shown" flags', () {
    testWidgets('reminder: written on the first build even while the card is '
        'still below the fold (non-lazy)', (tester) async {
      _setSurface(tester, const Size(320, 568));
      final (widget, prefs) = await _wrap(
        storedPrefs: _chosen,
        seedJournal: _oneClosedDay,
      );
      expect(prefs.getBool(reminderInvitationShownKey), isNull);

      await tester.pumpWidget(widget);
      await tester.pump();

      final viewport = tester.getRect(_homeScrollables);
      expect(
        tester.getRect(find.text('Not now')).top,
        greaterThan(viewport.bottom),
      );
      expect(prefs.getBool(reminderInvitationShownKey), isTrue);
      expect(prefs.getBool(premiumOfferInvitationShownKey), isNull);
    });

    testWidgets('Premium: written on the first build, reminder flag '
        'untouched', (tester) async {
      _setSurface(tester, const Size(320, 568));
      final (widget, prefs) = await _wrap(
        storedPrefs: {..._closedReflected, reminderInvitationShownKey: true},
        seedJournal: _twoClosedDays,
      );
      await tester.pumpWidget(widget);
      await tester.pump();

      expect(prefs.getBool(premiumOfferInvitationShownKey), isTrue);
      expect(prefs.getBool(reminderInvitationShownKey), isTrue);
    });

    testWidgets('nothing is written while reflection is pending', (
      tester,
    ) async {
      final (widget, prefs) = await _wrap(
        storedPrefs: _closedPendingReflection,
        seedJournal: _twoClosedDays,
      );
      await tester.pumpWidget(widget);
      await tester.pump();

      expect(prefs.getBool(reminderInvitationShownKey), isNull);
      expect(prefs.getBool(premiumOfferInvitationShownKey), isNull);
    });
  });

  group('Prompt priority (unchanged)', () {
    testWidgets('reflection first: no invitation while it is pending', (
      tester,
    ) async {
      final (widget, _) = await _wrap(
        storedPrefs: _closedPendingReflection,
        seedJournal: _twoClosedDays,
      );
      await tester.pumpWidget(widget);
      await tester.pump();

      expect(find.text('Did you try this activity?'), findsOneWidget);
      expect(_visibleCards(tester, ReminderInvitationCard), isFalse);
      expect(_visibleCards(tester, PremiumOfferInvitationCard), isFalse);
    });

    testWidgets('then the reminder invitation, never stacked with Premium', (
      tester,
    ) async {
      final (widget, _) = await _wrap(
        storedPrefs: _closedReflected,
        seedJournal: _twoClosedDays,
      );
      await tester.pumpWidget(widget);
      await tester.pump();

      expect(find.text('Did you try this activity?'), findsNothing);
      expect(_visibleCards(tester, ReminderInvitationCard), isTrue);
      expect(_visibleCards(tester, PremiumOfferInvitationCard), isFalse);
    });

    testWidgets('then Premium, once the reminder invitation has been shown', (
      tester,
    ) async {
      final (widget, _) = await _wrap(
        storedPrefs: {..._closedReflected, reminderInvitationShownKey: true},
        seedJournal: _twoClosedDays,
      );
      await tester.pumpWidget(widget);
      await tester.pump();

      expect(_visibleCards(tester, ReminderInvitationCard), isFalse);
      expect(_visibleCards(tester, PremiumOfferInvitationCard), isTrue);
    });
  });

  // The same matrix with the app's real fonts, including closed + Premium,
  // lives in home_page_b3_real_font_test.dart. Closed + Premium is left
  // out here: under flutter_test's square-glyph default font the Premium
  // card's fixed "Learn more" label measures ~2x its real width and
  // reports a horizontal overflow no device shows (the card's own Row,
  // unchanged by B3).
  group('QA floor — 200% text with cards', () {
    for (final size in const [Size(320, 568), Size(360, 640)]) {
      final sizeName = '${size.width.toInt()}x${size.height.toInt()}';
      for (final (name, prefs, seed) in [
        ('closed + reflection', _closedPendingReflection, null),
        ('assigned + reminder', _chosen, _oneClosedDay),
        ('started + reminder', _started, _oneClosedDay),
      ]) {
        for (final (themeName, theme) in [
          ('light', AppTheme.light),
          ('dark', AppTheme.dark),
        ]) {
          testWidgets('$sizeName, $name, $themeName: no overflow, bottom '
              'reachable', (tester) async {
            _setSurface(tester, size);
            final (widget, _) = await _wrap(
              storedPrefs: prefs,
              seedJournal: seed,
              textScale: 2.0,
              theme: theme,
            );
            await tester.pumpWidget(widget);
            await tester.pump();
            expect(tester.takeException(), isNull);

            await tester.drag(_homeScrollables, const Offset(0, -10000));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });

  group('First Breath with a card below the hero', () {
    testWidgets('still plays 6500ms, header hidden until it settles; the '
        'card does not delay or shorten it', (tester) async {
      final (widget, prefs) = await _wrap(
        storedPrefs: _chosen,
        seedJournal: _oneClosedDay,
        disableAnimations: false,
      );
      await tester.pumpWidget(widget);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('Choose a time'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 6499));
      expect(prefs.getString(firstBreathLastPlayedDateKey), isNull);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(prefs.getString(firstBreathLastPlayedDateKey), '2026-08-02');
      await tester.pumpAndSettle();
    });

    testWidgets('reduced motion still lands on the settled state at once', (
      tester,
    ) async {
      final (widget, prefs) = await _wrap(
        storedPrefs: _chosen,
        seedJournal: _oneClosedDay,
      );
      await tester.pumpWidget(widget);
      await tester.pump();

      expect(find.text('Start Circle'), findsOneWidget);
      expect(prefs.getString(firstBreathLastPlayedDateKey), '2026-08-02');
    });
  });
}
