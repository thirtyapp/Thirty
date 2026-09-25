import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/premium/premium_offer_providers.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';

/// "Manage subscription" for an active subscriber, shared by You's Premium
/// card and the Premium offer page: the store's own management URL
/// (fetched once per mount, [subscriptionManagementUrlProvider]) or, when
/// the store offers none, plain Google Play guidance — never a guessed URL.
class ManageSubscription extends ConsumerWidget {
  const ManageSubscription({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final urlState = ref.watch(subscriptionManagementUrlProvider);
    if (urlState.isLoading) return const SizedBox.shrink();

    final url = urlState.value;
    if (url == null) {
      return Text(
        'Manage or cancel this subscription from the Google Play Store app.',
        style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ThirtyButton(
        label: 'Manage subscription',
        variant: ThirtyButtonVariant.secondary,
        onPressed: () => _open(url),
      ),
    );
  }
}
