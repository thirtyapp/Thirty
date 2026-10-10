import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// THIRTY's two-choice confirmation dialog (Phase C5): a plain
/// [AlertDialog] whose body can always be read in full.
///
/// Show it with `showDialog<bool>`: [cancelLabel] pops `false`,
/// [confirmLabel] pops `true`, and a barrier tap or system back pops `null`
/// — callers proceed only on `true`.
///
/// At ordinary text sizes it lays out exactly like Material's default
/// dialog. At large accessibility text (≥ 130%, the same threshold as
/// `ThirtyButton`) the side inset narrows from 40pt to 16pt so words are
/// not broken mid-word, and stacked actions get 8pt between them. Title
/// and body scroll together, so a long warning is never cut off; the
/// actions stay visible below.
class ThirtyConfirmDialog extends StatelessWidget {
  const ThirtyConfirmDialog({
    required this.title,
    required this.body,
    required this.cancelLabel,
    required this.confirmLabel,
    this.destructive = false,
    super.key,
  });

  final String title;
  final String body;
  final String cancelLabel;
  final String confirmLabel;

  /// Shows [confirmLabel] in the AA `errorText` colour.
  final bool destructive;

  static const _largeTextScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final largeText =
        MediaQuery.textScalerOf(context).scale(1) >= _largeTextScale;

    return AlertDialog(
      // TalkBack announces the question itself on opening, not "Alert".
      semanticLabel: title,
      scrollable: true,
      insetPadding: largeText
          ? const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.l,
            )
          : null,
      actionsOverflowButtonSpacing: largeText ? AppSpacing.s : null,
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: destructive
              ? TextButton.styleFrom(foregroundColor: colors.errorText)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
