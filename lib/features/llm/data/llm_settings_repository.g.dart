// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'llm_settings_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(llmSettingsRepository)
final llmSettingsRepositoryProvider = LlmSettingsRepositoryProvider._();

final class LlmSettingsRepositoryProvider
    extends
        $FunctionalProvider<
          LlmSettingsRepository,
          LlmSettingsRepository,
          LlmSettingsRepository
        >
    with $Provider<LlmSettingsRepository> {
  LlmSettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'llmSettingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$llmSettingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<LlmSettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LlmSettingsRepository create(Ref ref) {
    return llmSettingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LlmSettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LlmSettingsRepository>(value),
    );
  }
}

String _$llmSettingsRepositoryHash() =>
    r'0781d6a2d32a6378bc1047d4b59a17ea82dedea0';
