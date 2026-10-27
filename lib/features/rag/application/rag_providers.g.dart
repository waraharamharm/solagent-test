// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rag_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RagSettingsController)
final ragSettingsControllerProvider = RagSettingsControllerProvider._();

final class RagSettingsControllerProvider
    extends $AsyncNotifierProvider<RagSettingsController, RagSettings> {
  RagSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ragSettingsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ragSettingsControllerHash();

  @$internal
  @override
  RagSettingsController create() => RagSettingsController();
}

String _$ragSettingsControllerHash() =>
    r'cec567e289ea4a4ec5e1e5696b7e1b094c1218e1';

abstract class _$RagSettingsController extends $AsyncNotifier<RagSettings> {
  FutureOr<RagSettings> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<RagSettings>, RagSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<RagSettings>, RagSettings>,
              AsyncValue<RagSettings>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Ready-to-use client, or null until a key is saved. Rebuilt whenever the
/// settings change.

@ProviderFor(ragService)
final ragServiceProvider = RagServiceProvider._();

/// Ready-to-use client, or null until a key is saved. Rebuilt whenever the
/// settings change.

final class RagServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<IRagService?>,
          IRagService?,
          FutureOr<IRagService?>
        >
    with $FutureModifier<IRagService?>, $FutureProvider<IRagService?> {
  /// Ready-to-use client, or null until a key is saved. Rebuilt whenever the
  /// settings change.
  RagServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ragServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ragServiceHash();

  @$internal
  @override
  $FutureProviderElement<IRagService?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<IRagService?> create(Ref ref) {
    return ragService(ref);
  }
}

String _$ragServiceHash() => r'702ee95c4dc2bfe7f4df53d9d1b5d5472ee295a6';

/// Result of the "Check connection" button: how many passages a test query
/// returned. A [RagFailure] ends up in the error state.

@ProviderFor(RagConnectionCheck)
final ragConnectionCheckProvider = RagConnectionCheckProvider._();

/// Result of the "Check connection" button: how many passages a test query
/// returned. A [RagFailure] ends up in the error state.
final class RagConnectionCheckProvider
    extends $NotifierProvider<RagConnectionCheck, AsyncValue<int?>> {
  /// Result of the "Check connection" button: how many passages a test query
  /// returned. A [RagFailure] ends up in the error state.
  RagConnectionCheckProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ragConnectionCheckProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ragConnectionCheckHash();

  @$internal
  @override
  RagConnectionCheck create() => RagConnectionCheck();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<int?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<int?>>(value),
    );
  }
}

String _$ragConnectionCheckHash() =>
    r'a5c95a3e0a771098faf6a4f361edc59b6bc5d271';

/// Result of the "Check connection" button: how many passages a test query
/// returned. A [RagFailure] ends up in the error state.

abstract class _$RagConnectionCheck extends $Notifier<AsyncValue<int?>> {
  AsyncValue<int?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<int?>, AsyncValue<int?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<int?>, AsyncValue<int?>>,
              AsyncValue<int?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
