import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/domain/circle_session.dart';
import '../../features/home/presentation/widgets/circle_session_card.dart';
import '../../features/home/presentation/widgets/home_circle_metrics.dart';
import '../providers/clock_provider.dart';
import '../providers/shared_preferences_provider.dart';
import '../theme/design_tokens.dart';
import '../widgets/thirty_button.dart';
import '../widgets/thirty_card.dart';

/// **Internal QA only — debug builds only** (V2 Phase C, ADR-021).
///
/// Proves the generic Paced runtime — phase timing, pause, pausing whenever
/// the app leaves the foreground, staying paused on return, reduced motion
/// and restoration — on a synthetic, neutral pattern. It is not an
/// activity, not breathing guidance and not reviewed content: no catalogue
/// activity paces until the separate safety/content review supplies its
/// pattern. The route exists only in debug builds (`app_router.dart`'s
/// `includeDevPreview`).
const pacedQaFixture = PacePattern(
  phases: [
    PacePhase('Pace one', Duration(seconds: 4)),
    PacePhase('Pace two', Duration(seconds: 6)),
  ],
  total: Duration(minutes: 2),
);

const _startedAtKey = 'qa_paced_started_at';
const _pausedAtKey = 'qa_paced_paused_at';
const _pausedMsKey = 'qa_paced_paused_ms';

/// The bench's runtime: the same timestamps-and-small-state model as
/// today's Circle, under its own debug keys.
typedef PacedQaState = ({
  DateTime? startedAt,
  DateTime? pausedAt,
  Duration pausedTotal,
});

class PacedQaNotifier extends Notifier<PacedQaState> {
  @override
  PacedQaState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return (
      startedAt: DateTime.tryParse(prefs.getString(_startedAtKey) ?? ''),
      pausedAt: DateTime.tryParse(prefs.getString(_pausedAtKey) ?? ''),
      pausedTotal: Duration(milliseconds: prefs.getInt(_pausedMsKey) ?? 0),
    );
  }

  DateTime _now() => ref.read(eventClockProvider)();

  Duration elapsedAt(DateTime now) {
    final startedAt = state.startedAt;
    if (startedAt == null) return Duration.zero;
    return activeElapsed(
      startedAt: startedAt,
      at: now,
      pausedAt: state.pausedAt,
      pausedTotal: state.pausedTotal,
    );
  }

  Future<void> _save(PacedQaState next) async {
    state = next;
    final prefs = ref.read(sharedPreferencesProvider);
    final startedAt = next.startedAt;
    final pausedAt = next.pausedAt;
    startedAt == null
        ? await prefs.remove(_startedAtKey)
        : await prefs.setString(_startedAtKey, startedAt.toIso8601String());
    pausedAt == null
        ? await prefs.remove(_pausedAtKey)
        : await prefs.setString(_pausedAtKey, pausedAt.toIso8601String());
    await prefs.setInt(_pausedMsKey, next.pausedTotal.inMilliseconds);
  }

  Future<void> start() =>
      _save((startedAt: _now(), pausedAt: null, pausedTotal: Duration.zero));

  Future<void> pause() {
    if (state.startedAt == null || state.pausedAt != null) {
      return Future.value();
    }
    return _save((
      startedAt: state.startedAt,
      pausedAt: _now(),
      pausedTotal: state.pausedTotal,
    ));
  }

  Future<void> resume() {
    final pausedAt = state.pausedAt;
    if (pausedAt == null) return Future.value();
    return _save((
      startedAt: state.startedAt,
      pausedAt: null,
      pausedTotal: state.pausedTotal + _now().difference(pausedAt),
    ));
  }

  Future<void> reset() =>
      _save((startedAt: null, pausedAt: null, pausedTotal: Duration.zero));
}

final pacedQaProvider = NotifierProvider<PacedQaNotifier, PacedQaState>(
  PacedQaNotifier.new,
);

class PacedQaBenchPage extends ConsumerStatefulWidget {
  const PacedQaBenchPage({super.key});

  static const location = '/dev/paced-qa';

  /// What TalkBack calls the bench's ring: a test session, not a Circle.
  static const ringLabel = 'Paced test session';

  @override
  ConsumerState<PacedQaBenchPage> createState() => _PacedQaBenchPageState();
}

class _PacedQaBenchPageState extends ConsumerState<PacedQaBenchPage> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(pacedQaProvider);
    final notifier = ref.read(pacedQaProvider.notifier);
    final clock = ref.read(eventClockProvider);
    final elapsed = notifier.elapsedAt(clock());
    final started = state.startedAt != null;
    final paused = state.pausedAt != null;
    final total = pacedQaFixture.total;
    final metrics = HomeCircleMetrics.forWidth(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Paced runtime · internal QA')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.s),
              decoration: BoxDecoration(
                borderRadius: AppRadius.small,
                border: Border.all(color: colors.warning),
              ),
              child: Text(
                'Synthetic pacing for testing the Paced runtime. Not an '
                'activity, not a breathing exercise, and not reviewed '
                'content. Debug builds only.',
                style: textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Center(
              child: HomeCircle(
                metrics: metrics,
                progress: total <= Duration.zero
                    ? 0
                    : (elapsed.inMilliseconds / total.inMilliseconds).clamp(
                        0.0,
                        1.0,
                      ),
                progressColor: colors.primary,
                trackColor: colors.ringTrack,
                semanticLabel: PacedQaBenchPage.ringLabel,
                semanticValue: paused
                    ? 'Paused. ${elapsed.inSeconds} of ${total.inSeconds} '
                          'seconds.'
                    : '${elapsed.inSeconds} of ${total.inSeconds} seconds.',
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              !started
                  ? 'Not started'
                  : paused
                  ? 'Paused at ${elapsed.inSeconds} of ${total.inSeconds} s'
                  : '${elapsed.inSeconds} of ${total.inSeconds} s',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.m),
            if (started)
              PauseWhenHidden(
                onHidden: notifier.pause,
                child: ThirtyCard(
                  child: PacedSessionBody(
                    pattern: pacedQaFixture,
                    elapsed: elapsed,
                    paused: paused,
                    elapsedNow: () => notifier.elapsedAt(clock()),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.l),
            if (!started)
              ThirtyButton(label: 'Start', onPressed: notifier.start)
            else ...[
              ThirtyButton(
                label: paused ? 'Resume' : 'Pause',
                variant: ThirtyButtonVariant.secondary,
                onPressed: paused ? notifier.resume : notifier.pause,
              ),
              const SizedBox(height: AppSpacing.s),
              ThirtyButton(
                label: 'Reset',
                variant: ThirtyButtonVariant.secondary,
                onPressed: notifier.reset,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
