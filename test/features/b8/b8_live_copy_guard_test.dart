import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/premium/presentation/premium_offer_page.dart';
import 'package:thirty/features/settings/presentation/widgets/you_premium_card.dart';

import 'support/live_copy.dart';

/// ADR-024 B8 — content guards over the LIVE product: every string literal
/// in production source (developer-only code excluded), read in context.
///
/// Each guard is a pattern for a concept the frozen rules forbid in live
/// copy. A hit fails unless it is on the allowlist below — each entry names
/// the file, the literal and why it is not that concept (an instruction's
/// "finish", a route redirect, a migration key, the scenery's "path").
/// Every allowlist entry must still match something, so an exemption can't
/// outlive its reason. Historical documents, comments and test fixtures are
/// not scanned.
class Guard {
  const Guard(this.name, this.pattern, {this.caseSensitive = false});

  final String name;
  final String pattern;
  final bool caseSensitive;

  RegExp get rx => RegExp(pattern, caseSensitive: caseSensitive);
}

const guards = [
  Guard('retired product', r'\b(paths?|routines?|tune-?ups?|toolkit)\b'),
  Guard('false completion', r'\b(complet\w*|finished|finish)\b'),
  Guard(
    'streak / guilt',
    r'\b(streaks?|missed|perfect week|failures?|failed|behind|catch up|'
        r'keep it up|don.t break)\b',
  ),
  Guard(
    'unsupported health claim',
    r'\b(improv\w*|anxiety|recover\w*|healthier|boost\w*|diagnos\w*|'
        r'treat\w*|therap\w*|cure\w*|healing|heals?|clinically|proven|'
        r'guarantee\w*)\b',
  ),
  Guard(
    'hidden inference',
    r'\b(you need|because you|you.re (tired|stressed|anxious|low)|stressed|'
        r'tired|fatigue\w*|your mood|burn.?out)\b',
  ),
  Guard(
    'Premium drift',
    r'\b(two voices|both voices|84 (clips|files)|annual|yearly|free trial|'
        r'trial|unlimited|chatbot|chat|artificial intelligence)\b',
  ),
  Guard('AI positioning', r'\bAI\b', caseSensitive: true),
];

/// (guard, file, literal fragment, why it is allowed).
const allowlist = [
  // Retired product — never live copy.
  (
    'retired product',
    'lib/core/routing/app_router.dart',
    '/toolkit',
    'retired routes that only redirect to Yours or Today (B1)',
  ),
  (
    'retired product',
    'lib/core/worlds/catalog/quiet_trail.dart',
    'path',
    'the Quiet Trail scenery\'s art direction (a path through hills), not '
        'the retired feature',
  ),
  (
    'retired product',
    'lib/features/home/application/phase_d_retirement.dart',
    '',
    'the pre-release migration\'s storage keys (B1)',
  ),
  (
    'retired product',
    'lib/features/home/domain/recommendation_engine.dart',
    'routine:',
    'an internal evidence key for journal records that name a retired '
        'routine',
  ),
  (
    'retired product',
    'lib/features/home/presentation/widgets/circle_journal_entry_card.dart',
    'Your routine',
    'a History record from a retired routine stays readable as recorded '
        '(ADR-024 §3); such records exist only on development devices',
  ),
  // "Finish" as an instruction, a payment, or an internal message.
  (
    'false completion',
    'lib/features/home/application/activity_catalog.dart',
    '',
    'activity instructions ("Finish with easy walking", "even if the job '
        'isn’t finished") — what to do, never a claim it was done',
  ),
  (
    'false completion',
    'lib/features/personal_circle/domain/circle_elements.dart',
    '',
    'part instructions ("Finish with one long reach", "finished or not")',
  ),
  (
    'false completion',
    'lib/features/home/presentation/widgets/activity_guide_sheet.dart',
    'To finish',
    'the heading of an activity\'s last step',
  ),
  (
    'false completion',
    'lib/features/home/presentation/widgets/circle_session_card.dart',
    'To finish',
    'the heading of an activity\'s last step',
  ),
  (
    'false completion',
    'lib/features/premium/presentation/premium_offer_page.dart',
    'it completes',
    'a pending Google Play payment that completes — not a Circle',
  ),
  (
    'false completion',
    'lib/features/home/application/phase_d_retirement.dart',
    '',
    'the pre-release migration\'s storage keys (B1)',
  ),
  (
    'false completion',
    'lib/core/worlds/world.dart',
    'completedCircleCount',
    'an internal assertion message',
  ),
  // Words that are instructions, not pressure or inference.
  (
    'streak / guilt',
    'lib/features/home/application/activity_catalog.dart',
    'behind',
    'a posture instruction ("clasp your hands behind")',
  ),
  (
    'hidden inference',
    'lib/features/home/application/activity_catalog.dart',
    'you need',
    'instructions ("as long as you need", "whatever you need for a warm '
        'drink") — never a claim about the user',
  ),
  (
    'unsupported health claim',
    'lib/features/home/application/circle_journal.dart',
    'treatment',
    'the journal\'s wire keys for the lighter/fuller treatment used',
  ),
  (
    'unsupported health claim',
    'lib/features/settings/presentation/widgets/you_data_card.dart',
    'improve',
    'usage data "helps us understand what to improve" — the app, not the '
        'user',
  ),
];

