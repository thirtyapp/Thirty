import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/toolkit/application/toolkit_provider.dart';
import 'package:thirty/features/toolkit/domain/toolkit_model.dart';

/// V2 Phase D2 correction pass (2026-10-11) — the saved-Circle / lapse
/// attack. **Not a willingness-to-pay test.** It pins the exact product
/// boundary where Circles the user kept could stand in for new Premium
/// composition, through the production providers:
///
/// - days 1–40, Premium: composed Circles; the user keeps one every few
///   days, up to the ownership limit, and sometimes uses one instead;
/// - days 41–100, lapsed: whenever a kept Circle for today's need fits
///   today's time, the user chooses it with "Use it today"; otherwise
///   Free's Today;
/// - days 101–120, Premium again.
///
/// Whether kept Circles substitute for the subscription is a COMMERCIAL
/// HYPOTHESIS for the post-D2 audit; ownership is not weakened here.
///
/// `--dart-define=TRACE=true` writes the day lines and the lapse report to
/// `build/saved_circle_lapse_attack.json`.
const _trace = bool.fromEnvironment('TRACE');

final _start = DateTime(2026, 3, 2, 9);

const _premiumUntil = 40;
const _lapsedUntil = 100;
const _lastDay = 120;

bool _entitled(int day) => day <= _premiumUntil || day > _lapsedUntil;

Intention _need(int day) => const [
  Intention.clearerHead,
  Intention.moreEnergy,
  Intention.gentlerPace,
][day % 3];

TimeWindow _window(int day) => const [
  TimeWindow.about20,
  TimeWindow.about10,
  TimeWindow.upTo30,
  TimeWindow.about20,
][(day ~/ 3) % 4];

/// What served a day.
enum Served { composed, keptChosen, free }

