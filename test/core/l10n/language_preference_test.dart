import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solagent/core/l10n/app_locale.dart';
import 'package:solagent/core/security/secure_store.dart';

class _MemoryStore implements SecureStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer make(_MemoryStore store) {
    final c = ProviderContainer(
      overrides: [secureStoreProvider.overrideWithValue(store)],
    );
    addTearDown(c.dispose);
    c.listen(appLocaleProvider, (_, _) {});
    return c;
  }

  setUp(() {
    binding.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(binding.platformDispatcher.clearLocalesTestValue);
  });

  test('follows the device until the user picks a language', () async {
    final c = make(_MemoryStore());
    expect(c.read(appLocaleProvider), const Locale('en'));

    await c.read(languagePreferenceProvider.notifier).set('ru');
    expect(c.read(appLocaleProvider), const Locale('ru'));

    binding.platformDispatcher.localesTestValue = const [Locale('en')];
    expect(c.read(appLocaleProvider), const Locale('ru'));

    await c.read(languagePreferenceProvider.notifier).set(null);
    expect(c.read(appLocaleProvider), const Locale('en'));
  });

  test('the choice is stored and restored; auto clears it', () async {
    final store = _MemoryStore();
    final first = make(store);
    await first.read(languagePreferenceProvider.notifier).set('ru');
    expect(store.values['ui.language'], 'ru');

    final second = make(store);
    second.read(languagePreferenceProvider);
    await Future<void>.delayed(Duration.zero);
    expect(second.read(appLocaleProvider), const Locale('ru'));

    await second.read(languagePreferenceProvider.notifier).set(null);
    expect(store.values, isEmpty);
  });

  test('an unsupported stored code is ignored', () async {
    final store = _MemoryStore()..values['ui.language'] = 'xx';
    final c = make(store);
    c.read(languagePreferenceProvider);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(appLocaleProvider), const Locale('en'));
  });
}
