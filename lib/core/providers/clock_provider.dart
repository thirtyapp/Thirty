import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current moment. Call sites read this instead of calling
/// `DateTime.now()` directly, so date-dependent logic (e.g. "has today's
/// ritual already happened?") stays deterministic and overridable in tests.
///
/// This is a plain [Provider]: its `DateTime.now()` call runs exactly once
/// — on first read within a given [ProviderContainer] — and that value is
/// then cached and returned unchanged for the container's entire lifetime
/// (verified directly: two reads of this provider, real milliseconds
/// apart, return the byte-identical [DateTime]). That is exactly right for
/// a coarse "which calendar day is it" check, which is the only thing
/// [nowProvider] is used for today — but it makes this provider the wrong
/// source for an *event* timestamp that must reflect the actual moment a
/// call happened, potentially long after the container (and this
/// provider) first came alive. Use [eventClockProvider] for that instead.
final nowProvider = Provider<DateTime>((ref) => DateTime.now());

/// A clock, not a cached moment: read this once
/// (`ref.read(eventClockProvider)`) and *call* the returned function right
/// when a fresh timestamp is actually needed, so each call yields the real
/// current time rather than [nowProvider]'s one-time, container-lifetime
/// snapshot. Intended for event timestamps — e.g.
/// `RecommendationState.startedAt`/`closedAt` — not for the coarse
/// calendar-day checks [nowProvider] already correctly serves.
final eventClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);
