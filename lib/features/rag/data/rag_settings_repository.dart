import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_problem.dart';
import '../../../core/security/secure_store.dart';
import '../../llm/domain/llm_settings.dart';
import '../domain/rag_models.dart';

part 'rag_settings_repository.g.dart';

const defaultRagUrl = 'https://rag.mtoper.ru';

class RagSettings {
  const RagSettings({required this.baseUrl, required this.hasApiKey});

  final String baseUrl;
  final bool hasApiKey;
}

/// The knowledge server address and key, both in [SecureStore]. Like the LLM
/// key, the RAG key goes in through [saveApiKey] and comes out only inside a
/// [RagConfig] for the HTTP client, never into UI state.
class RagSettingsRepository {
  RagSettingsRepository(this._store);

  static const _urlKey = 'rag.baseUrl';
  static const _apiKeyKey = 'rag.apiKey';

  final SecureStore _store;

  Future<RagSettings> load() async {
    final url = (await _store.read(_urlKey))?.trim();
    final key = await _store.read(_apiKeyKey);
    return RagSettings(
      baseUrl: url == null || url.isEmpty ? defaultRagUrl : url,
      hasApiKey: key != null && key.isNotEmpty,
    );
  }

  /// Throws [AppProblemError] for http to a public host or a non-http scheme.
  Future<void> saveBaseUrl(String baseUrl) async {
    final problem = validateBaseUrl(baseUrl);
    if (problem != null) throw AppProblemError(problem);
    await _store.write(_urlKey, baseUrl.trim());
  }

  Future<void> saveApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) throw const AppProblemError(AppProblem.emptyKey);
    await _store.write(_apiKeyKey, trimmed);
  }

  Future<void> deleteApiKey() => _store.delete(_apiKeyKey);

  /// Null until a key is saved.
  Future<RagConfig?> loadConfig() async {
    final settings = await load();
    final key = await _store.read(_apiKeyKey);
    if (key == null || key.isEmpty) return null;
    return RagConfig(baseUrl: settings.baseUrl, apiKey: key);
  }
}

@Riverpod(keepAlive: true)
RagSettingsRepository ragSettingsRepository(Ref ref) =>
    RagSettingsRepository(ref.watch(secureStoreProvider));
