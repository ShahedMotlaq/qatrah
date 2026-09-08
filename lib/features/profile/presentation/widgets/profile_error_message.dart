import 'package:qatrah/l10n/gen/app_localizations.dart';

String profileErrorMessage(AppLocalizations l10n, String message) {
  switch (message) {
    case 'completeRequiredFields':
      return l10n.completeRequiredFields;
    default:
      return message;
  }
}
