import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/personal_circle/application/guidance_session.dart';

/// V2 Phase D2 (ADR-023 §6) — the platform session's channel.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = 'com.thirty.app/guidance_session';

  Future<void> tapFromNotification(String action) =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            channel,
            const StandardMethodCodec().encodeMethodCall(
              MethodCall('action', action),
            ),
            (_) {},
          );

  test('the notification’s controls reach the session listening now — an '
      'older session going away never silences it (S25 finding: Pause '
      'reached nothing after the app’s state was rebuilt)', () async {
    final older = PlatformGuidanceSession();
    final newer = PlatformGuidanceSession();
    final heard = <GuidanceAction>[];
    older.listen((_) => fail('the older session must hear nothing'));
    newer.listen(heard.add);
    older.listen(null);
    await tapFromNotification('pause');
    await tapFromNotification('next');
    await tapFromNotification('unknown');
    expect(heard, [GuidanceAction.pause, GuidanceAction.next]);
    newer.listen(null);
    await tapFromNotification('resume');
    expect(heard, hasLength(2));
  });

  test(
    'without a platform session, showing and ending are silent no-ops',
    () async {
      final session = PlatformGuidanceSession();
      await session.show(
        const GuidanceSessionStatus(
          part: 'Get it out',
          paused: false,
          keepAwakeFor: Duration(minutes: 7),
        ),
      );
      await session.end(afterSpeech: true);
    },
  );
}
