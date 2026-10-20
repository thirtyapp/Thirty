/// Insights (ADR-024 §11, B5): "What does my actual use show, and is there
/// one useful change I can approve?"
///
/// What is kept is a dated record of what THIRTY showed — the shown text,
/// the facts and evidence it rested on, its wording version, and whether
/// the user applied it, said "Not now" or kept the part. Never a profile:
/// nothing here says what the user likes, needs or responds to, and every
/// observation can be recomputed from the journal, the Plans and the user's
/// own controls.
library;

import 'dart:convert';

/// The six frozen families — no seventh, no fallback.
enum InsightFamily {
  planForNeed('insight.plan_for_need'),
  planPacing('insight.plan_pacing'),
  skippedPart('insight.skipped_part'),
  usefulInCommon('insight.useful_in_common'),
  planReview('insight.plan_review'),
  whatsChanged('insight.whats_changed');

  const InsightFamily(this.id);

  /// Stable, as ADR-024 names it.
  final String id;

  /// Every family but the Plan review, which appears at once and outside
  /// the 7-day cadence.
  bool get isOrdinary => this != planReview;

  static InsightFamily? fromId(Object? id) {
    for (final family in values) {
      if (family.id == id) return family;
    }
    return null;
  }
}

/// When several ordinary families qualify at once: I3 > I2 > I4 > I1 > I6.
const ordinaryInsightPriority = [
  InsightFamily.skippedPart,
  InsightFamily.planPacing,
  InsightFamily.usefulInCommon,
  InsightFamily.planForNeed,
  InsightFamily.whatsChanged,
];

/// The wording a snapshot was rendered with. A snapshot keeps its text, so
/// it reads exactly as shown after the templates change.
const insightWordingVersion = 1;

/// At most this many snapshots are kept (ADR-024 §11).
const maxInsightSnapshots = 52;

/// "Not now" — and an applied or dismissed Insight — hides the same
/// evidence set this long.
const insightQuietDays = 28;

/// The evidence set an observation rests on, as one stable value: its
/// [subject] and the sorted journal ids of the Circles relevant to its
/// claim (32-bit FNV-1a). The same Circles, in any order, give the same
/// fingerprint; a new relevant Circle gives another. Never the wording.
String insightFingerprint(String subject, Iterable<String> evidence) {
  final ids = {...evidence}.toList()..sort();
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode([subject, ...ids].join('|'))) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return '$subject#${hash.toRadixString(16).padLeft(8, '0')}';
}

/// At most one new ordinary Insight in this many days.
const insightCadenceDays = 7;

/// The same claim — an ordinary family and its subject — is shown at most
/// once in this many days, from the day it was shown, whatever new evidence
/// arrives and whatever the user did with it (founder, 2026-10-18). Plan
/// reviews are outside it.
const insightRepeatDays = 28;

/// Which way the Plan application moves a Plan.
enum PlanStep { start, carryOn, goThroughAgain }

/// What the user may approve. Every one goes through an existing domain
/// action; none is ever applied without the user.
sealed class InsightApplication {
  const InsightApplication();

  Map<String, Object?> toJson();

  static InsightApplication? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    String? text(String key) => raw[key] is String ? raw[key] as String : null;
    return switch (raw['kind']) {
      'plan' => switch ((
        text('planId'),
        PlanStep.values.asNameMap()[raw['step']],
      )) {
        (final planId?, final step?) => PlanDirection(planId, step),
        _ => null,
      },
      'gentler' => switch ((text('planId'), text('cycleId'))) {
        (final planId?, final cycleId?) => KeepGentler(planId, cycleId),
        _ => null,
      },
      'leaveOut' => switch (text('element')) {
        final element? => LeaveOutPart(element),
        _ => null,
      },
      'keep' => switch (text('circleId')) {
        final circleId? => KeepCircleFromHistory(circleId),
        _ => null,
      },
      'planReview' => switch ((text('planId'), text('cycleId'))) {
        (final planId?, final cycleId?) => OpenPlanReview(planId, cycleId),
        _ => null,
      },
      'nothingToChange' => switch (text('text')) {
        final line? => NothingToChange(line),
        _ => null,
      },
      _ => null,
    };
  }
}

/// I1 / I6: start, carry on with, or go through a Plan again.
final class PlanDirection extends InsightApplication {
  const PlanDirection(this.planId, this.step);

  final String planId;
  final PlanStep step;

  @override
  Map<String, Object?> toJson() => {
    'kind': 'plan',
    'planId': planId,
    'step': step.name,
  };
}

/// I2: "Keep this Plan's Circles gentler for now", for this cycle.
final class KeepGentler extends InsightApplication {
  const KeepGentler(this.planId, this.cycleId);

  final String planId;
  final String cycleId;

  @override
  Map<String, Object?> toJson() => {
    'kind': 'gentler',
    'planId': planId,
    'cycleId': cycleId,
  };
}

/// I3: Leave it out next time — the existing Leave it out (Put it back
/// reverses it).
final class LeaveOutPart extends InsightApplication {
  const LeaveOutPart(this.element);

  /// `ElementId.name`.
  final String element;

  @override
  Map<String, Object?> toJson() => {'kind': 'leaveOut', 'element': element};
}

/// I4: keep a Circle from History as one of the user's kept Circles.
final class KeepCircleFromHistory extends InsightApplication {
  const KeepCircleFromHistory(this.circleId);

  final String circleId;

  @override
  Map<String, Object?> toJson() => {'kind': 'keep', 'circleId': circleId};
}

/// I5: the Plan review's own options, which Plans owns.
final class OpenPlanReview extends InsightApplication {
  const OpenPlanReview(this.planId, this.cycleId);

  final String planId;
  final String cycleId;

