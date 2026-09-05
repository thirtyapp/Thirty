import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/application/first_breath_provider.dart'
    show firstBreathLastPlayedDateKey;
import '../../features/home/application/recommendation_provider.dart'
    show recommendationDayKey;
import '../providers/shared_preferences_provider.dart';
import 'cohort.dart';

/// SharedPreferences key for the locally-generated, pseudonymous id that
/// identifies this device/install across analytics events — never a name,
/// email, or account (THIRTY has none — ADR-006), and never sent anywhere
/// except as the `tester_id` column of `analytics_events`.
const analyticsTesterIdKey = 'analytics_tester_id';

/// SharedPreferences key for this device's [Cohort], decided once (see
/// [TesterIdentityNotifier.build]) and never recomputed afterward.
const analyticsCohortKey = 'analytics_cohort';

/// A device's stable analytics identity: a pseudonymous [testerId] and its
/// fixed [cohort].
class TesterIdentity {
  const TesterIdentity({required this.testerId, required this.cohort});

  final String testerId;
  final Cohort cohort;
}

/// Resolves (and, on first use, persists) this device's [TesterIdentity].
///
/// **Cohort classification (Phase F — cohort integrity)** happens exactly
/// once per device, the first time this provider ever runs — normally the
/// very first app open after installing/updating to the Batch 1 build,
/// since analytics did not exist before it. At that one moment:
///
/// - If [recommendationDayKey] or [firstBreathLastPlayedDateKey] already
///   has a persisted value, this device already used THIRTY before Batch 1
///   — [Cohort.preFix].
/// - Otherwise, this is this device's first-ever observed exposure to
///   THIRTY, on the Batch 1 build itself — [Cohort.postFixBatch1].
///
/// The result is persisted under [analyticsCohortKey] and never
/// re-evaluated afterward, so a later app update can't silently convert a
/// tester's cohort — exactly the guarantee Phase F requires. This is the
/// entire, auditable cohort rule: no experimentation framework, no
/// server-side assignment, just one local, one-time read of state that
/// already existed before this device ever ran a Batch 1 build.
///
/// Deliberately reads [recommendationDayKey]/[firstBreathLastPlayedDateKey]
/// directly rather than through `features/home`'s own providers — this is
/// a one-time bootstrap check of *whether prior state exists*, never a
/// dependency on that feature's behaviour, so it stays a plain constant
/// lookup rather than a real cross-feature coupling.
class TesterIdentityNotifier extends Notifier<TesterIdentity> {
  @override
  TesterIdentity build() {
    final prefs = ref.watch(sharedPreferencesProvider);

    var testerId = prefs.getString(analyticsTesterIdKey);
    if (testerId == null) {
      testerId = _generateTesterId();
      unawaited(prefs.setString(analyticsTesterIdKey, testerId));
    }

    final storedCohort = cohortFromWireName(prefs.getString(analyticsCohortKey));
    final Cohort cohort;
    if (storedCohort != null) {
      cohort = storedCohort;
    } else {
      final hasPriorUsageEvidence =
          prefs.containsKey(recommendationDayKey) ||
          prefs.containsKey(firstBreathLastPlayedDateKey);
      cohort = hasPriorUsageEvidence
          ? Cohort.preFix
          : Cohort.postFixBatch1;
      unawaited(prefs.setString(analyticsCohortKey, cohort.wireName));
    }

    return TesterIdentity(testerId: testerId, cohort: cohort);
  }

  /// A sufficiently random, stable, pseudonymous local id — RFC 4122
  /// v4-shaped so it reads like a normal UUID in Supabase Studio, but not
  /// generated via a `uuid` package dependency (AGENTS.md §5: no new
  /// packages beyond what's already in `pubspec.yaml`).
  static String _generateTesterId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}

final testerIdentityProvider =
    NotifierProvider<TesterIdentityNotifier, TesterIdentity>(
      TesterIdentityNotifier.new,
    );
