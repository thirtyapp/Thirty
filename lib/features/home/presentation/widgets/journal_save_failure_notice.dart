import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

/// Tells the user, once for each Circle, when its save to History failed
/// (R6 final): never a silent loss, never a false confirmation. Wraps the
/// app's shell, so it is heard whichever tab is open.
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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _check(ref.read(journalSaveStatusProvider)),
    );
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
    return widget.child;
  }
}