void main() {
  final all = [for (final f in productionFiles()) ...literalsIn(f)];

  test('the scan reads the live product: nearly two thousand strings, the '
      'catalogue and the offer among them', () {
    expect(all.length, greaterThan(1500));
    final texts = all.map((s) => s.text).join('\n');
    expect(texts, contains(PremiumOfferPage.headline));
    expect(texts, contains('Begin today'));
    expect(all.any((s) => s.file.contains('/qa/')), isFalse);
  });

  for (final guard in guards) {
    test(
      '${guard.name}: no live copy, except where the allowlist says why',
      () {
        final violations = <String>[];
        for (final s in all) {
          if (!guard.rx.hasMatch(s.text)) continue;
          final allowed = allowlist.any(
            (a) =>
                a.$1 == guard.name && a.$2 == s.file && s.text.contains(a.$3),
          );
          if (!allowed) violations.add('${s.where}: ${s.text}');
        }
        expect(violations, isEmpty, reason: violations.join('\n'));
      },
    );
  }

  test('each guard catches its concept — the guards themselves are tested', () {
    const caught = {
      'retired product': 'Build a routine in your Toolkit',
      'false completion': 'Stage completed!',
      'streak / guilt': 'Don’t break your streak',
      'unsupported health claim': 'Clinically proven to reduce anxiety',
      'hidden inference': 'You seem tired today',
      'Premium drift': 'Start your free trial — unlimited Circles',
      'AI positioning': 'Your AI coach',
    };
    for (final guard in guards) {
      expect(
        guard.rx.hasMatch(caught[guard.name]!),
        isTrue,
        reason: guard.name,
      );
    }
    expect(guards.any((g) => g.rx.hasMatch('Your Circle for today.')), isFalse);
  });

  test('every allowlist entry still matches a live string — no exemption '
      'outlives its reason', () {
    for (final (guard, file, fragment, why) in allowlist) {
      final rx = guards.firstWhere((g) => g.name == guard).rx;
      expect(
        all.any(
          (s) =>
              s.file == file &&
              s.text.contains(fragment) &&
              rx.hasMatch(s.text),
        ),
        isTrue,
        reason: '$guard · $file · "$fragment" ($why)',
      );
    }
  });

  test('Premium is described as its three jobs, and nothing owned is said '
      'to need it', () {
    final offer = [
      PremiumOfferPage.promise,
      for (final (name, line) in PremiumOfferPage.points) '$name $line',
      YouPremiumCard.body,
    ].join('\n');
    for (final job in ['Circle', 'Plan', 'Insights']) {
      expect(offer, contains(job));
    }
    // Ownership and History are never sold as Premium.
    final owned = RegExp(
      r'(kept Circles?|History|calendar|what you keep)[^.]*\b(need|require|'
      r'only with|unlock)s?\b[^.]*Premium',
      caseSensitive: false,
    );
    for (final s in all) {
      expect(owned.hasMatch(s.text), isFalse, reason: s.where);
    }
    // Cancelling never deletes what the user owns.
    final loss = RegExp(
      r'cancel[^.]*\b(lose|delete|erase|remove)',
      caseSensitive: false,
    );
    for (final s in all) {
      expect(loss.hasMatch(s.text), isFalse, reason: s.where);
    }
  });
}
