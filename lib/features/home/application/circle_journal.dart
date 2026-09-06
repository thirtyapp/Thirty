/// THIRTY's prospective local Circle journal (ADR-013, Batch 1 / V1
/// Productization — §5 "Prospective Local Circle Journal").
///
/// This is the smallest versioned local record required by the frozen
/// recurring Premium architecture's future Plans/Coach/Insights — but it
/// is deliberately **not** any of those things yet, and it is not
/// analytics: it is a bounded, versioned, on-device history of what
/// actually happened on each local day's Circle, recorded prospectively
/// (from the day this shipped forward) rather than reconstructed from
/// Batch 2's short per-intention anti-repetition history or from Supabase
/// analytics events — see [CircleJournalRepository]'s own doc comment for
/// why neither of those sources is a legitimate substitute.
///
/// Device-local only: this is `SharedPreferences`, like every other piece
/// of THIRTY's state (AGENTS.md §5), and is never sent anywhere. See
/// `android/app/src/main/AndroidManifest.xml`'s `android:allowBackup`
/// setting (ADR-013 §7) for how "device-local" is kept true even against
/// the OS's own cloud-backup mechanism.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/shared_preferences_provider.dart';
import 'activity_catalog.dart';

/// The user's optional, self-reported answer to "Did you try this
/// activity?", offered once today's Circle is closed (ADR-013 §4).
///
/// A `null` [CircleJournalEntry.attemptResponse] means **no answer was
/// given** — deliberately distinct from [notToday], which is an explicit,
/// reported non-action. Neither value is ever treated as verified
/// completion, thirty elapsed minutes, or a wellbeing outcome — see this
/// enum's call sites in `recommendation_provider.dart` and ADR-013 §4 for
/// the exact semantics each value carries.
enum CircleAttemptResponse { yes, aLittle, notToday }

/// The wire-stable name [CircleAttemptResponse] is persisted/journalled as.
extension CircleAttemptResponseWire on CircleAttemptResponse {
  String get wireName => name;
}

/// The user's optional, self-reported usefulness rating — offered only
/// after an affirmative [CircleAttemptResponse] ([CircleAttemptResponse.yes]
/// or [CircleAttemptResponse.aLittle]), never after
/// [CircleAttemptResponse.notToday] or no answer at all. Self-reported
/// usefulness only — never treated as a verified health or wellbeing
/// outcome (ADR-013 §4).
enum CircleUsefulnessResponse { veryUseful, somewhatUseful, notUseful }

/// The wire-stable name [CircleUsefulnessResponse] is persisted/journalled
/// as.
extension CircleUsefulnessResponseWire on CircleUsefulnessResponse {
  String get wireName => name;
}

/// One local day's Circle journal record.
///
/// [circleId] and [localDate] are currently always equal — Free is bounded
/// to one Circle per local calendar day, so the local date already is a
/// stable, unique identity for that day's Circle. They are kept as two
/// separate fields (matching ADR-013 §5's explicit list of required
/// fields) so a future change to what makes a Circle's identity stable
/// (e.g. if that ever stops being 1:1 with the calendar date) would not
/// need a journal schema change, only a change to how [circleId] is
/// computed.
class CircleJournalEntry {
  const CircleJournalEntry({
    required this.schemaVersion,
    required this.circleId,
    required this.localDate,
    required this.direction,
    required this.activityId,
    required this.catalogVersion,
    required this.shownAt,
    this.startedAt,
    this.closedAt,
    this.attemptResponse,
    this.usefulnessResponse,
  });

  /// The journal record schema version this entry was written under — see
  /// [circleJournalSchemaVersion].
  final int schemaVersion;

  /// This Circle's stable identity — see class doc comment.
  final String circleId;

  /// The local calendar date (`YYYY-MM-DD`, `date_key.dart`'s [dateKey]
  /// format) this Circle belongs to.
  final String localDate;

  /// The direction ([Intention]) selected for this Circle.
  final Intention direction;

  /// The resolved [ActivityId] for this Circle.
  final ActivityId activityId;

  /// The [catalogVersion] the catalogue was at when [activityId] was
  /// resolved — lets a future catalogue revision tell which version of an
  /// activity's content a historical record actually refers to.
  final int catalogVersion;

  /// When this Circle's recommendation was resolved (`chooseIntention()`).
  final DateTime shownAt;

  /// When this Circle was started, or `null` if it never was.
  final DateTime? startedAt;

  /// When this Circle was closed, or `null` if it never was.
  final DateTime? closedAt;

  /// The user's optional "Did you try this activity?" answer — `null`
  /// means no answer was given (UNKNOWN, never treated as a negative).
  final CircleAttemptResponse? attemptResponse;

  /// The user's optional self-reported usefulness rating — `null` means
  /// no answer was given, or none was offered because [attemptResponse]
  /// was not affirmative.
  final CircleUsefulnessResponse? usefulnessResponse;

