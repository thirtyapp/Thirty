import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// THIRTY's one-action notice: something the user should know, with nothing
/// to decide — the sibling of `ThirtyConfirmDialog`, laid out the same way.
///
/// At ordinary text sizes it lays out exactly like Material's default
/// dialog. At large accessibility text (≥ 130%) the side inset narrows from
/// 40pt to 16pt so words are not broken mid-word. Title and body scroll
/// together, so the message is never cut off; the action stays visible.
class ThirtyNoticeDialog extends StatelessWidget {
  const ThirtyNoticeDialog({
    required this.title,
    required this.body,
    this.closeLabel = 'Close',
    super.key,
  });

  final String title;
  final String body;
  final String closeLabel;

  static const _largeTextScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final largeText =
        MediaQuery.textScalerOf(context).scale(1) >= _largeTextScale;

    return AlertDialog(
      // TalkBack announces the message itself on opening, not "Alert".
      semanticLabel: title,
      scrollable: true,
      insetPadding: largeText
          ? const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.l,
            )
          : null,
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(closeLabel),
        ),
      ],
    );
  }
}
