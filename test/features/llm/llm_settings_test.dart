import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solagent/core/errors/app_problem.dart';
import 'package:solagent/core/security/secure_store.dart';
import 'package:solagent/core/validation/base_url.dart';
import 'package:solagent/features/llm/application/llm_providers.dart';
import 'package:solagent/features/llm/data/llm_settings_repository.dart';
import 'package:solagent/features/llm/domain/llm_preset.dart';
import 'package:solagent/features/llm/domain/llm_settings.dart';

import '../../support/memory_store.dart';

void main() {
  group('validateBaseUrl', () {
    test('accepts https', () {
      expect(validateBaseUrl('https://api.deepseek.com/v1'), isNull);
    });

    test('accepts http only for loopback and private networks', () {
      for (final url in [
        'http://localhost:11434/v1',
        'http://127.0.0.1:8080/v1',
        'http://10.0.2.2:11434/v1',
        'http://192.168.1.5/v1',
        'http://172.20.0.3/v1',
      ]) {
        expect(validateBaseUrl(url), isNull, reason: url);
      }
    });

    test('rejects http to public hosts, garbage and other schemes', () {
      for (final url in [
        'http://api.openai.com/v1',
        'http://8.8.8.8/v1',
        'http://172.32.0.1/v1',
        'api.deepseek.com',
        '',
        'ftp://example.com',
      ]) {
        expect(validateBaseUrl(url), isNotNull, reason: url);
      }
    });
  });

  group('LlmSettingsRepository', () {
    late MemoryStore store;
    late LlmSettingsRepository repo;

    setUp(() {
      store = MemoryStore();
      repo = LlmSettingsRepository(store);
    });

    test('defaults when nothing stored', () async {
      expect(await repo.load(), LlmSettings.defaults);
      expect(await repo.loadConfig(), isNull);
    });

    test('settings round-trip and never contain the key', () async {
      await repo.saveApiKey('  sk-secret  ');
      await repo.save(
        LlmSettings.fromPreset(LlmPreset.grok).copyWith(model: 'grok-x'),
      );

      final loaded = await repo.load();
      expect(loaded.preset, LlmPreset.grok);
      expect(loaded.model, 'grok-x');
      expect(loaded.hasApiKey, isTrue);
      expect(store.values['llm.settings'], isNot(contains('sk-secret')));

      final config = await repo.loadConfig();
      expect(config!.apiKey, 'sk-secret');
      expect(config.baseUrl, LlmPreset.grok.baseUrl);
      expect(config.toString(), isNot(contains('sk-secret')));
    });

    test('rejects unsafe base url without writing', () async {
      final unsafe = LlmSettings.fromPreset(LlmPreset.custom)
          .copyWith(baseUrl: 'http://evil.example.com/v1', model: 'm');
      expect(() => repo.save(unsafe), throwsA(isA<AppProblemError>()));
      expect(store.values, isEmpty);
    });

    test('rejects empty key', () {
      expect(() => repo.saveApiKey('   '), throwsA(isA<AppProblemError>()));
    });

    test('corrupted settings fall back to defaults', () async {
      store.values['llm.settings'] = '{not json';
      expect(await repo.load(), LlmSettings.defaults);
    });

    test('deleteApiKey makes config unavailable', () async {
      await repo.saveApiKey('sk-secret');
      await repo.deleteApiKey();
      expect((await repo.load()).hasApiKey, isFalse);
      expect(await repo.loadConfig(), isNull);
    });
  });

  group('LlmSettingsController', () {
    late MemoryStore store;
    late ProviderContainer container;

    setUp(() {
      store = MemoryStore();
      container = ProviderContainer(
        overrides: [secureStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
    });

    LlmSettingsController controller() =>
        container.read(llmSettingsControllerProvider.notifier);

    test('no service until key is set', () async {
      expect(await container.read(llmServiceProvider.future), isNull);

      await container.read(llmSettingsControllerProvider.future);
      await controller().setApiKey('sk-secret');

      expect(
        container.read(llmSettingsControllerProvider).value!.hasApiKey,
        isTrue,
      );
      expect(await container.read(llmServiceProvider.future), isNotNull);
    });

    test('known preset resets endpoint, custom keeps it', () async {
      await container.read(llmSettingsControllerProvider.future);
      await controller().selectPreset(LlmPreset.openRouter);
      var s = container.read(llmSettingsControllerProvider).value!;
      expect(s.baseUrl, LlmPreset.openRouter.baseUrl);
      expect(s.model, LlmPreset.openRouter.defaultModel);

      await controller().selectPreset(LlmPreset.custom);
      s = container.read(llmSettingsControllerProvider).value!;
      expect(s.preset, LlmPreset.custom);
      expect(s.baseUrl, LlmPreset.openRouter.baseUrl);
    });

    test('updateEndpoint rejects unsafe url and keeps state', () async {
      final before = await container.read(llmSettingsControllerProvider.future);
      await expectLater(
        controller().updateEndpoint(
          baseUrl: 'http://evil.example.com',
          model: 'm',
        ),
        throwsA(isA<AppProblemError>()),
      );
      expect(container.read(llmSettingsControllerProvider).value, before);
    });

    test('clearApiKey drops the service', () async {
      await container.read(llmSettingsControllerProvider.future);
      await controller().setApiKey('sk-secret');
      await controller().clearApiKey();
      expect(await container.read(llmServiceProvider.future), isNull);
    });
  });
}