  CircleJournalEntry copyWith({
    DateTime? startedAt,
    DateTime? closedAt,
    CircleAttemptResponse? attemptResponse,
    CircleUsefulnessResponse? usefulnessResponse,
  }) {
    return CircleJournalEntry(
      schemaVersion: schemaVersion,
      circleId: circleId,
      localDate: localDate,
      direction: direction,
      activityId: activityId,
      catalogVersion: catalogVersion,
      shownAt: shownAt,
      startedAt: startedAt ?? this.startedAt,
      closedAt: closedAt ?? this.closedAt,
      attemptResponse: attemptResponse ?? this.attemptResponse,
      usefulnessResponse: usefulnessResponse ?? this.usefulnessResponse,
    );
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'circleId': circleId,
    'localDate': localDate,
    'direction': direction.name,
    'activityId': activityId.name,
    'catalogVersion': catalogVersion,
    'shownAt': shownAt.toIso8601String(),
    'startedAt': startedAt?.toIso8601String(),
    'closedAt': closedAt?.toIso8601String(),
    'attemptResponse': attemptResponse?.wireName,
    'usefulnessResponse': usefulnessResponse?.wireName,
  };

  /// Parses one journal entry, or `null` if [json] is missing or has an
  /// invalid value for any required field — a single corrupt entry is
  /// dropped, never allowed to make the rest of the journal unreadable
  /// (see [CircleJournalRepository]'s read path).
  static CircleJournalEntry? fromJson(Map<String, Object?> json) {
    final schemaVersion = json['schemaVersion'];
    final circleId = json['circleId'];
    final localDate = json['localDate'];
    final direction = Intention.values.asNameMap()[json['direction']];
    final activityId = ActivityId.values.asNameMap()[json['activityId']];
    final catalogVersion = json['catalogVersion'];
    final shownAt = DateTime.tryParse('${json['shownAt']}');

    if (schemaVersion is! int ||
        circleId is! String ||
        localDate is! String ||
        direction == null ||
        activityId == null ||
        catalogVersion is! int ||
        shownAt == null) {
      return null;
    }
    // Compatibility must hold for a historical entry exactly as it must
    // for today's live restore (recommendation_provider.dart) — an
    // activity that no longer belongs to its recorded direction's pool is
    // dropped rather than shown as a lie about what actually happened.
    if (!(activityPools[direction] ?? const []).contains(activityId)) {
      return null;
    }

    final startedAtRaw = json['startedAt'];
    final startedAt = startedAtRaw == null
        ? null
        : DateTime.tryParse('$startedAtRaw');
    final closedAtRaw = json['closedAt'];
    final closedAt = closedAtRaw == null
        ? null
        : DateTime.tryParse('$closedAtRaw');

    return CircleJournalEntry(
      schemaVersion: schemaVersion,
      circleId: circleId,
      localDate: localDate,
      direction: direction,
      activityId: activityId,
      catalogVersion: catalogVersion,
      shownAt: shownAt,
      startedAt: startedAt,
      closedAt: closedAt,
      attemptResponse: CircleAttemptResponse.values
          .asNameMap()[json['attemptResponse']],
      usefulnessResponse: CircleUsefulnessResponse.values
          .asNameMap()[json['usefulnessResponse']],
    );
  }
}

/// SharedPreferences key the entire journal is stored under, as one
/// JSON-encoded object (see [CircleJournalRepository]) — a single
/// coherent, versioned blob rather than one preference key per field, so a
/// write is one atomic string replace instead of several independent
/// preference writes that could observe a partial state between them.
const circleJournalKey = 'circle_journal_v1';

/// The current journal record-shape version. Bump only alongside a
/// reviewed schema-migration change to [CircleJournalRepository]'s
/// read/write path — never as an incidental side effect.
const circleJournalSchemaVersion = 1;

/// The hard cap on retained journal entries: at most this many of the most
/// recent local dates are kept, oldest dropped first.
///
/// The frozen recurring Premium architecture
/// (`docs/product/RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md`
/// §9, "Local history contract") states these as two separate figures: a
/// **365-day rolling retention window**, and a **hard cap of 366 Circle
/// records**. This constant is the latter — the actual enforced bound — not
/// a "366 days" reinterpretation of the former; the retention window
/// remains 365 days. One entry exists per local date, so in ordinary
/// operation (no missed days) this cap is reached one day after the
/// 365-day window itself would have started dropping entries — the source
/// document does not explain the one-entry difference further, and none is
/// invented here.
const circleJournalMaxRecords = 366;

