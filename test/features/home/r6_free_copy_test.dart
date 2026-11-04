import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/personal_circle/domain/spoken_cues.dart';

/// Audit remediation R6 (Audit #1 m6; founder-approved wording
/// 2026-11-03): four older Free activity lines, exactly as approved. The
/// activities, their ids and their status are unchanged, and none of these
/// lines is in a spoken recording.
void main() {
  final walk = activityDefinition(ActivityId.thirtyMinuteWalk);
  final music = activityDefinition(ActivityId.moveToMusic);
  final phoneFree = activityDefinition(ActivityId.phoneFreeWalk);

  test('A brisk walk — a step', () {
    expect(
      walk.whileYoureThere,
      contains(
        'Start easy, then walk briskly — at a pace you can still talk at.',
      ),
    );
  });

  test('Move to music — first action and a step', () {
    expect(music.firstAction, 'Put on a song you really like.');
    expect(
      music.whileYoureThere,
      contains('Let the next song be one you feel like moving to.'),
    );
  });

  test('Phone-free walk — first action', () {
    expect(
      phoneFree.firstAction,
      'Silence your notifications, keep your phone in your pocket, and '
      'start walking.',
    );
  });

  test('the old wording is gone from all three activities', () {
    final all = [
      for (final a in [walk, music, phoneFree]) ...[
        a.firstAction,
        ...a.whileYoureThere,
      ],
    ].join('\n');
    for (final old in [
      'a little quicker than usual',
      'turn it up a little',
      'a bit livelier',
      'out of sight in a pocket or bag',
    ]) {
      expect(all, isNot(contains(old)), reason: old);
    }
  });

  test('no recording changes: every spoken clip still names a bundled '
      'recording, in every voice — the Free activities have none of their '
      'own (the element "A brisk walk" already says the new walk line)', () {
    for (final voice in ThirtyVoice.values) {
      for (final clip in spokenGuidanceManifest) {
        expect(
          File(clip.assetFor(voice)).existsSync(),
          isTrue,
          reason: clip.assetFor(voice),
        );
      }
    }
    expect(
      spokenGuidanceManifest.map((c) => c.id),
      isNot(contains(startsWith('activity_'))),
    );
  });
}
