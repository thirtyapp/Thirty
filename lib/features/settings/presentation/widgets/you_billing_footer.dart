import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/premium/entitlement_status.dart';
import '../../../../core/premium/premium_access.dart';
import '../../../../core/theme/design_tokens.dart';

/// The quiet billing footer under You's Premium card (Phase C1): "Restore
/// purchases" lower in the billing area, with the reminder that restoring
/// is about Premium access only — THIRTY has no account, and Circle
/// history lives on this device alone.
///
/// Restores through [EntitlementNotifier.restore], so a successful restore
/// updates the Premium card straight away. Hidden while the entitlement
/// state is still being checked.
class YouBillingFooter extends ConsumerStatefulWidget {
  const YouBillingFooter({super.key});

  @override
  ConsumerState<YouBillingFooter> createState() => _YouBillingFooterState();
}

class _YouBillingFooterState extends ConsumerState<YouBillingFooter> {
  bool _isRestoring = false;
  String? _message;

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
      // Aligned with the Premium card's content above it.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.featuredCard,
        AppSpacing.xs,
        AppSpacing.featuredCard,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            onPressed: _isRestoring ? null : _restore,
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
              liveRegion: true,
              child: Text(_message!, style: quiet),
            ),
          ],
        ],
      ),
    );
  }
}
