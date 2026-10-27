import 'dart:ui';

import 'package:solagent/l10n/app_localizations.dart';

const fallbackLocale = Locale('en');

/// Picks the first device language we ship, in the user's preference order.
/// Anything else gets English. Supported-locale order does not matter, so
/// adding a language never changes the fallback.
Locale resolveAppLocale(
  List<Locale>? deviceLocales,
  Iterable<Locale> supported,
) {
  final languages = {for (final l in supported) l.languageCode};
  for (final device in deviceLocales ?? const <Locale>[]) {
    if (languages.contains(device.languageCode)) {
      return Locale(device.languageCode);
    }
  }
  return fallbackLocale;
}

Locale resolveAppLocaleDefault(List<Locale>? deviceLocales) =>
    resolveAppLocale(deviceLocales, AppLocalizations.supportedLocales);
