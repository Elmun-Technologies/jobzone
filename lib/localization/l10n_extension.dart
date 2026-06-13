import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

/// `context.l10n.signIn` — concise access to localized strings.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
