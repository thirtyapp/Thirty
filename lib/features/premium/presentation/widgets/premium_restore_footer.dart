import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/premium/entitlement_status.dart';
import '../../../../core/premium/premium_access.dart';
import '../../../../core/theme/design_tokens.dart';

/// The quiet billing footer shared by You (under its Premium card, Phase
/// C1) and the Premium offer page (Phase C2): "Restore purchases" with the
/// reminder that restoring is about Premium access only — THIRTY has no
/// account, and Circle history lives on this device alone.
///
/// Restores through [EntitlementNotifier.restore], so a successful restore
/// updates entitlement state straight away. Hidden while the entitlement
/// state is still being checked.
class PremiumRestoreFooter extends ConsumerStatefulWidget {
  const PremiumRestoreFooter({
    this.horizontalInset = AppSpacing.featuredCard,
    this.enabled = true,
    super.key,
  });

  /// Side inset: You aligns the footer with its Premium card's content;
  /// the offer page aligns it with the page itself.
  final double horizontalInset;

  /// `false` disables Restore (e.g. while a purchase is in flight).
  final bool enabled;

  @override
  ConsumerState<PremiumRestoreFooter> createState() =>
      _PremiumRestoreFooterState();
}

class _PremiumRestoreFooterState extends ConsumerState<PremiumRestoreFooter> {
  bool _isRestoring = false;
  String? _message;
  final _messageKey = GlobalKey();

  Future<void> _restore() async {
    setState(() {
      _isRestoring = true;
      _message = null;
    });
    final outcome = await ref.read(entitlementStatusProvider.notifier).restore();
    if (!mounted) return;
    setState(() {
      _isRestoring = false;
      _message = switch (outcome) {
        RestoreOutcome.restored => 'Your Premium access has been restored.',
        RestoreOutcome.notFound => 'No previous purchase was found to restore.',
        RestoreOutcome.unavailable =>
          'Restore isn’t available right now. Please try again later.',
        RestoreOutcome.error =>
          'Something went wrong restoring your purchase. Please try again.',
      };
    });
    // Restore is the last section on You, so the result line appears below
    // the visible page; bring it on screen (the live region announces it
    // either way).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messageContext = _messageKey.currentContext;
      if (messageContext == null) return;
      Scrollable.ensureVisible(
        messageContext,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(entitlementStatusProvider);
    if (status == EntitlementStatus.initializing) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final quiet = textTheme.bodySmall?.copyWith(color: colors.textSecondary);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        widget.horizontalInset,
        AppSpacing.xs,
        widget.horizontalInset,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            onPressed: _isRestoring || !widget.enabled ? null : _restore,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 48),
              alignment: AlignmentDirectional.centerStart,
            ),
            child: const Text('Restore purchases'),
          ),
          Text(
            'Restores Premium access only. Your Circle history stays on this '
            'device.',
            style: quiet,
          ),
          if (_message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Semantics(
              key: _messageKey,
              liveRegion: true,
              child: Text(_message!, style: quiet),
            ),
          ],
        ],
      ),
    );
  }
}
