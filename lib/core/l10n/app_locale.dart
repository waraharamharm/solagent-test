import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:solagent/l10n/app_localizations.dart';

import '../security/secure_store.dart';
import 'locale_resolver.dart';

part 'app_locale.g.dart';

/// Names of the languages in the picker, each in its own language.
/// Add an entry with each new ARB file.
const languageEndonyms = <String, String>{
  'en': 'English',
  'ru': '\u0420\u0443\u0441\u0441\u043a\u0438\u0439',
};

/// The language the user picked by hand, or null to follow the device.
/// Kept on the device.
@Riverpod(keepAlive: true)
class LanguagePreference extends _$LanguagePreference {
  static const _key = 'ui.language';

  @override
  String? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    try {
      final saved = await ref.read(secureStoreProvider).read(_key);
      final supported = {
        for (final l in AppLocalizations.supportedLocales) l.languageCode,
      };
      if (saved != null && supported.contains(saved) && ref.mounted) {
        state = saved;
      }
    } catch (_) {
      // A lost preference means "follow the device".
    }
  }

  /// [languageCode] null returns to following the device language.
  Future<void> set(String? languageCode) async {
    state = languageCode;
    try {
      final store = ref.read(secureStoreProvider);
      if (languageCode == null) {
        await store.delete(_key);
      } else {
        await store.write(_key, languageCode);
      }
    } catch (_) {
      // Applied for this session even if it could not be stored.
    }
  }
}

/// The language the app shows: the manual choice if there is one, otherwise
/// the device language list (re-read when the user changes it in system
/// settings).
@Riverpod(keepAlive: true)
class AppLocale extends _$AppLocale with WidgetsBindingObserver {
  @override
  Locale build() {
    final binding = WidgetsBinding.instance..addObserver(this);
    ref.onDispose(() => binding.removeObserver(this));
    final manual = ref.watch(languagePreferenceProvider);
    if (manual != null) return Locale(manual);
    return resolveAppLocaleDefault(binding.platformDispatcher.locales);
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (ref.read(languagePreferenceProvider) != null) return;
    state = resolveAppLocaleDefault(locales);
  }
}

/// Strings for code that has no BuildContext (controllers, services).
/// Widgets use `context.l10n`.
@Riverpod(keepAlive: true)
AppLocalizations appL10n(Ref ref) =>
    lookupAppLocalizations(ref.watch(appLocaleProvider));
