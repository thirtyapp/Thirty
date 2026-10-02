import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/worlds/daypart.dart';
import 'package:thirty/core/worlds/world.dart' show Daypart;
import 'package:thirty/features/plans/domain/plan_ids.dart';
import 'package:thirty/features/plans/domain/plan_state.dart';
import 'package:thirty/features/plans/presentation/widgets/plan_identity.dart';
import 'package:thirty/features/plans/presentation/widgets/plan_progress.dart';
import 'package:thirty/features/plans/presentation/widgets/plans_header_art.dart';

void main() {
  group('fixed scene — always one of the Plan\'s own stages', () {
    final day = DateTime(2026, 8, 2, 14);
    final evening = DateTime(2026, 8, 2, 21);

    test('the founder-approved scenes, at the current daypart', () {
      expect(
        PlanIdentity.of(
          PlanId.moreEnergyPath,
        ).cardAssetAt(PlanId.moreEnergyPath, day),
        'assets/worlds/quiet_trail/walk/card_day.webp',
      );
      expect(
        PlanIdentity.of(
          PlanId.clearerHeadPath,
        ).cardAssetAt(PlanId.clearerHeadPath, day),
        'assets/worlds/garden_window/tend/card_day.webp',
      );
      expect(
        PlanIdentity.of(
          PlanId.gentlerPacePath,
        ).cardAssetAt(PlanId.gentlerPacePath, evening),
        'assets/worlds/still_lake/breathe/card_evening.webp',
      );
    });

    test('the three Plans never share a scene', () {
      final assets = {
        for (final id in PlanId.values)
          PlanIdentity.of(id).cardAssetAt(id, day),
      };
      expect(assets, hasLength(3));
    });
  });

  group('stage states read straight from the cursor', () {
    PlanProgress progress({int cursor = 0, bool completed = false}) =>
        PlanProgress.fresh(
          planId: PlanId.moreEnergyPath,
          cycleId: 'c1',
          startedAt: DateTime(2026),
        ).copyWith(
          forwardCursor: cursor,
          status: completed
              ? PlanCycleStatus.completed
              : PlanCycleStatus.inProgress,
        );

    test('closed before the cursor, current at it, upcoming after', () {
      final states = planStageStates(
        progress(cursor: 2),
        stageCount: 5,
        showCurrent: true,
      );
      expect(states, [
        PlanStageState.closed,
        PlanStageState.closed,
        PlanStageState.current,
        PlanStageState.upcoming,
        PlanStageState.upcoming,
      ]);
      expect(planProgressLabel(states), 'Stage 3 of 5, 2 closed.');
    });

    test('a never-started Plan has no current stage', () {
      final states = planStageStates(
        progress(),
        stageCount: 5,
        showCurrent: false,
      );
      expect(states, everyElement(PlanStageState.upcoming));
      expect(planProgressLabel(states), '5 stages. Not started.');
    });

    test('a completed cycle closes every stage', () {
      final states = planStageStates(
        progress(cursor: 5, completed: true),
        stageCount: 5,
        showCurrent: true,
      );
      expect(states, everyElement(PlanStageState.closed));
      expect(
        planProgressLabel(states),
        'Guided cycle finished. All 5 stages closed.',
      );
    });
  });

  test("the header band resolves each daypart through THIRTY's own "
      'daypart boundaries', () {
    expect(
      plansHeaderArt.at(daypartAt(DateTime(2026, 8, 2, 5))).asset,
      'assets/plans/plans_header_morning_v1.webp',
    );
    expect(
      plansHeaderArt.at(daypartAt(DateTime(2026, 8, 2, 12))).asset,
      'assets/plans/plans_header_day_v1.webp',
    );
    expect(
      plansHeaderArt.at(daypartAt(DateTime(2026, 8, 2, 18))).asset,
      'assets/plans/plans_header_evening_v1.webp',
    );
    expect(
      plansHeaderArt.at(daypartAt(DateTime(2026, 8, 2, 2))).asset,
      'assets/plans/plans_header_evening_v1.webp',
    );
  });

  test('every header asset is a bundled file of the declared size', () {
    for (final daypart in Daypart.values) {
      final image = plansHeaderArt.at(daypart);
      final file = File(image.asset);
      expect(file.existsSync(), isTrue, reason: image.asset);
      // WebP VP8 lossy: width and height are 14-bit fields at byte 26.
      final bytes = file.readAsBytesSync();
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WEBP');
      final data = ByteData.sublistView(bytes);
      expect(data.getUint16(26, Endian.little) & 0x3fff, image.width);
      expect(data.getUint16(28, Endian.little) & 0x3fff, image.height);
    }
  });

  testWidgets('the header band renders nothing without registered art', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlansHeaderArt(art: null, now: DateTime(2026, 8, 2, 14)),
      ),
    );
    expect(find.byType(Image), findsNothing);
  });
}
