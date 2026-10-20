import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/routing/app_router.dart';
import 'package:thirty/core/routing/app_shell.dart';
import 'package:thirty/features/home/presentation/circle_history_page.dart';
import 'package:thirty/features/home/presentation/circle_record_detail_page.dart';
import 'package:thirty/features/home/presentation/home_page.dart';
import 'package:thirty/features/home/presentation/memory_page.dart';
import 'package:thirty/features/insights/presentation/insights_page.dart';
import 'package:thirty/features/personal_circle/presentation/yours_page.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';
import 'package:thirty/features/plans/domain/plan_copy.dart';
import 'package:thirty/features/plans/presentation/plan_detail_page.dart';
import 'package:thirty/features/plans/presentation/plans_page.dart';
import 'package:thirty/features/premium/presentation/premium_offer_page.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';
import 'package:thirty/features/settings/presentation/settings_page.dart';

class _SettledEntitlement extends EntitlementNotifier {
  _SettledEntitlement(this._status);

  final EntitlementStatus _status;

  @override
  EntitlementStatus build() => _status;
}

const _tabs = ['Today', 'Plans', 'Insights', 'You'];

/// B7 — the final shell and its routes, through the real `appRouter` and
/// `ThirtyApp`: Today | Plans | Insights | You, each root stable, Back
/// coherent (nested pages return to their parent; a tab root never bounces
/// through other tabs; a page opened by its own location returns to its
/// parent surface), and every direct route safe in every entitlement state —
/// no route checks Premium, so a route never grants it.
///
/// `appRouter` is shared across tests: each test starts at `/`.
void main() {
  late SharedPreferences prefs;

  Future<void> pumpApp(
    WidgetTester tester, {
    EntitlementStatus status = EntitlementStatus.active,
    bool keepPrefs = false,
    double height = 915,
  }) async {
    if (!keepPrefs) {
      SharedPreferences.setMockInitialValues({firstNamePromptSeenKey: true});
      prefs = await SharedPreferences.getInstance();
    }
    tester.view.physicalSize = Size(412, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          entitlementStatusProvider.overrideWith(
            () => _SettledEntitlement(status),
          ),
        ],
        child: const ThirtyApp(),
      ),
    );
    await tester.pumpAndSettle();
    appRouter.go('/');
    await tester.pumpAndSettle();
  }

  Finder tab(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  int selected(WidgetTester tester) =>
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

  Future<void> go(WidgetTester tester, String location) async {
    appRouter.go(location);
    await tester.pumpAndSettle();
  }

  Future<void> push(WidgetTester tester, String location) async {
    appRouter.push(location);
    await tester.pumpAndSettle();
  }

  /// The system Back gesture. `true` when the app handled it; `false` when
  /// Android would leave the app.
  Future<bool> systemBack(WidgetTester tester) async {
    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    return handled;
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(ThirtyApp)));

  group('the four tabs', () {
    testWidgets('exactly Today | Plans | Insights | You, in that order; no '
        'Toolkit, Journal, Paths or Coach tab', (tester) async {
      await pumpApp(tester);
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(
        bar.destinations.cast<NavigationDestination>().map((d) => d.label),
        _tabs,
      );
      for (final retired in ['Toolkit', 'Journal', 'Paths', 'Coach']) {
        expect(tab(retired), findsNothing, reason: retired);
      }
    });

    for (final (index, (location, page)) in const [
      ('/', HomePage),
      ('/plans', PlansPage),
      ('/insights', InsightsPage),
      ('/settings', SettingsPage),
    ].indexed) {
      testWidgets('$location is the ${_tabs[index]} root, inside the shell, '
          'with ${_tabs[index]} selected', (tester) async {
        await pumpApp(tester);
        await go(tester, location);
        expect(find.byType(page), findsOneWidget);
        expect(find.byType(AppShell), findsOneWidget);
        expect(selected(tester), index);
        // A root has nothing to go back to: no back arrow.
        expect(find.byType(BackButton), findsNothing);
      });
    }

    testWidgets('TalkBack hears each tab by name and position, and which is '
        'selected', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpApp(tester);
      for (final (index, label) in _tabs.indexed) {
        await tester.tap(tab(label));
        await tester.pumpAndSettle();
        for (final (other, otherLabel) in _tabs.indexed) {
          final node = tester.getSemantics(
            find.descendant(
              of: find.byType(NavigationBar),
              matching: find.bySemanticsLabel(
                RegExp('^$otherLabel\\nTab ${other + 1} of 4\$'),
              ),
            ),
          );
          expect(
            node,
            isSemantics(isSelected: other == index),
            reason: '$otherLabel while on $label',
          );
        }
      }
      semantics.dispose();
    });

    testWidgets('no tab carries a badge or a lock, and opening Plans or '
        'Insights on Free never opens the offer', (tester) async {
      await pumpApp(tester, status: EntitlementStatus.inactive);
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byType(Badge),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsNothing,
      );
      for (final label in _tabs) {
        await tester.tap(tab(label));
        await tester.pumpAndSettle();
        expect(find.byType(PremiumOfferPage), findsNothing, reason: label);
      }
    });
  });

  group('Back', () {
    testWidgets('at a tab root, Back never bounces through the tabs '
        'visited before', (tester) async {
      await pumpApp(tester);
      for (final label in ['Plans', 'Insights', 'You', 'Insights']) {
        await tester.tap(tab(label));
        await tester.pumpAndSettle();
      }
      expect(await systemBack(tester), isFalse);
      expect(selected(tester), 2);
      expect(find.byType(InsightsPage), findsOneWidget);
    });

    testWidgets('Plan detail → Plans', (tester) async {
      await pumpApp(tester);
      await tester.tap(tab('Plans'));
      await tester.pumpAndSettle();
      await push(tester, '/plans/making_room');
      expect(find.byType(PlanDetailPage), findsOneWidget);
      expect(selected(tester), 1);
      expect(await systemBack(tester), isTrue);
      expect(find.byType(PlansPage), findsOneWidget);
      expect(find.byType(PlanDetailPage), findsNothing);
    });

    testWidgets('Insights → a date → History list → back to Insights, the '
        'tab still selected', (tester) async {
      await pumpApp(tester);
      await tester.tap(tab('Insights'));
      await tester.pumpAndSettle();
      await push(tester, '/history');
      expect(find.byType(CircleHistoryPage), findsOneWidget);
      await push(tester, '/history/2026-10-12');
      expect(find.byType(CircleRecordDetailPage), findsOneWidget);
      expect(await systemBack(tester), isTrue);
      expect(find.byType(CircleHistoryPage), findsOneWidget);
      expect(await systemBack(tester), isTrue);
      expect(find.byType(InsightsPage), findsOneWidget);
      expect(selected(tester), 2);
    });

    testWidgets('the offer returns to the surface that opened it — Back, '
        'or Not now', (tester) async {
      await pumpApp(tester, status: EntitlementStatus.inactive, height: 2400);
      await tester.tap(tab('You'));
      await tester.pumpAndSettle();
      await push(tester, '/premium');
      expect(find.byType(PremiumOfferPage), findsOneWidget);
      expect(await systemBack(tester), isTrue);
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(selected(tester), 3);

      await tester.tap(tab('Plans'));
      await tester.pumpAndSettle();
      await push(tester, '/premium');
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(find.byType(PlansPage), findsOneWidget);
      expect(selected(tester), 1);
    });

    testWidgets('an Insight\'s Plan opens over Insights and returns to it', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(tab('Insights'));
      await tester.pumpAndSettle();
      await push(tester, '/plans/making_room');
      expect(find.byType(PlanDetailPage), findsOneWidget);
      expect(await systemBack(tester), isTrue);
      expect(find.byType(InsightsPage), findsOneWidget);
      expect(selected(tester), 2);
    });

    for (final (location, page, parent, parentPage) in const [
      ('/history/2026-10-12', CircleRecordDetailPage, 'Insights', InsightsPage),
      ('/history', CircleHistoryPage, 'Insights', InsightsPage),
      ('/premium', PremiumOfferPage, 'Today', HomePage),
      ('/memory', MemoryPage, 'You', SettingsPage),
    ]) {
      testWidgets('$location opened by its own location: Back leads to '
          '$parent, never out of the app', (tester) async {
        await pumpApp(tester);
        await go(tester, location);
        expect(find.byType(page), findsOneWidget);
        expect(find.byType(AppShell), findsNothing);
        // The arrow…
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byType(parentPage), findsOneWidget);
        expect(selected(tester), _tabs.indexOf(parent));
        // …and the system gesture.
        await go(tester, location);
        expect(await systemBack(tester), isTrue);
        expect(find.byType(parentPage), findsOneWidget);
      });
    }
  });

  group('state across tabs', () {
    testWidgets('switching tabs keeps each tab where it was: the Insights '
        'month, a Plan opened in Plans', (tester) async {
      await pumpApp(tester);
      await tester.tap(tab('Insights'));
      await tester.pumpAndSettle();
      final month = find.textContaining(RegExp(r'^\w+ \d{4}$'));
      final shown = tester.widget<Text>(month.first).data;
      await tester.ensureVisible(find.byTooltip('Previous month'));
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      final earlier = tester.widget<Text>(month.first).data;
      expect(earlier, isNot(shown));

      await tester.tap(tab('Plans'));
      await tester.pumpAndSettle();
      await push(tester, '/plans/slowing_down');
      await tester.tap(tab('Today'));
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);

      await tester.tap(tab('Insights'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(month.first).data, earlier);
      await tester.tap(tab('Plans'));
      await tester.pumpAndSettle();
      expect(find.byType(PlanDetailPage), findsOneWidget);
      // Tapping the tab already chosen returns it to its root.
      await tester.tap(tab('Plans'));
      await tester.pumpAndSettle();
      expect(find.byType(PlanDetailPage), findsNothing);
      expect(find.byType(PlansPage), findsOneWidget);
    });
  });

  group('direct routes in every entitlement state', () {
    for (final status in EntitlementStatus.values) {
      testWidgets('${status.name}: /plans, /plans/:id, /insights, /history, '
          '/history/:date and /premium open safely; no route runs a paid '
          'action', (tester) async {
        // Tall enough that each page is built whole.
        await pumpApp(tester, status: status, height: 2400);
        final paid = status == EntitlementStatus.active;
        for (final (location, page) in const [
          ('/plans', PlansPage),
          ('/plans/getting_going', PlanDetailPage),
          ('/insights', InsightsPage),
          ('/history', CircleHistoryPage),
          ('/history/2026-10-12', CircleRecordDetailPage),
          ('/premium', PremiumOfferPage),
        ]) {
          await go(tester, location);
          expect(tester.takeException(), isNull, reason: location);
          expect(find.byType(page), findsOneWidget, reason: location);
          // Opening a page never started anything.
          expect(
            container(tester).read(circlePlansProvider).plans,
            isEmpty,
            reason: location,
          );
        }
        await go(tester, '/plans/getting_going');
        expect(
          find.text(paid ? PlanCopy.start : PlanCopy.startWithPremium),
          findsWidgets,
        );
        // The offer: a purchase only for a settled Free user (here the
        // store has no price, so there is no Become Premium either).
        await go(tester, '/premium');
        expect(
          find.text('Not now'),
          status == EntitlementStatus.inactive ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('Premium is active'),
          paid ? findsOneWidget : findsNothing,
        );
      });
    }

    testWidgets('lapsed: the saved Plan place and its page stay; the paid '
        'action leads to the offer, never runs', (tester) async {
      await pumpApp(tester);
      expect(
        container(
          tester,
        ).read(circlePlansProvider.notifier).start('making_room'),
        PlanActionResult.done,
      );
      await tester.pumpAndSettle();
      await pumpApp(
        tester,
        status: EntitlementStatus.inactive,
        keepPrefs: true,
      );
      await go(tester, '/plans/making_room');
      expect(find.byType(PlanDetailPage), findsOneWidget);
      expect(
        container(tester).read(circlePlansProvider).lifecycleOf('making_room'),
        PlanLifecycle.active,
      );
      expect(find.text(PlanCopy.continueWithPremium), findsWidgets);
      await go(tester, '/insights');
      expect(find.byType(InsightsPage), findsOneWidget);
    });

    testWidgets('invalid ids are safe: an unknown Plan opens Plans; an unknown '
        'or malformed date says the record is not there', (tester) async {
      await pumpApp(tester);
      for (final location in ['/plans/notAPlan', '/plans/moreEnergyPath']) {
        await go(tester, location);
        expect(find.byType(PlansPage), findsOneWidget, reason: location);
        expect(find.byType(PlanDetailPage), findsNothing, reason: location);
      }
      for (final location in ['/history/2026-13-40', '/history/not-a-date']) {
        await go(tester, location);
        expect(tester.takeException(), isNull, reason: location);
        expect(
          find.byType(CircleRecordDetailPage),
          findsOneWidget,
          reason: location,
        );
        expect(
          find.textContaining('anymore', findRichText: true),
          findsOneWidget,
          reason: location,
        );
      }
    });

    testWidgets('retired roots lead to current pages: no Toolkit, Path or '
        'routine page exists', (tester) async {
      await pumpApp(tester);
      await go(tester, '/toolkit');
      expect(find.byType(YoursPage), findsOneWidget);
      expect(selected(tester), 3);
      for (final retired in [
        '/toolkit/paths',
        '/toolkit/review',
        '/toolkit/routine/routine-1',
      ]) {
        await go(tester, retired);
        expect(find.byType(HomePage), findsOneWidget, reason: retired);
      }
      for (final label in ['Toolkit', 'routine', 'Path']) {
        expect(find.textContaining(label), findsNothing, reason: label);
      }
    });
  });

  test('every launch Plan id is a direct route', () {
    expect(circlePlanById.keys, [
      'getting_going',
      'making_room',
      'slowing_down',
    ]);
  });
}