/// Reads, writes, and bounds THIRTY's prospective local Circle journal.
///
/// **Not analytics.** The existing Supabase `analytics_events` table
/// (`analytics_service.dart`) remains a narrow, pseudonymous, append-only
/// behavioural-measurement sink with no per-user read path in the app
/// itself — it was never designed to be queried back as a personal
/// record, and doing so would also silently turn Supabase into exactly
/// the "general application backend" AGENTS.md §5 and this batch's own
/// authority both rule out.
///
/// **Not derived from Batch 2's anti-repetition history.**
/// `recommendation_provider.dart`'s per-[Intention]
/// `recommendationHistoryKeyFor` lists exist only to drive the diversity
/// guard — they are short (`pool.length - 1` entries), unordered by date,
/// carry no timestamps, and are silently truncated. Treating them as a
/// historical record would fabricate a false journal, which ADR-013
/// explicitly forbids.
///
/// One entry per local date, upserted as that date's Circle progresses
/// through [recordShown]/[recordStarted]/[recordClosed]/[recordAttempt]/
/// [recordUsefulness] — never more than [circleJournalMaxRecords]
/// entries kept at once.
class CircleJournalRepository {
  CircleJournalRepository(this._prefs);

  final SharedPreferences _prefs;

  /// All journal entries currently retained, oldest local date first.
  List<CircleJournalEntry> readAll() {
    final entries = _readRaw();
    entries.sort((a, b) => a.localDate.compareTo(b.localDate));
    return entries;
  }

  /// Records (or, if [circleId] already has an entry, leaves unchanged —
  /// `RecommendationNotifier.chooseIntention` is already a no-op past the
  /// first call for a given day, so this should never actually overwrite
  /// an existing entry) today's "shown" record.
  Future<void> recordShown({
    required String circleId,
    required String localDate,
    required Intention direction,
    required ActivityId activityId,
    required DateTime shownAt,
  }) => _upsert(
    circleId: circleId,
    localDate: localDate,
    direction: direction,
    activityId: activityId,
    fallbackShownAt: shownAt,
    update: (entry) => entry,
  );

  /// Records [startedAt] on [circleId]'s entry.
  ///
  /// Self-healing rather than a strict update: if [circleId] has no entry
  /// yet — e.g. the app was killed between [recordShown] and this call, or
  /// a fire-and-forget write from `chooseIntention` simply hasn't landed
  /// yet by the time the user taps Start — one is synthesized here from
  /// [localDate]/[direction]/[activityId] instead of silently losing the
  /// day's record. Its `shownAt` becomes [startedAt] in that case, the
  /// closest honest estimate available (ADR-013 §3, "handle safely:
  /// process interruption during writes").
  Future<void> recordStarted({
    required String circleId,
    required String localDate,
    required Intention direction,
    required ActivityId activityId,
    required DateTime startedAt,
  }) => _upsert(
    circleId: circleId,
    localDate: localDate,
    direction: direction,
    activityId: activityId,
    fallbackShownAt: startedAt,
    update: (entry) => entry.copyWith(startedAt: startedAt),
  );

  /// Records [closedAt] on [circleId]'s entry. See [recordStarted] for the
  /// self-healing behaviour if the entry doesn't exist yet.
  Future<void> recordClosed({
    required String circleId,
    required String localDate,
    required Intention direction,
    required ActivityId activityId,
    required DateTime closedAt,
  }) => _upsert(
    circleId: circleId,
    localDate: localDate,
    direction: direction,
    activityId: activityId,
    fallbackShownAt: closedAt,
    update: (entry) => entry.copyWith(closedAt: closedAt),
  );

  /// Records the user's "Did you try this activity?" answer on [circleId]'s
  /// entry. Overwrites any earlier answer for the same [circleId] —
  /// changing your mind is allowed, this is never a one-shot lock. A
  /// non-affirmative [response] (or a changed answer that is no longer
  /// affirmative) clears any previously recorded [CircleUsefulnessResponse]
  /// on the same entry — usefulness may only ever follow an affirmative
  /// attempt (ADR-013 §4). See [recordStarted] for the self-healing
  /// behaviour if the entry doesn't exist yet.
  Future<void> recordAttempt({
    required String circleId,
    required String localDate,
    required Intention direction,
    required ActivityId activityId,
    required CircleAttemptResponse response,
    required DateTime respondedAt,
  }) => _upsert(
    circleId: circleId,
    localDate: localDate,
    direction: direction,
    activityId: activityId,
    fallbackShownAt: respondedAt,
    update: (entry) {
      final isAffirmative =
          response == CircleAttemptResponse.yes ||
          response == CircleAttemptResponse.aLittle;
      return CircleJournalEntry(
        schemaVersion: entry.schemaVersion,
        circleId: entry.circleId,
        localDate: entry.localDate,
        direction: entry.direction,
        activityId: entry.activityId,
        catalogVersion: entry.catalogVersion,
        shownAt: entry.shownAt,
        startedAt: entry.startedAt,
        closedAt: entry.closedAt,
        attemptResponse: response,
        usefulnessResponse: isAffirmative ? entry.usefulnessResponse : null,
      );
    },
  );

