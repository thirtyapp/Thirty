import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/store_save_failures.dart';
import '../../../../core/widgets/thirty_notice_dialog.dart';
import '../../application/circle_journal.dart';

/// The words for History that couldn't be saved or opened (R6 final).
abstract final class JournalSaveCopy {
  /// A Circle's save to History failed — founder wording (2026-11-03),
  /// split into the notice's title and body.
  static const notSavedTitle = 'This Circle couldn’t be saved to History.';
  static const notSavedBody = 'Your existing saved data wasn’t overwritten.';

  /// Earlier History couldn't be opened and a copy of it was kept before
  /// THIRTY wrote anything new — founder wording (2026-11-03).
  static const preserved =
      'Some earlier History couldn’t be opened. THIRTY preserved a copy '
      'before continuing.';

  /// History this build can't open (damaged, or saved by a newer THIRTY),
  /// still exactly as stored — nothing copied or written over it yet.
  /// Founder-approved wording (2026-11-03).
  static const unopened =
      'Your History couldn’t be opened. THIRTY has left the stored data '
      'unchanged.';

  /// A change to the user's own kept Circles, Plans or Insights wasn't
  /// saved (audit remediation R8) — founder wording (D1, 2026-11-04). It
  /// claims nothing about what was stored before: that isn't proven for
  /// every failure path.
  static const changeNotSavedTitle = 'This change couldn’t be saved.';

  /// See [changeNotSavedTitle] — founder wording (D1, 2026-11-04).
  static const changeNotSavedBody = 'Please try again.';
}

/// Tells the user, once for each Circle, when its save to History failed
/// (R6 final): never a silent loss, never a false confirmation. Wraps the
/// app's shell, so it is heard whichever tab is open.
///
/// Audit remediation R8 (Claude F-6, Astra R7-A03): also each time a save of
/// the user's kept Circles, Plans or Insights isn't confirmed
/// ([storeSaveFailuresProvider]) — once per failure, never stacked.
class JournalSaveFailureNotice extends ConsumerStatefulWidget {
  const JournalSaveFailureNotice({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<JournalSaveFailureNotice> createState() =>
      _JournalSaveFailureNoticeState();
}

class _JournalSaveFailureNoticeState
    extends ConsumerState<JournalSaveFailureNotice> {
  /// Circles whose failure has been shown in this session.
  final _told = <String>{};
  var _showing = false;

  @override
  void initState() {
    super.initState();
    // A failure that happened before this was on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _check(ref.read(journalSaveStatusProvider));
      _checkStores(ref.read(storeSaveFailuresProvider));
    });
  }

  /// Store failures already told.
  var _storeFailuresTold = 0;

  void _checkStores(StoreSaveState failures) {
    if (!mounted || failures.count <= _storeFailuresTold || _showing) return;
    _storeFailuresTold = failures.count;
    _showing = true;
    showDialog<void>(
      context: context,
      barrierLabel: 'Close',
      builder: (_) => const ThirtyNoticeDialog(
        title: JournalSaveCopy.changeNotSavedTitle,
        body: JournalSaveCopy.changeNotSavedBody,
      ),
    ).whenComplete(() => _showing = false);
  }

  void _check(Map<String, bool> outcomes) {
    if (!mounted) return;
    for (final MapEntry(key: circleId, value: saved) in outcomes.entries) {
      if (saved) {
        _told.remove(circleId);
      } else if (!_told.contains(circleId) && !_showing) {
        _told.add(circleId);
        _showing = true;
        showDialog<void>(
          context: context,
          barrierLabel: 'Close',
          builder: (_) => const ThirtyNoticeDialog(
            title: JournalSaveCopy.notSavedTitle,
            body: JournalSaveCopy.notSavedBody,
          ),
        ).whenComplete(() => _showing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(journalSaveStatusProvider, (_, next) => _check(next));
    ref.listen(storeSaveFailuresProvider, (_, next) => _checkStores(next));
    return widget.child;
  }
}
