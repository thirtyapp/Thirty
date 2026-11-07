import 'package:shared_preferences/shared_preferences.dart';

import 'recommendation_provider.dart';

/// The V1 Premium records retired in V2 Phase D (ADR-022): the Plan state
/// (every Plan's stage cursor, cycles and lighter default) and the Insight
/// snapshots. Coach kept nothing of its own.
const retiredV1PremiumKeys = ['plans_state_v1', 'insight_snapshots_v1'];

/// Set once the retirement has run.
const v1PremiumRetiredKey = 'v1_premium_retired';

/// Retires V1 Premium state — deterministically, idempotently, before
/// anything reads the store.
///
/// **Nothing is migrated into V2.** A V1 Plan's stage cursor is not a V2
/// Path position and V1 Plan progress is not a routine: the same area of the
/// product is not the same thing, so no Path, routine or claim is made from
/// it. What stays is what stays true: every recorded Circle (the journal,
/// where V1 Plan days keep their Plan label), the entitlement (RevenueCat's,
/// never stored here), and every Free preference.
///
/// Safe if interrupted: each removal is independent, the marker is written
/// last, and running it again removes nothing that wasn't V1.
///
/// R8.3 (founder decision D5, Claude O-2): `main()` awaits this before the
/// app starts, so the marker is read as whatever native type is stored — a
/// value of another type never stops THIRTY from starting. Such a value
/// records no retirement: the retirement runs (it only removes V1's
/// records), and the value is left as stored rather than written over.
Future<void> retireV1Premium(SharedPreferences prefs) async {
  final marker = prefs.get(v1PremiumRetiredKey);
  if (marker == true) return;
  for (final key in [...retiredV1PremiumKeys, ...retiredPlanDayKeys]) {
    await prefs.remove(key);
  }
  if (marker == null) await prefs.setBool(v1PremiumRetiredKey, true);
}
