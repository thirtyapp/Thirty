import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/premium/presentation/premium_offer_page.dart';

/// The Premium offer's words (ADR-023 §11; ADR-024): no outcome is
/// promised, and nothing retired before release — Paths, routines, tune-ups,
/// shorter versions, the Toolkit — is offered as a reason to subscribe.
/// (Moved from the retired Phase D content review, B1.) Since B7 the offer
/// describes the launch service as built: the guided Circle, Plans and
/// Insights; Free stays whole; cancelling takes nothing the user has.
void main() {
  final copy = [
    PremiumOfferPage.headline,
    PremiumOfferPage.promise,
    PremiumOfferPage.freeLine,
    for (final (name, line) in PremiumOfferPage.points) '$name $line',
    for (final (name, line) in PremiumOfferPage.voicedPoints) '$name $line',
    PremiumOfferPage.lapseLine,
    PremiumOfferPage.voicedLapseLine,
  ];

  test('no offer line promises an outcome — it may say what THIRTY does, '
      'never that it will work', () {
    const promises = [
      'so you come back',
      'lifts your',
      'you will feel',
      'you’ll feel',
      'makes you',
      'calmer',
      'clearer head',
      'better mood',
      'healthier',
      'boost',
    ];
    for (final line in copy) {
      for (final promise in promises) {
        expect(line.toLowerCase(), isNot(contains(promise)), reason: line);
      }
    }
  });

  test('no offer line sells a retired Phase D product', () {
    const retired = [
      'routine',
      'path',
      'toolkit',
      'tune',
      'shorter version',
      'upkeep',
    ];
    for (final line in copy) {
      for (final word in retired) {
        expect(line.toLowerCase(), isNot(contains(word)), reason: line);
      }
    }
  });

  group('B7: the offer describes the live product', () {
    final all = copy.join('\n');
    final points = PremiumOfferPage.points.map((p) => p.$1).toList();

    test('the three jobs: a guided Circle, Plans and Insights', () {
      expect(all, contains('guided Circle'));
      expect(
        points,
        containsAll(['Made for you', 'Plans to follow', 'Insights']),
      );
      expect(
        PremiumOfferPage.promise,
        contains('a direction for your Circles'),
      );
    });

    test('Free stays available, whole and not a trial', () {
      final free = PremiumOfferPage.freeLine;
      expect(
        free,
        startsWith(
          'With Free, THIRTY still gives you one good '
          'thing for today',
        ),
      );
      for (final kept in [
        'learns from what you tell it',
        'What it remembers',
        'History',
        'the Circles you keep',
        'reminders',
        'stay free',
      ]) {
        expect(free, contains(kept), reason: kept);
      }
    });

    test('cancelling is told truthfully: active to the end of the period, '
        'then new Premium work stops and nothing the user has is lost', () {
      for (final line in [
        PremiumOfferPage.lapseLine,
        PremiumOfferPage.voicedLapseLine,
      ]) {
        expect(line, contains('cancel anytime in Google Play'));
        expect(
          line,
          contains(
            'stays active until the end of your current '
            'billing period',
          ),
        );
        expect(line, contains('Today goes back to one good thing a day'));
        expect(line, contains('A Plan keeps its place.'));
        expect(line, contains('Insights you’ve seen stay readable'));
        expect(
          line,
          contains(
            'your History and everything you kept stay '
            'yours',
          ),
        );
      }
    });

    test('owning is never sold as Premium: no "Yours to keep" point', () {
      expect(points, isNot(contains('Yours to keep')));
    });

    test('no unsupported claim', () {
      final lower = all.toLowerCase();
      for (final claim in [
        ' ai ',
        'a.i.',
        'artificial',
        'unlimited',
        'medical',
        'therapy',
        'clinical',
        'guarantee',
        'proven',
        'lose your',
        'lost',
        'deleted',
        'removed',
        'streak',
        'annual',
        'yearly',
        'trial',
        'atmosphere',
        'statistics',
        'chat',
        'coach',
      ]) {
        expect(' $lower ', isNot(contains(claim)), reason: claim);
      }
    });
  });
}
