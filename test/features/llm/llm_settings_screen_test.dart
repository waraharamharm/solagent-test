import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solagent/core/l10n/l10n.dart';
import 'package:solagent/core/security/secure_store.dart';
import 'package:solagent/features/llm/domain/llm_preset.dart';
import 'package:solagent/features/llm/presentation/llm_settings_screen.dart';

import '../../support/memory_store.dart';

Future<MemoryStore> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final store = MemoryStore();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [secureStoreProvider.overrideWithValue(store)],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('ru'),
        home: LlmSettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

String _text(WidgetTester tester, Finder f) =>
    tester.widget<TextFormField>(f).controller!.text;

void main() {
  testWidgets('saving a key shows "Ключ сохранён" and never renders the key', (
    tester,
  ) async {
    const secret = 'sk-super-secret-123';
    final store = await _pump(tester);

    await tester.enterText(find.widgetWithText(TextField, 'API-ключ'), secret);
    await tester.tap(find.text('Сохранить ключ'));
    await tester.pumpAndSettle();

    expect(find.text('Ключ сохранён'), findsOneWidget);
    expect(find.text('Сохранить ключ'), findsNothing);
    expect(find.textContaining(secret), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) => w is EditableText && w.controller.text.contains(secret),
      ),
      findsNothing,
    );
    expect(store.values['llm.apiKey'], secret);
  });

  testWidgets('selecting OpenRouter updates the Base URL field', (
    tester,
  ) async {
    await _pump(tester);
    expect(_text(tester, _field('Base URL')), LlmPreset.deepSeek.baseUrl);

    await tester.tap(find.text('OpenRouter'));
    await tester.pumpAndSettle();

    expect(_text(tester, _field('Base URL')), LlmPreset.openRouter.baseUrl);
    expect(_text(tester, _field('Модель')), LlmPreset.openRouter.defaultModel);
  });

  testWidgets('unsafe http URL shows an error and is not persisted', (
    tester,
  ) async {
    final store = await _pump(tester);

    await tester.enterText(_field('Base URL'), 'http://evil.example.com/v1');
    await tester.tap(find.text('Сохранить').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Без https'), findsWidgets);
    expect(store.values, isEmpty);
  });
}