void main() {
  test(
    'saved Circles and lapse: owned stays owned, never offered unasked, '
    'one Circle a day; composition stops on lapse and resumes at once',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final served = <int, Served>{};
      final lines = <String>[];
      final keptIdsAtLapse = <String>[];
      String? renamedId;

      Future<void> settle() async {
        for (var i = 0; i < 6; i++) {
          await Future<void>.delayed(Duration.zero);
        }
      }

      for (var day = 1; day <= _lastDay; day++) {
        final morning = _start.add(Duration(days: day - 1));
        var clock = morning;
        final entitled = _entitled(day);
        final c = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            nowProvider.overrideWithValue(morning),
            eventClockProvider.overrideWithValue(() => clock),
            premiumEntitlementProvider.overrideWithValue(entitled),
            safetyPendingAllowedProvider.overrideWithValue(false),
          ],
        );
        try {
          await settle();
          final need = _need(day);
          final window = _window(day);
          final notifier = c.read(recommendationProvider.notifier);
          final toolkit = c.read(toolkitProvider);
          notifier.chooseIntention(need, window: window);
          final offered = c.read(recommendationProvider).recommendation!;

          // Never offered unasked: Today is never a kept Circle on its own.
          expect(offered.composed?.isKept ?? false, isFalse, reason: 'D$day');
          if (entitled) {
            // Premium every day it is active — from the first day back.
            expect(offered.composed, isNotNull, reason: 'D$day');
          } else {
            // New composition stops on lapse; Free is not a "fallback".
            expect(offered.composed, isNull, reason: 'D$day');
            expect(offered.composerFellBack, isFalse, reason: 'D$day');
          }

          // The user's own choice: a kept Circle for today's need that fits
          // today's time — every lapsed day one exists, and now and then
          // while Premium.
          final candidates = [
            for (final k in toolkit.kept)
              if (k.need == need && k.minutes <= window.maxMinutes) k,
          ];
          final choose =
              candidates.isNotEmpty &&
              (!entitled || (day > 20 && day % 5 == 0));
          KeptCircle? chosen;
          if (choose) {
            chosen = candidates[day % candidates.length];
            // "Use it today" is Free: it works whatever Premium's state.
            expect(
              notifier.useOwnedToday(keptCircleId: chosen.id),
              UseTodayResult.used,
              reason: 'D$day',
            );
          }
          final r = c.read(recommendationProvider).recommendation!;
          if (chosen != null) {
            expect(r.composed!.isKept, isTrue);
            expect(r.composed!.keptCircleId, chosen.id);
            expect(r.composed!.plan, chosen.plan);
            expect(r.reason, RecommendationReason.ownChoice);
          }

          notifier.start();
          // One Circle a day: once started, nothing replaces it.
          if (toolkit.kept.isNotEmpty) {
            expect(
              notifier.useOwnedToday(keptCircleId: toolkit.kept.first.id),
              UseTodayResult.alreadyStarted,
            );
          }
          clock = morning.add(Duration(minutes: r.offeredMinutes));
          notifier.close();
          notifier.reportAttempt(CircleAttemptResponse.yes);
          notifier.reportUsefulness(
            day.isEven
                ? CircleUsefulnessResponse.veryUseful
                : CircleUsefulnessResponse.somewhatUseful,
          );
          await settle();

          // Keeping, while Premium, every fourth day, up to the limit.
          final composed = r.composed;
          if (entitled &&
              day <= _premiumUntil &&
              day % 4 == 0 &&
              composed != null &&
              !composed.isKept) {
            final kept = c
                .read(toolkitProvider.notifier)
                .keepCircle(
                  plan: composed.plan,
                  need: need,
                  circleId: r.circleId,
                );
            final before = toolkit.kept.length;
            expect(kept == null, before >= maxKeptCircles, reason: 'D$day');
          }
          // Owned data is never held hostage: renamed while Free.
          if (day == 50) {
            renamedId = c.read(toolkitProvider).kept.first.id;
            c.read(toolkitProvider.notifier).renameKept(renamedId, 'Mine');
          }
          await settle();
          if (day == _premiumUntil) {
            keptIdsAtLapse.addAll([
              for (final k in c.read(toolkitProvider).kept) k.id,
            ]);
          }
          // Lapse takes nothing the user kept.
          if (day > _premiumUntil) {
            expect(
              [for (final k in c.read(toolkitProvider).kept) k.id],
              keptIdsAtLapse,
              reason: 'D$day',
            );
          }
          served[day] = chosen != null
              ? Served.keptChosen
              : composed != null
              ? Served.composed
              : Served.free;
          lines.add(
            'D${day.toString().padLeft(3)} ${entitled ? 'P' : 'F'} '
            '${need.name} ≈${window.maxMinutes} → ${served[day]!.name}'
            '${chosen != null ? ' “${chosen.name}”' : ''} · ${r.activity}',
          );
        } finally {
          c.dispose();
        }
      }

      // Ownership reached its limit, and survived the lapse untouched.
      expect(keptIdsAtLapse, hasLength(maxKeptCircles));

      // History: one Circle a day, each attributed to what it was.
      final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      final entries = c.read(circleJournalRepositoryProvider).readAll();
      expect(entries, hasLength(_lastDay));
      expect({for (final e in entries) e.localDate}, hasLength(_lastDay));
      final kept = c.read(toolkitProvider).kept;
      expect(kept.firstWhere((k) => k.id == renamedId).name, 'Mine');
      for (final entry in entries) {
        final day = entry.closedAt!.difference(_start).inDays + 1;
        final circle = pastCirclesFrom([entry]).single;
        switch (served[day]!) {
          case Served.keptChosen:
            // A kept Circle's day is recorded as that kept Circle — composite,
            // never an answer about a single activity.
            expect(entry.session!.keptCircleId, isNotNull, reason: 'D$day');
            expect(circle.composite, isTrue);
          case Served.composed:
            expect(entry.session!.keptCircleId, isNull, reason: 'D$day');
            expect(entry.session!.parts, isNotEmpty);
            expect(circle.composite, isTrue);
          case Served.free:
            expect(entry.session?.parts ?? const [], isEmpty, reason: 'D$day');
        }
      }

      final lapse = [
        for (var d = _premiumUntil + 1; d <= _lapsedUntil; d++) served[d]!,
      ];
      final report = {
        'lapsed days': lapse.length,
        'served by a kept Circle the user chose': lapse
            .where((s) => s == Served.keptChosen)
            .length,
        'served by Free’s Today': lapse.where((s) => s == Served.free).length,
        'composed while lapsed': lapse
            .where((s) => s == Served.composed)
            .length,
        'kept Circles at lapse': keptIdsAtLapse.length,
        'kept Circles after resubscribing': kept.length,
        'first day back composed': served[_lapsedUntil + 1] == Served.composed,
      };
      expect(report['composed while lapsed'], 0);
      expect(report['first day back composed'], isTrue);
      if (_trace) {
        Directory('build').createSync(recursive: true);
        File('build/saved_circle_lapse_attack.json').writeAsStringSync(
          const JsonEncoder.withIndent(
            '  ',
          ).convert({'report': report, 'days': lines}),
        );
      }
    },
  );
}
