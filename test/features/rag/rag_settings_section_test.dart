import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solagent/core/l10n/l10n.dart';
import 'package:solagent/core/security/secure_store.dart';
import 'package:solagent/features/rag/application/rag_providers.dart';
import 'package:solagent/features/rag/domain/knowledge_bundle.dart';
import 'package:solagent/features/rag/domain/rag_models.dart';
import 'package:solagent/features/rag/presentation/rag_settings_section.dart';

import '../../support/memory_store.dart';

class _Service implements IRagService {
  _Service(this.result);
  final Object result;

  @override
  Future<KnowledgeBundle> fetchBundle() => throw UnimplementedError();

  @override
  Future<List<RagHit>> search(String query, {String? os, int k = 4}) async {
    final r = result;
    if (r is RagFailure) throw r;
    return r as List<RagHit>;
  }
}

Future<void> _pump(
  WidgetTester tester,
  MemoryStore store, {
  Object? result,
  String locale = 'en',
}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        secureStoreProvider.overrideWithValue(store),
        if (result != null)
          ragServiceProvider.overrideWith((ref) async => _Service(result)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(locale),
        home: const Scaffold(
          body: SingleChildScrollView(child: RagSettingsSection()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('key is stored, field disappears, deletion needs confirmation', (
    tester,
  ) async {
    final store = MemoryStore();
    await _pump(tester, store);
    expect(find.text('Knowledge base'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Access key'),
      'sol_abc',
    );
    await tester.tap(find.text('Save access key'));
    await tester.pumpAndSettle();
    expect(find.text('Access key saved'), findsOneWidget);
    expect(find.text('sol_abc'), findsNothing);
    expect(store.values['rag.apiKey'], 'sol_abc');

    await tester.tap(find.byTooltip('Delete access key'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(store.values['rag.apiKey'], 'sol_abc');

    await tester.tap(find.byTooltip('Delete access key'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(store.values.containsKey('rag.apiKey'), isFalse);
  });

  testWidgets('the server address is not shown anywhere', (tester) async {
    await _pump(tester, MemoryStore());
    expect(find.text('Server address'), findsNothing);
    expect(find.textContaining('mtoper'), findsNothing);
  });

  testWidgets('the check is disabled until a key exists', (tester) async {
    await _pump(tester, MemoryStore());
    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Check knowledge base'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('check shows the passage count', (tester) async {
    final store = MemoryStore()..values['rag.apiKey'] = 'sol_abc';
    await _pump(
      tester,
      store,
      result: const [RagHit(source: 'doc', path: 'p', text: 't', score: 1)],
    );
    await tester.tap(find.text('Check knowledge base'));
    await tester.pumpAndSettle();
    expect(find.text('Connected. Passages found: 1'), findsOneWidget);
  });

  testWidgets('failures are shown in the app language', (tester) async {
    final store = MemoryStore()..values['rag.apiKey'] = 'sol_abc';
    await _pump(
      tester,
      store,
      result: const RagRateLimited('x', retryAfterSeconds: 7),
      locale: 'ru',
    );
    await tester.tap(find.text('Проверить базу знаний'));
    await tester.pumpAndSettle();
    expect(
      find.text('Слишком много запросов. Повторите через 7 с.'),
      findsOneWidget,
    );
  });
}
