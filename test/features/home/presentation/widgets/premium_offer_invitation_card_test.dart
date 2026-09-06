import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/premium/application/premium_offer_provider.dart';
import 'package:thirty/features/premium/presentation/widgets/premium_offer_invitation_card.dart';

Future<(Widget, ProviderContainer)> _wrap({bool entitled = false}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      premiumEntitlementProvider.overrideWithValue(entitled),
    ],
  );
  final widget = UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: PremiumOfferInvitationCard()),
    ),
  );
  return (widget, container);
}

Future<void> _closeCircle(ProviderContainer container, String date) async {
  final journal = container.read(circleJournalRepositoryProvider);
  final circleId = 'circle_$date';
  await journal.recordShown(
    circleId: circleId,
    localDate: date,
    direction: Intention.moreEnergy,
    activityId: ActivityId.thirtyMinuteWalk,
    shownAt: DateTime.parse('${date}T08:00:00'),
  );
  await journal.recordClosed(
    circleId: circleId,
    localDate: date,
    direction: Intention.moreEnergy,
    activityId: ActivityId.thirtyMinuteWalk,
    closedAt: DateTime.parse('${date}T08:30:00'),
  );
}

void main() {
  testWidgets('renders nothing before the second closed Circle', (
    tester,
  ) async {
    final (widget, container) = await _wrap();
    addTearDown(container.dispose);
    await _closeCircle(container, '2026-09-01');

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(find.byType(PremiumOfferInvitationCard), findsOneWidget);
    expect(find.textContaining('THIRTY Premium'), findsNothing);
  });

  testWidgets('renders the quiet inline invitation after a second closed '
      'Circle on a distinct date', (tester) async {
    final (widget, container) = await _wrap();
    addTearDown(container.dispose);
    await _closeCircle(container, '2026-09-01');
    await _closeCircle(container, '2026-09-02');

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(find.textContaining('THIRTY Premium'), findsOneWidget);
    expect(find.text('Learn more'), findsOneWidget);
  });

  testWidgets('marks itself shown once rendered, so a rebuild never shows '
      'it again in the same session', (tester) async {
    final (widget, container) = await _wrap();
    addTearDown(container.dispose);
    await _closeCircle(container, '2026-09-01');
    await _closeCircle(container, '2026-09-02');

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
    expect(find.textContaining('THIRTY Premium'), findsOneWidget);

    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getBool(premiumOfferInvitationShownKey), isTrue);
  });

  testWidgets('never renders while already entitled', (tester) async {
    final (widget, container) = await _wrap(entitled: true);
    addTearDown(container.dispose);
    await _closeCircle(container, '2026-09-01');
    await _closeCircle(container, '2026-09-02');

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(find.textContaining('THIRTY Premium'), findsNothing);
  });
}
