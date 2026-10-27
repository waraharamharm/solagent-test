import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solagent/core/l10n/app_locale.dart';
import 'package:solagent/core/l10n/l10n.dart';
import 'package:solagent/core/l10n/locale_resolver.dart';
import 'package:solagent/core/security/secure_store.dart';

void main() {
  const supported = [Locale('de'), Locale('en'), Locale('ru')];

  group('resolveAppLocale', () {
    test('picks the first preferred language we ship', () {
      expect(
        resolveAppLocale(const [Locale('ru', 'RU'), Locale('en')], supported),
        const Locale('ru'),
      );
      expect(
        resolveAppLocale(const [Locale('fr'), Locale('ru')], supported),
        const Locale('ru'),
      );
    });

    test('falls back to English, not to the first supported locale', () {
      expect(resolveAppLocale(const [Locale('ja')], supported), fallbackLocale);
      expect(resolveAppLocale(const [], supported), fallbackLocale);
      expect(resolveAppLocale(null, supported), fallbackLocale);
    });

    test('drops the country so every variant maps to one translation', () {
      expect(
        resolveAppLocale(const [Locale('en', 'GB')], supported),
        const Locale('en'),
      );
    });
  });

  group('AppLocale', () {
    testWidgets('follows the device language and updates live', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('ru', 'RU')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final container = ProviderContainer(
        overrides: [secureStoreProvider.overrideWithValue(_NoStore())],
      );
      addTearDown(container.dispose);

      expect(container.read(appLocaleProvider), const Locale('ru'));
      expect(container.read(appL10nProvider).localeName, 'ru');

      tester.platformDispatcher.localesTestValue = const [Locale('ja')];
      await tester.pump();
      expect(container.read(appLocaleProvider), const Locale('en'));
      expect(container.read(appL10nProvider).localeName, 'en');
    });

    testWidgets('widgets get strings for the resolved locale', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('ru')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      late AppLocalizations seen;
      await tester.pumpWidget(
        MaterialApp(
          locale: resolveAppLocaleDefault(tester.platformDispatcher.locales),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              seen = context.l10n;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen.localeName, 'ru');
    });
  });
}

class _NoStore implements SecureStore {
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<void> delete(String key) async {}
}
