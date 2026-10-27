import 'package:flutter/widgets.dart';
import 'package:solagent/l10n/app_localizations.dart';

export 'package:solagent/l10n/app_localizations.dart';

extension AppL10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
