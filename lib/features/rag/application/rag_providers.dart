import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/http_rag_service.dart';
import '../data/rag_settings_repository.dart';
import '../domain/rag_models.dart';

part 'rag_providers.g.dart';

@Riverpod(keepAlive: true)
class RagSettingsController extends _$RagSettingsController {
  RagSettingsRepository get _repo => ref.read(ragSettingsRepositoryProvider);

  @override
  Future<RagSettings> build() => _repo.load();

  /// Throws [AppProblemError] for an unsafe address.
  Future<void> updateBaseUrl(String baseUrl) async {
    await _repo.saveBaseUrl(baseUrl);
    state = AsyncData(await _repo.load());
  }

  Future<void> setApiKey(String apiKey) async {
    await _repo.saveApiKey(apiKey);
    state = AsyncData(await _repo.load());
  }

  Future<void> clearApiKey() async {
    await _repo.deleteApiKey();
    state = AsyncData(await _repo.load());
  }
}

/// Ready-to-use client, or null until a key is saved. Rebuilt whenever the
/// settings change.
@Riverpod(keepAlive: true)
Future<IRagService?> ragService(Ref ref) async {
  await ref.watch(ragSettingsControllerProvider.future);
  final config = await ref.read(ragSettingsRepositoryProvider).loadConfig();
  return config == null ? null : HttpRagService(config: config);
}

/// Result of the "Check connection" button: how many passages a test query
/// returned. A [RagFailure] ends up in the error state.
@riverpod
class RagConnectionCheck extends _$RagConnectionCheck {
  @override
  AsyncValue<int?> build() {
    ref.watch(ragSettingsControllerProvider);
    return const AsyncData(null);
  }

  Future<void> run() async {
    state = const AsyncLoading();
    try {
      final service = await ref.read(ragServiceProvider.future);
      if (service == null) {
        state = const AsyncError(
          RagUnauthorized('No API key saved'),
          StackTrace.empty,
        );
        return;
      }
      final hits = await service.search('connection check', k: 1);
      if (ref.mounted) state = AsyncData(hits.length);
    } on RagFailure catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
    }
  }
}
