import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';
import '../../../../core/widgets/thirty_confirm_dialog.dart';
import '../../../../core/widgets/thirty_notice_dialog.dart';
import '../../../insights/application/insights_provider.dart';
import '../../../insights/domain/insight.dart';
import '../../../personal_circle/application/kept_circles_provider.dart';
import '../../../personal_circle/domain/kept_circle.dart';
import '../../../plans/application/circle_plans_provider.dart';
import '../../../plans/domain/circle_plan.dart';
import '../../application/circle_history_deletion.dart';
import '../../application/circle_journal.dart';
import '../../application/suggestion_preferences.dart';

/// THIRTY's local Circle-journal export/delete controls — extracted from
/// `../circle_history_page.dart` (founder IA correction — "export/delete
/// remain under You > Your data") so the same behavior is available both
/// there and from `../../../settings/presentation/settings_page.dart`'s
/// "Your data" section, without duplicating the confirm-dialog/export
/// logic or the underlying data.
///
/// Free/shared, entitlement-independent — Journal access never depended
/// on Premium and this correction does not change that.
class JournalDataControls extends ConsumerWidget {
  const JournalDataControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journal = ref.watch(circleJournalRepositoryProvider);
    // Audit remediation R8 (Astra R7-A06): History THIRTY can't read is
    // still the user's to export and delete — never only what it reads.
    final hasEntries = journal.holdsHistory;

