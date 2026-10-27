import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solagent/app/home_screen.dart';
import 'package:solagent/core/l10n/app_locale.dart';
import 'package:solagent/core/l10n/l10n.dart';
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

class _App extends ConsumerWidget {
  const _App();

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: ref.watch(appLocaleProvider),
    home: const HomeScreen(),
  );
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('picking a language, then "Match device", returns to the device '
      'language', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    binding.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(binding.platformDispatcher.clearLocalesTestValue);

    final store = _MemoryStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [secureStoreProvider.overrideWithValue(store)],
        child: const _App(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('\u0420\u0443\u0441\u0441\u043a\u0438\u0439'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Language'), findsNothing);
    expect(store.values['ui.language'], 'ru');

    await tester.tap(find.byTooltip('\u042f\u0437\u044b\u043a'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(
        '\u041a\u0430\u043a \u043d\u0430 \u0443\u0441\u0442\u0440\u043e\u0439\u0441\u0442\u0432\u0435',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Language'), findsOneWidget);
    expect(store.values, isEmpty);
  });
}
