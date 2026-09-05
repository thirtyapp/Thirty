import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/release_info.dart';
import '../providers/clock_provider.dart';
import '../utils/date_key.dart';
import 'analytics_event_type.dart';
import 'cohort.dart';
import 'tester_identity_provider.dart';

/// Batch 1's behavioural instrumentation (Phase E).
///
/// Writes insert-only rows to Supabase's `analytics_events` table — the
/// one narrow, explicitly authorised exception to "no Supabase data layer
/// yet" (AGENTS.md §5; see
/// `docs/product/adr/ADR-011-batch-1-post-fix-retention-cohort.md` and
/// `supabase/README.md`). Nothing else in THIRTY reads, writes, or depends
/// on Supabase for product state — Circle/recommendation state, user
/// profiles, content, and configuration all stay local-only
/// (SharedPreferences), exactly as before.
///
/// [track] never throws and never blocks its caller: a dropped analytics
/// event must never degrade the product experience (ADR-004, "optional
/// data never required," applies just as much to instrumentation as to any
/// product feature).
abstract class AnalyticsService {
  void track(AnalyticsEventType type, {Map<String, Object?>? metadata});
}

class SupabaseAnalyticsService implements AnalyticsService {
  SupabaseAnalyticsService(this._ref);

  final Ref _ref;

  @override
  void track(AnalyticsEventType type, {Map<String, Object?>? metadata}) {
    final identity = _ref.read(testerIdentityProvider);
    final occurredAt = _ref.read(eventClockProvider)();

    unawaited(
      _send(
        identity: identity,
        type: type,
        occurredAt: occurredAt,
        metadata: metadata,
      ),
    );
  }

  Future<void> _send({
    required TesterIdentity identity,
    required AnalyticsEventType type,
    required DateTime occurredAt,
    Map<String, Object?>? metadata,
  }) async {
    try {
      await Supabase.instance.client.from('analytics_events').insert({
        'tester_id': identity.testerId,
        'event_type': type.wireName,
        'occurred_at': occurredAt.toIso8601String(),
        'local_date': dateKey(occurredAt),
        'app_version': ReleaseInfo.appVersion,
        'cohort': identity.cohort.wireName,
        'metadata': ?metadata,
      });
    } catch (_) {
      // Deliberately swallowed — see class doc comment. There is nowhere
      // safe to surface this to (no user-facing error state exists for
      // "your usage wasn't recorded," and it must not become one).
    }
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => SupabaseAnalyticsService(ref),
);