    // Paired buttons share one height: if large text wraps one label onto
    // a second line, both grow together (IntrinsicHeight + stretch). At
    // ordinary text sizes both stay exactly 48pt.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ThirtyButton(
              label: 'Copy as text',
              variant: ThirtyButtonVariant.secondary,
              onPressed: canCopyAsText(ref)
                  ? () => copyAsText(context, ref)
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: ThirtyButton(
              label: 'Delete all',
              variant: ThirtyButtonVariant.secondary,
              onPressed: hasEntries
                  ? () => confirmAndClear(context, journal, ref)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Whether "Copy as text" has anything of the user's to copy — watched,
  /// for a control's build. L-1 Option B: a preferences record THIRTY can't
  /// read counts, even when it is the only thing stored.
  static bool canCopyAsText(WidgetRef ref) =>
      ref.watch(circleJournalRepositoryProvider).holdsHistory ||
      !ref.watch(suggestionPreferencesProvider).isEmpty ||
      ref.watch(unreadableSuggestionPreferencesProvider) != null ||
      !ref.watch(keptCirclesProvider).isEmpty ||
      ref.watch(circlePlansProvider).plans.isNotEmpty ||
      !ref.watch(insightsProvider).isEmpty;

  /// "Copy as text" from History, You's "Your data" and the memory page:
  /// [exportToClipboard] with everything as it stands when tapped (L-1
  /// Option B) — the readable preferences and a record THIRTY can't read
  /// are read together, so one confirmed Reset never leaves the old record
  /// in a later copy.
  static Future<void> copyAsText(BuildContext context, WidgetRef ref) =>
      exportToClipboard(
        context,
        ref.read(circleJournalRepositoryProvider),
        preferences: ref.read(suggestionPreferencesProvider),
        storedPreferences: ref.read(unreadableSuggestionPreferencesProvider),
        kept: ref.read(keptCirclesProvider),
        plans: ref.read(circlePlansProvider),
        insights: ref.read(insightsProvider),
      );

  /// Copies the journal as text — with the user's suggestion preferences
  /// beside it (V2 Phase C), when there are any — and confirms with a
  /// SnackBar. Shared with You's own "Your data" rows (`settings_page.dart`),
  /// which present the same actions stacked; this widget's own side-by-side
  /// layout (Circle history) is unchanged.
  ///
  /// L-1 Option B: a preferences record THIRTY can't read as a whole
  /// ([storedPreferences]) is copied exactly as stored. A copy that can't be
  /// made — the export can't be written, or the clipboard refuses it — says
  /// so; it is never announced as copied.
  static Future<void> exportToClipboard(
    BuildContext context,
    CircleJournalRepository journal, {
    SuggestionPreferences preferences = SuggestionPreferences.empty,
    UnreadableSuggestionPreferences? storedPreferences,
    KeptCircles kept = KeptCircles.empty,
    CirclePlansState plans = CirclePlansState.empty,
    InsightsState insights = InsightsState.empty,
  }) async {
    try {
      await Clipboard.setData(
        ClipboardData(
          text: journal.exportAsJson(
            suggestionPreferences: preferences.isEmpty
                ? null
                : preferences.toJson(),
            suggestionPreferencesStored: storedPreferences?.toExport(),
            // The Circles the user kept — never a derived score — as
            // stored, one THIRTY can't read included, each in its place
            // (R4).
            keptCircles: kept.isEmpty
                ? null
                : keptCirclesRecord(kept.kept, retained: kept.retained)['kept']
                      as List<Object?>,
            keptCirclesUnreadable: kept.unreadable.isEmpty
                ? null
                : [for (final store in kept.unreadable) store.raw],
            // Each Circle Plan's place, cycles and stage records (B3).
            circlePlans: plans.plans.isEmpty ? null : plans.toJson(),
            // The Insights THIRTY showed, as shown (B5) — no profile.
            insights: insights.isEmpty ? null : insights.toJson(),
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UnreadablePreferencesCopy.copyFailed)),
      );
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied your Circle history as text.')),
    );
  }

  /// Asks for explicit confirmation, then deletes every recorded Circle —
  /// the journal, today's Circle session and the selection history drawn
  /// from past Circles — and with them everything learned from them. Today
  /// is then re-derived from the empty store, so no deleted Circle stays on
  /// screen. Shared with You's "Your data" rows.
  ///
  /// Kept Circles and suggestion preferences are kept — they have their own
  /// controls — but nothing learned survives the evidence it came from.
  /// A Circle Plan keeps its place; its stage evidence and reviews go with
  /// the journal (contract, Delete / Export), and so does every Insight
  /// snapshot — each is derived from it.
  ///
  /// L-1 Option B (founder decision, 2026-11-11): when the stored
  /// suggestion preferences are a record THIRTY can't read as a whole, the
  /// confirmation says they can't be checked for links to this history and
  /// will be kept unchanged; and a Delete that succeeded says the History
  /// was deleted but that record couldn't be checked — never shown after a
  /// Delete that didn't start or didn't finish.
  static Future<void> confirmAndClear(
    BuildContext context,
    CircleJournalRepository journal,
    WidgetRef ref,
  ) async {
    final unreadable =
        ref.read(unreadableSuggestionPreferencesProvider) != null;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierLabel: 'Keep my history',
      builder: (_) => ThirtyConfirmDialog(
        title: 'Delete your Circle history?',
        body: unreadable
            ? deleteConfirmBodyWithUnreadablePreferences
            : deleteConfirmBody,
        cancelLabel: 'Keep my history',
        confirmLabel: 'Delete permanently',
        destructive: true,
      ),
    );
    if (confirmed != true) return;

    // Audit remediation R3: one deletion, behind a barrier no earlier write
    // can cross, finished on the next start if the app stops midway. If it
    // can't be finished now, the user is told so — never that it was done.
    try {
      await ref.read(circleHistoryDeletionProvider).delete();
      // L-1 Option B: done — every known History store is deleted and
      // confirmed. A preferences record THIRTY can't read was kept as
      // stored, unchecked: said so, not claimed.
      if (!context.mounted ||
          ref.read(unreadableSuggestionPreferencesProvider) == null) {
        return;
      }
      await showDialog<void>(
        context: context,
        barrierLabel: 'Close',
        builder: (_) => const ThirtyNoticeDialog(
          title: UnreadablePreferencesCopy.deletedTitle,
          body: UnreadablePreferencesCopy.deletedBody,
        ),
      );
    } on HistoryDeletionNotStarted {
      // Audit remediation R8: nothing was deleted — never "will finish".
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        barrierLabel: 'Close',
        builder: (_) => const ThirtyNoticeDialog(
          title: deleteNotStartedTitle,
          body: deleteNotStartedBody,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      await showDeleteUnfinished(context);
    }
  }

  /// Tells the user Delete Circle history couldn't be finished (founder
  /// copy) — after Delete itself, and when a pending deletion still can't be
  /// finished before a new Circle.
  static Future<void> showDeleteUnfinished(BuildContext context) =>
      showDialog<void>(
        context: context,
        barrierLabel: 'Close',
        builder: (_) => const ThirtyNoticeDialog(
          title: deleteUnfinishedTitle,
          body: deleteUnfinishedBody,
        ),
      );
}

/// The Delete Circle history confirmation (contract, Delete / Export).
const deleteConfirmBody =
    'This permanently deletes every recorded Circle on this device, '
    'and everything THIRTY has learned from them, Insights and Plan '
    'reviews included. Your kept Circles, each Plan’s place and '
    'your suggestion preferences are kept — you can change those '
    'yourself. It cannot be undone, and nothing is '
    'stored anywhere else to restore it from. If you shared usage '
    'data, what was already sent isn’t deleted.';

/// [deleteConfirmBody] when the stored suggestion preferences are a record THIRTY
/// can't read as a whole (L-1 Option B, founder decision 2026-11-11): the
/// same words, and one sentence more.
const deleteConfirmBodyWithUnreadablePreferences =
    'This permanently deletes every recorded Circle on this device, '
    'and everything THIRTY has learned from them, Insights and Plan '
    'reviews included. Your kept Circles, each Plan’s place and '
    'your suggestion preferences are kept — you can change those '
    'yourself. Some saved suggestion preferences can’t be read, so THIRTY '
    'can’t check them for links to this history; they’ll be kept '
    'unchanged. It cannot be undone, and nothing is '
    'stored anywhere else to restore it from. If you shared usage '
    'data, what was already sent isn’t deleted.';

/// L-1 Option B (founder decision, 2026-11-11): the words about a stored
/// suggestion preferences record THIRTY can't read as a whole, in one place
/// (English; listed for the six-language localization work).
abstract final class UnreadablePreferencesCopy {
  /// After a Delete Circle history that succeeded (founder copy direction).
  static const deletedTitle = 'Some saved preferences couldn’t be checked';