  /// Records the user's optional usefulness rating on [circleId]'s entry.
  /// See [recordAttempt].
  Future<void> recordUsefulness({
    required String circleId,
    required String localDate,
    required Intention direction,
    required ActivityId activityId,
    required CircleUsefulnessResponse response,
    required DateTime respondedAt,
  }) => _upsert(
    circleId: circleId,
    localDate: localDate,
    direction: direction,
    activityId: activityId,
    fallbackShownAt: respondedAt,
    update: (entry) => entry.copyWith(usefulnessResponse: response),
  );

  /// Permanently deletes the entire local journal (ADR-013 §6 — "local
  /// deletion/reset control"). Irreversible; there is no undo and nothing
  /// to restore it from, since nothing is ever sent off-device.
  Future<void> clearAll() async {
    await _prefs.remove(circleJournalKey);
  }

  /// The full retained journal, pretty-printed as JSON (ADR-013 §6 —
  /// "local export capability"). Text-only, so it can be copied to the
  /// system clipboard without adding a file-sharing dependency (AGENTS.md
  /// §5 — no new packages beyond `pubspec.yaml`); see
  /// `circle_history_page.dart` for where this is offered to the user.
  String exportAsJson() {
    final entries = readAll();
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert({
      'schemaVersion': circleJournalSchemaVersion,
      'entries': entries.map((entry) => entry.toJson()).toList(),
    });
  }

  /// Finds [circleId]'s entry and applies [update] to it, or — if none
  /// exists yet — synthesizes one from [localDate]/[direction]/[activityId]
  /// (with `shownAt` set to [fallbackShownAt]) and applies [update] to
  /// that instead. See [recordStarted]'s doc comment for why this never
  /// simply no-ops on a missing entry.
  Future<void> _upsert({
    required String circleId,
    required String localDate,
    required Intention direction,
    required ActivityId activityId,
    required DateTime fallbackShownAt,
    required CircleJournalEntry Function(CircleJournalEntry entry) update,
  }) async {
    final entries = _readRaw();
    final index = entries.indexWhere((entry) => entry.circleId == circleId);
    final base = index == -1
        ? CircleJournalEntry(
            schemaVersion: circleJournalSchemaVersion,
            circleId: circleId,
            localDate: localDate,
            direction: direction,
            activityId: activityId,
            catalogVersion: catalogVersion,
            shownAt: fallbackShownAt,
          )
        : entries[index];

    final updated = update(base);
    if (index == -1) {
      entries.add(updated);
    } else {
      entries[index] = updated;
    }
    await _save(entries);
  }

  Future<void> _save(List<CircleJournalEntry> entries) async {
    entries.sort((a, b) => a.localDate.compareTo(b.localDate));
    final capped = entries.length > circleJournalMaxRecords
        ? entries.sublist(entries.length - circleJournalMaxRecords)
        : entries;

    final json = jsonEncode({
      'schemaVersion': circleJournalSchemaVersion,
      'entries': capped.map((entry) => entry.toJson()).toList(),
    });
    await _prefs.setString(circleJournalKey, json);
  }

  /// Reads and decodes the persisted journal, failing safe to an empty
  /// list (never throwing) for anything unreadable: no stored value, a
  /// non-JSON string, a wrapper missing/mismatching [circleJournalSchemaVersion]
  /// (including a *future* version this build predates, which it has no
  /// safe way to interpret), or a malformed `entries` list. Individual
  /// malformed entries within an otherwise valid wrapper are dropped one
  /// at a time by [CircleJournalEntry.fromJson] instead — a single bad
  /// record must never take down the rest of the journal.
  List<CircleJournalEntry> _readRaw() {
    final raw = _prefs.getString(circleJournalKey);
    if (raw == null) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return [];
      if (decoded['schemaVersion'] != circleJournalSchemaVersion) return [];

      final rawEntries = decoded['entries'];
      if (rawEntries is! List) return [];

      final entries = <CircleJournalEntry>[];
      for (final rawEntry in rawEntries) {
        if (rawEntry is! Map<String, Object?>) continue;
        final entry = CircleJournalEntry.fromJson(rawEntry);
        if (entry != null) entries.add(entry);
      }
      return entries;
    } catch (_) {
      return [];
    }
  }
}

/// The [CircleJournalRepository] backed by the app's resolved
/// [SharedPreferences] instance — read by `recommendation_provider.dart`
/// (to record each Circle's progression) and `circle_history_page.dart`
/// (to read, clear, and export it).
final circleJournalRepositoryProvider = Provider<CircleJournalRepository>(
  (ref) => CircleJournalRepository(ref.watch(sharedPreferencesProvider)),
);