  @override
  Map<String, Object?> toJson() => {
    'kind': 'planReview',
    'planId': planId,
    'cycleId': cycleId,
  };
}

/// An explicit "Nothing to change" — never a stand-in for an Insight that
/// didn't qualify.
final class NothingToChange extends InsightApplication {
  const NothingToChange(this.text);

  final String text;

  @override
  Map<String, Object?> toJson() => {'kind': 'nothingToChange', 'text': text};
}

/// One Insight as THIRTY showed it.
class InsightSnapshot {
  const InsightSnapshot({
    required this.id,
    required this.family,
    required this.generatedOn,
    required this.wordingVersion,
    required this.text,
    required this.facts,
    required this.evidence,
    required this.subject,
    required this.application,
    this.appliedOn,
    this.notNowOn,
    this.declinedOn,
  });

  final String id;
  final InsightFamily family;

  /// The local date it was generated (`YYYY-MM-DD`).
  final String generatedOn;
  final int wordingVersion;

  /// The observation, exactly as shown.
  final String text;

  /// The numbers and names the text was rendered from: counts with their
  /// denominators, dates, the need, part, kind or Plan.
  final Map<String, Object> facts;

  /// The Circles (journal ids) relevant to the claim: the need's choices
  /// (I1), the Plan's untreated stage offers (I2), the part's last four
  /// Circles (I3), the need's composed Circles in the window (I4), both
  /// windows (I6), the cycle's stage Circles (I5).
  final List<String> evidence;

  /// What the observation is about — the family and its need, Plan, part,
  /// kind or change of need. The same claim on a later day keeps it; it
  /// says nothing about which evidence ([evidenceFingerprint]).
  final String subject;

  /// The evidence set this observation was shown from — what "Not now"
  /// hides.
  String get evidenceFingerprint => insightFingerprint(subject, evidence);

  final InsightApplication application;

  /// The day the user applied it, when the domain action succeeded.
  final String? appliedOn;

  /// The day the user said "Not now".
  final String? notNowOn;

  /// I3: the day the user chose "Keep it" — a dismissal like "Not now":
  /// nothing changes, no preference or answer is recorded, and only this
  /// evidence set is hidden.
  final String? declinedOn;

  String? get planId => switch (application) {
    PlanDirection(:final planId) ||
    KeepGentler(:final planId) ||
    OpenPlanReview(:final planId) => planId,
    _ => facts['planId'] as String?,
  };

  String? get cycleId => switch (application) {
    KeepGentler(:final cycleId) || OpenPlanReview(:final cycleId) => cycleId,
    _ => null,
  };

  InsightSnapshot copyWith({
    String? appliedOn,
    String? notNowOn,
    String? declinedOn,
  }) => InsightSnapshot(
    id: id,
    family: family,
    generatedOn: generatedOn,
    wordingVersion: wordingVersion,
    text: text,
    facts: facts,
    evidence: evidence,
    subject: subject,
    application: application,
    appliedOn: appliedOn ?? this.appliedOn,
    notNowOn: notNowOn ?? this.notNowOn,
    declinedOn: declinedOn ?? this.declinedOn,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'family': family.id,
    'generatedOn': generatedOn,
    'wordingVersion': wordingVersion,
    'text': text,
    'facts': facts,
    'evidence': evidence,
    'subject': subject,
    'application': application.toJson(),
    'appliedOn': ?appliedOn,
    'notNowOn': ?notNowOn,
    'declinedOn': ?declinedOn,
  };

  /// `null` for anything that isn't a whole snapshot.
  static InsightSnapshot? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final id = raw['id'];
    final family = InsightFamily.fromId(raw['family']);
    final generatedOn = raw['generatedOn'];
    final version = raw['wordingVersion'];
    final text = raw['text'];
    final key = raw['subject'];
    final application = InsightApplication.fromJson(raw['application']);
    if (id is! String ||
        family == null ||
        generatedOn is! String ||
        version is! int ||
        text is! String ||
        key is! String ||
        application == null) {
      return null;
    }
    String? date(String k) => raw[k] is String ? raw[k] as String : null;
    return InsightSnapshot(
      id: id,
      family: family,
      generatedOn: generatedOn,
      wordingVersion: version,
      text: text,
      facts: {
        if (raw['facts'] case final Map<String, Object?> facts)
          for (final e in facts.entries)
            if (e.value is String || e.value is int) e.key: e.value!,
      },
      evidence: [
        if (raw['evidence'] case final List list)
          for (final item in list)
            if (item is String) item,
      ],
      subject: key,
      application: application,
      appliedOn: date('appliedOn'),
      notNowOn: date('notNowOn'),
      declinedOn: date('declinedOn'),
    );
  }
}

/// Every snapshot kept, oldest first.
class InsightsState {
  const InsightsState([this.snapshots = const []]);

  static const empty = InsightsState();

  final List<InsightSnapshot> snapshots;

  bool get isEmpty => snapshots.isEmpty;

  InsightSnapshot? byId(String id) {
    for (final s in snapshots) {
      if (s.id == id) return s;
    }
    return null;
  }

  InsightsState replacing(InsightSnapshot snapshot) => InsightsState([
    for (final s in snapshots) s.id == snapshot.id ? snapshot : s,
  ]);

  Map<String, Object?> toJson() => {
    'schemaVersion': insightsSchemaVersion,
    'snapshots': [for (final s in snapshots) s.toJson()],
  };

  /// `null` when [raw] isn't a readable record; unreadable snapshots are
  /// dropped one by one.
  static InsightsState? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    if (raw['schemaVersion'] != insightsSchemaVersion) return null;
    return InsightsState([
      if (raw['snapshots'] case final List list)
        for (final s in list) ?InsightSnapshot.fromJson(s),
    ]);
  }
}

const insightsSchemaVersion = 1;