  /// See [deletedTitle] (founder copy direction).
  static const deletedBody =
      'Your Circle history was deleted, but THIRTY couldn’t read some saved '
      'suggestion preferences to check whether they contain links to that '
      'history.\n\n'
      'Your preferences have been kept unchanged. You can export them or '
      'remove them using Reset suggestion preferences.';

  /// What THIRTY remembers, for as long as the record is stored. It never
  /// says a Delete happened: the record may predate any.
  static const memoryNotice =
      'Some saved suggestion preferences couldn’t be read. They’re kept '
      'unchanged and may include links to earlier history that THIRTY '
      'can’t check. You can copy your data before choosing to reset them.';

  /// Reset's own warning for that record (founder copy direction).
  static const resetTitle = 'Reset unreadable suggestion preferences?';

  /// See [resetTitle] (founder copy direction).
  static const resetBody =
      'THIRTY can’t read all your saved suggestion preferences. Reset will '
      'permanently remove that saved record, including choices THIRTY can’t '
      'currently show or restore.\n\n'
      'You can copy your saved data first from Your data. Your Circle history '
      'and answers won’t be deleted by this reset.';

  /// "Copy as text" that couldn't be made — never "Copied".
  static const copyFailed = 'Couldn’t copy your data. Please try again.';
}

/// Shown when Delete Circle history couldn't be finished (founder copy,
/// audit remediation R3). The deletion stays recorded and is finished on the
/// next start.
const deleteUnfinishedTitle = 'Couldn’t finish deleting your history.';

/// See [deleteUnfinishedTitle].
const deleteUnfinishedBody =
    'THIRTY will try to finish when you next open the app.';

/// Shown when Delete Circle history couldn't begin — its intent couldn't be
/// recorded, so nothing was deleted (audit remediation R8, Astra R7-A04).
/// Founder wording (D1, 2026-11-04).
const deleteNotStartedTitle = 'Your history wasn’t deleted.';

/// See [deleteNotStartedTitle]. Founder wording (D1, 2026-11-04).
const deleteNotStartedBody = 'Nothing was changed. You can try again.';
