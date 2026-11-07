import 'dart:convert';

import 'package:thirty/features/home/application/circle_history_deletion.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';

/// R8.3 — a reusable check of what is durably on the disk, read from the
/// stored bytes only ([FaultDisk.stored]), never from a provider's memory.
/// Each function returns the violations it finds, as text; a test expects
/// the list to be empty. The invariants are the founder's six (R8.3
/// directive §3), as far as they can be judged from the bytes alone:
///
/// - V (serialization fidelity): every record THIRTY reads decodes, and
///   re-encoding what it decoded gives back exactly the stored JSON — no
///   known field changed, no unknown field lost ([roundTripViolations]);
/// - II (attribution): an I1–I3 Insight marked applied has its own
///   provenance on disk ([appliedWithoutProvenance]);
/// - IV (temporal validity): a started or closed day was started on its own
///   local day ([startedOffDay]);
/// - VI (Delete completeness): nothing derived from the deleted History is
///   left, and what the user owns is untouched ([deletionResidue]).
///
/// I (durable confirmation) and III (idempotence) are judged by the
/// scenarios themselves — comparing a notice with the disk, and the bytes
/// before and after a retry or restart.
class DurableState {
  DurableState(this.stored);

  /// What is on the disk, keys unprefixed.
  final Map<String, Object> stored;

