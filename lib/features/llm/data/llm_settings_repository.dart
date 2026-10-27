import '../../../core/validation/base_url.dart';

import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_problem.dart';
import '../../../core/security/secure_store.dart';
import '../domain/llm_config.dart';
import '../domain/llm_settings.dart';

part 'llm_settings_repository.g.dart';

/// Persists LLM settings. Everything lives in [SecureStore]: the key is a
/// secret, and the endpoint/model are small enough not to need a second store.
///
/// The API key goes in through [saveApiKey] and comes out only as a
/// ready-to-use [LlmConfig] from [loadConfig]; it is never exposed to UI state.
class LlmSettingsRepository {
  LlmSettingsRepository(this._store);

  static const _settingsKey = 'llm.settings';
  static const _apiKeyKey = 'llm.apiKey';

  final SecureStore _store;

  Future<LlmSettings> load() async {
    final hasApiKey = (await _store.read(_apiKeyKey))?.isNotEmpty ?? false;
    final raw = await _store.read(_settingsKey);
    if (raw == null) return LlmSettings.defaults.copyWith(hasApiKey: hasApiKey);
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, Object?>) throw const FormatException();
      return LlmSettings.fromJson(json, hasApiKey: hasApiKey);
    } on FormatException {
      return LlmSettings.defaults.copyWith(hasApiKey: hasApiKey);
    }
  }

  /// Saves endpoint and model. Throws [AppProblemError] on an unsafe base URL.
  Future<void> save(LlmSettings settings) async {
    final error = validateBaseUrl(settings.baseUrl);
    if (error != null) throw AppProblemError(error);
    await _store.write(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<void> saveApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) throw const AppProblemError(AppProblem.emptyKey);
    await _store.write(_apiKeyKey, trimmed);
  }

  Future<void> deleteApiKey() => _store.delete(_apiKeyKey);

  /// Null when settings are incomplete or the key is missing.
  Future<LlmConfig?> loadConfig() async {
    final settings = await load();
    final apiKey = await _store.read(_apiKeyKey);
    if (apiKey == null || apiKey.isEmpty || !settings.isComplete) return null;
    return LlmConfig(
      baseUrl: settings.baseUrl.trim(),
      model: settings.model.trim(),
      apiKey: apiKey,
    );
  }
}

@Riverpod(keepAlive: true)
LlmSettingsRepository llmSettingsRepository(Ref ref) =>
    LlmSettingsRepository(ref.watch(secureStoreProvider));
