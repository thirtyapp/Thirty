import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/spoken_cues.dart';

/// What the user can do from a voiced Circle's notification.
enum GuidanceAction { pause, resume, next }

/// What a voiced Circle's background session shows: the part on show and
/// whether the Circle is paused.
class GuidanceSessionStatus {
  const GuidanceSessionStatus({
    required this.part,
    required this.paused,
    required this.keepAwakeFor,
  });

  /// The name of the part on show.
  final String part;
  final bool paused;

  /// How long the device must stay awake for the remaining cues — the
  /// Circle's remaining time, with a margin. Zero while paused: nothing
  /// is due then.
  final Duration keepAwakeFor;

  /// Whether the notification would look different.
  bool showsAs(GuidanceSessionStatus other) =>
      part == other.part && paused == other.paused;
}

/// Keeps a voiced Circle going while THIRTY is out of sight (V2 Phase D2,
/// ADR-023 §6): the platform's media-playback session — on Android a
/// foreground service with its notification and a wake lock — so the
/// device neither freezes nor sleeps THIRTY between cues. It plays nothing
/// itself and keeps no time: [GuidanceConductor] decides what is said and
/// when, from the Circle's stored facts.
abstract interface class GuidanceSession {
  /// Shows (or updates) the session for a running voiced Circle.
  Future<void> show(GuidanceSessionStatus status);

  /// Ends the session — at once, or [afterSpeech] once the voice has
  /// finished what it is saying.
  Future<void> end({bool afterSpeech = false});

  /// Receives the notification's controls; `null` stops listening.
  void listen(void Function(GuidanceAction action)? onAction);
}

/// No session: the voice speaks only while THIRTY is in front.
class NoGuidanceSession implements GuidanceSession {
  const NoGuidanceSession();

  @override
  Future<void> show(GuidanceSessionStatus status) async {}

  @override
  Future<void> end({bool afterSpeech = false}) async {}

  @override
  void listen(void Function(GuidanceAction action)? onAction) {}
}

/// The platform's session (Android: `GuidanceService.kt`), over a method
/// channel. Where there is none, it does nothing.
class PlatformGuidanceSession implements GuidanceSession {
  PlatformGuidanceSession();

  static const _channel = MethodChannel('com.thirty.app/guidance_session');

  @override
  Future<void> show(GuidanceSessionStatus status) => _call('show', {
    'title': status.paused
        ? SpokenGuidanceCopy.sessionPaused
        : SpokenGuidanceCopy.sessionRunning,
    'part': status.part,
    'paused': status.paused,
    'keepAwakeMs': status.keepAwakeFor.inMilliseconds,
    'pauseLabel': SpokenGuidanceCopy.pause,
    'resumeLabel': SpokenGuidanceCopy.resume,
    'nextLabel': SpokenGuidanceCopy.next,
    'channelName': SpokenGuidanceCopy.title,
  });

  @override
  Future<void> end({bool afterSpeech = false}) =>
      _call('end', {'afterSpeech': afterSpeech});

  /// The session whose listener the one platform channel calls.
  static PlatformGuidanceSession? _listening;

  @override
  void listen(void Function(GuidanceAction action)? onAction) {
    if (onAction == null) {
      // Only its own listener: a session that has gone (an old container)
      // must never silence the one that replaced it (S25 finding, D2 final
      // hardening: the notification's Pause reached nothing).
      if (_listening != this) return;
      _listening = null;
      _channel.setMethodCallHandler(null);
      return;
    }
    _listening = this;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'action') return;
      final action = GuidanceAction.values
          .where((a) => a.name == call.arguments)
          .firstOrNull;
      if (action != null) onAction(action);
    });
  }

  Future<void> _call(String method, Object? arguments) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // No session on this platform: the voice speaks only in front.
    } on PlatformException {
      // Never an error for the Circle itself.
    }
  }
}

final guidanceSessionProvider = Provider<GuidanceSession>(
  (ref) => PlatformGuidanceSession(),
);