  Object? _json(String key) {
    final raw = stored[key];
    if (raw is! String) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Map<String, Object?>? get plansJson =>
      _json(circlePlansKey) as Map<String, Object?>?;
  Map<String, Object?>? get insightsJson =>
      _json(insightsKey) as Map<String, Object?>?;
  Map<String, Object?>? get preferencesJson =>
      _json(suggestionPreferencesKey) as Map<String, Object?>?;

  CirclePlansState? get plans => switch (plansJson) {
    final json? => CirclePlansState.fromJson(json),
    null => null,
  };

  InsightsState? get insights => switch (insightsJson) {
    final json? => InsightsState.fromJson(json),
    null => null,
  };

  SuggestionPreferences? get preferences =>
      SuggestionPreferences.tryRead(stored[suggestionPreferencesKey]);

  /// Invariant V for the Plans, Insights and Suggestion Preferences records
  /// that are readable: decode, then encode, is the stored JSON exactly.
  List<String> roundTripViolations() {
    final out = <String>[];
    void check(String key, Object? json, Object? Function() reencode) {
      if (json == null) return;
      final again = reencode();
      if (again == null) return; // Unreadable: kept aside, not re-encoded.
      if (jsonEncode(again) != jsonEncode(json)) {
        out.add('V: $key does not round-trip: stored ${jsonEncode(json)} '
            'but re-encoded ${jsonEncode(again)}');
      }
    }

    check(circlePlansKey, plansJson, () => plans?.toJson());
    check(insightsKey, insightsJson, () => insights?.toJson());
    check(
      suggestionPreferencesKey,
      preferencesJson,
      () => preferencesJson == null ? null : preferences?.toJson(),
    );
    return out;
  }

  /// Invariant II: every I1–I3 snapshot marked applied whose own provenance
  /// isn't on disk — its Plan's [PlanProgress.appliedInsight] naming it (for
  /// I2, on its cycle) or its part's [ElementLeftOut.byInsight].
  List<String> appliedWithoutProvenance() {
    final out = <String>[];
    final plans = this.plans;
    final left = preferences?.elementsLeftOut ?? const <ElementLeftOut>[];
    for (final s in insights?.snapshots ?? const <InsightSnapshot>[]) {
      if (s.appliedOn == null) continue;
      final ok = switch (s.application) {
        PlanDirection(:final planId) =>
          plans?.plans[planId]?.appliedInsight?.insightId == s.id,
        KeepGentler(:final planId, :final cycleId) =>
          plans?.plans[planId]?.appliedInsight?.insightId == s.id &&
              plans?.plans[planId]?.appliedInsight?.cycleId == cycleId,
        LeaveOutPart(:final element) => left.any(
          (e) => e.element.name == element && e.byInsight == s.id,
        ),
        _ => true,
      };
      if (!ok) out.add('II: ${s.id} is marked applied with no provenance');
    }
    return out;
  }

  /// Invariant IV: today's Circle, when started or closed, was started on
  /// its own day ([recommendationDayKey]): a Start after its day had passed
  /// never becomes a started Circle.
  List<String> startedOffDay() {
    final status = stored[recommendationStatusKey];
    if (status != 'started' && status != 'closed') return const [];
    final day = stored[recommendationDayKey];
    final at = stored[recommendationStartedAtKey];
    final startedAt = at is String ? DateTime.tryParse(at)?.toLocal() : null;
    if (startedAt == null) return ['IV: a $status Circle with no Start time'];
    final startedDay =
        '${startedAt.year.toString().padLeft(4, '0')}-'
        '${startedAt.month.toString().padLeft(2, '0')}-'
        '${startedAt.day.toString().padLeft(2, '0')}';
    return startedDay == day
        ? const []
        : ['IV: Circle $day was started on $startedDay'];
  }

  /// Invariant VI after a Delete Circle history that succeeded: nothing
  /// derived from the deleted History is left — the journal, today's day
  /// keys, the Insights, each Plan's stage evidence and the lifecycle-order
  /// stamps, and an Insight's attribution on a left-out part — and the
  /// deletion is no longer pending.
  ///
  /// With [before] (the disk just before the Delete), what the user owns is
  /// checked too: kept Circles byte-identical; each Plan's place (lifecycle,
  /// cycles without evidence) as before; every suggestion preference as
  /// before, apart from the attribution removed.
  List<String> deletionResidue({DurableState? before}) {
    final out = <String>[];
    for (final key in [
      historyDeletionPendingKey,
      circleJournalKey,
      circleJournalPreservedKey,
      insightsKey,
      insightsUnreadableKey,
      circlePlansUnreadableKey,
      recommendationDayKey,
      recommendationStatusKey,
      recommendationStartedAtKey,
      recommendationClosedAtKey,
      recommendationPendingWriteKey,
      recommendationSessionKey,
      recommendationComposedKey,
    ]) {
      if (stored.containsKey(key)) out.add('VI: $key is still stored');
    }
    final plans = plansJson;
    for (final MapEntry(key: id, value: plan)
        in ((plans?['plans'] as Map?) ?? const {}).entries) {
      final p = plan as Map;
      for (final field in [
        'lastServed',
        'lastAdvancedCircleId',
        'appliedInsight',
        // R8.3.1: which Circle was started while its Plan was paused.
        'startedWhilePaused',
      ]) {
        if (p.containsKey(field)) out.add('VI: Plan $id still holds $field');
      }
      for (final c in (p['cycles'] as List? ?? const [])) {
        if (((c as Map)['records'] as List? ?? const []).isNotEmpty) {
          out.add('VI: Plan $id cycle ${c['id']} still holds stage records');
        }
      }
    }
    if ((plans?['unreadablePlans'] as Map?)?.isNotEmpty ?? false) {
      out.add('VI: unreadable Plans are still stored');
    }
    for (final item
        in (preferencesJson?['elementsLeftOut'] as List?) ?? const []) {
      if (item is Map && item.containsKey('byInsight')) {
        out.add('VI: left-out ${item['elementId']} still names an Insight');
      }
    }
    if (before != null) {
      if (jsonEncode(stored[keptCirclesKeyName]) !=
          jsonEncode(before.stored[keptCirclesKeyName])) {
        out.add('VI: kept Circles changed');
      }
      final placeBefore = before.plans?.forgetStageEvidence().toJson();
      final placeNow = this.plans?.toJson();
      if (placeBefore != null && jsonEncode(placeNow) != jsonEncode(placeBefore)) {
        out.add('VI: a Plan place changed: before ${jsonEncode(placeBefore)} '
            'now ${jsonEncode(placeNow)}');
      }
      List<String> owned(DurableState s) => [
        for (final item
            in (s.preferencesJson?['elementsLeftOut'] as List?) ?? const [])
          jsonEncode({...(item as Map)}..remove('byInsight')),
        jsonEncode(s.preferencesJson?['notSuggested']),
        jsonEncode(s.preferencesJson?['restsLifted']),
      ];
      if (jsonEncode(owned(this)) != jsonEncode(owned(before))) {
        out.add('VI: a suggestion preference changed');
      }
    }
    return out;
  }

  /// Every invariant that holds whatever the scenario: V and IV.
  List<String> always() => [...roundTripViolations(), ...startedOffDay()];
}

/// Kept Circles' key (`kept_circles_provider.dart`), named here so this
/// file needs no Flutter widget import.
const keptCirclesKeyName = 'toolkit_v1';
