import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/llm_settings_repository.dart';
import '../data/openai_compatible_llm_service.dart';
import '../domain/i_llm_service.dart';
import '../domain/llm_preset.dart';
import '../domain/llm_settings.dart';

part 'llm_providers.g.dart';

@Riverpod(keepAlive: true)
class LlmSettingsController extends _$LlmSettingsController {
  LlmSettingsRepository get _repo => ref.read(llmSettingsRepositoryProvider);

  @override
  Future<LlmSettings> build() => _repo.load();

  /// Switches preset. Known presets reset endpoint and model to their
  /// defaults; [LlmPreset.custom] keeps the current values for editing.
  Future<void> selectPreset(LlmPreset preset) async {
    final current = await future;
    final next = preset == LlmPreset.custom
        ? current.copyWith(preset: preset)
        : LlmSettings.fromPreset(preset, hasApiKey: current.hasApiKey);
    await _save(next);
  }

  /// Throws [ArgumentError] with a user-facing message on an unsafe URL.
  Future<void> updateEndpoint({
    required String baseUrl,
    required String model,
  }) async {
    final current = await future;
    await _save(current.copyWith(baseUrl: baseUrl.trim(), model: model.trim()));
  }

  Future<void> setApiKey(String apiKey) async {
    await _repo.saveApiKey(apiKey);
    state = AsyncData((await future).copyWith(hasApiKey: true));
  }

  Future<void> clearApiKey() async {
    await _repo.deleteApiKey();
    state = AsyncData((await future).copyWith(hasApiKey: false));
  }

  Future<void> _save(LlmSettings next) async {
    await _repo.save(next);
    state = AsyncData(next);
  }
}

/// Ready-to-use model client, or null until settings and key are complete.
/// Rebuilt whenever settings change.
@riverpod
Future<ILLMService?> llmService(Ref ref) async {
  await ref.watch(llmSettingsControllerProvider.future);
  final config = await ref.read(llmSettingsRepositoryProvider).loadConfig();
  return config == null ? null : OpenAiCompatibleLlmService(config: config);
}
