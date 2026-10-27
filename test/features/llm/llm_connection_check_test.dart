import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solagent/core/l10n/l10n.dart';
import 'package:solagent/core/security/secure_store.dart';
import 'package:solagent/features/llm/application/llm_connection_check.dart';
import 'package:solagent/features/llm/application/llm_providers.dart';
import 'package:solagent/features/llm/domain/chat_message.dart';
import 'package:solagent/features/llm/domain/i_llm_service.dart';
import 'package:solagent/features/llm/domain/llm_failure.dart';
import 'package:solagent/features/llm/domain/llm_preset.dart';

class _MemoryStore implements SecureStore {
  final _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

class _FakeService implements ILLMService {
  _FakeService({this.reply = 'ok', this.failure});

  final String reply;
  final LlmFailure? failure;
  List<ChatMessage>? lastMessages;
  double? lastTemperature;

  @override
  Future<LlmResponse> complete(
    List<ChatMessage> messages, {
    double temperature = 0.2,
  }) async {
    lastMessages = messages;
    lastTemperature = temperature;
    if (failure != null) throw failure!;
    return LlmResponse(content: reply);
  }

  @override
  Stream<String> stream(
    List<ChatMessage> messages, {
    double temperature = 0.2,
  }) => throw UnimplementedError();
}

ProviderContainer _container(ILLMService? service) {
  final container = ProviderContainer(
    overrides: [llmServiceProvider.overrideWith((ref) async => service)],
  );
  addTearDown(container.dispose);
  container.listen(llmConnectionCheckProvider, (_, _) {});
  return container;
}

String? _errorText(ProviderContainer c) {
  final error = c.read(llmConnectionCheckProvider).error;
  return error is LlmCheckError ? error.text : null;
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final ru = lookupAppLocalizations(const Locale('ru'));
  final en = lookupAppLocalizations(const Locale('en'));

  setUp(() {
    binding.platformDispatcher.localesTestValue = const [Locale('ru')];
    addTearDown(binding.platformDispatcher.clearLocalesTestValue);
  });

  test('initial state is data(null)', () {
    final c = _container(null);
    expect(c.read(llmConnectionCheckProvider), const AsyncData<String?>(null));
  });

  test('null service -> error text', () async {
    final c = _container(null);
    await c.read(llmConnectionCheckProvider.notifier).run();
    expect(_errorText(c), 'Сначала заполните настройки и ключ');
  });

  test('success stores trimmed reply and sends the probe', () async {
    final service = _FakeService(reply: '  ok \n');
    final c = _container(service);
    await c.read(llmConnectionCheckProvider.notifier).run();
    expect(c.read(llmConnectionCheckProvider).value, 'ok');
    expect(service.lastTemperature, 0);
    expect(service.lastMessages, [
      const ChatMessage.user('Reply with the single word: ok'),
    ]);
  });

  test('reply is cut to 200 chars', () async {
    final c = _container(_FakeService(reply: 'x' * 500));
    await c.read(llmConnectionCheckProvider.notifier).run();
    expect(c.read(llmConnectionCheckProvider).value!.length, 200);
  });

  test('result resets when settings change', () async {
    final c = ProviderContainer(
      overrides: [
        secureStoreProvider.overrideWithValue(_MemoryStore()),
        llmServiceProvider.overrideWith((ref) async => _FakeService()),
      ],
    );
    addTearDown(c.dispose);
    c.listen(llmConnectionCheckProvider, (_, _) {});
    await c.read(llmSettingsControllerProvider.future);

    await c.read(llmConnectionCheckProvider.notifier).run();
    expect(c.read(llmConnectionCheckProvider).value, 'ok');

    await c
        .read(llmSettingsControllerProvider.notifier)
        .selectPreset(LlmPreset.grok);
    expect(c.read(llmConnectionCheckProvider), const AsyncData<String?>(null));
  });

  group('failures map to Russian texts', () {
    final cases = <LlmFailure, String>{
      const LlmUnauthorized('HTTP 401: bad key'):
          'Ключ не принят: проверьте, что он вставлен целиком\n'
          'HTTP 401: bad key',
      const LlmUnauthorized('HTTP 403: region', statusCode: 403):
          'Доступ запрещён. Частая причина — регион: включите VPN\n'
          'HTTP 403: region',
      const LlmRateLimited('x'): 'Лимит запросов или закончился баланс\nx',
      const LlmNetworkFailure('x'): 'Нет связи с провайдером\nx',
      const LlmServerFailure(503, 'HTTP 503'): 'Ошибка провайдера\nHTTP 503',
      const LlmBadResponse('x'): 'Провайдер вернул непонятный ответ\nx',
    };
    test('the same failures in English carry no Cyrillic', () {
      for (final failure in cases.keys) {
        final text = describeLlmFailure(en, failure);
        expect(text, isNot(matches(RegExp('[А-Яа-яЁё]'))));
        expect(text, endsWith(failure.message));
      }
    });

    cases.forEach((failure, text) {
      test(failure.runtimeType.toString(), () async {
        expect(describeLlmFailure(ru, failure), text);
        final c = _container(_FakeService(failure: failure));
        await c.read(llmConnectionCheckProvider.notifier).run();
        expect(_errorText(c), text);
      });
    });
  });
}
