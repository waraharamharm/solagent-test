// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'llm_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LlmSettingsController)
final llmSettingsControllerProvider = LlmSettingsControllerProvider._();

final class LlmSettingsControllerProvider
    extends $AsyncNotifierProvider<LlmSettingsController, LlmSettings> {
  LlmSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'llmSettingsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$llmSettingsControllerHash();

  @$internal
  @override
  LlmSettingsController create() => LlmSettingsController();
}

String _$llmSettingsControllerHash() =>
    r'db513124b55c785e9db06a7cac7bc86d11650ef4';

abstract class _$LlmSettingsController extends $AsyncNotifier<LlmSettings> {
  FutureOr<LlmSettings> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<LlmSettings>, LlmSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LlmSettings>, LlmSettings>,
              AsyncValue<LlmSettings>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Ready-to-use model client, or null until settings and key are complete.
/// Rebuilt whenever settings change.

@ProviderFor(llmService)
final llmServiceProvider = LlmServiceProvider._();

/// Ready-to-use model client, or null until settings and key are complete.
/// Rebuilt whenever settings change.

final class LlmServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<ILLMService?>,
          ILLMService?,
          FutureOr<ILLMService?>
        >
    with $FutureModifier<ILLMService?>, $FutureProvider<ILLMService?> {
  /// Ready-to-use model client, or null until settings and key are complete.
  /// Rebuilt whenever settings change.
  LlmServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'llmServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$llmServiceHash();

  @$internal
  @override
  $FutureProviderElement<ILLMService?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ILLMService?> create(Ref ref) {
    return llmService(ref);
  }
}

String _$llmServiceHash() => r'cdefb69c8563d6e674075970c2a658f066c3fdce';
