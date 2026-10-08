import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/premium/entitlement_gateway.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_button.dart';
import 'package:thirty/features/premium/presentation/premium_offer_page.dart';

/// Phase C2 — the Premium offer page with the app's real fonts loaded:
/// every state at 320 / 360pt and 200% text, light and dark — nothing
/// truncated, nothing overflowing, the CTA still the 56pt hero.

/// How the store's monthly offer resolves in a test.
enum _Offer { priced, loading, none }

class _FakeEntitlementGateway implements EntitlementGateway {
  _FakeEntitlementGateway(this.status, this.offer);

  final EntitlementStatus status;
  final _Offer offer;

  @override
  Stream<EntitlementStatus> get statusUpdates => const Stream.empty();
  @override
  Future<EntitlementStatus> initialize() async => status;
  @override
  Future<MonthlyOffer?> monthlyOffer() => switch (offer) {
    // A long localized price string on purpose.
    _Offer.priced => Future.value(
      const MonthlyOffer(localizedPrice: r'US$ 4.99'),
    ),
    _Offer.loading => Completer<MonthlyOffer?>().future,
    _Offer.none => Future.value(),
  };
  @override
  Future<PurchaseOutcome> purchaseMonthly() async => PurchaseOutcome.error;
  @override
  Future<RestoreOutcome> restore() async => RestoreOutcome.notFound;
  @override
  Future<String?> managementUrl() async =>
      'https://play.google.com/store/account/subscriptions';
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

void main() {
  setUpAll(() async {
    await _loadFont('Inter', [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
    ]);
  });

  for (final width in [320.0, 360.0]) {
    for (final (label, status, offer, initialize) in [
      ('free', EntitlementStatus.inactive, _Offer.priced, true),
      ('price loading', EntitlementStatus.inactive, _Offer.loading, true),
      ('no offer', EntitlementStatus.inactive, _Offer.none, true),
      ('active', EntitlementStatus.active, _Offer.priced, true),
      ('unavailable', EntitlementStatus.unavailable, _Offer.priced, true),
      ('checking', EntitlementStatus.inactive, _Offer.priced, false),
    ]) {
      for (final (themeName, theme) in [
        ('light', AppTheme.light),
        ('dark', AppTheme.dark),
      ]) {
        testWidgets('${width.toInt()}pt, 200%, $label, $themeName: nothing '
            'truncated or overflowing', (tester) async {
          tester.view.physicalSize = Size(width, 3200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final container = ProviderContainer(
            overrides: [
              entitlementGatewayProvider.overrideWithValue(
                _FakeEntitlementGateway(status, offer),
              ),
            ],
          );
          addTearDown(container.dispose);
          if (initialize) {
            await container
                .read(entitlementStatusProvider.notifier)
                .initialize();
          }
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: theme,
                home: Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: const TextScaler.linear(2.0)),
                    child: const PremiumOfferPage(),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump();

          expect(tester.takeException(), isNull);
          final truncated = [
            for (final element in find.byType(RichText).evaluate())
              if ((element.renderObject! as RenderParagraph).didExceedMaxLines)
                (element.renderObject! as RenderParagraph).text.toPlainText(),
          ];
          expect(truncated, isEmpty);

          if (offer == _Offer.priced &&
              status == EntitlementStatus.inactive &&
              initialize) {
            // The price really rendered — not stuck loading.
            expect(find.text(r'US$ 4.99 / month'), findsOneWidget);
          }
          final cta = find.widgetWithText(ThirtyButton, 'Become Premium');
          if (cta.evaluate().isNotEmpty) {
            expect(tester.getSize(cta).height, greaterThanOrEqualTo(56));
          }
        });
      }
    }
  }
}
