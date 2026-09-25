import 'package:flutter/material.dart';

/// THIRTY's quiet text action (Phase C3): a secondary, text-only action —
/// management and shortcut actions that should never compete with a
/// screen's one [ThirtyButton] main action.
///
/// Keeps a 48pt tap target and lets its label wrap freely, so it is never
/// truncated at large accessibility text. Uses the theme's `primary` text
/// colour (AA on every THIRTY surface); a `null` [onPressed] disables it.
class ThirtyTextAction extends StatelessWidget {
  const ThirtyTextAction({
    required this.label,
    required this.onPressed,
    this.centered = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Centred (e.g. inside Home's centred Plan session panel) instead of the
  /// default start alignment.
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 48),
        alignment: centered
            ? Alignment.center
            : AlignmentDirectional.centerStart,
      ),
      child: Text(
        label,
        textAlign: centered ? TextAlign.center : TextAlign.start,
      ),
    );
  }
}
