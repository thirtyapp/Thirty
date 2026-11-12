import 'package:flutter/material.dart';

import '../../../../core/config/release_info.dart';
import '../../../../core/l10n/thirty_locales.dart';
import 'you_group_card.dart';

/// You's "About" group: informational only — THIRTY and the running build's
/// version ([ReleaseInfo.appVersion], the app's one version source). No
/// links: a privacy policy and support contact appear only once real
/// destinations exist.
///
/// Its words come from THIRTY's catalogue (`app_en.arb`): `brandName` and
/// `youAboutVersion`, which inserts [ReleaseInfo.appVersion] verbatim.
class YouAboutCard extends StatelessWidget {
  const YouAboutCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return YouGroupCard(
      children: [
        YouRow(
          icon: Icons.info_outline,
          child: MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                YouRowTitle(l10n.brandName),
                const SizedBox(height: 2),
                YouRowDetail(l10n.youAboutVersion(ReleaseInfo.appVersion)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
