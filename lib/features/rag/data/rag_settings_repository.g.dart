// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rag_settings_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ragSettingsRepository)
final ragSettingsRepositoryProvider = RagSettingsRepositoryProvider._();

final class RagSettingsRepositoryProvider
    extends
        $FunctionalProvider<
          RagSettingsRepository,
          RagSettingsRepository,
          RagSettingsRepository
        >
    with $Provider<RagSettingsRepository> {
  RagSettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ragSettingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ragSettingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<RagSettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RagSettingsRepository create(Ref ref) {
    return ragSettingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RagSettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RagSettingsRepository>(value),
    );
  }
}

String _$ragSettingsRepositoryHash() =>
    r'3d3327ad2a7c60bce316bce55440c490e328d22b';
