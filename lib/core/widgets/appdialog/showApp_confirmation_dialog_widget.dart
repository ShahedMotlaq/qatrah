import 'package:flutter/material.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';

Future<bool?> showAppConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmText,
}) {
  final l10n = context.l10n;

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmText ?? l10n.confirm),
        ),
      ],
    ),
  );
}
