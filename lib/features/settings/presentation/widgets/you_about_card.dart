import 'package:flutter/material.dart';

import '../../../../core/config/release_info.dart';
import 'you_group_card.dart';

/// You's "About" group: informational only — THIRTY and the running build's
/// version ([ReleaseInfo.appVersion], the app's one version source). No
/// links: a privacy policy and support contact appear only once real
/// destinations exist.
class YouAboutCard extends StatelessWidget {
  const YouAboutCard({super.key});

  static const versionLabel = 'Version ${ReleaseInfo.appVersion}';

  @override
  Widget build(BuildContext context) {
    return const YouGroupCard(
      children: [
        YouRow(
          icon: Icons.info_outline,
          child: MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                YouRowTitle('THIRTY'),
                SizedBox(height: 2),
                YouRowDetail(versionLabel),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
